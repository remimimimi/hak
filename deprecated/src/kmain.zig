const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, kmain, .{});

    while (true) {}
}

pub var vga = VGA{
    .vram = @intToPtr([*]VGAEntry, 0xb8000)[0..0x4000],
    // .vram = @intToPtr(*[VGA_SIZE]VGAEntry, vram),
    .cursor = 0,
    .foreground = Color.White,
    .background = Color.Black,
};

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    // var vga = VGA.init(VRAM_ADDR);
    @setCold(true);
    vga.writeString("KERNEL PANIC: ");
    vga.writeString(msg);
    while (true) {}
}

pub fn kmain() void {
    // var vga = VGA.init(VRAM_ADDR);
    vga.clear();
    vga.writeString("Hello world!");
    // WRITER.clear();
    // WRITER.writeByte('H');
}

const VRAM_ADDR = 0xb8000;
const VRAM_SIZE = 0x8000;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

pub const Color = enum(u4) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

pub const VGAEntry = packed struct {
    char: u8,
    foreground: Color,
    background: Color,
};

pub const VGA = struct {
    vram: []VGAEntry,
    cursor: usize,
    foreground: Color,
    background: Color,

    ////
    // Initialize the VGA status.
    //
    // Arguments:
    //     vram: The address of the VRAM buffer.
    //
    // Returns:
    //     A structure holding the VGA status.
    //
    pub fn init(vram: usize) VGA {
        return VGA{
            .vram = @intToPtr([*]VGAEntry, vram)[0..0x4000],
            // .vram = @intToPtr(*[VGA_SIZE]VGAEntry, vram),
            .cursor = 0,
            .foreground = Color.White,
            .background = Color.Black,
        };
    }

    ////
    // Clear the screen.
    //
    pub fn clear(self: *VGA) void {
        mem.set(VGAEntry, self.vram[0..VGA_SIZE], self.entry(' '));

        self.cursor = 0;
    }

    ////
    // Print a character to the screen.
    //
    // Arguments:
    //     char: Character to be printed.
    //
    fn writeChar(self: *VGA, char: u8) void {
        if (self.cursor == VGA_WIDTH * VGA_HEIGHT - 1) {
            self.scrollDown();
        }

        switch (char) {
            // Newline.
            '\n' => {
                self.writeChar(' ');
                while (self.cursor % VGA_WIDTH != 0)
                    self.writeChar(' ');
            },
            // Tab.
            '\t' => {
                self.writeChar(' ');
                while (self.cursor % 4 != 0)
                    self.writeChar(' ');
            },
            // Backspace.
            // FIXME: hardcoded 8 here is horrible.
            '\x08' => {
                // self.cursor -= 1;
                // self.writeChar(' ');
                // self.cursor -= 1;
                self.cursor -= 1;
                self.vram[self.cursor] = self.entry(char);
            },
            // Any other character.
            else => {
                self.vram[self.cursor] = self.entry(char);
                self.cursor += 1;
            },
        }
    }

    ////
    // Print a string to the screen.
    //
    // Arguments:
    //     string: String to be printed.
    //
    pub fn writeString(self: *VGA, string: []const u8) void {
        for (string) |char| {
            self.writeChar(char);
        }
    }

    ////
    // Scroll the screen one line down.
    //
    fn scrollDown(self: *VGA) void {
        const first = VGA_WIDTH; // Index of first line.
        const last = VGA_SIZE - VGA_WIDTH; // Index of last line.

        // Copy all the screen (apart from the first line) up one line.
        mem.copy(VGAEntry, self.vram[0..last], self.vram[first..VGA_SIZE]);
        // Clean the last line.
        mem.set(VGAEntry, self.vram[last..VGA_SIZE], self.entry(' '));

        // Bring the cursor back to the beginning of the last line.
        self.cursor -= VGA_WIDTH;
    }

    ////
    // Build a VGAEntry with current foreground and background.
    //
    // Arguments:
    //     char: The character of the entry.
    //
    // Returns:
    //     The requested VGAEntry.
    //
    fn entry(self: *VGA, char: u8) VGAEntry {
        return VGAEntry{
            .char = char,
            .foreground = self.foreground,
            .background = self.background,
        };
    }
};
// export fn kmain() noreturn {}
