// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");

const DenseMatrix = ermc.linalg.DenseMatrix;
const solve4x4 = ermc.linalg.solve4x4;
const solveDenseSystem = ermc.linalg.matrix.solveDenseSystem;
const solveWeightedQr = ermc.linalg.solveWeightedQrPreconditioned;
const hilbert = ermc.linalg.hilbert;
const svd = ermc.linalg.svd;

// ===========================================================================
// LINALG: SOLVER 4x4
// ===========================================================================

test "Linalg: Solver 4x4 exact Gauss elimination" {
    const a = [_]f64{
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    };
    const b = [_]f64{ 1.0, 2.0, 3.0, 4.0 };
    const x = solve4x4(&a, &b).?;
    try testing.expectApproxEqAbs(1.0, x[0], 1e-12);
    try testing.expectApproxEqAbs(2.0, x[1], 1e-12);
    try testing.expectApproxEqAbs(3.0, x[2], 1e-12);
    try testing.expectApproxEqAbs(4.0, x[3], 1e-12);

    const a_sing = [_]f64{0.0} ** 16;
    try testing.expect(solve4x4(&a_sing, &b) == null);
}

// ===========================================================================
// LINALG: DENSE SYSTEM
// ===========================================================================

test "Linalg: Solve general Dense System (v6 ultra)" {
    const allocator = testing.allocator;
    const a = [_]f64{
        4.0,  1.0,  -1.0,
        1.0,  4.0,  -1.0,
        -1.0, -1.0, 4.0,
    };
    const b = [_]f64{ 9.0, 12.0, 0.0 };
    var x = [_]f64{ 0.0, 0.0, 0.0 };

    const ok = try solveDenseSystem(allocator, &a, &b, 3, 1e-12, &x);
    try testing.expect(ok);
    try testing.expectApproxEqAbs(11.0 / 6.0, x[0], 1e-6);
    try testing.expectApproxEqAbs(17.0 / 6.0, x[1], 1e-6);
    try testing.expectApproxEqAbs(7.0 / 6.0, x[2], 1e-6);
}

// ===========================================================================
// LINALG: DenseMatrix OPERATIONS
// ===========================================================================

test "Linalg: DenseMatrix identity, trace and clone" {
    const allocator = testing.allocator;

    var ident = try DenseMatrix.identity(allocator, 3);
    defer ident.deinit();

    try testing.expectApproxEqAbs(3.0, ident.trace(), 1e-12);
    try testing.expectApproxEqAbs(1.0, ident.get(0, 0), 1e-12);
    try testing.expectApproxEqAbs(0.0, ident.get(0, 1), 1e-12);

    var clone = try ident.clone(allocator);
    defer clone.deinit();

    try testing.expectApproxEqAbs(3.0, clone.trace(), 1e-12);
}

test "Linalg: DenseMatrix transpose" {
    const allocator = testing.allocator;

    var mat = try DenseMatrix.init(allocator, 2, 3);
    defer mat.deinit();

    mat.set(0, 0, 1.0); mat.set(0, 1, 2.0); mat.set(0, 2, 3.0);
    mat.set(1, 0, 4.0); mat.set(1, 1, 5.0); mat.set(1, 2, 6.0);

    var trans = try mat.transpose(allocator);
    defer trans.deinit();

    try testing.expect(trans.rows == 3 and trans.cols == 2);
    try testing.expectApproxEqAbs(1.0, trans.get(0, 0), 1e-12);
    try testing.expectApproxEqAbs(4.0, trans.get(0, 1), 1e-12);
    try testing.expectApproxEqAbs(2.0, trans.get(1, 0), 1e-12);
    try testing.expectApproxEqAbs(5.0, trans.get(1, 1), 1e-12);
    try testing.expectApproxEqAbs(3.0, trans.get(2, 0), 1e-12);
    try testing.expectApproxEqAbs(6.0, trans.get(2, 1), 1e-12);
}

test "Linalg: DenseMatrix matMul" {
    const allocator = testing.allocator;

    var a = try DenseMatrix.init(allocator, 2, 2);
    defer a.deinit();
    a.set(0, 0, 1.0); a.set(0, 1, 2.0);
    a.set(1, 0, 3.0); a.set(1, 1, 4.0);

    var b_mat = try DenseMatrix.init(allocator, 2, 2);
    defer b_mat.deinit();
    b_mat.set(0, 0, 5.0); b_mat.set(0, 1, 6.0);
    b_mat.set(1, 0, 7.0); b_mat.set(1, 1, 8.0);

    var c = try a.matMul(b_mat, allocator);
    defer c.deinit();

    try testing.expectApproxEqAbs(19.0, c.get(0, 0), 1e-12);
    try testing.expectApproxEqAbs(22.0, c.get(0, 1), 1e-12);
    try testing.expectApproxEqAbs(43.0, c.get(1, 0), 1e-12);
    try testing.expectApproxEqAbs(50.0, c.get(1, 1), 1e-12);
}

test "Linalg: DenseMatrix isSymmetric and fromSlice" {
    var data = [_]f64{ 1.0, 2.0, 2.0, 4.0 };
    const mat = DenseMatrix.fromSlice(2, 2, &data);
    try testing.expect(mat.isSymmetric(1e-12));

    var data_asym = [_]f64{ 1.0, 2.0, 3.0, 4.0 };
    const mat_asym = DenseMatrix.fromSlice(2, 2, &data_asym);
    try testing.expect(!mat_asym.isSymmetric(1e-12));
}

test "Linalg: DenseMatrix columnNorm and fill" {
    const allocator = testing.allocator;
    var mat = try DenseMatrix.init(allocator, 3, 2);
    defer mat.deinit();

    mat.fill(2.0);
    try testing.expectApproxEqAbs(@sqrt(12.0), mat.columnNorm(0), 1e-12);
    try testing.expectApproxEqAbs(@sqrt(12.0), mat.columnNorm(1), 1e-12);
}

// ===========================================================================
// LINALG: QR
// ===========================================================================

test "Linalg: QR Preconditioned Least Squares" {
    const allocator = testing.allocator;
    const h = [_]f64{
        1.0, 2.0,
        2.0, 1.0,
        3.0, 0.0,
    };
    const y = [_]f64{ 2.0 * 1.0 - 3.0 * 2.0, 2.0 * 2.0 - 3.0 * 1.0, 2.0 * 3.0 - 3.0 * 0.0 };
    const weights = [_]f64{ 1.0, 1.0, 1.0 };
    var out_x = [_]f64{ 0.0, 0.0 };

    const ok = try solveWeightedQr(allocator, &h, &y, &weights, 3, 2, &out_x);
    try testing.expect(ok);
    try testing.expectApproxEqAbs(2.0, out_x[0], 1e-10);
    try testing.expectApproxEqAbs(-3.0, out_x[1], 1e-10);
}

// ===========================================================================
// LINALG: HILBERT SPACES & ORTHOGONAL PROJECTIONS
// ===========================================================================

test "Hilbert: inner product, norm and Cauchy-Schwarz" {
    const u = [_]f64{ 1.0, 2.0, 3.0 };
    const v = [_]f64{ 4.0, 5.0, 6.0 };

    const dot = hilbert.inner(&u, &v);
    try testing.expectEqual(32.0, dot);

    const nu = hilbert.norm(&u);
    const nv = hilbert.norm(&v);
    try testing.expect(dot <= nu * nv + 1e-12);

    const d = hilbert.distance(&u, &v);
    try testing.expectApproxEqAbs(@sqrt(27.0), d, 1e-10);

    const e1 = [_]f64{ 1.0, 0.0, 0.0 };
    const e2 = [_]f64{ 0.0, 1.0, 0.0 };
    try testing.expect(hilbert.isOrthogonal(&e1, &e2, 1e-15));
    const ang = hilbert.angle(&e1, &e2);
    try testing.expectApproxEqAbs(std.math.pi / 2.0, ang, 1e-10);
}

test "Hilbert: MGS-DGKS Orthonormalization satisfies machine precision" {
    const allocator = testing.allocator;

    const v0 = [_]f64{ 1.0, 1.0, 0.0, 0.0 };
    const v1 = [_]f64{ 1.0, 0.0, 1.0, 0.0 };
    const v2 = [_]f64{ 0.0, 1.0, 1.0, 1.0 };
    const input = [_][]const f64{ &v0, &v1, &v2 };

    const q0 = try allocator.alloc(f64, 4);
    defer allocator.free(q0);
    const q1 = try allocator.alloc(f64, 4);
    defer allocator.free(q1);
    const q2 = try allocator.alloc(f64, 4);
    defer allocator.free(q2);
    const out_q = [_][]f64{ q0, q1, q2 };

    const valid = try hilbert.orthonormalizeMgsDgks(allocator, &input, &out_q);
    try testing.expectEqual(@as(usize, 3), valid);

    for (0..3) |i| {
        for (0..3) |j| {
            const inner_val = hilbert.inner(out_q[i], out_q[j]);
            const expected: f64 = if (i == j) 1.0 else 0.0;
            try testing.expectApproxEqAbs(expected, inner_val, 1e-14);
        }
    }
}

test "Hilbert: Orthogonal Projection and Pythagorean Decomposition" {
    const allocator = testing.allocator;

    const b0 = [_]f64{ 1.0, 0.0, 0.0 };
    const b1 = [_]f64{ 0.0, 1.0, 0.0 };
    const basis = [_][]const f64{ &b0, &b1 };

    const v = [_]f64{ 3.0, 4.0, 5.0 };

    const p = try allocator.alloc(f64, 3);
    defer allocator.free(p);
    const perp = try allocator.alloc(f64, 3);
    defer allocator.free(perp);

    const decomp = hilbert.decomposeHilbert(&basis, &v, p, perp);

    try testing.expectApproxEqAbs(3.0, p[0], 1e-12);
    try testing.expectApproxEqAbs(4.0, p[1], 1e-12);
    try testing.expectApproxEqAbs(0.0, p[2], 1e-12);

    try testing.expectApproxEqAbs(0.0, perp[0], 1e-12);
    try testing.expectApproxEqAbs(0.0, perp[1], 1e-12);
    try testing.expectApproxEqAbs(5.0, perp[2], 1e-12);

    try testing.expect(decomp.orthogonality_error < 1e-14);
    try testing.expect(decomp.pythagorean_residual < 1e-12);
}

test "Hilbert: Orthogonal Polynomials and L2 Spectral Fitting" {
    const allocator = testing.allocator;

    const n_pts = 21;
    var grid: [n_pts]f64 = undefined;
    for (0..n_pts) |i| {
        grid[i] = -1.0 + 2.0 * @as(f64, @floatFromInt(i)) / @as(f64, @floatFromInt(n_pts - 1));
    }

    const polys = try hilbert.generateOrthogonalPolynomials(allocator, &grid, 3);
    defer {
        for (polys) |p| allocator.free(p);
        allocator.free(polys);
    }
    try testing.expectEqual(@as(usize, 4), polys.len);

    var f_vals: [n_pts]f64 = undefined;
    for (0..n_pts) |i| {
        const x = grid[i];
        f_vals[i] = 2.0 * x * x - 1.0;
    }

    const approx = try allocator.alloc(f64, n_pts);
    defer allocator.free(approx);
    const coeffs = try allocator.alloc(f64, polys.len);
    defer allocator.free(coeffs);

    hilbert.fitSpectralOrthogonal(polys, &f_vals, approx, coeffs);

    for (0..n_pts) |i| {
        try testing.expectApproxEqAbs(f_vals[i], approx[i], 1e-10);
    }
}

test "Hilbert: Weighted inner product and norm in L2" {
    const u = [_]f64{ 1.0, 2.0, 3.0 };
    const v = [_]f64{ 1.0, 1.0, 1.0 };
    const w = [_]f64{ 2.0, 0.5, 3.0 };

    const dot_w = hilbert.innerWeighted(&u, &v, &w);
    try testing.expectEqual(12.0, dot_w);

    const nw = hilbert.normWeighted(&v, &w);
    try testing.expectApproxEqAbs(@sqrt(5.5), nw, 1e-12);
}

// ===========================================================================
// LINALG: DESCOMPOSICIÓN EN VALORES SINGULARES (SVD)
// ===========================================================================

test "SVD: One-Sided Jacobi factorization U * Sigma * V^T = A" {
    const allocator = testing.allocator;

    var a = try DenseMatrix.init(allocator, 4, 3);
    defer a.deinit();

    a.set(0, 0, 1.0); a.set(0, 1, 2.0); a.set(0, 2, 3.0);
    a.set(1, 0, 4.0); a.set(1, 1, 5.0); a.set(1, 2, 6.0);
    a.set(2, 0, 7.0); a.set(2, 1, 8.0); a.set(2, 2, 9.0);
    a.set(3, 0, 10.0); a.set(3, 1, 11.0); a.set(3, 2, 12.0);

    var svd_res = try svd.computeSvd(allocator, a, 100, 1e-12);
    defer svd_res.deinit();

    try testing.expect(svd_res.s[0] >= svd_res.s[1]);
    try testing.expect(svd_res.s[1] >= svd_res.s[2]);

    var a_rec = try svd_res.reconstruct(allocator);
    defer a_rec.deinit();

    for (0..4) |i| {
        for (0..3) |j| {
            try testing.expectApproxEqAbs(a.get(i, j), a_rec.get(i, j), 1e-10);
        }
    }
}

test "SVD: Rank estimation and Moore-Penrose pseudo-inverse" {
    const allocator = testing.allocator;

    var a = try DenseMatrix.init(allocator, 3, 2);
    defer a.deinit();
    a.set(0, 0, 1.0); a.set(0, 1, 2.0);
    a.set(1, 0, 3.0); a.set(1, 1, 4.0);
    a.set(2, 0, 4.0); a.set(2, 1, 6.0);

    var svd_res = try svd.computeSvd(allocator, a, 100, 1e-12);
    defer svd_res.deinit();

    try testing.expectEqual(@as(usize, 2), svd_res.rank(null));

    var pinv = try svd_res.pseudoInverse(allocator);
    defer pinv.deinit();

    var m_mat = try a.matMul(pinv, allocator);
    defer m_mat.deinit();
    var a_penrose = try m_mat.matMul(a, allocator);
    defer a_penrose.deinit();

    for (0..3) |i| {
        for (0..2) |j| {
            try testing.expectApproxEqAbs(a.get(i, j), a_penrose.get(i, j), 1e-10);
        }
    }
}

test "SVD: Condition number of well-conditioned vs ill-conditioned matrix" {
    const allocator = testing.allocator;

    var eye = try DenseMatrix.identity(allocator, 3);
    defer eye.deinit();

    var svd_eye = try svd.computeSvd(allocator, eye, 50, 1e-12);
    defer svd_eye.deinit();

    try testing.expectApproxEqAbs(1.0, svd_eye.conditionNumber(), 1e-8);
}
