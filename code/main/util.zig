const std = @import("std");
const assert = std.debug.assert;
const builtin = std.builtin;
const TypeId = builtin.TypeId;
// usingnamespace @import("../main/util.zig");

pub fn zero_struct(comptime T: type) T {
    var out: T = undefined;
    std.mem.set(u8, @ptrCast([*]u8, &out)[0..@sizeOf(T)], 0);
    return out;
}

pub const String = []u8;
pub const Entity = u16;
pub const Hash = u64;
pub const Tag = u32;
pub const TagUnset: Tag = 0;

pub fn stringHash(s: []const u8) Hash {
    return std.hash.Wyhash.hash(0, s);
}

pub fn stringTag(comptime s: []const u8) Tag {
    return @truncate(u32, std.hash.Wyhash.hash(0, s));
}

pub const FullTag = struct {
    tag: Tag,
    string: String,
    pub fn init(string: String) FullTag {
        return .{
            .tag = stringTag(string),
            .string = string,
        };
    }
};

pub const VariantType = union(enum) {
    int64: i64,
    boolean: bool,
    hash: Hash,
    tag: Tag,
    ptr: usize,
};

pub const Variant = struct {
    value: VariantType = undefined,
    tag: Tag = 0,
    count: u32 = 1,

    pub fn create_ptr(ptr: var, tag: Tag) Variant {
        assert(tag != 0);
        return Variant{
            .value = .{ .ptr = @ptrToInt(ptr) },
            .tag = tag,
        };
    }

    pub fn create_slice(slice: var, tag: Tag) Variant {
        assert(tag != 0);
        return Variant{
            .value = .{ .ptr = @ptrToInt(slice.ptr) },
            .tag = tag,
            .count = slice.len,
        };
    }

    pub fn create_int(int: var) Variant {
        self.tag = 0; // TODO
        return Variant{
            .value = .{ .int64 = @intCast(i64, int) },
        };
    }

    pub fn set_ptr(self: *Variant, ptr: var, tag: Tag) void {
        assert(tag != 0);
        self.value = .{ .ptr = @ptrToInt(ptr) };
        self.tag = tag;
    }

    pub fn set_slice(slice: var, tag: Tag) Variant {
        assert(tag != 0);
        self.value = .{ .ptr = @ptrToInt(slice.ptr) };
        self.tag = tag;
        self.count = slice.len;
    }

    pub fn set_int(int: var) Variant {
        var v = VariantType{ .int64 = @intCast(i64, int) };
        return Variant{
            .value = .{ .int64 = @intCast(i64, int) },
        };
    }

    pub fn get_ptr(self: Variant, comptime T: type, tag: Hash) *T {
        assert(tag == self.tag);
        return @intToPtr(*T, self.value.ptr);
    }

    pub fn get_slice(self: Variant, comptime T: type, tag: Hash) []T {
        assert(tag == self.tag);
        var ptr = @intToPtr([*]T, self.value.ptr);
        return ptr[0..self.count];
    }

    pub fn get_int(self: Variant) i64 {
        return self.value.int64;
    }
};

pub const VariantMap = std.StringHashMap(Variant);

pub fn fillContext(params: VariantMap, comptime ContextT: type) ContextT {
    var context: ContextT = undefined;
    inline for (@typeInfo(ContextT).Struct.fields) |f, i| {
        const field_name = f.name;
        const typ = @memberType(ContextT, i);
        const ti = @typeInfo(typ);
        const variant = (params.getValue(field_name) orelse unreachable);
        switch (ti) {
            TypeId.Int => {
                @field(context, field_name) = @intCast(typ, variant.get_int());
            },
            TypeId.Bool => {
                @field(context, field_name) = variant.get_bool;
            },
            TypeId.Pointer => {
                switch (ti.Pointer.size) {
                    builtin.TypeInfo.Pointer.Size.One => {
                        var ptr = variant.get_ptr(ti.Pointer.child, stringTag(field_name));
                        @field(context, field_name) = ptr;
                    },
                    else => {
                        unreachable;
                    },
                }
            },
            else => {
                unreachable;
            },
        }
    }

    return context;
}

pub fn DoubleBuffer(comptime BufferedType: type) type {
    return struct {
        const Self = @This();

        allocator: *Allocator,
        current_buffer: u8 = 0,
        buffers: [2]BufferedType,

        pub fn init(allocator: *Allocator, capacity: usize) !Self {
            var res = try Self{
                .buffers = .{
                    BufferedType.init(allocator),
                    BufferedType.init(allocator),
                },
            };
            res.buffers[0].ensureCapacity(capacity);
            res.buffers[1].ensureCapacity(capacity);
            return res;
        }

        pub fn deinit(self: DoubleBuffer) void {
            self.buffers[0].deinit();
            self.buffers[1].deinit();
        }

        pub fn frontHasData(self: DoubleBuffer) []T {
            return self.buffers[self.current_buffer].count() > 0;
        }

        pub fn front(self: DoubleBuffer) *ArrayList(T) {
            return self.buffers[self.current_buffer];
        }

        pub fn back(self: DoubleBuffer) *ArrayList(T) {
            return self.buffers[1 - self.current_buffer];
        }

        pub fn swap(self: *DoubleBuffer) []T {
            self.currBuffer().resize(0);
            return self.current_buffer = 1 - self.current_buffer;
        }
    };
}
