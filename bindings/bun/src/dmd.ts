/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";

/**
 * Dynamic Mode Decomposition (DMD)
 * Técnica de reducción de orden y análisis modal de dinámica espaciotemporal en fluidos y física.
 */
export class DMD {
  /**
   * Extrae la frecuencia dominante (en radianes por segundo) a partir de snapshots multicanal
   * @param snapshots Matriz donde cada fila corresponde a un sensor y cada columna a un instante temporal
   * @param dt Intervalo de muestreo temporal entre snapshots sucesivos
   */
  public static dominantFrequency(
    snapshots: number[][],
    dt: number,
    customPath?: string
  ): number {
    const nSensors = snapshots.length;
    if (nSensors === 0) return 0.0;
    const nSnaps = snapshots[0].length;
    if (nSnaps === 0) return 0.0;

    const flat = new Float64Array(nSensors * nSnaps);
    for (let i = 0; i < nSensors; i++) {
      for (let j = 0; j < nSnaps; j++) {
        flat[i * nSnaps + j] = snapshots[i][j];
      }
    }

    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_dmd_dominant_frequency(
      ptr(flat),
      BigInt(nSensors),
      BigInt(nSnaps),
      dt
    );
  }
}
