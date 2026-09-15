// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Diferenciación Automática Forward mediante Números Duales
//!
//! Un número dual tiene la forma x = val + der * ε, donde ε² = 0.
//! Al evaluar cualquier función f(x + ε), el resultado es f(x) + f'(x) * ε.
//! Esto proporciona la derivada EXACTA con precisión de máquina (64 bits)
//! y CERO error de truncamiento numérico, eliminando por completo la cancelación
//! catastrófica y la inestabilidad de las diferencias finitas tradicionales.

const std = @import("std");

pub const Dual = struct {
    val: f64, // Valor de la función f(x)
    der: f64, // Derivada exacta f'(x)

    /// Crea un número dual a partir de valor y derivada
    pub fn init(val: f64, der: f64) Dual {
        return .{ .val = val, .der = der };
    }

    /// Crea una constante independiente (derivada = 0.0)
    pub fn constant(val: f64) Dual {
        return .{ .val = val, .der = 0.0 };
    }

    /// Crea una variable de diferenciación respecto a sí misma (derivada = 1.0)
    pub fn variable(val: f64) Dual {
        return .{ .val = val, .der = 1.0 };
    }

    pub fn neg(self: Dual) Dual {
        return .{ .val = -self.val, .der = -self.der };
    }

    pub fn add(self: Dual, other: Dual) Dual {
        return .{
            .val = self.val + other.val,
            .der = self.der + other.der,
        };
    }

    pub fn addScalar(self: Dual, c: f64) Dual {
        return .{
            .val = self.val + c,
            .der = self.der,
        };
    }

    pub fn sub(self: Dual, other: Dual) Dual {
        return .{
            .val = self.val - other.val,
            .der = self.der - other.der,
        };
    }

    pub fn subScalar(self: Dual, c: f64) Dual {
        return .{
            .val = self.val - c,
            .der = self.der,
        };
    }

    pub fn mul(self: Dual, other: Dual) Dual {
        // Regla del producto: (u * v)' = u' * v + u * v'
        return .{
            .val = self.val * other.val,
            .der = self.der * other.val + self.val * other.der,
        };
    }

    pub fn scale(self: Dual, factor: f64) Dual {
        return .{
            .val = self.val * factor,
            .der = self.der * factor,
        };
    }

    pub fn div(self: Dual, other: Dual) Dual {
        // Regla del cociente: (u / v)' = (u' * v - u * v') / v²
        const inv_denom = 1.0 / (other.val * other.val);
        return .{
            .val = self.val / other.val,
            .der = (self.der * other.val - self.val * other.der) * inv_denom,
        };
    }

    pub fn sin(self: Dual) Dual {
        return .{
            .val = @sin(self.val),
            .der = self.der * @cos(self.val),
        };
    }

    pub fn cos(self: Dual) Dual {
        return .{
            .val = @cos(self.val),
            .der = -self.der * @sin(self.val),
        };
    }

    pub fn exp(self: Dual) Dual {
        const e_val = @exp(self.val);
        return .{
            .val = e_val,
            .der = self.der * e_val,
        };
    }

    pub fn log(self: Dual) Dual {
        return .{
            .val = @log(self.val),
            .der = self.der / self.val,
        };
    }

    pub fn sqrt(self: Dual) Dual {
        const s = @sqrt(self.val);
        return .{
            .val = s,
            .der = self.der / (2.0 * s),
        };
    }

    pub fn pow(self: Dual, exponent: f64) Dual {
        // d/dx (u^p) = p * u^(p-1) * u'
        const val_pow = std.math.pow(f64, self.val, exponent);
        const der_pow = exponent * std.math.pow(f64, self.val, exponent - 1.0) * self.der;
        return .{
            .val = val_pow,
            .der = der_pow,
        };
    }

    pub fn tan(self: Dual) Dual {
        const t = @tan(self.val);
        // d/dx (tan u) = (1 + tan² u) * u'
        return .{
            .val = t,
            .der = self.der * (1.0 + t * t),
        };
    }

    pub fn tanh(self: Dual) Dual {
        const th = std.math.tanh(self.val);
        // d/dx (tanh u) = (1 - tanh² u) * u'
        return .{
            .val = th,
            .der = self.der * (1.0 - th * th),
        };
    }
};

/// Calcula el gradiente exacto ∇f(x) de una función multivariada f: ℝⁿ → ℝ
/// mediante diferenciación automática forward
pub fn computeGradient(
    comptime F: anytype,
    x: []const f64,
    out_grad: []f64,
) f64 {
    const n = x.len;
    std.debug.assert(out_grad.len == n);

    var f_val: f64 = 0.0;

    // Diferenciar respecto a cada variable x_i independientemente
    for (0..n) |i| {
        // Sembrar Dual(x_j, δ_ij)
        var dual_inputs: [16]Dual = undefined;
        for (0..n) |j| {
            dual_inputs[j] = Dual.init(x[j], if (i == j) 1.0 else 0.0);
        }

        const res = F(dual_inputs[0..n]);
        if (i == 0) f_val = res.val;
        out_grad[i] = res.der;
    }

    return f_val;
}
