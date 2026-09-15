// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Tests estrictos para PDE-FIND: Descubrimiento de Ecuaciones en Derivadas Parciales Espacio-Temporales

const std = @import("std");
const testing = std.testing;
const math = std.math;
const ermc = @import("ermc");
const pdefind = ermc.pdefind;
const findPde = ermc.findPde;

// ============================================================================
// TEST 1: ECUACIÓN DEL CALOR / DIFUSIÓN PURA (u_t = 0.5 * u_xx)
// Solución analítica: u(t, x) = exp(-0.5 * t) * sin(x)
// ============================================================================

test "PDE-FIND - 1D Heat Equation (Diffusion discovery)" {
    const allocator = testing.allocator;

    const n_t: usize = 41;
    const n_x: usize = 81;
    const dt: f64 = 0.01;
    const x_span: f64 = 6.0;
    const dx: f64 = x_span / @as(f64, @floatFromInt(n_x - 1));

    const U = try allocator.alloc(f64, n_t * n_x);
    defer allocator.free(U);

    const alpha: f64 = 0.5;
    const t0: f64 = 1.0;

    for (0..n_t) |ti| {
        const t = @as(f64, @floatFromInt(ti)) * dt;
        const s = 4.0 * alpha * (t + t0);
        const inv_sqrt_s = 1.0 / math.sqrt(math.pi * s);

        for (0..n_x) |xi| {
            const x = -3.0 + @as(f64, @floatFromInt(xi)) * dx;
            U[ti * n_x + xi] = inv_sqrt_s * math.exp(-(x * x) / s);
        }
    }

    var result = try findPde(allocator, U, n_t, n_x, dt, dx, .{
        .parsimony_threshold = 0.05,
        .snap_constants = true,
    });
    defer result.deinit();

    // 1. Debe aislar exactamente 1 término físico dominante: u_xx
    try testing.expectEqual(@as(usize, 1), result.active_terms.len);
    try testing.expectEqualStrings("u_xx", result.active_terms[0].name);

    // 2. Coeficiente recuperado de difusión térmica = 0.5
    try testing.expectApproxEqAbs(0.5, result.active_terms[0].coefficient, 1e-3);

    // 3. Alta bondad de ajuste R² > 0.999
    try testing.expect(result.r2_score > 0.999);
    try testing.expect(result.mse < 1e-5);
}

// ============================================================================
// TEST 2: ECUACIÓN DE ADVECCIÓN-DIFUSIÓN (u_t = -1.0 * u_x + 0.25 * u_xx)
// Solución analítica paquete gaussiano en traslación y difusión:
// u(t, x) = (1 / sqrt(4*pi*D*(t + t0))) * exp(-(x - v*t)^2 / (4*D*(t + t0)))
// ============================================================================

test "PDE-FIND - Advection-Diffusion equation discovery" {
    const allocator = testing.allocator;

    const n_t: usize = 41;
    const n_x: usize = 81;
    const dt: f64 = 0.01;
    const x_span: f64 = 8.0;
    const dx: f64 = x_span / @as(f64, @floatFromInt(n_x - 1));

    const U = try allocator.alloc(f64, n_t * n_x);
    defer allocator.free(U);

    const v: f64 = 1.0;
    const D: f64 = 0.25;
    const t0: f64 = 1.0;

    for (0..n_t) |ti| {
        const t = @as(f64, @floatFromInt(ti)) * dt;
        const s = 4.0 * D * (t + t0);
        const inv_sqrt_s = 1.0 / math.sqrt(math.pi * s);

        for (0..n_x) |xi| {
            const x = -4.0 + @as(f64, @floatFromInt(xi)) * dx;
            const xi_pos = x - v * t;
            U[ti * n_x + xi] = inv_sqrt_s * math.exp(-(xi_pos * xi_pos) / s);
        }
    }

    var result = try findPde(allocator, U, n_t, n_x, dt, dx, .{
        .parsimony_threshold = 0.05,
        .snap_constants = true,
    });
    defer result.deinit();

    // Debe descubrir exactamente los 2 términos físicos: advección (-1.0*u_x) y difusión (0.25*u_xx)
    try testing.expectEqual(@as(usize, 2), result.active_terms.len);

    var found_advection = false;
    var found_diffusion = false;

    for (result.active_terms) |term| {
        if (std.mem.eql(u8, term.name, "u_x")) {
            found_advection = true;
            try testing.expectApproxEqAbs(-1.0, term.coefficient, 1e-2);
        } else if (std.mem.eql(u8, term.name, "u_xx")) {
            found_diffusion = true;
            try testing.expectApproxEqAbs(0.25, term.coefficient, 1e-2);
        }
    }

    try testing.expect(found_advection);
    try testing.expect(found_diffusion);
    try testing.expect(result.r2_score > 0.999);
}

// ============================================================================
// TEST 3: ECUACIÓN DE REACCIÓN-DIFUSIÓN (ALLEN-CAHN: u_t = 0.2 * u_xx + 1.0 * u - 1.0 * u^3)
// Sistema no lineal biestable con difusión y pozo doble simétrico
// ============================================================================

test "PDE-FIND - Reaction-Diffusion (Allen-Cahn) nonlinear discovery" {
    const allocator = testing.allocator;

    const n_t: usize = 35;
    const n_x: usize = 65;
    const dt: f64 = 0.002;
    const x_span: f64 = 6.0;
    const dx: f64 = x_span / @as(f64, @floatFromInt(n_x - 1));

    const U = try allocator.alloc(f64, n_t * n_x);
    defer allocator.free(U);

    const D: f64 = 0.2;

    // Condición inicial: paquete gaussiano perturbado
    for (0..n_x) |xi| {
        const x = -3.0 + @as(f64, @floatFromInt(xi)) * dx;
        U[0 * n_x + xi] = 0.75 * math.exp(-x * x);
    }

    // Integración temporal hacia adelante para generar la trayectoria espacio-temporal U(t, x)
    const inv_dx2 = 1.0 / (dx * dx);
    for (0..n_t - 1) |ti| {
        for (0..n_x) |xi| {
            if (xi == 0 or xi == n_x - 1) {
                U[(ti + 1) * n_x + xi] = 0.0;
                continue;
            }

            const u_curr = U[ti * n_x + xi];
            const u_xx = (U[ti * n_x + xi + 1] - 2.0 * u_curr + U[ti * n_x + xi - 1]) * inv_dx2;
            const ut = D * u_xx + 1.0 * u_curr - 1.0 * u_curr * u_curr * u_curr;
            U[(ti + 1) * n_x + xi] = u_curr + dt * ut;
        }
    }

    var result = try findPde(allocator, U, n_t, n_x, dt, dx, .{
        .parsimony_threshold = 0.05,
        .snap_constants = true,
    });
    defer result.deinit();

    // Debe aislar exactamente los 3 mecanismos físicos: u_xx (0.2), u (1.0), u^3 (-1.0)
    try testing.expectEqual(@as(usize, 3), result.active_terms.len);

    var found_diffusion = false;
    var found_linear_growth = false;
    var found_cubic_saturation = false;

    for (result.active_terms) |term| {
        if (std.mem.eql(u8, term.name, "u_xx")) {
            found_diffusion = true;
            try testing.expectApproxEqAbs(0.2, term.coefficient, 1e-2);
        } else if (std.mem.eql(u8, term.name, "u")) {
            found_linear_growth = true;
            try testing.expectApproxEqAbs(1.0, term.coefficient, 1e-2);
        } else if (std.mem.eql(u8, term.name, "u^3")) {
            found_cubic_saturation = true;
            try testing.expectApproxEqAbs(-1.0, term.coefficient, 1e-2);
        }
    }

    try testing.expect(found_diffusion);
    try testing.expect(found_linear_growth);
    try testing.expect(found_cubic_saturation);
    try testing.expect(result.r2_score > 0.999);
}

// ============================================================================
// TEST 4: VALIDACIÓN DE DIMENSIONES Y ERRORES DE MALLA
// ============================================================================

test "PDE-FIND - Error handling on invalid grid dimensions" {
    const allocator = testing.allocator;
    const dummy_data = [_]f64{ 1.0, 2.0, 3.0, 4.0 };

    // Grilla demasiado pequeña para stencils (requiere n_t >= 3, n_x >= 5)
    const err_dim = findPde(allocator, &dummy_data, 2, 2, 0.01, 0.1, .{});
    try testing.expectError(error.DimensionMismatch, err_dim);

    // dt <= 0 inválido
    const larger_data = [_]f64{0.0} ** 30;
    const err_dt = findPde(allocator, &larger_data, 5, 6, 0.0, 0.1, .{});
    try testing.expectError(error.InvalidWindowSize, err_dt);
}
