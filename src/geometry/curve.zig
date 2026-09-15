// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Curvas Elípticas en Forma Corta de Weierstraß sobre Campos Finitos F_p
//!
//! Ecuación: y^2 = x^3 + a*x + b (mod p)
//! Implementa la ley de grupo abeliano completa:
//! - Comprobación de no-singularidad (4a^3 + 27b^2 != 0 mod p)
//! - Adición de puntos secantes (P + Q)
//! - Duplicación de puntos tangentes (2P) con cálculo de la pendiente diferencial
//! - Multiplicación escalar binaria O(log k)
//! - Búsqueda de puntos mediante Tonelli-Shanks

const std = @import("std");
const arith = @import("../modular/arithmetic.zig");
pub const Point = @import("point.zig").Point;

pub const EllipticCurve = struct {
    a: u64,
    b: u64,
    p: u64,

    /// Inicializa una curva elíptica verificando que sea no-singular
    pub fn init(a: u64, b: u64, p: u64) !EllipticCurve {
        if (p < 3) return error.ModulusTooSmall;

        // Discriminante: 4a^3 + 27b^2 mod p != 0
        const a_mod = a % p;
        const b_mod = b % p;
        const a3 = arith.mulMod(arith.mulMod(a_mod, a_mod, p), a_mod, p);
        const b2 = arith.mulMod(b_mod, b_mod, p);
        const term1 = arith.mulMod(4, a3, p);
        const term2 = arith.mulMod(27, b2, p);
        const disc = arith.addMod(term1, term2, p);

        if (disc == 0) {
            return error.SingularCurve;
        }

        return .{
            .a = a_mod,
            .b = b_mod,
            .p = p,
        };
    }

    /// Curva estándar secp256k1 reducida al módulo p: y^2 = x^3 + 7 (mod p)
    pub fn initKoblitz(p: u64) !EllipticCurve {
        return try init(0, 7, p);
    }

    /// Comprueba si un punto pertenece a la curva elíptica
    pub fn isOnCurve(self: EllipticCurve, pt: Point) bool {
        if (pt.isInfinity()) return true;

        const x = pt.x % self.p;
        const y = pt.y % self.p;

        const lhs = arith.mulMod(y, y, self.p);

        const x2 = arith.mulMod(x, x, self.p);
        const x3 = arith.mulMod(x2, x, self.p);
        const ax = arith.mulMod(self.a, x, self.p);
        const rhs = arith.addMod(arith.addMod(x3, ax, self.p), self.b, self.p);

        return lhs == rhs;
    }

    /// Suma de dos puntos en la curva elíptica: R = P + Q
    pub fn add(self: EllipticCurve, p1: Point, p2: Point) Point {
        if (p1.isInfinity()) return p2;
        if (p2.isInfinity()) return p1;

        const x1 = p1.x % self.p;
        const y1 = p1.y % self.p;
        const x2 = p2.x % self.p;
        const y2 = p2.y % self.p;

        if (x1 == x2) {
            // Si las coordenadas x coinciden pero y1 != y2, son inversos (P + (-P) = O)
            // O si y1 == 0, la tangente es vertical (2P = O)
            if (y1 != y2 or y1 == 0) {
                return Point.infinityPoint();
            }
            // P1 == P2: duplicación
            return self.double(p1);
        }

        // Pendiente de la secante: lambda = (y2 - y1) / (x2 - x1) mod p
        const num = arith.subMod(y2, y1, self.p);
        const den = arith.subMod(x2, x1, self.p);
        const lambda = arith.divMod(num, den, self.p) orelse return Point.infinityPoint();

        // x3 = lambda^2 - x1 - x2 mod p
        const lam2 = arith.mulMod(lambda, lambda, self.p);
        const x3 = arith.subMod(arith.subMod(lam2, x1, self.p), x2, self.p);

        // y3 = lambda*(x1 - x3) - y1 mod p
        const x_diff = arith.subMod(x1, x3, self.p);
        const lam_xdiff = arith.mulMod(lambda, x_diff, self.p);
        const y3 = arith.subMod(lam_xdiff, y1, self.p);

        return Point.affine(x3, y3);
    }

    /// Duplicación de un punto en la curva: R = 2*P
    pub fn double(self: EllipticCurve, p1: Point) Point {
        if (p1.isInfinity()) return p1;

        const x1 = p1.x % self.p;
        const y1 = p1.y % self.p;

        if (y1 == 0) return Point.infinityPoint();

        // Pendiente tangente diferencial: lambda = (3*x1^2 + a) / (2*y1) mod p
        const lambda = self.tangentSlope(p1) orelse return Point.infinityPoint();

        // x3 = lambda^2 - 2*x1 mod p
        const lam2 = arith.mulMod(lambda, lambda, self.p);
        const two_x1 = arith.mulMod(2, x1, self.p);
        const x3 = arith.subMod(lam2, two_x1, self.p);

        // y3 = lambda*(x1 - x3) - y1 mod p
        const x_diff = arith.subMod(x1, x3, self.p);
        const lam_xdiff = arith.mulMod(lambda, x_diff, self.p);
        const y3 = arith.subMod(lam_xdiff, y1, self.p);

        return Point.affine(x3, y3);
    }

    /// Calcula la pendiente tangente diferencial en el punto: lambda = (3*x^2 + a) / (2*y) mod p
    pub fn tangentSlope(self: EllipticCurve, p1: Point) ?u64 {
        if (p1.isInfinity()) return null;
        const x1 = p1.x % self.p;
        const y1 = p1.y % self.p;
        if (y1 == 0) return null;

        const x1_sq = arith.mulMod(x1, x1, self.p);
        const num = arith.addMod(arith.mulMod(3, x1_sq, self.p), self.a, self.p);
        const den = arith.mulMod(2, y1, self.p);

        return arith.divMod(num, den, self.p);
    }

    /// Multiplicación escalar binaria: Q = k * P mediante algoritmo Double-and-Add en O(log k)
    pub fn scalarMul(self: EllipticCurve, k: u64, p1: Point) Point {
        if (k == 0 or p1.isInfinity()) return Point.infinityPoint();

        var res = Point.infinityPoint();
        var base = p1;
        var scalar = k;

        while (scalar > 0) {
            if ((scalar & 1) == 1) {
                res = self.add(res, base);
            }
            base = self.double(base);
            scalar >>= 1;
        }

        return res;
    }

    /// Encuentra la coordenada y válida para un x dado tal que (x, y) pertenezca a la curva
    pub fn findY(self: EllipticCurve, x: u64) ?u64 {
        const x_mod = x % self.p;
        const x2 = arith.mulMod(x_mod, x_mod, self.p);
        const x3 = arith.mulMod(x2, x_mod, self.p);
        const ax = arith.mulMod(self.a, x_mod, self.p);
        const rhs = arith.addMod(arith.addMod(x3, ax, self.p), self.b, self.p);

        return arith.sqrtMod(rhs, self.p);
    }

    /// Genera hasta 'max_points' puntos válidos sobre la curva explorando x en F_p
    pub fn generatePoints(
        self: EllipticCurve,
        allocator: std.mem.Allocator,
        max_points: usize,
    ) ![]Point {
        var list = std.ArrayList(Point).empty;
        defer list.deinit(allocator);

        var x: u64 = 0;
        while (x < self.p and list.items.len < max_points) : (x += 1) {
            if (self.findY(x)) |y| {
                try list.append(allocator, Point.affine(x, y));
                if (y != 0 and list.items.len < max_points) {
                    try list.append(allocator, Point.affine(x, self.p - y));
                }
            }
        }

        return list.toOwnedSlice(allocator);
    }
};
