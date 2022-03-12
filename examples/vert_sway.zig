const std = @import("std");
const shaders = @import("assets/shaders.zig");
const gk = @import("gamekit");
const gfx = gk.gfx;
const Color = gk.math.Color;

var tex: gfx.Texture = undefined;
var shader: gfx.Shader = undefined;
var vs_params: shaders.VertexSwayParams = shaders.VertexSwayParams{
    .time = 1,
};

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    tex = try gfx.Texture.initFromFile(std.heap.c_allocator, "examples/assets/textures/tree.png", .linear);
    shader = try shaders.createVertSwayShader();
}

fn shutdown() !void {
    tex.deinit();
    shader.deinit();
}

fn update() !void {
    std.mem.copy(f32, &vs_params.transform_matrix, &gfx.state.transform_mat.data);
    vs_params.time = @floatCast(f32, gk.time.toSeconds(gk.time.now()));
}

fn render() !void {
    gfx.beginPass(.{ .color = Color.blue, .shader = &shader });
    shader.setVertUniform(shaders.VertexSwayParams, &vs_params);
    gfx.draw.tex(tex, .{ .x = 300, .y = 200 });
    gfx.endPass();
}
