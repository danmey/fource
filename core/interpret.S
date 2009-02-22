
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
	cmpl	$0,Word_found
	jnz	here3
	xchgl	%esi,%esp
	push	%eax
	mov	Value_to_push,	%eax
	xchgl	%esi,%esp
 	jmp here2
here3:	
	addl	$(4+4+32), Word_found
	pushl	$here2
	pushl 	Word_found
	ret
here2:
	movl	$0,Word_found
	Exit_continuation	
	jmp vm_loop
	
	
Define_continuation_with_context Interpret
a_loop:	
	Call_with_cc_with_context Get_word
#	C_Call_safe printf, $Token_buffer, $msg
	C_Call_ret_safe	Find_word
# 	C_Call_safe printf,%eax,$Fmt_dec 
	mov	%eax,Word_found
	orl	%eax,%eax
	jz	1f
	jmp 	2f
1:
	C_Call_ret_safe	Parse_literal
	movl	$0,Word_found
	movl	%eax,Value_to_push	
2:
	Call_with_cc_with_context Vm
	cmp	$0, Token_buffer
	jnz	a_loop
	Exit_continuation_ret
	jmp	a_loop


Vm_interpret:
	Vm_Save_context Enviroment_context
	push	%ebp
	mov	%esp,%ebp
	mov	8(%ebp),%eax
	mov	%eax,Input_stream
	call	Vm_parse
	pop	%ebp
	ret
	
Continuation_entry Vm_parse, Interpret, Interpret_data


	
		
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
