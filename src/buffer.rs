use alloc::boxed::Box;
use core::ops::{
    Index,
    IndexMut,
};

// We need a Buffer that can automatically be created and destroyed
// in the lifetime of our read and write functions. In C, this would entail
// goto statements that "unravel" all of the allocations that we made. Take
// a look at the read() function to see why I thought this way would be better.
pub struct Buffer<const SIZE: usize> {
    buffer: Box<[u8; SIZE]>,
}

impl<const SIZE: usize> Buffer<SIZE> {
    /// Allocate new zeroed buffer
    pub fn new() -> Self {
        Self {
            buffer: Box::new([0; SIZE]),
        }
    }

    pub fn get_mut(&mut self) -> &mut Box<[u8; SIZE]> {
        &mut self.buffer
    }

    pub const fn get(&self) -> &Box<[u8; SIZE]> {
        &self.buffer
    }

    pub const fn len(&self) -> usize {
        self.buffer.len()
    }
}

impl<const SIZE: usize> Default for Buffer<SIZE> {
    fn default() -> Self {
        Self::new()
    }
}

impl<const SIZE: usize> Index<usize> for Buffer<SIZE> {
    type Output = u8;

    fn index(&self, idx: usize) -> &Self::Output {
        unsafe { self.get().as_ptr().add(idx).as_ref().unwrap() }
    }
}

impl<const SIZE: usize> IndexMut<usize> for Buffer<SIZE> {
    fn index_mut(&mut self, idx: usize) -> &mut Self::Output {
        unsafe { self.get_mut().as_mut_ptr().add(idx).as_mut().unwrap() }
    }
}

impl<const SIZE: usize> Clone for Buffer<SIZE> {
    fn clone(&self) -> Self {
        Self {
            buffer: self.buffer.clone(),
        }
    }
}
