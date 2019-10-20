const std = @import("std");
const builtin = @import("builtin");

const is_windows = builtin.os == builtin.Os.windows;

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("main", "code/main/main.zig");
    exe.setBuildMode(mode);

    exe.addIncludeDir("./external");
    exe.addIncludeDir("./code");
    // exe.addCSourceFile("external/sralloc/sralloc.c", [_][]const u8{"-std=c99", "-Iexternal/sralloc/"});
    exe.addCSourceFile("external/zig_wraps/sokol.c", [_][]const u8{"-std=c99"});
    exe.linkSystemLibrary("c");
    exe.setMainPkgPath("./code");

    if (is_windows) {
        exe.addObjectFile("build/cimgui.obj");
        exe.addObjectFile("build/imgui.obj");
        exe.addObjectFile("build/imgui_demo.obj");
        exe.addObjectFile("build/imgui_draw.obj");
        exe.addObjectFile("build/imgui_widgets.obj");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else {
        // Untested, leaving commented out
        // exe.linkSystemLibrary("GL");
        // exe.linkSystemLibrary("GLEW");
    }

    const run_cmd = exe.run();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
