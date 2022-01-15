pub const Context = extern struct {
    params: Params,
    itw: f32,
    ith: f32,
    tex_data: [*c]u8,
    // omitted rest of struct

    pub fn init(params: *Params) !*Context {
        return fonsCreateInternal(params) orelse error.FailedToCreateFONS;
    }

    pub fn deinit(self: *Context) void {
        fonsDeleteInternal(self);
    }
};

pub const Params = extern struct {
    width: c_int = 256,
    height: c_int = 256,
    flags: Flags = .top_left,
    user_ptr: *anyopaque,
    renderCreate: ?fn (?*anyopaque, c_int, c_int) callconv(.C) c_int = null,
    renderResize: ?fn (?*anyopaque, c_int, c_int) callconv(.C) c_int = null,
    renderUpdate: ?fn (?*anyopaque, [*c]c_int, [*c]const u8) callconv(.C) c_int = null,
};

pub const Flags = enum(u8) {
    top_left = 1,
    bottom_left = 2,
};

pub const Align = enum(c_int) {
    // horizontal
    left = 1, // Default
    center = 2,
    right = 4,
    // vertical
    top = 8,
    middle = 16,
    bottom = 32,
    baseline = 64,
    default = 65,
    // combos
    left_middle = 17,
    center_middle = 18,
    right_middle = 20,
    top_left = 9,
};

pub const ErrorCode = enum(c_int) {
    atlas_full = 1,
    scratch_full = 2, // Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
    overflow = 3, // Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
    underflow = 4, // Trying to pop too many states fonsPopState().
};

pub const Quad = extern struct {
    x0: f32,
    y0: f32,
    s0: f32,
    t0: f32,
    x1: f32,
    y1: f32,
    s1: f32,
    t1: f32,
};

pub const FONSfont = opaque {};

pub const TextIter = extern struct {
    x: f32,
    y: f32,
    nextx: f32,
    nexty: f32,
    scale: f32,
    spacing: f32,
    color: c_uint,
    codepoint: c_uint,
    isize: c_short,
    iblur: c_short,
    font: ?*FONSfont,
    prevGlyphIndex: c_int,
    str: [*c]const u8,
    next: [*c]const u8,
    end: [*c]const u8,
    utf8state: c_uint,
};

pub const FONS_INVALID = -1;

pub extern fn fonsCreateInternal(params: [*c]Params) ?*Context;
pub extern fn fonsDeleteInternal(s: ?*Context) void;
pub extern fn fonsSetErrorCallback(s: ?*Context, callback: ?fn (?*anyopaque, c_int, c_int) callconv(.C) void, uptr: ?*anyopaque) void;
pub extern fn fonsGetAtlasSize(s: ?*Context, width: [*c]c_int, height: [*c]c_int) void;
pub extern fn fonsExpandAtlas(s: ?*Context, width: c_int, height: c_int) c_int;
pub extern fn fonsResetAtlas(stash: ?*Context, width: c_int, height: c_int) c_int;
pub extern fn fonsAddFontMem(stash: ?*Context, name: [*c]const u8, data: [*c]const u8, dataSize: c_int, freeData: c_int) c_int;
pub extern fn fonsGetFontByName(s: ?*Context, name: [*c]const u8) c_int;
pub extern fn fonsAddFallbackFont(stash: ?*Context, base: c_int, fallback: c_int) c_int;
pub extern fn fonsPushState(s: ?*Context) void;
pub extern fn fonsPopState(s: ?*Context) void;
pub extern fn fonsClearState(s: ?*Context) void;
pub extern fn fonsSetSize(s: ?*Context, size: f32) void;
pub extern fn fonsSetColor(s: ?*Context, color: c_uint) void;
pub extern fn fonsSetSpacing(s: ?*Context, spacing: f32) void;
pub extern fn fonsSetBlur(s: ?*Context, blur: f32) void;
pub extern fn fonsSetAlign(s: ?*Context, alignment: Align) void;
pub extern fn fonsSetFont(s: ?*Context, font: c_int) void;
pub extern fn fonsTextBounds(s: ?*Context, x: f32, y: f32, string: [*c]const u8, end: [*c]const u8, bounds: [*c]f32) f32;
pub extern fn fonsLineBounds(s: ?*Context, y: f32, miny: [*c]f32, maxy: [*c]f32) void;
pub extern fn fonsVertMetrics(s: ?*Context, ascender: [*c]f32, descender: [*c]f32, lineh: [*c]f32) void;
pub extern fn fonsTextIterInit(stash: ?*Context, iter: [*c]TextIter, x: f32, y: f32, str: [*c]const u8, len: c_int) c_int;
pub extern fn fonsTextIterNext(stash: ?*Context, iter: [*c]TextIter, quad: [*c]Quad) c_int;
pub extern fn fonsGetTextureData(stash: ?*Context, width: [*c]c_int, height: [*c]c_int) [*c]const u8;
pub extern fn fonsValidateTexture(s: ?*Context, dirty: [*c]c_int) c_int;
