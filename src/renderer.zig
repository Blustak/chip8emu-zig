//! This module handles drawing to the screen
const config = @import("config");
const std = @import("std");
const assert = std.debug.assert;
const rl = @cImport({
    @cInclude("raylib.h");
});

// const vbuf = [_]u64{0} ** 32;
const PIXEL_SCALE = config.pixel_scale;
const BG_COLOR = rl.DARKGRAY;
const FG_COLOR = rl.GREEN;
const WIDTH = 64;
const HEIGHT = 32;

const WIN_WIDTH = WIDTH * PIXEL_SCALE;
const WIN_HEIGHT = HEIGHT * PIXEL_SCALE;

/// A sprite is a group of bytes which are a binary representation of the
/// desired picture. Sprites may be up to 15 bytes.
pub const Sprite = struct {
    mem: []const [8]bool,
    /// assertion optimizations and checking
    pub fn new(mem: []const [8]bool) Sprite {
        assert(mem.len < 16);
        return Sprite{ .mem = mem };
    }
};
/// Video buffer - what the renderer reads to draw to the screen.
pub const Vbuf = struct {
    mem: [][]bool,
    len: usize,
    pub fn new(buf: [][]bool) Vbuf {
        assert(buf.len == HEIGHT);
        return Vbuf{ .mem = buf, .len = buf.len };
    }
    pub fn clear(self: *Vbuf) void {
        for (self.mem) |*row| {
            @memset(row.*, false);
        }
    }
};

pub fn openWindow(vram: *Vbuf) void {
    init();
    defer deinit();
    while (!rl.WindowShouldClose()) {
        draw(vram);
    }
}

fn draw(vram: *Vbuf) void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(BG_COLOR);
    for (vram.mem, 0..) |row, i| {
        for (row, 0..) |px, j| {
            if (px) {
                rl.DrawRectangle(
                    PIXEL_SCALE * j,
                    PIXEL_SCALE * i,
                    PIXEL_SCALE,
                    PIXEL_SCALE,
                    FG_COLOR,
                );
            }
        }
    }
}

fn init() void {
    rl.InitWindow(WIN_WIDTH, WIN_HEIGHT, "Chip-8 emu-rl");
    rl.SetTargetFPS(60);
}

fn deinit() void {
    rl.CloseWindow();
}

pub fn draw_sprite(vbuf: *Vbuf, sprite: *const Sprite, x: usize, y: usize) void {
    assert(x < WIDTH);
    assert(y < HEIGHT);
    const sprite_width: usize = if (WIDTH - x < 8) WIDTH - x else 8;
    const sprite_height: usize = if (HEIGHT - y < sprite.mem.len) HEIGHT - y else sprite.mem.len;
}

test "clear test" {
    const expect = std.testing.expect;
    var buf: [HEIGHT][]bool = undefined;
    inline for (0..HEIGHT) |i| {
        var row = [_]bool{false} ** WIDTH;
        buf[i] = &row;
    }
    var vbuf = Vbuf.new(&buf);
    vbuf.clear();
    for (vbuf.mem) |row| {
        for (row) |b| {
            try expect(!b);
        }
    }
    for (vbuf.mem) |*row| {
        @memset(row.*, true);
    }
    vbuf.clear();
    for (vbuf.mem) |row| {
        for (row) |b| {
            try expect(!b);
        }
    }
    for (buf) |row| {
        for (row) |b| {
            try expect(!b);
        }
    }
}

test "draw_sprite test" {
    const expectEqualSlices = std.testing.expectEqualSlices;
    var buf: [HEIGHT][]bool = undefined;
    inline for (0..HEIGHT) |i| {
        var row = [_]bool{false} ** WIDTH;
        buf[i] = &row;
    }
    var vbuf = Vbuf.new(&buf);
    const sprite_empty_data = [_]bool{false} ** 8;
    const tiny_sprite_data = [2][8]bool{
        .{ true, true, true, true, false, false, false, false },
        .{false} ** 8,
    };
    const big_sprite_data = [_][8]bool{[_]bool{true} ** 8} ** 4;
    const empty_sprite = Sprite.new(&.{sprite_empty_data});
    const tiny_sprite = Sprite.new(&tiny_sprite_data);
    const big_sprite = Sprite.new(&big_sprite_data);

    draw_sprite(&vbuf, &empty_sprite, 5, 5);
    try expectEqualSlices([]bool, &tiny_sprite_data, vbuf.mem[5][5..13]);
    vbuf.clear();

    draw_sprite(&vbuf, &tiny_sprite, 1, 0);
    inline for (tiny_sprite_data, 0..) |sprite_row, i| {
        try expectEqualSlices([]bool, &sprite_row, vbuf.mem[i][1..9]);
    }
    draw_sprite(&vbuf, &tiny_sprite, 1, 0);
    inline for (tiny_sprite_data, 0..) |sprite_row, i| {
        try expectEqualSlices([]bool, &sprite_row, vbuf.mem[i][1..9]);
    }
    vbuf.clear();
    draw_sprite(&vbuf, &big_sprite, 0, 0);
    inline for (big_sprite_data, 0..) |sprite_row, i| {
        try expectEqualSlices([]bool, &sprite_row, vbuf.mem[i][0..8]);
    }
}
