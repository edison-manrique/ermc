// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Asintótica Analítica de Ramanujan y Distribución de Primos de Riemann
//!
//! Implementa:
//! - Evaluación estable en espacio logarítmico de la Mock Theta Function f(q) de Ramanujan (orden 3)
//! - Modelo asintótico radial de Ramanujan-Watson para q -> -1:
//!   ln|f(-e^-t)| ~ (pi^2 / 24) * (1/t) - 0.5 * ln(t) + 0.5 * ln(pi)
//! - Criba de Eratóstenes y conteo exacto de números primos pi(x)
//! - Integral logarítmica Li(x) para la cota del error de Riemann

const std = @import("std");

/// Constantes analíticas teóricas de Ramanujan
pub const RAMANUJAN_PI2_DIV_24: f64 = (std.math.pi * std.math.pi) / 24.0; // 0.4112335167...
pub const RAMANUJAN_HALF_LN_PI: f64 = 0.5 * @log(std.math.pi); // 0.5723649429...

/// Evalúa la Mock Theta Function de Ramanujan de orden 3:
/// f(q) = 1 + sum_{n=1}^inf [ (-1)^n * q^(n^2) / prod_{k=1}^n (1 + q^k)^2 ]
/// para q = -exp(-t) con t > 0 en espacio logarítmico ultraestable para prevenir desbordamientos.
pub fn evaluateMockThetaLogSpace(t: f64, max_terms: usize) f64 {
    if (t <= 0.0) return 1.0;

    var sum: f64 = 1.0;
    var sum_ln_den: f64 = 0.0;

    var n: usize = 1;
    while (n <= max_terms) : (n += 1) {
        const n_f: f64 = @floatFromInt(n);
        const q_n_sign: f64 = if (n % 2 == 0) 1.0 else -1.0;
        const q_n = q_n_sign * @exp(-t * n_f);

        // Denominador acumulado: sum 2 * ln(1 + q^k)
        const factor = 1.0 + q_n;
        if (factor <= 0.0) break;
        sum_ln_den += 2.0 * @log(factor);

        const ln_abs_num = -t * (n_f * n_f);
        const ln_abs_term = ln_abs_num - sum_ln_den;

        // Criterio de parada dinámico seguro contra ruidos de máquina
        if (ln_abs_term < -50.0) {
            const peak_estimate = 1.5707963 / @sqrt(t);
            if (n_f > peak_estimate) break;
        }

        const abs_term = @exp(ln_abs_term);
        const sign: f64 = if (n % 2 == 0) 1.0 else -1.0;
        sum += sign * abs_term;
    }

    return sum;
}

/// Predicción asintótica teórica de Ramanujan-Watson para ln|f(-e^-t)| cuando t -> 0+
pub fn ramanujanWatsonAsymptotic(t: f64) f64 {
    return RAMANUJAN_PI2_DIV_24 * (1.0 / t) - 0.5 * @log(t) + RAMANUJAN_HALF_LN_PI;
}

/// Criba de Eratóstenes para números primos hasta max_n
pub fn sievePrimes(allocator: std.mem.Allocator, max_n: usize) ![]u64 {
    if (max_n < 2) return allocator.alloc(u64, 0);

    var is_prime = try allocator.alloc(bool, max_n + 1);
    defer allocator.free(is_prime);
    @memset(is_prime, true);
    is_prime[0] = false;
    is_prime[1] = false;

    var p: usize = 2;
    while (p * p <= max_n) : (p += 1) {
        if (is_prime[p]) {
            var mult = p * p;
            while (mult <= max_n) : (mult += p) {
                is_prime[mult] = false;
            }
        }
    }

    var count: usize = 0;
    for (2..max_n + 1) |i| {
        if (is_prime[i]) count += 1;
    }

    var primes = try allocator.alloc(u64, count);
    var idx: usize = 0;
    for (2..max_n + 1) |i| {
        if (is_prime[i]) {
            primes[idx] = @intCast(i);
            idx += 1;
        }
    }

    return primes;
}

/// Función contadora de números primos pi(x) usando un vector ordenado de primos
pub fn primeCountPi(primes: []const u64, x: f64) usize {
    if (x < 2.0 or primes.len == 0) return 0;
    const x_u: u64 = if (x >= @as(f64, @floatFromInt(std.math.maxInt(u64))))
        std.math.maxInt(u64)
    else
        @intFromFloat(x);

    // Búsqueda binaria del mayor primo <= x
    var left: usize = 0;
    var right: usize = primes.len;
    while (left < right) {
        const mid = left + (right - left) / 2;
        if (primes[mid] <= x_u) {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    return left;
}

/// Aproximación numérica de la Integral Logarítmica Li(x) = int_2^x dt / ln(t) + 1.04516
pub fn logarithmicIntegralLi(x: f64) f64 {
    if (x <= 2.0) return 0.0;
    const n_steps: usize = 200;
    const a = 2.0;
    const b = x;
    const h = (b - a) / @as(f64, @floatFromInt(n_steps));

    // Regla de Simpson compuesta
    var sum: f64 = (1.0 / @log(a)) + (1.0 / @log(b));
    for (1..n_steps) |i| {
        const t = a + @as(f64, @floatFromInt(i)) * h;
        const weight: f64 = if (i % 2 == 1) 4.0 else 2.0;
        sum += weight * (1.0 / @log(t));
    }
    return (h / 3.0) * sum + 1.04516378;
}
