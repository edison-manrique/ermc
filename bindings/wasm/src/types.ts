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

export type ActivationCode = Activation;

export interface OutlierDetectionResult {
  outliersCount: number;
  isOutlier: boolean[];
  cleanData: Float64Array;
}

export type OutlierResult = OutlierDetectionResult;

export interface SvdResult {
  u: Float64Array;
  s: Float64Array;
  v: Float64Array;
}

export interface ChaosResult {
  lyapunovExponent: number;
  predictabilityHorizon: number;
}

export interface ErmcWasmExports {
  memory: WebAssembly.Memory;
  ermc_version_wasm: (buf: number, maxLen: number) => number;
  ermc_alloc: (nBytes: number) => number;
  ermc_free: (ptr: number, nBytes: number) => void;

  // Hilbert
  ermc_hilbert_inner: (u: number, v: number, n: number) => number;
  ermc_hilbert_norm: (v: number, n: number) => number;
  ermc_hilbert_distance: (u: number, v: number, n: number) => number;
  ermc_hilbert_angle: (u: number, v: number, n: number) => number;

  // Precision
  ermc_precision_sum: (data: number, n: number) => number;

  // Outliers
  ermc_outliers_hampel: (
    data: number, n: number, k: number,
    out_mask: number, out_clean: number
  ) => number;

  // SVD
  ermc_svd: (
    matrix: number, m: number, n: number,
    out_u: number, out_s: number, out_v: number
  ) => boolean;

  // Sequence
  ermc_sequence_predict_next: (seq: number, n: number) => number;

  // DMD
  ermc_dmd_dominant_frequency: (
    snapshots: number, n_sensors: number, n_snaps: number, dt: number
  ) => number;

  // Chaos
  ermc_chaos_lorenz: (
    x0: number, y0: number, z0: number,
    out_lyap: number, out_horizon: number
  ) => boolean;

  // OmniEngine
  ermc_engine_create: (n_inputs: number) => number;
  ermc_engine_destroy: (handle: number) => void;
  ermc_engine_term_count: (handle: number) => number;
  ermc_engine_build_dictionary: (handle: number, codes: number, n: number) => boolean;
  ermc_engine_fit: (
    handle: number, flat_inputs: number, targets: number,
    n_samples: number, threshold: number, out_weights: number
  ) => number;
  ermc_engine_predict: (handle: number, input: number, weights: number) => number;
  ermc_engine_get_formula: (handle: number, weights: number, buf: number, maxLen: number) => number;

  // ── Aritmética Modular F_p (v0.4.0) ──────────────────────────────────────
  ermc_mod_add: (a: bigint, b: bigint, p: bigint) => bigint;
  ermc_mod_sub: (a: bigint, b: bigint, p: bigint) => bigint;
  ermc_mod_mul: (a: bigint, b: bigint, p: bigint) => bigint;
  ermc_mod_pow: (base: bigint, exp: bigint, p: bigint) => bigint;
  ermc_mod_inverse: (a: bigint, p: bigint) => bigint;
  ermc_mod_sqrt: (a: bigint, p: bigint) => bigint;

  // ── Curvas Elípticas y²=x³+7 mod p (v0.4.0) ─────────────────────────────
  ermc_ec_is_on_curve: (x: bigint, y: bigint, p: bigint) => number;
  ermc_ec_add: (px: bigint, py: bigint, qx: bigint, qy: bigint, p: bigint, out: number) => number;
  ermc_ec_scalar_mul: (k: bigint, px: bigint, py: bigint, p: bigint, out: number) => number;

  // ── Series Analíticas: Ramanujan & Primos (v0.4.0) ───────────────────────
  ermc_ramanujan_mock_theta_ln: (t: number, maxTerms: number) => number;
  ermc_ramanujan_watson_asymptotic: (t: number) => number;
  ermc_prime_count_pi: (x: number, maxN: number) => number;
  ermc_logarithmic_integral_li: (x: number) => number;
}
