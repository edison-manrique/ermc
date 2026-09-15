/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/02_precision.ts — Aritmética Compensada (Neumaier)
 */
import { Precision } from "../src/index";

console.log("=".repeat(60));
console.log("  ERMC | Demo 02: Aritmética Compensada (Neumaier)");
console.log("=".repeat(60));

// [1] Cancelación catastrófica
const data = [1e16, 1.0, -1e16];
const naiveSum = data.reduce((a, b) => a + b, 0);
const zigSum = Precision.sum(data);
console.log("\n[1] Cancelación catastrófica clásica:");
console.log(`  Datos: [1e16, 1.0, -1e16]`);
console.log(`  JS reduce():    ${naiveSum}   <-- ERROR: 0.0`);
console.log(`  Neumaier Zig:  ${zigSum}  <-- CORRECTO: 1.0`);

// [2] Serie armónica H_N
const N = 10_000;
const harmonic = Array.from({ length: N }, (_, k) => 1.0 / (k + 1));
const jsSumH = harmonic.reduce((a, b) => a + b, 0);
const zigSumH = Precision.sum(harmonic);
const ref = Math.log(N) + 0.5772156649015328 + 1 / (2 * N);
console.log(`\n[2] Serie armónica H_${N}:`);
console.log(`  JS reduce():  ${jsSumH.toFixed(10)}`);
console.log(`  Neumaier Zig: ${zigSumH.toFixed(10)}`);
console.log(`  Referencia:   ${ref.toFixed(10)}`);
console.log(`  Error JS:     ${Math.abs(jsSumH - ref).toExponential(2)}`);
console.log(`  Error Zig:    ${Math.abs(zigSumH - ref).toExponential(2)}`);

// [3] Magnitudes dispares
const dispares = [1e-15, 1e15, 1e-15, -1e15, 2.0];
console.log("\n[3] Magnitudes muy dispares:");
console.log(`  JS reduce():  ${dispares.reduce((a, b) => a + b, 0)}`);
console.log(`  Neumaier Zig: ${Precision.sum(dispares)}`);
console.log(`  Esperado:     2.000000000000002`);

// [4] Varianza (suma de cuadrados centrados)
const vals = [1e8 + 1, 1e8 + 2, 1e8 + 3];
const mean = 1e8 + 2;
const sqDevs = vals.map(x => (x - mean) ** 2);
console.log("\n[4] Suma de cuadrados para varianza:");
console.log(`  Neumaier Zig: ${Precision.sum(sqDevs).toFixed(6)}  (esperado: 2.0)`);
console.log(`  JS reduce():  ${sqDevs.reduce((a, b) => a + b, 0).toFixed(6)}`);

console.log("\n[OK] Demo 02 completado.\n");
