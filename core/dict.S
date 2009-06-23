
				#include "const.h"
#include "dict.h"
#include "ccall.h"
#include "continuation.h"
#include "emit.h"
	Defvar state, "state", VM_STATE_INTERPRETING

	# Pointer to last word
	Defvar here, "here", Cells
	Defvar  base, "base", 10
	## We use subroutine threading and TOS optimizations
	## %esi contain our parameter stack and %eax TOS

	Defword plus, "+"
		add	%eax,(%esp)
		pop	%eax
	Endword

	Defword minus, "-"
		sub	%eax,(%esp)
		pop	%eax
	Endword

	Defword lor,"or"
		orl	%eax,(%esp)
		pop	%eax
	Endword
	
	Defword lshift, "lshift"
		mov	%eax,%ecx
		pop	%eax
		shl	%cl, %eax
	Endword

	Defword rshift, "rshift"
		mov	%eax,%ecx
		pop	%eax
		shr	%cl, %eax
	Endword

	Defword land, "and"
		and	%eax,(%esp)
		pop	%eax
	Endword
	
	Defword star, "*"
		pop	%edx
		imul	%edx,%eax
	Endword

	Defword dup, "dup"
		push	%eax
	Endword

	Defword swap, "swap"
		xchg	%eax, (%esp)
	Endword

	Defword rot, "rot"
		pop	%edx
		pop	%ecx
		push	%eax
		push	%ecx
		mov	%edx,%eax
	Endword

	Defword dot, ".r"
		movl	%eax,	%ecx
		pop	%eax
		cmpl	$10, var_base
		jnz 	1f
			C_Call_ret_safe sprintf,%eax,$Fmt_dec,$Fmt_temp
			jmp	2f
	1:
		cmp	$16, var_base
		jnz 	2f
			C_Call_ret_safe sprintf,%eax,$Fmt_hex_,$Fmt_temp
	
	2:
		subl	%eax,%ecx
	4:	
		cmp	$0, %ecx
		jle	3f
		C_Call_safe	putchar,$0x20
		decl	%ecx
		jmp	4b
	3:
		C_Call_safe	printf,$Fmt_temp
		C_Call_safe	fflush,stdout
		pop	%eax
	Endword
	
	Defword lsqbracket, "]", $wcode_execute
		movl	$VM_STATE_COMPILING, var_state
	Endword

	Defword rqbracket, "[",	$wcode_execute
		movl	$VM_STATE_INTERPRETING, var_state
	Endword

	Defword compile,"compile,"
		pusha 
		mov	var_here, %edi
		addl	$Word_header_size,%eax
		Emit_sub_call	%eax
		mov	%edi, var_here
		popa
		pop	%eax

	Endword

	Defword literal, "literal"
		mov	var_here,%edi
		Emit_literal	%eax
		mov	%edi, var_here
		pop	%eax
	Endword

	Defword exit_comma,"exit,",IMM
		pusha
		
		movl	var_here,%edi
		mov	$0xC3,	%eax
		stosb
		movl	%edi, var_here
		popa
	Endword

	Defword comma, ","
		mov	var_here,%edi
		stosl
		mov	%edi,var_here
		pop	%eax
	Endword

	Defword char_comma, "c,"
		pusha
		mov	var_here,	%edi
		stosb
		mov 	%edi,var_here
		popa
		pop	%eax
	Endword

	Defword sp_fetch, "sp@"
		push	%eax
		mov	%esp,%eax
	Endword
	
	Defword execute,"execute"
		addl	$Word_header_size,%eax
		mov	%eax,	%edx
		pop	%eax
		xchg	%esi,	%esp
		pushl	$1f
		push	%edx
		ret
	1:
	 	xchg	%esi,%esp
	Endword

 	Defword fetch,"@"
		movl	(%eax),%eax
	Endword

	Defword fetchb,"c@"
		movzbl	(%eax),%eax
	Endword

	## This two need to be inlined as we operate on return stack
	## which is also used for subroutine threading
	Defword pushret, ">r", IMM
		mov	var_here,%edi
		EmitB	%edi,	$0x50 # push %eax

		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #

		EmitB	%edi,	$0x58 # pop %eax

		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #
		mov	%edi,	var_here
	Endword

	Defword popret, "r>", IMM
		mov	var_here,%edi
		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #
		EmitB	%edi,	$0x50 # push %eax
		EmitB	%edi,	$0x87 # xchg %esp,%esi
		EmitB	%edi,	$0xe6 #
		EmitB	%edi,	$0x58 # pop %eax
		mov	%edi,	var_here
	Endword

	### 
	Defword drop, "drop"
		pop	%eax
	Endword


	
	Defword branch_comma, "branch,",wcode_execute
		pusha
		mov	var_here, %edi
		Emit_branch_b
		dec	%eax	# adjust for jmp byte code and jmp
		dec	%eax	
		EmitB	%edi,%al
		mov	%edi,var_here
		popa
		pop	%eax
	Endword

	Defword branch0_comma, "0branch,",wcode_execute
		pusha
		mov	var_here, %edi
		Emit_branch0_b
		subl	$9,%eax	# adjust for jmp byte code and jmp
		EmitB	%edi,%al
		mov	%edi,var_here
		popa
		pop	%eax
	Endword


	Defword ubelow, "u<"
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jb	1f
		xor	%eax,%eax
	1:	
	Endword

	Defword below, "<"
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jl	1f
		xor	%eax,%eax
	1:	
	Endword

	Defword above, ">"
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jg	1f
		xor	%eax,%eax
	1:	
	Endword

	Defword tick,"'"
		C_Call_safe	Get_word
		C_Call_edx 	Find_word
		orl	%edx,%edx
		jz	1f
		pushl	%eax
		mov	%edx,%eax
		jmp	2f
1:	
		Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_DX, Exception_data
		Call_with_cc_with_context Exception
2:	
	Endword
	
	Defword ccompile,"[compile]", IMM
		C_Call_safe	Get_word
		C_Call_edx 	Find_word
		orl	%edx,%edx
		jz	1f
		lea 	Word_header_size(%edx),%ecx
		mov	var_here,%edi
		Emit_sub_call 	%ecx
		mov	%edi,var_here
		jmp	2f
1:	
		Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_DX, Exception_data
		Call_with_cc_with_context Exception
2:	
	Endword

	Defword test,"test"
		mov	var_here,%edi
		Emit_literal %eax
		Emit_sub_call $wcode_compile
		mov	%edi, var_here
		pop	%eax
	Endword
	
	Defword slash,"postpone", IMM
		C_Call_safe	Get_word
		C_Call_edx 	Find_word
		orl	%edx,%edx
		jz	1f
        	push    %eax            # push TOS
        	mov     %edx,   %eax    # set TOS to value of literal
        	xchg    %esi,%esp
                mov     $wcode_compile, %edx
                pushl   $2f                               # form call to XT
                pushl   %edx
                ret

1:	
		Set_continuation_slot $WORD_TO_LONG_EXCEPTION, CNT_DX, Exception_data
		Call_with_cc_with_context Exception
		jmp	3f
2:	        	xchg    %esi,%esp

3:	
	Endword

	Defword immediate,"immediate", IMM
		movl	var_last,%edx
		movl	$wcode_execute,WOFFS_COMPILATION_TOKEN(%edx)
	Endword

	Defword create, "create"
		xchg	%esi,%esp
		C_Call_safe	Get_word
		pusha
		movl	var_here,	%edi
		movl	$Token_buffer,	%esi
		movl	var_last,%eax
		push	%edi
		stosl
		mov	$1, 	%eax
		mov	$32,	%ecx
	1:
		or	%eax,%eax
		jz	3f
		lodsb
	3:
		stosb
		dec	%ecx
		jnz	1b
		movl	$1,%eax
		stosl
		movl	$wcode_execute,%eax
		stosl
		movl	$wcode_compile,%eax
		stosl
		movl	%edi,	var_here
		pop	%edi
		mov	%edi,var_last
		popa
		xchg	%esi,%esp
	Endword

	Defword store, "!"
		pop	(%eax)
		pop	%eax
	Endword

	Defword char_store, "c!"
		pop	%ecx
		mov	%cl,(%eax)
		pop	%eax
	Endword

	Defword invert, "invert"
		not	%eax
	Endword

	Defword equals, "="
		cmp	%eax,(%esp)
		pop	%eax
		mov	$-1,%eax
		jz	1f
		xor	%eax,%eax
	1:	
	Endword
	
	Defword key, "key"
		push	%eax
		C_Call_ret_safe	Get_key
	Endword

	Defword emit, "emit"
		C_Call_safe 	putchar,%eax
		C_Call_safe	fflush,stdout
		pop	%eax
	Endword

	Defword dlopen,"dlopen"
		pushl	%eax
		movl	$dlopen,%eax
	Endword
	
	Defword dlsym,"dlsym"
		pushl	%eax
		movl	$dlsym,%eax
	Endword

	Defword depth,"depth"
		lea	(CNT_STACK+(STACKDEPTH<<2)-8)(%ebp),%ecx
		sub	%esp,%ecx
		push	%eax
		mov	%ecx,%eax
		shr	$2,%eax
	Endword

	Defword pick,"pick"
		or	%eax,%eax
		jnz	1f
		pop	%eax
		push	%eax
		jmp	2f
	1:	
		dec	%eax
		movl	(%esp,%eax,4),%eax
	2:	
	Endword
		
#ifdef WITH_GC
	Defword gcalloc,"gc_alloc"
		pushal
		push	%eax
		call	gc_alloc
		add	$4, %esp
		mov	%eax,28(%esp)
		popal
	Endword
#endif				
	
	Defword saveimage, "saveimage"
	# a dirty hack :)
		movl	$1,Vm_Save_image
		Exit_continuation_ret
	Endword
	Defvar last, "last", wstart_last
Vm_Save_image:	 .LONG 0
image_name:	.ASCIZ "image.fi"
wb:	.ASCIZ "wb"
Fmt_temp:
	.FILL 	32
	.align 32
Cells:	
	.FILL 1024*1024
.TEXT


	

