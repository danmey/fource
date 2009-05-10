#ifndef _CCALL_H
#define _CCALL_H


################################################################################
### Module: 		CCall
### Description: 	Defines some useful macros for calling C routines
### 


	

################################################################################
### Macro: 	_C_call
### Description:
### 	Inner macro for unsafe C function call
###	Assumes that every parameter is dword wide
###	Fixes stack after call
### Arguments:
### 	>size: 	accumulated size of pushed params on stack
### 	>func:	called function
###	>head:	first parameter
###	>tail:	rest of parameters
	.MACRO _C_call size, func, head, tail:vararg
		.ifb \tail
			pushl 	\head
			call 	\func
			add	$\size,	%esp
		.else
			pushl	\head
			_C_call \size+4,\func,\tail
		.endif
	.ENDM
################################################################################


	

	################################################################################
### Macro: 	_C_call
### Description:
### 	Inner macro for unsafe C function call
###	Assumes that every parameter is dword wide
###	Fixes stack after call
### Arguments:
### 	>size: 	accumulated size of pushed params on stack
### 	>func:	called function
###	>head:	first parameter
###	>tail:	rest of parameters

	########################################################################
	# Macro: 	C_call
	# Desc:	 	Macro for unsafe C function call
	#		Assumes that every parameter is dword wide
	#		Fixes stack after call
	#
	# 	>func:	called function
	#	>tail:	rest parameters
	.MACRO C_Call func, params:vararg
		.set _Arg_size,0
		.ifb \params
			call \func
		.else
			_C_call 4, \func, \params
		.endif
	.ENDM

	.MACRO C_Call_safe params:vararg
		pusha
		C_Call \params
		popa
	.ENDM

	.MACRO C_Call_ret_safe params:vararg
		pusha
		C_Call \params
		movl	%eax, 28(%esp)
		popa
	.ENDM

	.MACRO C_Call_edx params:vararg
		pusha
		C_Call \params
		movl	%eax, 20(%esp)
		popa
	.ENDM


#endif
