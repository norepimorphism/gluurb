TARGET := gluurb.bin
SRCS := $(wildcard *.s)

AS := nasm

all: $(TARGET)

$(TARGET): $(SRCS)
	$(AS) -f bin start.s -o $@
