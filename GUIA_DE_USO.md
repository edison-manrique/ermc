# Guía de Uso Completa: ERMC (Exact Regression Mathematical Core)

**ERMC**: *Regresión exacta + núcleo matemático.*  
Motor de Inteligencia Artificial Matemática, SciML (Scientific Machine Learning), Espacios de Hilbert, Descomposición SVD/DMD, Detección de Caos y Aritmética Compensada de Ultra Precisión.

---

## Índice

1. [Arquitectura Modular del Proyecto](#1-arquitectura-modular-del-proyecto)
2. [Compilación de la Biblioteca y de la DLL](#2-compilación-de-la-biblioteca-y-de-la-dll)
3. [Ejecución de Tests Unitarios Modulares](#3-ejecución-de-tests-unitarios-modulares)
4. [Ejecución de los Ejemplos Modulares](#4-ejecución-de-los-ejemplos-modulares)
5. [Uso Nativo en Proyectos Zig](#5-uso-nativo-en-proyectos-zig)
6. [Librería TypeScript en Bun (FFI Nativo)](#6-librería-typescript-en-bun-ffi-nativo)
7. [Referencia de la API en TypeScript](#7-referencia-de-la-api-en-typescript)
8. [Extensión y Adición de Nuevas Funciones al C-ABI](#8-extensión-y-adición-de-nuevas-funciones-al-c-abi)

---

## 1. Arquitectura Modular del Proyecto

El proyecto sigue una separación estricta de responsabilidades:
- **`src/`**: Contiene **exclusivamente código de la librería**. No hay lógica ejecutable, ejemplos ni puntos de entrada demo.
- **`tests/`**: Suites de pruebas unitarias divididas por módulo con un agregador maestro `tests/root.zig`.
- **`examples/`**: 12 aplicaciones científicas independientes con su propio runner central `examples/root.zig`.
- **`bindings/bun/`**: Bindings en TypeScript listos para usar en Bun mediante FFI directo a la `.dll`.

```
ermc/
├── package.json                  <-- Manifiesto raíz npm/bun
├── .gitignore                    <-- Exclusiones de Git
├── LICENSE                       <-- Licencia Dual (AGPL-3.0 / Comercial) y Atribución
├── README.md                     <-- Documentación principal
├── GUIA_DE_USO.md                <-- Manual de usuario técnico
├── src/                          <-- CÓDIGO EXCLUSIVO DE LA LIBRERÍA
│   ├── root.zig                  <-- Punto de entrada del módulo Zig (re-exporta submódulos)
│   ├── engine.zig                <-- Fachada de alto nivel OmniEngine
│   ├── ffi.zig                   <-- Capa de exportación C-ABI para .DLL / .SO
│   ├── core/                     <-- Tipos, SIMD, RNG, Aritmética Compensada (Neumaier)
│   ├── linalg/                   <-- Matrices, QR, Espacios de Hilbert (MGS-DGKS), SVD
│   ├── stats/                    <-- Filtro Hampel ($10^100$ outliers), Test ESD
│   ├── filter/                   <-- Filtro Savitzky-Golay (derivadas numéricas)
│   ├── symbolic/                 <-- Diccionario simbólico, Snapping, Formatter
│   ├── solver/                   <-- Gauss-Jordan, STLSQ, SINDy, DMD, Integrador RK4, Caos
│   ├── autodiff/                 <-- Números duales, Diferenciación Automática hacia adelante
│   └── series/                   <-- IA de sucesiones matemáticas y gaps
├── tests/                        <-- TESTS MODULARES
│   ├── root.zig                  <-- Test Runner maestro (importa todos los tests)
│   ├── core_test.zig             <-- SIMD, RNG, Neumaier, SafeNorm
│   ├── linalg_test.zig           <-- Matrices, QR, Hilbert, SVD, Jacobi
│   ├── stats_test.zig            <-- Outliers Hampel, Test ESD
│   ├── filter_test.zig           <-- Filtro Savitzky-Golay
│   ├── symbolic_test.zig         <-- Diccionario, Snapping, Activaciones
│   ├── solver_test.zig           <-- STLSQ, Métricas R², RK4, DMD, Caos
│   ├── autodiff_test.zig         <-- Números duales, Gradiente Rosenbrock
│   └── series_test.zig           <-- Secuencias polinómicas y gaps
├── examples/                     <-- EJEMPLOS CIENTÍFICOS MODULARES
│   ├── root.zig                  <-- Runner central de todos los ejemplos
│   ├── 01_pendulum.zig           <-- Péndulo no lineal con arrastre cuadrático
│   ├── 02_sensor_decay.zig       <-- Sensor con decaimiento y ruido Gaussiano
│   ├── 03_snell_law.zig          <-- Ley de Snell y fracciones exactas
│   ├── 04_adiabatic.zig          <-- Termodinámica adiabática gamma = 5/3
│   ├── 05_torricelli.zig         <-- Hidrodinámica: vaciado de tanques
│   ├── 06_lorenz_sindy.zig       <-- Identificación de ODEs de Lorenz
│   ├── 07_series_gap.zig         <-- Predicción de sucesiones cuadráticas
│   ├── 08_hilbert_projection.zig <-- Proyección y ortogonalización MGS-DGKS
│   ├── 09_extreme_outliers.zig   <-- Outliers de 10^100 con aritmética compensada
│   ├── 10_svd_decomposition.zig  <-- SVD One-sided Jacobi y pseudoinversa
│   ├── 11_dmd_dynamics.zig       <-- Extracción de frecuencias puras con DMD
│   └── 12_chaos_lyapunov.zig     <-- Exponente de Lyapunov y horizonte de tiempo
├── bindings/
│   └── bun/                      <-- LIBRERÍA MODULAR DE TYPESCRIPT PARA BUN
│       ├── ermc.ts            <-- Re-exportador para compatibilidad directa
│       ├── demo.ts               <-- Demo interactivo en Bun
│       ├── package.json          <-- Configuración de paquete Bun
│       └── src/                  <-- MÓDULOS INDEPENDIENTES TS
│           ├── index.ts          <-- Barrel export principal
│           ├── types.ts          <-- Tipos e interfaces
│           ├── ffi.ts            <-- Carga y singleton de símbolos FFI
│           ├── engine.ts         <-- OmniEngine SciML
│           ├── hilbert.ts        <-- Espacios de Hilbert
│           ├── precision.ts      <-- Aritmética compensada Neumaier
│           ├── outliers.ts       <-- Filtro de outliers Hampel
│           ├── svd.ts            <-- Descomposición SVD
│           ├── sequence.ts       <-- IA de secuencias matemáticas
│           ├── dmd.ts            <-- Dynamic Mode Decomposition
│           └── chaos.ts          <-- Lyapunov y análisis de caos
├── build.zig                     <-- Orquestador de compilación de Zig 0.16.0
└── build.zig.zon                 <-- Manifiesto de paquetes de Zig
```

---

## 2. Compilación de la Biblioteca y de la DLL

El archivo [build.zig](./build.zig) compila simultáneamente tanto el ejecutable de ejemplos como la biblioteca compartida dinámica:

### Comando de Compilación:
```bash
zig build
```

### Artefactos Generados en `zig-out/bin/`:
- **`ermc.dll`** (Windows) / **`libermc.so`** (Linux): Biblioteca compartida C-ABI con exportación de todas las primitivas matemáticas y de machine learning.
- **`ermc.exe`**: Binario ejecutable que corre la suite modular de ejemplos científicos.

Para compilar en modo optimizado de alto rendimiento:
```bash
zig build -Doptimize=ReleaseFast
```

---

## 3. Ejecución de Tests Unitarios Modulares

Todos los tests unitarios están segregados por dominio y agregados en [tests/root.zig](./tests/root.zig).

### Ejecutar la suite completa:
```bash
zig build test
```

### Ver el desglose detallado de todos los tests (58 tests passing):
```bash
zig build test --summary all
```

Para correr una suite específica directamente:
```bash
zig test tests/linalg_test.zig
zig test tests/stats_test.zig
zig test tests/solver_test.zig
```

---

## 4. Ejecución de los Ejemplos Modulares

Los 14 ejemplos científicos se ejecutan mediante el runner modular [examples/root.zig](./examples/root.zig):

```bash
zig build run
```

Cada ejemplo es un archivo independiente que puede ser invocado o estudiado por separado:
- `examples/01_pendulum.zig`
- `examples/06_lorenz_sindy.zig`
- `examples/08_hilbert_projection.zig`
- `examples/09_extreme_outliers.zig`
- `examples/10_svd_decomposition.zig`
- `examples/11_dmd_dynamics.zig`
- `examples/12_chaos_lyapunov.zig`

---

## 5. Uso Nativo en Proyectos Zig

En tu propio archivo `main.zig` o módulo Zig, simplemente importa el módulo `ermc`:

```zig
const std = @import("std");
const ermc = @import("ermc");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 1. Espacios de Hilbert
    const u = [_]f64{ 1.0, 2.0, 3.0 };
    const v = [_]f64{ 4.0, 5.0, 6.0 };
    const inner_prod = ermc.linalg.inner(&u, &v);
    const norm_u = ermc.linalg.norm(&u);
    std.debug.print("Producto interno: {d}, Norma: {d}\n", .{ inner_prod, norm_u });

    // 2. Detección de Outliers Extremos
    const signal = [_]f64{ 1.0, 1.05, 0.98, 1e100, 1.02 };
    var detector = try ermc.stats.detectOutliersHampel(allocator, &signal, 3.0);
    defer detector.deinit();
    std.debug.print("Outliers detectados: {d}\n", .{ detector.n_outliers });

    // 3. OmniEngine: Descubrimiento Simbólico
    var engine = try ermc.OmniEngine.init(allocator, 2);
    defer engine.deinit();
    const acts = [_]ermc.Activation{ .Identity, .Sine, .Square };
    try engine.buildExpansionDictionary(&acts);
}
```

---

## 6. Librería TypeScript en Bun (FFI Nativo)

La librería incluye bindings completos para TypeScript en [bindings/bun/](./bindings/bun/). Carga directamente `ermc.dll` usando `bun:ffi` con **cero costo de serialización**.

### Requisitos:
1. Tener [Bun](https://bun.sh/) instalado (`bun --version`).
2. Haber compilado la DLL con `zig build`.

### Probar el Demo en Bun:
```bash
bun run bindings/bun/demo.ts
```

Salida esperada:
```
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
Muestras con perturbaciones cósmicas: [3.14, 3.15, 3.13, 1e+100, 3.145, 3.135, -1e+100, 3.141]
  Outliers detectados: 2 de 8
  Máscara: [OK, OK, OK, OUTLIER, OK, OK, OUTLIER, OK]
  Datos Limpios e Imputados: [3.1400, 3.1500, 3.1300, 3.1405, 3.1450, 3.1350, 3.1405, 3.1410]

--- 4. IA DE SUCESIONES MATEMÁTICAS ---
Secuencia: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121]
  Próximo valor predicho: 144.00 (Esperado exacto: 144)

--- 5. DESCOMPOSICIÓN SVD EN TYPESCRIPT ---
Matriz 3x2:
  Valores singulares Sigma: [9.5255, 0.5143]

--- 6. OMNI-ENGINE: DESCUBRIMIENTO DE LEY FÍSICA ---
  Ecuación Descubierta: f(X) = -9.8100*sin(x0) - 0.5000*x1^2
  Tiempo de optimización en Zig: 58.20 ms

--- 7. DMD: EXTRACCIÓN DE FRECUENCIAS ESPACIO-TEMPORALES ---
  Frecuencia teórica: ~3.1416 rad/s
  Frecuencia extraída con DMD: 3.1416 rad/s

--- 8. DINÁMICA DE CAOS Y EXPONENTE DE LYAPUNOV ---
  Exponente de Lyapunov λ_max: 0.2493 s⁻¹
  Horizonte de Predictibilidad T_L: 4.0110 s
  Diagnóstico: SISTEMA CAÓTICO CONFIRMADO (Efecto Mariposa)
```

---

## 7. Referencia de la API en TypeScript

### 7.1. `OmniEngine` (Descubrimiento Simbólico de Ecuaciones)
Descubre la ley matemática $y = f(x_0, x_1, \dots)$ detrás de una nube de datos:

```typescript
import { OmniEngine, Activation } from "./bindings/bun/src";

// 1. Crear motor para 2 entradas (ej. ángulo y velocidad angular)
const engine = new OmniEngine(2);

// 2. Configurar diccionario topológico modular (opcional)
engine.buildDictionary([Activation.Identity, Activation.Sine, Activation.Square]);

// 3. Definir dataset 2D no-colineal (muestreo en grid o aleatorio)
const inputs: number[][] = [];
const targets: number[] = [];
for (let i = 0; i < 20; i++) {
  const theta = -1.5 + (3.0 * i) / 19.0;
  for (let j = 0; j < 20; j++) {
    const omega = 0.0 + (3.0 * j) / 19.0;
    inputs.push([theta, omega]);
    targets.push(-9.81 * Math.sin(theta) - 0.5 * omega * omega);
  }
}

// 4. Ajustar modelo analítico con parsimonia L0
const weights = engine.fit(inputs, targets, 0.02);

// 5. Obtener la fórmula como string legible
const formula = engine.getFormula(weights);
console.log("Fórmula descubierta:", formula); 
// Imprime exactamente: -9.8100*sin(x0) - (1/2)*x1^2

// 6. Predecir un nuevo estado
const pred = engine.predict([0.5, 1.2], weights);

// 7. Liberar memoria nativa
engine.dispose();
```

---

### 7.2. `HilbertSpace` (Geometría en Espacios Funcionales)
Cálculo riguroso de productos internos, normas y ortogonalidad:

```typescript
import { HilbertSpace } from "./bindings/bun/src";

const u = [1.0, 2.0, 3.0, 4.0];
const v = [4.0, 3.0, 2.0, 1.0];

const innerProd = HilbertSpace.inner(u, v);    // <u, v> = 20
const norm = HilbertSpace.norm(u);             // ||u|| = 5.477
const dist = HilbertSpace.distance(u, v);      // d(u, v) = 4.472
const angleRad = HilbertSpace.angle(u, v);     // Ángulo entre vectores
```

---

### 7.3. `Precision` (Aritmética Compensada Neumaier)
Previene cancelaciones catastróficas en punto flotante de 64 bits:

```typescript
import { Precision } from "./bindings/bun/src";

// En JavaScript vanilla: (1e16 + 1.0) - 1e16 devuelve 0 (se perdió el 1.0)
const data = [1e16, 1.0, -1e16];

const exactSum = Precision.sum(data);
console.log(exactSum); // 1.0 (Exacto, cero pérdida de precisión)

const { mean, variance } = Precision.meanVar(data);
```

---

### 7.4. `Outliers` (Hampel de Ultra Robustez)
Detecta picos espurios extremos (incluso $10^{100}$) sin desbordar:

```typescript
import { Outliers } from "./bindings/bun/src";

const signal = [3.14, 3.15, 1e100, 3.145, -1e100, 3.141];
const result = Outliers.detectHampel(signal, 3.0);

console.log("Outliers encontrados:", result.outliersCount); // 2
console.log("Máscara booleana:", result.isOutlier);
console.log("Datos limpios e imputados:", result.cleanData);
```

---

### 7.5. `SVD` (Descomposición en Valores Singulares)
Factorización de matrices $A = U \Sigma V^T$ mediante el algoritmo One-Sided Jacobi:

```typescript
import { SVD } from "./bindings/bun/src";

const mat = [
  [1.0, 2.0],
  [3.0, 4.0],
  [5.0, 6.0],
];
const { u, s, v } = SVD.decompose(mat, 3, 2);

console.log("Valores singulares Sigma:", s); // [9.5255, 0.5143]
```

---

### 7.6. `SequenceAI` (Predicción de Sucesiones Numéricas)
Descubre el término siguiente de patrones matemáticos polinómicos:

```typescript
import { SequenceAI } from "./bindings/bun/src";

const squares = [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121];
const nextVal = SequenceAI.predictNext(squares);
console.log("Próximo valor predicho:", nextVal); // 144
```

---

### 7.7. `DMD` (Dynamic Mode Decomposition)
Extrae frecuencias espaciotemporales dominantes de señales multicanal:

```typescript
import { DMD } from "./bindings/bun/src";

// Matriz de snapshots (sensores x tiempo)
const dt = 0.05;
const snapshots = [
  [/* sensor 1 en t0, t1, t2... */],
  [/* sensor 2 en t0, t1, t2... */],
];

const dominantFreq = DMD.dominantFrequency(snapshots, dt);
console.log("Frecuencia angular dominante (rad/s):", dominantFreq);
```

---

### 7.8. `Chaos` (Exponente de Lyapunov y Predictibilidad)
Evalúa el Atractor de Lorenz y determina el tiempo de predictibilidad:

```typescript
import { Chaos } from "./bindings/bun/src";

const { lyapunovExponent, predictabilityHorizon } = Chaos.analyzeLorenz(1.0, 1.0, 1.0);
console.log("Exponente de Lyapunov Máximo:", lyapunovExponent); // > 0 indica caos
console.log("Horizonte de Predictibilidad (s):", predictabilityHorizon);
```

---

## 8. Extensión y Adición de Nuevas Funciones al C-ABI

Para exponer una nueva función matemática de Zig hacia Bun TypeScript:

1. **Implementa la lógica en su submódulo correspondiente** dentro de `src/` (ej. `src/linalg/`, `src/stats/`, etc.).
2. **Re-exporta la función con `export fn ... callconv(.c)` en [src/ffi.zig](./src/ffi.zig)** usando punteros C estándar (`[*]const f64`, `[*]f64`, `usize`, etc.).
3. **Recompila la DLL** ejecutando:
   ```bash
   zig build
   ```
4. **Registra el símbolo FFI en [bindings/bun/src/ffi.ts](./bindings/bun/src/ffi.ts)** dentro de `loadNativeSymbols`, indicando `args` y `returns` con `FFIType`.
5. **Crea un módulo TypeScript nuevo** en `bindings/bun/src/` (ej. `mi_modulo.ts`) con la clase wrapper que use `Float64Array`, `ptr()` y `getNativeLib()`.
6. **Re-exporta desde [bindings/bun/src/index.ts](./bindings/bun/src/index.ts)** añadiendo `export * from "./mi_modulo";`.

### Estructura modular de los bindings TypeScript:

```
bindings/bun/
├── ermc.ts              ← Re-exportación retrocompatible
├── demo.ts                 ← Demo interactivo
├── package.json
└── src/                    ← Módulos individuales
    ├── index.ts            ← Barrel export central
    ├── types.ts            ← Interfaces y enums (Activation, etc.)
    ├── ffi.ts              ← Loader de la DLL y definición de símbolos
    ├── engine.ts           ← OmniEngine (regresión simbólica)
    ├── hilbert.ts          ← HilbertSpace (espacios funcionales)
    ├── precision.ts        ← Precision (aritmética Neumaier)
    ├── outliers.ts         ← Outliers (filtro Hampel)
    ├── svd.ts              ← SVD (Jacobi)
    ├── sequence.ts         ← SequenceAI (sucesiones)
    ├── dmd.ts              ← DMD (modos dinámicos)
    └── chaos.ts            ← Chaos (Lyapunov)
```

---

## 9. WebAssembly (WASM) para Navegadores y Runtimes JS

ERMC se compila nativamente como módulo WebAssembly independiente (`wasm32-freestanding`) en modo ultra-optimizado (`ReleaseFast`), sin dependencias de sistema operativo:

### 9.1. Compilación del binario WASM:
```bash
zig build wasm
```
Genera el artefacto: `zig-out/wasm/ermc.wasm`

### 9.2. Estructura de los Bindings WASM:
```
bindings/wasm/
├── ermc_wasm.ts         ← Loader WebAssembly con gestión de memoria y wrappers
├── index.ts             ← Re-exportador central
├── package.json         ← Configuración de paquete @ermc/wasm
└── demo/                ← Suite de 8 demostraciones modulares sincronizadas
    ├── 01_hilbert.ts
    ├── 02_precision.ts
    ├── 03_outliers.ts
    ├── 04_sequence.ts
    ├── 05_svd.ts
    ├── 06_engine.ts
    ├── 07_dmd.ts
    ├── 08_chaos.ts
    └── run_all.ts
```

### 9.3. Ejecutar las Demos WASM con Bun:
```bash
cd bindings/wasm
bun run demo/run_all.ts
```

### 9.4. Uso en Código TypeScript / Navegador:
```typescript
import { loadErmc, OmniEngine, Activation, HilbertSpace } from "./bindings/wasm";

// Inicializar el módulo WebAssembly
await loadErmc();

// Usar cualquier módulo ERMC
const e1 = [1, 0, 0], e2 = [0, 1, 0];
console.log("Ortogonalidad:", HilbertSpace.inner(e1, e2)); // 0.0

const engine = new OmniEngine(2);
engine.buildDictionary([Activation.Identity, Activation.Sine, Activation.Square]);
const weights = engine.fit(inputs, targets, 0.02);
console.log("Ecuación física descubierta:", engine.getFormula(weights));
engine.dispose();
```

