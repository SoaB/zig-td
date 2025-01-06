const GameTime = struct {
    time: f32 = 0.0,
    delta_time: f32 = 0.0,
};
pub var gTime: GameTime = GameTime{};

pub fn update(delta_time: f32) void {
    gTime.delta_time = delta_time;
    gTime.time += delta_time;
}
pub fn getTime() f32 {
    return gTime.time;
}
pub fn getDeltaTime() f32 {
    return gTime.delta_time;
}
