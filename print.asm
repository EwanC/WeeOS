set_video_mode:
  push ax
  
  mov ah, 0x00
  mov al, 0x10 ; set video mode
  int 0x10

  pop ax
  ret

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
  mov bl, 0000b
  mov bx, 1111b ; set text to white
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

; prints string value from SI
print_string:
  pusha
  mov ah, 0x0e ; BIOS tele-type interrupt
  mov bh, 0x00 ; Page number
  mov bl, [COLOUR]

.repeat:
  mov al, [si]
  inc si
  cmp al, 0
  je .done
  int 0x10
  jmp .repeat

.done: ;end of string
  popa
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
  mov si, HEX_STR
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

print_heading:

  call set_text_cyan

  mov si, HEAD_1_STR
  call print_string
  call print_new_line

  mov si, HEAD_2_STR
  call print_string
  call print_new_line

  mov si, HEAD_3_STR
  call print_string
  call print_new_line

  mov si, HEAD_4_STR
  call print_string
  call print_new_line

  mov si, HEAD_5_STR
  call print_string
  call print_new_line

  mov si, HEAD_6_STR
  call print_string
  call print_new_line


  call set_text_white

  ret

print_prompt:
  push bx

  call set_text_green

  mov si, PROMPT
  call print_string

  call set_text_white

  pop bx
  ret

set_text_cyan:
 push ax

 mov ah, CYAN
 mov [COLOUR], ah

 pop ax
 ret


set_text_green:
 push ax

 mov ah, GREEN
 mov [COLOUR], ah

 pop ax
 ret

set_text_white:
 push ax

 mov ah, WHITE
 mov [COLOUR], ah

 pop ax
 ret


; global variable
HEX_STR: db '0x0000',0
PROMPT: db '$> ',0
COLOUR: db 1111b

; TITLE HEADER
HEAD_1_STR: db '  _    _            _____ _____ ',0
HEAD_2_STR: db ' | |  | |          |  _  /  ___|',0
HEAD_3_STR: db ' | |  | | ___  ___ | | | \ `--. ',0
HEAD_4_STR: db ' | |/\| |/ _ \/ _ \| | | |`--. \',0
HEAD_5_STR: db ' \  /\  /  __/  __/\ \_/ /\__/ /',0
HEAD_6_STR: db '  \/  \/ \___|\___| \___/\____/ ',0

; COLOURS
BLACK equ 0000b
BLUE equ 0001b
GREEN equ 0010b
CYAN equ 0011b
RED equ 0100b
WHITE equ 1111b
