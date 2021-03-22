const std = @import("std");
const Builder = @import("std").build.Builder;
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const fs = std.fs;

const x86_i686 = CrossTarget{
    .cpu_arch = .i386,
    .os_tag = .freestanding,
    .cpu_model = .{ .explicit = &Target.x86.cpu._i686 },
};

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{ .whitelist = &[_]CrossTarget{x86_i686}, .default_target = x86_i686 });

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const arch_root = "src/arch";
    const arch = switch (target.getCpuArch()) {
        .i386 => "x86",
        else => unreachable,
    };
    const linker_script_path = try fs.path.join(b.allocator, &[_][]const u8{ arch_root, arch, "linker.ld" });

    const kernel = b.addExecutable("kernel", "src/kmain.zig");
    kernel.setTarget(target);
    kernel.setBuildMode(mode);
    kernel.setLinkerScriptPath(linker_script_path);
    kernel.setOutputDir(b.cache_root);
    kernel.install();

    const kernel_output_path = kernel.getOutputPath();

    b.default_step.dependOn(&kernel.step);

    // Commands
    const run = b.step("run", "Run os with qemu");
    const qemu_cmd = b.addSystemCommand(&[_][]const u8{ "qemu-system-i386", "-kernel", kernel_output_path });
    qemu_cmd.step.dependOn(b.default_step);
    run.dependOn(&qemu_cmd.step);
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
