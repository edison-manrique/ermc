// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Representación de Puntos sobre Curvas Elípticas en Coordenadas Afines
//!
//! Soporta puntos regulares P = (x, y) y el punto en el infinito O (elemento neutro del grupo).

const std = @import("std");

pub const Point = struct {
    x: u64,
    y: u64,
    infinity: bool,

    /// Crea un punto afín regular (x, y)
    pub fn affine(x: u64, y: u64) Point {
        return .{ .x = x, .y = y, .infinity = false };
    }

    /// Punto en el infinito O (identidad del grupo abeliano)
    pub fn infinityPoint() Point {
        return .{ .x = 0, .y = 0, .infinity = true };
    }

    /// Retorna true si este punto es el elemento neutro O
    pub fn isInfinity(self: Point) bool {
        return self.infinity;
    }

    /// Compara dos puntos por igualdad en el grupo
    pub fn eq(self: Point, other: Point) bool {
        if (self.infinity and other.infinity) return true;
        if (self.infinity != other.infinity) return false;
        return self.x == other.x and self.y == other.y;
    }

    /// Negación en el grupo: -P = (x, -y mod p)
    pub fn negate(self: Point, p: u64) Point {
        if (self.infinity) return self;
        const y_mod = self.y % p;
        const neg_y = if (y_mod == 0) 0 else p - y_mod;
        return Point.affine(self.x % p, neg_y);
    }
};
