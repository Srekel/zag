const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const zero_struct = @import("util.zig").zero_struct;
const system = @import("../core/system.zig");

fn systemInit(params: []const system.SystemParam) void {
    std.debug.warn("init");
}

fn systemCleanup(params: []const system.SystemParam) void {
    std.debug.warn("deinit");
}

fn systemUpdate(params: []const system.SystemParam) void {
    std.debug.warn("update");
}

const funcs = [_]system.SystemFuncDef{
    system.SystemFuncDef{ .pass = "init", .phase = 0, .func = systemInit },
    system.SystemFuncDef{ .pass = "deinit", .phase = 0, .func = systemCleanup },
    system.SystemFuncDef{ .pass = "update", .phase = 0, .func = systemUpdate },
};

pub fn init(name: []const u8, allocator: *Allocator) system.System {
    var sys = system.System.init(name, funcs, allocator);
    return sys;
}

//  catch |err| {
//     std.debug.assert(false);
//     var sys2 = system.System{
//         .name = undefined,
//         .funcs = undefined,
//     };

//     return sys2;
// };
