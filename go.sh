#!/bin/sh

if test "`whoami`" != "root" ; then
     echo "You must be logged in as root to build (for loopback mounting)"
     exit
fi

# Create Floopy image with 1440 bocks
if [ -e weeOS.flp ]
then
    echo "Removing old floppy image"
    rm weeOS.flp
fi

# Make 1.44 MB FAT 12 floppy image
mkdosfs -C weeOS.flp -F 12 1440 || exit

# Assemble bootloader
nasm -f bin -o boot.bin boot.asm || exit

echo "Assembled Bootloader"

# Assemble kernel
nasm -f bin -o kernel.bin kernel.asm || exit

echo "Assembled Kernel"

# Copy bootloader to floppy image
dd status=noxfer conv=notrunc if=boot.bin of=weeOS.flp || exit

# A loop device is a fake device, actually just a file, that acts as a block based device.
echo "Copying kernel to floppy" 

mkdir tmp_floppy_files || exit

mount -o loop -t msdos -o "fat=12" weeOS.flp tmp_floppy_files || exit
cp kernel.bin tmp_floppy_files/ || exit

sleep 0.2 # Without sleep device will still be busy

echo "Unmounting loopback floppy"
umount tmp_floppy_files || exit

rm -rf tmp_floppy_files || exit

echo "Run Simulator"

# Boot Simulator from floppy
qemu-system-x86_64 -boot order=a -fda weeOS.flp
