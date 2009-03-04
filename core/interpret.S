#include "const.h"			
#include "context.h.S"			
#include "continuation.h.S"			
#include "ccall.h.S"


	## Exports
	.GLOBL Vm_interpret
	.GLOBL Vm_reset


	.DATA


	## Our enviroment context, TODO: Do we need that?
	Define_context Enviroment_context


	# Align register to some value
	.MACRO	Align reg, n
		decl	\reg
		andl	$~(\n-1),\reg
		addl	$n,\reg
	.ENDM

	
	## TODO: Use some more macros for changing state of VM
	.MACRO Vm_push val
		xchgl	%esp,	%esi 	# access parameter stack
		pushl	%eax
		mov	\val,%eax
		xchgl	%esp,	%esi 	# access parameter stack
	.ENDM
	
	.MACRO Vm_set_TOS val
		mov	\val, %eax
	.ENDM

	.MACRO Call_abs addr
		pushl	$1f				  # form call to XT
		pushl 	\addr
		ret
	1:	
	.ENDM
	
Define_continuation_with_context Vm
vm_loop:
	C_Call_safe	Get_word
	mov		$Token_buffer,	%ebx
	C_Call_edx	Find_word
	orl		%edx,		%edx
	jnz		not_literal
### We need to compile literal
		Vm_push		%eax
		C_Call_edx	Parse_literal
		jz 		word_not_found
		Vm_set_TOS 	%edx		# jump if not literal
		jmp		compile_literal		# loop
not_literal:	
### We need to compile word
	Vm_push	%edx
	movl	var_state,	%ecx
	mov	Word_semantics(%edx,%ecx,4), %edx # get the execution token
	Call_abs	%edx
	jmp vm_loop
word_not_found:	
	Set_continuation_slot $WORD_NOT_FOUND_EXCEPTION, CNT_DX, Exception_data
	Call_with_cc_with_context Exception
	jmp vm_loop

compile_literal: 
	cmpl	$VM_STATE_COMPILING, var_state
	jnz	vm_loop
		call	wcode_literal
1:
	jmp 	vm_loop
	
Vm_interpret:
	Vm_Save_context Enviroment_context
	push	%ebp
	mov	%esp,%ebp
	mov	8(%ebp),%eax
	mov	%eax,Input_stream
	call	Vm_Entry_point
	pop	%ebp
	ret
	
Continuation_entry Vm_Entry_point, Vm, Vm_data


	
		
.GLOBL	Find_word
# TODO: Make it case insensitive
Find_word:
 	movl	var_last,	%edx
next:
	
	movl	$NAMESIZE,	%ecx
	leal	4(%edx),	%edi
	mov	%ebx,		%esi
	repe	cmpsb
	or	%ecx,	%ecx
	jnz	not_found
	mov	%edx,	%eax
	ret
not_found:
	movl	(%edx),		%edx
	or	%edx,		%edx
	jnz	next
	xor	%eax,	%eax
	ret
