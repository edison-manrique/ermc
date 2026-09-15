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

    // Integradores Simplécticos (Hamiltoniano)
    pub const symplectic = @import("solver/symplectic.zig");

    // Optimización No Lineal (Levenberg-Marquardt)
    pub const levenberg_marquardt = @import("solver/levenberg_marquardt.zig");

    // Descubrimiento Espacio-Temporal PDE-FIND
    pub const pdefind = @import("solver/pdefind.zig");

    // Operadores de Koopman y EDMD
    pub const koopman = @import("solver/koopman.zig");
};

pub const series = struct {
    pub const sequence_ai = @import("series/sequence_ai.zig");
    pub const asymptotics = @import("series/asymptotics.zig");

    pub const SequenceAi = sequence_ai.SequenceAi;
    pub const SequenceBasis = sequence_ai.SequenceBasis;
    pub const evaluateMockThetaLogSpace = asymptotics.evaluateMockThetaLogSpace;
    pub const ramanujanWatsonAsymptotic = asymptotics.ramanujanWatsonAsymptotic;
    pub const sievePrimes = asymptotics.sievePrimes;
    pub const primeCountPi = asymptotics.primeCountPi;
    pub const logarithmicIntegralLi = asymptotics.logarithmicIntegralLi;
};

pub const modular = struct {
    pub const arithmetic = @import("modular/arithmetic.zig");
    pub const linear_solver = @import("modular/solver.zig");
    pub const regression = @import("modular/regression.zig");

    pub const addMod = arithmetic.addMod;
    pub const subMod = arithmetic.subMod;
    pub const mulMod = arithmetic.mulMod;
    pub const divMod = arithmetic.divMod;
    pub const modPow = arithmetic.modPow;
    pub const modInverse = arithmetic.modInverse;
    pub const legendreSymbol = arithmetic.legendreSymbol;
    pub const isQuadraticResidue = arithmetic.isQuadraticResidue;
    pub const sqrtMod = arithmetic.sqrtMod;
    pub const findCubeRootOfUnity = arithmetic.findCubeRootOfUnity;
    pub const solveModularLinearSystem = linear_solver.solveModularLinearSystem;
    pub const fitModularRational = regression.fitModularRational;
    pub const ModularRegressionResult = regression.ModularRegressionResult;
    pub const ModularSample2D = regression.ModularSample2D;
};

pub const geometry = struct {
    pub const point = @import("geometry/point.zig");
    pub const curve = @import("geometry/curve.zig");
    pub const glv = @import("geometry/glv.zig");

    pub const Point = point.Point;
    pub const EllipticCurve = curve.EllipticCurve;
    pub const GlvEndomorphism = glv.GlvEndomorphism;
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
pub const symplectic = solver.symplectic;
pub const SymplecticAlgorithm = solver.symplectic.SymplecticAlgorithm;
pub const SymplecticResult = solver.symplectic.SymplecticResult;
pub const integrateSymplectic = solver.symplectic.integrateSymplectic;
pub const lm = solver.levenberg_marquardt;
pub const minimizeLm = solver.levenberg_marquardt.minimizeLm;
pub const LmOptions = solver.levenberg_marquardt.LmOptions;
pub const LmResult = solver.levenberg_marquardt.LmResult;
pub const pdefind = solver.pdefind;
pub const findPde = solver.pdefind.findPde;
pub const PdeFindOptions = solver.pdefind.PdeFindOptions;
pub const PdeFindResult = solver.pdefind.PdeFindResult;
pub const PdeTerm = solver.pdefind.PdeTerm;
pub const koopman = solver.koopman;
pub const fitKoopman = solver.koopman.fitKoopman;
pub const KoopmanBasis = solver.koopman.KoopmanBasis;
pub const KoopmanModel = solver.koopman.KoopmanModel;
pub const KoopmanOptions = solver.koopman.KoopmanOptions;

// Geometría y Aritmética Modular
pub const Point = geometry.Point;
pub const EllipticCurve = geometry.EllipticCurve;
pub const GlvEndomorphism = geometry.GlvEndomorphism;
pub const modInverse = modular.modInverse;
pub const modPow = modular.modPow;


