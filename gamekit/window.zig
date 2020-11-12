const std = @import("std");
const sdl = @import("sdl");
const renderkit = @import("renderkit");

pub const WindowConfig = struct {
    title: [:0]const u8 = "Zig RenderKit", // the window title as UTF-8 encoded string
    width: i32 = 800, // the preferred width of the window / canvas
    height: i32 = 600, // the preferred height of the window / canvas
    resizable: bool = true, // whether the window should be allowed to be resized
    fullscreen: bool = false, // whether the window should be created in fullscreen mode
    high_dpi: bool = false, // whether the backbuffer is full-resolution on HighDPI displays
};

pub const WindowMode = enum(u32) {
    windowed = 0,
    full_screen = 1,
    desktop = 4097,
};

pub const Window = struct {
    sdl_window: *sdl.SDL_Window = undefined,
    gl_ctx: sdl.SDL_GLContext = undefined,
    id: u32 = 0,
    focused: bool = true,

    pub fn init(config: WindowConfig) !Window {
        var window = Window{};
        _ = sdl.SDL_InitSubSystem(sdl.SDL_INIT_VIDEO);

        var flags: c_int = 0;
        if (config.resizable) flags |= sdl.SDL_WINDOW_RESIZABLE;
        if (config.high_dpi) flags |= sdl.SDL_WINDOW_ALLOW_HIGHDPI;
        if (config.fullscreen) flags |= sdl.SDL_WINDOW_FULLSCREEN_DESKTOP;

        switch (renderkit.current_renderer) {
            .opengl => window.createOpenGlWindow(config, flags),
            .metal => window.createMetalWindow(config, flags),
            else => unreachable,
        }

        window.id = sdl.SDL_GetWindowID(window.sdl_window);
        return window;
    }

    pub fn deinit(self: Window) void {
        sdl.SDL_DestroyWindow(self.sdl_window);
        if (renderkit.current_renderer == .opengl) sdl.SDL_GL_DeleteContext(self.gl_ctx);
    }

    fn createOpenGlWindow(self: *Window, config: WindowConfig, flags: c_int) void {
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_CONTEXT_FLAGS, sdl.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE);
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, 3);

        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_DOUBLEBUFFER, 1);
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_DEPTH_SIZE, 24);
        _ = sdl.SDL_GL_SetAttribute(.SDL_GL_STENCIL_SIZE, 8);

        var window_flags = flags | @enumToInt(sdl.SDL_WindowFlags.SDL_WINDOW_OPENGL);
        self.sdl_window = sdl.SDL_CreateWindow(config.title, sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, config.width, config.height, @bitCast(u32, window_flags)) orelse {
            sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
            @panic("no window");
        };

        self.gl_ctx = sdl.SDL_GL_CreateContext(self.sdl_window);
    }

    fn createMetalWindow(self: *Window, config: WindowConfig, flags: c_int) void {
        _ = sdl.SDL_SetHint(sdl.SDL_HINT_RENDER_DRIVER, "metal");
        _ = sdl.SDL_InitSubSystem(sdl.SDL_INIT_VIDEO);

        var window_flags = flags | sdl.SDL_WINDOW_METAL;
        self.sdl_window = sdl.SDL_CreateWindow(config.title, sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, config.width, config.height, @bitCast(u32, window_flags)) orelse {
            sdl.SDL_Log("Unable to create window: %s", sdl.SDL_GetError());
            @panic("no window");
        };
    }

    pub fn handleEvent(self: *Window, event: *sdl.SDL_WindowEvent) void {
        switch (event.event) {
            sdl.SDL_WINDOWEVENT_SIZE_CHANGED => {
                std.debug.warn("resize: {}x{}\n", .{ event.data1, event.data2 });
                // TODO: make a resized event
            },
            sdl.SDL_WINDOWEVENT_FOCUS_GAINED => self.focused = true,
            sdl.SDL_WINDOWEVENT_FOCUS_LOST => self.focused = false,
            else => {},
        }
    }

    /// returns the drawable width / the window width. Used to scale mouse coords when the OS gives them to us in points.
    pub fn scale(self: Window) f32 {
        var wx = self.width();
        const draw_size = self.drawableSize();
        return @intToFloat(f32, draw_size.w) / @intToFloat(f32, wx);
    }

    pub fn width(self: Window) i32 {
        return self.size().w;
    }

    pub fn height(self: Window) i32 {
        return self.size().h;
    }

    pub fn drawableSize(self: Window) struct { w: c_int, h: c_int } {
        var w: c_int = 0;
        var h: c_int = 0;
        switch (renderkit.current_renderer) {
            .opengl => sdl.SDL_GL_GetDrawableSize(self.sdl_window, &w, &h),
            .metal => sdl.SDL_Metal_GetDrawableSize(self.sdl_window, &w, &h),
            else => unreachable,
        }

        return .{ .w = w, .h = h };
    }

    pub fn size(self: Window) struct { w: c_int, h: c_int } {
        var w: c_int = 0;
        var h: c_int = 0;
        sdl.SDL_GetWindowSize(self.sdl_window, &w, &h);
        return .{ .w = w, .h = h };
    }

    pub fn setSize(self: Window, w: i32, h: i32) void {
        sdl.SDL_SetWindowSize(self.sdl_window, w, h);
    }

    pub fn position(self: Window) struct { x: c_int, y: c_int } {
        var x: c_int = 0;
        var y: c_int = 0;
        sdl.SDL_GetWindowPosition(self.sdl_window, x, y);
        return .{ .x = x, .y = y };
    }

    pub fn setPosition(self: Window, x: i32, y: i32) struct { w: c_int, h: c_int } {
        sdl.SDL_SetWindowPosition(self.sdl_window, x, y);
    }

    pub fn setMode(self: Window, mode: WindowMode) void {
        sdl.SDL_SetWindowFullscreen(self.sdl_window, mode);
    }

    pub fn focused(self: Window) bool {
        return self.focused;
    }

    pub fn resizable(self: Window) bool {
        return (sdl.SDL_GetWindowFlags(self.sdl_window) & @intCast(u32, @enumToInt(sdl.SDL_WindowFlags.SDL_WINDOW_RESIZABLE))) != 0;
    }

    pub fn setResizable(self: Window, resizable: bool) void {
        sdl.SDL_SetWindowResizable(self.sdl_window, resizable);
    }
};
