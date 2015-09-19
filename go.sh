#!/bin/sh


# Create Floopy image with 1440 bocks
if [ -e weeOS.flp ]
then
    echo "Removing old floppy image"
    rm weeOS.flp
fi

# Make 1.44 MB FAT 12 floppy image
mkdosfs -C weeOS.flp -F 12 1440 || exit

# Assemble
nasm -f bin -o boot.bin boot.asm || exit

echo "Assembled Bootloader"

# Copy bootloader to floppy image
dd status=noxfer conv=notrunc if=boot.bin of=weeOS.flp || exit

# A loop device is a fake device, actually just a file, that acts as a block based device.
# mount -o loop -t msdos -o "fat=12" weeOS.flp tmp_floppy_files

echo "Run Simulator"

# Boot Simulator from floppy
qemu-system-x86_64 -boot order=a -fda weeOS.flp
