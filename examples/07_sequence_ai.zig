// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const SequenceAi = ermc.SequenceAi;

/// [EJEMPLO 7] IA DE SECUENCIAS MATEMÁTICAS (SERIES & GAPS)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 7] IA DE SECUENCIAS MATEMÁTICAS: IDENTIFICACIÓN DE GAPS\n", .{});
    std.debug.print(" >> Secuencia Cuadrática: p(x) = x^2 => 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const seq = [_]f64{ 0.0, 1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0, 121.0 };
    const seq_ai = SequenceAi.init();

    const start = std.Io.Clock.awake.now(io);
    const coefs = try seq_ai.fitGaps(allocator, &seq);
    defer allocator.free(coefs);

    const next_val = seq_ai.predictNext(&seq, coefs);
    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    std.debug.print(" >> Próximo valor predicho p(12): {d:.2} (Esperado exacto: 144.0)\n", .{next_val});
    std.debug.print(" > Tiempo de análisis de serie: {d:.2} us\n\n", .{elapsed_us});
}
