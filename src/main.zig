// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");
const OptionalFuncs = @import("optional");
const Optional = @import("optional").Optional;
const Tuple = @import("optional").Tuple;

const InputImages = struct { Images: [2]std.fs.File };

const TemplateFile = struct {
    File: std.fs.File,
};

const OutputFile = struct {
    File: []const u8,
};

fn TryOpenFileFromPath(path: []const u8, flags: std.fs.File.OpenFlags) Optional(std.fs.File) {
    const file = std.fs.openFileAbsolute(path, flags) catch {
        std.debug.print("File {s} cannot be opened. Check the Path.\n", .{path});
        return Optional(std.fs.File).None();
    };

    return Optional(std.fs.File).Init(file);
}

fn TryCreateFileFromPath(path: []const u8) Optional(std.fs.File) {
    const file = std.fs.createFileAbsolute(path, .{}) catch {
        std.debug.print("File {s} cannot be Created. Check the Path.\n", .{path});
        return Optional(std.fs.File).None();
    };

    return Optional(std.fs.File).Init(file);
}

fn IsPathFolderValid(path: []const u8) bool {
    //Find the first / in the path
    const localPath = path;
    var sliceEndpoint: usize = 0;
    var i: usize = localPath.len - 1;
    while (i > 0) : (i -= 1) {
        const testChar = localPath[i];
        if (testChar == '\\') {
            sliceEndpoint = i;
            break;
        }
    }
    const folderpath = localPath[0..sliceEndpoint];
    var dir = std.fs.openDirAbsolute(folderpath, .{}) catch {
        return false;
    };
    dir.close();
    return true;
}

fn ProcessInputArgs(allocator: std.mem.Allocator, args: [][:0]u8) Optional(InputImages) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-idir") and argumentNumber > i) {
            const pngFiles = FetchAllPNGFiles(allocator, args[i + 1]);

            if (pngFiles.items.len < 2) {
                std.debug.print("The provided Folder does not contain 2 Images to Diff\n", .{});
                return Optional(InputImages).None();
            }

            if (pngFiles.items.len > 2) {
                std.debug.print("The providerd folder contains more than 2 .png images. The first two will be used\n", .{});
            }
            return Optional(InputImages).Init(.{ .Images = [2]std.fs.File{ pngFiles.items[0], pngFiles.items[1] } });
        }
        if (std.mem.eql(u8, arg, "-ifile") and argumentNumber > i + 1) {
            const file1 = TryOpenFileFromPath(args[i + 1], .{});
            const file2 = TryOpenFileFromPath(args[i + 2], .{});

            return OptionalFuncs.Zip(std.fs.File, std.fs.File, file1, file2)
                .Bind(InputImages, struct {
                pub fn f(t: Tuple(std.fs.File, std.fs.File)) InputImages {
                    return .{ .Images = [2]std.fs.File{ t.m1, t.m2 } };
                }
            }.f);
        }
    }
    return Optional(InputImages).None();
}

fn ProcessOututArgs(args: [][:0]u8) Optional(OutputFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-o") and argumentNumber > i) {
            const potentialFilePath = args[i + 1];
            if (IsPathFolderValid(potentialFilePath)) {
                return Optional(OutputFile).Init(.{ .File = potentialFilePath });
            } else {
                return Optional(OutputFile).None();
            }
        }
    }
    return Optional(OutputFile).None();
}

fn ProcessTemplateArgs(args: [][:0]u8) Optional(TemplateFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-t") and argumentNumber > i) {
            std.debug.print("{}: {s}\n", .{ i, arg });

            const potentialFilePath = args[i + 1];
            return TryOpenFileFromPath(potentialFilePath, .{})
                .Bind(TemplateFile, struct {
                pub fn f(file: std.fs.File) TemplateFile {
                    return TemplateFile{ .File = file };
                }
            }.f);
        }
    }
    return Optional(TemplateFile).None();
}

fn IsValidFile(filename: []const u8) bool {
    const extensionFiler = [_][]const u8{ ".png", ".PNG" };
    for (extensionFiler) |extension| {
        if (std.mem.count(u8, filename, extension) > 0)
            return true;
    }
    return false;
}

fn FetchAllPNGFiles(allocator: std.mem.Allocator, folderPath: []const u8) std.ArrayList(std.fs.File) {
    var filePaths = std.ArrayList(std.fs.File).init(allocator);
    var dir = std.fs.cwd().openDir(folderPath, .{ .iterate = true }) catch {
        return filePaths;
    };
    defer dir.close();

    var walker = dir.walk(allocator) catch {
        return filePaths;
    };
    defer walker.deinit();

    while (walker.next() catch {
        return filePaths;
    }) |item| {
        if (item.kind != .file)
            continue;

        if (!IsValidFile(item.path))
            continue;

        const pathName = dir.realpathAlloc(allocator, "") catch {
            return filePaths;
        };
        const fullImagePath = std.fmt.allocPrint(allocator, "{s}\\{s}", .{ pathName, item.path }) catch {
            return filePaths;
        };
        if (TryOpenFileFromPath(fullImagePath, .{}).value) |f| {
            filePaths.append(f) catch {
                std.debug.print("Could not add files to process", .{});
            };
        }
    }
    return filePaths;
}

const Encoder = std.base64.standard.Encoder;
fn ConvertImageToBas64(allocator: std.mem.Allocator, file: std.fs.File) []const u8 {
    const filesize = file.getEndPos() catch {
        return "";
    };

    const filecontent = file.readToEndAlloc(allocator, filesize) catch {
        return "";
    };
    const encodedLength = Encoder.calcSize(filesize);
    const encodedFile = allocator.alloc(u8, encodedLength) catch {
        return "";
    };

    return Encoder.encode(encodedFile, filecontent);
}

fn CreateHTMLPage(allocator: std.mem.Allocator, outputfile: OutputFile, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    const fileContent = try std.fmt.allocPrint(allocator, "<html><body><img src=\"data:image/png;base64, {s}\"><img src=\"data:image/png;base64, {s}\"></body></html>", .{ encodedImage1, encodedImage2 });

    if (TryCreateFileFromPath(outputfile.File).value) |file| {
        try file.writeAll(fileContent);
    } else {
        if (TryOpenFileFromPath(outputfile.File, .{}).value) |file| {
            try file.writeAll(fileContent);
        }
    }
}

fn CreateHTMLPageFromTemplate(allocator: std.mem.Allocator, outputFile: OutputFile, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    const fileContent = try std.fmt.allocPrint(allocator, "<html><body><img src=\"data:image/png;base64, {s}\"><img src=\"data:image/png;base64, {s}\"></body></html>", .{ encodedImage1, encodedImage2 });

    if (TryCreateFileFromPath(outputFile.File).value) |file| {
        try file.writeAll(fileContent);
    } else {
        if (TryOpenFileFromPath(outputFile.File, .{}).value) |file| {
            try file.writeAll(fileContent);
        }
    }
}

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = general_purpose_allocator.allocator();
    const args = std.process.argsAlloc(gpa) catch {
        std.debug.print("No Valid Aruments provided\n", .{});
        return {};
    };
    defer std.process.argsFree(gpa, args);

    const input = ProcessInputArgs(gpa, args);
    const output = ProcessOututArgs(args);
    const template = ProcessTemplateArgs(args);
    if (OptionalFuncs.Zip(InputImages, OutputFile, input, output).value) |requiredInputs| {
        const encodedImage1 = ConvertImageToBas64(gpa, requiredInputs.m1.Images[0]);
        const encodedImage2 = ConvertImageToBas64(gpa, requiredInputs.m1.Images[1]);
        if (template.IsSet()) {
            CreateHTMLPageFromTemplate(gpa, requiredInputs.m2, encodedImage1, encodedImage2) catch {
                std.debug.print("Could not write to content to output File", .{});
            };
        } else {
            CreateHTMLPage(gpa, requiredInputs.m2, encodedImage1, encodedImage2) catch {
                std.debug.print("Could not write to content to output File", .{});
            };
        }
    }
}
