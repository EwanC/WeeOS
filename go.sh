#!/bin/sh

# Compile
nasm -f bin -o hello.bin hello.asm

# Run from floppy
qemu-system-x86_64 -fda hello.bin
