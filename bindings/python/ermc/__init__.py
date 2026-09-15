# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

"""
ERMC (Exact Regression Mathematical Core) - Python Bindings
Motor de Inteligencia Artificial Matemática, SciML y Descubrimiento Simbólico de Leyes Físicas.
"""

from .types import (
    Activation,
    OutlierResult,
    MeanVarResult,
    SvdResult,
    ChaosResult,
)
from .ffi import get_version, get_lib
from .engine import OmniEngine
from .hilbert import HilbertSpace
from .precision import Precision
from .outliers import Outliers
from .svd import SVD
from .sequence import SequenceAI
from .dmd import DMD
from .chaos import Chaos
from .modular import Modular
from .elliptic import EllipticCurve, EcPoint
from .series import AnalyticSeries

__version__ = get_version()
__all__ = [
    "Activation",
    "OutlierResult",
    "MeanVarResult",
    "SvdResult",
    "ChaosResult",
    "get_version",
    "get_lib",
    "OmniEngine",
    "HilbertSpace",
    "Precision",
    "Outliers",
    "SVD",
    "SequenceAI",
    "DMD",
    "Chaos",
    "Modular",
    "EllipticCurve",
    "EcPoint",
    "AnalyticSeries",
]

