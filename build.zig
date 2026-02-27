const std = @import("std");

pub fn build(b: *std.Build) void {
    const mfgen = b.addUpdateSourceFiles();

    mfgen.addCopyFileToSource(b.addRunArtifact(b.addExecutable(.{
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
    })).captureStdOut(), "patch.js");

    const patch = b.addExecutable(.{
        .name = "patch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/patch.zig"),
            .target = b.resolveTargetQuery(.{ .os_tag = .windows }),
            .optimize = .ReleaseSmall,
            .imports = &.{.{
                .name = "patch.js",
                .module = b.createModule(.{ .root_source_file = b.path("patch.js") }),
            }},
        }),
    });

    patch.step.dependOn(&mfgen.step);

    b.installArtifact(patch);
}
