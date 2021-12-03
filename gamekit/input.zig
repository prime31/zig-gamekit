const std = @import("std");
const sdl = @import("sdl");
const gk = @import("gamekit.zig");
const math = gk.math;
const input_types = @import("input_types.zig");
pub usingnamespace input_types;

const FixedList = gk.utils.FixedList;

const released: u3 = 1; // true only the frame the key is released
const down: u3 = 2; // true the entire time the key is down
const pressed: u3 = 3; // only true if down this frame and not down the previous frame

pub const MouseButton = enum(usize) {
    left = 1,
    middle = 2,
    right = 3,
};

pub const Input = struct {
    keys: [@intCast(usize, @enumToInt(input_types.Keys.num_keys))]u2 = [_]u2{0} ** @intCast(usize, @enumToInt(input_types.Keys.num_keys)),
    dirty_keys: FixedList(i32, 10),
    mouse_buttons: [4]u2 = [_]u2{0} ** 4,
    dirty_mouse_buttons: FixedList(u2, 3),
    mouse_wheel_y: i32 = 0,
    mouse_rel_x: i32 = 0,
    mouse_rel_y: i32 = 0,
    window_scale: i32 = 0,

    text_edit_buffer: [32]u8 = [_]u8{0} ** 32,
    text_input_buffer: [32]u8 = [_]u8{0} ** 32,
    text_edit: ?[]u8 = null,
    text_input: ?[]u8 = null,

    pub fn init(win_scale: f32) Input {
        return .{
            .dirty_keys = FixedList(i32, 10).init(),
            .dirty_mouse_buttons = FixedList(u2, 3).init(),
            .window_scale = @floatToInt(i32, win_scale),
        };
    }

    /// clears any released keys
    pub fn newFrame(self: *Input) void {
        if (self.dirty_keys.len > 0) {
            var iter = self.dirty_keys.iter();
            while (iter.next()) |key| {
                const ukey = @intCast(usize, key);

                // guard against double key presses
                if (self.keys[ukey] > 0)
                    self.keys[ukey] -= 1;
            }
            self.dirty_keys.clear();
        }

        if (self.dirty_mouse_buttons.len > 0) {
            var iter = self.dirty_mouse_buttons.iter();
            while (iter.next()) |button| {

                // guard against double mouse presses
                if (self.mouse_buttons[button] > 0)
                    self.mouse_buttons[button] -= 1;
            }
            self.dirty_mouse_buttons.clear();
        }

        self.mouse_wheel_y = 0;
        self.mouse_rel_x = 0;
        self.mouse_rel_y = 0;
        self.text_edit = null;
        self.text_input = null;
    }

    pub fn handleEvent(self: *Input, event: *sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_KEYDOWN, sdl.SDL_KEYUP => self.handleKeyboardEvent(&event.key),
            sdl.SDL_MOUSEBUTTONDOWN, sdl.SDL_MOUSEBUTTONUP => self.handleMouseEvent(&event.button),
            sdl.SDL_MOUSEWHEEL => self.mouse_wheel_y = event.wheel.y,
            sdl.SDL_MOUSEMOTION => {
                self.mouse_rel_x = event.motion.xrel;
                self.mouse_rel_y = event.motion.yrel;
            },
            sdl.SDL_CONTROLLERAXISMOTION => std.log.warn("SDL_CONTROLLERAXISMOTION\n", .{}),
            sdl.SDL_CONTROLLERBUTTONDOWN, sdl.SDL_CONTROLLERBUTTONUP => std.log.warn("SDL_CONTROLLERBUTTONUP/DOWN\n", .{}),
            sdl.SDL_CONTROLLERDEVICEADDED, sdl.SDL_CONTROLLERDEVICEREMOVED => std.log.warn("SDL_CONTROLLERDEVICEADDED/REMOVED\n", .{}),
            sdl.SDL_CONTROLLERDEVICEREMAPPED => std.log.warn("SDL_CONTROLLERDEVICEREMAPPED\n", .{}),
            sdl.SDL_TEXTEDITING, sdl.SDL_TEXTINPUT => {
                self.text_input_buffer = event.text.text;
                const end = std.mem.indexOfScalar(u8, &self.text_input_buffer, 0).?;
                self.text_input = self.text_input_buffer[0..end];
            },
            else => {},
        }
    }

    fn handleKeyboardEvent(self: *Input, evt: *sdl.SDL_KeyboardEvent) void {
        const scancode = @enumToInt(evt.keysym.scancode);
        self.dirty_keys.append(scancode);

        if (evt.state == 0) {
            self.keys[@intCast(usize, scancode)] = released;
        } else {
            self.keys[@intCast(usize, scancode)] = pressed;
        }

        // std.debug.warn("kb: {s}: {}\n", .{ sdl.SDL_GetKeyName(evt.keysym.sym), evt });
    }

    fn handleMouseEvent(self: *Input, evt: *sdl.SDL_MouseButtonEvent) void {
        self.dirty_mouse_buttons.append(@intCast(u2, evt.button));
        if (evt.state == 0) {
            self.mouse_buttons[@intCast(usize, evt.button)] = released;
        } else {
            self.mouse_buttons[@intCast(usize, evt.button)] = pressed;
        }

        // std.debug.warn("mouse: {}\n", .{evt});
    }

    /// only true if down this frame and not down the previous frame
    pub fn keyPressed(self: Input, key: input_types.Keys) bool {
        return self.keys[@intCast(usize, @enumToInt(key))] == pressed;
    }

    /// true the entire time the key is down
    pub fn keyDown(self: Input, key: input_types.Keys) bool {
        return self.keys[@intCast(usize, @enumToInt(key))] > released;
    }

    /// true only the frame the key is released
    pub fn keyUp(self: Input, key: input_types.Keys) bool {
        return self.keys[@intCast(usize, @enumToInt(key))] == released;
    }

    /// slice is only valid for the current frame
    pub fn textEdit(self: Input) ?[]const u8 {
        return self.text_edit orelse null;
    }

    /// slice is only valid for the current frame
    pub fn textInput(self: Input) ?[]const u8 {
        return self.text_input orelse null;
    }

    /// only true if down this frame and not down the previous frame
    pub fn mousePressed(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@enumToInt(button)] == pressed;
    }

    /// true the entire time the button is down
    pub fn mouseDown(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@enumToInt(button)] > released;
    }

    /// true only the frame the button is released
    pub fn mouseUp(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@enumToInt(button)] == released;
    }

    pub fn mouseWheel(self: Input) i32 {
        return self.mouse_wheel_y;
    }

    pub fn mousePos(self: Input) math.Vec2 {
        var xc: c_int = undefined;
        var yc: c_int = undefined;
        _ = sdl.SDL_GetMouseState(&xc, &yc);
        return .{ .x = @intToFloat(f32, xc * self.window_scale), .y = @intToFloat(f32, yc * self.window_scale) };
    }

    // gets the scaled mouse position based on the currently bound render texture scale and offset
    // as calcuated in OffscreenPass. scale should be scale and offset_n is the calculated x, y value.
    pub fn mousePosScaled(self: Input) math.Vec2 {
        const p = self.mousePos();

        const xf = p.x - @intToFloat(f32, self.res_scaler.x);
        const yf = p.y - @intToFloat(f32, self.res_scaler.y);
        return .{ .x = xf / self.res_scaler.scale, .y = yf / self.res_scaler.scale };
    }

    pub fn mousePosScaledVec(self: Input) math.Vec2 {
        var x: i32 = undefined;
        var y: i32 = undefined;
        self.mousePosScaled(&x, &y);
        return .{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
    }

    pub fn mouseRelMotion(self: Input, x: *i32, y: *i32) void {
        x.* = self.mouse_rel_x;
        y.* = self.mouse_rel_y;
    }
};

test "test input" {
    var input = Input.init(1);
    _ = input.keyPressed(.a);
    _ = input.mousePressed(.left);
    _ = input.mouseWheel();

    var x: i32 = undefined;
    var y: i32 = undefined;
    _ = input.mousePosScaled(&x, &y);

    _ = input.mousePosScaledVec();
    input.mouseRelMotion(&x, &y);
}
