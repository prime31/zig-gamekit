const Vec2 = @import("vec2.zig").Vec2;
const Color = @import("color.zig").Color;
const Quad = @import("quad.zig").Quad;
const Vertex = @import("../gamekit.zig").gfx.Vertex;
const std = @import("std");
const math = std.math;

// 3 row, 2 col 2D matrix
//
//  m[0] m[2] m[4]
//  m[1] m[3] m[5]
//
//  0: scaleX    2: sin       4: transX
//  1: cos       3: scaleY    5: transY
//
pub const Mat32 = extern struct {
    data: [6]f32 = undefined,

    pub const TransformParams = struct { x: f32 = 0, y: f32 = 0, angle: f32 = 0, sx: f32 = 1, sy: f32 = 1, ox: f32 = 0, oy: f32 = 0 };

    pub const identity = Mat32{ .data = .{ 1, 0, 0, 1, 0, 0 } };

    pub fn format(self: Mat32, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        return writer.print("{d:0.6}, {d:0.6}, {d:0.6}, {d:0.6}, {d:0.6}, {d:0.6}", .{ self.data[0], self.data[1], self.data[2], self.data[3], self.data[4], self.data[5] });
    }

    pub fn init() Mat32 {
        return identity;
    }

    pub fn initTransform(vals: TransformParams) Mat32 {
        var mat = Mat32{};
        mat.setTransform(vals);
        return mat;
    }

    pub fn initOrthoInverted(width: f32, height: f32) Mat32 {
        var result = Mat32{};
        result.data[0] = 2 / width;
        result.data[3] = 2 / height;
        result.data[4] = -1;
        result.data[5] = -1;
        return result;
    }

    pub fn initOrtho(width: f32, height: f32) Mat32 {
        var result = Mat32{};
        result.data[0] = 2 / width;
        result.data[3] = -2 / height;
        result.data[4] = -1;
        result.data[5] = 1;
        return result;
    }

    pub fn initOrthoOffCenter(width: f32, height: f32) Mat32 {
        const half_w = @ceil(width / 2);
        const half_h = @ceil(height / 2);

        var result = identity;
        result.data[0] = 2.0 / (half_w + half_w);
        result.data[3] = 2.0 / (-half_h - half_h);
        result.data[4] = (-half_w + half_w) / (-half_w - half_w);
        result.data[5] = (half_h - half_h) / (half_h + half_h);
        return result;
    }

    pub fn setTransform(self: *Mat32, vals: TransformParams) void {
        const c = math.cos(vals.angle);
        const s = math.sin(vals.angle);

        // matrix multiplication carried out on paper:
        // |1    x| |c -s  | |sx     | |1   -ox|
        // |  1  y| |s  c  | |   sy  | |  1 -oy|
        //   move    rotate    scale     origin
        self.data[0] = c * vals.sx;
        self.data[1] = s * vals.sx;
        self.data[2] = -s * vals.sy;
        self.data[3] = c * vals.sy;
        self.data[4] = vals.x - vals.ox * self.data[0] - vals.oy * self.data[2];
        self.data[5] = vals.y - vals.ox * self.data[1] - vals.oy * self.data[3];
    }

    pub fn invert(self: Mat32) Mat32 {
        var res = Mat32{};
        var det = 1 / (self.data[0] * self.data[3] - self.data[1] * self.data[2]);

        res.data[0] = self.data[3] * det;
        res.data[1] = -self.data[1] * det;

        res.data[2] = -self.data[2] * det;
        res.data[3] = self.data[0] * det;

        res.data[4] = (self.data[5] * self.data[2] - self.data[4] * self.data[3]) * det;
        res.data[5] = -(self.data[5] * self.data[0] - self.data[4] * self.data[1]) * det;

        return res;
    }

    pub fn mul(self: Mat32, r: Mat32) Mat32 {
        var result = Mat32{};
        result.data[0] = self.data[0] * r.data[0] + self.data[2] * r.data[1];
        result.data[1] = self.data[1] * r.data[0] + self.data[3] * r.data[1];
        result.data[2] = self.data[0] * r.data[2] + self.data[2] * r.data[3];
        result.data[3] = self.data[1] * r.data[2] + self.data[3] * r.data[3];
        result.data[4] = self.data[0] * r.data[4] + self.data[2] * r.data[5] + self.data[4];
        result.data[5] = self.data[1] * r.data[4] + self.data[3] * r.data[5] + self.data[5];
        return result;
    }

    pub fn translate(self: *Mat32, x: f32, y: f32) void {
        self.data[4] = self.data[0] * x + self.data[2] * y + self.data[4];
        self.data[5] = self.data[1] * x + self.data[3] * y + self.data[5];
    }

    pub fn rotate(self: *Mat32, rads: f32) void {
        const cos = math.cos(rads);
        const sin = math.sin(rads);

        const nm0 = self.data[0] * cos + self.data[2] * sin;
        const nm1 = self.data[1] * cos + self.data[3] * sin;

        self.data[2] = self.data[0] * -sin + self.data[2] * cos;
        self.data[3] = self.data[1] * -sin + self.data[3] * cos;
        self.data[0] = nm0;
        self.data[1] = nm1;
    }

    pub fn scale(self: *Mat32, x: f32, y: f32) void {
        self.data[0] *= x;
        self.data[1] *= x;
        self.data[2] *= y;
        self.data[3] *= y;
    }

    pub fn transformVec2(self: Mat32, pos: Vec2) Vec2 {
        return .{
            .x = pos.x * self.data[0] + pos.y * self.data[2] + self.data[4],
            .y = pos.x * self.data[1] + pos.y * self.data[3] + self.data[5],
        };
    }

    pub fn transformVec2Slice(self: Mat32, comptime T: type, dst: []T, src: []Vec2) void {
        for (src, 0..) |_, i| {
            const x = src[i].x * self.data[0] + src[i].y * self.data[2] + self.data[4];
            const y = src[i].x * self.data[1] + src[i].y * self.data[3] + self.data[5];
            dst[i].x = x;
            dst[i].y = y;
        }
    }

    /// transforms the positions in Quad and copies them to dst along with the uvs and color. This could be made generic
    /// if we have other common Vertex types
    pub fn transformQuad(self: Mat32, dst: []Vertex, quad: Quad, color: Color) void {
        for (dst, 0..) |*item, i| {
            item.*.pos.x = quad.positions[i].x * self.data[0] + quad.positions[i].y * self.data[2] + self.data[4];
            item.*.pos.y = quad.positions[i].x * self.data[1] + quad.positions[i].y * self.data[3] + self.data[5];
            item.*.uv = quad.uvs[i];
            item.*.col = color.value;
        }
    }

    pub fn transformVertexSlice(self: Mat32, dst: []Vertex) void {
        for (dst, 0..) |_, i| {
            const x = dst[i].pos.x * self.data[0] + dst[i].pos.y * self.data[2] + self.data[4];
            const y = dst[i].pos.x * self.data[1] + dst[i].pos.y * self.data[3] + self.data[5];

            // we defer setting because src and dst are the same
            dst[i].pos.x = x;
            dst[i].pos.y = y;
        }
    }
};

test "mat32 tests" {
    const i = Mat32.identity;
    _ = i;
    const mat1 = Mat32.initTransform(.{ .x = 10, .y = 10 });
    var mat2 = Mat32{};
    mat2.setTransform(.{ .x = 10, .y = 10 });
    std.testing.expectEqual(mat2, mat1);

    var mat3 = Mat32.init();
    mat3.setTransform(.{ .x = 10, .y = 10 });
    std.testing.expectEqual(mat3, mat1);

    const mat4 = Mat32.initOrtho(640, 480);
    _ = mat4;
    const mat5 = Mat32.initOrthoOffCenter(640, 480);
    _ = mat5;

    var mat6 = Mat32.init();
    mat6.translate(10, 20);
    std.testing.expectEqual(mat6.data[4], 10);
}

test "mat32 transform tests" {
    const i = Mat32.identity;
    const vec = Vec2.init(44, 55);
    const vec_t = i.transformVec2(vec);
    std.testing.expectEqual(vec, vec_t);

    var verts = [_]Vertex{
        .{ .pos = .{ .x = 0.5, .y = 0.5 }, .uv = .{ .x = 1, .y = 1 }, .col = 0xFFFFFFFF },
        .{ .pos = .{ .x = 0.5, .y = -0.5 }, .uv = .{ .x = 1, .y = 0 }, .col = 0x00FF0FFF },
        .{ .pos = .{ .x = -0.5, .y = -0.5 }, .uv = .{ .x = 0, .y = 0 }, .col = 0xFF00FFFF },
        .{ .pos = .{ .x = -0.5, .y = -0.5 }, .uv = .{ .x = 0, .y = 0 }, .col = 0xFF00FFFF },
        .{ .pos = .{ .x = -0.5, .y = 0.5 }, .uv = .{ .x = 0, .y = 1 }, .col = 0x00FFFFFF },
        .{ .pos = .{ .x = 0.5, .y = 0.5 }, .uv = .{ .x = 1, .y = 1 }, .col = 0xFFFFFFFF },
    };
    const quad = Quad.init(0, 0, 50, 50, 600, 400);
    _ = quad;
    // i.transformQuad(verts[0..], quad, Color.red); // triggers Zig bug

    i.transformVertexSlice(verts[0..]);
}
