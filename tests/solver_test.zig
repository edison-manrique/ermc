// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const OmniEngine = ermc.OmniEngine;
const OmniRng = ermc.core.rng.OmniRng;
const metrics = ermc.solver.metrics;
const integrator = ermc.solver.integrator;
const dmd = ermc.solver.dmd;
const chaos = ermc.solver.chaos;
const DenseMatrix = ermc.DenseMatrix;

// ===========================================================================
// SOLVER: ROBUST OUTLIER REJECTION
// ===========================================================================

test "Solver: Robust MAD outlier rejection" {
    const allocator = testing.allocator;
    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const acts = [_]ermc.Activation{.Identity};
    try engine.buildExpansionDictionary(&acts);

    var rng = OmniRng.init(555);
    var samples_data: [50][1]f64 = undefined;
    var dataset: [50]ermc.Sample = undefined;

    for (0..48) |i| {
        const x = rng.genRange(1.0, 10.0);
        samples_data[i] = [1]f64{x};
        dataset[i] = .{
            .inputs = &samples_data[i],
            .target = 5.0 * x,
        };
    }
    samples_data[48] = [1]f64{2.0};
    dataset[48] = .{ .inputs = &samples_data[48], .target = 99999.0 };
    samples_data[49] = [1]f64{3.0};
    dataset[49] = .{ .inputs = &samples_data[49], .target = -88888.0 };

    const weights = try engine.solveAnalytical(&dataset, 0.0);
    defer allocator.free(weights);

    try testing.expectApproxEqAbs(5.0, weights[0], 1e-2);
}

// ===========================================================================
// SOLVER: AUTOMATIC MODEL SELECTION
// ===========================================================================

test "Solver: Automatic Model Selection via AIC (Zero user threshold)" {
    const allocator = testing.allocator;
    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const acts = [_]ermc.Activation{ .Identity, .Sine, .Cosine, .Square, .Cube };
    try engine.buildExpansionDictionary(&acts);

    var rng = OmniRng.init(888);
    var samples_data: [150][1]f64 = undefined;
    var dataset: [150]ermc.Sample = undefined;

    for (0..150) |i| {
        const x = rng.genRange(-2.0, 2.0);
        samples_data[i] = [1]f64{x};
        dataset[i] = .{
            .inputs = &samples_data[i],
            .target = -3.0 * @sin(x) + 0.5 * (x * x * x),
        };
    }

    const weights = try engine.solveAnalytical(&dataset, 0.0);
    defer allocator.free(weights);

    const test_input = [_]f64{1.5};
    const pred = engine.predict(&test_input, weights);
    const expected = -3.0 * @sin(1.5) + 0.5 * (1.5 * 1.5 * 1.5);
    try testing.expectApproxEqAbs(expected, pred, 1e-2);
}

// ===========================================================================
// SOLVER: METRICS
// ===========================================================================

test "Metrics: R² perfect fit equals 1.0" {
    const y_true = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const y_pred = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };

    const r2_val = metrics.r2(&y_true, &y_pred);
    try testing.expectApproxEqAbs(1.0, r2_val, 1e-12);

    const mse_val = metrics.mse(&y_true, &y_pred);
    try testing.expectApproxEqAbs(0.0, mse_val, 1e-12);

    const mae_val = metrics.mae(&y_true, &y_pred);
    try testing.expectApproxEqAbs(0.0, mae_val, 1e-12);
}

test "Metrics: R² zero for mean prediction" {
    const y_true = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const y_pred = [_]f64{ 3.0, 3.0, 3.0, 3.0, 3.0 };

    const r2_val = metrics.r2(&y_true, &y_pred);
    try testing.expectApproxEqAbs(0.0, r2_val, 1e-12);
}

test "Metrics: MSE and RMSE computation" {
    const y_true = [_]f64{ 1.0, 2.0, 3.0 };
    const y_pred = [_]f64{ 1.5, 2.5, 3.5 };
    const mse_val = metrics.mse(&y_true, &y_pred);
    try testing.expectApproxEqAbs(0.25, mse_val, 1e-12);

    const rmse_val = metrics.rmse(&y_true, &y_pred);
    try testing.expectApproxEqAbs(0.5, rmse_val, 1e-12);
}

test "Metrics: activeCoefficients count" {
    const weights = [_]f64{ 0.0, 3.5, 0.0, -1.2, 0.0, 0.0, 7.0 };
    try testing.expect(metrics.activeCoefficients(&weights) == 3);
}

test "Metrics: maxAbsError" {
    const y_true = [_]f64{ 1.0, 10.0, 3.0 };
    const y_pred = [_]f64{ 1.0, 5.0, 3.0 };
    try testing.expectApproxEqAbs(5.0, metrics.maxAbsError(&y_true, &y_pred), 1e-12);
}

// ===========================================================================
// SOLVER: INTEGRATOR
// ===========================================================================

fn harmonicOscillator(_: f64, state: []const f64, dstate: []f64, _: ?*const anyopaque) void {
    dstate[0] = state[1];
    dstate[1] = -state[0];
}

test "Integrator: RK4 harmonic oscillator conserves energy" {
    const allocator = testing.allocator;

    const initial = [_]f64{ 1.0, 0.0 };
    var result = try integrator.integrateRk4(
        allocator,
        harmonicOscillator,
        &initial,
        0.0,
        2.0 * std.math.pi,
        0.01,
        null,
    );
    defer result.deinit();

    const last = result.states[result.states.len - 1];
    try testing.expectApproxEqAbs(1.0, last[0], 1e-4);
    try testing.expectApproxEqAbs(0.0, last[1], 1e-4);
}

test "Integrator: Euler converges (lower order)" {
    const allocator = testing.allocator;

    const initial = [_]f64{ 1.0, 0.0 };
    var result = try integrator.integrateEuler(
        allocator,
        harmonicOscillator,
        &initial,
        0.0,
        std.math.pi,
        0.001,
        null,
    );
    defer result.deinit();

    const last = result.states[result.states.len - 1];
    try testing.expectApproxEqAbs(-1.0, last[0], 0.05);
}

// ===========================================================================
// ENGINE: METRICS INTEGRATION
// ===========================================================================

test "Engine: computeR2 on perfect linear fit" {
    const allocator = testing.allocator;
    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const acts = [_]ermc.Activation{.Identity};
    try engine.buildExpansionDictionary(&acts);

    var samples_data: [20][1]f64 = undefined;
    var dataset: [20]ermc.Sample = undefined;
    for (0..20) |i| {
        const x: f64 = @as(f64, @floatFromInt(i)) * 0.5;
        samples_data[i] = [1]f64{x};
        dataset[i] = .{
            .inputs = &samples_data[i],
            .target = 3.0 * x + 2.0,
        };
    }

    const weights = try engine.solveAnalytical(&dataset, 0.0);
    defer allocator.free(weights);

    const r2_val = try engine.computeR2(&dataset, weights);
    try testing.expect(r2_val > 0.999);

    const active = engine.countActiveTerms(weights);
    try testing.expect(active >= 2);
}

// ===========================================================================
// DYNAMIC MODE DECOMPOSITION (DMD)
// ===========================================================================

test "DMD: Recovers pure oscillation frequency from snapshot matrix" {
    const allocator = testing.allocator;

    const omega_true: f64 = 2.5;
    const dt: f64 = 0.05;
    const n_snaps: usize = 30;

    var snaps = try DenseMatrix.init(allocator, 2, n_snaps);
    defer snaps.deinit();

    for (0..n_snaps) |j| {
        const t = @as(f64, @floatFromInt(j)) * dt;
        snaps.set(0, j, @sin(omega_true * t));
        snaps.set(1, j, @cos(omega_true * t));
    }

    var dmd_res = try dmd.computeDmd(allocator, snaps, dt, 2);
    defer dmd_res.deinit();

    try testing.expectEqual(@as(usize, 2), dmd_res.rank);

    const mode0 = dmd_res.modes[0];
    try testing.expectApproxEqAbs(omega_true, @abs(mode0.frequency_rad_s), 0.15);
    try testing.expectApproxEqAbs(0.0, mode0.growth_rate, 0.1);
}

// ===========================================================================
// DINÁMICA NO LINEAL Y CAOS (EXPONENTE DE LYAPUNOV)
// ===========================================================================

fn lorenzOde(t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void {
    _ = t;
    _ = ctx;
    const sigma: f64 = 10.0;
    const rho: f64 = 28.0;
    const beta: f64 = 8.0 / 3.0;

    const x = state[0];
    const y = state[1];
    const z = state[2];

    dstate[0] = sigma * (y - x);
    dstate[1] = x * (rho - z) - y;
    dstate[2] = x * y - beta * z;
}

fn dampedOscillatorOde(t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void {
    _ = t;
    _ = ctx;
    const gamma: f64 = 0.5;
    const omega_sq: f64 = 4.0;
    dstate[0] = state[1];
    dstate[1] = -omega_sq * state[0] - gamma * state[1];
}

test "Chaos: Lorenz 63 system has positive Lyapunov exponent (deterministic chaos)" {
    const allocator = testing.allocator;

    const init_state = [_]f64{ 1.0, 1.0, 1.0 };
    const res = try chaos.computeMaxLyapunovExponent(
        allocator,
        lorenzOde,
        &init_state,
        1e-8,
        0.05,
        250,
        0.005,
    );

    try testing.expect(res.lyapunov_exponent > 0.1);
    try testing.expectEqual(chaos.ChaosClassification.Chaotic, res.classification);
}

test "Chaos: Damped oscillator has negative Lyapunov exponent (stable fixed point)" {
    const allocator = testing.allocator;

    const init_state = [_]f64{ 2.0, 0.0 };
    const res = try chaos.computeMaxLyapunovExponent(
        allocator,
        dampedOscillatorOde,
        &init_state,
        1e-8,
        0.05,
        150,
        0.005,
    );

    try testing.expect(res.lyapunov_exponent < 0.0);
    try testing.expectEqual(chaos.ChaosClassification.StableFixedPoint, res.classification);
}
