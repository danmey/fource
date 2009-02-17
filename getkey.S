#include "continuation.h.S"
#include "context.h.S"




	.GLOBL	Vm_interpret



	
	.BSS
		.LCOMM Token_buffer, 32
		Define_context Vm_context
	.DATA

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

	

	
Define_continuation_context 	Get_word_data
	
Define_continuation 		Get_word
	mov	Input_stream, 	%esi

loop:
	mov	$Token_buffer,	%edi
	xor	%eax,%eax
	push	%edi
	mov	$32,	%ecx
	rep	stosb
	pop	%edi
white:	
	lodsb
	or	%al,	%al
	jnz	not_end
	Exit_continuation
	mov	Input_stream, 	%esi
	jmp	loop
not_end:	
	Is_white %al,	white
	dec	%esi

not_white:
	lodsb
	Is_white %al,	word_end
	or	%al,	%al
	jz	word_end2
	stosb
	jmp	not_white
	
word_end:
	dec 	%esi
	call	print_word
	jmp	loop
word_end2:
	dec 	%esi
	call	print_word
	Exit_continuation
	mov	Input_stream, 	%esi
	jmp	loop

print_word:
	push	$Token_buffer
	push	$fmt_str
	call	printf
	add	$8,%esp
	ret
	
Vm_interpret:
	push	%ebp
	mov	%esp,%ebp
	mov	8(%ebp),%eax
	mov	%eax,Input_stream
	call	Vm_parse
	pop	%ebp
	ret
	
Continuation_entry		Vm_parse, Get_word, Get_word_data
