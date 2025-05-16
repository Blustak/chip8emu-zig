const std = @import("std");

//Testing bits taken from the zig docs.
const test_targets = [_]std.Target.Query{
    .{}, //native
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    .{
        .cpu_arch = .aarch64,
        .os_tag = .macos,
    },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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
    for (test_targets) |test_target| {
        const unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(test_target),
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        run_unit_tests.skip_foreign_checks = true;
        test_step.dependOn(&run_unit_tests.step);
    }
}
