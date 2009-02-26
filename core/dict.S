#include "const.h"
#include "dict.h.S"
#include "ccall.h.S"
#include "continuation.h.S"	
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
		mov	var_here, %edi
		addl	$Word_header_size,%eax
		call 	Emit_sub_call
		mov	%edi, var_here
		popa
		pop	%eax
	Endword

	Defword epilog,"epilog", IMMEDIATE_WORD
		pusha
		movl	$(Epilog_code_end-Epilog_code),%ecx
		movl	$Epilog_code,	%esi
		movl	var_here,	%edi	
		rep	movsb
		movl	%edi, var_here
		popa
	Endword

	Defword prolog,"prolog", IMMEDIATE_WORD
		pusha
		movl	$(Prolog_code_end-Prolog_code),%ecx
		movl	$Prolog_code,	%esi
		movl	var_here,	%edi	
		rep	movsb
		movl	%edi, var_here
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

	Defword slash,"\\", IMMEDIATE_WORD
		C_Call_safe	Get_word
		mov	$Token_buffer, %ebx
		C_Call_edx 	Find_word
		orl	%edx,%edx
		jz	1f
		push	%eax		# push TOS
		mov	%edx,	%eax	# set TOS to value of literal
		xchg	%esi,%esp
		mov	WOFFS_COMPILATION_TOKEN(%edx), %edx
		pushl	$2f				  # form call to XT
		pushl 	%edx
		ret
		jmp	2f
1:
		Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_DX, Exception_data
		Call_with_cc_with_context Exception
2:	
		xchg	%esi,%esp
#		xchg	%esi,%esp
	Endword

	Defword immediate,"immediate",IMMEDIATE_WORD
		movl	var_last,%edx
		movl	$IMMEDIATE_WORD, WOFFS_FLAGS(%edx)
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
	.data
	.align	4
Cells:
	.FILL 1024*1024

Prolog_code:
	xchg	%esp,	%esi
Prolog_code_end:	

Epilog_code:
	xchg	%esp,	%esi
	ret
Epilog_code_end:

Test_code:
	xchg	%esi,	%esp
	push	%eax
	mov	$123,%eax
	xchg	%esi,	%esp
	ret
Test_code_end:

	

