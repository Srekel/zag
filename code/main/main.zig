const std = @import("std");
// const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const main_sokol = @import("main_sokol.zig");
const system = @import("../core/system.zig");

const MainState = struct {
    sm: *system.SystemManager,
    allocator: *std.mem.Allocator,
};

// SYSTEMS
const transform_system = @import("../systems/transform_system.zig");

fn init_safe(user_data: *c_void) void {
    init(user_data) catch |err| {
        std.debug.assert(false);
    };
}

fn init(user_data: *c_void) !void {
    var mainstate = @ptrCast([*]MainState, @alignCast(@alignOf([*]MainState), user_data));
    var sm = mainstate.*.sm;

    var systems = std.ArrayList(system.System).init(sm.allocator);

    var ts = transform_system.init("transform", sm.allocator);
    warn("1 {}\n", ts.funcs[0].pass);
    try systems.append(ts);
    warn("2 {}\n", ts.funcs[0].pass);
    sm.registerAllSystems(systems.toSlice());
    sm.runSystemFunc("init");
}

fn deinit(user_data: *c_void) void {}

fn update(dt: f64, total_time: f64, user_data: *c_void) bool {
    var mainstate = @ptrCast([*]MainState, @alignCast(@alignOf([*]MainState), user_data));
    var sm = mainstate.*.sm;
    sm.runSystemFunc("update");
    return false;
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
    defer arena.deinit();

    var sm = system.SystemManager.init(&arena.allocator);
    // var sm = system.SystemManager.init(std.heap.c_allocator);
    defer sm.deinit();

    var mainstate = MainState{
        .sm = &sm,
        // .allocator = std.heap.c_allocator,
        .allocator = &arena.allocator,
    };

    var state = zero_struct(main_sokol.AppState);
    state.init_func = init_safe;
    state.cleanup_func = deinit;
    state.update_func = update;
    state.user_data = &mainstate;

    // TODO: Change to main_sokol.run(...)
    var desc = zero_struct(main_sokol.sokol.sapp_desc);
    desc.width = 800;
    desc.height = 480;
    desc.window_title = c"Zag";
    desc.user_data = &state;
    desc.init_userdata_cb = main_sokol.init;
    desc.frame_userdata_cb = main_sokol.update;
    desc.cleanup_userdata_cb = main_sokol.deinit;
    desc.event_cb = main_sokol.event;
    var exit_code = main_sokol.sokol.sapp_run(&desc);
    warn("Done!\n");
}
