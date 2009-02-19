#include "continuation.h.S"	

	.BSS
		.LCOMM Vm_Exception_handler,4



	
	.GLOBL Vm_Exception_handler

	.MACRO Struct
		.struct 0
	.ENDM


	
	.MACRO Field label, len
		\label\():	.struct \label+\len
	.ENDM


	
	.MACRO End_struct
		.data
	.ENDM



	Struct
		field 	exc_context, 	CNT_REG_SIZE
		field	exc_stack_ptr, 4
		field	exc_ret_stack_ptr, 4
		field	exc_id, 4
		field 	ext_size, 0
	End_struct

	
	.LCOMM Vm_Exception_context, ext_size

	.DATA
Msg_Exception_handler_not_def:
	.asciz "*Error: Uncought Fource kernel exception!\n"

.GLOBL	Exception_data
.GLOBL	Exception
	
Define_continuation_context Exception_data
Define_continuation Exception
exception_loop:	
	cmpl	$0,	Vm_Exception_handler
	jz	exception_handler_empty
	pushl	%eax		     # our saved exception ID
	movl	CNT_EXIT(%ebp), %ebx # our saved exception

	## Copy context first
	leal	CNT_CONTEXT(%ebx), 	%esi
	movl	$Vm_Exception_context, 	%edi
	movl	$CNT_REG_SIZE,		%ecx
	rep 	stosb
	## Now the stack pointers
	leal	CNT_STACK(%ebx),	%eax
	stosl
	leal	CNT_RET_STACK(%ebx),	%eax
	stosl
	popl	%eax
	stosl
	## Call our handler routine
	pushl	$ Vm_Exception_context
	pushl	$ 1f	
	pushl	Vm_Exception_handler
	ret
1:
	addl	$4,	%esp	# Fix the stack after call
	Exit_continuation Get_word_data
	jmp	exception_loop
exception_handler_empty:
### TODO: Redirect message to stderr rather then stdout
	pushl	$ Msg_Exception_handler_not_def
	call	printf
	add	$4,	%esp
	Exit_continuation Get_word_data	
	jmp	exception_loop
	
