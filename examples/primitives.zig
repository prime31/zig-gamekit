const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
const Color = gk.math.Color;
const Vec2 = gk.math.Vec2;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {}

fn render() !void {
    gfx.beginPass(.{});
    // draw some text
    gfx.draw.text("The text rendering exists", 5, 20, null);

    gfx.draw.fontbook.setColor(Color.purple);
    gfx.draw.text("Purple text", 5, 40, null);
    gfx.draw.fontbook.setColor(Color.white);

    gfx.draw.fontbook.pushState();
    gfx.draw.fontbook.setBlur(1);
    gfx.draw.fontbook.setColor(Color.blue);
    gfx.draw.text("I'm some blurry blue text", 250, 95, null);
    gfx.draw.fontbook.popState();

    // render some primitives
    gfx.draw.line(Vec2.init(0, 0), Vec2.init(640, 480), 2, Color.blue);
    gfx.draw.point(Vec2.init(350, 350), 10, Color.sky_blue);
    gfx.draw.point(Vec2.init(380, 380), 15, Color.magenta);
    gfx.draw.rect(Vec2.init(387, 372), 40, 15, Color.dark_brown);
    gfx.draw.hollowRect(Vec2.init(430, 372), 40, 15, 2, Color.yellow);
    gfx.draw.circle(.{ .x = 400, .y = 300 }, 50, 3, 12, Color.orange);

    const poly = [_]Vec2{ .{ .x = 400, .y = 30 }, .{ .x = 420, .y = 10 }, .{ .x = 430, .y = 80 }, .{ .x = 410, .y = 60 }, .{ .x = 375, .y = 40 } };
    gfx.draw.hollowPolygon(poly[0..], 2, Color.lime);
    gfx.endPass();
}
