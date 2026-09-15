# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import Sequence
from .ffi import get_lib


class DMD:
    """Dynamic Mode Decomposition (DMD): Dinámica Espacio-Temporal y Frecuencias Coherentes"""

    @staticmethod
    def dominant_frequency(
        snapshots: Sequence[Sequence[float]],
        dt: float,
    ) -> float:
        """
        Extrae la frecuencia dominante (en rad/s) a partir de una matriz de instantáneas espacio-temporales
        
        :param snapshots: Matriz n_sensores x n_instantes temporales
        :param dt: Paso de tiempo uniforme entre instantáneas
        :return: Frecuencia pura en radianes por segundo
        """
        if dt <= 0.0:
            raise ValueError("dt debe ser mayor a 0")

        n_sensors = len(snapshots)
        if n_sensors == 0:
            raise ValueError("snapshots no puede estar vacío")

        n_snaps = len(snapshots[0])
        if n_snaps < 3:
            raise ValueError(f"Se requieren al menos 3 instantáneas temporales, se encontraron {n_snaps}")

        flat = []
        for sensor_series in snapshots:
            if len(sensor_series) != n_snaps:
                raise ValueError("Todas las series de sensores deben tener la misma longitud de instantáneas")
            flat.extend(float(x) for x in sensor_series)

        lib = get_lib()
        c_snaps = (ctypes.c_double * len(flat))(*flat)
        return float(lib.ermc_dmd_dominant_frequency(c_snaps, n_sensors, n_snaps, float(dt)))
