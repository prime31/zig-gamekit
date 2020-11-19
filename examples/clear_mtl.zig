const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
const Color = gk.math.Color;

pub const renderer: gk.renderkit.Renderer = .metal;

var dyn_mesh: gfx.DynamicMesh(u16, gfx.Vertex) = undefined;
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

    var dyn_indices = [_]u16{ 0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4 };
    dyn_mesh = try gfx.DynamicMesh(u16, gfx.Vertex).init(std.testing.allocator, vertices.len * 2, &dyn_indices);
    std.mem.copy(gfx.Vertex, dyn_mesh.verts, &vertices);
    for (vertices) |vert, i| {
        dyn_mesh.verts[i + 4] = vert;
        dyn_mesh.verts[i + 4].pos.x += 50;
        dyn_mesh.verts[i + 4].pos.y += 50;
    }

    tex = try gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/bee-8.png", .nearest);
    mesh.bindImage(tex.img, 0);
    dyn_mesh.bindImage(tex.img, 0);

    pass = gfx.OffscreenPass.init(300, 200);
}

var y: f32 = 0;
fn render() !void {
    // offscreen rendering
    gk.gfx.beginPass(.{ .color = gk.math.Color.purple, .pass = pass });
    var i: f32 = 10.0;
    while (i < 280) : (i += 40) {
        gfx.draw.tex(tex, .{ .x = i });
    }
    gk.gfx.endPass();

    // backbuffer rendering
    gfx.beginPass(.{ .color = Color.lime });
    gfx.draw.texScale(tex, .{ .x = 100, .y = 200 }, 2);
    gfx.draw.texScale(tex, .{ .x = 150, .y = 200 }, 2);

    // render the offscreen texture to the backbuffer
    y += 0.3;
    gfx.draw.tex(pass.color_texture, .{ .x = 400, .y = y });
    gfx.endPass();

    // draw the dynamic mesh in two parts, appending data before each draw
    gfx.beginPass(.{ .color_action = .dont_care });
    {
        var j: usize = 0;
        while (j < 4) : (j += 1) {
            dyn_mesh.verts[j].pos = dyn_mesh.verts[j].pos.add(0.3, 0.3);
        }
        dyn_mesh.appendVertSlice(0, 4);
        dyn_mesh.draw(0, 6);

        while (j < 8) : (j += 1) {
            dyn_mesh.verts[j].pos = dyn_mesh.verts[j].pos.add(0.1, 0);
        }
        dyn_mesh.appendVertSlice(4, 4);
        dyn_mesh.draw(0, 6);
    }
    gfx.endPass();
}
