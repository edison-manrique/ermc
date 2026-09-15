# ERMC ⚡🔬
### Exact Regression Mathematical Core

> **ERMC (Exact Regression Mathematical Core)**: *Regresión exacta + núcleo matemático.*  
> Motor de Inteligencia Artificial Matemática, SciML (Scientific Machine Learning), Descubrimiento Simbólico de Leyes Físicas, Curvas Elípticas, Aritmética Modular y Álgebra Numérica de Ultra Precisión.  
> Escrito en **Zig 0.16.0** con cero dependencias externas y soporte multiplataforma nativo en **TypeScript (Bun)**, **WebAssembly (Browsers/Node/Bun)** y **Python**.

[![Zig 0.16.0](https://img.shields.io/badge/Zig-0.16.0-orange.svg?logo=zig)](https://ziglang.org/)
[![Version](https://img.shields.io/badge/Version-v0.4.0-brightgreen.svg)]()
[![Bun](https://img.shields.io/badge/Bun-v1.4+-black.svg?logo=bun)](https://bun.sh/)
[![WebAssembly](https://img.shields.io/badge/WebAssembly-ReleaseFast-654ff0.svg?logo=webassembly)](./bindings/wasm)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg?logo=python)](./bindings/python)
[![Tests](https://img.shields.io/badge/Tests-All%20Passing-brightgreen.svg)]()
[![License: Dual AGPLv3 / Commercial](https://img.shields.io/badge/License-Dual%20AGPLv3%20%2F%20Commercial-purple.svg)](./LICENSE)
[![Author](https://img.shields.io/badge/Author-Edison%20Manrique%20Chocce-blue.svg)]()
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0-success.svg)]()

---

## 📑 Tabla de Contenidos

1. [¿Qué es `ERMC`?](#-qué-es-ermc)
2. [Capacidades Principales](#-capacidades-principales)
3. [Ecosistema Multiplataforma](#-ecosistema-multiplataforma)
4. [WebAssembly Interactive Playground](#-webassembly-interactive-playground)
5. [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
6. [Inicio Rápido](#-inicio-rápido)
   - [Compilación con Zig](#compilación-con-zig)
   - [Compilación WebAssembly](#compilación-webassembly)
   - [Ejecución de Tests y CLI Científica](#ejecución-de-tests-y-cli-científica)
   - [Uso con Bun / TypeScript](#uso-con-bun--typescript)
   - [Uso con WebAssembly](#uso-con-webassembly)
   - [Uso con Python](#uso-con-python)
7. [Guía Rápida de Dominios y Ejemplos](#-guía-rápida-de-dominios-y-ejemplos)
   - [1. Descubrimiento Simbólico de Ecuaciones (SINDy / STLSQ)](#1-descubrimiento-simbólico-de-ecuaciones-sindy--stlsq)
   - [2. Aritmética Modular en $\mathbb{F}_p$](#2-aritmética-modular-en-mathbbf_p)
   - [3. Curvas Elípticas $y^2 = x^3 + 7 \pmod p$ & Endomorfismo GLV](#3-curvas-elípticas-y2--x3--7-pmod-p--endomorfismo-glv)
   - [4. Series Analíticas: Mock Theta de Ramanujan y Primos de Riemann](#4-series-analíticas-mock-theta-de-ramanujan-y-primos-de-riemann)
   - [5. Espacios de Hilbert y Ortogonalidad MGS-DGKS](#5-espacios-de-hilbert-y-ortogonalidad-mgs-dgks)
   - [6. Detección de Outliers Extremos ($10^{100}$) y Filtro Hampel](#6-detección-de-outliers-extremos-10100-y-filtro-hampel)
   - [7. Aritmética Compensada Neumaier](#7-aritmética-compensada-neumaier)
   - [8. Descomposición en Valores Singulares (SVD)](#8-descomposición-en-valores-singulares-svd)
   - [9. Dynamic Mode Decomposition (DMD)](#9-dynamic-mode-decomposition-dmd)
   - [10. Detección de Caos y Exponentes de Lyapunov](#10-detección-de-caos-y-exponentes-de-lyapunov)
   - [11. IA de Sucesiones Matemáticas](#11-ia-de-sucesiones-matemáticas)
8. [Estructura del Código y Modularidad](#-estructura-del-código-y-modularidad)
9. [Documentación Adicional](#-documentación-adicional)
10. [Licencia y Atribución](#-licencia-y-derechos-de-autor)

---

## 🌟 ¿Qué es `ERMC`?

**ERMC** (**E**xact **R**egression **M**athematical **C**ore) es una biblioteca científica y motor matemático de ultra alto rendimiento diseñado para resolver problemas donde las bibliotecas tradicionales de machine learning fallan: **pérdida de precisión numérica en punto flotante**, **cajas negras sin interpretabilidad**, **inestabilidad ante perturbaciones astronómicas**, **desbordamientos en aritmética modular** y **sobrecarga de dependencias pesadas**.

Combina técnicas de **Scientific Machine Learning (SciML)** con algoritmos rigurosos de teoría de números, geometría algebraica, análisis funcional y álgebra lineal numérica:

- **Descubrimiento Simbólico Interpretable**: A partir de nubes de datos o series temporales, deduce la ley física exacta subyacente (ej: $f(x) = -9.81\sin(x_0) - \frac{1}{2}x_1^2$, Ley de Snell con fracción exacta $4/3$, adiabática con $\gamma = 5/3$) mediante expansión no lineal y regresión esparsa STLSQ.
- **Aritmética Modular en $\mathbb{F}_p$**: Operaciones algebraicas modulares completas en enteros de 64 bits sin signo (`u64`), cálculo de inversos modulares con el Algoritmo Extendido de Euclides, exponenciación binaria, raíces cuadradas modulares con Tonelli-Shanks y verificación del Pequeño Teorema de Fermat.
- **Curvas Elípticas & Criptografía Algebraica**: Curva corta de Weierstrass $y^2 = x^3 + 7 \pmod p$ (secp256k1 reducida / curva de Koblitz), ley de grupo asociativa, duplicación puntual, multiplicación escalar $k \cdot P$ mediante *double-and-add*, y aceleración por endomorfismo GLV $\phi(P) = (\beta x, y)$ con $\beta^3 \equiv 1 \pmod p$.
- **Series Analíticas y Teoría de Números**: Evaluación en espacio logarítmico de la función Mock Theta $f(q)$ de orden 3 de Ramanujan, convergencia a la asintótica de Watson $\frac{\pi^2}{24t} - \frac{1}{2}\ln(t) + \frac{1}{2}\ln(\pi)$, criba de Eratóstenes para conteo de primos $\pi(x)$ y validación de la Hipótesis de Riemann con la integral logarítmica $\text{Li}(x)$.
- **Espacios de Hilbert**: Descomposición ortogonal directa $v = P_W(v) + v^\perp$, cálculo de normas, ángulos y re-ortogonalización bi-etapa MGS-DGKS a precisión de máquina ($\sim 10^{-16}$).
- **Inmunidad a Outliers Extremos**: Filtro Hampel robusto que aísla perturbaciones de magnitud cósmica ($\pm 10^{100}$) sin corromper el cálculo estadístico ni desbordar los acumuladores.
- **Aritmética Compensada Neumaier**: Sumas y varianzas que rastrean y corrigen activamente el error de redondeo residual en IEEE 754 de 64 bits.
- **Diagnóstico No Lineal y Caos**: SVD One-Sided Jacobi, extracción modal DMD y cálculo del exponente máximo de Lyapunov $\lambda$ con horizonte de predictibilidad $T_L = 1/\lambda$.

---

## 🚀 Capacidades Principales

| Dominio | Algoritmo / Técnica | Precisión / Característica |
| :--- | :--- | :--- |
| **SciML Simbólico** | SINDy / STLSQ + Snapping Racional | Recuperación de coeficientes analíticos exactos ($4/3$, $5/3$, $1/2$) |
| **Aritmética Modular** | Campos Finitos $\mathbb{F}_p$, Euclides Extendido, Tonelli-Shanks | Inversos, raíces modulares y criterio de Euler en 64 bits sin desbordar |
| **Curvas Elípticas** | $y^2 = x^3 + 7 \pmod p$, Ley de Grupo, GLV Endomorphism | Multiplicación escalar $k \cdot P$ y endomorfismo $\phi(P) = (\beta x, y)$ |
| **Series Analíticas** | Ramanujan Mock Theta $f(q)$ & Watson Asymptotic | $\ln\|f(-e^{-t})\|$ con error $< 0.01\%$ vs modelo asintótico de Watson |
| **Distribución de Primos** | Criba de Eratóstenes $\pi(x)$ vs Riemann $\text{Li}(x)$ | Verificación numérica de la Hipótesis de Riemann y offset Ramanujan-Soldner |
| **Espacios de Hilbert** | $L^2$ Inner Product, Proyección $P_W$, MGS-DGKS | Ortogonalidad garantizada a $\varepsilon_{\text{mach}} \approx 10^{-16}$ |
| **Estadística Robusta** | Filtro Hampel con MAD Normalizado | Maneja outliers de magnitud $\pm 10^{100}$ sin desbordar |
| **Aritmética Exacta** | Neumaier Compensated Sum & Mean | Cancela el error de redondeo acumulado en `f64` |
| **Álgebra Matricial** | SVD One-Sided Jacobi & Pseudoinversa Moore-Penrose | Rango efectivo numérico y número de condición $\kappa(A)$ |
| **Sistemas Dinámicos** | Dynamic Mode Decomposition (DMD) | Identificación de modos espaciales coherentes y frecuencias puras |
| **Teoría del Caos** | Exponente de Lyapunov vía perturbaciones RK4 | Cálculo del tiempo de Lyapunov $T_L = 1/\lambda_{\max}$ |
| **Diferenciación** | AutoDiff Forward-Mode con Números Duales | Gradientes exactos de derivadas parciales sin aproximación |
| **Secuencias** | Diferencias Finitas Polinomiales | Predicción exacta de términos siguientes en series enteras |

---

## 🌐 Ecosistema Multiplataforma

`ERMC` está diseñado bajo una arquitectura de núcleo único con interfaces sincronizadas:

1. **Zig Core (Nativo)**: Rendimiento a nivel de hardware, compilación sin libc opcional, seguridad de memoria sin garbage collector.
2. **TypeScript / Bun (`bindings/bun/`)**: Bindings C-ABI tipados de máxima velocidad mediante FFI directa (`.dll` en Windows, `.so` en Linux, `.dylib` en macOS).
3. **WebAssembly (`bindings/wasm/`)**: Compilación `wasm32-freestanding` en modo `ReleaseFast`. Funciona en cualquier navegador moderno, Node.js y Bun.
4. **Python (`bindings/python/`)**: Bindings idiomáticos mediante `ctypes` sin necesidad de toolchains C++ pesados.

---

## 🎨 WebAssembly Interactive Playground

Para experimentar interactivamente con todas las capacidades de la biblioteca sin instalar compiladores nativos, ERMC incluye un **Playground WebAssembly** de diseño obsidian premium con gráficos en tiempo real:

```bash
# Iniciar el playground localmente
bun run playground
```

Abre en tu navegador: **`http://localhost:3000`**

### Módulos del Playground:
- **🔬 OmniEngine**: Elige entre péndulos con resistencia cuadrática, refracción de Snell, leyes adiabáticas o datos con ruido; presiona "Ejecutar Descubrimiento" y observa la sintetización simbólica de la fórmula analítica en microsegundos junto con el gráfico canvas interactivo.
- **🔢 Aritmética Modular**: Realiza sumas, productos, potencias $a^e \pmod p$, inversos euclidianos $a^{-1} \pmod p$, raíces de Tonelli-Shanks $\sqrt{a} \pmod p$ y comprobación instantánea del Pequeño Teorema de Fermat.
- **⚡ Curvas Elípticas**: Explora la curva $y^2 = x^3 + 7 \pmod p$, localiza puntos generadores $G$, visualiza el retículo discreto de puntos en canvas, computa multiplicaciones escalares $k \cdot G$ y verifica el endomorfismo GLV.
- **🌌 Ramanujan & Riemann**: Compara en tiempo real la función Mock Theta de Ramanujan contra la asintótica de Watson, y evalúa el contador de primos $\pi(x)$ frente a la integral logarítmica $\text{Li}(x)$.
- **📐 Espacios de Hilbert & SVD**: Calcula productos internos, ángulos, desigualdad de Cauchy-Schwarz y espectro de valores singulares con barra interactiva de energías.
- **🛡️ Outliers & Precisión**: Inyecta outliers astronómicos ($10^{100}$) y contrasta la media desbordada contra el filtro Hampel inmune y la suma compensada de Neumaier.

---

## 📁 Arquitectura del Proyecto

```text
ermc/
├── package.json                  <-- Scripts raíz ("playground", "build:wasm", "test:all", "demo:py")
├── .gitignore                    <-- Exclusión de caches, builds y artefactos
├── LICENSE                       <-- Licencia Dual (AGPL-3.0 / Comercial) y Atribución
├── README.md                     <-- Documentación principal del proyecto
├── GUIA_DE_USO.md                <-- Manual técnico de uso detallado
├── build.zig                     <-- Script de compilación Zig 0.16.0 (targets: lib, exe, test, wasm)
├── build.zig.zon                 <-- Metadatos del paquete Zig (ermc v0.4.0)
├── src/                          <-- CÓDIGO FUENTE PURO DEL MOTOR ZIG
│   ├── root.zig                  <-- Punto de entrada del módulo Zig
│   ├── engine.zig                <-- Fachada principal OmniEngine (SciML)
│   ├── ffi.zig                   <-- Capa de exportación C-ABI (.dll / .so)
│   ├── wasm.zig                  <-- Capa de exportación WebAssembly freestanding
│   ├── core/                     <-- SIMD, Aritmética Neumaier, RNG, SafeNorm
│   ├── linalg/                   <-- Matrices, QR, Hilbert (MGS-DGKS), SVD Jacobi
│   ├── modular/                  <-- Aritmética modular F_p, Fermat, Tonelli-Shanks, regresión
│   ├── geometry/                 <-- Curvas elípticas y²=x³+7 mod p, suma, scalar mul, GLV
│   ├── stats/                    <-- Filtro Hampel, MAD, Test ESD
│   ├── filter/                   <-- Savitzky-Golay (suavizado y derivadas numéricas)
│   ├── symbolic/                 <-- Diccionario de funciones, Snapping racional
│   ├── solver/                   <-- STLSQ, SINDy, DMD, Integrador RK4, Caos
│   ├── autodiff/                 <-- Números duales, Diferenciación Automática
│   └── series/                   <-- Sucesiones enteras + Asintóticas de Ramanujan y Riemann
├── tests/                        <-- SUITE MODULAR DE PRUEBAS
│   ├── root.zig                  <-- Test Runner central
│   ├── modular_test.zig          <-- Pruebas de aritmética modular F_p
│   ├── elliptic_test.zig         <-- Pruebas de curvas elípticas y GLV
│   ├── asymptotics_test.zig      <-- Pruebas de Ramanujan mock theta y primos
│   └── ...                       <-- Pruebas de linalg, stats, solver, autodiff, etc.
├── examples/                     <-- 14 EJEMPLOS CIENTÍFICOS NATIVOS
│   ├── root.zig                  <-- Runner central de la CLI (`zig build run`)
│   ├── 01_pendulum.zig           <-- Péndulo no lineal con resistencia cuadrática
│   ├── 03_snell_law.zig          <-- Ley de Snell y fracción 4/3
│   ├── 06_lorenz_sindy.zig       <-- Reconstrucción 3D de atractor de Lorenz
│   ├── 13_elliptic_glv.zig       <-- Curvas elípticas y²=x³+7 y endomorfismo GLV
│   ├── 14_ramanujan_primes.zig   <-- Mock Theta de Ramanujan y distribución de primos
│   └── ...
├── bindings/
│   ├── bun/                      <-- BINDINGS MODULARES TYPESCRIPT (BUN FFI)
│   │   ├── src/                  <-- modular.ts, elliptic.ts, series.ts, engine.ts, etc.
│   │   └── demo/                 <-- 11 demos modulares sincronizadas (`01` a `11`)
│   ├── wasm/                     <-- BINDINGS WEBASSSEMBLY (WASM32-FREESTANDING)
│   │   ├── src/                  <-- modular.ts, elliptic.ts, series.ts, engine.ts, etc.
│   │   ├── demo/                 <-- 11 demos ejecutables en Bun/TS vía WASM
│   │   └── playground/           <-- Aplicación web interactiva (index.html, style.css, app.js)
│   └── python/                   <-- BINDINGS MODULARES PYTHON (CTYPES FFI)
│       ├── ermc/                 <-- modular.py, elliptic.py, series.py, engine.py, etc.
│       └── demo/                 <-- 11 demos modulares sincronizadas en Python
└── scripts/
    └── add_copyright.ts          <-- Script de verificación de copyright
```

---

## ⚡ Inicio Rápido

### Requisitos Previos

- **Zig**: `0.16.0` o superior ([Descargar](https://ziglang.org/download/))
- **Bun** *(para TS y Playground)*: `1.0` o superior ([Instalar Bun](https://bun.sh/))
- **Python** *(opcional para Python FFI)*: `3.8` o superior

---

### Compilación con Zig

```bash
# Compilar biblioteca compartida (ermc.dll / libermc.so) y CLI de ejemplos
zig build

# Compilar con optimizaciones de máxima velocidad
zig build -Doptimize=ReleaseFast

# Compilar binario WebAssembly (zig-out/wasm/ermc.wasm)
zig build wasm
```

---

### Ejecución de Tests y CLI Científica

```bash
# Ejecutar toda la suite de pruebas unitarias e integración en Zig
zig build test

# Ejecutar la suite científica nativa completa (14 demostraciones en < 150 ms)
zig build run
```

---

### Uso con Bun / TypeScript

```bash
# Ejecutar la suite completa de 11 demos modulares en TypeScript
bun run bindings/bun/demo/run_all.ts

# O ejecutar una demo específica (ej. Curvas Elípticas o Ramanujan)
bun run bindings/bun/demo/10_elliptic.ts
bun run bindings/bun/demo/11_series.ts
```

---

### Uso con WebAssembly

```bash
# Compilar WASM si no lo has hecho
zig build wasm

# Ejecutar las 11 demos modulares sobre el motor WASM
bun run bindings/wasm/demo/run_all.ts

# Iniciar el Playground Web interactivo
bun run playground
# Abre http://localhost:3000
```

---

### Uso con Python

```bash
# Ejecutar las 11 demos modulares en Python
python bindings/python/demo/run_all.py

# O ejecutar una demo individual
python bindings/python/demo/09_modular.py
python bindings/python/demo/10_elliptic.py
python bindings/python/demo/11_series.py
```

---

## 🔬 Guía Rápida de Dominios y Ejemplos

### 1. Descubrimiento Simbólico de Ecuaciones (SINDy / STLSQ)

A partir de trayectorias con ruido, deduce la ley física exacta con coeficientes racionales simplificados:

```typescript
import { OmniEngine, Activation } from "ermc";

const engine = new OmniEngine(2); // 2 variables (θ, ω)
engine.buildDictionary([Activation.Identity, Activation.Sin, Activation.Poly]);

// Ajuste sobre trayectorias simuladas
const { weights } = engine.fit(X, y, 0.05);
console.log(engine.getFormula(weights));
// Salida: f(X) = -9.8100*sin(x0) - (1/2)*x1^2
```

---

### 2. Aritmética Modular en $\mathbb{F}_p$

Operaciones sobre campos finitos primos sin desbordamiento:

```typescript
import { getModular } from "ermc";

const mod = getModular();
const P = 1009n;

// Pequeño Teorema de Fermat: a^(p-1) ≡ 1 mod p
const fermat = mod.pow(42n, P - 1n, P); // 1n

// Inverso modular: a * a⁻¹ ≡ 1 mod p
const inv = mod.inverse(42n, P); // 985n

// Raíz cuadrada modular (Tonelli-Shanks)
const root = mod.sqrt(36n, 97n); // 6n (6² mod 97 = 36)
```

---

### 3. Curvas Elípticas $y^2 = x^3 + 7 \pmod p$ & Endomorfismo GLV

Cálculo de leyes de grupo en curvas cortas de Weierstrass (secp256k1 reducida):

```typescript
import { getElliptic, type EcPoint } from "ermc";

const ec = getElliptic();
const P = 1009n;
const G: EcPoint = { x: 1n, y: 131n, isInfinity: false };

// Comprobación sobre la curva
console.log(ec.isOnCurve(G.x, G.y, P)); // true

// Multiplicación escalar k·P
const twoG = ec.scalarMul(2n, G, P);
const threeG = ec.scalarMul(3n, G, P);
const fiveG = ec.scalarMul(5n, G, P);

// Ley de adición asociativa: 2G + 3G == 5G
const sum = ec.add(twoG, threeG, P);
console.log(sum.x === fiveG.x && sum.y === fiveG.y); // true
```

---

### 4. Series Analíticas: Mock Theta de Ramanujan y Primos de Riemann

Evaluación asintótica y comparación con la teoría analítica de números:

```typescript
import { getSeries } from "ermc";

const series = getSeries();

// Mock Theta de Ramanujan vs Modelo Asintótico de Watson
const lnF = series.mockThetaLn(0.05);       // 10.2927
const watson = series.watsonAsymptotic(0.05); // 10.2949 (Error: 0.02%)

// Contador de primos π(x) vs Integral Logarítmica Li(x) de Riemann
const piExact = series.primeCountPi(10000);   // 1229 primos
const liVal = series.logarithmicIntegralLi(10000); // 1261.14 (Error: 2.62%)
```

---

### 5. Espacios de Hilbert y Ortogonalidad MGS-DGKS

Proyección ortogonal estricta en $L^2$ con re-ortogonalización a precisión de máquina:

```typescript
import { HilbertSpace } from "ermc";

const u = [1.0, 2.0, 3.0, 4.0];
const v = [4.0, 3.0, 2.0, 1.0];

const inner = HilbertSpace.inner(u, v); // 20.0
const angle = HilbertSpace.angle(u, v); // 0.841069 rad
```

---

### 6. Detección de Outliers Extremos ($10^{100}$) y Filtro Hampel

Aislamiento de anomalías severas sin desbordamiento:

```typescript
import { Outliers } from "ermc";

const data = [3.14, 3.15, 1e100, 3.145, -1e100, 3.141];
const res = Outliers.detectHampel(data, 3.0);

console.log(res.n_outliers); // 2 outliers identificados
console.log(res.clean_data); // Datos con outliers imputados por la mediana robusta
```

---

### 7. Aritmética Compensada Neumaier

Suma exacta que elimina la pérdida de significancia en punto flotante:

```typescript
import { Precision } from "ermc";

const data = [1e16, 1.0, -1e16];
console.log(Precision.sum(data)); // 1.0 (Exacto, sin cancelación catastrófica)
```

---

### 8. Descomposición en Valores Singulares (SVD)

Descomposición $A = U \Sigma V^T$ mediante rotaciones Jacobi de un solo lado:

```typescript
import { SVD } from "ermc";

const A = [
  1, 2,
  3, 4,
  5, 6
]; // 3x2

const { s } = SVD.compute(A, 3, 2);
console.log(s); // [9.5255, 0.5143]
```

---

### 9. Dynamic Mode Decomposition (DMD)

Extracción de frecuencias puras y modos coherentes en series espacio-temporales:

```typescript
import { DMD } from "ermc";

const dominantFreq = DMD.dominantFrequency(snapshots, nSensors, nSnaps, dt);
console.log(`Frecuencia detectada: ${dominantFreq} rad/s`);
```

---

### 10. Detección de Caos y Exponentes de Lyapunov

Cálculo del efecto mariposa y horizonte de predictibilidad $T_L = 1/\lambda$ en el atractor de Lorenz:

```typescript
import { Chaos } from "ermc";

const res = Chaos.lorenz(1.0, 1.0, 1.0);
console.log(`Exponente de Lyapunov λ: ${res.lyapunov_exponent.toFixed(4)} s⁻¹`);
console.log(`Horizonte de predictibilidad: ${res.lyapunov_time.toFixed(2)} s`);
```

---

### 11. IA de Sucesiones Matemáticas

Predicción exacta del término siguiente a través de tablas de diferencias finitas:

```typescript
import { SequenceAI } from "ermc";

const seq = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121]; // x²
console.log(SequenceAI.predictNext(seq)); // 144.0
```

---

## 🏛️ Estructura del Código y Modularidad

### Módulos en Zig (`src/`)

- [`src/root.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/root.zig): Exporta los submódulos públicos de la biblioteca.
- [`src/engine.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/engine.zig): Fachada principal `OmniEngine` con flujo de regresión esparsa.
- [`src/ffi.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/ffi.zig): Funciones exportadas con convención C (`callconv(.c)`) para interoperabilidad FFI nativa.
- [`src/wasm.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/wasm.zig): Funciones exportadas con asignación lineal para WebAssembly freestanding.
- [`src/modular/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/modular/): Aritmética modular en $\mathbb{F}_p$, inverso euclidiano, Tonelli-Shanks y regresión modular.
- [`src/geometry/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/geometry/): Curvas elípticas $y^2 = x^3 + 7 \pmod p$, adición de grupo, multiplicación escalar y endomorfismo GLV.
- [`src/series/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/series/): Tablas de diferencias finitas y análisis asintótico de Ramanujan/Riemann.
- [`src/core/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/core/): Primitivas numéricas, sumas de Neumaier, RNG y utilidades SIMD.
- [`src/linalg/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/linalg/): Álgebra lineal densa, factorización QR Householder, ortogonalización en espacios de Hilbert y SVD Jacobi.
- [`src/stats/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/stats/): Filtro Hampel robusto a $10^{100}$, estimador de escala MAD y prueba ESD.
- [`src/solver/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/solver/): STLSQ, SINDy para sistemas dinámicos, DMD, integradores RK4 y exponentes de Lyapunov.
- [`src/symbolic/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/symbolic/): Diccionario de funciones no lineales y snapping a fracciones racionales exactas.
- [`src/autodiff/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/autodiff/): Números duales y diferenciación automática forward-mode.

---

## 📚 Documentación Adicional

- **[Guía de Uso Completa (`GUIA_DE_USO.md`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/GUIA_DE_USO.md)**: Manual exhaustivo con explicaciones paso a paso de cada módulo, tablas de la API y ejemplos prácticos.
- **[Playground WebAssembly (`bindings/wasm/playground/`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/bindings/wasm/playground/)**: Entorno interactivo visual para probar en el navegador todas las capacidades matemáticas de ERMC.

---

## 📄 Licencia y Derechos de Autor

**Copyright (c) 2026 Edison Manrique Chocce. Todos los derechos reservados.**

Este proyecto se distribuye bajo un **Modelo de Licencia Dual** diseñado para proteger la autoría intelectual, fomentar la investigación abierta y habilitar la adopción comercial segura:

### 1. Uso Académico, de Investigación y Personal (Open Source)
- Licenciado bajo la **GNU Affero General Public License v3.0 (AGPL-3.0)** (Gratis y de Código Abierto).
- Si utilizas `ERMC` en proyectos académicos, de investigación o software personal, tienes completa libertad de uso, modificación y distribución, siempre que cualquier software derivado o servicio de red (SaaS/Cloud) también sea liberado bajo la misma licencia AGPL-3.0 con su código fuente abierto a la comunidad.

### 2. Uso Comercial y Empresarial (Proprietary / Closed Source)
- **Requiere Licencia Comercial por Separado**.
- Dirigido a empresas, startups u organizaciones que deseen incorporar `ERMC` en aplicaciones cerradas o productos comerciales sin la obligación de liberar su código fuente derivado, o que requieran acuerdos de soporte técnico, garantías y SLA.
- **Contacto comercial y adquisición de licencias:**  
  ✉️ **Email:** `edison.manrique.chocce@gmail.com`

---

## 🛡️ Cláusula de Atribución Obligatoria

Cualquier uso, publicación, cita o trabajo derivado que utilice esta librería **DEBE incluir obligatoriamente**:
1. **Atribución Visible:** Mención clara y destacada a **"Edison Manrique Chocce"**.
2. **Enlace al Repositorio:** Link al proyecto oficial: [`https://github.com/edison-manrique/ermc`](https://github.com/edison-manrique/ermc)  
   SSH: `git@github.com:edison-manrique/ermc.git`
3. **Mención en la Documentación:** Inclusión en la sección de créditos o referencias de la aplicación o paper científico.

Para consultar los términos y condiciones completos, revisa el archivo [LICENSE](./LICENSE).
