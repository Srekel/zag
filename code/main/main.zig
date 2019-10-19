const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;

fn zero_struct(comptime T: type) T {
    var out: T = undefined;
    std.mem.set(u8, @ptrCast([*]u8, &out)[0..@sizeOf(T)], 0);
    return out;
}

const sokol = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("sokol/sokol_app.h");
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("sokol/sokol_time.h");
    @cInclude("cimgui/cimgui.h");
    @cInclude("sokol/util/sokol_imgui.h");
});

fn app_state() type {
    return struct {
        x: f32 = 0,
        y: f32 = 0,
        pass_action: sokol.sg_pass_action = undefined,
    };
}

var last_time: u64 = 0;

export fn init(user_data: ?*c_void) void {
    var state = @ptrCast([*]app_state(), @alignCast(@alignOf([*]app_state()), user_data));

    var desc = zero_struct(sokol.sg_desc);
    sokol.sg_setup(&desc);
    sokol.stm_setup();

    var imgui_desc = zero_struct(sokol.simgui_desc_t);
    sokol.simgui_setup(&imgui_desc);

    state.*.pass_action.colors[0].action = sokol.SG_ACTION_CLEAR;
    state.*.pass_action.colors[0].val = [_]f32{ 0.1, 0.3, 0.1, 1.0 };
}

export fn cleanup(user_data: ?*c_void) void {
    sokol.simgui_shutdown();
    sokol.sg_shutdown();
}

export fn update(user_data: ?*c_void) void {
    var state = @ptrCast([*]app_state(), @alignCast(@alignOf([*]app_state()), user_data));
    const width = sokol.sapp_width();
    const height = sokol.sapp_height();
    const dt = sokol.stm_sec(sokol.stm_laptime(&last_time));
    sokol.simgui_new_frame(width, height, dt);
    sokol.igText(c"Zag!");
    sokol.sg_begin_default_pass(&state.*.pass_action, width, height);
    sokol.simgui_render();
    sokol.sg_end_pass();
    sokol.sg_commit();
}

export fn event(ev: [*c]const sokol.sapp_event) void {
    _ = sokol.simgui_handle_event(ev);
}

pub fn main() void {
    var state = zero_struct(app_state());
    state.x = 3;

    var desc = zero_struct(sokol.sapp_desc);
    desc.width = 800;
    desc.height = 480;
    desc.window_title = c"Zag";
    desc.user_data = &state;
    desc.init_userdata_cb = init;
    desc.frame_userdata_cb = update;
    desc.cleanup_userdata_cb = cleanup;
    desc.event_cb = event;
    var exit_code = sokol.sapp_run(&desc);

    warn("Done!\n");
}
