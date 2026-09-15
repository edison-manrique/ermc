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
export const defaultDllPath = resolve(import.meta.dir, "../../../zig-out/bin/ermc.dll");

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
    ermc_version: {
      args: [],
      returns: FFIType.cstring,
    },
    ermc_engine_create: {
      args: [FFIType.u64],
      returns: FFIType.ptr,
    },
    ermc_engine_destroy: {
      args: [FFIType.ptr],
      returns: FFIType.void,
    },
    ermc_engine_term_count: {
      args: [FFIType.ptr],
      returns: FFIType.u64,
    },
    ermc_engine_build_dictionary: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // act_codes (u32*)
        FFIType.u64, // n_acts
      ],
      returns: FFIType.bool,
    },
    ermc_engine_fit: {
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
    ermc_engine_predict: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // input (f64*)
        FFIType.ptr, // weights (f64*)
      ],
      returns: FFIType.f64,
    },
    ermc_engine_get_formula: {
      args: [
        FFIType.ptr, // handle
        FFIType.ptr, // weights (f64*)
        FFIType.ptr, // out_buf (u8*)
        FFIType.u64, // max_len
      ],
      returns: FFIType.u64,
    },
    ermc_hilbert_inner: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_hilbert_norm: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_hilbert_distance: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_hilbert_angle: {
      args: [FFIType.ptr, FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_precision_sum: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_precision_mean_var: {
      args: [FFIType.ptr, FFIType.u64, FFIType.ptr, FFIType.ptr],
      returns: FFIType.void,
    },
    ermc_outliers_hampel: {
      args: [
        FFIType.ptr, // data
        FFIType.u64, // n
        FFIType.f64, // k_threshold
        FFIType.ptr, // out_mask (u8*)
        FFIType.ptr, // out_clean (f64*)
      ],
      returns: FFIType.u64,
    },
    ermc_svd: {
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
    ermc_sequence_predict_next: {
      args: [FFIType.ptr, FFIType.u64],
      returns: FFIType.f64,
    },
    ermc_dmd_dominant_frequency: {
      args: [FFIType.ptr, FFIType.u64, FFIType.u64, FFIType.f64],
      returns: FFIType.f64,
    },
    ermc_chaos_lorenz: {
      args: [
        FFIType.f64,
        FFIType.f64,
        FFIType.f64,
        FFIType.ptr, // out_lyap
        FFIType.ptr, // out_horizon
      ],
      returns: FFIType.bool,
    },

    // ── Aritmética Modular F_p (v0.4.0) ────────────────────────────────────
    ermc_mod_add: { args: [FFIType.u64, FFIType.u64, FFIType.u64], returns: FFIType.u64 },
    ermc_mod_sub: { args: [FFIType.u64, FFIType.u64, FFIType.u64], returns: FFIType.u64 },
    ermc_mod_mul: { args: [FFIType.u64, FFIType.u64, FFIType.u64], returns: FFIType.u64 },
    ermc_mod_pow: { args: [FFIType.u64, FFIType.u64, FFIType.u64], returns: FFIType.u64 },
    ermc_mod_inverse: { args: [FFIType.u64, FFIType.u64], returns: FFIType.u64 },
    ermc_mod_sqrt: { args: [FFIType.u64, FFIType.u64], returns: FFIType.u64 },

    // ── Curvas Elípticas y²=x³+7 (mod p) (v0.4.0) ─────────────────────────
    ermc_ec_is_on_curve: { args: [FFIType.u64, FFIType.u64, FFIType.u64], returns: FFIType.bool },
    ermc_ec_add: {
      args: [
        FFIType.u64, FFIType.u64, // px, py
        FFIType.u64, FFIType.u64, // qx, qy
        FFIType.u64,               // p
        FFIType.ptr, FFIType.ptr,  // out_x, out_y
      ],
      returns: FFIType.bool,
    },
    ermc_ec_scalar_mul: {
      args: [
        FFIType.u64,               // k
        FFIType.u64, FFIType.u64,  // px, py
        FFIType.u64,               // p
        FFIType.ptr, FFIType.ptr,  // out_x, out_y
      ],
      returns: FFIType.bool,
    },

    // ── Ramanujan & Primos (v0.4.0) ─────────────────────────────────────────
    ermc_ramanujan_mock_theta_ln:     { args: [FFIType.f64, FFIType.u64], returns: FFIType.f64 },
    ermc_ramanujan_watson_asymptotic: { args: [FFIType.f64], returns: FFIType.f64 },
    ermc_prime_count_pi:              { args: [FFIType.f64, FFIType.u64], returns: FFIType.u64 },
    ermc_logarithmic_integral_li:     { args: [FFIType.f64], returns: FFIType.f64 },
  });
}
