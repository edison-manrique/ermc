// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const DenseMatrix = ermc.DenseMatrix;
const dmd = ermc.solver.dmd;

/// [EJEMPLO 11] DYNAMIC MODE DECOMPOSITION (DMD): MODOS COHERENTES
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 11] DYNAMIC MODE DECOMPOSITION (DMD): DINÁMICA ESPACIO-TEMPORAL\n", .{});
    std.debug.print(" >> Extracción de Frecuencias Puras y Modos Espaciales Coherentes\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    const omega_real = std.math.pi;
    const dt: f64 = 0.05;
    const n_snaps: usize = 40;
    const n_sensors: usize = 4;

    var snapshots = try DenseMatrix.init(allocator, n_sensors, n_snaps);
    defer snapshots.deinit();

    for (0..n_snaps) |col| {
        const t = @as(f64, @floatFromInt(col)) * dt;
        for (0..n_sensors) |row| {
            const spatial_phase = @as(f64, @floatFromInt(row)) * 0.5;
            snapshots.set(row, col, @cos(omega_real * t + spatial_phase));
        }
    }

    var dmd_res = try dmd.computeDmd(allocator, snapshots, dt, 2);
    defer dmd_res.deinit();

    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    std.debug.print("  >> Frecuencia real simulada:       {d:.4} rad/s\n", .{omega_real});
    std.debug.print("  >> Frecuencia DMD descubierta:     {d:.4} rad/s\n", .{@abs(dmd_res.modes[0].frequency_rad_s)});
    std.debug.print("  >> Tasa de crecimiento γ:          {d:.4} (Sistema conservativo)\n", .{dmd_res.modes[0].growth_rate});
    std.debug.print("  >> Modos espaciales identificados: {d}\n", .{dmd_res.modes.len});
    std.debug.print(" > Tiempo de análisis DMD:           {d:.2} us\n\n", .{elapsed_us});
}
