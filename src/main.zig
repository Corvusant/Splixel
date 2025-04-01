//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");
const OptionalFuncs = @import("optional");
const Optional = @import("optional").Optional;
const Tuple = @import("optional").Tuple;

const InputImages = struct {
    Image1: std.fs.File,
    Image2: std.fs.File,
};

const InputFolder = struct {
    Folder: []const u8,
};

const TemplateFile = struct {
    TemplateFile: std.fs.File,
};

const OutputFile = struct {
    File: []const u8,
};

const InputType = enum {
    File,
    Folder,
};
const InputUnion = union(InputType) { File: InputImages, Folder: InputFolder };

pub fn TryOpenFileFromPath(path: []const u8) Optional(std.fs.File) {
    const file = std.fs.openFileAbsolute(path, .{});
    if (file) {
        return Optional{file};
    } else {
        std.debug.print("Template File {s} cannot be opened. Check the Path.\n", .{});
        return Optional{};
    }
}

pub fn ProcessInputArgs(args: [][]const u8) Optional(InputUnion) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) return null; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-idir") and argumentNumber > i) {
            return Optional(InputUnion){InputFolder{ .Folder = args[i + 1] }};
        }
        if (std.mem.eql(u8, arg, "-ifile") and argumentNumber > i + 1) {
            const file1 = TryOpenFileFromPath(args[i + 1]);
            const file2 = TryOpenFileFromPath(args[i + 2]);

            return OptionalFuncs.Zip(file1, file2)
                .Bind(InputUnion, struct {
                pub fn f(t: Tuple(std.fs.File, std.fs.File)) TemplateFile {
                    return InputUnion{InputImages{ .Image1 = t.m1, .Image2 = t.m2 }};
                }
            }.f);
        }
        std.debug.print("{}: {s}\n", .{ i, arg });
    }
}

pub fn ProcessOututArgs(args: [][]const u8) ?OutputFile {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) return null; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-o") and argumentNumber > i) {
            std.debug.print("{}: {s}\n", .{ i, arg });
            return OutputFile{
                .File = args[i + 1],
            };
        }
    }
}

pub fn ProcessTemplateArgs(args: [][]const u8) Optional(TemplateFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) return null; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-t") and argumentNumber > i) {
            std.debug.print("{}: {s}\n", .{ i, arg });

            const potentialFilePath = args[i + 1];
            return TryOpenFileFromPath(potentialFilePath)
                .Bind(TemplateFile, struct {
                pub fn f(file: std.fs.File) TemplateFile {
                    return TemplateFile{ .file = file };
                }
            }.f);
        }
    }
}

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
    const args = std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    if (args) {
        const input = ProcessInputArgs(args);
        const output = ProcessOututArgs(args);
        const template = ProcessTemplateArgs(args);
    } else {
        std.debug.print("No Valid Aruments provided\n");
    }

    const pngFiles = try FetchAllPNGFiles(gpa, inputPath);
    defer pngFiles.deinit();
    for (pngFiles.items) |file| {
        std.debug.print(" File Found {s}", .{file});
        const encodedImage = try ConvertImageToBas64(gpa, file);
        try CreateHTMLPageWithImage(gpa, outputPath, encodedImage);
    }
}
