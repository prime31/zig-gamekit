const std = @import("std");
const shaders = @import("assets/shaders.zig");
const gk = @import("gamekit");
const math = gk.math;
const gfx = gk.gfx;
const draw = gfx.draw;

var checker_tex: gfx.Texture = undefined;
var pass: gfx.OffscreenPass = undefined;
var shader: gfx.Shader = undefined;

pub fn main() !void {
    try gk.run(.{
        .window = .{
            .resizable = false,
        },
        .init = init,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    checker_tex = gfx.Texture.initCheckerTexture();
    pass = gfx.OffscreenPass.initMrt(400, 300, 2);
    shader = shaders.createMrtShader() catch unreachable;
}

fn render() !void {
    // offscreen rendering
    gk.gfx.beginPass(.{ .color = math.Color.sky_blue, .shader = &shader, .pass = pass });
    draw.texScale(checker_tex, .{ .x = 260, .y = 70 }, 12.5);
    draw.point(.{ .x = 20, .y = 20 }, 40, math.Color.yellow);
    gk.gfx.endPass();

    // backbuffer rendering
    gk.gfx.beginPass(.{ .color = gk.math.Color.beige });
    draw.tex(pass.color_texture, .{});
    draw.tex(pass.color_texture2.?, .{ .x = 400, .y = 300 });
    gk.gfx.endPass();
}

fn shutdown() !void {
    checker_tex.deinit();
    pass.deinit();
    shader.deinit();
}
