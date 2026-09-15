/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { dlopen, FFIType } from "bun:ffi";
import { resolve } from "path";
import { existsSync } from "fs";

// Ruta por defecto a la biblioteca DLL compartida generada por Zig
const ermcPath = resolve(import.meta.dir, "../../../zig-out/bin/ermc.dll");
const mathMlPath = resolve(import.meta.dir, "../../../zig-out/bin/math_ml.dll");
export const defaultDllPath = existsSync(ermcPath) ? ermcPath : mathMlPath;

export type NativeSymbols = ReturnType<typeof loadNativeSymbols>;

let cachedLib: NativeSymbols | null = null;

export function getNativeLib(customPath?: string): NativeSymbols {
  if (!cachedLib) {
    const libPath = customPath || defaultDllPath;
    cachedLib = loadNativeSymbols(libPath);
  }
  return cachedLib;
}

function loadNativeSymbols(path: string) {
  return dlopen(path, {
    math_ml_version: {
      args: [],
      returns: FFIType.cstring,
    },
    math_ml_engine_create: {
      args: [FFIType.u64],
      returns: FFIType.ptr,
    },
    math_ml_engine_destroy: {
      args: [FFIType.ptr],
      returns: FFIType.void,
    },
    math_ml_engine_term_count: {
      args: [FFIType.ptr],
      returns: FFIType.u64,
    },
    math_ml_engine_build_dictionary: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // act_codes (u32*)
        FFIType.u64, // n_acts
      ],
      returns: FFIType.bool,
    },
    math_ml_engine_fit: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // flat_inputs (f64*)
        FFIType.ptr, // targets (f64*)
        FFIType.u64, // n_samples
        FFIType.f64, // threshold
        FFIType.ptr, // out_weights (f64*)
      ],
      returns: FFIType.u64,
    },
    math_ml_engine_predict: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // input (f64*)
        FFIType.ptr, // weights (f64*)
      ],
      returns: FFIType.f64,
    },
    math_ml_engine_get_formula: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // weights (f64*)
        FFIType.ptr, // out_buf (u8*)
        FFIType.u64, // max_len
      ],
      returns: FFIType.u64,
    },
    math_ml_hilbert_inner: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_hilbert_norm: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_hilbert_distance: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_hilbert_angle: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_precision_sum: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_precision_mean_var: {
      args: [FFIType.ptr, FFIType.u64, FFIType.ptr, FFIType.ptr],
      returns: FFIType.void,
    },
    math_ml_outliers_hampel: {
      args: [
        FFIType.ptr, // data
        FFIType.u64, // n
        FFIType.f64, // k_threshold
        FFIType.ptr, // out_mask (u8*)
        FFIType.ptr, // out_clean (f64*)
      ],
      returns: FFIType.u64,
    },
    math_ml_svd: {
      args: [
        FFIType.ptr, // matrix (f64*)
        FFIType.u64, // m
        FFIType.u64, // n
        FFIType.ptr, // out_u
        FFIType.ptr, // out_s
        FFIType.ptr, // out_v
      ],
      returns: FFIType.bool,
    },
    math_ml_sequence_predict_next: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    math_ml_dmd_dominant_frequency: {
      args: [FFIType.ptr, FFIType.u64, FFIType.u64, FFIType.f64],
      returns: FFIType.f64,
    },
    math_ml_chaos_lorenz: {
      args: [
        FFIType.f64,
        FFIType.f64,
        FFIType.f64,
        FFIType.ptr, // out_lyap
        FFIType.ptr, // out_horizon
      ],
      returns: FFIType.bool,
    },
  });
}
