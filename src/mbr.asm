bits 16
org 0x7c00

COM equ 0x3f8	; COM1

start:
	xor ax, ax
	mov ds, ax

	; Init COM1
	mov dx, 0x3f9
	xor al, al
	out dx, al	; IER = 0, close interrupt

	mov dx, 0x3fb
	mov al, 0x80
	out dx, al	; LCR: DLAB=1

	mov dx, 0x3f8
	mov al, 3
	out dx, al	; DLL = 3 (38400 baud)

	mov dx, 0x3f9
	xor al, al
	out dx, al	; DLM = 0

	mov dx, 0x3fb
	mov al, 3
	out dx, al	; LCR: 8N1, DLAB=0

	mov dx, 0x3fa
	mov al, 0xc7
	out dx, al	; FCR: enable FIFO, clear

	; Loopback self-test
	mov dx, 0x3fc
	mov al, 0x1e
	out dx, al	; MCR: LOOP=1, RTS/DTR/OUT2=1

	mov dx, 0x3f8
	mov al, 0xae
	out dx, al	; THR: send test byte

	; Wait for data ready
	mov cx, 0xffff
	.wait_lb:
		mov dx, 0x3fd
		in al, dx
		test al, 1
		jnz .read_lb
		loop .wait_lb
		jmp .comFail

	.read_lb:
		mov dx, 0x3f8
		in al, dx
		cmp al, 0xae
		jne .comFail

	; Loopback OK, disable loopback
	mov dx, 0x3fc
	mov al, 0x0f
	out dx, al	; MCR: LOOP=0, OUT2=1

	jmp .comOkay

	.comFail:
		; Beep + halt on failure
		in al, 0x61
		or al, 3
		out 0x61, al
		mov ecx, 0xffffff
		.soundLoop:
			dec ecx
			jnz .soundLoop
		in al, 0x61
		and al, 0xfc
		out 0x61, al
		mov byte [0x600], 0xff
		cli
		hlt
		jmp $

	.comOkay: ; tag
	
	mov si, Init
	call dputs
	
	cli
	mov al, 0x80
	out 0x70, al
	.a20Wait:
		in al, 0x64
		test al, 2
		jnz .a20Wait
	mov al, 0xad
	out 0x64, al
	mov si, IDis
	call dputs

	.enableA20:
		call .a20WaitIE
		mov al, 0xd0
		out 0x64, al
		
		call .a20WaitOF
		in al, 0x60
		push ax
		
		call .a20WaitIE
		mov al, 0xd1
		out 0x64, al
		
		call .a20WaitIE
		pop ax
		or al, 2
		out 0x60, al
		
		call .a20WaitIE
		mov al, 0xae
		out 0x64, al

	sti
	
	mov si, A20S
	call dputs
	
	lgdt [GdtDesc]
	mov si, GdtL
	call dputs

	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp 8:pm

; funciton
	.a20WaitIE:
		in al, 0x64
		test al, 2
		jnz .a20WaitIE
		ret

	.a20WaitOF:
		in al, 0x64
		test al, 1
		jz .a20WaitOF
		ret

bits 32
pm:
	;hlt ; DBG
	;jmp $ ; DBG
	mov ax, 0x10
	mov ds, ax
	mov ss, ax
	mov esp, 0x90000
	mov esi, Opm
	call pdputs

	.enableNMI:
		in al, 0x70
		and al, 0x7f
		out 0x70, al

	cli
	hlt
	jmp $

; functions

bits 16

%macro PUT 4
%1:
	push %3
	mov %3, Dbg
	call %2
	pop %3
	call %2
	mov %3, Line
	call %2
	ret

%2:
	lodsb
	or al, al
	jz .done
	call %4
	jmp %2
.done:
	ret

%4:
	push dx
	push ax
.wait_:
	mov dx, COM+5
	in al, dx
	test al, 0x20
	jz .wait_
	mov dx, COM
	pop ax
	out dx, al
	pop dx
	ret
%endmacro

PUT dputs, puts, si, putc

bits 32
PUT pdputs, pputs, esi, pputc

Dbg		db "s:", 0
Line	db 0xd, 0xa, 0

Init	db "Init", 0
IDis	db "IDis", 0
GdtL	db "GdtL", 0
A20S	db "A20S", 0
Opm		db "Opm", 0

Gdt:
	dq 0
	dq 0x00CF9A000000FFFF
	dq 0x00CF92000000FFFF
GdtDesc:
	dw GdtDesc - Gdt - 1
	dd Gdt

%warning %($ - $$%)

times 510 - ($-$$) db 0
dw 0xaa55
