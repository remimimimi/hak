pub usingnamespace @import("std").c.builtins;

pub const rtcdate = extern struct {
    second: c_uint,
    minute: c_uint,
    hour: c_uint,
    day: c_uint,
    month: c_uint,
    year: c_uint,
};
