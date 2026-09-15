# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
from typing import List, Optional, Sequence, Union
from .ffi import get_lib
from .types import Activation


class OmniEngine:
    """
    OmniEngine: Motor de Regresión Simbólica y Descubrimiento de Leyes Físicas
    
    Implementa regresión dispersa (STLSQ), snapping de constantes físicas
    y expansión multivariable en espacios funcionales no lineales.
    """

    def __init__(self, num_inputs: int, custom_lib_path: Optional[str] = None):
        if num_inputs <= 0:
            raise ValueError("num_inputs debe ser mayor a 0")

        self.lib = get_lib(custom_lib_path)
        self.num_inputs = num_inputs
        self.handle = self.lib.ermc_engine_create(num_inputs)

        if not self.handle:
            raise RuntimeError("No se pudo instanciar OmniEngine en el núcleo nativo C/Zig")

        self._is_disposed = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.dispose()

    def __del__(self):
        self.dispose()

    def dispose(self) -> None:
        """Libera la memoria y recursos nativos asignados en Zig"""
        if not self._is_disposed and hasattr(self, "handle") and self.handle:
            self.lib.ermc_engine_destroy(self.handle)
            self.handle = None
            self._is_disposed = True

    def get_term_count(self) -> int:
        """Devuelve el número actual de términos en el diccionario topológico"""
        self._check_alive()
        return self.lib.ermc_engine_term_count(self.handle)

    def build_dictionary(self, activations: Sequence[Activation]) -> None:
        """
        Construye el diccionario de expansión funcional con las activaciones especificadas
        
        Ejemplo:
            engine.build_dictionary([Activation.Identity, Activation.Sine, Activation.Square])
        """
        self._check_alive()
        if not activations:
            return

        n_acts = len(activations)
        c_acts = (ctypes.c_uint32 * n_acts)(*(int(a) for a in activations))

        ok = self.lib.ermc_engine_build_dictionary(self.handle, c_acts, n_acts)
        if not ok:
            raise RuntimeError("Error al construir el diccionario de expansiones en Zig")

    def fit(
        self,
        inputs: Union[List[List[float]], Sequence[Sequence[float]]],
        targets: Sequence[float],
        threshold: float = 0.015,
    ) -> List[float]:
        """
        Ajusta el modelo a los datos y devuelve el vector de coeficientes descubiertos
        
        :param inputs: Lista de muestras M x num_inputs
        :param targets: Lista de objetivos M
        :param threshold: Umbral relativo de parsimonia para STLSQ (defecto 0.015 = 1.5%)
        :return: Lista de coeficientes para cada término del diccionario
        """
        self._check_alive()
        n_samples = len(targets)
        if n_samples == 0:
            raise ValueError("El conjunto de datos no puede estar vacío")

        if len(inputs) != n_samples:
            raise ValueError(f"Dimensión inconsistente: {len(inputs)} entradas vs {n_samples} objetivos")

        # Aplanar inputs en buffer contiguo f64
        flat_inputs = []
        for row in inputs:
            if len(row) != self.num_inputs:
                raise ValueError(f"Cada muestra debe tener {self.num_inputs} valores, se encontró {len(row)}")
            flat_inputs.extend(float(val) for val in row)

        c_inputs = (ctypes.c_double * len(flat_inputs))(*flat_inputs)
        c_targets = (ctypes.c_double * n_samples)(*(float(t) for t in targets))

        term_count = self.get_term_count()
        c_out_weights = (ctypes.c_double * term_count)()

        n_terms = self.lib.ermc_engine_fit(
            self.handle,
            c_inputs,
            c_targets,
            n_samples,
            float(threshold),
            c_out_weights,
        )

        if n_terms == 0 and term_count > 0:
            return [0.0] * term_count

        return [c_out_weights[i] for i in range(n_terms)]

    def predict(
        self,
        input_sample: Sequence[float],
        weights: Sequence[float],
    ) -> float:
        """
        Predice el valor target para una muestra de entrada utilizando los coeficientes descubiertos
        """
        self._check_alive()
        if len(input_sample) != self.num_inputs:
            raise ValueError(f"input_sample debe tener {self.num_inputs} valores, se encontró {len(input_sample)}")

        n_terms = self.get_term_count()
        if len(weights) != n_terms:
            raise ValueError(f"weights debe coincidir con el número de términos ({n_terms})")

        c_input = (ctypes.c_double * self.num_inputs)(*(float(x) for x in input_sample))
        c_weights = (ctypes.c_double * n_terms)(*(float(w) for w in weights))

        return float(self.lib.ermc_engine_predict(self.handle, c_input, c_weights))

    def get_formula(self, weights: Sequence[float]) -> str:
        """
        Reconstruye la fórmula matemática analítica en texto legible a partir de los pesos
        
        Ejemplo retornado: 'f(X) = -9.8100*sin(x0) - (1/2)*x1^2'
        """
        self._check_alive()
        n_terms = self.get_term_count()
        if len(weights) != n_terms:
            raise ValueError(f"weights debe tener longitud {n_terms}")

        c_weights = (ctypes.c_double * n_terms)(*(float(w) for w in weights))
        buf_size = 1024
        out_buf = ctypes.create_string_buffer(buf_size)

        copied = self.lib.ermc_engine_get_formula(self.handle, c_weights, out_buf, buf_size)
        if copied == 0:
            return "0.0000"

        return out_buf.value.decode("utf-8", errors="replace")

    def _check_alive(self):
        if self._is_disposed or not self.handle:
            raise RuntimeError("OmniEngine ya ha sido liberado")
