const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const stretchy_buffer = @import("stretchy_buffer.zig");
const Allocator = std.mem.Allocator;

pub const SystemParam = struct {
    name: []u8,
    value: union {
        buf_u8: []u8,
    },
};

pub const system_func = fn () void;

pub const SystemFunc = struct {
    name: []u8,
    pass: []u8,
    params: stretchy_buffer.stretchy_buffer(SystemParam),
    func: system_func,
};

pub const System = struct {
    name: []u8,
    // funcs: stretchy_buffer.stretchy_buffer(SystemFunc),
};

pub const SystemManager = struct {
    systems: stretchy_buffer.stretchy_buffer(System),
};
