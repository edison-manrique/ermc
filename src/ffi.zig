// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC FFI (Foreign Function Interface) C-ABI Wrapper
//!
//! Permite que ERMC sea compilado como una biblioteca compartida (.dll en Windows,
//! .so en Linux, .dylib en macOS) para ser invocada directamente mediante FFI
//! desde Bun / Node.js / Deno / TypeScript o Python con cero sobrecosto.

const std = @import("std");
const root = @import("root.zig");

const allocator = std.heap.page_allocator;

// ===========================================================================
// INFORMACIÓN Y VERSIÓN
// ===========================================================================

export fn ermc_version() callconv(.c) [*:0]const u8 {
    return "0.3.0";
}

// ===========================================================================
// OMNI-ENGINE: REGRESIÓN SIMBÓLICA Y DESCUBRIMIENTO DE LEYES
// ===========================================================================

export fn ermc_engine_create(n_inputs: usize) callconv(.c) ?*anyopaque {
    const engine = allocator.create(root.OmniEngine) catch return null;
    engine.* = root.OmniEngine.init(allocator, n_inputs) catch {
        allocator.destroy(engine);
        return null;
    };
    // Diccionario estándar amplio
    const acts = [_]root.Activation{ .Identity, .Sine, .Cosine, .Square, .Cube, .ExpNeg, .Sqrt };
    engine.buildExpansionDictionary(&acts) catch {
        engine.deinit();
        allocator.destroy(engine);
        return null;
    };
    return @ptrCast(engine);
}

export fn ermc_engine_destroy(handle: ?*anyopaque) callconv(.c) void {
    if (handle) |h| {
        const engine: *root.OmniEngine = @ptrCast(@alignCast(h));
        engine.deinit();
        allocator.destroy(engine);
    }
}

export fn ermc_engine_term_count(handle: ?*anyopaque) callconv(.c) usize {
    if (handle == null) return 0;
    const engine: *root.OmniEngine = @ptrCast(@alignCast(handle.?));
    return engine.termCount();
}

export fn ermc_engine_build_dictionary(
    handle: ?*anyopaque,
    act_codes: [*]const u32,
    n_acts: usize,
) callconv(.c) bool {
    if (handle == null or n_acts == 0) return false;
    const engine: *root.OmniEngine = @ptrCast(@alignCast(handle.?));
    var acts = allocator.alloc(root.Activation, n_acts) catch return false;
    defer allocator.free(acts);

    for (0..n_acts) |i| {
        const code = act_codes[i];
        if (code <= @intFromEnum(root.Activation.Interaction)) {
            acts[i] = @enumFromInt(code);
        } else {
            acts[i] = .Identity;
        }
    }
    engine.buildExpansionDictionary(acts) catch return false;
    return true;
}

export fn ermc_engine_fit(
    handle: ?*anyopaque,
    flat_inputs: [*]const f64,
    targets: [*]const f64,
    n_samples: usize,
    threshold: f64,
    out_weights: [*]f64,
) callconv(.c) usize {
    if (handle == null or n_samples == 0) return 0;
    const engine: *root.OmniEngine = @ptrCast(@alignCast(handle.?));
    const n_dim = engine.num_inputs;

    var dataset = allocator.alloc(root.Sample, n_samples) catch return 0;
    defer allocator.free(dataset);

    for (0..n_samples) |i| {
        dataset[i] = .{
            .inputs = flat_inputs[i * n_dim .. (i + 1) * n_dim],
            .target = targets[i],
        };
    }

    const weights = engine.solveAnalytical(dataset, threshold) catch return 0;
    defer allocator.free(weights);

    const n_terms = weights.len;
    @memcpy(out_weights[0..n_terms], weights);
    return n_terms;
}

export fn ermc_engine_predict(
    handle: ?*anyopaque,
    input: [*]const f64,
    weights: [*]const f64,
) callconv(.c) f64 {
    if (handle == null) return 0.0;
    const engine: *root.OmniEngine = @ptrCast(@alignCast(handle.?));
    const n_dim = engine.num_inputs;
    const n_terms = engine.termCount();
    return engine.predict(input[0..n_dim], weights[0..n_terms]);
}

export fn ermc_engine_get_formula(
    handle: ?*anyopaque,
    weights: [*]const f64,
    out_buf: [*]u8,
    max_len: usize,
) callconv(.c) usize {
    if (handle == null or max_len == 0) return 0;
    const engine: *root.OmniEngine = @ptrCast(@alignCast(handle.?));
    const n_terms = engine.termCount();

    const formula = engine.getReconstructedFormula(weights[0..n_terms]) catch return 0;
    defer allocator.free(formula);

    const copy_len = @min(formula.len, max_len - 1);
    @memcpy(out_buf[0..copy_len], formula[0..copy_len]);
    out_buf[copy_len] = 0;
    return copy_len;
}

// ===========================================================================
// ESPACIOS DE HILBERT
// ===========================================================================

export fn ermc_hilbert_inner(u: [*]const f64, v: [*]const f64, n: usize) callconv(.c) f64 {
    return root.linalg.inner(u[0..n], v[0..n]);
}

export fn ermc_hilbert_norm(v: [*]const f64, n: usize) callconv(.c) f64 {
    return root.linalg.norm(v[0..n]);
}

export fn ermc_hilbert_distance(u: [*]const f64, v: [*]const f64, n: usize) callconv(.c) f64 {
    return root.linalg.distance(u[0..n], v[0..n]);
}

export fn ermc_hilbert_angle(u: [*]const f64, v: [*]const f64, n: usize) callconv(.c) f64 {
    return root.linalg.angle(u[0..n], v[0..n]);
}

// ===========================================================================
// ARITMÉTICA COMPENSADA Y OUTLIERS
// ===========================================================================

export fn ermc_precision_sum(data: [*]const f64, n: usize) callconv(.c) f64 {
    return root.core.neumaierSum(data[0..n]);
}

export fn ermc_precision_mean_var(
    data: [*]const f64,
    n: usize,
    out_mean: *f64,
    out_var: *f64,
) callconv(.c) void {
    const stats = root.core.compensatedMeanVar(data[0..n]);
    out_mean.* = stats.mean;
    out_var.* = stats.variance;
}

export fn ermc_outliers_hampel(
    data: [*]const f64,
    n: usize,
    k_threshold: f64,
    out_mask: [*]u8,   // 1 si outlier, 0 si limpio
    out_clean: [*]f64, // Datos con outliers imputados
) callconv(.c) usize {
    if (n == 0) return 0;
    var res = root.stats.detectOutliersHampel(allocator, data[0..n], k_threshold) catch return 0;
    defer res.deinit();

    for (0..n) |i| {
        out_mask[i] = if (res.is_outlier[i]) 1 else 0;
        out_clean[i] = res.clean_data[i];
    }
    return res.n_outliers;
}

// ===========================================================================
// SVD: DESCOMPOSICIÓN EN VALORES SINGULARES
// ===========================================================================

export fn ermc_svd(
    matrix: [*]const f64,
    m: usize,
    n: usize,
    out_u: [*]f64, // m × n
    out_s: [*]f64, // n
    out_v: [*]f64, // n × n
) callconv(.c) bool {
    if (m < n or n == 0) return false;

    var a = root.DenseMatrix.init(allocator, m, n) catch return false;
    defer a.deinit();

    for (0..m) |i| {
        for (0..n) |j| {
            a.set(i, j, matrix[i * n + j]);
        }
    }

    var svd_res = root.linalg.computeSvd(allocator, a, 100, 1e-12) catch return false;
    defer svd_res.deinit();

    // Copiar U (m × n)
    for (0..m) |i| {
        for (0..n) |j| {
            out_u[i * n + j] = svd_res.u.get(i, j);
        }
    }
    // Copiar S (n)
    @memcpy(out_s[0..n], svd_res.s[0..n]);
    // Copiar V (n × n)
    for (0..n) |i| {
        for (0..n) |j| {
            out_v[i * n + j] = svd_res.v.get(i, j);
        }
    }

    return true;
}

// ===========================================================================
// IA DE SUCESIONES MATEMÁTICAS
// ===========================================================================

export fn ermc_sequence_predict_next(seq: [*]const f64, n: usize) callconv(.c) f64 {
    if (n < 3) return 0.0;
    const seq_ai = root.SequenceAi.initExtended();
    const coefs = seq_ai.fitGaps(allocator, seq[0..n]) catch return 0.0;
    defer allocator.free(coefs);
    return seq_ai.predictNext(seq[0..n], coefs);
}

// ===========================================================================
// DYNAMIC MODE DECOMPOSITION (DMD)
// ===========================================================================

export fn ermc_dmd_dominant_frequency(
    snapshots: [*]const f64,
    n_sensors: usize,
    n_snaps: usize,
    dt: f64,
) callconv(.c) f64 {
    if (n_sensors == 0 or n_snaps < 3 or dt <= 0.0) return 0.0;

    var mat = root.DenseMatrix.init(allocator, n_sensors, n_snaps) catch return 0.0;
    defer mat.deinit();

    for (0..n_sensors) |i| {
        for (0..n_snaps) |j| {
            mat.set(i, j, snapshots[i * n_snaps + j]);
        }
    }

    var dmd_res = root.solver.computeDmd(allocator, mat, dt, 2) catch return 0.0;
    defer dmd_res.deinit();

    if (dmd_res.modes.len > 0) {
        return @abs(dmd_res.modes[0].frequency_rad_s);
    }
    return 0.0;
}

// ===========================================================================
// DINÁMICA NO LINEAL Y CAOS (LORENZ 63)
// ===========================================================================

fn lorenzOdeFfi(t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void {
    _ = t;
    _ = ctx;
    const sigma: f64 = 10.0;
    const rho: f64 = 28.0;
    const beta: f64 = 8.0 / 3.0;

    const x = state[0];
    const y = state[1];
    const z = state[2];

    dstate[0] = sigma * (y - x);
    dstate[1] = x * (rho - z) - y;
    dstate[2] = x * y - beta * z;
}

export fn ermc_chaos_lorenz(
    x0: f64,
    y0: f64,
    z0: f64,
    out_lyap: *f64,
    out_horizon: *f64,
) callconv(.c) bool {
    const init_state = [_]f64{ x0, y0, z0 };
    const res = root.solver.computeMaxLyapunovExponent(
        allocator,
        lorenzOdeFfi,
        &init_state,
        1e-8,
        0.05,
        250,
        0.005,
    ) catch return false;

    out_lyap.* = res.lyapunov_exponent;
    out_horizon.* = res.lyapunov_time;
    return true;
}
