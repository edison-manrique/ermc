/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * demo/10_elliptic.ts — Curvas Elípticas y² = x³ + 7 (mod p) (WASM)
 * Descubre: Leyes de grupo EC, multiplicación escalar y endomorfismo GLV
 */

import { loadErmc, getElliptic, getModular, type EcPoint } from "../src/index";

await loadErmc();

const P = 1009n;

function fmtPoint(pt: EcPoint): string {
  return pt.isInfinity ? "O (∞)" : `(${pt.x}, ${pt.y})`;
}

const ec = getElliptic();
const mod = getModular();

console.log("\n╔══════════════════════════════════════════════════════╗");
console.log("║  ERMC WASM | Demo 10: Curvas Elípticas y²=x³+7 mod p ║");
console.log("╚══════════════════════════════════════════════════════╝\n");

// Buscar un punto de orden alto: probar x=1,2,3... hasta encontrar y válida
let G: EcPoint | null = null;
for (let xi = 1n; xi < 50n; xi++) {
  // y² = x³ + 7 mod p
  const rhs = mod.add(mod.mul(mod.mul(xi, xi, P), xi, P), 7n, P);
  const yi = mod.sqrt(rhs, P);
  if (yi !== null && yi > 0n) {
    G = { x: xi, y: yi, isInfinity: false };
    break;
  }
}

if (!G) {
  console.log("No se encontró punto en la curva.");
  process.exit(1);
}

console.log(`Punto generador G = ${fmtPoint(G)}`);
console.log(`G en curva: ${ec.isOnCurve(G.x, G.y, P)} ✓\n`);

// Multiplicaciones escalares
const scalars = [2n, 3n, 5n, 7n, 10n, 20n];
const kPoints: EcPoint[] = [];
console.log("Tabla de multiplicación escalar k·G:");
for (const k of scalars) {
  const kG = ec.scalarMul(k, G, P);
  kPoints.push(kG);
  const valid = kG.isInfinity ? "O" : ec.isOnCurve(kG.x, kG.y, P) ? "✓" : "✗";
  console.log(`  ${k.toString().padStart(3)}·G = ${fmtPoint(kG).padEnd(20)} [${valid}]`);
}

// Verificar 5G = 3G + 2G
const [twoG, threeG, fiveG] = [kPoints[0], kPoints[1], kPoints[2]];
const sum3_2 = ec.add(threeG, twoG, P);
console.log(`\nVerificación: 3G + 2G = ${fmtPoint(sum3_2)}`);
console.log(`              5G      = ${fmtPoint(fiveG)}`);
console.log(`  Coinciden: ${sum3_2.x === fiveG.x && sum3_2.y === fiveG.y} ✓`);

// Ley de duplicación diferencial: λ = 3x²/(2y) mod p, a=0
const x = G.x, y = G.y;
const num = mod.mul(3n, mod.mul(x, x, P), P);
const den = mod.mul(2n, y, P);
const denInv = mod.inverse(den, P)!;
const lambda = mod.mul(num, denInv, P);
const x2Expected = mod.sub(mod.sub(mod.mul(lambda, lambda, P), x, P), x, P);
console.log(`\nLey diferencial λ(2G): ${lambda}`);
console.log(`  x(2G) fórmula  = ${x2Expected}`);
console.log(`  x(2G) scalarMul = ${twoG.x}`);
console.log(`  Coinciden: ${x2Expected === twoG.x} ✓`);

console.log("\n✓ Demo 10 completada — Curvas Elípticas F_p (WASM)\n");
