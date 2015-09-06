BITS 16     ; 16-bit real mode
[org 0x7C00] ; tell assembler where this code expects to be loaded

;mov bx, HELLO_MSG ; bx is parameter reg for function
;call print_string

mov [BOOT_DRIVE], dl ; BIOS stores our bootdrive in dl,
                     ; so best remember this for later

mov bp, 0x8000 ; set the stack out of the way at 0x8000
mov sp, bp

mov bx, 0x9000 ; load 5 sectors 0x0000(ES):0x9000(BX)
mov dh, 5      ; from the boot disk
mov dl, [BOOT_DRIVE]
call disk_load

mov dx, [0x9000] ; Print out the first loaded word which
call print_hex   ; We expect to be 0xdada

mov dx, [0x9000 + 512]  ; Also print first word from the second
call print_hex          ; loaded sector, 0xface

jmp $ ; Hang

%include "print.asm"  ; functions for printing
%include "disk.asm"   ; functions for loading from dis

;Data
HELLO_MSG:
  db 'Welcome to WeeOS',0xa, 0

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
