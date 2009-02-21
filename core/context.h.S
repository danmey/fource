



#ifndef CONTEXT_H_S
#define CONTEXT_H_S



	
	.MACRO Define_context context
		.DATA 2
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


	.MACRO Vm_Save_context_reg reg, ofs
		movl	%esp,	(32+\ofs)(\reg)
		lea	(32+\ofs)(\reg),	%esp
		pushal
		movl	(32+\ofs)(\reg),	%esp
	.ENDM

	.MACRO Vm_Restore_context_reg reg,ofs
		leal	\ofs(\reg),	%esp
		popal
		movl	(32+\ofs)(\reg),%esp
	.ENDM




#endif
### #ifndef CONTEXT_H_S
