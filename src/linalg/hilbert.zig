// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Módulo de Espacios de Hilbert y Proyecciones Ortogonales
//!
//! Implementa la formulación rigurosa de espacios con producto interno (pre-Hilbert y Hilbert finito):
//! - Productos internos Euclidianos y ponderados L^2: ⟨u, v⟩_w = ∑ w_i u_i v_i
//! - Norma inducida, distancia métrica y ángulo en el espacio de Hilbert
//! - Ortogonalización de Gram-Schmidt Modificada (MGS) con re-ortogonalización de Daniel-Gragg-Kahan-Stewart (DGKS)
//!   garantizando ortogonalidad a precisión de máquina (∼ 10^-15)
//! - Proyector ortogonal sobre subespacios W: P_W(v)
//! - Complemento ortogonal W^⟂ con verificación del Teorema de Pitágoras: ‖v‖² = ‖P_W(v)‖² + ‖v^⟂‖²
//! - Descomposición espectral de funciones mediante polinomios ortogonales discretos

const std = @import("std");
const simd = @import("../core/simd.zig");

/// Producto interno euclidiano estándar ⟨u, v⟩ = ∑ u_i * v_i
pub fn inner(u: []const f64, v: []const f64) f64 {
    std.debug.assert(u.len == v.len);
    return simd.dotProduct(u, v);
}

/// Producto interno ponderado en L^2 discreto: ⟨u, v⟩_w = ∑ w_i * u_i * v_i
pub fn innerWeighted(u: []const f64, v: []const f64, weights: []const f64) f64 {
    std.debug.assert(u.len == v.len and u.len == weights.len);
    var sum: f64 = 0.0;
    for (u, v, weights) |ui, vi, wi| {
        sum += wi * ui * vi;
    }
    return sum;
}

/// Norma inducida por el producto interno estándar: ‖v‖_H = √(⟨v, v⟩)
pub fn norm(v: []const f64) f64 {
    const val = inner(v, v);
    return if (val > 0.0) @sqrt(val) else 0.0;
}

/// Norma inducida por producto interno ponderado: ‖v‖_w = √(⟨v, v⟩_w)
pub fn normWeighted(v: []const f64, weights: []const f64) f64 {
    const val = innerWeighted(v, v, weights);
    return if (val > 0.0) @sqrt(val) else 0.0;
}

/// Distancia métrica inducida en el espacio de Hilbert: d_H(u, v) = ‖u - v‖_H
pub fn distance(u: []const f64, v: []const f64) f64 {
    std.debug.assert(u.len == v.len);
    var sumsq: f64 = 0.0;
    for (u, v) |ui, vi| {
        const diff = ui - vi;
        sumsq += diff * diff;
    }
    return @sqrt(sumsq);
}

/// Ángulo en radianes entre dos vectores en el espacio de Hilbert: θ = arccos(⟨u, v⟩ / (‖u‖ * ‖v‖))
pub fn angle(u: []const f64, v: []const f64) f64 {
    const nu = norm(u);
    const nv = norm(v);
    if (nu < 1e-15 or nv < 1e-15) return 0.0;
    var cos_theta = inner(u, v) / (nu * nv);
    cos_theta = std.math.clamp(cos_theta, -1.0, 1.0);
    return std.math.acos(cos_theta);
}

/// Comprueba si dos vectores son ortogonales dentro de una tolerancia ε
pub fn isOrthogonal(u: []const f64, v: []const f64, tol: f64) bool {
    return @abs(inner(u, v)) <= tol;
}

/// Ortogonalización de Gram-Schmidt Modificada con Re-ortogonalización DGKS (Daniel-Gragg-Kahan-Stewart)
///
/// Transforma un conjunto de k vectores v_0, ..., v_{k-1} en ℝ^m en una base ortonormal q_0, ..., q_{k-1}.
/// El paso de re-ortogonalización ("twice is enough") previene la pérdida catastrófica de ortogonalidad
/// provocada por el redondeo en aritmética de punto flotante en sistemas mal condicionados.
pub fn orthonormalizeMgsDgks(
    allocator: std.mem.Allocator,
    vectors: []const []const f64,
    out_orthonormal: []const []f64,
) !usize {
    const k = vectors.len;
    if (k == 0) return 0;
    const m = vectors[0].len;
    std.debug.assert(out_orthonormal.len >= k);

    var valid_count: usize = 0;

    for (0..k) |j| {
        std.debug.assert(vectors[j].len == m);
        std.debug.assert(out_orthonormal[valid_count].len == m);

        // Copiar vector original
        @memcpy(out_orthonormal[valid_count], vectors[j]);
        var q_j = out_orthonormal[valid_count];

        // Paso 1: Gram-Schmidt modificado contra los vectores ortonormales previos
        for (0..valid_count) |i| {
            const q_i = out_orthonormal[i];
            const proj = inner(q_j, q_i);
            for (0..m) |s| {
                q_j[s] -= proj * q_i[s];
            }
        }

        // Paso 2: Re-ortogonalización DGKS ("Twice is enough")
        for (0..valid_count) |i| {
            const q_i = out_orthonormal[i];
            const proj2 = inner(q_j, q_i);
            for (0..m) |s| {
                q_j[s] -= proj2 * q_i[s];
            }
        }

        // Paso 3: Normalización
        const q_norm = norm(q_j);
        if (q_norm > 1e-12) {
            const inv_norm = 1.0 / q_norm;
            for (0..m) |s| {
                q_j[s] *= inv_norm;
            }
            valid_count += 1;
        }
    }

    _ = allocator;
    return valid_count;
}

/// Proyección ortogonal de un vector v sobre el subespacio W generado por una base ortonormal {q_0, ..., q_{k-1}}:
/// P_W(v) = ∑_{i=0}^{k-1} ⟨v, q_i⟩ q_i
pub fn projectOntoSubspace(
    orthonormal_basis: []const []const f64,
    v: []const f64,
    out_proj: []f64,
) void {
    const m = v.len;
    std.debug.assert(out_proj.len == m);
    @memset(out_proj, 0.0);

    for (orthonormal_basis) |q| {
        std.debug.assert(q.len == m);
        const coeff = inner(v, q);
        for (0..m) |s| {
            out_proj[s] += coeff * q[s];
        }
    }
}

/// Complemento ortogonal: v^⟂ = v - P_W(v)
/// Garantiza matemáticamente que v^⟂ es ortogonal a todo vector en W: ⟨v^⟂, w⟩ = 0 ∀ w ∈ W
pub fn orthogonalComplement(
    orthonormal_basis: []const []const f64,
    v: []const f64,
    out_perp: []f64,
) void {
    const m = v.len;
    std.debug.assert(out_perp.len == m);

    // out_perp temporalmente almacena la proyección P_W(v)
    projectOntoSubspace(orthonormal_basis, v, out_perp);

    // v^⟂ = v - P_W(v)
    for (0..m) |s| {
        out_perp[s] = v[s] - out_perp[s];
    }
}

/// Resultado de la descomposición ortogonal en el espacio de Hilbert
pub const DecompositionResult = struct {
    proj_norm: f64,
    perp_norm: f64,
    total_norm: f64,
    orthogonality_error: f64, // |⟨P_W(v), v^⟂⟩|
    pythagorean_residual: f64, // |‖v‖² - (‖P_W(v)‖² + ‖v^⟂‖²)|
};

/// Descompone v = P_W(v) + v^⟂ y verifica el Teorema de Pitágoras en el Espacio de Hilbert
pub fn decomposeHilbert(
    orthonormal_basis: []const []const f64,
    v: []const f64,
    out_proj: []f64,
    out_perp: []f64,
) DecompositionResult {
    const m = v.len;
    std.debug.assert(out_proj.len == m and out_perp.len == m);

    // P_W(v)
    projectOntoSubspace(orthonormal_basis, v, out_proj);

    // v^⟂ = v - P_W(v)
    for (0..m) |s| {
        out_perp[s] = v[s] - out_proj[s];
    }

    const n_v = norm(v);
    const n_proj = norm(out_proj);
    const n_perp = norm(out_perp);

    const dot_proj_perp = @abs(inner(out_proj, out_perp));
    const pyth_res = @abs((n_v * n_v) - ((n_proj * n_proj) + (n_perp * n_perp)));

    return .{
        .proj_norm = n_proj,
        .perp_norm = n_perp,
        .total_norm = n_v,
        .orthogonality_error = dot_proj_perp,
        .pythagorean_residual = pyth_res,
    };
}

/// Generador de polinomios ortogonales discretos (tipo Legendre) sobre una grilla arbitraria x_0, ..., x_{m-1}
/// mediante ortogonalización de Gram-Schmidt sobre la base canónica de monomios {1, x, x^2, ..., x^d}.
pub fn generateOrthogonalPolynomials(
    allocator: std.mem.Allocator,
    grid: []const f64,
    max_degree: usize,
) ![][]f64 {
    const m = grid.len;
    const n_polys = max_degree + 1;

    // Reservar espacio para los monomios originales y los polinomios ortonormales
    var monomials = try allocator.alloc([]f64, n_polys);
    errdefer allocator.free(monomials);
    for (0..n_polys) |d| {
        monomials[d] = try allocator.alloc(f64, m);
    }
    defer {
        for (0..n_polys) |d| {
            allocator.free(monomials[d]);
        }
        allocator.free(monomials);
    }

    // Construir monomios p_d(x) = x^d
    for (0..m) |i| {
        const x = grid[i];
        var x_pow: f64 = 1.0;
        for (0..n_polys) |d| {
            monomials[d][i] = x_pow;
            x_pow *= x;
        }
    }

    // Reservar salida para la base ortonormal
    var ortho_polys = try allocator.alloc([]f64, n_polys);
    errdefer allocator.free(ortho_polys);
    for (0..n_polys) |d| {
        ortho_polys[d] = try allocator.alloc(f64, m);
    }

    // Orto-normalizar monomios mediante MGS-DGKS
    const valid = try orthonormalizeMgsDgks(allocator, monomials, ortho_polys);
    if (valid < n_polys) {
        for (valid..n_polys) |d| {
            allocator.free(ortho_polys[d]);
        }
        ortho_polys = try allocator.realloc(ortho_polys, valid);
    }

    return ortho_polys;
}

/// Realiza una aproximación espectral óptima de una función continua discreta f(x) en L^2
/// mediante la base polinomial ortonormal: f̂(x) = ∑ c_k * P_k(x) donde c_k = ⟨f, P_k⟩
pub fn fitSpectralOrthogonal(
    ortho_basis: []const []const f64,
    f_values: []const f64,
    out_approx: []f64,
    out_coeffs: []f64,
) void {
    const k = ortho_basis.len;
    const m = f_values.len;
    std.debug.assert(out_approx.len == m);
    std.debug.assert(out_coeffs.len >= k);

    @memset(out_approx, 0.0);

    for (0..k) |j| {
        const c_j = inner(f_values, ortho_basis[j]);
        out_coeffs[j] = c_j;
        for (0..m) |s| {
            out_approx[s] += c_j * ortho_basis[j][s];
        }
    }
}
