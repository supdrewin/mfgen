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
        const path = try std.fs.path.join(allocator, &.{ game, "index.html" });
        defer allocator.free(path);

        const file = try std.fs.createFileAbsolute(path, .{});
        defer file.close();

        _ = try file.write(index);
    }

    {
        const path = try std.fs.path.join(allocator, &.{ game, "patch.js" });
        defer allocator.free(path);

        const file = try std.fs.createFileAbsolute(path, .{});
        defer file.close();

        _ = try file.write(patch);
    }

    const path = try std.fs.path.join(allocator, &.{ game, ".grp" });
    defer allocator.free(path);

    std.fs.deleteFileAbsolute(path) catch {};
}
