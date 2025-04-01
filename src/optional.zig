pub fn Optional(comptime Domain: type) type {
    return struct {
        value: ?Domain,

        pub fn IsSet() bool {
            return if (.value) {
                return true;
            } else {
                return false;
            };
        }

        pub fn Bind(comptime Codomain: type, comptime func: anytype) ?Optional(Codomain) {
            if (.value) |value| {
                return Optional(Codomain){func(value)};
            } else {
                return null;
            }
        }
    };
}

pub fn Tuple(comptime t1: type, comptime t2: type) type {
    return struct {
        m1: t1,
        m2: t2,
    };
}

pub fn Zip(comptime l: Optional, comptime r: Optional) Optional(Tuple) {
    if (l.value) |lvalue| {
        if (r.value) |rvalue| {
            return Optional(Tuple){.{ .m1 = lvalue, .m2 = rvalue }};
        } else {
            return Optional(Tuple){null};
        }
    } else {
        return Optional(Tuple){null};
    }
}
