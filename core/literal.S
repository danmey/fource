#include "ccall.h.S"

Fmt_dec:	.ASCIZ "%d"
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
	mov	$_token,%edi
	repnz 	scasb
	jnz	1f	# real

	C_Call_ret_safe sscanf,$_token,$Fmt_float,$_temp_long
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret
1:
	cmpb	$10,_var_base
	jz	2f
	C_Call_ret_safe sscanf,$_token,$Fmt_hex_val,$_temp_long
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret
2:	
# Use cheap sscanf
	C_Call_ret_safe sscanf,$_token,$Fmt_dec_val,$_temp_long
3:	
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret
