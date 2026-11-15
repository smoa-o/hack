bits 16
org 0x7e00

Sputs dd 0

%define sputs [Sputs]

lmain:
	mov esi, ALdr
	call sputs

	.checkCpuid:
		pushfd
		pop eax

		mov ecx, eax
		xor eax, 1 << 21

		push eax
		
		popfd
		pushfd

		pop eax

		push ecx
		popfd

		xor eax, ecx
		jz .cpuidUnsupported
		jmp .queryLongmode

		.cpuidUnsupported:
			mov esi, NCpd
			call sputs
			jmp .error

	.queryLongmode:
		mov eax, 0x80000000
		cpuid
		cmp eax, 0x80000001
		jb .longmodeUnsupported

		.extFeaturesUnsupported:
			mov esi, NExF
			call sputs
			jmp .error

		.checkLongmode:
			mov eax, 0x80000001
			cpuid
			test edx, 1 << 19 ; LM
			jz .longmodeUnsupported

			.longmodeUnsupported:
				mov esi, NLm
				call sputs
				jmp .error

.error:
	cli
	hlt
	jmp $

ALdr db "s:ALdr", 0xd, 0xa, 0 ; At Loader
NCpd db "s:NCpd", 0xd, 0xa, 0 ; Not Supported CPUID
NExF db "s:NExF", 0xd, 0xa, 0 ; Not Extension Features
NLm  db "s:NLm",  0xd, 0xa, 0 ; Not Longmode

