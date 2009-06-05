#include "const.h"			
#include "context.h"			
#include "continuation.h"			
#include "ccall.h"
#include "dict.h"



	## Our enviroment context, TODO: Do we need that?
	Define_context Enviroment_context


### This is our continuation, in case of EOF we escape from the conitunation
Define_continuation_with_context Vm
vm_loop:
	C_Call_safe	Get_word
	mov		$Token_buffer,	%ebx
	C_Call_edx	Find_word
	orl		%edx,		%edx
	jnz		not_literal
### We need to compile literal
		C_Call_edx	Parse_literal
		jz 		word_not_found
		Vm_push		%edx
		jmp		compile_literal		# loop
not_literal:	
### We need to compile word
	Vm_push	%edx
	movl	var_state,	%ecx
	mov	Word_semantics(%edx,%ecx,4), %edx # get the execution token
	Call_abs	%edx
	jmp vm_loop
word_not_found:	
	Set_continuation_slot $WORD_NOT_FOUND_EXCEPTION, CNT_DX, Exception_data
	Call_with_cc_with_context Exception
	jmp vm_loop

compile_literal: 
	cmpl	$VM_STATE_COMPILING, var_state
	jnz	vm_loop
		call	wcode_literal
1:
	jmp 	vm_loop
	
Vm_eval:
	call 	init_mem
	Vm_Save_context Enviroment_context
	push	%ebp
	mov	%esp,%ebp
	mov	8(%ebp),%eax
	mov	%eax,Input_stream
	call	Vm_Entry_point
	pop	%ebp
	ret
	
Continuation_entry Vm_Entry_point, Vm, Vm_data

	.MACRO Upper_case regb
		cmpb	$'a',	\regb
		jb	9f
		cmpb	$'z',	\regb
		ja	9f
		subb	$0x20,	\regb
	9:
	.ENDM

# TODO: Make general macro for definition of procedures
Find_word:
 	movl	var_last,	%edx
next:
	
	movl	$NAMESIZE,	%ecx
	leal	4(%edx),	%edi
	mov	$Token_buffer,	%esi
1:
# Following chunk of code compares uppercase converted characters
	xorl	%eax,	%eax
	movb	(%esi),	%ah
	Upper_case 	%ah
	movb	(%edi),	%al
	Upper_case 	%al
	inc	%esi
	inc	%edi
	cmp	%al,	%ah
	jnz	not_found
	dec	%ecx
	jne	1b
	cmp	$1, 36(%edx)
	jz	not_found
	mov	%edx,	%eax
	ret
not_found:
	movl	(%edx),		%edx
	or	%edx,		%edx
	jnz	next
	xor	%eax,	%eax
	ret

Vm_reset:	
	Reset_continuation Vm
	ret
	
	