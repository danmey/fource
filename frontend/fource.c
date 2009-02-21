#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "vm.h"


// char* Vm_interpret(const char* buffer);
//void  Vm_reset    (void);




/* FIX: refactored by (JO) */
#define PANIC(_rcode,...) ( {fprintf(stderr, "Fatal: "); fprintf(stderr, __VA_ARGS__ ) ; exit(_rcode); })
#define FEAR(...) ({fprintf(stderr, "Warning: "); fprintf(stderr,  __VA_ARGS__ ); })


/* TODO: Make it windows friendly... */
/* VERY CLUMSY! */
int just_one_line(FILE* f, int max_buffer, char* o_buffer)
{
    assert(o_buffer != NULL);
    assert(f != NULL);
    // Need space for "\n\0"
    assert(max_buffer > 2);
  
    int nread=0, max_read = max_buffer-2, ch=0;
    while( nread < max_read &&
	   EOF != (ch = fgetc(f)) &&
	   ch != '\n' )
	{ o_buffer[nread] = ch; ++nread; }

    if ( nread == max_read )
	{
	    if ( ch != EOF )
		{
		    char msg[128];
		    FEAR("Line exceeded %d characters. Truncated.",msg);
		    return -2;
		}
	}
    
    if ( ch == '\n')
	o_buffer[nread++] = '\n';
    
    o_buffer[nread++] = '\0';

    if ( ch == EOF )
	return EOF;
  
    return nread;
}

// TODO: Add dump of registers and IP
int kernel_exception_handler(Vm_Exception_t* ex)
{
  switch(ex->id)
    {
    case WORD_TO_LONG_EXCEPTION: 
      // TODO: Put exception description in a table
      // TODO: Debug Fear macro as it crashes :)
      printf("***Exception: Word to long. Truncating..\n");
      break;
      }
}

extern Vm_Exception_handler_t Vm_Exception_handler;
extern void Vm_interpret(char *);
int main()
{
  /*
  void* lib = dlopen("./libfource.so",RTLD_LAZY);
  if ( lib == NULL )
    {
      char* dlError = dlerror();
      printf("error loading dll: %s\n", dlError);
      exit(1);
    }
  Vm_Exception_handler = dlsym(lib, "Vm_Exception_handler");
  Vm_interpret = dlsym(lib, "Vm_interpret");
  printf("%x\n", Vm_interpret);
  */
    char line[257];
    //printf("%x\n", &Vm_Exception_handler);
    Vm_Exception_handler = &kernel_exception_handler;
    while( EOF != just_one_line(stdin, 256, line) )
	{
	  Vm_interpret(line);
	    //      puts("ala");
	    //      if ( word != NULL )
	    //	puts(word);
	    //
	}
    return 0;
}
