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

#ifdef WITH_GC
#include "gc/gc.S"
#endif
#include "interpret.S"
#include "literal.S"
#include "getkey.S"
#include "mem.S"
#include "exception.S"
#include "dict.S"
#ifdef WITH_GC
#include "trailer.S"
#endif

.TEXT 1
.ALIGN 4096
Vm_image_end:
 	.ascii "IMG_END"

	
