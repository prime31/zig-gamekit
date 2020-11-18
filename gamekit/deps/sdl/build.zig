const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("sdl2");

    if (std.builtin.os.tag == .windows) {
        // Windows include dirs for SDL2. This requires downloading SDL2 dev and extracting to c:\SDL2
        exe.addLibPath("c:\\SDL2\\lib\\x64");

        // SDL2.dll needs to be copied to the zig-cache/bin folder
        // TODO: installFile doesnt seeem to work so manually copy the file over
        b.installFile("c:\\SDL2\\lib\\x64\\SDL2.dll", "bin\\SDL2.dll");

        std.fs.cwd().makePath("zig-cache\\bin") catch unreachable;
        const src_dir = std.fs.cwd().openDir("c:\\SDL2\\lib\\x64", .{}) catch unreachable;
        src_dir.copyFile("SDL2.dll", std.fs.cwd(), "zig-cache\\bin\\SDL2.dll", .{}) catch unreachable;
    }

    exe.addPackage(getPackage(prefix_path));
}

pub fn getPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "sdl",
        .path = prefix_path ++ "gamekit/deps/sdl/sdl.zig",
    };
}