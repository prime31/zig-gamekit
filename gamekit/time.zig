const std = @import("std");
const sdl = @import("sdl");

const samples_for_avg = 5;

pub const Time = struct {
    fps_frames: u32 = 0,
    prev_time: u32 = 0,
    curr_time: u32 = 0,
    fps_last_update: u32 = 0,
    frames_per_seconds: u32 = 0,
    frame_count: u32 = 1,
    timestep: Timestep = undefined,

    pub fn init(update_rate: f64) Time {
        return Time{
            .timestep = Timestep.init(update_rate),
        };
    }

    fn updateFps(self: *Time) void {
        self.frame_count += 1;
        self.fps_frames += 1;
        self.prev_time = self.curr_time;
        self.curr_time = sdl.SDL_GetTicks();

        const time_since_last = self.curr_time - self.fps_last_update;
        if (self.curr_time > self.fps_last_update + 1000) {
            self.frames_per_seconds = self.fps_frames * 1000 / time_since_last;
            self.fps_last_update = self.curr_time;
            self.fps_frames = 0;
        }
    }

    pub fn tick(self: *Time) void {
        self.updateFps();
        self.timestep.tick();
    }

    pub fn sleep(self: Time, ms: u32) void {
        sdl.SDL_Delay(ms);
    }

    pub fn frames(self: Time) u32 {
        return self.frame_count;
    }

    pub fn ticks(self: Time) u32 {
        return sdl.SDL_GetTicks();
    }

    pub fn seconds(self: Time) f32 {
        return @intToFloat(f32, sdl.SDL_GetTicks()) / 1000;
    }

    pub fn fps(self: Time) u32 {
        return self.frames_per_seconds;
    }

    pub fn dt(self: Time) f32 {
        return self.timestep.fixed_deltatime;
    }

    pub fn rawDeltaTime(self: Time) f32 {
        return self.timestep.raw_deltatime;
    }

    pub fn now(self: Time) u64 {
        return sdl.SDL_GetPerformanceCounter();
    }

    /// returns the time in milliseconds since the last call
    pub fn laptime(self: Time, last_time: *u64) f64 {
        tmp = last_time;
        const now = self.now();

        const dt: f64 = if (tmp.* != 0) {
            @intToFloat(f64, ((now - tmp.*) * 1000.0) / @intToFloat(f64, sdl.SDL_GetPerformanceFrequency()));
        } else 0;
        return dt;
    }

    pub fn toSeconds(self: Time, perf_counter_time: u64) f64 {
        return @intToFloat(f64, perf_counter_time) / @intToFloat(f64, sdl.SDL_GetPerformanceFrequency());
    }

    pub fn toMs(self: Time, perf_counter_time: u64) f64 {
        return @intToFloat(f64, perf_counter_time) * 1000 / @intToFloat(f64, sdl.SDL_GetPerformanceFrequency());
    }

    /// forces a resync of the timing code. Useful after some slower operations such as level loads or window resizes
    pub fn resync(self: *Time) void {
        self.timestep.resync = true;
        self.timestep.prev_frame_time = sdl.SDL_GetPerformanceCounter() + @floatToInt(u64, self.timestep.fixed_deltatime);
    }

    // converted from Tyler Glaiel's: https://github.com/TylerGlaiel/FrameTimingControl/blob/master/frame_timer.cpp
    const Timestep = struct {
        // compute how many ticks one update should be
        fixed_deltatime: f32,
        desired_frametime: i32,
        raw_deltatime: f32 = 0,

        // these are to snap deltaTime to vsync values if it's close enough
        vsync_maxerror: u64,
        snap_frequencies: [5]i32 = undefined,
        prev_frame_time: u64,
        frame_accumulator: i64 = 0,
        resync: bool = false,
        // time_averager: utils.Ring_Buffer(u64, samples_for_avg),
        time_averager: [samples_for_avg]i32 = undefined,

        pub fn init(update_rate: f64) Timestep {
            var timestep = Timestep{
                .fixed_deltatime = 1 / @floatCast(f32, update_rate),
                .desired_frametime = @floatToInt(i32, @intToFloat(f64, sdl.SDL_GetPerformanceFrequency()) / update_rate),
                .vsync_maxerror = sdl.SDL_GetPerformanceFrequency() / 5000,
                .prev_frame_time = sdl.SDL_GetPerformanceCounter(),
            };

            // TODO:
            // utils.ring_buffer_fill(&timestep.time_averager, timestep.desired_frametime);
            timestep.time_averager = [samples_for_avg]i32{ timestep.desired_frametime, timestep.desired_frametime, timestep.desired_frametime, timestep.desired_frametime, timestep.desired_frametime };

            const time_60hz = @floatToInt(i32, @intToFloat(f64, sdl.SDL_GetPerformanceFrequency()) / 60);
            timestep.snap_frequencies[0] = time_60hz; // 60fps
            timestep.snap_frequencies[1] = time_60hz * 2; // 30fps
            timestep.snap_frequencies[2] = time_60hz * 3; // 20fps
            timestep.snap_frequencies[3] = time_60hz * 4; // 15fps
            timestep.snap_frequencies[4] = @divTrunc(time_60hz + 1, 2); // 120fps

            return timestep;
        }

        pub fn tick(self: *Timestep) void {
            // frame timer
            const current_frame_time = sdl.SDL_GetPerformanceCounter();
            const delta_u32 = @truncate(u32, current_frame_time - self.prev_frame_time);
            var delta_time = @intCast(i32, delta_u32);
            self.prev_frame_time = current_frame_time;

            // handle unexpected timer anomalies (overflow, extra slow frames, etc)
            if (delta_time > self.desired_frametime * 8) delta_time = self.desired_frametime;
            if (delta_time < 0) delta_time = 0;

            // vsync time snapping
            for (self.snap_frequencies) |snap| {
                if (std.math.absCast(delta_time - snap) < self.vsync_maxerror) {
                    delta_time = snap;
                    break;
                }
            }

            // delta time averaging
            var dt_avg = delta_time;
            var i: usize = 0;
            while (i < samples_for_avg - 1) : (i += 1) {
                self.time_averager[i] = self.time_averager[i + 1];
                dt_avg += self.time_averager[i];
            }

            self.time_averager[samples_for_avg - 1] = delta_time;
            delta_time = @divTrunc(dt_avg, samples_for_avg);
            self.raw_deltatime = @intToFloat(f32, delta_u32) / @intToFloat(f32, sdl.SDL_GetPerformanceFrequency());

            // add to the accumulator
            self.frame_accumulator += delta_time;

            // spiral of death protection
            if (self.frame_accumulator > self.desired_frametime * 8) self.resync = true;

            // TODO: should we zero out the frame_accumulator here? timer resync if requested so reset all state
            if (self.resync) {
                self.frame_accumulator = self.desired_frametime;
                delta_time = self.desired_frametime;
                self.resync = false;
            }
        }
    };
};