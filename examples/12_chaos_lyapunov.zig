// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const math_ml = @import("math-ml");

const chaos = math_ml.solver.chaos;

fn lorenzOdeDemo(t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void {
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

/// [EJEMPLO 12] DETECCIÓN DE CAOS Y EXPONENTE DE LYAPUNOV (LORENZ 63)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 12] DETECCIÓN DE CAOS Y EXPONENTE DE LYAPUNOV (LORENZ 63)\n", .{});
    std.debug.print(" >> Medición del Efecto Mariposa y Horizonte de Predictibilidad en RK4\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    const init_state = [_]f64{ 10.0, 10.0, 25.0 };
    const chaos_res = try chaos.computeMaxLyapunovExponent(
        allocator,
        lorenzOdeDemo,
        &init_state,
        1e-8,
        0.05,
        300,
        0.005,
    );

    const dur = start.untilNow(io, .awake);
    const elapsed_ms = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1_000_000.0;

    const class_str = switch (chaos_res.classification) {
        .Chaotic => "CAÓTICO DETERMINISTA (Sensibilidad Extrema a Condiciones Iniciales)",
        .LimitCycle => "CICLO LÍMITE PERIÓDICO",
        .StableFixedPoint => "PUNTO FIJO ESTABLE",
    };

    std.debug.print("  >> Exponente de Lyapunov Máximo λ: {d:.4} s⁻¹ (Teórico Lorenz: ~0.90)\n", .{chaos_res.lyapunov_exponent});
    std.debug.print("  >> Horizonte de predictibilidad T_L: {d:.2} s (Tiempo de Lyapunov = 1/λ)\n", .{chaos_res.lyapunov_time});
    std.debug.print("  >> Diagnóstico del Atractor:        {s}\n", .{class_str});
    std.debug.print(" > Tiempo de análisis caótico (2000 RK4 steps): {d:.2} ms\n\n", .{elapsed_ms});
}
