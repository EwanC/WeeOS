  _    _            _____ _____
 | |  | |          |  _  /  ___|
 | |  | | ___  ___ | | | \ `--.
 | |/\| |/ _ \/ _ \| | | |`--. \
 \  /\  /  __/  __/\ \_/ /\__/ /
  \/  \/ \___|\___| \___/\____/    by Ewan Crawford, ewan.cr@gmail.com


Project to create own OS.

Following guide: http://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf
and using MikeOS as a reference



QEMU tips
ctr-alt-2 to enter montior mode
use info regs to see registers, ctrl(page up/page down)
memsave to dump memory, memsave 0 65536 dump.bin




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

CHS
- Each circular track is divided into sectors, of 512 bytes, refered to bye a sector index
- cylinder is the heads discrete distance from  the outer edge
- track is the specific platter surface within the cylinder.
- Head specifies the track

- A cluster is the smallest allocation unit of storage that can be used to hold a file

Floppy 
- 1.44 MB, 3.5 Inch, 2 sides
- Can only be formatted to FAT, we use FAT12
- 512 bytes clusters, same size as sector

FAT 12, 12-bit

Area                                                  size
Boot block                                            1 block
File Allocation Table (may be multiple copies)        Depends on file system size
Disk root directory                                   Variable (selected when disk is formatted)
File data area                                        The rest of the disk`

The first cluster on the disk is the boot sector/block, where our bootloader is stoped.
Offset  Size        Description

0x00    3 bytes     Part of the bootstrap program. A jump statement, where to jump to for actual bootstrap code.
0x03    8 bytes     Optional manufacturer description.
0x0b    2 bytes     Number of bytes per block (almost always 512).
0x0d    1 byte  Number of blocks per allocation unit.
0x0e    2 bytes     Number of reserved blocks. This is the number of blocks on the disk that are not actually part of the file system; in most cases this is exactly 1, being the allowance for the boot block.
0x10    1 byte  Number of File Allocation Tables.
0x11    2 bytes     Number of root directory entries (including unused ones).
0x13    2 bytes     Total number of blocks in the entire disk. If the disk size is larger than 65535 blocks (and thus will not fit in these two bytes), this value is set to zero, and the true size is stored at offset 0x20.
0x15    1 byte  Media Descriptor. This is rarely used, but still exists. .
0x16    2 bytes     The number of blocks occupied by one copy of the File Allocation Table.
0x18    2 bytes     The number of blocks per track. This information is present primarily for the use of the bootstrap program, and need not concern us further here.
0x1a    2 bytes     The number of heads (disk surfaces). This information is present primarily for the use of the bootstrap program, and need not concern us further here.
0x1c    4 bytes     The number of hidden blocks. The use of this is largely historical, and it is nearly always set to 0; thus it can be ignored.
0x20    4 bytes     Total number of blocks in the entire disk (see also offset 0x13).
0x24    2 bytes     Physical drive number. This information is present primarily for the use of the bootstrap program, and need not concern us further here.
0x26    1 byte  Extended Boot Record Signature This information is present primarily for the use of the bootstrap program, and need not concern us further here.
0x27    4 bytes     Volume Serial Number. Unique number used for identification of a particular disk.
0x2b    11 bytes    Volume Label. This is a string of characters for human-readable identification of the disk (padded with spaces if shorter); it is selected when the disk is formatted.
0x36    8 bytes     File system identifier (padded at the end with spaces if shorter).
0x3e    0x1c0 bytes     The remainder of the bootstrap program.
0x1fe   2 bytes     Boot block 'signature' (0x55 followed by 0xaa).

FAT occupies one or more blocks immediately following the boot block. Mutliple FATs are used on floppies because of the likelihood of errors when reading the disk. 

FAT has one entry for each disk cluster. Entry N relates to cluster N. Clusters  0 and 1 don't exist since those FAT entries are special cases.
A normal FAT entry contains the successor cluster number, that is the number of the cluster that follows this one in the file to which the current cluster belongs. The last cluster in the file has
the value 0xffff in its FAT entry to indicate that there are no more clusters.

In FAT 12 each entry is 12 bits in size

The Root Directory

The root directory contains an entry for each file whose name appears at the root of the file system. The difference between the root dir and subdirs
is that space for the root dir is allocated statically when the device is formatted. There is thus an upper limit on the number of files that can appear in the root dir.

The format of all directories is the same. Each entry is 32 bytes in size, so a single block can contain 16 of then.
The following table shows a summary of a single directory entry

Offset  Length  Description
0x00    8 bytes     Filename
0x08    3 bytes     Filename extension
0x0b    1 byte  File attributes
0x0c    10 bytes    Reserved
0x16    2 bytes     Time created or last updated
0x18    2 bytes     Date created or last updated
0x1a    2 bytes     Starting cluster number for file
0x1c    4 bytes     File size in bytes
