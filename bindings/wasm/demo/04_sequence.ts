/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/04_sequence.ts — IA de Sucesiones Matemáticas (WASM)
 */
import { loadErmc, SequenceAI } from "../ermc_wasm";

await loadErmc();

console.log("=".repeat(60));
console.log("  ERMC WASM | Demo 04: IA de Sucesiones Matemáticas");
console.log("=".repeat(60));

const sequences: Array<[string, number[], number, string]> = [
  ["Cuadrados perfectos",    [0,1,4,9,16,25,36,49,64,81,100,121], 144, "n^2"],
  ["Cubos perfectos",        [0,1,8,27,64,125,216,343,512,729],   1000, "n^3"],
  ["Progresion aritmética",  [3,7,11,15,19,23,27,31,35,39],        43,  "a+(n-1)*4"],
  ["Progresion geométrica",  [2,4,8,16,32,64,128,256],            512,  "2^n"],
  ["Números triangulares",   [0,1,3,6,10,15,21,28,36,45],          55,  "n*(n+1)/2"],
];

console.log();
let allPass = true;
for (const [name, seq, expected, desc] of sequences) {
  const pred = SequenceAI.predictNext(seq.map(Number));
  const ok = Math.abs(pred - expected) < 0.5;
  if (!ok) allPass = false;
  const status = ok ? "[PASS]" : "[FAIL]";
  console.log(`  ${status} ${name}`);
  console.log(`         Secuencia:  [${seq.join(", ")}]`);
  console.log(`         Predicción: ${pred.toFixed(1)}  |  Esperado: ${expected}  (${desc})\n`);
}

// Descubrimiento libre: números piramidales cuadrados
const mystery = [1, 5, 14, 30, 55, 91, 140, 204];
const predM = SequenceAI.predictNext(mystery.map(Number));
const expected285 = (9 * 10 * 19) / 6;
console.log(`[Descubrimiento] Secuencia: [${mystery.join(", ")}]`);
console.log(`  Predicción ERMC WASM: ${predM.toFixed(1)}`);
console.log(`  (Números piramidales cuadrados: n*(n+1)*(2n+1)/6)`);
console.log(`  Siguiente real: ${expected285}`);

console.log(`\n[${allPass ? "OK" : "PARCIAL"}] Demo 04 completado.\n`);
