# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import Sequence
from .ffi import get_lib
from .types import MeanVarResult


class Precision:
    """Aritmética Compensada de Orden de Máquina (Neumaier y Welford)"""

    @staticmethod
    def sum(data: Sequence[float]) -> float:
        """
        Suma Compensada de Neumaier
        Previene la cancelación catastrófica de punto flotante en sumas de gran rango dinámico
        (ej. 1e16 + 1.0 - 1e16 = 1.0 en lugar de 0.0)
        """
        n = len(data)
        if n == 0:
            return 0.0

        lib = get_lib()
        c_data = (ctypes.c_double * n)(*(float(x) for x in data))
        return float(lib.ermc_precision_sum(c_data, n))

    @staticmethod
    def mean_var(data: Sequence[float]) -> MeanVarResult:
        """
        Calcula la media y varianza con acumulación exacta en un solo pase
        """
        n = len(data)
        if n == 0:
            return MeanVarResult(0.0, 0.0)

        lib = get_lib()
        c_data = (ctypes.c_double * n)(*(float(x) for x in data))
        out_mean = ctypes.c_double(0.0)
        out_var = ctypes.c_double(0.0)

        lib.ermc_precision_mean_var(c_data, n, ctypes.byref(out_mean), ctypes.byref(out_var))
        return MeanVarResult(out_mean.value, out_var.value)
