const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});

const std = @import("std");
const math = std.math;
const print = std.debug.print;
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
pub fn inv_sqrt(f: anytype, iterations: usize) @TypeOf(f) {
    const x2: @TypeOf(f) = f * 0.5;
    const uType: type = switch (@TypeOf(f)) {
        f32 => u32,
        f64 => u64,
        f128 => u128,
        else => @compileError("Unexpected type " ++ @typeName(@TypeOf(f))),
    };
    const i: uType = @bitCast(f); // evil float bit hacking
    var y: @TypeOf(f) = switch (@TypeOf(f)) { // what the fuck?
        f32 => @bitCast(0x5F3759DF - (i >> 1)),
        f64 => @bitCast(0x5FE6EB50C7B537A9 - (i >> 1)),
        // brute force, wild guess, f128 magic number
        f128 => @bitCast(0x5FFE6B21300000000000000000000000 - (i >> 1)),
        else => @compileError("Unexpected type " ++ @typeName(@TypeOf(f))),
    };
    for (0..iterations) |_| y = y * (1.5 - (x2 * y * y));

    return y;
}
pub fn normal(a: rl.Vector2) rl.Vector2 {
    const inv_mag = inv_sqrt(a.x * a.x + a.y * a.y, 2);
    return rl.Vector2{
        .x = a.x * inv_mag,
        .y = a.y * inv_mag,
    };
}
