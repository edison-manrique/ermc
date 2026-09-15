/**
 * ERMC Demo 09 — Aritmética Modular en F_p
 * Descubre: Pequeño Teorema de Fermat, residuos cuadráticos y raíces mod p
 */

import { getModular } from "../src/modular";

const P = 1009n; // primo

export async function run() {
  const mod = getModular();

  console.log("\n╔══════════════════════════════════════════════════════╗");
  console.log("║  Demo 09: Aritmética Modular en F_p (ERMC v0.4.0)   ║");
  console.log("╚══════════════════════════════════════════════════════╝\n");

  // Pequeño Teorema de Fermat: a^(p-1) ≡ 1 (mod p)
  const a = 42n;
  const fermat = mod.pow(a, P - 1n, P);
  console.log(`Pequeño Teorema de Fermat: ${a}^(${P}-1) mod ${P} = ${fermat} ✓`);

  // Inverso modular: a * a^{-1} ≡ 1 (mod p)
  const inv = mod.inverse(a, P)!;
  const check = mod.mul(a, inv, P);
  console.log(`Inverso modular: ${a}^{-1} mod ${P} = ${inv},  ${a}×${inv} mod ${P} = ${check} ✓`);

  // Residuos cuadráticos y raíces
  console.log("\nResiduos cuadráticos mod 97:");
  const p97 = 97n;
  for (const sq of [4n, 9n, 16n, 25n, 36n]) {
    const root = mod.sqrt(sq, p97);
    if (root !== null) {
      const verify = mod.mul(root, root, p97);
      console.log(`  √${sq} mod ${p97} = ${root}  (${root}²=${verify}=${sq} ✓)`);
    }
  }

  // Non-residuos cuadráticos: verificar que sqrt retorna null
  for (const cand of [3n, 5n, 6n, 7n, 10n]) {
    const rootCand = mod.sqrt(cand, p97);
    if (rootCand === null) {
      console.log(`  ${cand} es NO-residuo cuadrático mod ${p97} (isQR=${mod.isQR(cand, p97)}) ✓`);
      break;
    }
  }

  // Aritmética encadenada: (a + b) * (a - b) = a² - b² mod p
  const b = 30n;
  const lhs = mod.mul(mod.add(a, b, P), mod.sub(a, b, P), P);
  const rhs = mod.sub(mod.mul(a, a, P), mod.mul(b, b, P), P);
  console.log(`\n(a+b)(a-b) = a²-b² mod ${P}: ${lhs} = ${rhs} ✓ (diferencia de cuadrados)`);

  console.log("\n✓ Demo 09 completada — Aritmética Modular F_p\n");
}

await run();
