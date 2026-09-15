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

/// [EJEMPLO 5] HIDRODINÁMICA: LEY DE TORRICELLI (VACIADO DE TANQUES)
/// Ley Física: v(h) = sqrt(2 * g * h) => ~ 4.4287*sqrt(x0)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 5] HIDRODINÁMICA: LEY DE TORRICELLI (VACIADO DE TANQUES)\n", .{});
    std.debug.print(" >> Ley Física Esperada: v(h) = sqrt(2 * g * h) => ~ 4.4287*sqrt(x0)\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    var rng = OmniRng.init(999);
    const n_samples = 300;

    var input_buffer = try allocator.alloc([1]f64, n_samples);
    defer allocator.free(input_buffer);

    var dataset = try allocator.alloc(Sample, n_samples);
    defer allocator.free(dataset);

    const g: f64 = 9.80665;
    const factor: f64 = @sqrt(2.0 * g);

    for (0..n_samples) |i| {
        const h = rng.genRange(0.1, 10.0);
        input_buffer[i] = [1]f64{h};
        const target = factor * @sqrt(h);
        dataset[i] = .{
            .inputs = &input_buffer[i],
            .target = target,
        };
    }

    var engine = try OmniEngine.init(allocator, 1);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .Sqrt, .Square };
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
