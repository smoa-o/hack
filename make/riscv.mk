ARCH ?= arch
SRC ?= $(ARCH)/riscv
BIN ?= $(ARCH)/bin
AUTOGEN ?= $(BIN)

CC ?= clang
LD ?= ld.lld
OBJCOPY ?= llvm-objcopy

CFLAGS ?=
DEFCFLAGS ?= -target riscv64 -march=rv64gc -mabi=lp64 -nostdlib -static

LDFLAGS ?=
DEFLDFLAGS ?= -Ttext=0x80000000

QEMUFLAGS ?=
DEFQEMUFLAGS ?= -machine virt -bios none

all: ready run
dev: ready run-dev

ready: mkdirs compile

# Cleaning
clean:
	rm -rf $(AUTOGEN)

mkdirs:
	mkdir -p $(BIN)

# Compiling
compile: $(BIN)/kernel.bin

$(BIN)/kernel.tmp: $(SRC)/kernel.S
	$(CC) $(CFLAGS) $(DEFCFLAGS) -c $< -o $(BIN)/kernel.o
	$(LD) $(LDFLAGS) $(DEFLDFLAGS) $(BIN)/kernel.o -o $@

$(BIN)/kernel.bin: $(BIN)/kernel.tmp
	$(OBJCOPY) -O binary $< $@

# Running
run:
	qemu-system-riscv64 $(DEFQEMUFLAGS) \
		-device loader,file=$(BIN)/kernel.bin,addr=0x80000000 \
		$(QEMUFLAGS)

run-dev:
	qemu-system-riscv64 $(DEFQEMUFLAGS) \
		-device loader,file=$(BIN)/kernel.bin,addr=0x80000000 -display none \
		$(QEMUFLAGS) -s -S -monitor stdio -serial tcp:127.0.0.1:5555,server,nowait

.PHONY: all run dev ready clean mkdirs compile
