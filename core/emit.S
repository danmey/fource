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

	.GLOBL Emit_sub_call
Emit_sub_call:
	mov	%edi,	%edx
	sub	%eax,	%edx
	neg	%edx
	sub	$5, 	%edx
	// Store op-code for call
	EmitB	%edi,	$0xE8
	EmitDW	%edi,	%edx
	EmitB	%edi,	$0xC3
	ret
