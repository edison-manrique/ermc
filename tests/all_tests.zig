// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! all_tests.zig (Wrapper compatible que delega a tests/root.zig)
const std = @import("std");

test {
    _ = @import("root.zig");
}
