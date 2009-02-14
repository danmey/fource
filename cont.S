################################################################################
#
# 	Continuation module
# 	===================
#
#	This module allows one to program in CPS (Continuation Passing Style).
#	Every registered continuation has a static block alocated in
#	.bss section that preserves return and parameter stack
#	(remember we are implementing Forth) and block that saves
#	context plus address pass the return continuation call, when
#	the continuation is called, current continuation is saved in
#	target continuation block, the target context is restored and
#	the program runs in previously saved state. Parameter passing
#	to a continuation not implemented yet This implementation
#	doesn't care about global roots.
#	Continuations allow us to
#	easily implement:
#	- Green threads - Exceptions - Tail
#	recursion



#include "context.S"
	
#define STACKDEPTH	256

/* Let's declare some helper macros */
	
	.MACRO Struct
		.struct 0
	.ENDM
	
	.MACRO Field label, len
		\label\():	.struct \label+\len
	.ENDM

	.MACRO End_struct
		.data
	.ENDM



	
/* Our continuation context data structure */
	Struct
		/* Parameter stack */
		field 	cnt_stack, 	(STACKDEPTH<<2)	
		/* Return stack */
		field 	cnt_ret_stack, 	(STACKDEPTH<<2)
		/* Register */
		field 	cnt_context,	32+4
		/* Instruction pointer ! */
		field 	cnt_IP,		4
		/* Continuation to be called on exit */
		field 	cnt_exit_cnt,	4
		/* If the block was iniited? */
		field 	cnt_init,	4
		/* Size tag for out structure */
		field 	cnt_size,	0
	End_struct
	
	
	

	.MACRO Define_continuation name
		.bss

		# we should really keep the pointers if
		# we dont need to alloc mem for every continuation
		# please see exceptions
			.ALIGN	32
			.LCOMM	\name, cnt_size
		.data

		\name\()_code:
			cmp	$0, (\name + cnt_init)
			jnz	9f
			lea	(\name + cnt_stack +(STACKDEPTH<<2)-4),%esi
			lea	(\name + cnt_ret_stack	+(STACKDEPTH<<2)-4),%esp
			Vm_Save_context (\name + cnt_context)
			movl	$8f,	(\name + cnt_IP)
			movl	$1, (\name + cnt_init)
		9:	
			Vm_Restore_context (\name + cnt_context)
			pushl	(\name + cnt_IP)
			ret
		8:	
			Vm_Restore_context (\name + cnt_context)
	
		# Ugly.
		.IFDEF first
			.PURGEM	Call_with_cc
			.PURGEM	Call_with_cc2
		.ENDIF
		
		.MACRO Call_with_cc callee_code
			.data
			Vm_Save_context (\name + cnt_context)
			movl	$9f,	(\name + cnt_IP)
			jmp	callee_code
		9:	
		.ENDM

		
	.SET first,0
	.ENDM

	.bss
		Define_context Vm_context
	.data
fmt_dec:	.asciz "%d\n"
	

	Define_continuation Counter
		mov	$0,%ebx
	loop:
		inc	%ebx
		pushal
		push	%ebx
		push	$fmt_dec
		call	printf
		add	$8,%esp
		popal
		Call_with_cc Get_word_code
		jmp	loop

	
	Define_continuation Get_word
	1:	
		Call_with_cc Counter_code
		movl	$1b, (Get_word+cnt_IP)
		Vm_Restore_context Vm_context
		ret

get_word:
	Vm_Save_context Vm_context
	call Get_word_code
	ret
	
#	End_Continuation Get_word
/*
	movl		$Token_buffer,	%edi	# %edi our token buffer
whites:	
	call 		Get_char
	Is_white 	%cl,whites
	movl		$Token_buffer,	%edi
	Store_char	%edi
char_loop:	
	call Get_char
	Store_char	%edi
	Is_white 	%cl,end_of_word
	jmp char_loop
end_of_word:
	ret

Get_char:
	Next_char 	1f
	ret
1:
	End_continuation
*/
	
	.GLOBL Vm_interpret
 Vm_interpret:
#	pushl	%ebp
#	movl	%esp,		%ebp
#	mov	(%ebp),	Vm_input_stream
#	popl	%ebp
	call get_word
	ret
