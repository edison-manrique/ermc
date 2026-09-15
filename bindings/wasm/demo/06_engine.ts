/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/06_engine.ts — OmniEngine: Descubrimiento Simbólico de Leyes Físicas (WASM)
 */
import { loadErmc, OmniEngine, Activation } from "../src/index";

await loadErmc();

console.log("=".repeat(60));
console.log("  ERMC WASM | Demo 06: OmniEngine - Descubrimiento de Leyes Físicas");
console.log("=".repeat(60));

const experiments = [
  {
    name: "Péndulo no lineal con arrastre",
    law: "f(th, w) = -9.81*sin(th) - 0.5*w^2",
    nVars: 2,
    activations: [Activation.Identity, Activation.Sine, Activation.Square],
    generateData: () => {
      const inp: number[][] = [], tgt: number[] = [];
      for (let i = 0; i < 25; i++) {
        const theta = -1.5 + (3.0 * i) / 24;
        for (let j = 0; j < 25; j++) {
          const omega = (3.0 * j) / 24;
          inp.push([theta, omega]);
          tgt.push(-9.81 * Math.sin(theta) - 0.5 * omega ** 2);
        }
      }
      return { inp, tgt };
    },
    testInput: [0.5, 1.2],
    exactFn: () => -9.81 * Math.sin(0.5) - 0.5 * 1.44,
  },
  {
    name: "Ley de Hooke (resorte amortiguado)",
    law: "f(x, v) = -10*x - 0.3*v",
    nVars: 2,
    activations: [Activation.Identity],
    generateData: () => {
      const inp: number[][] = [], tgt: number[] = [];
      for (let i = 0; i < 20; i++) {
        const x = -2.0 + (4.0 * i) / 19;
        for (let j = 0; j < 20; j++) {
          const vv = -3.0 + (6.0 * j) / 19;
          inp.push([x, vv]);
          tgt.push(-10.0 * x - 0.3 * vv);
        }
      }
      return { inp, tgt };
    },
    testInput: [1.0, 0.5],
    exactFn: () => -10.0 * 1.0 - 0.3 * 0.5,
  },
];

for (const exp of experiments) {
  console.log(`\n--- ${exp.name} ---`);
  console.log(`  Ley Teórica: ${exp.law}`);

  const { inp, tgt } = exp.generateData();
  const engine = new OmniEngine(exp.nVars);
  engine.buildDictionary(exp.activations);

  const t0 = performance.now();
  const weights = engine.fit(inp, tgt, 0.02);
  const elapsed = performance.now() - t0;

  const formula = engine.getFormula(weights);
  const pred = engine.predict(exp.testInput, weights);
  const exact = exp.exactFn();
  const error = Math.abs(pred - exact);

  console.log(`  Ecuación: f(X) = ${formula}`);
  console.log(`  Términos: ${engine.getTermCount()} | Tiempo: ${elapsed.toFixed(2)} ms`);
  console.log(`  Test => Pred: ${pred.toFixed(5)} | Real: ${exact.toFixed(5)} | Error: ${error.toExponential(2)}`);
  console.log(`  ${error < 1e-4 ? "[EXCELENTE]" : error < 1e-2 ? "[ACEPTABLE]" : "[REVISAR]"}`);

  engine.dispose();
}

console.log("\n[OK] Demo 06 completado.\n");
