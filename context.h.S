



#ifndef CONTEXT_H_S
#define CONTEXT_H_S



	
	.MACRO Define_context context
		.ALIGN	32
		.LCOMM 	\context, 32+4
	.ENDM
	
	.MACRO Vm_Save_context context
		movl	%esp,	(\context+32)
		movl	$(\context+32),	%esp
		pushal
		movl	(\context+32),	%esp
	.ENDM

	.MACRO Vm_Restore_context context
		movl	$(\context),	%esp
		popal
		movl	(\context+32),	%esp
	.ENDM




#endif
### #ifndef CONTEXT_H_S
