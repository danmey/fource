
#include "const.h"			
#include "context.h.S"			
#include "continuation.h.S"			


	
	.globl Vm_interpret
	.globl Vm_reset

	

	
################################################################################
# Declare some useful macros
#
	









	
	# Align register to some value
	.MACRO	Align reg, n
		decl	\reg
		andl	$~(\n-1),\reg
		addl	$n,\reg
	.ENDM







	


	



	
#include "ccall.h.S"

	

	
	

	







	.DATA 2
	Define_context Enviroment_context
	.GLOBL Enviroment_context
	.DATA
.GLOBL Interpret_data
	
msg:	.asciz "%s "

### TODO: Remove this ugly globals!
Word_found:	.LONG 0
Value_to_push:	.LONG 0
Define_continuation_with_context Vm
vm_loop:
	C_Call_safe	Get_word
	mov	$Token_buffer,	%ebx
	C_Call_edx	Find_word
	orl	%edx,%edx
	jnz	2f
### We need to compile literal
		xchgl	%esp,	%esi 	# access parameter stack
		push	%eax		# push TOS
		xchgl	%esi,	%esp	# access call stack
		C_Call_edx	Parse_literal
		jz 	5f		# jump if not literal
		mov	%edx,%eax 	# set TOS to value of literal
		jmp	6f		# loop
2:
### We need to compile word
	xchgl	%esp,%esi	# access parameter stack
	push	%eax		# push TOS
	xchgl	%esp,%esi	# access call stack
	mov	%edx,%eax	# set TOS to value of literal
	cmpl	$IMMEDIATE_WORD, WOFFS_FLAGS(%edx)
	jz 	immediate
	cmpl	$VM_STATE_COMPILING, var_state
	jz	1f
	cmpl	$VM_STATE_MACRO_COMPILING, var_state
	jz	macro_compiling
immediate:	
	mov	WOFFS_EXECUTION_TOKEN(%edx), %edx # get the execution token
	jmp	4f
1:
	
	mov	WOFFS_COMPILATION_TOKEN(%edx), %edx
4:	
	pushl	$3f				  # form call to XT
	pushl 	%edx
	ret
3:	
	# This is called in Get_key module, so if we run out of
	# characters in the stream it will return to host
#	Exit_continuation_ret	
	jmp vm_loop
5:
	Set_continuation_slot $WORD_NOT_FOUND_EXCEPTION, CNT_DX, Exception_data
	Call_with_cc_with_context Exception
	jmp vm_loop

6:
	cmpl	$VM_STATE_COMPILING, var_state
	jnz	1f
	push	$1f
	push	$wcode_literal
	ret
1:	jmp 	vm_loop

macro_compiling:
	xchgl	%esp,%esi	# access parameter stack
	push	%eax		# push TOS
	xchgl	%esp,%esi	# access call stack
	call	wcode_literal
	mov	%eax,%edx
 	mov	WOFFS_COMPILATION_TOKEN(%edx), %edx
	mov	%edx,%eax
	subl	$Word_header_size,%eax
 	pushl	$3f				  # form call to XT
 	pushl 	%edx
 	ret
3:
	jmp	vm_loop
	
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
