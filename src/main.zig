//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    for (args, 0..) |arg, i| {
        std.debug.print("{}: {s}\n", .{ i, arg });

        const filePath = std.fs.path.basenameWindows(arg);
        var file = try std.fs.cwd().openFile(filePath, .{ .mode = .read_only });
        defer file.close();
    }
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("ImageDiffer_lib");
