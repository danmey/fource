#include "ccall.h.S"

.GLOBL Fmt_dec
.GLOBL Parse_literal
	.DATA
Fmt_dec:	.ASCIZ "%d\n"
Fmt_hex:	.ASCIZ "%x"
Fmt_real:	.ASCIZ "%f"
_temp_long:	.LONG 0

	
################################################################################	
# Parse literal, string is in _token
# TODO: Make it work with floats
# In:
# Out:	
# eax - integer value
Parse_literal:
# Check for dot if dot is present then we have floating point number
	push 	%edi
	mov	$Token_buffer,%edi
# string length
	xor 	%ecx,%ecx
	not	%ecx
	xor 	%eax,%eax
	cld
	repnz 	scasb
	not 	%ecx
	dec 	%ecx
 
	mov	$'.',%al
	mov	$Token_buffer,%edi
	repnz 	scasb
	jnz	1f	# real

	C_Call_ret_safe sscanf,$_temp_long,$Fmt_real, $Token_buffer
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret
1:
	cmpb	$10,var_base
	jz	2f
	C_Call_ret_safe sscanf,$_temp_long,$Fmt_hex, $Token_buffer
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret 
2:	
# Use cheap sscanf
	C_Call_ret_safe sscanf,$_temp_long,$Fmt_dec,$Token_buffer
3:	
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret
