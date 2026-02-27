const std = @import("std");

const index = @embedFile("index.html");
const patch = @embedFile("patch.js");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    var game: [:0]const u8 = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game";

    if (args.len == 2) {
        game = args[1];
    }

    {
        const file = try std.fs.createFileAbsolute(try std.fs.path.join(allocator, &.{ game, "index.html" }), .{});
        defer file.close();

        _ = try file.write(index);
    }

    {
        const file = try std.fs.createFileAbsolute(try std.fs.path.join(allocator, &.{ game, "patch.js" }), .{});
        defer file.close();

        _ = try file.write(patch);
    }

    try std.fs.deleteFileAbsolute(try std.fs.path.join(allocator, &.{ game, ".grp" }));
}
