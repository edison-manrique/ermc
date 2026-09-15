/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";
import type { MeanVarResult } from "./types";

/**
 * Aritmética Compensada de Ultra-Precisión (Algoritmo de Neumaier)
 * Previene errores de redondeo y cancelaciones catastróficas en punto flotante IEEE 754 de 64 bits.
 */
export class Precision {
  /**
   * Suma exacta con compensación de error en tiempo real
   * Preserva diferencias infinitesimales incluso ante magnitudes extremas (ej. [1e16, 1.0, -1e16] -> 1.0)
   */
  public static sum(data: number[] | Float64Array, customPath?: string): number {
    const arr = data instanceof Float64Array ? data : new Float64Array(data);
    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_precision_sum(ptr(arr), BigInt(arr.length));
  }

  /**
   * Calcula la media aritmética y varianza muestral mediante corrección compensada de dos pasos
   */
  public static meanVar(
    data: number[] | Float64Array,
    customPath?: string
  ): MeanVarResult {
    const arr = data instanceof Float64Array ? data : new Float64Array(data);
    const meanBuf = new Float64Array(1);
    const varBuf = new Float64Array(1);
    const lib = getNativeLib(customPath);
    lib.symbols.math_ml_precision_mean_var(
      ptr(arr),
      BigInt(arr.length),
      ptr(meanBuf),
      ptr(varBuf)
    );
    return { mean: meanBuf[0], variance: varBuf[0] };
  }
}
