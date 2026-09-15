# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/01_hilbert.py — Espacios de Hilbert y Ortogonalidad
Descubre propiedades geométricas de vectores en espacios de dimensión N.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
import sys
sys.path.insert(0, "..")
from ermc import HilbertSpace

print("=" * 60)
print("  ERMC | Demo 01: Espacios de Hilbert y Ortogonalidad")
print("=" * 60)

# --- Experimento 1: Vectores canónicos ---
e1 = [1.0, 0.0, 0.0]
e2 = [0.0, 1.0, 0.0]
print("\n[1] Vectores canonicos ortogonales:")
print(f"  <e1, e2> = {HilbertSpace.inner(e1, e2)}  (esperado: 0.0)")
print(f"  ||e1||   = {HilbertSpace.norm(e1):.6f}  (esperado: 1.0)")
print(f"  Angulo   = {HilbertSpace.angle(e1, e2):.6f} rad  (esperado: pi/2 = {math.pi/2:.6f})")

# --- Experimento 2: Ley del Coseno en R^4 ---
u = [1.0, 2.0, 3.0, 4.0]
v = [4.0, 3.0, 2.0, 1.0]
print("\n[2] Ley del coseno en R^4:")
cos_theta = HilbertSpace.inner(u, v) / (HilbertSpace.norm(u) * HilbertSpace.norm(v))
print(f"  <u,v>    = {HilbertSpace.inner(u, v):.4f}")
print(f"  cos(ang) = {cos_theta:.6f}  (verificado con producto interno)")
print(f"  Angulo   = {HilbertSpace.angle(u, v):.6f} rad")

# --- Experimento 3: Desigualdad de Cauchy-Schwarz ---
print("\n[3] Desigualdad de Cauchy-Schwarz: |<u,v>| <= ||u|| * ||v||")
lhs = abs(HilbertSpace.inner(u, v))
rhs = HilbertSpace.norm(u) * HilbertSpace.norm(v)
print(f"  |<u,v>|      = {lhs:.6f}")
print(f"  ||u|| * ||v||= {rhs:.6f}")
print(f"  Se cumple: {lhs <= rhs + 1e-10}")

# --- Experimento 4: Distancia en espacio de funciones (muestreo) ---
f_sin = [math.sin(2 * math.pi * k / 16) for k in range(16)]
f_cos = [math.cos(2 * math.pi * k / 16) for k in range(16)]
print("\n[4] Distancia L2 entre sin(2*pi*t) y cos(2*pi*t) (16 muestras):")
print(f"  d(sin, cos) = {HilbertSpace.distance(f_sin, f_cos):.6f}")
print(f"  <sin, cos>  = {HilbertSpace.inner(f_sin, f_cos):.6f}  (casi 0 = ortogonales)")

print("\n[OK] Demo 01 completado.\n")
