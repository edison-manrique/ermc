// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Familias de Polinomios Ortogonales Clásicos y Algoritmo de Clenshaw
//!
//! Proporciona evaluación por recurrencia de tres términos numéricamente estable,
//! evaluación de series mediante el algoritmo de Clenshaw O(N), generación de nodos
//! de interpolación óptima (Chebyshev-Gauss) y bases ortogonales para evitar el
//! mal condicionamiento en regresión simbólica polinómica de grado elevado.

const std = @import("std");
const math = std.math;

/// Familias de polinomios ortogonales soportadas
pub const OrthogonalFamily = enum {
    ChebyshevT, // Primera especie: T_n(x), ortogonal en [-1, 1] con w(x) = (1 - x^2)^(-1/2)
    ChebyshevU, // Segunda especie: U_n(x), ortogonal en [-1, 1] con w(x) = (1 - x^2)^(1/2)
    LegendreP,  // Legendre: P_n(x), ortogonal en [-1, 1] con w(x) = 1
    HermiteH,   // Hermite de Físicos: H_n(x), ortogonal en (-inf, inf) con w(x) = exp(-x^2)
    HermiteHe,  // Hermite de Probabilistas: He_n(x), ortogonal con w(x) = exp(-x^2/2)
    LaguerreL,  // Laguerre: L_n(x), ortogonal en [0, inf) con w(x) = exp(-x)
};

// ============================================================================
// EVALUACIÓN POR RECURRENCIA DE TRES TÉRMINOS
// ============================================================================

/// Evalúa el polinomio de Chebyshev de 1ª especie T_n(x)
/// Recurrencia: T_0 = 1, T_1 = x, T_{k+1} = 2x T_k - T_{k-1}
pub fn chebyshevT(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return x;

    var p0: f64 = 1.0;
    var p1: f64 = x;
    const two_x = 2.0 * x;

    for (2..n + 1) |_| {
        const p2 = two_x * p1 - p0;
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa el polinomio de Chebyshev de 2ª especie U_n(x)
/// Recurrencia: U_0 = 1, U_1 = 2x, U_{k+1} = 2x U_k - U_{k-1}
pub fn chebyshevU(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return 2.0 * x;

    var p0: f64 = 1.0;
    var p1: f64 = 2.0 * x;
    const two_x = 2.0 * x;

    for (2..n + 1) |_| {
        const p2 = two_x * p1 - p0;
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa el polinomio de Legendre P_n(x)
/// Recurrencia de Bonnet: (k+1) P_{k+1} = (2k+1) x P_k - k P_{k-1}
pub fn legendreP(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return x;

    var p0: f64 = 1.0;
    var p1: f64 = x;

    for (1..n) |k_usize| {
        const k: f64 = @floatFromInt(k_usize);
        const p2 = ((2.0 * k + 1.0) * x * p1 - k * p0) / (k + 1.0);
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa el polinomio de Hermite de Físicos H_n(x)
/// Recurrencia: H_0 = 1, H_1 = 2x, H_{k+1} = 2x H_k - 2k H_{k-1}
pub fn hermiteH(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return 2.0 * x;

    var p0: f64 = 1.0;
    var p1: f64 = 2.0 * x;
    const two_x = 2.0 * x;

    for (1..n) |k_usize| {
        const k: f64 = @floatFromInt(k_usize);
        const p2 = two_x * p1 - 2.0 * k * p0;
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa el polinomio de Hermite de Probabilistas He_n(x)
/// Recurrencia: He_0 = 1, He_1 = x, He_{k+1} = x He_k - k He_{k-1}
pub fn hermiteHe(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return x;

    var p0: f64 = 1.0;
    var p1: f64 = x;

    for (1..n) |k_usize| {
        const k: f64 = @floatFromInt(k_usize);
        const p2 = x * p1 - k * p0;
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa el polinomio de Laguerre L_n(x)
/// Recurrencia: L_0 = 1, L_1 = 1 - x, (k+1) L_{k+1} = (2k+1 - x) L_k - k L_{k-1}
pub fn laguerreL(n: usize, x: f64) f64 {
    if (n == 0) return 1.0;
    if (n == 1) return 1.0 - x;

    var p0: f64 = 1.0;
    var p1: f64 = 1.0 - x;

    for (1..n) |k_usize| {
        const k: f64 = @floatFromInt(k_usize);
        const p2 = ((2.0 * k + 1.0 - x) * p1 - k * p0) / (k + 1.0);
        p0 = p1;
        p1 = p2;
    }
    return p1;
}

/// Evalúa cualquier familia ortogonal por despacho estático
pub fn evaluate(family: OrthogonalFamily, n: usize, x: f64) f64 {
    return switch (family) {
        .ChebyshevT => chebyshevT(n, x),
        .ChebyshevU => chebyshevU(n, x),
        .LegendreP => legendreP(n, x),
        .HermiteH => hermiteH(n, x),
        .HermiteHe => hermiteHe(n, x),
        .LaguerreL => laguerreL(n, x),
    };
}

// ============================================================================
// ALGORITMO DE CLENSHAW (EVALUACIÓN DE SERIES EN O(N))
// ============================================================================

/// Evalúa una serie truncada de Chebyshev: f(x) = sum_{k=0}^{N-1} c_k * T_k(x)
/// mediante el algoritmo de Clenshaw numéricamente estable.
pub fn clenshawChebyshev(coeffs: []const f64, x: f64) f64 {
    const n = coeffs.len;
    if (n == 0) return 0.0;
    if (n == 1) return coeffs[0];

    const two_x = 2.0 * x;
    var b_next: f64 = 0.0;
    var b_curr: f64 = 0.0;

    var k = n;
    while (k > 1) {
        k -= 1;
        const b_prev = coeffs[k] + two_x * b_curr - b_next;
        b_next = b_curr;
        b_curr = b_prev;
    }

    // Para k = 0: f(x) = c_0 + x * b_1 - b_2
    return coeffs[0] + x * b_curr - b_next;
}

/// Evalúa una serie truncada de Legendre: f(x) = sum_{k=0}^{N-1} c_k * P_k(x)
/// usando el algoritmo de Clenshaw adaptado a la recurrencia de Legendre.
pub fn clenshawLegendre(coeffs: []const f64, x: f64) f64 {
    const n = coeffs.len;
    if (n == 0) return 0.0;
    if (n == 1) return coeffs[0];

    var b_next: f64 = 0.0;
    var b_curr: f64 = 0.0;

    var k = n;
    while (k > 1) {
        k -= 1;
        const k_f: f64 = @floatFromInt(k);
        // alpha_k = (2k+1)/(k+1) * x, beta_{k+1} = (k+1)/(k+2)
        const alpha = (2.0 * k_f + 1.0) / (k_f + 1.0) * x;
        const beta = (k_f + 1.0) / (k_f + 2.0);

        const b_prev = coeffs[k] + alpha * b_curr - (if (k + 1 < n) beta * b_next else 0.0);
        b_next = b_curr;
        b_curr = b_prev;
    }

    // Término final k = 0
    return coeffs[0] + x * b_curr - 0.5 * b_next;
}

// ============================================================================
// NODOS ÓPTIMOS DE INTERPOLACIÓN
// ============================================================================

/// Genera los N nodos de Chebyshev-Gauss (raíces de T_N(x)):
/// x_k = cos((2k - 1) * pi / (2N)), k = 1..N en [-1, 1]
pub fn chebyshevGaussNodes(allocator: std.mem.Allocator, n: usize) ![]f64 {
    if (n == 0) return error.EmptyDataset;
    const nodes = try allocator.alloc(f64, n);
    const n_f: f64 = @floatFromInt(n);

    for (0..n) |i| {
        const k: f64 = @floatFromInt(i + 1);
        const theta = ((2.0 * k - 1.0) * math.pi) / (2.0 * n_f);
        nodes[i] = math.cos(theta);
    }
    return nodes;
}

/// Genera los N nodos de Chebyshev-Gauss-Lobatto (extremos de T_{N-1}(x)):
/// x_k = cos(k * pi / (N - 1)), k = 0..N-1 en [-1, 1] (incluye extremos -1 y 1)
pub fn chebyshevLobattoNodes(allocator: std.mem.Allocator, n: usize) ![]f64 {
    if (n < 2) return error.EmptyDataset;
    const nodes = try allocator.alloc(f64, n);
    const denom: f64 = @floatFromInt(n - 1);

    for (0..n) |i| {
        const k: f64 = @floatFromInt(i);
        nodes[i] = math.cos((k * math.pi) / denom);
    }
    return nodes;
}

// ============================================================================
// MATRICES DE DISEÑO ORTOGONALES (VANDERMONDE GENERALIZADO)
// ============================================================================

/// Construye una matriz de diseño ortogonal de tamaño (n_samples x (max_degree + 1))
/// usando la familia ortogonal indicada: A[i, j] = Phi_j(x_i)
/// Esto previene la colinealidad catastrófica de las potencias estándar x^j.
pub fn fillOrthogonalVandermonde(
    family: OrthogonalFamily,
    x_samples: []const f64,
    max_degree: usize,
    out_matrix: []f64, // Memoria plana de tamaño n_samples * (max_degree + 1)
) void {
    const cols = max_degree + 1;
    for (x_samples, 0..) |x, i| {
        for (0..cols) |deg| {
            out_matrix[i * cols + deg] = evaluate(family, deg, x);
        }
    }
}
