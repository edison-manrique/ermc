// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC Test Suite Runner
//!
//! Agrupa y ejecuta de manera modular todos los tests organizados por subsistema:
//! - core: RNG, SIMD, Precisión compensada Neumaier
//! - linalg: Matrices, Solucionador 4x4, QR, Espacios de Hilbert, SVD
//! - stats: Outliers extremos (Hampel, ESD, exact median/MAD)
//! - filter: Filtro y derivadas Savitzky-Golay
//! - symbolic: Activaciones, Diccionario, Snapping de constantes físicas, Formatter
//! - solver: STLSQ, Métricas (R², MSE), Integrador ODE (RK4, Euler), DMD, Caos y Lyapunov
//! - autodiff: Números duales, derivadas de orden de máquina, gradientes multivariados
//! - series: IA de sucesiones, predicción multi-paso

const std = @import("std");

test {
    _ = @import("core_test.zig");
    _ = @import("linalg_test.zig");
    _ = @import("stats_test.zig");
    _ = @import("filter_test.zig");
    _ = @import("symbolic_test.zig");
    _ = @import("orthogonal_test.zig");
    _ = @import("solver_test.zig");
    _ = @import("symplectic_test.zig");
    _ = @import("autodiff_test.zig");
    _ = @import("series_test.zig");
}
