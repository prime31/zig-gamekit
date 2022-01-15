const std = @import("std");
const gk = @import("gamekit");
const Color = gk.math.Color;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {}

fn render() !void {
    gk.gfx.beginPass(.{ .color = Color.lime });
    gk.gfx.endPass();
}
