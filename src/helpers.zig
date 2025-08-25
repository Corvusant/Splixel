// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const mem = std.mem;
pub const Allocator = std.mem.Allocator;

const ReplacementData = struct {
    size: usize,
    replacementLocation: usize,
};

pub fn gatherReplacementAccelerationData(comptime T: type, input: []const T, needle: []const T, replacement: []const T, offset: usize) ReplacementData {
    // Empty needle will loop forever.
    assert(needle.len > 0);
    @setEvalBranchQuota(100000); // we set this high so we can parse moste base template files

    var i: usize = offset;
    var size: usize = input.len;
    var needleLocation = i;
    while (i < input.len) {
        if (mem.startsWith(T, input[i..], needle)) {
            size = size - needle.len + replacement.len;
            needleLocation = i;
            i += needle.len;
        } else {
            i += 1;
        }
    }

    return ReplacementData{ .size = size, .replacementLocation = needleLocation };
}

pub fn replaceOwned(comptime T: type, allocator: Allocator, input: []const T, needleLength: usize, replacement: []const T, offset: usize, size: usize) Allocator.Error![]T {
    const output = try allocator.alloc(T, size);
    _ = replace(T, input, needleLength, replacement, output, offset);
    return output;
}

//This will only replace the the appareance of the needle at the offset
pub fn replace(comptime T: type, input: []const T, needleLength: usize, replacement: []const T, output: []T, offset: usize) void {
    // Empty needle will loop until output buffer overflows.
    assert(needleLength > 0);

    const postreplacementEnd = offset + replacement.len;
    const prereplacementEnd = offset + needleLength;

    @memcpy(output[0..offset], input[0..offset]);
    @memcpy(output[offset..][0..replacement.len], replacement);
    @memcpy(output[postreplacementEnd..], input[prereplacementEnd..input.len]);
}
