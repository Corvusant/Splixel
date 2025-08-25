// Copyright (c) 2025 Josua Kucher All rights reserved.

//Compiletime Flags
const config = @import("config");

//std
const std = @import("std");

const OptionalFuncs = @import("optional.zig");
const Optional = @import("optional.zig").Optional;
const Tuple = @import("optional.zig").Tuple;
const perf = @import("perftimer.zig");
const fileUtils = @import("fileUtils.zig");
const threading = @import("threadWorker.zig");
const encoding = @import("imageEncoding.zig");
const filetypes = @import("types.zig");
const siteGeneration = @import("websitegeneration.zig");

fn ProcessInputArgs(allocator: std.mem.Allocator, args: [][:0]u8) Optional(filetypes.InputFiles) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-idir") and argumentNumber > i) {
            const pngFiles = FetchAllPNGFiles(allocator, args[i + 1]);

            if (pngFiles.items.len < 2) {
                std.debug.print("The provided Folder does not contain 2 Images to Diff\n", .{});
                return Optional(filetypes.InputFiles).None();
            }

            if (pngFiles.items.len > 2) {
                std.debug.print("The providerd folder contains more than 2 .png images. The first two will be used\n", .{});
            }
            return Optional(filetypes.InputFiles).Init(.{ .Images = [2]std.fs.File{ pngFiles.items[0], pngFiles.items[1] } });
        }
        if (std.mem.eql(u8, arg, "-ifile") and argumentNumber > i + 1) {
            const file1 = fileUtils.TryOpenFileFromPath(args[i + 1], .{});
            const file2 = fileUtils.TryOpenFileFromPath(args[i + 2], .{});

            return OptionalFuncs.Zip(std.fs.File, std.fs.File, file1, file2)
                .Bind(filetypes.InputFiles, struct {
                pub fn f(t: Tuple(std.fs.File, std.fs.File)) filetypes.InputFiles {
                    return .{ .Images = [2]std.fs.File{ t.m1, t.m2 } };
                }
            }.f);
        }
    }
    return Optional(filetypes.InputFiles).None();
}

fn ProcessOutputArgs(args: [][:0]u8) Optional(filetypes.OutputFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-o") and argumentNumber > i) {
            const potentialFilePath = args[i + 1];
            if (fileUtils.IsPathFolderValid(potentialFilePath)) {
                return Optional(filetypes.OutputFile).Init(.{ .File = potentialFilePath });
            } else {
                return Optional(filetypes.OutputFile).None();
            }
        }
    }
    return Optional(filetypes.OutputFile).None();
}

fn ProcessTemplatOutputArgs(args: [][:0]u8) Optional(filetypes.OutputFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-to") and argumentNumber > i) {
            const potentialFilePath = args[i + 1];
            if (fileUtils.IsPathFolderValid(potentialFilePath)) {
                return Optional(filetypes.OutputFile).Init(.{ .File = potentialFilePath });
            } else {
                return Optional(filetypes.OutputFile).None();
            }
        }
    }
    return Optional(filetypes.OutputFile).None();
}

const help = "Splixel: is a small utility for creating html pages with embedded 2 images conainting diffing functionality\n  -h|-help|-?|?: prints arguments and help\n  -idir [directory path]: input directory to fetch images from (cannot be used with -ifile)\n  -ifile [filepath] [filepath]: images to use (cannot be used with -idir)\n  -o [filepath]: output file to use (file will be created if it does not exist, missing directories will NOT be created)\n  -t [filepath]: optional html template file to use, default will be used if none is provided\n  -to [filepath]: generates a template file from the basetemplate, this can be used to start creating your own templates. Cannot be used with other arguments";
fn FindAndPrintHelp(args: [][:0]u8) bool {
    for (args, 0..) |arg, i| {
        if (i == 0) {
            if (args.len == 1 or args.len == 0) {
                std.debug.print(help, .{});
                return true;
            }
        } //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "-help") or std.mem.eql(u8, arg, "-?") or std.mem.eql(u8, arg, "?")) {
            std.debug.print(help, .{});
            return true;
        }
    }
    return false;
}

fn ProcessTemplateArgs(args: [][:0]u8) Optional(filetypes.TemplateFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-t") and argumentNumber > i) {
            const potentialFilePath = args[i + 1];
            return fileUtils.TryOpenFileFromPath(potentialFilePath, .{})
                .Bind(filetypes.TemplateFile, struct {
                pub fn f(file: std.fs.File) filetypes.TemplateFile {
                    return filetypes.TemplateFile{ .File = file };
                }
            }.f);
        }
    }
    return Optional(filetypes.TemplateFile).None();
}

fn FetchAllPNGFiles(allocator: std.mem.Allocator, folderPath: []const u8) std.ArrayList(std.fs.File) {
    var filePaths: std.ArrayList(std.fs.File) = std.ArrayList(std.fs.File).init(allocator);
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

        var extensions = [_][]const u8{ ".png", ".PNG" };
        if (!fileUtils.IsValidFile(item.path, &extensions))
            continue;

        const pathName = dir.realpathAlloc(allocator, "") catch {
            return filePaths;
        };
        const fullImagePath = std.fmt.allocPrint(allocator, "{s}\\{s}", .{ pathName, item.path }) catch {
            return filePaths;
        };
        if (fileUtils.TryOpenFileFromPath(fullImagePath, .{}).value) |f| {
            filePaths.append(f) catch {
                std.debug.print("Could not add files to process", .{});
            };
        }
    }
    return filePaths;
}

pub fn main() !void {
    var timer = if (comptime config.profiling) perf.StartTimer("main");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const args = std.process.argsAlloc(allocator) catch {
        std.debug.print("No Valid Aruments provided\n", .{});
        return {};
    };
    defer std.process.argsFree(allocator, args);

    if (FindAndPrintHelp(args))
        return;

    const templateOut = ProcessTemplatOutputArgs(args);
    if (templateOut.value) |to| {
        siteGeneration.GenerateTemplateFile(to) catch {
            std.debug.print("Could not write out Template to Location", .{});
        };
        return;
    }

    const input = ProcessInputArgs(allocator, args);
    const output = ProcessOutputArgs(args);
    const template = ProcessTemplateArgs(args);
    if (OptionalFuncs.Zip(filetypes.InputFiles, filetypes.OutputFile, input, output).value) |requiredInputs| {
        const filebuff = try allocator.alloc(u8, encoding.GetEncodedImageSize(requiredInputs.m1.Images[0]));
        const filebuff2 = try allocator.alloc(u8, encoding.GetEncodedImageSize(requiredInputs.m1.Images[1]));

        var ctx1 = threading.ThreadContext{
            .buff = filebuff,
            .file = requiredInputs.m1.Images[0],
            .out = undefined,
            .threadIdx = 0,
        };
        var t1 = try std.Thread.spawn(.{}, threading.worker, .{&ctx1});

        var ctx2 = threading.ThreadContext{
            .buff = filebuff2,
            .file = requiredInputs.m1.Images[1],
            .out = undefined,
            .threadIdx = 1,
        };
        var t2 = try std.Thread.spawn(.{}, threading.worker, .{&ctx2});

        t1.join();
        t2.join();

        if (template.value) |t| {
            siteGeneration.CreateHTMLPageFromTemplate(allocator, t.File, requiredInputs.m2, ctx1.out, ctx2.out) catch {
                std.debug.print("Could not write content to output File", .{});
            };
        } else {
            siteGeneration.CreateHTMLPageFromIncludedTemplate(allocator, requiredInputs.m2, ctx1.out, ctx2.out) catch {
                std.debug.print("Could not write content to output File", .{});
            };
        }
    }
}
