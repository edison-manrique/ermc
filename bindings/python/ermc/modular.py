# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

from typing import Optional
from .ffi import get_lib

U64_MAX = 18446744073709551615


class Modular:
    """Aritmética de campos finitos F_p (enteros de 64 bits sin signo)."""

    @staticmethod
    def add(a: int, b: int, p: int) -> int:
        """Suma modular: (a + b) mod p"""
        return get_lib().ermc_mod_add(int(a), int(b), int(p))

    @staticmethod
    def sub(a: int, b: int, p: int) -> int:
        """Resta modular: (a - b) mod p"""
        return get_lib().ermc_mod_sub(int(a), int(b), int(p))

    @staticmethod
    def mul(a: int, b: int, p: int) -> int:
        """Multiplicación modular: (a * b) mod p"""
        return get_lib().ermc_mod_mul(int(a), int(b), int(p))

    @staticmethod
    def pow(base: int, exp: int, p: int) -> int:
        """Exponenciación modular binaria: base^exp mod p"""
        return get_lib().ermc_mod_pow(int(base), int(exp), int(p))

    @staticmethod
    def inverse(a: int, p: int) -> Optional[int]:
        """Inverso modular a^{-1} mod p (Algoritmo Extendido de Euclides), o None si no existe."""
        res = get_lib().ermc_mod_inverse(int(a), int(p))
        return None if res == U64_MAX else res

    @staticmethod
    def sqrt(a: int, p: int) -> Optional[int]:
        """Raíz cuadrada modular √a mod p (Algoritmo Tonelli-Shanks), o None si no es residuo cuadrático."""
        res = get_lib().ermc_mod_sqrt(int(a), int(p))
        return None if res == U64_MAX else res

    @staticmethod
    def is_qr(a: int, p: int) -> bool:
        """Criterio de Euler: verifica si a es residuo cuadrático mod p."""
        e = (int(p) - 1) // 2
        return Modular.pow(a, e, p) == 1
