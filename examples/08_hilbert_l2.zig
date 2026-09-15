// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const math_ml = @import("math-ml");

const hilbert = math_ml.linalg.hilbert;

/// [EJEMPLO 8] ESPACIOS DE HILBERT Y DESCOMPOSICIÓN ORTOGONAL EN L^2
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 8] ESPACIOS DE HILBERT Y DESCOMPOSICIÓN ORTOGONAL EN L^2\n", .{});
    std.debug.print(" >> Proyección P_W(v) + v^⟂ con Ortogonalización MGS-DGKS a Precisión de Máquina\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    // 1. Generar base ortonormal de Legendre sobre grilla x ∈ [-1, 1]
    const n_grid: usize = 31;
    var grid: [n_grid]f64 = undefined;
    for (0..n_grid) |i| {
        grid[i] = -1.0 + 2.0 * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(n_grid - 1));
    }

    const polys = try hilbert.generateOrthogonalPolynomials(allocator, &grid, 4);
    defer {
        for (polys) |p| allocator.free(p);
        allocator.free(polys);
    }

    // 2. Proyección y descomposición ortogonal de un vector v en ℝ³¹
    var v: [n_grid]f64 = undefined;
    for (0..n_grid) |i| {
        const x = grid[i];
        v[i] = @exp(-x * x) + 0.5 * @sin(3.0 * std.math.pi * x);
    }

    const p_w = try allocator.alloc(f64, n_grid);
    defer allocator.free(p_w);
    const v_perp = try allocator.alloc(f64, n_grid);
    defer allocator.free(v_perp);

    const decomp = hilbert.decomposeHilbert(polys, &v, p_w, v_perp);

    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    std.debug.print("  >> Norma total ‖v‖_H:               {d:.6}\n", .{decomp.total_norm});
    std.debug.print("  >> Norma proyección ‖P_W(v)‖_H:      {d:.6}\n", .{decomp.proj_norm});
    std.debug.print("  >> Norma complemento ‖v^⟂‖_H:        {d:.6}\n", .{decomp.perp_norm});
    std.debug.print("  >> Error de ortogonalidad |⟨P, v^⟂⟩|: {e:.2} (Teorema de Pitágoras exacto)\n", .{decomp.orthogonality_error});
    std.debug.print("  >> Residuo pitagórico:               {e:.2}\n", .{decomp.pythagorean_residual});
    std.debug.print(" > Tiempo de descomposición en Hilbert: {d:.2} us\n\n", .{elapsed_us});
}
