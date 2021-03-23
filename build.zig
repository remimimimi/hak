const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const fs = std.fs;
const mem = std.mem;

const riscv64 = CrossTarget{
    .cpu_arch = .riscv64,
    .os_tag = .freestanding,
};

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{ .whitelist = &[_]CrossTarget{riscv64}, .default_target = riscv64 });

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // const arch_root = "src/arch";
    // const arch = switch (target.getCpuArch()) {
    //     .i386 => "x86",
    //     else => unreachable,
    // };
    // const linker_script_path = try fs.path.join(b.allocator, &[_][]const u8{ arch_root, arch, "linker.ld" });

    const kernel = b.addExecutable("kernel", "src/kmain.zig");
    kernel.setTarget(target);
    kernel.setBuildMode(mode);
    kernel.setLinkerScriptPath("src/kernel.ld");
    kernel.setOutputDir(b.cache_root);
    kernel.install();

    const kernel_output_path = kernel.getOutputPath();

    b.default_step.dependOn(&kernel.step);

    // Commands
    const run = b.step("run", "Run os with qemu");
    const qemu_cmd = b.addSystemCommand(&[_][]const u8{ "qemu-system-riscv64", "-kernel", kernel_output_path });
    qemu_cmd.step.dependOn(b.default_step);
    run.dependOn(&qemu_cmd.step);
}

fn buildMkfs(b: *Builder, target: CrossTarget, mode: builtin.Mode) LibExeObjStep {
    const mkfs_exec = b.addExecutable("mkfs", "mkfs/mkfs.c");
    mkfs_exec.setTarget(target);
    mkfs_exec.setBuildMode(mode);
    mkfs_exec.setOutputDir(b.cache_root);
    mkfs_exec.install();
    return mkfs_exec;
}

fn buildFsImg(b: *Builder, target: CrossTarget, mode: builtin.Mode) void {
    const user_progs = &[_][]const u8{
        "user/_cat\\",
        "user/_echo\\",
        "user/_forktest\\",
        "user/_grep\\",
        "user/_init\\",
        "user/_kill\\",
        "user/_ln\\",
        "user/_ls\\",
        "user/_mkdir\\",
        "user/_rm\\",
        "user/_sh\\",
        "user/_stressfs\\",
        "user/_usertests\\",
        "user/_grind\\",
        "user/_wc\\",
        "user/_zombie\\",
    };
    const mk_fs_img_cmd = b.addSystemCommand(&[_][]const u8{ "mkfs/mkfs", "fs.img", "README.md" } ++ user_progs);
    mk_fs_img_cmd.dependOn(&buildMkfs().step);
}

// pub const BuildContext = struct {
//     linker_script_path: []const u8,

//     pub fn init() BuildContext {

//     }
// };

// fn buildKernel(b: *Builder) ![]const u8 {
//     const target = b.standardTargetOptions(.{ .whitelist = &[_]CrossTarget{x86_i686}, .default_target = x86_i686 });

//     // Standard release options allow the person running `zig build` to select
//     // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
//     const mode = b.standardReleaseOptions();

//     const arch_root = "src/arch";
//     const arch = switch (target.getCpuArch()) {
//         .i386 => "x86",
//         else => unreachable,
//     };

//     const linker_script_path = try fs.path.join(b.allocator, &[_][]const u8{ arch_root, arch, "linker.ld" });
//     const kernel = b.addExecutable("kernel", "src/kmain.zig");
//     kernel.setTarget(target);
//     kernel.setBuildMode(mode);
//     kernel.setLinkerScriptPath(linker_script_path);
//     kernel.install();

//     b.default_step.dependOn(&kernel.step);
//     return kernel.getOutputPath();
// }
