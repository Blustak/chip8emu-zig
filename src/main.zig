const renderer = @import("renderer.zig");
const audio_driver = @import("audio_driver.zig");
const rl = @import("raylib").rl;

pub fn main() !void {
    try renderer.init();
    defer renderer.deinit();
    try audio_driver.init();
    defer audio_driver.deinit();
    audio_driver.play_tone = true;

    while (!rl.WindowShouldClose()){
        renderer.draw();
        audio_driver.play_sound();
    }
}
