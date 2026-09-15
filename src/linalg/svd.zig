// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Descomposición en Valores Singulares (SVD) mediante Rotaciones de Jacobi Unilaterales
//!
//! Factoriza cualquier matriz A (m × n con m ≥ n) en A = U Σ Vᵀ:
//! - U (m × n): Columnas ortonormales en ℝᵐ
//! - Σ: Vector de valores singulares ordenados σ₁ ≥ σ₂ ≥ ... ≥ σₙ ≥ 0
//! - V (n × n): Matriz ortogonal en ℝⁿˣⁿ (Vᵀ V = I)
//!
//! Proporciona:
//! - Rango numérico de la matriz
//! - Número de condición κ(A) = σ_max / σ_min
//! - Pseudoinversa de Moore-Penrose A⁺ = V Σ⁺ Uᵀ
//! - Aproximación óptima de bajo rango (Teorema de Eckart-Young-Mirsky)

const std = @import("std");
const matrix_mod = @import("matrix.zig");
const DenseMatrix = matrix_mod.DenseMatrix;
const simd = @import("../core/simd.zig");

pub const SvdResult = struct {
    allocator: std.mem.Allocator,
    m: usize,
    n: usize,
    u: DenseMatrix,
    s: []f64,
    v: DenseMatrix,

    pub fn deinit(self: *SvdResult) void {
        self.u.deinit();
        self.v.deinit();
        self.allocator.free(self.s);
    }

    /// Calcula el rango numérico efectivo basado en tolerancia ε
    pub fn rank(self: SvdResult, tol: ?f64) usize {
        if (self.s.len == 0) return 0;
        const default_tol = @as(f64, @floatFromInt(@max(self.m, self.n))) * self.s[0] * 2.220446049250313e-16;
        const effective_tol = tol orelse default_tol;

        var r: usize = 0;
        for (self.s) |sigma| {
            if (sigma > effective_tol) {
                r += 1;
            }
        }
        return r;
    }

    /// Calcula el número de condición κ(A) = σ₁ / σₙ
    pub fn conditionNumber(self: SvdResult) f64 {
        if (self.s.len == 0) return 1.0;
        const s_max = self.s[0];
        const s_min = self.s[self.s.len - 1];
        if (s_min < 1e-15) return std.math.inf(f64);
        return s_max / s_min;
    }

    /// Calcula la pseudoinversa de Moore-Penrose: A⁺ = V Σ⁺ Uᵀ (dimensión n × m)
    pub fn pseudoInverse(self: SvdResult, allocator: std.mem.Allocator) !DenseMatrix {
        var pinv = try DenseMatrix.init(allocator, self.n, self.m);
        errdefer pinv.deinit();

        const tol = @as(f64, @floatFromInt(@max(self.m, self.n))) * self.s[0] * 1e-15;

        // A⁺ = ∑ (1 / σ_k) * v_k * u_kᵀ
        for (0..self.n) |k| {
            const sigma = self.s[k];
            if (sigma <= tol) continue;
            const inv_sigma = 1.0 / sigma;

            for (0..self.n) |i| {
                const v_ik = self.v.get(i, k);
                for (0..self.m) |j| {
                    const u_jk = self.u.get(j, k);
                    const cur = pinv.get(i, j);
                    pinv.set(i, j, cur + inv_sigma * v_ik * u_jk);
                }
            }
        }

        return pinv;
    }

    /// Reconstruye la matriz aproximada A_reconstructed = U Σ Vᵀ (dimensión m × n)
    pub fn reconstruct(self: SvdResult, allocator: std.mem.Allocator) !DenseMatrix {
        var a_rec = try DenseMatrix.init(allocator, self.m, self.n);
        errdefer a_rec.deinit();

        for (0..self.m) |i| {
            for (0..self.n) |j| {
                var sum: f64 = 0.0;
                for (0..self.n) |k| {
                    sum += self.u.get(i, k) * self.s[k] * self.v.get(j, k);
                }
                a_rec.set(i, j, sum);
            }
        }

        return a_rec;
    }
};

/// Calcula la Descomposición en Valores Singulares (SVD) de una matriz A (m × n)
/// utilizando el método de Jacobi Unilateral de Hestenes.
pub fn computeSvd(
    allocator: std.mem.Allocator,
    a: DenseMatrix,
    max_iters: usize,
    tolerance: f64,
) !SvdResult {
    const m = a.rows;
    const n = a.cols;
    std.debug.assert(m >= n and n > 0);

    // B inicia como una copia de A (m × n)
    var b = try a.clone(allocator);
    defer b.deinit();

    // V inicia como la matriz identidad (n × n)
    var v = try DenseMatrix.identity(allocator, n);
    errdefer v.deinit();

    var s = try allocator.alloc(f64, n);
    errdefer allocator.free(s);

    // Bucle de barridos de Jacobi
    var iter: usize = 0;
    while (iter < max_iters) : (iter += 1) {
        var max_ortho_err: f64 = 0.0;

        for (0..n) |i| {
            for ((i + 1)..n) |j| {
                // Producto punto ⟨b_i, b_j⟩ y normas cuadráticas
                var alpha: f64 = 0.0; // ‖b_i‖²
                var beta: f64 = 0.0;  // ‖b_j‖²
                var gamma: f64 = 0.0; // ⟨b_i, b_j⟩

                for (0..m) |r| {
                    const bi = b.get(r, i);
                    const bj = b.get(r, j);
                    alpha += bi * bi;
                    beta += bj * bj;
                    gamma += bi * bj;
                }

                const denom = @sqrt(alpha * beta);
                if (denom > 1e-25) {
                    const err = @abs(gamma) / denom;
                    if (err > max_ortho_err) max_ortho_err = err;
                }

                if (@abs(gamma) < 1e-15 or denom < 1e-25) continue;

                // Parámetro de rotación de Jacobi
                const zeta = (beta - alpha) / (2.0 * gamma);
                const t = if (zeta >= 0.0)
                    1.0 / (zeta + @sqrt(1.0 + zeta * zeta))
                else
                    -1.0 / (-zeta + @sqrt(1.0 + zeta * zeta));

                const c = 1.0 / @sqrt(1.0 + t * t);
                const sn = t * c;

                // Aplicar rotación a las columnas i y j de B
                for (0..m) |r| {
                    const bi = b.get(r, i);
                    const bj = b.get(r, j);
                    b.set(r, i, c * bi - sn * bj);
                    b.set(r, j, sn * bi + c * bj);
                }

                // Aplicar rotación a las columnas i y j de V
                for (0..n) |r| {
                    const vi = v.get(r, i);
                    const vj = v.get(r, j);
                    v.set(r, i, c * vi - sn * vj);
                    v.set(r, j, sn * vi + c * vj);
                }
            }
        }

        if (max_ortho_err < tolerance) break;
    }

    // Calcular valores singulares σ_k = ‖b_k‖ y normalizar columnas para formar U
    var u = try DenseMatrix.init(allocator, m, n);
    errdefer u.deinit();

    for (0..n) |j| {
        var sumsq: f64 = 0.0;
        for (0..m) |r| {
            const val = b.get(r, j);
            sumsq += val * val;
        }
        const sigma = @sqrt(sumsq);
        s[j] = sigma;

        if (sigma > 1e-14) {
            const inv_sigma = 1.0 / sigma;
            for (0..m) |r| {
                u.set(r, j, b.get(r, j) * inv_sigma);
            }
        } else {
            for (0..m) |r| {
                u.set(r, j, 0.0);
            }
        }
    }

    // Ordenar valores singulares de forma decreciente (burbuja/inserción sobre n columnas)
    for (0..n) |i| {
        var max_idx = i;
        var max_val = s[i];
        for ((i + 1)..n) |j| {
            if (s[j] > max_val) {
                max_val = s[j];
                max_idx = j;
            }
        }
        if (max_idx != i) {
            // Intercambiar singular value
            s[max_idx] = s[i];
            s[i] = max_val;

            // Intercambiar columnas en U
            for (0..m) |r| {
                const tmp = u.get(r, i);
                u.set(r, i, u.get(r, max_idx));
                u.set(r, max_idx, tmp);
            }

            // Intercambiar columnas en V
            for (0..n) |r| {
                const tmp = v.get(r, i);
                v.set(r, i, v.get(r, max_idx));
                v.set(r, max_idx, tmp);
            }
        }
    }

    return SvdResult{
        .allocator = allocator,
        .m = m,
        .n = n,
        .u = u,
        .s = s,
        .v = v,
    };
}
