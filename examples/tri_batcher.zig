const std = @import("std");
const gk = @import("gamekit");
const math = gk.math;
const Color = math.Color;

var shader: gk.gfx.Shader = undefined;
var tri_batch: gk.gfx.TriangleBatcher = undefined;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {
    shader = try gk.gfx.Shader.initFromFile(std.testing.allocator, "examples/assets/shaders/vert.vs", "examples/assets/shaders/frag.fs");
    shader.bind();
    shader.setUniformName(i32, "MainTex", 0);
    shader.setUniformName(math.Mat32, "TransformMatrix", math.Mat32.initOrtho(800, 600));

    tri_batch = try gk.gfx.TriangleBatcher.init(std.testing.allocator, 100);
}

fn render() !void {
    gk.gfx.beginPass(.{});

    tri_batch.begin();
    tri_batch.drawTriangle(.{ .x = 50, .y = 50 }, .{ .x = 150, .y = 150 }, .{ .x = 0, .y = 150 }, Color.sky_blue);
    tri_batch.drawTriangle(.{ .x = 300, .y = 50 }, .{ .x = 350, .y = 150 }, .{ .x = 200, .y = 150 }, Color.lime);
    tri_batch.end();

    gk.gfx.endPass();
}
