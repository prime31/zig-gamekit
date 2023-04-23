const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

var framework_dir: ?[]u8 = null;
const build_impl_type: enum { exe, static_lib, object_files } = .static_lib;

pub fn build(b: *std.build.Builder) !void {
    const exe = b.addStaticLibrary("JunkLib", null);
    linkArtifact(b, exe, b.standardTargetOptions(.{}), .static, "");
    exe.install();
}

/// prefix_path is used to add package paths. It should be the the same path used to include this build file
pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");

    exe.linkLibCpp();

    if (target.isWindows()) {
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else if (target.isDarwin()) {
        const frameworks_dir = macosFrameworksDir(b) catch unreachable;
        exe.addFrameworkPath(frameworks_dir);
        exe.linkFramework("Foundation");
        exe.linkFramework("Cocoa");
        exe.linkFramework("Quartz");
        exe.linkFramework("QuartzCore");
        exe.linkFramework("Metal");
        exe.linkFramework("MetalKit");
        exe.linkFramework("OpenGL");
        exe.linkFramework("AudioToolbox");
        exe.linkFramework("CoreAudio");
        exe.linkSystemLibrary("c++");
    } else {
        exe.linkLibC();
        exe.linkSystemLibrary("c++");
    }

    const base_path = prefix_path ++ "gamekit/deps/imgui/";
    exe.addIncludePath(base_path ++ "cimgui/imgui");
    exe.addIncludePath(base_path ++ "cimgui/imgui/examples");

    const cpp_args = [_][]const u8{"-Wno-return-type-c-linkage"};
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_demo.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_draw.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_widgets.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/cimgui.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "temporary_hacks.cpp", &cpp_args);
}

/// helper function to get SDK path on Mac
fn macosFrameworksDir(b: *Builder) ![]u8 {
    if (framework_dir) |dir| return dir;

    var str = b.exec(&[_][]const u8{ "xcrun", "--show-sdk-path" });
    const strip_newline = std.mem.lastIndexOf(u8, str, "\n");
    if (strip_newline) |index| {
        str = str[0..index];
    }
    framework_dir = try std.mem.concat(b.allocator, u8, &[_][]const u8{ str, "/System/Library/Frameworks" });
    return framework_dir.?;
}

pub fn getModule(b: *std.Build, comptime prefix_path: []const u8) *std.build.Module {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");
    return b.createModule(.{
        .source_file = .{ .path = prefix_path ++ "gamekit/deps/imgui/imgui.zig" },
    });
}
