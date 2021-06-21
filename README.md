# `Terrikon`

New type operating system

# Building and running
## Prerequests
### Rust
Install Rust RISC-V toolchain and `cargo-binutils`
```sh
rustup target add riscv64gc-unknown-none-elf
cargo install cargo-binutils
```
### Qemu
Qemu can be installed in arch linux with
```sh
pacman -S qemu qemu-arch-extra
```
### Hard drive file
To run this , you'll need a hard drive file called hdd.dsk in this directory. You can create an empty
one by typing the following.
```sh
fallocate -l 32M hdd.dsk
```

## Running
To run, you can just use normal `cargo run` or `cargo run --release` for release mode

# License
The source code in this project is licensed under the GNU General Public License v3.0
