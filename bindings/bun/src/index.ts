/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

/**
 * MATH-ML: Biblioteca de Machine Learning Científico, Álgebra Numérica y Descubrimiento Simbólico
 * Powered by Zig 0.16.0 Native FFI DLL
 */

export * from "./types";
export * from "./ffi";
export * from "./engine";
export * from "./hilbert";
export * from "./precision";
export * from "./outliers";
export * from "./svd";
export * from "./sequence";
export * from "./dmd";
export * from "./chaos";

import { getNativeLib } from "./ffi";

/** Obtiene la versión del motor nativo Zig compilado en la DLL */
export function getVersion(customPath?: string): string {
  const lib = getNativeLib(customPath);
  return lib.symbols.math_ml_version().toString();
}
