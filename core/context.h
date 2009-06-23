



#ifndef CONTEXT_H_S
#define CONTEXT_H_S


	## TODO: This module must be refactored many macros can be simplified

	
	.MACRO Define_context context
		.ALIGN	32
		Vm_alloc 	\context, 32+4
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
Reg_ESP:	.LONG 0
	.MACRO Vm_Restore_general_reg reg,ofs
		movl	%esp, Reg_ESP
		leal	\ofs(\reg),	%esp
	## Skip not general registers
		pop	%eax
		pop	%eax
		pop	%eax
		pop	%eax
	## Now the interesting ones
		pop	%ebx
		pop	%edx
		pop	%ecx
		pop	%eax
		movl	Reg_ESP,%esp
	.ENDM

	.MACRO Vm_alloc lab, bytes
	  .ALIGN 4096
		\lab:	.FILL \bytes
	.ENDM


#endif
### #ifndef CONTEXT_H_S
