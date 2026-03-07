const std = @import("std");

const windows = std.os.windows;
const allocator = std.heap.page_allocator;

const script = "<script type=\"text/javascript\" src=\"script.js";
const patch = "<script type=\"text/javascript\" src=\"patch.js";

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const game = if (args.len == 2) args[1] else "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game";

    blk: {
        const __path = try std.fs.path.join(allocator, &.{ game, "index.html" });
        defer allocator.free(__path);

        const _path = try std.fmt.allocPrint(allocator, "\\??\\{s}", .{__path});
        defer allocator.free(_path);

        const path = try std.unicode.wtf8ToWtf16LeAlloc(allocator, _path);
        defer allocator.free(path);

        const file = std.fs.File{ .handle = try windows.OpenFile(path, .{
            .access_mask = windows.SYNCHRONIZE | windows.GENERIC_READ | windows.GENERIC_WRITE,
            .creation = windows.FILE_OPEN,
        }) };
        defer file.close();

        var buffer: [1024]u8 = undefined;
        var pos: u64 = 0;

        var reader = file.reader(&buffer);
        {
            var _pos: u64 = 0;

            while (try reader.interface.takeDelimiter('\n')) |line| {
                if (std.mem.eql(u8, line[0..patch.len], patch)) {
                    break :blk;
                } else if (std.mem.eql(u8, line[0..script.len], script)) {
                    pos = _pos;
                }

                _pos = reader.logicalPos();
            }
        }
        try reader.seekTo(pos);

        const remaining = try reader.interface.allocRemaining(allocator, .unlimited);
        defer allocator.free(remaining);

        var writer = file.writer(&buffer);
        try writer.seekTo(pos);

        _ = try writer.interface.write(patch ++ "\" ></script>\n");
        _ = try writer.interface.write(remaining);

        try writer.interface.flush();
    }

    {
        const __path = try std.fs.path.join(allocator, &.{ game, "patch.js" });
        defer allocator.free(__path);

        const _path = try std.fmt.allocPrint(allocator, "\\??\\{s}", .{__path});
        defer allocator.free(_path);

        const path = try std.unicode.wtf8ToWtf16LeAlloc(allocator, _path);
        defer allocator.free(path);

        const file = std.fs.File{ .handle = try windows.OpenFile(path, .{
            .access_mask = windows.SYNCHRONIZE | windows.GENERIC_WRITE,
            .creation = windows.FILE_OVERWRITE_IF,
        }) };
        defer file.close();

        _ = try file.write(@embedFile("patch.js"));
    }

    const __path = try std.fs.path.join(allocator, &.{ game, ".grp" });
    defer allocator.free(__path);

    const _path = try std.fmt.allocPrint(allocator, "\\??\\{s}", .{__path});
    defer allocator.free(_path);

    const path = try std.unicode.wtf8ToWtf16LeAlloc(allocator, _path);
    defer allocator.free(path);

    windows.DeleteFile(path, .{ .dir = null }) catch {};
}
