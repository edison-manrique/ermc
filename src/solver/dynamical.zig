// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const types = @import("../core/types.zig");
const SolveOptions = types.SolveOptions;
const filter = @import("../filter/savitzky_golay.zig");
const stlsq = @import("stlsq.zig");
const dictionary = @import("../symbolic/dictionary.zig");

pub const DynamicalResult = struct {
    dim_weights: [][]f64,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *DynamicalResult) void {
        for (self.dim_weights) |w| {
            self.allocator.free(w);
        }
        self.allocator.free(self.dim_weights);
    }
};

/// Resuelve e identifica las ecuaciones diferenciales de un sistema dinámico multivariable continuo dx/dt = f(x)
/// a partir de series temporales o trayectorias con ruido.
pub fn solveDynamicalSystem(
    allocator: std.mem.Allocator,
    dict: *dictionary.ExpansionDictionary,
    time: []const f64,
    trajectory: []const []const f64,
    window_half: usize,
    options: SolveOptions,
) !DynamicalResult {
    const n_samples = trajectory.len;
    if (n_samples == 0) return error.EmptyDataset;
    const n_dim = trajectory[0].len;

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    // 1. Extraer coordenadas por dimensión
    const coords = try temp_alloc.alloc([]f64, n_dim);
    for (0..n_dim) |d| {
        coords[d] = try temp_alloc.alloc(f64, n_samples);
        for (0..n_samples) |s| {
            coords[d][s] = trajectory[s][d];
        }
    }

    const clean_trajectory = try temp_alloc.alloc([]f64, n_samples);
    for (0..n_samples) |s| {
        clean_trajectory[s] = try temp_alloc.alloc(f64, n_dim);
    }

    const derivatives = try temp_alloc.alloc([]f64, n_dim);

    // 2. Filtrado y diferenciación numérica con Savitzky-Golay
    for (0..n_dim) |d| {
        const filt = try filter.localSavitzkyGolayCubic(temp_alloc, time, coords[d], window_half);
        derivatives[d] = filt.derivatives;
        for (0..n_samples) |s| {
            clean_trajectory[s][d] = filt.smoothed[s];
        }
    }

    // 3. Evaluar matriz de diseño H sobre las trayectorias limpiadas
    const n_features = dict.acts.items.len;
    const h_matrix = try temp_alloc.alloc(f64, n_samples * n_features);

    for (0..n_samples) |s| {
        dict.forward(clean_trajectory[s]);
        const offset = s * n_features;
        @memcpy(h_matrix[offset .. offset + n_features], dict.values.items);
    }

    // 4. Resolver regresión SINDy por cada dimensión
    const result_weights = try allocator.alloc([]f64, n_dim);
    errdefer {
        for (result_weights) |w| allocator.free(w);
        allocator.free(result_weights);
    }

    for (0..n_dim) |d| {
        const w = try stlsq.solveAnalyticalStlsq(
            allocator,
            h_matrix,
            derivatives[d],
            n_samples,
            n_features,
            dict.num_inputs, // Bias C index
            options,
        );
        result_weights[d] = w;
    }

    return .{
        .dim_weights = result_weights,
        .allocator = allocator,
    };
}
