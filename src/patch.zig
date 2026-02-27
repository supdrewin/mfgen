const std = @import("std");

const windows = std.os.windows;
const gpa = std.heap.page_allocator;

const script = "<script type=\"text/javascript\" src=\"script.js";
const patch = "<script type=\"text/javascript\" src=\"patch.js";

pub fn main() !void {
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const game = if (args.len == 2) args[1] else "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game";

    var arena: std.heap.ArenaAllocator = .init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    _: {
        const file: std.fs.File = .{
            .handle = try windows.OpenFile(
                try join(allocator, &.{ game, "index.html" }),
                .{
                    .access_mask = windows.SYNCHRONIZE | windows.GENERIC_READ | windows.GENERIC_WRITE,
                    .creation = windows.FILE_OPEN,
                },
            ),
        };
        defer file.close();

        var buffer: [1024]u8 = undefined;
        var reader = file.reader(&buffer);

        var pos: u64 = undefined;
        var _pos: u64 = 0;

        while (try reader.interface.takeDelimiter('\n')) |line| : (_pos = reader.logicalPos()) {
            if (std.mem.eql(u8, line[0..patch.len], patch)) break :_;
            if (std.mem.eql(u8, line[0..script.len], script)) pos = _pos;
        }

        try reader.seekTo(pos);

        const remaining = try reader.interface.allocRemaining(allocator, .unlimited);

        try file.seekTo(pos);
        try file.writeAll(patch ++ "\" ></script>\n");
        try file.writeAll(remaining);
    }

    {
        const file: std.fs.File = .{
            .handle = try windows.OpenFile(
                try join(allocator, &.{ game, "patch.js" }),
                .{
                    .access_mask = windows.SYNCHRONIZE | windows.GENERIC_WRITE,
                    .creation = windows.FILE_OVERWRITE_IF,
                },
            ),
        };
        defer file.close();

        try file.writeAll(@embedFile("patch.js"));
    }

    windows.DeleteFile(try join(allocator, &.{ game, ".grp" }), .{ .dir = null }) catch {};
}

fn join(arena: std.mem.Allocator, paths: []const []const u8) ![]const u16 {
    return try std.unicode.wtf8ToWtf16LeAlloc(arena, try std.fmt.allocPrint(arena, "\\??\\{s}", .{try std.fs.path.join(arena, paths)}));
}
