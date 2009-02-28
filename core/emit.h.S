#ifndef _EMIT_H_S
#define _EMIT_H_S

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



	.MACRO Emit_literal val
		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #
		EmitB	%edi,	$0x50 # push %eax
		EmitB	%edi,	$0xb8 # mov val,%eax
		EmitDW	%edi,	\val  #
		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #
	.ENDM

	.MACRO Emit_sub_call ptr
		mov	%edi,	%edx
		sub	\ptr,	%edx
		neg	%edx
		sub	$5, 	%edx
	// Store op-code for call
		EmitB	%edi,	$0xE8
		EmitDW	%edi,	%edx
	.ENDM


#endif
