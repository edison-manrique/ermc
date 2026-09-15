// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Optimizador No Lineal Levenberg-Marquardt amortiguado y Gauss-Newton
//!
//! Minimiza la suma de cuadrados de residuos no lineales:
//! S(theta) = 0.5 * sum_{i=1}^M r_i(theta)^2 = 0.5 * ||r(theta)||^2_2
//!
//! Interpola dinámicamente entre descenso por gradiente (cuando la estimación está lejos
//! del óptimo) y el método de Gauss-Newton (convergencia cuadrática rápida cerca del mínimo),
//! garantizando robustez y ultra-precisión en el ajuste de parámetros físicos no lineales.

const std = @import("std");
const math = std.math;
const matrix = @import("../linalg/matrix.zig");
const Dual = @import("../autodiff/dual.zig").Dual;

/// Función de evaluación de residuos: r_i(theta) = modelo(x_i; theta) - y_i
pub const ResidualFn = *const fn (params: []const f64, residuals: []f64, ctx: ?*const anyopaque) void;

/// Función de evaluación de Jacobiano analítico: J_{i,j} = d r_i / d theta_j (dimensión M x P)
pub const JacobianFn = *const fn (params: []const f64, J: []f64, ctx: ?*const anyopaque) void;

/// Función de evaluación de residuo individual mediante diferenciación automática Forward
pub const DualResidualFn = *const fn (params: []const Dual, residual_index: usize, ctx: ?*const anyopaque) Dual;

/// Configuración del optimizador Levenberg-Marquardt
pub const LmOptions = struct {
    /// Iteraciones máximas
    max_iterations: usize = 150,
    /// Amortiguamiento inicial lambda
    initial_lambda: f64 = 1e-3,
    /// Factor de escala multiplicativo para lambda (aumentar o disminuir)
    lambda_factor: f64 = 10.0,
    /// Tolerancia de convergencia en norma infinita del gradiente ||J^T r||_inf
    tolerance_gradient: f64 = 1e-12,
    /// Tolerancia de convergencia en paso ||Delta theta||_2
    tolerance_step: f64 = 1e-12,
    /// Tolerancia de convergencia en reducción relativa de costo
    tolerance_cost: f64 = 1e-12,
};

/// Resultado de la optimización Levenberg-Marquardt
pub const LmResult = struct {
    params: []f64,
    final_cost: f64, // 0.5 * ||r||^2
    iterations: usize,
    converged: bool,
    gradient_norm: f64,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *LmResult) void {
        self.allocator.free(self.params);
    }
};

/// Calcula el Jacobiano numérico mediante diferencias finitas hacia adelante
/// si el usuario no proporciona derivadas analíticas ni diferenciación automática.
pub fn computeFiniteDifferenceJacobian(
    f_res: ResidualFn,
    params: []const f64,
    base_res: []const f64,
    m: usize,
    p: usize,
    J_out: []f64,
    allocator: std.mem.Allocator,
    ctx: ?*const anyopaque,
) !void {
    const eps: f64 = 1e-7;
    const temp_params = try allocator.dupe(f64, params);
    defer allocator.free(temp_params);

    const perturbed_res = try allocator.alloc(f64, m);
    defer allocator.free(perturbed_res);

    for (0..p) |j| {
        const orig = temp_params[j];
        temp_params[j] += eps;
        f_res(temp_params, perturbed_res, ctx);
        temp_params[j] = orig;

        for (0..m) |i| {
            J_out[i * p + j] = (perturbed_res[i] - base_res[i]) / eps;
        }
    }
}

/// Calcula el Jacobiano exacto usando diferenciación automática Dual forward-mode
pub fn computeAutoDiffJacobian(
    f_dual_res: DualResidualFn,
    params: []const f64,
    m: usize,
    p: usize,
    J_out: []f64,
    allocator: std.mem.Allocator,
    ctx: ?*const anyopaque,
) !void {
    const dual_params = try allocator.alloc(Dual, p);
    defer allocator.free(dual_params);

    for (0..p) |j| {
        // Inicializar parámetros duales: derivada = 1.0 en j, 0.0 en el resto
        for (0..p) |k| {
            dual_params[k] = if (k == j) Dual.variable(params[k]) else Dual.constant(params[k]);
        }

        // Evaluar derivadas exactas de cada residuo i respecto a theta_j
        for (0..m) |i| {
            const dual_res = f_dual_res(dual_params, i, ctx);
            J_out[i * p + j] = dual_res.der;
        }
    }
}

/// Optimiza un modelo no lineal minimizando sus residuos mediante Levenberg-Marquardt
pub fn minimizeLm(
    allocator: std.mem.Allocator,
    f_residuals: ResidualFn,
    opt_f_jacobian: ?JacobianFn,
    initial_params: []const f64,
    n_residuals: usize,
    options: LmOptions,
    ctx: ?*const anyopaque,
) !LmResult {
    const p = initial_params.len;
    const m = n_residuals;

    if (p == 0 or m < p) return error.DimensionMismatch;

    const current_params = try allocator.dupe(f64, initial_params);
    errdefer allocator.free(current_params);

    const candidate_params = try allocator.alloc(f64, p);
    defer allocator.free(candidate_params);

    const residuals = try allocator.alloc(f64, m);
    defer allocator.free(residuals);

    const candidate_residuals = try allocator.alloc(f64, m);
    defer allocator.free(candidate_residuals);

    const J = try allocator.alloc(f64, m * p);
    defer allocator.free(J);

    const JtJ = try allocator.alloc(f64, p * p);
    defer allocator.free(JtJ);

    const damped_A = try allocator.alloc(f64, p * p);
    defer allocator.free(damped_A);

    const neg_gradient = try allocator.alloc(f64, p); // -J^T * r
    defer allocator.free(neg_gradient);

    const delta_theta = try allocator.alloc(f64, p);
    defer allocator.free(delta_theta);

    // 1. Evaluación inicial de residuos y costo
    f_residuals(current_params, residuals, ctx);
    var current_cost: f64 = 0.0;
    for (residuals) |r| current_cost += 0.5 * r * r;

    var lambda = options.initial_lambda;
    var iterations: usize = 0;
    var converged = false;
    var grad_norm: f64 = 0.0;

    while (iterations < options.max_iterations) : (iterations += 1) {
        // 2. Calcular Jacobiano J (m x p)
        if (opt_f_jacobian) |f_jac| {
            f_jac(current_params, J, ctx);
        } else {
            try computeFiniteDifferenceJacobian(f_residuals, current_params, residuals, m, p, J, allocator, ctx);
        }

        // 3. Calcular J^T * J (p x p) y -J^T * r (p)
        @memset(JtJ, 0.0);
        @memset(neg_gradient, 0.0);

        for (0..p) |j| {
            for (0..m) |i| {
                const J_ij = J[i * p + j];
                neg_gradient[j] -= J_ij * residuals[i];

                for (j..p) |k| {
                    const val = J_ij * J[i * p + k];
                    JtJ[j * p + k] += val;
                    if (j != k) JtJ[k * p + j] += val;
                }
            }
        }

        // 4. Verificar criterio de gradiente ||J^T r||_inf
        grad_norm = 0.0;
        for (neg_gradient) |g| {
            const abs_g = @abs(g);
            if (abs_g > grad_norm) grad_norm = abs_g;
        }

        if (grad_norm < options.tolerance_gradient) {
            converged = true;
            break;
        }

        // 5. Bucle interno de amortiguamiento Levenberg-Marquardt
        var step_accepted = false;
        var inner_attempts: usize = 0;

        while (!step_accepted and inner_attempts < 10) : (inner_attempts += 1) {
            // Construir matriz amortiguada: damped_A = J^T J + lambda * diag(J^T J + I)
            @memcpy(damped_A, JtJ);
            for (0..p) |j| {
                const diag_elem = JtJ[j * p + j];
                const scale = if (diag_elem > 1e-9) diag_elem else 1.0;
                damped_A[j * p + j] += lambda * scale;
            }

            // Resolver sistema lineal: damped_A * delta_theta = neg_gradient
            const solved = matrix.solveDenseSystem(allocator, damped_A, neg_gradient, p, 0.0, delta_theta) catch false;
            if (!solved) {
                lambda *= options.lambda_factor;
                continue;
            }

            // Calcular parámetro candidato: theta_new = theta + delta_theta
            var step_norm_sq: f64 = 0.0;
            for (0..p) |j| {
                candidate_params[j] = current_params[j] + delta_theta[j];
                step_norm_sq += delta_theta[j] * delta_theta[j];
            }

            // Evaluar nuevo costo
            f_residuals(candidate_params, candidate_residuals, ctx);
            var candidate_cost: f64 = 0.0;
            for (candidate_residuals) |r| candidate_cost += 0.5 * r * r;

            // Criterio de aceptación: reducción estricta de costo
            if (candidate_cost < current_cost) {
                step_accepted = true;
                const cost_reduction = current_cost - candidate_cost;

                // Aceptar paso
                @memcpy(current_params, candidate_params);
                @memcpy(residuals, candidate_residuals);
                current_cost = candidate_cost;

                // Reducir amortiguamiento (más parecido a Gauss-Newton rápido)
                lambda /= options.lambda_factor;
                if (lambda < 1e-15) lambda = 1e-15;

                // Verificar criterios de parada por tamaño de paso o cambio relativo de costo
                if (math.sqrt(step_norm_sq) < options.tolerance_step or cost_reduction / (current_cost + 1e-12) < options.tolerance_cost) {
                    converged = true;
                    break;
                }
            } else {
                // Rechazar paso y aumentar amortiguamiento (más parecido a descenso por gradiente)
                lambda *= options.lambda_factor;
            }
        }

        if (converged) break;
    }

    return LmResult{
        .params = current_params,
        .final_cost = current_cost,
        .iterations = iterations,
        .converged = converged,
        .gradient_norm = grad_norm,
        .allocator = allocator,
    };
}
