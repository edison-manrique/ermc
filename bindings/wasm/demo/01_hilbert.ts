/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/01_hilbert.ts — Espacios de Hilbert y Ortogonalidad (WASM)
 */
import { loadErmc, HilbertSpace } from "../ermc_wasm";

await loadErmc();

console.log("=".repeat(60));
console.log("  ERMC WASM | Demo 01: Espacios de Hilbert y Ortogonalidad");
console.log("=".repeat(60));

// [1] Vectores canónicos ortogonales
const e1 = [1.0, 0.0, 0.0];
const e2 = [0.0, 1.0, 0.0];
console.log("\n[1] Vectores canónicos ortogonales:");
console.log(`  <e1, e2> = ${HilbertSpace.inner(e1, e2)}  (esperado: 0.0)`);
console.log(`  ||e1||   = ${HilbertSpace.norm(e1).toFixed(6)}  (esperado: 1.0)`);
console.log(`  Ángulo   = ${HilbertSpace.angle(e1, e2).toFixed(6)} rad  (esperado: ${(Math.PI / 2).toFixed(6)})`);

// [2] Ley del coseno en R^4
const u = [1.0, 2.0, 3.0, 4.0];
const v = [4.0, 3.0, 2.0, 1.0];
const cosTheta = HilbertSpace.inner(u, v) / (HilbertSpace.norm(u) * HilbertSpace.norm(v));
console.log("\n[2] Ley del coseno en R^4:");
console.log(`  <u, v>   = ${HilbertSpace.inner(u, v).toFixed(4)}`);
console.log(`  cos(ang) = ${cosTheta.toFixed(6)}`);
console.log(`  Ángulo   = ${HilbertSpace.angle(u, v).toFixed(6)} rad`);

// [3] Desigualdad de Cauchy-Schwarz
const lhs = Math.abs(HilbertSpace.inner(u, v));
const rhs = HilbertSpace.norm(u) * HilbertSpace.norm(v);
console.log("\n[3] Cauchy-Schwarz: |<u,v>| <= ||u|| * ||v||");
console.log(`  |<u,v>|       = ${lhs.toFixed(6)}`);
console.log(`  ||u|| * ||v|| = ${rhs.toFixed(6)}`);
console.log(`  Se cumple:      ${lhs <= rhs + 1e-10}`);

// [4] Distancia L2 entre sin y cos (16 muestras)
const fSin = Array.from({ length: 16 }, (_, k) => Math.sin((2 * Math.PI * k) / 16));
const fCos = Array.from({ length: 16 }, (_, k) => Math.cos((2 * Math.PI * k) / 16));
console.log("\n[4] Distancia L2 entre sin(2*pi*t) y cos(2*pi*t):");
console.log(`  d(sin, cos) = ${HilbertSpace.distance(fSin, fCos).toFixed(6)}`);
console.log(`  <sin, cos>  = ${HilbertSpace.inner(fSin, fCos).toFixed(6)}  (casi 0 = ortogonales)`);

console.log("\n[OK] Demo 01 completado.\n");
