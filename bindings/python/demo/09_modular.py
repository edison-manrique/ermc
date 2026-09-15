# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/09_modular.py — Aritmética Modular en F_p (Python)
Descubre: Pequeño Teorema de Fermat, residuos cuadráticos y raíces mod p
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

sys.path.insert(0, "..")
from ermc import Modular

P = 1009

print("\n╔══════════════════════════════════════════════════════╗")
print("║  Demo 09: Aritmética Modular en F_p (ERMC v0.4.0)   ║")
print("╚══════════════════════════════════════════════════════╝\n")

# Pequeño Teorema de Fermat: a^(p-1) ≡ 1 (mod p)
a = 42
fermat = Modular.pow(a, P - 1, P)
print(f"Pequeño Teorema de Fermat: {a}^({P}-1) mod {P} = {fermat} ✓")

# Inverso modular: a * a^{-1} ≡ 1 (mod p)
inv = Modular.inverse(a, P)
assert inv is not None
check = Modular.mul(a, inv, P)
print(f"Inverso modular: {a}^(-1) mod {P} = {inv},  {a}×{inv} mod {P} = {check} ✓")

# Residuos cuadráticos y raíces mod 97
print("\nResiduos cuadráticos mod 97:")
p97 = 97
for sq in [4, 9, 16, 25, 36]:
    root = Modular.sqrt(sq, p97)
    if root is not None:
        verify = Modular.mul(root, root, p97)
        print(f"  √{sq} mod {p97} = {root}  ({root}²={verify}={sq} ✓)")

# Non-residuos cuadráticos: verificar que sqrt retorna None
for cand in [3, 5, 6, 7, 10]:
    root_cand = Modular.sqrt(cand, p97)
    if root_cand is None:
        print(f"  {cand} es NO-residuo cuadrático mod {p97} (is_qr={Modular.is_qr(cand, p97)}) ✓")
        break

# Aritmética encadenada: (a + b) * (a - b) = a² - b² mod p
b = 30
lhs = Modular.mul(Modular.add(a, b, P), Modular.sub(a, b, P), P)
rhs = Modular.sub(Modular.mul(a, a, P), Modular.mul(b, b, P), P)
print(f"\n(a+b)(a-b) = a²-b² mod {P}: {lhs} = {rhs} ✓ (diferencia de cuadrados)")

print("\n✓ Demo 09 completada — Aritmética Modular F_p (Python)\n")
