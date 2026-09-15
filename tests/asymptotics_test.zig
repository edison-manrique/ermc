// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const testing = std.testing;
const ermc = @import("ermc");
const asymp = ermc.series;

test "Ramanujan Mock Theta: log-space convergence" {
    // Para t = 0.05, f(-e^-t) puede ser positivo o negativo (q es negativo)
    // El modelo asintótico aplica a ln|f(-e^-t)|
    const t = 0.05;
    const f_val = asymp.evaluateMockThetaLogSpace(t, 500);
    try testing.expect(!std.math.isNan(f_val));
    try testing.expect(!std.math.isInf(f_val));
    try testing.expect(f_val != 0.0);

    // Comparar ln|f(q)| con la asintótica teórica de Ramanujan-Watson
    const ln_f = @log(@abs(f_val));
    const asymp_pred = asymp.ramanujanWatsonAsymptotic(t);

    // En t = 0.05, la asintótica predice con alta precisión (< 5% de error relativo)
    const rel_err = @abs(ln_f - asymp_pred) / @abs(asymp_pred);
    try testing.expect(rel_err < 0.05);
}

test "Number Theory: Sieve of Eratosthenes and prime counting pi(x)" {
    const allocator = testing.allocator;

    const primes = try asymp.sievePrimes(allocator, 1000);
    defer allocator.free(primes);

    // Hay exactamente 25 primos <= 100
    const pi100 = asymp.primeCountPi(primes, 100.0);
    try testing.expectEqual(@as(usize, 25), pi100);

    // Hay exactamente 168 primos <= 1000
    const pi1000 = asymp.primeCountPi(primes, 1000.0);
    try testing.expectEqual(@as(usize, 168), pi1000);

    // El primer primo es 2, el último <= 1000 es 997
    try testing.expectEqual(@as(u64, 2), primes[0]);
    try testing.expectEqual(@as(u64, 997), primes[primes.len - 1]);
}

test "Number Theory: Logarithmic Integral Li(x) approximation" {
    // Li(100) ~ 30.1, pi(100) = 25
    const li100 = asymp.logarithmicIntegralLi(100.0);
    try testing.expect(li100 > 28.0 and li100 < 32.0);

    // Li(1000) ~ 177.6, pi(1000) = 168
    const li1000 = asymp.logarithmicIntegralLi(1000.0);
    try testing.expect(li1000 > 170.0 and li1000 < 185.0);
}
