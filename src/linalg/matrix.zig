// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const simd = @import("../core/simd.zig");

/// Representación plana contigua en memoria de una matriz de números reales f64
pub const DenseMatrix = struct {
    rows: usize,
    cols: usize,
    data: []f64,
    allocator: ?std.mem.Allocator = null,

    const Self = @This();

    /// Asigna e inicializa una matriz vacía (llena de ceros)
    pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Self {
        const data = try allocator.alloc(f64, rows * cols);
        @memset(data, 0.0);
        return .{
            .rows = rows,
            .cols = cols,
            .data = data,
            .allocator = allocator,
        };
    }

    /// Crea una vista estructurada sobre un slice preasignado existente
    pub fn fromSlice(rows: usize, cols: usize, data: []f64) Self {
        std.debug.assert(data.len >= rows * cols);
        return .{
            .rows = rows,
            .cols = cols,
            .data = data[0 .. rows * cols],
            .allocator = null,
        };
    }

    /// Crea una matriz identidad de dimensión n x n
    pub fn identity(allocator: std.mem.Allocator, n: usize) !Self {
        var mat = try Self.init(allocator, n, n);
        for (0..n) |i| {
            mat.data[i * n + i] = 1.0;
        }
        return mat;
    }

    pub fn deinit(self: *Self) void {
        if (self.allocator) |alloc| {
            alloc.free(self.data);
            self.data = &.{};
        }
    }

    pub inline fn get(self: Self, r: usize, c: usize) f64 {
        std.debug.assert(r < self.rows and c < self.cols);
        return self.data[r * self.cols + c];
    }

    pub inline fn set(self: *Self, r: usize, c: usize, value: f64) void {
        std.debug.assert(r < self.rows and c < self.cols);
        self.data[r * self.cols + c] = value;
    }

    pub inline fn row(self: Self, r: usize) []f64 {
        std.debug.assert(r < self.rows);
        const offset = r * self.cols;
        return self.data[offset .. offset + self.cols];
    }

    pub inline fn rowConst(self: Self, r: usize) []const f64 {
        std.debug.assert(r < self.rows);
        const offset = r * self.cols;
        return self.data[offset .. offset + self.cols];
    }

    /// Calcula la norma L2 euclidiana de una columna específica
    pub fn columnNorm(self: Self, c: usize) f64 {
        std.debug.assert(c < self.cols);
        var sumsq: f64 = 0.0;
        var r: usize = 0;
        while (r < self.rows) : (r += 1) {
            const val = self.get(r, c);
            sumsq += val * val;
        }
        return @sqrt(sumsq);
    }

    /// Rellena toda la matriz con un valor escalar
    pub fn fill(self: *Self, val: f64) void {
        @memset(self.data, val);
    }

    /// Crea un clon profundo de la matriz (nueva asignación de memoria)
    pub fn clone(self: Self, allocator: std.mem.Allocator) !Self {
        const new_data = try allocator.alloc(f64, self.rows * self.cols);
        @memcpy(new_data, self.data[0 .. self.rows * self.cols]);
        return .{
            .rows = self.rows,
            .cols = self.cols,
            .data = new_data,
            .allocator = allocator,
        };
    }

    /// Calcula la traza (suma de la diagonal principal) de una matriz cuadrada
    pub fn trace(self: Self) f64 {
        const n = @min(self.rows, self.cols);
        var sum: f64 = 0.0;
        for (0..n) |i| {
            sum += self.data[i * self.cols + i];
        }
        return sum;
    }

    /// Devuelve la transpuesta de la matriz en una nueva asignación
    pub fn transpose(self: Self, allocator: std.mem.Allocator) !Self {
        var result = try Self.init(allocator, self.cols, self.rows);
        for (0..self.rows) |r| {
            for (0..self.cols) |c| {
                result.data[c * self.rows + r] = self.data[r * self.cols + c];
            }
        }
        return result;
    }

    /// Multiplicación matricial general: C = self * other
    /// Requiere self.cols == other.rows
    pub fn matMul(self: Self, other: Self, allocator: std.mem.Allocator) !Self {
        std.debug.assert(self.cols == other.rows);
        var result = try Self.init(allocator, self.rows, other.cols);

        for (0..self.rows) |r| {
            for (0..other.cols) |c| {
                var sum: f64 = 0.0;
                for (0..self.cols) |k| {
                    sum += self.data[r * self.cols + k] * other.data[k * other.cols + c];
                }
                result.data[r * other.cols + c] = sum;
            }
        }
        return result;
    }

    /// Calcula la norma de Frobenius: sqrt(Σ a_ij²)
    pub fn frobeniusNorm(self: Self) f64 {
        const total = self.rows * self.cols;
        return simd.normL2(self.data[0..total]);
    }

    /// Suma escalar: modifica in-place self += scalar
    pub fn addScalar(self: *Self, scalar: f64) void {
        for (self.data[0 .. self.rows * self.cols]) |*val| {
            val.* += scalar;
        }
    }

    /// Escala in-place todos los elementos por un factor: self *= factor
    pub fn scaleInPlace(self: *Self, factor: f64) void {
        simd.scale(self.data[0 .. self.rows * self.cols], factor);
    }

    /// Verifica si la matriz es simétrica dentro de una tolerancia
    pub fn isSymmetric(self: Self, tolerance: f64) bool {
        if (self.rows != self.cols) return false;
        for (0..self.rows) |r| {
            for (r + 1..self.cols) |c| {
                if (@abs(self.get(r, c) - self.get(c, r)) > tolerance) return false;
            }
        }
        return true;
    }
};

/// Resuelve un sistema lineal general A * x = b de dimensión n x n con regularización Tikhonov alpha
/// mediante eliminación Gaussiana con pivoteo parcial (implementación de v6 ultra).
pub fn solveDenseSystem(
    allocator: std.mem.Allocator,
    A: []const f64,
    b: []const f64,
    n: usize,
    alpha: f64,
    x_out: []f64,
) !bool {
    if (n == 0) return false;
    std.debug.assert(A.len >= n * n);
    std.debug.assert(b.len >= n);
    std.debug.assert(x_out.len >= n);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    const stride = n + 1;
    const mat = try temp_alloc.alloc(f64, n * stride);

    for (0..n) |i| {
        for (0..n) |j| {
            mat[i * stride + j] = A[i * n + j];
        }
        mat[i * stride + i] += alpha;
        mat[i * stride + n] = b[i];
    }

    for (0..n) |i| {
        var max_row = i;
        var max_val = @abs(mat[i * stride + i]);

        var r = i + 1;
        while (r < n) : (r += 1) {
            const val = @abs(mat[r * stride + i]);
            if (val > max_val) {
                max_val = val;
                max_row = r;
            }
        }

        if (max_val < 1e-30) return false;

        if (max_row != i) {
            for (0..stride) |c| {
                const tmp = mat[i * stride + c];
                mat[i * stride + c] = mat[max_row * stride + c];
                mat[max_row * stride + c] = tmp;
            }
        }

        r = i + 1;
        while (r < n) : (r += 1) {
            const factor = mat[r * stride + i] / mat[i * stride + i];
            for (i..stride) |c| {
                mat[r * stride + c] -= factor * mat[i * stride + c];
            }
        }
    }

    var k: usize = n;
    while (k > 0) {
        k -= 1;
        var sum: f64 = 0.0;
        var j = k + 1;
        while (j < n) : (j += 1) {
            sum += mat[k * stride + j] * x_out[j];
        }
        x_out[k] = (mat[k * stride + n] - sum) / mat[k * stride + k];
    }

    return true;
}
