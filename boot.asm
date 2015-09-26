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
MediumByte          db 0x0F0         ; Media descriptor byte
SectorsPerFat       dw 9             ; Number of blocks occupied by one copy of the File Allocaton Table
SectorsPerTrack     dw 18            ; Sectors per track (36/cylinder)
Sides               dw 2             ; Number of sides/heads
HiddenSectors       dd 0             ; Historical, can be ignored
LargeSectors        dd 0             ; Number of LBA sectors
DriveNo             dw 0             ; Drive No: 0
Signature           db 41            ; Drive signature: 41 for floppy
VolumeID            dd 0x00000000    ; Volume ID: any number
VolumeLabel         db "WeeOS      " ; Volume Label: any 11 chars
FileSystem          db "FAT12   "    ; File system type: don't change!


bootloader_start:
  mov [BOOT_DRIVE], dl ; BIOS stores our bootdrive in dl,
                       ; so best remember this for later

  ; set the stack out of the way at 0xA000
  mov bp, 0xA000   
  mov sp, bp
  

   ; Calling interrupt 0x13 with ah=0x8 Reads the dirve parameters
  mov ah, 0x8
  int 0x13
  jc disk_error  
  and cx, 0x3F ; Max number of sectors
  mov [SectorsPerTrack], cx
  movzx dx, dh ; dh stores max head number
  inc dx ; head numbers start at 0
  mov [Sides], dx

   ; Load FAT Root directory from floppy
  ; root sector # = (size of FAT) * (Number of FATS) + 1
  ;               = (9 * 2) + 1
  ;               = 19
  mov ax, 19
  call set_disk_regs
  mov ah, 2   ; Read disk
  
  ; Size of Root directory in sectors
  ; size = (number of root entries) * 32 Bytes / (Sector size)
  ;      = (224 * 32) / 512
  ;      = 14
  mov al, 14
  mov bx, buffer

  push ax
  mov ax, 0
  mov es, ax
  pop ax

  int 0x13 ; read root into ES:BX 
  jc disk_error  

  cmp al, 14 ;See if we actually read 14 sectors
  jne disk_error

  ; Cluster number of first block after root dir
  ; # = Root start + root size
  ;   = 19 + 14
  ;   = 33

  mov bx, HELLO_MSG ; bx is parameter reg for function
  call print_string
  call print_new_line

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

; Assumes all int 13 regs have already been inited by 
; calling set_disk_regs
; stores result in  ES:BX
disk_read:
  mov ah, 0x02 ; BIOS read sector function
  int 0x13
  jc disk_error ; disk error
  ret

disk_error:
  mov bx, DISK_ERROR_MSG
  call print_string
  jmp $               ; HANG

%include "print.asm"  ; functions for printing

;Data
HELLO_MSG: db 'Welcome to WeeOS', 0
DISK_ERROR_MSG: db 'Disk read error',0
BOOT_DRIVE: db 0

times 510-($-$$) db 0 ; Pad remainder of boot sector with 0s
dw 0xAA55; The standard PC boot signature

buffer: ; Disk buffer label for loading root directory 
        ; Should be 0x7E00
