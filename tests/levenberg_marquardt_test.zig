// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Tests rigurosos para el Optimizador No Lineal Levenberg-Marquardt amortiguado

const std = @import("std");
const testing = std.testing;
const math = std.math;
const ermc = @import("ermc");
const lm = ermc.lm;
const Dual = ermc.Dual;

// ============================================================================
// CASO 1: FUNCIÓN DE ROSENBROCK (VALLE DE LA BANANA)
// S(x, y) = (1 - x)^2 + 100 * (y - x^2)^2
// Residuos:
// r_0 = 1 - x
// r_1 = 10 * (y - x^2)
// ============================================================================

fn rosenbrockResiduals(params: []const f64, residuals: []f64, _: ?*const anyopaque) void {
    const x = params[0];
    const y = params[1];
    residuals[0] = 1.0 - x;
    residuals[1] = 10.0 * (y - x * x);
}

fn rosenbrockJacobian(params: []const f64, J: []f64, _: ?*const anyopaque) void {
    const x = params[0];
    // Fila 0: d r_0 / dx = -1, d r_0 / dy = 0
    J[0 * 2 + 0] = -1.0;
    J[0 * 2 + 1] = 0.0;
    // Fila 1: d r_1 / dx = -20*x, d r_1 / dy = 10
    J[1 * 2 + 0] = -20.0 * x;
    J[1 * 2 + 1] = 10.0;
}

test "Levenberg-Marquardt - Rosenbrock banana function with finite differences" {
    const allocator = testing.allocator;
    const initial_guess = [_]f64{ -1.2, 1.0 };

    var res = try lm.minimizeLm(
        allocator,
        rosenbrockResiduals,
        null, // Usar diferencias finitas automáticas
        &initial_guess,
        2,
        .{
            .max_iterations = 200,
            .initial_lambda = 1e-2,
            .tolerance_cost = 1e-13,
            .tolerance_gradient = 1e-10,
        },
        null,
    );
    defer res.deinit();

    try testing.expect(res.converged);
    try testing.expectApproxEqAbs(1.0, res.params[0], 1e-4);
    try testing.expectApproxEqAbs(1.0, res.params[1], 1e-4);
    try testing.expect(res.final_cost < 1e-8);
}

test "Levenberg-Marquardt - Rosenbrock banana function with analytical Jacobian" {
    const allocator = testing.allocator;
    const initial_guess = [_]f64{ -1.2, 1.0 };

    var res = try lm.minimizeLm(
        allocator,
        rosenbrockResiduals,
        rosenbrockJacobian, // Jacobiano analítico exacto
        &initial_guess,
        2,
        .{
            .max_iterations = 200,
            .initial_lambda = 1e-3,
            .tolerance_cost = 1e-14,
            .tolerance_gradient = 1e-12,
        },
        null,
    );
    defer res.deinit();

    try testing.expect(res.converged);
    try testing.expectApproxEqAbs(1.0, res.params[0], 1e-5);
    try testing.expectApproxEqAbs(1.0, res.params[1], 1e-5);
    try testing.expect(res.final_cost < 1e-10);
}

// ============================================================================
// CASO 2: AJUSTE DE CURVA EXPONENCIAL NO LINEAL
// y(t) = A * exp(-lambda * t)
// True params: A = 4.5, lambda = 0.65
// ============================================================================

const DecayContext = struct {
    t: []const f64,
    y: []const f64,
};

fn decayResiduals(params: []const f64, residuals: []f64, ctx_ptr: ?*const anyopaque) void {
    const ctx: *const DecayContext = @ptrCast(@alignCast(ctx_ptr.?));
    const A = params[0];
    const lam = params[1];

    for (0..ctx.t.len) |i| {
        const model_val = A * math.exp(-lam * ctx.t[i]);
        residuals[i] = model_val - ctx.y[i];
    }
}

test "Levenberg-Marquardt - Exponential Decay Parameter Estimation" {
    const allocator = testing.allocator;

    const t_data = [_]f64{ 0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0 };
    var y_data: [t_data.len]f64 = undefined;

    const true_A: f64 = 4.5;
    const true_lam: f64 = 0.65;
    for (0..t_data.len) |i| {
        y_data[i] = true_A * math.exp(-true_lam * t_data[i]);
    }

    const decay_ctx = DecayContext{
        .t = &t_data,
        .y = &y_data,
    };

    // Punto inicial distante
    const initial_guess = [_]f64{ 1.0, 0.1 };

    var res = try lm.minimizeLm(
        allocator,
        decayResiduals,
        null,
        &initial_guess,
        t_data.len,
        .{
            .max_iterations = 150,
            .initial_lambda = 1e-3,
        },
        &decay_ctx,
    );
    defer res.deinit();

    try testing.expect(res.converged);
    try testing.expectApproxEqAbs(true_A, res.params[0], 1e-4);
    try testing.expectApproxEqAbs(true_lam, res.params[1], 1e-4);
    try testing.expect(res.final_cost < 1e-12);
}

// ============================================================================
// CASO 3: AJUSTE DE OSCILADOR AMORTIGUADO (3 PARÁMETROS NO LINEALES)
// y(t) = A * exp(-gamma * t) * sin(omega * t)
// True: A = 2.5, gamma = 0.35, omega = 2.4
// ============================================================================

const OscillatorContext = struct {
    t: []const f64,
    y: []const f64,
};

fn oscResiduals(params: []const f64, residuals: []f64, ctx_ptr: ?*const anyopaque) void {
    const ctx: *const OscillatorContext = @ptrCast(@alignCast(ctx_ptr.?));
    const A = params[0];
    const gamma = params[1];
    const omega = params[2];

    for (0..ctx.t.len) |i| {
        const ti = ctx.t[i];
        const model_val = A * math.exp(-gamma * ti) * math.sin(omega * ti);
        residuals[i] = model_val - ctx.y[i];
    }
}

test "Levenberg-Marquardt - Damped Harmonic Oscillator Parameter Recovery" {
    const allocator = testing.allocator;

    var t_pts: [30]f64 = undefined;
    var y_pts: [30]f64 = undefined;
    const true_A: f64 = 2.5;
    const true_gamma: f64 = 0.35;
    const true_omega: f64 = 2.4;

    for (0..30) |i| {
        const ti = 0.1 + @as(f64, @floatFromInt(i)) * 0.15;
        t_pts[i] = ti;
        y_pts[i] = true_A * math.exp(-true_gamma * ti) * math.sin(true_omega * ti);
    }

    const osc_ctx = OscillatorContext{
        .t = &t_pts,
        .y = &y_pts,
    };

    const initial_guess = [_]f64{ 1.8, 0.5, 2.0 };

    var res = try lm.minimizeLm(
        allocator,
        oscResiduals,
        null,
        &initial_guess,
        t_pts.len,
        .{
            .max_iterations = 150,
            .initial_lambda = 1e-2,
            .tolerance_cost = 1e-12,
        },
        &osc_ctx,
    );
    defer res.deinit();

    try testing.expect(res.converged);
    try testing.expectApproxEqAbs(true_A, res.params[0], 1e-3);
    try testing.expectApproxEqAbs(true_gamma, res.params[1], 1e-3);
    try testing.expectApproxEqAbs(true_omega, res.params[2], 1e-3);
    try testing.expect(res.final_cost < 1e-9);
}

// ============================================================================
// CASO 4: JACOBIANO CON DIFERENCIACIÓN AUTOMÁTICA DUAL vs DIFERENCIAS FINITAS
// ============================================================================

fn sampleDualResidual(params: []const Dual, i: usize, _: ?*const anyopaque) Dual {
    const x = params[0];
    const y = params[1];

    if (i == 0) {
        // r_0 = x^2 + y^2 - 4.0
        return x.mul(x).add(y.mul(y)).sub(Dual.constant(4.0));
    } else if (i == 1) {
        // r_1 = x * y - 1.5
        return x.mul(y).sub(Dual.constant(1.5));
    } else {
        // r_2 = x + 2*y - 3.5
        return x.add(y.mul(Dual.constant(2.0))).sub(Dual.constant(3.5));
    }
}

fn sampleStandardResiduals(params: []const f64, residuals: []f64, _: ?*const anyopaque) void {
    const x = params[0];
    const y = params[1];
    residuals[0] = x * x + y * y - 4.0;
    residuals[1] = x * y - 1.5;
    residuals[2] = x + 2.0 * y - 3.5;
}

test "Levenberg-Marquardt - AutoDiff Dual Jacobian consistency" {
    const allocator = testing.allocator;

    const test_point = [_]f64{ 1.6, 1.1 };
    const m = 3;
    const p = 2;

    var base_residuals: [m]f64 = undefined;
    sampleStandardResiduals(&test_point, &base_residuals, null);

    const J_autodiff = try allocator.alloc(f64, m * p);
    defer allocator.free(J_autodiff);

    const J_findiff = try allocator.alloc(f64, m * p);
    defer allocator.free(J_findiff);

    try lm.computeAutoDiffJacobian(sampleDualResidual, &test_point, m, p, J_autodiff, allocator, null);
    try lm.computeFiniteDifferenceJacobian(sampleStandardResiduals, &test_point, &base_residuals, m, p, J_findiff, allocator, null);

    // Verificar correspondencia estricta entre AutoDiff Dual y Diferencias Finitas
    for (0..m * p) |idx| {
        try testing.expectApproxEqAbs(J_autodiff[idx], J_findiff[idx], 1e-5);
    }
}

// ============================================================================
// CASO 5: VALIDACIÓN DE DIMENSIONES Y ERRORES
// ============================================================================

test "Levenberg-Marquardt - Error handling on Dimension Mismatch" {
    const allocator = testing.allocator;
    const two_params = [_]f64{ 1.0, 2.0 };

    // Más parámetros (2) que residuos (1) -> sistema indeterminado no invertible
    const err = lm.minimizeLm(
        allocator,
        rosenbrockResiduals,
        null,
        &two_params,
        1,
        .{},
        null,
    );
    try testing.expectError(error.DimensionMismatch, err);
}
