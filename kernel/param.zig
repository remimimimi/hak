pub usingnamespace @import("std").c.builtins;

pub const NPROC = 64; // maxium number of processes
pub const NCPU = 8; // maximum number of CPUs
pub const NOFILE = 16; // open files per process
pub const NFILE = 100; // open files per system
pub const NINODE = 50; // maximum number of active i-nodes
pub const NDEV = 10; // maximum major device number
pub const ROOTDEV = 1; // device number of file system root disk
pub const MAXARG = 32; // max exec arguments
pub const MAXOPBLOCKS = 10; // max # of blocks any FS op writes
pub const LOGSIZE = MAXOPBLOCKS * 3; // max data blocks in on-disk log
pub const NBUF = MAXOPBLOCKS * 3; // size of disk block cache
pub const FSSIZE = 1000; // size of file system in blocks
pub const MAXPATH = 128; // maximum file path name
