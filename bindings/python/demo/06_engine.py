# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/06_engine.py — OmniEngine: Descubrimiento Simbólico de Leyes Físicas
Redescubre ecuaciones de la física clásica desde datos numéricos puros.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
import time
sys.path.insert(0, "..")
from ermc import OmniEngine, Activation

print("=" * 60)
print("  ERMC | Demo 06: OmniEngine - Descubrimiento de Leyes Fisicas")
print("=" * 60)

experiments = [
    {
        "name": "Pendulo no lineal con arrastre",
        "law": "f(th, w) = -9.81*sin(th) - 0.5*w^2",
        "n_vars": 2,
        "activations": [Activation.Identity, Activation.Sine, Activation.Square],
        "sampler": lambda: [
            ([
                -1.5 + 3.0 * i / 24,
                0.0 + 3.0 * j / 24,
            ],
            -9.81 * math.sin(-1.5 + 3.0 * i / 24) - 0.5 * (3.0 * j / 24) ** 2)
            for i in range(25)
            for j in range(25)
        ],
        "test": ([0.5, 1.2], lambda: -9.81 * math.sin(0.5) - 0.5 * 1.44),
    },
    {
        "name": "Ley de Hooke (resorte amortiguado)",
        "law": "f(x, v) = -10*x - 0.3*v",
        "n_vars": 2,
        "activations": [Activation.Identity],
        "sampler": lambda: [
            ([
                -2.0 + 4.0 * i / 19,
                -3.0 + 6.0 * j / 19,
            ],
            -10.0 * (-2.0 + 4.0 * i / 19) - 0.3 * (-3.0 + 6.0 * j / 19))
            for i in range(20)
            for j in range(20)
        ],
        "test": ([1.0, 0.5], lambda: -10.0 * 1.0 - 0.3 * 0.5),
    },
]

for exp in experiments:
    print(f"\n--- {exp['name']} ---")
    print(f"  Ley Teorica: {exp['law']}")

    pairs = exp["sampler"]()
    inputs = [p[0] for p in pairs]
    targets = [p[1] for p in pairs]

    with OmniEngine(exp["n_vars"]) as engine:
        engine.build_dictionary(exp["activations"])
        t0 = time.perf_counter()
        weights = engine.fit(inputs, targets, 0.02)
        elapsed = (time.perf_counter() - t0) * 1000

        formula = engine.get_formula(weights)
        test_in, exact_fn = exp["test"]
        pred = engine.predict(test_in, weights)
        exact = exact_fn()
        error = abs(pred - exact)

        print(f"  Ecuacion encontrada: f(X) = {formula}")
        print(f"  Terminos: {engine.get_term_count()} | Tiempo: {elapsed:.2f} ms")
        print(f"  Test => Pred: {pred:.5f} | Real: {exact:.5f} | Error: {error:.2e}")
        status = "[EXCELENTE]" if error < 1e-4 else "[ACEPTABLE]" if error < 1e-2 else "[REVISAR]"
        print(f"  {status}")

print("\n[OK] Demo 06 completado.\n")
