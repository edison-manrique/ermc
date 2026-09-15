// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const math_ml = @import("math-ml");

const filter = math_ml.filter.savitzky_golay;

// ===========================================================================
// FILTER: SAVITZKY-GOLAY
// ===========================================================================

test "Filter: Savitzky-Golay cubic derivative" {
    const allocator = testing.allocator;
    const n = 50;
    var time: [n]f64 = undefined;
    var signal: [n]f64 = undefined;
    for (0..n) |i| {
        const t: f64 = @as(f64, @floatFromInt(i)) * 0.1;
        time[i] = t;
        signal[i] = 3.0 * t * t - 4.0 * t + 5.0;
    }

    var res = try filter.localSavitzkyGolayCubic(allocator, &time, &signal, 3);
    defer res.deinit(allocator);

    for (10..40) |i| {
        const t = time[i];
        const expected_deriv = 6.0 * t - 4.0;
        try testing.expectApproxEqAbs(expected_deriv, res.derivatives[i], 1e-4);
    }
}
