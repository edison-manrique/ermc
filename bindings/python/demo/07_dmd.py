# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/07_dmd.py — Dynamic Mode Decomposition (DMD)
Extrae frecuencias dominantes de sistemas espacio-temporales.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
sys.path.insert(0, "..")
from ermc import DMD

print("=" * 60)
print("  ERMC | Demo 07: DMD - Modos Dinamicos Dominantes")
print("=" * 60)

# --- Experimento 1: Señal mono-frecuencia conocida ---
print("\n[1] Senal mono-frecuencia (omega = pi rad/s):")
dt = 0.05
n = 60
omega_true = math.pi
snapshots_1 = [
    [math.sin(omega_true * k * dt) for k in range(n)],
    [math.cos(omega_true * k * dt) for k in range(n)],
]
freq_1 = DMD.dominant_frequency(snapshots_1, dt)
error_1 = abs(freq_1 - omega_true)
print(f"  omega teorico: {omega_true:.6f} rad/s")
print(f"  omega DMD:     {freq_1:.6f} rad/s")
print(f"  Error:         {error_1:.2e}")
print(f"  {'[PASS]' if error_1 < 0.05 else '[FAIL]'}")

# --- Experimento 2: Batimiento de dos frecuencias ---
print("\n[2] Batimiento: suma de dos frecuencias (omega1=2, omega2=7):")
omega1, omega2 = 2.0, 7.0
dt2 = 0.02
n2 = 80
snapshots_2 = [
    [math.sin(omega1 * k * dt2) + 0.5 * math.sin(omega2 * k * dt2) for k in range(n2)],
    [math.cos(omega1 * k * dt2) + 0.5 * math.cos(omega2 * k * dt2) for k in range(n2)],
]
freq_2 = DMD.dominant_frequency(snapshots_2, dt2)
print(f"  Frecuencia dominante extraida: {freq_2:.4f} rad/s")
print(f"  (La componente mas energetica es omega1 = {omega1} rad/s)")

# --- Experimento 3: Sistema fisico — oscilador de Van der Pol aproximado ---
print("\n[3] Datos de tipo Van der Pol (oscilador de ciclo limite):")
# Simulacion simplificada de trayectoria de VdP
eps = 0.1
x, y = 0.1, 0.0
dt3 = 0.02
n3 = 100
trj_x, trj_y = [], []
for _ in range(n3):
    dx = y
    dy = eps * (1 - x * x) * y - x
    x += dx * dt3
    y += dy * dt3
    trj_x.append(x)
    trj_y.append(y)

freq_vdp = DMD.dominant_frequency([trj_x, trj_y], dt3)
print(f"  Frecuencia de ciclo limite detectada: {freq_vdp:.4f} rad/s")
print(f"  (Esperado aprox: 1.0 rad/s para eps pequeño)")

print("\n[OK] Demo 07 completado.\n")
