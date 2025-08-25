// Copyright (c) 2025 Josua Kucher All rights reserved.

//Compiletime Flags
const config = @import("config");

//std
const std = @import("std");

pub const InputFiles = struct { Images: [2]std.fs.File };

pub const TemplateFile = struct {
    File: std.fs.File,
};

pub const OutputFile = struct {
    File: []const u8,
};
