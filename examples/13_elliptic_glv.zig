// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

const arith = ermc.modular.arithmetic;
const GlvEndomorphism = ermc.GlvEndomorphism;
const EllipticCurve = ermc.EllipticCurve;
const Point = ermc.Point;

/// [EJEMPLO 13] CURVAS ELÍPTICAS Y ENDOMORFISMO GLV (secp256k1 reducida)
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 13] CURVAS ELÍPTICAS & ENDOMORFISMO GLV EN F_p\n", .{});
    std.debug.print(" >> y² = x³ + 7 (mod 1009) — secp256k1 reducida con φ(P) = (β·x, y)\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);
    const p: u64 = 1009;

    // Inicializar curva de Koblitz y^2 = x^3 + 7 (mod 1009)
    const curve = try EllipticCurve.initKoblitz(p);

    // Generar puntos sobre la curva
    const pts = try curve.generatePoints(allocator, 20);
    defer allocator.free(pts);

    const P = pts[0];
    const Q = pts[1];
    const R = pts[2];

    // Verificar leyes del grupo
    const lhs = curve.add(curve.add(P, Q), R);
    const rhs = curve.add(P, curve.add(Q, R));
    const assoc_ok = lhs.eq(rhs);

    const inf = Point.infinityPoint();
    const identity_ok = curve.add(P, inf).eq(P);
    const neg_P = P.negate(p);
    const inverse_ok = curve.add(P, neg_P).isInfinity();

    // Multiplicaciones escalares
    const p5 = curve.scalarMul(5, P);
    const p10 = curve.scalarMul(10, P);
    const p3_p2 = curve.add(curve.scalarMul(3, P), curve.scalarMul(2, P));
    const scalar_ok = p5.eq(p3_p2);

    // Endomorfismo GLV
    const glv = try GlvEndomorphism.init(curve);
    const b2 = arith.mulMod(glv.beta, glv.beta, p);
    const b3 = arith.mulMod(b2, glv.beta, p);

    // Verificar φ(P) sobre curva
    var phi_on_curve: usize = 0;
    for (pts[0..@min(10, pts.len)]) |pt| {
        const phi_pt = glv.apply(pt);
        if (curve.isOnCurve(phi_pt)) phi_on_curve += 1;
    }

    // Pendiente de duplicación: λ = 3x²/(2y) mod p (curva con a=0)
    const num = arith.mulMod(3, arith.mulMod(P.x, P.x, p), p);
    const den = arith.mulMod(2, P.y, p);
    const inv_den = arith.modInverse(den, p).?;
    const lambda = arith.mulMod(num, inv_den, p);
    const x_double = arith.subMod(arith.subMod(arith.mulMod(lambda, lambda, p), P.x, p), P.x, p);
    const double_P = curve.double(P);

    const dur = start.untilNow(io, .awake);
    const elapsed_ms = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1_000_000.0;

    std.debug.print("  >> Curva: y² = x³ + {d} (mod {d}) | β = {d} | β³ = {d} ✓\n", .{ curve.b, curve.p, glv.beta, b3 });
    std.debug.print("  >> P = ({d}, {d}), Q = ({d}, {d})\n", .{ P.x, P.y, Q.x, Q.y });
    std.debug.print("  >> Asociatividad (P+Q)+R = P+(Q+R): {}\n", .{assoc_ok});
    std.debug.print("  >> Identidad P + O = P: {}\n", .{identity_ok});
    std.debug.print("  >> Inverso P + (-P) = O: {}\n", .{inverse_ok});
    std.debug.print("  >> 5P = 3P + 2P: {}\n", .{scalar_ok});
    std.debug.print("  >> 10P = ({d}, {d})\n", .{ p10.x, p10.y });
    std.debug.print("  >> φ(P) sobre curva: {d}/10 puntos verificados ✓\n", .{phi_on_curve});
    std.debug.print("  >> λ(2P) = {d}, x(2P) fórmula = {d}, x(2P) directo = {d}\n", .{ lambda, x_double, double_P.x });
    std.debug.print(" > Tiempo aritmética curvas elípticas F_{d}: {d:.2} ms\n\n", .{ p, elapsed_ms });
}
