const Timer = struct {
    time: f32 = 0.0,
    deltaTime: f32 = 0.0,
};
pub const GameTime = struct {
    var timer: Timer = Timer{};
    pub fn update(deltaTime: f32) void {
        timer.deltaTime = deltaTime;
        timer.time += deltaTime;
    }
    pub fn reset() void {
        timer.time = 0.0;
    }
    pub fn getDeltaTime() f32 {
        return timer.deltaTime;
    }
    pub fn getTime() f32 {
        return timer.time;
    }
};
