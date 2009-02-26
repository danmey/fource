#include "const.h"
#include "dict.h.S"
#include "ccall.h.S"
	
.data
	Defvar state, "state", VM_STATE_INTERPRETING
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
	Defword body,"body>"
		# Get the body of the word
		addl	$Word_header_size,%eax
	Endword
	Defword lsqbracket, "]"
		movl	$VM_STATE_COMPILING, var_state
	Endword

	Defword rqbracket, "[", IMMEDIATE_WORD
		movl	$VM_STATE_INTERPRETING, var_state
	Endword

	Defword compile,"compile"
		pusha
		mov	var_here,%edi
		C_Call_safe Emit_sub_call
		popa
		pop	%eax
	Endword

	Defword epilog,"epilog"
		pusha
		movl	$(Ret_code_end-Ret_code),%ecx
		movl	$Ret_code,	%esi
		movl	var_here,	%edi	
		rep	movsb
		popa
	Endword
	
	Defword execute,"execute"
		call	wcode_body
		mov	%eax,	%edx
		pop	%eax
		xchg	%esi,%esp
		pushl	$1f
		push	%edx
	1:	
	 	xchg	%esi,%esp
	Endword
	
	Defword create, "create"
		xchg	%esi,%esp
		C_Call_safe	Get_word
		pusha
		movl	var_here,	%edi
		movl	$Token_buffer,	%esi
		movl	var_last,%eax
		push	%edi
		stosl
		mov	$1, 	%eax
		mov	$32,	%ecx
	1:
		or	%eax,%eax
		jz	3f
		lodsb
	3:
		stosb
		dec	%ecx
		jnz	1b
		stosl
		movl	$wcode_compile,%eax
		stosl
		movl	$wcode_execute,%eax
		stosl
		## movl	$(Test_code_end-Test_code),%ecx
		## movl	$Test_code,	%esi
		## rep	movsb
		movl	%edi,	var_here
		pop	%edi
		mov	%edi,var_last
		popa
		xchg	%esi,%esp
	Endword
	
	Defvar  base, "base", 10
	Defvar last, "last", wstart_last
	.align	4
Cells:
	.FILL 1024*1024

Ret_code:	
	xchg	%esi,	%esp
	ret
Ret_code_end:	
Test_code:
	xchg	%esi,	%esp
	push	%eax
	mov	$123,%eax
	xchg	%esi,	%esp
	ret
Test_code_end:

	

