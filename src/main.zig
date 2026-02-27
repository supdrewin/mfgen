pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var map: std.StringArrayHashMap([]const usize) = .init(gpa);
    defer map.deinit();

    var dir = try std.fs.cwd().openDir("asset/image/live2d", .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(gpa);
    defer walker.deinit();

    var arena: std.heap.ArenaAllocator = .init(gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".model3.json")) {
            const model3 = try json(gpa, dir, entry.path);
            defer model3.deinit();

            const path = try std.fs.path.join(allocator, &.{
                std.fs.path.dirname(entry.path).?,
                model3.value.object.get("FileReferences").?.object.get("DisplayInfo").?.string,
            });

            const cdi3 = try json(gpa, dir, path);
            defer cdi3.deinit();

            var parts: std.ArrayList(usize) = .empty;

            for (cdi3.value.object.get("Parts").?.array.items, 0..) |value, i| {
                const name = value.object.get("Name").?.string;

                if (std.mem.eql(u8, name, "效果组") or std.mem.containsAtLeast(u8, name, 1, "雾"))
                    try parts.append(allocator, i);
            }

            if (parts.items.len != 0) try map.put(
                try std.ascii.allocLowerString(allocator, entry.basename),
                try parts.toOwnedSlice(allocator),
            );
        }
    }

    try map.put("lh_mengyao.model3.json", &.{0});
    try map.put("ys_suxi.model3.json", &.{ 3, 5 });

    _ = map.swapRemove("hsq_mengyao.model3.json");
    _ = map.swapRemove("wq_cg.model3.json");

    var buffer: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buffer);

    const stdout = &writer.interface;

    try stdout.print(
        "// Generated from: https://github.com/supdrewin/mfgen\n" ++
            "// Current version: {s}\n" ++
            "var id = setInterval(() => {{\n" ++
            "\tLAppModel.prototype._loadAssets = LAppModel.prototype.loadAssets;\n" ++
            "\tLAppModel.prototype._loadModel = LAppModel.prototype.loadModel;\n" ++
            "\tLive2DCubismCore.Model.prototype._hasUpdateHack = false;\n" ++
            "\tLive2DCubismCore.Model.prototype._update = Live2DCubismCore.Model.prototype.update;\n" ++
            "\tLive2DCubismCore.Model.prototype.update = function () {{\n" ++
            "\t\tthis._update();\n" ++
            "\t\tif (this._hasUpdateHack) this.drawables.opacities.forEach((_, i, opacities) => {{\n" ++
            "\t\t\tif (this.drawables.parentPartIndices[i] < 0) opacities[i] = 0;\n" ++
            "\t\t}});\n" ++
            "\t}};\n" ++
            "\tLAppModel.prototype.loadAssets = function (dir, fileName) {{\n" ++
            "\t\tif (fileName.toLowerCase() == \"sh_jinyueshi.model3.json\") {{\n" ++
            "\t\t\tLAppModel.prototype.loadModel = function (buffer, shouldCheckMocConsistency = false) {{\n" ++
            "\t\t\t\tthis._loadModel(buffer, shouldCheckMocConsistency);\n" ++
            "\t\t\t\tthis._model._model._hasUpdateHack = true;\n" ++
            "\t\t\t\tLAppModel.prototype.loadModel = LAppModel.prototype._loadModel;\n" ++
            "\t\t\t}};\n",
        .{@import("build.zig.zon").version},
    );

    while (map.pop()) |entry| {
        try stdout.print(
            "\t\t}} else if (fileName.toLowerCase() == \"{s}\") {{\n" ++
                "\t\t\tLAppModel.prototype.loadModel = function (buffer, shouldCheckMocConsistency = false) {{\n" ++
                "\t\t\t\tthis._loadModel(buffer, shouldCheckMocConsistency);\n",
            .{entry.key},
        );

        for (entry.value) |i| {
            try stdout.print("\t\t\t\tthis._model.setPartOpacityByIndex({}, 0);\n", .{i});
        }

        try stdout.print(
            "\t\t\t\tLAppModel.prototype.loadModel = LAppModel.prototype._loadModel;\n" ++
                "\t\t\t}};\n",
            .{},
        );
    }

    try stdout.print(
        "\t\t}}\n" ++
            "\t\tthis._loadAssets(dir, fileName);\n" ++
            "\t}};\n" ++
            "\tclearInterval(id);\n" ++
            "}}, 1000);\n",
        .{},
    );

    try stdout.flush();
}

fn json(gpa: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) !std.json.Parsed(std.json.Value) {
    const file = try dir.openFile(path, .{});
    defer file.close();

    var buffer: [1024]u8 = undefined;
    var reader = file.reader(&buffer);

    const s = try reader.interface.allocRemaining(gpa, .unlimited);
    defer gpa.free(s);

    return try std.json.parseFromSlice(std.json.Value, gpa, s, .{});
}

const std = @import("std");
