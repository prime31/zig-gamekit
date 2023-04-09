const std = @import("std");
const gk = @import("../gamekit.zig");
const math = gk.math;
const rk = gk.renderkit;
const fs = gk.utils.fs;

/// default params for the sprite shader. Translates the Mat32 into 2 arrays of f32 for the shader uniform slot.
pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
        .images = .{"main_tex"},
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,

    pub fn init(mat: *math.Mat32) VertexParams {
        var params = VertexParams{};
        std.mem.copy(f32, &params.transform_matrix, &mat.data);
        return params;
    }
};

fn defaultVertexShader() [:0]const u8 {
    return @embedFile("../assets/sprite_vs.glsl");
}

fn defaultFragmentShader() [:0]const u8 {
    return @embedFile("../assets/sprite_fs.glsl");
}

pub const Shader = struct {
    shader: rk.ShaderProgram,
    onPostBind: ?*const fn (*Shader) void,
    onSetTransformMatrix: ?*const fn (*math.Mat32) void,

    const Empty = struct {};

    pub const ShaderOptions = struct {
        /// if vert and frag are file paths an Allocator is required. If they are the shader code then no Allocator should be provided
        allocator: ?std.mem.Allocator = null,

        /// optional vertex shader file path (without extension) or shader code. If null, the default sprite shader vertex shader is used
        vert: ?[:0]const u8 = null,

        /// required frag shader file path (without extension) or shader code.
        frag: [:0]const u8,

        /// optional function that will be called immediately after bind is called allowing you to auto-update uniforms
        onPostBind: ?*const fn (*Shader) void = null,

        /// optional function that lets you override the behavior when the transform matrix is set. This is used when there is a
        /// custom vertex shader and isnt necessary if the standard sprite vertex shader is used. Note that the shader is already
        /// bound when this is called if `gfx.setShader` is used so send your uniform immediately!
        onSetTransformMatrix: ?*const fn (*math.Mat32) void = null,
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
                    const vert_path = try std.mem.concat(allocator, u8, &[_][]const u8{ vert, ".glsl\x00" });
                    defer allocator.free(vert_path);
                    break :blk try fs.readZ(allocator, vert_path);
                }
                break :blk vert;
            } else {
                break :blk defaultVertexShader();
            }
        };
        const frag = blk: {
            if (options.allocator) |allocator| {
                const frag_path = try std.mem.concat(allocator, u8, &[_][]const u8{ options.frag, ".glsl" });
                defer allocator.free(frag_path);
                break :blk try fs.readZ(allocator, frag_path);
            }
            break :blk options.frag;
        };

        return Shader{
            .shader = rk.createShaderProgram(VertUniformT, FragUniformT, .{ .vs = vert, .fs = frag }),
            .onPostBind = options.onPostBind,
            .onSetTransformMatrix = options.onSetTransformMatrix,
        };
    }

    pub fn deinit(self: Shader) void {
        rk.destroyShaderProgram(self.shader);
    }

    pub fn bind(self: *Shader) void {
        rk.useShaderProgram(self.shader);
        if (self.onPostBind) |onPostBind| onPostBind(self);
    }

    pub fn setTransformMatrix(self: Shader, matrix: *math.Mat32) void {
        if (self.onSetTransformMatrix) |setMatrix| {
            setMatrix(matrix);
        } else {
            var params = VertexParams.init(matrix);
            self.setVertUniform(VertexParams, &params);
        }
    }

    pub fn setVertUniform(self: Shader, comptime VertUniformT: type, value: *VertUniformT) void {
        rk.setShaderProgramUniformBlock(VertUniformT, self.shader, .vs, value);
    }

    pub fn setFragUniform(self: Shader, comptime FragUniformT: type, value: *FragUniformT) void {
        rk.setShaderProgramUniformBlock(FragUniformT, self.shader, .fs, value);
    }
};

/// convenience object that binds a fragment uniform with a Shader. You can optionally wire up the onPostBind method
/// to the Shader.onPostBind so that the FragUniformT object is automatically updated when the Shader is bound.
pub fn ShaderState(comptime FragUniformT: type) type {
    return struct {
        shader: Shader,
        frag_uniform: FragUniformT = .{},

        pub fn init(options: Shader.ShaderOptions) @This() {
            return .{
                .shader = Shader.initWithFrag(FragUniformT, options) catch unreachable,
            };
        }

        pub fn deinit(self: @This()) void {
            self.shader.deinit();
        }

        pub fn onPostBind(shader: *Shader) void {
            const self = @fieldParentPtr(@This(), "shader", shader);
            shader.setFragUniform(FragUniformT, &self.frag_uniform);
        }
    };
}
