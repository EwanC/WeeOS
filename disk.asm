; load DH sectors to ES:BX from drive DL
disk_load:
  push dx         ; Store DX on stack so later we can recall
                  ; how many sectors were request to be read,
                  ; even if it is altered in the meantime
  mov ah, 0x02    ; BIOS read sector function
  mov al, dh      ; read DH sectors
  mov ch, 0x00    ; select cylinder 0
  mov dh, 0x00    ; select head 0
  mov cl, 0x02    ; start reading from second sector(i.e after boot sector)

  int 0x13        ; BIOS interrupt

  jc disk_error   ; Jump if error (i.e carry flag is set)
  
  pop dx
  cmp dh, al      ; if AL (sectors read) != DH (sectors expected)
  jne disk_error  ; diplay error msh
  ret

; Returns a comma separated string of file
; names on disk in ax.
disk_file_list:
  mov word [.file_list_tmp], ax
  ret
  .file_list_tmp   dw 0

disk_error:
  mov bx, DISK_ERROR_MSG
  call print_string
  jmp $               ; HANG

; variables
DISK_ERROR_MSG: db "Disk read error!",0
