// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Integradores Simplécticos y SciML Hamiltoniano
//!
//! Implementa integradores geométricos que preservan exactamente la 2-forma simpléctica
//! y el volumen del espacio de fases (Teorema de Liouville). A diferencia de los métodos
//! estándar como Runge-Kutta que sufren de disipación o inestabilidad numérica a largo plazo,
//! los integradores simplécticos garantizan conservación de energía a nivel de máquina
//! (sin deriva secular) a lo largo de millones de pasos temporales.
//!
//! Algoritmos implementados:
//! - Verlet / Leapfrog (2º Orden)
//! - Ruth (3ᵉʳ Orden)
//! - Yoshida (4ᵗᵒ Orden)

const std = @import("std");
const math = std.math;

/// Función de Fuerza o Gradiente Negativo de Potencial: F(q) = -grad V(q)
/// Recibe el vector de posiciones `q` y escribe las fuerzas calculadas en `force`.
pub const ForceFn = *const fn (q: []const f64, force: []f64, ctx: ?*const anyopaque) void;

/// Función de Energía Potencial escalar V(q)
pub const PotentialFn = *const fn (q: []const f64, ctx: ?*const anyopaque) f64;

/// Algoritmos simplécticos disponibles
pub const SymplecticAlgorithm = enum {
    Verlet, // 2º orden (Velocity Verlet) - 1 evaluación de fuerza por paso
    Ruth3, // 3ᵉʳ orden (Ruth 1983) - 3 evaluaciones de fuerza por paso
    Yoshida4, // 4ᵗᵒ orden (Yoshida 1990) - 4 evaluaciones de fuerza por paso
};

/// Resultado detallado de una simulación simpléctica
pub const SymplecticResult = struct {
    time: []f64,
    q: [][]f64, // Coordenadas generalizadas (posiciones)
    p: [][]f64, // Momentos conjugados (velocidades * masa)
    energy: []f64, // Energía Hamiltoniana total H(q, p) = T + V
    initial_energy: f64,
    max_energy_drift: f64, // Máxima desviación relativa: max |E(t) - E_0| / |E_0|
    allocator: std.mem.Allocator,

    pub fn deinit(self: *SymplecticResult) void {
        for (self.q) |row| self.allocator.free(row);
        for (self.p) |row| self.allocator.free(row);
        self.allocator.free(self.q);
        self.allocator.free(self.p);
        self.allocator.free(self.energy);
        self.allocator.free(self.time);
    }
};

/// Calcula la energía cinética T(p) = sum(p_i^2 / (2 * m_i))
pub fn computeKineticEnergy(p: []const f64, masses: ?[]const f64) f64 {
    var ke: f64 = 0.0;
    if (masses) |m| {
        for (p, m) |pi, mi| {
            ke += (pi * pi) / (2.0 * mi);
        }
    } else {
        for (p) |pi| {
            ke += 0.5 * pi * pi;
        }
    }
    return ke;
}

/// Un único paso de integración Velocity Verlet (2º orden)
/// p_{1/2} = p_0 + dt/2 * F(q_0)
/// q_1     = q_0 + dt   * (p_{1/2} / m)
/// p_1     = p_{1/2} + dt/2 * F(q_1)
pub fn stepVerlet(
    q: []f64,
    p: []f64,
    f_force: ForceFn,
    force_buf: []f64,
    dt: f64,
    masses: ?[]const f64,
    ctx: ?*const anyopaque,
) void {
    const dim = q.len;
    const half_dt = 0.5 * dt;

    // 1. Fuerza en q_0
    f_force(q, force_buf, ctx);

    // 2. Medio paso de momento y paso completo de posición
    for (0..dim) |i| {
        p[i] += half_dt * force_buf[i];
        const m = if (masses) |m_slice| m_slice[i] else 1.0;
        q[i] += dt * (p[i] / m);
    }

    // 3. Fuerza en q_1
    f_force(q, force_buf, ctx);

    // 4. Segundo medio paso de momento
    for (0..dim) |i| {
        p[i] += half_dt * force_buf[i];
    }
}

/// Un único paso de integración simpléctica de Ruth (3ᵉʳ orden)
pub fn stepRuth3(
    q: []f64,
    p: []f64,
    f_force: ForceFn,
    force_buf: []f64,
    dt: f64,
    masses: ?[]const f64,
    ctx: ?*const anyopaque,
) void {
    const dim = q.len;
    // Coeficientes simplécticos de Ruth (1983)
    const c = [_]f64{ 7.0 / 24.0, 3.0 / 4.0, -1.0 / 24.0 };
    const d = [_]f64{ 2.0 / 3.0, -2.0 / 3.0, 1.0 };

    inline for (0..3) |stage| {
        // Actualizar posición q
        for (0..dim) |i| {
            const m = if (masses) |m_slice| m_slice[i] else 1.0;
            q[i] += c[stage] * dt * (p[i] / m);
        }

        // Evaluar fuerza y actualizar momento p
        f_force(q, force_buf, ctx);
        for (0..dim) |i| {
            p[i] += d[stage] * dt * force_buf[i];
        }
    }
}

/// Un único paso de integración simpléctica de Yoshida (4ᵗᵒ orden)
/// Composición simétrica de 4 etapas desarrollada por Haruo Yoshida (1990)
pub fn stepYoshida4(
    q: []f64,
    p: []f64,
    f_force: ForceFn,
    force_buf: []f64,
    dt: f64,
    masses: ?[]const f64,
    ctx: ?*const anyopaque,
) void {
    const dim = q.len;

    // Constante de Yoshida: 2^(1/3)
    const cbrt2 = 1.2599210498948731647672;
    const w1 = 1.0 / (2.0 - cbrt2);
    const w0 = -cbrt2 / (2.0 - cbrt2);

    const c = [_]f64{ 0.5 * w1, 0.5 * (w0 + w1), 0.5 * (w0 + w1), 0.5 * w1 };
    const d = [_]f64{ w1, w0, w1, 0.0 };

    inline for (0..4) |stage| {
        // Actualizar posición
        for (0..dim) |i| {
            const m = if (masses) |m_slice| m_slice[i] else 1.0;
            q[i] += c[stage] * dt * (p[i] / m);
        }

        if (stage < 3) {
            // Evaluar fuerza y actualizar momento
            f_force(q, force_buf, ctx);
            for (0..dim) |i| {
                p[i] += d[stage] * dt * force_buf[i];
            }
        }
    }
}

/// Ejecuta una simulación Hamiltoniana completa preservando la estructura simpléctica
pub fn integrateSymplectic(
    allocator: std.mem.Allocator,
    algorithm: SymplecticAlgorithm,
    f_force: ForceFn,
    f_potential: PotentialFn,
    initial_q: []const f64,
    initial_p: []const f64,
    t_start: f64,
    t_end: f64,
    dt: f64,
    masses: ?[]const f64,
    ctx: ?*const anyopaque,
) !SymplecticResult {
    if (initial_q.len != initial_p.len) return error.DimensionMismatch;
    if (dt <= 0.0 or t_end <= t_start) return error.DimensionMismatch;

    const dim = initial_q.len;
    const n_steps = @as(usize, @intFromFloat(@ceil((t_end - t_start) / dt))) + 1;

    var time_arr = try allocator.alloc(f64, n_steps);
    errdefer allocator.free(time_arr);

    var q_history = try allocator.alloc([]f64, n_steps);
    errdefer allocator.free(q_history);

    var p_history = try allocator.alloc([]f64, n_steps);
    errdefer allocator.free(p_history);

    var energy_arr = try allocator.alloc(f64, n_steps);
    errdefer allocator.free(energy_arr);

    const current_q = try allocator.dupe(f64, initial_q);
    defer allocator.free(current_q);

    const current_p = try allocator.dupe(f64, initial_p);
    defer allocator.free(current_p);

    const force_buf = try allocator.alloc(f64, dim);
    defer allocator.free(force_buf);

    // Energía inicial H(q_0, p_0)
    const initial_energy = computeKineticEnergy(current_p, masses) + f_potential(current_q, ctx);
    var max_drift: f64 = 0.0;

    for (0..n_steps) |step| {
        time_arr[step] = t_start + @as(f64, @floatFromInt(step)) * dt;

        q_history[step] = try allocator.dupe(f64, current_q);
        p_history[step] = try allocator.dupe(f64, current_p);

        const current_energy = computeKineticEnergy(current_p, masses) + f_potential(current_q, ctx);
        energy_arr[step] = current_energy;

        if (@abs(initial_energy) > 1e-12) {
            const drift = @abs(current_energy - initial_energy) / @abs(initial_energy);
            if (drift > max_drift) max_drift = drift;
        }

        // Avanzar un paso simpléctico
        switch (algorithm) {
            .Verlet => stepVerlet(current_q, current_p, f_force, force_buf, dt, masses, ctx),
            .Ruth3 => stepRuth3(current_q, current_p, f_force, force_buf, dt, masses, ctx),
            .Yoshida4 => stepYoshida4(current_q, current_p, f_force, force_buf, dt, masses, ctx),
        }
    }

    return SymplecticResult{
        .time = time_arr,
        .q = q_history,
        .p = p_history,
        .energy = energy_arr,
        .initial_energy = initial_energy,
        .max_energy_drift = max_drift,
        .allocator = allocator,
    };
}
