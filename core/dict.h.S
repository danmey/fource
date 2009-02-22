#ifndef _DICT_H_S
#define _DICT_H_S



#include "const.h"



	
	# Pointer to previous word, needed for constructing
	# statically new core words
 	.SET 		Wprev, 0

	# Macro that defines new word
	.MACRO 	Defword 	label, name
		.ALIGN 4
	wstart_\label:
		.LONG		Wprev		# This a link to previous word
	 	.LOCAL 		nstart		# Needed for padding the word
		.SET 		nstart, .	# name into 32 bytes
		.ASCIZ		"\name"	# store name
	 	.FILL 		NAMESIZE - ( . - nstart )	# pad it
		.LONG		0		# Flags
		.SET		Wprev, wstart_\label	# update prev label
	wcode_\label:
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
		add	$4, %esi
		mov	%eax,(%esi)
		movl	var_\()\label,%eax
		Endword 
var_\()\label:
		.LONG 	\value
	.GLOBL var_\()\label
	.ENDM


#endif
