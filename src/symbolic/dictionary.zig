// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const types = @import("../core/types.zig");
const Activation = types.Activation;
const activation = @import("activation.zig");

pub const ExpansionDictionary = struct {
    num_inputs: usize,
    acts: std.ArrayList(Activation),
    values: std.ArrayList(f64),
    offsets: std.ArrayList(usize),
    indices: std.ArrayList(usize),
    weights: std.ArrayList(f64),
    node_names: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, num_inputs: usize) !Self {
        var self = Self{
            .num_inputs = num_inputs,
            .acts = .empty,
            .values = .empty,
            .offsets = .empty,
            .indices = .empty,
            .weights = .empty,
            .node_names = .empty,
            .allocator = allocator,
        };

        // 1. Registrar nodos de entrada x0, x1, ...
        for (0..num_inputs) |i| {
            try self.acts.append(allocator, .Identity);
            try self.values.append(allocator, 0.0);
            const name = try std.fmt.allocPrint(allocator, "x{d}", .{i});
            try self.node_names.append(allocator, name);
        }

        // 2. Registrar nodo constante Bias "C" (siempre vale 1.0)
        try self.acts.append(allocator, .Identity);
        try self.values.append(allocator, 1.0);
        const c_name = try allocator.dupe(u8, "C");
        try self.node_names.append(allocator, c_name);

        return self;
    }

    pub inline fn termCount(self: *const Self) usize {
        return self.acts.items.len;
    }

    pub fn deinit(self: *Self) void {
        for (self.node_names.items) |name| {
            self.allocator.free(name);
        }
        self.node_names.deinit(self.allocator);
        self.acts.deinit(self.allocator);
        self.values.deinit(self.allocator);
        self.offsets.deinit(self.allocator);
        self.indices.deinit(self.allocator);
        self.weights.deinit(self.allocator);
    }

    fn clearExpanded(self: *Self) void {
        const base_len = self.num_inputs + 1;
        while (self.node_names.items.len > base_len) {
            const popped_name = self.node_names.pop();
            if (popped_name) |p| self.allocator.free(p);
        }
        while (self.acts.items.len > base_len) {
            _ = self.acts.pop();
        }
        while (self.values.items.len > base_len) {
            _ = self.values.pop();
        }
        self.offsets.clearRetainingCapacity();
        self.indices.clearRetainingCapacity();
        self.weights.clearRetainingCapacity();
    }

    /// Construye la biblioteca topológica CSR expandiendo activaciones univariadas e interacciones bilineales
    /// Utiliza optimización de máscara de bits u64 (Bitmask Origin Tracking) y orden canónico de operandos de v6
    pub fn buildExpansion(self: *Self, activations: []const Activation) !void {
        try self.buildExpansionAdvanced(activations, true, 2);
    }

    /// Versión avanzada configurable de buildExpansion
    pub fn buildExpansionAdvanced(
        self: *Self,
        activations: []const Activation,
        include_interactions: bool,
        max_interaction_level: usize,
    ) !void {
        self.clearExpanded();

        for (0..self.num_inputs) |i| {
            self.values.items[i] = 0.0;
        }
        self.values.items[self.num_inputs] = 1.0;

        // Buffers dinámicos temporales para rastreo bitmask y orden canónico (v6 ultra)
        var sources: std.ArrayList(u64) = .empty;
        defer sources.deinit(self.allocator);

        var first_operand: std.ArrayList(usize) = .empty;
        defer first_operand.deinit(self.allocator);

        for (0..self.num_inputs) |i| {
            const mask: u64 = if (i < 64) (@as(u64, 1) << @intCast(i)) else 0;
            try sources.append(self.allocator, mask);
            try first_operand.append(self.allocator, i);
        }
        // Constante C no tiene fuentes
        try sources.append(self.allocator, 0);
        try first_operand.append(self.allocator, self.num_inputs);

        // Offsets iniciales para variables de entrada y constante
        for (0..self.num_inputs + 1) |_| {
            try self.offsets.append(self.allocator, 0);
        }

        var current_offset: usize = 0;

        // 1. Expansiones univariadas sobre las variables de entrada
        for (activations) |act| {
            if (act == .Identity or act == .Interaction) continue;

            for (0..self.num_inputs) |i| {
                try self.acts.append(self.allocator, act);
                try self.values.append(self.allocator, 0.0);

                const mask: u64 = if (i < 64) (@as(u64, 1) << @intCast(i)) else 0;
                try sources.append(self.allocator, mask);
                try first_operand.append(self.allocator, self.acts.items.len - 1);

                try self.offsets.append(self.allocator, current_offset);
                try self.indices.append(self.allocator, i);
                try self.weights.append(self.allocator, 1.0);
                current_offset += 1;

                const base_name = self.node_names.items[i];
                const expr = switch (act) {
                    .Identity => try std.fmt.allocPrint(self.allocator, "{s}", .{base_name}),
                    .Sine => try std.fmt.allocPrint(self.allocator, "sin({s})", .{base_name}),
                    .Cosine => try std.fmt.allocPrint(self.allocator, "cos({s})", .{base_name}),
                    .Square => try std.fmt.allocPrint(self.allocator, "{s}^2", .{base_name}),
                    .Cube => try std.fmt.allocPrint(self.allocator, "{s}^3", .{base_name}),
                    .Exp => try std.fmt.allocPrint(self.allocator, "exp({s})", .{base_name}),
                    .ExpNeg => try std.fmt.allocPrint(self.allocator, "exp(-{s})", .{base_name}),
                    .Sqrt => try std.fmt.allocPrint(self.allocator, "sqrt({s})", .{base_name}),
                    .InverseSquare => try std.fmt.allocPrint(self.allocator, "1/({s}^2)", .{base_name}),
                    .Inv => try std.fmt.allocPrint(self.allocator, "1/{s}", .{base_name}),
                    .Ln => try std.fmt.allocPrint(self.allocator, "ln({s})", .{base_name}),
                    .Tanh => try std.fmt.allocPrint(self.allocator, "tanh({s})", .{base_name}),
                    .Interaction => unreachable,
                };
                try self.node_names.append(self.allocator, expr);
            }
        }
        const end_univariates = self.acts.items.len;

        // 2. Interacciones bilineales de Nivel 1 (O(1) Bitwise check)
        if (include_interactions) {
            const start_level1 = self.acts.items.len;
            var i: usize = 0;
            while (i < end_univariates) : (i += 1) {
                if (i == self.num_inputs) continue; // Saltear constante

                var j: usize = i + 1;
                while (j < end_univariates) : (j += 1) {
                    if (j == self.num_inputs) continue;

                    // O(1) Bitwise Disjoint Check: si no comparten bits, provienen de variables distintas
                    if ((sources.items[i] & sources.items[j]) == 0) {
                        try self.acts.append(self.allocator, .Interaction);
                        try self.values.append(self.allocator, 0.0);

                        try sources.append(self.allocator, sources.items[i] | sources.items[j]);
                        try first_operand.append(self.allocator, i);

                        try self.offsets.append(self.allocator, current_offset);
                        try self.indices.append(self.allocator, i);
                        try self.indices.append(self.allocator, j);
                        current_offset += 2;

                        const expr = try std.fmt.allocPrint(
                            self.allocator,
                            "{s}*{s}",
                            .{ self.node_names.items[i], self.node_names.items[j] },
                        );
                        try self.node_names.append(self.allocator, expr);
                    }
                }
            }
            const end_level1 = self.acts.items.len;

            // 3. Interacciones bilineales de Nivel 2 con Orden Canónico (evita duplicados conmutativos)
            if (max_interaction_level >= 2) {
                i = 0;
                while (i < end_univariates) : (i += 1) {
                    if (i == self.num_inputs) continue;

                    var j: usize = start_level1;
                    while (j < end_level1) : (j += 1) {
                        // Verificación de orden canónico: i < first_operand[j]
                        if ((sources.items[i] & sources.items[j]) == 0 and i < first_operand.items[j]) {
                            try self.acts.append(self.allocator, .Interaction);
                            try self.values.append(self.allocator, 0.0);

                            try sources.append(self.allocator, sources.items[i] | sources.items[j]);
                            try first_operand.append(self.allocator, i);

                            try self.offsets.append(self.allocator, current_offset);
                            try self.indices.append(self.allocator, i);
                            try self.indices.append(self.allocator, j);
                            current_offset += 2;

                            const expr = try std.fmt.allocPrint(
                                self.allocator,
                                "{s}*{s}",
                                .{ self.node_names.items[i], self.node_names.items[j] },
                            );
                            try self.node_names.append(self.allocator, expr);
                        }
                    }
                }
            }
        }

        try self.offsets.append(self.allocator, current_offset);
    }

    /// Evaluación forward ultra-rápida de todos los nodos del grafo topológico
    pub inline fn forward(self: *Self, inputs: []const f64) void {
        const copy_count = @min(self.num_inputs, inputs.len);
        for (0..copy_count) |i| {
            self.values.items[i] = inputs[i];
        }
        self.values.items[self.num_inputs] = 1.0;

        const total_nodes = self.acts.items.len;
        var i: usize = self.num_inputs + 1;
        while (i < total_nodes) : (i += 1) {
            const start = self.offsets.items[i];
            const act = self.acts.items[i];

            if (act == .Interaction) {
                const src_a = self.indices.items[start];
                const src_b = self.indices.items[start + 1];
                self.values.items[i] = self.values.items[src_a] * self.values.items[src_b];
            } else {
                const src_idx = self.indices.items[start];
                const input_val = self.values.items[src_idx];
                self.values.items[i] = activation.evaluateUnary(act, input_val);
            }
        }
    }
};
