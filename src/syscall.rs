//! # Syscall
//! We should implement some system calls for compatability with libgloss and
//! respectivly with newlib. So there's list of libgloss syscalls
//! ```
//! // These system call numbers come from libgloss so that we can use newlib
//! // for our system calls.
//! // Libgloss wants the system call number in A7 and arguments in A0..A6
//! #define SYS_getcwd 17
//! #define SYS_dup 23
//! #define SYS_fcntl 25
//! #define SYS_faccessat 48
//! #define SYS_chdir 49
//! #define SYS_openat 56
//! #define SYS_close 57
//! #define SYS_getdents 61
//! #define SYS_lseek 62
//! #define SYS_read 63
//! #define SYS_write 64
//! #define SYS_writev 66
//! #define SYS_pread 67
//! #define SYS_pwrite 68
//! #define SYS_fstatat 79
//! #define SYS_fstat 80
//! #define SYS_exit 93
//! #define SYS_exit_group 94
//! #define SYS_kill 129
//! #define SYS_rt_sigaction 134
//! #define SYS_times 153
//! #define SYS_uname 160
//! #define SYS_gettimeofday 169
//! #define SYS_getpid 172
//! #define SYS_getuid 174
//! #define SYS_geteuid 175
//! #define SYS_getgid 176
//! #define SYS_getegid 177
//! #define SYS_brk 214
//! #define SYS_munmap 215
//! #define SYS_mremap 216
//! #define SYS_mmap 222
//! #define SYS_open 1024
//! #define SYS_link 1025
//! #define SYS_unlink 1026
//! #define SYS_mkdir 1030
//! #define SYS_access 1033
//! #define SYS_stat 1038
//! #define SYS_lstat 1039
//! #define SYS_time 1062
//! #define SYS_getmainvars 2011
//! ```

use alloc::{
    boxed::Box,
    string::String,
};
use core::convert::TryFrom;

use crate::{
    cpu::{
        dump_registers,
        Registers,
        TrapFrame,
    },
    elf,
    fs,
    page::{
        map,
        virt_to_phys,
        EntryBits,
        Table,
        PAGE_SIZE,
    },
    process::{
        add_kernel_process_args,
        delete_process,
        get_by_pid,
        set_sleeping,
        set_waiting,
        PROCESS_LIST,
        PROCESS_LIST_MUTEX,
    },
    virtio::{
        block::block_op,
        gpu,
        input::{
            Event,
            ABS_EVENTS,
            ABS_OBSERVERS,
            KEY_EVENTS,
            KEY_OBSERVERS,
        },
    },
    Buffer,
};

/// Contain all supported system calls
#[repr(usize)]
pub enum Syscall {
    PutChar = 2,
    DumpRegisters = 8,
    Sleep = 10,
    Execv = 11,
    Read = 63,
    _Exit = 93,
    GetPid = 172,
    BlockRead = 180,
    GetFramebuffer = 1000,
    TransferRectangleAndInvalidate = 1001,
    WaitForKeyboardEvents = 1002,
    WaitForAbsEvents = 1004,
    GetTime = 1062,
}

/// Convert [`usize`] to [`Syscall`]
///
/// If value equal to [`Syscall`] descriminant
/// then we return `Ok(Syscall::Variant)` else
/// we return `Err(give_code)``
impl TryFrom<usize> for Syscall {
    type Error = usize;

    fn try_from(syscall: usize) -> Result<Self, Self::Error> {
        match syscall {
            2 => Ok(Self::PutChar),
            8 => Ok(Self::DumpRegisters),
            10 => Ok(Self::Sleep),
            11 => Ok(Self::Execv),
            63 => Ok(Self::Read),
            93 => Ok(Self::_Exit),
            172 => Ok(Self::GetPid),
            180 => Ok(Self::BlockRead),
            1000 => Ok(Self::GetFramebuffer),
            1001 => Ok(Self::TransferRectangleAndInvalidate),
            1002 => Ok(Self::WaitForKeyboardEvents),
            1004 => Ok(Self::WaitForAbsEvents),
            1062 => Ok(Self::GetTime),
            unexpected_syscal => Err(unexpected_syscal),
        }
    }
}

/// Return [`Syscall`] variant descriminant
impl From<Syscall> for usize {
    fn from(syscall: Syscall) -> Self {
        // We can use as because this value always correct and
        // there's no many kinds of conversation, lossy conversions and
        // dangerous coercions.
        syscall as usize
    }
}

/// System calls handler
///
/// [`do_syscall`], is called from trap.rs to invoke a system call. No discernment is
/// made here whether this is a U-mode, S-mode, or M-mode system call.
/// Since we can't do anything unless we dereference the passed pointer,
/// I went ahead and made the entire function unsafe.
/// If we return 0 from this function, the `m_trap` function will schedule
/// the next process--consider this a yield. A non-0 is the program counter
/// we want to go back to.
pub unsafe fn do_syscall(mepc: usize, frame: *mut TrapFrame) -> usize {
    // Libgloss expects the system call number in A7, so let's follow
    // their lead.
    // A7 is X17, so it's register number 17.
    Syscall::try_from((*frame).regs[Registers::A7 as usize]).map_or_else(
        |unexpected_syscall| {
            println!("Unknown syscall number {}", unexpected_syscall);
            0
        },
        |syscall| {
            match syscall {
                Syscall::_Exit => {
                    delete_process((*frame).pid as u16);
                    0
                },
                Syscall::PutChar => {
                    print!("{}", (*frame).regs[Registers::A0 as usize] as u8 as char);
                    0
                },
                Syscall::DumpRegisters => {
                    dump_registers(frame);
                    mepc + 4
                },
                Syscall::Sleep => {
                    set_sleeping((*frame).pid as u16, (*frame).regs[Registers::A0 as usize]);
                    0
                },
                Syscall::Execv => {
                    // A0 = path
                    // A1 = argv
                    let mut path_addr = (*frame).regs[Registers::A0 as usize];
                    // If the MMU is turned on, translate.
                    if (*frame).satp >> 60 != 0 {
                        let p = get_by_pid((*frame).pid as u16);
                        let table = ((*p).get_table_address() as *mut Table).as_ref().unwrap();
                        path_addr = virt_to_phys(table, path_addr).unwrap();
                    }
                    // Our path address here is now a physical address. If it came in virtual,
                    // it is now physical.
                    let path_bytes = path_addr as *const u8;
                    let mut path = String::new();
                    let mut iterator: usize = 0;
                    // I really have to figure out how to change an array of bytes
                    // to a string. For now, this is very C-style and mimics strcpy.
                    loop {
                        let ch = *path_bytes.add(iterator);
                        if ch == 0 {
                            break;
                        }
                        iterator += 1;
                        path.push(ch as char);
                    }
                    // See if we can find the path.
                    if let Ok(inode) = fs::MinixFileSystem::open(8, &path) {
                        let inode_heap = Box::new(inode);
                        // The Box above moves the Inode to a new memory location on the heap.
                        // This needs to be on the heap since we are about to hand over control
                        // to a kernel process.
                        // THERE is an issue here. If we fail somewhere inside the kernel process,
                        // we shouldn't delete our process here. However, since this is asynchronous
                        // our process will still get deleted and the error won't be reported.
                        // We have to make sure we relinquish Box control here by using into_raw.
                        // Otherwise, the Box will free the memory associated with this inode.
                        add_kernel_process_args(exec_func, Box::into_raw(inode_heap) as usize);
                        // This deletes us, which is what we want.
                        delete_process((*frame).pid as u16);
                        0
                    } else {
                        // If we get here, the path couldn't be found, or for some reason
                        // open failed. So, we return -1 and move on.
                        println!("Could not open path '{}'.", path);
                        (*frame).regs[Registers::A0 as usize] = usize::MAX;
                        mepc + 4
                    }
                },
                Syscall::Read => {
                    // This is an asynchronous call. This will get the
                    // process going. We won't hear the answer until
                    // we an interrupt back.
                    // TODO: The buffer is a virtual memory address that
                    // needs to be translated to a physical memory location.
                    // This needs to be put into a process and ran.
                    // The buffer (regs[12]) needs to be translated when ran
                    // from a user process using virt_to_phys. If this turns
                    // out to be a page fault, we need to NOT proceed with
                    // the read!
                    // If the MMU is turned on, we have to translate the
                    // address. Eventually, I will put this code into a
                    // convenient function, but for now, it will show how
                    // translation will be done.
                    let physical_buffer = if (*frame).satp != 0 {
                        let p = get_by_pid((*frame).pid as u16);
                        let table = ((*p).get_table_address() as *mut Table).as_ref().unwrap();
                        let paddr = virt_to_phys(table, (*frame).regs[12]);
                        if paddr.is_none() {
                            (*frame).regs[Registers::A0 as usize] = usize::MAX;
                            return 0;
                        }
                        paddr.unwrap()
                    } else {
                        (*frame).regs[Registers::A2 as usize]
                    };
                    // TODO: Not only do we need to check the buffer, but it
                    // is possible that the buffer spans multiple pages. We
                    // need to check all pages that this might span. We
                    // can't just do paddr and paddr + size, since there
                    // could be a missing page somewhere in between.
                    fs::process_read(
                        (*frame).pid as u16,
                        (*frame).regs[Registers::A0 as usize] as usize,
                        (*frame).regs[Registers::A1 as usize] as u32,
                        physical_buffer as *mut u8,
                        (*frame).regs[Registers::A3 as usize] as u32,
                        (*frame).regs[Registers::A4 as usize] as u32,
                    );
                    // If we return 0, the trap handler will schedule
                    // another process.
                    0
                },
                Syscall::GetPid => {
                    // A0 = pid
                    (*frame).regs[Registers::A0 as usize] = (*frame).pid;
                    0
                },
                Syscall::BlockRead => {
                    set_waiting((*frame).pid as u16);
                    let _ = block_op(
                        (*frame).regs[Registers::A0 as usize],
                        (*frame).regs[Registers::A1 as usize] as *mut u8,
                        (*frame).regs[Registers::A2 as usize] as u32,
                        (*frame).regs[Registers::A3 as usize] as u64,
                        false,
                        (*frame).pid as u16,
                    );
                    0
                },
                // System calls 1000 and above are "special" system calls for our OS. I'll
                // try to mimic the normal system calls below 1000 so that this OS is compatible
                // with libraries.
                Syscall::GetFramebuffer => {
                    // syscall_get_framebuffer(device)
                    let dev = (*frame).regs[Registers::A0 as usize];
                    (*frame).regs[Registers::A0 as usize] = 0;
                    if dev > 0 && dev <= 8 {
                        if let Some(p) = gpu::GPU_DEVICES[dev - 1].take() {
                            let ptr = p.get_framebuffer() as usize;
                            if (*frame).satp >> 60 != 0 {
                                let process = get_by_pid((*frame).pid as u16);
                                let table = ((*process).get_table_address() as *mut Table).as_mut().unwrap();
                                let num_pages = (p.get_width() * p.get_height() * 4) as usize / PAGE_SIZE;
                                for i in 0..num_pages {
                                    let vaddr = 0x3000_0000 + (i << 12);
                                    let paddr = ptr + (i << 12);
                                    map(table, vaddr, paddr, EntryBits::UserReadWrite as i64, 0);
                                }
                                gpu::GPU_DEVICES[dev - 1].replace(p);
                            }
                            (*frame).regs[Registers::A0 as usize] = 0x3000_0000;
                        }
                    }
                    0
                },
                Syscall::TransferRectangleAndInvalidate => {
                    let dev = (*frame).regs[Registers::A0 as usize];
                    let x = (*frame).regs[Registers::A1 as usize] as u32;
                    let y = (*frame).regs[Registers::A2 as usize] as u32;
                    let width = (*frame).regs[Registers::A3 as usize] as u32;
                    let height = (*frame).regs[Registers::A4 as usize] as u32;
                    gpu::transfer(dev, x, y, width, height);
                    0
                },
                Syscall::WaitForKeyboardEvents => {
                    let mut ev = KEY_EVENTS.take().unwrap();
                    let max_events = (*frame).regs[Registers::A1 as usize];
                    let vaddr = (*frame).regs[Registers::A0 as usize] as *const Event;
                    if (*frame).satp >> 60 != 0 {
                        let process = get_by_pid((*frame).pid as u16);
                        let table = ((*process).get_table_address() as *mut Table).as_mut().unwrap();
                        (*frame).regs[Registers::A0 as usize] = 0;
                        for i in 0..if max_events <= ev.len() { max_events } else { ev.len() } {
                            let paddr = virt_to_phys(table, vaddr.add(i) as usize);
                            if paddr.is_none() {
                                break;
                            }
                            let paddr = paddr.unwrap() as *mut Event;
                            *paddr = ev.pop_front().unwrap();
                            (*frame).regs[Registers::A0 as usize] += 1;
                        }
                    }
                    KEY_EVENTS.replace(ev);
                    0
                },
                Syscall::WaitForAbsEvents => {
                    let mut ev = ABS_EVENTS.take().unwrap();
                    let max_events = (*frame).regs[Registers::A1 as usize];
                    let v_addr = (*frame).regs[Registers::A0 as usize] as *const Event;
                    if (*frame).satp >> 60 != 0 {
                        let process = get_by_pid((*frame).pid as u16);
                        let table = ((*process).get_table_address() as *mut Table).as_mut().unwrap();
                        (*frame).regs[Registers::A0 as usize] = 0;
                        for i in 0..if max_events <= ev.len() { max_events } else { ev.len() } {
                            let paddr = virt_to_phys(table, v_addr.add(i) as usize);
                            if paddr.is_none() {
                                break;
                            }
                            let p_addr = paddr.unwrap() as *mut Event;
                            *p_addr = ev.pop_front().unwrap();
                            (*frame).regs[Registers::A0 as usize] += 1;
                        }
                    }
                    ABS_EVENTS.replace(ev);
                    0
                },
                Syscall::GetTime => {
                    // gettime
                    (*frame).regs[Registers::A0 as usize] = crate::cpu::get_mtime();
                    0
                },
            }
        },
    )
}

/// Extern assembly function that correlates registers to proper
/// for abi compatability
extern "C" {
    fn make_syscall(
        syscall_number: usize,
        arg0: usize,
        arg1: usize,
        arg2: usize,
        arg3: usize,
        arg4: usize,
        arg5: usize,
    ) -> usize;
}

/// Wrapper over [`make_syscall`] to reduce `unsafe` blocks usage
fn do_make_syscall(
    syscall_number: usize,
    arg0: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
    arg5: usize,
) -> usize {
    unsafe { make_syscall(syscall_number, arg0, arg1, arg2, arg3, arg4, arg5) }
}

/// Close current process
pub fn syscall_exit() {
    let _ = do_make_syscall(Syscall::_Exit as usize, 0, 0, 0, 0, 0, 0);
}

/// Overlay Calling Process and Run New Program
pub fn syscall_execv(path: *const u8, argv: usize) -> usize {
    do_make_syscall(Syscall::Execv.into(), path as usize, argv, 0, 0, 0, 0)
}

/// Read file in file system
pub fn syscall_fs_read(dev: usize, inode: u32, buffer: *mut u8, size: u32, offset: u32) -> usize {
    do_make_syscall(
        Syscall::Read.into(),
        dev,
        inode as usize,
        buffer as usize,
        size as usize,
        offset as usize,
        0,
    )
}

/// Read the block on device
pub fn syscall_block_read(dev: usize, buffer: *mut u8, size: u32, offset: u32) -> u8 {
    do_make_syscall(
        Syscall::BlockRead.into(),
        dev,
        buffer as usize,
        size as usize,
        offset as usize,
        0,
        0,
    ) as u8
}

/// Gives a little sleep to the process
///
/// He worked so hard!
pub fn syscall_sleep(duration: usize) {
    let _ = do_make_syscall(Syscall::Sleep.into(), duration, 0, 0, 0, 0, 0);
}

/// Get process id
pub fn syscall_get_pid() -> u16 {
    do_make_syscall(Syscall::GetPid.into(), 0, 0, 0, 0, 0, 0) as u16
}

/// This is a helper function ran as a process in kernel space
/// to finish loading and executing a process.
fn exec_func(args: usize) {
    unsafe {
        // We got the inode from the syscall. Its Box rid itself of control, so
        // we take control back here. The Box now owns the Inode and will complete
        // freeing the heap memory allocated for it.
        let inode = Box::from_raw(args as *mut fs::Inode);
        let mut buffer = Buffer::with_capacity(inode.size as usize);
        // This is why we need to be in a process context. The read() call may sleep as it
        // waits for the block driver to return.
        fs::MinixFileSystem::read(8, &inode, buffer.as_mut_ptr(), inode.size, 0);
        // Now we have the data, so the following will load the ELF file and give us a process.
        let proc = elf::File::load_proc(&buffer);
        if proc.is_err() {
            println!("Failed to launch process.");
        } else {
            // If we hold this lock, we can still be preempted, but the scheduler will
            // return control to us. This required us to use try_lock in the scheduler.
            PROCESS_LIST_MUTEX.sleep_lock();
            if let Some(mut proc_list) = PROCESS_LIST.take() {
                proc_list.push_back(proc.ok().unwrap());
                PROCESS_LIST.replace(proc_list);
            }
            PROCESS_LIST_MUTEX.unlock();
        }
    }
}
