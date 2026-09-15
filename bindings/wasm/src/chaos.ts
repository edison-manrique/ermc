/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, wasmAlloc, wasmFree, getMemView } from "./wasm";
import type { ChaosResult } from "./types";

/**
 * Dinámica No Lineal y Detección de Caos Determinista (WebAssembly)
 * Diagnostica el atractor de Lorenz 63 midiendo la divergencia exponencial y el horizonte de predictibilidad.
 */
export class Chaos {
  /**
   * Integra la trayectoria en RK4 y calcula el Exponente Máximo de Lyapunov ($\lambda_{\max}$) y el tiempo de predictibilidad ($T_L = 1/\lambda$)
   */
  public static analyzeLorenz(
    x0: number = 1.0,
    y0: number = 1.0,
    z0: number = 1.0
  ): ChaosResult {
    const lyapPtr = wasmAlloc(8);
    const horizonPtr = wasmAlloc(8);

    const ok = getWasmExports().ermc_chaos_lorenz(
      x0,
      y0,
      z0,
      lyapPtr,
      horizonPtr
    );

    if (!ok) {
      wasmFree(lyapPtr, 8);
      wasmFree(horizonPtr, 8);
      throw new Error("Falló la integración dinámica o cálculo de Lyapunov en WebAssembly");
    }

    const mem = getMemView();
    const lyapunovExponent = mem.getFloat64(lyapPtr, true);
    const predictabilityHorizon = mem.getFloat64(horizonPtr, true);

    wasmFree(lyapPtr, 8);
    wasmFree(horizonPtr, 8);

    return {
      lyapunovExponent,
      predictabilityHorizon,
    };
  }
}
