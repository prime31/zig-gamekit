const std = @import("std");
const renderkit = @import("renderkit");
const gk = @import("../gamekit.zig");
const math = gk.math;

const IndexBuffer = renderkit.IndexBuffer;
const VertexBuffer = renderkit.VertexBuffer;
const Vertex = gk.gfx.Vertex;
const Texture = gk.gfx.Texture;

pub const Batcher = struct {
    mesh: gk.gfx.DynamicMesh(Vertex, u16),
    vert_index: usize = 0, // current index into the vertex array
    current_image: renderkit.Image = std.math.maxInt(renderkit.Image),

    pub fn init(allocator: *std.mem.Allocator, max_sprites: usize) Batcher {
        if (max_sprites * 6 > std.math.maxInt(u16)) @panic("max_sprites exceeds u16 index buffer size");

        var indices = allocator.alloc(u16, max_sprites * 6) catch unreachable;
        defer allocator.free(indices);
        var i: usize = 0;
        while (i < max_sprites) : (i += 1) {
            indices[i * 3 * 2 + 0] = @intCast(u16, i) * 4 + 0;
            indices[i * 3 * 2 + 1] = @intCast(u16, i) * 4 + 1;
            indices[i * 3 * 2 + 2] = @intCast(u16, i) * 4 + 2;
            indices[i * 3 * 2 + 3] = @intCast(u16, i) * 4 + 0;
            indices[i * 3 * 2 + 4] = @intCast(u16, i) * 4 + 2;
            indices[i * 3 * 2 + 5] = @intCast(u16, i) * 4 + 3;
        }

        return .{
            .mesh = gk.gfx.DynamicMesh(Vertex, u16).init(allocator, max_sprites * 4, indices) catch unreachable,
        };
    }

    pub fn deinit(self: *Batcher) void {
        self.mesh.deinit();
    }

    pub fn begin(self: *Batcher) void {
        self.vert_index = 0;
    }

    pub fn end(self: *Batcher) void {
        self.flush();
    }

    pub fn flush(self: *Batcher) void {
        if (self.vert_index == 0) return;

        // send data
        self.mesh.updateVertSlice(0, self.vert_index);

        // bind texture
        self.mesh.bindImage(self.current_image, 0);

        // draw
        const quads = @divExact(self.vert_index, 4);
        self.mesh.draw(@intCast(c_int, quads * 6));

        // reset
        self.vert_index = 0;
    }

    pub fn drawTex(self: *Batcher, pos: math.Vec2, col: u32, texture: Texture) void {
        if (self.vert_index >= self.mesh.verts.len or self.current_image != texture.img) {
            self.flush();
        }

        self.current_image = texture.img;

        var verts = self.mesh.verts[self.vert_index .. self.vert_index + 4];
        verts[0].pos = pos; // tl
        verts[0].uv = .{ .x = 0, .y = 0 };
        verts[0].col = col;

        verts[1].pos = .{ .x = pos.x + texture.width, .y = pos.y }; // tr
        verts[1].uv = .{ .x = 1, .y = 0 };
        verts[1].col = col;

        verts[2].pos = .{ .x = pos.x + texture.width, .y = pos.y + texture.height }; // br
        verts[2].uv = .{ .x = 1, .y = 1 };
        verts[2].col = col;

        verts[3].pos = .{ .x = pos.x, .y = pos.y + texture.height }; // bl
        verts[3].uv = .{ .x = 0, .y = 1 };
        verts[3].col = col;

        self.vert_index += 4;
    }

    pub fn draw(self: *Batcher, texture: Texture, quad: math.Quad, mat: math.Mat32, color: math.Color) void {
        if (self.vert_index >= self.mesh.verts.len or self.current_image != texture.img) {
            self.flush();
        }

        self.current_image = texture.img;

        // copy the quad positions, uvs and color into vertex array transforming them with the matrix as we do it
        mat.transformQuad(self.mesh.verts[self.vert_index .. self.vert_index + 4], quad, color);

        self.vert_index += 4;
    }
};
