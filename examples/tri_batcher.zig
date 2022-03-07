const std = @import("std");
const gk = @import("gamekit");
const math = gk.math;
const Color = math.Color;

var tri_batch: gk.gfx.TriangleBatcher = undefined;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {
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
