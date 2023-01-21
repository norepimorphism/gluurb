; gluurb.

CPU 8086

TEMP_STACK_SIZE  equ 0x100

TEXT_SEGMENT     equ 0x100
TEXT_BASE        equ 0x2000
TEXT_SIZE        equ 0x1000
TEXT_END         equ (TEXT_BASE + TEXT_SIZE)

%ifdef ENABLE_BIOS
extern bios_init
extern bios_putchar
extern bios_puts
%endif

%macro todo 0
%ifdef ENABLE_BIOS
    mov     byte al, '~'
    call    bios_putchar
%endif
    hlt
%endmacro

start:
    jmp     stage_1

header:
    db      0xa
    db      'gluurb.'
    ; Terminate the string.
    db      0xa
    db      0

temp_stack:
; Pad with space until `stage_1`.
times TEMP_STACK_SIZE \
    db      0
align 8
stage_1:
    ; TODO: switch to Real Mode if in Protected Mode.
    mov     word cx, cs

%ifdef ENABLE_TEMP_STACK
.init_temp_stack:
    ; Our temporary stack will flow downward from `stage_1`, (unfortunately) overwriting our
    ; beautiful 'gluurb.' header.
    mov     word ss, cx
    ; Don't overwrite `%cx`; we need it later.
    lea     bx, cs:[stage_1]
    mov     word sp, bx
%endif

%ifdef ENABLE_BIOS
.do_bios_init:
    call    bios_init
    ; We can now use `bios_puts` and `bios_putchar`.

    ; Print `1` to indicate that Stage 1 is running.
    mov     byte al, '1'
    call    bios_putchar
    ; Print the 'gluurb.' header.
    lea     si, cs:[header]
    call    bios_puts
%endif

%ifdef REBASE
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

    ; Check if we exist at the correct location.
    ; TODO: because segmented addressing is so fucked up and there are 2^12 (4096) ways to represent
    ; the same physical address as a logical address, we must convert to `%si` to a physical
    ; address.
.check_segment:
    ; Remember: `%cx` contains the current value of `%cs`.
    cmp     cx, TEXT_SEGMENT
    je      .check_address
    cmp     si, start
    jmp     rebase
.check_address:
    cmp     si, start
    ; If they match, we may continue on our merry way.
    je     stage_2
    ; Otherwise, continue to rebase.

rebase:
    ; We will try to rebase to `TEXT_BASE` and trampoline.
    ;
    ; If there is no overlap, we can do a simple `memcpy`. If there is overlap, we'll resort to a
    ; `memmove`. We are overlapping if the absolute distance between the current base and
    ; `TEXT_BASE` is less than `TEXT_SIZE`. To calculate this absolute distance (or offset), we must
    ; be careful to subtract the smaller number from the bigger one.

    ; If we are before `TEXT_BASE`, go to `.too_low`; otherwise, go to `.too_high`.
    jg      .too_high
.too_low:
    ; `TEXT_BASE` is larger than `%si`.
    mov     word ax, TEXT_BASE
    sub     ax, si
    jmp     .check_overlap
.too_high:
    ; `%si` is larger than `TEXT_BASE`.
    mov     word ax, si
    sub     ax, TEXT_BASE
.check_overlap:
    cmp     ax, TEXT_SIZE
    ; If the absolute distance is greater than or equal to `TEXT_SIZE`, we can use
    ; `.rebase_nonoverlapping`.
    jge     .rebase_nonoverlapping
    ; Otherwise, we must use `.rebase_overlapping`.
.rebase_overlapping:
    ; This is a `memmove`.
    todo
    jmp     .trampoline
.rebase_nonoverlapping:
    ; This is  a `memcpy` that moves eight bytes at a time.
    mov     word di, TEXT_BASE
.rebase_nonoverlapping_loop:
%ifdef ENABLE_BIOS
    mov     byte al, '.'
    call    bios_putchar
%endif

    mov     word ax, cs:[si + 0]
    mov     word bx, cs:[si + 2]
    mov     word cx, cs:[si + 4]
    mov     word dx, cs:[si + 6]
    mov     word cs:[di + 0], ax
    mov     word cs:[di + 2], bx
    mov     word cs:[di + 4], cx
    mov     word cs:[di + 6], dx
    add     si, 8
    add     di, 8
    cmp     di, (TEXT_BASE + TEXT_SIZE)
    jl      .rebase_nonoverlapping_loop
.trampoline:
    jmp     word TEXT_SEGMENT:(TEXT_BASE + stage_2)
%endif ; REBASE

stage_2:
%ifdef ENABLE_BIOS
    ; Print `2` to indicate that Stage 2 is running.
    mov     byte al, '2'
    call    bios_putchar
%endif

    todo
    jmp     main

align 2
text_base:
    dw      TEXT_BASE
text_size:
    dw      TEXT_SIZE
text_end:
    dw      TEXT_END

align 8
main:
    todo
