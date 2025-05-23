const renderer = @import("renderer.zig");

pub fn main() !void {
    renderer.init();
    defer renderer.deinit();
    renderer.draw();
}
