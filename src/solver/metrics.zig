// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Métricas de bondad de ajuste para evaluación cuantitativa de modelos descubiertos

/// Error Cuadrático Medio (Mean Squared Error)
/// Mide la magnitud promedio de los errores al cuadrado entre predicciones y valores reales.
pub fn mse(y_true: []const f64, y_pred: []const f64) f64 {
    std.debug.assert(y_true.len == y_pred.len);
    const n = y_true.len;
    if (n == 0) return 0.0;

    var sum_sq: f64 = 0.0;
    for (y_true, y_pred) |yt, yp| {
        const diff = yt - yp;
        sum_sq += diff * diff;
    }
    return sum_sq / @as(f64, @floatFromInt(n));
}

/// Error Absoluto Medio (Mean Absolute Error)
/// Métrica robusta frente a outliers, mide la magnitud promedio de los errores absolutos.
pub fn mae(y_true: []const f64, y_pred: []const f64) f64 {
    std.debug.assert(y_true.len == y_pred.len);
    const n = y_true.len;
    if (n == 0) return 0.0;

    var sum_abs: f64 = 0.0;
    for (y_true, y_pred) |yt, yp| {
        sum_abs += @abs(yt - yp);
    }
    return sum_abs / @as(f64, @floatFromInt(n));
}

/// Raíz del Error Cuadrático Medio (Root Mean Squared Error)
/// Tiene las mismas unidades que la variable objetivo, facilitando su interpretación.
pub fn rmse(y_true: []const f64, y_pred: []const f64) f64 {
    return @sqrt(mse(y_true, y_pred));
}

/// Coeficiente de Determinación R² (R-squared)
/// Indica la proporción de varianza explicada por el modelo.
/// R² = 1.0 indica ajuste perfecto; R² = 0.0 indica que el modelo es tan bueno como la media.
/// Valores negativos indican peor rendimiento que la predicción trivial.
pub fn r2(y_true: []const f64, y_pred: []const f64) f64 {
    std.debug.assert(y_true.len == y_pred.len);
    const n = y_true.len;
    if (n == 0) return 0.0;

    // Media de y_true
    var mean: f64 = 0.0;
    for (y_true) |yt| mean += yt;
    mean /= @as(f64, @floatFromInt(n));

    // SS_res = Σ(y_true - y_pred)²  y  SS_tot = Σ(y_true - mean)²
    var ss_res: f64 = 0.0;
    var ss_tot: f64 = 0.0;
    for (y_true, y_pred) |yt, yp| {
        const res = yt - yp;
        ss_res += res * res;
        const tot = yt - mean;
        ss_tot += tot * tot;
    }

    if (ss_tot < 1e-30) return if (ss_res < 1e-30) 1.0 else 0.0;
    return 1.0 - (ss_res / ss_tot);
}

/// R² Ajustado (Adjusted R²)
/// Penaliza la complejidad del modelo para evitar sobreajuste.
/// k = número de coeficientes activos (no-cero) del modelo.
pub fn r2Adjusted(y_true: []const f64, y_pred: []const f64, k: usize) f64 {
    const n = y_true.len;
    if (n <= k + 1) return r2(y_true, y_pred);

    const r2_val = r2(y_true, y_pred);
    const fn_f: f64 = @floatFromInt(n);
    const fk_f: f64 = @floatFromInt(k);
    return 1.0 - (1.0 - r2_val) * (fn_f - 1.0) / (fn_f - fk_f - 1.0);
}

/// Error Máximo Absoluto (Maximum Absolute Error)
/// Identifica el peor caso de predicción del modelo.
pub fn maxAbsError(y_true: []const f64, y_pred: []const f64) f64 {
    std.debug.assert(y_true.len == y_pred.len);
    var max_err: f64 = 0.0;
    for (y_true, y_pred) |yt, yp| {
        const err = @abs(yt - yp);
        if (err > max_err) max_err = err;
    }
    return max_err;
}

/// Error Relativo Medio (Mean Relative Error)
/// Útil cuando los targets tienen órdenes de magnitud variados.
pub fn meanRelativeError(y_true: []const f64, y_pred: []const f64) f64 {
    std.debug.assert(y_true.len == y_pred.len);
    const n = y_true.len;
    if (n == 0) return 0.0;

    var sum_rel: f64 = 0.0;
    var count: f64 = 0.0;
    for (y_true, y_pred) |yt, yp| {
        const abs_yt = @abs(yt);
        if (abs_yt > 1e-15) {
            sum_rel += @abs(yt - yp) / abs_yt;
            count += 1.0;
        }
    }
    if (count < 1.0) return 0.0;
    return sum_rel / count;
}

/// Cuenta el número de coeficientes activos (no-cero) en un vector de pesos.
/// Útil para medir la parsimonia/complejidad del modelo descubierto.
pub fn activeCoefficients(weights: []const f64) usize {
    var count: usize = 0;
    for (weights) |w| {
        if (@abs(w) > 1e-15) count += 1;
    }
    return count;
}
