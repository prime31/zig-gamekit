const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    exe.linkLibC();
    exe.addIncludeDir(prefix_path ++ "gamekit/deps/stb/src");

    const lib_cflags = &[_][]const u8{"-std=c99"};
    exe.addCSourceFile(prefix_path ++ "gamekit/deps/stb/src/stb_impl.c", lib_cflags);

    exe.addPackage(getPackage(prefix_path));
}

pub fn getPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "stb",
        .path = prefix_path ++ "gamekit/deps/stb/stb.zig",
    };
}
