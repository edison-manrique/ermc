/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, wasmAlloc, wasmFree, writeF64, readF64 } from "./wasm";
import type { SvdResult } from "./types";

/**
 * Descomposición en Valores Singulares (SVD) mediante algoritmo One-Sided Jacobi en WebAssembly
 * Factoriza una matriz $A \in \mathbb{R}^{m \times n}$ en $A = U \Sigma V^T$.
 */
export class SVD {
  public static decompose(
    matrix: number[][],
    rows: number,
    cols: number
  ): SvdResult {
    const flat = new Float64Array(rows * cols);
    for (let i = 0; i < rows; i++) {
      for (let j = 0; j < cols; j++) {
        flat[i * cols + j] = matrix[i][j];
      }
    }

    const matPtr = writeF64(flat);
    const uPtr = wasmAlloc(rows * cols * 8);
    const sPtr = wasmAlloc(cols * 8);
    const vPtr = wasmAlloc(cols * cols * 8);

    const ok = getWasmExports().ermc_svd(
      matPtr,
      rows,
      cols,
      uPtr,
      sPtr,
      vPtr
    );

    if (!ok) {
      wasmFree(matPtr, flat.length * 8);
      wasmFree(uPtr, rows * cols * 8);
      wasmFree(sPtr, cols * 8);
      wasmFree(vPtr, cols * cols * 8);
      throw new Error(
        "SVD no convergió o las dimensiones son incompatibles (requiere rows >= cols > 0)"
      );
    }

    const u = readF64(uPtr, rows * cols);
    const s = readF64(sPtr, cols);
    const v = readF64(vPtr, cols * cols);

    wasmFree(matPtr, flat.length * 8);
    wasmFree(uPtr, rows * cols * 8);
    wasmFree(sPtr, cols * 8);
    wasmFree(vPtr, cols * cols * 8);

    return { u, s, v };
  }
}
