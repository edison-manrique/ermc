# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/11_series.py — Mock Theta de Ramanujan & Distribución de Primos (Python)
Descubre: Convergencia de Watson, π(x) exacto vs Li(x), Hipótesis de Riemann
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import AnalyticSeries

print("\n╔══════════════════════════════════════════════════════════╗")
print("║  Demo 11: Ramanujan Mock Theta & Primos (ERMC v0.4.0)  ║")
print("╚══════════════════════════════════════════════════════════╝\n")

# Mock Theta vs asintótica de Watson
print("Mock Theta f(q) — Convergencia al modelo asintótico de Watson:")
print("  [t=0.5 todavía lejos del límite; t→0 converge con < 1%]")

t_values = [0.5, 0.2, 0.1, 0.05, 0.02]
for t in t_values:
    ln_f = AnalyticSeries.mock_theta_ln(t, 800)
    watson = AnalyticSeries.watson_asymptotic(t)
    err_pct = abs(ln_f - watson) / abs(watson) * 100.0
    print(f"  t={t:.2f}: ln|f|={ln_f:.4f}, Watson={watson:.4f}, err={err_pct:.2f}%")

# π(x) exacto vs Li(x) — validación numérica Riemann
print("\nπ(x) exacto vs Li(x) de Riemann:")
print("  x          π(x)   Li(x)    error")
print("  " + "─" * 42)

for x in [100, 500, 1000, 5000, 10000, 50000]:
    pi_val = AnalyticSeries.prime_count_pi(x, 100000)
    li_val = AnalyticSeries.logarithmic_integral_li(x)
    err_val = AnalyticSeries.riemann_error(x, 100000)
    print(f"  {str(x).rjust(6)}  {str(pi_val).rjust(6)}  {li_val:7.1f}  {err_val:.2f}%")

# Constante de Ramanujan-Soldner: Li(2) ≈ 1.04516
li2 = AnalyticSeries.logarithmic_integral_li(2.0)
print(f"\nOffset Ramanujan-Soldner Li(2) = {li2:.6f} (valor conocido ≈ 1.04516)")

# Asintótica de Watson en valores extremos
print("\nAsintótica de Watson (predicción teórica pura):")
for t in [0.01, 0.005, 0.001]:
    w = AnalyticSeries.watson_asymptotic(t)
    print(f"  t={t}: π²/(24t) - ½ln(t) + ½ln(π) = {w:.2f}")

print("\n✓ Demo 11 completada — Ramanujan & Distribución de Primos (Python)\n")
