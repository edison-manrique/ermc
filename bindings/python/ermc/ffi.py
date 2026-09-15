# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

import ctypes
import os
import platform
import sys
from typing import Optional

IS_WINDOWS = platform.system() == "Windows"
IS_DARWIN = platform.system() == "Darwin"

if IS_WINDOWS:
    LIB_NAME = "ermc.dll"
elif IS_DARWIN:
    LIB_NAME = "libermc.dylib"
else:
    LIB_NAME = "libermc.so"

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(CURRENT_DIR, "..", "..", ".."))

# Rutas estándar de búsqueda de la biblioteca compartida compilada por Zig
CANDIDATE_PATHS = [
    os.environ.get("ERMC_LIB_PATH"),
    os.path.join(REPO_ROOT, "zig-out", "bin", LIB_NAME),
    os.path.join(REPO_ROOT, "zig-out", "lib", LIB_NAME),
    os.path.join(CURRENT_DIR, LIB_NAME),
    os.path.join(os.path.dirname(CURRENT_DIR), LIB_NAME),
]

_cached_lib = None


def find_library_path(custom_path: Optional[str] = None) -> str:
    """Encuentra la ruta absoluta a la biblioteca dinámica nativa ermc"""
    if custom_path and os.path.exists(custom_path):
        return os.path.abspath(custom_path)

    for path in CANDIDATE_PATHS:
        if path and os.path.exists(path):
            return os.path.abspath(path)

    raise FileNotFoundError(
        f"No se encontró la biblioteca compartida '{LIB_NAME}'.\n"
        f"Asegúrate de compilar el proyecto con 'zig build' en la raíz de ERMC.\n"
        f"Rutas examinadas:\n" + "\n".join(f"  - {p}" for p in CANDIDATE_PATHS if p)
    )


def load_native_library(custom_path: Optional[str] = None) -> ctypes.CDLL:
    """Carga y configura las firmas ctypes de la biblioteca nativa ERMC"""
    lib_path = find_library_path(custom_path)
    lib_dir = os.path.dirname(lib_path)

    if IS_WINDOWS and hasattr(os, "add_dll_directory"):
        try:
            os.add_dll_directory(lib_dir)
        except Exception:
            pass

    try:
        if IS_WINDOWS and sys.version_info >= (3, 8):
            lib = ctypes.CDLL(lib_path, winmode=0)
        else:
            lib = ctypes.CDLL(lib_path)
    except Exception as e:
        raise RuntimeError(f"Error al cargar la biblioteca nativa ERMC en {lib_path}: {e}")

    # =========================================================================
    # CONFIGURACIÓN DE FIRMAS CTYPES (C-ABI)
    # =========================================================================

    # Versión
    lib.ermc_version.argtypes = []
    lib.ermc_version.restype = ctypes.c_char_p

    # OmniEngine
    lib.ermc_engine_create.argtypes = [ctypes.c_size_t]
    lib.ermc_engine_create.restype = ctypes.c_void_p

    lib.ermc_engine_destroy.argtypes = [ctypes.c_void_p]
    lib.ermc_engine_destroy.restype = None

    lib.ermc_engine_term_count.argtypes = [ctypes.c_void_p]
    lib.ermc_engine_term_count.restype = ctypes.c_size_t

    lib.ermc_engine_build_dictionary.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_uint32),
        ctypes.c_size_t,
    ]
    lib.ermc_engine_build_dictionary.restype = ctypes.c_bool

    lib.ermc_engine_fit.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
        ctypes.c_double,
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_engine_fit.restype = ctypes.c_size_t

    lib.ermc_engine_predict.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_engine_predict.restype = ctypes.c_double

    lib.ermc_engine_get_formula.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_char),
        ctypes.c_size_t,
    ]
    lib.ermc_engine_get_formula.restype = ctypes.c_size_t

    # Hilbert
    lib.ermc_hilbert_inner.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_hilbert_inner.restype = ctypes.c_double

    lib.ermc_hilbert_norm.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_hilbert_norm.restype = ctypes.c_double

    lib.ermc_hilbert_distance.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_hilbert_distance.restype = ctypes.c_double

    lib.ermc_hilbert_angle.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_hilbert_angle.restype = ctypes.c_double

    # Precisión Compensada
    lib.ermc_precision_sum.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_precision_sum.restype = ctypes.c_double

    lib.ermc_precision_mean_var.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_precision_mean_var.restype = None

    # Outliers
    lib.ermc_outliers_hampel.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
        ctypes.c_double,
        ctypes.POINTER(ctypes.c_uint8),
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_outliers_hampel.restype = ctypes.c_size_t

    # SVD
    lib.ermc_svd.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
        ctypes.c_size_t,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_svd.restype = ctypes.c_bool

    # Secuencias
    lib.ermc_sequence_predict_next.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
    ]
    lib.ermc_sequence_predict_next.restype = ctypes.c_double

    # DMD
    lib.ermc_dmd_dominant_frequency.argtypes = [
        ctypes.POINTER(ctypes.c_double),
        ctypes.c_size_t,
        ctypes.c_size_t,
        ctypes.c_double,
    ]
    lib.ermc_dmd_dominant_frequency.restype = ctypes.c_double

    # Caos
    lib.ermc_chaos_lorenz.argtypes = [
        ctypes.c_double,
        ctypes.c_double,
        ctypes.c_double,
        ctypes.POINTER(ctypes.c_double),
        ctypes.POINTER(ctypes.c_double),
    ]
    lib.ermc_chaos_lorenz.restype = ctypes.c_bool

    return lib


def get_lib(custom_path: Optional[str] = None) -> ctypes.CDLL:
    """Devuelve la instancia singleton de la biblioteca nativa cargada"""
    global _cached_lib
    if _cached_lib is None or custom_path is not None:
        _cached_lib = load_native_library(custom_path)
    return _cached_lib


def get_version(custom_path: Optional[str] = None) -> str:
    """Obtiene la cadena de versión de la biblioteca ERMC compilada en Zig"""
    lib = get_lib(custom_path)
    raw = lib.ermc_version()
    if raw:
        return raw.decode("utf-8")
    return "0.0.0"
