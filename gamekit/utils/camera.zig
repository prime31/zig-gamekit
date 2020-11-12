const std = @import("std");
const gk = @import("../gamekit.zig");
const math = gk.math;

pub const Camera = struct {
    pos: math.Vec2 = .{},
    zoom: f32 = 1,

    pub fn init() Camera {
        return .{};
    }

    pub fn transMat(self: Camera) math.Mat32 {
        const size = gk.window.size();
        const half_w = @intToFloat(f32, size.w) * 0.5;
        const half_h = @intToFloat(f32, size.h) * 0.5;

        var transform = math.Mat32.identity;

        var tmp = math.Mat32.identity;
        tmp.translate(-self.pos.x, -self.pos.y);
        transform = tmp.mul(transform);

        tmp = math.Mat32.identity;
        tmp.scale(self.zoom, self.zoom);
        transform = tmp.mul(transform);

        tmp = math.Mat32.identity;
        tmp.translate(half_w, half_h);
        transform = tmp.mul(transform);

        return transform;
    }

    pub fn screenToWorld(self: Camera, pos: math.Vec2) math.Vec2 {
        var inv_trans_mat = self.transMat().invert();
        return inv_trans_mat.transformVec2(.{ .x = pos.x, .y = @intToFloat(f32, gk.window.height()) - pos.y });
    }
};
