// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const SequenceAi = ermc.SequenceAi;

// ===========================================================================
// SERIES: SEQUENCE AI
// ===========================================================================

test "Series: Sequence AI pattern identification" {
    const allocator = testing.allocator;
    const seq_ai = SequenceAi.init();

    const seq = [_]f64{ 2.0, 5.0, 8.0, 11.0, 14.0, 17.0, 20.0, 23.0, 26.0, 29.0, 32.0, 35.0 };
    const coefs = try seq_ai.fitGaps(allocator, &seq);
    defer allocator.free(coefs);

    const next_val = seq_ai.predictNext(&seq, coefs);
    try testing.expectApproxEqAbs(38.0, next_val, 1e-3);
}

test "Series: SequenceAi extended bases" {
    const allocator = testing.allocator;
    const seq_ai = SequenceAi.initExtended();

    // Secuencia cuadrática: 0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121
    const seq = [_]f64{ 0.0, 1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0, 121.0 };
    const coefs = try seq_ai.fitGaps(allocator, &seq);
    defer allocator.free(coefs);

    const next_val = seq_ai.predictNext(&seq, coefs);
    try testing.expectApproxEqAbs(144.0, next_val, 2.0);
}

test "Series: SequenceAi predictNextN multi-step" {
    const allocator = testing.allocator;
    const seq_ai = SequenceAi.init();

    // Secuencia lineal: 2, 5, 8, 11, 14, ...
    const seq = [_]f64{ 2.0, 5.0, 8.0, 11.0, 14.0, 17.0, 20.0, 23.0, 26.0, 29.0 };
    const coefs = try seq_ai.fitGaps(allocator, &seq);
    defer allocator.free(coefs);

    const predictions = try seq_ai.predictNextN(allocator, &seq, coefs, 3);
    defer allocator.free(predictions);

    try testing.expectApproxEqAbs(32.0, predictions[0], 1.0);
    try testing.expectApproxEqAbs(35.0, predictions[1], 1.0);
    try testing.expectApproxEqAbs(38.0, predictions[2], 1.0);
}

test "Series: SequenceAi geometric sequence" {
    const allocator = testing.allocator;
    const seq_ai = SequenceAi.initExtended();

    // Secuencia cúbica: 1, 8, 27, 64, 125, 216
    const seq = [_]f64{ 1.0, 8.0, 27.0, 64.0, 125.0, 216.0, 343.0, 512.0 };
    const coefs = try seq_ai.fitGaps(allocator, &seq);
    defer allocator.free(coefs);

    const next_val = seq_ai.predictNext(&seq, coefs);
    // 9^3 = 729
    try testing.expectApproxEqAbs(729.0, next_val, 5.0);
}
