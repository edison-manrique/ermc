/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/run_all.ts — Ejecutor de todas las demos modulares ERMC (Bun/TS)
 * Uso: bun run demo/run_all.ts              (todas)
 *      bun run demo/run_all.ts 01 06        (sólo las indicadas)
 */
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";

const DEMO_DIR = dirname(fileURLToPath(import.meta.url));

const DEMOS: Array<[string, string]> = [
  ["01_hilbert.ts",  "Espacios de Hilbert y Ortogonalidad"],
  ["02_precision.ts","Aritmética Compensada (Neumaier)"],
  ["03_outliers.ts", "Detección Robusta de Outliers"],
  ["04_sequence.ts", "IA de Sucesiones Matemáticas"],
  ["05_svd.ts",      "SVD - Valores Singulares"],
  ["06_engine.ts",   "OmniEngine - Descubrimiento de Leyes"],
  ["07_dmd.ts",      "DMD - Modos Dinámicos"],
  ["08_chaos.ts",    "Dinámica de Caos y Lyapunov"],
];

const selected = process.argv.slice(2);

console.log("=".repeat(65));
console.log("  ERMC | Suite de Demos Modulares Bun/TypeScript");
const total = selected.length > 0 ? selected.length : DEMOS.length;
console.log(`  Ejecutando ${total} de ${DEMOS.length} demos`);
console.log("=".repeat(65) + "\n");

const results: Array<[string, string, boolean, number]> = [];

for (const [fname, title] of DEMOS) {
  const demoId = fname.slice(0, 2);
  if (selected.length > 0 && !selected.includes(demoId)) continue;

  console.log(`>>> [${demoId}] ${title}`);
  console.log("-".repeat(65));

  const path = join(DEMO_DIR, fname);
  const t0 = performance.now();
  const proc = spawnSync("bun", ["run", path], {
    stdio: "inherit",
    cwd: join(DEMO_DIR, ".."),
  });
  const elapsed = performance.now() - t0;
  const ok = proc.status === 0;
  results.push([demoId, title, ok, elapsed]);
  console.log(`\n${ok ? "[PASS]" : "[FAIL]"} ${title} (${elapsed.toFixed(0)} ms)\n`);
}

console.log("=".repeat(65));
console.log("  RESUMEN FINAL");
console.log("=".repeat(65));
for (const [did, title, ok, ms] of results) {
  const status = ok ? "PASS" : "FAIL";
  console.log(`  [${status}] ${did}: ${title.padEnd(42)} ${ms.toFixed(0).padStart(6)} ms`);
}

const passed = results.filter(r => r[2]).length;
console.log(`\n  ${passed}/${results.length} demos pasadas exitosamente.`);
console.log("=".repeat(65));
