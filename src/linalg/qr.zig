// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Solucionador de mínimos cuadrados ponderados mediante descomposición QR precondicionada por norma de columna.
/// Garantiza ultra-alta estabilidad numérica frente a bases polinomiales y exponenciales de alto grado.
pub fn solveWeightedQrPreconditioned(
    allocator: std.mem.Allocator,
    h: []const f64,
    y: []const f64,
    weights: []const f64,
    m: usize,
    n: usize,
    out_x: []f64,
) !bool {
    std.debug.assert(h.len >= m * n);
    std.debug.assert(y.len >= m);
    std.debug.assert(weights.len >= m);
    std.debug.assert(out_x.len >= n);

    if (m == 0 or n == 0) return false;

    // Buffer temporal de memoria
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    const col_norms = try temp_alloc.alloc(f64, n);
    const q_matrix = try temp_alloc.alloc(f64, m * n);
    const b_vec = try temp_alloc.alloc(f64, m);
    const r_matrix = try temp_alloc.alloc(f64, n * n);
    @memset(r_matrix, 0.0);
    const qty = try temp_alloc.alloc(f64, n);
    const x_norm = try temp_alloc.alloc(f64, n);

    // 1. Ponderar datos y calcular normas de columnas iniciales
    for (0..n) |j| {
        var sumsq: f64 = 0.0;
        for (0..m) |i| {
            const w_factor = @sqrt(weights[i]);
            const val = h[i * n + j] * w_factor;
            q_matrix[i * n + j] = val;
            sumsq += val * val;
        }
        col_norms[j] = @sqrt(sumsq);
    }

    // 2. Precondicionamiento: normalizar columnas de Q
    for (0..n) |j| {
        const norm = col_norms[j];
        if (norm > 1e-25) {
            const inv_norm = 1.0 / norm;
            for (0..m) |i| {
                q_matrix[i * n + j] *= inv_norm;
            }
        } else {
            for (0..m) |i| {
                q_matrix[i * n + j] = 0.0;
            }
        }
    }

    // 3. Ponderar vector objetivo
    for (0..m) |i| {
        b_vec[i] = y[i] * @sqrt(weights[i]);
    }

    // 4. Gram-Schmidt Modificado (Factorización QR)
    for (0..n) |i| {
        var norm_sq: f64 = 0.0;
        for (0..m) |s| {
            const q_val = q_matrix[s * n + i];
            norm_sq += q_val * q_val;
        }
        const norm = @sqrt(norm_sq);

        // Si el índice supera el número de muestras m, el rango máximo se ha alcanzado
        if (i >= m or norm < 1e-10) {
            r_matrix[i * n + i] = 0.0;
            for (0..m) |s| {
                q_matrix[s * n + i] = 0.0;
            }
        } else {
            r_matrix[i * n + i] = norm;
            const inv_norm = 1.0 / norm;
            for (0..m) |s| {
                q_matrix[s * n + i] *= inv_norm;
            }

            var j = i + 1;
            while (j < n) : (j += 1) {
                var dot: f64 = 0.0;
                for (0..m) |s| {
                    dot += q_matrix[s * n + i] * q_matrix[s * n + j];
                }
                r_matrix[i * n + j] = dot;
                for (0..m) |s| {
                    q_matrix[s * n + j] -= dot * q_matrix[s * n + i];
                }
            }
        }
    }

    // 5. Proyección Q^T * b
    for (0..n) |i| {
        var sum: f64 = 0.0;
        for (0..m) |s| {
            sum += q_matrix[s * n + i] * b_vec[s];
        }
        qty[i] = sum;
    }

    // 6. Retro-sustitución sobre R * x_norm = Q^T * b
    var k: usize = n;
    while (k > 0) {
        k -= 1;
        const r_diag = r_matrix[k * n + k];
        if (@abs(r_diag) < 1e-10) {
            x_norm[k] = 0.0;
        } else {
            var sum: f64 = 0.0;
            var j = k + 1;
            while (j < n) : (j += 1) {
                sum += r_matrix[k * n + j] * x_norm[j];
            }
            x_norm[k] = (qty[k] - sum) / r_diag;
        }
    }

    // 7. Desnormalizar solución mediante las normas de columna
    for (0..n) |j| {
        const norm = col_norms[j];
        if (norm > 1e-25) {
            out_x[j] = x_norm[j] / norm;
        } else {
            out_x[j] = 0.0;
        }
    }

    return true;
}
