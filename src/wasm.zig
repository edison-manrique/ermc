// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC WASM Entry Point
//!
//! Compila ERMC como WebAssembly (wasm32-freestanding, ReleaseFast).
//! Usa std.heap.wasm_allocator en lugar de page_allocator.
//! Todos los handles de engine se devuelven como u32 (offset en memoria lineal WASM).
//! Compatible con WebAssembly.instantiate() nativo en Bun/Node.js/Browser.

const std = @import("std");
const root = @import("ermc");

// WASM usa wasm_allocator basado en memory.grow (sin OS)
const allocator = std.heap.wasm_allocator;

// ===========================================================================
// VERSIÓN
// ===========================================================================

export fn ermc_version_wasm(out_buf: [*]u8, max_len: usize) usize {
    const ver = "0.3.0";
    const copy_len = @min(ver.len, max_len - 1);
    @memcpy(out_buf[0..copy_len], ver[0..copy_len]);
    out_buf[copy_len] = 0;
    return copy_len;
}

// ===========================================================================
// OMNI-ENGINE
// ===========================================================================

export fn ermc_engine_create(n_inputs: usize) u32 {
    const engine = allocator.create(root.OmniEngine) catch return 0;
    engine.* = root.OmniEngine.init(allocator, n_inputs) catch {
        allocator.destroy(engine);
        return 0;
    };
    const acts = [_]root.Activation{ .Identity, .Sine, .Cosine, .Square, .Cube, .ExpNeg, .Sqrt };
    engine.buildExpansionDictionary(&acts) catch {
        engine.deinit();
        allocator.destroy(engine);
        return 0;
    };
    return @intFromPtr(engine);
}

export fn ermc_engine_destroy(handle: u32) void {
    if (handle == 0) return;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
    engine.deinit();
    allocator.destroy(engine);
}

export fn ermc_engine_term_count(handle: u32) usize {
    if (handle == 0) return 0;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
    return engine.termCount();
}

export fn ermc_engine_build_dictionary(
    handle: u32,
    act_codes: [*]const u32,
    n_acts: usize,
) bool {
    if (handle == 0 or n_acts == 0) return false;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
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
    handle: u32,
    flat_inputs: [*]const f64,
    targets: [*]const f64,
    n_samples: usize,
    threshold: f64,
    out_weights: [*]f64,
) usize {
    if (handle == 0 or n_samples == 0) return 0;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
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
    handle: u32,
    input: [*]const f64,
    weights: [*]const f64,
) f64 {
    if (handle == 0) return 0.0;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
    const n_dim = engine.num_inputs;
    const n_terms = engine.termCount();
    return engine.predict(input[0..n_dim], weights[0..n_terms]);
}

export fn ermc_engine_get_formula(
    handle: u32,
    weights: [*]const f64,
    out_buf: [*]u8,
    max_len: usize,
) usize {
    if (handle == 0 or max_len == 0) return 0;
    const engine: *root.OmniEngine = @ptrFromInt(handle);
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

export fn ermc_hilbert_inner(u: [*]const f64, v: [*]const f64, n: usize) f64 {
    return root.linalg.inner(u[0..n], v[0..n]);
}

export fn ermc_hilbert_norm(v: [*]const f64, n: usize) f64 {
    return root.linalg.norm(v[0..n]);
}

export fn ermc_hilbert_distance(u: [*]const f64, v: [*]const f64, n: usize) f64 {
    return root.linalg.distance(u[0..n], v[0..n]);
}

export fn ermc_hilbert_angle(u: [*]const f64, v: [*]const f64, n: usize) f64 {
    return root.linalg.angle(u[0..n], v[0..n]);
}

// ===========================================================================
// ARITMÉTICA COMPENSADA Y OUTLIERS
// ===========================================================================

export fn ermc_precision_sum(data: [*]const f64, n: usize) f64 {
    return root.core.neumaierSum(data[0..n]);
}

export fn ermc_outliers_hampel(
    data: [*]const f64,
    n: usize,
    k_threshold: f64,
    out_mask: [*]u8,
    out_clean: [*]f64,
) usize {
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
// SVD
// ===========================================================================

export fn ermc_svd(
    matrix: [*]const f64,
    m: usize,
    n: usize,
    out_u: [*]f64,
    out_s: [*]f64,
    out_v: [*]f64,
) bool {
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

    for (0..m) |i| {
        for (0..n) |j| {
            out_u[i * n + j] = svd_res.u.get(i, j);
        }
    }
    @memcpy(out_s[0..n], svd_res.s[0..n]);
    for (0..n) |i| {
        for (0..n) |j| {
            out_v[i * n + j] = svd_res.v.get(i, j);
        }
    }

    return true;
}

// ===========================================================================
// IA DE SUCESIONES
// ===========================================================================

export fn ermc_sequence_predict_next(seq: [*]const f64, n: usize) f64 {
    if (n < 3) return 0.0;
    const seq_ai = root.SequenceAi.initExtended();
    const coefs = seq_ai.fitGaps(allocator, seq[0..n]) catch return 0.0;
    defer allocator.free(coefs);
    return seq_ai.predictNext(seq[0..n], coefs);
}

// ===========================================================================
// DMD
// ===========================================================================

export fn ermc_dmd_dominant_frequency(
    snapshots: [*]const f64,
    n_sensors: usize,
    n_snaps: usize,
    dt: f64,
) f64 {
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
// CAOS Y LORENZ
// ===========================================================================

fn lorenzOde(t: f64, state: []const f64, dstate: []f64, ctx: ?*const anyopaque) void {
    _ = t;
    _ = ctx;
    const sigma: f64 = 10.0;
    const rho: f64 = 28.0;
    const beta: f64 = 8.0 / 3.0;
    dstate[0] = sigma * (state[1] - state[0]);
    dstate[1] = state[0] * (rho - state[2]) - state[1];
    dstate[2] = state[0] * state[1] - beta * state[2];
}

export fn ermc_chaos_lorenz(
    x0: f64,
    y0: f64,
    z0: f64,
    out_lyap: *f64,
    out_horizon: *f64,
) bool {
    const init_state = [_]f64{ x0, y0, z0 };
    const res = root.solver.computeMaxLyapunovExponent(
        allocator,
        lorenzOde,
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

// ===========================================================================
// UTILIDADES DE MEMORIA WASM (necesarias para el loader TS)
// ===========================================================================

/// Aloca N bytes en la memoria WASM y devuelve el offset (u32).
/// El loader TS puede escribir/leer datos aquí antes de llamar funciones.
export fn ermc_alloc(n_bytes: usize) u32 {
    const buf = allocator.alloc(u8, n_bytes) catch return 0;
    return @intFromPtr(buf.ptr);
}

/// Libera una región previamente alojada con ermc_alloc.
export fn ermc_free(ptr: u32, n_bytes: usize) void {
    if (ptr == 0) return;
    const slice: []u8 = @as([*]u8, @ptrFromInt(ptr))[0..n_bytes];
    allocator.free(slice);
}
