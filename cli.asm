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

  mov si, buffer

  mov di, shutdown_string
  call compare_string
  jc do_shutdown

  mov di, ls_string
  call compare_string
  jc do_list_files

  call print_string ; echo
  ret

; Shutsdown qemu emulator
do_shutdown:
    ; Connect to APM API
    mov ax, 0x5301 ; Connect to Advanced Power Management real mode interface
    xor bx, bx
    int 0x15 ; CF set on error but try shutdown anyway

    mov ax, 0x5307 ; Set power state
    mov bx, 1 ; Device id
    mov cx, 3 ; cx - system state id: 0 ready, 1 standbye, 2 suspend, 3 off
    int 0x15
    ret

; Lists all the files
do_list_files:
   mov ax, file_name_buffer
   call disk_file_list

   mov si, disk_file_list
   call print_string
   ret

;input buffer
buffer times 256 db 0
file_name_buffer times 1024 db 0

;COMMANDS
shutdown_string  db 'shutdown', 0
ls_string  db 'ls', 0
