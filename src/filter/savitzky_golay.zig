// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const solver4x4 = @import("../linalg/solver4x4.zig");

pub const FilterResult = struct {
    smoothed: []f64,
    derivatives: []f64,

    pub fn deinit(self: *FilterResult, allocator: std.mem.Allocator) void {
        allocator.free(self.smoothed);
        allocator.free(self.derivatives);
    }
};

/// Aplica un filtro Savitzky-Golay cúbico local con ventana adaptativa.
/// Computa simultáneamente la señal suavizada (coeficiente de orden 0) y la derivada temporal analítica dy/dt (coeficiente de orden 1).
/// Utiliza ajuste de mínimos cuadrados con regularización de Tikhonov y eliminación 4x4.
pub fn localSavitzkyGolayCubic(
    allocator: std.mem.Allocator,
    time: []const f64,
    signal: []const f64,
    window_half: usize,
) !FilterResult {
    const n = signal.len;
    std.debug.assert(time.len == n);

    const smoothed = try allocator.alloc(f64, n);
    const derivatives = try allocator.alloc(f64, n);

    const isize_n: isize = @intCast(n);
    const isize_wh: isize = @intCast(window_half);

    for (0..n) |i| {
        const isize_i: isize = @intCast(i);
        var start: isize = isize_i - isize_wh;
        var end: isize = isize_i + isize_wh;

        if (start < 0) {
            end -= start;
            start = 0;
        }
        if (end >= isize_n) {
            const diff = end - (isize_n - 1);
            start -= diff;
            end = isize_n - 1;
            if (start < 0) {
                start = 0;
            }
        }

        const w_size: usize = @intCast(end - start + 1);

        // Optimización: si la ventana cabe en el stack, evitamos heap
        var h_stack: [256]f64 = undefined;
        var y_stack: [64]f64 = undefined;

        var h: []f64 = undefined;
        var y: []f64 = undefined;
        var dyn_mem: ?[]f64 = null;
        defer if (dyn_mem) |mem| allocator.free(mem);

        if (w_size <= 64) {
            h = h_stack[0 .. w_size * 4];
            y = y_stack[0 .. w_size];
        } else {
            dyn_mem = try allocator.alloc(f64, w_size * 5);
            h = dyn_mem.?[0 .. w_size * 4];
            y = dyn_mem.?[w_size * 4 .. w_size * 5];
        }

        const t_ref = time[i];
        for (0..w_size) |idx| {
            const actual_idx: usize = @intCast(start + @as(isize, @intCast(idx)));
            const dt = time[actual_idx] - t_ref;
            const dt2 = dt * dt;
            const dt3 = dt2 * dt;

            h[idx * 4 + 0] = 1.0;
            h[idx * 4 + 1] = dt;
            h[idx * 4 + 2] = dt2;
            h[idx * 4 + 3] = dt3;
            y[idx] = signal[actual_idx];
        }

        // Matriz normal H^T * H y vector H^T * y
        var hth = [_]f64{0.0} ** 16;
        var hty = [_]f64{0.0} ** 4;

        for (0..4) |r| {
            for (0..4) |c| {
                var sum: f64 = 0.0;
                for (0..w_size) |idx| {
                    sum += h[idx * 4 + r] * h[idx * 4 + c];
                }
                hth[r * 4 + c] = sum;
            }
            var sum_y: f64 = 0.0;
            for (0..w_size) |idx| {
                sum_y += h[idx * 4 + r] * y[idx];
            }
            hty[r] = sum_y;
        }

        // Regularización Tikhonov para condicionar la matriz local
        for (0..4) |r| {
            hth[r * 4 + r] += 1e-12;
        }

        if (solver4x4.solve4x4(&hth, &hty)) |coefs| {
            smoothed[i] = coefs[0];
            derivatives[i] = coefs[1];
        } else {
            smoothed[i] = signal[i];
            derivatives[i] = 0.0;
        }
    }

    return .{
        .smoothed = smoothed,
        .derivatives = derivatives,
    };
}
