[bits 16]
[org 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ah, 0x00
    mov al, 0x03
    int 0x10

    mov si, msg_ebios
    call print_string_16

    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov bx, 0x8000
    int 0x13
    jc disk_crash

    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp 0x08:0x8000

disk_crash:
    jmp $

print_string_16:
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    ret          

msg_ebios db "boot", 0x0D, 0x0A, 0

gdt_start:
gdt_null: dd 0x0, 0x0
gdt_code: dw 0xffff, 0x0, 0x9a00, 0xcf
gdt_data: dw 0xffff, 0x0, 0x9200, 0xcf
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55
