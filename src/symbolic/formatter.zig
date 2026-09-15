// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Reconstruye una fórmula matemática analítica limpia y legible a partir del vector de pesos.
/// Incluye supresión de coeficientes triviales (1.0, -1.0) y detección de fracciones reconocibles.
pub fn reconstructFormula(
    allocator: std.mem.Allocator,
    weights: []const f64,
    node_names: []const []const u8,
) ![]u8 {
    var parts: std.ArrayList([]const u8) = .empty;
    defer {
        for (parts.items) |p| allocator.free(p);
        parts.deinit(allocator);
    }

    for (weights, 0..) |w, i| {
        if (@abs(w) > 1e-8) {
            const name = if (i < node_names.len) node_names[i] else "unk";
            const is_const = std.mem.eql(u8, name, "C");
            const abs_w = @abs(w);

            const prefix = if (parts.items.len > 0)
                (if (w >= 0.0) " + " else " - ")
            else
                (if (w < 0.0) "-" else "");

            const term_str = blk: {
                if (is_const) {
                    // Término constante: solo imprimir el valor numérico
                    break :blk try formatCoefficient(allocator, prefix, abs_w, null);
                } else if (isApproxOne(abs_w)) {
                    // Coeficiente ≈ 1.0: omitir para estética (imprimir solo el nombre)
                    break :blk try std.fmt.allocPrint(allocator, "{s}{s}", .{ prefix, name });
                } else {
                    // Caso general: coeficiente * nombre
                    break :blk try formatCoefficient(allocator, prefix, abs_w, name);
                }
            };

            try parts.append(allocator, term_str);
        }
    }

    if (parts.items.len == 0) {
        return try allocator.dupe(u8, "0.0000");
    }

    var total_len: usize = 0;
    for (parts.items) |p| total_len += p.len;

    const result = try allocator.alloc(u8, total_len);
    var offset: usize = 0;
    for (parts.items) |p| {
        @memcpy(result[offset .. offset + p.len], p);
        offset += p.len;
    }
    return result;
}

/// Formatea un coeficiente, detectando fracciones reconocibles como (4/3), (5/3), etc.
fn formatCoefficient(
    allocator: std.mem.Allocator,
    prefix: []const u8,
    abs_w: f64,
    name: ?[]const u8,
) ![]u8 {
    // Intentar detectar fracciones simples con denominadores 2..8
    const frac_str = detectFraction(abs_w);

    if (frac_str) |frac| {
        if (name) |n| {
            return try std.fmt.allocPrint(allocator, "{s}({s})*{s}", .{ prefix, frac, n });
        } else {
            return try std.fmt.allocPrint(allocator, "{s}({s})", .{ prefix, frac });
        }
    }

    if (name) |n| {
        return try std.fmt.allocPrint(allocator, "{s}{d:.4}*{s}", .{ prefix, abs_w, n });
    } else {
        return try std.fmt.allocPrint(allocator, "{s}{d:.4}", .{ prefix, abs_w });
    }
}

/// Detecta si un valor f64 es una fracción simple p/q con q ∈ [2..8]
fn detectFraction(val: f64) ?[]const u8 {
    // Tabla de fracciones reconocibles frecuentes en física
    const known_fractions = [_]struct { num: u8, den: u8, text: []const u8, value: f64 }{
        .{ .num = 1, .den = 2, .text = "1/2", .value = 0.5 },
        .{ .num = 1, .den = 3, .text = "1/3", .value = 1.0 / 3.0 },
        .{ .num = 2, .den = 3, .text = "2/3", .value = 2.0 / 3.0 },
        .{ .num = 4, .den = 3, .text = "4/3", .value = 4.0 / 3.0 },
        .{ .num = 5, .den = 3, .text = "5/3", .value = 5.0 / 3.0 },
        .{ .num = 7, .den = 3, .text = "7/3", .value = 7.0 / 3.0 },
        .{ .num = 8, .den = 3, .text = "8/3", .value = 8.0 / 3.0 },
        .{ .num = 1, .den = 4, .text = "1/4", .value = 0.25 },
        .{ .num = 3, .den = 4, .text = "3/4", .value = 0.75 },
        .{ .num = 1, .den = 5, .text = "1/5", .value = 0.2 },
        .{ .num = 2, .den = 5, .text = "2/5", .value = 0.4 },
        .{ .num = 3, .den = 5, .text = "3/5", .value = 0.6 },
        .{ .num = 4, .den = 5, .text = "4/5", .value = 0.8 },
        .{ .num = 1, .den = 6, .text = "1/6", .value = 1.0 / 6.0 },
        .{ .num = 5, .den = 6, .text = "5/6", .value = 5.0 / 6.0 },
        .{ .num = 1, .den = 7, .text = "1/7", .value = 1.0 / 7.0 },
        .{ .num = 1, .den = 8, .text = "1/8", .value = 0.125 },
        .{ .num = 3, .den = 8, .text = "3/8", .value = 0.375 },
        .{ .num = 5, .den = 8, .text = "5/8", .value = 0.625 },
        .{ .num = 7, .den = 8, .text = "7/8", .value = 0.875 },
    };

    for (known_fractions) |frac| {
        if (@abs(val - frac.value) < 1e-6) {
            return frac.text;
        }
    }
    return null;
}

/// Verifica si un valor es aproximadamente 1.0 (para suprimir coeficientes triviales)
fn isApproxOne(val: f64) bool {
    return @abs(val - 1.0) < 1e-6;
}

/// Genera la ecuación matemática completa f(X) = ... en memoria
pub fn formatEquation(
    allocator: std.mem.Allocator,
    weights: []const f64,
    node_names: []const []const u8,
) ![]u8 {
    const body = try reconstructFormula(allocator, weights, node_names);
    defer allocator.free(body);
    return try std.fmt.allocPrint(allocator, "f(X) = {s}", .{body});
}
