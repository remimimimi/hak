// Format of an ELF executable file
pub usingnamespace @import("std").c.builtins;

pub const ELF_MAGIC = @as(c_uint, 0x464C457F); // "\x7FELF" in little endian

// File header
pub const elfhdr = extern struct {
    magic: c_uint, // must equal ELF_MAGIC
    elf: [12]u8,
    @"type": c_ushort,
    machine: c_ushort,
    version: c_uint,
    entry: c_ulong,
    phoff: c_ulong,
    shoff: c_ulong,
    flags: c_uint,
    ehsize: c_ushort,
    phentsize: c_ushort,
    phnum: c_ushort,
    shentsize: c_ushort,
    shnum: c_ushort,
    shstrndx: c_ushort,
};

// Program section header
pub const proghdr = extern struct {
    type: c_uint,
    flags: c_uint,
    off: c_ulong,
    vaddr: c_ulong,
    paddr: c_ulong,
    filesz: c_ulong,
    memsz: c_ulong,
    @"align": c_ulong,
};

// Values of Proghdr type
pub const ELF_PROG_LOAD = 1;

// Flag bits for Proghdr flags
pub const ELF_PROG_FLAG_EXEC = 1;
pub const ELF_PROG_FLAG_WRITE = 2;
pub const ELF_PROG_FLAG_READ = 4;
