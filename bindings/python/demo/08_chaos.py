# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/08_chaos.py — Dinámica de Caos y Exponente de Lyapunov
Confirma el caos determinista en el sistema de Lorenz y variantes.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import Chaos

print("=" * 60)
print("  ERMC | Demo 08: Dinamica de Caos (Lorenz) - Lyapunov")
print("=" * 60)

# --- Experimento 1: Condiciones iniciales clásicas ---
print("\n[1] Sistema de Lorenz: condiciones iniciales clasicas (1,1,1):")
c1 = Chaos.analyze_lorenz(1.0, 1.0, 1.0)
print(f"  Exponente de Lyapunov max: {c1.lyapunov_exponent:.4f} s^-1")
print(f"  Horizonte predictibilidad: {c1.predictability_horizon:.4f} s")
print(f"  Diagnostico: {'CAOTICO' if c1.lyapunov_exponent > 0 else 'ESTABLE'}")

# --- Experimento 2: Sensibilidad a condiciones iniciales ---
print("\n[2] Sensibilidad a condiciones iniciales (efecto mariposa):")
configs = [
    (0.1, 0.0, 0.0, "Punto cercano al origen"),
    (1.0, 0.0, 0.0, "Eje X"),
    (0.0, 1.0, 0.0, "Eje Y"),
    (0.0, 0.0, 1.0, "Eje Z"),
    (5.0, 5.0, 5.0, "Punto en el atractor"),
]

print(f"  {'Condicion inicial':<30} {'Lyapunov':>10} {'T_pred (s)':>12} {'Estado':>10}")
print(f"  {'-'*65}")
for x0, y0, z0, label in configs:
    res = Chaos.analyze_lorenz(x0, y0, z0)
    status = "CAOTICO" if res.lyapunov_exponent > 0 else "ESTABLE"
    print(f"  {label:<30} {res.lyapunov_exponent:>10.4f} {res.predictability_horizon:>12.4f} {status:>10}")

# --- Experimento 3: Interpretación práctica ---
print("\n[3] Interpretacion practica del horizonte de predictibilidad:")
c3 = Chaos.analyze_lorenz(1.0, 1.0, 1.0)
t_pred = c3.predictability_horizon
print(f"  El sistema de Lorenz (sigma=10, r=28, b=8/3) tiene:")
print(f"  - Lyapunov max = {c3.lyapunov_exponent:.4f} s^-1")
print(f"  - Horizonte    = {t_pred:.4f} s")
print(f"  - Esto significa: despues de {t_pred:.2f}s, una perturbacion de 1e-10")
print(f"    crece hasta O(1) => perdida total de predictibilidad.")
print(f"  - Analogia meteorologica: limite del pronostico del tiempo ~2 semanas")

print("\n[OK] Demo 08 completado.\n")
