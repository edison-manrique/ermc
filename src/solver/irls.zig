// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const qr = @import("../linalg/qr.zig");

/// Estima los pesos de robustez de las muestras utilizando M-estimador de Huber e IRLS
/// para aislar y anular la influencia de sensores rotos, ruido impulsivo y valores atípicos (outliers).
pub fn computeRobustSampleWeights(
    allocator: std.mem.Allocator,
    h_matrix: []const f64,
    y_vector: []const f64,
    sample_weights: []f64,
    n_samples: usize,
    n_features: usize,
    max_iters: usize,
    huber_tuning: f64,
) ![]f64 {
    std.debug.assert(h_matrix.len >= n_samples * n_features);
    std.debug.assert(y_vector.len >= n_samples);
    std.debug.assert(sample_weights.len >= n_samples);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    // 1. Detección previa de outliers severos basada en mediana y percentil 90
    const y_sorted = try temp_alloc.alloc(f64, n_samples);
    @memcpy(y_sorted, y_vector);
    std.mem.sort(f64, y_sorted, {}, std.sort.asc(f64));

    const mid = n_samples / 2;
    const median_y = y_sorted[mid];

    const abs_diffs = try temp_alloc.alloc(f64, n_samples);
    for (y_vector, 0..) |y, i| {
        abs_diffs[i] = @abs(y - median_y);
    }
    std.mem.sort(f64, abs_diffs, {}, std.sort.asc(f64));

    const p90_idx = (n_samples * 9) / 10;
    const p90_dev = @max(abs_diffs[p90_idx], 1e-6);
    const bound = 5.0 * p90_dev;

    for (0..n_samples) |s| {
        if (@abs(y_vector[s] - median_y) > bound) {
            sample_weights[s] = 0.0;
        } else {
            sample_weights[s] = 1.0;
        }
    }

    const weights = try allocator.alloc(f64, n_features);
    @memset(weights, 0.0);

    const residuals = try temp_alloc.alloc(f64, n_samples);

    // 2. Bucle IRLS con pérdida de Huber
    for (0..max_iters) |_| {
        const solved = try qr.solveWeightedQrPreconditioned(
            allocator,
            h_matrix,
            y_vector,
            sample_weights,
            n_samples,
            n_features,
            weights,
        );

        if (!solved) break;

        var res_sum: f64 = 0.0;
        var active_count: f64 = 0.0;

        for (0..n_samples) |s| {
            if (sample_weights[s] == 0.0) {
                residuals[s] = 0.0;
                continue;
            }
            var pred: f64 = 0.0;
            const offset = s * n_features;
            for (0..n_features) |f| {
                pred += h_matrix[offset + f] * weights[f];
            }
            const r = @abs(y_vector[s] - pred);
            residuals[s] = r;
            res_sum += r;
            active_count += 1.0;
        }

        const mean_res = res_sum / @max(active_count, 1.0);
        var dev_sum: f64 = 0.0;
        for (0..n_samples) |s| {
            if (sample_weights[s] == 0.0) continue;
            dev_sum += @abs(residuals[s] - mean_res);
        }

        const scale = @max(dev_sum / @max(active_count, 1.0), 1e-6);

        for (0..n_samples) |s| {
            if (@abs(y_vector[s] - median_y) > bound) continue;

            const r_norm = residuals[s] / scale;
            if (r_norm <= huber_tuning) {
                sample_weights[s] = 1.0;
            } else {
                sample_weights[s] = huber_tuning / r_norm;
            }
        }
    }

    return weights;
}
