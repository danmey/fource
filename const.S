/*										
 *	Internal constants used in VM 						
 */										

/* Word name size */
#define NAMESIZE		32
/* Maximum dictionary cells */
#define	MAXCELLS		(1024*1024)
/* Size of stack */
#define STACKCELLS		(1024*1024)
/* Size of return stack */
#define RETURNCELLS		(1024*1024)
/* Flag up immediate words */
#define IMMEDIATE_WORD		(1<<1)
/* Flag up hidden word */
#define HIDDEN_WORD		(1<<2)
/* Flag variable. NEEDED? */
#define VARIABLE		(1<<3)




/*										
 *	Return values from VM
 */
	
/* Kernel waits for more input */
#define VM_STATE_ACCEPTING	(1<<1)
/* Kernel is intepreting stream */
#define VM_STATE_INTERPRETING	(0<<0)
/* Kernel is compiling */
#define VM_STATE_COMPILING	(1<<0)
/* Kernel thrown an exception */
#define VM_STATE_EXCEPTION	(2<<2)
/* Mask out stream index where exception occured */
#define VM_CHARACTER_INDEX_MASK	(0xFFFF0000)
/* What kind of exception occured? */
#define VM_EXCEPTION_ID_MASK	(0x0000FF00)

#define VM_IS_ACCEPTING(a) 	(VM_STATE_ACCEPTING&(a))

#define VM_IS_INTEPRETING(a) 	(VM_STATE_INTEPRETING&(a))

#define VM_IS_COMPILING(a) 	(VM_STATE_COMPILING&(a))

/* Catching VM exception */
#define VM_CATCH(a,_ex,_index) \
 	if( VM_STATE_EXCEPTION & (a) ) { \
		(_ex) = ((VM_EXCEPTION_ID_MASK&(a))>>16); \
		(_index) = (VM_CHARACTER_INDEX_MASK&(a)>>16); \
	} \
	if( VM_STATE_EXCEPTION & (a) ) 
	
/*						
 *	Exceptions
 */
	
/* TODO: Define further exceptions */

/* Any exception */
#define ANY_EXCEPTION			0
/* End of stream exception, occurs when VM accepts input
   when there is no more character left.
   Used for reclaiming the control flow to VM host */
#define END_OF_STREAM_EXCEPTION		1
/* Word is not found */
#define WORD_NOT_FOUND_EXCEPTION	2

#define STACKDEPTH 256		

#define CNT_CONTEXT 0
#define CNT_DI 	 0
#define CNT_SI 	 4
#define CNT_BP 	 8
#define CNT_SP 	12
#define CNT_BX 	16
#define CNT_DX 	20
#define CNT_CX 	24
#define CNT_AX 	28
#define CNT_OLD_SP  32
#define CNT_IP	36
#define CNT_REG_SIZE	40
#define CNT_STACK     ((CNT_OLD_SP)+4)
#define CNT_RET_STACK ((CNT_STACK)    +((STACKDEPTH)<<2))
#define CNT_EXIT      ((CNT_RET_STACK)+((STACKDEPTH)<<2))
#define CNT_INIT      ((CNT_EXIT)+4)
#define CNT_SIZE      ((CNT_INIT)+4)


