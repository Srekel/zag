const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;

// const sralloc = @cImport({
//     @cInclude("sralloc/sralloc_wrapper.h");
// });
const sokol_app = @cImport({
    @cInclude("sokol/sokol_app.h");
});

fn app_state() type {
    return struct {
        x: f32 = 0,
        y: f32 = 0,
    };
}

pub fn main() void {

    // var root_allocator = sralloc.sralloc_create_malloc_allocator(c"root") orelse return;
    // defer sralloc.sralloc_destroy_malloc_allocator(root_allocator);

    // warn("allocations: {}\n", root_allocator.*.stats.num_allocations);
    // var allocation = sralloc.sralloc_alloc_with_size(root_allocator, 1234);

    // warn("allocations: {}\n", root_allocator.*.stats.num_allocations);
    // sralloc.sralloc_dealloc(root_allocator, allocation.ptr);

    // warn("allocations: {}\n", root_allocator.*.stats.num_allocations);

    var state = app_state(){};
    var desc: sokol_app.sapp_desc = undefined;
    std.mem.set(u8, @ptrCast([*]u8, &desc)[0..@sizeOf(@typeOf(desc))], 0);
    var exit_code = sokol_app.sapp_run(&desc);

    warn("Done!\n");
}
