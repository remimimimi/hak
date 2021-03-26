#![no_std]
#![no_main]
#![feature(panic_info_message, asm, global_asm)]

pub mod arch;
pub mod uart;

#[macro_export]
macro_rules! print {
    ($($args:tt)+) => ({
        use core::fmt::Write;
        let _ = write!(crate::uart::UartDriver::new(0x1000_0000), $($args)+);
    });
}
#[macro_export]
macro_rules! println {
    () => ({
        print!("\n")
    });
    ($fmt:expr) => ({
        print!(concat!($fmt, "\n"))
    });
    ($fmt:expr, $($args:tt)+) => ({
        print!(concat!($fmt, "\n"), $($args)+)
    });
}

#[no_mangle]
extern "C" fn kmain() {
    let mut my_uart = uart::UartDriver::new(0x1000_0000);
    my_uart.init();

    println!("Hello, world!");
    // println!("Test output for tiny riscv os");

    loop {
        if let Some(c) = my_uart.get() {
            match c {
                8 => print!("BACKSPACE:{}{}{}end", 8 as char, ' ', 8 as char),
                10 | 13 => println!(),
                0x1b => {
                    if let Some(next_byte) = my_uart.get() {
                        if next_byte == 91 {
                            if let Some(b) = my_uart.get() {
                                match b as char {
                                    'A' => println!("That's the up arrow!"),
                                    'B' => println!("That's the down arrow!"),
                                    'C' => println!("That's the right arrow!"),
                                    'D' => println!("That's the left arrow!"),
                                    _ => println!("That's something else..."),
                                }
                            }
                        }
                    }
                }
                _ => print!("{}", c as char),
            }
        }
    }
}

#[no_mangle]
extern "C" fn eh_personality() {}

#[panic_handler]
fn panic(info: &core::panic::PanicInfo) -> ! {
    print!("Aborting: ");
    // NOTE: without underscore rust cause warning
    if let Some(_location) = info.location() {
        println!(
            "{}:{} happend {}",
            _location.file(),
            _location.line(),
            info.message().unwrap()
        )
    } else {
        println!("no information available");
    }

    abort();
}

#[no_mangle]
extern "C" fn abort() -> ! {
    loop {
        unsafe {
            asm!("wfi");
        }
    }
}
