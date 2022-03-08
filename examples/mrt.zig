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
        .init = init,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    checker_tex = gfx.Texture.initCheckerTexture();
    pass = gfx.OffscreenPass.initMrt(300, 200, 2);
    shader = shaders.createMrtShader() catch unreachable;
}

fn render() !void {
    // offscreen rendering
    gk.gfx.beginPass(.{ .color = math.Color.sky_blue, .pass = pass });
    draw.texScale(checker_tex, .{ .x = 260, .y = 70 }, 12.5);
    gk.gfx.endPass();

    // backbuffer rendering
    gk.gfx.beginPass(.{ .color = gk.math.Color.beige });
    draw.tex(pass.color_texture, .{ .y = 100 });
    draw.tex(pass.color_texture2.?, .{ .x = 400, .y = 50 });
    gk.gfx.endPass();
}

fn shutdown() !void {
    checker_tex.deinit();
    pass.deinit();
    shader.deinit();
}
