/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/08_chaos.ts — Dinámica de Caos y Exponente de Lyapunov
 */
import { Chaos } from "../src/index";

console.log("=".repeat(60));
console.log("  ERMC | Demo 08: Dinámica de Caos (Lorenz) - Lyapunov");
console.log("=".repeat(60));

// [1] Condiciones iniciales clásicas
const c1 = Chaos.analyzeLorenz(1.0, 1.0, 1.0);
console.log("\n[1] Sistema de Lorenz: condiciones iniciales (1,1,1):");
console.log(`  Exponente de Lyapunov max: ${c1.lyapunovExponent.toFixed(4)} s^-1`);
console.log(`  Horizonte predictibilidad:  ${c1.predictabilityHorizon.toFixed(4)} s`);
console.log(`  Diagnóstico: ${c1.lyapunovExponent > 0 ? "CAÓTICO" : "ESTABLE"}`);

// [2] Sensibilidad a condiciones iniciales
const configs: Array<[number, number, number, string]> = [
  [0.1, 0.0, 0.0, "Cercano al origen"],
  [1.0, 0.0, 0.0, "Eje X"],
  [0.0, 1.0, 0.0, "Eje Y"],
  [0.0, 0.0, 1.0, "Eje Z"],
  [5.0, 5.0, 5.0, "Punto en el atractor"],
];

console.log("\n[2] Sensibilidad a condiciones iniciales:");
console.log(`  ${"Condición inicial".padEnd(28)} ${"Lyapunov".padStart(10)} ${"T_pred (s)".padStart(12)} ${"Estado".padStart(10)}`);
console.log(`  ${"-".repeat(62)}`);
for (const [x0, y0, z0, label] of configs) {
  const res = Chaos.analyzeLorenz(x0, y0, z0);
  const status = res.lyapunovExponent > 0 ? "CAÓTICO" : "ESTABLE";
  console.log(`  ${label.padEnd(28)} ${res.lyapunovExponent.toFixed(4).padStart(10)} ${res.predictabilityHorizon.toFixed(4).padStart(12)} ${status.padStart(10)}`);
}

// [3] Interpretación práctica
const c3 = Chaos.analyzeLorenz(1.0, 1.0, 1.0);
console.log("\n[3] Interpretación práctica del horizonte:");
console.log(`  Lyapunov max = ${c3.lyapunovExponent.toFixed(4)} s^-1`);
console.log(`  Horizonte    = ${c3.predictabilityHorizon.toFixed(4)} s`);
console.log(`  Una perturbación de 1e-10 crece a O(1) en ${c3.predictabilityHorizon.toFixed(2)}s`);
console.log(`  => Análogo al límite de predicción meteorológica (~2 semanas)`);

console.log("\n[OK] Demo 08 completado.\n");
