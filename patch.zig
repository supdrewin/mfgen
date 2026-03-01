const std = @import("std");

const index = @embedFile("index.html");
const patch = @embedFile("patch.js");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const game = if (args.len == 2) args[1] else "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game";

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

    // replace `std.fs.deleteFileAbsolute` to decrease executable size (save ~200KB)
    {
        const __path = try std.fs.path.join(allocator, &.{ game, ".grp" });
        defer allocator.free(__path);

        const _path = try std.fmt.allocPrint(allocator, "\\??\\{s}", .{__path});
        defer allocator.free(_path);

        const path = try std.unicode.wtf8ToWtf16LeAlloc(allocator, _path);
        defer allocator.free(path);

        std.os.windows.DeleteFile(path, .{ .dir = null }) catch {};
    }
}
