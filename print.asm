read_input_string:
  pusha
 
  mov di, ax          ; DI is where we'll store input (buffer)
  mov cx, 0           ; index in buffer
.more:                  ; Now onto string getting
  call wait_for_key

  cmp al, 13          ; If Enter key pressed, finish
  je .done
 
  cmp al, ' '         ; ascii prinatable char
  jb .more    

  cmp al, '~'
  ja .more


  ; echo char
  mov ah, 0x0e
  int 0x10
  stosb
  inc cx
  cmp cx, 254
  jae near .done

  jmp near .more

.done:
  mov ax, 0 ; null terminating byte
  stosb

  popa
  ret

; Waits for keypress and returns key in ax
wait_for_key:
  pusha 

  mov ax, 0 
  mov ah, 10h         ; BIOS call to wait for key 
  int 16h 

  mov [.tmp_buf], ax      ; Store resulting keypress 

  popa                ; But restore all other regs 
  mov ax, [.tmp_buf]
  ret 

  .tmp_buf    dw 0

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

; prints the value of DX as hex.
print_hex:
  pusha
  mov si, HEX_STR + 2

.mask:
  mov bx, dx
  and bx, 0xf000 ; mask byte to print
  shr bx, 4
  add bh, 0x30 ; 0x30 is ascii '0'
  cmp bh, 0x39 ; 0x39 is ascii '9'
  jle .print
  add bh, 0x7 ; map dec(10) to hex(A) etc

.print:
  mov al, bh
  mov [si], bh ; Copy char into string
  inc si
  shl dx, 4 ; check for another byte
  or dx, dx
  jnz .mask
  mov bx, HEX_STR
  call print_string

  popa
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

; global variable
HEX_STR: db '0x0000',0
