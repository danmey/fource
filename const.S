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
	

