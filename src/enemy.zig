const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;

const gameTime = @import("gameTime.zig").GameTime;
pub const ENEMY_MAX_COUNT = 400;
pub const EnemyType = enum(u8) { NONE, MIMION };

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
                .startMovingTime = 0,
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
                e.*.startMovingTime = 0;
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
            enemies[count].startMovingTime = 0;
            enemies[count].enemyType = t;
            count += 1;
        }
    }
    pub fn remove(idx: usize) void {
        if (idx < count) {
            enemies[idx].enemyType = EnemyType.NONE;
        }
    }
    pub fn getCurrentPosition(idx: usize) rl.Vector2 {
        return rl.Vector2{ .x = @as(f32, @floatFromInt(enemies[idx].x)), .y = @as(f32, @floatFromInt(enemies[idx].y)) };
    }
    pub fn getCurrentSpeed(e: EnemyType) f32 {
        switch (e) {
            EnemyType.MIMION => return 1.0,
            else => return 1.0,
        }
    }
    pub fn draw() void {
        for (enemies[0..count]) |e| {
            const speed = getCurrentSpeed(e.enemyType);
            const transition = (gameTime.getTime() - e.startMovingTime) * speed;
            const dx: i32 = e.nextX - e.x;
            const dy: i32 = e.nextY - e.y;
            const x: f32 = @as(f32, @floatFromInt(e.x)) + @as(f32, @floatFromInt(dx)) * transition;
            const z: f32 = @as(f32, @floatFromInt(e.y)) + @as(f32, @floatFromInt(dy)) * transition;
            switch (e.enemyType) {
                EnemyType.MIMION => {
                    rl.DrawCube(rl.Vector3{ .x = x, .y = 0.2, .z = z }, 0.4, 0.4, 0.4, rl.GREEN);
                },
                else => {},
            }
        }
    }
    pub fn update() void {
        const castleX: i32 = 0;
        const castleY: i32 = 0;
        for (enemies[0..count]) |*e| {
            if (e.*.enemyType == EnemyType.NONE) {
                continue;
            }
            const speed = 1.0;
            const transition = (gameTime.getTime() - e.*.startMovingTime) * speed;
            if (transition >= 1.0) {
                e.*.startMovingTime = gameTime.getTime();
                e.*.x = e.nextX;
                e.*.y = e.nextY;
                const dx: i32 = castleX - e.*.x;
                const dy: i32 = castleY - e.*.y;
                if (dx == 0 and dy == 0) {
                    e.*.enemyType = EnemyType.NONE;
                    continue;
                }
                if (@abs(dx) > @abs(dy)) {
                    if (dx > 0) {
                        e.*.nextX = e.*.x + 1;
                    } else {
                        e.*.nextX = e.*.x - 1;
                    }
                    e.*.nextY = e.*.y;
                } else {
                    if (dy > 0) {
                        e.*.nextY = e.*.y + 1;
                    } else {
                        e.*.nextY = e.*.y - 1;
                    }
                    e.*.nextX = e.*.x;
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
