/**
 * Copyright (c) 2026 Edison Manrique Chocce
 * Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
 *
 * ermc-wasm.js — Wrapper WebAssembly universal para navegadores
 * Proporciona acceso de alto nivel a todas las funciones exportadas por ERMC WebAssembly.
 */

export class ErmcWasm {
  constructor() {
    this.instance = null;
    this.exports = null;
    this.memory = null;
  }

  /**
   * Carga e inicializa el binario WebAssembly desde una URL o ArrayBuffer
   */
  async init(wasmSource = "./ermc.wasm") {
    let bytes;
    if (wasmSource instanceof ArrayBuffer || wasmSource instanceof Uint8Array) {
      bytes = wasmSource;
    } else {
      const response = await fetch(wasmSource);
      if (!response.ok) {
        throw new Error(`No se pudo cargar el archivo WASM desde ${wasmSource} (HTTP ${response.status})`);
      }
      bytes = await response.arrayBuffer();
    }

    const { instance } = await WebAssembly.instantiate(bytes, {});
    this.instance = instance;
    this.exports = instance.exports;
    this.memory = this.exports.memory;
    return this;
  }

  // --- Manejo de memoria lineal WASM ---
  alloc(bytes) {
    return this.exports.ermc_wasm_alloc(bytes);
  }

  free(ptr, bytes) {
    this.exports.ermc_wasm_free(ptr, bytes);
  }

  writeF64Array(arr) {
    const ptr = this.alloc(arr.length * 8);
    new Float64Array(this.memory.buffer, ptr, arr.length).set(arr);
    return ptr;
  }

  readF64Array(ptr, len) {
    return Array.from(new Float64Array(this.memory.buffer, ptr, len));
  }

  writeU32Array(arr) {
    const ptr = this.alloc(arr.length * 4);
    new Uint32Array(this.memory.buffer, ptr, arr.length).set(arr);
    return ptr;
  }

  readCString(ptr, maxLen = 256) {
    const u8 = new Uint8Array(this.memory.buffer, ptr, maxLen);
    let end = 0;
    while (end < maxLen && u8[end] !== 0) end++;
    return new TextDecoder().decode(u8.subarray(0, end));
  }

  // --- Información general ---
  getVersion() {
    const buf = this.alloc(64);
    const len = this.exports.ermc_version_wasm(buf, 64);
    const str = this.readCString(buf, len);
    this.free(buf, 64);
    return str;
  }

  // --- OmniEngine: Descubrimiento Simbólico ---
  createEngine(nVars) {
    return this.exports.ermc_engine_create(nVars);
  }

  destroyEngine(handle) {
    this.exports.ermc_engine_destroy(handle);
  }

  buildDictionary(handle, activations) {
    const ptr = this.writeU32Array(activations);
    const ok = this.exports.ermc_engine_build_dictionary(handle, ptr, activations.length) !== 0;
    this.free(ptr, activations.length * 4);
    return ok;
  }

  getTermCount(handle) {
    return this.exports.ermc_engine_term_count(handle);
  }

  fit(handle, X_flat, y, lambda = 0.1) {
    const nSamples = y.length;
    const nVars = Math.round(X_flat.length / nSamples);
    const pX = this.writeF64Array(X_flat);
    const py = this.writeF64Array(y);
    const nTerms = this.getTermCount(handle);
    const pWeights = this.alloc(nTerms * 8);

    const ok = this.exports.ermc_engine_fit(handle, pX, py, nSamples, nVars, lambda, pWeights) !== 0;
    const weights = ok ? this.readF64Array(pWeights, nTerms) : [];

    this.free(pX, X_flat.length * 8);
    this.free(py, y.length * 8);
    this.free(pWeights, nTerms * 8);
    return { ok, weights };
  }

  getFormula(handle, weights, maxLen = 256) {
    const pWeights = this.writeF64Array(weights);
    const pBuf = this.alloc(maxLen);
    const len = this.exports.ermc_engine_get_formula(handle, pWeights, pBuf, maxLen);
    const formula = this.readCString(pBuf, len);
    this.free(pWeights, weights.length * 8);
    this.free(pBuf, maxLen);
    return formula;
  }

  predict(handle, inputVector, weights) {
    const pInput = this.writeF64Array(inputVector);
    const pWeights = this.writeF64Array(weights);
    const pred = this.exports.ermc_engine_predict(handle, pInput, pWeights);
    this.free(pInput, inputVector.length * 8);
    this.free(pWeights, weights.length * 8);
    return pred;
  }

  // --- Aritmética Modular F_p ---
  modAdd(a, b, p) {
    return this.exports.ermc_mod_add(BigInt(a), BigInt(b), BigInt(p));
  }

  modSub(a, b, p) {
    return this.exports.ermc_mod_sub(BigInt(a), BigInt(b), BigInt(p));
  }

  modMul(a, b, p) {
    return this.exports.ermc_mod_mul(BigInt(a), BigInt(b), BigInt(p));
  }

  modPow(base, exp, p) {
    return this.exports.ermc_mod_pow(BigInt(base), BigInt(exp), BigInt(p));
  }

  modInverse(a, p) {
    const U64_MAX = BigInt("18446744073709551615");
    const res = this.exports.ermc_mod_inverse(BigInt(a), BigInt(p));
    return res === U64_MAX ? null : res;
  }

  modSqrt(a, p) {
    const U64_MAX = BigInt("18446744073709551615");
    const res = this.exports.ermc_mod_sqrt(BigInt(a), BigInt(p));
    return res === U64_MAX ? null : res;
  }

  isQuadraticResidue(a, p) {
    const P = BigInt(p);
    const e = (P - 1n) / 2n;
    return this.modPow(a, e, P) === 1n;
  }

  // --- Curvas Elípticas y² = x³ + 7 mod p ---
  ecIsOnCurve(x, y, p) {
    return this.exports.ermc_ec_is_on_curve(BigInt(x), BigInt(y), BigInt(p)) !== 0;
  }

  ecAdd(px, py, qx, qy, p) {
    const pOut = this.alloc(16);
    this.exports.ermc_ec_add(BigInt(px), BigInt(py), BigInt(qx), BigInt(qy), BigInt(p), pOut);
    const view = new DataView(this.memory.buffer);
    const lo0 = BigInt(view.getUint32(pOut, true));
    const hi0 = BigInt(view.getUint32(pOut + 4, true));
    const lo1 = BigInt(view.getUint32(pOut + 8, true));
    const hi1 = BigInt(view.getUint32(pOut + 12, true));
    this.free(pOut, 16);
    const rx = (hi0 << 32n) | lo0;
    const ry = (hi1 << 32n) | lo1;
    return { x: rx, y: ry, isInfinity: rx === 0n && ry === 0n };
  }

  ecScalarMul(k, px, py, p) {
    const pOut = this.alloc(16);
    this.exports.ermc_ec_scalar_mul(BigInt(k), BigInt(px), BigInt(py), BigInt(p), pOut);
    const view = new DataView(this.memory.buffer);
    const lo0 = BigInt(view.getUint32(pOut, true));
    const hi0 = BigInt(view.getUint32(pOut + 4, true));
    const lo1 = BigInt(view.getUint32(pOut + 8, true));
    const hi1 = BigInt(view.getUint32(pOut + 12, true));
    this.free(pOut, 16);
    const rx = (hi0 << 32n) | lo0;
    const ry = (hi1 << 32n) | lo1;
    return { x: rx, y: ry, isInfinity: rx === 0n && ry === 0n };
  }

  // --- Series Analíticas & Ramanujan ---
  mockThetaLn(t, maxTerms = 500) {
    return this.exports.ermc_ramanujan_mock_theta_ln(Number(t), maxTerms);
  }

  watsonAsymptotic(t) {
    return this.exports.ermc_ramanujan_watson_asymptotic(Number(t));
  }

  primeCountPi(x, maxN = 100000) {
    return this.exports.ermc_prime_count_pi(Number(x), maxN);
  }

  logarithmicIntegralLi(x) {
    return this.exports.ermc_logarithmic_integral_li(Number(x));
  }

  // --- Espacios de Hilbert ---
  innerProduct(u, v) {
    const pu = this.writeF64Array(u);
    const pv = this.writeF64Array(v);
    const res = this.exports.ermc_hilbert_inner(pu, pv, u.length);
    this.free(pu, u.length * 8);
    this.free(pv, v.length * 8);
    return res;
  }

  norm(u) {
    const pu = this.writeF64Array(u);
    const res = this.exports.ermc_hilbert_norm(pu, u.length);
    this.free(pu, u.length * 8);
    return res;
  }

  angle(u, v) {
    const pu = this.writeF64Array(u);
    const pv = this.writeF64Array(v);
    const res = this.exports.ermc_hilbert_angle(pu, pv, u.length);
    this.free(pu, u.length * 8);
    this.free(pv, v.length * 8);
    return res;
  }

  // --- SVD ---
  svd(matrixFlat, m, n) {
    const pMat = this.writeF64Array(matrixFlat);
    const pU = this.alloc(m * n * 8);
    const pS = this.alloc(n * 8);
    const pV = this.alloc(n * n * 8);

    const ok = this.exports.ermc_svd(pMat, m, n, pU, pS, pV) !== 0;
    const u = ok ? this.readF64Array(pU, m * n) : [];
    const s = ok ? this.readF64Array(pS, n) : [];
    const v = ok ? this.readF64Array(pV, n * n) : [];

    this.free(pMat, matrixFlat.length * 8);
    this.free(pU, m * n * 8);
    this.free(pS, n * 8);
    this.free(pV, n * n * 8);
    return { ok, u, s, v };
  }

  // --- Estadística Robusta (Hampel) & Precisión Neumaier ---
  hampel(data, kThreshold = 3.0) {
    const pData = this.writeF64Array(data);
    const pMask = this.alloc(data.length);
    const pClean = this.alloc(data.length * 8);

    const nOutliers = this.exports.ermc_outliers_hampel(pData, data.length, kThreshold, pMask, pClean);
    const mask = Array.from(new Uint8Array(this.memory.buffer, pMask, data.length)).map(x => x === 1);
    const clean = this.readF64Array(pClean, data.length);

    this.free(pData, data.length * 8);
    this.free(pMask, data.length);
    this.free(pClean, data.length * 8);
    return { nOutliers, mask, clean };
  }

  neumaierSum(data) {
    const pData = this.writeF64Array(data);
    const sum = this.exports.ermc_precision_sum(pData, data.length);
    this.free(pData, data.length * 8);
    return sum;
  }
}
