/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC WASM — Aritmética Modular en F_p (v0.4.0)
 */

import { getWasmExports } from "./wasm";

const U64_MAX = BigInt("18446744073709551615");

export interface WasmModularLib {
  add(a: bigint, b: bigint, p: bigint): bigint;
  sub(a: bigint, b: bigint, p: bigint): bigint;
  mul(a: bigint, b: bigint, p: bigint): bigint;
  pow(base: bigint, exp: bigint, p: bigint): bigint;
  inverse(a: bigint, p: bigint): bigint | null;
  sqrt(a: bigint, p: bigint): bigint | null;
  isQR(a: bigint, p: bigint): boolean;
}

export function getWasmModular(): WasmModularLib {
  const exp = getWasmExports();
  return {
    add: (a, b, p) => exp.ermc_mod_add(a, b, p),
    sub: (a, b, p) => exp.ermc_mod_sub(a, b, p),
    mul: (a, b, p) => exp.ermc_mod_mul(a, b, p),
    pow: (base, e, p) => exp.ermc_mod_pow(base, e, p),
    inverse(a, p) {
      const r = exp.ermc_mod_inverse(a, p);
      return r === U64_MAX ? null : r;
    },
    sqrt(a, p) {
      const r = exp.ermc_mod_sqrt(a, p);
      return r === U64_MAX ? null : r;
    },
    isQR(a, p) {
      const e = (p - 1n) / 2n;
      return exp.ermc_mod_pow(a, e, p) === 1n;
    },
  };
}

export { getWasmModular as getModular };

