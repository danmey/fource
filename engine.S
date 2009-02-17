#include "const.S"			
#include "exception.S"


	
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
		pushl	1f
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
	# Macro: 	Is_white
	# Desc:	 	Check for a white
	#
	# 	>breg: 	a character
	# 	<Z:	set it is white
	.MACRO	Is_white breg, white_label
		cmpb	$10,	\breg		# CR ?
		jz	1f
		cmpb	$13,	\breg       	# LF ?
		jz	1f
		cmpb	$9,	\breg		# TAB ?
		jz	1f
		cmpb	$' ',	\breg	# SPACE ?
	1:
		jz \white_label	
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


	

	.MACRO Define_context context
		.ALIGN	32
		.LCOMM 	\context, 32+8
	.ENDM
	
################################################################################
#	Some unitialized staticaly allocated blocks of memory

	.SECTION .bss
	
	# Shared buffer with next token
		.LCOMM 	Initialized, 4
		.LCOMM 	Token_buffer, 	NAMESIZE
		Define_context	Enviroment_context
		Define_context	Vm_context
		Define_context	Vm_Get_char_context
	# Our stack TODO: think about something more wise
		.LCOMM 	Stack, 		STACKCELLS<<2
	# TODO: IN THAT MODEL, DO WE NEED A RETURN STACK??!
		.LCOMM 	Return_stack,	RETURNCELLS<<2
	
	

	

################################################################################
#	Section that contains our code and data
# 	Code placed in that section because we will emit a lot of code and
#	for time being the dictionary is linear
	
	.section .data 

Fmt_hex:		.asciz 	"%x"	# Printing hex value
Fmt_dec:		.asciz 	"%d"	# Printing dec value
save_eax:	.LONG  	0
Input_stream:	.LONG	0


	
	# Pointer to next free cell
	Defvar here "here" Cells








	Defword cells_q "cells?"
		movl	$Cells,		%eax
		subl	var_here, 	%eax
		shrl	$2,		%eax
		pushl	%eax
	Endword
	



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


	
#include "stream.S"
	
# The free cells
Cells:	
	.FILL MAXCELLS

#TODO: Shall we clear the Cells block?
Vm_reset:
	Vm_Save_context 	Enviroment_context
	movl	$Cells,	var_here
	movl	$((STACKCELLS  <<2 - 4) + Stack),		%esi
	movl	$((RETURNCELLS <<2 - 4) + Return_stack),	%esp
	Vm_Save_context 	Vm_context
	Vm_Restore_context 	Enviroment_context
	movl		$1,	Initialized
	ret


################################################################################
# Functions that do everything for us with `parsing'

	.MACRO Loadch zero_label
		xor	%eax,	%eax
		lodsb
		or	%eax,	%eax
		jz	\zero_label
	.ENDM

	.MACRO	BoundLow left,right,not_in_bounds_label
		cmp	\right,\left
		jae	\not_in_bounds_label
	.ENDM
	
Get_token:
	movl	$Token_buffer,	%edi	# %edi our token buffer
	mov	$NAMESIZE,	%ecx
	xor	%eax,%eax
	rep	stosb
					# zero out
	movl	$Token_buffer,	%edi	# %edi our token buffer
	movl	%edi,	%ebx		# end of buffer for boundary checking
	addl	$(NAMESIZE),%ebx	
		
skip_whites:
	BoundLow	%edi,%ebx,end_parse
	Loadch		end_parse
	Is_white 	%al,skip_whites			# is white?

	dec	%esi			# push back last character
parse_token:	
	BoundLow	%edi,%ebx,end_parse
	Loadch		end_parse
	Is_white %al,	end_parse
	stosb				# otherwise store a character
	jmp	parse_token		# and loop
end_parse:
	ret

#Do_something:
#	pushl	$msg1
#	call 	printf
#	add 	$4,	%esp
#	ret
#	
#Do_even_more:
#	Throw
#	pushl	$msg2
#	call 	printf
#	add 	$4,	%esp
#	ret

#Do_even_more_and_more:
#	xor	%eax,%eax
#1:
#	inc	%eax
#	cmp	$100, %eax
#	je	2f
#	call 1b
#2:	
#	Throw
#	ret


	
#	Try_any a_label
#		call Do_something
#		call Do_even_more_and_more
#	Catch 	a_label
#		pushl	$msg3
#		call 	printf
#		add 	$4,	%esp
#	End_try	a_label

msg1:	.asciz "%s\n"
# msg2:	.asciz "test func 2\n"
# msg3:	.asciz "The rat's been killed!\n"

#2Vm_interpret:
	Vm_Save_context	Enviroment_context
	cmpl	$0,	Initialized
	jnz	1f
	call	Vm_reset
1:
	pushl	%ebp
	movl	%esp,		%ebp
	movl	8(%ebp),	%eax
	Vm_Restore_context Enviroment_context
	ret

	Vm_set_context_reg 	Vm_context,%eax,%eax		
	Vm_Restore_context	Vm_context
		mov	%eax,	Input_stream

#	Try	END_OF_STREAM_EXCEPTION, a_label2
#		call	Get_word
#		Catch	a_label2
#	End_try	a_label2
	Vm_Restore_context Enviroment_context
	ret

	
word_loop:	
	call	Get_token
	xor	%eax,	%eax
	cmpl	$Token_buffer,%edi
	jz	interpreted
	pushl	$Token_buffer
	pushl	$msg1
	call 	printf
	add	$8,	%esp

#	call	Find_word

#	or	%eax,%eax
#	jz	interpreted
#	add	$4,	%eax
	jmp	word_loop

interpreted:	
	movl		%esi, %eax
	Vm_set_context_reg 	Enviroment_context,%eax,%eax		
	Vm_Save_context		Vm_context
	Vm_Restore_context	Enviroment_context
	pop	%ebp
	ret
	
		
Emit_sub_call:
 	// Get body of the word
	WBody 	%ebx
	// Calculate relative offset for call
	mov	%edi,	%eax
	sub	%ebx,	%eax
	neg	%eax
	sub	$5, 	%eax
	// Store op-code for call
	EmitB	%edi,	$0xE8
	EmitDW	%edi,	%eax
	EmitB	%edi,	$0xC3
	ret

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


	
Test_code: .fill 128
	
	# pad with zeros
	inc	%ebx
1:	
	cmpl	%edi,	%ebx
	jz	1f
	xor	%eax,%eax
	stosb
	jmp	1b
1:	
	ret



