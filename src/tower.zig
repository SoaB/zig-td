const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;
const vec = @import("vec.zig");
const gameTime = @import("GameTime.zig");
const enemy = @import("enemy.zig").Enemy;
const enemies = @import("enemy.zig").Enemys;
const eType = @import("enemy.zig").EnemyType;
const projectiles = @import("projectiles.zig").Projectiles;
const projectileType = @import("projectiles.zig").ProjectileType;

pub const TOWER_MAX_COUNT = 400;

pub const TowerType = enum(u8) {
    NONE,
    BASE,
    GUN,
};

pub const Tower = struct {
    x: i32,
    y: i32,
    towerType: TowerType,
    coolDown: f32,
};

pub const Towers = struct {
    var towers: [TOWER_MAX_COUNT]Tower = undefined;
    var count: u32 = 0;

    pub fn init() void {
        for (&towers) |*t| {
            t.*.x = 0.0;
            t.*.y = 0.0;
            t.*.towerType = TowerType.NONE;
        }
        count = 0;
    }
    pub fn alreadyAt(x: i32, y: i32) bool {
        for (0..count) |i| {
            if (towers[i].x == x and towers[i].y == y) {
                return true;
            }
        }
        return false;
    }
    pub fn add(x: i32, y: i32, towerType: TowerType) void {
        if (count >= TOWER_MAX_COUNT) {
            return;
        }
        if (alreadyAt(x, y)) {
            return;
        }
        towers[count].x = x;
        towers[count].y = y;
        towers[count].towerType = towerType;
        count += 1;
    }
    pub fn draw() void {
        for (0..count) |i| {
            const tower = towers[i];
            const x: f32 = @floatFromInt(tower.x);
            const z: f32 = @floatFromInt(tower.y);
            rl.DrawCube(rl.Vector3{ .x = x, .y = 0.125, .z = z }, 1.0, 0.25, 1.0, rl.GRAY);
            switch (tower.towerType) {
                TowerType.BASE => rl.DrawCube(rl.Vector3{ .x = x, .y = 0.4, .z = z }, 0.8, 0.8, 0.8, rl.MAROON),
                TowerType.GUN => rl.DrawCube(rl.Vector3{ .x = x, .y = 0.2, .z = z }, 0.8, 0.4, 0.8, rl.DARKPURPLE),
                else => {},
            }
        }
    }
    pub fn getPosition(t: Tower) rl.Vector2 {
        const x: f32 = @floatFromInt(t.x);
        const z: f32 = @floatFromInt(t.y);
        return rl.Vector2{ .x = x, .y = z };
    }
    fn fabs(x: f32) f32 {
        if (x < 0.0) {
            return -x;
        }
        return x;
    }
    pub fn gunUpdate(t: *Tower) void {
        if (t.*.coolDown <= 0.0) {
            const eIndex: ?usize = enemies.getClosetIdxToCastle(t.*.x, t.*.y, 3.0);
            if (eIndex) |e| {
                t.*.coolDown = 0.5;
                const bullet_speed: f32 = 2.0;
                const bullet_damage: f32 = 3.0;
                const delta_time: f32 = gameTime.getTime() - enemies.getStartMovingTime(e);
                var future_pos: rl.Vector2 = enemies.getPosition(e, delta_time);
                const tower_pos: rl.Vector2 = rl.Vector2{ .x = @as(f32, @floatFromInt(t.*.x)), .y = @as(f32, @floatFromInt(t.*.y)) };
                var time_to_hit1: f32 = vec.distance(tower_pos, future_pos) / bullet_speed;
                var got_it: bool = false;
                while (!got_it) {
                    future_pos = enemies.getPosition(e, delta_time + time_to_hit1);
                    const distance: f32 = vec.distance(tower_pos, future_pos);
                    const time_to_hit2: f32 = distance / bullet_speed;
                    if (@abs(time_to_hit2 - time_to_hit1) < 0.01) {
                        got_it = true;
                    }
                    time_to_hit1 = (time_to_hit1 + time_to_hit2) * 0.5;
                }
                projectiles.add(projectileType.BULLET, e, tower_pos, future_pos, bullet_speed, bullet_damage);
                enemies.addfetureDamage(e, bullet_damage);
            }
        } else {
            t.*.coolDown -= gameTime.getDeltaTime();
        }
    }
    pub fn update() void {
        for (0..count) |i| {
            const tower = towers[i];
            switch (tower.towerType) {
                TowerType.GUN => gunUpdate(@constCast(&tower)),
                else => {},
            }
        }
    }
};
