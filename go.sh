#!/bin/sh

# Compile
nasm -f bin -o hello.bin hello.asm

# Boot from floppy
qemu-system-x86_64 -boot order=a -fda hello.bin
