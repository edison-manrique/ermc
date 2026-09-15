# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/04_sequence.py — IA de Sucesiones Matemáticas
Descubre el siguiente término en secuencias numéricas clásicas y novedosas.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import SequenceAI

print("=" * 60)
print("  ERMC | Demo 04: IA de Sucesiones Matematicas")
print("=" * 60)

sequences = [
    # (nombre, datos, esperado, descripcion)
    ("Cuadrados perfectos",
     [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121],
     144,
     "n^2: siguiente es 12^2 = 144"),
    ("Cubos perfectos",
     [0, 1, 8, 27, 64, 125, 216, 343, 512, 729],
     1000,
     "n^3: siguiente es 10^3 = 1000"),
    ("Progresion aritmetica",
     [3, 7, 11, 15, 19, 23, 27, 31, 35, 39],
     43,
     "a + (n-1)*4: siguiente es 43"),
    ("Progresion geometrica",
     [2, 4, 8, 16, 32, 64, 128, 256],
     512,
     "2^n: siguiente es 512"),
    ("Numeros triangulares",
     [0, 1, 3, 6, 10, 15, 21, 28, 36, 45],
     55,
     "n*(n+1)/2: siguiente es 55"),
]

print()
all_pass = True
for name, seq, expected, desc in sequences:
    pred = SequenceAI.predict_next([float(x) for x in seq])
    ok = abs(pred - expected) < 0.5
    status = "[PASS]" if ok else "[FAIL]"
    if not ok:
        all_pass = False
    print(f"  {status} {name}")
    print(f"         Secuencia:  {seq}")
    print(f"         Prediccion: {pred:.1f}  |  Esperado: {expected}  ({desc})\n")

# --- Experimento especial: descubrimiento libre ---
print("[Descubrimiento] Secuencia desconocida: 1, 5, 14, 30, 55, 91, 140, 204")
mystery = [1, 5, 14, 30, 55, 91, 140, 204]
pred_m = SequenceAI.predict_next([float(x) for x in mystery])
print(f"  Prediccion ERMC: {pred_m:.1f}")
print(f"  (Son numeros piramidales cuadrados: n*(n+1)*(2n+1)/6)")
print(f"  Siguiente real: {9*10*19//6} = {9*10*19//6}")

print(f"\n[{'OK' if all_pass else 'PARCIAL'}] Demo 04 completado.\n")
