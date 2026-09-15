/**
 * ERMC Demo 11 — Mock Theta de Ramanujan & Distribución de Primos
 * Descubre: Convergencia de Watson, π(x) exacto vs Li(x), Hipótesis de Riemann
 */

import { getSeries } from "../src/series";

export async function run() {
  const s = getSeries();

  console.log("\n╔══════════════════════════════════════════════════════════╗");
  console.log("║  Demo 11: Ramanujan Mock Theta & Primos (ERMC v0.4.0)  ║");
  console.log("╚══════════════════════════════════════════════════════════╝\n");

  // Mock Theta vs asintótica de Watson
  console.log("Mock Theta f(q) — Convergencia al modelo asintótico de Watson:");
  console.log("  [t=0.5 todavía lejos del límite; t→0 converge con < 1%]");

  const tValues = [0.5, 0.2, 0.1, 0.05, 0.02];
  for (const t of tValues) {
    const lnF    = s.mockThetaLn(t, 800);
    const watson = s.watsonAsymptotic(t);
    const errPct = Math.abs(lnF - watson) / Math.abs(watson) * 100;
    console.log(`  t=${t.toFixed(2)}: ln|f|=${lnF.toFixed(4)}, Watson=${watson.toFixed(4)}, err=${errPct.toFixed(2)}%`);
  }

  // π(x) exacto vs Li(x) — validación numérica Riemann
  console.log("\nπ(x) exacto vs Li(x) de Riemann:");
  console.log("  x          π(x)   Li(x)    error");
  console.log("  " + "─".repeat(42));

  for (const x of [100, 500, 1000, 5000, 10000, 50000]) {
    const pi   = s.primeCountPi(x, 100000);
    const li   = s.logarithmicIntegralLi(x);
    const err  = s.riemannError(x, 100000);
    console.log(`  ${x.toString().padStart(6)}  ${pi.toString().padStart(6)}  ${li.toFixed(1).padStart(7)}  ${err.toFixed(2)}%`);
  }

  // Constante de Ramanujan-Soldner: Li(2) ≈ 1.04516
  const li2 = s.logarithmicIntegralLi(2.0);
  console.log(`\nOffset Ramanujan-Soldner Li(2) = ${li2.toFixed(6)} (valor conocido ≈ 1.04516)`);

  // Asintótica de Watson en valores extremos
  console.log("\nAsintótica de Watson (predicción teórica pura):");
  for (const t of [0.01, 0.005, 0.001]) {
    const w = s.watsonAsymptotic(t);
    console.log(`  t=${t}: π²/(24t) - ½ln(t) + ½ln(π) = ${w.toFixed(2)}`);
  }

  console.log("\n✓ Demo 11 completada — Ramanujan & Distribución de Primos\n");
}

await run();
