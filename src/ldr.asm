org 0x7e00
bits 32

%include "mc/put.asm"
%define pdputs [_Pdputs]
;%define Dbg [_Dbg]
;%define Line [_Line]

COM equ 0x3f8	; COM1

start:
	mov ax, 0x10
	mov ds, ax
	mov ss, ax
	mov sp, 0x90000

	mov [_Pdputs], ebx
	mov [_Dbg], ecx
	mov [_Line], edx

	mov esi, OLdr
	call pdputs
	
	.checkCpuid:
		pushfd
		pop eax

		mov ecx, eax
		xor eax, 1 << 21 ; EFLAGS_ID

		push eax
		popfd
		pushfd
		pop eax

		push ecx
		popfd

		xor eax, ecx
		jz .cpuidUnsupported
		call .cpuidSupported

	.qeuryFeatures:
		mov eax, 0x80000000 ; CPUID_EXTENSIONS
		cpuid
		cmp eax, 0x80000001 ; CPUID_FEATURES
		jb .cpuidUnsupported
		call .cpuidSupported

	.queryLongmode:
		mov eax, 0x80000001 ; CPUID_FEATURES
		cpuid
		test edx, 1 << 29 ; CPUID_EDX_EXT_FEAT_LM
		jz .cpuidUnsupported
		call .cpuidSupported


	.disablePaging32:
		mov eax, cr0
		and eax, ~(1 << 31) ; CR0.PAGING
		mov cr0, eax
		mov esi, Cr3S
		call pdputs


PML4_ADDR equ 0x1000
PDRT_ADDR equ 0x2000
PDT_ADDR equ 0x3000

PRESENT equ 1 << 0
WRITABLE equ 1 << 1
USER equ 1 << 2
WRITE_THROUGH equ 1 << 3
CACHE_DISABLE equ 1 << 4
PS equ 1 << 7

	.pagetableIntiailize:
		; 0 ~ 0x1FFFFF => identity map, ring3 readable+executable
		mov edi, PML4_ADDR
		mov cr3, edi

		xor eax, eax
		mov ecx, 3072
		rep stosd

		.pml4Initialize:
			mov edi, PML4_ADDR
			mov dword [edi], PDRT_ADDR | PRESENT | WRITABLE

		.pdrtInitialize:
			mov edi, PDRT_ADDR
			mov dword [edi], PDT_ADDR | PRESENT | WRITABLE

		.pdtInitialize:
			mov edi, PDT_ADDR
			mov dword [edi], PRESENT | WRITABLE | USER | PS

		.setPae:
			mov eax, cr4
			or eax, 1 << 5 ; CR4.PAE
			mov cr4, eax
			mov si, Cr4S
			call pdputs

		.setLme:
			mov ecx, 0xc0000080 ; IA32_EFER
			rdmsr
			or eax, 1 << 8 ; EFER.LME
			wrmsr
			mov si, LmeS
			call pdputs

		.setPg:
			mov eax, cr0
			or eax, 1 << 31 ; CR0.PG
			mov cr0, eax
			cpuid ; Flushing
			mov si, PgS ; DBG
			call pdputs ; DBG

	jmp 0x18:abs lm

; functions
	.cpuidUnsupported:
		mov si, CpdF
		call pdputs
		cli
		hlt
		jmp $
	
	.cpuidSupported:
		mov si, CpdO
		call pdputs
		ret

bits 64
lm:
	mov ax, 0x20
	mov ds, ax

	mov rsi, Olm
	call qdputs
	
	cli
	hlt
	jmp $

qdputs:
	push rsi
	mov rsi, Dbg
	call qputs
	pop rsi
	call qputs
	mov rsi, Line
	call qputs

qputs:
	lodsb
	or al, al
	jz .done
	call qputc
	jmp qputs
.done:
	ret

qputc:
	push rdx
	push rax
.wait_:
	mov dx, COM+5
	in al, dx
	test al, 0x20
	jz .wait_
	mov dx, COM
	pop rax
	out dx, al
	pop rdx
	ret

Dbg		db "s:", 0
Line	db 0xd, 0xa, 0

OLdr db "OLdr", 0 ; On Loader
CpdF db "CpdF", 0 ; CPUID Failures
CpdO db "CpdO", 0 ; CPUID Okay
Cr3S db "Cr3S", 0 ; CR3 Seted
Cr4S db "Cr4S", 0 ; CR4 Seted
LmeS db "LmeS", 0 ; LME Seted
Olm  db "Olm",  0 ; On Long Mode
PgS  db "PgS",  0 ; PG Seted

_Pdputs dd 0xffffffff
_Dbg dq 0xffffffffffffffff
_Line dq 0xffffffffffffffff
