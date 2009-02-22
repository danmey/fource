#include "dict.h.S"

	Defvar state, "state", VM_STATE_COMPILING
	# Pointer to last word
	Defvar here, "here", Cells
	## We use subroutine threading and TOS optimizations
	## %esi contain our parameter stack and %eax TOS
	Defword plus, "+"
		add	%eax,(%esp)
		pop	%eax
	Endword
	.GLOBL wcode_dot
	Defword dot, "."
		pusha
		push	%eax
		push	$Fmt_dec
		call	printf
	 	add	$8,%esp
		popa
		pop	%eax
	Endword
	
	Defvar  base, "base", 10
	Defvar last, "last", wstart_last

Cells:
	.FILL 1024*1024

	

