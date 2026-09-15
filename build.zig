// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Módulo principal reutilizable de la librería (solo src/root.zig)
    const mod = b.addModule("ermc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Biblioteca compartida (.dll en Windows, .so en Linux, .dylib en macOS)
    // Para consumo FFI desde Bun / Node.js / TypeScript / Python
    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "ermc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/ffi.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ermc", .module = mod },
            },
        }),
    });
    b.installArtifact(lib);

    // Binario CLI con la suite de ejemplos modulares (examples/root.zig)
    const exe = b.addExecutable(.{
        .name = "ermc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ermc", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    // Step para correr la aplicación: `zig build run`
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Ejecutar la suite de demostración y descubrimiento de IA Matemática ERMC");
    run_step.dependOn(&run_cmd.step);

    // Step para correr los tests unitarios e integrales: `zig build test`
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/root.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "ermc", .module = mod },
            },
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Ejecutar todas las pruebas unitarias y de integración");
    test_step.dependOn(&run_unit_tests.step);
}
