;--------------------------------------------------------------------------------------------------
; Bootloader for 3.5 Inch FAT12 Floppy
;
; This 512 Byte bootloader is loaded into 0x7C00 in RAM
;
;--------------------------------------------------------------------------------------------------


BITS 16     ; Assembler directive for 16-bit real mode
[org 0x7C00] ; Load bootloader into 0x7C000.


; First 3 bytes of boostrap program should be a jump to the
; begining of the boostrap program past the dist description table

jmp short bootloader_start ; two byte instruction
nop ; padding

; Disk Description Table
OEMLabel            db "EWANBOOT"    ; Optional manufacturers description, 8 bytes
BytesPerSector      dw 512           ; Bytes per sector/block, almost always 512
SectorsPerCluster   db 1             ; Sectors per cluster, i.e blocks per allocation unit
ReservedForBoot     dw 1             ; Reserved sectors for boot record. Number of blocks on the disk
                                     ; that are not actually part of the file system.
NumberOfFats        db 2             ; Number of copies of the File allocation Table.
RootDirEntries      dw 224           ; Number of entries in root dir
                                     ; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors      dw 2880          ; Number of logical sectors on the entire disk.
MediumByte          db 0F0h          ; Media descriptor byte
SectorsPerFat       dw 9             ; Number of blocks occupied by one copy of the File Allocaton Table
SectorsPerTrack     dw 18            ; Sectors per track (36/cylinder)
Sides               dw 2             ; Number of sides/heads
HiddenSectors       dd 0             ; Historical, can be ignored
LargeSectors        dd 0             ; Number of LBA sectors
DriveNo             dw 0             ; Drive No: 0
Signature           db 41            ; Drive signature: 41 for floppy
VolumeID            dd 00000000h     ; Volume ID: any number
VolumeLabel         db "WeeOS      " ; Volume Label: any 11 chars
FileSystem          db "FAT12   "    ; File system type: don't change!


bootloader_start:
  mov [BOOT_DRIVE], dl ; BIOS stores our bootdrive in dl,
                       ; so best remember this for later

  mov bp, 0x8000 ; set the stack out of the way at 0x8000
  mov sp, bp


  ; Load FAT Root directory from floppy
  ; root sector # = (size of FAT) * (Number of FATS) + 1
  ;               = (9 * 2) + 1
  ;               = 19



  ; Size of Root directory in sectors
  ; size = (number of root entries) * 32 Bytes / (Sector size)
  ;      = (224 * 32) / 512
  ;      = 14

  ; Cluster number of first block after root dir
  ; # = Root start + root size
  ;   = 19 + 14
  ;   = 33

  mov bx, HELLO_MSG ; bx is parameter reg for function
  call print_string
  call print_new_line

  mov bx, 0x9000 ; load 5 sectors 0x0000(ES):0x9000(BX)
  mov dh, 5      ; from the boot disk
  mov dl, [BOOT_DRIVE]
  call disk_load

  mov dx, [0x9000] ; Print out the first loaded word which
  call print_hex   ; We expect to be 0xdada

  call print_new_line

  mov dx, [0x9000 + 512]  ; Also print first word from the second
  call print_hex          ; loaded sector, 0xface

  jmp $ ; Hang

; Calculates head(dh), track(ch), device(dl), and sector(cl) registers
; for disk read with int 13
; ax is passed in as the logical sector to read(Logical Block Addressing)
;
; Note: Sector is based at 1 not 0
;
; - Temp = LBA / Sectors per track
; - Sector = (LBA % Sectors per track) + 1
; - Head = Temp % (number of heads)
; - Cylinder = Temp / (number of heads)

set_disk_regs:
  push ax
  push bx

  mov bx, ax ; save logical sector

  ; First calculate the sector
  mov dx, 0
  div word [SectorsPerTrack] ; unsigned divide dx:ax by SectorsPerTrack,
                             ; storing quotient in AX and remainer in DX
  add dl, 0x01  ; Physical sectors start at one
  mov cl, dl ; sectors belong in cl
  mov ax, bx

  ; Calculate head
  mov dx, 0
  div word [SectorsPerTrack] ; AX is now Temp
  mov dx, 0
  div word [Sides]    ; Two heads, one on each side
  mov dh, dl          ; set head
  mov ch, al          ; set track

  pop ax
  pop bx

  mov dl, byte [BOOT_DRIVE] ; set correct device

  ret

  %include "print.asm"  ; functions for printing
  %include "disk.asm"   ; functions for loading from dis

;Data
HELLO_MSG:
  db 'Welcome to WeeOS', 0

BOOT_DRIVE:
  db 0

times 510-($-$$) db 0 ; Pad remainder of boot sector with 0s
dw 0xAA55; The standard PC boot signature

; We know the BIOS will load only the first 512-byte sector from the disk.
; So if we purposely add a few more sectors to out code by repeating some
; familiar numbers, we can prove to ourselfs that we actually loaded these
; additional two sectors

times 256 dw 0xdada
times 256 dw 0xface
