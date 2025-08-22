// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");

const PerfTimer = struct {
    name: []const u8,
    timer: std.time.Timer,
};

pub fn StartTimer(name: []const u8) PerfTimer {
    const timer = std.time.Timer.start() catch {
        return .{ .name = name, .timer = undefined };
    };

    return .{ .name = name, .timer = timer };
}

pub fn StopTimer(timer: *PerfTimer) void {
    const nanoSeconds = timer.timer.lap();
    const milliSeconds = @as(f64, @floatFromInt(nanoSeconds)) / 1e6;
    std.debug.print("{s}: {d:.3}\n", .{ timer.name, milliSeconds });
}
