/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import {
  getWasmExports,
  wasmAlloc,
  wasmFree,
  writeF64,
  readF64,
  writeU32,
  readCString,
} from "./wasm";
import { Activation } from "./types";

/**
 * OmniEngine: Motor de IA Matemática y Descubrimiento Simbólico de Leyes Físicas (WebAssembly)
 * Utiliza sparse regression (STLSQ), snapping a constantes físicas y expansión polinómica/trigonométrica.
 */
export class OmniEngine {
  private handle: number;
  private numInputs: number;
  private currentTermCount: number = 0;

  constructor(numInputs: number) {
    this.numInputs = numInputs;
    this.handle = getWasmExports().ermc_engine_create(numInputs);
    if (this.handle === 0) {
      throw new Error("No se pudo inicializar OmniEngine en WebAssembly");
    }
    this.updateTermCount();
  }

  private updateTermCount(): void {
    if (this.handle !== 0) {
      this.currentTermCount = getWasmExports().ermc_engine_term_count(this.handle);
    }
  }

  /**
   * Obtiene la cantidad actual de términos y características en el diccionario topológico
   */
  public getTermCount(): number {
    this.updateTermCount();
    return this.currentTermCount;
  }

  /**
   * Configura dinámicamente qué funciones de activación construir en el diccionario topológico
   * @param activations Lista de activaciones (ej. [Activation.Identity, Activation.Sine, Activation.Square])
   */
  public buildDictionary(activations: Activation[]): void {
    if (this.handle === 0) throw new Error("OmniEngine ya ha sido liberado");
    if (activations.length === 0) return;

    const ptr = writeU32(activations);
    const ok = getWasmExports().ermc_engine_build_dictionary(
      this.handle,
      ptr,
      activations.length
    );
    wasmFree(ptr, activations.length * 4);

    if (!ok) {
      throw new Error("Error al construir el diccionario de expansiones en WebAssembly");
    }
    this.updateTermCount();
  }

  /** Libera los recursos nativos asignados en el motor WASM */
  public dispose(): void {
    if (this.handle !== 0) {
      getWasmExports().ermc_engine_destroy(this.handle);
      this.handle = 0;
    }
  }

  /**
   * Ajusta el modelo descubriendo los pesos analíticos mediante parsimonia STLSQ y regularización L0
   * @param inputs Matriz 2D de muestras (cada fila tiene `numInputs` valores)
   * @param targets Vector 1D con las respuestas observadas
   * @param threshold Umbral de poda L0 (por defecto 0.02)
   */
  public fit(
    inputs: number[][],
    targets: number[],
    threshold: number = 0.02
  ): Float64Array {
    if (this.handle === 0) throw new Error("OmniEngine ya ha sido liberado");
    const nSamples = inputs.length;
    if (nSamples === 0 || targets.length !== nSamples) {
      throw new Error("Dimensiones del dataset inválidas o vacías");
    }

    const flatInputs = new Float64Array(nSamples * this.numInputs);
    for (let i = 0; i < nSamples; i++) {
      for (let j = 0; j < this.numInputs; j++) {
        flatInputs[i * this.numInputs + j] = inputs[i][j];
      }
    }

    this.updateTermCount();
    const maxTerms = this.currentTermCount > 0 ? this.currentTermCount : 512;

    const inPtr = writeF64(flatInputs);
    const tgtPtr = writeF64(targets);
    const outPtr = wasmAlloc(maxTerms * 8);

    const activeTerms = getWasmExports().ermc_engine_fit(
      this.handle,
      inPtr,
      tgtPtr,
      nSamples,
      threshold,
      outPtr
    );

    const weights = readF64(outPtr, activeTerms);

    wasmFree(inPtr, flatInputs.length * 8);
    wasmFree(tgtPtr, targets.length * 8);
    wasmFree(outPtr, maxTerms * 8);

    this.currentTermCount = activeTerms;
    return weights;
  }

  /**
   * Evalúa la predicción f(x) a partir de los pesos descubiertos
   * @param inputVector Vector de entrada con dimensión `numInputs`
   * @param weights Vector de pesos obtenido de `fit()`
   */
  public predict(
    inputVector: number[],
    weights: Float64Array | number[]
  ): number {
    if (this.handle === 0) throw new Error("OmniEngine ya ha sido liberado");
    const inPtr = writeF64(inputVector);
    const wPtr = writeF64(weights);
    const result = getWasmExports().ermc_engine_predict(
      this.handle,
      inPtr,
      wPtr
    );
    wasmFree(inPtr, inputVector.length * 8);
    wasmFree(wPtr, weights.length * 8);
    return result;
  }

  /**
   * Reconstruye la ecuación algebraica descubierta como string legible
   * @param weights Vector de pesos obtenido de `fit()`
   */
  public getFormula(weights: Float64Array | number[]): string {
    if (this.handle === 0) throw new Error("OmniEngine ya ha sido liberado");
    const wPtr = writeF64(weights);
    const bufPtr = wasmAlloc(2048);
    const len = getWasmExports().ermc_engine_get_formula(
      this.handle,
      wPtr,
      bufPtr,
      2048
    );
    const formula = readCString(bufPtr, len);
    wasmFree(wPtr, weights.length * 8);
    wasmFree(bufPtr, 2048);
    return formula;
  }

  public [Symbol.dispose](): void {
    this.dispose();
  }
}
