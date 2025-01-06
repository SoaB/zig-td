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

const Vec2f = @import("Vector2.zig").Vec2f;

const gameTime = @import("GameTime.zig");

const PROJECTILE_MAX_COUNT = 1200;

pub const ProjectileType = enum(u8) {
    NONE,
    BULLET,
};

pub const Projectile = struct {
    shoot: f32,
    arrival_time: f32,
    damage: f32,
    position: Vec2f,
    target: Vec2f,
    direction_normal: Vec2f,
    target_enemy: enemyIdentity,
    projectile_type: ProjectileType,
};

pub const Projectiles = struct {
    var projectiles: [PROJECTILE_MAX_COUNT]Projectile = undefined;
    var count: u32 = 0;
    pub fn init() void {
        for (&projectiles) |*p| {
            p.* = .{
                .projectile_type = ProjectileType.NONE,
                .shoot = 0,
                .arrival_time = 0,
                .damage = 0,
                .position = Vec2f{ .x = 0, .y = 0 },
                .target = Vec2f{ .x = 0, .y = 0 },
                .direction_normal = Vec2f{ .x = 0, .y = 0 },
                .target_enemy = .{ .index = 0, .generation = 0 },
            };
        }
        count = 0;
    }
    pub fn add(pType: ProjectileType, emyId: usize, pos: Vec2f, target: Vec2f, speed: f32, damage: f32) void {
        for (0..PROJECTILE_MAX_COUNT) |i| {
            const p = &projectiles[i];
            if (p.*.projectile_type == pType and p.*.target_enemy.index == emyId) {
                return;
            }
            if (p.*.projectile_type == ProjectileType.NONE) {
                p.*.projectile_type = pType;
                p.*.shoot = gameTime.getTime();
                p.*.arrival_time = gameTime.getTime() + pos.distance(target) / speed;
                p.*.damage = damage;
                p.*.position = pos;
                p.*.target = target;
                p.*.direction_normal = Vec2f.normal(target.sub(pos));
                p.*.target_enemy = enemyId.getId(emyId);
                if (count <= i) {
                    count = @as(u32, @intCast(i)) + 1;
                }
                return;
            }
        }
    }
    pub fn update() void {
        for (0..count) |i| {
            const p = &projectiles[i];
            if (p.*.projectile_type == ProjectileType.NONE) {
                continue;
            }
            const transition: f32 = (gameTime.getTime() - p.*.shoot) / (p.*.arrival_time - p.*.shoot);
            if (transition >= 1.0) {
                p.*.projectile_type = ProjectileType.NONE;
                const eid = enemyId.tryResolve(p.*.target_enemy);
                if (eid) |e| {
                    enemys.addDamage(e, p.*.damage);
                }
                continue;
            }
        }
    }
    pub fn draw() void {
        for (0..count) |i| {
            const p = &projectiles[i];
            if (p.*.projectile_type == ProjectileType.NONE) {
                continue;
            }
            const transition: f32 = (gameTime.getTime() - p.*.shoot) / (p.*.arrival_time - p.*.shoot);
            if (transition >= 1.0) {
                continue;
            }
            const position: Vec2f = Vec2f.lerp(p.*.position, p.*.target, transition);
            var x: f32 = position.x;
            var y: f32 = position.y;
            const dx = p.*.direction_normal.x;
            const dy = p.*.direction_normal.y;
            var d: f32 = 1.0;
            while (d > 0.0) {
                x -= dx * 0.1;
                y -= dy * 0.1;
                const size = 0.1 * d;
                d -= 0.25;
                rl.DrawCube(rl.Vector3{ .x = x, .y = 0.2, .z = y }, size, size, size, rl.RED);
            }
        }
    }
};
