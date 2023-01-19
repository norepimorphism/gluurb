BIOS_PAGE   equ 0
MAX_ROW     equ 20
MAX_COL     equ 20

; Prints an ASCII character to the BIOS framebuffer.
;
; Arguments:
; - %1: the character.
;
; Clobbers:
; - %ax
; - %bx
; - %cx
; - %dx
%macro putchar 1
    push    %1
.set_cursor_position:
    mov     ax, (0x02 << 8)
    ; Set the page number.
    mov     bx, (BIOS_PAGE << 8)
    ; Set the row and column.
    mov     dx, [bios_cursor]
    int     0x10
.inc_cursor:
    ; If we hit the maximum column, then create a new line.
    test    dl, MAX_COL
    je     .newline
    ; Otherwise, increment the column and continue.
    inc     dl
    mov     [bios_cursor_col], dl
    jmp     .print_char
.newline:
    ; If we are at the maximum row, too, then reset both the row and column.
    test    dh, MAX_ROW
    je     .newpage
    ; Otherwise, just increment the row.
.inc_row:
    inc     dh
    jmp     .newline_end
.newpage:
    xor     dh, dh
.newline_end:
    xor     dl, dl
    mov     [bios_cursor_row], dh
    mov     [bios_cursor_col], dl
.print_char:
    pop     ax
    mov     ah, 0x9
    ; Note: I don't really trust that the BIOS preserved `%bh`, so we're going to load it again.
    ; We'll also set the color to 'light magenta'.
    mov     bx, ((BIOS_PAGE << 8) | 0xd)
    ; Print only one character.
    mov     cx, 1
    int     0x10
%endmacro

; Prints an ASCII character to the BIOS framebuffer.
;
; Arguments:
; - %dl: the character.
bios_putchar:
    push    ax
    push    bx
    push    cx
    push    dx
    and     dx, 0xff
    putchar dx
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret

bios_cursor:
bios_cursor_row:
    db      0
bios_cursor_col:
    db      0

bios_init:
    push    ax
    push    bx
    push    dx
.init_cursor:
    mov     ah, 0x2
    ; Set the page number.
    mov     bh, BIOS_PAGE
    ; Set the row and column to zero.
    xor     dx, dx
    int     0x10
.end:
    pop     dx
    pop     bx
    pop     ax
    ret

; Prints a null-terminated ASCII string to the BIOS framebuffer.
;
; Arguments:
; - %bx: the address of the first byte in the string.
bios_puts:
    push    ax
    push    cx
    push    dx
.loop:
    xor     cx, cx
    mov     cl, [bx]
    jcxz    .end
    ; Note: `putchar` clobbers `%bx`. `%ax` and `%dx` have already been saved, and we can just
    ; discard `%cx`, which is about to be cleared in the next iteration anyway.
    push    bx
    putchar cx
    pop     bx
    inc     bx
    jmp     .loop
.end:
    pop     dx
    pop     cx
    pop     ax
    ret
