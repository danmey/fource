
	#include "const.S"

	

	
/*
 * Dictionary entry structure:
 * Offset	Description
 * =========================
 * $00		Pointer to previous word
 * $04		String containing name of word, pad to 16 bytes
 * $10		Begining of word code
 * ...		Body of word
 *
 ******************************************************************************/


/*******************************************************************************
 * Core Macros
 ******************************************************************************/

	.SET 		wprev, 0

	.MACRO 	Defword 	label, name_str
		.ALIGN 4
	wstart_\label:
		.LONG		wprev
	 	.LOCAL 		nstart
		.SET 		nstart, .
		.ASCIZ		"\name_str"
	 	.FILL 		WNAME_SIZE - ( . - nstart )
		.SET		wprev, wstart_\label
	wcode_\label:
		xchgl	%esp,%esi
	.ENDM
	
	
	
	
	.MACRO 	Endword
		xchgl 	%esp,%esi
		ret
	.ENDM
	



	.MACRO 	Defvar 		label, name_str, value
		Defword	label, name_str
		pushl	1f
		Endword
1:
		.LONG 	\value
	.ENDM




	.MACRO	Align reg, n
		decl	\reg
		andl	$~(\n-1),\reg
		addl	$n,\reg
	.ENDM




	.MACRO	WBody reg
		addl	$(WNAME_SIZE+4),\reg
	.ENDM




	.MACRO EmitB reg, b
		movb	\b,	(\reg)
		incl	\reg
	.ENDM



	
	.MACRO EmitDW 	reg, b
		movl	\b,	(\reg)
		addl	$4,	\reg
	.ENDM



	.MACRO	Is_white breg
		cmpb	$10,	\breg		# CR ?
		jz	1f
		cmpb	$13,	\breg       	# LF ?
		jz	1f
		cmpb	$9,	\breg		# TAB ?
		jz	1f
		cmpb	$' ',	\breg	# SPACE ?
		jz	1f
	1:
	.ENDM


	.set _Arg_size,0
	.MACRO C_call_ size, func, head, tail:vararg
		.ifb \tail
			.SET _Arg_size,\size
		.else
			C_call_ \size+4,\func,\tail
		.endif
		pushl	\head
	.ENDM

	.MACRO C_Call func, params:vararg
		C_call_ 4, \func, \params
		call 	\func
		add	$_Arg_size,	%esp
	.ENDM
	
	.SECTION .bss

	.LCOMM Token_buffer, WNAME_SIZE
	.LCOMM Stack, 128000

	
	
	.section .data
Fmt_hex:		.asciz 	"%x"
Fmt_dec:		.asciz 	"%d"
test:			.asciz  "test\n" 

	Defword dot "."
		pushl	$Fmt_dec
		call	printf
		add 	$8,	%esp
	Endword

/*******************************************************************************
 *
 *	Subroutine:	Interpret
 *	Description:	Interpets string
 *		> %esi 		pointer to word
 *
 ******************************************************************************/

Interpret_token:
	
Interpret:
	movl	$Token_buffer,	%edi
	movl	%edi,	%ebx
	addl	$WNAME_SIZE,%ebx
		
skip_whites:
	cmpl	%ebx,	%edi
	jae	end_parse
	xor	%eax,	%eax
	lodsb
	or	%eax,	%eax
	jz	end_parse
	Is_white %al
	jz	skip_whites

	dec	%esi
parse_token:	
	cmpl	%ebx,	%edi
	jae	end_parse_with_interpret
	xor	%eax,	%eax
	lodsb
	or	%eax,	%eax
	jz	end_parse_with_interpret
	Is_white %al
	jz	interpret_token
	stosb
	jmp	parse_token

interpret_token:
	
	jmp	Interpret
end_parse_with_interpret:
	xor	%eax,	%eax
	dec	%ebx
	cmp	%edi,	%ebx
	jz	1f
	stosb
	
end_parse:
	ret

#	.globl main
	.globl vm_interpret
vm_interpret:
	pushl	%ebp
	lea	8(%esp),	%ebp
	pushal
	mov	 (%ebp),	%esi
	call	Interpret

	movl	$Stack,	%esi
	add	$(128000-4),%esi
	movl	$123,	(%esi)
	call	wcode_dot
	call 	params_test
	popal
	pop	%ebp
	mov	$Token_buffer, %eax
	ret
	
	

dict_begin:	

	Defvar here, "here", dict_begin

	
	
/*******************************************************************************
 *
 *	Subroutine:	Emit_sub_call
 *	Description:	Emits needed code for word call
 *		> %ebx 		pointer to word
 *		> %edi		free chunk of memory in dictionary
 *		< %edi		free chunk of memory in dicrionary
 *
 ******************************************************************************/
dump:
	.asciz "hello! %x\n"	
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
.align 4

	
Test_code: .fill 128
	
.text
params_test:
	C_call printf,$Fmt_dec, $12345
	


	

	
	
	
subprepost:	xchgl	%esp,%esi
subprepost_end:
	
/*
	################################################################################	
# Get token, separated by whites, and put it in _token
# TODO: Make it case insesitive (lowercase everything)
# In:
# Out:	
# eax - integer value
# _token - a token
_get_token:
	
# Skip whites
	call	_get_key_white_skip
	mov 	$_token,%edi
	mov 	$NTAB_ENTRY_SIZE,%ecx
1:	
	dec %ecx			# keep the counter becasue we need to clear out _token
	stosb				# in al we had out character
	call _get_key			# get next key
	call _is_white			# is white?
	jnz 1b				# NO?
	K4_SAFE_CALL(ungetc,%eax,stdin)	# unget char
	xor 	%eax,%eax		# clear status (not needed?)
	rep 	stosb			# Fill rest of _token
	ret
	
	
	
################################################################################	
# Parse literal, string is in _token
# TODO: Make it work with floats
# In:
# Out:	
# eax - integer value
_parse_literal:
# Check for dot if dot is present then we have floating point number
	push 	%edi
	mov	$_token,%edi
# string length
	xor 	%ecx,%ecx
	not	%ecx
	xor 	%eax,%eax
	cld
	repnz 	scasb
	not 	%ecx
	dec 	%ecx

	mov	$'.',%al
	mov	$_token,%edi
	repnz 	scasb
	jnz	1f	# real

	K4_SAFE_CALL(sscanf,$_token,$_fmt_float,$_tmp_dec_val)
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret
1:
	cmpb	$10,_var_base
	jz	2f
	K4_SAFE_CALL(sscanf,$_token,$_fmt_hex,$_tmp_dec_val)
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret
2:	
# Use cheap sscanf
	K4_SAFE_CALL(sscanf,$_token,$_fmt_dec,$_tmp_dec_val)
3:	
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret

	
Get_key_white_skip:
	xorl	%eax,	%eax
	lodsb
	or	%eax,	%eax
	jz	End_of_parse
	call 	Is_white
	jz _get_key_white_skip	# loop until we will find something
	ret

End_of_parse:
*/	
