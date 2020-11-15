const std = @import("std");
const renderkit = @import("renderkit");
const renderer = renderkit.renderer;
const fs = @import("../gamekit.zig").utils.fs;

pub const Shader = struct {
    shader: renderkit.ShaderProgram,

    pub fn initFromFile(allocator: *std.mem.Allocator, vert_path: []const u8, frag_path: []const u8) !Shader {
        var vert = try fs.readZ(allocator, vert_path);
        errdefer allocator.free(vert);
        var frag = try fs.readZ(allocator, frag_path);
        errdefer allocator.free(frag);

        return try Shader.init(vert, frag);
    }

    pub fn init(vert: [:0]const u8, frag: [:0]const u8) !Shader {
        return Shader{ .shader = renderer.createShaderProgram(void, .{.vs = vert, .fs = frag}) };
    }

    pub fn deinit(self: Shader) void {
        renderer.destroyShaderProgram(self.shader);
    }

    pub fn bind(self: Shader) void {
        renderer.useShaderProgram(self.shader);
    }

    pub fn setUniformName(self: Shader, comptime T: type, name: [:0]const u8, value: T) void {
        renderer.setShaderProgramUniform(T, self.shader, name, value);
    }

    pub fn setUniform(self: *Shader, comptime T: type, location: c_int, value: T) void {
        // TODO: need a matching getUniformLocation before this is useful
        unreachable;
    }
};
