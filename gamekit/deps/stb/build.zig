const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *std.build.Builder) !void {
    _ = b;
}

pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    _ = b;
    _ = target;
    exe.linkLibC();
    exe.addIncludePath(prefix_path ++ "gamekit/deps/stb/src");

    const lib_cflags = &[_][]const u8{"-std=c99"};
    exe.addCSourceFile(prefix_path ++ "gamekit/deps/stb/src/stb_impl.c", lib_cflags);
}

pub fn getModule(b: *std.Build, comptime prefix_path: []const u8) *std.build.Module {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");
    return b.createModule(.{
        .source_file = .{ .path = prefix_path ++ "gamekit/deps/stb/stb.zig" },
    });
}
