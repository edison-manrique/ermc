// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    // Usar ReleaseFast por defecto para bibliotecas nativas (.dll/.so).
    // Se puede sobreescribir con: zig build -Doptimize=Debug
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

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

    // =========================================================================
    // WASM: Compilar ERMC como WebAssembly (wasm32-freestanding, ReleaseFast)
    // Uso: zig build wasm
    // Salida: zig-out/wasm/ermc.wasm
    // =========================================================================
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm_mod = b.addModule("ermc", .{
        .root_source_file = b.path("src/root.zig"),
        .target = wasm_target,
        .optimize = .ReleaseFast,
    });

    const wasm_exe = b.addExecutable(.{
        .name = "ermc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wasm.zig"),
            .target = wasm_target,
            .optimize = .ReleaseFast,
            .imports = &.{
                .{ .name = "ermc", .module = wasm_mod },
            },
        }),
    });
    // WASM freestanding: exportar todas las funciones, sin entry point OS
    wasm_exe.entry = .disabled;
    wasm_exe.rdynamic = true;

    const wasm_install = b.addInstallArtifact(wasm_exe, .{
        .dest_dir = .{ .override = .{ .custom = "wasm" } },
    });

    const wasm_step = b.step("wasm", "Compilar ERMC como WebAssembly (wasm32-freestanding, ReleaseFast)");
    wasm_step.dependOn(&wasm_install.step);
}
