include(macros.m4)
include(const.S)

.section .bss
	
.lcomm _token,NTAB_ENTRY_SIZE
.lcomm 	_code_mode_word, NTAB_ENTRY_SIZE
.lcomm _pad, 1024
.section .data

_fmt_hex:		.asciz 	"%x"
_fmt_dec:		.asciz 	"%d"
_fmt_float: 		.asciz  "%f"
_fmt_str:		.asciz 	"%s"
_tmp_dec_val:		.long	0
_fmt_Word_not_found:	.asciz 	"Unknown word: '%s'\n"
_var_base:		.long 	10
_code_mode:		.long 	0
_latest:		.long 	 _code_abort
_interpret_bcode:	.long 0, _code_abort - _dict
_cmd_gcc:		.asciz "as -o __tmp.o __tmp.s\n"
_fmt_cmd_ld:		.asciz "ld -Ttext %x -s --oformat binary -o __tmp.bin __tmp.o"
_str_asm_file_name:	.asciz "__tmp.s"
_str_asm_file_access:	.asciz "wt"

.globl main

main:
	# Reserve some space for Return stack
#	mov	%esp,_vm_param_stack_start
	mov 	%esp,%ebp		
	sub	$RET_STACK_SIZE,%ebp
#	mov	%ebp,_vm_return_stack_start

#	call	_show_welcome
# Main loop
_interpet_loop:
	call 	_get_token	# token
	mov 	$_token,%edx
	call 	_find_word
	jnc 	1f		# found word
	K4_SAFE_CALL(printf,$_fmt_Word_not_found, $_token)
	jmp 	_interpet_loop
1:	
	movl 	$_interpret_bcode,%esi
	sub	$_dict, %eax
	mov 	%eax,(%esi)		# do it
	jmp 	_next_word		# run interpreter
	ret
# edx <- word
# eax -> word_ptr
_find_word:
	mov	_latest, %ebx
1:
	or	%ebx,%ebx
	jz	2f
	add	$8,%ebx
	K4_SAFE_CALL(strcmp, %edx,%ebx)
	or	%eax,%eax
	jz	1f
	sub	$4,%ebx
	mov	(%ebx),%ebx
	jmp	1b
1:
	mov	%ebx,%eax
	sub	$8,%eax
	clc
	ret
2:
	xor 	%eax,%eax
	stc
	ret



################################################################################	
# Get token, separated by whites, and put it in _token
# TODO: Make it case insesitive (lowercase everything)
# In:
# Out:	
# eax - integer value
# _token - a token
_get_token:
	
# Skip whites
	call	_get_key_white_skip
	mov 	$_token,%edi
	mov 	$NTAB_ENTRY_SIZE,%ecx
1:	
	dec %ecx			# keep the counter becasue we need to clear out _token
	stosb				# in al we had out character
	call _get_key			# get next key
	call _is_white			# is white?
	jnz 1b				# NO?
	K4_SAFE_CALL(ungetc,%eax,stdin)	# unget char
	xor 	%eax,%eax		# clear status (not needed?)
	rep 	stosb			# Fill rest of _token
	ret
	
	
	
################################################################################	
# Parse literal, string is in _token
# TODO: Make it work with floats
# In:
# Out:	
# eax - integer value
_parse_literal:
# Check for dot if dot is present then we have floating point number
	push 	%edi
	mov	$_token,%edi
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

	K4_SAFE_CALL(sscanf,$_token,$_fmt_float,$_tmp_dec_val)
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret
1:
	cmpb	$10,_var_base
	jz	2f
	K4_SAFE_CALL(sscanf,$_token,$_fmt_hex,$_tmp_dec_val)
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret
2:	
# Use cheap sscanf
	K4_SAFE_CALL(sscanf,$_token,$_fmt_dec,$_tmp_dec_val)
3:	
	cmp	$0,%eax
	mov 	_tmp_dec_val,%eax
	pop	%edi
	ret
	
################################################################################	
# Get key, skipping whites
# In:
# Out:	
# al - an ASCII code of character
# _token - a token
_get_key_white_skip:
	call _get_key
	call _is_white
	jz _get_key_white_skip	# loop until we will find something
	ret

################################################################################	
# Is white?
# In:
# al - an ASCII code of character
# Out:
# Z - if its white
# _token - a token
_is_white:
	cmpb	$10,%al		# CR ?
	jz	1f
	cmpb	$13,%al       	# LF ?
	jz	1f
	cmpb	$9,%al		# TAB ?
	jz	1f
	cmpb	$' ',%al	# SPACE ?
	jz	1f
1:	ret
	
	
################################################################################	
# Get char from STDIN, jumps out in case of EOF
# In:
# Out:
# al - an ASCII code of character
# _token - a token
_get_key:
	K4_SAFE_CALL(getchar)
	cmp 	$-1,%eax
	jz 	_exit
	cmpb	$10,%al
	jnz 1f
#	push	%eax
#	K4_SAFE_CALL(printf,$_msg_OK)
#	pop	%eax
1:	ret

_next_word:
 	xor 	%eax,%eax		# Clear up %eax
 	lodsl				# load a byte
	add 	$_dict, %eax		# convert dict offset to memory addres
 	jmpl 	*(%eax)			# run the first word

_dict:

_code_abort:	
def_code(abort)
	jmp	_interpet_loop
end_code

def_code(ldlib)
	
end_code

def_code(:code)
	K4_SAFE_CALL(_get_token)
	K4_SAFE_CALL(strcpy,$_code_mode_word, $_token)
	K4_SAFE_CALL(fopen,$_str_asm_file_name,$_str_asm_file_access)
	mov	%eax,%edx
1:
	K4_SAFE_CALL(_get_key)
	cmp	$';',%eax
	jz 	1f
	K4_SAFE_CALL(fputc,%eax,%edx)
	jmp 	1b
1:
	K4_SAFE_CALL(fclose, %edx)
	K4_SAFE_CALL(system, $_cmd_gcc)
	K4_SAFE_CALL(sprintf,$_pad,$_fmt_cmd_ld,_here+40)
	K4_SAFE_CALL(system, $_pad)
end_code
	
.lcomm fill,32*1024
