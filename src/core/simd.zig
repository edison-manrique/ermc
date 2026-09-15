// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

pub const Vec4 = @Vector(4, f64);

/// Calcula el producto punto entre dos slices de f64 acelerado por hardware SIMD
pub fn dotProduct(a: []const f64, b: []const f64) f64 {
    std.debug.assert(a.len == b.len);
    const n = a.len;
    var sum: f64 = 0.0;
    var i: usize = 0;

    while (i + 4 <= n) : (i += 4) {
        const va: Vec4 = a[i..][0..4].*;
        const vb: Vec4 = b[i..][0..4].*;
        sum += @reduce(.Add, va * vb);
    }

    while (i < n) : (i += 1) {
        sum += a[i] * b[i];
    }

    return sum;
}

/// Suma ponderada vectorial en memoria: dest[i] += a[i] * factor
pub fn axpy(dest: []f64, a: []const f64, factor: f64) void {
    std.debug.assert(dest.len == a.len);
    const n = dest.len;
    const vfactor: Vec4 = @splat(factor);
    var i: usize = 0;

    while (i + 4 <= n) : (i += 4) {
        const vdest: Vec4 = dest[i..][0..4].*;
        const va: Vec4 = a[i..][0..4].*;
        dest[i..][0..4].* = vdest + (va * vfactor);
    }

    while (i < n) : (i += 1) {
        dest[i] += a[i] * factor;
    }
}

/// Escala los elementos de un slice in-place por un factor escalar
pub fn scale(slice: []f64, factor: f64) void {
    const n = slice.len;
    const vfactor: Vec4 = @splat(factor);
    var i: usize = 0;

    while (i + 4 <= n) : (i += 4) {
        const vs: Vec4 = slice[i..][0..4].*;
        slice[i..][0..4].* = vs * vfactor;
    }

    while (i < n) : (i += 1) {
        slice[i] *= factor;
    }
}

/// Calcula la norma euclídea L2 de un slice
pub fn normL2(slice: []const f64) f64 {
    const sumsq = dotProduct(slice, slice);
    return @sqrt(sumsq);
}
