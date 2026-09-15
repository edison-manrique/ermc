// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");
const Point = ermc.geometry.Point;
const EllipticCurve = ermc.geometry.EllipticCurve;
const GlvEndomorphism = ermc.geometry.GlvEndomorphism;

test "EllipticCurve: initialization and singularity detection" {
    // y^2 = x^3 + 7 (mod 1009) es no-singular (secp256k1 reducida)
    const curve = try EllipticCurve.initKoblitz(1009);
    try testing.expectEqual(@as(u64, 0), curve.a);
    try testing.expectEqual(@as(u64, 7), curve.b);
    try testing.expectEqual(@as(u64, 1009), curve.p);

    // Curva singular: y^2 = x^3 (a = 0, b = 0 => disc = 0)
    try testing.expectError(error.SingularCurve, EllipticCurve.init(0, 0, 1009));
}

test "EllipticCurve: point validation on curve" {
    const curve = try EllipticCurve.initKoblitz(97); // y^2 = x^3 + 7 (mod 97)

    // Punto en el infinito siempre pertenece a la curva
    try testing.expect(curve.isOnCurve(Point.infinityPoint()));

    // Para x = 1: 1^3 + 7 = 8 mod 97. 8 no es residuo mod 97.
    // Busquemos un x válido con findY:
    const y_opt = curve.findY(12);
    try testing.expect(y_opt != null); // 12^3 + 7 = 1728 + 7 = 1735 = 17*97 + 86 = 86 mod 97.
    // 34^2 = 1156 = 11*97 + 89... wait, findY devuelve raíz si existe
    const pt = Point.affine(12, y_opt.?);
    try testing.expect(curve.isOnCurve(pt));

    // Punto deliberadamente falso
    const fake_pt = Point.affine(12, (y_opt.? + 1) % 97);
    try testing.expect(!curve.isOnCurve(fake_pt));
}

test "EllipticCurve: group axioms (Identity and Inverse)" {
    const curve = try EllipticCurve.initKoblitz(1009);
    const y1 = (curve.findY(210)).?;
    const p1 = Point.affine(210, y1);
    try testing.expect(curve.isOnCurve(p1));

    const inf = Point.infinityPoint();

    // Identidad: P + O = P y O + P = P
    try testing.expect(curve.add(p1, inf).eq(p1));
    try testing.expect(curve.add(inf, p1).eq(p1));

    // Inverso: P + (-P) = O
    const neg_p1 = p1.negate(curve.p);
    try testing.expect(curve.isOnCurve(neg_p1));
    try testing.expect(curve.add(p1, neg_p1).isInfinity());
}

test "EllipticCurve: point addition and doubling" {
    const allocator = testing.allocator;
    const curve = try EllipticCurve.initKoblitz(1009);

    const pts = try curve.generatePoints(allocator, 5);
    defer allocator.free(pts);
    try testing.expect(pts.len >= 3);

    const p1 = pts[0];
    const p2 = pts[1];

    // Duplicación 2*P
    const double_p1 = curve.double(p1);
    try testing.expect(curve.isOnCurve(double_p1));

    // P + P debe ser igual a double(P)
    const add_self = curve.add(p1, p1);
    try testing.expect(add_self.eq(double_p1));

    // P1 + P2 debe estar en la curva
    const sum_p1_p2 = curve.add(p1, p2);
    try testing.expect(curve.isOnCurve(sum_p1_p2));
}

test "EllipticCurve: group associativity (P + Q) + R = P + (Q + R)" {
    const allocator = testing.allocator;
    const curve = try EllipticCurve.initKoblitz(1009);

    const pts = try curve.generatePoints(allocator, 6);
    defer allocator.free(pts);
    try testing.expect(pts.len >= 3);

    const p = pts[0];
    const q = pts[1];
    const r = pts[2];

    // (P + Q) + R
    const lhs = curve.add(curve.add(p, q), r);
    // P + (Q + R)
    const rhs = curve.add(p, curve.add(q, r));

    try testing.expect(lhs.eq(rhs));
}

test "EllipticCurve: scalar multiplication via double-and-add" {
    const allocator = testing.allocator;
    const curve = try EllipticCurve.initKoblitz(1009);

    const pts = try curve.generatePoints(allocator, 2);
    defer allocator.free(pts);
    const p = pts[0];

    // 0 * P = O
    try testing.expect(curve.scalarMul(0, p).isInfinity());

    // 1 * P = P
    try testing.expect(curve.scalarMul(1, p).eq(p));

    // 2 * P = double(P)
    try testing.expect(curve.scalarMul(2, p).eq(curve.double(p)));

    // 3 * P = 2*P + P
    const p3 = curve.scalarMul(3, p);
    const p2_plus_p1 = curve.add(curve.double(p), p);
    try testing.expect(p3.eq(p2_plus_p1));

    // 5 * P = 3*P + 2*P
    const p5 = curve.scalarMul(5, p);
    const p3_plus_p2 = curve.add(p3, curve.double(p));
    try testing.expect(p5.eq(p3_plus_p2));
}

test "GLV Endomorphism: O(1) acceleration on secp256k1" {
    const allocator = testing.allocator;
    const curve = try EllipticCurve.initKoblitz(1009);

    const glv = try GlvEndomorphism.init(curve);
    try testing.expect(glv.beta != 1);

    // Comprobar beta^3 = 1 mod p
    const beta3 = ermc.modular.arithmetic.mulMod(
        ermc.modular.arithmetic.mulMod(glv.beta, glv.beta, 1009),
        glv.beta,
        1009,
    );
    try testing.expectEqual(@as(u64, 1), beta3);

    // Obtener puntos sobre la curva y comprobar que phi(P) está en la curva
    const pts = try curve.generatePoints(allocator, 10);
    defer allocator.free(pts);

    for (pts) |pt| {
        try testing.expect(glv.verify(pt));
        const q = glv.apply(pt);
        // Q = (beta*x, y)
        try testing.expectEqual(pt.y, q.y);
        try testing.expectEqual(ermc.modular.arithmetic.mulMod(pt.x, glv.beta, 1009), q.x);
    }
}
