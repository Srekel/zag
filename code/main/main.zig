const std = @import("std");
// const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const main_sokol = @import("main_sokol.zig");
const system_manager = @import("../core/system_manager.zig");
// const stretchy_buffer = @import("../core/stretchy_buffer.zig");

// systems
const transform_system = @import("../systems/transform_system.zig");

var sm = zero_struct(system_manager.SystemManager);
// var sm = system_manager.SystemManager{
//     .systems = stretchy_buffer.stretchy_buffer(system_manager.System).init(std.heap.direct_allocator),
// };

fn init(user_data: *c_void) void {
    transform_system.register(sm);
}
fn cleanup(user_data: *c_void) void {}
fn update(dt: f64, total_time: f64, user_data: *c_void) bool {
    return true;
}

pub fn main() void {
    var state = zero_struct(main_sokol.AppState);
    state.init_func = init;
    state.cleanup_func = cleanup;
    state.update_func = update;

    // TODO: Change to main_sokol.run(...)
    var desc = zero_struct(main_sokol.sokol.sapp_desc);
    desc.width = 800;
    desc.height = 480;
    desc.window_title = c"Zag";
    desc.user_data = &state;
    desc.init_userdata_cb = main_sokol.init;
    desc.frame_userdata_cb = main_sokol.update;
    desc.cleanup_userdata_cb = main_sokol.cleanup;
    desc.event_cb = main_sokol.event;
    var exit_code = main_sokol.sokol.sapp_run(&desc);
    warn("Done!\n");
}
