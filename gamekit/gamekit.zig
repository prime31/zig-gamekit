const std = @import("std");
const sdl = @import("sdl");
const imgui_impl = @import("imgui/implementation.zig");

pub const imgui = @import("imgui");
pub const renderkit = @import("renderkit");
pub const utils = @import("utils/utils.zig");
pub const math = @import("math/math.zig");

const Gfx = @import("gfx.zig").Gfx;
const Window = @import("window.zig").Window;
const WindowConfig = @import("window.zig").WindowConfig;
const Input = @import("input.zig").Input;
const Time = @import("time.zig").Time;

pub const Config = struct {
    init: fn () anyerror!void,
    update: ?fn () anyerror!void = null,
    render: fn () anyerror!void,
    shutdown: ?fn () anyerror!void = null,

    window: WindowConfig = WindowConfig{},

    update_rate: f64 = 60, // desired fps
    imgui_icon_font: bool = true,
    imgui_viewports: bool = false, // whether imgui viewports should be enabled
    imgui_docking: bool = true, // whether imgui docking should be enabled
};

// search path: root.build_options, root.enable_imgui, default to false
pub const enable_imgui: bool = if (@hasDecl(@import("root"), "build_options"))
blk: {
    break :blk @field(@import("root"), "build_options").enable_imgui;
} else if (@hasDecl(@import("root"), "enable_imgui"))
blk: {
    break :blk @field(@import("root"), "enable_imgui");
} else blk: {
    break :blk false;
};

pub const gfx = @import("gfx.zig");
pub var window: Window = undefined;
pub var time: Time = undefined;
pub var input: Input = undefined;

pub fn run(comptime config: Config) !void {
    window = try Window.init(config.window);

    renderkit.setup(.{
        .gl_loader = sdl.SDL_GL_GetProcAddress,
    }, std.heap.c_allocator);

    gfx.init();
    time = Time.init(config.update_rate);
    input = Input.init(window.scale());

    if (enable_imgui) imgui_impl.init(window.sdl_window, config.imgui_docking, config.imgui_viewports, config.imgui_icon_font);

    try config.init();

    while (!pollEvents()) {
        time.tick();
        if (config.update) |update| try update();
        try config.render();

        if (enable_imgui) {
            gfx.beginPass(.{ .clear_color = false });
            imgui_impl.render();
            gfx.endPass();
            _ = sdl.SDL_GL_MakeCurrent(window.sdl_window, window.gl_ctx);
        }

        sdl.SDL_GL_SwapWindow(window.sdl_window);
        gfx.commitFrame();
        input.newFrame();
    }

    if (enable_imgui) imgui_impl.deinit();
    if (config.shutdown) |shutdown| try shutdown();
    gfx.deinit();
    renderkit.shutdown();
    window.deinit();
    sdl.SDL_Quit();
}

fn pollEvents() bool {
    var event: sdl.SDL_Event = undefined;
    while (sdl.SDL_PollEvent(&event) != 0) {
        if (enable_imgui and imgui_impl.handleEvent(&event)) continue;

        switch (event.type) {
            sdl.SDL_QUIT => return true,
            sdl.SDL_WINDOWEVENT => {
                if (event.window.windowID == window.id) {
                    if (event.window.event == sdl.SDL_WINDOWEVENT_CLOSE) return true;
                    window.handleEvent(&event.window);
                }
            },
            else => input.handleEvent(&event),
        }
    }

    // if ImGui is running we force a timer resync every frame. This ensures we get exactly one update call and one render call
    // each frame which prevents ImGui from flickering due to skipped/doubled update calls.
    if (enable_imgui) {
        imgui_impl.newFrame();
        time.resync();
    }

    return false;
}
