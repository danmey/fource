#ifndef _DICT_H_S
#define _DICT_H_S



#include "const.h"



	
	# Pointer to previous word, needed for constructing
	# statically new core words
 	.SET 		Wprev, 0


	# Macro that defines new word
	.MACRO 	Defword 	label, name, token:vararg
		.ALIGN 4
	wstart_\label:
		.LONG		Wprev		# This a link to previous word
	 	.LOCAL 		nstart		# Needed for padding the word
		.SET 		nstart, .	# name into 32 bytes
		.ASCIZ		"\name"	# store name
	 	.FILL 		NAMESIZE - ( . - nstart )	# pad it
		.LONG 	0
 		.SET		Wprev, wstart_\label	# update prev label
		.SET		Word_semantics, . - wstart_\label
		.GLOBL		Word_semantics
		.GLOBL		wcode_execute
		.LONG		wcode_execute
		.IFB \token
		.LONG wcode_compile
		.ELSE
		.LONG wcode_execute
		.ENDIF
#		.LONG		wcode_compile # meta compile
	wcode_\label:
		.SET	Word_header_size, wcode_\label - wstart_\label
		.GLOBL 	Word_header_size
		.GLOBL wstart_\label

	# This instruction is going to restore stack for local use in word
	# Parameter stack resides in %esi register
		xchgl	%esp,%esi
	.ENDM
	
	
	

	# Macro that terminates word
	.MACRO 	Endword
		xchgl 	%esp,%esi	# Restore return stack!
		ret
	.ENDM
	

	

	# Macro that defines a variable
	.MACRO 	Defvar 		label, name_str, value
		Defword	\label, \name_str
		push	%eax
		movl	$var_\()\label,%eax
		Endword 
var_\()\label:
		.LONG 	\value
	.GLOBL var_\()\label
	.ENDM


#endif
