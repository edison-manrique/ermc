// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Extended Dynamic Mode Decomposition (EDMD) y Operadores de Koopman
//!
//! Proporciona linealización global de sistemas dinámicos no lineales mediante elevación
//! (lifting) a un espacio de Hilbert de observables psi(x):
//! psi(x_{k+1}) \approx K * psi(x_k)
//!
//! Permite:
//! - Predicción lineal exacta a largo plazo de dinámicas altamente no lineales
//! - Extracción de autovalores continuos (tasas de amortiguamiento y frecuencias globales)
//! - Identificación de variedades lentas (slow manifolds) invariantes

const std = @import("std");
const math = std.math;
const matrix = @import("../linalg/matrix.zig");

/// Tipo de diccionario de funciones observables de elevación
pub const KoopmanBasis = enum {
    /// Solo el espacio de estados original (equivalente a DMD estándar)
    StateOnly,
    /// Estado + monomios cuadráticos e interacciones cruzadas x_i * x_j + constante 1
    Polynomial2,
    /// Estado + polinomios de grado 2 y grado 3 + constante 1
    Polynomial3,
};

/// Opciones de configuración para el ajuste de Koopman / EDMD
pub const KoopmanOptions = struct {
    basis: KoopmanBasis = .Polynomial2,
    /// Regularización Tikhonov Ridge sobre la matriz Gram G
    ridge_alpha: f64 = 1e-7,
};

/// Modelo entrenado del Operador de Koopman
pub const KoopmanModel = struct {
    allocator: std.mem.Allocator,
    state_dim: usize,
    lifted_dim: usize,
    basis: KoopmanBasis,
    /// Matriz de Koopman K de dimensión (lifted_dim x lifted_dim) en row-major
    K: []f64,

    pub fn deinit(self: *KoopmanModel) void {
        self.allocator.free(self.K);
    }

    /// Predice la trayectoria del sistema no lineal n_steps hacia adelante
    /// - `x0`: estado inicial de dimensión `state_dim`
    /// - `n_steps`: número de pasos temporales a proyectar
    /// - `out_traj`: buffer preasignado de dimensión `n_steps * state_dim`
    pub fn predict(self: *const KoopmanModel, x0: []const f64, n_steps: usize, out_traj: []f64) !void {
        if (x0.len != self.state_dim) return error.DimensionMismatch;
        if (out_traj.len < n_steps * self.state_dim) return error.DimensionMismatch;

        const N = self.lifted_dim;
        const d = self.state_dim;

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const z_curr = try temp_alloc.alloc(f64, N);
        const z_next = try temp_alloc.alloc(f64, N);

        // 1. Elevar estado inicial
        liftState(x0, z_curr, self.basis);

        // 2. Propagar linealmente en el espacio de observables: z_{k+1} = K * z_k
        for (0..n_steps) |step| {
            // Guardar proyección del estado (primeras d componentes)
            for (0..d) |j| {
                out_traj[step * d + j] = z_curr[j];
            }

            // Multiplicación matriz-vector: z_next = K * z_curr
            for (0..N) |row| {
                var sum: f64 = 0.0;
                const row_offset = row * N;
                for (0..N) |col| {
                    sum += self.K[row_offset + col] * z_curr[col];
                }
                z_next[row] = sum;
            }

            @memcpy(z_curr, z_next);
        }
    }
};

/// Calcula la dimensión del espacio de observables levantado
pub fn computeLiftedDimension(state_dim: usize, basis: KoopmanBasis) usize {
    switch (basis) {
        .StateOnly => return state_dim,
        .Polynomial2 => {
            // state (d) + quadratic combinations d*(d+1)/2 + constant (1)
            const quad_count = (state_dim * (state_dim + 1)) / 2;
            return state_dim + quad_count + 1;
        },
        .Polynomial3 => {
            const d = state_dim;
            const quad_count = (d * (d + 1)) / 2;
            const cubic_count = (d * (d + 1) * (d + 2)) / 6;
            return d + quad_count + cubic_count + 1;
        },
    }
}

/// Eleva un estado x a su vector de observables psi(x)
pub fn liftState(x: []const f64, out_psi: []f64, basis: KoopmanBasis) void {
    const d = x.len;

    // 1. Estados originales (proyección canónica directa)
    for (0..d) |i| {
        out_psi[i] = x[i];
    }

    if (basis == .StateOnly) return;

    var idx: usize = d;

    // 2. Términos cuadráticos: x_i * x_j para i <= j
    for (0..d) |i| {
        for (i..d) |j| {
            out_psi[idx] = x[i] * x[j];
            idx += 1;
        }
    }

    // 3. Términos cúbicos si aplica
    if (basis == .Polynomial3) {
        for (0..d) |i| {
            for (i..d) |j| {
                for (j..d) |k| {
                    out_psi[idx] = x[i] * x[j] * x[k];
                    idx += 1;
                }
            }
        }
    }

    // 4. Término constante 1.0
    out_psi[idx] = 1.0;
}

/// Ajusta el operador de Koopman de dimensión finita K a partir de pares de instantáneas (X, Y)
/// donde Y = F(X) representa la dinámica un paso adelante.
///
/// Resuelve el problema de mínimos cuadrados de Frobenius:
/// min || \Psi_Y - K * \Psi_X ||_F^2
/// que equivale a resolver: G * K^T = A^T
/// donde G = (1/M) * \Psi_X * \Psi_X^T y A = (1/M) * \Psi_Y * \Psi_X^T
pub fn fitKoopman(
    allocator: std.mem.Allocator,
    X: []const f64,
    Y: []const f64,
    n_snapshots: usize,
    state_dim: usize,
    options: KoopmanOptions,
) !KoopmanModel {
    if (n_snapshots == 0 or state_dim == 0) return error.EmptyDataset;
    if (X.len < n_snapshots * state_dim or Y.len < n_snapshots * state_dim) {
        return error.DimensionMismatch;
    }

    const N = computeLiftedDimension(state_dim, options.basis);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_alloc = arena.allocator();

    const psi_x = try temp_alloc.alloc(f64, N);
    const psi_y = try temp_alloc.alloc(f64, N);

    // Matrices de correlación espacial G (N x N) y A (N x N)
    const G = try temp_alloc.alloc(f64, N * N);
    const A = try temp_alloc.alloc(f64, N * N);
    @memset(G, 0.0);
    @memset(A, 0.0);

    const inv_m = 1.0 / @as(f64, @floatFromInt(n_snapshots));

    // 1. Acumular matrices G = (1/M) * \sum psi_x psi_x^T y A = (1/M) * \sum psi_y psi_x^T
    for (0..n_snapshots) |k| {
        const x_k = X[k * state_dim .. (k + 1) * state_dim];
        const y_k = Y[k * state_dim .. (k + 1) * state_dim];

        liftState(x_k, psi_x, options.basis);
        liftState(y_k, psi_y, options.basis);

        for (0..N) |i| {
            const px_i = psi_x[i];
            const py_i = psi_y[i];

            for (0..N) |j| {
                const px_j = psi_x[j];
                G[i * N + j] += px_i * px_j * inv_m;
                A[i * N + j] += py_i * px_j * inv_m;
            }
        }
    }

    // 2. Regularización Tikhonov en G
    for (0..N) |i| {
        G[i * N + i] += options.ridge_alpha;
    }

    // 3. Resolver para cada fila i de K: G * (K_{i,:})^T = (A_{i,:})^T
    const K = try allocator.alloc(f64, N * N);
    errdefer allocator.free(K);

    const rhs = try temp_alloc.alloc(f64, N);
    const sol_row = try temp_alloc.alloc(f64, N);

    for (0..N) |i| {
        // El vector rhs es la fila i de A: A[i, :]
        for (0..N) |j| {
            rhs[j] = A[i * N + j];
        }

        const ok = matrix.solveDenseSystem(temp_alloc, G, rhs, N, 0.0, sol_row) catch false;
        if (!ok) {
            // En caso de cuasi-singularidad severa, fallback a regularización aumentada
            _ = try matrix.solveDenseSystem(temp_alloc, G, rhs, N, 1e-4, sol_row);
        }

        for (0..N) |j| {
            K[i * N + j] = sol_row[j];
        }
    }

    return KoopmanModel{
        .allocator = allocator,
        .state_dim = state_dim,
        .lifted_dim = N,
        .basis = options.basis,
        .K = K,
    };
}
