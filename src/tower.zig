const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;

const gameTime = @import("gametime.zig").GameTime;
const enemy = @import("enemy.zig").Enemy;
const enemies = @import("enemy.zig").Enemys;
const eType = @import("enemy.zig").EnemyType;
const projectiles = @import("projectiles.zig").Projectiles;
const projectileType = @import("projectiles.zig").PROJECTILE_TYPE;

pub const TOWER_MAX_COUNT = 400;

pub const TowerType = enum(u8) {
    TOWER_TYPE_NONE,
    TOWER_TYPE_BASE,
    TOWER_TYPE_GUN,
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
            t.*.towerType = TowerType.TOWER_TYPE_NONE;
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
                TowerType.TOWER_TYPE_BASE => rl.DrawCube(rl.Vector3{ .x = x, .y = 0.4, .z = z }, 0.8, 0.8, 0.8, rl.MAROON),
                TowerType.TOWER_TYPE_GUN => rl.DrawCube(rl.Vector3{ .x = x, .y = 0.2, .z = z }, 0.8, 0.4, 0.8, rl.DARKPURPLE),
                else => {},
            }
        }
    }
    pub fn gunUpdate(t: *Tower) void {
        if (t.*.coolDown <= 0.0) {
            const eIndex: ?usize = enemies.getClosetIdxToCastle(t.*.x, t.*.y, 3.0);
            if (eIndex) |e| {
                t.*.coolDown = 0.5;
                const sx: f32 = @floatFromInt(t.*.x);
                const sy: f32 = @floatFromInt(t.*.y);
                projectiles.add(projectileType.BULLET, e, rl.Vector2{ .x = sx, .y = sy }, enemies.getCurrentPosition(e), 5.0, 1.0);
            }
        } else {
            t.*.coolDown -= gameTime.getDeltaTime();
        }
    }
    pub fn update() void {
        for (0..count) |i| {
            const tower = towers[i];
            switch (tower.towerType) {
                TowerType.TOWER_TYPE_GUN => gunUpdate(@constCast(&tower)),
                else => {},
            }
        }
    }
};
