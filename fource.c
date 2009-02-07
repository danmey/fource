#include <stdio.h>

char* vm_interpret(const char* buffer);

int main()
{
  char line[128];
  while( NULL != gets(line) )
    vm_interpret(line);
  return 0;
}
