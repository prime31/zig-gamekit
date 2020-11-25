const std = @import("std");

const LibExeObjStep = std.build.LibExeObjStep;
const Builder = std.build.Builder;
const Target = std.build.Target;
const Pkg = std.build.Pkg;

const renderkit_build = @import("renderkit/build.zig");
const ShaderCompileStep = renderkit_build.ShaderCompileStep;

var enable_imgui: ?bool = null;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const examples = [_][2][]const u8{
        [_][]const u8{ "mode7", "examples/mode7.zig" },
        [_][]const u8{ "primitives", "examples/primitives.zig" },
        [_][]const u8{ "offscreen", "examples/offscreen.zig" },
        [_][]const u8{ "tri_batcher", "examples/tri_batcher.zig" },
        [_][]const u8{ "batcher", "examples/batcher.zig" },
        [_][]const u8{ "meshes", "examples/meshes.zig" },
        [_][]const u8{ "clear", "examples/clear.zig" },
        [_][]const u8{ "clear_mtl", "examples/clear_mtl.zig" },
        [_][]const u8{ "clear_imgui", "examples/clear_imgui.zig" },
    };

    const examples_step = b.step("examples", "build all examples");
    b.default_step.dependOn(examples_step);

    for (examples) |example, i| {
        const name = example[0];
        const source = example[1];

        var exe = createExe(b, target, name, source);
        examples_step.dependOn(&exe.step);

        // first element in the list is added as "run" so "zig build run" works
        if (i == 0) _ = createExe(b, target, "run", source);
    }

    // shader compiler, run with `zig build compile-shaders`
    const res = ShaderCompileStep.init(b, "renderkit/shader_compiler/", .{
        .shader = "examples/assets/shaders/shader_src.glsl",
        .shader_output_path = "examples/assets/shaders",
        .package_output_path = "examples/assets",
        .additional_imports = &[_][]const u8{
            "const gk = @import(\"gamekit\");",
            "const gfx = gk.gfx;",
            "const math = gk.math;",
            "const renderkit = gk.renderkit;",
        },
    });

    const comple_shaders_step = b.step("compile-shaders", "compiles all shaders");
    b.default_step.dependOn(comple_shaders_step);
    comple_shaders_step.dependOn(&res.step);
}

fn createExe(b: *Builder, target: std.build.Target, name: []const u8, source: []const u8) *std.build.LibExeObjStep {
    var exe = b.addExecutable(name, source);
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setOutputDir("zig-cache/bin");

    addGameKitToArtifact(b, exe, target, "");

    const run_cmd = exe.run();
    const exe_step = b.step(name, b.fmt("run {}.zig", .{name}));
    exe_step.dependOn(&run_cmd.step);

    return exe;
}

/// adds gamekit, renderkit, stb and sdl packages to the LibExeObjStep
pub fn addGameKitToArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    // only add the build option once!
    if (enable_imgui == null)
        enable_imgui = b.option(bool, "imgui", "enable imgui") orelse false;
    exe.addBuildOption(bool, "enable_imgui", enable_imgui.?);

    var dependencies = std.ArrayList(Pkg).init(b.allocator);

    // sdl
    const sdl_builder = @import("gamekit/deps/sdl/build.zig");
    sdl_builder.linkArtifact(b, exe, target, prefix_path);
    const sdl_pkg = sdl_builder.getPackage(prefix_path);

    // stb
    const stb_builder = @import("gamekit/deps/stb/build.zig");
    stb_builder.linkArtifact(b, exe, target, prefix_path);
    const stb_pkg = stb_builder.getPackage(prefix_path);

    // fontstash
    const fontstash_build = @import("gamekit/deps/fontstash/build.zig");
    fontstash_build.linkArtifact(b, exe, target, prefix_path);
    const fontstash_pkg = fontstash_build.getPackage(prefix_path);

    // renderkit
    renderkit_build.addRenderKitToArtifact(b, exe, target, prefix_path ++ "renderkit/");
    const renderkit_pkg = renderkit_build.getRenderKitPackage(prefix_path ++ "renderkit/");

    // imgui
    const imgui_builder = @import("gamekit/deps/imgui/build.zig");
    imgui_builder.linkArtifact(b, exe, target, prefix_path);
    const imgui_pkg = imgui_builder.getImGuiPackage(prefix_path);
    const imgui_gl_pkg = imgui_builder.getImGuiGlPackage(prefix_path);

    // gamekit
    const gamekit_package = Pkg{
        .name = "gamekit",
        .path = prefix_path ++ "gamekit/gamekit.zig",
        .dependencies = &[_]Pkg{ renderkit_pkg, sdl_pkg, stb_pkg, fontstash_pkg, imgui_pkg, imgui_gl_pkg },
    };
    exe.addPackage(gamekit_package);
}
