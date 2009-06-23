#include "ccall.h"

.TEXT 1
Fmt_dec:	.ASCIZ "%d"
Fmt_hex:	.ASCIZ "%x"
Fmt_hex_:	.ASCIZ "%#x"	
Fmt_real:	.ASCIZ "%f"
	
_temp_long:	.LONG 0
.TEXT
	
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
	cmpb	$'$',Token_buffer
	jnz 	5f
4:
	C_Call_ret_safe sscanf,$_temp_long,$Fmt_hex, $(Token_buffer+1)
	cmp	$0,%eax
	mov 	_temp_long,%eax
	pop	%edi
	ret 
5:	
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
