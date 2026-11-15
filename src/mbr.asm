bits 16
org 7c00h
mbr:
	cli

	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ah, 2
	mov al, 1 ; Count
	mov bx, 0x7e00
	xor ch, ch
	mov cl, 2 ; Start Sector
	xor dh, dh
	int 13h
	jc .error
	
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

	mov si, Orm
	call sputs

	lgdt [GdtDesc]

	mov si, GdtL
	call sputs

	in al, 92h
	or al, 2
	out 92h, al

	mov si, A20
	call sputs

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp 0x8:pm

	mov si, Bfj ; Bad Far Jump
	call sputs

	cli
	hlt
	jmp $

.error:
	mov si, ATE
	call sputs
	cli
	hlt
	jmp $

bits 32
pm:
	mov ax, 10h
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000

	mov esi, Opm
	call p_sputs

	cli
	hlt
	jmp $

p_sputs:
	mov al, [ds:esi]
	inc esi
	or al, al
	jz .done
	call p_sputc
	jmp p_sputs
.done:
	ret

p_sputc:
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

bits 16

sputs:
	lodsb
	or al, al
	jz .done
	call sputc
	jmp sputs
.done:
	ret

; base=3f8
sputc:
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

Orm db "s:Orm", 0xd, 0xa, 0 ; On Realmode
Bfj db "s:Bfj", 0xd, 0xa, 0 ; Bad Far Jump
Opm  db "s:Opm", 0xd, 0xa, 0 ; on Protected Mode
GdtL db "s:GdtL", 0xd, 0xa, 0 ; GDT Loaded
A20 db "s:A20", 0xd, 0xa, 0 ; A20 Seted
ATE db "s:ATE", 0xd, 0xa, 0 ; ATA Error

Gdt:
	dq 0
	dq 0x00CF9A000000FFFF
	dq 0x00CF92000000FFFF
GdtDesc:
	dw GdtDesc - Gdt - 1
	dd Gdt

times 510-($-$$) db 0
dw 0xaa55
