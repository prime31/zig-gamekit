const std = @import("std");
const imgui = @import("imgui");
const sdl = @import("sdl");
const gk = @import("../gamekit.zig");

const Renderer = @import("renderer.zig").Renderer;
const Events = @import("events.zig").Events;

var state = struct {
    renderer: Renderer = undefined,
    events: Events = undefined,
}{};

// public methods
pub fn init(window: *sdl.SDL_Window, docking: bool, viewports: bool, icon_font: bool) void {
    _ = window;
    state.renderer = Renderer.init(docking, viewports, icon_font);
    state.events = Events.init();
}

pub fn deinit() void {
    state.renderer.deinit();
    state.events.deinit();
}

pub fn newFrame() void {
    state.events.newFrame(gk.window.sdl_window);
    imgui.igNewFrame();
}

pub fn render() void {
    state.renderer.render();
}

/// returns true if the event is handled by imgui and should be ignored
pub fn handleEvent(event: *sdl.SDL_Event) bool {
    return state.events.handleEvent(event);
}
