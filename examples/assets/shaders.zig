const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
const math = gk.math;
const renderkit = gk.renderkit;

pub const Mode7Shader = gfx.ShaderState(Mode7Params);

pub fn createMode7Shader() Mode7Shader {
    const frag = @embedFile("shaders/mode7_fs.glsl");
    return Mode7Shader.init(.{ .frag = frag, .onPostBind = Mode7Shader.onPostBind });
}

pub fn createMrtShader() !gfx.Shader {
    const vert = @embedFile("shaders/sprite_vs.glsl");
    const frag = @embedFile("shaders/mrt_fs.glsl");
    return try gfx.Shader.initWithVertFrag(VertexParams, struct { pub const metadata = .{ .images = .{ "main_tex" } }; }, .{ .frag = frag, .vert = vert });
}

pub fn createVertSwayShader() !gfx.Shader {
    const vert = @embedFile("shaders/vert_sway_vs.glsl");
    const frag = @embedFile("shaders/sprite_fs.glsl");
    return try gfx.Shader.initWithVertFrag(VertexSwayParams, struct { pub const metadata = .{ .images = .{ "main_tex" } }; }, .{ .frag = frag, .vert = vert });
}


pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,
};

pub const VertexSwayParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexSwayParams = .{ .type = .float4, .array_count = 3 } },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,
    time: f32 = 0,
    _pad36_0_: [12]u8 = [_]u8{0} ** 12,
};

pub const Mode7Params = extern struct {
    pub const metadata = .{
        .images = .{ "main_tex", "map_tex" },
        .uniforms = .{ .Mode7Params = .{ .type = .float4, .array_count = 3 } },
    };

    mapw: f32 = 0,
    maph: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    zoom: f32 = 0,
    fov: f32 = 0,
    offset: f32 = 0,
    wrap: f32 = 0,
    x1: f32 = 0,
    x2: f32 = 0,
    y1: f32 = 0,
    y2: f32 = 0,
};

