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


; prints the value of DX as hex.
print_hex:
  ; TODO manipulate chars at HEX_OUT to reflect DX
 
  mov bx, HEX_OUT
  call print_string; 
  ret

; global variable
HEX_OUT: db '0x0000',0
