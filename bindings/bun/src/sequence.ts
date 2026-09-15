/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";

/**
 * IA de Sucesiones Numéricas y Polinómicas
 * Deduce patrones no lineales y extrapola el siguiente término de la serie analíticamente.
 */
export class SequenceAI {
  /**
   * Predice el siguiente término de la secuencia matemática
   * @param sequence Array de números conocidos
   * @param snapInteger Si es true, ajusta a entero si la distancia a un entero es < 1e-5 (elimina ruido numérico)
   */
  public static predictNext(
    sequence: number[] | Float64Array,
    snapInteger: boolean = true,
    customPath?: string
  ): number {
    const arr = sequence instanceof Float64Array ? sequence : new Float64Array(sequence);
    const lib = getNativeLib(customPath);
    const rawVal = lib.symbols.math_ml_sequence_predict_next(ptr(arr), BigInt(arr.length));

    if (snapInteger) {
      const nearestInt = Math.round(rawVal);
      if (Math.abs(rawVal - nearestInt) < 1e-5) {
        return nearestInt;
      }
    }

    return rawVal;
  }
}
