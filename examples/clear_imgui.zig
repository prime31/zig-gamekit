const std = @import("std");
const gk = @import("gamekit");
const gfx = gk.gfx;
usingnamespace @import("imgui");

pub const renderer: gk.renderkit.Renderer = .opengl;
pub const enable_imgui = true;

var clear_color = gk.math.Color.aya;
var camera: gk.utils.Camera = undefined;
var tex: gfx.Texture = undefined;

pub fn main() !void {
    try gk.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    camera = gk.utils.Camera.init();
    tex = gfx.Texture.initSingleColor(0xFFFF00FF);
}

fn update() !void {
    igShowDemoWindow(null);

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
    gfx.beginPass(.{ .color = clear_color, .trans_mat = camera.transMat() });

    igText("WASD moves camera");

    var color = clear_color.asArray();
    if (igColorEdit4("Clear Color", &color[0], ImGuiColorEditFlags_NoInputs)) {
        clear_color = gk.math.Color.fromRgba(color[0], color[1], color[2], color[3]);
    }

    var buf: [255]u8 = undefined;
    var str = try std.fmt.bufPrintZ(&buf, "Camera Pos: {d:.2}, {d:.2}", .{ camera.pos.x, camera.pos.y });
    igText(str);

    var mouse = gk.input.mousePos();
    var world = camera.screenToWorld(mouse);

    str = try std.fmt.bufPrintZ(&buf, "Mouse Pos: {d:.2}, {d:.2}", .{ mouse.x, mouse.y });
    igText(str);

    str = try std.fmt.bufPrintZ(&buf, "World Pos: {d:.2}, {d:.2}", .{ world.x, world.y });
    igText(str);

    if (ogButton("Camera Pos to 0,0")) camera.pos = .{};
    if (ogButton("Camera Pos to screen center")) {
        const size = gk.window.size();
        camera.pos = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };
    }

    gfx.draw.point(.{}, 40, gk.math.Color.white);

    gfx.endPass();
}
