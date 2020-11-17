const std = @import("std");
const renderkit = @import("renderkit");
const renderer = renderkit.renderer;

pub const Mesh = struct {
    bindings: renderer.BufferBindings,
    element_count: c_int,

    pub fn init(comptime IndexT: type, indices: []IndexT, comptime VertT: type, verts: []VertT) Mesh {
        var ibuffer = renderer.createBuffer(IndexT, .{
            .type = .index,
            .content = indices,
        });
        var vbuffer = renderer.createBuffer(VertT, .{
            .content = verts,
        });

        return .{
            .bindings = renderer.BufferBindings.init(ibuffer, &[_]renderer.Buffer{vbuffer}),
            .element_count = @intCast(c_int, indices.len),
        };
    }

    pub fn deinit(self: Mesh) void {
        renderer.destroyBuffer(self.bindings.index_buffer);
        renderer.destroyBuffer(self.bindings.vert_buffers[0]);
    }

    pub fn bindImage(self: *Mesh, image: renderkit.Image, slot: c_uint) void {
        self.bindings.bindImage(image, slot);
    }

    pub fn draw(self: Mesh) void {
        renderer.applyBindings(self.bindings);
        renderer.draw(0, self.element_count, 0);
    }
};

/// Contains a dynamic vert buffer and a slice of verts
pub fn DynamicMesh(comptime IndexT: type, comptime VertT: type) type {
    return struct {
        const Self = @This();

        bindings: renderkit.BufferBindings,
        vertex_buffer: renderkit.Buffer,
        verts: []VertT,
        element_count: c_int,
        allocator: *std.mem.Allocator,

        pub fn init(allocator: *std.mem.Allocator, vertex_count: usize, indices: []IndexT) !Self {
            var ibuffer = renderer.createBuffer(IndexT, .{
                .type = .index,
                .content = indices,
            });
            var vertex_buffer = renderer.createBuffer(VertT, .{
                .usage = .stream,
                .size = @intCast(c_long, vertex_count * @sizeOf(VertT)),
            });

            return Self{
                .bindings = renderer.BufferBindings.init(ibuffer, &[_]renderer.Buffer{vertex_buffer}),
                .vertex_buffer = vertex_buffer,
                .verts = try allocator.alloc(VertT, vertex_count),
                .element_count = @intCast(c_int, indices.len),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            renderer.destroyBuffer(self.bindings.index_buffer);
            renderer.destroyBuffer(self.bindings.vert_buffers[0]);
            self.allocator.free(self.verts);
        }

        pub fn updateAllVerts(self: *Self) void {
            renderer.updateBuffer(VertT, self.vertex_buffer, self.verts);
        }

        /// uploads to the GPU the slice from start_index with num_verts
        pub fn updateVertSlice(self: *Self, start_index: usize, num_verts: usize) void {
            std.debug.assert(start_index + num_verts <= self.verts.len);
            const vert_slice = self.verts[start_index .. start_index + num_verts];
            renderer.updateBuffer(VertT, self.vertex_buffer, vert_slice);
        }

        pub fn bindImage(self: *Self, image: renderkit.Image, slot: c_uint) void {
            self.bindings.bindImage(image, slot);
        }

        pub fn draw(self: Self, element_count: c_int) void {
            renderer.applyBindings(self.bindings);
            renderer.draw(0, element_count, 0);
        }

        pub fn drawAllVerts(self: Self) void {
            self.draw(@intCast(c_int, self.element_count));
        }
    };
}
