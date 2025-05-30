const rl = @import("raylib").rl;
const std = @import("std");
const assert = std.debug.assert;

const PIXEL_WIDTH:i32 = 64;
const PIXEL_HEIGHT:i32 = 32;
const PIXEL_SCALE:i32 = 20;
const SCREEN_WIDTH:i32 = PIXEL_WIDTH * PIXEL_SCALE;
const SCREEN_HEIGHT:i32 = PIXEL_HEIGHT * PIXEL_SCALE;

const BACKGROUND_COLOUR = rl.BLACK;
const FOREGROUND_COLOR = rl.GREEN;

pub const DrawEvent = struct {
    sprite:*const Sprite,
    x:usize,
    y:usize,

    pub fn write(self:*const DrawEvent, write_buf:*[PIXEL_HEIGHT][PIXEL_WIDTH]bool) void {
        const x = self.x;
        const y = self.y;
        assert(x < PIXEL_WIDTH);
        assert(y < PIXEL_HEIGHT);
        const sprite_width = if (PIXEL_WIDTH - self.x > 8) 8 else PIXEL_WIDTH - x;
        const sprite_height = if (PIXEL_HEIGHT - self.y > self.sprite.data.len) self.sprite.data.len else PIXEL_HEIGHT - y;
        for (0..sprite_height) |i| {
            const vram_slice = write_buf[y + i][x..(x + sprite_width)];
            for (vram_slice, 0..) |*b, j| {
                const sprite_px = self.sprite.*.data[i][j];
                b.* = if (b.* and sprite_px) false else b.* or sprite_px;
            }
        }
        std.log.info("Wrote sprite {*} at {}, {}. Contents:{any}", .{self, x, y, self.sprite.data});
    }
};
var buf:[@sizeOf(*const DrawEvent)*256]u8 = undefined;
var gpa = std.heap.FixedBufferAllocator.init(&buf);
const alloc = gpa.allocator();

var event_stack: std.ArrayList(*const DrawEvent) = undefined;

pub var vram: [PIXEL_HEIGHT][PIXEL_WIDTH]bool = .{.{false} ** PIXEL_WIDTH} ** PIXEL_HEIGHT;
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

pub fn init() !void {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Chip 8 emulator");
    event_stack = std.ArrayList(*const DrawEvent).init(alloc);
    rl.SetTargetFPS(60);
}

pub fn deinit() void {
    event_stack.deinit();
    rl.CloseWindow();
}

pub fn draw() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(BACKGROUND_COLOUR);
    while (event_stack.pop()) |ev| {
        ev.write(&vram);
    }

    for (vram, 0..) |row, y| {
        for (row, 0..) |px, x| {
            rl.DrawRectangle(
                @as(i32, @intCast(x)) * PIXEL_SCALE,
                @as(i32, @intCast(y)) * PIXEL_SCALE,
                @as(i32, @intCast(x + 1)) * PIXEL_SCALE,
                @as(i32, @intCast(y + 1)) * PIXEL_SCALE,
                if (px) FOREGROUND_COLOR else BACKGROUND_COLOUR,
            );
        }
    }
}

pub fn add_draw_event(event:union(enum){ptr:*const DrawEvent, slice:[]const *const DrawEvent}) !void {
    switch (event) {
        .ptr => |pt| {try event_stack.append(pt);},
        .slice => |sl| {try event_stack.appendSlice(sl);},
    }
}
