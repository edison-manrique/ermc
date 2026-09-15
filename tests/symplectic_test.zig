// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Tests estrictos para Integradores Simplécticos y SciML Hamiltoniano

const std = @import("std");
const testing = std.testing;
const math = std.math;
const ermc = @import("ermc");
const symplectic = ermc.symplectic;

// ============================================================================
// SISTEMA 1: OSCILADOR ARMÓNICO SIMPLE (H = 0.5*p^2 + 0.5*k*q^2)
// ============================================================================

fn harmonicForce(q: []const f64, force: []f64, _: ?*const anyopaque) void {
    const k: f64 = 1.0;
    force[0] = -k * q[0];
}

fn harmonicPotential(q: []const f64, _: ?*const anyopaque) f64 {
    const k: f64 = 1.0;
    return 0.5 * k * q[0] * q[0];
}

test "Harmonic Oscillator - Energy Conservation in Verlet and Yoshida4" {
    const allocator = testing.allocator;
    const q0 = [_]f64{1.0};
    const p0 = [_]f64{0.0};
    const dt = 0.02;
    const t_end = 40.0; // ~6.3 periodos completos (2000 pasos)

    // 1. Velocity Verlet (2º orden)
    var res_verlet = try symplectic.integrateSymplectic(
        allocator,
        .Verlet,
        harmonicForce,
        harmonicPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        dt,
        null,
        null,
    );
    defer res_verlet.deinit();

    // En Verlet, la energía oscila en una banda estrecha O(dt^2) sin deriva secular
    try testing.expect(res_verlet.max_energy_drift < 5e-4);

    // 2. Yoshida4 (4º orden)
    var res_yoshida = try symplectic.integrateSymplectic(
        allocator,
        .Yoshida4,
        harmonicForce,
        harmonicPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        dt,
        null,
        null,
    );
    defer res_yoshida.deinit();

    // En Yoshida4, la conservación es ultra-precisa O(dt^4)
    try testing.expect(res_yoshida.max_energy_drift < 1e-7);

    // Yoshida4 debe ser órdenes de magnitud más preciso que Verlet
    try testing.expect(res_yoshida.max_energy_drift < res_verlet.max_energy_drift * 1e-3);
}

// ============================================================================
// SISTEMA 2: PÉNDULO NO LINEAL (H = 0.5*p^2 - cos(q))
// ============================================================================

fn pendulumForce(q: []const f64, force: []f64, _: ?*const anyopaque) void {
    force[0] = -math.sin(q[0]);
}

fn pendulumPotential(q: []const f64, _: ?*const anyopaque) f64 {
    return -math.cos(q[0]);
}

test "Nonlinear Pendulum - Large Amplitude Hamiltonian Invariance" {
    const allocator = testing.allocator;
    // Gran amplitud inicial: 1.5 rad (~86 grados, régimen altamente no lineal)
    const q0 = [_]f64{1.5};
    const p0 = [_]f64{0.0};
    const dt = 0.01;
    const t_end = 25.0;

    var res = try symplectic.integrateSymplectic(
        allocator,
        .Yoshida4,
        pendulumForce,
        pendulumPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        dt,
        null,
        null,
    );
    defer res.deinit();

    // Verificación estricta de invariante adiabático / energía total
    try testing.expect(res.max_energy_drift < 1e-7);

    // La energía inicial debe ser exacta
    const expected_e0 = -math.cos(1.5);
    try testing.expectApproxEqAbs(expected_e0, res.initial_energy, 1e-14);
}

// ============================================================================
// SISTEMA 3: PROBLEMA DE KEPLER 2D (ÓRBITA GRAVITACIONAL ELÍPTICA)
// ============================================================================

fn keplerForce(q: []const f64, force: []f64, _: ?*const anyopaque) void {
    const r2 = q[0] * q[0] + q[1] * q[1];
    const r3 = r2 * math.sqrt(r2);
    force[0] = -q[0] / r3;
    force[1] = -q[1] / r3;
}

fn keplerPotential(q: []const f64, _: ?*const anyopaque) f64 {
    const r = math.sqrt(q[0] * q[0] + q[1] * q[1]);
    return -1.0 / r;
}

test "Kepler 2D Orbit - Energy and Angular Momentum Preservation" {
    const allocator = testing.allocator;

    // Condiciones iniciales para órbita elíptica con excentricidad e = 0.5:
    // q = (1 - e, 0) = (0.5, 0)
    // p = (0, sqrt((1 + e)/(1 - e))) = (0, sqrt(3)) ~ (0, 1.7320508)
    const e = 0.5;
    const q0 = [_]f64{ 1.0 - e, 0.0 };
    const p0 = [_]f64{ 0.0, math.sqrt((1.0 + e) / (1.0 - e)) };
    const dt = 0.005;
    const t_end = 15.0; // ~2.4 órbitas completas

    var res = try symplectic.integrateSymplectic(
        allocator,
        .Yoshida4,
        keplerForce,
        keplerPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        dt,
        null,
        null,
    );
    defer res.deinit();

    // 1. Conservación de energía en órbita gravitacional
    try testing.expect(res.max_energy_drift < 2e-5);

    // 2. Conservación estricta de Momento Angular L = q_x * p_y - q_y * p_x
    const l0 = q0[0] * p0[1] - q0[1] * p0[0];
    for (res.q, res.p) |qt, pt| {
        const lt = qt[0] * pt[1] - qt[1] * pt[0];
        try testing.expectApproxEqAbs(l0, lt, 1e-12);
    }
}

test "Ruth3 Order of Accuracy Scaling" {
    const allocator = testing.allocator;
    const q0 = [_]f64{1.0};
    const p0 = [_]f64{0.0};
    const t_end = 10.0;

    // Prueba con dt = 0.04
    var res_coarse = try symplectic.integrateSymplectic(
        allocator,
        .Ruth3,
        harmonicForce,
        harmonicPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        0.04,
        null,
        null,
    );
    defer res_coarse.deinit();

    // Prueba con dt = 0.02 (la mitad del paso)
    var res_fine = try symplectic.integrateSymplectic(
        allocator,
        .Ruth3,
        harmonicForce,
        harmonicPotential,
        &q0,
        &p0,
        0.0,
        t_end,
        0.02,
        null,
        null,
    );
    defer res_fine.deinit();

    // Para método de orden 3, al reducir dt a la mitad el error debe reducirse aproximadamente por 2^3 = 8
    try testing.expect(res_fine.max_energy_drift < res_coarse.max_energy_drift * 0.2);
}
