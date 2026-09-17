// Copyright (c) 2026 Edison Manrique Chocce
// Todos los derechos reservados.
// Licencia Dual: AGPL-3.0 para uso académico/personal | Licencia Comercial requerida para uso propietario.
// Ver archivo LICENSE en la raíz del proyecto para términos completos.

//! Arena reutilizable de bloques encadenados para memoria temporal.
//!
//! No es thread-safe. Las asignaciones individuales sólo pueden liberarse o
//! redimensionarse in-place cuando son la última asignación del bloque activo.
const std = @import("std");

pub const FastArena = struct {
    const Self = @This();
    const Alignment = std.mem.Alignment;

    const Block = struct {
        next: ?*Block = null,
        capacity: usize,
        used: usize = 0,
        generation: u64 = 0,
    };

    pub const Config = struct {
        initial_block_size: usize = 64 * 1024,
        max_block_size: usize = 4 * 1024 * 1024,
    };

    pub const Stats = struct {
        blocks: usize,
        capacity: usize,
        used: usize,
        allocations: usize,
    };

    child_allocator: std.mem.Allocator,
    head: ?*Block = null,
    current: ?*Block = null,
    initial_block_size: usize,
    max_block_size: usize,
    next_block_size: usize,
    generation: u64 = 1,
    allocation_count: usize = 0,

    pub fn init(child_allocator: std.mem.Allocator, config: Config) Self {
        const initial = @max(config.initial_block_size, 1);
        return .{
            .child_allocator = child_allocator,
            .initial_block_size = initial,
            .max_block_size = @max(config.max_block_size, initial),
            .next_block_size = initial,
        };
    }

    pub fn deinit(self: *Self) void {
        var block = self.head;
        while (block) |current| {
            const next = current.next;
            const total = @sizeOf(Block) + current.capacity;
            self.child_allocator.rawFree(
                @as([*]u8, @ptrCast(current))[0..total],
                .of(Block),
                @returnAddress(),
            );
            block = next;
        }
        self.* = undefined;
    }

    /// Invalidates all allocations and preserves blocks for a following batch.
    /// Each block is cleared lazily when it is reached, so this is O(1).
    pub fn reset(self: *Self) void {
        self.generation +%= 1;
        // Generation zero is valid too; equality, not its value, is what matters.
        self.current = self.head;
        self.allocation_count = 0;
    }

    pub fn allocator(self: *Self) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = vtableAlloc,
                .resize = vtableResize,
                .remap = vtableRemap,
                .free = vtableFree,
            },
        };
    }

    pub fn stats(self: *const Self) Stats {
        var result: Stats = .{ .blocks = 0, .capacity = 0, .used = 0, .allocations = self.allocation_count };
        var block = self.head;
        while (block) |current| : (block = current.next) {
            result.blocks += 1;
            result.capacity += current.capacity;
            if (current.generation == self.generation) result.used += current.used;
        }
        return result;
    }

    fn blockData(block: *Block) [*]u8 {
        return @as([*]u8, @ptrCast(block)) + @sizeOf(Block);
    }

    fn activate(self: *Self, block: *Block) void {
        if (block.generation != self.generation) {
            block.generation = self.generation;
            block.used = 0;
        }
    }

    fn tryAlloc(block: *Block, len: usize, alignment: Alignment) ?[*]u8 {
        const data = blockData(block);
        const start = @intFromPtr(data) + block.used;
        const aligned = alignment.forward(start);
        const padding = aligned - start;
        const end = std.math.add(usize, block.used, padding) catch return null;
        const new_used = std.math.add(usize, end, len) catch return null;
        if (new_used > block.capacity) return null;
        block.used = new_used;
        return @ptrFromInt(aligned);
    }

    fn allocateBlock(self: *Self, minimum_capacity: usize) ?*Block {
        const target = @max(minimum_capacity, @min(self.next_block_size, self.max_block_size));
        const total = std.math.add(usize, @sizeOf(Block), target) catch return null;
        const memory = self.child_allocator.rawAlloc(total, .of(Block), @returnAddress()) orelse return null;
        const block: *Block = @ptrCast(@alignCast(memory));
        block.* = .{ .capacity = target, .generation = self.generation };
        self.next_block_size = @min(self.max_block_size, std.math.mul(usize, self.next_block_size, 2) catch self.max_block_size);
        return block;
    }

    fn allocBytes(self: *Self, len: usize, alignment: Alignment) ?[*]u8 {
        // Allocator vtables never receive a zero-length request.
        const required = std.math.add(usize, len, alignment.toByteUnits() - 1) catch return null;
        var block = self.current;
        while (true) {
            if (block) |current| {
                self.activate(current);
                if (tryAlloc(current, len, alignment)) |ptr| {
                    self.current = current;
                    self.allocation_count += 1;
                    return ptr;
                }
                if (current.next) |next| {
                    block = next;
                    continue;
                }
                const new_block = self.allocateBlock(required) orelse return null;
                current.next = new_block;
                block = new_block;
            } else {
                const new_block = self.allocateBlock(required) orelse return null;
                self.head = new_block;
                block = new_block;
            }
        }
    }

    fn isLastAllocation(self: *Self, memory: []u8) bool {
        const block = self.current orelse return false;
        if (block.generation != self.generation) return false;
        const end = @intFromPtr(blockData(block)) + block.used;
        return @intFromPtr(memory.ptr) + memory.len == end;
    }

    fn resizeInPlace(self: *Self, memory: []u8, new_len: usize) bool {
        if (!self.isLastAllocation(memory)) return false;
        const block = self.current.?;
        if (new_len <= memory.len) {
            block.used -= memory.len - new_len;
            return true;
        }
        const extra = new_len - memory.len;
        if (extra > block.capacity - block.used) return false;
        block.used += extra;
        return true;
    }

    fn vtableAlloc(ctx: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.allocBytes(len, alignment);
    }

    fn vtableResize(ctx: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
        _ = alignment;
        _ = ret_addr;
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.resizeInPlace(memory, new_len);
    }

    fn vtableRemap(ctx: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        _ = alignment;
        _ = ret_addr;
        const self: *Self = @ptrCast(@alignCast(ctx));
        return if (self.resizeInPlace(memory, new_len)) memory.ptr else null;
    }

    fn vtableFree(ctx: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize) void {
        _ = alignment;
        _ = ret_addr;
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self.resizeInPlace(memory, 0);
    }
};
