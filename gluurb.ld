SECTIONS {
    .text : {
        start.o;
        bios.o;
        * (.text);
    }
    .data : { * (.data); }

    . = 0x1000;
}
