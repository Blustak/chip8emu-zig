const renderer = @import("renderer.zig");

pub fn main() !void {
    try renderer.init();
    defer renderer.deinit();

    renderer.draw();
}
