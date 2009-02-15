#include <stdio.h>
#include <assert.h>
#include "const.S"


char* Vm_interpret(const char* buffer);
void  Vm_reset    (void);




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


int main()
{
  char line[257];
  while( EOF != just_one_line(stdin, 256, line) )
    {
      char* word = Vm_interpret(line);
      //      puts("ala");
      //      if ( word != NULL )
	//	puts(word);
      //
    }
  return 0;
}
