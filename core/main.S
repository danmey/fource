	.GLOBL Vm_eval
	.GLOBL Vm_reset
	.GLOBL Vm_Exception_handler
	.GLOBL Vm_Save_image
	.GLOBL Vm_image_start
	.GLOBL Vm_image_end

	.text
.ALIGN 4096
Vm_image_start:
 	.ascii "IMG_START"

#include "interpret.S"
#include "literal.S"
#include "getkey.S"
#include "mem.S"
#include "exception.S"
#include "dict.S"

.TEXT 1
.ALIGN 4096
Vm_image_end:
 	.ascii "IMG_END"

	
