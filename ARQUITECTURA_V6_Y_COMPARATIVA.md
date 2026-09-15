# Arquitectura v6 Ultra y Guía Técnica: `math-ml`

Este documento detalla las innovaciones matemáticas y de ingeniería extraídas de **`omni_core_v6_ultra.c`** e incorporadas en la biblioteca modular **`math-ml`** (Zig 0.16.0).

---

## 1. Comparativa Conceptual: Rust v3.5 vs C v6 Ultra vs Zig `math-ml`

| Dimensión | Omni-Core Rust (v3.5) | Omni-Core C (v6 Ultra) | `math-ml` (Zig 0.16.0) |
| :--- | :--- | :--- | :--- |
| **Rastreo de Origen de Nodos** | `Vec<Vec<usize>>` con clonación, ordenamiento y `contains()` | `unsigned long long` bitfield (`1ULL << i`) | Máscaras de bits `u64` nativas ($O(1)$ bitwise) |
| **Filtrado de Outliers** | Desviación estándar y percentil $P_{90}$ | **MAD** (*Median Absolute Deviation*) con corte $4.5 \times \text{MAD}$ | **MAD** exacto ordenado in-place sin fugas |
| **Selección de Hiperparámetros** | Umbral único manual por el usuario | **Búsqueda automática de 18 umbrales con AIC** | **AIC / Navaja de Ockham automático** sobre matriz Gram |
| **Sesgo de Coeficientes** | Posible sesgo por regularización fija | **Re-estimación insesgada** sobre soporte óptimo | **Re-estimación insesgada** con Tikhonov residual $10^{-12}$ |
| **Orden de Operandos** | Permutaciones no restringidas | Orden canónico estricto ($i < first\_operand[j]$) | Orden canónico estricto libre de duplicados conmutativos |
| **Aceleración Hardware** | Escalar / Auto-vectorización LLVM | Escalar optimizado por bucles planos | **Instrucciones SIMD vectorizadas** con `@Vector(4, f64)` |
| **Gestión de Memoria** | RAII dinámico de Rust | `malloc` / `free` manual propenso a errores | **Allocators explícitos** (`ArenaAllocator`, `DebugAllocator`) con cero leaks |

---

## 2. Las 6 Innovaciones Extraídas de `omni_core_v6_ultra.c`

### 2.1. Rastreo de Origen por Máscara de Bits (Bitmask Origin Tracking)
En las versiones iniciales, rastrear si dos términos compartían variables originales requería listas dinámicas:
$$\text{shares\_origin}(A, B) \iff A \cap B \neq \emptyset \quad (O(K))$$
En **v6 Ultra / Zig**:
Cada variable de entrada $i$ recibe un bit único:
$$\text{mask}(x_i) = 1 \ll i$$
Para cualquier término de interacción $T_k = T_i \times T_j$:
1. **Comprobación de disyunción en 1 ciclo de CPU**:
   $$\text{si } (\text{sources}[i] \ \& \ \text{sources}[j]) == 0 \implies \text{son ortogonalmente independientes}$$
2. **Propagación instantánea**:
   $$\text{sources}[k] = \text{sources}[i] \mid \text{sources}[j]$$

### 2.2. Orden Canónico de Operandos (Supresión de Duplicados Conmutativos)
Para términos de nivel 2 (interacción de 3 variables), la multiplicación es conmutativa:
$$(x_0) \cdot (x_1 \cdot x_2) \equiv (x_1) \cdot (x_0 \cdot x_2) \equiv (x_2) \cdot (x_0 \cdot x_1)$$
Si se generan todos, la matriz de diseño se vuelve numéricamente colineal (rango deficiente).
**Solución v6**: Guardar `first_operand[j]` y restringir la combinación únicamente a:
$$i < \text{first\_operand}[j]$$
Esto garantiza que **cada monomio multivariado se genere exactamente una sola vez**.

### 2.3. Filtrado Robusto por MAD (Median Absolute Deviation)
El estimador clásico de desviación estándar ($\sigma$) colapsa ante un solo outlier masivo (resistencia nula / punto de quiebre del 0%).
El **MAD** calcula:
$$\text{MAD} = \text{Mediana}(|y_i - \text{Mediana}(y)|)$$
El corte robusto se establece en:
$$\text{bound} = 4.5 \times \text{MAD}$$
Las muestras que exceden este límite reciben peso $w_s = 0.0$, protegiendo al motor contra sensores quemados o picos espurios.

### 2.4. Selección Automática de Modelo mediante AIC (Navaja de Ockham)
En lugar de forzar al usuario a adivinar el umbral de parsimonia óptimo, el motor evalúa una rejilla de 18 candidatos:
$$\lambda \in [10^{-4}, 0.4]$$
Divide los datos en **Entrenamiento (80%)** y **Validación (20%)** mediante una descomposición sobre la matriz Gram de correlación $G$ y vector $z$:
$$G_{i,j} = \sum_{s} H_{\text{norm}}[s, i] \cdot H_{\text{norm}}[s, j]$$
Para cada umbral $\lambda$, resuelve STLSQ y calcula la pérdida en validación penalizada por complejidad (criterio AIC):
$$\text{Score}(\lambda) = \ln(\text{MSE}_{\text{val}} + 10^{-16}) + \alpha \cdot K_{\text{activo}}$$
Donde $K_{\text{activo}}$ es el número de términos no nulos. El soporte que minimiza esta función es seleccionado automáticamente, hallando la ley física más simple que explica los datos.

### 2.5. Re-estimación Insesgada del Soporte Activo
Cuando STLSQ poda términos, los coeficientes restantes pueden quedar ligeramente sesgados por la regularización.
Al fijar el soporte óptimo descubierto $S^* = \{f \mid w_f \neq 0\}$, el motor resuelve una última ecuación de mínimos cuadrados sobre la matriz Gram total:
$$G_{S^*, S^*} \cdot w_{S^*} = z_{S^*}$$
Esto elimina cualquier atenuación artificial de los parámetros reales.

### 2.6. Catálogo Ampliado de Constantes Físicas
Se incorporó detección de constantes universales exactas:
- $\sigma = 5.67037 \times 10^{-8}$ (Constante de Stefan-Boltzmann)
- $2\pi = 6.283185...$ (Constante de rotación y fase)
- $C_{\text{péndulo}} = \frac{2\pi}{\sqrt{g}} \approx 2.00606668$
- $C_{\text{Torricelli}} = \sqrt{2g} \approx 4.42867926$
- Fracciones periódicas ampliadas hasta denominadores $q \in [2, 8]$ (ej. $3/7, 5/8, 7/8$).

---

## 3. Ejemplo Práctico de Uso en Zig

```zig
const std = @import("std");
const math_ml = @import("math-ml");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Inicializar motor para 2 variables de entrada
    var engine = try math_ml.OmniEngine.init(allocator, 2);
    defer engine.deinit();

    // 2. Compilar diccionario de bases (univariadas e interacciones)
    const bases = [_]math_ml.Activation{ .Identity, .Sine, .Square, .Cube, .ExpNeg };
    try engine.buildExpansionDictionary(&bases);

    // 3. Resolver regresión simbólica (0.0 activa selección automática AIC)
    const weights = try engine.solveAnalytical(dataset, 0.0);
    defer allocator.free(weights);

    // 4. Imprimir fórmula descubierta
    engine.printEquation(weights);
}
```

---

## 4. Banco de Pruebas y Rendimiento

Al compilar en modo optimizado o ejecutar el banco físico:
```bash
zig build run
```
Se obtienen descubrimientos de leyes analíticas completas en menos de **20 milisegundos**:
- **Péndulo amortiguado**: $f(X) = -9.8100 \sin(x_0) - 0.5000 x_1^2$ (~$5.7\text{ ms}$)
- **Sensor con decaimiento ruidoso**: $f(X) = -0.8000 x_0 + 15.0000 + 2.4000 e^{-x_0}$ (~$2.8\text{ ms}$)
- **Ley de Snell**: $n = 1.3333 \sin(x_0)$ (~$0.9\text{ ms}$)
- **Termodinámica adiabática**: $P = 1.6667 x_0 x_1$ (~$1.3\text{ ms}$)
- **Ley de Torricelli**: $v = 4.4287 \sqrt{x_0}$ (~$0.9\text{ ms}$)
- **Atractor de Lorenz 3D**: Reconstrucción exacta de $\dot{x}, \dot{y}, \dot{z}$ (~$4.6\text{ ms}$)
- **IA de Sucesiones**: Predicción de saltos cuadráticos en ~$67\ \mu\text{s}$.
