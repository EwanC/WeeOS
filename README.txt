Project to create own OS.

build:
 nasm -f bin -o hello.bin hello.asm

run: 
 qemu-system-x86_64 hello.bin
