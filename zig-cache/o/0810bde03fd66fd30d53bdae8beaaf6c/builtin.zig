usingnamespace @import("std").builtin;
/// Deprecated
pub const arch = Target.current.cpu.arch;
/// Deprecated
pub const endian = Target.current.cpu.arch.endian();

/// Zig version. When writing code that supports multiple versions of Zig, prefer
/// feature detection (i.e. with `@hasDecl` or `@hasField`) over version checks.
pub const zig_version = try @import("std").SemanticVersion.parse("0.8.0-dev.1142+153cd4da0");

pub const output_mode = OutputMode.Exe;
pub const link_mode = LinkMode.Static;
pub const is_test = false;
pub const single_threaded = false;
pub const abi = Abi.eabi;
pub const cpu: Cpu = Cpu{
    .arch = .i386,
    .model = &Target.x86.cpu._i686,
    .features = Target.x86.featureSet(&[_]Target.x86.Feature{
        .@"cmov",
        .@"cx8",
        .@"slow_unaligned_mem_16",
        .@"vzeroupper",
        .@"x87",
    }),
};
pub const os = Os{
    .tag = .freestanding,
    .version_range = .{ .none = {} }
};
pub const object_format = ObjectFormat.elf;
pub const mode = Mode.Debug;
pub const link_libc = false;
pub const link_libcpp = false;
pub const have_error_return_tracing = true;
pub const valgrind_support = false;
pub const position_independent_code = false;
pub const position_independent_executable = false;
pub const strip_debug_info = false;
pub const code_model = CodeModel.default;
