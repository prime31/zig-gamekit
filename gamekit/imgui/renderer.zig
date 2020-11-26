const std = @import("std");
const imgui = @import("imgui");
const gk = @import("../gamekit.zig");
const gfx = gk.gfx;
const rk = @import("renderkit");
const renderer = rk.renderer;

pub const Renderer = struct {
    font_texture: gfx.Texture,
    vert_buffer_size: c_long,
    index_buffer_size: c_long,
    bindings: rk.BufferBindings,

    const font_awesome_range: [3]imgui.ImWchar = [_]imgui.ImWchar{ imgui.icons.icon_range_min, imgui.icons.icon_range_max, 0 };

    pub fn init(docking: bool, viewports: bool) Renderer {
        const max_verts = 16384;
        const index_buffer_size = @intCast(c_long, max_verts * 3 * @sizeOf(u16));
        var ibuffer = renderer.createBuffer(u16, .{
            .type = .index,
            .usage = .stream,
            .size = index_buffer_size,
        });
        const vert_buffer_size = @intCast(c_long, max_verts * @sizeOf(gfx.Vertex));
        var vertex_buffer = renderer.createBuffer(gfx.Vertex, .{
            .usage = .stream,
            .size = vert_buffer_size,
        });

        _ = imgui.igCreateContext(null);
        var io = imgui.igGetIO();
        if (docking) io.ConfigFlags |= imgui.ImGuiConfigFlags_DockingEnable;
        if (viewports) io.ConfigFlags |= imgui.ImGuiConfigFlags_ViewportsEnable;
        io.ConfigDockingWithShift = true;

        imgui.igStyleColorsDark(imgui.igGetStyle());
        imgui.igGetStyle().FrameRounding = 0;
        imgui.igGetStyle().WindowRounding = 0;

        _ = imgui.ImFontAtlas_AddFontDefault(io.Fonts, null);

        // add FontAwesome optionally
        const icon_font = false;
        if (icon_font) {
            var icons_config = imgui.ImFontConfig_ImFontConfig();
            icons_config[0].MergeMode = true;
            icons_config[0].PixelSnapH = true;
            icons_config[0].FontDataOwnedByAtlas = false;

            var data = @embedFile("assets/" ++ imgui.icons.font_icon_filename_fas);
            _ = imgui.ImFontAtlas_AddFontFromMemoryTTF(io.Fonts, data, data.len, 14, icons_config, &font_awesome_range[0]);
        }

        var w: i32 = undefined;
        var h: i32 = undefined;
        var bytes_per_pixel: i32 = undefined;
        var pixels: [*c]u8 = undefined;
        imgui.ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, &pixels, &w, &h, &bytes_per_pixel);

        const font_tex = gfx.Texture.initWithData(u8, w, h, pixels[0..@intCast(usize, w * h * bytes_per_pixel)]);
        imgui.ImFontAtlas_SetTexID(io.Fonts, font_tex.imTextureID());

        return .{
            .font_texture = font_tex,
            .vert_buffer_size = vert_buffer_size,
            .index_buffer_size = index_buffer_size,
            .bindings = renderer.BufferBindings.init(ibuffer, &[_]renderer.Buffer{vertex_buffer}),
        };
    }

    pub fn deinit(self: Renderer) void {
        self.font_texture.deinit();
        renderer.destroyBuffer(self.bindings.index_buffer);
        renderer.destroyBuffer(self.bindings.vert_buffers[0]);
    }

    pub fn render(self: *Renderer) void {
        imgui.igEndFrame();
        imgui.igRender();

        const io = imgui.igGetIO();
        const draw_data = imgui.igGetDrawData();
        if (draw_data.TotalVtxCount == 0) return;

        self.updateBuffers(draw_data);
        self.bindings.index_buffer_offset = 0;

        var tex_id = imgui.igGetIO().Fonts.TexID;
        self.bindings.images[0] = @intCast(rk.Image, @ptrToInt(tex_id));

        imgui.ImDrawData_ScaleClipRects(draw_data, io.DisplayFramebufferScale);
        const width = @floatToInt(i32, draw_data.DisplaySize.x * io.DisplayFramebufferScale.x);
        const height = @floatToInt(i32, draw_data.DisplaySize.y * io.DisplayFramebufferScale.y);
        renderer.viewport(0, 0, width, height);

        gfx.setShader(null);

        renderer.setRenderState(.{ .scissor = true });

        var vb_offset: u32 = 0;
        for (draw_data.CmdLists[0..@intCast(usize, draw_data.CmdListsCount)]) |list, i| {
            // append vertices and indices to buffers, record start offsets in draw state
            const indices = @ptrCast([*]u16, list.IdxBuffer.Data)[0..@intCast(usize, list.IdxBuffer.Size)];
            self.bindings.index_buffer_offset = renderer.appendBuffer(u16, self.bindings.index_buffer, indices);

            const verts = @ptrCast([*]gfx.Vertex, list.VtxBuffer.Data)[0..@intCast(usize, list.VtxBuffer.Size)];
            vb_offset = renderer.appendBuffer(gfx.Vertex, self.bindings.vert_buffers[0], verts);
            self.bindings.vertex_buffer_offsets[0] = vb_offset;

            renderer.applyBindings(self.bindings);

            var base_element: c_int = 0;
            var vtx_offset: u32 = 0;
            for (list.CmdBuffer.Data[0..@intCast(usize, list.CmdBuffer.Size)]) |cmd| {
                if (cmd.UserCallback) |cb| {
                    cb(list, &cmd);
                } else {
                    // std.debug.print("{d}\n", .{cmd.ClipRect});
                    const clip_x = @floatToInt(i32, cmd.ClipRect.x - draw_data.DisplayPos.x);
                    const clip_y = @floatToInt(i32, cmd.ClipRect.y - draw_data.DisplayPos.y);
                    const clip_w = @floatToInt(i32, cmd.ClipRect.z - cmd.ClipRect.x);
                    const clip_h = @floatToInt(i32, cmd.ClipRect.w - cmd.ClipRect.y);

                    renderer.scissor(clip_x, clip_y, clip_w, clip_h);

                    if (tex_id != cmd.TextureId or vtx_offset != cmd.VtxOffset) {
                        tex_id = cmd.TextureId;
                        self.bindings.images[0] = @intCast(rk.Image, @ptrToInt(tex_id));

                        vtx_offset = cmd.VtxOffset;
                        self.bindings.vertex_buffer_offsets[0] = vb_offset + vtx_offset * @sizeOf(imgui.ImDrawVert);
                        renderer.applyBindings(self.bindings);
                    }

                    // gfx.device.applyVertexBufferBindings(&vert_buffer_binding, 1, bindings_updated, @intCast(i32, cmd.VtxOffset));
                    // gfx.device.drawIndexedPrimitives(.triangle_list, @intCast(i32, cmd.VtxOffset), 0, list.VtxBuffer.Size, @intCast(i32, cmd.IdxOffset), @intCast(i32, cmd.ElemCount / 3), self.index_buffer.buffer, .sixteen_bit);
                    // bindings_updated = false;
                    renderer.draw(base_element, @intCast(c_int, cmd.ElemCount), 1);
                }
                base_element += @intCast(c_int, cmd.ElemCount);
            } // end for CmdBuffer.Data
        }

        // reset the scissor
        renderer.scissor(0, 0, width, height);
        renderer.setRenderState(.{});
    }

    pub fn updateBuffers(self: *Renderer, draw_data: *imgui.ImDrawData) void {
        // Expand buffers if we need more room
        if (draw_data.TotalIdxCount > self.index_buffer_size) {
            renderer.destroyBuffer(self.bindings.index_buffer);

            self.index_buffer_size = @floatToInt(c_long, @intToFloat(f32, draw_data.TotalIdxCount) * 1.5);
            var ibuffer = renderer.createBuffer(u16, .{
                .type = .index,
                .usage = .stream,
                .size = self.index_buffer_size,
            });
            self.bindings.index_buffer = ibuffer;
        }

        if (draw_data.TotalVtxCount > self.vert_buffer_size) {
            renderer.destroyBuffer(self.bindings.vert_buffers[0]);

            self.vert_buffer_size = @floatToInt(c_long, @intToFloat(f32, draw_data.TotalVtxCount) * 1.5);
            var vertex_buffer = renderer.createBuffer(gfx.Vertex, .{
                .usage = .stream,
                .size = self.vert_buffer_size,
            });
        }
    }
};
