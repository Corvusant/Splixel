// Copyright (c) 2025 Josua Kucher All rights reserved.

//Compiletime Flags
const config = @import("config");

//standard library
const std = @import("std");

const encoding = @import("imageEncoding.zig");
const perf = @import("perftimer.zig");

pub const ThreadContext = struct { buff: []u8, file: std.fs.File, out: []const u8, threadIdx: u8 };

pub fn worker(ctx: *ThreadContext) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    const timerName = if (comptime config.profiling) std.fmt.allocPrint(
        allocator,
        "Encode {}",
        .{ctx.threadIdx},
    ) catch {
        return;
    };

    var timer = if (comptime config.profiling) perf.StartTimer(timerName);
    defer if (comptime config.profiling) perf.StopTimer(&timer);

    const encodedImage = encoding.ConvertImageToBas64(allocator, ctx.file, ctx.buff);
    ctx.out = encodedImage;
}
