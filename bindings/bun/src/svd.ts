/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";
import type { SvdResult } from "./types";

/**
 * Descomposición en Valores Singulares (SVD) mediante algoritmo One-Sided Jacobi
 * Factoriza una matriz $A \in \mathbb{R}^{m \times n}$ en $A = U \Sigma V^T$.
 */
export class SVD {
  public static decompose(
    matrix: number[][],
    rows: number,
    cols: number,
    customPath?: string
  ): SvdResult {
    const flat = new Float64Array(rows * cols);
    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        flat[i * cols + j] = matrix[i][j];
      }
    }

    const outU = new Float64Array(rows * cols);
    const outS = new Float64Array(cols);
    const outV = new Float64Array(cols * cols);

    const lib = getNativeLib(customPath);
    const ok = lib.symbols.math_ml_svd(
      ptr(flat),
      BigInt(rows),
      BigInt(cols),
      ptr(outU),
      ptr(outS),
      ptr(outV)
    );

    if (!ok) {
      throw new Error("SVD no convergió o las dimensiones son incompatibles (requiere rows >= cols > 0)");
    }

    return { u: outU, s: outS, v: outV };
  }
}
