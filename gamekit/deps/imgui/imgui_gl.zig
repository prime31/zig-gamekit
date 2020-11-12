const imgui = @import("imgui.zig");

pub extern fn gl3wInit() void;

// ImGui SDL2 and OpenGL3 implementation
pub extern fn ImGui_ImplSDL2_InitForOpenGL(window: ?*c_void, sdl_gl_context: ?*c_void) bool;
pub extern fn ImGui_ImplSDL2_ProcessEvent(event: ?*c_void) bool;
pub extern fn ImGui_ImplSDL2_NewFrame(window: ?*c_void) void;
pub extern fn ImGui_ImplSDL2_Shutdown() void;

pub extern fn ImGui_ImplOpenGL3_Init(glsl_version: [*c]const u8) bool;
pub extern fn ImGui_ImplOpenGL3_NewFrame() void;
pub extern fn ImGui_ImplOpenGL3_RenderDrawData(draw_data: ?*c_void) void;
pub extern fn ImGui_ImplOpenGL3_Shutdown() void;

// ImGui lifecycle helpers, wrapping ImGui, SDL2 Impl and GL Impl methods
// BEFORE calling init_for_gl a gl loader lib must be called! You must use the same one
// used in the makefile when imgui was compiled!
pub fn initForGl(glsl_version: [*c]const u8, window: ?*c_void, gl_context: ?*c_void) void {
    gl3wInit();
    _ = ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    _ = ImGui_ImplOpenGL3_Init(glsl_version);
}

pub fn newFrame(window: ?*c_void) void {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame(window);
    imgui.igNewFrame();
}

pub fn render() void {
    imgui.igRender();

    var io = imgui.igGetIO();
    ImGui_ImplOpenGL3_RenderDrawData(imgui.igGetDrawData());

    if ((io.ConfigFlags & imgui.ImGuiConfigFlags_ViewportsEnable) != 0) {
        imgui.igUpdatePlatformWindows();
        imgui.igRenderPlatformWindowsDefault(null, null);
    }
}

pub fn shutdown() void {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    imgui.igDestroyContext(null);
}
