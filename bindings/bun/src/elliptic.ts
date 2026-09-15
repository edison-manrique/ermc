/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC — Curvas Elípticas y² = x³ + 7 (mod p) — secp256k1 reducida
 * Wraps native Zig FFI for exact elliptic curve group arithmetic.
 */

import { getNativeLib } from "./ffi";
import { ptr } from "bun:ffi";

export interface EcPoint {
  x: bigint;
  y: bigint;
  /** true si es el punto en el infinito (elemento neutro del grupo) */
  isInfinity: boolean;
}

export interface EllipticLib {
  /** Verifica si (x, y) pertenece a la curva y²=x³+7 (mod p) */
  isOnCurve(x: bigint, y: bigint, p: bigint): boolean;
  /** P + Q en el grupo elíptico sobre F_p */
  add(P: EcPoint, Q: EcPoint, p: bigint): EcPoint;
  /** k·P multiplicación escalar */
  scalarMul(k: bigint, P: EcPoint, p: bigint): EcPoint;
}

function readPoint(buf: BigInt64Array): EcPoint {
  const x = BigInt.asUintN(64, buf[0]);
  const y = BigInt.asUintN(64, buf[1]);
  return { x, y, isInfinity: x === 0n && y === 0n };
}

export function getElliptic(customPath?: string): EllipticLib {
  const lib = getNativeLib(customPath);
  const { symbols } = lib;

  return {
    isOnCurve(x, y, p) {
      return !!symbols.ermc_ec_is_on_curve(x, y, p);
    },

    add(P, Q, p) {
      const outBuf = new BigInt64Array(2);
      symbols.ermc_ec_add(
        P.x, P.y,
        Q.x, Q.y,
        p,
        ptr(outBuf),
        ptr(outBuf, 8),
      );
      return readPoint(outBuf);
    },

    scalarMul(k, P, p) {
      const outBuf = new BigInt64Array(2);
      symbols.ermc_ec_scalar_mul(
        k,
        P.x, P.y,
        p,
        ptr(outBuf),
        ptr(outBuf, 8),
      );
      return readPoint(outBuf);
    },
  };
}
