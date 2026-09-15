/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib } from "./ffi";

/**
 * Operaciones geométricas rigurosas en Espacios de Hilbert L^2
 */
export class HilbertSpace {
  /** Producto interno $\langle u, v \rangle = \sum u_i v_i$ */
  public static inner(
    u: number[] | Float64Array,
    v: number[] | Float64Array,
    customPath?: string
  ): number {
    const n = u.length;
    const uArr = u instanceof Float64Array ? u : new Float64Array(u);
    const vArr = v instanceof Float64Array ? v : new Float64Array(v);
    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_hilbert_inner(ptr(uArr), ptr(vArr), BigInt(n));
  }

  /** Norma inducida $\|v\|_H = \sqrt{\langle v, v \rangle}$ */
  public static norm(
    v: number[] | Float64Array,
    customPath?: string
  ): number {
    const n = v.length;
    const vArr = v instanceof Float64Array ? v : new Float64Array(v);
    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_hilbert_norm(ptr(vArr), BigInt(n));
  }

  /** Distancia métrica $d(u, v) = \|u - v\|_H$ */
  public static distance(
    u: number[] | Float64Array,
    v: number[] | Float64Array,
    customPath?: string
  ): number {
    const n = u.length;
    const uArr = u instanceof Float64Array ? u : new Float64Array(u);
    const vArr = v instanceof Float64Array ? v : new Float64Array(v);
    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_hilbert_distance(ptr(uArr), ptr(vArr), BigInt(n));
  }

  /** Ángulo en radianes $\theta = \arccos\left(\frac{\langle u, v \rangle}{\|u\| \|v\|}\right)$ */
  public static angle(
    u: number[] | Float64Array,
    v: number[] | Float64Array,
    customPath?: string
  ): number {
    const n = u.length;
    const uArr = u instanceof Float64Array ? u : new Float64Array(u);
    const vArr = v instanceof Float64Array ? v : new Float64Array(v);
    const lib = getNativeLib(customPath);
    return lib.symbols.math_ml_hilbert_angle(ptr(uArr), ptr(vArr), BigInt(n));
  }
}
