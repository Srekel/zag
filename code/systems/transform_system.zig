const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const system = @import("../core/system.zig");
usingnamespace @import("../main/util.zig");
const math3d = @import("math3d");

const Context = struct {
    max_entity_count: u16,
    allocator: *Allocator,
};

pub const TransformSystem = struct {
    positions: []math3d.Vec3 = undefined,
    fn setup(self: *TransformSystem, context: Context) void {
        self.positions = context.allocator.alloc(math3d.Vec3, context.max_entity_count) catch unreachable;
        std.debug.warn("setup");
    }

    fn tearDown(self: *TransformSystem, context: Context) void {
        context.allocator.free(self.positions);
        std.debug.warn("freeee");
    }

    fn update(self: *TransformSystem, context: Context) void {}
};

const funcWrap = system.systemFunctionWrap;
const funcs = [_]system.SystemFuncDef{
    system.SystemFuncDef{
        .pass = "setup",
        .phase = 0,
        .func = funcWrap(TransformSystem, TransformSystem.setup, Context),
    },
    system.SystemFuncDef{
        .pass = "teardown",
        .phase = 0,
        .func = funcWrap(TransformSystem, TransformSystem.tearDown, Context),
    },
    system.SystemFuncDef{
        .pass = "update",
        .phase = 0,
        .func = funcWrap(TransformSystem, TransformSystem.update, Context),
    },
};

pub fn init(name: []const u8, allocator: *Allocator) system.System {
    var ts = allocator.create(TransformSystem) catch unreachable;
    var sys = system.System.init(name, funcs, @ptrCast(*system.SystemSelf, ts));
    return sys;
}

pub fn deinit(sys: *System, allocator: *Allocator) void {
    allocator.destroy(sys.*.self);
}

//  catch |err| {
//     std.debug.assert(false);
//     var sys2 = system.System{
//         .name = undefined,
//         .funcs = undefined,
//     };

//     return sys2;
// };
