const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

var framework_dir: ?[]u8 = null;
const build_impl_type: enum { exe, static_lib, object_files } = .static_lib;

pub fn build(b: *std.build.Builder) anyerror!void {
    const exe = b.addStaticLibrary("JunkLib", null);
    linkArtifact(b, exe, b.standardTargetOptions(.{}), .static, "");
    exe.install();
}

/// prefix_path is used to add package paths. It should be the the same path used to include this build file
pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    exe.addPackage(getImGuiPackage(prefix_path));

    if (target.isWindows()) {
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
    } else if (target.isDarwin()) {
        const frameworks_dir = macosFrameworksDir(b) catch unreachable;
        exe.addFrameworkDir(frameworks_dir);
        exe.linkFramework("Foundation");
        exe.linkFramework("Cocoa");
        exe.linkFramework("Quartz");
        exe.linkFramework("QuartzCore");
        exe.linkFramework("Metal");
        exe.linkFramework("MetalKit");
        exe.linkFramework("OpenGL");
        exe.linkFramework("Audiotoolbox");
        exe.linkFramework("CoreAudio");
        exe.linkSystemLibrary("c++");
    } else {
        exe.linkLibC();
        exe.linkSystemLibrary("c++");
    }

    const base_path = prefix_path ++ "gamekit/deps/imgui/";
    exe.addIncludeDir(base_path ++ "cimgui/imgui");
    exe.addIncludeDir(base_path ++ "cimgui/imgui/examples");

    const cpp_args = [_][]const u8{"-Wno-return-type-c-linkage"};
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_demo.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_draw.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/imgui/imgui_widgets.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "cimgui/cimgui.cpp", &cpp_args);
    exe.addCSourceFile(base_path ++ "temporary_hacks.cpp", &cpp_args);

    addImGuiGlImplementation(b, exe, target, prefix_path);
}

fn addImGuiGlImplementation(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    const base_path = prefix_path ++ "gamekit/deps/imgui/";
    const cpp_args = [_][]const u8{ "-Wno-return-type-c-linkage", "-DIMGUI_IMPL_API=extern \"C\"", "-DIMGUI_IMPL_OPENGL_LOADER_GL3W" };

    // TODO: why doesnt gl3w/imgui_impl_opengl3 compile correctly?
    if (build_impl_type == .static_lib) {
        const lib = b.addStaticLibrary("gl3w", null);
        lib.setBuildMode(b.standardReleaseOptions());
        lib.setTarget(target);

        if (target.isWindows()) {
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("gdi32");
        } else if (target.isDarwin()) {
            const frameworks_dir = macosFrameworksDir(b) catch unreachable;
            lib.addFrameworkDir(frameworks_dir);
            // for some reason, only on some SDL installs this is required...
            // const x11_include_dir = std.mem.concat(b.allocator, u8, &[_][]const u8{ frameworks_dir, "/Tk.framework/Headers" }) catch unreachable;
            // lib.addIncludeDir(x11_include_dir);
        } else {
            lib.linkLibC();
            lib.linkSystemLibrary("c++");
        }

        lib.addIncludeDir(base_path ++ "cimgui/imgui");
        lib.addIncludeDir(base_path ++ "cimgui/imgui/examples/libs/gl3w");
        lib.addIncludeDir("/usr/local/include/SDL2");

        lib.addCSourceFile(base_path ++ "cimgui/imgui/examples/libs/gl3w/GL/gl3w.c", &cpp_args);
        lib.addCSourceFile(base_path ++ "cimgui/imgui/examples/imgui_impl_opengl3.cpp", &cpp_args);
        lib.addCSourceFile(base_path ++ "cimgui/imgui/examples/imgui_impl_sdl.cpp", &cpp_args);
        lib.install();
        exe.linkLibrary(lib);
    } else if (build_impl_type == .object_files) {
        // use make to build the object files then include them
        _ = b.exec(&[_][]const u8{ "make", "-C", "gamekit/deps/imgui" }) catch unreachable;
        exe.addObjectFile(base_path ++ "build/gl3w.o");
        exe.addObjectFile(base_path ++ "build/imgui_impl_opengl3.o");
        exe.addObjectFile(base_path ++ "build/imgui_impl_sdl.o");
        exe.addCSourceFile(base_path ++ "cimgui/imgui/examples/imgui_impl_sdl.cpp", &cpp_args);
    } else if (build_impl_type == .exe) {
        // what we actually want to work but for some reason on macos it doesnt
        exe.addIncludeDir(base_path ++ "cimgui/imgui/examples/libs/gl3w");
        exe.addIncludeDir("/usr/local/include/SDL2");

        exe.addCSourceFile(base_path ++ "cimgui/imgui/examples/libs/gl3w/GL/gl3w.c", &cpp_args);
        exe.addCSourceFile(base_path ++ "cimgui/imgui/examples/imgui_impl_opengl3.cpp", &cpp_args);
        exe.addCSourceFile(base_path ++ "cimgui/imgui/examples/imgui_impl_sdl.cpp", &cpp_args);
    }
}

/// helper function to get SDK path on Mac
fn macosFrameworksDir(b: *Builder) ![]u8 {
    if (framework_dir) |dir| return dir;

    var str = try b.exec(&[_][]const u8{ "xcrun", "--show-sdk-path" });
    const strip_newline = std.mem.lastIndexOf(u8, str, "\n");
    if (strip_newline) |index| {
        str = str[0..index];
    }
    framework_dir = try std.mem.concat(b.allocator, u8, &[_][]const u8{ str, "/System/Library/Frameworks" });
    return framework_dir.?;
}

pub fn getImGuiPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "imgui",
        .path = prefix_path ++ "gamekit/deps/imgui/imgui.zig",
    };
}

pub fn getImGuiGlPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "imgui_gl",
        .path = prefix_path ++ "gamekit/deps/imgui/imgui_gl.zig",
        .dependencies = &[_]std.build.Pkg{getImGuiPackage(prefix_path)},
    };
}
