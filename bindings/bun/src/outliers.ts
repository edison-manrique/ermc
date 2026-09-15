/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";
import type { OutlierDetectionResult } from "./types";

/**
 * Detección de Outliers Extremos ($10^{100}$) mediante Filtro Hampel Normalizado (MAD)
 */
export class Outliers {
  /**
   * Identifica anomalías severas sin desbordamiento numérico ni degradación de precisión
   * @param data Vector de observaciones
   * @param kThreshold Umbral en múltiplos de MAD normalizado (por defecto 3.0)
   */
  public static detectHampel(
    data: number[] | Float64Array,
    kThreshold: number = 3.0,
    customPath?: string
  ): OutlierDetectionResult {
    const arr = data instanceof Float64Array ? data : new Float64Array(data);
    const n = arr.length;
    const mask = new Uint8Array(n);
    const clean = new Float64Array(n);

    const lib = getNativeLib(customPath);
    const count = lib.symbols.math_ml_outliers_hampel(
      ptr(arr),
      BigInt(n),
      kThreshold,
      ptr(mask),
      ptr(clean)
    );

    return {
      outliersCount: Number(count),
      isOutlier: Array.from(mask).map((m) => m === 1),
      cleanData: clean,
    };
  }
}
