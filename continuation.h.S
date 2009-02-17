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
### Our continuation implementation uses %ebp register as pointer to its data
### Maybe it is not the best choice, but serves as a playground.
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
		field 	cnt_exit,	4		# Doubled!
		field 	cnt_IP,		4 		# Program Pointer
		field 	cnt_init,	4		# Init flag
		field 	cnt_size,	0		# Size of tje strucuture
	End_struct
	
	


	.MACRO Define_continuation_context name
		.bss
			.ALIGN	32
			.LCOMM	\name, cnt_size
	.ENDM



	
### ###########################################################################
### Define the continuation 

	.MACRO Define_continuation name
		.DATA
	\name:
	## That's needed becaue of bug in GAS macros

	## Neet to play a little bit with stack to not destroy registers
	## and fetch the paremeter to %ebp
		
		mov	(%esp), %ebp
	
		## Execute only ones
		cmp	$0, 		cnt_init(%ebp)
		jnz	9f

		## Initialize stack pointers
		lea	(cnt_ret_stack	+(STACKDEPTH<<2)-4)(%ebp),%esp
		lea	(cnt_stack +     (STACKDEPTH<<2)-4)(%ebp),%esi

		## Trick, in first invocation it points to 8f 
		movl	$8f,	cnt_IP(%ebp)

		## We are inited 
		movl	$1, cnt_init(%ebp)

		## Save our context by popping out saved %ebp
		Vm_Save_context_reg	%ebp, cnt_context
		push	%ebp
		
	9:
		pop 	%ebp
		## Jump to the code where we suspended 
		Vm_Restore_context_reg %ebp, cnt_context
		push	%ebp
		pushl	cnt_IP(%ebp)
		ret
	8:
		### This is first invocation 
		pop 	%ebp
		Vm_Restore_context_reg %ebp, cnt_context
	

	

		### Ugly. Clean up previous macros
	.IFDEF first
		.PURGEM	Call_with_cc
		.PURGEM Enter_continuation
		.PURGEM Exit_continuation
	.ENDIF

	



	
### ###########################################################################
### Define the continuation call
 	.MACRO Call_with_cc cont, data
		Vm_Save_context_reg 	%ebp, cnt_context
 		movl	$9f,	cnt_IP(%ebp)
 		push	$\data
		jmp	\cont
	9:	
 	.ENDM

### ###########################################################################
### Return from continuatiom
	.MACRO Exit_continuation
		Vm_Save_context_reg 	%ebp, cnt_context

		### Set the ip to the next instruction 
		movl	$9f,	cnt_IP(%ebp)
		pushl	cnt_exit(%ebp)
		ret
	9:	
	.ENDM


### ###########################################################################
### Define the direct continuation call
	.MACRO Enter_continuation name_c, cont, data
	.BSS
	Define_context \name\()_context
	.DATA
	\name_c:
		Vm_Save_context \name\()_context
 		movl	$9f,	(\data+cnt_exit)
 		push	$\data
		jmp	\cont
9:
	Vm_Restore_context \name\()_context
	ret	
	.ENDM
	### Ugly.
	.SET first,0
	.ENDM

	

	
#endif
### ifndef CONTINUATION_H_S
