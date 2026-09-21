[bits 32]
[org 0x8000]

%include "macros.asm"

kernel_entry:
    cli
    cld

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7C00

    mov edi, 0xB8000

    printcol "booted", WHITE
    printcol "", WHITE 

    read_sector_32 0, 0x60000
    jc disk_error

    mov esi, 0x60000
    mov ax, [esi + 0x0E]
    mov [fat_start_sector], ax

shell_loop:
    input "# ", 0x50000, 0x50040
    call handle_command
    jmp shell_loop

disk_error:
    printcol "Disk read error", RED

.halt:
    cli
    hlt
    jmp .halt

handle_command:
    mov esi, 0x50000
    mov ebx, command_help
    call command_equals
    test eax, eax
    jnz .help

    mov esi, 0x50000
    mov ebx, command_ver
    call command_equals
    test eax, eax
    jnz .ver

    mov esi, 0x50000
    mov ebx, command_exit
    call command_equals
    test eax, eax
    jnz .exit

    printcol "Unknown command", RED ; I can't add a blank printcol here. It breaks the entire damn input.
    ret

.help:
    printcol "help - show this message", WHITE
    printcol "ver  - show version", WHITE
    printcol "exit - exit OS instance", WHITE
    printcol "", WHITE 
    ret

.ver:
    printcol "asmOS - By Turlum25", GREEN
    printcol "Version 0.01", WHITE
    printcol "", WHITE
    ret

.exit:
    call exitos
    ret

command_equals:
    push esi
    push edi
    push ebx

    mov edi, ebx

.compare:
    mov al, [esi]
    cmp al, [edi]
    jne .not_equal

    test al, al
    jz .equal

    inc esi
    inc edi
    jmp .compare

.equal:
    mov eax, 1
    jmp .done

.not_equal:
    xor eax, eax

.done:
    pop ebx
    pop edi
    pop esi
    ret

exitos:
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax

.halt:
    cli
    hlt
    jmp .halt

read_keyboard_input_32:
    mov edx, esi

.wait_key:
    in al, 0x64
    test al, 1
    jz .wait_key

    in al, 0x60

    test al, 0x80
    jnz .wait_key

    cmp al, 0x1C
    je .enter

    cmp al, 0x0E
    je .backspace

    call scancode_to_ascii
    test al, al
    jz .wait_key

    cmp edx, ebp
    jae .wait_key

    mov [edx], al
    inc edx

    mov [edi], al
    mov byte [edi + 1], WHITE
    add edi, 2

    jmp .wait_key

.backspace:
    cmp edx, esi
    jbe .wait_key

    dec edx
    sub edi, 2

    mov byte [edi], ' '
    mov byte [edi + 1], WHITE

    jmp .wait_key

.enter:
    mov byte [edx], 0

    call newline_32
    ret

scancode_to_ascii:
    cmp al, 0x39
    ja .unknown

    movzx eax, al
    mov al, [scancode_table + eax]
    ret

.unknown:
    xor eax, eax
    ret

scancode_table:
    db 0, 0, '1', '2', '3', '4', '5', '6'
    db '7', '8', '9', '0', '-', '=', 0, 0
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'
    db 'o', 'p', '[', ']', 0, 0, 'a', 's'
    db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'
    db 0x27, '`', 0, '\', 'z', 'x', 'c', 'v'
    db 'b', 'n', 'm', ',', '.', '/', 0, '*'
    db 0, ' ', 0, 0, 0, 0, 0, 0

ata_read_sector:
    pusha

    mov edi, ebx
    mov ecx, eax

    mov dx, 0x1F2
    mov al, 1
    out dx, al

    mov dx, 0x1F3
    mov al, cl
    out dx, al

    mov dx, 0x1F4
    mov al, ch
    out dx, al

    shr ecx, 16
    mov dx, 0x1F5
    mov al, cl
    out dx, al

    shr ecx, 8
    mov dx, 0x1F6
    mov al, cl
    and al, 0x0F
    or al, 0xE0
    out dx, al

    mov dx, 0x1F7
    mov al, 0x20
    out dx, al

    mov esi, 0x100000

.wait_status:
    in al, dx

    test al, 1
    jnz .fail

    test al, 0x80
    jnz .status_again

    test al, 8
    jnz .data_ready

.status_again:
    dec esi
    jnz .wait_status
    jmp .fail

.data_ready:
    mov ecx, 256
    mov dx, 0x1F0

.read_loop:
    in ax, dx
    stosw
    loop .read_loop

    clc
    popa
    ret

.fail:
    stc
    popa
    ret

newline_32:
    push eax
    push ecx
    push edx

    mov eax, edi
    sub eax, 0xB8000

    xor edx, edx
    mov ecx, 160
    div ecx

    inc eax
    imul eax, 160

    cmp eax, 4000
    jb .set_cursor

    xor eax, eax

.set_cursor:
    add eax, 0xB8000
    mov edi, eax

    pop edx
    pop ecx
    pop eax
    ret

command_help:
    db "help", 0

command_ver:
    db "ver", 0

command_exit:
    db "exit", 0

fat_start_sector:
    dw 0
