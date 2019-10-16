const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("main", "code/main/main.zig");
    exe.setBuildMode(mode);

        exe.addIncludeDir("./external");
    // exe.addIncludeDir("external/sralloc");
    // exe.addCSourceFile("external/sralloc/sralloc.c", [_][]const u8{"-std=c99", "-Iexternal/sralloc/"});
    exe.addCSourceFile("external/sokol/sokol.c", [_][]const u8{"-std=c99", "-Iexternal/sokol/"});
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("winmm");
    exe.linkSystemLibrary("opengl32");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("user32");

    const run_cmd = exe.run();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}