BIOS_PAGE   equ 0
MAX_ROW     equ 20
MAX_COL     equ 20

bios_cursor:
bios_cursor_row:
    db      0
bios_cursor_col:
    db      0

; Initializes the BIOS functions.
;
; This must be called before any other `bios_` functions.
;
; Arguments: none
;
; Clobbers: none
bios_init:
    push    ax
    push    bx
    push    dx
.set_page:
    mov     ax, ((0x05 << 8) | BIOS_PAGE)
    int     0x10
.init_cursor:
    mov     ah, 0x2
    ; Set the page number.
    mov     bh, BIOS_PAGE
    ; Set the row and column to zero.
    ; Note: we don't really want `xor dx, dx` here because that would require us to preserve flags.
    mov     dx, 0
    int     0x10
.end:
    pop     dx
    pop     bx
    pop     ax
    ret

; Increments the cursor for the next character, inserting a new line or clearing the page if
; necessary.
;
; Arguments:
; - %dx: the cursor.
;
; Clobbers: none
bios_inc_cursor:
    pushf
    ; If we hit the maximum column, then create a new line.
    test    dl, MAX_COL
    je     .newline
.inc_row:
    ; Otherwise, increment the column and return.
    inc     dl
    mov     [bios_cursor_col], dl
    jmp     .end
.newline:
    call    bios_newline
.end:
    popf
    ret

; Moves the cursor to the start of the next line, clearing the page if necessary.
;
; Arguments:
; - %dx: the cursor.
;
; Clobbers: none
bios_newline:
    pushf
    ; If we hit the maximum row, then create a new page.
    test    dh, MAX_ROW
    je     .newpage
.inc_row:
    ; Otherwise, just increment the row and reset the column.
    inc     dh
    xor     dl, dl
    mov     [bios_cursor], dx
    jmp     .end
.newpage:
    call    bios_newpage
.end:
    popf
    ret

; Sets the cursor to the top-left corner.
;
; Arguments: none
;
; Clobbers: none
bios_newpage:
    mov     word [bios_cursor], 0
    ret

; Prints an ASCII character to the BIOS framebuffer.
;
; Arguments:
; - %dl: the character.
;
; Clobbers: none
bios_putchar:
    pushf
    push    ax
    ; Move the character to `%ax` so we can put the row and column into `%dx`.
    mov     ax, dx
    mov     dx, [bios_cursor]
    ; Catch newlines.
    ;test    al, 0xa
    ;jne     .graphic
    jmp     .graphic
.newline:
    call    bios_newline
    jmp     .end
.graphic:
    push    bx
    push    cx
    push    ax
    ; Current stack:
    ; - [%sp - 2]: %ax (the character)
    ; - [%sp - 4]: %cx (caller-saved)
    ; - [%sp - 6]: %bx (caller-saved)
    ; - [%sp - 8]: %ax (caller-saved)
    ; - [%sp - 10]: flags (caller-saved)
.set_cursor_position:
    mov     ah, 0x2
    ; Set the page number.
    mov     bh, BIOS_PAGE
    ; Note: the BIOS will probably trash `%dx`, so we'll have to save it.
    push    dx
    ;int     0x10
    pop     dx
.inc_cursor:
    call    bios_inc_cursor
.print_char:
    ; Pop the character back into `%ax`.
    pop     ax
    mov     ah, 0x9
    ; We'll also set the color to 'light magenta'.
    mov     bx, ((BIOS_PAGE << 8) | 0xd)
    ; Print only one character.
    mov     cx, 1
    ; FIXME
    mov     ah, 0xe
    int     0x10
.end_graphic:
    pop     cx
    pop     bx
.end:
    pop     ax
    popf
    ret

; Prints a null-terminated ASCII string to the BIOS framebuffer.
;
; Arguments:
; - %bx: the address of the first byte in the string.
;
; Clobbers: none
bios_puts:
    push    cx
    push    dx
.loop:
    mov     cx, 0
    mov     cl, [bx]
    jcxz    .end
    mov     dl, cl
    call    bios_putchar
    inc     bx
    jmp     .loop
.end:
    pop     dx
    pop     cx
    ret
