SRC ?= src
BIN ?= bin
DSK ?= dsk
AUTOGEN ?= $(BIN) $(DSK)

NASMFLAGS ?= -w+all
QEMUFLAGS ?=

all: reset compile write run

# Reseting
kill-vnc:
	-pkill -f qemu-system-x86_64
	-pkill -f websockify

clean:
	rm -rf $(AUTOGEN)

mkdirs:
	mkdir -p $(AUTOGEN)

crtdsk: crtdsk-boot

crtdsk-boot: $(DSK)/boot.img
	dd if=/dev/zero of=$< bs=512 count=2880 conv=notrunc
$(DSK)/boot.img:

reset: kill-vnc clean mkdirs crtdsk

# Compiling
compile: $(BIN)/mbr.a.bin $(BIN)/lm.a.bin

$(BIN)/%.a.bin: $(SRC)/%.asm
	nasm $(NASMFLAGS) -f bin $< -o $@

# Writing
write: wrdsk-boot

wrdsk-boot: $(DSK)/boot.img
	dd if=$(BIN)/mbr.a.bin of=$< bs=512 count=1 conv=notrunc
	dd if=$(BIN)/lm.a.bin  of=$< bs=512 count=1 conv=notrunc seek=1

# Running
run:
	qemu-system-x86_64 -boot a -D qemu.log -vnc :1 $(QEMUFLAGS) \
		-drive file=dsk/boot.img,format=raw,if=floppy,index=0 -serial stdio &
	websockify --web=$(HOME)/git-project/noVNC 6080 localhost:5901 &
	echo "Already."

.PHONY: all run
