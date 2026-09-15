// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Tipo de función de estado para un sistema de ecuaciones diferenciales ordinarias.
/// Recibe el tiempo actual `t`, el vector de estado `state`, y escribe las derivadas en `dstate`.
pub const OdeFn = *const fn (t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void;

/// Resultado de una integración numérica ODE
pub const IntegrationResult = struct {
    time: []f64,
    states: [][]f64,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *IntegrationResult) void {
        for (self.states) |s| self.allocator.free(s);
        self.allocator.free(self.states);
        self.allocator.free(self.time);
    }
};

/// Integrador numérico de 4to orden Runge-Kutta (RK4) para sistemas ODE genéricos.
///
/// Proporciona alta precisión (error local O(h^5), error global O(h^4)) con costo computacional
/// moderado: 4 evaluaciones de la función de estado por paso.
///
/// ## Ejemplo de uso
/// ```zig
/// fn lorenz(t: f64, s: []const f64, ds: []f64, _: ?*const anyopaque) void {
///     ds[0] = 10.0 * (s[1] - s[0]);
///     ds[1] = s[0] * (28.0 - s[2]) - s[1];
///     ds[2] = s[0] * s[1] - (8.0/3.0) * s[2];
/// }
///
/// var result = try integrateRk4(alloc, lorenz, &[_]f64{1,1,1}, 0.0, 10.0, 0.01, null);
/// defer result.deinit();
/// ```
pub fn integrateRk4(
    allocator: std.mem.Allocator,
    f: OdeFn,
    initial_state: []const f64,
    t_start: f64,
    t_end: f64,
    dt: f64,
    ctx: ?*const anyopaque,
) !IntegrationResult {
    const n_dim = initial_state.len;
    std.debug.assert(dt > 0.0);
    std.debug.assert(t_end > t_start);

    const n_steps: usize = @intFromFloat(@ceil((t_end - t_start) / dt));
    const total_points = n_steps + 1;

    const time = try allocator.alloc(f64, total_points);
    errdefer allocator.free(time);

    const states = try allocator.alloc([]f64, total_points);
    errdefer {
        for (states) |s| allocator.free(s);
        allocator.free(states);
    }

    // Buffers temporales RK4 (k1, k2, k3, k4, state_temp)
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    const k1 = try temp_alloc.alloc(f64, n_dim);
    const k2 = try temp_alloc.alloc(f64, n_dim);
    const k3 = try temp_alloc.alloc(f64, n_dim);
    const k4 = try temp_alloc.alloc(f64, n_dim);
    const state_temp = try temp_alloc.alloc(f64, n_dim);

    // Estado inicial
    states[0] = try allocator.alloc(f64, n_dim);
    @memcpy(states[0], initial_state);
    time[0] = t_start;

    for (1..total_points) |step| {
        const t = t_start + @as(f64, @floatFromInt(step - 1)) * dt;
        const h = @min(dt, t_end - t);
        const prev = states[step - 1];

        // k1 = f(t, y)
        f(t, prev, k1, ctx);

        // k2 = f(t + h/2, y + h/2 * k1)
        for (0..n_dim) |i| state_temp[i] = prev[i] + 0.5 * h * k1[i];
        f(t + 0.5 * h, state_temp, k2, ctx);

        // k3 = f(t + h/2, y + h/2 * k2)
        for (0..n_dim) |i| state_temp[i] = prev[i] + 0.5 * h * k2[i];
        f(t + 0.5 * h, state_temp, k3, ctx);

        // k4 = f(t + h, y + h * k3)
        for (0..n_dim) |i| state_temp[i] = prev[i] + h * k3[i];
        f(t + h, state_temp, k4, ctx);

        // y_{n+1} = y_n + (h/6) * (k1 + 2*k2 + 2*k3 + k4)
        states[step] = try allocator.alloc(f64, n_dim);
        for (0..n_dim) |i| {
            states[step][i] = prev[i] + (h / 6.0) * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]);
        }
        time[step] = t + h;
    }

    return .{
        .time = time,
        .states = states,
        .allocator = allocator,
    };
}

/// Ejecuta un único paso de integración RK4 en el punto (t, y) con tamaño de paso h.
/// Escribe el siguiente estado en `out_next` utilizando los buffers temporales provistos.
pub fn rk4Step(
    f: OdeFn,
    t: f64,
    y: []const f64,
    h: f64,
    out_next: []f64,
    k1: []f64,
    k2: []f64,
    k3: []f64,
    k4: []f64,
    temp: []f64,
    ctx: ?*const anyopaque,
) void {
    const n = y.len;
    // k1 = f(t, y)
    f(t, y, k1, ctx);

    // k2 = f(t + h/2, y + h/2 * k1)
    for (0..n) |i| temp[i] = y[i] + 0.5 * h * k1[i];
    f(t + 0.5 * h, temp, k2, ctx);

    // k3 = f(t + h/2, y + h/2 * k2)
    for (0..n) |i| temp[i] = y[i] + 0.5 * h * k2[i];
    f(t + 0.5 * h, temp, k3, ctx);

    // k4 = f(t + h, y + h * k3)
    for (0..n) |i| temp[i] = y[i] + h * k3[i];
    f(t + h, temp, k4, ctx);

    // out_next = y + (h/6) * (k1 + 2*k2 + 2*k3 + k4)
    for (0..n) |i| {
        out_next[i] = y[i] + (h / 6.0) * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]);
    }
}

/// Integrador numérico de Euler Explícito (1er orden) para sistemas ODE.
///
/// Es el método más simple (error local O(h²), error global O(h)),
/// útil para prototipar o cuando el costo computacional debe ser mínimo.
pub fn integrateEuler(
    allocator: std.mem.Allocator,
    f: OdeFn,
    initial_state: []const f64,
    t_start: f64,
    t_end: f64,
    dt: f64,
    ctx: ?*const anyopaque,
) !IntegrationResult {
    const n_dim = initial_state.len;
    std.debug.assert(dt > 0.0);
    std.debug.assert(t_end > t_start);

    const n_steps: usize = @intFromFloat(@ceil((t_end - t_start) / dt));
    const total_points = n_steps + 1;

    const time = try allocator.alloc(f64, total_points);
    errdefer allocator.free(time);

    const states = try allocator.alloc([]f64, total_points);
    errdefer {
        for (states) |s| allocator.free(s);
        allocator.free(states);
    }

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const deriv = try arena.allocator().alloc(f64, n_dim);

    states[0] = try allocator.alloc(f64, n_dim);
    @memcpy(states[0], initial_state);
    time[0] = t_start;

    for (1..total_points) |step| {
        const t = t_start + @as(f64, @floatFromInt(step - 1)) * dt;
        const h = @min(dt, t_end - t);
        const prev = states[step - 1];

        f(t, prev, deriv, ctx);

        states[step] = try allocator.alloc(f64, n_dim);
        for (0..n_dim) |i| {
            states[step][i] = prev[i] + h * deriv[i];
        }
        time[step] = t + h;
    }

    return .{
        .time = time,
        .states = states,
        .allocator = allocator,
    };
}
