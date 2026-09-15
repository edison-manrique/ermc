// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Módulo de Detección de Outliers Extremos sin Pérdida de Precisión
//!
//! Diseñado para detectar anomalías y valores atípicos severos (sensores averiados, picos cósmicos,
//! divergencias numéricas con magnitudes desde 10^-50 hasta 10^150) sin sufrir cancelación
//! catastrófica, desbordamiento (overflow) o degradación en la precisión de los datos limpios.
//!
//! Métodos incluidos:
//! - Filtro de Hampel Robusto con factor asintótico normal c = 1.482602218505602
//! - Test ESD Generalizado (Extreme Studentized Deviate) con acumulación compensada
//! - Detector de Outliers en Rangos Dinámicos Masivos (escala invariante)

const std = @import("std");
const precision = @import("../core/precision.zig");

pub const OutlierResult = struct {
    allocator: std.mem.Allocator,
    is_outlier: []bool,
    severity: []f64, // Puntuación Z robusta (|x - med| / MAD_norm)
    clean_data: []f64, // Datos con outliers imputados por la mediana robusta
    n_outliers: usize,
    median: f64,
    mad: f64,
    mad_normalized: f64, // mad * 1.482602218505602

    pub fn deinit(self: *OutlierResult) void {
        self.allocator.free(self.is_outlier);
        self.allocator.free(self.severity);
        self.allocator.free(self.clean_data);
    }
};

/// Factor de consistencia asintótica del MAD para la distribución normal:
/// 1 / (√2 * erf⁻¹(0.5)) ≈ 1.482602218505602
pub const NORMAL_MAD_SCALE: f64 = 1.48260221850560186;

/// Aproximación analítica de Winitzki de la función error inversa erf⁻¹(x)
pub fn invErf(x: f64) f64 {
    const a: f64 = 0.147;
    const sign: f64 = if (x < 0.0) -1.0 else 1.0;
    const clamped_x = std.math.clamp(x, -0.999999999, 0.999999999);
    const x_sq = clamped_x * clamped_x;

    const log_term = @log(1.0 - x_sq);
    const two_pi_a = 2.0 / (std.math.pi * a);
    const term1 = two_pi_a + 0.5 * log_term;
    const inner = (term1 * term1) - (log_term / a);
    const root = @sqrt(@max(inner, 0.0)) - term1;
    return sign * @sqrt(@max(root, 0.0));
}

/// Calcula la mediana exacta de un slice preservando la inmutabilidad de los datos originales
pub fn computeExactMedian(allocator: std.mem.Allocator, data: []const f64) !f64 {
    const n = data.len;
    if (n == 0) return 0.0;
    if (n == 1) return data[0];

    const sorted = try allocator.alloc(f64, n);
    defer allocator.free(sorted);
    @memcpy(sorted, data);
    std.mem.sort(f64, sorted, {}, std.sort.asc(f64));

    const mid = n / 2;
    if (n % 2 == 1) {
        return sorted[mid];
    } else {
        // Promedio aritmético compensado de los dos valores centrales
        const a = sorted[mid - 1];
        const b = sorted[mid];
        return a * 0.5 + b * 0.5;
    }
}

/// Calcula el MAD (Median Absolute Deviation) exacto
pub fn computeExactMad(allocator: std.mem.Allocator, data: []const f64, median: f64) !f64 {
    const n = data.len;
    if (n <= 1) return 0.0;

    const diffs = try allocator.alloc(f64, n);
    defer allocator.free(diffs);

    for (data, 0..) |x, i| {
        diffs[i] = @abs(x - median);
    }

    std.mem.sort(f64, diffs, {}, std.sort.asc(f64));

    const mid = n / 2;
    if (n % 2 == 1) {
        return diffs[mid];
    } else {
        return diffs[mid - 1] * 0.5 + diffs[mid] * 0.5;
    }
}

/// Detector de Outliers de Ultra-Alta Precisión (Filtro de Hampel Invariante a la Escala).
/// Opera con estabilidad numérica absoluta incluso si los outliers alcanzan órdenes de magnitud
/// gigantescos (ej. 10^100) o si los datos limpios tienen fluctuaciones diminutas (10^-15).
pub fn detectOutliersHampel(
    allocator: std.mem.Allocator,
    data: []const f64,
    k_threshold: f64,
) !OutlierResult {
    const n = data.len;
    std.debug.assert(n > 0);

    const median = try computeExactMedian(allocator, data);
    const raw_mad = try computeExactMad(allocator, data, median);
    const mad_norm = raw_mad * NORMAL_MAD_SCALE;

    var is_outlier = try allocator.alloc(bool, n);
    errdefer allocator.free(is_outlier);

    var severity = try allocator.alloc(f64, n);
    errdefer allocator.free(severity);

    var clean_data = try allocator.alloc(f64, n);
    errdefer allocator.free(clean_data);

    var outlier_count: usize = 0;

    // Umbral de escala mínima para evitar división por cero en series idénticas
    const scale = @max(mad_norm, 1e-20);

    for (data, 0..) |x, i| {
        // Diferencia absoluta
        const diff = @abs(x - median);

        // Si diff es infinito o NaN, es un outlier extremo por definición
        if (std.math.isNan(x) or std.math.isInf(x)) {
            is_outlier[i] = true;
            severity[i] = std.math.inf(f64);
            clean_data[i] = median;
            outlier_count += 1;
            continue;
        }

        const z_score = diff / scale;
        severity[i] = z_score;

        if (z_score > k_threshold) {
            is_outlier[i] = true;
            clean_data[i] = median; // Imputación insesgada con la mediana
            outlier_count += 1;
        } else {
            is_outlier[i] = false;
            clean_data[i] = x; // Conserva el bit exacto original de la mantisa
        }
    }

    return .{
        .allocator = allocator,
        .is_outlier = is_outlier,
        .severity = severity,
        .clean_data = clean_data,
        .n_outliers = outlier_count,
        .median = median,
        .mad = raw_mad,
        .mad_normalized = mad_norm,
    };
}

/// Test ESD Generalizado (Extreme Studentized Deviate) para detectar hasta `max_outliers`
/// outliers severos usando estadísticas compensadas con Kahan-Neumaier.
pub fn detectExtremeEsd(
    allocator: std.mem.Allocator,
    data: []const f64,
    max_outliers: usize,
    alpha: f64,
) !OutlierResult {
    const n = data.len;
    std.debug.assert(n > 3);
    const k = @min(max_outliers, n / 2);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    // Copia de trabajo para el algoritmo ESD secuencial
    var active_mask = try temp_alloc.alloc(bool, n);
    @memset(active_mask, true);

    var outlier_indices = try temp_alloc.alloc(usize, k);
    var r_statistics = try temp_alloc.alloc(f64, k);
    var critical_values = try temp_alloc.alloc(f64, k);

    var current_n = n;

    for (0..k) |iter| {
        // Extraer sub-array activo
        var active_vals = try temp_alloc.alloc(f64, current_n);
        var active_map = try temp_alloc.alloc(usize, current_n);
        var idx: usize = 0;
        for (0..n) |orig_i| {
            if (active_mask[orig_i]) {
                active_vals[idx] = data[orig_i];
                active_map[idx] = orig_i;
                idx += 1;
            }
        }

        // Estadísticas compensadas
        const stats = precision.compensatedMeanVar(active_vals);
        const s_dev = @max(stats.std_dev, 1e-15);

        // Encontrar valor con máxima desviación
        var max_diff: f64 = -1.0;
        var max_orig_idx: usize = 0;

        for (0..current_n) |j| {
            const diff = @abs(active_vals[j] - stats.mean);
            if (diff > max_diff) {
                max_diff = diff;
                max_orig_idx = active_map[j];
            }
        }

        const r_stat = max_diff / s_dev;
        r_statistics[iter] = r_stat;
        outlier_indices[iter] = max_orig_idx;

        // Valor crítico ESD usando aproximación de la distribución t de Student
        const p = 1.0 - alpha / (2.0 * @as(f64, @floatFromInt(current_n)));
        const df = @as(f64, @floatFromInt(current_n - 2));
        // Cuantil aproximado de t para grados de libertad df
        // t_p ≈ z_p + (z_p^3 + z_p) / (4*df)
        const zp = @sqrt(2.0) * invErf(2.0 * p - 1.0);
        const tp = zp + (zp * zp * zp + zp) / (4.0 * df);

        const num = @as(f64, @floatFromInt(current_n - 1)) * tp;
        const den = @sqrt((df + tp * tp) * @as(f64, @floatFromInt(current_n)));
        critical_values[iter] = num / den;

        // Remover del conjunto activo para la siguiente iteración
        active_mask[max_orig_idx] = false;
        current_n -= 1;
    }

    // Encontrar el mayor l tal que R_l > lambda_l
    var max_l: isize = -1;
    var l: isize = @as(isize, @intCast(k)) - 1;
    while (l >= 0) : (l -= 1) {
        const ul = @as(usize, @intCast(l));
        if (r_statistics[ul] > critical_values[ul]) {
            max_l = l;
            break;
        }
    }

    // Construir resultado final
    var is_out = try allocator.alloc(bool, n);
    errdefer allocator.free(is_out);
    @memset(is_out, false);

    var sev = try allocator.alloc(f64, n);
    errdefer allocator.free(sev);
    @memset(sev, 0.0);

    var clean = try allocator.alloc(f64, n);
    errdefer allocator.free(clean);
    @memcpy(clean, data);

    const median = try computeExactMedian(allocator, data);
    const raw_mad = try computeExactMad(allocator, data, median);

    var total_detected: usize = 0;
    if (max_l >= 0) {
        const count = @as(usize, @intCast(max_l + 1));
        total_detected = count;
        for (0..count) |i| {
            const out_idx = outlier_indices[i];
            is_out[out_idx] = true;
            sev[out_idx] = r_statistics[i];
            clean[out_idx] = median;
        }
    }

    return .{
        .allocator = allocator,
        .is_outlier = is_out,
        .severity = sev,
        .clean_data = clean,
        .n_outliers = total_detected,
        .median = median,
        .mad = raw_mad,
        .mad_normalized = raw_mad * NORMAL_MAD_SCALE,
    };
}
