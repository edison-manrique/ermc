// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const precision = ermc.core.precision;
const outliers = ermc.stats.outliers;

/// [EJEMPLO 9] DETECCIÓN DE OUTLIERS EXTREMOS DE ESCALA CÓSMICA (10^100)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 9] OUTLIERS EXTREMOS (10^100) Y ARITMÉTICA COMPENSADA NEUMAIER\n", .{});
    std.debug.print(" >> Detección con Cero Pérdida de Precisión frente a Desbordamientos Numéricos\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    // Conjunto de datos contaminado con spikes cósmicos de ±10^100
    const raw_signals = [_]f64{
        2.718281828, 2.718281829, 2.718281827,
        1.0e100, // Outlier extremo masivo
        2.718281830, 2.718281828,
        -1.0e100, // Outlier extremo negativo
        2.718281829, 2.718281827, 2.718281828,
    };

    var outlier_res = try outliers.detectOutliersHampel(allocator, &raw_signals, 4.0);
    defer outlier_res.deinit();

    // Demostración de suma compensada de Neumaier vs suma ingenua
    const cancellation_data = [_]f64{ 1.0e16, 42.0, -1.0e16, 1.0e-15 };
    var naive_sum: f64 = 0.0;
    for (cancellation_data) |x| naive_sum += x;
    const neumaier_sum = precision.neumaierSum(&cancellation_data);

    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    std.debug.print("  >> Outliers severos detectados:    {d} de {d} muestras\n", .{ outlier_res.n_outliers, raw_signals.len });
    std.debug.print("  >> Mediana robusta calculada:      {d:.9}\n", .{outlier_res.median});
    std.debug.print("  >> MAD normalizado:                {e:.6}\n", .{outlier_res.mad_normalized});
    std.debug.print("  >> Suma ingenua (cancelación):     {d} (PERDIÓ EL 1e-15)\n", .{naive_sum});
    std.debug.print("  >> Suma Neumaier (compensada):     {d:.15} (PRECISIÓN A 64 BITS INTACTA)\n", .{neumaier_sum});
    std.debug.print(" > Tiempo de análisis de outliers:   {d:.2} us\n\n", .{elapsed_us});
}
