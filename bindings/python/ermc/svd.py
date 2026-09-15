# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import List, Sequence, Union
from .ffi import get_lib
from .types import SvdResult


class SVD:
    """Descomposición en Valores Singulares (One-Sided Jacobi)"""

    @staticmethod
    def decompose(
        matrix_data: Union[Sequence[Sequence[float]], Sequence[float]],
        m: int,
        n: int,
    ) -> SvdResult:
        """
        Factoriza la matriz A (m x n con m >= n) en U * S * V^T
        
        :param matrix_data: Matriz como lista de listas (m x n) o buffer aplanado (m * n)
        :param m: Número de filas
        :param n: Número de columnas (debe ser m >= n)
        :return: Objeto SvdResult con matrices U, S (valores singulares) y V
        """
        if m < n or n == 0:
            raise ValueError(f"Dimensión inválida para SVD: m={m}, n={n} (se requiere m >= n > 0)")

        # Aplanar datos
        flat = []
        if len(matrix_data) > 0 and isinstance(matrix_data[0], (list, tuple)):
            for row in matrix_data:
                flat.extend(float(x) for x in row)
        else:
            flat = [float(x) for x in matrix_data]

        if len(flat) != m * n:
            raise ValueError(f"Datos de matriz tienen {len(flat)} elementos, se esperaban {m * n}")

        lib = get_lib()
        c_mat = (ctypes.c_double * len(flat))(*flat)
        c_u = (ctypes.c_double * (m * n))()
        c_s = (ctypes.c_double * n)()
        c_v = (ctypes.c_double * (n * n))()

        ok = lib.ermc_svd(c_mat, m, n, c_u, c_s, c_v)
        if not ok:
            raise RuntimeError("Error al calcular la descomposición SVD en el núcleo C/Zig")

        # Convertir a matrices anidadas amigables en Python
        u_mat = [[c_u[i * n + j] for j in range(n)] for i in range(m)]
        s_vec = [c_s[j] for j in range(n)]
        v_mat = [[c_v[i * n + j] for j in range(n)] for i in range(n)]

        return SvdResult(m=m, n=n, u=u_mat, s=s_vec, v=v_mat)
