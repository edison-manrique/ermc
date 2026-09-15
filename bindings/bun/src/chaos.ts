/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";
import type { ChaosResult } from "./types";

/**
 * Dinámica No Lineal y Detección de Caos Determinista
 * Diagnostica el atractor de Lorenz 63 midiendo la divergencia exponencial y el horizonte de predictibilidad.
 */
export class Chaos {
  /**
   * Integra la trayectoria en RK4 y calcula el Exponente Máximo de Lyapunov ($\lambda_{\max}$) y el tiempo de predictibilidad ($T_L = 1/\lambda$)
   */
  public static analyzeLorenz(
    x0: number = 1.0,
    y0: number = 1.0,
    z0: number = 1.0,
    customPath?: string
  ): ChaosResult {
    const lyapBuf = new Float64Array(1);
    const horizonBuf = new Float64Array(1);
    const lib = getNativeLib(customPath);
    const ok = lib.symbols.math_ml_chaos_lorenz(
      x0,
      y0,
      z0,
      ptr(lyapBuf),
      ptr(horizonBuf)
    );

    if (!ok) {
      throw new Error("Falló la integración dinámica o cálculo de Lyapunov en Zig");
    }

    return {
      lyapunovExponent: lyapBuf[0],
      predictabilityHorizon: horizonBuf[0],
    };
  }
}
