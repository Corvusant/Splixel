//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn IsValidFile(filename: []const u8) bool {
    const extensionFiler = [_][]const u8{ ".png", ".PNG" };
    for (extensionFiler) |extension| {
        if (std.mem.count(u8, filename, extension) > 0)
            return true;
    }
    return false;
}

pub fn FetchAllPNGFiles(allocator: std.mem.Allocator, folderPath: []const u8) !std.ArrayList([]const u8) {
    var filePaths = std.ArrayList([]const u8).init(allocator);
    var dir = try std.fs.cwd().openDir(folderPath, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |item| {
        if (item.kind != .file)
            continue;

        if (!IsValidFile(item.path))
            continue;
        const path = try allocator.alloc(u8, item.path.len);
        std.mem.copyForwards(u8, path, item.path);
        try filePaths.append(path);
    }
    return filePaths;
}

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        std.debug.print("{}: {s}\n", .{ i, arg });
        const pngFiles = try FetchAllPNGFiles(gpa, arg);
        defer pngFiles.deinit();
        for (pngFiles.items) |file| {
            std.debug.print(" File Found {s}", .{file});
        }
    }
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("ImageDiffer_lib");
