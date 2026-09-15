// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Regresión Simbólica Exacta sobre Campos Finitos F_p
//!
//! Descubre leyes algebraicas racionales discretas f(x, y) = z (mod p)
//! mediante expansión en biblioteca modular de monomios y términos racionales (x^2/y, 1/y, etc.)
//! y resolución Gauss-Jordan exacta sin pérdida de precisión.

const std = @import("std");
const arith = @import("arithmetic.zig");
const solver = @import("solver.zig");

pub const ModularSample2D = struct {
    x: u64,
    y: u64,
    target: u64,
};

pub const ModularFeature = enum(u8) {
    X = 0,
    Y = 1,
    Const = 2,
    X2 = 3,
    Y2 = 4,
    XY = 5,
    InvY = 6,
    X_InvY = 7,
    X2_InvY = 8,
    X3 = 9,

    pub fn name(self: ModularFeature) []const u8 {
        return switch (self) {
            .X => "x",
            .Y => "y",
            .Const => "C",
            .X2 => "x^2",
            .Y2 => "y^2",
            .XY => "x*y",
            .InvY => "1/y",
            .X_InvY => "x/y",
            .X2_InvY => "x^2/y",
            .X3 => "x^3",
        };
    }
};

pub const ModularRegressionResult = struct {
    weights: []u64,
    features: []const ModularFeature,
    modulus: u64,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ModularRegressionResult) void {
        self.allocator.free(self.weights);
    }

    /// Evalúa la fórmula descubierta para una entrada dada (x, y) mod p
    pub fn evaluate(self: ModularRegressionResult, x: u64, y: u64) u64 {
        const p = self.modulus;
        const x_p = x % p;
        const y_p = y % p;

        const inv_y = arith.modInverse(y_p, p) orelse 0;
        const x_sq = arith.mulMod(x_p, x_p, p);
        const y_sq = arith.mulMod(y_p, y_p, p);
        const x_cb = arith.mulMod(x_sq, x_p, p);

        var sum: u128 = 0;
        for (self.features, 0..) |feat, i| {
            const w = self.weights[i];
            if (w == 0) continue;

            const val: u64 = switch (feat) {
                .X => x_p,
                .Y => y_p,
                .Const => 1,
                .X2 => x_sq,
                .Y2 => y_sq,
                .XY => arith.mulMod(x_p, y_p, p),
                .InvY => inv_y,
                .X_InvY => arith.mulMod(x_p, inv_y, p),
                .X2_InvY => arith.mulMod(x_sq, inv_y, p),
                .X3 => x_cb,
            };

            sum = (sum + @as(u128, w) * @as(u128, val)) % p;
        }

        return @intCast(sum);
    }

    /// Formatea la fórmula algebraica descubierta como cadena legible
    pub fn formatFormula(self: ModularRegressionResult, allocator: std.mem.Allocator) ![]u8 {
        var list = std.ArrayList(u8).empty;
        defer list.deinit(allocator);

        var first = true;
        for (self.features, 0..) |feat, i| {
            const w = self.weights[i];
            if (w == 0) continue;

            if (!first) {
                try list.appendSlice(allocator, " + ");
            }
            first = false;

            if (feat == .Const) {
                try list.writer(allocator).print("{d}", .{w});
            } else if (w == 1) {
                try list.writer(allocator).print("{s}", .{feat.name()});
            } else {
                try list.writer(allocator).print("{d}*{s}", .{ w, feat.name() });
            }
        }

        if (first) {
            try list.appendSlice(allocator, "0");
        }

        return list.toOwnedSlice(allocator);
    }
};

/// Ejecuta regresión simbólica en F_p sobre un dataset de pares (x, y) -> target
pub fn fitModularRational(
    allocator: std.mem.Allocator,
    dataset: []const ModularSample2D,
    p: u64,
) !?ModularRegressionResult {
    const default_features = [_]ModularFeature{
        .X,
        .Y,
        .Const,
        .X2,
        .Y2,
        .XY,
        .InvY,
        .X_InvY,
        .X2_InvY,
        .X3,
    };

    const n_samples = dataset.len;
    const n_features = default_features.len;

    var h_flat = try allocator.alloc(u64, n_samples * n_features);
    defer allocator.free(h_flat);

    var y_target = try allocator.alloc(u64, n_samples);
    defer allocator.free(y_target);

    for (dataset, 0..) |s, row| {
        const x_p = s.x % p;
        const y_p = s.y % p;

        const inv_y = arith.modInverse(y_p, p) orelse 0;
        const x_sq = arith.mulMod(x_p, x_p, p);
        const y_sq = arith.mulMod(y_p, y_p, p);
        const x_cb = arith.mulMod(x_sq, x_p, p);

        h_flat[row * n_features + 0] = x_p;
        h_flat[row * n_features + 1] = y_p;
        h_flat[row * n_features + 2] = 1;
        h_flat[row * n_features + 3] = x_sq;
        h_flat[row * n_features + 4] = y_sq;
        h_flat[row * n_features + 5] = arith.mulMod(x_p, y_p, p);
        h_flat[row * n_features + 6] = inv_y;
        h_flat[row * n_features + 7] = arith.mulMod(x_p, inv_y, p);
        h_flat[row * n_features + 8] = arith.mulMod(x_sq, inv_y, p);
        h_flat[row * n_features + 9] = x_cb;

        y_target[row] = s.target % p;
    }

    const sol = try solver.solveModularLinearSystem(
        allocator,
        h_flat,
        y_target,
        n_samples,
        n_features,
        p,
    );

    if (sol) |weights| {
        return ModularRegressionResult{
            .weights = weights,
            .features = &default_features,
            .modulus = p,
            .allocator = allocator,
        };
    }

    return null;
}
