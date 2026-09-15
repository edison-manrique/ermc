# ERMC ⚡ WebAssembly Playground

> Aplicación web interactiva para experimentación científica, descubrimiento de leyes físicas, curvas elípticas y aritmética modular directamente en el navegador mediante WebAssembly.

---

## 🚀 Inicio Rápido

Para iniciar el servidor local ultrarrápido con Bun:

```bash
# Desde la raíz del repositorio:
bun run playground

# O directamente desde esta carpeta:
bun run serve.ts
```

Abre en tu navegador: **`http://localhost:3000`**

---

## 🔬 Módulos Disponibles en el Playground

1. **🔬 OmniEngine (Descubrimiento Simbólico SciML)**:
   - Deducción analítica de leyes físicas a partir de datos sintéticos o con ruido gaussiano.
   - Presets incluidos: Péndulo no lineal con resistencia cuadrática, Ley de Snell (óptica), ley adiabática de gases monoatómicos ($\gamma = 5/3$), Ley de Torricelli y oscilador amortiguado de Hooke.
   - Visualizador gráfico en Canvas comparando datos reales contra el modelo descubierto.

2. **🔢 Aritmética Modular en $\mathbb{F}_p$**:
   - Operaciones sobre campos finitos primos en enteros de 64 bits sin signo (`u64`).
   - Suma, resta, multiplicación, potencias modulares $a^e \pmod p$.
   - Inverso modular con el Algoritmo Extendido de Euclides $a^{-1} \pmod p$.
   - Raíces cuadradas modulares $\sqrt{a} \pmod p$ con el algoritmo de Tonelli-Shanks.
   - Verificación instantánea del Pequeño Teorema de Fermat ($a^{p-1} \equiv 1 \pmod p$).

3. **⚡ Curvas Elípticas & Endomorfismo GLV**:
   - Curva corta de Weierstrass $y^2 = x^3 + 7 \pmod p$ (secp256k1 reducida).
   - Búsqueda automática de puntos generadores $G = (x, y)$.
   - Retículo gráfico interactivo de puntos en el toro discreto $\mathbb{F}_p \times \mathbb{F}_p$.
   - Multiplicación escalar $k \cdot P$ mediante *Double-and-Add*.
   - Comprobación de la ley de grupo asociativa ($2P + 3P = 5P$).
   - Endomorfismo GLV $\phi(P) = (\beta x, y)$ con $\beta^3 \equiv 1 \pmod p$.

4. **🌌 Ramanujan Mock Theta & Primos de Riemann**:
   - Función Mock Theta $f(q)$ de orden 3 evaluada en espacio logarítmico $\ln|f(-e^{-t})|$.
   - Convergencia hacia la asintótica de Watson: $\frac{\pi^2}{24t} - \frac{1}{2}\ln(t) + \frac{1}{2}\ln(\pi)$ (error $< 0.01\%$).
   - Conteo exacto de primos $\pi(x)$ (Criba de Eratóstenes) vs Integral Logarítmica $\text{Li}(x)$ de Riemann.

5. **📐 Espacios de Hilbert $L^2$ & Descomposición SVD**:
   - Producto interno $\langle u, v \rangle$, normas $\|u\|_H, \|v\|_H$, ángulo en radianes/grados y verificación de la desigualdad de Cauchy-Schwarz.
   - Descomposición SVD Jacobi: $A = U \Sigma V^T$, gráfico de barras del espectro de valores singulares, rango numérico efectivo y número de condición $\kappa(A)$.

6. **🛡️ Filtro Hampel & Aritmética Compensada Neumaier**:
   - Demostración de inmunidad ante perturbaciones astronómicas ($\pm 10^{100}$) sin desbordamiento.
   - Comparación de la media estándar desbordada contra la estimación robusta de ERMC.
   - Suma compensada de Neumaier garantizando retención total de precisión a 64 bits.

---

## 🛠️ Tecnologías Empleadas

- **Zig 0.16.0**: Compilado a `wasm32-freestanding` en modo `ReleaseFast`.
- **HTML5 & Vanilla CSS3**: Modo oscuro Obsidian con estética glassmorphic, tipografías Outfit, Inter y JetBrains Mono.
- **JavaScript Moderno (ES Modules)**: Sin frameworks pesados ni dependencias de compilación en el frontend.
- **HTML5 Canvas 2D**: Gráficos interactivos de curvas y retículos discretos.
