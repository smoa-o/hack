bits 64
org 0x100000

lm:
	mov ax, 0x28
	mov ds, ax
	
	mov rsi, Lm
	call sputs

	cli
	hlt
	jmp $

sputs:
	mov al, [rsi]
	inc rsi
	or al, al
	jz .done
	call sputc
	jmp sputs
.done:
	ret

sputc:
	push rdx
	push rax
.wait_:
	mov dx, 3fdh
	in al, dx
	test al, 20h
	jz .wait_

	pop rax
	sub dx, 5 ;0
	out dx, al
	pop rdx
	ret
	

Lm db "On IA-32e Mode", 0xd, 0xa, 0
