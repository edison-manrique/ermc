// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const OmniRng = ermc.core.rng.OmniRng;
const simd = ermc.core.simd;
const precision = ermc.core.precision;

// ===========================================================================
// CORE: RNG
// ===========================================================================

test "Core: OmniRng determinism and range" {
    var rng = OmniRng.init(42);
    for (0..100) |_| {
        const val = rng.nextF64();
        try testing.expect(val >= 0.0 and val < 1.0);
    }

    const r = rng.genRange(-5.0, 10.0);
    try testing.expect(r >= -5.0 and r <= 10.0);

    const g = rng.genGaussian(0.0, 1.0);
    try testing.expect(!std.math.isNan(g));
}

test "Core: OmniRng nextU64 produces non-zero values" {
    var rng = OmniRng.init(123);
    var has_nonzero = false;
    for (0..50) |_| {
        const val = rng.nextU64();
        if (val != 0) has_nonzero = true;
    }
    try testing.expect(has_nonzero);
}

test "Core: OmniRng Box-Muller cache doubles throughput" {
    var rng = OmniRng.init(99);

    const g1 = rng.genGaussian(0.0, 1.0);
    try testing.expect(rng.has_cached);

    const g2 = rng.genGaussian(0.0, 1.0);
    try testing.expect(!rng.has_cached);

    try testing.expect(!std.math.isNan(g1));
    try testing.expect(!std.math.isNan(g2));
    try testing.expect(g1 != g2);
}

test "Core: OmniRng shuffle produces permutation" {
    var rng = OmniRng.init(42);
    var data = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
    const original = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };

    rng.shuffle(&data);

    var sum_orig: f64 = 0.0;
    var sum_shuf: f64 = 0.0;
    for (0..8) |i| {
        sum_orig += original[i];
        sum_shuf += data[i];
    }
    try testing.expectApproxEqAbs(sum_orig, sum_shuf, 1e-12);
}

test "Core: OmniRng fillGaussian batch" {
    var rng = OmniRng.init(77);
    var buf: [100]f64 = undefined;
    rng.fillGaussian(&buf, 5.0, 2.0);

    var sum: f64 = 0.0;
    for (buf) |v| sum += v;
    const mean = sum / 100.0;
    try testing.expect(@abs(mean - 5.0) < 2.0);
}

// ===========================================================================
// CORE: SIMD
// ===========================================================================

test "Core: SIMD dotProduct and operations" {
    const a = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const b = [_]f64{ 2.0, 0.5, 1.0, -1.0, 2.0 };
    const dot = simd.dotProduct(&a, &b);
    try testing.expectApproxEqAbs(12.0, dot, 1e-12);

    const norm = simd.normL2(&a);
    try testing.expectApproxEqAbs(@sqrt(55.0), norm, 1e-12);
}

// ===========================================================================
// CORE: ARITMÉTICA COMPENSADA Y PRECISIÓN NUMÉRICA
// ===========================================================================

test "Precision: Neumaier Sum preserves machine epsilon against catastrophic cancellation" {
    const data = [_]f64{ 1e16, 1.0, -1e16, 1e-16 };
    const neumaier_result = precision.neumaierSum(&data);
    try testing.expectApproxEqAbs(1.0 + 1e-16, neumaier_result, 1e-16);
}

test "Precision: Compensated Mean and Variance prevent catastrophic cancellation" {
    const shifted = [_]f64{ 1e9 + 1.0, 1e9 + 2.0, 1e9 + 3.0 };
    const stats = precision.compensatedMeanVar(&shifted);

    try testing.expectApproxEqAbs(1e9 + 2.0, stats.mean, 1e-10);
    try testing.expectApproxEqAbs(1.0, stats.variance, 1e-10);
    try testing.expectApproxEqAbs(1.0, stats.std_dev, 1e-10);
}

test "Precision: SafeNorm handles extreme values without overflow (10^200)" {
    const extreme_vec = [_]f64{ 3.0e200, 4.0e200 };
    const norm_val = precision.safeNorm(&extreme_vec);

    try testing.expect(!std.math.isInf(norm_val));
    try testing.expect(!std.math.isNan(norm_val));
    try testing.expectApproxEqRel(5.0e200, norm_val, 1e-14);
}
