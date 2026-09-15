# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import Sequence
from .ffi import get_lib


class SequenceAI:
    """Inteligencia Artificial Simbólica para Reconocimiento de Patrones y Series"""

    @staticmethod
    def predict_next(sequence: Sequence[float]) -> float:
        """
        Descubre la ley generadora subyacente de una sucesión numérica y predice el próximo elemento
        (ej. [0, 1, 4, 9, 16, 25, 36, 49, 64, 81, 100, 121] -> 144)
        """
        n = len(sequence)
        if n < 3:
            raise ValueError(f"Se requieren al menos 3 valores para identificar una secuencia, se dieron {n}")

        lib = get_lib()
        c_seq = (ctypes.c_double * n)(*(float(x) for x in sequence))
        return float(lib.ermc_sequence_predict_next(c_seq, n))
