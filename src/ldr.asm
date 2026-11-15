bits 32
org 0x7e00

PGT equ 0x200000

loader:
	; esi: sputs
	; edi: sputc
	
	jmp 0x28:0x100000
