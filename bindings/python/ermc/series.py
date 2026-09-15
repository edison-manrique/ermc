# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
# Ver archivo LICENSE en la raíz del proyecto para términos completos.

from .ffi import get_lib


class AnalyticSeries:
    """Series analíticas: Ramanujan Mock Theta y distribución de números primos."""

    @staticmethod
    def mock_theta_ln(t: float, max_terms: int = 500) -> float:
        """Evalúa ln|f(-e^{-t})| de la función Mock Theta f(q) de orden 3 de Ramanujan."""
        return float(get_lib().ermc_ramanujan_mock_theta_ln(float(t), int(max_terms)))

    @staticmethod
    def watson_asymptotic(t: float) -> float:
        """Predicción asintótica teórica de Ramanujan-Watson: π²/(24t) - ½ln(t) + ½ln(π)."""
        return float(get_lib().ermc_ramanujan_watson_asymptotic(float(t)))

    @staticmethod
    def prime_count_pi(x: float, max_n: int = 100000) -> int:
        """Contador exacto π(x) de números primos ≤ x (Criba de Eratóstenes)."""
        return int(get_lib().ermc_prime_count_pi(float(x), int(max_n)))

    @staticmethod
    def logarithmic_integral_li(x: float) -> float:
        """Integral logarítmica Li(x) de Riemann."""
        return float(get_lib().ermc_logarithmic_integral_li(float(x)))

    @staticmethod
    def riemann_error(x: float, max_n: int = 100000) -> float:
        """Error relativo porcentual |Li(x) - π(x)| / π(x) * 100."""
        pi_val = AnalyticSeries.prime_count_pi(x, max_n)
        if pi_val == 0:
            return 0.0
        li_val = AnalyticSeries.logarithmic_integral_li(x)
        return abs(li_val - pi_val) / pi_val * 100.0
