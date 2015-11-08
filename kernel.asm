;--------------------------------------------------------------------------------------------------
; WeeOS Kernel
; Ewan Crawford <ewan.cr@gmail.com> 01/10/15
;--------------------------------------------------------------------------------------------------

BITS 16

os_main:
  cli ; clear interrupts

  mov ax, 0
  mov ss, ax        ;set stack segment to zero, flat memory space
  mov sp, 0xffff    ;set stack pointer to end of our memory space
  sti   ;restore interrupts

  cld ; increment string operations in si, di

  ; set all segments to match where the kernel is loaded
  mov ax, 0x2000
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  call set_video_mode
  call print_heading

.loop:
  call print_new_line
  call os_command_line

  jmp .loop

exit:
  jmp $ ; Hang

;;;;;;;;;;;;;;;;;;;;;;
; Data
;;;;;;;;;;;;;;;;;;;;;;
OS_SETUP_MSG: db 'Loading WeeOS',0

;;;;;;;;;;;;;;;;;;;;;
; Includes
;;;;;;;;;;;;;;;;;;;;;
%include "print.asm"
%include "cli.asm"
