Project to create own OS.

Following guide: http://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf
and using MikeOS as a reference



0x0     ------------------------------------------
        |Interrupt vector table
0x400   ------------------------------------------
        |BIOS Data area 
0x500   ------------------------------------------
        |
0x7C00  ------------------------------------------
        |Loaded boot sector(512 bytes)
0x7E00  ------------------------------------------
        | FREE (638 KB)
0x9fc00 ------------------------------------------
        | Extended Bios Data area
0xA0000 ------------------------------------------
        | Video memory
0xC0000 ------------------------------------------
        | BIOS
0x100000------------------------------------------


With 16 bit register the highest address we can reference is 0xffff, 64K.
To get around this problem we can use cs, ds, ss, es segment registers.
Such that any address we reference is offset by the segment start address
e.g
   mov ds, 0x4d
   mov ax, [0x20] ; ax is loaded from 0x4d0 (16 * 0x4d + 0x20)

this allows us the reach 1MB(0xffff * 16 + 0xffff) 
