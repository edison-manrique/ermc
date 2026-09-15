/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Licencia Comercial para uso propietario.
 *
 * ERMC WASM — Curvas Elípticas y²=x³+7 (mod p) (v0.4.0)
 */

import { getWasmExports, wasmAlloc, wasmFree } from "./wasm";

export interface WasmEcPoint {
  x: bigint;
  y: bigint;
  isInfinity: boolean;
}

export interface WasmEllipticLib {
  isOnCurve(x: bigint, y: bigint, p: bigint): boolean;
  add(P: WasmEcPoint, Q: WasmEcPoint, p: bigint): WasmEcPoint;
  scalarMul(k: bigint, P: WasmEcPoint, p: bigint): WasmEcPoint;
}

function readWasmPoint(ptr: number): WasmEcPoint {
  const exp = getWasmExports();
  const mem = exp.memory.buffer;
  const view = new DataView(mem);
  // Two u64 values at ptr and ptr+8 (little-endian)
  const lo0 = BigInt(view.getUint32(ptr, true));
  const hi0 = BigInt(view.getUint32(ptr + 4, true));
  const lo1 = BigInt(view.getUint32(ptr + 8, true));
  const hi1 = BigInt(view.getUint32(ptr + 12, true));
  const x = (hi0 << 32n) | lo0;
  const y = (hi1 << 32n) | lo1;
  return { x, y, isInfinity: x === 0n && y === 0n };
}

export function getWasmElliptic(): WasmEllipticLib {
  const exp = getWasmExports();

  return {
    isOnCurve(x, y, p) {
      return exp.ermc_ec_is_on_curve(x, y, p) !== 0;
    },

    add(P, Q, p) {
      const out = wasmAlloc(16); // 2 × u64 = 16 bytes
      try {
        exp.ermc_ec_add(P.x, P.y, Q.x, Q.y, p, out);
        return readWasmPoint(out);
      } finally {
        wasmFree(out, 16);
      }
    },

    scalarMul(k, P, p) {
      const out = wasmAlloc(16);
      try {
        exp.ermc_ec_scalar_mul(k, P.x, P.y, p, out);
        return readWasmPoint(out);
      } finally {
        wasmFree(out, 16);
      }
    },
  };
}

export { getWasmElliptic as getElliptic, type WasmEcPoint as EcPoint };

