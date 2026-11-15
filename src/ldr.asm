bits 32
org 0x7e00

PGT equ 0x200000

loader:
	; esi: sputs
	; edi: sputc
	; ebx: Pm

	mov [Sputs], esi
	mov [Sputc], edi

	mov esi, ebx
	call [Sputs]

	; Page Table
	; Clean
	mov edi, PGT
	xor eax, eax
	mov ecx, 3072
	cld
	rep stosd
	mov esi, Pc
	call [Sputs]

	; PML4
	mov dword [PGT], 0x201003
	mov esi, Ppml4
	call [Sputs]

	; PDPT
	mov dword [PGT+0x1000], 0x202003
	mov esi, Ppdpt
	call [Sputs]

	; PD
	mov dword [PGT+0x2000], 83h
	mov dword [PGT+0x2008], 0x200083
	mov esi, Ppd
	call [Sputs]

	mov eax, PGT
	mov cr3, eax
	mov esi, C3L
	call [Sputs]

	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax
	mov esi, Pae
	call [Sputs]

	mov ecx, 0xc0000080
	rdmsr
	or eax, 1 << 8
	wrmsr
	mov esi, PgL
	call [Sputs]

	jmp 0x20:0x100000

Sputs dd 0
Sputc dd 0

Pc  db "Pagetable Cleaned", 0xd, 0xa, 0
Ppml4 db "PML4 Loaded", 0xd, 0xa, 0
Ppdpt db "PDPT Loaded", 0xd, 0xa, 0
Ppd db "PD Loaded", 0xd, 0xa, 0
C3L db "CR3 Loaded", 0xd, 0xa, 0
Pae db "PAE Seted", 0xd, 0xa, 0
Lme db "LME Seted", 0xd, 0xa, 0
PgL db "PG Seted", 0xd, 0xa, 0
