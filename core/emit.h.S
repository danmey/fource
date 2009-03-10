#ifndef _EMIT_H_S
#define _EMIT_H_S

	## TODO: Could that module be just harcoded in Forth? I see no point keeping that here!
	## (At least for branching words, rest is OK)
	
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

	.MACRO Emit_branch_b 
	// Store op-code for call
		EmitB	%edi,	$0xEB

//		EmitB	%edi, $-2
	.ENDM

	.MACRO Emit_branch0_b 
	// Store op-code for call
		EmitB	%edi, $0x87 # xchg %esp,%esi
		EmitB	%edi, $0xe6 #
		EmitB	%edi, $0x09
		EmitB	%edi, $0xC0
		EmitB	%edi, $0x58
		EmitB	%edi, $0x87 # xchg %esp,%esi
		EmitB	%edi, $0xe6 #
		EmitB	%edi, $0x74
	.ENDM

#endif
