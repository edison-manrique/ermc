// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const OmniEngine = ermc.OmniEngine;
const OmniRng = ermc.OmniRng;
const Activation = ermc.Activation;
const Sample = ermc.Sample;

/// [EJEMPLO 3] ÓPTICA: LEY DE SNELL (DESCUBRIMIENTO DE FRACCIÓN 4/3)
/// Ley Física: n_agua(theta) = 1.3333*sin(x0)  (Fracción: 4/3)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 3] ÓPTICA: LEY DE SNELL (DESCUBRIMIENTO DE FRACCIÓN 4/3)\n", .{});
    std.debug.print(" >> Ley Física Esperada: n_agua(theta) = 1.3333*sin(x0)  (Fracción: 4/3)\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    var rng = OmniRng.init(2024);
    const n_samples = 300;

    var input_buffer = try allocator.alloc([1]f64, n_samples);
    defer allocator.free(input_buffer);

    var dataset = try allocator.alloc(Sample, n_samples);
    defer allocator.free(dataset);

    for (0..n_samples) |i| {
        const theta_i = rng.genRange(0.05, 1.2);
        input_buffer[i] = [1]f64{theta_i};
        const target = (4.0 / 3.0) * @sin(theta_i);
        dataset[i] = .{
            .inputs = &input_buffer[i],
            .target = target,
        };
    }

    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .Sine, .Cosine };
    try engine.buildExpansionDictionary(&dict);

    const start = std.Io.Clock.awake.now(io);
    const weights = try engine.solveAnalytical(dataset, 0.01);
    defer allocator.free(weights);
    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    const formula = try engine.getReconstructedFormula(weights);
    defer allocator.free(formula);

    std.debug.print(" >> Ecuación descubierta: f(X) = {s}\n", .{formula});
    std.debug.print(" > Tiempo de cómputo: {d:.2} us\n\n", .{elapsed_us});
}
