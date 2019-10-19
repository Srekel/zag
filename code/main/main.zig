const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;
const main_sokol = @import("main_sokol.zig");

pub fn main() void {
    var state = zero_struct(main_sokol.app_state());

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
