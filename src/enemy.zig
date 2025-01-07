const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});
const std = @import("std");
const math = std.math;
const print = std.debug.print;
const Vec2f = @import("Vector2.zig").Vec2f;
const gameTime = @import("GameTime.zig");
const ENEMY_MAX_PATH_COUNT = 8;
pub const ENEMY_MAX_COUNT = 400;
pub const EnemyType = enum(u8) {
    NONE,
    MIMION,
    _,
};
pub const EnemyConfig = struct {
    speed: f32 = 0,
    health: f32 = 0,
    radius: f32 = 0,
    max_acceleartion: f32 = 0,
};
pub const EnemyConfigs = [_]EnemyConfig{
    .{}, // NONE
    .{ // MIMION
        .speed = 1.0,
        .health = 3.0,
        .radius = 0.25,
        .max_acceleartion = 1.0,
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
    sim_position: Vec2f,
    sim_velocity: Vec2f,
    generation: u32,
    start_moving_time: f32,
    damage: f32,
    feture_damage: f32,
    move_path_count: u32,
    move_path: [ENEMY_MAX_PATH_COUNT]Vec2f,
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
                .sim_position = Vec2f{ .x = 0, .y = 0 },
                .sim_velocity = Vec2f{ .x = 0, .y = 0 },
                .generation = 0,
                .start_moving_time = gameTime.getTime(),
                .damage = 0,
                .feture_damage = 0,
                .move_path_count = 0,
                .move_path = [_]Vec2f{Vec2f{ .x = 0, .y = 0 }} ** ENEMY_MAX_PATH_COUNT,
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
                e.*.sim_position = Vec2f{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
                e.*.sim_velocity = Vec2f{ .x = 0, .y = 0 };
                e.*.generation += 1;
                e.*.start_moving_time = gameTime.getTime();
                e.*.damage = 0;
                e.*.feture_damage = 0;
                e.*.move_path_count = 0;
                e.*.enemy_type = t;
                return;
            }
        }
        if (count < ENEMY_MAX_COUNT) {
            enemies[count].x = x;
            enemies[count].y = y;
            enemies[count].next_x = x;
            enemies[count].next_y = y;
            enemies[count].sim_position = Vec2f{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
            enemies[count].sim_velocity = Vec2f{ .x = 0, .y = 0 };
            enemies[count].generation += 1;
            enemies[count].start_moving_time = gameTime.getTime();
            enemies[count].damage = 0;
            enemies[count].feture_damage = 0;
            enemies[count].move_path_count = 0;
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
    pub fn getSimVelocity(idx: usize) Vec2f {
        return enemies[idx].sim_velocity;
    }
    pub fn getCurrentSpeed(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].speed;
    }
    pub fn getCurrentMaxSpeed(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].speed;
    }
    pub fn getMaxAcceleration(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].max_acceleartion;
    }
    pub fn getMaxHealth(e: EnemyType) f32 {
        const idx: usize = @intFromEnum(e);
        return EnemyConfigs[idx].health;
    }
    pub fn getCount() u32 {
        var cnt: u32 = 0;
        for (enemies[0..ENEMY_MAX_COUNT]) |e| {
            if (e.enemy_type != EnemyType.NONE) {
                cnt += 1;
            }
        }
        return cnt;
    }
    pub fn draw() void {
        for (enemies[0..count], 0..count) |e, i| {
            var gg: u32 = 0;
            const posi: Vec2f = getPosition(i, gameTime.getTime() - e.start_moving_time, @constCast(&e.sim_velocity), &gg);
            if (e.move_path_count > 0) {
                const p: rl.Vector3 = rl.Vector3{ .x = e.move_path[0].x, .y = 0.2, .z = e.move_path[0].y };
                rl.DrawLine3D(p, rl.Vector3{ .x = posi.x, .y = 0.2, .z = posi.y }, rl.GREEN);
            }
            if (e.move_path_count > 1) {
                for (1..e.move_path_count - 1) |j| {
                    const p1: rl.Vector3 = rl.Vector3{ .x = e.move_path[j - 1].x, .y = 0.2, .z = e.move_path[j - 1].y };
                    const p2: rl.Vector3 = rl.Vector3{ .x = e.move_path[j].x, .y = 0.2, .z = e.move_path[j].y };
                    rl.DrawLine3D(p1, p2, rl.GREEN);
                }
            }
            switch (e.enemy_type) {
                EnemyType.MIMION => {
                    rl.DrawCubeWires(rl.Vector3{ .x = posi.x, .y = 0.2, .z = posi.y }, 0.4, 0.4, 0.4, rl.GREEN);
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
    pub fn getPosition(idx: usize, deltaT: f32, velocity: *Vec2f, way_point_passed_count: *u32) Vec2f {
        const point_reach_distance = 0.25;
        const point_reach_distance2 = point_reach_distance * point_reach_distance;
        const max_sim_step_time = 0.015625;
        const max_acceleartion = getMaxAcceleration(enemies[idx].enemy_type);
        const max_speed = getCurrentMaxSpeed(enemies[idx].enemy_type);
        var next_x: i32 = enemies[idx].next_x;
        var next_y: i32 = enemies[idx].next_y;
        var position: Vec2f = enemies[idx].sim_position;
        var pass_counter: u32 = 0;
        var t: f32 = 0.0;
        while (t < deltaT) : (t += max_sim_step_time) {
            const step_time: f32 = @min(deltaT - t, max_sim_step_time);
            var target: Vec2f = Vec2f{ .x = @floatFromInt(next_x), .y = @floatFromInt(next_y) };
            const speed: f32 = Vec2f.len(velocity.*);
            // draw the target position for debug
            rl.DrawCubeWires(rl.Vector3{ .x = target.x, .y = 0.2, .z = target.y }, 0.1, 0.4, 0.1, rl.RED);
            const look_forward_position: Vec2f = Vec2f.add(position, Vec2f.scale(velocity.*, speed));
            if (Vec2f.distanceSquared(position, target) <= point_reach_distance2) {
                // we reach the target position,let's move to the next way point
                _ = getNextPosition(next_x, next_y, &next_x, &next_y);
                target = Vec2f{ .x = @floatFromInt(next_x), .y = @floatFromInt(next_y) };
                // track the way point passed count
                pass_counter += 1;
            }
            // acceleration toward the target
            const unit_direction: Vec2f = Vec2f.normalize(Vec2f.sub(target, look_forward_position));
            const acceleration: Vec2f = Vec2f.scale(unit_direction, max_acceleartion * step_time);
            velocity.* = Vec2f.add(velocity.*, acceleration);
            // limit the speed
            if (speed > max_speed) {
                velocity.* = Vec2f.scale(velocity.*, max_speed / speed);
            }
            // move the position
            position = Vec2f.add(position, Vec2f.scale(velocity.*, step_time));
        }
        if (way_point_passed_count.* == 0) {
            way_point_passed_count.* = pass_counter;
        }
        return position;
    }
    pub fn getCurrentPosition(idx: usize) Vec2f {
        return Vec2f{ .x = @as(f32, @floatFromInt(enemies[idx].x)), .y = @as(f32, @floatFromInt(enemies[idx].y)) };
    }
    pub fn handleCollision() void {
        for (enemies[0..count], 0..count) |*e, i| {
            if (e.*.enemy_type == EnemyType.NONE) {
                continue;
            }
            for (enemies[i + 1 .. count]) |*e2| {
                if (e2.*.enemy_type == EnemyType.NONE) {
                    continue;
                }
                const distance_squared: f32 = Vec2f.distanceSquared(e.*.sim_position, e2.*.sim_position);
                const radius1: f32 = EnemyConfigs[@intFromEnum(e.*.enemy_type)].radius;
                const radius2: f32 = EnemyConfigs[@intFromEnum(e2.*.enemy_type)].radius;
                const radius_sum: f32 = radius1 + radius2;
                if (distance_squared <= radius_sum * radius_sum and distance_squared > 0.001) {
                    // collision detected, let's do something
                    const distance: f32 = @sqrt(distance_squared);
                    const overlap: f32 = radius_sum - distance;
                    // move the objects apart
                    // TODO: use a more realistic collision response
                    const position_correction: f32 = overlap / 5.0;
                    const direction: Vec2f = Vec2f{
                        .x = (e2.*.sim_position.x - e.*.sim_position.x) / distance * position_correction,
                        .y = (e2.*.sim_position.y - e.*.sim_position.y) / distance * position_correction,
                    };
                    e.*.sim_position = Vec2f.sub(e.*.sim_position, direction);
                    e2.*.sim_position = Vec2f.add(e2.*.sim_position, direction);
                }
            }
        }
    }
    pub fn update() void {
        const castle_x: f32 = 0;
        const castle_y: f32 = 0;
        const max_path_distance2: f32 = 0.25 * 0.25;
        for (enemies[0..count], 0..count) |*e, i| {
            if (e.*.enemy_type == EnemyType.NONE) {
                continue;
            }
            var way_point_passed_count: u32 = 0;
            e.*.sim_position = getPosition(i, gameTime.getTime() - e.*.start_moving_time, &e.sim_velocity, &way_point_passed_count);
            e.*.start_moving_time = gameTime.getTime();
            if (e.*.move_path_count == 0 or Vec2f.distanceSquared(e.*.sim_position, e.*.move_path[0]) > max_path_distance2) {
                var j: u32 = ENEMY_MAX_PATH_COUNT - 1;
                while (j > 0) : (j -= 1) {
                    e.*.move_path[j] = e.*.move_path[j - 1];
                }
                e.*.move_path[0] = e.*.sim_position;
                e.*.move_path_count += 1;
                if (e.*.move_path_count > ENEMY_MAX_PATH_COUNT) {
                    e.*.move_path_count = ENEMY_MAX_PATH_COUNT;
                }
            }
            if (way_point_passed_count > 0) {
                e.*.x = e.*.next_x;
                e.*.y = e.*.next_y;
                if (getNextPosition(e.*.x, e.*.y, &e.next_x, &e.next_y) and
                    Vec2f.distanceSquared(e.*.sim_position, Vec2f{ .x = castle_x, .y = castle_y }) > max_path_distance2)
                {
                    e.*.enemy_type = EnemyType.NONE;
                    continue;
                }
            }
        }
        handleCollision();
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
