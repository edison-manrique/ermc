/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, writeF64, wasmFree } from "./wasm";

/**
 * IA de Sucesiones Numéricas y Polinómicas (WebAssembly)
 * Deduce patrones no lineales y extrapola el siguiente término de la serie analíticamente.
 */
export class SequenceAI {
  /**
   * Predice el siguiente término de la secuencia matemática
   * @param sequence Array de números conocidos
   * @param snapInteger Si es true, ajusta a entero si la distancia a un entero es < 1e-5
   */
  public static predictNext(
    sequence: number[] | Float64Array,
    snapInteger: boolean = true
  ): number {
    const n = sequence.length;
    const ptr = writeF64(sequence);
    const rawVal = getWasmExports().ermc_sequence_predict_next(ptr, n);
    wasmFree(ptr, n * 8);

    if (snapInteger) {
      const nearestInt = Math.round(rawVal);
      if (Math.abs(rawVal - nearestInt) < 1e-5) {
        return nearestInt;
      }
    }

    return rawVal;
  }
}
