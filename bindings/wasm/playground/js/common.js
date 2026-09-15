/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial segun LICENSE.
 *
 * common.js - Menu comun, singleton WebAssembly, helpers de canvas y renderizado
 *             Markdown/LaTeX para el Playground ERMC.
 */

const NAV_ITEMS = [
  { id: "dashboard",  href: "index.html",      title: "⚡ Dashboard Central",    badge: "HUB"    },
  { id: "omniengine", href: "omniengine.html",  title: "🔬 OmniEngine (SciML)",  badge: "SINDy"  },
  { id: "modular",    href: "modular.html",     title: "🔢 Aritmetica Modular",   badge: "F_p"    },
  { id: "elliptic",   href: "elliptic.html",    title: "⚡ Curvas Elipticas",     badge: "GLV"    },
  { id: "series",     href: "series.html",      title: "🌌 Ramanujan & Riemann",  badge: "SERIES" },
  { id: "hilbert",    href: "hilbert.html",     title: "📐 Espacios de Hilbert",  badge: "L^2"    },
  { id: "outliers",   href: "outliers.html",    title: "🛡️ Outliers & Precision", badge: "MAD"    },
  { id: "chaos",      href: "chaos.html",       title: "🌀 Caos de Lorenz",       badge: "RK4"    },
];

export function initLayout(activeId = "dashboard") {
  const header = document.getElementById("app-header");
  if (header) {
    header.className = "app-header";
    header.innerHTML = `
      <a href="index.html" class="brand-container">
        <div class="brand-logo">⚡</div>
        <div class="brand-title">ERMC SciML <span class="tag">WASM v0.4.0</span></div>
      </a>
      <div class="header-status">
        <div class="wasm-badge">
          <span class="status-dot" id="wasm-status-dot"></span>
          <span id="wasm-status-text">Inicializando WASM...</span>
        </div>
      </div>`;
  }
  const sidebar = document.getElementById("app-sidebar");
  if (sidebar) {
    sidebar.className = "app-sidebar";
    let html = `<div class="sidebar-title">Modulos Cientificos</div>`;
    NAV_ITEMS.forEach(({ id, href, title, badge }) => {
      const active = id === activeId ? "active" : "";
      html += `<a href="${href}" class="sidebar-item ${active}"><span>${title}</span>${badge ? `<span class="item-badge">${badge}</span>` : ""}</a>`;
    });
    sidebar.innerHTML = html;
  }
}

// SINGLETON WEBASSEMBLY
class ErmcWasmEngine {
  constructor() { this.instance = null; this.exports = null; this.memory = null; }

  async init(wasmPath = "./ermc.wasm") {
    if (this.exports) return this;
    const dot = document.getElementById("wasm-status-dot");
    const txt = document.getElementById("wasm-status-text");
    try {
      if (txt) txt.innerText = "Cargando WASM...";
      const resp = await fetch(wasmPath);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const { instance } = await WebAssembly.instantiate(await resp.arrayBuffer(), {});
      this.instance = instance; this.exports = instance.exports; this.memory = this.exports.memory;
      if (dot) dot.classList.add("active");
      if (txt) txt.innerText = "WASM Listo (ReleaseFast)";
      return this;
    } catch (err) {
      if (txt) txt.innerText = "Error: " + err.message;
      if (dot) dot.style.background = "#F6465D";
      throw err;
    }
  }

  alloc(bytes) {
    const fn = this.exports.ermc_alloc || this.exports.ermc_wasm_alloc;
    if (!fn) throw new Error("ermc_alloc no disponible");
    return fn(bytes);
  }
  free(ptr, bytes) { const fn = this.exports.ermc_free || this.exports.ermc_wasm_free; if (fn && ptr !== 0) fn(ptr, bytes); }
  writeF64Array(arr) { const ptr = this.alloc(arr.length * 8); new Float64Array(this.memory.buffer, ptr, arr.length).set(arr); return ptr; }
  readF64Array(ptr, len) { return Array.from(new Float64Array(this.memory.buffer, ptr, len)); }
  writeU32Array(arr) { const ptr = this.alloc(arr.length * 4); new Uint32Array(this.memory.buffer, ptr, arr.length).set(arr); return ptr; }
  readCString(ptr, maxLen = 256) {
    const u8 = new Uint8Array(this.memory.buffer, ptr, maxLen);
    let e = 0; while (e < maxLen && u8[e] !== 0) e++;
    return new TextDecoder().decode(u8.subarray(0, e));
  }

  createEngine(n) { return this.exports.ermc_engine_create(n); }
  destroyEngine(h) { if (h) this.exports.ermc_engine_destroy(h); }
  getTermCount(h) { return this.exports.ermc_engine_term_count(h); }
  buildDictionary(h, acts) {
    const p = this.writeU32Array(acts);
    const ok = this.exports.ermc_engine_build_dictionary(h, p, acts.length) !== 0;
    this.free(p, acts.length * 4); return ok;
  }
  fit(h, X, y, lambda = 0.05) {
    const pX = this.writeF64Array(X), py = this.writeF64Array(y);
    const nT = this.getTermCount(h), pW = this.alloc(nT * 8);
    const ok = this.exports.ermc_engine_fit(h, pX, py, y.length, Math.round(X.length / y.length), lambda, pW) !== 0;
    const weights = ok ? this.readF64Array(pW, nT) : [];
    this.free(pX, X.length * 8); this.free(py, y.length * 8); this.free(pW, nT * 8);
    return { ok, weights };
  }
  getFormula(h, w, maxLen = 256) {
    const pW = this.writeF64Array(w), pB = this.alloc(maxLen);
    const len = this.exports.ermc_engine_get_formula(h, pW, pB, maxLen);
    const f = this.readCString(pB, len);
    this.free(pW, w.length * 8); this.free(pB, maxLen); return f;
  }
  predict(h, input, w) {
    const pI = this.writeF64Array(input), pW = this.writeF64Array(w);
    const v = this.exports.ermc_engine_predict(h, pI, pW);
    this.free(pI, input.length * 8); this.free(pW, w.length * 8); return v;
  }

  modAdd(a, b, p) { return this.exports.ermc_mod_add(BigInt(a), BigInt(b), BigInt(p)); }
  modSub(a, b, p) { return this.exports.ermc_mod_sub(BigInt(a), BigInt(b), BigInt(p)); }
  modMul(a, b, p) { return this.exports.ermc_mod_mul(BigInt(a), BigInt(b), BigInt(p)); }
  modPow(base, exp, p) { return this.exports.ermc_mod_pow(BigInt(base), BigInt(exp), BigInt(p)); }
  modInverse(a, p) { const U = BigInt("18446744073709551615"), r = this.exports.ermc_mod_inverse(BigInt(a), BigInt(p)); return r === U ? null : r; }
  modSqrt(a, p)    { const U = BigInt("18446744073709551615"), r = this.exports.ermc_mod_sqrt(BigInt(a), BigInt(p));    return r === U ? null : r; }

  ecIsOnCurve(x, y, p) { return this.exports.ermc_ec_is_on_curve(BigInt(x), BigInt(y), BigInt(p)) !== 0; }
  _readPt(pOut) {
    const v = new DataView(this.memory.buffer);
    const rx = (BigInt(v.getUint32(pOut + 4, true)) << 32n) | BigInt(v.getUint32(pOut,     true));
    const ry = (BigInt(v.getUint32(pOut +12, true)) << 32n) | BigInt(v.getUint32(pOut + 8, true));
    this.free(pOut, 16);
    return { x: rx, y: ry, isInfinity: rx === 0n && ry === 0n };
  }
  ecAdd(px, py, qx, qy, p)  { const o = this.alloc(16); this.exports.ermc_ec_add(BigInt(px), BigInt(py), BigInt(qx), BigInt(qy), BigInt(p), o); return this._readPt(o); }
  ecScalarMul(k, px, py, p) { const o = this.alloc(16); this.exports.ermc_ec_scalar_mul(BigInt(k), BigInt(px), BigInt(py), BigInt(p), o); return this._readPt(o); }

  mockThetaLn(t, n = 500)    { return this.exports.ermc_ramanujan_mock_theta_ln(Number(t), n); }
  watsonAsymptotic(t)         { return this.exports.ermc_ramanujan_watson_asymptotic(Number(t)); }
  primeCountPi(x, n = 100000){ return this.exports.ermc_prime_count_pi(Number(x), n); }
  logarithmicIntegralLi(x)   { return this.exports.ermc_logarithmic_integral_li(Number(x)); }

  innerProduct(u, v) { const pu = this.writeF64Array(u), pv = this.writeF64Array(v); const r = this.exports.ermc_hilbert_inner(pu, pv, u.length); this.free(pu, u.length*8); this.free(pv, v.length*8); return r; }
  norm(u)            { const p = this.writeF64Array(u);  const r = this.exports.ermc_hilbert_norm(p, u.length);  this.free(p, u.length*8);  return r; }
  angle(u, v)        { const pu = this.writeF64Array(u), pv = this.writeF64Array(v); const r = this.exports.ermc_hilbert_angle(pu, pv, u.length); this.free(pu, u.length*8); this.free(pv, v.length*8); return r; }
  svd(mat, m, n) {
    const pM = this.writeF64Array(mat), pU = this.alloc(m*n*8), pS = this.alloc(n*8), pV = this.alloc(n*n*8);
    const ok = this.exports.ermc_svd(pM, m, n, pU, pS, pV) !== 0;
    const u = ok ? this.readF64Array(pU, m*n) : [], s = ok ? this.readF64Array(pS, n) : [], v = ok ? this.readF64Array(pV, n*n) : [];
    this.free(pM, mat.length*8); this.free(pU, m*n*8); this.free(pS, n*8); this.free(pV, n*n*8);
    return { ok, u, s, v };
  }

  hampel(data, k = 3.0) {
    const pD = this.writeF64Array(data), pM = this.alloc(data.length), pC = this.alloc(data.length*8);
    const n = this.exports.ermc_outliers_hampel(pD, data.length, k, pM, pC);
    const mask = Array.from(new Uint8Array(this.memory.buffer, pM, data.length)).map(x => x === 1);
    const clean = this.readF64Array(pC, data.length);
    this.free(pD, data.length*8); this.free(pM, data.length); this.free(pC, data.length*8);
    return { nOutliers: n, mask, clean };
  }
  neumaierSum(data) { const p = this.writeF64Array(data); const r = this.exports.ermc_precision_sum(p, data.length); this.free(p, data.length*8); return r; }

  chaosLorenz(x0, y0, z0) {
    const pL = this.alloc(8), pH = this.alloc(8);
    const ok = this.exports.ermc_chaos_lorenz(x0, y0, z0, pL, pH) !== 0;
    const lyap = new Float64Array(this.memory.buffer, pL, 1)[0];
    const horiz = new Float64Array(this.memory.buffer, pH, 1)[0];
    this.free(pL, 8); this.free(pH, 8);
    return { ok, lyap, horiz };
  }
}

export const ermc = new ErmcWasmEngine();
export async function initWasm() { return ermc.init("./ermc.wasm"); }

// CANVAS — ResizeObserver-based sizing (fixes blank chart on first render)
export function watchCanvas(canvas, drawFn) {
  const parent = canvas.parentElement;
  function paint() {
    const rect = parent.getBoundingClientRect();
    const w = Math.floor(rect.width), h = Math.floor(rect.height);
    if (!w || !h) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width  = w * dpr; canvas.height = h * dpr;
    canvas.style.width = w + "px"; canvas.style.height = h + "px";
    const ctx = canvas.getContext("2d"); ctx.scale(dpr, dpr);
    drawFn(ctx, w, h);
  }
  const ro = new ResizeObserver(paint);
  ro.observe(parent);
  requestAnimationFrame(paint);
  return ro;
}

export function fitCanvas(canvas) {
  const parent = canvas.parentElement;
  const rect = parent.getBoundingClientRect();
  const dpr = window.devicePixelRatio || 1;
  const w = Math.max(Math.floor(rect.width), 100);
  const h = Math.max(Math.floor(rect.height), 200);
  canvas.width  = w * dpr; canvas.height = h * dpr;
  canvas.style.width = w + "px"; canvas.style.height = h + "px";
  const ctx = canvas.getContext("2d"); ctx.scale(dpr, dpr);
  return { ctx, w, h };
}

// MATH & MARKDOWN — KaTeX + marked lazy-loaded from CDN
let _katexP = null, _markedP = null;
function loadScript(src) {
  return new Promise((ok, fail) => {
    const s = document.createElement("script");
    s.src = src; s.defer = true; s.onload = ok; s.onerror = fail;
    document.head.appendChild(s);
  });
}
async function loadKatex()  { if (!_katexP)  _katexP  = window.katex  ? Promise.resolve(window.katex)  : loadScript("https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js").then(() => window.katex);  return _katexP; }
async function loadMarked() { if (!_markedP) _markedP = window.marked ? Promise.resolve(window.marked) : loadScript("https://cdn.jsdelivr.net/npm/marked@12.0.0/marked.min.js").then(() => window.marked); return _markedP; }

export async function renderMath(element) {
  const katex = await loadKatex();
  if (!katex || !element) return;
  function walk(node) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent;
      if (!text.includes("$")) return;
      const re = /\$\$([^$]+)\$\$|\$([^$\n]+)\$/g;
      const frag = document.createDocumentFragment();
      let last = 0, m;
      while ((m = re.exec(text)) !== null) {
        if (m.index > last) frag.appendChild(document.createTextNode(text.slice(last, m.index)));
        const display = !!m[1], formula = (m[1] || m[2]).trim();
        const wrap = document.createElement(display ? "div" : "span");
        try { katex.render(formula, wrap, { throwOnError: false, displayMode: display, output: "html" }); }
        catch { wrap.textContent = m[0]; }
        frag.appendChild(wrap);
        last = m.index + m[0].length;
      }
      if (last < text.length) frag.appendChild(document.createTextNode(text.slice(last)));
      node.parentNode.replaceChild(frag, node);
    } else if (node.nodeType === Node.ELEMENT_NODE && !["SCRIPT","STYLE","CODE","PRE"].includes(node.tagName)) {
      Array.from(node.childNodes).forEach(walk);
    }
  }
  walk(element);
}

export async function renderMarkdown(markdown, element) {
  const [marked] = await Promise.all([loadMarked(), loadKatex()]);
  if (!marked || !element) return;
  marked.setOptions({ gfm: true, breaks: true });
  element.innerHTML = marked.parse(markdown);
  element.classList.add("md-content");
  await renderMath(element);
}

// UTILITIES
export function showToast(msg) {
  let c = document.getElementById("toast-container");
  if (!c) { c = document.createElement("div"); c.id = "toast-container"; document.body.appendChild(c); }
  const t = Object.assign(document.createElement("div"), { className: "toast", innerText: msg });
  c.appendChild(t);
  setTimeout(() => { t.style.cssText += ";opacity:0;transform:translateY(20px);transition:all .25s ease"; setTimeout(() => t.remove(), 250); }, 2500);
}

export function copyToClipboard(text, label = "Texto") {
  if (!text) return;
  navigator.clipboard.writeText(text).then(() => showToast(`✓ ${label} copiado`)).catch(() => showToast("❌ Error al copiar"));
}
