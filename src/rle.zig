// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");

pub fn encode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (input.len <= 0)
        return "";

    var encodedString = std.ArrayList(u8).init(allocator);
    var count: u8 = 1;

    for (input, 0..) |char, index| {
        if (index + 1 >= input.len) {
            var buf: [2]u8 = undefined;
            const str = try std.fmt.bufPrint(&buf, "{c}{c}", .{ count, char });
            try encodedString.append(str[0]);
            try encodedString.append(str[1]);
            count = 0;
            continue;
        }

        if (input[index + 1] == char and count < 9) {
            count += 1;
        } else {
            var buf: [2]u8 = undefined;
            const str = try std.fmt.bufPrint(&buf, "{c}{c}", .{ count, char });
            try encodedString.append(str[0]);
            try encodedString.append(str[1]);
            count = 1;
        }
    }

    return encodedString.items;
}

pub fn decode(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (input.len <= 0)
        return "";

    var decodedString = std.ArrayList(u8).init(allocator);
    var i: usize = 0;
    while (i < input.len) : (i += 2) {
        const count = input[i];
        const character = input[i + 1];
        for (0..count) |_| {
            try decodedString.append(character);
        }
    }

    return decodedString.items;
}
