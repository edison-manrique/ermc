/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, writeF64, wasmFree } from "./wasm";

/**
 * Aritmética Compensada de Ultra-Precisión (Algoritmo de Neumaier en WebAssembly)
 * Previene errores de redondeo y cancelaciones catastróficas en punto flotante IEEE 754 de 64 bits.
 */
export class Precision {
  /**
   * Suma exacta con compensación de error en tiempo real
   * Preserva diferencias infinitesimales incluso ante magnitudes extremas (ej. [1e16, 1.0, -1e16] -> 1.0)
   */
  public static sum(data: number[] | Float64Array): number {
    const n = data.length;
    const ptr = writeF64(data);
    const result = getWasmExports().ermc_precision_sum(ptr, n);
    wasmFree(ptr, n * 8);
    return result;
  }
}
