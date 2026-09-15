# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from dataclasses import dataclass
from .ffi import get_lib


@dataclass
class EcPoint:
    """Punto en la curva elíptica afín sobre F_p."""
    x: int
    y: int
    is_infinity: bool = False

    @classmethod
    def infinity(cls) -> "EcPoint":
        return cls(x=0, y=0, is_infinity=True)

    def __str__(self) -> str:
        return "O (∞)" if self.is_infinity else f"({self.x}, {self.y})"


class EllipticCurve:
    """Curva elíptica de Weierstrass corta y² = x³ + 7 (mod p) — Koblitz / secp256k1 reducida."""

    @staticmethod
    def is_on_curve(x: int, y: int, p: int) -> bool:
        """Verifica si (x, y) pertenece a la curva y² = x³ + 7 mod p."""
        return bool(get_lib().ermc_ec_is_on_curve(int(x), int(y), int(p)))

    @staticmethod
    def add(p1: EcPoint, p2: EcPoint, p: int) -> EcPoint:
        """Suma geométrica de dos puntos P1 + P2 en la curva mod p."""
        if p1.is_infinity:
            return p2
        if p2.is_infinity:
            return p1

        out_x = ctypes.c_uint64()
        out_y = ctypes.c_uint64()
        ok = get_lib().ermc_ec_add(
            int(p1.x), int(p1.y),
            int(p2.x), int(p2.y),
            int(p),
            ctypes.byref(out_x),
            ctypes.byref(out_y),
        )
        if not ok:
            return EcPoint.infinity()
        if out_x.value == 0 and out_y.value == 0:
            return EcPoint.infinity()
        return EcPoint(x=int(out_x.value), y=int(out_y.value), is_infinity=False)

    @staticmethod
    def scalar_mul(k: int, pt: EcPoint, p: int) -> EcPoint:
        """Multiplicación escalar k·P (Double-and-Add) en la curva mod p."""
        if pt.is_infinity or k == 0:
            return EcPoint.infinity()

        out_x = ctypes.c_uint64()
        out_y = ctypes.c_uint64()
        ok = get_lib().ermc_ec_scalar_mul(
            int(k),
            int(pt.x), int(pt.y),
            int(p),
            ctypes.byref(out_x),
            ctypes.byref(out_y),
        )
        if not ok:
            return EcPoint.infinity()
        if out_x.value == 0 and out_y.value == 0:
            return EcPoint.infinity()
        return EcPoint(x=int(out_x.value), y=int(out_y.value), is_infinity=False)
