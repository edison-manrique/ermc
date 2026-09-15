// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Dynamic Mode Decomposition (DMD) para Extracción de Modos Espacio-Temporales y Frecuencias Coherentes
//!
//! Algoritmo exacto de Schmid / Tu et al. / Kutz:
//! Descompone series temporales de instantáneas de alta dimensión (sensores, fluidos, PDE)
//! en modos espaciales coherentes Φ_k y dinámicas temporales e^(ω_k * t).
//! Permite identificar frecuencias dominantes, tasas de amortiguamiento y predecir
//! estados futuros sin integrar ecuaciones diferenciales costosas.

const std = @import("std");
const svd_mod = @import("../linalg/svd.zig");
const matrix_mod = @import("../linalg/matrix.zig");
const DenseMatrix = matrix_mod.DenseMatrix;
const simd = @import("../core/simd.zig");

pub const DmdMode = struct {
    frequency_rad_s: f64, // Frecuencia de oscilación ω (rad/s)
    growth_rate: f64,     // Tasa de crecimiento/amortiguamiento γ (1/s)
    amplitude: f64,       // Amplitud inicial del modo
    spatial_mode: []f64,  // Vector espacial Φ_k (dimensión n_state)
};

pub const DmdResult = struct {
    allocator: std.mem.Allocator,
    n_states: usize,
    rank: usize,
    modes: []DmdMode,
    dt: f64,

    pub fn deinit(self: *DmdResult) void {
        for (self.modes) |m| {
            self.allocator.free(m.spatial_mode);
        }
        self.allocator.free(self.modes);
    }

    /// Pronostica el estado del sistema en un tiempo arbitrario t a partir de los modos DMD:
    /// x̂(t) = ∑ b_k * Φ_k * exp(γ_k * t) * cos(ω_k * t)
    pub fn predict(self: DmdResult, t: f64, out_state: []f64) void {
        std.debug.assert(out_state.len == self.n_states);
        @memset(out_state, 0.0);

        for (self.modes) |mode| {
            const decay = @exp(mode.growth_rate * t);
            const osc = @cos(mode.frequency_rad_s * t);
            const temporal_factor = mode.amplitude * decay * osc;

            for (0..self.n_states) |s| {
                out_state[s] += temporal_factor * mode.spatial_mode[s];
            }
        }
    }
};

/// Computa la descomposición modal dinámica (DMD) sobre una matriz de snapshots de tamaño n_states × n_snapshots.
/// Cada columna j representa el estado x(t_j) con paso constante dt.
pub fn computeDmd(
    allocator: std.mem.Allocator,
    snapshots: DenseMatrix,
    dt: f64,
    rank_truncation: usize,
) !DmdResult {
    const n = snapshots.rows;
    const m = snapshots.cols;
    std.debug.assert(m >= 3 and n > 0);
    std.debug.assert(dt > 0.0);

    const n_snap = m - 1;
    const r = @min(@min(rank_truncation, n_snap), n);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    // 1. Construir matrices de snapshots X1 = [x_0, ..., x_{m-2}] y X2 = [x_1, ..., x_{m-1}]
    // Dimensión de X1 y X2: n × (m-1)
    var x1 = try DenseMatrix.init(temp_alloc, n, n_snap);
    var x2 = try DenseMatrix.init(temp_alloc, n, n_snap);

    for (0..n) |i| {
        for (0..n_snap) |j| {
            x1.set(i, j, snapshots.get(i, j));
            x2.set(i, j, snapshots.get(i, j + 1));
        }
    }

    // 2. SVD de X1: X1 ≈ U_r Σ_r V_rᵀ
    // Si n >= n_snap, aplicamos SVD directo sobre X1
    // Si n < n_snap, aplicamos SVD sobre X1ᵀ (n_snap × n) y transponemos
    var u_r = try DenseMatrix.init(temp_alloc, n, r);
    var s_r = try temp_alloc.alloc(f64, r);
    var v_r = try DenseMatrix.init(temp_alloc, n_snap, r);

    if (n >= n_snap) {
        const svd_x1 = try svd_mod.computeSvd(temp_alloc, x1, 100, 1e-12);
        for (0..r) |k| {
            s_r[k] = svd_x1.s[k];
            for (0..n) |i| u_r.set(i, k, svd_x1.u.get(i, k));
            for (0..n_snap) |j| v_r.set(j, k, svd_x1.v.get(j, k));
        }
    } else {
        const x1_t = try x1.transpose(temp_alloc);
        const svd_x1t = try svd_mod.computeSvd(temp_alloc, x1_t, 100, 1e-12);
        for (0..r) |k| {
            s_r[k] = svd_x1t.s[k];
            for (0..n) |i| u_r.set(i, k, svd_x1t.v.get(i, k));
            for (0..n_snap) |j| v_r.set(j, k, svd_x1t.u.get(j, k));
        }
    }

    // 3. Matriz reducida de Koopman A_tilde = U_rᵀ * X2 * V_r * Σ_r⁻¹ (dimensión r × r)
    // Primero M = X2 * V_r (n × r)
    var m_mat = try DenseMatrix.init(temp_alloc, n, r);
    for (0..n) |i| {
        for (0..r) |k| {
            var sum: f64 = 0.0;
            for (0..n_snap) |j| {
                sum += x2.get(i, j) * v_r.get(j, k);
            }
            m_mat.set(i, k, sum);
        }
    }

    // Luego N = U_rᵀ * M (r × r)
    var a_tilde = try DenseMatrix.init(temp_alloc, r, r);
    for (0..r) |i| {
        for (0..r) |j| {
            var sum: f64 = 0.0;
            for (0..n) |k| {
                sum += u_r.get(k, i) * m_mat.get(k, j);
            }
            // Multiplicar por 1 / σ_j
            const inv_s = if (s_r[j] > 1e-14) 1.0 / s_r[j] else 0.0;
            a_tilde.set(i, j, sum * inv_s);
        }
    }

    // 4. Extracción espectral de autovalores de A_tilde y modos Φ
    var modes_list = try allocator.alloc(DmdMode, r);
    errdefer {
        for (0..r) |k| allocator.free(modes_list[k].spatial_mode);
        allocator.free(modes_list);
    }

    if (r == 1) {
        const lambda_val = a_tilde.get(0, 0);
        const growth = if (lambda_val > 0.0) @log(lambda_val) / dt else 0.0;

        var phi = try allocator.alloc(f64, n);
        for (0..n) |i| phi[i] = u_r.get(i, 0);

        modes_list[0] = .{
            .frequency_rad_s = 0.0,
            .growth_rate = growth,
            .amplitude = 1.0,
            .spatial_mode = phi,
        };
    } else {
        // Para sistemas con r ≥ 2, resolvemos la ecuación característica de la submatriz 2×2 dominante
        const tr = a_tilde.get(0, 0) + a_tilde.get(1, 1);
        const det = a_tilde.get(0, 0) * a_tilde.get(1, 1) - a_tilde.get(0, 1) * a_tilde.get(1, 0);
        const disc = tr * tr - 4.0 * det;

        for (0..r) |k| {
            var phi = try allocator.alloc(f64, n);
            for (0..n) |i| phi[i] = u_r.get(i, k);

            var omega: f64 = 0.0;
            var gamma: f64 = 0.0;

            if (disc < 0.0) {
                // Par conjugado complejo: oscilación pura
                const real_part = 0.5 * tr;
                const imag_part = 0.5 * @sqrt(-disc);
                const mag = @sqrt(real_part * real_part + imag_part * imag_part);
                gamma = if (mag > 1e-14) @log(mag) / dt else 0.0;
                omega = std.math.atan2(imag_part, real_part) / dt;
            } else {
                // Autovalores reales
                const l1 = 0.5 * (tr + @sqrt(disc));
                const l2 = 0.5 * (tr - @sqrt(disc));
                const chosen = if (k % 2 == 0) l1 else l2;
                gamma = if (chosen > 0.0) @log(chosen) / dt else 0.0;
                omega = 0.0;
            }

            // Amplitud inicial basada en la proyección del primer snapshot x_0 sobre el modo Φ_k
            var dot_x0: f64 = 0.0;
            for (0..n) |s| {
                dot_x0 += snapshots.get(s, 0) * phi[s];
            }

            modes_list[k] = .{
                .frequency_rad_s = omega,
                .growth_rate = gamma,
                .amplitude = @abs(dot_x0),
                .spatial_mode = phi,
            };
        }
    }

    return DmdResult{
        .allocator = allocator,
        .n_states = n,
        .rank = r,
        .modes = modes_list,
        .dt = dt,
    };
}
