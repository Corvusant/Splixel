// Copyright (c) 2025 Josua Kucher All rights reserved.

//Compiletime Flags
const config = @import("config");

//std
const std = @import("std");

const OptionalFuncs = @import("optional.zig");
const Optional = @import("optional.zig").Optional;
const perf = @import("perftimer.zig");

pub fn TryOpenFileFromPath(path: []const u8, flags: std.fs.File.OpenFlags) Optional(std.fs.File) {
    var timer = if (comptime config.profiling) perf.StartTimer("TryOpenFileFromPath");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    const file = std.fs.openFileAbsolute(path, flags) catch {
        std.debug.print("File {s} cannot be opened. Check the Path.\n", .{path});
        return Optional(std.fs.File).None();
    };

    return Optional(std.fs.File).Init(file);
}

pub fn TryCreateFileFromPath(path: []const u8) Optional(std.fs.File) {
    var timer = if (comptime config.profiling) perf.StartTimer("TryCreateFileFromPath");
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    const file = std.fs.createFileAbsolute(path, .{}) catch {
        std.debug.print("File {s} cannot be Created. Check the Path.\n", .{path});
        return Optional(std.fs.File).None();
    };

    return Optional(std.fs.File).Init(file);
}

pub fn IsPathFolderValid(path: []const u8) bool {
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

pub fn IsValidFile(filename: []const u8, extensionFilter: [][]const u8) bool {
    for (extensionFilter) |extension| {
        if (std.mem.count(u8, filename, extension) > 0)
            return true;
    }
    return false;
}
