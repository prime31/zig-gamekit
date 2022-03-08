const std = @import("std");
const rk = @import("renderkit");
const gfx = @import("../gamekit.zig").gfx;

pub const OffscreenPass = struct {
    pass: rk.Pass,
    color_texture: gfx.Texture,
    color_texture2: ?gfx.Texture = null,
    color_texture3: ?gfx.Texture = null,
    color_texture4: ?gfx.Texture = null,
    depth_stencil_texture: ?gfx.Texture = null,

    pub fn init(width: i32, height: i32) OffscreenPass {
        return initWithOptions(width, height, .nearest, .clamp);
    }

    pub fn initMrt(width: i32, height: i32, tex_cnt: usize) OffscreenPass {
        var pass = OffscreenPass{
            .pass = undefined,
            .color_texture = undefined,
        };

        pass.color_texture = gfx.Texture.initOffscreen(width, height, .nearest, .clamp);
        pass.color_texture2 = if (tex_cnt > 1) gfx.Texture.initOffscreen(width, height, .nearest, .clamp) else null;
        pass.color_texture3 = if (tex_cnt > 2) gfx.Texture.initOffscreen(width, height, .nearest, .clamp) else null;
        pass.color_texture4 = if (tex_cnt > 3) gfx.Texture.initOffscreen(width, height, .nearest, .clamp) else null;

        var desc = rk.PassDesc{
            .color_img = pass.color_texture.img,
            .color_img2 = if (pass.color_texture2) |t| t.img else null,
            .color_img3 = if (pass.color_texture3) |t| t.img else null,
            .color_img4 = if (pass.color_texture4) |t| t.img else null,
        };

        pass.pass = rk.createPass(desc);
        return pass;
    }

    pub fn initWithOptions(width: i32, height: i32, filter: rk.TextureFilter, wrap: rk.TextureWrap) OffscreenPass {
        const color_tex = gfx.Texture.initOffscreen(width, height, filter, wrap);

        const pass = rk.createPass(.{
            .color_img = color_tex.img,
        });
        return .{ .pass = pass, .color_texture = color_tex };
    }

    pub fn initWithStencil(width: i32, height: i32, filter: rk.TextureFilter, wrap: rk.TextureWrap) OffscreenPass {
        const color_tex = gfx.Texture.initOffscreen(width, height, filter, wrap);
        const depth_stencil_img = gfx.Texture.initStencil(width, height, filter, wrap);

        const pass = rk.createPass(.{
            .color_img = color_tex.img,
            .depth_stencil_img = depth_stencil_img.img,
        });
        return .{ .pass = pass, .color_texture = color_tex, .depth_stencil_texture = depth_stencil_img };
    }

    pub fn deinit(self: *const OffscreenPass) void {
        // Pass MUST be destroyed first! It relies on the Textures being present.
        rk.destroyPass(self.pass);
        self.color_texture.deinit();
        if (self.color_texture2) |t| t.deinit();
        if (self.color_texture3) |t| t.deinit();
        if (self.color_texture4) |t| t.deinit();
        if (self.depth_stencil_texture) |depth_stencil| depth_stencil.deinit();
    }
};
