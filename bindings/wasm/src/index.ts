/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

/**
 * ERMC: Biblioteca de Machine Learning Científico, Álgebra Numérica y Descubrimiento Simbólico
 * Powered by Zig 0.16.0 WebAssembly (wasm32-freestanding, ReleaseFast)
 */

export * from "./types";
export * from "./wasm";
export * from "./engine";
export * from "./hilbert";
export * from "./precision";
export * from "./outliers";
export * from "./svd";
export * from "./sequence";
export * from "./dmd";
export * from "./chaos";

import { getWasmExports, wasmAlloc, wasmFree, readCString } from "./wasm";

/** Obtiene la versión del motor ERMC compilado en WebAssembly */
export function getVersion(): string {
  const bufPtr = wasmAlloc(32);
  const len = getWasmExports().ermc_version_wasm(bufPtr, 32);
  const ver = readCString(bufPtr, len);
  wasmFree(bufPtr, 32);
  return ver;
}
