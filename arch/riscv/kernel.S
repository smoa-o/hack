.section .text
.global start

.equ COM1, 0x10000000
.equ UART, COM1

start:
	csrrc zero, mstatus, 8
	li sp, 0x87F00000
	
	li x5, UART
	sb zero, 1(x5)
	li x6, 0x80 # [c
	sb x6, 3(x5)
	li x6, 3
	sb x6, 0(x5)
	sb zero, 1(x5)
	sb x6, 3(x5)
	li x6, 0xc7 # c]
	sb x6, 2(x5)

	# Loopback self-test
.if 0
	li x6, 0x5e # c
	sb x6, 4(x5)
	li x6, 0xae # c
	sb x6, 0(x5)
	
	li x6, 0xffff
	.wait_lb:
		lb x7, 5(x5) # c
		li x8, 1 # c
		and x7, x7, x8
		beq x7, x8, .read_lb
		addi x6, x6, -1
		bne x6, zero, .wait_lb
		j .comFail
	# un 5

	.read_lb:
		lb x6, 0(x5) # cache
		li x7, 0xae # cache
		bne x6, x7, .comFail
		li x6, 0xf # c
		sb x6, 4(x5)
		j .comOkay

	.comFail:
		li x6, 0xff
		sb x6, 0(zero)

		wfi
		0:
			j 0b
.endif

	.comOkay: # tag

	la x20, Init
	jal ra, dputs

	wfi
	l1:
		j l1

dputs:
	addi sp, sp, -16
	sd ra, 8(sp)
	sd x20, 0(sp)

	la x20, Dbg
	jal ra, puts

	ld x20, 0(sp)
	addi sp, sp, 8
	jal ra, puts

	la x20, Line
	jal ra, puts

	ld ra, 0(sp)
	addi sp, sp, 8
	jalr zero, 0(ra)

puts:
	addi sp, sp, -8
	sd ra, 0(sp)
.loop:
	lbu x25, 0(x20)
	addi x20, x20, 1
	beqz x25, .done

	addi sp, sp, -8
	sd x20, 0(sp)
	mv x20, x25 # cache
	jal ra, putc
	ld x20, 0(sp)
	addi sp, sp, 8
	
	j .loop
.done:
	ld ra, 0(sp)
	addi sp, sp, 8
	jalr zero, 0(ra)

putc:
	addi sp, sp, -8
	sd ra, 0(sp)

	li x25, COM1

	.wait:
		lb x26, 5(x25) # cache
		andi x27, x26, 0x20 # cache
		beqz x27, .wait

	sb x20, 0(x25)
	
	ld ra, 0(sp)
	addi sp, sp, 8
	jalr zero, 0(ra)

.section .data

Dbg: .string "s:"
Line: .byte 0xd, 0xa, 0

Init: .string "Init"
