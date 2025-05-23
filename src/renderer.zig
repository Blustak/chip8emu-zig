const rl = @cImport({
    @cInclude("raylib.h");
});
const std = @import("std");
const assert = std.debug.assert;

const PIXEL_WIDTH = 64;
const PIXEL_HEIGHT = 32;
const PIXEL_SCALE = 20;
const SCREEN_WIDTH = PIXEL_WIDTH * PIXEL_SCALE;
const SCREEN_HEIGHT = PIXEL_HEIGHT * PIXEL_SCALE;

const BACKGROUND_COLOUR = rl.BLACK;
const FOREGROUND_COLOR = rl.GREEN;

var vram: [PIXEL_HEIGHT][PIXEL_WIDTH]bool = .{.{false} ** PIXEL_WIDTH} ** PIXEL_HEIGHT;
pub const Sprite = struct {
    data: []const [8]bool,
};
// Convert a u8 to an array of bools.
pub fn u8_to_data(data: u8) [8]bool {
    var out: [8]bool = .{false} ** 8;
    inline for (0..8) |i| {
        out[i] = (((data >> i) % 2) == 0);
    }
}

pub fn init() void {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Chip 8 emulator");
    rl.SetTargetFPS(60);
}

pub fn deinit() void {
    rl.CloseWindow();
}

pub fn draw() void {
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(BACKGROUND_COLOUR);

        @setEvalBranchQuota((SCREEN_HEIGHT * SCREEN_WIDTH) + 1);
        inline for (vram, 0..) |row, y| {
            inline for (row, 0..) |px, x| {
                rl.DrawRectangle(
                    x * PIXEL_SCALE,
                    y * PIXEL_SCALE,
                    (x + 1) * PIXEL_SCALE,
                    (y + 1) * PIXEL_SCALE,
                    if (px) FOREGROUND_COLOR else BACKGROUND_COLOUR,
                );
            }
        }
    }
}

pub fn write_sprite(sprite: *const Sprite, x: usize, y: usize) void {
    assert(x < PIXEL_WIDTH);
    assert(y < PIXEL_HEIGHT);
    const sprite_width = if (PIXEL_WIDTH - x > 8) 8 else PIXEL_WIDTH - x;
    const sprite_height = if (PIXEL_HEIGHT - y > sprite.data.len) sprite.data.len else PIXEL_HEIGHT - y;
    for (0..sprite_height) |i| {
        const vram_slice = vram[y + i][x..(x + sprite_width)];
        for (vram_slice, 0..) |*b, j| {
            const sprite_px = sprite.*.data[i][j];
            b.* = if (b.* and sprite_px) false else b.* or sprite_px;
        }
    }
}
