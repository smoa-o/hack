bits 16
org 0x7c00

COM equ 0x3f8 ; COM1

start:
	xor ax, ax
	mov ds, ax
	
	; base=COM

	; Init COM1
	mov dx, 3f9h
	xor al, al
	out dx, al ; Close Interrupt
	
	add dx, 2 ;+3
	mov al, 80h
	out dx, al ; DLAB=1
	
	sub dx, 3 ;+0
	mov al, 3
	out dx, al ; Low

	inc dx ;1
	xor al, al
	out dx, al ; Low

	add dx, 2 ;+3
	mov al, 3
	out dx, al ; 8N1, DLAB=0

	mov dx, 3fah
	mov al, 0xc7
	out dx, al

	; Testing
	mov al, 0x1e
	out dx, al ;+4,
	mov dx, COM
	mov al, 0xae
	
	in al, dx
	cmp al, 0xae
	je .comOkay
	
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
	mov [0x600], 0xff

	cli
	hlt
	jmp $

	.comOkay: ; tag
	
	add dx, 4 ;+4
	mov al, 0xf
	out dx, al

	;mov al, 'A'
	;call putc

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

	lgdt [GdtDesc]
	mov si, GdtL
	call dputs

	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp 8:pm

bits 32
pm:
	mov esi, Opm
	call dputs

	.enableA20:
		call .a20WaitIE
		mov al, 0xd0
		out 0x64, al

		call .a20WaitOF
		in al, 0x60
		push eax

		call .a20WaitIE
		mov al, 0xd1
		out 0x64, al

		call .a20WaitIE
		pop eax
		or al, 2
		out 0x60, al ; Activate A20

		call .a20WaitIE
		mov al, 0xae
		out 0x64, al ; Reactivate

		sti
		mov esi, A20S
		call pdupts

	.enableNMI:
		in al, 0x70
		and al, 0x7f
		out 0x70, al

	cli
	hlt
	jmp $

; functions
	.a20WaitIE: ; Input Empty
		in al, 0x64
		test al, 2
		jnz .a20WaitIE
		ret
	.a20WaitOF: ; Output Full
		in al, 0x64
		test al, 1
		jz .a20WaitOF
		ret

pdupts:
	push esi
	mov esi, Dbg
	call puts
	pop esi
	call puts
	mov esi, Line
	call puts
	ret

bits 16

dputs:
	push si
	mov si, Dbg
	call puts
	pop si
	call puts
	mov si, Line
	call puts
	ret

puts:
	lodsb
	or al, al
	jz .done
	call putc
	jmp puts
.done:
	ret

putc:
	; base=PORT
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

Dbg  db "s:", 0
Line db 0xd, 0xa, 0

Init db "Init", 0
IDis db "IDis", 0 ; Interrupting Disabled
GdtL db "GdtL", 0 ; GDT Loaded
A20S db "A20S", 0 ; A20 Seted
Opm  db "Opm",  0 ; On Protected Mode

Gdt:
	dq 0
	dq 0x00CF9A000000FFFF ; 32-bit ring0 code
	dq 0x00CF92000000FFFF ; 32-bit Ring0 data
GdtDesc:
	dw GdtDesc - Gdt - 1
	dd Gdt

times 510 - ($-$$) db 0
dw 0xaa55
