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

/// [EJEMPLO 2] SENSOR CON DECAIMIENTO EXPONENCIAL Y RUIDO GAUSSIANO
/// Ley Física: f(T) = 15.0000 - 0.8000*x0 + 2.4000*exp(-x0)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 2] SENSOR CON DECAIMIENTO EXPONENCIAL Y RUIDO GAUSSIANO\n", .{});
    std.debug.print(" >> Ley Física Esperada: f(T) = 15.0000 - 0.8000*x0 + 2.4000*exp(-x0)\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    var rng = OmniRng.init(42);
    const n_samples = 500;

    var input_buffer = try allocator.alloc([1]f64, n_samples);
    defer allocator.free(input_buffer);

    var dataset = try allocator.alloc(Sample, n_samples);
    defer allocator.free(dataset);

    for (0..n_samples) |i| {
        const t = rng.genRange(0.0, 5.0);
        input_buffer[i] = [1]f64{t};
        const noise = rng.genGaussian(0.0, 0.05);
        const target = 15.0 - 0.8 * t + 2.4 * @exp(-t) + noise;
        dataset[i] = .{
            .inputs = &input_buffer[i],
            .target = target,
        };
    }

    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .ExpNeg, .Square };
    try engine.buildExpansionDictionary(&dict);

    const start = std.Io.Clock.awake.now(io);
    const weights = try engine.solveAnalytical(dataset, 0.05);
    defer allocator.free(weights);
    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    const formula = try engine.getReconstructedFormula(weights);
    defer allocator.free(formula);

    std.debug.print(" >> Ecuación descubierta: f(X) = {s}\n", .{formula});
    std.debug.print(" > Ruido Gaussiano (sigma): 0.05 | Tiempo de cómputo: {d:.2} us\n\n", .{elapsed_us});
}
