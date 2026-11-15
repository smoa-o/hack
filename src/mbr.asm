bits 16
org 7c00h
mbr:
	cli

	mov [BootDrive], dl
	
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

bits 32
pm:
	mov ax, 10h
	mov ds, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x90000
	mov ax, 18h
	mov es, ax

	mov esi, Pm
	call p_sputs

	mov eax, cr0
	and eax, ~1
	mov cr0, eax
	jmp 0:.urm

bits 16
.urm: ; Unreal Mode
	mov si, Urm
	call sputs

	sti
	mov ah, 2
	mov al, 1 ; Count
	xor bx, bx ; ES:BX => 1M
	mov ch, 0
	mov cl, 2; Start Sector
	xor dx, dx
	mov dl, [BootDrive]
	int 13h
	jc .error

	mov si, Rds
	call sputs

	push ax
	xor ax, ax
	mov es, ax
	pop ax

	mov si, Rm
	call sputs

	add bx, 0x7e00
	int 13h
	jc .error
	mov si, Rds
	call sputs

	mov esi, p_sputs
	mov edi, p_sputc

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x8:0x7e00

	;cli
	;hlt
	;jmp $
.error:
	mov si, Rde
	call p_sputs
	cli
	hlt
	jmp $

%if 0
bits 32
PGT equ 0x200000
.pm:
	mov esi, Pm
	call p_sputs

	; Page Table
	; Clean
	mov edi, PGT
	xor eax, eax
	mov ecx, 3072
	cld
	rep stosd
	mov esi, Pc
	call p_sputs

	; PML4
	mov dword [PGT], 0x201003
	mov esi, Ppml4
	call p_sputs

	; PDPT
	mov dword [PGT+0x1000], 0x202003
	mov esi, Ppdpt
	call p_sputs

	; PD
	mov dword [PGT+0x2000], 83h
	mov dword [PGT+0x2008], 0x200083
	mov esi, Ppd
	call p_sputs

	mov eax, PGT
	mov cr3, eax
	mov esi, C3L
	call p_sputs

	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax
	mov esi, Pae
	call p_sputs

	mov ecx, 0xc0000080
	rdmsr
	or eax, 1 << 8
	wrmsr
	mov esi, PgL
	call p_sputs

	jmp 0x20:0x100000
%endif

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

Msg db "On Real Mode", 0xd, 0xa, 0
Bfj db "Bad Far Jump", 0xd, 0xa, 0
Pm  db "On Protect Mode", 0xd, 0xa, 0
GdtL db "Gdt Loaded", 0xd, 0xa, 0
A20 db "A20 Seted", 0xd, 0xa, 0
Urm db "On Unreal Mode", 0xd, 0xa, 0
Rde db "Read Error", 0xd, 0xa, 0
Rds db "Read Success", 0xd, 0xa, 0
Rm  db "On Real Mode", 0xd, 0xa, 0
Pc  db "Pagetable Cleaned", 0xd, 0xa, 0
Ppml4 db "PML4 Loaded", 0xd, 0xa, 0
Ppdpt db "PDPT Loaded", 0xd, 0xa, 0
Ppd db "PD Loaded", 0xd, 0xa, 0
C3L db "CR3 Loaded", 0xd, 0xa, 0
Pae db "PAE Seted", 0xd, 0xa, 0
Lme db "LME Seted", 0xd, 0xa, 0
PgL db "PG Seted", 0xd, 0xa, 0

BootDrive db 0

Gdt:
	dq 0
	
	; Protected Mode
	dq 0x00CF9A000000FFFF
	dq 0x00CF92000000FFFF

	; Unreal Mode
	dq 0x00CF920010000000

	; Long Mode
	dq 0x0020980000000000
	dq 0x0000920000000000
GdtDesc:
	dw GdtDesc - Gdt - 1
	dd Gdt

times 510-($-$$) db 0
dw 0xaa55
