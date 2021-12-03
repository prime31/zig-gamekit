const std = @import("std");
const gk = @import("gamekit");
const math = gk.math;
const gfx = gk.gfx;
const draw = gfx.draw;

pub const renderer: gk.renderkit.Renderer = .opengl;
var rng = std.rand.DefaultPrng.init(0x12345678);

pub fn range(comptime T: type, at_least: T, less_than: T) T {
    if (@typeInfo(T) == .Int) {
        return rng.random().intRangeLessThanBiased(T, at_least, less_than);
    } else if (@typeInfo(T) == .Float) {
        return at_least + rng.random().float(T) * (less_than - at_least);
    }
    unreachable;
}

pub fn randomColor() u32 {
    const r = 200 + range(u8, 0, 55);
    const g = 200 + range(u8, 0, 55);
    const b = 200 + range(u8, 0, 55);
    return (r) | (@as(u32, g) << 8) | (@as(u32, b) << 16) | (@as(u32, 255) << 24);
}

const Thing = struct {
    texture: gfx.Texture,
    pos: math.Vec2,
    vel: math.Vec2,
    col: u32,

    pub fn init(tex: gfx.Texture) Thing {
        return .{
            .texture = tex,
            .pos = .{
                .x = range(f32, 0, 750),
                .y = range(f32, 0, 50),
            },
            .vel = .{
                .x = range(f32, 0, 0),
                .y = range(f32, 0, 50),
            },
            .col = randomColor(),
        };
    }
};

var texture: gfx.Texture = undefined;
var checker_tex: gfx.Texture = undefined;
var white_tex: gfx.Texture = undefined;
var things: []Thing = undefined;
var pass: gfx.OffscreenPass = undefined;
var rt_pos: math.Vec2 = .{};
var camera: gk.utils.Camera = undefined;

pub fn main() !void {
    rng.seed(@intCast(u64, std.time.milliTimestamp()));
    try gk.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    camera = gk.utils.Camera.init();
    const size = gk.window.size();
    camera.pos = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };

    texture = gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/bee-8.png", .nearest) catch unreachable;
    checker_tex = gfx.Texture.initCheckerTexture();
    white_tex = gfx.Texture.initSingleColor(0xFFFFFFFF);
    things = makeThings(12, texture);
    pass = gfx.OffscreenPass.init(300, 200);
}

fn update() !void {
    for (things) |*thing| {
        thing.pos.x += thing.vel.x * gk.time.dt();
        thing.pos.y += thing.vel.y * gk.time.dt();
    }

    rt_pos.x += 0.5;
    rt_pos.y += 0.5;

    if (gk.input.keyDown(.a)) {
        camera.pos.x += 100 * gk.time.dt();
    } else if (gk.input.keyDown(.d)) {
        camera.pos.x -= 100 * gk.time.dt();
    }
    if (gk.input.keyDown(.w)) {
        camera.pos.y -= 100 * gk.time.dt();
    } else if (gk.input.keyDown(.s)) {
        camera.pos.y += 100 * gk.time.dt();
    }
}

fn render() !void {
    // offscreen rendering
    gk.gfx.beginPass(.{ .color = math.Color.purple, .pass = pass });
    draw.tex(texture, .{ .x = 10 + range(f32, -5, 5) });
    draw.tex(texture, .{ .x = 50 + range(f32, -5, 5) });
    draw.tex(texture, .{ .x = 90 + range(f32, -5, 5) });
    draw.tex(texture, .{ .x = 130 + range(f32, -5, 5) });
    gk.gfx.endPass();

    // backbuffer rendering
    gk.gfx.beginPass(.{
        .color = math.Color{ .value = randomColor() },
        .trans_mat = camera.transMat(),
    });

    // render the offscreen texture to the backbuffer
    draw.tex(pass.color_texture, rt_pos);

    for (things) |thing| {
        draw.tex(thing.texture, thing.pos);
    }

    draw.texScale(checker_tex, .{ .x = 350, .y = 50 }, 12);
    draw.point(.{ .x = 400, .y = 300 }, 20, math.Color.orange);
    draw.texScale(checker_tex, .{ .x = 0, .y = 0 }, 12.5); // bl
    draw.texScale(checker_tex, .{ .x = 800 - 50, .y = 0 }, 12.5); // br
    draw.texScale(checker_tex, .{ .x = 800 - 50, .y = 600 - 50 }, 12.5); // tr
    draw.texScale(checker_tex, .{ .x = 0, .y = 600 - 50 }, 12.5); // tl

    gk.gfx.endPass();
}

fn makeThings(n: usize, tex: gfx.Texture) []Thing {
    var the_things = std.testing.allocator.alloc(Thing, n) catch unreachable;

    for (the_things) |*thing| {
        thing.* = Thing.init(tex);
    }

    return the_things;
}
