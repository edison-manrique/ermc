/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/07_dmd.ts — Dynamic Mode Decomposition
 */
import { DMD } from "../src/index";

console.log("=".repeat(60));
console.log("  ERMC | Demo 07: DMD - Modos Dinámicos Dominantes");
console.log("=".repeat(60));

// [1] Mono-frecuencia conocida
const omegaTrue = Math.PI;
const dt1 = 0.05, n1 = 60;
const snaps1 = [
  Array.from({ length: n1 }, (_, k) => Math.sin(omegaTrue * k * dt1)),
  Array.from({ length: n1 }, (_, k) => Math.cos(omegaTrue * k * dt1)),
];
const freq1 = DMD.dominantFrequency(snaps1, dt1);
const err1 = Math.abs(freq1 - omegaTrue);
console.log("\n[1] Señal mono-frecuencia (omega = pi rad/s):");
console.log(`  omega teórico: ${omegaTrue.toFixed(6)} rad/s`);
console.log(`  omega DMD:     ${freq1.toFixed(6)} rad/s`);
console.log(`  Error:         ${err1.toExponential(2)}`);
console.log(`  ${err1 < 0.05 ? "[PASS]" : "[FAIL]"}`);

// [2] Batimiento de dos frecuencias
const omega1 = 2.0, omega2 = 7.0;
const dt2 = 0.02, n2 = 80;
const snaps2 = [
  Array.from({ length: n2 }, (_, k) => Math.sin(omega1 * k * dt2) + 0.5 * Math.sin(omega2 * k * dt2)),
  Array.from({ length: n2 }, (_, k) => Math.cos(omega1 * k * dt2) + 0.5 * Math.cos(omega2 * k * dt2)),
];
const freq2 = DMD.dominantFrequency(snaps2, dt2);
console.log("\n[2] Batimiento (omega1=2, omega2=7):");
console.log(`  Frecuencia dominante extraída: ${freq2.toFixed(4)} rad/s`);
console.log(`  (Componente más energética = omega1 = ${omega1} rad/s)`);

// [3] Van der Pol
let x = 0.1, y = 0.0;
const dt3 = 0.02, n3 = 100, eps = 0.1;
const trjX: number[] = [], trjY: number[] = [];
for (let _ = 0; _ < n3; _++) {
  const dx = y;
  const dy = eps * (1 - x * x) * y - x;
  x += dx * dt3;
  y += dy * dt3;
  trjX.push(x);
  trjY.push(y);
}
const freqVdp = DMD.dominantFrequency([trjX, trjY], dt3);
console.log("\n[3] Oscilador de Van der Pol (ciclo límite):");
console.log(`  Frecuencia detectada: ${freqVdp.toFixed(4)} rad/s`);
console.log(`  (Esperado aprox: 1.0 rad/s para eps pequeño)`);

console.log("\n[OK] Demo 07 completado.\n");
