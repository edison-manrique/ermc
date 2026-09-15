// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Analizador de Caos y Dinámica No Lineal: Exponente de Lyapunov Máximo (MLE)
//!
//! Mide la tasa exponencial de separación de dos trayectorias infinitesimalmente cercanas
//! en el espacio de fases (el "Efecto Mariposa"):
//! ‖δ(t)‖ ≈ ‖δ(0)‖ * e^(λ * t)
//!
//! Diagnóstico:
//! - λ > 0: Caos determinista (atractor extraño, ej. Atractor de Lorenz)
//! - λ ≈ 0: Ciclo límite periódico o sistema conservativo
//! - λ < 0: Punto fijo atractor estable
//!
//! Horizonte de predictibilidad (Tiempo de Lyapunov): T_L = 1 / λ

const std = @import("std");
const integrator = @import("integrator.zig");
const OdeFn = integrator.OdeFn;
const integrateRk4 = integrator.integrateRk4;
const simd = @import("../core/simd.zig");

pub const ChaosClassification = enum {
    Chaotic,       // λ > 0.05
    LimitCycle,    // -0.05 <= λ <= 0.05
    StableFixedPoint, // λ < -0.05
};

pub const ChaosAnalysisResult = struct {
    lyapunov_exponent: f64,     // Exponente de Lyapunov máximo λ (1/s)
    lyapunov_time: f64,         // Horizonte de predictibilidad T_L = 1 / λ
    classification: ChaosClassification,
    steps_evaluated: usize,
};

/// Calcula el Exponente de Lyapunov Máximo de un sistema de Ecuaciones Diferenciales
/// utilizando el método de Benettin / Wolf con renormalización periódica continua.
pub fn computeMaxLyapunovExponent(
    allocator: std.mem.Allocator,
    comptime ode_fn: OdeFn,
    initial_state: []const f64,
    delta_0: f64,       // Magnitud de perturbación inicial (ej. 1e-8)
    tau: f64,           // Intervalo entre renormalizaciones (ej. 0.05 s)
    n_iterations: usize,// Número de pasos de renormalización (ej. 500)
    dt: f64,            // Paso interno de integración RK4 (ej. 0.005 s)
) !ChaosAnalysisResult {
    const dim = initial_state.len;
    std.debug.assert(dim > 0);
    std.debug.assert(delta_0 > 0.0 and tau > 0.0 and dt > 0.0);

    const z = try allocator.alloc(f64, dim);
    defer allocator.free(z);
    @memcpy(z, initial_state);

    const z_pert = try allocator.alloc(f64, dim);
    defer allocator.free(z_pert);
    @memcpy(z_pert, initial_state);
    z_pert[0] += delta_0;

    const next_z = try allocator.alloc(f64, dim);
    defer allocator.free(next_z);
    const next_z_pert = try allocator.alloc(f64, dim);
    defer allocator.free(next_z_pert);

    // Buffers RK4 compartidos
    const k1 = try allocator.alloc(f64, dim);
    defer allocator.free(k1);
    const k2 = try allocator.alloc(f64, dim);
    defer allocator.free(k2);
    const k3 = try allocator.alloc(f64, dim);
    defer allocator.free(k3);
    const k4 = try allocator.alloc(f64, dim);
    defer allocator.free(k4);
    const temp_buf = try allocator.alloc(f64, dim);
    defer allocator.free(temp_buf);

    var sum_log_divergence: f64 = 0.0;
    const steps_per_tau = @max(@as(usize, @intFromFloat(tau / dt)), 1);
    const actual_dt = tau / @as(f64, @floatFromInt(steps_per_tau));

    var current_time: f64 = 0.0;

    // Fase 1: Calentamiento / Transitorio (descarta el colapso inicial hacia el atractor)
    const n_warmup = @max(n_iterations / 5, 20);
    for (0..n_warmup) |_| {
        for (0..steps_per_tau) |_| {
            integrator.rk4Step(ode_fn, current_time, z, actual_dt, next_z, k1, k2, k3, k4, temp_buf, null);
            @memcpy(z, next_z);
            integrator.rk4Step(ode_fn, current_time, z_pert, actual_dt, next_z_pert, k1, k2, k3, k4, temp_buf, null);
            @memcpy(z_pert, next_z_pert);
            current_time += actual_dt;
        }
        var diff_sq: f64 = 0.0;
        for (0..dim) |i| {
            const diff = z_pert[i] - z[i];
            diff_sq += diff * diff;
        }
        const d_1 = @sqrt(diff_sq);
        if (d_1 > 1e-15) {
            const scale_factor = delta_0 / d_1;
            for (0..dim) |i| {
                z_pert[i] = z[i] + (z_pert[i] - z[i]) * scale_factor;
            }
        }
    }

    // Fase 2: Medición del Exponente de Lyapunov
    for (0..n_iterations) |_| {
        // Integrar ambas trayectorias a lo largo del intervalo tau
        for (0..steps_per_tau) |_| {
            integrator.rk4Step(ode_fn, current_time, z, actual_dt, next_z, k1, k2, k3, k4, temp_buf, null);
            @memcpy(z, next_z);

            integrator.rk4Step(ode_fn, current_time, z_pert, actual_dt, next_z_pert, k1, k2, k3, k4, temp_buf, null);
            @memcpy(z_pert, next_z_pert);

            current_time += actual_dt;
        }

        // Medir separación euclidiana d_1 = ‖z_pert - z‖
        var diff_sq: f64 = 0.0;
        for (0..dim) |i| {
            const diff = z_pert[i] - z[i];
            diff_sq += diff * diff;
        }
        const d_1 = @sqrt(diff_sq);

        if (d_1 > 1e-15) {
            sum_log_divergence += @log(d_1 / delta_0);

            // Renormalización: reubicar z_pert a una distancia delta_0 en la misma dirección
            const scale_factor = delta_0 / d_1;
            for (0..dim) |i| {
                z_pert[i] = z[i] + (z_pert[i] - z[i]) * scale_factor;
            }
        }
    }

    const total_time = @as(f64, @floatFromInt(n_iterations)) * tau;
    const lambda = sum_log_divergence / total_time;
    const lyapunov_time = if (lambda > 1e-6) 1.0 / lambda else std.math.inf(f64);

    const classification: ChaosClassification = if (lambda > 0.05)
        .Chaotic
    else if (lambda < -0.05)
        .StableFixedPoint
    else
        .LimitCycle;

    return ChaosAnalysisResult{
        .lyapunov_exponent = lambda,
        .lyapunov_time = lyapunov_time,
        .classification = classification,
        .steps_evaluated = n_iterations,
    };
}
