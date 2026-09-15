/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

/**
 * Funciones de activación y transformaciones simbólicas
 * Corresponden a enum Activation en src/core/types.zig
 */
export enum Activation {
  Identity = 0,
  Sine = 1,
  Cosine = 2,
  Square = 3,
  Cube = 4,
  Exp = 5,
  ExpNeg = 6,
  Sqrt = 7,
  InverseSquare = 8,
  Inv = 9,
  Ln = 10,
  Tanh = 11,
  Interaction = 12,
}

export interface OutlierDetectionResult {
  outliersCount: number;
  isOutlier: boolean[];
  cleanData: Float64Array;
}

export interface MeanVarResult {
  mean: number;
  variance: number;
}

export interface SvdResult {
  u: Float64Array;
  s: Float64Array;
  v: Float64Array;
}

export interface ChaosResult {
  lyapunovExponent: number;
  predictabilityHorizon: number;
}
