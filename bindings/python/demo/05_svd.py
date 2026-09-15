# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/05_svd.py — Descomposición en Valores Singulares (SVD)
Analiza rango efectivo, compresión de datos y reducción de ruido.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
sys.path.insert(0, "..")
from ermc import SVD

print("=" * 60)
print("  ERMC | Demo 05: SVD - Descomposicion en Valores Singulares")
print("=" * 60)

# --- Experimento 1: Rango efectivo de una matriz ---
print("\n[1] Rango efectivo de matrices:")
matrices = [
    ("Rango 2 (3x3 con fila dep.)",
     [[1, 2, 3], [4, 5, 6], [7, 10, 13]],  # fila3 = fila1 + fila2 + ajuste
     3, 3),
    ("Identidad 3x3",
     [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
     3, 3),
    ("Matriz de datos 4x2",
     [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [7.0, 8.0]],
     4, 2),
]

for name, mat, rows, cols in matrices:
    mat_f = [[float(x) for x in row] for row in mat]
    res = SVD.decompose(mat_f, rows, cols)
    threshold = 1e-10
    effective_rank = sum(1 for s in res.s if s > threshold)
    print(f"\n  {name}:")
    print(f"    Sigma: [{', '.join(f'{s:.4f}' for s in res.s)}]")
    print(f"    Rango efectivo: {effective_rank}")

# --- Experimento 2: Energía capturada por componentes principales ---
print("\n\n[2] Energia capturada por valores singulares:")
mat = [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]]
res = SVD.decompose(mat, 3, 2)
total_energy = sum(s**2 for s in res.s)
cumulative = 0.0
for i, s in enumerate(res.s):
    cumulative += s**2
    pct = 100 * cumulative / total_energy if total_energy > 0 else 0
    print(f"    Componente {i+1}: sigma={s:.4f}  energia acumulada={pct:.2f}%")

# --- Experimento 3: Matriz de correlación 3x3 ---
print("\n[3] Analisis SVD de matriz de correlacion (PCA dummy):")
corr = [
    [1.0,  0.9, -0.3],
    [0.9,  1.0, -0.2],
    [-0.3, -0.2, 1.0],
]
res2 = SVD.decompose(corr, 3, 3)
print(f"  Sigma: [{', '.join(f'{s:.4f}' for s in res2.s)}]")
print(f"  Varianza explicada por 1er componente: {res2.s[0]**2 / sum(s**2 for s in res2.s) * 100:.1f}%")

print("\n[OK] Demo 05 completado.\n")
