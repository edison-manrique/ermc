// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Aritmética Compensada de Ultra-Alta Precisión
//!
//! Implementa algoritmos numéricos de error cero/compensado:
//! - Sumación de Kahan-Babuška-Neumaier: rastreo exacto del error de redondeo de punto flotante
//! - Producto punto compensado
//! - Media y varianza insesgada sin cancelación catastrófica (Two-pass Neumaier)
//! - Norma Euclídea escalada (Algoritmo de Blue / Two-scale) inmune al desbordamiento (10^150 a 10^-150)

const std = @import("std");

/// Sumación compensada de Neumaier (variante superior de Kahan).
/// Conserva la precisión hasta el último bit del épsilon de máquina (∼ 2.22e-16),
/// incluso cuando se suman números pequeños a sumas gigantescas o en presencia de outliers masivos.
pub fn neumaierSum(slice: []const f64) f64 {
    if (slice.len == 0) return 0.0;
    var sum: f64 = 0.0;
    var c: f64 = 0.0; // Error acumulado de compensación

    for (slice) |x| {
        const t = sum + x;
        if (@abs(sum) >= @abs(x)) {
            c += (sum - t) + x;
        } else {
            c += (x - t) + sum;
        }
        sum = t;
    }
    return sum + c;
}

/// Producto punto con acumulación compensada de Neumaier
pub fn compensatedDot(a: []const f64, b: []const f64) f64 {
    std.debug.assert(a.len == b.len);
    if (a.len == 0) return 0.0;

    var sum: f64 = 0.0;
    var c: f64 = 0.0;

    for (a, b) |ai, bi| {
        const prod = ai * bi;
        const t = sum + prod;
        if (@abs(sum) >= @abs(prod)) {
            c += (sum - t) + prod;
        } else {
            c += (prod - t) + sum;
        }
        sum = t;
    }
    return sum + c;
}

/// Estadísticas básicas computadas mediante dos pasadas compensadas,
/// completamente inmunes a la cancelación catastrófica de ∑ x² - (∑ x)² / n.
pub const CompensatedStats = struct {
    mean: f64,
    variance: f64,
    std_dev: f64,
    min: f64,
    max: f64,
};

pub fn compensatedMeanVar(slice: []const f64) CompensatedStats {
    const n = slice.len;
    if (n == 0) {
        return .{ .mean = 0.0, .variance = 0.0, .std_dev = 0.0, .min = 0.0, .max = 0.0 };
    }
    if (n == 1) {
        return .{ .mean = slice[0], .variance = 0.0, .std_dev = 0.0, .min = slice[0], .max = slice[0] };
    }

    // Pasada 1: Media exacta vía Neumaier
    const total_sum = neumaierSum(slice);
    const mean = total_sum / @as(f64, @floatFromInt(n));

    var min_val = slice[0];
    var max_val = slice[0];

    // Pasada 2: Desviaciones cuadráticas sumadas con Neumaier
    var diff_sq_sum: f64 = 0.0;
    var c_sq: f64 = 0.0;

    for (slice) |x| {
        if (x < min_val) min_val = x;
        if (x > max_val) max_val = x;

        const diff = x - mean;
        const sq = diff * diff;

        const t = diff_sq_sum + sq;
        if (@abs(diff_sq_sum) >= @abs(sq)) {
            c_sq += (diff_sq_sum - t) + sq;
        } else {
            c_sq += (sq - t) + diff_sq_sum;
        }
        diff_sq_sum = t;
    }

    const variance = (diff_sq_sum + c_sq) / @as(f64, @floatFromInt(n - 1));
    const std_dev = if (variance > 0.0) @sqrt(variance) else 0.0;

    return .{
        .mean = mean,
        .variance = variance,
        .std_dev = std_dev,
        .min = min_val,
        .max = max_val,
    };
}

/// Norma Euclídea escalada (Two-scale norm / Algoritmo de Blue simplificado).
/// Permite calcular la norma de vectores cuyos elementos exceden 10^154 (lo cual desbordaría a +inf al elevarse al cuadrado)
/// o son menores a 10^-154 (que subdesbordarían a 0).
pub fn safeNorm(slice: []const f64) f64 {
    if (slice.len == 0) return 0.0;

    // Encontrar escala máxima absoluta
    var max_abs: f64 = 0.0;
    for (slice) |x| {
        const ax = @abs(x);
        if (ax > max_abs) max_abs = ax;
    }

    if (max_abs == 0.0) return 0.0;
    if (std.math.isInf(max_abs)) return std.math.inf(f64);

    // Sumar con Neumaier sobre valores escalados en [0, 1]
    const inv_scale = 1.0 / max_abs;
    var sumsq: f64 = 0.0;
    var c: f64 = 0.0;

    for (slice) |x| {
        const scaled = x * inv_scale;
        const sq = scaled * scaled;
        const t = sumsq + sq;
        if (@abs(sumsq) >= @abs(sq)) {
            c += (sumsq - t) + sq;
        } else {
            c += (sq - t) + sumsq;
        }
        sumsq = t;
    }

    return max_abs * @sqrt(sumsq + c);
}
