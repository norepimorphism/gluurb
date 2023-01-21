BIOS_PAGE   equ 0
MAX_ROW     equ 20
MAX_COL     equ 20

align 2
bios_cursor:
; Note: x86 is little-endian, so these need to be swapped.
bios_cursor_col:
    db      0
bios_cursor_row:
    db      0



align 8
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
    mov     word ax, ((0x05 << 8) | BIOS_PAGE)
    int     0x10
.init_cursor:
    mov     byte ah, 0x2
    ; Set the page number.
    mov     byte bh, BIOS_PAGE
    ; Set the row and column to zero.
    ; Note: we don't really want `xor dx, dx` here because that would require us to preserve flags.
    mov     word dx, 0
    int     0x10
.end:
    pop     dx
    pop     bx
    pop     ax
    ret

; Sets the cursor to the top-left corner.
;
; Arguments: none
;
; Clobbers: none
bios_newpage:
    mov     word cs:[bios_cursor], 0
    ret

bios_flush_cursor:
    push    ax
    push    bx
    push    dx
    mov     byte ah, 0x2
    ; Set the page number.
    mov     byte bh, BIOS_PAGE
    mov     word dx, [bios_cursor]
    int     0x10
    pop     dx
    pop     bx
    pop     ax
    ret

bios_print_char:
    push    ax
    push    bx
    push    cx
    mov     byte ah, 0x9
    ; We'll also set the color to 'light magenta'.
    mov     word bx, ((BIOS_PAGE << 8) | 0xd)
    ; Print only one character.
    mov     word cx, 1
    int     0x10
    pop     cx
    pop     bx
    pop     ax
    ret
