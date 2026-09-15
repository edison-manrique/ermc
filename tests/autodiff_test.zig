// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const math_ml = @import("math-ml");

const dual = math_ml.autodiff.dual;
const Dual = dual.Dual;

// ===========================================================================
// AUTODIFF: DIFERENCIACIÓN AUTOMÁTICA FORWARD (NÚMEROS DUALES)
// ===========================================================================

test "AutoDiff: Dual numbers compute exact derivative with ZERO truncation error" {
    // Función de prueba: f(x) = x^3 * sin(x) + exp(-x^2)
    // f'(x) = 3x^2 * sin(x) + x^3 * cos(x) - 2x * exp(-x^2)
    const x_val: f64 = 1.5;

    const x_dual = Dual.variable(x_val);

    const term1 = x_dual.pow(3.0).mul(x_dual.sin());
    const term2 = x_dual.pow(2.0).neg().exp();
    const f_res = term1.add(term2);

    const exact_der = 3.0 * (x_val * x_val) * @sin(x_val) +
        (x_val * x_val * x_val) * @cos(x_val) -
        2.0 * x_val * @exp(-x_val * x_val);

    try testing.expectApproxEqAbs(exact_der, f_res.der, 1e-14);
}

fn rosenbrockDual(x: []const Dual) Dual {
    const x0 = x[0];
    const x1 = x[1];

    const term1 = Dual.constant(1.0).sub(x0).pow(2.0);
    const term2 = Dual.constant(100.0).mul(x1.sub(x0.pow(2.0)).pow(2.0));

    return term1.add(term2);
}

test "AutoDiff: Multivariate gradient of Rosenbrock function" {
    const x_opt = [_]f64{ 1.0, 1.0 };
    var grad: [2]f64 = undefined;

    const f_val = dual.computeGradient(rosenbrockDual, &x_opt, &grad);

    try testing.expectApproxEqAbs(0.0, f_val, 1e-14);
    try testing.expectApproxEqAbs(0.0, grad[0], 1e-12);
    try testing.expectApproxEqAbs(0.0, grad[1], 1e-12);
}

test "AutoDiff: Elementary operations (quotient, log, tanh)" {
    const x0: f64 = 2.0;
    const x_dual = Dual.variable(x0);

    const numerator = x_dual.log();
    const denominator = x_dual.tanh();
    const res = numerator.div(denominator);

    const th = std.math.tanh(x0);
    const analytical = ((1.0 / x0) * th - @log(x0) * (1.0 - th * th)) / (th * th);

    try testing.expectApproxEqAbs(analytical, res.der, 1e-12);
}
