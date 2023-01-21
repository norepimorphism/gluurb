#define MAX_ROW 20
#define MAX_COL 20

typedef unsigned char u8;

extern u8 bios_cursor_row;
extern u8 bios_cursor_col;

// These signatures are probably f*cked up... I don't know enough about __cdecl to know.
extern void bios_newpage();
extern void bios_flush_cursor();
extern void bios_print_char(short);

// Moves the cursor to the start of the next line, clearing the page if necessary.
void bios_newline() {
    if (bios_cursor_row >= MAX_ROW) {
        bios_newpage();
        return;
    }

    bios_cursor_row++;
    bios_cursor_col = 0;
}

// Increments the cursor for the next character, inserting a new line or clearing the page if
// necessary.
void bios_inc_cursor() {
    if (bios_cursor_col >= MAX_COL) {
        bios_newline();
        return;
    }

    bios_cursor_col++;
}

// Prints an ASCII character to the BIOS framebuffer.
void bios_putchar(const short c) {
    if (c == '\n') {
        bios_newline();
        return;
    }

    bios_flush_cursor();
    bios_inc_cursor();
    bios_print_char(c);
}

// Prints a null-terminated ASCII string to the BIOS framebuffer.
void bios_puts(const char *s) {
    for (const char c = s[0]; c != 0; s++)
        bios_putchar(c);
}
