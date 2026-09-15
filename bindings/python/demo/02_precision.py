# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/02_precision.py — Aritmética Compensada de Neumaier
Demuestra la superioridad numérica frente a la suma estándar de Python.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import Precision

print("=" * 60)
print("  ERMC | Demo 02: Aritmetica Compensada (Neumaier)")
print("=" * 60)

# --- Experimento 1: Cancelación catastrófica clásica ---
print("\n[1] Cancelacion catastrofica clasica:")
data = [1e16, 1.0, -1e16]
print(f"  Datos: {data}")
print(f"  Python sum(): {sum(data)}   <-- ERROR: devuelve 0.0")
print(f"  Neumaier Zig: {Precision.sum(data)}  <-- CORRECTO: 1.0")

# --- Experimento 2: Suma de serie armónica (1/1 + 1/2 + ... + 1/N) ---
print("\n[2] Serie armonica H_N = sum(1/k, k=1..N):")
N = 10_000
harmonic = [1.0 / k for k in range(1, N + 1)]
py_sum = sum(harmonic)
zig_sum = Precision.sum(harmonic)
# Valor de referencia: digamma(N+1) + gamma_euler
import math
ref = math.log(N) + 0.5772156649015328 + 1 / (2 * N)
print(f"  N = {N}")
print(f"  Python sum():    {py_sum:.10f}")
print(f"  Neumaier Zig:    {zig_sum:.10f}")
print(f"  Ref (log+gamma): {ref:.10f}")
print(f"  Error Python:    {abs(py_sum - ref):.2e}")
print(f"  Error Neumaier:  {abs(zig_sum - ref):.2e}")

# --- Experimento 3: Suma con magnitudes muy distintas ---
print("\n[3] Suma de magnitudes dispares [1e-15, 1e15, 1e-15, -1e15, 2.0]:")
dispares = [1e-15, 1e15, 1e-15, -1e15, 2.0]
print(f"  Python sum(): {sum(dispares)}")
print(f"  Neumaier Zig: {Precision.sum(dispares)}")
print(f"  Esperado:     2.000000000000002")

# --- Experimento 4: Compensación en cálculo de varianza ---
print("\n[4] Suma de cuadrados para varianza (Welford vs naive):")
vals = [1e8 + 1.0, 1e8 + 2.0, 1e8 + 3.0]
mean = 1e8 + 2.0
sq_devs = [(x - mean) ** 2 for x in vals]
print(f"  Suma de (x-mu)^2 por Neumaier: {Precision.sum(sq_devs):.6f}  (esperado: 2.0)")
naive_sq = sum(sq_devs)
print(f"  Suma naive:                    {naive_sq:.6f}")

print("\n[OK] Demo 02 completado.\n")
