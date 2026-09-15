/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Todos los derechos reservados.
 * Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
 * Ver archivo LICENSE en la raíz del proyecto para términos completos.
 */

import {
  getVersion,
  OmniEngine,
  HilbertSpace,
  Precision,
  Outliers,
  SVD,
  SequenceAI,
  DMD,
  Chaos,
  Activation,
} from "./src/index";

console.log("=========================================================================");
console.log("  ERMC EN BUN + TYPESCRIPT VIA FFI (.DLL)");
console.log(`  Versión de DLL Nativa (Zig 0.16): ${getVersion()}`);
console.log("=========================================================================\n");

// 1. ESPACIOS DE HILBERT
console.log("--- 1. ESPACIOS DE HILBERT Y ORTOGONALIDAD ---");
const u = [1.0, 2.0, 3.0, 4.0];
const v = [4.0, 3.0, 2.0, 1.0];
console.log(`Vector u: [${u}] | Vector v: [${v}]`);
console.log(`  <u, v> Producto Interno: ${HilbertSpace.inner(u, v)}`);
console.log(`  ||u||  Norma:           ${HilbertSpace.norm(u).toFixed(6)}`);
console.log(`  d(u,v) Distancia:       ${HilbertSpace.distance(u, v).toFixed(6)}`);
console.log(`  Ángulo (rad):           ${HilbertSpace.angle(u, v).toFixed(6)} rad\n`);

// 2. ARITMÉTICA COMPENSADA (NEUMAIER)
console.log("--- 2. ARITMÉTICA COMPENSADA (NEUMAIER SUM) ---");
const dataCancel = [1e16, 1.0, -1e16];
const naiveSum = dataCancel.reduce((a, b) => a + b, 0);
const neumaierSum = Precision.sum(dataCancel);
console.log(`Datos: [1e16, 1.0, -1e16]`);
console.log(`  Suma estándar JS (cancela): ${naiveSum}`);
console.log(`  Suma Neumaier Zig (exacta): ${neumaierSum}\n`);

// 3. OUTLIERS EXTREMOS (10^100)
console.log("--- 3. DETECCIÓN DE OUTLIERS EXTREMOS (10^100) ---");
const noisySignal = [3.14, 3.15, 3.13, 1e100, 3.145, 3.135, -1e100, 3.141];
const outlierRes = Outliers.detectHampel(noisySignal, 3.0);
console.log(`Muestras con perturbaciones cósmicas: [${noisySignal.map(x => x > 1e10 || x < -1e10 ? x.toExponential() : x)}]`);
console.log(`  Outliers detectados: ${outlierRes.outliersCount} de ${noisySignal.length}`);
console.log(`  Máscara: [${outlierRes.isOutlier.map(b => b ? "OUTLIER" : "OK").join(", ")}]`);
console.log(`  Datos Limpios e Imputados: [${Array.from(outlierRes.cleanData).map(x => x.toFixed(4)).join(", ")}]\n`);

// 4. IA DE SUCESIONES MATEMÁTICAS
console.log("--- 4. IA DE SUCESIONES MATEMÁTICAS ---");
const squares = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121];
const nextVal = SequenceAI.predictNext(squares);
console.log(`Secuencia: [${squares.join(", ")}]`);
console.log(`  Próximo valor predicho: ${nextVal} (Esperado exacto: 144)\n`);

// 5. SVD (DESCOMPOSICIÓN EN VALORES SINGULARES)
console.log("--- 5. DESCOMPOSICIÓN SVD EN TYPESCRIPT ---");
const mat = [
  [1.0, 2.0],
  [3.0, 4.0],
  [5.0, 6.0],
];
const svdRes = SVD.decompose(mat, 3, 2);
console.log(`Matriz 3x2:`);
console.log(`  Valores singulares Sigma: [${Array.from(svdRes.s).map(s => s.toFixed(4)).join(", ")}]\n`);

// 6. OMNI-ENGINE: REGRESIÓN SIMBÓLICA Y DESCUBRIMIENTO FÍSICO
console.log("--- 6. OMNI-ENGINE: DESCUBRIMIENTO DE LEY FÍSICA ---");
console.log("Sistema: Péndulo no lineal con arrastre de aire");
console.log("Ley Teórica: f(theta, omega) = -9.81 * sin(theta) - 0.5 * omega^2");

const engine = new OmniEngine(2);
// Construir diccionario modular con activaciones relevantes
engine.buildDictionary([Activation.Identity, Activation.Sine, Activation.Square]);

const samplesInputs: number[][] = [];
const samplesTargets: number[] = [];

// Muestreo 2D no colineal sobre la región física [-1.5, 1.5] x [0.0, 3.0]
const nTheta = 25;
const nOmega = 25;
for (let i = 0; i < nTheta; i++) {
  const theta = -1.5 + (3.0 * i) / (nTheta - 1);
  for (let j = 0; j < nOmega; j++) {
    const omega = 0.0 + (3.0 * j) / (nOmega - 1);
    const target = -9.81 * Math.sin(theta) - 0.5 * (omega * omega);
    samplesInputs.push([theta, omega]);
    samplesTargets.push(target);
  }
}

const t0 = performance.now();
const weights = engine.fit(samplesInputs, samplesTargets, 0.02);
const t1 = performance.now();

const formula = engine.getFormula(weights);
const testInput = [0.5, 1.2];
const pred = engine.predict(testInput, weights);
const exact = -9.81 * Math.sin(0.5) - 0.5 * (1.2 * 1.2);

console.log(`  Ecuación Descubierta: f(X) = ${formula}`);
console.log(`  Términos en Diccionario: ${engine.getTermCount()} | Tiempo en Zig: ${(t1 - t0).toFixed(2)} ms`);
console.log(`  Test f(0.5, 1.2) => Predicho: ${pred.toFixed(5)} | Real: ${exact.toFixed(5)} | Error: ${Math.abs(pred - exact).toExponential(2)}`);
engine.dispose();
console.log("");

// 7. DMD (DYNAMIC MODE DECOMPOSITION)
console.log("--- 7. DMD: EXTRACCIÓN DE FRECUENCIAS ESPACIO-TEMPORALES ---");
const dt = 0.05;
const nSnaps = 50;
const snapshots: number[][] = [[], []];
for (let k = 0; k < nSnaps; k++) {
  const t = k * dt;
  snapshots[0].push(Math.sin(3.14159 * t));
  snapshots[1].push(Math.cos(3.14159 * t));
}
const freq = DMD.dominantFrequency(snapshots, dt);
console.log(`  Frecuencia teórica: ~3.1416 rad/s`);
console.log(`  Frecuencia extraída con DMD: ${freq.toFixed(4)} rad/s\n`);

// 8. DINÁMICA DE CAOS Y LYAPUNOV
console.log("--- 8. DINÁMICA DE CAOS Y EXPONENTE DE LYAPUNOV ---");
const chaos = Chaos.analyzeLorenz(1.0, 1.0, 1.0);
console.log(`  Exponente de Lyapunov λ_max: ${chaos.lyapunovExponent.toFixed(4)} s⁻¹`);
console.log(`  Horizonte de Predictibilidad T_L: ${chaos.predictabilityHorizon.toFixed(4)} s`);
console.log(`  Diagnóstico: ${chaos.lyapunovExponent > 0 ? "SISTEMA CAÓTICO CONFIRMADO (Efecto Mariposa)" : "SISTEMA ESTABLE"}\n`);

console.log("=========================================================================");
console.log(" >> Bun + TypeScript FFI sobre ermc.dll FUNCIONANDO AL 100%!");
console.log("=========================================================================");
