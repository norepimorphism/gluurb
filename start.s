; gluurb.

TEXT_BASE        equ 0x2000
TEXT_SIZE        equ 0x1000
TEXT_END         equ (TEXT_BASE + TEXT_SIZE)
; The offset of `stage_1` from `start`.
STAGE_1_OFF equ 16

%macro todo 0
    mov     dl, '~'
    call    bios_putchar
    hlt
%endmacro

start:
    jmp     stage_1

header:
    db      0xa
    db      'gluurb.'

; Pad with space until address `STAGE_1_OFF`.
times (STAGE_1_OFF - ($ - start) - 2) \
    db      ' '
    ; Terminate the string.
    db      0xa
    db      0
stage_1:
.enable_tiny_mode:
    push    cs
    pop     ds
.do_bios_init:
    call    bios_init
    ; We can now use `bios_puts` and `bios_putchar`.

    mov     si, (header + 1)
    call    bios_puts
    ; Print `1` to indicate that Stage 1 is running.
    mov     dl, '1'
    call    bios_putchar

    ; Now, we'll see if we need to rebase.

    ; This is a trick to obtain the IP.
    call    .get_ip
.get_ip:
    ; Pop the return address into `%si`.
    ;
    ; `%si` now contains the address of `.get_ip` in memory.
    pop     si
    ; Rebase `%si`.
    sub     si, .get_ip
    ; Check if we exist at the correct address.
    cmp     si, TEXT_BASE
    ; If yes, then we may continue on our merry way.
    je      stage_2
    ; Otherwise, we will try to rebase to `TEXT_BASE` and trampoline.
    ;
    ; We will check if there is overlap. In other words, the absolute distance between the current
    ; base and `TEXT_BASE` must be less than `TEXT_SIZE`. To calculate this absolute distance (or
    ; offset), we must be careful to subtract the smaller number from the bigger one.

    ; If we are before `TEXT_BASE`, go to `.too_low`; otherwise, go to `.too_high`.
    jg      .too_high
.too_low:
    ; `TEXT_BASE` is larger than `%si`.
    mov     ax, TEXT_BASE
    sub     ax, si
    jmp     .check_overlap
.too_high:
    ; `%si` is larger than `TEXT_BASE`.
    mov     ax, si
    sub     ax, TEXT_BASE
.check_overlap:
    cmp     ax, TEXT_SIZE
    ; If the absolute distance is greater than or equal to `TEXT_SIZE`, we can use
    ; `.rebase_nonoverlapping`.
    jge     .rebase_nonoverlapping
    ; Otherwise, we must use `.rebase_overlapping`.

%define trampoline_to_stage_2 \
    jmp     (TEXT_BASE + stage_2)

.rebase_overlapping:
    todo
    trampoline_to_stage_2
.rebase_nonoverlapping:
    ; This is  a `memcpy` that moves eight bytes at a time.
    mov     di, TEXT_BASE
.rebase_nonoverlapping_loop:
    mov     dl, '.'
    call    bios_putchar

    mov     ax, [si + 0]
    mov     bx, [si + 2]
    mov     cx, [si + 4]
    mov     dx, [si + 6]
    mov     [di + 0], ax
    mov     [di + 2], bx
    mov     [di + 4], cx
    mov     [di + 6], dx
    add     si, 8
    add     di, 8
    cmp     di, (TEXT_BASE + TEXT_SIZE)
    jl      .rebase_nonoverlapping_loop
    trampoline_to_stage_2

stage_2:
    ; Print `2` to indicate that Stage 2 is running.
    mov     dl, '2'
    call    bios_putchar

    todo
    jmp     main

%include    'bios.s'

text_base:
    dw      TEXT_BASE
text_size:
    dw      TEXT_SIZE
text_end:
    dw      TEXT_END

main:
    todo
