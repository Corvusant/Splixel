// Copyright (c) 2025 Josua Kucher All rights reserved.

const std = @import("std");

pub fn Optional(comptime Domain: type) type {
    return struct {
        value: ?Domain,
        const Self = @This();

        pub fn None() Self {
            return Self{ .value = null };
        }

        pub fn Init(v: Domain) Self {
            return Self{ .value = v };
        }

        pub fn IsSet(self: Self) bool {
            return if (self.value) |_| {
                return true;
            } else {
                return false;
            };
        }

        pub fn Bind(self: Self, comptime Codomain: type, comptime func: anytype) Optional(Codomain) {
            if (self.value) |value| {
                return Optional(Codomain).Init(func(value));
            } else {
                return Optional(Codomain).None();
            }
        }

        //Allows to run a function on the Optional content, cannot capture
        pub fn Iter(comptime func: anytype) void {
            if (.value) |value| {
                func(value);
            } else {}
        }

        pub fn Flatten(comptime Codomain: type, comptime setFunc: anytype, comptime unsetFunc: anytype) Codomain {
            return if (.value) |value| setFunc(value) else unsetFunc();
        }
    };
}

pub fn Tuple(comptime t1: type, comptime t2: type) type {
    return struct {
        m1: t1,
        m2: t2,
    };
}

pub fn Zip(comptime t1: type, comptime t2: type, l: Optional(t1), r: Optional(t2)) Optional(Tuple(t1, t2)) {
    if (l.value) |lvalue| {
        if (r.value) |rvalue| {
            return Optional(Tuple(t1, t2)).Init(.{ .m1 = lvalue, .m2 = rvalue });
        } else {
            return Optional(Tuple(t1, t2)).None();
        }
    } else {
        return Optional(Tuple(t1, t2)).None();
    }
}
