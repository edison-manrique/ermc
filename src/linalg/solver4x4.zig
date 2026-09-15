// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Resuelve el sistema lineal A * x = b de dimensión 4x4 mediante eliminación gaussiana con pivoteo parcial.
/// Diseñado para máxima velocidad sin asignación dinámica de memoria (utilizado por Savitzky-Golay).
pub fn solve4x4(a: *const [16]f64, b: *const [4]f64) ?[4]f64 {
    var mat: [16]f64 = a.*;
    var vec: [4]f64 = b.*;

    // Eliminación hacia adelante con pivoteo parcial
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        var max_row = i;
        var max_val = @abs(mat[i * 4 + i]);

        var r = i + 1;
        while (r < 4) : (r += 1) {
            const val = @abs(mat[r * 4 + i]);
            if (val > max_val) {
                max_val = val;
                max_row = r;
            }
        }

        // Matriz singular o mal condicionada
        if (max_val < 1e-14) {
            return null;
        }

        // Intercambio de filas (pivoteo)
        if (max_row != i) {
            var c: usize = 0;
            while (c < 4) : (c += 1) {
                const temp = mat[i * 4 + c];
                mat[i * 4 + c] = mat[max_row * 4 + c];
                mat[max_row * 4 + c] = temp;
            }
            const temp_v = vec[i];
            vec[i] = vec[max_row];
            vec[max_row] = temp_v;
        }

        // Eliminación por filas
        r = i + 1;
        while (r < 4) : (r += 1) {
            const factor = mat[r * 4 + i] / mat[i * 4 + i];
            var c = i;
            while (c < 4) : (c += 1) {
                mat[r * 4 + c] -= factor * mat[i * 4 + c];
            }
            vec[r] -= factor * vec[i];
        }
    }

    // Sustitución hacia atrás
    var x = [4]f64{ 0.0, 0.0, 0.0, 0.0 };
    var k: usize = 4;
    while (k > 0) {
        k -= 1;
        var sum: f64 = 0.0;
        var j = k + 1;
        while (j < 4) : (j += 1) {
            sum += mat[k * 4 + j] * x[j];
        }
        x[k] = (vec[k] - sum) / mat[k * 4 + k];
    }

    return x;
}
