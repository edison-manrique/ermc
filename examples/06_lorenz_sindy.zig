// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const math_ml = @import("math-ml");

const OmniEngine = math_ml.OmniEngine;
const Activation = math_ml.Activation;

/// [EJEMPLO 6] ATRACTOR CAÓTICO DE LORENZ: RECONSTRUCCIÓN ODE DINÁMICA (SINDy)
/// dx/dt = 10*(y - x) | dy/dt = x*(28 - z) - y | dz/dt = x*y - (8/3)*z
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 6] ATRACTOR CAÓTICO DE LORENZ: RECONSTRUCCIÓN ODE DINÁMICA\n", .{});
    std.debug.print(" >> Objetivo Teórico: dx/dt = 10*(y - x) | dy/dt = x*(28 - z) - y | dz/dt = x*y - (8/3)*z\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const n_steps = 1500;
    const dt = 0.01;

    var time = try allocator.alloc(f64, n_steps);
    defer allocator.free(time);

    var trajectory = try allocator.alloc([3]f64, n_steps);
    defer allocator.free(trajectory);

    // Integración de RK4 sintética de la trayectoria real
    var state = [3]f64{ -8.0, 8.0, 27.0 };
    for (0..n_steps) |step| {
        const t = @as(f64, @floatFromInt(step)) * dt;
        time[step] = t;
        trajectory[step] = state;

        const x = state[0];
        const y = state[1];
        const z = state[2];

        const dx1 = 10.0 * (y - x);
        const dy1 = x * (28.0 - z) - y;
        const dz1 = x * y - (8.0 / 3.0) * z;

        state[0] += dx1 * dt;
        state[1] += dy1 * dt;
        state[2] += dz1 * dt;
    }

    var traj_slices = try allocator.alloc([]const f64, n_steps);
    defer allocator.free(traj_slices);
    for (0..n_steps) |step| {
        traj_slices[step] = &trajectory[step];
    }

    var engine = try OmniEngine.init(allocator, 3);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .Square };
    try engine.buildExpansionDictionary(&dict);

    const start = std.Io.Clock.awake.now(io);
    var dyn_res = try engine.solveDynamicalSystem(
        time,
        traj_slices,
        2,
        .{ .parsimony_threshold = 0.01 },
    );
    defer dyn_res.deinit();
    const dur = start.untilNow(io, .awake);
    const elapsed_ms = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1_000_000.0;

    const labels = [_][]const u8{ "dx/dt", "dy/dt", "dz/dt" };
    for (0..3) |d| {
        const form = try engine.getReconstructedFormula(dyn_res.dim_weights[d]);
        defer allocator.free(form);
        std.debug.print("  >> {s} = {s}\n", .{ labels[d], form });
    }
    std.debug.print(" > Tiempo total de identificación dinámica (3D ODE): {d:.2} ms\n\n", .{elapsed_ms});
}
