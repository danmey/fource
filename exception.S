################################################################################
# 			Exception module
#			================
#
#		+------------------------------+
#		| return address from CATCH    |   
#		| (ip)                         |   
#		+------------------------------+
#		| 32 bytes stack frame with    |
#		| our saved context before     |	 
#		| execution   		       |
#		+------------------------------+  ^
#		| exception stack marker       |  |
#		| 		               |  |   Direction of stack
#		+------------------------------+  |   unwinding by THROW.
#						  |
#
# Basic usage:
# ============
#
#
#	Try_any a_label
#		call Do_something
#		call Do_even_more
#	Catch
#		C_call printf "The rat's been killed!\n"
#	End_try


# Stupid value but... thats for prototype

#define EXCEPTION_MARKER 	Vm_Dispatch_exception
#define EXCEPTION_STACKFRAME	(4+4+32)

	.BSS
	Define_context Vm_Exception_context
	
	.DATA
	.ALIGN 4
	
	.MACRO 	Try exception_id catch_label 
		pushl	\catch_label	# store our return address on stack
		pushal			# store our context (EASY!)
		pushl	\exception_id
		pushl	$EXCEPTION_MARKER
	.ENDM



	
	.MACRO Catch catch_label
		add	$(EXCEPTION_STACKFRAME),%esp
		jmp	\catch_label\()_end
	\catch_label:
	.ENDM



	
	.MACRO 	End_try catch_label
		\catch_label\()_end:
	.ENDM

	

	
	.MACRO  Throw	exception_id
		mov	\exception_id,	%ecx
	1:
		popl	%edx
		cmpl	$EXCEPTION_MARKER,%edx
		jnz	1b
		popl	%edx
		or	%edx,	%edx
		jz	2f
		cmp	%ecx,	%edx
		jnz	1b
	2:	
		popal
		ret
	.ENDM
		

# Thats all folks! 	:)
