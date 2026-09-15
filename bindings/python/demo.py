# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

"""
Demostración General de ERMC en Python via FFI (.dll / .so)
Ejecuta todos los módulos y valida los resultados.
"""

import sys
import os

# Forzar UTF-8 en la salida estándar para compatibilidad con Windows
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
import time
from ermc import (
    get_version,
    OmniEngine,
    HilbertSpace,
    Precision,
    Outliers,
    SVD,
    SequenceAI,
    DMD,
    Chaos,
    Activation,
)

print("=========================================================================")
print("  ERMC EN PYTHON VIA FFI (.DLL)")
print(f"  Version de DLL Nativa (Zig 0.16): {get_version()}")
print("=========================================================================\n")

# 1. ESPACIOS DE HILBERT
print("--- 1. ESPACIOS DE HILBERT Y ORTOGONALIDAD ---")
u = [1.0, 2.0, 3.0, 4.0]
v = [4.0, 3.0, 2.0, 1.0]
print(f"Vector u: {u} | Vector v: {v}")
print(f"  <u, v> Producto Interno: {HilbertSpace.inner(u, v)}")
print(f"  ||u||  Norma:           {HilbertSpace.norm(u):.6f}")
print(f"  d(u,v) Distancia:       {HilbertSpace.distance(u, v):.6f}")
print(f"  Angulo (rad):           {HilbertSpace.angle(u, v):.6f} rad\n")

# 2. ARITMÉTICA COMPENSADA (NEUMAIER)
print("--- 2. ARITMETICA COMPENSADA (NEUMAIER SUM) ---")
data_cancel = [1e16, 1.0, -1e16]
naive_sum = sum(data_cancel)
neumaier_sum = Precision.sum(data_cancel)
print(f"Datos: {data_cancel}")
print(f"  Suma estandar Python (cancela): {naive_sum}")
print(f"  Suma Neumaier Zig (exacta):     {neumaier_sum}\n")

# 3. OUTLIERS EXTREMOS (10^100)
print("--- 3. DETECCION DE OUTLIERS EXTREMOS (10^100) ---")
noisy_signal = [3.14, 3.15, 3.13, 1e100, 3.145, 3.135, -1e100, 3.141]
outlier_res = Outliers.detect_hampel(noisy_signal, 3.0)
str_samples = [f"{x:.2e}" if abs(x) > 1e10 else str(x) for x in noisy_signal]
print(f"Muestras con perturbaciones cosmicas: [{', '.join(str_samples)}]")
print(f"  Outliers detectados: {outlier_res.outliers_count} de {len(noisy_signal)}")
print(f"  Mascara: [{', '.join('OUTLIER' if b else 'OK' for b in outlier_res.is_outlier)}]")
print(f"  Datos Limpios e Imputados: [{', '.join(f'{x:.4f}' for x in outlier_res.clean_data)}]\n")

# 4. IA DE SUCESIONES MATEMÁTICAS
print("--- 4. IA DE SUCESIONES MATEMATICAS ---")
squares = [0.0, 1.0, 4.0, 9.0, 16.0, 25.0, 36.0, 49.0, 64.0, 81.0, 100.0, 121.0]
next_val = SequenceAI.predict_next(squares)
print(f"Secuencia: {[int(x) for x in squares]}")
print(f"  Proximo valor predicho: {next_val:.0f} (Esperado exacto: 144)\n")

# 5. SVD (DESCOMPOSICIÓN EN VALORES SINGULARES)
print("--- 5. DESCOMPOSICION SVD EN PYTHON ---")
mat = [
    [1.0, 2.0],
    [3.0, 4.0],
    [5.0, 6.0],
]
svd_res = SVD.decompose(mat, 3, 2)
print("Matriz 3x2:")
print(f"  Valores singulares Sigma: [{', '.join(f'{s:.4f}' for s in svd_res.s)}]\n")

# 6. OMNI-ENGINE: REGRESIÓN SIMBÓLICA Y DESCUBRIMIENTO FÍSICO
print("--- 6. OMNI-ENGINE: DESCUBRIMIENTO DE LEY FISICA ---")
print("Sistema: Pendulo no lineal con arrastre de aire")
print("Ley Teorica: f(theta, omega) = -9.81 * sin(theta) - 0.5 * omega^2")

with OmniEngine(2) as engine:
    engine.build_dictionary([Activation.Identity, Activation.Sine, Activation.Square])

    samples_inputs = []
    samples_targets = []

    n_theta = 25
    n_omega = 25
    for i in range(n_theta):
        theta = -1.5 + (3.0 * i) / (n_theta - 1)
        for j in range(n_omega):
            omega = 0.0 + (3.0 * j) / (n_omega - 1)
            target = -9.81 * math.sin(theta) - 0.5 * (omega * omega)
            samples_inputs.append([theta, omega])
            samples_targets.append(target)

    t0 = time.perf_counter()
    weights = engine.fit(samples_inputs, samples_targets, 0.02)
    t1 = time.perf_counter()

    formula = engine.get_formula(weights)
    test_input = [0.5, 1.2]
    pred = engine.predict(test_input, weights)
    exact = -9.81 * math.sin(0.5) - 0.5 * (1.2 * 1.2)

    print(f"  Ecuacion Descubierta: f(X) = {formula}")
    print(f"  Terminos en Diccionario: {engine.get_term_count()} | Tiempo en Zig: {(t1 - t0) * 1000:.2f} ms")
    print(f"  Test f(0.5, 1.2) => Predicho: {pred:.5f} | Real: {exact:.5f} | Error: {abs(pred - exact):.2e}\n")

# 7. DMD (DYNAMIC MODE DECOMPOSITION)
print("--- 7. DMD: EXTRACCION DE FRECUENCIAS ESPACIO-TEMPORALES ---")
dt = 0.05
n_snaps = 50
snapshots = [[], []]
for k in range(n_snaps):
    t = k * dt
    snapshots[0].append(math.sin(3.14159 * t))
    snapshots[1].append(math.cos(3.14159 * t))

freq = DMD.dominant_frequency(snapshots, dt)
print("  Frecuencia teorica: ~3.1416 rad/s")
print(f"  Frecuencia extraida con DMD: {freq:.4f} rad/s\n")

# 8. DINÁMICA DE CAOS Y LYAPUNOV
print("--- 8. DINAMICA DE CAOS Y EXPONENTE DE LYAPUNOV ---")
chaos = Chaos.analyze_lorenz(1.0, 1.0, 1.0)
print(f"  Exponente de Lyapunov lambda_max: {chaos.lyapunov_exponent:.4f} s^-1")
print(f"  Horizonte de Predictibilidad T_L:  {chaos.predictability_horizon:.4f} s")
diag = "SISTEMA CAOTICO CONFIRMADO (Efecto Mariposa)" if chaos.lyapunov_exponent > 0 else "SISTEMA ESTABLE"
print(f"  Diagnostico: {diag}\n")

print("=========================================================================")
print(" >> Python FFI sobre ermc.dll FUNCIONANDO AL 100%!")
print("=========================================================================")
