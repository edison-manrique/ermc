// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const math_ml = @import("math-ml");

const OmniEngine = math_ml.OmniEngine;
const OmniRng = math_ml.OmniRng;
const Activation = math_ml.Activation;
const Sample = math_ml.Sample;

/// [EJEMPLO 4] TERMODINÁMICA: ADIABÁTICA DE GAS MONOATÓMICO
/// Ley Física: P(T, invV) = 1.6667*x0*x1  (Gamma: 5/3)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 4] TERMODINÁMICA: ADIABÁTICA DE GAS MONOATÓMICO\n", .{});
    std.debug.print(" >> Ley Física Esperada: P(T, invV) = 1.6667*x0*x1  (Gamma: 5/3)\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    var rng = OmniRng.init(777);
    const n_samples = 400;

    var input_buffer = try allocator.alloc([2]f64, n_samples);
    defer allocator.free(input_buffer);

    var dataset = try allocator.alloc(Sample, n_samples);
    defer allocator.free(dataset);

    for (0..n_samples) |i| {
        const temp = rng.genRange(1.0, 10.0);
        const inv_vol = rng.genRange(0.5, 3.0);
        input_buffer[i] = [2]f64{ temp, inv_vol };
        const target = (5.0 / 3.0) * temp * inv_vol;
        dataset[i] = .{
            .inputs = &input_buffer[i],
            .target = target,
        };
    }

    var engine = try OmniEngine.init(allocator, 2);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .Square };
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
