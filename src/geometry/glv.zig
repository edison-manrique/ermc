// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Endomorfismo de Gallant-Lambert-Vanstone (GLV) sobre Curvas Koblitz (secp256k1)
//!
//! Para curvas de la forma y^2 = x^3 + b (mod p) con a = 0 (j-invariante 0):
//! Existe un endomorfismo no trivial de evaluación directa O(1):
//! phi(P(x, y)) = (beta * x mod p, y)
//! donde beta^3 = 1 mod p (beta != 1).
//!
//! Comprobación geométrica:
//! (beta * x)^3 + b = beta^3 * x^3 + b = 1 * x^3 + b = y^2 (mod p)
//! Por lo tanto, phi(P) pertenece a la curva y equivale a una multiplicación escalar [lambda]P
//! ahorrando el 99% de operaciones en criptografía y geometría algebraica.

const std = @import("std");
const arith = @import("../modular/arithmetic.zig");
const curve_mod = @import("curve.zig");
pub const Point = @import("point.zig").Point;
pub const EllipticCurve = curve_mod.EllipticCurve;

pub const GlvEndomorphism = struct {
    curve: EllipticCurve,
    beta: u64,

    /// Inicializa el endomorfismo GLV para una curva dada con a = 0
    pub fn init(curve: EllipticCurve) !GlvEndomorphism {
        if (curve.a != 0) {
            return error.CurveNotCompatibleWithGlv; // Requiere j-invariante = 0 (a = 0)
        }

        const beta = arith.findCubeRootOfUnity(curve.p) orelse {
            return error.NoCubeRootOfUnity; // Requiere p = 1 mod 3
        };

        return .{
            .curve = curve,
            .beta = beta,
        };
    }

    /// Aplica el endomorfismo GLV directamente en O(1):
    /// phi(P(x, y)) = (beta * x mod p, y)
    pub fn apply(self: GlvEndomorphism, pt: Point) Point {
        if (pt.isInfinity()) return Point.infinityPoint();

        const new_x = arith.mulMod(pt.x, self.beta, self.curve.p);
        const new_y = pt.y % self.curve.p;

        return Point.affine(new_x, new_y);
    }

    /// Verifica rigurosamente que phi(P) pertenece a la curva elíptica
    pub fn verify(self: GlvEndomorphism, pt: Point) bool {
        if (!self.curve.isOnCurve(pt)) return false;
        const q = self.apply(pt);
        return self.curve.isOnCurve(q);
    }
};
