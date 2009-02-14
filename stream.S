#include "cont.S"
	
	.LONG	Input_stream
	
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
		
Get_char:
	Next_char 	1f
	ret
1:
	Vm_Save_state 	Vm_Get_char_context, 	Get_char
	Throw 		$END_OF_STREAM_EXCEPTION
	ret
	
Get_word:
	Vm_is_state	Vm_Get_char_context, l1
		Vm_Save_state	Vm_Get_char_context, l1
l1:
	Vm_Restore_context Vm_Get_char_context
	movl		$Token_buffer,	%edi	# %edi our token buffer
whites:	
	call 		Get_char
	Is_white 	%cl,whites
	movl		$Token_buffer,	%edi
	Store_char	%edi
char_loop:	
	call Get_char
	Store_char	%edi
	Is_white 	%cl,end_of_word
	jmp char_loop
end_of_word:
	ret
