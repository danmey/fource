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
#include "const.h"

	


	
	
### ############################################################################
### Let's declare some helper macros
	
	## .MACRO Struct
	## 	.struct 0
	## .ENDM
	
	## .MACRO Field label, len
	## 	\label\():	.struct \label+\len
	## .ENDM

	## .MACRO End_struct
	## 	.data
	## .ENDM



	
### ############################################################################
### Our continuation context data structure

	## Struct
	## 	field 	cnt_stack, 	(STACKDEPTH<<2)	# Parameter stack 
	## 	field 	cnt_ret_stack, 	(STACKDEPTH<<2)	# Return stack 
	## 	field 	cnt_context,	32+4		# Registers
	## 	field 	cnt_exit,	4		# Doubled!
	## 	field 	cnt_IP,		4 		# Program Pointer
	## 	field 	cnt_init,	4		# Init flag
	## 	field 	cnt_size,	0		# Size of tje strucuture
	## End_struct
	
	


	.MACRO Define_continuation_context name
			.ALIGN	32
			.LCOMM	\name, CNT_SIZE
	.ENDM



	
### ###########################################################################
### Define the continuation 

	.MACRO Define_continuation name
	\name:
	## That's needed becaue of bug in GAS macros

	## Neet to play a little bit with stack to not destroy registers
	## and fetch the paremeter to %ebp
		
		mov	(%esp), %ebp
		Vm_Restore_general_reg %ebp,CNT_CONTEXT
		xchg	4(%esp),%eax
		movl	%eax,	CNT_EXIT_DATA(%ebp)
		movl	$\name,	CNT_CONTINUATION(%ebp)
		xchg	4(%esp),%eax
		## Execute only ones
		cmp	$0, 		CNT_INIT(%ebp)
		jnz	9f

		## Initialize stack pointers
		lea	(CNT_RET_STACK	+(STACKDEPTH<<2)-4)(%ebp),%esp
		lea	(CNT_STACK +     (STACKDEPTH<<2)-4)(%ebp),%esi

		## Trick, in first invocation it points to 8f 
		movl	$8f,	CNT_IP(%ebp)

		## We are inited 
		movl	$1, CNT_INIT(%ebp)

		## Save our context by popping out saved %ebp
		Vm_Save_context_reg	%ebp, CNT_CONTEXT
		push	%ebp
		
	9:
		pop 	%ebp
		pop	%eax
		## Jump to the code where we suspended 
		Vm_Restore_context_reg %ebp, CNT_CONTEXT
		pushl	CNT_IP(%ebp)
		ret
	8:
		### This is first invocation 
		Vm_Restore_context_reg %ebp, CNT_CONTEXT
	

	.ENDM


	
### ###########################################################################
### Define the continuation call
 	.MACRO Call_with_cc cont, data
		Vm_Save_context_reg 	%ebp, CNT_CONTEXT
 		movl	$9f,	CNT_IP(%ebp)
 		pushl	%ebp
		pushl	$\data
		pushl	$\cont
		ret
	9:	
 	.ENDM

### ###########################################################################
### Return from continuatiom
	.MACRO Exit_continuation_ret 
		Vm_Save_context_reg 	%ebp, CNT_CONTEXT

		### Set the ip to the next instruction 
		movl	$9f,	CNT_IP(%ebp)
		pushl	CNT_EXIT(%ebp)
		nop
		ret
	9:	
	.ENDM

	.MACRO Exit_continuation 
		Vm_Save_context_reg 	%ebp, CNT_CONTEXT
		### Set the ip to the next instruction 
		movl	$9f,	CNT_IP(%ebp) # Save our instruction pointer
		pushl	%ebp		     # Pass old context to called cont
		movl	CNT_EXIT_DATA(%ebp),%ebp # Get called context
		pushl	%ebp
		pushl	CNT_CONTINUATION(%ebp)		 # Find main called proc
		ret
	9:	
	.ENDM

Define_continuation_context Dummy
### ###########################################################################
### Define the direct continuation call
	.MACRO Continuation_entry name, cont, data
	Define_context \name\()_context
	\name:
		Vm_Save_context \name\()_context
 		movl	$9f,	(\data+CNT_EXIT)
		pushl	$0
 		pushl	$\data
		jmp	\cont
9:
	Vm_Restore_context \name\()_context
	ret	
	.ENDM



	.MACRO Set_continuation_slot value, slot, data
		movl	\value, (\data+\slot)
	.ENDM

	.MACRO Define_continuation_with_context name
		Define_continuation_context \name\()_data
		Define_continuation \name
	.ENDM

	.MACRO Call_with_cc_with_context name
		Call_with_cc \name, \name\()_data
	.ENDM

#endif
### ifndef CONTINUATION_H_S
