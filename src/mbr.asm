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
	hlt
	jmp $

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

times 510 - ($-$$) db 0
dw 0xaa55
