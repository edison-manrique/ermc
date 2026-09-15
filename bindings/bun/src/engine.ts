/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import { ptr } from "bun:ffi";
import { getNativeLib, type NativeSymbols } from "./ffi";
import { Activation } from "./types";

/**
 * OmniEngine: Motor de IA Matemática y Descubrimiento Simbólico de Leyes Físicas
 * Utiliza sparse regression (STLSQ), snapping a constantes físicas y expansión polinómica/trigonométrica.
 */
export class OmniEngine {
  private handle: any;
  private numInputs: number;
  private lib: NativeSymbols;
  private currentTermCount: number = 0;

  constructor(numInputs: number, customPath?: string) {
    this.lib = getNativeLib(customPath);
    this.numInputs = numInputs;
    this.handle = this.lib.symbols.math_ml_engine_create(BigInt(numInputs));
    if (!this.handle) {
      throw new Error("No se pudo inicializar OmniEngine en C/Zig");
    }
    this.updateTermCount();
  }

  private updateTermCount(): void {
    if (this.handle) {
      this.currentTermCount = Number(
        this.lib.symbols.math_ml_engine_term_count(this.handle)
      );
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
    if (!this.handle) throw new Error("OmniEngine ya ha sido liberado");
    if (activations.length === 0) return;

    const actCodes = new Uint32Array(activations);
    const ok = this.lib.symbols.math_ml_engine_build_dictionary(
      this.handle,
      ptr(actCodes),
      BigInt(actCodes.length)
    );
    if (!ok) {
      throw new Error("Error al construir el diccionario de expansiones en Zig");
    }
    this.updateTermCount();
  }

  /** Libera los recursos nativos asignados en el motor Zig */
  public dispose(): void {
    if (this.handle) {
      this.lib.symbols.math_ml_engine_destroy(this.handle);
      this.handle = null;
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
    if (!this.handle) throw new Error("OmniEngine ya ha sido liberado");
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

    const targetArr = new Float64Array(targets);
    this.updateTermCount();
    const maxTerms = this.currentTermCount > 0 ? this.currentTermCount : 512;
    const outWeights = new Float64Array(maxTerms);

    const activeTerms = this.lib.symbols.math_ml_engine_fit(
      this.handle,
      ptr(flatInputs),
      ptr(targetArr),
      BigInt(nSamples),
      threshold,
      ptr(outWeights)
    );

    return outWeights.slice(0, Number(activeTerms));
  }

  /**
   * Evalúa la predicción f(x) a partir de los pesos descubiertos
   * @param inputVector Vector de entrada con dimensión `numInputs`
   * @param weights Vector de pesos obtenido de `fit()`
   */
  public predict(inputVector: number[], weights: Float64Array): number {
    if (!this.handle) throw new Error("OmniEngine ya ha sido liberado");
    const inArr = new Float64Array(inputVector);
    return this.lib.symbols.math_ml_engine_predict(
      this.handle,
      ptr(inArr),
      ptr(weights)
    );
  }

  /**
   * Reconstruye la ecuación algebraica descubierta como string legible (ej. "f(X) = -9.81*sin(x0) - 0.5*x1^2")
   * @param weights Vector de pesos obtenido de `fit()`
   */
  public getFormula(weights: Float64Array): string {
    if (!this.handle) throw new Error("OmniEngine ya ha sido liberado");
    const buf = new Uint8Array(2048);
    const len = this.lib.symbols.math_ml_engine_get_formula(
      this.handle,
      ptr(weights),
      ptr(buf),
      BigInt(buf.length)
    );
    return new TextDecoder().decode(buf.subarray(0, Number(len)));
  }
}
