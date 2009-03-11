#include "const.h"
#include "dict.h.S"
#include "ccall.h.S"
#include "continuation.h.S"
#include "emit.h.S"
#include "reloc.h.S"
.data


	.GLOBL 	Dictionary_start
	.GLOBL 	Reloc_start
	.GLOBL	var_here
Dictionary_start:
Reloc_start:
	.LONG	0 
	.LONG	0 
	.LONG	0 
	.LONG	0 
	.LONG	0 
	.LONG	0 
	.LONG	0 
	.LONG	0 
	
	Defvar state, "state", VM_STATE_INTERPRETING

	# Pointer to last word
	Defvar here, "here", Cells
	Defvar  base, "base", 10
	## We use subroutine threading and TOS optimizations
	## %esi contain our parameter stack and %eax TOS

	Defword plus, "+"
		add	%eax,(%esp)
		pop	%eax
	Endword

	Defword minus, "-"
		sub	%eax,(%esp)
		pop	%eax
	Endword

	Defword star, "*"
		pop	%ebx
		imul	%ebx,%eax
	Endword

	Defword dup, "dup"
		push	%eax
	Endword

	Defword swap, "swap"
		xchg	%eax, (%esp)
	Endword

	Defword rot, "rot"
		pop	%ebx
		pop	%ecx
		push	%eax
		push	%ecx
		mov	%ebx,%eax
	Endword

	.GLOBL wcode_dot
	
	Defword dot, "."
		Load_reloc %ecx
		cmpl	$10, var_base
		jnz 	1f
			C_Call_safe printf,%eax,rFmt_dec(%ecx)
			jmp	2f
	1:
		cmp	$16, var_base
		jnz 	2f
			C_Call_safe printf,%eax,rFmt_hex(%ecx)
			jmp	2f
	2:
		pop	%eax
	Endword
	
	Defword body,"body>"
		# Get the body of the word
		addl	$Word_header_size,%eax
	Endword
	
	Defword lsqbracket, "]", $wcode_execute
		movl	$VM_STATE_COMPILING, var_state
	Endword

	Defword rqbracket, "[",	$wcode_execute
		movl	$VM_STATE_INTERPRETING, var_state
	Endword

	defword rbracket, ")",wcode_execute
		movl	$VM_STATE_MACRO_COMPILING, var_state
	Endword
	
	Defword compile,"compile"
		pusha 
		mov	var_here, %edi
		addl	$Word_header_size,%eax
#		Emit_literal	$123
		Emit_sub_call	%eax
		mov	%edi, var_here
		popa
		pop	%eax

	Endword
	.GLOBL wcode_literal

	Defword literal, "literal"
		mov	var_here,%edi
		Emit_literal	%eax
		mov	%edi, var_here
		pop	%eax
	Endword

	Defword exit_comma,"exit,",IMM
		pusha
		movl	$(Epilog_code_end-Epilog_code),%ecx
		movl	$Epilog_code,	%esi
		movl	var_here,	%edi	
		rep	movsb
		movl	%edi, var_here
		popa
	Endword
Epilog_code:
	ret
Epilog_code_end:

	Defword comma, ","
		mov	var_here,%edi
		stosl
		mov	%edi,var_here
		pop	%eax
	Endword

	Defword char_comma, "c,"
		pusha
		mov	var_here,	%edi
		stosb
		mov 	%edi,var_here
		popa
		pop	%eax
	Endword

	Defword sp_fetch, "sp@"
		push	%eax
		mov	%esp,%eax
	Endword
	
	Defword execute,"execute"
		addl	$Word_header_size,%eax
		mov	%eax,	%edx
		pop	%eax
		xchg	%esi,	%esp
		Reloc	%ecx
		add	$1f,	%ecx
		push	%ecx
		push	%edx
		ret
	1:
	 	xchg	%esi,%esp
	Endword

	Defword fetch,"@"
		movl	(%eax),%eax
	Endword

	Defword pushret, ">r"
		xchg	%esi,%esp
		push	%eax
		xchg	%esi,%esp
		pop	%eax
	Endword

	Defword drop, "drop"
		pop	%eax
	Endword

	Defword popret, "r>"
		push	%eax
		xchg	%esi,%esp
		pop	%eax
		xchg	%esi,%esp
	Endword

	
	Defword branch_comma, "branch,",wcode_execute
		pusha
		mov	var_here, %edi
		Emit_branch_b
		dec	%eax	# adjust for jmp byte code and jmp
		dec	%eax	
		EmitB	%edi,%al
		mov	%edi,var_here
		popa
		pop	%eax
	Endword

	Defword branch0_comma, "0branch,",wcode_execute
		pusha
		mov	var_here, %edi
		Emit_branch0_b
		subl	$9,%eax	# adjust for jmp byte code and jmp
		EmitB	%edi,%al
		mov	%edi,var_here
		popa
		pop	%eax
	Endword


	Defword below, "u<"
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jb	1f
		xor	%eax,%eax
	1:	
	Endword

	Defword slash,"\\",wcode_execute
		Load_reloc	%ecx
		C_Call_safe	*rGet_word(%ecx)
		mov	rToken_buffer(%ecx), %ebx
		C_Call_edx 	*rFind_word(%ecx)
		orl	%edx,%edx
		jz	1f
		push	%eax		# push TOS
		mov	%edx,	%eax	# set TOS to value of literal
		xchg	%esi,%esp
		mov	$wcode_compile, %edx
		Reloc	%ecx
		add	$2f,	%ecx
		pushl	%ecx				  # form call to XT
		pushl 	%edx
		ret
		jmp	2f
1:
		## Load_reloc 	%ecx
		## mov	rException_data(%ecx),%ecx
		## Set_continuation_slot_reg $WORD_TO_LONG_EXCEPTION, CNT_DX, %ecx
		## Load_reloc 	%ecx
		## Call_with_cc_with_context_reg rException, %ecx
2:	
		xchg	%esi,%esp
	Endword

	Defword immediate,"immediate", IMM
		movl	var_last,%edx
		movl	$wcode_execute,WOFFS_COMPILATION_TOKEN(%edx)
	Endword

	Defword create, "create"
		xchg	%esi,%esp
		Load_reloc	%ecx
		C_Call_safe	*rGet_word(%ecx)
		pusha
		movl	var_here,	%edi
		movl	rToken_buffer(%ecx),	%esi
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
		movl	$1,%eax
		stosl
		movl	$wcode_execute,%eax
		stosl
		movl	$wcode_compile,%eax
		stosl
		movl	%edi,	var_here
		pop	%edi
		mov	%edi,var_last
		popa
		xchg	%esi,%esp
	Endword

	Defword store, "!"
		pop	(%eax)
		pop	%eax
	Endword

	Defword char_store, "c!"
		pop	%ecx
		mov	%cl,(%eax)
		pop	%eax
	Endword

	Defword invert, "invert"
		not	%eax
	Endword

	Defword equals, "="
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jz	1f
		xor	%eax,%eax
	1:	
	Endword
	
	Defword key, "key"
		push	%eax
		Load_reloc %ecx
		C_Call_ret_safe	*rGet_key(%ecx)
	Endword

	Defword emit, "emit"
		C_Call_safe 	putchar,%eax
		pop	%eax
	Endword

	Defvar last, "last", wstart_last
.GLOBL Cells
Cells:
	.FILL 1024*1024

	

