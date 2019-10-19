const std = @import("std");

pub fn zero_struct(comptime T: type) T {
    var out: T = undefined;
    std.mem.set(u8, @ptrCast([*]u8, &out)[0..@sizeOf(T)], 0);
    return out;
}
