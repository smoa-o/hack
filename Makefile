SRC ?= src
BIN ?= bin
DSK ?= dsk
AUTOGEN ?= $(BIN) $(DSK)

NASMFLAGS ?= -w+all
QEMUFLAGS ?=
DEFQEMUFLAGS ?= -boot a -D qemu.log \
	-drive file=dsk/boot.img,format=raw,if=floppy,index=0

all: ready run
dev: ready run-dev

ready: reset compile write

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
compile: $(BIN)/mbr.a.bin $(BIN)/ldr.a.bin $(BIN)/lm.a.bin

$(BIN)/%.a.bin: $(SRC)/%.asm
	nasm $(NASMFLAGS) -f bin $< -o $@

# Writing
write: wrdsk-boot

wrdsk-boot: $(DSK)/boot.img
	dd if=$(BIN)/mbr.a.bin of=$< bs=512 count=1 conv=notrunc
	dd if=$(BIN)/lm.a.bin  of=$< bs=512 count=1 conv=notrunc seek=1

# Running
run:
	qemu-system-x86_64 $(DEFQEMUFLAGS) -vnc :1 -serial stdio $(QEMUFLAGS) &
	websockify --web=$(HOME)/git-project/noVNC 6080 localhost:5901 &
	echo "Already."

run-dev:
	qemu-system-x86_64 $(DEFQEMUFLAGS) $(QEMUFLAGS) --nographic -monitor stdio \
		-s -S -serial tcp:127.0.0.1:5555,server,nowait

.PHONY: all run
