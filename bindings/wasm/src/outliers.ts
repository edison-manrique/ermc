/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, writeF64, wasmAlloc, wasmFree, readMask, readF64 } from "./wasm";
import type { OutlierDetectionResult } from "./types";

/**
 * Detección de Outliers Extremos ($10^{100}$) mediante Filtro Hampel Normalizado (MAD en WebAssembly)
 */
export class Outliers {
  /**
   * Identifica anomalías severas sin desbordamiento numérico ni degradación de precisión
   * @param data Vector de observaciones
   * @param kThreshold Umbral en múltiplos de MAD normalizado (por defecto 3.0)
   */
  public static detectHampel(
    data: number[] | Float64Array,
    kThreshold: number = 3.0
  ): OutlierDetectionResult {
    const n = data.length;
    const dataPtr = writeF64(data);
    const maskPtr = wasmAlloc(n);
    const cleanPtr = wasmAlloc(n * 8);

    const count = getWasmExports().ermc_outliers_hampel(
      dataPtr,
      n,
      kThreshold,
      maskPtr,
      cleanPtr
    );

    const isOutlier = readMask(maskPtr, n);
    const cleanData = readF64(cleanPtr, n);

    wasmFree(dataPtr, n * 8);
    wasmFree(maskPtr, n);
    wasmFree(cleanPtr, n * 8);

    return {
      outliersCount: count,
      isOutlier,
      cleanData,
    };
  }
}
