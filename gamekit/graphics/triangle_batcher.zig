const std = @import("std");
const renderkit = @import("renderkit");
const gk = @import("../gamekit.zig");
const math = gk.math;

const Vertex = gk.gfx.Vertex;
const DynamicMesh = gk.gfx.DynamicMesh;

pub const TriangleBatcher = struct {
    mesh: DynamicMesh(u16, Vertex),
    white_tex: gk.gfx.Texture = undefined,

    vert_index: usize = 0, // current index into the vertex array

    pub fn init(allocator: *std.mem.Allocator, max_tris: usize) !TriangleBatcher {
        var indices = try allocator.alloc(u16, @intCast(usize, max_tris * 3));
        defer allocator.free(indices);
        var i: usize = 0;
        while (i < max_tris) : (i += 1) {
            indices[i * 3 + 0] = @intCast(u16, i) * 3 + 0;
            indices[i * 3 + 1] = @intCast(u16, i) * 3 + 1;
            indices[i * 3 + 2] = @intCast(u16, i) * 3 + 2;
        }

        var batcher = TriangleBatcher{
            .mesh = try DynamicMesh(u16, Vertex).init(allocator, max_tris * 3, indices),
        };
        errdefer batcher.deinit();

        var pixels = [_]u32{ 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
        batcher.white_tex = gk.gfx.Texture.initWithData(u32, 2, 2, pixels[0..]);

        return batcher;
    }

    pub fn deinit(self: TriangleBatcher) void {
        self.mesh.deinit();
        self.white_tex.deinit();
    }

    pub fn begin(self: *TriangleBatcher) void {
        self.vert_index = 0;
    }

    /// call at the end of the frame when all drawing is complete. Flushes the batch and resets local state.
    pub fn end(self: *TriangleBatcher) void {
        self.flush();
        self.vert_index = 0;
    }

    pub fn flush(self: *TriangleBatcher) void {
        if (self.vert_index == 0) return;

        self.mesh.updateVertSlice(0, self.vert_index);
        self.mesh.bindImage(self.white_tex.img, 0);

        // draw
        const tris = self.vert_index / 3;
        self.mesh.draw(@intCast(c_int, tris * 3));

        self.vert_index = 0;
    }

    pub fn drawTriangle(self: *TriangleBatcher, pt1: math.Vec2, pt2: math.Vec2, pt3: math.Vec2, color: math.Color) void {
        if (self.vert_index + 3 > self.mesh.verts.len) self.flush();

        // copy the quad positions, uvs and color into vertex array transforming them with the matrix after we do it
        self.mesh.verts[self.vert_index].pos = pt1;
        self.mesh.verts[self.vert_index].col = color.value;
        self.mesh.verts[self.vert_index + 1].pos = pt2;
        self.mesh.verts[self.vert_index + 1].col = color.value;
        self.mesh.verts[self.vert_index + 2].pos = pt3;
        self.mesh.verts[self.vert_index + 2].col = color.value;

        const mat = math.Mat32.identity;
        mat.transformVertexSlice(self.mesh.verts[self.vert_index .. self.vert_index + 3]);
        self.vert_index += 3;
    }
};

test "test triangle batcher" {
    var batcher = try TriangleBatcher.init(null, 10);
    _ = try batcher.ensureCapacity(null);
    batcher.flush(false);
    batcher.deinit();
}
