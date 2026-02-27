pub fn build(b: *std.Build) void {
    b.installArtifact(b.addExecutable(.{
        .name = "patch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/patch.zig"),
            .target = b.resolveTargetQuery(.{ .os_tag = .windows }),
            .optimize = .ReleaseSmall,
            .strip = true,
            .unwind_tables = .none,
            .imports = &.{.{
                .name = "patch.js",
                .module = b.createModule(.{
                    .root_source_file = b.addRunArtifact(b.addExecutable(.{
                        .name = "mfgen",
                        .root_module = b.createModule(.{
                            .root_source_file = b.path("src/main.zig"),
                            .target = b.standardTargetOptions(.{}),
                            .optimize = b.standardOptimizeOption(.{}),
                            .imports = &.{.{
                                .name = "build.zig.zon",
                                .module = b.createModule(.{ .root_source_file = b.path("build.zig.zon") }),
                            }},
                        }),
                    })).captureStdOut(),
                }),
            }},
        }),
    }));
}

const std = @import("std");
