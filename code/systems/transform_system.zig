const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const system = @import("../core/system.zig");
const math3d = @import("../external/zig-gamedev-lib/src/math3d.zig");

const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const Context = struct {
    maxEntityCount: u16,
    allocator: *Allocator,
};

fn fillContext(params: system.SystemParamLookup, comptime T: type) T {
    var context: T = undefined;
    inline for (@typeInfo(T).Struct.fields) |f, i| {
        const fieldName = f.name;

        const typ = @memberType(T, i);
        const ti = @typeInfo(typ);
        switch (ti) {
            TypeId.Int => {
                @field(context, fieldName) = @intCast(@IntType(ti.Int.is_signed, ti.Int.bits), (params.getValue(fieldName) orelse unreachable).vint);
            },
            TypeId.Bool => {
                @field(context, fieldName) = (params.getValue(fieldName) orelse unreachable).vbool;
            },
            TypeId.Pointer => {
                switch (ti.Pointer.size) {
                    builtin.TypeInfo.Pointer.Size.One => {
                        @field(context, fieldName) = @ptrCast(typ, (params.getValue(fieldName) orelse unreachable).pvoid);
                    },
                    builtin.TypeInfo.Pointer.Size.Slice,
                    builtin.TypeInfo.Pointer.Size.Many,
                    builtin.TypeInfo.Pointer.Size.C,
                    => {
                        unreachable;
                        continue;
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

const TransformSystem = struct {
    positions: math3d.Vec3 = undefined,
};

fn systemInit(params: system.SystemParamLookup) void {
    std.debug.warn("init");
    var context = fillContext(params, Context);
    // var allocator = params.get("allocator").Allocator;
    // var entity_count = (params.getValue("max_entity_count") orelse unreachable).vint;
    // var allocator = (params.getValue("allocator") orelse unreachable).pallocator;
    // var lolmem = allocator.*.alloc(u8, 123);
    // var allocator2 = (params.getValue("allocator") orelse unreachable).pallocator;
    const lol = 3;
}

fn systemCleanup(params: system.SystemParamLookup) void {
    std.debug.warn("deinit");
}

fn systemUpdate(params: system.SystemParamLookup) void {
    std.debug.warn("update");
}

const funcs = [_]system.SystemFuncDef{
    system.SystemFuncDef{ .pass = "init", .phase = 0, .func = systemInit, .params = [_][]const u8{ "allocator", "entity_count" } },
    system.SystemFuncDef{ .pass = "deinit", .phase = 0, .func = systemCleanup },
    system.SystemFuncDef{ .pass = "update", .phase = 0, .func = systemUpdate },
};

pub fn init(name: []const u8, allocator: *Allocator) system.System {
    // var
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
