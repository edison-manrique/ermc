# ERMC ⚡🔬
### Exact Regression Mathematical Core

> **ERMC (Exact Regression Mathematical Core)**: *Regresión exacta + núcleo matemático.*  
> Motor de Inteligencia Artificial Matemática, SciML (Scientific Machine Learning), Descubrimiento Simbólico de Leyes Físicas y Álgebra Numérica de Ultra Precisión.  
> Escrito en **Zig 0.16.0** con cero dependencias externas y bindings modulares en **TypeScript para Bun** vía C-ABI / FFI (`.dll` / `.so`).

[![Zig 0.16.0](https://img.shields.io/badge/Zig-0.16.0-orange.svg?logo=zig)](https://ziglang.org/)
[![Bun](https://img.shields.io/badge/Bun-v1.4.2-black.svg?logo=bun)](https://bun.sh/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue.svg?logo=typescript)](https://www.typescriptlang.org/)
[![Tests](https://img.shields.io/badge/Tests-58%2F58%20Passing-brightgreen.svg)]()
[![License: Dual AGPLv3 / Commercial](https://img.shields.io/badge/License-Dual%20AGPLv3%20%2F%20Commercial-purple.svg)](./LICENSE)
[![Author](https://img.shields.io/badge/Author-Edison%20Manrique%20Chocce-blue.svg)]()
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0-success.svg)]()

---

## 📑 Tabla de Contenidos

1. [¿Qué es `ERMC`?](#-qué-es-ermc)
2. [Capacidades Principales](#-capacidades-principales)
3. [Arquitectura del Proyecto](#-arquitectura-del-proyecto)
4. [Inicio Rápido](#-inicio-rápido)
   - [Compilación con Zig](#compilación-con-zig)
   - [Ejecución de Tests Modulares](#ejecución-de-tests-modulares)
   - [Suite de Ejemplos Científicos](#suite-de-ejemplos-científicos)
   - [Uso con Bun y TypeScript](#uso-con-bun-y-typescript)
5. [Guía Rápida de Uso y Ejemplos](#-guía-rápida-de-uso-y-ejemplos)
   - [1. Descubrimiento Simbólico de Ecuaciones (SINDy / STLSQ)](#1-descubrimiento-simbólico-de-ecuaciones-sindy--stlsq)
   - [2. Espacios de Hilbert y Ortogonalidad MGS-DGKS](#2-espacios-de-hilbert-y-ortogonalidad-mgs-dgks)
   - [3. Detección de Outliers Extremos ($10^{100}$) y Filtro Hampel](#3-detección-de-outliers-extremos-10100-y-filtro-hampel)
   - [4. Aritmética Compensada Neumaier](#4-aritmética-compensada-neumaier)
   - [5. Descomposición en Valores Singulares (SVD)](#5-descomposición-en-valores-singulares-svd)
   - [6. Dynamic Mode Decomposition (DMD)](#6-dynamic-mode-decomposition-dmd)
   - [7. Detección de Caos y Exponentes de Lyapunov](#7-detección-de-caos-y-exponentes-de-lyapunov)
   - [8. IA de Sucesiones Matemáticas](#8-ia-de-sucesiones-matemáticas)
6. [Estructura del Código y Modularidad](#-estructura-del-código-y-modularidad)
7. [Documentación Adicional](#-documentación-adicional)
8. [Licencia y Atribución](#-licencia-y-derechos-de-autor)

---

## 🌟 ¿Qué es `ERMC`?

**ERMC** (**E**xact **R**egression **M**athematical **C**ore) es una biblioteca científica de alto rendimiento diseñada para abordar problemas donde las bibliotecas tradicionales de machine learning fallan: **pérdida de precisión numérica en aritmética de punto flotante**, **caja negra sin interpretabilidad**, **inestabilidad ante perturbaciones extremas** y **sobrecarga de dependencias pesadas**.

Combina técnicas de **Scientific Machine Learning (SciML)** con algoritmos rigurosos de análisis funcional y álgebra lineal numérica:

- **Descubrimiento Simbólico Interpretable**: A partir de nubes de datos o series temporales, deduce la ley física exacta subyacente (fórmulas analíticas como $f(x) = -\frac{9.81}{\sin(x)} - \frac{1}{2}v^2$) usando expansión no lineal y regresión esparsa STLSQ.
- **Álgebra en Espacios de Hilbert**: Proyecciones ortogonales directas $v = P_W(v) + v^\perp$, cálculo de normas, ángulos y re-ortogonalización bi-etapa MGS-DGKS a precisión de máquina ($\sim 10^{-16}$).
- **Inmunidad a Desbordamientos y Outliers Severos**: Filtro Hampel robusto que aísla perturbaciones de magnitud cósmica ($10^{100}$ o $-10^{100}$) sin corromper el cálculo estadístico ni desbordar los acumuladores.
- **Aritmética Compensada Neumaier**: Sumas y promedios que rastrean y corrigen el error de redondeo residual en IEEE 754 de 64 bits.
- **Diagnóstico No Lineal**: SVD por rotaciones Jacobi de un solo lado, extracción modal DMD y cálculo del exponente máximo de Lyapunov para medir caos y horizontes de predictibilidad.
- **Doble Ecosistema**: Úsalo nativamente en **Zig 0.16.0** para rendimiento puro o en **TypeScript (Bun)** mediante una DLL dinámica con una API orientada a objetos moderna y tipada.

---

## 🚀 Capacidades Principales

| Dominio | Algoritmo / Técnica | Precisión / Característica |
| :--- | :--- | :--- |
| **SciML Simbólico** | SINDy / STLSQ + Snapping Racional | Recuperación de coeficientes exactos ($4/3$, $5/3$, $1/2$) |
| **Espacios de Hilbert** | $L^2$ Inner Product, Proyección $P_W$, MGS-DGKS | Ortogonalidad garantizada a $\varepsilon_{\text{mach}} \approx 10^{-16}$ |
| **Estadística Robusta** | Filtro Hampel con MAD Normalizado | Maneja outliers de magnitud $\pm 10^{100}$ sin desbordar |
| **Aritmética Exacta** | Neumaier Compensated Sum & Mean | Cancela el error de redondeo acumulado en `f64` |
| **Álgebra Matricial** | SVD One-Sided Jacobi & Pseudoinversa Moore-Penrose | Cálculo de rango efectivo y número de condición $\kappa(A)$ |
| **Sistemas Dinámicos** | Dynamic Mode Decomposition (DMD) | Identificación de modos espaciales coherentes y frecuencias puras |
| **Teoría del Caos** | Exponente de Lyapunov vía perturbaciones RK4 | Cálculo del tiempo de Lyapunov $T_L = 1/\lambda_{\max}$ |
| **Diferenciación** | AutoDiff Forward-Mode con Números Duales | Gradientes exactos de derivadas parciales sin aproximación |
| **Secuencias** | Diferencias Finitas Polinomiales | Predicción exacta de términos siguientes en series enteras |

---

## 📁 Arquitectura del Proyecto

El repositorio respeta estrictamente los principios de diseño de software modular:
- `src/` contiene **exclusivamente código de la librería**. No contiene `main` ni demos ejecutables.
- `tests/` organiza las pruebas por componente, unificadas por `tests/root.zig`.
- `examples/` alberga 12 aplicaciones científicas del mundo real con su runner `examples/root.zig`.
- `bindings/bun/` ofrece una librería modular en TypeScript con clases especializadas.

```text
ermc/
├── package.json                  <-- Manifiesto raíz npm/bun ("ermc") con scripts y metadatos
├── .gitignore                    <-- Exclusión de caches, builds y artefactos
├── LICENSE                       <-- Licencia Dual (AGPL-3.0 / Comercial) y Atribución
├── README.md                     <-- Documentación principal del proyecto
├── GUIA_DE_USO.md                <-- Manual técnico de uso detallado
├── src/                          <-- CÓDIGO FUENTE PURO DE LA LIBRERÍA
│   ├── root.zig                  <-- Punto de entrada del módulo Zig
│   ├── engine.zig                <-- Fachada principal OmniEngine (SciML)
│   ├── ffi.zig                   <-- Capa de exportación C-ABI (.dll / .so)
│   ├── core/                     <-- SIMD, Aritmética Neumaier, RNG, SafeNorm
│   ├── linalg/                   <-- Matrices, QR, Hilbert (MGS-DGKS), SVD Jacobi
│   ├── stats/                    <-- Filtro Hampel, MAD, Test ESD
│   ├── filter/                   <-- Savitzky-Golay (suavizado y derivadas numéricas)
│   ├── symbolic/                 <-- Diccionario de funciones, Snapping racional
│   ├── solver/                   <-- STLSQ, SINDy, DMD, Integrador RK4, Caos
│   ├── autodiff/                 <-- Números duales, Diferenciación Automática
│   └── series/                   <-- IA de secuencias matemáticas
├── tests/                        <-- SUITE MODULAR DE PRUEBAS (58 tests)
│   ├── root.zig                  <-- Test Runner que agrega todos los submódulos
│   ├── core_test.zig
│   ├── linalg_test.zig
│   ├── stats_test.zig
│   ├── filter_test.zig
│   ├── symbolic_test.zig
│   ├── solver_test.zig
│   ├── autodiff_test.zig
│   └── series_test.zig
├── examples/                     <-- 12 EJEMPLOS CIENTÍFICOS
│   ├── root.zig                  <-- Runner central de ejemplos
│   ├── 01_pendulum.zig           <-- Péndulo no lineal con resistencia cuadrática
│   ├── 02_sensor_decay.zig       <-- Decaimiento exponencial con ruido
│   ├── 03_snell_law.zig          <-- Ley de Snell y fracción 4/3
│   ├── 04_adiabatic.zig          <-- Termodinámica gamma = 5/3
│   ├── 05_torricelli.zig         <-- Vaciado de tanques (raíz cuadrada)
│   ├── 06_lorenz_sindy.zig       <-- Reconstrucción 3D de atractor de Lorenz
│   ├── 07_series_gap.zig         <-- Predicción de sucesiones cuadráticas
│   ├── 08_hilbert_projection.zig <-- Proyección ortogonal y descomposición directa
│   ├── 09_extreme_outliers.zig   <-- Outliers 10^100 con aritmética compensada
│   ├── 10_svd_decomposition.zig  <-- SVD y pseudoinversa de Moore-Penrose
│   ├── 11_dmd_dynamics.zig       <-- Descomposición modal DMD
│   └── 12_chaos_lyapunov.zig     <-- Caos determinista y efecto mariposa
├── bindings/
│   └── bun/                      <-- BINDINGS MODULARES PARA TYPESCRIPT & BUN
│       ├── package.json          <-- Paquete Bun "ermc-bun"
│       ├── demo.ts               <-- Demo integral de los 8 dominios en TS
│       ├── ermc.ts            <-- Re-exportador de retrocompatibilidad
│       └── src/                  <-- Módulos TypeScript desacoplados
│           ├── index.ts          <-- Re-exportador principal
│           ├── types.ts          <-- Enums, Interfaces y Tipos
│           ├── ffi.ts            <-- Carga y Singleton del binario nativo
│           ├── engine.ts         <-- OmniEngine (SciML & Regresión Simbólica)
│           ├── hilbert.ts        <-- HilbertSpace
│           ├── precision.ts      <-- Precision (Neumaier)
│           ├── outliers.ts       <-- Outliers (Hampel Filter)
│           ├── svd.ts            <-- SVD & Inversas
│           ├── sequence.ts       <-- SequenceAI
│           ├── dmd.ts            <-- DMD
│           └── chaos.ts          <-- Chaos & Lyapunov
├── scripts/
│   └── add_copyright.ts          <-- Script de inyección automática de Copyright
├── build.zig                     <-- Script de compilación Zig 0.16.0
└── build.zig.zon                 <-- Metadatos del paquete Zig (.ermc v0.3.0)
```

---

## ⚡ Inicio Rápido

### Requisitos Previos

- **Zig**: `0.16.0` o superior ([Descargar](https://ziglang.org/download/))
- *(Opcional para TS)* **Bun**: `1.0` o superior ([Instalar Bun](https://bun.sh/))

---

### Compilación con Zig

Para compilar la biblioteca nativa compartida (`ermc.dll` / `libermc.so`) y la suite de ejemplos:

```bash
# Compilación estándar (genera binarios en zig-out/bin/)
zig build

# Compilación optimizada para máxima velocidad de producción
zig build -Doptimize=ReleaseFast
```

Los binarios generados se ubicarán en `zig-out/bin/`:
- `zig-out/bin/ermc.dll` (Biblioteca compartida C-ABI para FFI)
- `zig-out/bin/ermc.exe` (Ejecutable de ejemplos)

---

### Ejecución de Tests Modulares

El proyecto cuenta con **58 pruebas unitarias exhaustivas** organizadas de forma modular:

```bash
zig build test
```

Salida esperada:
```text
All 58 tests passed.
```

---

### Suite de Ejemplos Científicos

Ejecuta la suite con los 12 problemas de física, SciML y álgebra:

```bash
zig build run
```

*Ejecuta problemas como el atractor de Lorenz, ley de Snell, péndulos con resistencia cuadrática y análisis de caos en menos de 200 ms.*

---

### Uso con Bun y TypeScript

La carpeta `bindings/bun/` contiene una biblioteca lista para importar directamente en TypeScript:

```bash
cd bindings/bun
bun run demo.ts
```

Salida esperada:
```text
=========================================================================
  ERMC EN BUN + TYPESCRIPT VIA FFI (.DLL)
  Versión de DLL Nativa (Zig 0.16): 0.3.0
=========================================================================

--- 1. ESPACIOS DE HILBERT Y ORTOGONALIDAD ---
Vector u: [1,2,3,4] | Vector v: [4,3,2,1]
  <u, v> Producto Interno: 20
  ||u||  Norma:           5.477226
  d(u,v) Distancia:       4.472136
  Ángulo (rad):           0.841069 rad

--- 2. ARITMÉTICA COMPENSADA (NEUMAIER SUM) ---
Datos: [1e16, 1.0, -1e16]
  Suma estándar JS (cancela): 0
  Suma Neumaier Zig (exacta): 1

--- 3. DETECCIÓN DE OUTLIERS EXTREMOS (10^100) ---
Muestras con perturbaciones cósmicas: [3.14,3.15,3.13,1e+100,3.145,3.135,-1e+100,3.141]
  Outliers detectados: 2 de 8
  Máscara: [OK, OK, OK, OUTLIER, OK, OK, OUTLIER, OK]
  Datos Limpios e Imputados: [3.1400, 3.1500, 3.1300, 3.1405, 3.1450, 3.1350, 3.1405, 3.1410]

--- 4. IA DE SUCESIONES MATEMÁTICAS ---
Secuencia: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121]
  Próximo valor predicho: 144 (Esperado exacto: 144)

--- 5. DESCOMPOSICIÓN SVD EN TYPESCRIPT ---
Matriz 3x2:
  Valores singulares Sigma: [9.5255, 0.5143]

--- 6. OMNI-ENGINE: DESCUBRIMIENTO DE LEY FÍSICA ---
Sistema: Péndulo no lineal con arrastre de aire
Ley Teórica: f(theta, omega) = -9.81 * sin(theta) - 0.5 * omega^2
  Ecuación Descubierta: f(X) = -9.8100*sin(x0) - (1/2)*x1^2
  Términos en Diccionario: 16 | Tiempo en Zig: 6.50 ms
  Test f(0.5, 1.2) => Predicho: -5.42316 | Real: -5.42316 | Error: 0.00e+0

--- 7. DMD: EXTRACCIÓN DE FRECUENCIAS ESPACIO-TEMPORALES ---
  Frecuencia teórica: ~3.1416 rad/s
  Frecuencia extraída con DMD: 3.1416 rad/s

--- 8. DINÁMICA DE CAOS Y EXPONENTE DE LYAPUNOV ---
  Exponente de Lyapunov λ_max: 0.2493 s⁻¹
  Horizonte de Predictibilidad T_L: 4.0110 s
  Diagnóstico: SISTEMA CAÓTICO CONFIRMADO (Efecto Mariposa)

=========================================================================
 >> Bun + TypeScript FFI sobre ermc.dll FUNCIONANDO AL 100%!
=========================================================================
```

---

## 📖 Guía Rápida de Uso y Ejemplos

### 1. Descubrimiento Simbólico de Ecuaciones (SINDy / STLSQ)

Descubre la fórmula analítica exacta a partir de datos experimentales ruidosos:

#### En TypeScript (Bun):
```typescript
import { OmniEngine, Activation } from "./bindings/bun/src";

// Inicializar motor para 2 variables de entrada (ej. ángulo x0 y velocidad angular x1)
const engine = new OmniEngine(2);

// Configurar funciones base candidatas
engine.buildDictionary([
  Activation.Identity,
  Activation.Sine,
  Activation.Square,
  Activation.Cosine,
]);

// Entrenar con muestras (X: matriz plana n x 2, Y: vector de salidas n)
engine.fit(X_flat, Y, {
  lambda: 0.02,
  maxIterations: 10,
  snapThreshold: 0.05,
});

// Obtener la ecuación analítica interpretable descubierta
console.log(engine.getFormula());
// Imprime: "f(X) = -9.8100*sin(x0) - (1/2)*x1^2"

// Realizar predicciones instantáneas
const pred = engine.predict([0.5, 1.2]);

engine.dispose();
```

---

### 2. Espacios de Hilbert y Ortogonalidad MGS-DGKS

Cálculo de productos internos $\langle u, v \rangle = \sum u_i v_i$, normas $\|u\| = \sqrt{\langle u, u \rangle}$, distancias y ángulos en espacios de Hilbert con re-ortogonalización bi-etapa a precisión de máquina:

#### En TypeScript:
```typescript
import { HilbertSpace } from "./bindings/bun/src";

const u = [1, 2, 3, 4];
const v = [4, 3, 2, 1];

const innerProd = HilbertSpace.innerProduct(u, v); // 20.0
const normU     = HilbertSpace.norm(u);             // 5.477226
const dist      = HilbertSpace.distance(u, v);     // 4.472136
const angleRad  = HilbertSpace.angle(u, v);        // 0.841069 rad
```

#### En Zig:
```zig
const ermc = @import("ermc");
const hilbert = ermc.linalg.hilbert;

const u = [_]f64{ 1.0, 2.0, 3.0, 4.0 };
const v = [_]f64{ 4.0, 3.0, 2.0, 1.0 };

const inner = hilbert.innerProduct(&u, &v);
const norm_u = hilbert.norm(&u);
const angle = hilbert.angle(&u, &v);
```

---

### 3. Detección de Outliers Extremos ($10^{100}$) y Filtro Hampel

Elimina perturbaciones gigantescas producidas por errores de telemetría o fallas de sensores sin alterar los datos legítimos ni causar overflow numérico:

```typescript
import { Outliers } from "./bindings/bun/src";

// Serie temporal con ruido severo de 10^100
const samples = [3.14, 3.15, 3.13, 1e100, 3.145, 3.135, -1e100, 3.141];

// Detección con ventana = 2 y umbral k = 3.0
const result = Outliers.hampel(samples, 2, 3.0);

console.log(`Outliers hallados: ${result.numOutliers}`); // 2 de 8
console.log(result.isOutlier); // [false, false, false, true, false, false, true, false]
console.log(result.cleanData); // Los outliers son sustituidos por la mediana local
```

---

### 4. Aritmética Compensada Neumaier

Evita el catastrófico error de cancelación en punto flotante IEEE 754 de 64 bits ($10^{16} + 1.0 - 10^{16}$ produce `0.0` en JavaScript nativo):

```typescript
import { Precision } from "./bindings/bun/src";

const data = [1e16, 1.0, -1e16];

// JavaScript nativo: data.reduce((a, b) => a + b, 0) => 0 ❌ (pérdida total)
const exactSum = Precision.sum(data); 
console.log(exactSum); // => 1.0 ✅ (precisión exacta preservada)

const { mean, variance } = Precision.meanVar(data);
```

---

### 5. Descomposición en Valores Singulares (SVD)

Calcula $A = U \Sigma V^T$ mediante el método One-Sided Jacobi, obteniendo valores singulares y pseudoinversa de Moore-Penrose:

```typescript
import { SVD } from "./bindings/bun/src";

// Matriz 3x2: [[3, 2], [2, 3], [2, -2]]
const matrixFlat = [
  3, 2,
  2, 3,
  2, -2
];

const svd = SVD.decompose(matrixFlat, 3, 2);
console.log("Valores Singulares (Sigma):", svd.singularValues);
// [9.5255, 0.5143]
```

---

### 6. Dynamic Mode Decomposition (DMD)

Separa dinámicas espacio-temporales complejas en modos espaciales coherentes y frecuencias armónicas puras:

```typescript
import { DMD } from "./bindings/bun/src";

// X: instantáneas t=0..N-1, Y: instantáneas t=1..N
const freq = DMD.dominantFrequency(snapshotsX, snapshotsY, rows, cols, dt);
console.log(`Frecuencia descubierta: ${freq} rad/s`);
```

---

### 7. Detección de Caos y Exponentes de Lyapunov

Mide la divergencia exponencial de trayectorias en sistemas no lineales (efecto mariposa) y calcula el horizonte de tiempo antes del cual cualquier predicción diverge:

```typescript
import { Chaos } from "./bindings/bun/src";

const res = Chaos.analyzeLorenz({
  sigma: 10.0,
  rho: 28.0,
  beta: 8.0 / 3.0,
  dt: 0.01,
  steps: 2000,
});

console.log(`Exponente de Lyapunov λ: ${res.lyapunovExponent} s⁻¹`);
console.log(`Horizonte predictivo: ${res.predictabilityHorizon} s`);
console.log(`¿Es caótico?: ${res.isChaotic ? "SÍ" : "NO"}`);
```

---

### 8. IA de Sucesiones Matemáticas

Detecta patrones de recurrencia polinómica y proyecta el valor siguiente sin necesidad de redes neuronales pesadas:

```typescript
import { SequenceAI } from "./bindings/bun/src";

// Sucesión cuadrática: n^2
const serie = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121];

const nextVal = SequenceAI.predictNext(serie, true); // con snap a entero
console.log(`Próximo valor predicho: ${nextVal}`); // 144
```

---

## 🏛️ Estructura del Código y Modularidad

### Módulos en Zig (`src/`)

- [`src/root.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/root.zig): Exporta los submódulos públicos de la biblioteca.
- [`src/engine.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/engine.zig): Fachada principal `OmniEngine` con flujo de regresión esparsa.
- [`src/ffi.zig`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/ffi.zig): Funciones con convención C (`callconv(.c)`) para interoperabilidad externa.
- [`src/core/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/core/): Primitivas de punto flotante, sumas de Neumaier, RNG y utilidades SIMD.
- [`src/linalg/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/linalg/): Álgebra lineal densa, factorización QR Householder, ortogonalización en espacios de Hilbert y SVD Jacobi.
- [`src/stats/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/stats/): Filtro Hampel robusto a $10^{100}$, estimador de escala MAD y prueba ESD.
- [`src/solver/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/solver/): STLSQ, solucionador SINDy para ecuaciones diferenciales, DMD, integradores RK4 y cálculo de exponentes de Lyapunov.
- [`src/symbolic/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/symbolic/): Construcción y evaluación de diccionarios de funciones base y snapping de coeficientes a fracciones racionales exactas.
- [`src/autodiff/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/autodiff/): Números duales y diferenciación automática forward-mode.
- [`src/series/`](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/src/series/): Tablas de diferencias finitas para inferencia de secuencias.

---

## 📚 Documentación Adicional

Para profundizar en el diseño, la teoría matemática o la referencia detallada de la API, consulta los documentos complementarios:

- **[Guía de Uso Completa (`GUIA_DE_USO.md`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/GUIA_DE_USO.md)**: Manual exhaustivo con explicaciones detalladas paso a paso, tablas de la API de TypeScript y ejemplos en Zig.
- **[Arquitectura y Comparativa (`ARQUITECTURA_V6_Y_COMPARATIVA.md`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/ARQUITECTURA_V6_Y_COMPARATIVA.md)**: Comparación entre la versión C original (`omni_core_v6_ultra.c`) y la arquitectura idiomática en Zig 0.16.0.
- **[Espacios de Hilbert y Capacidades Avanzadas (`ESPACIOS_HILBERT_OUTLIERS_Y_CAPACIDADES.md`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/ESPACIOS_HILBERT_OUTLIERS_Y_CAPACIDADES.md)**: Demostraciones matemáticas sobre MGS-DGKS, el filtro Hampel inmune a desbordamientos y el algoritmo SVD Jacobi.
- **[Registro de Mejoras (`MEJORAS_V2.md`)](file:///c:/EMC/GDRIVE/app-center/GITHUB/ermc/MEJORAS_V2.md)**: Bitácora de optimizaciones SIMD, correcciones numéricas y nuevas funcionalidades.

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

### ❌ Prohibiciones Expresas
- ❌ Uso en productos propietarios o servicios cloud cerrados sin una licencia comercial válida.
- ❌ Eliminar, ofuscar o modificar los avisos de copyright o atribución de autoría en el código fuente o en los binarios compilados.
- ❌ Patentar algoritmos, métodos o derivados de esta librería sin autorización previa y por escrito de Edison Manrique Chocce.

Para consultar los términos y condiciones completos, revisa el archivo [LICENSE](./LICENSE).
