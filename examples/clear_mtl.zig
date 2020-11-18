const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
const Color = gk.math.Color;

pub const renderer: gk.renderkit.Renderer = .metal;

var mesh: gfx.Mesh = undefined;
var tex: gfx.Texture = undefined;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {
    var vertices = [_]gfx.Vertex{
        .{ .pos = .{ .x = 10, .y = 10 }, .uv = .{ .x = 0, .y = 1 } }, // bl
        .{ .pos = .{ .x = 100, .y = 10 }, .uv = .{ .x = 1, .y = 1 } }, // br
        .{ .pos = .{ .x = 100, .y = 100 }, .uv = .{ .x = 1, .y = 0 } }, // tr
        .{ .pos = .{ .x = 50, .y = 130 }, .uv = .{ .x = 0.5, .y = 0 } }, // tc
        .{ .pos = .{ .x = 10, .y = 100 }, .uv = .{ .x = 0, .y = 0 } }, // tl
        .{ .pos = .{ .x = 50, .y = 50 }, .uv = .{ .x = 0.5, .y = 0.5 } }, // c
    };
    var indices = [_]u16{ 0, 5, 4, 5, 3, 4, 5, 2, 3, 5, 1, 2, 5, 0, 1 };
    mesh = gfx.Mesh.init(u16, indices[0..], gfx.Vertex, vertices[0..]);

    tex = gfx.Texture.initSingleColor(0xFFFF00FF);
}

fn render() !void {
    gfx.beginPass(.{ .color = Color.lime });
    gfx.draw.texScale(tex, .{}, 100);
    gfx.draw.texScale(tex, .{ .x = 200, .y = 200 }, 3);
    gfx.endPass();

    gfx.beginPass(.{ .color_action = .dont_care });
    mesh.draw();
    gfx.endPass();
}
