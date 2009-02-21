#include <stdio.h>

extern char _Image_start;
extern char _Image_end;
int main()
{
  FILE* f = fopen("./image", "wb");
  int size = &_Image_end-&_Image_start;
  fwrite(&size, 4, 1, f);
  fwrite(&_Image_start, size, 1, f);
  fclose(f);
  return 0;
}
