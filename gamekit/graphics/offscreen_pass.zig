const std = @import("std");
const rk = @import("renderkit");
const gfx = @import("../gamekit.zig").gfx;

pub const OffscreenPass = struct {
    pass: rk.Pass,
    color_texture: gfx.Texture,
    depth_stencil_texture: ?gfx.Texture = null,

    pub fn init(width: i32, height: i32) OffscreenPass {
        return initWithOptions(width, height, .nearest, .clamp);
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
        if (self.depth_stencil_texture) |depth_stencil| {
            depth_stencil.deinit();
        }
    }
};
