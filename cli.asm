;--------------------------------------------------------------------------------------------------
; WeeOS command line interface
; Ewan Crawford <ewan.cr@gmail.com> 01/10/15
;--------------------------------------------------------------------------------------------------

os_command_line:

  ; clear input buffer
  mov di, buffer
  mov al, 0
  mov cx, 256
  rep stosb ; repeate store byte to string

  call print_prompt

  mov ax, buffer ; get command from user
  call read_input_string
  call print_new_line

  mov si, buffer ; echo 
  call print_string
  call print_new_line

  ret

;input buffer
buffer times 256 db 0
