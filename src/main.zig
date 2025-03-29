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

        const pathName = try dir.realpathAlloc(allocator, "");
        const fullImagePath = try std.fmt.allocPrint(allocator, "{s}\\{s}", .{ pathName, item.path });
        try filePaths.append(fullImagePath);
    }
    return filePaths;
}

const Encoder = std.base64.standard.Encoder;
pub fn ConvertImageToBas64(allocator: std.mem.Allocator, filepath: []const u8) ![]const u8 {
    const path = filepath;
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();

    const filesize = try file.getEndPos();

    const filecontent = try file.readToEndAlloc(allocator, filesize);
    const encodedLength = Encoder.calcSize(filesize);
    const encodedFile = try allocator.alloc(u8, encodedLength);
    return Encoder.encode(encodedFile, filecontent);
}

pub fn CreateHTMLPageWithImage(allocator: std.mem.Allocator, filePath: []const u8, encodedImage: []const u8) !void {
    const path = filePath;
    var file = try std.fs.cwd().createFile(path, .{});
    const fileContent = try std.fmt.allocPrint(allocator, "<html><body><img src=\"data:image/png;base64, {s}\"></body></html>", .{encodedImage});
    try file.writeAll(fileContent);
}

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    var outputPath: []u8 = "";
    var inputPath: []u8 = "";
    for (args, 0..) |arg, i| {
        if (i == 0) continue;
        if (std.mem.eql(u8, arg, "-i") and args.len > i) {
            inputPath = args[i + 1];
        }
        if (std.mem.eql(u8, arg, "-o") and args.len > i) {
            outputPath = args[i + 1];
        } //ignore the path to our own executable
        std.debug.print("{}: {s}\n", .{ i, arg });
    }

    const pngFiles = try FetchAllPNGFiles(gpa, inputPath);
    defer pngFiles.deinit();
    for (pngFiles.items) |file| {
        std.debug.print(" File Found {s}", .{file});
        const encodedImage = try ConvertImageToBas64(gpa, file);
        try CreateHTMLPageWithImage(gpa, outputPath, encodedImage);
    }
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("ImageDiffer_lib");
