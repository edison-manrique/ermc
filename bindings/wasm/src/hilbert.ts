/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { getWasmExports, writeF64, wasmFree } from "./wasm";

/**
 * Operaciones geométricas rigurosas en Espacios de Hilbert L^2 (WebAssembly)
 */
export class HilbertSpace {
  /** Producto interno $\langle u, v \rangle = \sum u_i v_i$ */
  public static inner(
    u: number[] | Float64Array,
    v: number[] | Float64Array
  ): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = getWasmExports().ermc_hilbert_inner(uPtr, vPtr, n);
    wasmFree(uPtr, n * 8);
    wasmFree(vPtr, n * 8);
    return result;
  }

  /** Norma inducida $\|v\|_H = \sqrt{\langle v, v \rangle}$ */
  public static norm(v: number[] | Float64Array): number {
    const n = v.length;
    const ptr = writeF64(v);
    const result = getWasmExports().ermc_hilbert_norm(ptr, n);
    wasmFree(ptr, n * 8);
    return result;
  }

  /** Distancia métrica $d(u, v) = \|u - v\|_H$ */
  public static distance(
    u: number[] | Float64Array,
    v: number[] | Float64Array
  ): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = getWasmExports().ermc_hilbert_distance(uPtr, vPtr, n);
    wasmFree(uPtr, n * 8);
    wasmFree(vPtr, n * 8);
    return result;
  }

  /** Ángulo en radianes $\theta = \arccos\left(\frac{\langle u, v \rangle}{\|u\| \|v\|}\right)$ */
  public static angle(
    u: number[] | Float64Array,
    v: number[] | Float64Array
  ): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = getWasmExports().ermc_hilbert_angle(uPtr, vPtr, n);
    wasmFree(uPtr, n * 8);
    wasmFree(vPtr, n * 8);
    return result;
  }
}
