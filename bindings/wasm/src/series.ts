/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC WASM — Series Analíticas: Ramanujan Mock Theta & Distribución de Primos (v0.4.0)
 */

import { getWasmExports } from "./wasm";

export interface WasmSeriesLib {
  /** ln|f(-e^{-t})| — Mock Theta de Ramanujan (orden 3) */
  mockThetaLn(t: number, maxTerms?: number): number;
  /** Asintótica de Ramanujan-Watson: π²/(24t) - ½ln(t) + ½ln(π) */
  watsonAsymptotic(t: number): number;
  /** Número exacto de primos ≤ x (criba hasta maxN) */
  primeCountPi(x: number, maxN?: number): number;
  /** Integral logarítmica Li(x) de Riemann */
  logarithmicIntegralLi(x: number): number;
  /** Error relativo Li(x) vs π(x) exacto (%) */
  riemannError(x: number, maxN?: number): number;
}

export function getWasmSeries(): WasmSeriesLib {
  const exp = getWasmExports();

  return {
    mockThetaLn(t, maxTerms = 500) {
      return exp.ermc_ramanujan_mock_theta_ln(t, maxTerms);
    },

    watsonAsymptotic(t) {
      return exp.ermc_ramanujan_watson_asymptotic(t);
    },

    primeCountPi(x, maxN = 100000) {
      return exp.ermc_prime_count_pi(x, maxN);
    },

    logarithmicIntegralLi(x) {
      return exp.ermc_logarithmic_integral_li(x);
    },

    riemannError(x, maxN = 100000) {
      const pi = this.primeCountPi(x, maxN);
      const li = this.logarithmicIntegralLi(x);
      return Math.abs(li - pi) / pi * 100;
    },
  };
}

export { getWasmSeries as getSeries };

