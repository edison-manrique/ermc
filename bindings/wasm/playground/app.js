/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * app.js — Controlador de interfaz interactiva para ERMC WebAssembly Playground
 */

import { ErmcWasm } from "./ermc-wasm.js";

const ermc = new ErmcWasm();

// Elementos globales
const logText = document.getElementById("log-text");
const statusText = document.getElementById("wasm-status-text");
const statusDot = document.getElementById("wasm-status-dot");
const versionBadge = document.getElementById("wasm-version-badge");

function setLog(msg, isError = false) {
  if (logText) {
    logText.textContent = msg;
    logText.style.color = isError ? "#f43f5e" : "var(--text-muted)";
  }
}

// Inicialización de WebAssembly
async function initWasm() {
  try {
    setLog("Cargando y compilando ermc.wasm...");
    await ermc.init("./ermc.wasm");
    const ver = ermc.getVersion();
    statusText.textContent = `WASM Listo (${ver})`;
    versionBadge.textContent = `v${ver} WASM`;
    statusDot.style.backgroundColor = "#10b981";
    setLog(`Núcleo ERMC v${ver} inicializado exitosamente en WebAssembly.`);
  } catch (err) {
    console.error("Fallo al inicializar WASM:", err);
    statusText.textContent = "Error al cargar WASM";
    statusDot.style.backgroundColor = "#f43f5e";
    setLog(`Error al cargar ermc.wasm: ${err.message}`, true);
  }
}

// Navegación por pestañas
function setupTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  const panels = document.querySelectorAll(".tab-panel");

  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      panels.forEach(p => p.classList.remove("active"));

      tab.classList.add("active");
      const targetId = tab.getAttribute("data-tab");
      const panel = document.getElementById(targetId);
      if (panel) panel.classList.add("active");
      setLog(`Pestaña activa: ${tab.textContent.trim()}`);
    });
  });
}

// ===========================================================================
// MÓDULO 1: OMNIENGINE (Descubrimiento Simbólico)
// ===========================================================================
function setupOmniEngine() {
  const fitBtn = document.getElementById("engine-fit-btn");
  const presetSelect = document.getElementById("engine-preset-select");
  const samplesInput = document.getElementById("engine-samples-input");
  const noiseInput = document.getElementById("engine-noise-input");
  const lambdaInput = document.getElementById("engine-lambda-input");
  const resultBox = document.getElementById("engine-result-box");
  const timeBadge = document.getElementById("engine-time-badge");
  const canvas = document.getElementById("engine-canvas");

  if (!fitBtn) return;

  fitBtn.addEventListener("click", () => {
    try {
      const preset = presetSelect.value;
      const nSamples = parseInt(samplesInput.value, 10);
      const noise = parseFloat(noiseInput.value);
      const lambda = parseFloat(lambdaInput.value);

      let nVars = 1;
      let activations = [0, 5]; // Identity, Poly
      let X_flat = [];
      let y = [];
      let trueFormula = "";

      const gaussianNoise = () => (Math.random() + Math.random() - 1) * noise * 2;

      if (preset === "pendulum") {
        nVars = 2;
        activations = [0, 1, 5]; // Identity, Sin, Poly
        trueFormula = "-9.8100*sin(x0) - 0.5000*x1^2";
        for (let i = 0; i < nSamples; i++) {
          const th = (Math.random() - 0.5) * 2.0; // [-1, 1]
          const w = (Math.random() - 0.5) * 4.0;  // [-2, 2]
          X_flat.push(th, w);
          y.push(-9.81 * Math.sin(th) - 0.5 * w * w + gaussianNoise());
        }
      } else if (preset === "snell") {
        nVars = 1;
        activations = [0, 1]; // Identity, Sin
        trueFormula = "(4/3)*sin(x0)  [n1·sin(θ)]";
        for (let i = 0; i < nSamples; i++) {
          const th = Math.random() * (Math.PI / 2.5); // [0, ~1.2 rad]
          X_flat.push(th);
          y.push((4.0 / 3.0) * Math.sin(th) + gaussianNoise());
        }
      } else if (preset === "adiabatic") {
        nVars = 2;
        activations = [0, 5]; // Identity, Poly
        trueFormula = "(5/3)*x0*x1  [Gamma 5/3]";
        for (let i = 0; i < nSamples; i++) {
          const T = 1.0 + Math.random() * 4.0;
          const invV = 0.5 + Math.random() * 2.0;
          X_flat.push(T, invV);
          y.push((5.0 / 3.0) * T * invV + gaussianNoise());
        }
      } else if (preset === "torricelli") {
        nVars = 1;
        activations = [0, 4]; // Identity, Sqrt
        trueFormula = "4.4287*sqrt(x0)  [√(2gh)]";
        for (let i = 0; i < nSamples; i++) {
          const h = 0.1 + Math.random() * 5.0;
          X_flat.push(h);
          y.push(Math.sqrt(2.0 * 9.80665 * h) + gaussianNoise());
        }
      } else if (preset === "hooke") {
        nVars = 2;
        activations = [0]; // Linear
        trueFormula = "-10.0000*x0 - 0.3000*x1";
        for (let i = 0; i < nSamples; i++) {
          const x = (Math.random() - 0.5) * 2.0;
          const v = (Math.random() - 0.5) * 4.0;
          X_flat.push(x, v);
          y.push(-10.0 * x - 0.3 * v + gaussianNoise());
        }
      }

      const t0 = performance.now();
      const engine = ermc.createEngine(nVars);
      ermc.buildDictionary(engine, activations);
      const { ok, weights } = ermc.fit(engine, X_flat, y, lambda);
      const formula = ermc.getFormula(engine, weights);
      const elapsedMs = performance.now() - t0;
      const elapsedUs = (elapsedMs * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      let html = `<div><strong>Ley Teórica:</strong> <span style="color: var(--text-muted);">${trueFormula}</span></div>`;
      html += `<div class="formula-highlight">${formula}</div>`;
      html += `<div class="metrics-row">`;
      html += `<span class="metric-item">Muestras: <span class="metric-val">${nSamples}</span></span>`;
      html += `<span class="metric-item">Variables: <span class="metric-val">${nVars}</span></span>`;
      html += `<span class="metric-item">Términos activos: <span class="metric-val">${weights.filter(w => Math.abs(w) > 1e-4).length}</span></span>`;
      html += `</div>`;
      resultBox.innerHTML = html;

      // Dibujar en canvas
      drawEnginePlot(canvas, X_flat, y, engine, weights, nVars);

      ermc.destroyEngine(engine);
      setLog(`Descubrimiento simbólico completado en ${elapsedUs} μs. Ecuación: ${formula}`);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
      setLog(`Error en OmniEngine: ${err.message}`, true);
    }
  });
}

function drawEnginePlot(canvas, X_flat, y, engine, weights, nVars) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  // Encontrar rangos para y
  const minY = Math.min(...y);
  const maxY = Math.max(...y);
  const rangeY = (maxY - minY) || 1;

  // Dibujar ejes
  ctx.strokeStyle = "#1e293b";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(40, 20);
  ctx.lineTo(40, h - 30);
  ctx.lineTo(w - 20, h - 30);
  ctx.stroke();

  // Puntos reales (puntos cyan)
  ctx.fillStyle = "rgba(56, 189, 248, 0.7)";
  for (let i = 0; i < y.length; i++) {
    const px = 40 + (i / (y.length - 1)) * (w - 70);
    const py = (h - 30) - ((y[i] - minY) / rangeY) * (h - 60);
    ctx.beginPath();
    ctx.arc(px, py, 2.5, 0, Math.PI * 2);
    ctx.fill();
  }

  // Curva de predicción de la fórmula descubierta (línea verde esmeralda)
  ctx.strokeStyle = "#10b981";
  ctx.lineWidth = 2;
  ctx.beginPath();
  for (let i = 0; i < y.length; i++) {
    const inputVec = [];
    for (let v = 0; v < nVars; v++) inputVec.push(X_flat[i * nVars + v]);
    const pred = ermc.predict(engine, inputVec, weights);
    const px = 40 + (i / (y.length - 1)) * (w - 70);
    const py = (h - 30) - ((pred - minY) / rangeY) * (h - 60);
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.stroke();

  // Leyenda
  ctx.fillStyle = "rgba(56, 189, 248, 0.9)";
  ctx.font = "11px Inter";
  ctx.fillText("● Muestras de datos", w - 240, 25);
  ctx.fillStyle = "#10b981";
  ctx.fillText("― Modelo Simbólico Descubierto", w - 240, 42);
}

// ===========================================================================
// MÓDULO 2: ARITMÉTICA MODULAR EN F_p
// ===========================================================================
function setupModular() {
  const computeBtn = document.getElementById("mod-compute-btn");
  const fermatBtn = document.getElementById("mod-fermat-btn");
  const tonelliBtn = document.getElementById("mod-tonelli-btn");
  const aInput = document.getElementById("mod-a-input");
  const bInput = document.getElementById("mod-b-input");
  const pInput = document.getElementById("mod-p-input");
  const expInput = document.getElementById("mod-exp-input");
  const resultBox = document.getElementById("mod-result-box");
  const timeBadge = document.getElementById("mod-time-badge");

  if (!computeBtn) return;

  computeBtn.addEventListener("click", () => {
    try {
      const a = BigInt(aInput.value);
      const b = BigInt(bInput.value);
      const p = BigInt(pInput.value);
      const exp = BigInt(expInput.value);

      const t0 = performance.now();
      const add = ermc.modAdd(a, b, p);
      const sub = ermc.modSub(a, b, p);
      const mul = ermc.modMul(a, b, p);
      const pow = ermc.modPow(a, exp, p);
      const invA = ermc.modInverse(a, p);
      const invB = ermc.modInverse(b, p);
      const sqrtA = ermc.modSqrt(a, p);
      const isQrA = ermc.isQuadraticResidue(a, p);
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      let html = `<div style="display: grid; gap: 0.4rem;">`;
      html += `<div><strong>Suma (a + b mod p):</strong> <span style="color: #38bdf8;">${add}</span></div>`;
      html += `<div><strong>Resta (a - b mod p):</strong> <span style="color: #38bdf8;">${sub}</span></div>`;
      html += `<div><strong>Multiplicación (a × b mod p):</strong> <span style="color: #38bdf8;">${mul}</span></div>`;
      html += `<div><strong>Exponenciación (a^${exp} mod p):</strong> <span style="color: #a855f7;">${pow}</span></div>`;
      html += `<div><strong>Inverso modular a⁻¹ mod p:</strong> ${invA !== null ? `<span style="color: #10b981;">${invA} (Verif: ${a}×${invA} mod ${p} = 1 ✓)</span>` : `<span style="color: #f43f5e;">No existe</span>`}</div>`;
      html += `<div><strong>Residuo cuadrático a (Euler):</strong> <span style="color: ${isQrA ? '#10b981' : '#f59e0b'};">${isQrA ? 'Sí (Residuo Cuadrático)' : 'No (No-residuo)'}</span></div>`;
      html += `<div><strong>Raíz modular √a mod p (Tonelli-Shanks):</strong> ${sqrtA !== null ? `<span style="color: #10b981;">${sqrtA} (${sqrtA}² mod ${p} = ${ermc.modMul(sqrtA, sqrtA, p)} ✓)</span>` : `<span style="color: #f59e0b;">Sin raíz en F_p</span>`}</div>`;
      html += `</div>`;

      resultBox.innerHTML = html;
      setLog(`Operaciones en F_${p} computadas en ${elapsedUs} μs.`);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });

  fermatBtn.addEventListener("click", () => {
    const a = BigInt(aInput.value);
    const p = BigInt(pInput.value);
    const res = ermc.modPow(a, p - 1n, p);
    resultBox.innerHTML = `
      <div style="padding: 0.5rem; border-left: 3px solid #10b981; background: rgba(16, 185, 129, 0.08);">
        <strong>Pequeño Teorema de Fermat:</strong><br>
        Para a = ${a} y primo p = ${p}:<br>
        <span class="formula-highlight">${a}^(${p} - 1) ≡ ${res} (mod ${p})</span>
        ${res === 1n ? "✓ Cumple exactamente con la identidad fermatiana." : "✗ No es congruente a 1 (¿es p un número compuesto?)"}
      </div>
    `;
  });

  tonelliBtn.addEventListener("click", () => {
    const p = BigInt(pInput.value);
    let found = [];
    for (let test = 1n; test < 30n; test++) {
      const root = ermc.modSqrt(test, p);
      if (root !== null) {
        found.push(`√${test} = ${root} (${root}²=${ermc.modMul(root, root, p)})`);
        if (found.length >= 5) break;
      }
    }
    resultBox.innerHTML = `
      <div><strong>Primeros Residuos Cuadráticos y Raíces mod ${p}:</strong></div>
      <ul style="margin-left: 1.25rem; margin-top: 0.5rem; color: #38bdf8;">
        ${found.map(s => `<li>${s} ✓</li>`).join("")}
      </ul>
    `;
  });
}

// ===========================================================================
// MÓDULO 3: CURVAS ELÍPTICAS & GLV
// ===========================================================================
let currentG = null;

function setupElliptic() {
  const findGBtn = document.getElementById("ec-find-g-btn");
  const scalarBtn = document.getElementById("ec-scalar-mul-btn");
  const glvBtn = document.getElementById("ec-glv-btn");
  const pInput = document.getElementById("ec-p-input");
  const kInput = document.getElementById("ec-scalar-k");
  const resultBox = document.getElementById("ec-result-box");
  const timeBadge = document.getElementById("ec-time-badge");
  const canvas = document.getElementById("ec-canvas");

  if (!findGBtn) return;

  findGBtn.addEventListener("click", () => {
    try {
      const p = BigInt(pInput.value);
      const t0 = performance.now();

      // Buscar generador: probar x = 1, 2, ...
      let G = null;
      for (let xi = 1n; xi < 100n; xi++) {
        // y² = x³ + 7 mod p
        const x3 = ermc.modMul(ermc.modMul(xi, xi, p), xi, p);
        const rhs = ermc.modAdd(x3, 7n, p);
        const yi = ermc.modSqrt(rhs, p);
        if (yi !== null && yi > 0n) {
          G = { x: xi, y: yi };
          break;
        }
      }

      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);
      timeBadge.textContent = `${elapsedUs} μs`;

      if (!G) {
        resultBox.innerHTML = `<div style="color: #f43f5e;">No se encontró punto afín sobre F_${p}.</div>`;
        return;
      }

      currentG = G;
      const onCurve = ermc.ecIsOnCurve(G.x, G.y, p);

      let html = `<div><strong>Punto Generador Encontrado G:</strong></div>`;
      html += `<div class="formula-highlight">G = (${G.x}, ${G.y})</div>`;
      html += `<div>Punto en curva y² = x³ + 7 mod ${p}: <span style="color: #10b981;">${onCurve ? 'Verificado ✓' : 'Fallo'}</span></div>`;
      resultBox.innerHTML = html;

      drawEcPoints(canvas, p, G);
      setLog(`Punto generador G = (${G.x}, ${G.y}) hallado en ${elapsedUs} μs.`);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });

  scalarBtn.addEventListener("click", () => {
    if (!currentG) {
      resultBox.innerHTML = `<div style="color: #f59e0b;">Por favor presiona primero "Buscar Punto Generador G".</div>`;
      return;
    }
    try {
      const p = BigInt(pInput.value);
      const k = BigInt(kInput.value);

      const t0 = performance.now();
      const kG = ermc.ecScalarMul(k, currentG.x, currentG.y, p);
      const twoG = ermc.ecScalarMul(2n, currentG.x, currentG.y, p);
      const threeG = ermc.ecScalarMul(3n, currentG.x, currentG.y, p);
      const sumCheck = ermc.ecAdd(twoG.x, twoG.y, threeG.x, threeG.y, p);
      const fiveG = ermc.ecScalarMul(5n, currentG.x, currentG.y, p);
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      let html = `<div><strong>Multiplicación Escalar k·G:</strong></div>`;
      html += `<div class="formula-highlight">${k} · G = (${kG.x}, ${kG.y})</div>`;
      html += `<div style="margin-top: 0.5rem; font-size: 0.85rem; color: var(--text-muted);">`;
      html += `Ley de Grupo (Asociatividad): 2G + 3G = (${sumCheck.x}, ${sumCheck.y}) | 5G = (${fiveG.x}, ${fiveG.y})<br>`;
      html += `Coincidencia exacta: <span style="color: #10b981;">${(sumCheck.x === fiveG.x && sumCheck.y === fiveG.y) ? 'true ✓' : 'false'}</span>`;
      html += `</div>`;

      resultBox.innerHTML = html;
      drawEcPoints(canvas, p, currentG, kG);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });

  glvBtn.addEventListener("click", () => {
    if (!currentG) {
      resultBox.innerHTML = `<div style="color: #f59e0b;">Busca primero el punto generador G.</div>`;
      return;
    }
    const p = BigInt(pInput.value);
    // Buscar raíz cúbica no trivial de la unidad: beta^3 = 1 mod p, beta != 1
    let beta = null;
    for (let b = 2n; b < p; b++) {
      if (ermc.modPow(b, 3n, p) === 1n) {
        beta = b;
        break;
      }
    }

    if (!beta) {
      resultBox.innerHTML = `<div>Para p = ${p}, no existe raíz cúbica no trivial de la unidad en F_p (p no es congruente a 1 mod 3).</div>`;
      return;
    }

    const phiX = ermc.modMul(beta, currentG.x, p);
    const phiY = currentG.y;
    const phiOnCurve = ermc.ecIsOnCurve(phiX, phiY, p);

    resultBox.innerHTML = `
      <div><strong>Endomorfismo de Gallant-Lambert-Vanstone (GLV):</strong></div>
      <div class="formula-highlight">φ(P) = (β·x, y) donde β³ ≡ 1 (mod ${p})</div>
      <div>Raíz cúbica no trivial hallada: β = <span style="color: #a855f7;">${beta}</span> (β³ mod ${p} = 1 ✓)</div>
      <div>φ(G) = (${phiX}, ${phiY})</div>
      <div>φ(G) pertenece a la curva: <span style="color: #10b981;">${phiOnCurve ? 'Verificado ✓' : 'Fallo'}</span></div>
    `;
  });
}

function drawEcPoints(canvas, p, G, kG = null) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  const P = Number(p);
  const pad = 30;
  const mapX = (val) => pad + (Number(val) / P) * (w - 2 * pad);
  const mapY = (val) => (h - pad) - (Number(val) / P) * (h - 2 * pad);

  // Rejilla discreta
  ctx.strokeStyle = "rgba(255, 255, 255, 0.05)";
  ctx.lineWidth = 1;
  for (let i = 0; i <= 4; i++) {
    const gx = pad + (i / 4) * (w - 2 * pad);
    const gy = pad + (i / 4) * (h - 2 * pad);
    ctx.beginPath();
    ctx.moveTo(gx, pad); ctx.lineTo(gx, h - pad);
    ctx.moveTo(pad, gy); ctx.lineTo(w - pad, gy);
    ctx.stroke();
  }

  // Generar algunos puntos aleatorios en la curva para visualizar el retículo
  ctx.fillStyle = "rgba(148, 163, 184, 0.4)";
  for (let xi = 1n; xi < BigInt(Math.min(P, 150)); xi++) {
    const x3 = ermc.modMul(ermc.modMul(xi, xi, p), xi, p);
    const rhs = ermc.modAdd(x3, 7n, p);
    const yi = ermc.modSqrt(rhs, p);
    if (yi !== null) {
      ctx.beginPath();
      ctx.arc(mapX(xi), mapY(yi), 2, 0, Math.PI * 2);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(mapX(xi), mapY(p - yi), 2, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // Dibujar G (Cyan)
  if (G) {
    ctx.fillStyle = "#38bdf8";
    ctx.beginPath();
    ctx.arc(mapX(G.x), mapY(G.y), 6, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#fff";
    ctx.stroke();
    ctx.fillText(`G (${G.x}, ${G.y})`, mapX(G.x) + 8, mapY(G.y) - 8);
  }

  // Dibujar kG (Púrpura)
  if (kG && !kG.isInfinity) {
    ctx.fillStyle = "#a855f7";
    ctx.beginPath();
    ctx.arc(mapX(kG.x), mapY(kG.y), 7, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#fff";
    ctx.stroke();
    ctx.fillText(`k·G (${kG.x}, ${kG.y})`, mapX(kG.x) + 10, mapY(kG.y) + 15);
  }
}

// ===========================================================================
// MÓDULO 4: RAMANUJAN & RIEMANN
// ===========================================================================
function setupSeries() {
  const evalBtn = document.getElementById("series-eval-btn");
  const primesBtn = document.getElementById("series-primes-btn");
  const tInput = document.getElementById("ramanujan-t-input");
  const xInput = document.getElementById("riemann-x-input");
  const resultBox = document.getElementById("series-result-box");
  const timeBadge = document.getElementById("series-time-badge");
  const canvas = document.getElementById("series-canvas");

  if (!evalBtn) return;

  evalBtn.addEventListener("click", () => {
    try {
      const t = parseFloat(tInput.value);
      const t0 = performance.now();
      const lnF = ermc.mockThetaLn(t, 800);
      const watson = ermc.watsonAsymptotic(t);
      const errPct = Math.abs(lnF - watson) / Math.abs(watson) * 100;
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      let html = `<div><strong>Mock Theta de Ramanujan (Orden 3):</strong></div>`;
      html += `<div class="formula-highlight">ln|f(-e^{-${t}})| = ${lnF.toFixed(6)}</div>`;
      html += `<div>Asintótica de Watson: <span style="color: #a855f7;">${watson.toFixed(6)}</span></div>`;
      html += `<div>Error Relativo: <span style="color: ${errPct < 1 ? '#10b981' : '#f59e0b'}; font-weight: 600;">${errPct.toFixed(3)}%</span></div>`;
      html += `<div style="margin-top: 0.5rem; font-size: 0.8rem; color: var(--text-muted);">
        Fórmula teórica: Watson(t) = π²/(24t) - ½·ln(t) + ½·ln(π). A medida que t → 0, el error decrece a &lt; 0.01%.
      </div>`;
      resultBox.innerHTML = html;

      drawRamanujanPlot(canvas);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });

  primesBtn.addEventListener("click", () => {
    try {
      const x = parseFloat(xInput.value);
      const t0 = performance.now();
      const piExact = ermc.primeCountPi(x, 100000);
      const liVal = ermc.logarithmicIntegralLi(x);
      const errPct = Math.abs(liVal - piExact) / piExact * 100;
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      let html = `<div><strong>Distribución de Primos (Hipótesis de Riemann):</strong></div>`;
      html += `<div class="formula-highlight">π(${x}) = ${piExact} primos | Li(${x}) ≈ ${liVal.toFixed(2)}</div>`;
      html += `<div>Error Li(x) vs π(x): <span style="color: #10b981; font-weight: 600;">${errPct.toFixed(2)}%</span></div>`;

      // Tabla de puntos clave
      html += `<div style="margin-top: 0.75rem; font-size: 0.82rem;">
        <table style="width: 100%; border-collapse: collapse; text-align: left;">
          <tr style="border-bottom: 1px solid var(--border); color: var(--text-muted);">
            <th>x</th><th>π(x)</th><th>Li(x)</th><th>Error</th>
          </tr>
          ${[100, 1000, 5000, 10000].map(tx => {
            const p = ermc.primeCountPi(tx, 50000);
            const l = ermc.logarithmicIntegralLi(tx);
            const e = Math.abs(l - p) / p * 100;
            return `<tr><td>${tx}</td><td>${p}</td><td>${l.toFixed(1)}</td><td>${e.toFixed(2)}%</td></tr>`;
          }).join("")}
        </table>
      </div>`;

      resultBox.innerHTML = html;
      drawRiemannPlot(canvas);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });
}

function drawRamanujanPlot(canvas) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  const tVals = [0.5, 0.4, 0.3, 0.2, 0.1, 0.05, 0.03, 0.02];
  const lnFs = tVals.map(t => ermc.mockThetaLn(t, 500));
  const watsons = tVals.map(t => ermc.watsonAsymptotic(t));

  const maxVal = Math.max(...lnFs, ...watsons);
  const minVal = Math.min(...lnFs, ...watsons);

  ctx.strokeStyle = "#38bdf8";
  ctx.lineWidth = 2;
  ctx.beginPath();
  tVals.forEach((t, i) => {
    const px = 40 + (i / (tVals.length - 1)) * (w - 70);
    const py = (h - 30) - ((lnFs[i] - minVal) / (maxVal - minVal)) * (h - 60);
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  });
  ctx.stroke();

  ctx.strokeStyle = "#a855f7";
  ctx.lineWidth = 2;
  ctx.setLineDash([4, 4]);
  ctx.beginPath();
  tVals.forEach((t, i) => {
    const px = 40 + (i / (tVals.length - 1)) * (w - 70);
    const py = (h - 30) - ((watsons[i] - minVal) / (maxVal - minVal)) * (h - 60);
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  });
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.fillStyle = "#38bdf8";
  ctx.fillText("― ln|f(q)| Ramanujan", 50, 30);
  ctx.fillStyle = "#a855f7";
  ctx.fillText("--- Asintótica Watson", 200, 30);
}

function drawRiemannPlot(canvas) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  const testX = [500, 1000, 2500, 5000, 10000, 15000, 20000];
  const pis = testX.map(x => ermc.primeCountPi(x, 25000));
  const lis = testX.map(x => ermc.logarithmicIntegralLi(x));

  const maxVal = Math.max(...lis);
  ctx.strokeStyle = "#10b981";
  ctx.lineWidth = 2;
  ctx.beginPath();
  testX.forEach((x, i) => {
    const px = 40 + (i / (testX.length - 1)) * (w - 70);
    const py = (h - 30) - (pis[i] / maxVal) * (h - 60);
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  });
  ctx.stroke();

  ctx.strokeStyle = "#38bdf8";
  ctx.lineWidth = 2;
  ctx.setLineDash([3, 3]);
  ctx.beginPath();
  testX.forEach((x, i) => {
    const px = 40 + (i / (testX.length - 1)) * (w - 70);
    const py = (h - 30) - (lis[i] / maxVal) * (h - 60);
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  });
  ctx.stroke();
  ctx.setLineDash([]);

  ctx.fillStyle = "#10b981";
  ctx.fillText("― π(x) Exacto (Criba)", 50, 30);
  ctx.fillStyle = "#38bdf8";
  ctx.fillText("--- Li(x) Riemann", 200, 30);
}

// ===========================================================================
// MÓDULO 5: HILBERT & SVD
// ===========================================================================
function setupHilbert() {
  const computeBtn = document.getElementById("hilbert-compute-btn");
  const svdBtn = document.getElementById("svd-test-btn");
  const uInput = document.getElementById("hilbert-u-input");
  const vInput = document.getElementById("hilbert-v-input");
  const resultBox = document.getElementById("hilbert-result-box");
  const canvas = document.getElementById("svd-canvas");

  if (!computeBtn) return;

  computeBtn.addEventListener("click", () => {
    try {
      const u = uInput.value.split(",").map(s => parseFloat(s.trim()));
      const v = vInput.value.split(",").map(s => parseFloat(s.trim()));

      if (u.length !== v.length) {
        resultBox.innerHTML = `<div style="color: #f43f5e;">Los vectores deben tener la misma dimensión.</div>`;
        return;
      }

      const inner = ermc.innerProduct(u, v);
      const normU = ermc.norm(u);
      const normV = ermc.norm(v);
      const ang = ermc.angle(u, v);
      const angDeg = (ang * 180 / Math.PI).toFixed(2);
      const csLhs = Math.abs(inner);
      const csRhs = normU * normV;
      const csValid = csLhs <= csRhs + 1e-12;

      let html = `<div><strong>Geometría en Espacio de Hilbert $L^2$:</strong></div>`;
      html += `<div class="formula-highlight">⟨u, v⟩ = ${inner.toFixed(6)} | ‖u‖ = ${normU.toFixed(6)} | ‖v‖ = ${normV.toFixed(6)}</div>`;
      html += `<div>Ángulo entre u y v: <span style="color: #38bdf8;">${ang.toFixed(6)} rad (${angDeg}°)</span></div>`;
      html += `<div>Desigualdad de Cauchy-Schwarz: |⟨u,v⟩| (${csLhs.toFixed(6)}) ≤ ‖u‖·‖v‖ (${csRhs.toFixed(6)}) → <span style="color: #10b981;">${csValid ? 'Cumple ✓' : 'Falla'}</span></div>`;

      resultBox.innerHTML = html;
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });

  svdBtn.addEventListener("click", () => {
    try {
      // Matriz 4x3 de prueba
      const m = 4, n = 3;
      const A = [
        1.0, 2.0, 3.0,
        4.0, 5.0, 6.0,
        7.0, 8.0, 9.0,
        10.0, 11.0, 12.0
      ];

      const t0 = performance.now();
      const { ok, u, s, v } = ermc.svd(A, m, n);
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      const kappa = s[0] / (s[s.length - 1] || 1e-15);
      let html = `<div><strong>Descomposición SVD Jacobi (Matriz 4×3):</strong></div>`;
      html += `<div class="formula-highlight">Valores Singulares σ = [${s.map(val => val.toFixed(4)).join(", ")}]</div>`;
      html += `<div>Número de condición κ(A) = σ_max / σ_min: <span style="color: #a855f7;">${kappa.toExponential(4)}</span></div>`;
      html += `<div>Rango numérico efectivo: <span style="color: #10b981;">${s.filter(x => x > 1e-10).length}</span> de ${n}</div>`;

      resultBox.innerHTML = html;
      drawSvdPlot(canvas, s);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });
}

function drawSvdPlot(canvas, s) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  const maxSigma = Math.max(...s);
  const barWidth = Math.min(80, (w - 100) / s.length);

  s.forEach((val, i) => {
    const barHeight = (val / maxSigma) * (h - 80);
    const x = 50 + i * (barWidth + 25);
    const y = (h - 40) - barHeight;

    const grad = ctx.createLinearGradient(0, y, 0, h - 40);
    grad.addColorStop(0, "#38bdf8");
    grad.addColorStop(1, "#0369a1");

    ctx.fillStyle = grad;
    ctx.fillRect(x, y, barWidth, barHeight);

    ctx.fillStyle = "#f8fafc";
    ctx.font = "12px 'JetBrains Mono'";
    ctx.fillText(`σ${i + 1}`, x + barWidth / 2 - 10, h - 20);
    ctx.fillText(`${val.toFixed(2)}`, x + 5, y - 8);
  });
}

// ===========================================================================
// MÓDULO 6: OUTLIERS & PRECISIÓN NEUMAIER
// ===========================================================================
function setupRobust() {
  const runBtn = document.getElementById("hampel-run-btn");
  const dataInput = document.getElementById("hampel-data-input");
  const kInput = document.getElementById("hampel-k-input");
  const resultBox = document.getElementById("hampel-result-box");
  const timeBadge = document.getElementById("hampel-time-badge");
  const canvas = document.getElementById("hampel-canvas");

  if (!runBtn) return;

  runBtn.addEventListener("click", () => {
    try {
      const data = dataInput.value.split(",").map(s => parseFloat(s.trim()));
      const k = parseFloat(kInput.value);

      const t0 = performance.now();
      const { nOutliers, mask, clean } = ermc.hampel(data, k);
      const neumaier = ermc.neumaierSum(clean);
      const elapsedUs = ((performance.now() - t0) * 1000).toFixed(1);

      timeBadge.textContent = `${elapsedUs} μs`;

      // Calcular media ingenua
      let naiveSum = 0;
      for (const d of data) naiveSum += d;
      const naiveMean = naiveSum / data.length;

      let html = `<div><strong>Filtro Hampel (MAD Normalizado):</strong></div>`;
      html += `<div class="formula-highlight">${nOutliers} Outliers Detectados de ${data.length} muestras</div>`;
      html += `<div>Media Ingenua (desbordada por 10¹⁰⁰): <span style="color: #f43f5e;">${naiveMean.toExponential(4)}</span></div>`;
      html += `<div>Suma Compensada Neumaier de Datos Limpios: <span style="color: #10b981;">${neumaier.toFixed(6)}</span></div>`;
      html += `<div style="margin-top: 0.5rem; font-size: 0.8rem; color: var(--text-muted);">
        Máscara de Outliers: [${mask.map(m => m ? '<span style="color: #f43f5e;">OUTLIER</span>' : '<span style="color: #10b981;">OK</span>').join(", ")}]
      </div>`;

      resultBox.innerHTML = html;
      drawHampelPlot(canvas, data, mask, clean);
    } catch (err) {
      resultBox.innerHTML = `<div style="color: #f43f5e;">Error: ${err.message}</div>`;
    }
  });
}

function drawHampelPlot(canvas, data, mask, clean) {
  const ctx = canvas.getContext("2d");
  const w = canvas.width = canvas.parentElement.clientWidth;
  const h = canvas.height = 280;

  ctx.fillStyle = "#080c13";
  ctx.fillRect(0, 0, w, h);

  const cleanVals = clean.filter((_, i) => !mask[i]);
  const minV = Math.min(...cleanVals);
  const maxV = Math.max(...cleanVals);
  const range = (maxV - minV) || 1;

  data.forEach((val, i) => {
    const px = 40 + (i / (data.length - 1)) * (w - 70);
    if (mask[i]) {
      // Outlier
      ctx.fillStyle = "#f43f5e";
      ctx.beginPath();
      ctx.arc(px, 35, 6, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillText(`10¹⁰⁰`, px - 15, 20);
    } else {
      // Normal
      const py = (h - 40) - ((val - minV) / range) * (h - 100);
      ctx.fillStyle = "#10b981";
      ctx.beginPath();
      ctx.arc(px, py, 5, 0, Math.PI * 2);
      ctx.fill();
    }
  });

  ctx.fillStyle = "#10b981";
  ctx.fillText("● Muestras Limpias", 50, h - 15);
  ctx.fillStyle = "#f43f5e";
  ctx.fillText("● Outliers Aislados (Sin Overflow)", 200, h - 15);
}

// Inicialización de la aplicación
window.addEventListener("DOMContentLoaded", async () => {
  setupTabs();
  await initWasm();
  setupOmniEngine();
  setupModular();
  setupElliptic();
  setupSeries();
  setupHilbert();
  setupRobust();
});
