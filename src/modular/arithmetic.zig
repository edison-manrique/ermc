// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Aritmética Modular Exacta y Álgebra sobre Campos Finitos F_p
//!
//! Implementa operaciones fundamentales con prevención total de overflow mediante u128:
//! - Suma, resta, multiplicación y división modular
//! - Algoritmo Extendido de Euclides (EEA) para inverso multiplicativo en F_p
//! - Exponenciación modular binaria rápida O(log exp)
//! - Criterio de Euler y Símbolo de Legendre (a/p)
//! - Algoritmo de Tonelli-Shanks para raíces cuadradas modulares
//! - Búsqueda de raíces cúbicas de la unidad (beta^3 = 1 mod p)

const std = @import("std");

/// Suma modular: (a + b) mod p
pub fn addMod(a: u64, b: u64, p: u64) u64 {
    const sum = @as(u128, a % p) + @as(u128, b % p);
    return @intCast(sum % p);
}

/// Resta modular: (a - b) mod p
pub fn subMod(a: u64, b: u64, p: u64) u64 {
    const a_mod = a % p;
    const b_mod = b % p;
    if (a_mod >= b_mod) {
        return a_mod - b_mod;
    } else {
        return p - (b_mod - a_mod);
    }
}

/// Multiplicación modular: (a * b) mod p (sin overflow de 64 bits)
pub fn mulMod(a: u64, b: u64, p: u64) u64 {
    const prod = @as(u128, a % p) * @as(u128, b % p);
    return @intCast(prod % p);
}

/// Exponenciación modular rápida: (base^exp) mod p en O(log exp)
pub fn modPow(base: u64, exp: u64, p: u64) u64 {
    if (p == 1) return 0;
    var res: u128 = 1;
    var b: u128 = base % p;
    var e = exp;

    while (e > 0) {
        if ((e & 1) == 1) {
            res = (res * b) % p;
        }
        b = (b * b) % p;
        e >>= 1;
    }
    return @intCast(res);
}

/// Inverso multiplicativo modular a^(-1) mod p mediante Algoritmo Extendido de Euclides (EEA)
/// Retorna null si mcd(a, p) != 1
pub fn modInverse(a: u64, p: u64) ?u64 {
    if (p <= 1) return null;
    var mn0: i128 = @intCast(p);
    var mn1: i128 = @intCast(a % p);
    if (mn1 == 0) return null;

    var xy0: i128 = 0;
    var xy1: i128 = 1;

    while (mn1 != 0) {
        const q = @divTrunc(mn0, mn1);
        const rem = mn0 - q * mn1;
        mn0 = mn1;
        mn1 = rem;

        const new_xy = xy0 - q * xy1;
        xy0 = xy1;
        xy1 = new_xy;
    }

    if (mn0 > 1) return null; // No coprimos

    const p_i128: i128 = @intCast(p);
    const res = @mod(xy0, p_i128);
    const pos = if (res < 0) res + p_i128 else res;
    return @intCast(pos);
}

/// División modular: (a / b) mod p = (a * b^(-1)) mod p
pub fn divMod(a: u64, b: u64, p: u64) ?u64 {
    const inv = modInverse(b, p) orelse return null;
    return mulMod(a, inv, p);
}

/// Símbolo de Legendre (a / p) mediante el Criterio de Euler:
/// Retorna:
///   1 si a es residuo cuadrático no nulo mod p
///  -1 si a es no-residuo cuadrático mod p
///   0 si a = 0 mod p
pub fn legendreSymbol(a: u64, p: u64) i8 {
    const a_mod = a % p;
    if (a_mod == 0) return 0;
    const exp = (p - 1) / 2;
    const pow_res = modPow(a_mod, exp, p);
    if (pow_res == 1) {
        return 1;
    } else if (pow_res == p - 1) {
        return -1;
    }
    return 0;
}

/// Determina si a es residuo cuadrático en F_p (existe x tal que x^2 = a mod p)
pub fn isQuadraticResidue(a: u64, p: u64) bool {
    return legendreSymbol(a, p) == 1 or (a % p == 0);
}

/// Raíz cuadrada modular (Tonelli-Shanks / caso p = 3 mod 4)
/// Encuentra x tal que x^2 = a mod p.
/// Retorna la menor raíz positiva x <= p/2, o null si no existe.
pub fn sqrtMod(a: u64, p: u64) ?u64 {
    const a_mod = a % p;
    if (a_mod == 0) return 0;
    if (p == 2) return a_mod;
    if (legendreSymbol(a_mod, p) != 1) return null;

    // Caso común y ultrarrápido: p = 3 mod 4
    if ((p & 3) == 3) {
        const root = modPow(a_mod, (p + 1) / 4, p);
        return @min(root, p - root);
    }

    // Algoritmo general de Tonelli-Shanks para p = 1 mod 4
    // 1. Descomponer p - 1 = Q * 2^S con Q impar
    var q = p - 1;
    var s: u32 = 0;
    while ((q & 1) == 0) {
        s += 1;
        q >>= 1;
    }

    // 2. Encontrar un no-residuo cuadrático z mod p
    var z: u64 = 2;
    while (z < p) : (z += 1) {
        if (legendreSymbol(z, p) == -1) break;
    }

    var m = s;
    var c = modPow(z, q, p);
    var t = modPow(a_mod, q, p);
    var r = modPow(a_mod, (q + 1) / 2, p);

    while (t != 1) {
        // Encontrar el menor i (0 < i < m) tal que t^(2^i) = 1 mod p
        var i: u32 = 0;
        var temp = t;
        while (temp != 1 and i < m) {
            temp = mulMod(temp, temp, p);
            i += 1;
        }

        if (i == m) return null; // No converge

        const b_exp = std.math.pow(u64, 2, m - i - 1);
        const b = modPow(c, b_exp, p);
        m = i;
        c = mulMod(b, b, p);
        t = mulMod(t, c, p);
        r = mulMod(r, b, p);
    }

    return @min(r, p - r);
}

/// Encuentra una raíz cúbica no trivial de la unidad en F_p (beta^3 = 1 mod p, beta != 1)
/// Útil para el endomorfismo GLV de curvas Koblitz como secp256k1 (requiere p = 1 mod 3)
pub fn findCubeRootOfUnity(p: u64) ?u64 {
    if ((p - 1) % 3 != 0) return null; // No existen raíces cúbicas no triviales en F_p

    const exp = (p - 1) / 3;
    var g: u64 = 2;
    while (g < p) : (g += 1) {
        const beta = modPow(g, exp, p);
        if (beta != 1) {
            // Verificar beta^3 = 1 mod p
            if (mulMod(mulMod(beta, beta, p), beta, p) == 1) {
                return beta;
            }
        }
    }
    return null;
}
