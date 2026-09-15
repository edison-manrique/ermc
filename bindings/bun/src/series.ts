/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC — Series Analíticas: Ramanujan Mock Theta & Distribución de Primos
 * Wraps native Zig FFI for number theory and analytic series.
 */

import { getNativeLib } from "./ffi";

export interface SeriesLib {
  /**
   * Evalúa ln|f(-e^{-t})| de la Mock Theta Function de Ramanujan (orden 3).
   * Válido para t > 0. Converge a la asintótica de Watson para t → 0+.
   */
  mockThetaLn(t: number, maxTerms?: number): number;

  /**
   * Asintótica de Ramanujan-Watson: π²/(24t) - ½·ln(t) + ½·ln(π)
   * Predice ln|f(-e^{-t})| con error < 1% para t < 0.1.
   */
  watsonAsymptotic(t: number): number;

  /**
   * Número exacto de primos ≤ x usando la Criba de Eratóstenes hasta maxN.
   * @param maxN Límite superior de la criba (debe ser ≥ x)
   */
  primeCountPi(x: number, maxN?: number): number;

  /**
   * Integral Logarítmica Li(x) = ∫_2^x dt/ln(t) + 1.04516...
   * Aproxima π(x) con error < 3% para x > 100.
   */
  logarithmicIntegralLi(x: number): number;

  /**
   * Error relativo Li(x) vs π(x) exacto (%).
   * Valida la Hipótesis de Riemann numéricamente.
   */
  riemannError(x: number, maxN?: number): number;
}

export function getSeries(customPath?: string): SeriesLib {
  const lib = getNativeLib(customPath);
  const { symbols } = lib;

  return {
    mockThetaLn(t, maxTerms = 500) {
      return symbols.ermc_ramanujan_mock_theta_ln(t, BigInt(maxTerms));
    },

    watsonAsymptotic(t) {
      return symbols.ermc_ramanujan_watson_asymptotic(t);
    },

    primeCountPi(x, maxN = 100000) {
      return Number(symbols.ermc_prime_count_pi(x, BigInt(maxN)));
    },

    logarithmicIntegralLi(x) {
      return symbols.ermc_logarithmic_integral_li(x);
    },

    riemannError(x, maxN = 100000) {
      const pi = this.primeCountPi(x, maxN);
      const li = this.logarithmicIntegralLi(x);
      return Math.abs(li - pi) / pi * 100;
    },
  };
}
