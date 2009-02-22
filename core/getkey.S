#include "continuation.h.S"
#include "context.h.S"



	.GLOBL	Vm_interpret



	
	.DATA 1
	.GLOBL
_Image_start:	

		.LCOMM Token_buffer, 32
		Define_context Vm_context
	Input_stream:	.LONG	0
	fmt_str:	.ASCIZ "%s "

	
	
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
	
word_end_fail:
	## TODO: Correct to get it work again
	Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_AX, Exception_data
	Call_with_cc Exception, Exception_data
	Exit_continuation_ret
	ret
	jmp	Get_word

