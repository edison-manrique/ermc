// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const outliers = ermc.stats.outliers;

// ===========================================================================
// STATS: DETECCIÓN DE OUTLIERS EXTREMOS SIN PÉRDIDA DE PRECISIÓN
// ===========================================================================

test "Outliers: Hampel detector isolates cosmic-scale spikes (10^100) with zero data corruption" {
    const allocator = testing.allocator;

    var data = [_]f64{ 1.0, 1.01, 0.99, 1.02, 1e100, 0.98, 1.0, -1e100, 1.01, 0.99 };
    var res = try outliers.detectOutliersHampel(allocator, &data, 4.5);
    defer res.deinit();

    try testing.expectEqual(@as(usize, 2), res.n_outliers);
    try testing.expect(res.is_outlier[4]); // 1e100
    try testing.expect(res.is_outlier[7]); // -1e100
    try testing.expect(!res.is_outlier[0]);
    try testing.expect(!res.is_outlier[1]);

    // Los datos no atípicos conservan exactamente su valor original a nivel de bit
    try testing.expectEqual(1.0, res.clean_data[0]);
    try testing.expectEqual(1.01, res.clean_data[1]);
    try testing.expectEqual(0.99, res.clean_data[2]);
}

test "Outliers: Generalized ESD identifies multiple sequential outliers" {
    const allocator = testing.allocator;

    const data = [_]f64{ 10.0, 10.2, 9.8, 10.1, 100.0, 9.9, 10.3, 9.7, 50.0, 10.0, 10.1, 9.9 };
    var res = try outliers.detectExtremeEsd(allocator, &data, 3, 0.05);
    defer res.deinit();

    try testing.expect(res.n_outliers >= 2);
    try testing.expect(res.is_outlier[4]); // 100.0
    try testing.expect(res.is_outlier[8]); // 50.0
}

test "Outliers: Handles perfectly constant data without division by zero" {
    const allocator = testing.allocator;

    const const_data = [_]f64{ 42.0, 42.0, 42.0, 42.0, 42.0 };
    var res = try outliers.detectOutliersHampel(allocator, &const_data, 3.0);
    defer res.deinit();

    try testing.expectEqual(@as(usize, 0), res.n_outliers);
    try testing.expectEqual(42.0, res.median);
    try testing.expectEqual(0.0, res.mad);
}
