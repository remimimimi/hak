use core::{mem, ptr};

// Reexport all linker symbols
global_asm!(include_str!("mem.S"));
extern "C" {
    pub(crate) static HEAP_START: usize;
    pub(crate) static HEAP_SIZE: usize;
    pub(crate) static TEXT_START: usize;
    pub(crate) static TEXT_END: usize;
    pub(crate) static DATA_START: usize;
    pub(crate) static DATA_END: usize;
    pub(crate) static RODATA_START: usize;
    pub(crate) static RODATA_END: usize;
    pub(crate) static BSS_START: usize;
    pub(crate) static BSS_END: usize;
    pub(crate) static KERNEL_STACK_START: usize;
    pub(crate) static KERNEL_STACK_END: usize;
    pub(crate) static mut KERNEL_TABLE: usize;
}

static mut ALLOC_START: usize = 0;
const PAGE_ORDER: usize = 12;
pub const PAGE_SIZE: usize = 1 << 12;

/// Align the given address `addr` upwards to alignment `align`.
///
/// Requires that `align` is a power of two.
pub const fn align_up(addr: usize, align: usize) -> usize {
    (addr + align - 1) & !(align - 1)
}

#[repr(u8)]
pub enum PageBits {
    Empty = 0,
    Taken = 1 << 0,
    Last = 1 << 1,
}

impl PageBits {
    pub fn as_u8(self) -> u8 {
        self as u8
    }
}

// Each page is described by the Page structure. Linux does this
// as well, where each 4096-byte chunk of memory has a structure
// associated with it. However, there structure is much larger.
pub struct Page {
    flags: u8,
}

impl Page {
    /// If this page has been marked as the final allocation,
    /// this function returns true. Otherwise, it returns false.
    pub fn is_last(&self) -> bool {
        self.flags & PageBits::Last.as_u8() != 0
    }

    /// If the page is marked as being taken (allocated), then
    /// this function teturns true. Otherwise, it returns false.
    pub fn is_taken(&self) -> bool {
        self.flags & PageBits::Taken.as_u8() != 0
    }

    /// Opposite function of is_taken().
    pub fn is_free(&self) -> bool {
        !self.is_taken()
    }

    /// Clear the Page structure and all associated allocations.
    pub fn clear(&mut self) {
        self.flags = PageBits::Empty.as_u8()
    }

    // We ran into trouble here since PageBits
    // is an enumeration and we haven't implemented the BitOr Trait
    // on it.
    /// Set a certain flag.
    pub fn set_flag(&mut self, flag: PageBits) {
        self.flags |= flag.as_u8();
    }

    pub fn clear_flag(&mut self, flag: PageBits) {
        self.flags &= !(flag.as_u8());
    }
}

pub fn init() {
    unsafe {
        let num_pages = HEAP_SIZE / PAGE_SIZE;
        let ptr = HEAP_START as *mut Page;
        // Clear all pages to make sure that they aren't accidently taken
        for i in 0..num_pages {
            (*ptr.add(i)).clear();
        }
        // Determine where the actual useful memory starts. This will be
        // after all Page structures. We also must align the ALLOC_START
        // to a page boundary (PAGE_SIZE = 4096).
        // ALLOC_START = (HEAP_START + num_pages * mem::size_of::<Page>() + PAGE_SIZE - 1) & !(PAGE_SIZE - 1)
        ALLOC_START =
            align_up(HEAP_START + num_pages * mem::size_of::<Page>(), PAGE_SIZE) & !(PAGE_SIZE - 1);
    }
}

/// Allocate a page or multiple pages
/// pages: the number of PAGE_SIZE pages to allocate
pub fn alloc(pages: usize) -> *mut u8 {
    // We have to find a contiguous allocation of pages
    assert!(pages > 0);
    unsafe {
        // We create a Page structure for each page on the heap. We
        // actually might have more since HEAP_SIZE moves and so does
        // the size of our structure, but we'll only waste a few bytes.
        let num_pages = HEAP_START / PAGE_SIZE;
        let ptr = HEAP_START as *mut Page;
        for i in 0..num_pages - pages {
            let mut found = false;
            // Check to see if this Page is free. If so, we have our
            // first candidate memory address.
            if (*ptr.add(i)).is_free() {
                // It was FREE! YAY!
                found = true;
                for j in i..i + pages {
                    // Now check to see if we have a
                    // contiguous allocation for all of the
                    // request pages. If not, we should
                    // check somewhere else.
                    if (*ptr.add(j)).is_taken() {
                        found = false;
                        break;
                    }
                }
            }
            // We've checked to see if there are nough contiguous
            // pages to form what we need. If we couldn't, found
            // will be false, otherwise it will be true, which means
            // we've found valid memory we can allocate.
            if found {
                for k in i..i + pages - 1 {
                    (*ptr.add(k)).set_flag(PageBits::Taken);
                }

                // The marker for the last page is
                // PageBits::last This lets us know when we've
                // hit the end of this particular allocation.
                (*ptr.add(i + pages - 1)).set_flag(PageBits::Taken);
                (*ptr.add(i + pages - 1)).set_flag(PageBits::Last);
                return (ALLOC_START + PAGE_SIZE * i) as *mut u8;
            }
        }
    }

    // If we get here, that means that no contiguous allocation was found.
    ptr::null_mut()
}

/// Allocate and zero a page or multiple pages
/// pages: the number of pages to allocate
/// Each page is PAGE_SIZE which is calculated as 1 << PAGE_ORDER
/// On RISC-V, this typically will be 4096 bytes.
pub fn zalloc(pages: usize) -> *mut u8 {
    todo!()
}
