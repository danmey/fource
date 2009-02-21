#include "const.h"			
#include "context.h.S"			
#include "continuation.h.S"			


	
	.globl Vm_interpret
	.globl Vm_reset

	

	
################################################################################
# Declare some useful macros
#
	

	# Pointer to previous word, needed for constructing
	# statically new core words
 	.SET 		Wprev, 0

	# Macro that defines new word
	.MACRO 	Defword 	label, name
		.ALIGN 4
	wstart_\label:
		.LONG		Wprev		# This a link to previous word
	 	.LOCAL 		nstart		# Needed for padding the word
		.SET 		nstart, .	# name into 32 bytes
		.ASCIZ		"\name"	# store name
	 	.FILL 		NAMESIZE - ( . - nstart )	# pad it
		.LONG		0		# Flags
		.SET		Wprev, wstart_\label	# update prev label
	wcode_\label:
	# This instruction is going to restore stack for local use in word
	# Parameter stack resides in %esi register
		xchgl	%esp,%esi			
	.ENDM
	
	
	

	# Macro that terminates word
	.MACRO 	Endword
		xchgl 	%esp,%esi	# Restore return stack!
		ret
	.ENDM
	

	

	# Macro that defines a variable
	.MACRO 	Defvar 		label, name_str, value
		Defword	\label, \name_str
		pushl	var_\()\label
		Endword
var_\label:
		.LONG 	\value
	.ENDM








	
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



	



	
	########################################################################
	# Macro: 	_C_call
	# Desc:	 	Inner macro for unsafe C function call
	#		Assumes that every parameter is dword wide
	#		Fixes stack after call
	#
	# 	>size: 	accumulated size of pushed params on stack
	# 	>func:	called function
	#	>head:	first parameter
	#	>tail:	rest of parameters
	.set _Arg_size,0
	.MACRO _C_call size, func, head, tail:vararg
		.ifb \tail
			call 	\func
			add	$_Arg_size,	%esp
		.else
			C_call_ \size+4,\func,\tail
		.endif
		pushl	\head
	.ENDM


	

	########################################################################
	# Macro: 	C_call
	# Desc:	 	Macro for unsafe C function call
	#		Assumes that every parameter is dword wide
	#		Fixes stack after call
	#
	# 	>func:	called function
	#	>tail:	rest parameters
	.MACRO C_Call func, params:vararg
		C_call_ 4, \func, \params
	.ENDM


	

	
	

	

################################################################################
#	Section that contains our code and data
# 	Code placed in that section because we will emit a lot of code and
#	for time being the dictionary is linear
	
	.section .data 



	
	# Pointer to next free cell
//	Defvar here "here" Cells







/*
	Defword cells_q "cells?"
		movl	$Cells,		%eax
		subl	var_here, 	%eax
		shrl	$2,		%eax
		pushl	%eax
	Endword
*/	


Fmt_dec:	.asciz "%d"
	########################################################################
	# Word: 	. dot
	# Desc:		Prints a value from top of stack
	# 	( n -- )
	Defword dot "."
		pushl	$Fmt_dec
		call	printf
		addl 	$8,	%esp
	Endword

	Defvar state, "state", VM_STATE_COMPILING
	
		# Pointer to last word
	Defvar last, "last", wstart_last


	.DATA 2
	Define_context Enviroment_context
	.GLOBL Enviroment_context
	.DATA
.GLOBL Interpret_data
	
msg:	.asciz "%s "
Define_continuation_with_context Interpret
a_loop:	
	Call_with_cc_with_context Get_word
	cmpb	$0, Token_buffer
	jnz	1f
	Exit_continuation_ret
	jmp	a_loop
1:	
	pushl	$Token_buffer
	pushl	$msg
	call 	printf
	add	$4,	%esp
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

## # TODO: Make it case insensitive
## Find_word:
## 	movl	var_last,	%edx
## next:	
## 	movl	$NAMESIZE,	%ecx
## 	leal	4(%edx),	%edi
## 	mov	$Token_buffer,	%esi
## 	repe	cmpsb
## 	or	%ecx,	%ecx
## 	jnz	not_found
## 	mov	%edx,	%eax
## 	ret
## not_found:
## 	movl	(%edx),		%edx
## 	or	%edx,		%edx
## 	jnz	next
## 	xor	%eax,		%eax
## 	ret
