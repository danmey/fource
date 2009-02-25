## Emit_sub_call:
##  	// Get body of the word
## 	WBody 	%ebx
## 	// Calculate relative offset for call
## 	mov	%edi,	%eax
## 	sub	%ebx,	%eax
## 	neg	%eax
## 	sub	$5, 	%eax
## 	// Store op-code for call
## 	EmitB	%edi,	$0xE8
## 	EmitDW	%edi,	%eax
## 	EmitB	%edi,	$0xC3
## 	ret
