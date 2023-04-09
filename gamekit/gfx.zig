const std = @import("std");
const gamekit = @import("gamekit.zig");
const renderkit = @import("renderkit");
const math = gamekit.math;

// high level wrapper objects that use the low-level backend api
pub const Texture = @import("graphics/texture.zig").Texture;
pub const OffscreenPass = @import("graphics/offscreen_pass.zig").OffscreenPass;
pub const Shader = @import("graphics/shader.zig").Shader;
pub const ShaderState = @import("graphics/shader.zig").ShaderState;

// even higher level wrappers for 2D game dev
pub const Mesh = @import("graphics/mesh.zig").Mesh;
pub const DynamicMesh = @import("graphics/mesh.zig").DynamicMesh;

pub const Batcher = @import("graphics/batcher.zig").Batcher;
pub const MultiBatcher = @import("graphics/multi_batcher.zig").MultiBatcher;
pub const TriangleBatcher = @import("graphics/triangle_batcher.zig").TriangleBatcher;

pub const FontBook = @import("graphics/fontbook.zig").FontBook;

pub const Vertex = extern struct {
    pos: math.Vec2 = .{ .x = 0, .y = 0 },
    uv: math.Vec2 = .{ .x = 0, .y = 0 },
    col: u32 = 0xFFFFFFFF,
};

pub const PassConfig = struct {
    pub const ColorAttachmentAction = extern struct {
        clear: bool = true,
        color: math.Color = math.Color.aya,
    };

    clear_color: bool = true,
    color: math.Color = math.Color.aya,
    mrt_colors: [3]ColorAttachmentAction = [_]ColorAttachmentAction{.{}} ** 3,
    clear_stencil: bool = false,
    stencil: u8 = 0,
    clear_depth: bool = false,
    depth: f64 = 0,

    trans_mat: ?math.Mat32 = null,
    shader: ?*Shader = null,
    pass: ?OffscreenPass = null,

    pub fn asClearCommand(self: PassConfig) renderkit.ClearCommand {
        var cmd = renderkit.ClearCommand{};
        cmd.colors[0].clear = self.clear_color;
        cmd.colors[0].color = self.color.asArray();

        for (self.mrt_colors, 0..) |mrt_color, i| {
            cmd.colors[i + 1] = .{
                .clear = mrt_color.clear,
                .color = mrt_color.color.asArray(),
            };
        }

        cmd.clear_stencil = self.clear_stencil;
        cmd.stencil = self.stencil;
        cmd.clear_depth = self.clear_depth;
        cmd.depth = self.depth;
        return cmd;
    }
};

pub var state = struct {
    shader: Shader = undefined,
    transform_mat: math.Mat32 = math.Mat32.identity,
}{};

pub fn init() void {
    state.shader = Shader.initDefaultSpriteShader() catch unreachable;
    draw.init();
}

pub fn deinit() void {
    draw.deinit();
    state.shader.deinit();
}

pub fn setShader(shader: ?*Shader) void {
    const new_shader = shader orelse &state.shader;

    draw.batcher.flush();
    new_shader.bind();
    new_shader.setTransformMatrix(&state.transform_mat);
}

pub fn setRenderState(renderstate: renderkit.RenderState) void {
    draw.batcher.flush();
    renderkit.setRenderState(renderstate);
}

pub fn beginPass(config: PassConfig) void {
    var proj_mat: math.Mat32 = math.Mat32.init();
    var clear_command = config.asClearCommand();
    draw.batcher.begin();

    if (config.pass) |pass| {
        renderkit.beginPass(pass.pass, clear_command);
        // inverted for OpenGL offscreen passes
        proj_mat = math.Mat32.initOrthoInverted(pass.color_texture.width, pass.color_texture.height);
    } else {
        const size = gamekit.window.drawableSize();
        renderkit.beginDefaultPass(clear_command, size.w, size.h);
        proj_mat = math.Mat32.initOrtho(@intToFloat(f32, size.w), @intToFloat(f32, size.h));
    }

    // if we were given a transform matrix multiply it here
    if (config.trans_mat) |trans_mat| {
        proj_mat = proj_mat.mul(trans_mat);
    }

    state.transform_mat = proj_mat;

    // if we were given a Shader use it else set the default Shader
    setShader(config.shader);
}

pub fn endPass() void {
    setShader(null);
    draw.batcher.end();
    renderkit.endPass();
}

/// if we havent yet blitted to the screen do so now
pub fn commitFrame() void {
    renderkit.commitFrame();
}

// import all the drawing methods
pub const draw = @import("draw.zig").draw;
