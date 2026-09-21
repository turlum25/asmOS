BLACK   equ 0x00
BLUE    equ 0x09
GREEN   equ 0x0A
BROWN   equ 0x06
WHITE   equ 0x0F
RED     equ 0x0C
ORANGE  equ 0x06
YELLOW  equ 0x0E

%macro printcol 2
    jmp %%skip

%%str:
    db %1, 0

%%skip:
    cld
    mov esi, %%str

%%loop:
    lodsb
    test al, al
    jz %%done

    mov [edi], al
    mov byte [edi + 1], %2
    add edi, 2
    jmp %%loop

%%done:
    call newline_32
%endmacro

%macro read_sector_32 2
    mov eax, %1
    mov ebx, %2
    call ata_read_sector
%endmacro

%macro input 3
    jmp %%skip

%%prompt:
    db %1, 0

%%skip:
    cld
    mov esi, %%prompt

%%prompt_loop:
    lodsb
    test al, al
    jz %%prompt_done

    mov [edi], al
    mov byte [edi + 1], WHITE
    add edi, 2
    jmp %%prompt_loop

%%prompt_done:
    mov esi, %2
    mov edx, %2
    mov ebp, %3
    call read_keyboard_input_32
%endmacro
