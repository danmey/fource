#include "continuation.h.S"

	
	.data
Input_stream:	.LONG	0
	.bss
		.LCOMM Token_buffer, 32
		Define_context Vm_context
	.data
fmt_str:	.ASCIZ "%s\n"
	.MACRO Next_char end_of_stream
		xor	%ecx,		%ecx
		mov	Input_stream,	%edx
		incl	Input_stream
		movb	(%edx),	%cl
		or	%ecx,		%ecx
		jz	\end_of_stream
	.ENDM

.MACRO Store_char	reg
	mov	%cl,	(\reg)
	incl	\reg
.ENDM

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
		
Define_continuation Get_word
loop:	
	mov	$Token_buffer,	%edi
	xor	%eax,	%eax
	mov	$32,	%ecx
	rep	stosb
whites:	
	call 		Get_char
	Is_white 	%cl,whites
	movl		$Token_buffer,	%edi
	Store_char	%edi
char_loop:	
	call 	Get_char
	Store_char	%edi
	Is_white 	%cl,end_of_word
	jmp char_loop
end_of_word:
	call	print_word
	jmp	loop
	ret
print_word:	
	pushl	$Token_buffer
	pushl	$fmt_str
	call	printf
	add	$8,%esp
	ret
Get_char:
	Next_char 	2f
	ret
2:
	call	print_word
	Call_with_cc Vm_Env_code
	ret


Define_continuation Vm_Env
	Call_continuation Get_word_code
	Vm_Restore_context Vm_context
	ret
	.GLOBL Vm_interpret
Vm_interpret:	
	Vm_Save_context Vm_context
	mov	%esp,	%ebp
	mov	4(%ebp),	%eax
	mov	%eax,		Input_stream
	call 	Vm_Env_code
	ret
