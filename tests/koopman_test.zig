// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Tests estrictos para Extended Dynamic Mode Decomposition (EDMD) y Operadores de Koopman

const std = @import("std");
const testing = std.testing;
const math = std.math;
const ermc = @import("ermc");
const koopman = ermc.koopman;
const fitKoopman = ermc.fitKoopman;

// ============================================================================
// TEST 1: SISTEMA LINEAL 2D (RECUPERACIÓN EXACTA DE LA MATRIZ DINÁMICA)
// x_{k+1} = [ 0.85  -0.25 ] * x_k
//           [ 0.25   0.85 ]
// ============================================================================

test "Koopman EDMD - Exact linear dynamical system recovery" {
    const allocator = testing.allocator;
    const n_snapshots: usize = 50;
    const d: usize = 2;

    const X = try allocator.alloc(f64, n_snapshots * d);
    defer allocator.free(X);
    const Y = try allocator.alloc(f64, n_snapshots * d);
    defer allocator.free(Y);

    const a11: f64 = 0.85;
    const a12: f64 = -0.25;
    const a21: f64 = 0.25;
    const a22: f64 = 0.85;

    // Generar muestras en el plano de fases
    for (0..n_snapshots) |k| {
        const theta = @as(f64, @floatFromInt(k)) * 0.2;
        const r = 1.0 + 0.5 * math.sin(theta * 2.0);
        const x0 = r * math.cos(theta);
        const x1 = r * math.sin(theta);

        X[k * d + 0] = x0;
        X[k * d + 1] = x1;

        Y[k * d + 0] = a11 * x0 + a12 * x1;
        Y[k * d + 1] = a21 * x0 + a22 * x1;
    }

    var model = try fitKoopman(allocator, X, Y, n_snapshots, d, .{
        .basis = .StateOnly,
        .ridge_alpha = 1e-9,
    });
    defer model.deinit();

    try testing.expectEqual(@as(usize, 2), model.lifted_dim);

    // Verificar correspondencia exacta de la matriz de Koopman K con la matriz A
    try testing.expectApproxEqAbs(a11, model.K[0 * 2 + 0], 1e-4);
    try testing.expectApproxEqAbs(a12, model.K[0 * 2 + 1], 1e-4);
    try testing.expectApproxEqAbs(a21, model.K[1 * 2 + 0], 1e-4);
    try testing.expectApproxEqAbs(a22, model.K[1 * 2 + 1], 1e-4);

    // Predicción multi-paso a 10 pasos
    const x_init = [_]f64{ 1.0, 0.0 };
    const n_steps: usize = 10;
    const pred_traj = try allocator.alloc(f64, n_steps * d);
    defer allocator.free(pred_traj);

    try model.predict(&x_init, n_steps, pred_traj);

    // Simulación analítica exacta
    var true_x0: f64 = 1.0;
    var true_x1: f64 = 0.0;
    for (0..n_steps) |s| {
        try testing.expectApproxEqAbs(true_x0, pred_traj[s * d + 0], 1e-4);
        try testing.expectApproxEqAbs(true_x1, pred_traj[s * d + 1], 1e-4);

        const nx0 = a11 * true_x0 + a12 * true_x1;
        const nx1 = a21 * true_x0 + a22 * true_x1;
        true_x0 = nx0;
        true_x1 = nx1;
    }
}

// ============================================================================
// TEST 2: SISTEMA NO LINEAL CON VARIEDAD LENTA (BRUNTON ET AL. 2016)
// x_{k+1, 0} = lambda * x_{k, 0}
// x_{k+1, 1} = mu * x_{k, 1} + (lambda^2 - mu) * x_{k, 0}^2
// En el espacio levantado psi = [x0, x1, x0^2, x0*x1, x1^2, 1], la dinámica es 100% lineal!
// ============================================================================

test "Koopman EDMD - Nonlinear slow-manifold exact global linearization" {
    const allocator = testing.allocator;
    const n_snapshots: usize = 120;
    const d: usize = 2;

    const lambda: f64 = 0.8;
    const mu: f64 = 0.5;
    const coupling: f64 = lambda * lambda - mu; // 0.64 - 0.5 = 0.14

    const X = try allocator.alloc(f64, n_snapshots * d);
    defer allocator.free(X);
    const Y = try allocator.alloc(f64, n_snapshots * d);
    defer allocator.free(Y);

    var rng = std.Random.DefaultPrng.init(1337);
    const rand = rng.random();

    for (0..n_snapshots) |k| {
        const x0 = rand.float(f64) * 1.6 - 0.8;
        const x1 = rand.float(f64) * 1.6 - 0.8;

        X[k * d + 0] = x0;
        X[k * d + 1] = x1;

        Y[k * d + 0] = lambda * x0;
        Y[k * d + 1] = mu * x1 + coupling * (x0 * x0);
    }

    var model = try fitKoopman(allocator, X, Y, n_snapshots, d, .{
        .basis = .Polynomial2,
        .ridge_alpha = 1e-8,
    });
    defer model.deinit();

    // d=2 con Polynomial2 genera N = 2 + 3 + 1 = 6 observables: [x0, x1, x0^2, x0*x1, x1^2, 1]
    const N = 6;
    try testing.expectEqual(N, model.lifted_dim);

    // K[0, 0] debe ser lambda = 0.8
    try testing.expectApproxEqAbs(lambda, model.K[0 * N + 0], 1e-3);

    // K[1, 1] debe ser mu = 0.5
    try testing.expectApproxEqAbs(mu, model.K[1 * N + 1], 1e-3);

    // K[1, 2] es el acoplamiento con x0^2: (lambda^2 - mu) = 0.14
    try testing.expectApproxEqAbs(coupling, model.K[1 * N + 2], 1e-3);

    // Test de predicción a 15 pasos en régimen no lineal
    const x_init = [_]f64{ 0.65, -0.45 };
    const n_steps: usize = 15;
    const pred_traj = try allocator.alloc(f64, n_steps * d);
    defer allocator.free(pred_traj);

    try model.predict(&x_init, n_steps, pred_traj);

    var true_x0 = x_init[0];
    var true_x1 = x_init[1];
    for (0..n_steps) |s| {
        try testing.expectApproxEqAbs(true_x0, pred_traj[s * d + 0], 1e-3);
        try testing.expectApproxEqAbs(true_x1, pred_traj[s * d + 1], 1e-3);

        const nx0 = lambda * true_x0;
        const nx1 = mu * true_x1 + coupling * (true_x0 * true_x0);
        true_x0 = nx0;
        true_x1 = nx1;
    }
}

// ============================================================================
// TEST 3: VALIDACIÓN DE PARÁMETROS Y MANEJO DE ERRORES
// ============================================================================

test "Koopman EDMD - Parameter validation and dimension error handling" {
    const allocator = testing.allocator;
    const empty_slice = [_]f64{};

    const err_empty = fitKoopman(allocator, &empty_slice, &empty_slice, 0, 2, .{});
    try testing.expectError(error.EmptyDataset, err_empty);

    const dummy_x = [_]f64{ 1.0, 2.0 };
    const dummy_y = [_]f64{1.0}; // Longitud insuficiente para 1 snapshot de dim 2
    const err_dim = fitKoopman(allocator, &dummy_x, &dummy_y, 1, 2, .{});
    try testing.expectError(error.DimensionMismatch, err_dim);
}
