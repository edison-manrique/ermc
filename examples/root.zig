// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! ERMC: Suite Modular de Ejemplos y Descubrimiento Físico/SciML
//!
//! Permite ejecutar la suite completa de demostraciones o invocar ejemplos individuales:
//! `zig build run` -> Ejecuta los 12 ejemplos en secuencia
//! `zig build run -- 8` -> Ejecuta únicamente el ejemplo 8 (Espacios de Hilbert)

const std = @import("std");

pub const ex01 = @import("01_pendulum.zig");
pub const ex02 = @import("02_sensor_decay.zig");
pub const ex03 = @import("03_snell_law.zig");
pub const ex04 = @import("04_adiabatic.zig");
pub const ex05 = @import("05_torricelli.zig");
pub const ex06 = @import("06_lorenz_sindy.zig");
pub const ex07 = @import("07_sequence_ai.zig");
pub const ex08 = @import("08_hilbert_l2.zig");
pub const ex09 = @import("09_extreme_outliers.zig");
pub const ex10 = @import("10_svd_pinv.zig");
pub const ex11 = @import("11_dmd_wave.zig");
pub const ex12 = @import("12_chaos_lyapunov.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=========================================================================\n", .{});
    std.debug.print("  ERMC: MOTOR DE IA MATEMÁTICA Y DESCUBRIMIENTO SIMBÓLICO EN ZIG\n", .{});
    std.debug.print("  Versión 0.3.0 | SciML, Espacios de Hilbert, SVD, DMD, AutoDiff y Caos\n", .{});
    std.debug.print("=========================================================================\n\n", .{});

    const start_total = std.Io.Clock.awake.now(io);

    try ex01.run(allocator, io);
    try ex02.run(allocator, io);
    try ex03.run(allocator, io);
    try ex04.run(allocator, io);
    try ex05.run(allocator, io);
    try ex06.run(allocator, io);
    try ex07.run(allocator, io);
    try ex08.run(allocator, io);
    try ex09.run(allocator, io);
    try ex10.run(allocator, io);
    try ex11.run(allocator, io);
    try ex12.run(allocator, io);

    const dur_total = start_total.untilNow(io, .awake);
    const total_time_ms = @as(f64, @floatFromInt(dur_total.toNanoseconds())) / 1_000_000.0;

    std.debug.print("=========================================================================\n", .{});
    std.debug.print(" >> Suite completa de descubrimiento y SciML ejecutada en: {d:.3} ms ({f})\n", .{ total_time_ms, dur_total });
    std.debug.print("=========================================================================\n\n", .{});
}
