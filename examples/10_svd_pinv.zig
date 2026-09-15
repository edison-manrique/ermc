// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const DenseMatrix = ermc.DenseMatrix;
const svd = ermc.linalg.svd;

/// [EJEMPLO 10] SVD: RECONSTRUCCIÓN ÓPTIMA Y PSEUDOINVERSA DE MOORE-PENROSE
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 10] DESCOMPOSICIÓN SVD Y PSEUDOINVERSA DE MOORE-PENROSE\n", .{});
    std.debug.print(" >> Algoritmo One-Sided Jacobi: A = U * Σ * Vᵀ y Rango Numérico Efectivo\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    var a = try DenseMatrix.init(allocator, 5, 3);
    defer a.deinit();

    a.set(0, 0, 1.0); a.set(0, 1, 2.0); a.set(0, 2, 3.0);
    a.set(1, 0, 2.0); a.set(1, 1, 4.0); a.set(1, 2, 6.0);
    a.set(2, 0, 3.0); a.set(2, 1, 1.0); a.set(2, 2, 2.0);
    a.set(3, 0, 4.0); a.set(3, 1, 2.0); a.set(3, 2, 1.0);
    a.set(4, 0, 5.0); a.set(4, 1, 3.0); a.set(4, 2, 4.0);

    var svd_res = try svd.computeSvd(allocator, a, 100, 1e-14);
    defer svd_res.deinit();

    const cond = svd_res.conditionNumber();
    const rank = svd_res.rank(null);

    var pinv = try svd_res.pseudoInverse(allocator);
    defer pinv.deinit();

    var a_rec = try svd_res.reconstruct(allocator);
    defer a_rec.deinit();

    var max_err: f64 = 0.0;
    for (0..5) |i| {
        for (0..3) |j| {
            const err = @abs(a.get(i, j) - a_rec.get(i, j));
            if (err > max_err) max_err = err;
        }
    }

    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    std.debug.print("  >> Valores singulares [σ₁, σ₂, σ₃]: [{d:.4}, {d:.4}, {d:.4}]\n", .{ svd_res.s[0], svd_res.s[1], svd_res.s[2] });
    std.debug.print("  >> Rango numérico efectivo:         {d} (de 3 posibles)\n", .{rank});
    std.debug.print("  >> Número de condición κ(A):        {d:.4}\n", .{cond});
    std.debug.print("  >> Error de reconstrucción ‖A - UΣVᵀ‖_max: {e:.2}\n", .{max_err});
    std.debug.print("  >> Dimensión de pseudoinversa A⁺:   {d} × {d}\n", .{ pinv.rows, pinv.cols });
    std.debug.print(" > Tiempo de descomposición SVD:      {d:.2} us\n\n", .{elapsed_us});
}
