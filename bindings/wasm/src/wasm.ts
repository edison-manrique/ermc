/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { readFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import type { ErmcWasmExports } from "./types";

let _exports: ErmcWasmExports | null = null;
let _mem: () => DataView;
let _f64: () => Float64Array;
let _u8: () => Uint8Array;
let _u32: () => Uint32Array;

/**
 * Carga e inicializa el binario WebAssembly de ERMC
 * @param wasmPath Ruta personalizada al archivo ermc.wasm (opcional)
 */
export async function loadErmc(wasmPath?: string): Promise<void> {
  if (_exports) return;

  let resolvedPath = wasmPath;
  if (!resolvedPath) {
    const dir = dirname(fileURLToPath(import.meta.url));
    const candidates = [
      join(dir, "../../../zig-out/wasm/ermc.wasm"),
      join(dir, "../../zig-out/wasm/ermc.wasm"),
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
  const { instance } = await WebAssembly.instantiate(bytes, {});

  _exports = instance.exports as unknown as ErmcWasmExports;

  // Vistas dinámicas a la memoria lineal WASM (reconstruidas si la memoria crece)
  _mem = () => new DataView(_exports!.memory.buffer);
  _f64 = () => new Float64Array(_exports!.memory.buffer);
  _u8 = () => new Uint8Array(_exports!.memory.buffer);
  _u32 = () => new Uint32Array(_exports!.memory.buffer);
}

/**
 * Retorna la tabla de funciones exportadas por el módulo WebAssembly
 */
export function getWasmExports(): ErmcWasmExports {
  if (!_exports) {
    throw new Error(
      "ERMC WebAssembly no está inicializado. Llame primero a 'await loadErmc()'."
    );
  }
  return _exports;
}

/** Aloca N bytes en la memoria WASM y devuelve el offset (u32) */
export function wasmAlloc(nBytes: number): number {
  const exp = getWasmExports();
  const ptr = exp.ermc_alloc(nBytes);
  if (ptr === 0) throw new Error(`ermc_alloc falló al alocar ${nBytes} bytes`);
  return ptr;
}

/** Libera una región previamente alojada en memoria WASM */
export function wasmFree(ptr: number, nBytes: number): void {
  if (ptr === 0) return;
  getWasmExports().ermc_free(ptr, nBytes);
}

/** Escribe un array JS o Float64Array en memoria WASM */
export function writeF64(data: readonly number[] | Float64Array): number {
  const n = data.length;
  const ptr = wasmAlloc(n * 8);
  const view = _f64();
  const offset = ptr >> 3;
  for (let i = 0; i < n; i++) {
    view[offset + i] = data[i];
  }
  return ptr;
}

/** Lee n flotantes de 64 bits desde la memoria WASM devolviendo un Float64Array nuevo */
export function readF64(ptr: number, n: number): Float64Array {
  const view = _f64();
  const offset = ptr >> 3;
  const out = new Float64Array(n);
  for (let i = 0; i < n; i++) {
    out[i] = view[offset + i];
  }
  return out;
}

/** Escribe un array u32 en la memoria WASM */
export function writeU32(data: readonly number[] | Uint32Array): number {
  const n = data.length;
  const ptr = wasmAlloc(n * 4);
  const view = _u32();
  const offset = ptr >> 2;
  for (let i = 0; i < n; i++) {
    view[offset + i] = data[i];
  }
  return ptr;
}

/** Lee n bytes como array de booleanos desde la memoria WASM */
export function readMask(ptr: number, n: number): boolean[] {
  const view = _u8();
  const out: boolean[] = new Array(n);
  for (let i = 0; i < n; i++) {
    out[i] = view[ptr + i] !== 0;
  }
  return out;
}

/** Lee una cadena UTF-8 desde la memoria WASM */
export function readCString(ptr: number, len: number): string {
  return new TextDecoder().decode(_u8().subarray(ptr, ptr + len));
}

/** Obtiene el DataView de la memoria WASM */
export function getMemView(): DataView {
  return _mem();
}
