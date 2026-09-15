/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC — Aritmética Modular en F_p (Cuerpos Finitos Primos)
 * Wraps the native Zig FFI for exact modular arithmetic operations.
 */

import { getNativeLib } from "./ffi";

const U64_MAX = BigInt("18446744073709551615");

export interface ModularLib {
  /** a + b mod p */
  add(a: bigint, b: bigint, p: bigint): bigint;
  /** a - b mod p */
  sub(a: bigint, b: bigint, p: bigint): bigint;
  /** a * b mod p (overflow-safe via u128 intermediary in Zig) */
  mul(a: bigint, b: bigint, p: bigint): bigint;
  /** base^exp mod p (fast exponentiation) */
  pow(base: bigint, exp: bigint, p: bigint): bigint;
  /** Modular inverse a^{-1} mod p, or null if gcd(a,p) ≠ 1 */
  inverse(a: bigint, p: bigint): bigint | null;
  /** Square root of a mod p (Tonelli-Shanks), or null if non-residue */
  sqrt(a: bigint, p: bigint): bigint | null;
  /** Legendre symbol: is a a quadratic residue mod p? */
  isQR(a: bigint, p: bigint): boolean;
}

export function getModular(customPath?: string): ModularLib {
  const lib = getNativeLib(customPath);
  const { symbols } = lib;

  return {
    add: (a, b, p) => BigInt(symbols.ermc_mod_add(a, b, p)),
    sub: (a, b, p) => BigInt(symbols.ermc_mod_sub(a, b, p)),
    mul: (a, b, p) => BigInt(symbols.ermc_mod_mul(a, b, p)),
    pow: (base, exp, p) => BigInt(symbols.ermc_mod_pow(base, exp, p)),

    inverse(a, p) {
      const res = BigInt(symbols.ermc_mod_inverse(a, p));
      return res === U64_MAX ? null : res;
    },

    sqrt(a, p) {
      const res = BigInt(symbols.ermc_mod_sqrt(a, p));
      return res === U64_MAX ? null : res;
    },

    isQR(a, p) {
      // Legendre symbol: a^{(p-1)/2} mod p == 1
      const exp = (p - 1n) / 2n;
      return BigInt(symbols.ermc_mod_pow(a, exp, p)) === 1n;
    },
  };
}
