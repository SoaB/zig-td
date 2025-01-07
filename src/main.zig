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

var nextSpwnTime: f32 = 0.0;

pub fn initGame() void {
    gameTime.update(0.0);
    towers.init();
    enemys.init();
    projectiles.init();
    towers.add(0, 0, towerType.BASE);
    towers.add(2, 0, towerType.GUN);
    towers.add(-2, 0, towerType.GUN);
    enemys.add(4, 4, enemyType.MIMION);
}

pub fn updateGame() void {
    const dt = rl.GetFrameTime();
    gameTime.update(dt);
    enemys.update();
    towers.update();
    projectiles.update();
    //spwn enemies
    if (gameTime.getTime() > nextSpwnTime and enemys.getCount() < 50) {
        nextSpwnTime = gameTime.getTime() + 0.25;
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
    //    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //    const allocator = gpa.allocator();
    rl.InitWindow(gd.scrWidth, gd.scrHeight, "Tower Defense");
    rl.SetTargetFPS(60);
    var camera: rl.Camera3D = rl.Camera3D{};
    camera.position = rl.Vector3{ .x = 0.0, .y = 10.0, .z = -0.5 };
    camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = -0.5 };
    camera.up = rl.Vector3{ .x = 0.0, .y = 0.0, .z = -1.0 };
    camera.fovy = 12.0;
    camera.projection = rl.CAMERA_ORTHOGRAPHIC;
    initGame();
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.DARKBLUE);
        rl.BeginMode3D(camera);
        rl.DrawGrid(10, 1.0);
        towers.draw();
        enemys.draw();
        projectiles.draw();
        updateGame();
        rl.EndMode3D();
        const str = "Tower Defense";
        const textWidth: i32 = rl.MeasureText(str.ptr, 20);
        rl.DrawText(str.ptr, @divExact((gd.scrWidth - textWidth), 2) + 2, 5 + 2, 20, rl.BLACK);
        rl.DrawText(str.ptr, @divExact((gd.scrWidth - textWidth), 2), 5, 20, rl.WHITE);
        rl.EndDrawing();
    }
    rl.CloseWindow();
    //    _ = gpa.deinit();
}
