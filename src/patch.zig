pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    const game = if (args.len == 2) args[1] else "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game";

    var dir = try std.Io.Dir.openDirAbsolute(init.io, game, .{});
    defer dir.close(init.io);

    _: {
        const file = try dir.openFile(init.io, "index.html", .{ .mode = .read_write });
        defer file.close(init.io);

        var buffer: [1024]u8 = undefined;
        var reader = file.reader(init.io, &buffer);

        const script = "<script type=\"text/javascript\" src=\"script.js";
        const patch = "<script type=\"text/javascript\" src=\"patch.js";

        var pos: u64 = undefined;
        var _pos: u64 = 0;

        while (try reader.interface.takeDelimiter('\n')) |line| : (_pos = reader.logicalPos()) {
            if (std.mem.eql(u8, line[0..patch.len], patch)) break :_;
            if (std.mem.eql(u8, line[0..script.len], script)) pos = _pos;
        }

        try reader.seekTo(pos);

        const remaining = try reader.interface.allocRemaining(init.gpa, .unlimited);
        defer init.gpa.free(remaining);

        var writer = file.writer(init.io, "");

        try writer.seekTo(pos);

        try writer.interface.writeAll(patch ++ "\" ></script>\n");
        try writer.interface.writeAll(remaining);
    }

    {
        const file = try dir.createFile(init.io, "patch.js", .{});
        defer file.close(init.io);

        var writer = file.writer(init.io, "");

        try writer.interface.writeAll(@embedFile("patch.js"));
    }

    dir.deleteFile(init.io, ".grp") catch {};
}

pub const std_options: std.Options = .{ .networking = false };

const std = @import("std");
