#include "ccall.h.S"
#define PROT_READ	0x1		/* Page can be read.  */
#define PROT_WRITE	0x2		/* Page can be written.  */
#define PROT_EXEC	0x4		/* Page can be executed.  */

.GLOBL init_mem
init_mem:
	pushal
	.GLOBL	_Image_start
	movl	$_Image_start,	%eax
	andl	$0xfffff000,	%eax
	C_call	mprotect, $(PROT_READ | PROT_WRITE | PROT_EXEC),$(64*1024), %eax 
	popal


	ret