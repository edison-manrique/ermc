// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const snapping = ermc.symbolic.snapping;
const dictionary = ermc.symbolic.dictionary;
const activation = ermc.symbolic.activation;
const formatter = ermc.symbolic.formatter;

// ===========================================================================
// SYMBOLIC: ACTIVATIONS
// ===========================================================================

test "Symbolic: New activations Cube, Inv, Tanh (v6)" {
    const cube_val = activation.evaluateUnary(.Cube, 3.0);
    try testing.expectApproxEqAbs(27.0, cube_val, 1e-12);

    const inv_val = activation.evaluateUnary(.Inv, 4.0);
    try testing.expectApproxEqAbs(0.25, inv_val, 1e-12);

    const inv_zero = activation.evaluateUnary(.Inv, 0.0);
    try testing.expectApproxEqAbs(0.0, inv_zero, 1e-12);

    const tanh_val = activation.evaluateUnary(.Tanh, 0.0);
    try testing.expectApproxEqAbs(0.0, tanh_val, 1e-12);
}

// ===========================================================================
// SYMBOLIC: SNAPPING
// ===========================================================================

test "Symbolic: Extended physical constant snapping (v6)" {
    const snap_4_3 = snapping.snapToPhysicalConstantScaleInvariant(1.33331);
    try testing.expectApproxEqAbs(4.0 / 3.0, snap_4_3, 1e-12);

    const snap_5_3 = snapping.snapToPhysicalConstantScaleInvariant(1.66670);
    try testing.expectApproxEqAbs(5.0 / 3.0, snap_5_3, 1e-12);

    const snap_sb = snapping.snapToPhysicalConstantScaleInvariant(5.67036);
    try testing.expectApproxEqAbs(5.67037, snap_sb, 1e-5);

    const snap_2pi = snapping.snapToPhysicalConstantScaleInvariant(6.28318);
    try testing.expectApproxEqAbs(2.0 * std.math.pi, snap_2pi, 1e-5);

    const snap_torr = snapping.snapToPhysicalConstantScaleInvariant(4.42867);
    try testing.expectApproxEqAbs(4.42867926, snap_torr, 1e-5);

    const snap_3_7 = snapping.snapToPhysicalConstantScaleInvariant(0.42856);
    try testing.expectApproxEqAbs(3.0 / 7.0, snap_3_7, 1e-4);
}

test "Symbolic: Snapping NaN/Inf passthrough" {
    const nan = std.math.nan(f64);
    const inf = std.math.inf(f64);
    const neg_inf = -std.math.inf(f64);

    const snap_nan = snapping.snapToPhysicalConstantScaleInvariant(nan);
    try testing.expect(std.math.isNan(snap_nan));

    const snap_inf = snapping.snapToPhysicalConstantScaleInvariant(inf);
    try testing.expect(std.math.isPositiveInf(snap_inf));

    const snap_neg_inf = snapping.snapToPhysicalConstantScaleInvariant(neg_inf);
    try testing.expect(std.math.isNegativeInf(snap_neg_inf));
}

test "Symbolic: Snapping expanded constants (golden ratio, sqrt2, ln2)" {
    const snap_sqrt2 = snapping.snapToPhysicalConstantScaleInvariant(1.41420);
    try testing.expectApproxEqAbs(@sqrt(2.0), snap_sqrt2, 1e-4);

    const snap_phi = snapping.snapToPhysicalConstantScaleInvariant(1.61802);
    try testing.expectApproxEqAbs(1.6180339887498948, snap_phi, 1e-4);
}

// ===========================================================================
// SYMBOLIC: FORMATTER
// ===========================================================================

test "Symbolic: Formatter suppresses coefficient 1.0" {
    const allocator = testing.allocator;
    const weights = [_]f64{ 1.0, 0.0 };
    const names = [_][]const u8{ "sin(x0)", "C" };

    const formula = try formatter.reconstructFormula(allocator, &weights, &names);
    defer allocator.free(formula);

    try testing.expect(std.mem.indexOf(u8, formula, "1.0000") == null);
    try testing.expect(std.mem.indexOf(u8, formula, "sin(x0)") != null);
}

test "Symbolic: Formatter detects fractions" {
    const allocator = testing.allocator;
    const weights = [_]f64{ 4.0 / 3.0 };
    const names = [_][]const u8{"sin(x0)"};

    const formula = try formatter.reconstructFormula(allocator, &weights, &names);
    defer allocator.free(formula);

    try testing.expect(std.mem.indexOf(u8, formula, "(4/3)") != null);
}

test "Symbolic: Formatter all-zero weights" {
    const allocator = testing.allocator;
    const weights = [_]f64{ 0.0, 0.0, 0.0 };
    const names = [_][]const u8{ "x0", "x1", "C" };

    const formula = try formatter.reconstructFormula(allocator, &weights, &names);
    defer allocator.free(formula);

    try testing.expectEqualSlices(u8, "0.0000", formula);
}

// ===========================================================================
// SYMBOLIC: DICTIONARY
// ===========================================================================

test "Symbolic: Bitmask Origin Tracking and Canonical Ordering" {
    const allocator = testing.allocator;
    var dict = try dictionary.ExpansionDictionary.init(allocator, 3);
    defer dict.deinit();

    const acts = [_]ermc.Activation{ .Sine, .Square };
    try dict.buildExpansion(&acts);

    for (dict.node_names.items, 0..) |name1, i| {
        for (dict.node_names.items[i + 1 ..]) |name2| {
            try testing.expect(!std.mem.eql(u8, name1, name2));
        }
    }
}
