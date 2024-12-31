const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});

const std = @import("std");
const math = std.math;

pub fn add(a: rl.Vector2, b: rl.Vector2) rl.Vector2 {
    return rl.Vector2{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn sub(a: rl.Vector2, b: rl.Vector2) rl.Vector2 {
    return rl.Vector2{
        .x = a.x - b.x,
        .y = a.y - b.y,
    };
}

pub fn scale(a: rl.Vector2, scalar: f32) rl.Vector2 {
    return rl.Vector2{
        .x = a.x * scalar,
        .y = a.y * scalar,
    };
}

pub fn dotProduct(a: rl.Vector2, b: rl.Vector2) f32 {
    return a.x * b.x + a.y * b.y;
}

pub fn magnitude(a: rl.Vector2) f32 {
    return math.sqrt(a.x * a.x + a.y * a.y);
}

pub fn normalize(a: rl.Vector2) rl.Vector2 {
    const mag = magnitude(a);
    return rl.Vector2{
        .x = a.x / mag,
        .y = a.y / mag,
    };
}
pub fn distance(v1: rl.Vector2, v2: rl.Vector2) f32 {
    const result: f32 = @sqrt((v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y));
    return result;
}
pub fn lerp(v1: rl.Vector2, v2: rl.Vector2, amount: f32) rl.Vector2 {
    const x: f32 = v1.x + amount * (v2.x - v1.x);
    const y: f32 = v1.y + amount * (v2.y - v1.y);
    return rl.Vector2{
        .x = x,
        .y = y,
    };
}
