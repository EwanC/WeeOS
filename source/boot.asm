;--------------------------------------------------------------------------------------------------
; WeeOS Bootloader for 3.5 Inch FAT12 Floppy
;
; This 512 Byte bootloader is loaded into 0x7C00 in RAM.
; Looks in FAT root table for the WeeOS kernel binary KERNEL.BIN
; Loads it from disk then jmps to load location to execute it.
;
;
; Ewan Crawford <ewan.cr@gmail.com> 01/10/15
;
; Based on the MikeOS bootloader.
;--------------------------------------------------------------------------------------------------


BITS 16                        ; Assembler directive for 16-bit real mode
[org 0x7C00]                   ; Load bootloader into 0x7C00.

; First 3 bytes of boostrap program should be a jump to the
; begining of the boostrap program past the disk description table

jmp short bootloader_start ; two byte instruction
nop ; 1 byte padding

; Disk Description Table
OEMLabel            db "EWANBOOT"    ; Optional manufacturers description, 8 bytes
BytesPerSector      dw 512           ; Bytes per sector/block, almost always 512
SectorsPerCluster   db 1             ; Sectors per cluster, i.e blocks per allocation unit
ReservedForBoot     dw 1             ; Reserved sectors for boot record. Number of blocks on the disk
                                     ; that are not actually part of the file system.
NumberOfFats        db 2             ; Number of copies of the File allocation Table.
RootDirEntries      dw 224           ; Max number of entries in root dir
                                     ; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors      dw 2880          ; Number of logical sectors on the entire disk.
                                     ; 80 tracks, 36 sectors per track, 2 geads
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

  ; Calling interrupt 0x13 with ah=0x8 reading the dirve parameters
  mov ah, 0x8
  int 0x13
  jc disk_error
  and cx, 0x3F ; Max number of sectors, 63
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
  mov bx, buffer ; point read destination to our buffer
                 ; see end of file

  push ax
  mov ax, 0
  mov es, ax   ; TODO find a cleaner way of setting es to 0
  pop ax

  int 0x13 ; read root into ES:BX
  jc disk_error

  cmp al, 14 ; See if we actually read 14 sectors
  jne disk_error

; Get ready to search root directory for our kernel binary
search_dir:
  mov dx, word[RootDirEntries] ; dx is loop counter
  mov ax, 0 ; iterator
  mov di, buffer

next_root_entry:

  mov si, KERN_FILENAME
  mov cx, 11 ; filename length

  rep cmpsb ; cmpsb - compares strings at DS:SI with ES:DI, and sets flags accordingly
            ;       - SI and DI are then adjusted
            ; rep   - repeat instruction number of times specified by cx
            ; ZF will be one if string is found here

  je found_file ; We found the directory entry for the file

  add ax, 32 ; Pointer to next 32 byte buffer entry
  add di, ax

  dec dx     ; Decrement loop counter
  cmp dx, 0
  jg next_root_entry ; Loop if still entries left

  mov bx, FILE_NOT_FOUND_MSG ; bx is parameter reg for function
  call print_string
  call print_new_line

  jmp quit

found_file: ; Load FAT into RAM

  ; Starting cluster of file is at offset 0x1a(26) in root dir entry
  ; We are at offset 11, so offset a further 15
  mov ax, word [di + 0xF]
  mov word [CLUSTER], ax

  mov ax, 1 ; Read file allocation table, from sector 1
  call set_disk_regs

  ; setup es:bx to read disk into buffer
  mov di, buffer
  mov bx, di

  mov ah, 2 ; int 0x13 read function
  mov al, [SectorsPerFat] ; Read all fat sectors

  int 0x13

  jc disk_error

  cmp al, [SectorsPerFat] ; See if we actually read 14 sectors
  jne disk_error

load_file_sector:
  ; Cluster number of first block after root dir
  ; # = Root start + root size
  ;   = 19 + 14
  ;   = 33
  ; FAT cluster 0 = media descriptor = 0F0h
  ; FAT cluster 1 = filler cluster = 0FFh
  ; Cluster  = (cluster number) + 31

  ; Prepare to read clusta from disk
  mov ax, word[CLUSTER] ; Cluster read # read from FAT
  add ax, 31

  call set_disk_regs

  ; Load Kernel at 0x2000:XXXX
  mov ax, 0x2000
  mov es, ax
  mov bx, word [POINTER] ; set buffer past what we've already read

  ; Params for reading single sector from FAT
  mov ah, 2
  mov al, 1

  int 0x13

  jc disk_error

  cmp al, 1
  jne disk_error

calc_next_cluster:
  ; Since we're using FAT12 cluster values are stored in 12 bits
  mov ax, [CLUSTER]
  mov dx, 0
  mov bx, 3
  mul bx
  mov bx, 2
  div bx              ; DX = [cluster] mod 2
  mov si, buffer
  add si, ax          ; AX = word in FAT for the 12 bit entry
  mov ax, word [ds:si]

  or dx, dx           ; If DX = 0 [cluster] is even; if DX = 1 then it's odd

  jz even             ; If [cluster] is even, drop last 4 bits of word
                      ; with next cluster; if odd, drop first 4 bits

odd:
  shr ax, 4           ; Shift out first 4 bits (they belong to another entry)
  jmp short next_cluster_cont

even:
  and ax, 0x0FFF           ; Mask out final 4 bits

next_cluster_cont:
  mov word [CLUSTER], ax      ; Store cluster

  cmp ax, 0x0FF8           ; 0xFF8 = end of file marker in FAT12
  jae end

  add word [POINTER], 512     ; Increase buffer pointer 1 sector length
  jmp load_file_sector

end:                             ; We've got the file to load!
  mov dl, byte [BOOT_DRIVE]      ; Provide kernel with boot device info

  mov bx, BOOT_DONE_MSG
  call print_string
  call print_new_line

  jmp 0x2000:0000        ; Jump to entry point of loaded kernel!

quit:
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

disk_error:
  mov bx, DISK_ERROR_MSG
  call print_string
  jmp $               ; HANG

; prints string value from BX
print_string:
  push ax
  push bx
  mov ah, 0x0e ; BIOS tele-type interrupt
.repeat:
  mov al, [bx]
  inc bx
  cmp al, 0
  je .done
  int 0x10
  jmp .repeat

.done: ;end of string
  pop bx
  pop ax
  ret

; prints a new line
print_new_line:
  pusha

  mov ah, 0x3 ; get cursor position
  mov bh, 0   ; page number 0
  int 0x10

  mov dl, 0   ; set column to 0
  inc dh      ; move row down one
  mov ah, 0x2 ; set cursor position
  int 0x10

  popa
  ret

;Data
DISK_ERROR_MSG: db 'Disk read error',0
FILE_NOT_FOUND_MSG: db 'Could not find file',0
BOOT_DONE_MSG: db 'BOOT COMPLETE',0
KERN_FILENAME: db "KERNEL  BIN"

BOOT_DRIVE: db 0 ; boot drive number
CLUSTER: dw 0 ; Cluster of the file we want to load
POINTER: dw 0 ; Pointer into buffer for loading kernel

times 510-($-$$) db 0 ; Pad remainder of boot sector with 0s
dw 0xAA55; The standard PC boot signature

buffer: ; Disk buffer label for loading root directory
        ; Should be 0x7E00
