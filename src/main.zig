// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");
const OptionalFuncs = @import("optional");
const Optional = @import("optional").Optional;
const Tuple = @import("optional").Tuple;
const perf = @import("perftimer.zig");

const baseTemplate = "<!DOCTYPE html>\n<html>\n<head>\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<style>\n\nbody {\n  background-color: rgb(52, 57, 57);\n  margin: 0px;\n  height: 100%;\n}\n.wrapper {\n  display: flex;\n  top: 50px;\n  align-items: center;\n  justify-content: center;\n}\n.container {\n  position: absolute;\n  top: 50px;\n  border: 5px solid #ffcb70;\n  border-radius: 2%;\n  overflow: hidden;\n}\n\n.sliderHandle{\n  position: absolute;\n  z-index:9;\n  cursor: ew-resize;\n  width: 25px;\n  height: 25px;\n  background-color: #ffcb70;\n  border-radius: 50%;\n  opacity: 0.7;\n}\n\n.sliderLine {\n  position: absolute;\n  z-index:8;\n  cursor: ew-resize;\n  width: 3px;\n  background-color: #ffcb70;\n  opacity: 0.7;\n}\n\n.img {\n  position: absolute;\n  width: auto;\n  height: auto;\n  overflow:hidden;\n}\n\n.img .img-overlay{}\n\n.img img {\n  display:block;\n  vertical-align:middle;\n}\n\n</style>\n<script>\n\nvar x = 0, i =0;\nvar clicked = 0, w = 0, h = 0;\nvar sliderHandle, sliderLine, overlayImage, container;\n\nfunction ToCssDimensionPx(x) { return x + \"px\"; }\n\nfunction SetupSlider(w,h)\n{\n  \n  halfWidth = w/2;\n  halfHeight = h/2;\n  \n  /*create slider:*/\n  sliderHandle = document.getElementsByClassName(\"sliderHandle\")[0];\n  sliderLine = document.getElementsByClassName(\"sliderLine\")[0];\n\n  sliderLine.style.height =ToCssDimensionPx(h); \n\n  /*position the slider in the middle:*/\n  sliderHandle.style.top = ToCssDimensionPx(halfHeight - (sliderHandle.offsetHeight / 2));\n  sliderHandle.style.left = ToCssDimensionPx(halfWidth - (sliderHandle.offsetWidth / 2));\n\n  sliderLine.style.top = ToCssDimensionPx(halfHeight - (sliderLine.offsetHeight / 2));\n  sliderLine.style.left = ToCssDimensionPx(halfWidth - (sliderLine.offsetWidth / 2));\n\n  sliderHandle.addEventListener(\"mousedown\", slideReady);\n  sliderLine.addEventListener(\"mousedown\", slideReady);\n  sliderHandle.addEventListener(\"touchstart\", slideReady);\n  sliderLine.addEventListener(\"touchstart\", slideReady);\n}\n\nfunction SetupContainer(w, h)\n{\n  container = document.getElementsByClassName(\"container\")[0];\n  container.style.width = ToCssDimensionPx(w);\n  container.style.height = ToCssDimensionPx(h);\n}\n  \nfunction slideReady(e) {\n    /*prevent any other actions that may occur when moving over the image:*/\n    e.preventDefault();\n    /*the slider is now clicked and ready to move:*/\n    clicked = 1;\n    /*execute a function when the slider is moved:*/\n    window.addEventListener(\"mousemove\", slideMove);\n    window.addEventListener(\"touchmove\", slideMove);\n  }\n\n  function slideFinish() {\n    /*the slider is no longer clicked:*/\n    clicked = 0;\n  }\n\n  function slideMove(e) {\n    var pos;\n    /*if the slider is no longer clicked, exit this function:*/\n    if (clicked == 0) return false;\n    /*get the cursor's x position:*/\n    pos = getCursorPos(e)\n    /*prevent the slider from being positioned outside the image:*/\n    if (pos < 0) pos = 0;\n    if (pos > w) pos = w;\n    /*execute a function that will resize the overlay image according to the cursor:*/\n    slide(pos);\n  }\n\n  function getCursorPos(e) {\n    var a, x = 0;\n    e = (e.changedTouches) ? e.changedTouches[0] : e;\n    /*get the x positions of the image:*/\n    a = overlayImage.getBoundingClientRect();\n    /*calculate the cursor's x coordinate, relative to the image:*/\n    x = e.pageX - a.left;\n    /*consider any page scrolling:*/\n    x = x - window.pageXOffset;\n    return x;\n  }\n\n  function slide(x) {\n    overlayImage.style.width = ToCssDimensionPx(x);\n    sliderHandle.style.left = ToCssDimensionPx(overlayImage.offsetWidth - (sliderHandle.offsetWidth / 2));\n    sliderLine.style.left = ToCssDimensionPx(overlayImage.offsetWidth - (sliderLine.offsetWidth / 2));\n  }\n\n\nfunction Compare() {\n\n  var images = document.getElementsByClassName(\"img\");\n  for (i = 0; i < images.length; i++) {\n    w = Math.max(w,images[i].clientWidth);\n    h = Math.max(h,images[i].clientHeight);\n  };\n\n  overlayImage = document.getElementsByClassName(\"img-overlay\")[0];\n  overlayImage.style.width = ToCssDimensionPx(overlayImage.clientWidth);\n  \n  SetupContainer(w,h);\n  SetupSlider(w,h);\n\n  /*Window functions*/\n  window.addEventListener(\"mouseup\", slideFinish);\n  window.addEventListener(\"touchend\", slideFinish);\n\n  slide(w/2);\n}\n\n  window.onload = function() {\n    Compare();\n};\n</script>\n\n</script>\n</head>\n<body>\n<div class=\"wrapper\">\n  <div class=\"container\">\n    <div class=\"img\">\n      <img src=\"data:image/png;base64, <{img-left}>\">\n    </div>\n    <div class=\"sliderLine\"></div>\n    <div class=\"sliderHandle\"></div>\n    <div class=\"img img-overlay\">\n      <img src=\"data:image/png;base64, <{img-right}>\">\n    </div>\n  </div>\n</div>\n</body>\n</html>\n";
const leftImageMarker = "<{img-left}>";
const rightImageMarker = "<{img-right}>";

const InputImages = struct { Images: [2]std.fs.File };

const TemplateFile = struct {
    File: std.fs.File,
};

const OutputFile = struct {
    File: []const u8,
};

fn TryOpenFileFromPath(path: []const u8, flags: std.fs.File.OpenFlags) Optional(std.fs.File) {
    var timer = perf.StarTimer("TryOpenFileFromPath");
    defer perf.StopTimer(&timer);
    const file = std.fs.openFileAbsolute(path, flags) catch {
        std.debug.print("File {s} cannot be opened. Check the Path.\n", .{path});
        return Optional(std.fs.File).None();
    };

    return Optional(std.fs.File).Init(file);
}

fn TryCreateFileFromPath(path: []const u8) Optional(std.fs.File) {
    var timer = perf.StarTimer("TryCreateFileFromPath");
    defer perf.StopTimer(&timer);
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

fn ProcessOutputArgs(args: [][:0]u8) Optional(OutputFile) {
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

fn ProcessTemplatOutputArgs(args: [][:0]u8) Optional(OutputFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-to") and argumentNumber > i) {
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

fn ProcessTemplateArgs(args: [][:0]u8) Optional(TemplateFile) {
    const argumentNumber = args.len;

    for (args, 0..) |arg, i| {
        if (i == 0) continue; //ignore the path to our own executable
        if (std.mem.eql(u8, arg, "-t") and argumentNumber > i) {
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

fn ConvertImageToBas64(allocator: std.mem.Allocator, file: std.fs.File, fileBuf: []u8) []const u8 {
    const Encoder = std.base64.standard.Encoder;
    const filesize = file.getEndPos() catch {
        return "";
    };

    const filecontent = file.readToEndAlloc(allocator, filesize) catch {
        return "";
    };

    return Encoder.encode(fileBuf, filecontent);
}

fn GetEncodedImageSize(file: std.fs.File) usize {
    const Encoder = std.base64.standard.Encoder;
    const filesize = file.getEndPos() catch {
        return 0;
    };

    return Encoder.calcSize(filesize);
}

fn CreateHTMLPage(allocator: std.mem.Allocator, outputfile: OutputFile, template: []const u8, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    var timer = perf.StarTimer("CreateHTMLPageFromTemplate");
    defer perf.StopTimer(&timer);

    var timer2 = perf.StarTimer("ReplaceLeftImageMarker");
    const templateWithImg1 = try std.mem.replaceOwned(u8, allocator, template, leftImageMarker, encodedImage1);
    perf.StopTimer(&timer2);

    var timer3 = perf.StarTimer("ReplaceRightImageMarker");
    const completedFile = try std.mem.replaceOwned(u8, allocator, templateWithImg1, rightImageMarker, encodedImage2);
    perf.StopTimer(&timer3);

    if (TryCreateFileFromPath(outputfile.File).value) |file| {
        try file.writeAll(completedFile);
    } else {
        if (TryOpenFileFromPath(outputfile.File, .{}).value) |file| {
            try file.writeAll(completedFile);
        }
    }
}

fn CreateHTMLPageFromTemplate(allocator: std.mem.Allocator, template: std.fs.File, outputFile: OutputFile, encodedImage1: []const u8, encodedImage2: []const u8) !void {
    var timer = perf.StarTimer("CreateHTMLPageFromTemplate");
    defer perf.StopTimer(&timer);

    const filesize = try template.getEndPos();
    const templateContent = try template.readToEndAlloc(allocator, filesize);
    try CreateHTMLPage(allocator, outputFile, templateContent, encodedImage1, encodedImage2);
}

fn GenerateTemplateFile(outputFile: OutputFile) !void {
    var timer = perf.StarTimer("CreateHTMLPageFromTemplate");
    defer perf.StopTimer(&timer);

    if (TryCreateFileFromPath(outputFile.File).value) |file| {
        try file.writeAll(baseTemplate);
    } else {
        if (TryOpenFileFromPath(outputFile.File, .{}).value) |file| {
            try file.writeAll(baseTemplate);
        }
    }
}

const ThreadContext = struct { buff: []u8, file: std.fs.File, out: []const u8, threadIdx: u8 };

fn worker(ctx: *ThreadContext) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const timerName = std.fmt.allocPrint(
        allocator,
        "Encode {}",
        .{ctx.threadIdx},
    ) catch {
        return;
    };

    var timer = perf.StarTimer(timerName);
    defer perf.StopTimer(&timer);

    ctx.out = ConvertImageToBas64(allocator, ctx.file, ctx.buff);
}

pub fn main() !void {
    var timer = perf.StarTimer("Main");
    defer perf.StopTimer(&timer);

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
        GenerateTemplateFile(to) catch {
            std.debug.print("Could not write out Template to Location", .{});
        };
        return;
    }

    const input = ProcessInputArgs(allocator, args);
    const output = ProcessOutputArgs(args);
    const template = ProcessTemplateArgs(args);
    if (OptionalFuncs.Zip(InputImages, OutputFile, input, output).value) |requiredInputs| {
        const filebuff = try allocator.alloc(u8, GetEncodedImageSize(requiredInputs.m1.Images[0]));
        const filebuff2 = try allocator.alloc(u8, GetEncodedImageSize(requiredInputs.m1.Images[1]));

        var ctx1 = ThreadContext{
            .buff = filebuff,
            .file = requiredInputs.m1.Images[0],
            .out = undefined,
            .threadIdx = 0,
        };
        var t1 = try std.Thread.spawn(.{}, worker, .{&ctx1});

        var ctx2 = ThreadContext{
            .buff = filebuff2,
            .file = requiredInputs.m1.Images[1],
            .out = undefined,
            .threadIdx = 1,
        };
        var t2 = try std.Thread.spawn(.{}, worker, .{&ctx2});

        t1.join();
        t2.join();

        if (template.value) |t| {
            CreateHTMLPageFromTemplate(allocator, t.File, requiredInputs.m2, ctx1.out, ctx2.out) catch {
                std.debug.print("Could not write content to output File", .{});
            };
        } else {
            CreateHTMLPage(allocator, requiredInputs.m2, baseTemplate, ctx1.out, ctx2.out) catch {
                std.debug.print("Could not write content to output File", .{});
            };
        }
    }
}
