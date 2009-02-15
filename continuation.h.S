################################################################################
###
### 	Continuation module
### 	===================
###
### This set of macros allows one to program in CPS (Continuation Passing Style).
### Every registered continuation has a static block alocated in
### .bss section that preserves the context of suspended continuation.
###
### This block preserves:
### - register contents
### - parameter and return stack
### - intruction pointer
### 
### When the continuation is called, current continuation context is saved.
### target continuation context is restored then long jmp is performed to
### target continuation instruction pointer.
### 
### Parameter passing to continuations not implemented yet.
### For sake of the simplicity and effieciency this implementation
### doesn't care about global roots and heap.
### 
### Continuations allow us to easily implement: 
### - Green threads
### - Exceptions
### - Tail recursion 
###

	

	
#ifndef CONTINUATION_H_S
#define CONTINUATION_H_S




#include "context.h.S"


	
 	.EQU STACKDEPTH, 256


	
	
### ############################################################################
### Let's declare some helper macros
	
	.MACRO Struct
		.struct 0
	.ENDM
	
	.MACRO Field label, len
		\label\():	.struct \label+\len
	.ENDM

	.MACRO End_struct
		.data
	.ENDM



	
### ############################################################################
### Our continuation context data structure

	Struct
		field 	cnt_stack, 	(STACKDEPTH<<2)	# Parameter stack 
		field 	cnt_ret_stack, 	(STACKDEPTH<<2)	# Return stack 
		field 	cnt_context,	32+4		# Registers
		field 	cnt_IP,		4 		# Program Pointer
		field 	cnt_exit_cnt,	4		# Continuation at exit
		field 	cnt_init,	4		# Init flag
		field 	cnt_size,	0		# Size of tje strucuture
	End_struct
	
	


### ###########################################################################
### Define the continuation 
	.MACRO Define_continuation name, exit_continuation
		.bss

		### we should really keep the pointers if
		### we dont need to alloc mem for every continuation
		### please see exceptions
			.ALIGN	32
			.LCOMM	\name, cnt_size
		.data

	\name\()_code:

		### Execute only ones
		cmp	$0, (\name + cnt_init) 
		jnz	9f

		### Initialize stack pointers
		lea	(\name + cnt_stack +     (STACKDEPTH<<2)-4),	%esi
		lea	(\name + cnt_ret_stack	+(STACKDEPTH<<2)-4),	%esp

		### Save our context 
		Vm_Save_context (\name + cnt_context)

		### Trick, in first invocation it points to 8f 
		movl	$8f,	(\name + cnt_IP)

		### We are inited 
		movl	$1, (\name + cnt_init)
	9:	
		Vm_Restore_context (\name + cnt_context)

		### Jump to the code where we suspended 
		pushl	(\name + cnt_IP)
		ret
	8:
		### This is first invocation 
		Vm_Restore_context (\name + cnt_context)
	

	

		### Ugly. Clean up previous macros
	.IFDEF first
		.PURGEM	Call_with_cc
		.PURGEM Call_continuation
		.PURGEM Exit_continuation
	.ENDIF

	




### ###########################################################################
### Define the continuation call
	.MACRO Call_with_cc callee_code 
		.data
	
		### Save the context 
		Vm_Save_context (\name + cnt_context)

		### Set the ip to the next instruction 
		movl	$9f,	(\name + cnt_IP)
		jmp	\callee_code
	9:	
	.ENDM

### ###########################################################################
### Return from continuatiom
	.MACRO Exit_continuation
		Call_with_cc \exit_continuation
	.ENDM



### ###########################################################################
### Define the direct continuation call
	.MACRO Call_continuation callee
	8:	
		Call_with_cc \callee
		movl	$8b, (\name+cnt_IP)
	.ENDM
	### Ugly.
	.SET first,0
	.ENDM

	

	
#endif
### ifndef CONTINUATION_H_S
