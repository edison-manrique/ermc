// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Funciones base de activación y transformación simbólica
pub const Activation = enum {
    Identity,
    Sine,
    Cosine,
    Square,
    Cube,
    Exp,
    ExpNeg,
    Sqrt,
    InverseSquare,
    Inv,
    Ln,
    Tanh,
    Interaction,

    pub fn toSymbol(self: Activation) []const u8 {
        return switch (self) {
            .Identity => "id",
            .Sine => "sin",
            .Cosine => "cos",
            .Square => "sqr",
            .Cube => "cube",
            .Exp => "exp",
            .ExpNeg => "exp_neg",
            .Sqrt => "sqrt",
            .InverseSquare => "inv_sqr",
            .Inv => "inv",
            .Ln => "ln",
            .Tanh => "tanh",
            .Interaction => "*",
        };
    }
};

/// Estructura para una muestra individual de entrenamiento/inferencia
pub const Sample = struct {
    inputs: []const f64,
    target: f64,
};

/// Opciones de configuración para los algoritmos de resolución y regresión
pub const SolveOptions = struct {
    /// Umbral mínimo de parsimonia para SINDy / STLSQ (0.015 = 1.5%)
    parsimony_threshold: f64 = 0.015,
    /// Iteraciones del estimador M de Huber ponderado iterativamente
    max_irls_iters: usize = 2,
    /// Iteraciones máximas de STLSQ para podar coeficientes débiles
    max_stlsq_iters: usize = 8,
    /// Parámetro de ajuste de corte robusto para pérdida Huber
    huber_tuning: f64 = 1.345,
    /// Activar filtro noise-gate L2 en memoria para suprimir drift numérico
    noise_gate_l2: bool = true,
    /// Activar ajuste automático a constantes físicas y fracciones limpias
    snap_constants: bool = true,
};

/// Errores específicos del motor matemático ERMC y de aprendizaje
pub const ErmcError = error{
    SingularMatrix,
    EmptyDataset,
    DimensionMismatch,
    InvalidWindowSize,
    ConvergenceFailure,
    OutOfMemory,
};

/// Alias de compatibilidad
pub const MathMlError = ErmcError;
