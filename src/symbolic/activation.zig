// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const types = @import("../core/types.zig");
const Activation = types.Activation;

/// Evalúa una transformación univariada de activación de forma numéricamente segura
pub inline fn evaluateUnary(act: Activation, x: f64) f64 {
    return switch (act) {
        .Identity => x,
        .Sine => @sin(x),
        .Cosine => @cos(x),
        .Square => x * x,
        .Cube => x * x * x,
        .Exp => {
            if (x > 700.0) return @exp(700.0);
            if (x < -700.0) return 0.0;
            return @exp(x);
        },
        .ExpNeg => {
            if (-x > 700.0) return @exp(700.0);
            if (-x < -700.0) return 0.0;
            return @exp(-x);
        },
        .Sqrt => @sqrt(@abs(x)),
        .InverseSquare => {
            const sq = x * x;
            if (sq > 1e-25) {
                return 1.0 / sq;
            } else {
                return 0.0;
            }
        },
        .Inv => {
            const abs_x = @abs(x);
            if (abs_x > 1e-25) {
                return 1.0 / x;
            } else {
                return 0.0;
            }
        },
        .Ln => {
            const abs_x = @abs(x);
            if (abs_x > 1e-25) {
                return @log(abs_x);
            } else {
                return 0.0;
            }
        },
        .Tanh => std.math.tanh(x),
        .Interaction => x,
    };
}

/// Evalúa la interacción bilineal entre dos valores de nodos
pub inline fn evaluateInteraction(a: f64, b: f64) f64 {
    return a * b;
}
