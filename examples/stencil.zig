const std = @import("std");
const gl = @import("renderkit").gl;
const gk = @import("gamekit");
const math = gk.math;
const gfx = gk.gfx;
const draw = gfx.draw;

const Thing = struct {
    dir: f32,
    pos: math.Vec2 = .{},
    col: math.Color,
};

var white_tex: gfx.Texture = undefined;
var pass: gfx.OffscreenPass = undefined;
var points: [2]Thing = [_]Thing{
    .{ .dir = 1, .pos = .{ .x = 60, .y = 300 }, .col = math.Color.red },
    .{ .dir = -1, .pos = .{ .x = 600, .y = 300 }, .col = math.Color.blue },
};

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    white_tex = gfx.Texture.initSingleColor(0xFFFFFFFF);

    const size = gk.window.size();
    pass = gfx.OffscreenPass.initWithStencil(size.w, size.h, .nearest, .clamp);
}

fn update() !void {
    const speed: f32 = 5;
    const size = gk.window.size();
    for (points) |*p| {
        p.pos.x += p.dir * speed;
        if (p.pos.x + 30 > @intToFloat(f32, size.w)) p.dir *= -1;
        if (p.pos.x - 30 < 0) p.dir *= -1;
    }
}

fn render() !void {
    // offscreen rendering. set stencil to write
    gfx.setRenderState(.{
        .stencil = .{
            .enabled = true,
            .write_mask = 0xFF,
            .compare_func = .always,
            .ref = 1,
            .read_mask = 0xFF,
        }
    });
    gk.gfx.beginPass(.{
        .color = math.Color.purple,
        .pass = pass,
        .clear_stencil = true,
    });
    draw.point(points[0].pos, 160, points[0].col);
    gk.gfx.endPass();

    // set stencil to read
    gfx.setRenderState(.{
        .stencil = .{
            .enabled = true,
            .write_mask = 0x00, // disable writing to stencil
            .compare_func = .equal,
            .ref = 1,
            .read_mask = 0xFF,
        }
    });
    gk.gfx.beginPass(.{
        .clear_color = false,
        .clear_stencil = false,
        .pass = pass,
    });
    draw.point(points[1].pos, 60, points[1].col);
    gk.gfx.endPass();

    // backbuffer rendering, reset stencil
    gfx.setRenderState(.{});
    gk.gfx.beginPass(.{});
    draw.tex(pass.color_texture, .{});
    gk.gfx.endPass();
}
