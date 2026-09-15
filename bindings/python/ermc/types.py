# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

from dataclasses import dataclass
from enum import IntEnum
from typing import List


class Activation(IntEnum):
    """
    Funciones de activación y transformaciones simbólicas
    Corresponden a enum Activation en src/core/types.zig
    """
    Identity = 0
    Sine = 1
    Cosine = 2
    Square = 3
    Cube = 4
    Exp = 5
    ExpNeg = 6
    Sqrt = 7
    InverseSquare = 8
    Inv = 9
    Ln = 10
    Tanh = 11
    Interaction = 12


@dataclass
class OutlierResult:
    """Resultado de la detección robusta de anomalías estadísticas"""
    outliers_count: int
    is_outlier: List[bool]
    clean_data: List[float]


@dataclass
class MeanVarResult:
    """Media y varianza calculadas con precisión compensada"""
    mean: float
    variance: float


@dataclass
class SvdResult:
    """Resultado de la descomposición en valores singulares A = U * S * V^T"""
    m: int
    n: int
    u: List[List[float]]
    s: List[float]
    v: List[List[float]]


@dataclass
class ChaosResult:
    """Resultado del análisis de dinámicas caóticas y exponente de Lyapunov"""
    lyapunov_exponent: float
    predictability_horizon: float
