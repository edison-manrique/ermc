// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const ermc = @import("ermc");

/// [EJEMPLO 14] MOCK THETA DE RAMANUJAN, DISTRIBUCIÓN DE PRIMOS Y ESTIMACIÓN DE RIEMANN
pub fn run(allocator: std.mem.Allocator, io: anytype) !void {
    std.debug.print("-------------------------------------------------------------------------\n", .{});
    std.debug.print(" [EJEMPLO 14] MOCK THETA DE RAMANUJAN & DISTRIBUCIÓN DE PRIMOS\n", .{});
    std.debug.print(" >> f(q) Ramanujan-Watson, Criba de Eratóstenes y Li(x) de Riemann\n", .{});
    std.debug.print("-------------------------------------------------------------------------\n", .{});

    const start = std.Io.Clock.awake.now(io);

    // Mock Theta: convergencia del modelo asintótico de Watson
    const t_vals = [_]f64{ 0.5, 0.1, 0.05, 0.02 };
    std.debug.print("  >> ln|f(-e^{{-t}})| vs Asintótica Watson [π²/(24t) - ½·ln(t) + ½·ln(π)]:\n", .{});
    for (t_vals) |t| {
        const f_val = ermc.series.evaluateMockThetaLogSpace(t, 800);
        const ln_f = @log(@abs(f_val));
        const watson = ermc.series.ramanujanWatsonAsymptotic(t);
        const err_pct = @abs(ln_f - watson) / @abs(watson) * 100.0;
        std.debug.print("     t={d:.2}: ln|f|={d:.4}, Watson={d:.4}, err={d:.2}%\n", .{ t, ln_f, watson, err_pct });
    }

    // Criba de Eratóstenes y conteo de primos
    const max_n: usize = 10000;
    const primes = try ermc.series.sievePrimes(allocator, max_n);
    defer allocator.free(primes);

    std.debug.print("  >> Criba de Eratóstenes hasta {d}: {d} primos\n", .{ max_n, primes.len });
    std.debug.print("  >> Comparación π(x) exacto vs Li(x) de Riemann:\n", .{});

    const x_vals = [_]f64{ 100, 1000, 5000, 10000 };
    for (x_vals) |x| {
        const pi_x = ermc.series.primeCountPi(primes, x);
        const li_x = ermc.series.logarithmicIntegralLi(x);
        const err_pct = @abs(li_x - @as(f64, @floatFromInt(pi_x))) / @as(f64, @floatFromInt(pi_x)) * 100.0;
        std.debug.print("     π({d:.0}) = {d}, Li({d:.0}) = {d:.2}, err = {d:.2}%\n", .{ x, pi_x, x, li_x, err_pct });
    }

    // Gaps de primos en región [1000, 2000]
    var max_gap: u64 = 0;
    var sum_gap: u64 = 0;
    var gap_count: usize = 0;
    for (0..primes.len - 1) |i| {
        if (primes[i] >= 1000 and primes[i] <= 2000) {
            const gap = primes[i + 1] - primes[i];
            if (gap > max_gap) max_gap = gap;
            sum_gap += gap;
            gap_count += 1;
        }
    }
    const avg_gap = if (gap_count > 0)
        @as(f64, @floatFromInt(sum_gap)) / @as(f64, @floatFromInt(gap_count))
    else
        0.0;
    const cramer_pred = @log(1000.0); // ln(x) ~ gap promedio (conjetura de Cramér)

    const dur = start.untilNow(io, .awake);
    const elapsed_ms = @as(f64, @floatFromInt(dur.toNanoseconds())) / 1_000_000.0;

    std.debug.print("  >> Gaps de primos en [1000,2000]: max={d}, promedio={d:.2}, Cramér ln(1000)={d:.2}\n", .{ max_gap, avg_gap, cramer_pred });
    std.debug.print("  >> Li(2) = {d:.6} (offset de Ramanujan-Soldner ≈ 1.04516)\n", .{ermc.series.logarithmicIntegralLi(2.0)});
    std.debug.print(" > Tiempo análisis teórico Ramanujan-Riemann: {d:.2} ms\n\n", .{elapsed_ms});
}
