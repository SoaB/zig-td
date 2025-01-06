const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;
const vec = @import("vec.zig");
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
        if (Enemys.enemies[id.index].generation != id.generation or Enemys.enemies[id.index].enemyType == EnemyType.NONE) {
            return null;
        }
        return id.index;
    }
};
pub const Enemy = struct {
    x: i32,
    y: i32,
    nextX: i32,
    nextY: i32,
    generation: u32,
    startMovingTime: f32,
    damage: f32,
    feture_damage: f32,
    enemyType: EnemyType,
};

pub const Enemys = struct {
    var count: u32 = 0;
    var enemies: [ENEMY_MAX_COUNT]Enemy = undefined;
    pub fn init() void {
        for (&enemies) |*e| {
            e.* = Enemy{
                .x = 0,
                .y = 0,
                .nextX = 0,
                .nextY = 0,
                .generation = 0,
                .startMovingTime = gameTime.getTime(),
                .damage = 0,
                .feture_damage = 0,
                .enemyType = EnemyType.NONE,
            };
        }
        count = 0;
    }
    pub fn add(x: i32, y: i32, t: EnemyType) void {
        for (enemies[0..count]) |*e| {
            if (e.*.enemyType == EnemyType.NONE) {
                e.*.x = x;
                e.*.y = y;
                e.*.nextX = x;
                e.*.nextY = y;
                e.*.generation += 1;
                e.*.startMovingTime = gameTime.getTime();
                e.*.damage = 0;
                e.*.feture_damage = 0;
                e.*.enemyType = t;
                return;
            }
        }
        if (count < ENEMY_MAX_COUNT) {
            enemies[count].x = x;
            enemies[count].y = y;
            enemies[count].nextX = x;
            enemies[count].nextY = y;
            enemies[count].generation += 1;
            enemies[count].startMovingTime = gameTime.getTime();
            enemies[count].damage = 0;
            enemies[count].feture_damage = 0;
            enemies[count].enemyType = t;
            count += 1;
        }
    }
    pub fn addDamage(idx: usize, damage: f32) void {
        if (idx < count) {
            enemies[idx].damage += damage;
            if (enemies[idx].damage >= getMaxHealth(enemies[idx].enemyType)) {
                enemies[idx].enemyType = EnemyType.NONE;
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
            enemies[idx].enemyType = EnemyType.NONE;
        }
    }
    pub fn getStartMovingTime(idx: usize) f32 {
        return enemies[idx].startMovingTime;
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
            const posi: rl.Vector2 = getPosition(i, gameTime.getTime() - e.startMovingTime);
            switch (e.enemyType) {
                EnemyType.MIMION => {
                    rl.DrawCube(rl.Vector3{ .x = posi.x, .y = 0.2, .z = posi.y }, 0.4, 0.4, 0.4, rl.GREEN);
                },
                else => {},
            }
        }
    }
    pub fn getNextPosition(cX: i32, cY: i32, nX: *i32, nY: *i32) bool {
        const castleX: i32 = 0;
        const castleY: i32 = 0;
        const dx: i32 = castleX - cX;
        const dy: i32 = castleY - cY;
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
    pub fn getPosition(idx: usize, deltaT: f32) rl.Vector2 {
        var speed = getCurrentSpeed(enemies[idx].enemyType) * deltaT;
        var currentX: i32 = enemies[idx].x;
        var currentY: i32 = enemies[idx].y;
        var nextX: i32 = enemies[idx].nextX;
        var nextY: i32 = enemies[idx].nextY;
        while (speed > 1.0) {
            speed -= 1.0;
            currentX = nextX;
            currentY = nextY;
            if (getNextPosition(currentX, currentY, &nextX, &nextY)) {
                const x: f32 = @floatFromInt(currentX);
                const y: f32 = @floatFromInt(currentY);
                return rl.Vector2{ .x = x, .y = y };
            }
        }
        const v1 = rl.Vector2{ .x = @floatFromInt(currentX), .y = @floatFromInt(currentY) };
        const v2 = rl.Vector2{ .x = @floatFromInt(nextX), .y = @floatFromInt(nextY) };
        return vec.lerp(v1, v2, speed);
    }
    pub fn getCurrentPosition(idx: usize) rl.Vector2 {
        return rl.Vector2{ .x = @as(f32, @floatFromInt(enemies[idx].x)), .y = @as(f32, @floatFromInt(enemies[idx].y)) };
    }
    pub fn update() void {
        for (enemies[0..count]) |*e| {
            if (e.*.enemyType == EnemyType.NONE) {
                continue;
            }
            const speed = getCurrentSpeed(e.*.enemyType);
            const transition = (gameTime.getTime() - e.*.startMovingTime) * speed;
            if (transition >= 1.0) {
                e.*.startMovingTime = gameTime.getTime();
                e.*.x = e.*.nextX;
                e.*.y = e.*.nextY;
                if (getNextPosition(e.*.x, e.*.y, &e.nextX, &e.nextY)) {
                    e.*.enemyType = EnemyType.NONE;
                    continue;
                }
            }
        }
    }
    pub fn getClosetIdxToCastle(x: i32, y: i32, range: f32) ?usize {
        const castleX: i32 = 0;
        const castleY: i32 = 0;
        var closestDistance: i32 = 0;
        var closest: ?usize = null;
        const range2: f32 = range * range;
        for (enemies[0..count], 0..count) |e, i| {
            if (e.enemyType == EnemyType.NONE) {
                continue;
            }
            const max_health = getMaxHealth(e.enemyType);
            if (e.feture_damage >= max_health) {
                continue;
            }
            const dx: i32 = castleX - e.x;
            const dy: i32 = castleY - e.y;
            const distance: i32 = @as(i32, @intCast(@abs(dx) + @abs(dy)));
            if (closest == null or distance < closestDistance) {
                const tdx: f32 = @floatFromInt(x - e.x);
                const tdy: f32 = @floatFromInt(y - e.y);
                if (tdx * tdx + tdy * tdy <= range2) {
                    closest = i;
                    closestDistance = distance;
                }
            }
        }
        return closest;
    }
};
