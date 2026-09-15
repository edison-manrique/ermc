// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Resolvedor de Sistemas Lineales sobre Campos Finitos F_p
//!
//! Implementa eliminación Gauss-Jordan exacta con pivoteo parcial en F_p.
//! Utilizado para regresión simbólica modular y criptoanálisis de endomorfismos.

const std = @import("std");
const arith = @import("arithmetic.zig");

/// Resuelve el sistema lineal H * w = y (mod p)
/// H: matriz plana de m filas y n columnas (m * n)
/// y: vector de longitud m
/// Retorna un slice alocado de tamaño n con la solución w, o null si el sistema es inconsistente.
pub fn solveModularLinearSystem(
    allocator: std.mem.Allocator,
    h_flat: []const u64,
    y: []const u64,
    m: usize,
    n: usize,
    p: u64,
) !?[]u64 {
    if (m == 0 or n == 0 or y.len != m or h_flat.len != m * n) {
        return null;
    }

    const n_aug = n + 1;
    // Matriz aumentada [H | y] de dimensión m x (n + 1)
    var aug = try allocator.alloc(u64, m * n_aug);
    defer allocator.free(aug);

    for (0..m) |i| {
        for (0..n) |j| {
            aug[i * n_aug + j] = h_flat[i * n + j] % p;
        }
        aug[i * n_aug + n] = y[i] % p;
    }

    var pivot_rows = try allocator.alloc(?usize, n);
    defer allocator.free(pivot_rows);
    @memset(pivot_rows, null);

    var row: usize = 0;

    for (0..n) |col| {
        // Buscar pivote no nulo en la columna col desde 'row' hacia abajo
        var pivot: ?usize = null;
        for (row..m) |r| {
            if (aug[r * n_aug + col] != 0) {
                pivot = r;
                break;
            }
        }

        if (pivot) |pivot_row| {
            // Intercambiar fila actual con la fila del pivote
            if (pivot_row != row) {
                for (0..n_aug) |c| {
                    const tmp = aug[row * n_aug + c];
                    aug[row * n_aug + c] = aug[pivot_row * n_aug + c];
                    aug[pivot_row * n_aug + c] = tmp;
                }
            }

            pivot_rows[col] = row;

            // Normalizar la fila pivote dividiendo por el elemento pivote
            const pivot_val = aug[row * n_aug + col];
            const inv = arith.modInverse(pivot_val, p) orelse return null;

            for (col..n_aug) |c| {
                aug[row * n_aug + c] = arith.mulMod(aug[row * n_aug + c], inv, p);
            }

            // Eliminar todas las demás filas
            for (0..m) |r| {
                if (r != row and aug[r * n_aug + col] != 0) {
                    const factor = aug[r * n_aug + col];
                    for (col..n_aug) |c| {
                        const term = arith.mulMod(factor, aug[row * n_aug + c], p);
                        aug[r * n_aug + c] = arith.subMod(aug[r * n_aug + c], term, p);
                    }
                }
            }

            row += 1;
            if (row == m) break;
        }
    }

    // Comprobación de consistencia: si alguna fila tiene ceros en todos los coeficientes
    // pero el término independiente no es cero, el sistema no tiene solución.
    for (0..m) |r| {
        var all_zeros = true;
        for (0..n) |c| {
            if (aug[r * n_aug + c] != 0) {
                all_zeros = false;
                break;
            }
        }
        if (all_zeros and aug[r * n_aug + n] != 0) {
            return null; // Sistema inconsistente (0 = k con k != 0)
        }
    }

    // Extraer solución
    var w = try allocator.alloc(u64, n);
    for (0..n) |col| {
        if (pivot_rows[col]) |r| {
            w[col] = aug[r * n_aug + n];
        } else {
            w[col] = 0; // Variable libre asignada a 0
        }
    }

    return w;
}
