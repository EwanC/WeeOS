BITS 16     ; 16-bit real mode
[org 0x7C00] ; tell assembler where this code expects to be loaded

mov bx, HELLO_MSG ; bx is parameter reg for function
call print_string

mov dx, 0xBEEF
call print_hex

jmp $ ; Hang

%include "print.asm"  

;Data
HELLO_MSG:
  db 'Welcome to WeeOS', 0

times 510-($-$$) db 0; Pad remainder of boot sector with 0s
dw 0xAA55; The standard PC boot signature
