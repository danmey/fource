#include "continuation.h.S"
#include "context.h.S"



	.GLOBL	Vm_interpret



	

		Define_context Vm_context
	Input_stream:	.LONG	0
	fmt_str:	.ASCIZ "%s "
	Vm_alloc 	Token_buffer, 32

	
	
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

	.GLOBL Get_word
	.GLOBL Token_buffer
.GLOBL Input_stream
	
 .GLOBL	Get_word_data
################################################################################
#	Define_continuation_with_context Get_word
# Commented out! we need continuation on VM rather then Get_word module
#
Get_word:
	movl	Input_stream, 	%esi
	movl	$Token_buffer,	%edi
	xor	%eax,%eax
	push	%edi
	mov	$32,	%ecx
	rep	stosb
	pop	%edi
white:	
	lodsb
	or	%al,	%al
	jnz	not_end
	## Exit damn continuation if there is end ot token :)
	## TODO: Replace somewhat with Exit_continuation call
	Exit_continuation_ret
	jmp	Get_word
not_end:	
	Is_white %al,	white
	dec	%esi

not_white:
	lodsb
	Is_white %al,	word_end
	or	%al,	%al
	jz	word_end2
	cmp	$(Token_buffer+31),%edi
	jae	word_end_fail
	stosb
	jmp	not_white
	
word_end:
	dec 	%esi
	jmp	exit_func
word_end2:
	dec 	%esi
	jmp	exit_func
exit_func:
	movl	%esi, Input_stream
	ret
.GLOBL Get_key

Get_key:
	xor	%eax,%eax
	movl	Input_stream, 	%esi
	lodsb
	or	%eax,%eax
	jnz 	1f
	Exit_continuation_ret
	jmp	Get_key
1:
	movl	%esi, Input_stream
	ret
	
word_end_fail:
	## TODO: Correct to get it work again
	Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_DX, Exception_data
	Call_with_cc_with_context Exception
	Exit_continuation_ret
	jmp	Get_word

