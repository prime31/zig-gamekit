const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
const Color = gk.math.Color;

pub const renderer: gk.renderkit.Renderer = .metal;

var mesh: gfx.Mesh = undefined;
var tex: gfx.Texture = undefined;
var pass: gfx.OffscreenPass = undefined;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {
    var vertices = [_]gfx.Vertex{
        .{ .pos = .{ .x = 10, .y = 10 }, .uv = .{ .x = 0, .y = 0 }, .col = 0xFF000000 }, // tl
        .{ .pos = .{ .x = 100, .y = 10 }, .uv = .{ .x = 1, .y = 0 }, .col = 0xFF000000 }, // tr
        .{ .pos = .{ .x = 100, .y = 100 }, .uv = .{ .x = 1, .y = 1 } }, // br
        .{ .pos = .{ .x = 10, .y = 100 }, .uv = .{ .x = 0, .y = 1 } }, // bl
    };
    var indices = [_]u16{ 0, 1, 2, 2, 3, 0 };
    mesh = gfx.Mesh.init(u16, indices[0..], gfx.Vertex, vertices[0..]);

    tex = try gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/bee-8.png", .nearest);
    mesh.bindImage(tex.img, 0);

    pass = gfx.OffscreenPass.init(300, 200);
}

var y: f32 = 0;
fn render() !void {
    // offscreen rendering
    gk.gfx.beginPass(.{ .color = gk.math.Color.purple, .pass = pass });
    var i: f32 = 0.0;
    while (i < 300) : (i += 40) {
        gfx.draw.tex(tex, .{ .x = i });
    }
    gk.gfx.endPass();

    // backbuffer rendering
    gfx.beginPass(.{ .color = Color.lime });
    gfx.draw.texScale(tex, .{ .x = 100, .y = 200 }, 2);
    gfx.draw.texScale(tex, .{ .x = 150, .y = 200 }, 2);

    // render the offscreen texture to the backbuffer
    y += 0.3;
    gfx.draw.tex(pass.color_texture, .{ .x = 400, .y = 0 + y });
    gfx.endPass();

    gfx.beginPass(.{ .color_action = .dont_care });
    mesh.draw();
    gfx.endPass();
}
