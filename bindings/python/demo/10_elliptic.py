# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/10_elliptic.py — Curvas Elípticas y² = x³ + 7 (mod p) (Python)
Descubre: Leyes de grupo EC, multiplicación escalar y duplicación diferencial
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import EllipticCurve, EcPoint, Modular

P = 1009

print("\n╔══════════════════════════════════════════════════════╗")
print("║  Demo 10: Curvas Elípticas y²=x³+7 mod p (v0.4.0)  ║")
print("╚══════════════════════════════════════════════════════╝\n")

# Buscar un punto de orden alto: probar x=1,2,3... hasta encontrar y válida
G = None
for xi in range(1, 50):
    # y² = x³ + 7 mod p
    rhs = Modular.add(Modular.mul(Modular.mul(xi, xi, P), xi, P), 7, P)
    yi = Modular.sqrt(rhs, P)
    if yi is not None and yi > 0:
        G = EcPoint(x=xi, y=yi)
        break

if not G:
    print("No se encontró punto en la curva.")
    sys.exit(1)

print(f"Punto generador G = {G}")
print(f"G en curva: {EllipticCurve.is_on_curve(G.x, G.y, P)} ✓\n")

# Multiplicaciones escalares
scalars = [2, 3, 5, 7, 10, 20]
k_points = []
print("Tabla de multiplicación escalar k·G:")
for k in scalars:
    k_G = EllipticCurve.scalar_mul(k, G, P)
    k_points.append(k_G)
    valid = "O" if k_G.is_infinity else ("✓" if EllipticCurve.is_on_curve(k_G.x, k_G.y, P) else "✗")
    print(f"  {str(k).rjust(3)}·G = {str(k_G).ljust(20)} [{valid}]")

# Verificar 5G = 3G + 2G
two_G, three_G, five_G = k_points[0], k_points[1], k_points[2]
sum3_2 = EllipticCurve.add(three_G, two_G, P)
print(f"\nVerificación: 3G + 2G = {sum3_2}")
print(f"              5G      = {five_G}")
print(f"  Coinciden: {sum3_2.x == five_G.x and sum3_2.y == five_G.y} ✓")

# Ley de duplicación diferencial: λ = 3x²/(2y) mod p, a=0
x, y = G.x, G.y
num = Modular.mul(3, Modular.mul(x, x, P), P)
den = Modular.mul(2, y, P)
den_inv = Modular.inverse(den, P)
assert den_inv is not None
lambda_val = Modular.mul(num, den_inv, P)
x2_expected = Modular.sub(Modular.sub(Modular.mul(lambda_val, lambda_val, P), x, P), x, P)
print(f"\nLey diferencial λ(2G): {lambda_val}")
print(f"  x(2G) fórmula  = {x2_expected}")
print(f"  x(2G) scalarMul = {two_G.x}")
print(f"  Coinciden: {x2_expected == two_G.x} ✓")

print("\n✓ Demo 10 completada — Curvas Elípticas F_p (Python)\n")
