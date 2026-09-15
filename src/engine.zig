// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

const std = @import("std");
const types = @import("core/types.zig");
const Activation = types.Activation;
const Sample = types.Sample;
const SolveOptions = types.SolveOptions;
const dictionary = @import("symbolic/dictionary.zig");
const stlsq = @import("solver/stlsq.zig");
const dynamical = @import("solver/dynamical.zig");
const formatter = @import("symbolic/formatter.zig");
const metrics = @import("solver/metrics.zig");

/// Fachada unificada de alto nivel del Motor de IA Matemática y Descubrimiento Simbólico (OmniEngine)
pub const OmniEngine = struct {
    num_inputs: usize,
    dict: dictionary.ExpansionDictionary,
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, num_inputs: usize) !Self {
        const dict = try dictionary.ExpansionDictionary.init(allocator, num_inputs);
        return .{
            .num_inputs = num_inputs,
            .dict = dict,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.dict.deinit();
    }

    pub inline fn termCount(self: *const Self) usize {
        return self.dict.termCount();
    }

    /// Compila la topología del grafo construyendo términos univariados e interacciones
    pub fn buildExpansionDictionary(self: *Self, activations: []const Activation) !void {
        try self.dict.buildExpansion(activations);
    }

    /// Evalúa el grafo completo para un vector de entrada
    pub inline fn forward(self: *Self, inputs: []const f64) void {
        self.dict.forward(inputs);
    }

    /// Evalúa la predicción f(x) para un vector de pesos descubierto
    pub fn predict(self: *Self, inputs: []const f64, weights: []const f64) f64 {
        self.forward(inputs);
        var sum: f64 = 0.0;
        const n = @min(self.dict.values.items.len, weights.len);
        for (0..n) |i| {
            sum += self.dict.values.items[i] * weights[i];
        }
        return sum;
    }

    /// Resuelve la regresión simbólica con umbral de parsimonia simple
    pub fn solveAnalytical(
        self: *Self,
        dataset: []const Sample,
        parsimony_threshold: f64,
    ) ![]f64 {
        const options = SolveOptions{
            .parsimony_threshold = parsimony_threshold,
        };
        return self.solveAnalyticalWithOptions(dataset, options);
    }

    /// Resuelve la regresión simbólica con configuración avanzada
    pub fn solveAnalyticalWithOptions(
        self: *Self,
        dataset: []const Sample,
        options: SolveOptions,
    ) ![]f64 {
        const n_samples = dataset.len;
        if (n_samples == 0) return error.EmptyDataset;

        const n_features = self.dict.acts.items.len;

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const h_matrix = try temp_alloc.alloc(f64, n_samples * n_features);
        const y_vector = try temp_alloc.alloc(f64, n_samples);

        for (dataset, 0..) |sample, s| {
            self.forward(sample.inputs);
            const offset = s * n_features;
            @memcpy(h_matrix[offset .. offset + n_features], self.dict.values.items);
            y_vector[s] = sample.target;
        }

        return stlsq.solveAnalyticalStlsq(
            self.allocator,
            h_matrix,
            y_vector,
            n_samples,
            n_features,
            self.num_inputs, // Bias C index
            options,
        );
    }

    /// Descubre el sistema dinámico de ecuaciones diferenciales dx/dt = f(x) a partir de trayectorias
    pub fn solveDynamicalSystem(
        self: *Self,
        time: []const f64,
        trajectory: []const []const f64,
        window_half: usize,
        options: SolveOptions,
    ) !dynamical.DynamicalResult {
        return dynamical.solveDynamicalSystem(
            self.allocator,
            &self.dict,
            time,
            trajectory,
            window_half,
            options,
        );
    }

    /// Obtiene la fórmula matemática descubierta como una cadena de texto en memoria
    pub fn getReconstructedFormula(self: *const Self, weights: []const f64) ![]u8 {
        return formatter.reconstructFormula(
            self.allocator,
            weights,
            self.dict.node_names.items,
        );
    }

    /// Imprime la ecuación en stdout formateada limpiamente: f(X) = ...
    pub fn printEquation(self: *const Self, weights: []const f64) void {
        const form = self.getReconstructedFormula(weights) catch return;
        defer self.allocator.free(form);
        std.debug.print("f(X) = {s}\n", .{form});
    }

    /// Calcula el coeficiente de determinación R² sobre un dataset usando los pesos descubiertos
    pub fn computeR2(self: *Self, dataset: []const Sample, weights: []const f64) !f64 {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const y_true = try temp_alloc.alloc(f64, dataset.len);
        const y_pred = try temp_alloc.alloc(f64, dataset.len);

        for (dataset, 0..) |sample, i| {
            y_true[i] = sample.target;
            y_pred[i] = self.predict(sample.inputs, weights);
        }

        return metrics.r2(y_true, y_pred);
    }

    /// Calcula el MSE (Error Cuadrático Medio) sobre un dataset
    pub fn computeMse(self: *Self, dataset: []const Sample, weights: []const f64) !f64 {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const temp_alloc = arena.allocator();

        const y_true = try temp_alloc.alloc(f64, dataset.len);
        const y_pred = try temp_alloc.alloc(f64, dataset.len);

        for (dataset, 0..) |sample, i| {
            y_true[i] = sample.target;
            y_pred[i] = self.predict(sample.inputs, weights);
        }

        return metrics.mse(y_true, y_pred);
    }

    /// Cuenta el número de coeficientes activos (no-cero) en los pesos
    pub fn countActiveTerms(_: *const Self, weights: []const f64) usize {
        return metrics.activeCoefficients(weights);
    }
};
