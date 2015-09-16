#!/bin/sh

# Compile
nasm -f bin -o boot.bin boot.asm

# Boot from floppy
qemu-system-x86_64 -boot order=a -fda boot.bin
