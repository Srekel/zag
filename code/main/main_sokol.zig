const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const zero_struct = @import("util.zig").zero_struct;

pub const sokol = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("sokol/sokol_app.h");
    @cInclude("sokol/sokol_gfx.h");
    @cInclude("sokol/sokol_time.h");
    @cInclude("cimgui/cimgui.h");
    @cInclude("sokol/util/sokol_imgui.h");
});

const SokolState = struct {
    pass_action: sokol.sg_pass_action = undefined,
};

pub const AppInitFunc = fn (user_data: *c_void) void;
pub const AppUpdateFunc = fn (dt: f64, total_time: f64, user_data: *c_void) bool;

pub const AppState = struct {
    init_func: AppInitFunc,
    cleanup_func: AppInitFunc,
    update_func: AppUpdateFunc,
    user_data: *c_void,
};

var sokol_state: SokolState = undefined;
var last_time: u64 = 0;

pub export fn init(user_data: ?*c_void) void {
    var desc = zero_struct(sokol.sg_desc);
    sokol.sg_setup(&desc);
    sokol.stm_setup();

    var imgui_desc = zero_struct(sokol.simgui_desc_t);
    sokol.simgui_setup(&imgui_desc);

    sokol_state.pass_action.colors[0].action = sokol.SG_ACTION_CLEAR;
    sokol_state.pass_action.colors[0].val = [_]f32{ 0.1, 0.3, 0.1, 1.0 };

    var state = @ptrCast([*]AppState, @alignCast(@alignOf([*]AppState), user_data));
    state.*.init_func(state.*.user_data);
}

pub export fn cleanup(user_data: ?*c_void) void {
    sokol.simgui_shutdown();
    sokol.sg_shutdown();
}

pub export fn update(user_data: ?*c_void) void {
    var state = @ptrCast([*]AppState, @alignCast(@alignOf([*]AppState), user_data));
    const width = sokol.sapp_width();
    const height = sokol.sapp_height();
    const dt = sokol.stm_sec(sokol.stm_laptime(&last_time));

    var quit = state.*.update_func(dt, 0, state.*.user_data);

    sokol.simgui_new_frame(width, height, dt);
    sokol.igText(c"Zag!");
    sokol.sg_begin_default_pass(&sokol_state.pass_action, width, height);
    sokol.simgui_render();
    sokol.sg_end_pass();
    sokol.sg_commit();

    if (quit) {
        sokol.sapp_quit();
    }
}

pub export fn event(ev: [*c]const sokol.sapp_event) void {
    _ = sokol.simgui_handle_event(ev);
}
