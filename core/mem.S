#include "ccall.h"
#define PROT_READ	0x1		/* Page can be read.  */
#define PROT_WRITE	0x2		/* Page can be written.  */
#define PROT_EXEC	0x4		/* Page can be executed.  */
#define PROT_NONE	0x0		/* Page can not be accessed.  */

	.GLOBL Vm_init
Vm_init:
	pushal
	movl	$Vm_image_start,%eax
//	andl	$0xfffff000,	%eax
	C_call	mprotect, $(PROT_READ | PROT_WRITE | PROT_EXEC),$(Vm_image_end-Vm_image_start), %eax 

	## Protect stack boundaries, little bit clumsy but it works
	movl	$(Vm_data+PAGE_SIZE),	%eax
	C_call	mprotect, $(PROT_NONE),$PAGE_SIZE, %eax

	movl	$(Vm_data+3*PAGE_SIZE),	%eax
	C_call	mprotect, $(PROT_NONE),$PAGE_SIZE, %eax

	movl	$(Vm_data+5*PAGE_SIZE),	%eax
	C_call	mprotect, $(PROT_NONE),$PAGE_SIZE, %eax
	
	popal
	ret