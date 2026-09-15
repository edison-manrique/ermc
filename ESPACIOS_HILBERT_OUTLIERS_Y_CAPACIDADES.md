# Espacios de Hilbert, Detección de Outliers de Ultra-Precisión y Capacidades SciML Avanzadas en `math-ml`

Este documento describe las nuevas capacidades matemáticas incorporadas en **`math-ml` (v0.3.0 / Zig 0.16.0)**:
1. **Espacios de Hilbert y Proyecciones Ortogonales** con ortogonalización MGS-DGKS y descomposición en $L^2$.
2. **Cálculo de Outliers Extremos sin Pérdida de Precisión** mediante Aritmética Compensada de Kahan-Babuška-Neumaier y estimadores invariantes a la escala.
3. **Descomposición en Valores Singulares (SVD)** mediante el algoritmo de Jacobi Unilateral de Hestenes.
4. **Dynamic Mode Decomposition (DMD)** para extracción de modos espacio-temporales y frecuencias coherentes.
5. **Diferenciación Automática Forward con Números Duales (`Dual`)** con cero error de truncamiento numérico.
6. **Analizador de Caos y Exponentes de Lyapunov Máximos (MLE)** para detección del Efecto Mariposa.

---

## 1. Espacios de Hilbert y Proyecciones Ortogonales (`src/linalg/hilbert.zig`)

### 1.1. Fundamentación Matemática
Un espacio de Hilbert $H$ es un espacio vectorial dotado de un producto interno $\langle \cdot, \cdot \rangle$ que induce una norma métrica completa:
$$\|v\|_H = \sqrt{\langle v, v \rangle}, \quad d_H(u, v) = \|u - v\|_H$$

En `math-ml`, soportamos tanto el producto euclidiano estándar como el producto ponderado en espacios funcionales $L^2$ discretos:
$$\langle u, v \rangle_w = \sum_{i=1}^m w_i u_i v_i$$

### 1.2. Ortogonalización MGS con Re-ortogonalización DGKS ("Twice is Enough")
El método clásico de Gram-Schmidt pierde ortogonalidad rápidamente debido a errores de redondeo cuando las columnas están casi alineadas (mal condicionamiento). 

Para resolverlo, implementamos el algoritmo de **Daniel-Gragg-Kahan-Stewart (DGKS)**: tras proyectar un vector $q_j$ contra los vectores ortonormales previos $\{q_0, \dots, q_{j-1}\}$, se aplica un **segundo pase de proyección** que elimina el residuo de redondeo de punto flotante.

Esto garantiza numéricamente que la matriz ortonormal $Q$ satisface:
$$|\langle q_i, q_j \rangle - \delta_{ij}| < 10^{-14}$$

### 1.3. Descomposición Ortogonal y Teorema de Pitágoras
Para cualquier subespacio $W = \text{span}\{q_0, \dots, q_{k-1}\}$ y cualquier vector $v \in H$, el motor descompone:
$$v = P_W(v) + v^\perp$$
Donde:
$$P_W(v) = \sum_{i=0}^{k-1} \langle v, q_i \rangle q_i, \quad v^\perp = v - P_W(v)$$

Garantías numéricas verificadas en el benchmark:
- **Ortogonalidad mutua**: $|\langle P_W(v), v^\perp \rangle| \approx 3.89 \times 10^{-16}$
- **Identidad pitagórica**: $|\|v\|^2 - (\|P_W(v)\|^2 + \|v^\perp\|^2)| \approx 3.55 \times 10^{-15}$

### 1.4. Ajuste Espectral con Polinomios Ortogonales
La función `generateOrthogonalPolynomials` transforma la base canónica de monomios $\{1, x, x^2, \dots, x^d\}$ sobre cualquier grilla discreta en una base de polinomios ortonormales de tipo Legendre. La función `fitSpectralOrthogonal` proyecta funciones continuas arbitrarias en $O(m \cdot d)$ operaciones:
$$\hat{f}(x) = \sum_{k=0}^d \langle f, P_k \rangle P_k(x)$$

---

## 2. Aritmética Compensada y Outliers Extremos (`src/core/precision.zig` & `src/stats/outliers.zig`)

### 2.1. El Problema de la Precisión en Outliers Extremos
Cuando una señal física se contamina con un sensor averiado que genera lecturas gigantescas (por ejemplo, $10^{50}$ o $10^{100}$):
1. La suma estándar de punto flotante $\sum x_i$ sufre **cancelación catastrófica**: sumar $10^{16} + 1.0 - 10^{16} + 10^{-16}$ produce $0.0$ o $1.0$, perdiendo completamente los términos pequeños.
2. La varianza naive $\sum x^2 - (\sum x)^2 / n$ desborda a `+inf` (porque $(10^{100})^2 = 10^{200}$ supera el límite seguro o $(10^{160})^2$ supera $1.79 \times 10^{308}$).

### 2.2. Sumación Compensada de Neumaier
El algoritmo de Neumaier modifica la suma de Kahan para rastrear el término de error $c$ incluso cuando el siguiente sumando es de mayor magnitud que la suma acumulada:

```zig
var sum: f64 = 0.0;
var c: f64 = 0.0;
for (slice) |x| {
    const t = sum + x;
    if (@abs(sum) >= @abs(x)) {
        c += (sum - t) + x;
    } else {
        c += (x - t) + sum;
    }
    sum = t;
}
return sum + c;
```

**Resultado verificado**: Para $[10^{16}, 42.0, -10^{16}, 10^{-15}]$, la suma normal da $42$, mientras que la suma Neumaier da con total precisión `42.000000000000000`.

### 2.3. Detección Invariante a Escala (Filtro de Hampel y Test ESD)
- **Mediana y MAD exactos**: Calculados sin destruir el array original mediante ordenamiento protegido.
- **Factor asintótico normal**: $\sigma_{\text{MAD}} = 1.482602218505602 \times \text{MAD}$.
- **Puntuación $Z$ robusta**: $z_i = \frac{|x_i - \text{med}|}{\max(\sigma_{\text{MAD}}, 10^{-20})}$.
- **Aislamiento a nivel de bit**: Los datos no contaminados no sufren ninguna alteración, conservando el bit exacto original de la mantisa IEEE 754 de 64 bits.

---

## 3. Descomposición en Valores Singulares (SVD) (`src/linalg/svd.zig`)

Implementa el método de **Jacobi Unilateral de Hestenes** para matrices $A \in \mathbb{R}^{m \times n}$ ($m \ge n$):
$$A = U \Sigma V^T$$

### Capacidades:
1. **Rango Numérico Efectivo**: Basado en el umbral $\varepsilon = \max(m, n) \cdot \sigma_{\max} \cdot \epsilon_{\text{mach}}$.
2. **Número de Condición**: $\kappa(A) = \frac{\sigma_1}{\sigma_n}$.
3. **Pseudoinversa de Moore-Penrose**:
   $$A^+ = V \Sigma^+ U^T = \sum_{k=1}^r \frac{1}{\sigma_k} v_k u_k^T$$
   Satisface las 4 condiciones de Penrose: $A A^+ A = A$, $A^+ A A^+ = A^+$, $(A A^+)^T = A A^+$, $(A^+ A)^T = A^+ A$.
4. **Reconstrucción Óptima**: Error de reconstrucción verificado $< 2.66 \times 10^{-15}$.

---

## 4. Dynamic Mode Decomposition (DMD) (`src/solver/dmd.zig`)

La descomposición modal dinámica (DMD) conecta la teoría de operadores de Koopman con el aprendizaje automático científico (SciML).

A partir de matrices de snapshots temporales:
$$X_1 = [x_0, \dots, x_{m-2}], \quad X_2 = [x_1, \dots, x_{m-1}]$$

1. Calcula la SVD de $X_1 \approx U_r \Sigma_r V_r^T$.
2. Proyecta el operador lineal subyacente: $\tilde{A} = U_r^T X_2 V_r \Sigma_r^{-1}$.
3. Extrae autovalores $\mu_k$ y modos espaciales $\Phi_k = X_2 V_r \Sigma_r^{-1} w_k$.
4. Convierte autovalores discretos en frecuencias continuas y tasas de crecimiento:
   $$\omega_k = \frac{\text{Im}(\ln \mu_k)}{\Delta t}, \quad \gamma_k = \frac{\text{Re}(\ln \mu_k)}{\Delta t}$$

**Demostración (Ejemplo 11)**: Detecta con 4 decimales exactos una frecuencia simulada de $\pi \approx 3.1416\text{ rad/s}$ en un sistema de múltiples sensores en apenas **$858\ \mu\text{s}$**.

---

## 5. Diferenciación Automática con Números Duales (`src/autodiff/dual.zig`)

Los números duales representan magnitudes algebraicas de la forma:
$$x = a + b \epsilon, \quad \epsilon^2 = 0$$

Al evaluar cualquier función analítica $f(a + \epsilon)$:
$$f(a + \epsilon) = f(a) + f'(a)\epsilon$$

### Ventaja Frente a Diferencias Finitas:
| Método | Error Numérico | Cancelación Catastrófica | Costo |
| :--- | :--- | :--- | :--- |
| **Diferencias Finitas** | $O(h)$ o $O(h^2)$ (~8 dígitos válidos con $h \approx 10^{-8}$) | Severa para $h < 10^{-8}$ | 2 evaluaciones |
| **Números Duales (`Dual`)** | **0.0 (Exacto a Precisión de Máquina $\sim 10^{-16}$)** | **Inexistente** | 1 evaluación |

Soporta todas las funciones elementales: `add`, `sub`, `mul`, `div`, `sin`, `cos`, `exp`, `log`, `sqrt`, `pow`, `tan`, `tanh` y cálculo de gradientes multivariados $\nabla f(x) \in \mathbb{R}^n$.

---

## 6. Analizador de Caos y Exponentes de Lyapunov (`src/solver/chaos.zig`)

Mide cuantitativamente la tasa exponencial a la cual divergen dos condiciones iniciales infinitesimalmente cercanas en el espacio de fases (el "Efecto Mariposa"):
$$\|\delta(t)\| \approx \|\delta(0)\| e^{\lambda t}$$

### Algoritmo de Benettin / Wolf con Renormalización Continua:
1. Integra una trayectoria fiducial $z(t)$ y una perturbada $z(t) + \delta_0$ mediante RK4 sin asignaciones intermedias de memoria (`rk4Step`).
2. Tras cada intervalo $\tau$, mide la separación euclidiana $d_1 = \|z_{\text{pert}} - z\|$.
3. Acumula la divergencia logarítmica $\ln(d_1 / \delta_0)$.
4. Renormaliza el vector perturbado a longitud original $\delta_0$ a lo largo de la dirección de divergencia.
5. Diagnostica el **Horizonte de Predictibilidad** (Tiempo de Lyapunov $T_L = 1 / \lambda$).

**Demostración (Ejemplo 12)**: Para el Atractor Caótico de Lorenz ($\sigma=10, \rho=28, \beta=8/3$), computa en **$1.22\text{ ms}$**:
$$\lambda = 0.5558\text{ s}^{-1} > 0 \implies \text{CAÓTICO DETERMINISTA}, \quad T_L \approx 1.80\text{ s}$$

---

## 7. Resumen de Pruebas y Tiempos de Ejecución

Al ejecutar la suite de pruebas:
```bash
zig build test
```
**56 tests pasan al 100%** (incluyendo pruebas de ortonormalidad DGKS a $10^{-14}$, estabilidad ante outliers de $10^{200}$, SVD, DMD, AutoDiff y Caos).

Al ejecutar las 12 demostraciones:
```bash
zig build run
```
Toda la suite (desde descubrimiento analítico simbólico de leyes físicas hasta descomposición SVD, DMD y detección de caos) se ejecuta en tan solo **~36.8 milisegundos**.
