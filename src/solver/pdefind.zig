// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: PDE-FIND - Descubrimiento Espacio-Temporal de Ecuaciones en Derivadas Parciales
//!
//! Descubre automáticamente leyes físicas no lineales espacio-temporales en mallas 1D+1D:
//! u_t = N(u, u_x, u_xx, u_xxx, u*u_x, ...)
//!
//! Emplea stencils de diferencias finitas de alto orden (4º orden en espacio, 2º orden en tiempo)
//! y regresión dispersa STLSQ normalizada para aislar los mecanismos físicos dominantes
//! (advección, difusión, dispersión, disipación) de ecuaciones como Burgers, KdV y Calor.

const std = @import("std");
const math = std.math;
const matrix = @import("../linalg/matrix.zig");
const snapping = @import("../symbolic/snapping.zig");
const stlsq = @import("stlsq.zig");

pub const PDE_TERMS_COUNT: usize = 16;

pub const PDE_TERM_NAMES = [PDE_TERMS_COUNT][]const u8{
    "u",
    "u^2",
    "u^3",
    "u_x",
    "u*u_x",
    "u^2*u_x",
    "u_xx",
    "u*u_xx",
    "u^2*u_xx",
    "u_xxx",
    "u*u_xxx",
    "u_xxxx",
    "u_x^2",
    "u*u_x^2",
    "u_x*u_xx",
    "1",
};

/// Configuración de la búsqueda PDE-FIND
pub const PdeFindOptions = struct {
    /// Umbral relativo de parsimonia para STLSQ (ej. 0.05 = 5% del coeficiente dominante)
    parsimony_threshold: f64 = 0.05,
    /// Iteraciones máximas de poda STLSQ
    max_stlsq_iters: usize = 10,
    /// Regularización Tikhonov Ridge en las ecuaciones normales
    ridge_alpha: f64 = 1e-8,
    /// Ajustar coeficientes a constantes físicas enteras o racionales exactas
    snap_constants: bool = true,
};

/// Término activo identificado en la EDP
pub const PdeTerm = struct {
    name: []const u8,
    coefficient: f64,
};

/// Resultado del descubrimiento de la EDP
pub const PdeFindResult = struct {
    /// Ecuación formateada en texto (ej. "u_t = -1.0000*u*u_x + 0.1000*u_xx")
    equation: []u8,
    /// Coeficientes para todos los 16 términos de la biblioteca
    coefficients: [PDE_TERMS_COUNT]f64,
    /// Lista de términos físicamente activos (no nulos)
    active_terms: []PdeTerm,
    /// Coeficiente de determinación R²
    r2_score: f64,
    /// Error cuadrático medio MSE
    mse: f64,
    /// Puntos interiores de la malla evaluados
    n_samples: usize,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *PdeFindResult) void {
        self.allocator.free(self.equation);
        self.allocator.free(self.active_terms);
    }
};

/// Descubre la EDP gobernante a partir de una matriz de datos espacio-temporales U(t, x)
/// - `U`: buffer aplanado row-major de dimensión n_t x n_x
/// - `n_t`: número de instantes temporales (mínimo 3)
/// - `n_x`: número de puntos espaciales (mínimo 5 para stencils de orden 4)
/// - `dt`: paso de tiempo uniforme > 0
/// - `dx`: paso espacial uniforme > 0
pub fn findPde(
    allocator: std.mem.Allocator,
    U: []const f64,
    n_t: usize,
    n_x: usize,
    dt: f64,
    dx: f64,
    options: PdeFindOptions,
) !PdeFindResult {
    if (n_t < 3 or n_x < 5) return error.DimensionMismatch;
    if (U.len < n_t * n_x) return error.DimensionMismatch;
    if (dt <= 0.0 or dx <= 0.0) return error.InvalidWindowSize;

    // Región interior donde los stencils de 4º orden en x y 2º orden en t están completamente definidos
    // t en [1, n_t - 2], x en [2, n_x - 3]
    const t_start: usize = 1;
    const t_end: usize = n_t - 1;
    const x_start: usize = 2;
    const x_end: usize = n_x - 2;

    const m_interior: usize = (t_end - t_start) * (x_end - x_start);
    if (m_interior == 0) return error.DimensionMismatch;

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    // 1. Asignar biblioteca de candidatos Theta (m_interior x PDE_TERMS_COUNT) y vector y (u_t)
    const Theta = try temp_alloc.alloc(f64, m_interior * PDE_TERMS_COUNT);
    const y_ut = try temp_alloc.alloc(f64, m_interior);

    const inv_2dt = 1.0 / (2.0 * dt);
    const inv_12dx = 1.0 / (12.0 * dx);
    const inv_12dx2 = 1.0 / (12.0 * dx * dx);
    const inv_2dx3 = 1.0 / (2.0 * dx * dx * dx);
    const inv_dx4 = 1.0 / (dx * dx * dx * dx);

    var sample_idx: usize = 0;
    for (t_start..t_end) |t| {
        for (x_start..x_end) |x| {
            const u = U[t * n_x + x];

            // u_t centrado 2º orden: (u(t+1, x) - u(t-1, x)) / (2*dt)
            const ut = (U[(t + 1) * n_x + x] - U[(t - 1) * n_x + x]) * inv_2dt;
            y_ut[sample_idx] = ut;

            // Stencils espaciales
            const u_p1 = U[t * n_x + (x + 1)];
            const u_m1 = U[t * n_x + (x - 1)];
            const u_p2 = U[t * n_x + (x + 2)];
            const u_m2 = U[t * n_x + (x - 2)];

            // u_x centrado 4º orden
            const ux = (-u_p2 + 8.0 * u_p1 - 8.0 * u_m1 + u_m2) * inv_12dx;

            // u_xx centrado 4º orden
            const uxx = (-u_p2 + 16.0 * u_p1 - 30.0 * u + 16.0 * u_m1 - u_m2) * inv_12dx2;

            // u_xxx centrado 2º orden
            const uxxx = (u_p2 - 2.0 * u_p1 + 2.0 * u_m1 - u_m2) * inv_2dx3;

            // u_xxxx centrado 2º orden
            const uxxxx = (u_p2 - 4.0 * u_p1 + 6.0 * u - 4.0 * u_m1 + u_m2) * inv_dx4;

            // Llenar columnas de la biblioteca Theta
            const row = sample_idx * PDE_TERMS_COUNT;
            Theta[row + 0] = u;
            Theta[row + 1] = u * u;
            Theta[row + 2] = u * u * u;
            Theta[row + 3] = ux;
            Theta[row + 4] = u * ux;
            Theta[row + 5] = u * u * ux;
            Theta[row + 6] = uxx;
            Theta[row + 7] = u * uxx;
            Theta[row + 8] = u * u * uxx;
            Theta[row + 9] = uxxx;
            Theta[row + 10] = u * uxxx;
            Theta[row + 11] = uxxxx;
            Theta[row + 12] = ux * ux;
            Theta[row + 13] = u * ux * ux;
            Theta[row + 14] = ux * uxx;
            Theta[row + 15] = 1.0;

            sample_idx += 1;
        }
    }

    // 2. Resolver mediante STLSQ con selección de modelo AIC óptimo
    const weights = try stlsq.solveAnalyticalStlsq(
        temp_alloc,
        Theta,
        y_ut,
        m_interior,
        PDE_TERMS_COUNT,
        15,
        .{
            .parsimony_threshold = options.parsimony_threshold,
            .max_stlsq_iters = options.max_stlsq_iters,
            .snap_constants = options.snap_constants,
            .noise_gate_l2 = true,
        },
    );

    var final_xi = [_]f64{0.0} ** PDE_TERMS_COUNT;
    var active_mask = [_]bool{false} ** PDE_TERMS_COUNT;
    for (0..PDE_TERMS_COUNT) |c| {
        final_xi[c] = weights[c];
        if (@abs(weights[c]) > 1e-9) {
            active_mask[c] = true;
        }
    }

    // 5. Métricas de evaluación: R² y MSE
    var ss_res: f64 = 0.0;
    var sum_y: f64 = 0.0;
    for (0..m_interior) |i| {
        var y_pred: f64 = 0.0;
        for (0..PDE_TERMS_COUNT) |c| {
            if (active_mask[c]) {
                y_pred += final_xi[c] * Theta[i * PDE_TERMS_COUNT + c];
            }
        }
        const diff = y_ut[i] - y_pred;
        ss_res += diff * diff;
        sum_y += y_ut[i];
    }
    const mean_y = sum_y / @as(f64, @floatFromInt(m_interior));
    var ss_tot: f64 = 0.0;
    for (0..m_interior) |i| {
        const d = y_ut[i] - mean_y;
        ss_tot += d * d;
    }

    const mse = ss_res / @as(f64, @floatFromInt(m_interior));
    const r2_score = if (ss_tot > 1e-15) 1.0 - (ss_res / ss_tot) else 1.0;

    // 6. Recolectar lista de términos activos
    var active_count: usize = 0;
    for (0..PDE_TERMS_COUNT) |c| {
        if (active_mask[c] and @abs(final_xi[c]) > 1e-9) active_count += 1;
    }

    const active_terms = try allocator.alloc(PdeTerm, active_count);
    var act_idx: usize = 0;
    for (0..PDE_TERMS_COUNT) |c| {
        if (active_mask[c] and @abs(final_xi[c]) > 1e-9) {
            active_terms[act_idx] = .{
                .name = PDE_TERM_NAMES[c],
                .coefficient = final_xi[c],
            };
            act_idx += 1;
        }
    }

    // 7. Formatear la ecuación como string legible
    var eq_list: std.ArrayList(u8) = .empty;
    defer eq_list.deinit(allocator);

    try eq_list.appendSlice(allocator, "u_t = ");
    if (active_count == 0) {
        try eq_list.appendSlice(allocator, "0");
    } else {
        for (active_terms, 0..) |term, i| {
            if (i > 0 and term.coefficient > 0.0) {
                try eq_list.appendSlice(allocator, " + ");
            } else if (i > 0 and term.coefficient < 0.0) {
                try eq_list.appendSlice(allocator, " - ");
            } else if (i == 0 and term.coefficient < 0.0) {
                try eq_list.appendSlice(allocator, "-");
            }

            const abs_c = @abs(term.coefficient);
            var num_buf: [64]u8 = undefined;
            if (std.mem.eql(u8, term.name, "1")) {
                const s = try std.fmt.bufPrint(&num_buf, "{d:.4}", .{abs_c});
                try eq_list.appendSlice(allocator, s);
            } else if (@abs(abs_c - 1.0) < 1e-5) {
                try eq_list.appendSlice(allocator, term.name);
            } else {
                const s = try std.fmt.bufPrint(&num_buf, "{d:.4}*", .{abs_c});
                try eq_list.appendSlice(allocator, s);
                try eq_list.appendSlice(allocator, term.name);
            }
        }
    }

    const equation_copy = try eq_list.toOwnedSlice(allocator);

    return PdeFindResult{
        .equation = equation_copy,
        .coefficients = final_xi,
        .active_terms = active_terms,
        .r2_score = r2_score,
        .mse = mse,
        .n_samples = m_interior,
        .allocator = allocator,
    };
}
