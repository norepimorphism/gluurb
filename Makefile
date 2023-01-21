TARGET := gluurb.bin
SRCS := start.s bios.s bios.c

AS := nasm
CC := clang

.PHONY: rebuild build clean

all: build

rebuild: clean build

build: $(TARGET)

$(TARGET): start.o bios.o bios.c
	$(CC) $^ -o $@ -m16

%.o: %.s
	$(AS) -f win32 $< -o $@ -dENABLE_TEMP_STACK -dENABLE_BIOS

clean:
	rm $(TARGET) start.o bios.o
