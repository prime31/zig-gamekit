const std = @import("std");
const gfx = @import("gfx.zig");
const renderkit = @import("renderkit");
const gk = @import("gamekit.zig");
const math = gk.math;

const Texture = gfx.Texture;

pub const draw = struct {
    pub var batcher: gfx.Batcher = undefined;
    pub var fontbook: *gfx.FontBook = undefined;

    var quad: math.Quad = math.Quad.init(0, 0, 1, 1, 1, 1);
    var white_tex: Texture = undefined;

    pub fn init() void {
        white_tex = Texture.initSingleColor(0xFFFFFFFF);
        batcher = gfx.Batcher.init(std.testing.allocator, 1000);

        fontbook = gfx.FontBook.init(std.testing.allocator, 128, 128, .nearest) catch unreachable;
        _ = fontbook.addFontMem("ProggyTiny", @embedFile("assets/ProggyTiny.ttf"), false);
        fontbook.setSize(10);
    }

    pub fn deinit() void {
        batcher.deinit();
        white_tex.deinit();
    }

    /// binds a Texture to the Bindings in the Batchers DynamicMesh
    pub fn bindTexture(texture: Texture, slot: c_uint) void {
        batcher.mesh.bindImage(texture.img, slot);
    }

    /// unbinds a previously bound texture. All texture slots > 0 must be unbound manually!
    pub fn unbindTexture(slot: c_uint) void {
        batcher.mesh.bindImage(0, slot);
    }

    // Drawing
    pub fn tex(texture: Texture, position: math.Vec2) void {
        quad.setFill(texture.width, texture.height);

        var mat = math.Mat32.initTransform(.{ .x = position.x, .y = position.y });
        batcher.draw(texture, quad, mat, math.Color.white);
    }

    pub fn texScale(texture: Texture, position: math.Vec2, scale: f32) void {
        quad.setFill(texture.width, texture.height);

        var mat = math.Mat32.initTransform(.{ .x = position.x, .y = position.y, .sx = scale, .sy = scale });
        batcher.draw(texture, quad, mat, math.Color.white);
    }

    pub fn texScaleOrigin(texture: Texture, x: f32, y: f32, scale: f32, ox: f32, oy: f32) void {
        quad.setFill(texture.width, texture.height);

        var mat = math.Mat32.initTransform(.{ .x = x, .y = y, .sx = scale, .sy = scale, .ox = ox, .oy = oy });
        batcher.draw(texture, quad, mat, math.Color.white);
    }

    pub fn texViewport(texture: Texture, viewport: math.RectI, transform: math.Mat32) void {
        quad.setImageDimensions(texture.width, texture.height);
        quad.setViewportRectI(viewport);
        batcher.draw(texture, quad, transform, math.Color.white);
    }

    pub fn text(str: []const u8, x: f32, y: f32, fb: ?*gfx.FontBook) void {
        var book = fb orelse fontbook;
        // TODO: dont hardcode scale as 4
        var matrix = math.Mat32.initTransform(.{ .x = x, .y = y, .sx = 2, .sy = 2 });

        var fons_quad = book.getQuad();
        var iter = book.getTextIterator(str);
        while (book.textIterNext(&iter, &fons_quad)) {
            quad.positions[0] = .{ .x = fons_quad.x0, .y = fons_quad.y0 };
            quad.positions[1] = .{ .x = fons_quad.x1, .y = fons_quad.y0 };
            quad.positions[2] = .{ .x = fons_quad.x1, .y = fons_quad.y1 };
            quad.positions[3] = .{ .x = fons_quad.x0, .y = fons_quad.y1 };

            quad.uvs[0] = .{ .x = fons_quad.s0, .y = fons_quad.t0 };
            quad.uvs[1] = .{ .x = fons_quad.s1, .y = fons_quad.t0 };
            quad.uvs[2] = .{ .x = fons_quad.s1, .y = fons_quad.t1 };
            quad.uvs[3] = .{ .x = fons_quad.s0, .y = fons_quad.t1 };

            batcher.draw(book.texture.?, quad, matrix, math.Color{ .value = iter.color });
        }
    }

    pub fn textOptions(str: []const u8, fb: ?*gfx.FontBook, options: struct { x: f32, y: f32, rot: f32 = 0, sx: f32 = 1, sy: f32 = 1, alignment: gfx.FontBook.Align = .default, color: math.Color = math.Color.White }) void {
        var book = fb orelse fontbook;
        var matrix = math.Mat32.initTransform(.{ .x = options.x, .y = options.y, .angle = options.rot, .sx = options.sx, .sy = options.sy });
        book.setAlign(options.alignment);

        var fons_quad = book.getQuad();
        var iter = book.getTextIterator(str);
        while (book.textIterNext(&iter, &fons_quad)) {
            quad.positions[0] = .{ .x = fons_quad.x0, .y = fons_quad.y0 };
            quad.positions[1] = .{ .x = fons_quad.x1, .y = fons_quad.y0 };
            quad.positions[2] = .{ .x = fons_quad.x1, .y = fons_quad.y1 };
            quad.positions[3] = .{ .x = fons_quad.x0, .y = fons_quad.y1 };

            quad.uvs[0] = .{ .x = fons_quad.s0, .y = fons_quad.t0 };
            quad.uvs[1] = .{ .x = fons_quad.s1, .y = fons_quad.t0 };
            quad.uvs[2] = .{ .x = fons_quad.s1, .y = fons_quad.t1 };
            quad.uvs[3] = .{ .x = fons_quad.s0, .y = fons_quad.t1 };

            batcher.draw(book.texture.?, quad, matrix, options.color);
        }
    }

    pub fn point(position: math.Vec2, size: f32, color: math.Color) void {
        quad.setFill(size, size);

        const offset = if (size == 1) 0 else size * 0.5;
        var mat = math.Mat32.initTransform(.{ .x = position.x, .y = position.y, .ox = offset, .oy = offset });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn line(start: math.Vec2, end: math.Vec2, thickness: f32, color: math.Color) void {
        quad.setFill(1, 1);

        const angle = start.angleBetween(end);
        const length = start.distance(end);

        var mat = math.Mat32.initTransform(.{ .x = start.x, .y = start.y, .angle = angle, .sx = length, .sy = thickness });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn rect(position: math.Vec2, width: f32, height: f32, color: math.Color) void {
        quad.setFill(width, height);
        var mat = math.Mat32.initTransform(.{ .x = position.x, .y = position.y });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn hollowRect(position: math.Vec2, width: f32, height: f32, thickness: f32, color: math.Color) void {
        const tr = math.Vec2{ .x = position.x + width, .y = position.y };
        const br = math.Vec2{ .x = position.x + width, .y = position.y + height };
        const bl = math.Vec2{ .x = position.x, .y = position.y + height };

        line(position, tr, thickness, color);
        line(tr, br, thickness, color);
        line(br, bl, thickness, color);
        line(bl, position, thickness, color);
    }

    pub fn circle(center: math.Vec2, radius: f32, thickness: f32, resolution: i32, color: math.Color) void {
        quad.setFill(white_tex.width, white_tex.height);

        var last = math.Vec2.init(1, 0).scale(radius);
        var last_p = last.orthogonal();

        var i: usize = 0;
        while (i <= resolution) : (i += 1) {
            const at = math.Vec2.angleToVec(@intToFloat(f32, i) * std.math.pi * 0.5 / @intToFloat(f32, resolution), radius);
            const at_p = at.orthogonal();

            line(center.addv(last), center.addv(at), thickness, color);
            line(center.subv(last), center.subv(at), thickness, color);
            line(center.addv(last_p), center.addv(at_p), thickness, color);
            line(center.subv(last_p), center.subv(at_p), thickness, color);

            last = at;
            last_p = at_p;
        }
    }

    pub fn hollowPolygon(verts: []const math.Vec2, thickness: f32, color: math.Color) void {
        var i: usize = 0;
        while (i < verts.len - 1) : (i += 1) {
            line(verts[i], verts[i + 1], thickness, color);
        }
        line(verts[verts.len - 1], verts[0], thickness, color);
    }
};
