#include "dict.h.S"

	Defvar state, "state", VM_STATE_COMPILING
	# Pointer to last word
	Defvar here, "here", Cells
	## We use subroutine threading and TOS optimizations
	## %esi contain our parameter stack and %eax TOS
	Defword plus, "+"
		add	(%esi),%eax
		add	$4, %esi
	Endword

	Defvar last, "last", wstart_last

Cells:
	.FILL 1024*1024

	

