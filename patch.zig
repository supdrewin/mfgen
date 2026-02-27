const std = @import("std");

const index = @embedFile("index.html");
const patch = @embedFile("patch.js");

const game = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\METEORITEFALL\\Game\\";

pub fn main() !void {
    {
        const file = try std.fs.createFileAbsolute(game ++ "index.html", .{});
        defer file.close();

        _ = try file.write(index);
    }

    {
        const file = try std.fs.createFileAbsolute(game ++ "patch.js", .{});
        defer file.close();

        _ = try file.write(patch);
    }

    try std.fs.deleteFileAbsolute(game ++ ".grp");
}
