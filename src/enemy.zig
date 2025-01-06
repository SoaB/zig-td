const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;
const Vec2f = @import("Vector2.zig").Vec2f;
const gameTime = @import("GameTime.zig");
pub const ENEMY_MAX_COUNT = 400;
pub const EnemyType = enum(u8) {
    NONE,
    MIMION,
    _,
};
pub const EnemyConfig = struct {
    speed: f32 = 0,
    health: f32 = 0,
};
pub const EnemyConfigs = [_]EnemyConfig{
    .{}, // NONE
    .{ // MIMION
        .speed = 1.0,
        .health = 3.0,
    },
};
pub const EnemyIdentity = struct {
    index: usize,
    generation: u32,
};

pub const EnemyId = struct {
    pub fn getId(index: usize) EnemyIdentity {
        return EnemyIdentity{
            .index = index,
            .generation = Enemys.enemies[index].generation,
        };
    }
    pub fn tryResolve(id: EnemyIdentity) ?usize {
        if (id.index >= ENEMY_MAX_COUNT) {
            return null;
        }
        if (Enemys.enemies[id.index].generation != id.generation or Enemys.enemies[id.index].enemy_type == EnemyType.NONE) {
            return null;
        }
        return id.index;
    }
};
pub const Enemy = struct {
    x: i32,
    y: i32,
    next_x: i32,
    next_y: i32,
    generation: u32,
    start_moving_time: f32,
    damage: f32,
    feture_damage: f32,
    enemy_type: EnemyType,
};

pub const Enemys = struct {
    var count: u32 = 0;
    var enemies: [ENEMY_MAX_COUNT]Enemy = undefined;
    pub fn init() void {
        for (&enemies) |*e| {
            e.* = Enemy{
                .x = 0,
                .y = 0,
                .next_x = 0,
                .next_y = 0,
                .generation = 0,
                .start_moving_time = gameTime.getTime(),
                .damage = 0,
                .feture_damage = 0,
                .enemy_type = EnemyType.NONE,
            };
        }
        count = 0;
    }
    pub fn add(x: i32, y: i32, t: EnemyType) void {
        for (enemies[0..count]) |*e| {
            if (e.*.enemy_type == EnemyType.NONE) {
                e.*.x = x;
                e.*.y = y;
                e.*.next_x = x;
                e.*.next_y = y;
                e.*.generation += 1;
                e.*.start_moving_time = gameTime.getTime();
                e.*.damage = 0;
                e.*.feture_damage = 0;
                e.*.enemy_type = t;
                return;
            }
        }
        if (count < ENEMY_MAX_COUNT) {
            enemies[count].x = x;
            enemies[count].y = y;
            enemies[count].next_x = x;
            enemies[count].next_y = y;
            enemies[count].generation += 1;
            enemies[count].start_moving_time = gameTime.getTime();
            enemies[count].damage = 0;
            enemies[count].feture_damage = 0;
            enemies[count].enemy_type = t;
            count += 1;
        }
    }
    pub fn addDamage(idx: usize, damage: f32) void {
        if (idx < count) {
            enemies[idx].damage += damage;
            if (enemies[idx].damage >= getMaxHealth(enemies[idx].enemy_type)) {
                enemies[idx].enemy_type = EnemyType.NONE;
            }
        }
    }
    pub fn addfetureDamage(idx: usize, damage: f32) void {
        if (idx < count) {
            enemies[idx].feture_damage += damage;
        }
    }
    pub fn remove(idx: usize) void {
        if (idx < count) {
            enemies[idx].enemy_type = EnemyType.NONE;
        }
    }
    pub fn getStartMovingTime(idx: usize) f32 {
        return enemies[idx].start_moving_time;
    }
    pub fn getCurrentSpeed(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].speed;
    }
    pub fn getMaxHealth(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].health;
    }
    pub fn draw() void {
        for (enemies[0..count], 0..count) |e, i| {
            const posi: Vec2f = getPosition(i, gameTime.getTime() - e.start_moving_time);
            switch (e.enemy_type) {
                EnemyType.MIMION => {
                    rl.DrawCube(rl.Vector3{ .x = posi.x, .y = 0.2, .z = posi.y }, 0.4, 0.4, 0.4, rl.GREEN);
                },
                else => {},
            }
        }
    }
    pub fn getNextPosition(cX: i32, cY: i32, nX: *i32, nY: *i32) bool {
        const castle_x: i32 = 0;
        const castle_y: i32 = 0;
        const dx: i32 = castle_x - cX;
        const dy: i32 = castle_y - cY;
        if (@abs(dx) <= 0 and @abs(dy) <= 0) {
            nX.* = cX;
            nY.* = cY;
            return true;
        }
        if (@abs(dx) > @abs(dy)) {
            if (dx > 0) {
                nX.* = cX + 1;
            } else {
                nX.* = cX - 1;
            }
            nY.* = cY;
        } else {
            nX.* = cX;
            if (dy > 0) {
                nY.* = cY + 1;
            } else {
                nY.* = cY - 1;
            }
        }
        return false;
    }
    pub fn getPosition(idx: usize, deltaT: f32) Vec2f {
        var speed = getCurrentSpeed(enemies[idx].enemy_type) * deltaT;
        var curr_x: i32 = enemies[idx].x;
        var curr_y: i32 = enemies[idx].y;
        var next_x: i32 = enemies[idx].next_x;
        var next_y: i32 = enemies[idx].next_y;
        while (speed > 1.0) {
            speed -= 1.0;
            curr_x = next_x;
            curr_y = next_y;
            if (getNextPosition(curr_x, curr_y, &next_x, &next_y)) {
                const x: f32 = @floatFromInt(curr_x);
                const y: f32 = @floatFromInt(curr_y);
                return Vec2f{ .x = x, .y = y };
            }
        }
        const v1 = Vec2f{ .x = @floatFromInt(curr_x), .y = @floatFromInt(curr_y) };
        const v2 = Vec2f{ .x = @floatFromInt(next_x), .y = @floatFromInt(next_y) };
        return v1.lerp(v2, speed);
    }
    pub fn getCurrentPosition(idx: usize) Vec2f {
        return Vec2f{ .x = @as(f32, @floatFromInt(enemies[idx].x)), .y = @as(f32, @floatFromInt(enemies[idx].y)) };
    }
    pub fn update() void {
        for (enemies[0..count]) |*e| {
            if (e.*.enemy_type == EnemyType.NONE) {
                continue;
            }
            const speed = getCurrentSpeed(e.*.enemy_type);
            const transition = (gameTime.getTime() - e.*.start_moving_time) * speed;
            if (transition >= 1.0) {
                e.*.start_moving_time = gameTime.getTime();
                e.*.x = e.*.next_x;
                e.*.y = e.*.next_y;
                if (getNextPosition(e.*.x, e.*.y, &e.next_x, &e.next_y)) {
                    e.*.enemy_type = EnemyType.NONE;
                    continue;
                }
            }
        }
    }
    pub fn getClosetIdxToCastle(x: i32, y: i32, range: f32) ?usize {
        const castle_x: i32 = 0;
        const castle_y: i32 = 0;
        var closest_distance: i32 = 0;
        var closest: ?usize = null;
        const range2: f32 = range * range;
        for (enemies[0..count], 0..count) |e, i| {
            if (e.enemy_type == EnemyType.NONE) {
                continue;
            }
            const max_health = getMaxHealth(e.enemy_type);
            if (e.feture_damage >= max_health) {
                continue;
            }
            const dx: i32 = castle_x - e.x;
            const dy: i32 = castle_y - e.y;
            const distance: i32 = @as(i32, @intCast(@abs(dx) + @abs(dy)));
            if (closest == null or distance < closest_distance) {
                const tdx: f32 = @floatFromInt(x - e.x);
                const tdy: f32 = @floatFromInt(y - e.y);
                if (tdx * tdx + tdy * tdy <= range2) {
                    closest = i;
                    closest_distance = distance;
                }
            }
        }
        return closest;
    }
};
