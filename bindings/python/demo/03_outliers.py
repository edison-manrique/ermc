# Copyright (c) 2026 Edison Manrique Chocce
# Todos los derechos reservados.
# Licencia Dual: AGPL-3.0 | Comercial según LICENSE.
"""
demo/03_outliers.py — Detección Robusta de Outliers (Hampel)
Aplica el identificador de Hampel a señales reales con perturbaciones.
"""
import sys
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import math
sys.path.insert(0, "..")
from ermc import Outliers

print("=" * 60)
print("  ERMC | Demo 03: Deteccion Robusta de Outliers (Hampel)")
print("=" * 60)

# --- Experimento 1: Señal sinusoidal con spikes cósmicos ---
print("\n[1] Senal sinusoidal con spikes cosmicos (1e100):")
n = 20
signal = [math.sin(2 * math.pi * k / n) for k in range(n)]
signal[5] = 1e100    # spike positivo
signal[13] = -1e100  # spike negativo
res = Outliers.detect_hampel(signal, 3.0)
print(f"  Outliers detectados: {res.outliers_count} de {n}")
print(f"  Posiciones: {[i for i, b in enumerate(res.is_outlier) if b]}")
print(f"  Datos limpios (pos 4-7): {[f'{x:.4f}' for x in res.clean_data[4:8]]}")

# --- Experimento 2: Señal de temperatura con mediciones corruptas ---
print("\n[2] Temperatura diaria (grados C) con sensores defectuosos:")
temps = [22.1, 22.5, 23.0, 22.8, 999.0, 22.9, 23.1, -200.0, 22.7, 23.2,
         22.6, 23.0, 22.4, 22.8, 23.1, 22.3, 22.9, 23.3, 22.5, 22.7]
res2 = Outliers.detect_hampel(temps, 2.5)
print(f"  Outliers detectados: {res2.outliers_count}")
print(f"  Posiciones corruptas: {[i for i, b in enumerate(res2.is_outlier) if b]}")
print(f"  Media limpia: {sum(res2.clean_data) / len(res2.clean_data):.2f} C")

# --- Experimento 3: ECG sintético con artefactos de movimiento ---
print("\n[3] ECG sintetico (50 muestras) con 3 artefactos:")
ecg = [math.sin(2 * math.pi * k / 8) * math.exp(-0.05 * k) for k in range(50)]
ecg[10] = 50.0   # artefacto muscular
ecg[25] = -40.0  # movimiento del electrodo
ecg[40] = 30.0   # interferencia eléctrica
res3 = Outliers.detect_hampel(ecg, 3.0)
print(f"  Artefactos detectados: {res3.outliers_count} de 50")
print(f"  Posiciones: {[i for i, b in enumerate(res3.is_outlier) if b]}")
snr_before = max(abs(x) for x in ecg) / (sum(abs(x) for x in ecg) / len(ecg))
snr_after = max(abs(x) for x in res3.clean_data) / (sum(abs(x) for x in res3.clean_data) / len(res3.clean_data))
print(f"  Peak-to-mean ANTES:  {snr_before:.2f}x")
print(f"  Peak-to-mean DESPUES:{snr_after:.2f}x  (reducido = señal mas limpia)")

print("\n[OK] Demo 03 completado.\n")
