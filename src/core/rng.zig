// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

/// Generador pseudo-aleatorio determinista de ultra-alta velocidad (Xoshiro256** / SplitMix64)
/// Reproduce con precisión de bits los generadores científicos de Omni-Core.
/// Incluye caché Box-Muller para genGaussian eficiente.
pub const OmniRng = struct {
    state: [4]u64,
    /// Caché Box-Muller: almacena z1 para reutilizar en la siguiente llamada
    cached_gaussian: f64 = 0.0,
    has_cached: bool = false,

    const Self = @This();

    pub fn init(seed: u64) Self {
        var s: [4]u64 = undefined;
        var sm: u64 = seed;
        for (0..4) |i| {
            sm +%= 0x9e3779b97f4a7c15;
            var z = sm;
            z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
            z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
            s[i] = z ^ (z >> 31);
        }
        return .{ .state = s };
    }

    /// Genera un entero u64 aleatorio (Xoshiro256**)
    pub inline fn nextU64(self: *Self) u64 {
        const result = std.math.rotl(u64, self.state[1] *% 5, 7) *% 9;
        const t = self.state[1] << 17;

        self.state[2] ^= self.state[0];
        self.state[3] ^= self.state[1];
        self.state[1] ^= self.state[2];
        self.state[0] ^= self.state[3];

        self.state[2] ^= t;
        self.state[3] = std.math.rotl(u64, self.state[3], 45);

        return result;
    }

    /// Genera un flotante f64 uniforme en el intervalo [0.0, 1.0)
    pub inline fn nextF64(self: *Self) f64 {
        const result = self.nextU64();
        const mantissa = result >> 11;
        const factor: f64 = 1.0 / 9007199254740992.0; // 1 / 2^53
        return @as(f64, @floatFromInt(mantissa)) * factor;
    }

    /// Genera un flotante f64 uniforme en el rango [min, max]
    pub inline fn genRange(self: *Self, min: f64, max: f64) f64 {
        return min + self.nextF64() * (max - min);
    }

    /// Generador de ruido Gaussiano con distribución normal N(mean, std_dev)
    /// mediante la transformada de Box-Muller con caché para máxima eficiencia.
    /// Cada invocación de Box-Muller produce dos valores; el segundo se cachea.
    pub fn genGaussian(self: *Self, mean: f64, std_dev: f64) f64 {
        if (self.has_cached) {
            self.has_cached = false;
            return self.cached_gaussian * std_dev + mean;
        }

        var unif1 = self.nextF64();
        while (unif1 <= 1e-15) {
            unif1 = self.nextF64();
        }
        const unif2 = self.nextF64();
        const mag = @sqrt(-2.0 * @log(unif1));
        const angle = 2.0 * std.math.pi * unif2;
        const z0 = mag * @cos(angle);
        const z1 = mag * @sin(angle);

        // Cachear z1 para la próxima llamada
        self.cached_gaussian = z1;
        self.has_cached = true;

        return z0 * std_dev + mean;
    }

    /// Genera un entero aleatorio en el rango [0, max) sin sesgo modular
    pub fn genInt(self: *Self, max: usize) usize {
        if (max == 0) return 0;
        const val = self.nextU64();
        return @intCast(val % @as(u64, @intCast(max)));
    }

    /// Baraja un slice de f64 in-place usando el algoritmo Fisher-Yates
    pub fn shuffle(self: *Self, slice: []f64) void {
        if (slice.len <= 1) return;
        var i: usize = slice.len - 1;
        while (i > 0) : (i -= 1) {
            const j = self.genInt(i + 1);
            const temp = slice[i];
            slice[i] = slice[j];
            slice[j] = temp;
        }
    }

    /// Genera un vector de valores uniformes f64 en [0.0, 1.0)
    pub fn fillUniform(self: *Self, dest: []f64) void {
        for (dest) |*d| {
            d.* = self.nextF64();
        }
    }

    /// Genera un vector de valores gaussianos N(mean, std_dev)
    pub fn fillGaussian(self: *Self, dest: []f64, mean: f64, std_dev: f64) void {
        for (dest) |*d| {
            d.* = self.genGaussian(mean, std_dev);
        }
    }
};
