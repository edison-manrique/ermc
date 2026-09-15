// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Tests estrictos para Familias de Polinomios Ortogonales y Algoritmo de Clenshaw

const std = @import("std");
const testing = std.testing;
const math = std.math;
const ermc = @import("ermc");
const orthogonal = ermc.orthogonal;

test "Chebyshev T - Exact analytical values and trigonometric identity" {
    const x = 0.6;

    // T_0(x) = 1
    try testing.expectEqual(@as(f64, 1.0), orthogonal.chebyshevT(0, x));

    // T_1(x) = x
    try testing.expectApproxEqAbs(x, orthogonal.chebyshevT(1, x), 1e-15);

    // T_2(x) = 2x^2 - 1
    const t2_expected = 2.0 * x * x - 1.0;
    try testing.expectApproxEqAbs(t2_expected, orthogonal.chebyshevT(2, x), 1e-15);

    // T_3(x) = 4x^3 - 3x
    const t3_expected = 4.0 * x * x * x - 3.0 * x;
    try testing.expectApproxEqAbs(t3_expected, orthogonal.chebyshevT(3, x), 1e-15);

    // T_4(x) = 8x^4 - 8x^2 + 1
    const t4_expected = 8.0 * math.pow(f64, x, 4.0) - 8.0 * x * x + 1.0;
    try testing.expectApproxEqAbs(t4_expected, orthogonal.chebyshevT(4, x), 1e-15);

    // T_5(x) = 16x^5 - 20x^3 + 5x
    const t5_expected = 16.0 * math.pow(f64, x, 5.0) - 20.0 * math.pow(f64, x, 3.0) + 5.0 * x;
    try testing.expectApproxEqAbs(t5_expected, orthogonal.chebyshevT(5, x), 1e-14);

    // Identidad trigonométrica T_n(cos(theta)) = cos(n * theta)
    const theta = 0.7853981633974483; // pi / 4
    const cos_theta = math.cos(theta);
    for (0..8) |n| {
        const expected = math.cos(@as(f64, @floatFromInt(n)) * theta);
        const computed = orthogonal.chebyshevT(n, cos_theta);
        try testing.expectApproxEqAbs(expected, computed, 1e-14);
    }
}

test "Chebyshev U - Exact analytical values" {
    const x = 0.5;

    // U_0(x) = 1
    try testing.expectEqual(@as(f64, 1.0), orthogonal.chebyshevU(0, x));

    // U_1(x) = 2x = 1.0
    try testing.expectApproxEqAbs(@as(f64, 1.0), orthogonal.chebyshevU(1, x), 1e-15);

    // U_2(x) = 4x^2 - 1 = 4(0.25) - 1 = 0
    try testing.expectApproxEqAbs(@as(f64, 0.0), orthogonal.chebyshevU(2, x), 1e-15);

    // U_3(x) = 8x^3 - 4x = 8(0.125) - 4(0.5) = 1 - 2 = -1
    try testing.expectApproxEqAbs(@as(f64, -1.0), orthogonal.chebyshevU(3, x), 1e-15);

    // U_4(x) = 16x^4 - 12x^2 + 1 = 16(0.0625) - 12(0.25) + 1 = 1 - 3 + 1 = -1
    try testing.expectApproxEqAbs(@as(f64, -1.0), orthogonal.chebyshevU(4, x), 1e-15);
}

test "Legendre P - Exact analytical values, Bonnet recurrence and symmetry" {
    const x = 0.4;

    // P_0(x) = 1
    try testing.expectEqual(@as(f64, 1.0), orthogonal.legendreP(0, x));

    // P_1(x) = x
    try testing.expectApproxEqAbs(x, orthogonal.legendreP(1, x), 1e-15);

    // P_2(x) = 0.5 * (3x^2 - 1)
    const p2_expected = 0.5 * (3.0 * x * x - 1.0);
    try testing.expectApproxEqAbs(p2_expected, orthogonal.legendreP(2, x), 1e-15);

    // P_3(x) = 0.5 * (5x^3 - 3x)
    const p3_expected = 0.5 * (5.0 * x * x * x - 3.0 * x);
    try testing.expectApproxEqAbs(p3_expected, orthogonal.legendreP(3, x), 1e-15);

    // P_4(x) = (35x^4 - 30x^2 + 3) / 8
    const p4_expected = (35.0 * math.pow(f64, x, 4.0) - 30.0 * x * x + 3.0) / 8.0;
    try testing.expectApproxEqAbs(p4_expected, orthogonal.legendreP(4, x), 1e-14);

    // Propiedades de contorno P_n(1) = 1 y P_n(-1) = (-1)^n
    for (0..10) |n| {
        try testing.expectApproxEqAbs(@as(f64, 1.0), orthogonal.legendreP(n, 1.0), 1e-14);
        const expected_neg = if (n % 2 == 0) @as(f64, 1.0) else @as(f64, -1.0);
        try testing.expectApproxEqAbs(expected_neg, orthogonal.legendreP(n, -1.0), 1e-14);
    }
}

test "Hermite H and He - Physics and Probability formulations" {
    const x = 1.5;

    // Hermite Físicos: H_0=1, H_1=2x, H_2=4x^2-2, H_3=8x^3-12x
    try testing.expectEqual(@as(f64, 1.0), orthogonal.hermiteH(0, x));
    try testing.expectApproxEqAbs(2.0 * x, orthogonal.hermiteH(1, x), 1e-15);
    try testing.expectApproxEqAbs(4.0 * x * x - 2.0, orthogonal.hermiteH(2, x), 1e-14);
    try testing.expectApproxEqAbs(8.0 * x * x * x - 12.0 * x, orthogonal.hermiteH(3, x), 1e-14);

    // Hermite Probabilistas: He_0=1, He_1=x, He_2=x^2-1, He_3=x^3-3x
    try testing.expectEqual(@as(f64, 1.0), orthogonal.hermiteHe(0, x));
    try testing.expectApproxEqAbs(x, orthogonal.hermiteHe(1, x), 1e-15);
    try testing.expectApproxEqAbs(x * x - 1.0, orthogonal.hermiteHe(2, x), 1e-15);
    try testing.expectApproxEqAbs(x * x * x - 3.0 * x, orthogonal.hermiteHe(3, x), 1e-14);
}

test "Laguerre L - Exact polynomial values" {
    const x = 2.0;

    // L_0(x) = 1
    try testing.expectEqual(@as(f64, 1.0), orthogonal.laguerreL(0, x));

    // L_1(x) = 1 - x
    try testing.expectApproxEqAbs(1.0 - x, orthogonal.laguerreL(1, x), 1e-15);

    // L_2(x) = 0.5 * (x^2 - 4x + 2)
    const l2_expected = 0.5 * (x * x - 4.0 * x + 2.0);
    try testing.expectApproxEqAbs(l2_expected, orthogonal.laguerreL(2, x), 1e-15);

    // L_3(x) = (-x^3 + 9x^2 - 18x + 6) / 6
    const l3_expected = (-x * x * x + 9.0 * x * x - 18.0 * x + 6.0) / 6.0;
    try testing.expectApproxEqAbs(l3_expected, orthogonal.laguerreL(3, x), 1e-15);

    // L_n(0) = 1 para todo n
    for (0..8) |n| {
        try testing.expectApproxEqAbs(@as(f64, 1.0), orthogonal.laguerreL(n, 0.0), 1e-15);
    }
}

test "Chebyshev Discrete Orthogonality on Gauss Nodes" {
    const allocator = testing.allocator;
    const n_nodes: usize = 12;
    const nodes = try orthogonal.chebyshevGaussNodes(allocator, n_nodes);
    defer allocator.free(nodes);

    try testing.expectEqual(n_nodes, nodes.len);

    // Comprobar ortogonalidad discreta: sum_{k=1}^N T_n(x_k) * T_m(x_k) = 0 para n != m
    const deg_n: usize = 2;
    const deg_m: usize = 4;

    var cross_sum: f64 = 0.0;
    for (nodes) |x_k| {
        cross_sum += orthogonal.chebyshevT(deg_n, x_k) * orthogonal.chebyshevT(deg_m, x_k);
    }

    // Ortogonalidad exacta a precisión de máquina
    try testing.expectApproxEqAbs(@as(f64, 0.0), cross_sum, 1e-14);

    // Norma cuadrática discreta: sum_{k=1}^N T_n(x_k)^2 = N / 2 = 6.0
    var norm_sum: f64 = 0.0;
    for (nodes) |x_k| {
        const val = orthogonal.chebyshevT(deg_n, x_k);
        norm_sum += val * val;
    }
    const expected_norm = @as(f64, @floatFromInt(n_nodes)) / 2.0;
    try testing.expectApproxEqAbs(expected_norm, norm_sum, 1e-14);
}

test "Clenshaw Algorithm vs Direct Recursive Summation" {
    // Serie: f(x) = 1.5 * T_0 + 0.8 * T_1 - 0.45 * T_2 + 0.12 * T_3 - 0.05 * T_4
    const coeffs = [_]f64{ 1.5, 0.8, -0.45, 0.12, -0.05 };

    const test_points = [_]f64{ -0.9, -0.5, 0.0, 0.35, 0.88 };

    for (test_points) |x| {
        // Evaluación directa término a término
        var direct_sum: f64 = 0.0;
        for (coeffs, 0..) |c, deg| {
            direct_sum += c * orthogonal.chebyshevT(deg, x);
        }

        // Evaluación rápida O(N) por Clenshaw
        const clenshaw_val = orthogonal.clenshawChebyshev(&coeffs, x);

        try testing.expectApproxEqAbs(direct_sum, clenshaw_val, 1e-14);
    }
}

test "High Degree Numeric Stability (T_30 at cos(pi/3) = 1.0)" {
    // Para x = 0.5 = cos(pi/3):
    // T_30(0.5) = cos(30 * pi/3) = cos(10 * pi) = 1.0 exactamente
    const val_30 = orthogonal.chebyshevT(30, 0.5);
    try testing.expectApproxEqAbs(@as(f64, 1.0), val_30, 1e-11);

    // T_24(0.5) = cos(24 * pi/3) = cos(8 * pi) = 1.0 exactamente
    const val_24 = orthogonal.chebyshevT(24, 0.5);
    try testing.expectApproxEqAbs(@as(f64, 1.0), val_24, 1e-12);
}

test "Orthogonal Vandermonde Matrix generation" {
    const x_samples = [_]f64{ -0.5, 0.0, 0.5 };
    const max_degree: usize = 2; // Columnas: deg 0, 1, 2 => 3 columnas
    var matrix: [3 * 3]f64 = undefined;

    orthogonal.fillOrthogonalVandermonde(.LegendreP, &x_samples, max_degree, &matrix);

    // Fila 0: x = -0.5 => [P_0(-0.5), P_1(-0.5), P_2(-0.5)] = [1.0, -0.5, 0.5*(3*0.25 - 1)] = [1.0, -0.5, -0.125]
    try testing.expectApproxEqAbs(@as(f64, 1.0), matrix[0], 1e-15);
    try testing.expectApproxEqAbs(@as(f64, -0.5), matrix[1], 1e-15);
    try testing.expectApproxEqAbs(@as(f64, -0.125), matrix[2], 1e-15);

    // Fila 1: x = 0.0 => [P_0(0), P_1(0), P_2(0)] = [1.0, 0.0, -0.5]
    try testing.expectApproxEqAbs(@as(f64, 1.0), matrix[3], 1e-15);
    try testing.expectApproxEqAbs(@as(f64, 0.0), matrix[4], 1e-15);
    try testing.expectApproxEqAbs(@as(f64, -0.5), matrix[5], 1e-15);
}
