// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");
const OptionalFuncs = @import("optional");
const Optional = @import("optional").Optional;
const Tuple = @import("optional").Tuple;

const baseTemplate = "<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><style>body{background-color:#343939;margin:0;height:100%}.wrapper{display:flex;top:50px;align-items:center;justify-content:center}.container{position:absolute;top:50px;border:5px solid #ffcb70;border-radius:2%;overflow:hidden}.sliderHandle{position:absolute;z-index:9;cursor:ew-resize;width:25px;height:25px;background-color:#ffcb70;border-radius:50%;opacity:.7}.sliderLine{position:absolute;z-index:8;cursor:ew-resize;width:3px;background-color:#ffcb70;opacity:.7}.img{position:absolute;width:auto;height:auto;overflow:hidden}.img img{display:block;vertical-align:middle}</style><script>var sliderHandle,sliderLine,overlayImage,container,x=0,i=0,clicked=0,w=0,h=0;function ToCssDimensionPx(e){return e+\"px\"}function SetupSlider(e,i){halfWidth=e/2,halfHeight=i/2,sliderHandle=document.getElementsByClassName(\"sliderHandle\")[0],(sliderLine=document.getElementsByClassName(\"sliderLine\")[0]).style.height=ToCssDimensionPx(i),sliderHandle.style.top=ToCssDimensionPx(halfHeight-sliderHandle.offsetHeight/2),sliderHandle.style.left=ToCssDimensionPx(halfWidth-sliderHandle.offsetWidth/2),sliderLine.style.top=ToCssDimensionPx(halfHeight-sliderLine.offsetHeight/2),sliderLine.style.left=ToCssDimensionPx(halfWidth-sliderLine.offsetWidth/2),sliderHandle.addEventListener(\"mousedown\",slideReady),sliderLine.addEventListener(\"mousedown\",slideReady),sliderHandle.addEventListener(\"touchstart\",slideReady),sliderLine.addEventListener(\"touchstart\",slideReady)}function SetupContainer(e,i){(container=document.getElementsByClassName(\"container\")[0]).style.width=ToCssDimensionPx(e),container.style.height=ToCssDimensionPx(i)}function slideReady(e){e.preventDefault(),clicked=1,window.addEventListener(\"mousemove\",slideMove),window.addEventListener(\"touchmove\",slideMove)}function slideFinish(){clicked=0}function slideMove(e){var i;if(0==clicked)return!1;(i=getCursorPos(e))<0&&(i=0),w<i&&(i=w),slide(i)}function getCursorPos(e){var i,n=0;return e=e.changedTouches?e.changedTouches[0]:e,i=overlayImage.getBoundingClientRect(),n=e.pageX-i.left,n-=window.pageXOffset}function slide(e){overlayImage.style.width=ToCssDimensionPx(e),sliderHandle.style.left=ToCssDimensionPx(overlayImage.offsetWidth-sliderHandle.offsetWidth/2),sliderLine.style.left=ToCssDimensionPx(overlayImage.offsetWidth-sliderLine.offsetWidth/2)}function Compare(){var e=document.getElementsByClassName(\"img\");for(i=0;i<e.length;i++)w=Math.max(w,e[i].clientWidth),h=Math.max(h,e[i].clientHeight);(overlayImage=document.getElementsByClassName(\"img-overlay\")[0]).style.width=ToCssDimensionPx(overlayImage.clientWidth),SetupContainer(w,h),SetupSlider(w,h),window.addEventListener(\"mouseup\",slideFinish),window.addEventListener(\"touchend\",slideFinish),slide(w/2)}window.onload=function(){Compare()}</script></head><body><div class=\"wrapper\"><div class=\"container\"><div class=\"img\"><img src=\"data:image/png;base64, <{img-left}>\"></div><div class=\"sliderLine\"></div><div class=\"sliderHandle\"></div><div class=\"img img-overlay\"><img src=\"data:image/png;base64, <{img-right}>\"></div></div></div></body></html>";
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

const help = "IMGDI: is a small utility for creating html pages with embedded 2 images conainting diffing functionality\n  -h|-help|-?|?: prints arguments and help\n  -idir [directory path]: input directory to fetch images from (cannot be used with -ifile)\n  -ifile [filepath] [filepath]: images to use (cannot be used with -idir)\n  -o [filepath]: outoutfile to use (file will be created if it does not exist, missing directories will NOT be created)\n  -t [filepath]: otpional html template file to use, default will be used if none is provided";
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
    const templateWithImg1 = try std.mem.replaceOwned(u8, allocator, baseTemplate, leftImageMarker, encodedImage1);
    const completedFile = try std.mem.replaceOwned(u8, allocator, templateWithImg1, rightImageMarker, encodedImage2);
    if (TryCreateFileFromPath(outputfile.File).value) |file| {
        try file.writeAll(completedFile);
    } else {
        if (TryOpenFileFromPath(outputfile.File, .{}).value) |file| {
            try file.writeAll(completedFile);
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

    if (FindAndPrintHelp(args))
        return;

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
