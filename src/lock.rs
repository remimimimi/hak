use spin::Mutex;

use crate::syscall::syscall_sleep;

pub const DEFAULT_LOCK_SLEEP: usize = 10000;

pub trait SleepExt {
    fn sleep_lock(&mut self);
}

impl<T> SleepExt for Mutex<T> {
    fn sleep_lock(&mut self) {
        while let None = self.try_lock() {
            syscall_sleep(DEFAULT_LOCK_SLEEP);
        }
    }
}
