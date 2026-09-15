# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import Sequence
from .ffi import get_lib


class HilbertSpace:
    """Operaciones fundamentales en Espacios de Hilbert L2"""

    @staticmethod
    def inner(u: Sequence[float], v: Sequence[float]) -> float:
        """Calcula el producto interno euclidiano <u, v> con acumulación SIMD"""
        if len(u) != len(v):
            raise ValueError(f"Dimensión incompatible: {len(u)} != {len(v)}")
        n = len(u)
        if n == 0:
            return 0.0

        lib = get_lib()
        c_u = (ctypes.c_double * n)(*(float(x) for x in u))
        c_v = (ctypes.c_double * n)(*(float(x) for x in v))
        return float(lib.ermc_hilbert_inner(c_u, c_v, n))

    @staticmethod
    def norm(v: Sequence[float]) -> float:
        """Calcula la norma inducida ||v||_H = sqrt(<v, v>)"""
        n = len(v)
        if n == 0:
            return 0.0

        lib = get_lib()
        c_v = (ctypes.c_double * n)(*(float(x) for x in v))
        return float(lib.ermc_hilbert_norm(c_v, n))

    @staticmethod
    def distance(u: Sequence[float], v: Sequence[float]) -> float:
        """Calcula la métrica canónica d(u, v) = ||u - v||_H"""
        if len(u) != len(v):
            raise ValueError(f"Dimensión incompatible: {len(u)} != {len(v)}")
        n = len(u)
        if n == 0:
            return 0.0

        lib = get_lib()
        c_u = (ctypes.c_double * n)(*(float(x) for x in u))
        c_v = (ctypes.c_double * n)(*(float(x) for x in v))
        return float(lib.ermc_hilbert_distance(c_u, c_v, n))

    @staticmethod
    def angle(u: Sequence[float], v: Sequence[float]) -> float:
        """Calcula el ángulo en radianes theta = arccos(<u, v> / (||u|| * ||v||))"""
        if len(u) != len(v):
            raise ValueError(f"Dimensión incompatible: {len(u)} != {len(v)}")
        n = len(u)
        if n == 0:
            return 0.0

        lib = get_lib()
        c_u = (ctypes.c_double * n)(*(float(x) for x in u))
        c_v = (ctypes.c_double * n)(*(float(x) for x in v))
        return float(lib.ermc_hilbert_angle(c_u, c_v, n))
