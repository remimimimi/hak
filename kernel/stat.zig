pub usingnamespace @import("std").c.builtins;

pub const T_DIR = 1; // Directory
pub const T_FILE = 2; // File
pub const T_DEVICE = 3; // Device

pub const stat = extern struct {
    dev: c_int, // File system's disk device
    ino: c_uint, // i-node number
    @"type": c_short, // Type of file
    nlink: c_short, // Number of links to file
    size: c_ulong // Size of file in bytes
};
