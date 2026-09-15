/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/05_svd.ts — SVD: Valores Singulares y Rango Efectivo (WASM)
 */
import { loadErmc, SVD } from "../src/index";

await loadErmc();

console.log("=".repeat(60));
console.log("  ERMC WASM | Demo 05: SVD - Valores Singulares");
console.log("=".repeat(60));

// [1] Rango efectivo de matrices
console.log("\n[1] Rango efectivo de matrices:");
const matrices: Array<[string, number[][], number, number]> = [
  ["Identidad 3x3",     [[1,0,0],[0,1,0],[0,0,1]], 3, 3],
  ["Datos 4x2",         [[1,2],[3,4],[5,6],[7,8]], 4, 2],
  ["Rango 2 (3x3)",     [[1,2,3],[4,5,6],[7,10,13]], 3, 3],
];

for (const [name, mat, rows, cols] of matrices) {
  const res = SVD.decompose(mat, rows, cols);
  const sigma = Array.from(res.s);
  const rank = sigma.filter(s => s > 1e-10).length;
  console.log(`\n  ${name}:`);
  console.log(`    Sigma: [${sigma.map(s => s.toFixed(4)).join(", ")}]`);
  console.log(`    Rango efectivo: ${rank}`);
}

// [2] Energía capturada por componentes
console.log("\n\n[2] Energía por componentes:");
const mat3x2 = [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]];
const res32 = SVD.decompose(mat3x2, 3, 2);
const sigma32 = Array.from(res32.s);
const totalEnergy = sigma32.reduce((a, s) => a + s * s, 0);
let cumulative = 0;
for (let i = 0; i < sigma32.length; i++) {
  cumulative += sigma32[i] ** 2;
  const pct = totalEnergy > 0 ? (100 * cumulative) / totalEnergy : 0;
  console.log(`    Componente ${i + 1}: sigma=${sigma32[i].toFixed(4)}  energía acumulada=${pct.toFixed(2)}%`);
}

// [3] Matriz de correlación
console.log("\n[3] PCA en matriz de correlación 3x3:");
const corr = [[1.0, 0.9, -0.3], [0.9, 1.0, -0.2], [-0.3, -0.2, 1.0]];
const resCorr = SVD.decompose(corr, 3, 3);
const sigCorr = Array.from(resCorr.s);
const totalCorr = sigCorr.reduce((a, s) => a + s * s, 0);
console.log(`  Sigma: [${sigCorr.map(s => s.toFixed(4)).join(", ")}]`);
console.log(`  Varianza explicada (1er PC): ${(sigCorr[0] ** 2 / totalCorr * 100).toFixed(1)}%`);

console.log("\n[OK] Demo 05 completado.\n");
