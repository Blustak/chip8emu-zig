const raylib = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    // Window steps
    raylib.InitWindow(800, 450, "Raylib basic window");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    // Drawing loop
    while (!raylib.WindowShouldClose()) {
        // Drawing steps
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        // What to draw
        raylib.ClearBackground(raylib.RAYWHITE);
        raylib.DrawText("Raylib from zig!", 190, 200, 20, raylib.LIGHTGRAY);
    }
}
