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
        renderer.draw(0, self.element_count, 1);
    }
};

/// Contains a dynamic vert buffer and a slice of verts
pub fn DynamicMesh(comptime IndexT: type, comptime VertT: type) type {
    return struct {
        const Self = @This();

        bindings: renderkit.BufferBindings,
        verts: []VertT,
        element_count: c_int,
        verts_updated: bool = false,
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
            renderer.updateBuffer(VertT, self.bindings.vert_buffers[0], self.verts);
            // updateBuffer gives us a fresh buffer so make sure we reset our append offset
            self.bindings.vertex_buffer_offsets[0] = 0;
        }

        /// uploads to the GPU the slice from start_index with num_verts
        pub fn updateVertSlice(self: *Self, num_verts: usize) void {
            std.debug.assert(num_verts <= self.verts.len);
            const vert_slice = self.verts[0..num_verts];
            renderer.updateBuffer(VertT, self.bindings.vert_buffers[0], vert_slice);
        }

        /// uploads to the GPU the slice from start with num_verts. Records the offset in the BufferBindings allowing you
        /// to interleave appendVertSlice and draw calls. When calling draw after appendVertSlice
        /// the base_element is reset to the start of the newly updated data so you would pass in 0 for base_element.
        pub fn appendVertSlice(self: *Self, start_index: usize, num_verts: usize) void {
            std.debug.assert(start_index + num_verts <= self.verts.len);
            const vert_slice = self.verts[start_index..start_index + num_verts];
            self.bindings.vertex_buffer_offsets[0] = renderer.appendBuffer(VertT, self.bindings.vert_buffers[0], vert_slice);
        }

        pub fn bindImage(self: *Self, image: renderkit.Image, slot: c_uint) void {
            self.bindings.bindImage(image, slot);
        }

        pub fn draw(self: Self, base_element: c_int, element_count: c_int) void {
            renderer.applyBindings(self.bindings);
            renderer.draw(base_element, element_count, 1);
        }

        pub fn drawAllVerts(self: Self) void {
            self.draw(0, @intCast(c_int, self.element_count));
        }
    };
}
