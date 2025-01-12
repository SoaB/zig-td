const rl = @cImport({
    @cDefine("SUPPORT_GIF_RECORDING", "1");
    @cInclude("Raylib.h");
});

const std = @import("std");
const math = std.math;
const print = std.debug.print;
const gd = @import("globalData.zig");
///////////////////////////////////////////////////////////////////////////
const towers = @import("tower.zig").Towers;
const towerType = @import("tower.zig").TowerType;
const enemys = @import("enemy.zig").Enemys;
const enemyType = @import("enemy.zig").EnemyType;
const gameTime = @import("GameTime.zig");
const projectiles = @import("projectiles.zig").Projectiles;
const PathFind = @import("PathFind.zig");
const Vec3f = @import("Vector3.zig").Vec3f;

var nextSpwnTime: f32 = 0.0;

pub fn initGame(allocator: std.mem.Allocator) void {
    gameTime.update(0.0);
    towers.init();
    enemys.init();
    projectiles.init();
    PathFind.mapInit(allocator, 20, 20, Vec3f{ .x = -10.0, .y = 0.0, .z = -10.0 }, 1.0);
    towers.add(0, 0, towerType.BASE);
    towers.add(2, 0, towerType.GUN);
    //towers.add(-2, 0, towerType.GUN);
    towers.add(2, 2, towerType.WALL);
    //    var i: i32 = -2;
    //    while (i <= 2) : (i += 1) {
    //        towers.add(i, 2, towerType.WALL);
    //        towers.add(i, -2, towerType.WALL);
    //        towers.add(-2, i, towerType.WALL);
    //        towers.add(2, i, towerType.WALL);
    //    }
    enemys.add(5, 4, enemyType.MIMION);
}

pub fn updateGame() void {
    const dt = rl.GetFrameTime();
    if (dt > 0.1) {
        gameTime.update(0.1);
    } else {
        gameTime.update(dt);
    }
    PathFind.mapUpdate();
    enemys.update();
    towers.update();
    projectiles.update();
    //spwn enemies
    if (gameTime.getTime() > nextSpwnTime and enemys.getCount() < 1) {
        nextSpwnTime = gameTime.getTime() + 0.2;
        const randVal: i32 = rl.GetRandomValue(-5, 5);
        const randSide: i32 = rl.GetRandomValue(0, 3);
        var x: i32 = 0;
        var y: i32 = 0;
        if (randSide == 0) {
            x = -5;
        } else if (randSide == 1) {
            x = 5;
        } else {
            x = randVal;
        }
        if (randSide == 2) {
            y = -5;
        } else if (randSide == 3) {
            y = 5;
        } else {
            y = randVal;
        }
        enemys.add(x, y, enemyType.MIMION);
    }
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    rl.InitWindow(gd.scrWidth, gd.scrHeight, "Tower Defense");
    rl.SetTargetFPS(60);
    var camera: rl.Camera3D = rl.Camera3D{};
    camera.position = rl.Vector3{ .x = 0.0, .y = 10.0, .z = -0.5 };
    camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = -0.5 };
    camera.up = rl.Vector3{ .x = 0.0, .y = 0.0, .z = -1.0 };
    camera.fovy = 12.0;
    camera.projection = rl.CAMERA_ORTHOGRAPHIC;
    initGame(allocator);
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.DARKBLUE);
        rl.BeginMode3D(camera);
        rl.DrawGrid(10, 1.0);
        towers.draw();
        enemys.draw();
        projectiles.draw();
        PathFind.mapDraw();
        updateGame();
        rl.EndMode3D();
        const str = "Tower Defense...";
        const textWidth: i32 = rl.MeasureText(str.ptr, 20);
        rl.DrawText(str.ptr, @divExact((gd.scrWidth - textWidth), 2) + 2, 5 + 2, 20, rl.BLACK);
        rl.DrawText(str.ptr, @divExact((gd.scrWidth - textWidth), 2), 5, 20, rl.WHITE);
        rl.EndDrawing();
    }
    PathFind.mapDeinit();
    rl.CloseWindow();
    const deinit_status = gpa.deinit();
    // 检测是否发生内存泄漏
    if (deinit_status == .leak) @panic("TEST FAIL");
}
