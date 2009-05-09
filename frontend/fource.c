#include "vm.h"

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/mman.h>
#include <linux/errno.h>
#include <sigsegv.h>
#include <features.h>
#include <getopt.h>


extern Vm_Exception_handler_t Vm_Exception_handler;
extern void Vm_interpret(char *);
extern char _Image_start;
extern char _Image_end;

/* FIX: refactored by (JO) */
#define PANIC(_rcode,...) ( {fprintf(stderr, "Fatal: "); fprintf(stderr, __VA_ARGS__ ) ; exit(_rcode); })
#define FEAR(...) ({fprintf(stderr, "Warning: "); fprintf(stderr,  __VA_ARGS__ ); })


struct {
  int be_quiet;
  void* image_file;
} opts;
  
int
process_opts (int argc, char **argv)
{
  char* image_file_name = NULL;
  int opterr = 0;
  int c = 0;
  while ((c = getopt (argc, argv, "i:")) != -1)
    switch (c)
      {
      case 'i':
	continue;
      default:
	abort ();
      }
  
  
  for (int index = optind; index < argc; index++)
    printf ("Non-option argument %s\n", argv[index]);
  return 0;
}

void 
enable_memory_block(void* start, void* end)
{
  if ( -1 == mprotect(start,end-start,(PROT_READ | PROT_WRITE | PROT_EXEC)))
    {
      printf("Error: mprotect\n");
      exit(1);
    }
}

void 
install_exception_handler(Vm_Exception_handler_t handler)
{
  Vm_Exception_handler = handler;
}


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
		    FEAR("Line exceeded %d characters. Truncated.",nread);
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
    case WORD_NOT_FOUND_EXCEPTION:
      printf("***Exception: Word '%s' not found..\n", ex->word_name);
      break;
      }
}

void run_repl()
{
  static char line[257];
  while( EOF != just_one_line(stdin, 256, line) )
      Vm_interpret(line);
}

// Promising, but need to find way of portable dealing with signals
/*
sigsegv_dispatcher ss_dispatcher;

int ss_handler(void* fault_address, int serious);
void loop(void*p1, void*p2, void*p3)
{
  sigsegv_init(&ss_dispatcher);
  sigsegv_install_handler(ss_handler);
  char line[257];
  while( EOF != just_one_line(stdin, 256, line) )
    {
      Vm_interpret(line);
    }
}

int ss_handler(void* fault_address, int serious)
{
  printf("***Exception: Segmentation fault %x %d\n", fault_address, serious);
  sigsegv_leave_handler(loop, 0,0,0);
  return 1;
}

*/


int main(int argc, void* argv)
{
  //  sigsegv_init(&ss_dispatcher);
  //  sigsegv_install_handler(ss_handler);
   
  process_opts(argc,argv);
  enable_memory_block(&_Image_start, &_Image_end);
  install_exception_handler(kernel_exception_handler);
  run_repl();
  return 0;
}
