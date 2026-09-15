/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/03_outliers.ts — Detección Robusta de Outliers (Hampel)
 */
import { Outliers } from "../src/index";

console.log("=".repeat(60));
console.log("  ERMC | Demo 03: Detección Robusta de Outliers (Hampel)");
console.log("=".repeat(60));

// [1] Señal sinusoidal con spikes cósmicos
const n = 20;
const signal = Array.from({ length: n }, (_, k) => Math.sin((2 * Math.PI * k) / n));
signal[5] = 1e100;
signal[13] = -1e100;
const res1 = Outliers.detectHampel(signal, 3.0);
console.log("\n[1] Señal sinusoidal con spikes cósmicos:");
console.log(`  Outliers detectados: ${res1.outliersCount} de ${n}`);
console.log(`  Posiciones: [${res1.isOutlier.map((b, i) => b ? i : -1).filter(i => i >= 0).join(", ")}]`);
console.log(`  Datos limpios (pos 4-7): [${Array.from(res1.cleanData).slice(4, 8).map(x => x.toFixed(4)).join(", ")}]`);

// [2] Temperatura con sensores defectuosos
const temps = [22.1, 22.5, 23.0, 22.8, 999.0, 22.9, 23.1, -200.0, 22.7, 23.2,
               22.6, 23.0, 22.4, 22.8, 23.1, 22.3, 22.9, 23.3, 22.5, 22.7];
const res2 = Outliers.detectHampel(temps, 2.5);
const cleanMean = Array.from(res2.cleanData).reduce((a, b) => a + b, 0) / temps.length;
console.log("\n[2] Temperatura diaria con sensores defectuosos:");
console.log(`  Outliers detectados: ${res2.outliersCount}`);
console.log(`  Posiciones corruptas: [${res2.isOutlier.map((b, i) => b ? i : -1).filter(i => i >= 0).join(", ")}]`);
console.log(`  Media limpia: ${cleanMean.toFixed(2)} °C`);

// [3] ECG con artefactos
const ecg = Array.from({ length: 50 }, (_, k) =>
  Math.sin((2 * Math.PI * k) / 8) * Math.exp(-0.05 * k)
);
ecg[10] = 50.0;
ecg[25] = -40.0;
ecg[40] = 30.0;
const res3 = Outliers.detectHampel(ecg, 3.0);
const maxBefore = Math.max(...ecg.map(Math.abs));
const meanBefore = ecg.reduce((a, b) => a + Math.abs(b), 0) / ecg.length;
const maxAfter = Math.max(...Array.from(res3.cleanData).map(Math.abs));
const meanAfter = Array.from(res3.cleanData).reduce((a, b) => a + Math.abs(b), 0) / ecg.length;
console.log("\n[3] ECG con artefactos de movimiento:");
console.log(`  Artefactos detectados: ${res3.outliersCount} de 50`);
console.log(`  Posiciones: [${res3.isOutlier.map((b, i) => b ? i : -1).filter(i => i >= 0).join(", ")}]`);
console.log(`  Peak-to-mean ANTES:   ${(maxBefore / meanBefore).toFixed(2)}x`);
console.log(`  Peak-to-mean DESPUÉS: ${(maxAfter / meanAfter).toFixed(2)}x`);

console.log("\n[OK] Demo 03 completado.\n");
