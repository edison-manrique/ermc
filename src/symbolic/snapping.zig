// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Ajusta coeficientes reales descubiertos numéricamente hacia constantes físicas universales,
/// fracciones racionales canónicas (ej. 4/3, 5/3, 8/3) o enteros exactos de forma invariante de escala.
/// Incluye validación NaN/Inf y tabla expandida de constantes matemáticas fundamentales.
pub fn snapToPhysicalConstantScaleInvariant(w: f64) f64 {
    // Validación de entradas degeneradas
    if (std.math.isNan(w) or std.math.isInf(w)) {
        return w; // Propagar sin modificar valores patológicos
    }

    const abs_w = @abs(w);

    // Filtro severo contra ruido numérico infinitesimal
    if (abs_w < 1e-25) {
        return 0.0;
    }

    const sign: f64 = if (w >= 0.0) 1.0 else -1.0;

    // Snapping directo de enteros inmediatos
    const raw_round = @round(abs_w);
    if (raw_round > 0.0 and @abs(abs_w - raw_round) < 1e-5) {
        return raw_round * sign;
    }

    const log10_w = std.math.log10(abs_w);
    const exponent = @floor(log10_w);
    const scale = std.math.pow(f64, 10.0, exponent);
    const normalized_w = abs_w / scale;

    var best_normalized_val = normalized_w;
    var best_score: f64 = std.math.inf(f64);

    // 1. Snapping de enteros escalados (Tolerancia: 2.0%)
    const p_int = @round(normalized_w);
    const err_int = @abs(normalized_w - p_int);
    if (err_int < 0.02) {
        const score = err_int * 1.0;
        if (score < best_score) {
            best_score = score;
            best_normalized_val = p_int;
        }
    }

    // 2. Snapping de fracciones con denominador q acotado a 2..12 (extendido de 2..8)
    var q: usize = 2;
    while (q <= 12) : (q += 1) {
        const fq: f64 = @floatFromInt(q);
        const p = @round(normalized_w * fq);
        const err = @abs(normalized_w - (p / fq));
        if (err < 0.012) {
            // Penalizar denominadores grandes ligeramente más
            const score = err * (1.2 + 0.08 * fq);
            if (score < best_score) {
                best_score = score;
                best_normalized_val = p / fq;
            }
        }
    }

    // 3. Constantes universales exactas y factores científicos (v2 expandida)
    const universal_constants = [_]f64{
        // Fracciones físicas importantes
        4.0 / 3.0,          // 1.33333... (Ley de Snell agua/vidrio)
        5.0 / 3.0,          // 1.66666... (Coeficiente adiabático gas monoatómico)
        8.0 / 3.0,          // 2.66666... (Parámetro beta atractor caótico de Lorenz)

        // Constantes matemáticas fundamentales
        std.math.e,          // 2.71828... (Número de Euler)
        std.math.pi / 4.0,   // 0.78539... (pi/4)
        std.math.pi / 2.0,   // 1.57079... (pi/2)
        std.math.pi,          // 3.14159... (pi)
        2.0 * std.math.pi,   // 6.28318... (tau / 2*pi)
        @log(2.0),           // 0.69314... (ln(2))
        @sqrt(2.0),          // 1.41421... (√2)
        @sqrt(3.0),          // 1.73205... (√3)
        1.6180339887498948,   // Φ (golden ratio / número áureo)

        // Constantes físicas
        5.67037,             // Constante de radiación de Stefan-Boltzmann (sigma)
        6.67430,             // Constante de gravitación universal G
        8.98755,             // Constante de Coulomb k_c
        9.80665,             // Aceleración de gravedad g estándar
        9.81,                // Gravedad redondeada estándar

        // Factores derivados de la gravedad
        2.00606668,          // Factor de período de péndulo: 2*pi / sqrt(9.81)
        4.42867926,          // Coeficiente de Torricelli: sqrt(2 * 9.80665)
    };

    for (universal_constants) |u_const| {
        const err = @abs(normalized_w - u_const);
        if (err < 0.005) {
            const score = err * 1.5;
            if (score < best_score) {
                best_score = score;
                best_normalized_val = u_const;
            }
        }
    }

    const reconstructed_w = best_normalized_val * scale * sign;

    // Si la alteración supera el 2.0% relativo, se descarta el snap
    if (@abs(reconstructed_w - w) / abs_w > 0.02) {
        return w;
    } else {
        return reconstructed_w;
    }
}
