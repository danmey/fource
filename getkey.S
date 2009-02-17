#include "continuation.h.S"
#include "context.h.S"




	.GLOBL 	Vm_Get_key
	.GLOBL 	Vm_Get_word
	.GLOBL	Vm_interpret



	
	.BSS
		.LCOMM Token_buffer, 32
		Define_context Vm_context
	.DATA

Input_stream:	.LONG	0
fmt_str:	.ASCIZ "%s\n"



	.MACRO Next_char end_of_stream
		xorl	%ecx,		%ecx
		movl	Input_stream,	%edx
		incl	Input_stream
		movb	(%edx),		%cl
		orl	%ecx,		%ecx
		jz	\end_of_stream
	.ENDM



	
	.MACRO Store_char	reg
		movb	%cl,	(\reg)
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

	
	## TODO: Put logic into macro
## Define_continuation_context Get_key_context, Enviroment_code
	
## Continuation_def Get_key, Get_key_context
## Continuation_code Get_key
## 1:	
## 	Next_char 	2f
## 	jmp		1b
## 2:
## 	Exit_continuation



	
## Define_continuation_context Get_word_context, Enviroment_code
## Continuation_def Get_word, Get_word_context
## Continuation_code Get_word
## loop:	
## 	mov	$Token_buffer,	%edi
## 	xor	%eax,	%eax
## 	mov	$32,	%ecx
## 	rep	stosb
## whites:
## 	## TODO: As above
## 1:	
## 	Next_char 	2f	
## 	jmp		3f
## 2:
## 	Exit_continuation
## 3:	
## 	Is_white 	%cl,whites
## 	movl		$Token_buffer,	%edi
## 	Store_char	%edi
## char_loop:	
## 	## TODO: As above
## 1:	
## 	Next_char 	2f
## 	jmp		3f
## 2:
## 	Exit_continuation
## 3:	
## 	Store_char	%edi
## 	Is_white 	%cl,end_of_word
## 	jmp char_loop
## end_of_word:
## 	call	print_word
## 	jmp	loop
## 	ret
## print_word:	
## 	pushl	$Token_buffer
## 	pushl	$fmt_str
## 	call	printf
## 	add	$8,%esp
## 	ret
## 2:
## 	call	print_word
## 	Exit_continuation
## 	ret


msg:	.asciz "Hello world!\n"
Define_continuation_context Enviroment_data
Define_continuation Enviroment
1:	
	Exit_continuation
	jmp	1b

Vm_interpret:	
	Vm_Save_context Vm_context
	mov	%esp,	%ebp
	mov	4(%ebp),	%eax
	mov	%eax,		Input_stream

	movl	$ll,	(Enviroment_data+cnt_exit)
	push	$Enviroment_data
	jmp	Enviroment
	
ll:
 	pushl	$msg
 	call	printf
	Vm_Restore_context Vm_context
	ret



