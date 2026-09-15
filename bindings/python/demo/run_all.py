# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/run_all.py — Ejecutor de todas las demos modulares de ERMC (Python)
Uso: python run_all.py            (ejecuta todo)
     python run_all.py 01 06      (ejecuta sólo las demos indicadas)
"""
import sys
import os
import subprocess
import time

if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

DEMO_DIR = os.path.dirname(os.path.abspath(__file__))

DEMOS = [
    ("01_hilbert.py",  "Espacios de Hilbert y Ortogonalidad"),
    ("02_precision.py","Aritmetica Compensada (Neumaier)"),
    ("03_outliers.py", "Deteccion Robusta de Outliers"),
    ("04_sequence.py", "IA de Sucesiones Matematicas"),
    ("05_svd.py",      "SVD - Valores Singulares"),
    ("06_engine.py",   "OmniEngine - Descubrimiento de Leyes"),
    ("07_dmd.py",      "DMD - Modos Dinamicos"),
    ("08_chaos.py",    "Dinamica de Caos y Lyapunov"),
]

# Filtrar si se pasan IDs por argumento
selected = sys.argv[1:] if len(sys.argv) > 1 else None

print("=" * 65)
print("  ERMC | Suite de Demos Modulares Python")
print(f"  Ejecutando {len(DEMOS) if not selected else len(selected)} de {len(DEMOS)} demos")
print("=" * 65 + "\n")

results = []
for fname, title in DEMOS:
    demo_id = fname[:2]
    if selected and demo_id not in selected:
        continue

    print(f">>> [{demo_id}] {title}")
    print("-" * 65)

    path = os.path.join(DEMO_DIR, fname)
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.join(DEMO_DIR, "..")

    t0 = time.perf_counter()
    proc = subprocess.run(
        [sys.executable, path],
        env=env,
        capture_output=False,
    )
    elapsed = (time.perf_counter() - t0) * 1000
    ok = proc.returncode == 0
    results.append((demo_id, title, ok, elapsed))
    print(f"\n{'[PASS]' if ok else '[FAIL]'} {title} ({elapsed:.0f} ms)\n")

print("=" * 65)
print("  RESUMEN FINAL")
print("=" * 65)
for did, title, ok, ms in results:
    status = "PASS" if ok else "FAIL"
    print(f"  [{status}] {did}: {title:<40} {ms:>6.0f} ms")

total = len(results)
passed = sum(1 for _, _, ok, _ in results if ok)
print(f"\n  {passed}/{total} demos pasadas exitosamente.")
print("=" * 65)
