# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import Sequence
from .ffi import get_lib
from .types import OutlierResult


class Outliers:
    """Detección ultra-robusta de valores atípicos y perturbaciones extremas (10^100)"""

    @staticmethod
    def detect_hampel(data: Sequence[float], k_threshold: float = 3.0) -> OutlierResult:
        """
        Identificador Hampel robusto basado en Mediana y MAD (Median Absolute Deviation)
        Inmune a desbordamientos numéricos causados por outliers extremos (ej. 1e100).
        
        :param data: Vector de muestras numéricas
        :param k_threshold: Factor de escala de desviación estándar robusta (defecto 3.0)
        :return: Objeto OutlierResult con cantidad, máscara booleana y datos limpios e imputados
        """
        n = len(data)
        if n == 0:
            return OutlierResult(0, [], [])

        lib = get_lib()
        c_data = (ctypes.c_double * n)(*(float(x) for x in data))
        c_mask = (ctypes.c_uint8 * n)()
        c_clean = (ctypes.c_double * n)()

        n_outliers = lib.ermc_outliers_hampel(
            c_data,
            n,
            float(k_threshold),
            c_mask,
            c_clean,
        )

        is_outlier = [bool(c_mask[i] == 1) for i in range(n)]
        clean_data = [c_clean[i] for i in range(n)]

        return OutlierResult(
            outliers_count=n_outliers,
            is_outlier=is_outlier,
            clean_data=clean_data,
        )
