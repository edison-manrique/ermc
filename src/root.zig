// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Motor Modular de Inteligencia Artificial Matemática y Simbólica en Zig 0.16.0
//! Inspirado en Omni-Core (SciML / SINDy / Regresión Simbólica de Alta Precisión).
//! v2: Métricas, Integrador ODE, IRLS integrado, optimizaciones SIMD y Gram unificada.

pub const core = struct {
    pub const types = @import("core/types.zig");
    pub const rng = @import("core/rng.zig");
    pub const simd = @import("core/simd.zig");
    pub const precision = @import("core/precision.zig");

    pub const Activation = types.Activation;
    pub const Sample = types.Sample;
    pub const SolveOptions = types.SolveOptions;
    pub const MathMlError = types.MathMlError;
    pub const OmniRng = rng.OmniRng;

    // Aritmética Compensada v3
    pub const neumaierSum = precision.neumaierSum;
    pub const compensatedDot = precision.compensatedDot;
    pub const compensatedMeanVar = precision.compensatedMeanVar;
    pub const safeNorm = precision.safeNorm;
};

pub const linalg = struct {
    pub const matrix = @import("linalg/matrix.zig");
    pub const solver4x4 = @import("linalg/solver4x4.zig");
    pub const qr = @import("linalg/qr.zig");
    pub const hilbert = @import("linalg/hilbert.zig");
    pub const svd = @import("linalg/svd.zig");

    pub const DenseMatrix = matrix.DenseMatrix;
    pub const solve4x4 = solver4x4.solve4x4;
    pub const solveWeightedQrPreconditioned = qr.solveWeightedQrPreconditioned;
    pub const solveDenseSystem = matrix.solveDenseSystem;

    // Espacios de Hilbert v3
    pub const inner = hilbert.inner;
    pub const innerWeighted = hilbert.innerWeighted;
    pub const norm = hilbert.norm;
    pub const normWeighted = hilbert.normWeighted;
    pub const distance = hilbert.distance;
    pub const angle = hilbert.angle;
    pub const isOrthogonal = hilbert.isOrthogonal;
    pub const orthonormalizeMgsDgks = hilbert.orthonormalizeMgsDgks;
    pub const projectOntoSubspace = hilbert.projectOntoSubspace;
    pub const orthogonalComplement = hilbert.orthogonalComplement;
    pub const decomposeHilbert = hilbert.decomposeHilbert;
    pub const generateOrthogonalPolynomials = hilbert.generateOrthogonalPolynomials;
    pub const fitSpectralOrthogonal = hilbert.fitSpectralOrthogonal;

    // SVD v3
    pub const computeSvd = svd.computeSvd;
    pub const SvdResult = svd.SvdResult;
};

pub const stats = struct {
    pub const outliers = @import("stats/outliers.zig");

    pub const OutlierResult = outliers.OutlierResult;
    pub const computeExactMedian = outliers.computeExactMedian;
    pub const computeExactMad = outliers.computeExactMad;
    pub const detectOutliersHampel = outliers.detectOutliersHampel;
    pub const detectExtremeEsd = outliers.detectExtremeEsd;
};

pub const autodiff = struct {
    pub const dual = @import("autodiff/dual.zig");

    pub const Dual = dual.Dual;
    pub const computeGradient = dual.computeGradient;
};

pub const filter = struct {
    pub const savitzky_golay = @import("filter/savitzky_golay.zig");

    pub const FilterResult = savitzky_golay.FilterResult;
    pub const localSavitzkyGolayCubic = savitzky_golay.localSavitzkyGolayCubic;
};

pub const symbolic = struct {
    pub const activation = @import("symbolic/activation.zig");
    pub const dictionary = @import("symbolic/dictionary.zig");
    pub const snapping = @import("symbolic/snapping.zig");
    pub const formatter = @import("symbolic/formatter.zig");
    pub const orthogonal = @import("symbolic/orthogonal.zig");

    pub const ExpansionDictionary = dictionary.ExpansionDictionary;
    pub const snapToPhysicalConstantScaleInvariant = snapping.snapToPhysicalConstantScaleInvariant;
    pub const reconstructFormula = formatter.reconstructFormula;
    pub const formatEquation = formatter.formatEquation;
};

pub const solver = struct {
    pub const irls = @import("solver/irls.zig");
    pub const stlsq = @import("solver/stlsq.zig");
    pub const dynamical = @import("solver/dynamical.zig");
    pub const metrics = @import("solver/metrics.zig");
    pub const integrator = @import("solver/integrator.zig");
    pub const dmd = @import("solver/dmd.zig");
    pub const chaos = @import("solver/chaos.zig");

    pub const computeRobustSampleWeights = irls.computeRobustSampleWeights;
    pub const solveAnalyticalStlsq = stlsq.solveAnalyticalStlsq;
    pub const solveDynamicalSystem = dynamical.solveDynamicalSystem;
    pub const DynamicalResult = dynamical.DynamicalResult;

    // Métricas v2
    pub const mse = metrics.mse;
    pub const mae = metrics.mae;
    pub const rmse = metrics.rmse;
    pub const r2 = metrics.r2;
    pub const r2Adjusted = metrics.r2Adjusted;
    pub const maxAbsError = metrics.maxAbsError;
    pub const meanRelativeError = metrics.meanRelativeError;
    pub const activeCoefficients = metrics.activeCoefficients;

    // Integrador ODE v2
    pub const integrateRk4 = integrator.integrateRk4;
    pub const integrateEuler = integrator.integrateEuler;
    pub const OdeFn = integrator.OdeFn;
    pub const IntegrationResult = integrator.IntegrationResult;

    // DMD y Caos v3
    pub const computeDmd = dmd.computeDmd;
    pub const DmdResult = dmd.DmdResult;
    pub const DmdMode = dmd.DmdMode;
    pub const computeMaxLyapunovExponent = chaos.computeMaxLyapunovExponent;
    pub const ChaosAnalysisResult = chaos.ChaosAnalysisResult;
    pub const ChaosClassification = chaos.ChaosClassification;
};

pub const series = struct {
    pub const sequence_ai = @import("series/sequence_ai.zig");

    pub const SequenceAi = sequence_ai.SequenceAi;
    pub const SequenceBasis = sequence_ai.SequenceBasis;
};

pub const engine = @import("engine.zig");
pub const OmniEngine = engine.OmniEngine;

// Exportaciones directas ergonómicas
pub const Activation = core.Activation;
pub const Sample = core.Sample;
pub const SolveOptions = core.SolveOptions;
pub const ErmcError = core.ErmcError;
pub const MathMlError = core.MathMlError;
pub const OmniRng = core.OmniRng;
pub const SequenceAi = series.SequenceAi;
pub const DenseMatrix = linalg.DenseMatrix;
pub const Dual = autodiff.Dual;
pub const SvdResult = linalg.SvdResult;
pub const DmdResult = solver.DmdResult;
pub const OutlierResult = stats.OutlierResult;
pub const orthogonal = symbolic.orthogonal;
pub const OrthogonalFamily = symbolic.OrthogonalFamily;

