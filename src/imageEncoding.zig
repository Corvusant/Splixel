// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");
const debug = std.debug;
const mem = std.mem;

pub fn ConvertImageToBas64(allocator: std.mem.Allocator, file: std.fs.File, fileBuf: []u8) []const u8 {
    const Encoder = std.base64.standard.Encoder;
    const filesize = file.getEndPos() catch {
        return "";
    };

    const filecontent = file.readToEndAlloc(allocator, filesize) catch {
        return "";
    };

    return Encoder.encode(fileBuf, filecontent);
}

pub fn GetEncodedImageSize(file: std.fs.File) usize {
    const Encoder = std.base64.standard.Encoder;
    const filesize = file.getEndPos() catch {
        return 0;
    };

    return Encoder.calcSize(filesize);
}
