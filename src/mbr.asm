bits 16
org 7c00h
mbr:
	cli
	
	; Init UART, base=3f8
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

	mov si, Msg
	call sputs

	cli
	hlt
	jmp $

sputs:
	lodsb
	or al, al
	jz .done
	call putc
	jmp sputs
.done:
	ret

; base=3f8
putc:
	push dx
	push ax
.wait_:
	mov dx, 3fdh
	in al, dx
	test al, 20h
	jz .wait_

	pop ax
	sub dx, 5 ;0
	out dx, al
	pop dx
	ret

Msg db "On MBR", 0xd, 0xa, 0
times 510-($-$$) db 0
dw 0xaa55
