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

/// [EJEMPLO 1] PÉNDULO CON ARRASTRE DE AIRE CUADRÁTICO
/// Ley Física: f(theta, omega) = -9.8100*sin(x0) - 0.5000*x1^2
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 1] PÉNDULO CON ARRASTRE DE AIRE CUADRÁTICO\n", .{});
    std.debug.print(" >> Ley Física Esperada: f(theta, omega) = -9.8100*sin(x0) - 0.5000*x1^2\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    var rng = OmniRng.init(1337);
    const n_samples = 1000;

    var input_buffer = try allocator.alloc([2]f64, n_samples);
    defer allocator.free(input_buffer);

    var dataset = try allocator.alloc(Sample, n_samples);
    defer allocator.free(dataset);

    for (0..n_samples) |i| {
        const theta = rng.genRange(-1.5, 1.5);
        const omega = rng.genRange(0.0, 3.0);
        input_buffer[i] = [2]f64{ theta, omega };
        const target = -9.81 * @sin(theta) - 0.5 * (omega * omega);
        dataset[i] = .{
            .inputs = &input_buffer[i],
            .target = target,
        };
    }

    var engine = try OmniEngine.init(allocator, 2);
    defer engine.deinit();

    const dict = [_]Activation{ .Identity, .Sine, .Square };
    try engine.buildExpansionDictionary(&dict);

    const start = std.Io.Clock.awake.now(io);
    const weights = try engine.solveAnalytical(dataset, 0.02);
    defer allocator.free(weights);
    const dur = start.untilNow(io, .awake);
    const elapsed_us = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1000.0;

    const formula = try engine.getReconstructedFormula(weights);
    defer allocator.free(formula);

    std.debug.print(" >> Ecuación descubierta: f(X) = {s}\n", .{formula});
    std.debug.print(" > Tiempo de cómputo: {d:.2} us | Nodos topológicos: {d}\n\n", .{ elapsed_us, engine.termCount() });
}
