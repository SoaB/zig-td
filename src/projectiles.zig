const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;

const enemy = @import("enemy.zig");
const enemyIdentity = enemy.EnemyIdentity;
const enemyId = enemy.EnemyId;
const enemys = enemy.Enemys;

const vec2 = @import("vec.zig");

const gameTime = @import("gameTime.zig").GameTime;

const PROJECTILE_MAX_COUNT = 1200;

pub const PROJECTILE_TYPE = enum(u8) {
    NONE,
    BULLET,
};

pub const Projectile = struct {
    projectileType: PROJECTILE_TYPE,
    shoot: f32,
    arrivalTime: f32,
    damage: f32,
    position: rl.Vector2,
    target: rl.Vector2,
    directionNormal: rl.Vector2,
    targetEnemy: enemyIdentity,
};

pub const Projectiles = struct {
    var projectiles: [PROJECTILE_MAX_COUNT]Projectile = undefined;
    var count: u32 = 0;
    pub fn init() void {
        for (&projectiles) |*p| {
            p.* = .{
                .projectileType = PROJECTILE_TYPE.NONE,
                .shoot = 0,
                .arrivalTime = 0,
                .damage = 0,
                .position = rl.Vector2{ .x = 0, .y = 0 },
                .target = rl.Vector2{ .x = 0, .y = 0 },
                .directionNormal = rl.Vector2{ .x = 0, .y = 0 },
                .targetEnemy = .{ .index = 0, .generation = 0 },
            };
        }
        count = 0;
    }
    pub fn add(pType: PROJECTILE_TYPE, emyId: usize, pos: rl.Vector2, target: rl.Vector2, speed: f32, damage: f32) void {
        for (0..PROJECTILE_MAX_COUNT) |i| {
            const p = &projectiles[i];
            if (p.*.projectileType == PROJECTILE_TYPE.NONE) {
                p.*.projectileType = pType;
                p.*.shoot = gameTime.getTime();
                p.*.arrivalTime = gameTime.getTime() + vec2.distance(pos, target) / speed;
                p.*.damage = damage;
                p.*.position = pos;
                p.*.target = target;
                p.*.directionNormal = vec2.normalize(vec2.sub(target, pos));
                p.*.targetEnemy = enemyId.getId(emyId);
                if (count <= i) {
                    count = @as(u32, @intCast(i)) + 1;
                }
                return;
            }
        }
    }
    pub fn update() void {
        for (0..PROJECTILE_MAX_COUNT) |i| {
            const p = &projectiles[i];
            if (p.*.projectileType == PROJECTILE_TYPE.NONE) {
                continue;
            }
            const transition: f32 = (gameTime.getTime() - p.*.shoot) / (p.*.arrivalTime - p.*.shoot);
            if (transition >= 1.0) {
                p.*.projectileType = PROJECTILE_TYPE.NONE;
                const eid = enemyId.tryResolve(p.*.targetEnemy);
                if (eid) |e| {
                    enemys.remove(e);
                }
                continue;
            }
        }
    }
    pub fn draw() void {
        for (0..PROJECTILE_MAX_COUNT) |i| {
            const p = &projectiles[i];
            if (p.*.projectileType == PROJECTILE_TYPE.NONE) {
                continue;
            }
            const transition: f32 = (gameTime.getTime() - p.*.shoot) / (p.*.arrivalTime - p.*.shoot);
            if (transition >= 1.0) {
                continue;
            }
            const position: rl.Vector2 = vec2.lerp(p.*.position, p.*.target, transition);
            var x: f32 = position.x;
            var y: f32 = position.y;
            const dx = p.*.directionNormal.x;
            const dy = p.*.directionNormal.y;
            var d: f32 = 1.0;
            while (d > 0.0) : (d -= 0.25) {
                x -= dx * 0.1;
                y -= dy * 0.1;
                const size = 0.1 * d;
                rl.DrawCube(rl.Vector3{ .x = x, .y = 0.2, .z = y }, size, size, size, rl.RED);
            }
        }
    }
};
