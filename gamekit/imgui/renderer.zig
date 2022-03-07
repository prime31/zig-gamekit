const std = @import("std");
const imgui = @import("imgui");
const gk = @import("../gamekit.zig");
const gfx = gk.gfx;
const rk = @import("renderkit");

pub const Renderer = struct {
    font_texture: gfx.Texture,
    vert_buffer_size: c_long,
    index_buffer_size: c_long,
    bindings: rk.BufferBindings,

    const font_awesome_range: [3]imgui.ImWchar = [_]imgui.ImWchar{ imgui.icons.icon_range_min, imgui.icons.icon_range_max, 0 };

    pub fn init(docking: bool, viewports: bool, icon_font: bool) Renderer {
        const max_verts = 16384;
        const index_buffer_size = @intCast(c_long, max_verts * 3 * @sizeOf(u16));
        var ibuffer = rk.createBuffer(u16, .{
            .type = .index,
            .usage = .stream,
            .size = index_buffer_size,
        });
        const vert_buffer_size = @intCast(c_long, max_verts * @sizeOf(gfx.Vertex));
        var vertex_buffer = rk.createBuffer(gfx.Vertex, .{
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
        if (icon_font) {
            var icons_config = imgui.ImFontConfig_ImFontConfig();
            icons_config[0].MergeMode = true;
            icons_config[0].PixelSnapH = true;
            icons_config[0].FontDataOwnedByAtlas = false;

            var data = @embedFile("assets/" ++ imgui.icons.font_icon_filename_fas);
            _ = imgui.ImFontAtlas_AddFontFromMemoryTTF(io.Fonts, data, data.len, 13, icons_config, &font_awesome_range[0]);
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
            .bindings = rk.BufferBindings.init(ibuffer, &[_]rk.Buffer{vertex_buffer}),
        };
    }

    pub fn deinit(self: Renderer) void {
        self.font_texture.deinit();
        rk.destroyBuffer(self.bindings.index_buffer);
        rk.destroyBuffer(self.bindings.vert_buffers[0]);
    }

    pub fn render(self: *Renderer) void {
        imgui.igEndFrame();
        imgui.igRender();

        const io = imgui.igGetIO();
        _ = io;
        const draw_data = imgui.igGetDrawData();
        if (draw_data.TotalVtxCount == 0) return;

        self.updateBuffers(draw_data);
        self.bindings.index_buffer_offset = 0;

        var tex_id = imgui.igGetIO().Fonts.TexID;
        self.bindings.images[0] = @intCast(rk.Image, @ptrToInt(tex_id));

        var fb_scale = draw_data.FramebufferScale;
        imgui.ogImDrawData_ScaleClipRects(draw_data, fb_scale);
        const width = @floatToInt(i32, draw_data.DisplaySize.x * fb_scale.x);
        const height = @floatToInt(i32, draw_data.DisplaySize.y * fb_scale.y);
        rk.viewport(0, 0, width, height);

        gfx.setShader(null);

        rk.setRenderState(.{ .scissor = true });

        var vb_offset: u32 = 0;
        for (draw_data.CmdLists[0..@intCast(usize, draw_data.CmdListsCount)]) |list| {
            // append vertices and indices to buffers
            const indices = @ptrCast([*]u16, list.IdxBuffer.Data)[0..@intCast(usize, list.IdxBuffer.Size)];
            self.bindings.index_buffer_offset = rk.appendBuffer(u16, self.bindings.index_buffer, indices);

            const verts = @ptrCast([*]gfx.Vertex, list.VtxBuffer.Data)[0..@intCast(usize, list.VtxBuffer.Size)];
            vb_offset = rk.appendBuffer(gfx.Vertex, self.bindings.vert_buffers[0], verts);
            self.bindings.vertex_buffer_offsets[0] = vb_offset;

            rk.applyBindings(self.bindings);

            var base_element: c_int = 0;
            var vtx_offset: u32 = 0;
            for (list.CmdBuffer.Data[0..@intCast(usize, list.CmdBuffer.Size)]) |cmd| {
                if (cmd.UserCallback) |cb| {
                    cb(list, &cmd);
                } else {
                    // DisplayPos is 0,0 unless viewports is enabled
                    const clip_x = @floatToInt(i32, (cmd.ClipRect.x - draw_data.DisplayPos.x) * fb_scale.x);
                    const clip_y = @floatToInt(i32, (cmd.ClipRect.y - draw_data.DisplayPos.y) * fb_scale.y);
                    const clip_w = @floatToInt(i32, (cmd.ClipRect.z - draw_data.DisplayPos.x) * fb_scale.x);
                    const clip_h = @floatToInt(i32, (cmd.ClipRect.w - draw_data.DisplayPos.y) * fb_scale.y);

                    rk.scissor(clip_x, clip_y, clip_w - clip_x, clip_h - clip_y);

                    if (tex_id != cmd.TextureId or vtx_offset != cmd.VtxOffset) {
                        tex_id = cmd.TextureId;
                        self.bindings.images[0] = @intCast(rk.Image, @ptrToInt(tex_id));

                        vtx_offset = cmd.VtxOffset;
                        self.bindings.vertex_buffer_offsets[0] = vb_offset + vtx_offset * @sizeOf(imgui.ImDrawVert);
                        rk.applyBindings(self.bindings);
                    }

                    rk.draw(base_element, @intCast(c_int, cmd.ElemCount), 1);
                }
                base_element += @intCast(c_int, cmd.ElemCount);
            } // end for CmdBuffer.Data
        }

        // reset the scissor
        rk.scissor(0, 0, width, height);
        rk.setRenderState(.{});
    }

    pub fn updateBuffers(self: *Renderer, draw_data: *imgui.ImDrawData) void {
        // Expand buffers if we need more room
        if (draw_data.TotalIdxCount > self.index_buffer_size) {
            rk.destroyBuffer(self.bindings.index_buffer);

            self.index_buffer_size = @floatToInt(c_long, @intToFloat(f32, draw_data.TotalIdxCount) * 1.5);
            var ibuffer = rk.createBuffer(u16, .{
                .type = .index,
                .usage = .stream,
                .size = self.index_buffer_size,
            });
            self.bindings.index_buffer = ibuffer;
        }

        if (draw_data.TotalVtxCount > self.vert_buffer_size) {
            rk.destroyBuffer(self.bindings.vert_buffers[0]);

            self.vert_buffer_size = @floatToInt(c_long, @intToFloat(f32, draw_data.TotalVtxCount) * 1.5);
            var vertex_buffer = rk.createBuffer(gfx.Vertex, .{
                .usage = .stream,
                .size = self.vert_buffer_size,
            });
            _ = vertex_buffer;
        }
    }
};
