const std = @import("std");

const PIXEL_WIDTH = 64;
const PIXEL_HEIGHT = 32;
const PIXEL_SCALE = 20;
//Testing bits taken from the zig docs.

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const pixel_scale = b.option(usize, "scale", "scale of each chip-8 pixel") orelse PIXEL_SCALE;

    const options = b.addOptions();
    options.addOption(usize, "pixel_scale", pixel_scale);

    const exe = b.addExecutable(.{
        .name = "chip8-emulator",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Link against Raylib library
    exe.linkSystemLibrary("raylib");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the executable");
    run_step.dependOn(&run_exe.step);

    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
    });
    unit_tests.linkSystemLibrary("raylib");
    unit_tests.linkLibC();

    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
