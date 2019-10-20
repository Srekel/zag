const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const system_manager = @import("../core/system_manager.zig");

pub fn register(sm: system_manager.SystemManager) void {
    // var system = zero_struct(sm.System);
    // system.name = "transform";
    // sm.systems[sm.systems.len] = system;
}
