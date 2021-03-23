pub usingnamespace @import("std").c.builtins;
pub const uint = c_uint;
pub const ushort = c_ushort;
pub const uchar = u8;
pub const uint8 = u8;
pub const uint16 = c_ushort;
pub const uint32 = c_uint;
pub const uint64 = c_ulong;
pub const pde_t = uint64;

// which hart (core) is this?
pub export fn r_mhartid() uint64 {
    return asm volatile ("csrr %[ret], mhartid"
        : [ret] "={x10}" (-> uint64)
    );
}

// Machine Status Register, mstatus
pub const MSTATUS_MPP_MASK = @as(c_long, 3) << 11; // previous mode.
pub const MSTATUS_MPP_M = @as(c_long, 3) << 11;
pub const MSTATUS_MPP_S = @as(c_long, 1) << 11;
pub const MSTATUS_MPP_U = @as(c_long, 0) << 11;
pub const MSTATUS_MIE = @as(c_long, 1) << 3; // machine-mode interrupt enable.
pub export fn r_mstatus() uint64 {
    return asm volatile ("csrr %[ret], mstatus"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_mstatus(x: uint64) void {
    asm volatile ("csrw mstatus, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// machine exception program counter, holds the
// instruction address to which a return from
// exception will go.
pub export fn w_mepc(x: uint64) void {
    asm volatile ("csrw mepc, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Supervisor Status Register, sstatus
pub const SSTATUS_SPP = @as(c_long, 1) << 8; // Previous mode, 1=Supervisor, 0=User
pub const SSTATUS_SPIE = @as(c_long, 1) << 5; // Supervisor Previous Interrupt Enable
pub const SSTATUS_UPIE = @as(c_long, 1) << 4; // User Previous Interrupt Enable
pub const SSTATUS_SIE = @as(c_long, 1) << 1; // Supervisor Interrupt Enable
pub const SSTATUS_UIE = @as(c_long, 1) << 0; // User Interrupt Enable
pub export fn r_sstatus() uint64 {
    return asm volatile ("csrr %[ret], sstatus"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_sstatus(x: uint64) void {
    asm volatile ("csrw sstatus, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Supervisor Interrupt Pending
pub export fn r_sip() uint64 {
    return asm volatile ("csrr %[ret], sip"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_sip(x: uint64) void {
    asm volatile ("csrw sip, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Supervisor Interrupt Enable
pub const SIE_SEIE = @as(c_long, 1) << 9; // external
pub const SIE_STIE = @as(c_long, 1) << 5; // timer
pub const SIE_SSIE = @as(c_long, 1) << 1; // software
pub export fn r_sie() uint64 {
    return asm volatile ("csrr %[ret], sie"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_sie(x: uint64) void {
    asm volatile ("csrw sie, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Machine-mode Interrupt Enable
pub const MIE_MEIE = @as(c_long, 1) << 11; // external
pub const MIE_MTIE = @as(c_long, 1) << 7; // timer
pub const MIE_MSIE = @as(c_long, 1) << 3; // software
pub export fn r_mie() uint64 {
    return asm volatile ("csrr %[ret], mie"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_mie(x: uint64) void {
    asm volatile ("csrw mie, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// machine exception program counter, holds the
// instruction address to which a return from
// exception will go.
pub export fn r_sepc() uint64 {
    return asm volatile ("csrr %[ret], sepc"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_sepc(x: uint64) void {
    asm volatile ("csrw sepc, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Machine Exception Delegation
pub export fn r_medeleg() uint64 {
    return asm volatile ("csrr %[ret], medeleg"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_medeleg(x: uint64) void {
    asm volatile ("csrw medeleg, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Machine Interrupt Delegation
pub export fn r_mideleg() uint64 {
    return asm volatile ("csrr %[ret], mideleg"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_mideleg(x: uint64) void {
    asm volatile ("csrw mideleg, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

pub export fn r_stvec() uint64 {
    return asm volatile ("csrr %[ret], stvec"
        : [ret] "={x10}" (-> uint64)
    );
}

/// Supervisor Trap-Vector Base Address
/// low two bits are mode.
pub export fn w_stvec(x: uint64) void {
    asm volatile ("csrw stvec, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Machine-mode interrupt vector
pub export fn w_mtvec(x: uint64) void {
    asm volatile ("csrw mtvec, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// use riscv's sv39 page table scheme.
pub const SATP_SV39 = @as(c_long, 8) << 60;

pub fn MAKE_SATP(pagetable: anytype) callconv(.Inline) @TypeOf(SATP_SV39 | ((@import("std").meta.cast(uint64, pagetable)) >> 12)) {
    return SATP_SV39 | ((@import("std").meta.cast(uint64, pagetable)) >> 12);
}

// supervisor address translation and protection;
// holds the address of the page table.
pub export fn w_satp(x: uint64) void {
    asm volatile ("csrw satp, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

pub export fn r_satp() uint64 {
    return asm volatile ("csrr %[ret], satp"
        : [ret] "={x10}" (-> uint64)
    );
}

// Supervisor Scrath register, for early trap handler in trampoline.S.
pub export fn w_sscratch(x: uint64) void {
    asm volatile ("csrw sscratch, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

pub export fn w_mscratch(x: uint64) void {
    asm volatile ("csrw mscratch, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// Supervisor Trap Cause
pub export fn r_scause() uint64 {
    return asm volatile ("csrr %[ret], scause"
        : [ret] "={x10}" (-> uint64)
    );
}

// Supervisor Trap Value
pub export fn r_stval() uint64 {
    return asm volatile ("csrr %[ret], stval"
        : [ret] "={x10}" (-> uint64)
    );
}

// Machine-mode Counter-Enable
pub export fn w_mcounteren(x: uint64) void {
    asm volatile ("csrw mcounteren, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

// machine-mode cycle counter
pub export fn r_time() uint64 {
    return asm volatile ("csrr %[ret], time"
        : [ret] "={x10}" (-> uint64)
    );
}

// enable device interrupts
pub fn intr_on() callconv(.C) void {
    w_sstatus((r_sstatus() | @bitCast(c_ulong, (@as(c_long, 1) << @intCast(@import("std").math.Log2Int(c_long), 1)))));
}

// disable device interrupts
pub fn intr_off() callconv(.C) void {
    w_sstatus((r_sstatus() & @bitCast(c_ulong, ~(@as(c_long, 1) << @intCast(@import("std").math.Log2Int(c_long), 1)))));
}

// are device interrupts enabled?
pub fn intr_get() callconv(.C) c_int {
    var x: uint64 = r_sstatus();
    return @boolToInt(((x & @bitCast(c_ulong, (@as(c_long, 1) << @intCast(@import("std").math.Log2Int(c_long), 1)))) != @bitCast(c_ulong, @as(c_long, @as(c_int, 0)))));
}

pub export fn r_sp() uint64 {
    return asm volatile ("mv %[ret], sp"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn r_tp() uint64 {
    return asm volatile ("mv %[ret], tp"
        : [ret] "={x10}" (-> uint64)
    );
}

pub export fn w_tp(x: uint64) void {
    asm volatile ("mv tp, %[x]"
        :
        : [x] "{x10}" (x)
    );
}

pub export fn r_ra() uint64 {
    return asm volatile ("mv %[ret], ra"
        : [ret] "={x10}" (-> uint64)
    );
}

// flush the TLB.
pub export fn sfence_vma() void {
    // the zero, zero means flush all TLB entries.
    asm volatile ("sfence.vma zero, zero");
}

pub const PGSIZE = 4096; // bytes per page
pub const PGSHIFT = 12; // bits of offest within a page

pub fn PGROUNDUP(sz: anytype) callconv(.Inline) @TypeOf(((sz + PGSIZE) - 1) & ~(PGSIZE - 1)) {
    return ((sz + PGSIZE) - 1) & ~(PGSIZE - 1);
}

pub fn PGROUNDDOWN(a: anytype) callconv(.Inline) @TypeOf(a & ~(PGSIZE - 1)) {
    return a & ~(PGSIZE - 1);
}

pub const PTE_V = @as(c_long, 1) << 0; // valid
pub const PTE_R = @as(c_long, 1) << 1;
pub const PTE_W = @as(c_long, 1) << 2;
pub const PTE_X = @as(c_long, 1) << 3;
pub const PTE_U = @as(c_long, 1) << 4; // 1 -> user can access

// shifts a physical address to the right place for a PIE.
pub fn PA2PTE(pa: anytype) callconv(.Inline) @TypeOf(((@import("std").meta.cast(uint64, pa)) >> 12) << 10) {
    return ((@import("std").meta.cast(uint64, pa)) >> 12) << 10;
}

pub fn PTE2PA(pte: anytype) callconv(.Inline) @TypeOf((pte >> 10) << 12) {
    return (pte >> 10) << 12;
}

pub fn PTE_FLAGS(pte: anytype) callconv(.Inline) @TypeOf(pte & 0x3FF) {
    return pte & 0x3FF;
}

// extract the three 9-bit page table indices from a virtual address.
pub const PXMASK = 0x1FF; // 9 bits
pub fn PXSHIFT(level: anytype) callconv(.Inline) @TypeOf(PGSHIFT + (9 * level)) {
    return PGSHIFT + (9 * level);
}
pub fn PX(level: anytype, va: anytype) callconv(.Inline) @TypeOf(((@import("std").meta.cast(uint64, va)) >> PXSHIFT(level)) & PXMASK) {
    return ((@import("std").meta.cast(uint64, va)) >> PXSHIFT(level)) & PXMASK;
}

// one beyond the highest possible virtual address.
// MAXVA is actually one bit less than the max allowed by
// Sv39, to avoid having to sign-extend virtual addresses
// that have the high bit set.
pub const MAXVA = @as(c_long, 1) << ((((9 + 9) + 9) + 12) - 1);

pub const pte_t = uint64;
pub const pagetable_t = [*c]uint64; // 512 PTEs
