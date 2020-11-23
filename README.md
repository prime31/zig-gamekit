# Zig GameKit 2D
Companion repo and example implementation for [zig-renderkit](https://github.com/prime31/zig-renderkit). `GameKit` provides an example implementation of a game framework built on top of `RenderKit`. It includes the core render loop, window (via SDL), input, Dear ImGui and timing support. You can use it as a base to make a 2D game as-is or create your own 2D framework based on it.

`GameKit` provides the following wrappers around `RenderKit`'s API showing how it can be abstracted away in a real work project: `Texture`, `Shader` and `OffscreenPass`. Building on top of those types, `GameKit` then provides `Mesh` and `DynamicMesh` which manage buffers and bindings for you. Finally, the high level types utilize `DynamicMesh` and cover pretty much all that any 2D game would require: `Batcher` (quad/sprite batch) and `TriangleBatcher`.

Some basic utilities and a small math lib with just the types required for the renderer (`Vec2`, `Vec3`, `Color`, `3x2 Matrix`, `Quad`) are also included.


### Usage
- clone the repository recursively: `git clone --recursive https://github.com/prime31/zig-gamekit`
- `zig build help` to see what examples are availble
- `zig build EXAMPLE_NAME` to run an example


### Minimal GameKit Project File
```zig
var texture: Texture = undefined;

pub fn main() !void {
    try gamekit.run(.{ .init = init, .render = render });
}

fn init() !void {
    texture = Texture.initFromFile(std.testing.allocator, "texture.png", .nearest) catch unreachable;
}

fn render() !void {
    gamekit.gfx.beginPass(.{ .color = Color.lime });
    gamekit.draw.tex(texture, .{ .x = 50, .y = 50 });
    gamekit.gfx.endPass();
}
```