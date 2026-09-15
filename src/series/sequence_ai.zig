// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const qr = @import("../linalg/qr.zig");

pub const BasisEvalFn = *const fn (x: f64, y1: f64, y2: f64) f64;

pub const SequenceBasis = struct {
    name: []const u8,
    eval: BasisEvalFn,
};

fn evalConst(_: f64, _: f64, _: f64) f64 {
    return 1.0;
}
fn evalLogX(x: f64, _: f64, _: f64) f64 {
    return if (x > 1.0) @log(x) else 0.0;
}
fn evalLogY1(_: f64, y1: f64, _: f64) f64 {
    return if (y1 > 1.0) @log(y1) else 0.0;
}
fn evalRatio(x: f64, y1: f64, _: f64) f64 {
    return if (x > 0.0) y1 / x else 0.0;
}
fn evalInvLogX(x: f64, _: f64, _: f64) f64 {
    return if (x > 1.5) 1.0 / @log(x) else 0.0;
}
fn evalMomentum(_: f64, y1: f64, y2: f64) f64 {
    return y1 - y2;
}
fn evalParity(x: f64, _: f64, _: f64) f64 {
    const ix: i64 = @intFromFloat(x);
    return if (@mod(ix, 2) == 0) 1.0 else -1.0;
}
fn evalSqrtX(x: f64, _: f64, _: f64) f64 {
    return if (x >= 0.0) @sqrt(x) else 0.0;
}
fn evalLinearX(x: f64, _: f64, _: f64) f64 {
    return x;
}
// Nuevas bases adicionales para v2
fn evalQuadraticX(x: f64, _: f64, _: f64) f64 {
    return x * x;
}
fn evalXLogX(x: f64, _: f64, _: f64) f64 {
    return if (x > 1.0) x * @log(x) else 0.0;
}
fn evalSinPiX(x: f64, _: f64, _: f64) f64 {
    return @sin(std.math.pi * x);
}
fn evalAcceleration(_: f64, y1: f64, y2: f64) f64 {
    // Segunda diferencia finita (aceleración discreta)
    return y1 - 2.0 * y2;
}
fn evalY1Squared(_: f64, y1: f64, _: f64) f64 {
    return y1 * y1;
}

pub const SequenceAi = struct {
    bases: []const SequenceBasis,

    const default_bases = [_]SequenceBasis{
        .{ .name = "1", .eval = evalConst },
        .{ .name = "ln(x)", .eval = evalLogX },
        .{ .name = "ln(p(x-1))", .eval = evalLogY1 },
        .{ .name = "p(x-1)/x", .eval = evalRatio },
        .{ .name = "1/ln(x)", .eval = evalInvLogX },
        .{ .name = "p(x-1)-p(x-2)", .eval = evalMomentum },
        .{ .name = "(-1)^x", .eval = evalParity },
        .{ .name = "sqrt(x)", .eval = evalSqrtX },
        .{ .name = "x", .eval = evalLinearX },
    };

    const extended_bases = [_]SequenceBasis{
        .{ .name = "1", .eval = evalConst },
        .{ .name = "ln(x)", .eval = evalLogX },
        .{ .name = "ln(p(x-1))", .eval = evalLogY1 },
        .{ .name = "p(x-1)/x", .eval = evalRatio },
        .{ .name = "1/ln(x)", .eval = evalInvLogX },
        .{ .name = "p(x-1)-p(x-2)", .eval = evalMomentum },
        .{ .name = "(-1)^x", .eval = evalParity },
        .{ .name = "sqrt(x)", .eval = evalSqrtX },
        .{ .name = "x", .eval = evalLinearX },
        .{ .name = "x^2", .eval = evalQuadraticX },
        .{ .name = "x*ln(x)", .eval = evalXLogX },
        .{ .name = "sin(pi*x)", .eval = evalSinPiX },
        .{ .name = "accel", .eval = evalAcceleration },
        .{ .name = "p(x-1)^2", .eval = evalY1Squared },
    };

    /// Inicializa con el conjunto de bases estándar (9 bases)
    pub fn init() SequenceAi {
        return .{
            .bases = &default_bases,
        };
    }

    /// Inicializa con el conjunto extendido de bases (14 bases)
    /// Incluye x², x*ln(x), sin(πx), aceleración discreta y p(x-1)²
    pub fn initExtended() SequenceAi {
        return .{
            .bases = &extended_bases,
        };
    }

    /// Inicializa con un conjunto de bases personalizado proporcionado por el usuario
    pub fn initWithBases(bases: []const SequenceBasis) SequenceAi {
        return .{
            .bases = bases,
        };
    }

    /// Analiza una serie numérica dada (ej. números primos, gaps, progresiones) y descubre
    /// la combinación lineal óptima de funciones base que modelan el siguiente incremento.
    pub fn fitGaps(
        self: SequenceAi,
        allocator: std.mem.Allocator,
        sequence: []const f64,
    ) ![]f64 {
        if (sequence.len < 4) return error.EmptyDataset;

        const n_samples = sequence.len - 2;
        const n_bases = self.bases.len;

        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const h_matrix = try temp_alloc.alloc(f64, n_samples * n_bases);
        const y_target = try temp_alloc.alloc(f64, n_samples);
        const weights_ones = try temp_alloc.alloc(f64, n_samples);
        @memset(weights_ones, 1.0);

        for (0..n_samples) |s| {
            const idx = s + 2;
            const x: f64 = @floatFromInt(idx);
            const y1 = sequence[idx - 1];
            const y2 = sequence[idx - 2];
            const gap = sequence[idx] - y1;

            y_target[s] = gap;

            for (self.bases, 0..) |basis, b| {
                h_matrix[s * n_bases + b] = basis.eval(x, y1, y2);
            }
        }

        const coefs = try allocator.alloc(f64, n_bases);
        _ = try qr.solveWeightedQrPreconditioned(
            temp_alloc,
            h_matrix,
            y_target,
            weights_ones,
            n_samples,
            n_bases,
            coefs,
        );

        return coefs;
    }

    /// Predice el siguiente elemento de la serie sumando el incremento proyectado al último valor
    pub fn predictNext(
        self: SequenceAi,
        sequence: []const f64,
        coefs: []const f64,
    ) f64 {
        const len = sequence.len;
        if (len < 2) return 0.0;
        const next_idx = len;
        const x: f64 = @floatFromInt(next_idx);
        const y1 = sequence[len - 1];
        const y2 = sequence[len - 2];

        var predicted_gap: f64 = 0.0;
        for (self.bases, 0..) |basis, b| {
            predicted_gap += coefs[b] * basis.eval(x, y1, y2);
        }

        return y1 + predicted_gap;
    }

    /// Predice múltiples valores futuros de la serie
    pub fn predictNextN(
        self: SequenceAi,
        allocator: std.mem.Allocator,
        sequence: []const f64,
        coefs: []const f64,
        n: usize,
    ) ![]f64 {
        const predictions = try allocator.alloc(f64, n);

        // Buffer temporal extendido para alimentar predicciones recursivas
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const extended = try temp_alloc.alloc(f64, sequence.len + n);
        @memcpy(extended[0..sequence.len], sequence);

        for (0..n) |i| {
            const current_len = sequence.len + i;
            const x: f64 = @floatFromInt(current_len);
            const y1 = extended[current_len - 1];
            const y2 = extended[current_len - 2];

            var predicted_gap: f64 = 0.0;
            for (self.bases, 0..) |basis, b| {
                predicted_gap += coefs[b] * basis.eval(x, y1, y2);
            }

            const next_val = y1 + predicted_gap;
            extended[current_len] = next_val;
            predictions[i] = next_val;
        }

        return predictions;
    }
};
