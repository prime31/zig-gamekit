const std = @import("std");
const gk = @import("../gamekit.zig");
const rk = gk.renderkit;
const renderer = rk.renderer;
const fs = gk.utils.fs;

const VertexParams = gk.gfx.VertexParams;

fn defaultVertexShader() [:0]const u8 {
    return switch (rk.current_renderer) {
        .opengl => @embedFile("../assets/sprite_vs.glsl"),
        .metal => @embedFile("../assets/sprite_vs.metal"),
        else => @panic("no default vert shader for renderer: " ++ renderkit.current_renderer),
    };
}

fn defaultFragmentShader() [:0]const u8 {
    return switch (rk.current_renderer) {
        .opengl => @embedFile("../assets/sprite_fs.glsl"),
        .metal => @embedFile("../assets/sprite_fs.metal"),
        else => @panic("no default vert shader for renderer: " ++ renderkit.current_renderer),
    };
}

pub const Shader = struct {
    shader: rk.ShaderProgram,

    const Empty = struct {};

    pub const ShaderOptions = struct {
        /// if vert and frag are file paths an Allocator is required. If they are the shader code then no Allocator should be provided
        allocator: ?*std.mem.Allocator = null,
        /// optional vertex shader file path or shader code. If null, the default sprite shader vertex shader is used
        vert: ?[:0]const u8 = null,
        frag: [:0]const u8,
    };

    pub fn initDefaultSpriteShader() !Shader {
        return initWithVertFrag(VertexParams, Empty, .{ .vert = defaultVertexShader(), .frag = defaultFragmentShader() });
    }

    pub fn initWithFrag(comptime FragUniformT: type, options: ShaderOptions) !Shader {
        return initWithVertFrag(VertexParams, FragUniformT, options);
    }

    pub fn initWithVertFrag(comptime VertUniformT: type, comptime FragUniformT: type, options: ShaderOptions) !Shader {
        const vert = blk: {
            // if we were not provided a vert shader we substitute in the sprite shader
            if (options.vert) |vert| {
                // if we were provided an allocator that means this is a file
                if (options.allocator) |allocator| {
                    break :blk try fs.readZ(allocator, vert);
                }
                break :blk vert;
            } else {
                break :blk defaultVertexShader();
            }
        };
        const frag = blk: {
            if (options.allocator) |allocator| {
                break :blk try fs.readZ(allocator, options.frag);
            }
            break :blk options.frag;
        };
        return Shader{ .shader = renderer.createShaderProgram(VertUniformT, FragUniformT, .{ .vs = vert, .fs = frag }) };
    }

    pub fn deinit(self: Shader) void {
        renderer.destroyShaderProgram(self.shader);
    }

    pub fn bind(self: Shader) void {
        renderer.useShaderProgram(self.shader);
    }

    pub fn setVertUniform(self: Shader, comptime VertUniformT: type, value: *VertUniformT) void {
        renderer.setShaderProgramUniformBlock(VertUniformT, self.shader, .vs, value);
    }

    pub fn setFragUniform(self: Shader, comptime FragUniformT: type, value: *FragUniformT) void {
        renderer.setShaderProgramUniformBlock(FragUniformT, self.shader, .fs, value);
    }
};
