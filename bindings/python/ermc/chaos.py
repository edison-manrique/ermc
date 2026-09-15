# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from .ffi import get_lib
from .types import ChaosResult


class Chaos:
    """Dinámica No Lineal, Caos Determinista y Exponentes de Lyapunov"""

    @staticmethod
    def analyze_lorenz(x0: float = 1.0, y0: float = 1.0, z0: float = 1.0) -> ChaosResult:
        """
        Calcula el exponente de Lyapunov máximo lambda_max y el horizonte de predictibilidad T_L
        mediante integración RK4 perturbada del atractor caótico de Lorenz 63.
        
        :param x0: Condición inicial x
        :param y0: Condición inicial y
        :param z0: Condición inicial z
        :return: Objeto ChaosResult con exponente de Lyapunov y horizonte temporal
        """
        lib = get_lib()
        out_lyap = ctypes.c_double(0.0)
        out_horizon = ctypes.c_double(0.0)

        ok = lib.ermc_chaos_lorenz(
            float(x0),
            float(y0),
            float(z0),
            ctypes.byref(out_lyap),
            ctypes.byref(out_horizon),
        )

        if not ok:
            raise RuntimeError("Error al ejecutar el análisis caótico en el núcleo C/Zig")

        return ChaosResult(
            lyapunov_exponent=out_lyap.value,
            predictability_horizon=out_horizon.value,
        )
