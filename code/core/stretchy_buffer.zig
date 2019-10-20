// NOTE: Taken from https://github.com/rivten/carbon/blob/master/code/common.zig

const std = @import("std");
const Allocator = std.mem.Allocator;

// NOTE(hugo): The stretchy_buffer and hashmap types
// are directly taken from Per Vogsen's Bitwise project !

pub fn stretchy_buffer(comptime T: type) type {
    return struct {
        allocator: *Allocator,
        len: usize,
        elems: []T,

        const Self = @This();

        pub fn init(allocator: *Allocator) Self {
            return Self{
                .allocator = allocator,
                .len = 0,
                .elems = [_]T{},
            };
        }

        pub fn push(buf: *Self, elem: T) !void {
            try fit(buf, 1 + buf.len);
            buf.elems[buf.len] = elem;
            buf.len += 1;
        }

        pub fn append(buf: *Self, elems: []const T) !void {
            for (elems) |e| try buf.push(e);
        }

        fn fit(buf: *Self, n: usize) !void {
            if (n > buf.elems.len) {
                try grow(buf, n);
            }
        }

        fn grow(buf: *Self, new_len: usize) !void {
            const new_cap = std.math.max(2 * buf.elems.len, std.math.min(new_len, 16));
            if (buf.elems.len == 0) {
                buf.elems = try buf.allocator.alloc(T, new_cap);
            } else {
                buf.elems = try buf.allocator.realloc(buf.elems, new_cap);
            }
        }

        pub fn clear(buf: *Self) void {
            buf.len = 0;
        }

        pub fn free(buf: *Self) void {
            buf.allocator.free(buf.elems);
        }

        pub fn elements(buf: *Self) []T {
            return buf.elems[0..buf.len];
        }
    };
}

test "init" {
    var buf = stretchy_buffer(i32).init(&std.heap.DirectAllocator.init().allocator);
    std.debug.assert(buf.len == 0);
    std.debug.assert(buf.elems.len == 0);
}

test "push i32" {
    var buf = stretchy_buffer(i32).init(&std.heap.DirectAllocator.init().allocator);
    try buf.push(1);
    try buf.push(2);
    try buf.push(5);
    for (buf.elements()) |e| {
        std.debug.warn("{}\n", e);
    }
    buf.clear();
    std.debug.assert(buf.len == 0);
}

test "push struct" {
    const myStruct = struct {
        a: i32,
        b: bool,
    };

    const A = myStruct{
        .a = 0,
        .b = true,
    };

    const B = myStruct{
        .a = 1,
        .b = false,
    };

    var buf = stretchy_buffer(myStruct).init(&std.heap.DirectAllocator.init().allocator);
    try buf.push(A);
    try buf.push(B);
    for (buf.elements()) |e| {
        std.debug.warn("{}\n", e);
    }
}
