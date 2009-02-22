
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




	# Get the body of the word
	.MACRO	WBody reg
		addl	$(NAMESIZE+4),\reg
	.ENDM



	
	# Emit a byte into memory pointed by register
	.MACRO EmitB reg, b
		movb	\b,	(\reg)
		incl	\reg
	.ENDM



	
	# Emit a dword into memory pointed by register
	.MACRO EmitDW 	reg, b
		movl	\b,	(\reg)
		addl	$4,	\reg
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
	C_Call_edx	Find_word
#	C_Call_safe	printf,$Token_buffer
	orl	%edx,%edx
	jnz	2f
		xchgl	%esp,%esi
		push	%eax
		xchgl	%esi,%esp
		C_Call_edx	Parse_literal
		jz 	4f
		mov	%edx,%eax
		jmp	3f
2:	
	addl	$(4+4+32), %edx
	pushl	$3f
	pushl 	%edx
	ret
3:
	# This is called in Get_key module, so if we run out of
	# characters in the stream it will return to host
#	Exit_continuation_ret	
	jmp vm_loop
4:
	Set_continuation_slot $WORD_NOT_FOUND_EXCEPTION, CNT_DX, Exception_data
	Call_with_cc_with_context Exception
	jmp vm_loop

	
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


	
		
## Emit_sub_call:
##  	// Get body of the word
## 	WBody 	%ebx
## 	// Calculate relative offset for call
## 	mov	%edi,	%eax
## 	sub	%ebx,	%eax
## 	neg	%eax
## 	sub	$5, 	%eax
## 	// Store op-code for call
## 	EmitB	%edi,	$0xE8
## 	EmitDW	%edi,	%eax
## 	EmitB	%edi,	$0xC3
## 	ret

# TODO: Make it case insensitive
Find_word:
 	movl	var_last,	%edx
next:	
	movl	$NAMESIZE,	%ecx
	leal	4(%edx),	%edi
	mov	$Token_buffer,	%esi
	repe	cmpsb
	or	%ecx,	%ecx
	jnz	not_found
	mov	%edx,	%eax
	ret
not_found:
	movl	(%edx),		%edx
	or	%edx,		%edx
	jnz	next
	xor	%eax,		%eax
	ret
