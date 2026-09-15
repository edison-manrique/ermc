// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");
const arith = ermc.modular.arithmetic;
const solver = ermc.modular.linear_solver;
const reg = ermc.modular.regression;

test "Modular arithmetic: basic operations and modInverse" {
    const p: u64 = 97;

    // Suma y resta
    try testing.expectEqual(@as(u64, 50), arith.addMod(25, 25, p));
    try testing.expectEqual(@as(u64, 0), arith.addMod(50, 47, p));
    try testing.expectEqual(@as(u64, 10), arith.subMod(30, 20, p));
    try testing.expectEqual(@as(u64, 90), arith.subMod(10, 17, p)); // 10 - 17 = -7 = 90 mod 97

    // Multiplicación: 10 * 49 = 490 = 5*97 + 5 => 5 mod 97
    try testing.expectEqual(@as(u64, 5), arith.mulMod(10, 49, 97));

    // Inverso modular
    // 3 * 65 = 195 = 2*97 + 1 => 3^(-1) mod 97 = 65
    const inv3 = arith.modInverse(3, 97);
    try testing.expect(inv3 != null);
    try testing.expectEqual(@as(u64, 65), inv3.?);
    try testing.expectEqual(@as(u64, 1), arith.mulMod(3, inv3.?, 97));

    // Inverso en primo grande
    const p_large: u64 = 1009;
    const inv2 = arith.modInverse(2, p_large);
    try testing.expectEqual(@as(u64, 505), inv2.?); // 2 * 505 = 1010 = 1 mod 1009

    // Elemento sin inverso (múltiplo de p)
    try testing.expect(arith.modInverse(97, 97) == null);
}

test "Modular arithmetic: modPow and Fermat Little Theorem" {
    const p: u64 = 1009;
    const a: u64 = 42;

    // Pequeño Teorema de Fermat: a^(p-1) = 1 mod p
    const fermat = arith.modPow(a, p - 1, p);
    try testing.expectEqual(@as(u64, 1), fermat);

    // a^0 = 1
    try testing.expectEqual(@as(u64, 1), arith.modPow(a, 0, p));
    // 2^10 = 1024 = 15 mod 1009
    try testing.expectEqual(@as(u64, 15), arith.modPow(2, 10, p));
}

test "Modular arithmetic: Legendre symbol and sqrtMod" {
    const p: u64 = 97;

    // 4 es residuo cuadrático: 2^2 = 4 mod 97
    try testing.expectEqual(@as(i8, 1), arith.legendreSymbol(4, p));
    const sqrt4 = arith.sqrtMod(4, p);
    try testing.expect(sqrt4 != null);
    try testing.expectEqual(@as(u64, 2), sqrt4.?);

    // Verificar que sqrtMod encuentra la raíz
    for ([_]u64{ 9, 16, 25, 36, 49 }) |sq| {
        const root = arith.sqrtMod(sq, p);
        try testing.expect(root != null);
        try testing.expectEqual(sq, arith.mulMod(root.?, root.?, p));
    }

    // Raíz cuadrada en p = 1009 (caso general p = 1 mod 4)
    const p1009: u64 = 1009; // 1009 = 1 mod 4
    const root1009 = arith.sqrtMod(100, p1009);
    try testing.expect(root1009 != null);
    try testing.expectEqual(@as(u64, 10), root1009.?);
}

test "Modular arithmetic: findCubeRootOfUnity" {
    // Para p = 1009 (1009 = 1 mod 3), debe existir beta tal que beta^3 = 1 mod 1009
    const beta = arith.findCubeRootOfUnity(1009);
    try testing.expect(beta != null);
    try testing.expect(beta.? != 1);

    const beta3 = arith.mulMod(arith.mulMod(beta.?, beta.?, 1009), beta.?, 1009);
    try testing.expectEqual(@as(u64, 1), beta3);

    // Para p = 11 ((11-1) % 3 != 0), no hay raíces cúbicas no triviales
    try testing.expect(arith.findCubeRootOfUnity(11) == null);
}

test "Modular solver: exact Gaussian elimination in F_p" {
    const allocator = testing.allocator;
    const p: u64 = 97;

    // Sistema 3x3 en F_97 con solución exacta w = [1, 3, 3]:
    // H = [[2,1,1],[1,3,1],[1,1,4]]
    // y = H * w = [2+3+3, 1+9+3, 1+3+12] = [8, 13, 16]
    const h = [_]u64{
        2, 1, 1,
        1, 3, 1,
        1, 1, 4,
    };
    const y = [_]u64{ 8, 13, 16 };

    const sol = try solver.solveModularLinearSystem(allocator, &h, &y, 3, 3, p);
    try testing.expect(sol != null);
    defer allocator.free(sol.?);

    try testing.expectEqual(@as(usize, 3), sol.?.len);
    try testing.expectEqual(@as(u64, 1), sol.?[0]);
    try testing.expectEqual(@as(u64, 3), sol.?[1]);
    try testing.expectEqual(@as(u64, 3), sol.?[2]);

    // Verificar: reconstituir H*sol y comparar con y
    try testing.expectEqual(y[0], arith.addMod(arith.addMod(arith.mulMod(h[0], sol.?[0], p), arith.mulMod(h[1], sol.?[1], p), p), arith.mulMod(h[2], sol.?[2], p), p));
    try testing.expectEqual(y[1], arith.addMod(arith.addMod(arith.mulMod(h[3], sol.?[0], p), arith.mulMod(h[4], sol.?[1], p), p), arith.mulMod(h[5], sol.?[2], p), p));
    try testing.expectEqual(y[2], arith.addMod(arith.addMod(arith.mulMod(h[6], sol.?[0], p), arith.mulMod(h[7], sol.?[1], p), p), arith.mulMod(h[8], sol.?[2], p), p));
}

test "Modular regression: symbolic discovery of rational tangent slope law" {
    const allocator = testing.allocator;
    const p: u64 = 1009;

    // Simulamos la ley de duplicación diferencial en una curva:
    // lambda = (3*x^2 + 7)/(2*y) mod 1009
    // Esto equivale a: lambda = (3/2) * (x^2/y) + (7/2) * (1/y) mod 1009
    // 3/2 mod 1009 = 3 * 505 mod 1009 = 1515 mod 1009 = 506
    // 7/2 mod 1009 = 7 * 505 mod 1009 = 3535 mod 1009 = 508
    const expected_w_x2_invy: u64 = 506;
    const expected_w_invy: u64 = 508;

    var samples: [20]reg.ModularSample2D = undefined;
    var seed: u64 = 12345;
    for (&samples) |*s| {
        seed = seed *% 6364136223846793005 +% 1442695040888963407;
        const x = seed % p;
        seed = seed *% 6364136223846793005 +% 1442695040888963407;
        var y = seed % p;
        if (y == 0) y = 1;

        const num = arith.addMod(arith.mulMod(3, arith.mulMod(x, x, p), p), 7, p);
        const den = arith.mulMod(2, y, p);
        const lambda = arith.divMod(num, den, p).?;

        s.* = .{ .x = x, .y = y, .target = lambda };
    }

    var res = (try reg.fitModularRational(allocator, &samples, p)).?;
    defer res.deinit();

    // Comprobar que los coeficientes descubiertos coinciden exactamente
    const idx_invy = @intFromEnum(reg.ModularFeature.InvY);
    const idx_x2_invy = @intFromEnum(reg.ModularFeature.X2_InvY);

    try testing.expectEqual(expected_w_invy, res.weights[idx_invy]);
    try testing.expectEqual(expected_w_x2_invy, res.weights[idx_x2_invy]);

    // Comprobar evaluación precisa
    const test_eval = res.evaluate(15, 30);
    const expected_eval = arith.divMod(
        arith.addMod(arith.mulMod(3, arith.mulMod(15, 15, p), p), 7, p),
        arith.mulMod(2, 30, p),
        p,
    ).?;
    try testing.expectEqual(expected_eval, test_eval);
}
