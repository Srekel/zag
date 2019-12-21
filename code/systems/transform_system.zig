const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const system = @import("../core/system.zig");
const entity = @import("../core/entity.zig");
usingnamespace @import("../main/util.zig");
const math3d = @import("math3d");

const SystemSetupContext = struct {
    max_entity_count: u16,
    allocator: *Allocator,
    entity_manager: *entity.EntityManager,
};

const SystemTearDownContext = struct {};

const SystemUpdateContext = struct {};

const EntityCreateContext = struct {
    transform_components: []math3d.Mat4,
    transform_entities: []Entity,
};

pub const TransformComponentInitData = struct {
    pos: math3d.Vec3,
    rot: math3d.Quaternion,
};

pub const TransformSystem = struct {
    allocator: *Allocator = undefined,
    positions: []math3d.Vec3 = undefined,
    transforms: []math3d.Mat4 = undefined,

    fn setup(self: *TransformSystem, context: SystemSetupContext) void {
        self.allocator = context.allocator;
        self.positions = context.allocator.alloc(math3d.Vec3, context.max_entity_count) catch unreachable;
        for (self.positions) |*pos| pos.* = math3d.Vec3.zero;
        std.debug.warn("setup");

        context.entity_manager.registerComponent(math3d.Vec3, "transform_position_comp");
    }

    fn tearDown(self: *TransformSystem, context: SystemTearDownContext) void {
        self.allocator.free(self.positions);
        std.debug.warn("freeee");
    }

    fn update(self: *TransformSystem, context: SystemUpdateContext) void {}

    fn entityCreate(self: *TransformSystem, context: EntityCreateContext) void {
        for (context.transform_position_comp.entities) |ent, index| {
            self.transforms[ent] = context.transform_position_comp.components[index];
        }
    }

    fn entityDestroy(self: *TransformSystem, context: EntityDestroyContext) void {
        if (std.builtin.mode != .Debug) {
            return;
        }
        for (context.transform_position_comp.entities) |ent, index| {
            self.transforms[ent] = math3d.Mat4.zero;
        }
    }
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
    system.SystemFuncDef{
        .pass = "entity_create",
        .phase = 0,
        .func = funcWrap(TransformSystem, TransformSystem.entityCreate, EntityCreateContext),
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
