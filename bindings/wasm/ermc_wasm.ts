/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 *
 * ermc_wasm.ts — Loader y wrappers tipados para ermc.wasm
 *
 * Arquitectura de memoria:
 *   - WASM expone una memoria lineal (WebAssembly.Memory)
 *   - ermc_alloc(n) → devuelve un offset u32 en esa memoria
 *   - Escribimos datos con Float64Array/Uint8Array sobre ese offset
 *   - Llamamos la función exportada, leemos resultados del mismo buffer
 *   - ermc_free(ptr, n) libera la región
 */

import { readFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

// ===========================================================================
// TIPOS INTERNOS
// ===========================================================================

interface ErmcExports {
  memory: WebAssembly.Memory;
  ermc_version_wasm: (buf: number, maxLen: number) => number;
  ermc_alloc: (nBytes: number) => number;
  ermc_free: (ptr: number, nBytes: number) => void;

  // Hilbert
  ermc_hilbert_inner: (u: number, v: number, n: number) => number;
  ermc_hilbert_norm: (v: number, n: number) => number;
  ermc_hilbert_distance: (u: number, v: number, n: number) => number;
  ermc_hilbert_angle: (u: number, v: number, n: number) => number;

  // Precision
  ermc_precision_sum: (data: number, n: number) => number;

  // Outliers
  ermc_outliers_hampel: (
    data: number, n: number, k: number,
    out_mask: number, out_clean: number
  ) => number;

  // SVD
  ermc_svd: (
    matrix: number, m: number, n: number,
    out_u: number, out_s: number, out_v: number
  ) => boolean;

  // Sequence
  ermc_sequence_predict_next: (seq: number, n: number) => number;

  // DMD
  ermc_dmd_dominant_frequency: (
    snapshots: number, n_sensors: number, n_snaps: number, dt: number
  ) => number;

  // Chaos
  ermc_chaos_lorenz: (
    x0: number, y0: number, z0: number,
    out_lyap: number, out_horizon: number
  ) => boolean;

  // OmniEngine
  ermc_engine_create: (n_inputs: number) => number;
  ermc_engine_destroy: (handle: number) => void;
  ermc_engine_term_count: (handle: number) => number;
  ermc_engine_build_dictionary: (handle: number, codes: number, n: number) => boolean;
  ermc_engine_fit: (
    handle: number, flat_inputs: number, targets: number,
    n_samples: number, threshold: number, out_weights: number
  ) => number;
  ermc_engine_predict: (handle: number, input: number, weights: number) => number;
  ermc_engine_get_formula: (handle: number, weights: number, buf: number, maxLen: number) => number;
}

// ===========================================================================
// SINGLETON DE INSTANCIA WASM
// ===========================================================================

let _exports: ErmcExports | null = null;
let _mem: () => DataView;
let _f64: () => Float64Array;
let _u8: () => Uint8Array;
let _u32: () => Uint32Array;

export async function loadErmc(wasmPath?: string): Promise<void> {
  if (_exports) return;

  let resolvedPath = wasmPath;
  if (!resolvedPath) {
    const dir = dirname(fileURLToPath(import.meta.url));
    const candidates = [
      join(dir, "../../zig-out/wasm/ermc.wasm"),
      join(dir, "../../../zig-out/wasm/ermc.wasm"),
      join(process.cwd(), "zig-out/wasm/ermc.wasm"),
      join(process.cwd(), "../../zig-out/wasm/ermc.wasm"),
    ];
    for (const c of candidates) {
      if (existsSync(c)) {
        resolvedPath = c;
        break;
      }
    }
    if (!resolvedPath) resolvedPath = candidates[0];
  }

  const bytes = readFileSync(resolvedPath);
  const { instance } = await WebAssembly.instantiate(bytes, {
    // WASM freestanding no necesita imports del host
  });

  _exports = instance.exports as unknown as ErmcExports;

  // Views lazy (se reconstruyen si la memoria crece)
  _mem = () => new DataView(_exports!.memory.buffer);
  _f64 = () => new Float64Array(_exports!.memory.buffer);
  _u8 = () => new Uint8Array(_exports!.memory.buffer);
  _u32 = () => new Uint32Array(_exports!.memory.buffer);
}

// ===========================================================================
// HELPERS DE MEMORIA
// ===========================================================================

/** Escribe un array JS de f64 en la memoria WASM y retorna el puntero. */
function writeF64(arr: readonly number[]): number {
  const ptr = _exports!.ermc_alloc(arr.length * 8);
  if (ptr === 0) throw new Error("ermc_alloc failed");
  const view = _f64();
  for (let i = 0; i < arr.length; i++) view[(ptr >> 3) + i] = arr[i];
  return ptr;
}

/** Lee n valores f64 desde la memoria WASM a un array JS. */
function readF64(ptr: number, n: number): number[] {
  const view = _f64();
  return Array.from({ length: n }, (_, i) => view[(ptr >> 3) + i]);
}

/** Lee n bytes como boolean (0/1) desde la memoria WASM. */
function readMask(ptr: number, n: number): boolean[] {
  const view = _u8();
  return Array.from({ length: n }, (_, i) => view[ptr + i] !== 0);
}

/** Lee una string C desde la memoria WASM hasta null-terminator. */
function readCString(ptr: number, len: number): string {
  return new TextDecoder().decode(_u8().subarray(ptr, ptr + len));
}

/** Escribe un array u32 en la memoria WASM. */
function writeU32(arr: readonly number[]): number {
  const ptr = _exports!.ermc_alloc(arr.length * 4);
  if (ptr === 0) throw new Error("ermc_alloc u32 failed");
  const view = _u32();
  for (let i = 0; i < arr.length; i++) view[(ptr >> 2) + i] = arr[i];
  return ptr;
}

// ===========================================================================
// VERSION
// ===========================================================================

export function getVersion(): string {
  const bufPtr = _exports!.ermc_alloc(32);
  const len = _exports!.ermc_version_wasm(bufPtr, 32);
  const ver = readCString(bufPtr, len);
  _exports!.ermc_free(bufPtr, 32);
  return ver;
}

// ===========================================================================
// HILBERT SPACE
// ===========================================================================

export const HilbertSpace = {
  inner(u: number[], v: number[]): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = _exports!.ermc_hilbert_inner(uPtr, vPtr, n);
    _exports!.ermc_free(uPtr, n * 8);
    _exports!.ermc_free(vPtr, n * 8);
    return result;
  },

  norm(v: number[]): number {
    const n = v.length;
    const ptr = writeF64(v);
    const result = _exports!.ermc_hilbert_norm(ptr, n);
    _exports!.ermc_free(ptr, n * 8);
    return result;
  },

  distance(u: number[], v: number[]): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = _exports!.ermc_hilbert_distance(uPtr, vPtr, n);
    _exports!.ermc_free(uPtr, n * 8);
    _exports!.ermc_free(vPtr, n * 8);
    return result;
  },

  angle(u: number[], v: number[]): number {
    const n = u.length;
    const uPtr = writeF64(u);
    const vPtr = writeF64(v);
    const result = _exports!.ermc_hilbert_angle(uPtr, vPtr, n);
    _exports!.ermc_free(uPtr, n * 8);
    _exports!.ermc_free(vPtr, n * 8);
    return result;
  },
};

// ===========================================================================
// PRECISION
// ===========================================================================

export const Precision = {
  sum(data: number[]): number {
    const n = data.length;
    const ptr = writeF64(data);
    const result = _exports!.ermc_precision_sum(ptr, n);
    _exports!.ermc_free(ptr, n * 8);
    return result;
  },
};

// ===========================================================================
// OUTLIERS
// ===========================================================================

export interface OutlierResult {
  outliersCount: number;
  isOutlier: boolean[];
  cleanData: number[];
}

export const Outliers = {
  detectHampel(data: number[], kThreshold: number): OutlierResult {
    const n = data.length;
    const dataPtr = writeF64(data);
    const maskPtr = _exports!.ermc_alloc(n);
    const cleanPtr = _exports!.ermc_alloc(n * 8);

    const count = _exports!.ermc_outliers_hampel(dataPtr, n, kThreshold, maskPtr, cleanPtr);

    const isOutlier = readMask(maskPtr, n);
    const cleanData = readF64(cleanPtr, n);

    _exports!.ermc_free(dataPtr, n * 8);
    _exports!.ermc_free(maskPtr, n);
    _exports!.ermc_free(cleanPtr, n * 8);

    return { outliersCount: count, isOutlier, cleanData };
  },
};

// ===========================================================================
// SVD
// ===========================================================================

export interface SvdResult {
  u: number[];
  s: number[];
  v: number[];
}

export const SVD = {
  decompose(matrix: number[][], m: number, n: number): SvdResult {
    const flat = matrix.flat();
    const matPtr = writeF64(flat);
    const uPtr = _exports!.ermc_alloc(m * n * 8);
    const sPtr = _exports!.ermc_alloc(n * 8);
    const vPtr = _exports!.ermc_alloc(n * n * 8);

    const ok = _exports!.ermc_svd(matPtr, m, n, uPtr, sPtr, vPtr);

    const result: SvdResult = ok
      ? { u: readF64(uPtr, m * n), s: readF64(sPtr, n), v: readF64(vPtr, n * n) }
      : { u: [], s: [], v: [] };

    _exports!.ermc_free(matPtr, flat.length * 8);
    _exports!.ermc_free(uPtr, m * n * 8);
    _exports!.ermc_free(sPtr, n * 8);
    _exports!.ermc_free(vPtr, n * n * 8);

    return result;
  },
};

// ===========================================================================
// SEQUENCE AI
// ===========================================================================

export const SequenceAI = {
  predictNext(seq: number[]): number {
    const n = seq.length;
    const ptr = writeF64(seq);
    const result = _exports!.ermc_sequence_predict_next(ptr, n);
    _exports!.ermc_free(ptr, n * 8);
    return result;
  },
};

// ===========================================================================
// DMD
// ===========================================================================

export const DMD = {
  dominantFrequency(snapshots: number[][], dt: number): number {
    const nSensors = snapshots.length;
    const nSnaps = snapshots[0].length;
    const flat = snapshots.flat();
    const ptr = writeF64(flat);
    const result = _exports!.ermc_dmd_dominant_frequency(ptr, nSensors, nSnaps, dt);
    _exports!.ermc_free(ptr, flat.length * 8);
    return result;
  },
};

// ===========================================================================
// CHAOS
// ===========================================================================

export interface ChaosResult {
  lyapunovExponent: number;
  predictabilityHorizon: number;
}

export const Chaos = {
  analyzeLorenz(x0: number, y0: number, z0: number): ChaosResult {
    const lyapPtr = _exports!.ermc_alloc(8);
    const horizPtr = _exports!.ermc_alloc(8);

    const ok = _exports!.ermc_chaos_lorenz(x0, y0, z0, lyapPtr, horizPtr);
    const lyap = ok ? _mem().getFloat64(lyapPtr, true) : 0;
    const horiz = ok ? _mem().getFloat64(horizPtr, true) : 0;

    _exports!.ermc_free(lyapPtr, 8);
    _exports!.ermc_free(horizPtr, 8);

    return { lyapunovExponent: lyap, predictabilityHorizon: horiz };
  },
};

// ===========================================================================
// OMNI-ENGINE
// ===========================================================================

export const Activation = {
  Identity:    0,
  Sine:        1,
  Cosine:      2,
  Square:      3,
  Cube:        4,
  ExpNeg:      5,
  Sqrt:        6,
  Interaction: 7,
} as const;

export type ActivationCode = (typeof Activation)[keyof typeof Activation];

export class OmniEngine {
  private handle: number;
  private _nTerms: number = 0;
  readonly nInputs: number;

  constructor(nInputs: number) {
    this.nInputs = nInputs;
    this.handle = _exports!.ermc_engine_create(nInputs);
    if (this.handle === 0) throw new Error("ermc_engine_create failed");
    this._nTerms = _exports!.ermc_engine_term_count(this.handle);
  }

  buildDictionary(codes: ActivationCode[]): void {
    const ptr = writeU32(codes);
    _exports!.ermc_engine_build_dictionary(this.handle, ptr, codes.length);
    _exports!.ermc_free(ptr, codes.length * 4);
    this._nTerms = _exports!.ermc_engine_term_count(this.handle);
  }

  fit(inputs: number[][], targets: number[], threshold = 0.02): number[] {
    const nSamples = inputs.length;
    const flat = inputs.flat();
    const inPtr = writeF64(flat);
    const tgtPtr = writeF64(targets);
    const outPtr = _exports!.ermc_alloc(this._nTerms * 8);

    const nWeights = _exports!.ermc_engine_fit(
      this.handle, inPtr, tgtPtr, nSamples, threshold, outPtr
    );

    const weights = readF64(outPtr, nWeights);
    this._nTerms = nWeights;

    _exports!.ermc_free(inPtr, flat.length * 8);
    _exports!.ermc_free(tgtPtr, targets.length * 8);
    _exports!.ermc_free(outPtr, nWeights * 8);

    return weights;
  }

  predict(input: number[], weights: number[]): number {
    const inPtr = writeF64(input);
    const wPtr = writeF64(weights);
    const result = _exports!.ermc_engine_predict(this.handle, inPtr, wPtr);
    _exports!.ermc_free(inPtr, input.length * 8);
    _exports!.ermc_free(wPtr, weights.length * 8);
    return result;
  }

  getFormula(weights: number[]): string {
    const wPtr = writeF64(weights);
    const bufPtr = _exports!.ermc_alloc(512);
    const len = _exports!.ermc_engine_get_formula(this.handle, wPtr, bufPtr, 512);
    const formula = readCString(bufPtr, len);
    _exports!.ermc_free(wPtr, weights.length * 8);
    _exports!.ermc_free(bufPtr, 512);
    return formula;
  }

  getTermCount(): number {
    return _exports!.ermc_engine_term_count(this.handle);
  }

  dispose(): void {
    if (this.handle !== 0) {
      _exports!.ermc_engine_destroy(this.handle);
      this.handle = 0;
    }
  }

  [Symbol.dispose](): void { this.dispose(); }
}
