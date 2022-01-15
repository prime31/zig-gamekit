const std = @import("std");
const gk = @import("../gamekit.zig");
const rk = @import("renderkit");
const fons = @import("fontstash");

pub const FontBook = struct {
    stash: *fons.Context,
    texture: ?gk.gfx.Texture,
    tex_filter: rk.TextureFilter,
    width: i32 = 0,
    height: i32 = 0,
    tex_dirty: bool = false,
    last_update: u32 = 0,
    allocator: std.mem.Allocator,

    pub const Align = fons.Align;

    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32, filter: rk.TextureFilter) !*FontBook {
        var book = try allocator.create(FontBook);
        errdefer allocator.destroy(book);

        var params = fons.Params{
            .width = width,
            .height = height,
            .flags = fons.Flags.top_left,
            .user_ptr = book,
            .renderCreate = renderCreate,
            .renderResize = renderResize,
            .renderUpdate = renderUpdate,
        };

        book.texture = null;
        book.tex_filter = filter;
        book.width = width;
        book.height = height;
        book.allocator = allocator;
        book.stash = try fons.Context.init(&params);

        return book;
    }

    pub fn deinit(self: *FontBook) void {
        self.stash.deinit();
        if (self.texture != null) self.texture.?.deinit();
        self.allocator.destroy(self);
    }

    // add fonts
    pub fn addFont(self: *FontBook, file: [:0]const u8) c_int {
        const data = gk.fs.read(self.allocator, file) catch unreachable;

        // we can let FONS free the data since we are using the c_allocator here
        return fons.fonsAddFontMem(self.stash, file, @ptrCast([*c]const u8, data), @intCast(i32, data.len), 1);
    }

    pub fn addFontMem(self: *FontBook, name: [:0]const u8, data: []const u8, free_data: bool) c_int {
        const free: c_int = if (free_data) 1 else 0;
        return fons.fonsAddFontMem(self.stash, name, @ptrCast([*c]const u8, data), @intCast(i32, data.len), free);
    }

    // state setting
    pub fn setAlign(self: *FontBook, alignment: Align) void {
        fons.fonsSetAlign(self.stash, alignment);
    }

    pub fn setSize(self: FontBook, size: f32) void {
        fons.fonsSetSize(self.stash, size);
    }

    pub fn setColor(self: FontBook, color: gk.math.Color) void {
        fons.fonsSetColor(self.stash, color.value);
    }

    pub fn setSpacing(self: FontBook, spacing: f32) void {
        fons.fonsSetSpacing(self.stash, spacing);
    }

    pub fn setBlur(self: FontBook, blur: f32) void {
        fons.fonsSetBlur(self.stash, blur);
    }

    // state handling
    pub fn pushState(self: *FontBook) void {
        fons.fonsPushState(self.stash);
    }

    pub fn popState(self: *FontBook) void {
        fons.fonsPopState(self.stash);
    }

    pub fn clearState(self: *FontBook) void {
        fons.fonsClearState(self.stash);
    }

    // measure text
    pub fn getTextBounds(self: *FontBook, x: f32, y: f32, str: []const u8) struct { width: f32, bounds: f32 } {
        var bounds: f32 = undefined;
        const width = fons.fonsTextBounds(self.stash, x, y, str.ptr, null, &bounds);
        return .{ .width = width, .bounds = bounds };
    }

    pub fn getLineBounds(self: *FontBook, y: f32) struct { min_y: f32, max_y: f32 } {
        var min_y: f32 = undefined;
        var max_y: f32 = undefined;
        fons.fonsLineBounds(self.stash, y, &min_y, &max_y);
        return .{ .min_y = min_y, .max_y = max_y };
    }

    pub fn getVertMetrics(self: *FontBook) struct { ascender: f32, descender: f32, line_h: f32 } {
        var ascender: f32 = undefined;
        var descender: f32 = undefined;
        var line_h: f32 = undefined;
        fons.fonsVertMetrics(self.stash, &ascender, &descender, &line_h);
        return .{ .ascender = ascender, .descender = descender, .line_h = line_h };
    }

    // text iter
    pub fn getTextIterator(self: *FontBook, str: []const u8) fons.TextIter {
        var iter = std.mem.zeroes(fons.TextIter);
        const res = fons.fonsTextIterInit(self.stash, &iter, 0, 0, str.ptr, @intCast(c_int, str.len));
        if (res == 0) std.log.warn("getTextIterator failed! Make sure you have added a font.\n", .{});
        return iter;
    }

    pub fn textIterNext(self: *FontBook, iter: *fons.TextIter, quad: *fons.Quad) bool {
        return fons.fonsTextIterNext(self.stash, iter, quad) == 1;
    }

    pub fn getQuad(self: FontBook) fons.Quad {
        _ = self;
        return std.mem.zeroes(fons.Quad);
    }

    fn renderCreate(ctx: ?*anyopaque, width: c_int, height: c_int) callconv(.C) c_int {
        var self = @ptrCast(*FontBook, @alignCast(@alignOf(FontBook), ctx));

        if (self.texture != null and (self.texture.?.width != @intToFloat(f32, width) or self.texture.?.height != @intToFloat(f32, height))) {
            self.texture.?.deinit();
            self.texture = null;
        }

        if (self.texture == null)
            self.texture = gk.gfx.Texture.initDynamic(width, height, self.tex_filter, .clamp);

        self.width = width;
        self.height = height;

        return 1;
    }

    fn renderResize(ctx: ?*anyopaque, width: c_int, height: c_int) callconv(.C) c_int {
        return renderCreate(ctx, width, height);
    }

    fn renderUpdate(ctx: ?*anyopaque, rect: [*c]c_int, data: [*c]const u8) callconv(.C) c_int {
        // TODO: only update the rect that changed
        _ = rect;

        var self = @ptrCast(*FontBook, @alignCast(@alignOf(FontBook), ctx));
        if (!self.tex_dirty or self.last_update == gk.time.frames()) {
            self.tex_dirty = true;
            return 0;
        }

        const tex_area = @intCast(usize, self.width * self.height);
        var pixels = self.allocator.alloc(u8, tex_area * 4) catch |err| {
            std.log.warn("failed to allocate texture data: {}\n", .{err});
            return 0;
        };
        defer self.allocator.free(pixels);
        const source = data[0..tex_area];

        for (source) |alpha, i| {
            pixels[i * 4 + 0] = 255;
            pixels[i * 4 + 1] = 255;
            pixels[i * 4 + 2] = 255;
            pixels[i * 4 + 3] = alpha;
        }

        self.texture.?.setData(u8, pixels);
        self.tex_dirty = false;
        self.last_update = gk.time.frames();
        return 1;
    }
};
