const std = @import("std");
const renderkit = @import("renderkit");
const gamekit = @import("gamekit");
const gfx = gamekit.gfx;
const math = gamekit.math;

const Texture = gamekit.gfx.Texture;
const Color = gamekit.math.Color;

const Mode7Uniform = struct {
    mapw: f32 = 0,
    maph: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    zoom: f32 = 0,
    fov: f32 = 0,
    offset: f32 = 0,
    wrap: f32 = 0,
    x1: f32 = 0,
    x2: f32 = 0,
    y1: f32 = 0,
    y2: f32 = 0,
};

const Block = struct {
    tex: Texture,
    pos: math.Vec2,
    scale: f32,
    dist: f32,
};

const Camera = struct {
    sw: f32,
    sh: f32,
    x: f32 = 0,
    y: f32 = 0,
    r: f32 = 0,
    z: f32 = 32,
    f: f32 = 1,
    o: f32 = 1,
    x1: f32 = 0,
    y1: f32 = 0,
    x2: f32 = 0,
    y2: f32 = 0,
    sprites: std.ArrayList(Block) = undefined,

    pub fn init(sw: f32, sh: f32) Camera {
        var cam = Camera{ .sw = sw, .sh = sh, .sprites = std.ArrayList(Block).init(std.testing.allocator) };
        cam.setRotation(0);
        return cam;
    }

    pub fn deinit(self: Camera) void {
        self.sprites.deinit();
    }

    pub fn setRotation(self: *Camera, rot: f32) void {
        self.r = rot;
        self.x1 = std.math.sin(rot);
        self.y1 = std.math.cos(rot);
        self.x2 = -std.math.cos(rot);
        self.y2 = std.math.sin(rot);
    }

    pub fn toWorld(self: Camera, pos: gamekit.math.Vec2) gamekit.math.Vec2 {
        const sx = (self.sw / 2 - pos.x) * self.z / (self.sw / self.sh);
        const sy = (self.o * self.sh - pos.y) * (self.z / self.f);

        const rot_x = sx * self.x1 + sy * self.y1;
        const rot_y = sx * self.x2 + sy * self.y2;

        return .{ .x = rot_x / pos.y + self.x, .y = rot_y / pos.y + self.y };
    }

    pub fn toScreen(self: Camera, pos: gamekit.math.Vec2) struct { x: f32, y: f32, size: f32 } {
        const obj_x = -(self.x - pos.x) / self.z;
        const obj_y = (self.y - pos.y) / self.z;

        const space_x = (-obj_x * self.x1 - obj_y * self.y1);
        const space_y = (obj_x * self.x2 + obj_y * self.y2) * self.f;

        const distance = 1 - space_y;
        const screen_x = (space_x / distance) * self.o * self.sw + self.sw / 2;
        const screen_y = ((space_y + self.o - 1) / distance) * self.sh + self.sh;

        // Should be approximately one pixel on the plane
        const size = ((1 / distance) / self.z * self.o) * self.sw;

        return .{ .x = screen_x, .y = screen_y, .size = size };
    }

    pub fn placeSprite(self: *Camera, tex: gamekit.gfx.Texture, pos: gamekit.math.Vec2, scale: f32) void {
        const dim = self.toScreen(pos);
        const sx2 = (dim.size * scale) / tex.width;

        if (sx2 < 0) return;

        _ = self.sprites.append(.{
            .tex = tex,
            .pos = .{ .x = dim.x, .y = dim.y },
            .scale = sx2,
            .dist = dim.size,
        }) catch unreachable;
    }

    pub fn renderSprites(self: *Camera) void {
        if (self.sprites.items.len > 0) {
            std.sort.sort(Block, self.sprites.items, {}, sort);
        }

        for (self.sprites.items) |sprite| {
            gfx.draw.texScaleOrigin(sprite.tex, sprite.pos.x, sprite.pos.y, sprite.scale, sprite.tex.width / 2, sprite.tex.height);
        }
        self.sprites.items.len = 0;
    }

    fn sort(ctx: void, a: Block, b: Block) bool {
        return a.dist < b.dist;
    }
};

var map: Texture = undefined;
var block: Texture = undefined;
var mode7_shader: gfx.Shader = undefined;
var uniform: Mode7Uniform = .{};
var camera: Camera = undefined;
var blocks: std.ArrayList(math.Vec2) = undefined;
var wrap: f32 = 0;

pub fn main() !void {
    try gamekit.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .window = .{ .resizable = false },
    });
}

fn init() !void {
    _ = @import("sdl").SDL_GL_SetSwapInterval(1);
    const drawable_size = gamekit.window.drawableSize();
    camera = Camera.init(@intToFloat(f32, drawable_size.w), @intToFloat(f32, drawable_size.h));

    map = Texture.initFromFile(std.testing.allocator, "examples/assets/mario_kart.png", .nearest) catch unreachable;
    block = Texture.initFromFile(std.testing.allocator, "examples/assets/block.png", .nearest) catch unreachable;
    mode7_shader = try gfx.Shader.initWithFragUniform(Mode7Uniform, @embedFile("assets/shaders/vert.vs"), @embedFile("assets/shaders/mode7.fs"));
    mode7_shader.bind();
    mode7_shader.setUniformName(i32, "MainTex", 0);
    mode7_shader.setUniformName(i32, "map_tex", 1);

    blocks = std.ArrayList(math.Vec2).init(std.testing.allocator);
    _ = blocks.append(.{ .x = 0, .y = 0 }) catch unreachable;

    // uncomment for sorting stress test
    // var x: usize = 4;
    // while (x < 512) : (x += 12) {
    //     var y: usize = 4;
    //     while (y < 512) : (y += 12) {
    //         _ = blocks.append(.{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) }) catch unreachable;
    //     }
    // }
}

fn shutdown() !void {
    map.deinit();
    block.deinit();
    mode7_shader.deinit();
    blocks.deinit();
    camera.deinit();
}

fn update() !void {
    const move_speed = 140.0;
    if (gamekit.input.keyDown(.w)) {
        camera.x += std.math.cos(camera.r) * move_speed * gamekit.time.rawDeltaTime();
        camera.y += std.math.sin(camera.r) * move_speed * gamekit.time.rawDeltaTime();
    } else if (gamekit.input.keyDown(.s)) {
        camera.x = camera.x - std.math.cos(camera.r) * move_speed * gamekit.time.rawDeltaTime();
        camera.y = camera.y - std.math.sin(camera.r) * move_speed * gamekit.time.rawDeltaTime();
    }

    if (gamekit.input.keyDown(.a)) {
        camera.x += std.math.cos(camera.r - std.math.pi / 2.0) * move_speed * gamekit.time.rawDeltaTime();
        camera.y += std.math.sin(camera.r - std.math.pi / 2.0) * move_speed * gamekit.time.rawDeltaTime();
    } else if (gamekit.input.keyDown(.d)) {
        camera.x += std.math.cos(camera.r + std.math.pi / 2.0) * move_speed * gamekit.time.rawDeltaTime();
        camera.y += std.math.sin(camera.r + std.math.pi / 2.0) * move_speed * gamekit.time.rawDeltaTime();
    }

    if (gamekit.input.keyDown(.i)) {
        camera.f += gamekit.time.rawDeltaTime();
    } else if (gamekit.input.keyDown(.o)) {
        camera.f -= gamekit.time.rawDeltaTime();
    }

    if (gamekit.input.keyDown(.k)) {
        camera.o += gamekit.time.rawDeltaTime();
    } else if (gamekit.input.keyDown(.l)) {
        camera.o -= gamekit.time.rawDeltaTime();
    }

    if (gamekit.input.keyDown(.minus)) {
        camera.z += gamekit.time.rawDeltaTime() * 10;
    } else if (gamekit.input.keyDown(.equals)) {
        camera.z -= gamekit.time.rawDeltaTime() * 10;
    }

    if (gamekit.input.keyDown(.q)) {
        camera.setRotation(@mod(camera.r, std.math.tau) - gamekit.time.rawDeltaTime());
    } else if (gamekit.input.keyDown(.e)) {
        camera.setRotation(@mod(camera.r, std.math.tau) + gamekit.time.rawDeltaTime());
    }

    if (gamekit.input.mousePressed(.left)) {
        var pos = camera.toWorld(gamekit.input.mousePos());
        _ = blocks.append(pos) catch unreachable;
    }

    if (gamekit.input.mousePressed(.right)) {
        wrap = if (wrap == 0) 1 else 0;
    }
}

fn render() !void {
    gfx.beginPass(.{});
    drawPlane();

    var pos = camera.toScreen(camera.toWorld(gamekit.input.mousePos()));
    gfx.draw.circle(.{ .x = pos.x, .y = pos.y }, pos.size, 2, 8, gamekit.math.Color.white);
    gfx.draw.texScaleOrigin(block, pos.x, pos.y, pos.size, block.width / 2, block.height);

    for (blocks.items) |b| {
        camera.placeSprite(block, b, 8);
    }
    camera.renderSprites();

    gfx.draw.text("WASD to move", 5, 20, null);
    gfx.draw.text("i/o to change fov", 5, 40, null);
    gfx.draw.text("k/l to change offset", 5, 60, null);
    gfx.draw.text("-/= to change z pos", 5, 80, null);
    gfx.draw.text("q/e to rotate cam", 5, 100, null);
    gfx.draw.text("left click to place block", 5, 120, null);
    gfx.draw.text("right click to toggle wrap", 5, 140, null);
    gfx.draw.text("z to load zelda map", 5, 160, null);

    gfx.endPass();
}

fn drawPlane() void {
    gfx.setShader(mode7_shader);

    uniform.mapw = map.width;
    uniform.maph = map.height;
    uniform.x = camera.x;
    uniform.y = camera.y;
    uniform.zoom = camera.z;
    uniform.fov = camera.f;
    uniform.offset = camera.o;
    uniform.wrap = wrap;
    uniform.x1 = camera.x1;
    uniform.y1 = camera.y1;
    uniform.x2 = camera.x2;
    uniform.y2 = camera.y2;
    mode7_shader.setFragUniform(Mode7Uniform, uniform);

    // bind out map to the second texture slot and we need a full screen render for the shader so we just draw a full screen rect
    gfx.draw.bindTexture(map, 1);
    const drawable_size = gamekit.window.drawableSize();
    gfx.draw.rect(.{}, @intToFloat(f32, drawable_size.w), @intToFloat(f32, drawable_size.h), math.Color.white);
    gfx.setShader(null);
    gfx.draw.unbindTexture(1);
}
