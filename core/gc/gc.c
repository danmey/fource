#include <assert.h>
#include <stdio.h>
#include "test.h"
// Let's assume constant size of younger heap chunks
#define GC_MINOR_CHUNK_SIZE 256
#define GC_MINOR_HEAP_SIZE (1024*64)
#define GC_MAJOR_HEAP_SIZE (1024*1024*32)
// Let's assume that every data structure is pointer size aligned
#define GC_MINOR_CHUNKS (GC_MINOR_HEAP_SIZE/GC_MINOR_CHUNK_SIZE)
// We need to sacrifice first 4 bytes flag/size
// let's first bit to be set if chunk has been marked during collection
// initialy 0
#define GC_MINOR_BITS_SIZE (GC_MINOR_CHUNK_SIZE-sizeof(unsigned int))

#define GC_FLAG_FREE 0
#define GC_COL_WHITE 1
#define GC_COL_GREY 2
#define GC_COL_BLACK 3
#define GC_MARKED 1

#define BITS(ch) ((ch)+sizeof(unsigned int))
#define BITS_AT(ch, idx) (*(((void**)(BITS((ch))+(idx)*sizeof(void*)))))
#define FLAGS(ch) (*((unsigned int*) (ch)))
// Mark chunk with least significant bit set to 1
#define MARK_CHUNK(ch,col) ((FLAGS(ch)) |= col);

// Extract chunk size from flag/size field
#define CHUNK_SIZE(ch) (FLAGS((ch)) & (~3))
#define CHUNK_FLAGS(ch) (FLAGS((ch)) & (3))
// Align by 4 bytes boundary (TODO: make it more portable)
#define ALIGN(ptr) (((ptr)+3)&~3)
// if it's not marked
#define MEM_TAG(ptr) (!(((unsigned int)(ptr))&1))
// If the pointer is pointing the first generation heap
#define POINTS_MINOR(ptr) (((byte*)(ptr)) >= &gc_minor_heap[0] && ((byte*)(ptr)) < &gc_minor_heap[GC_MINOR_HEAP_SIZE])
// Calculate address of begining of chunk
#define MINOR_CHUNK(ptr) (((((byte*)(ptr) - &gc_minor_heap[0])/GC_MINOR_CHUNK_SIZE)*GC_MINOR_CHUNK_SIZE)+&gc_minor_heap[0])
// Find if the chunk points to another chunk
#define REF_PTR(ptr) (MEM_TAG((ptr)) && POINTS_MINOR((ptr)))
// Is it marked?
#define MARKED(ch) (FLAGS(ch) & 1)
//#define MJ_CHUNK_SIZE(ch) ((ch)->flags& (3<<
// The chunk structure
/*
typedef s
truct {
  unsigned int flags; 
  void* bits[GC_MINOR_BITS_SIZE/4];
} chunk_t;
*/
/*
// Major chunk header
typedef struct {
  unsigned int flags;
} chunk_hdr_t;
*/
// need to be aligned!
typedef char byte;
typedef unsigned int hdr;
typedef byte chunk[sizeof(hdr)+GC_MINOR_BITS_SIZE];

// Our first generation heap
byte gc_minor_heap[GC_MINOR_HEAP_SIZE];
// Elder generation heap
byte gc_major_heap[GC_MAJOR_HEAP_SIZE];
// Points to free chunk
int gc_cur_min_chunk = 0;
//byte* gc_mj_ptr = gc_major_heap;
// Some logging/debugging facilities
//#define LOGGING
#ifdef LOGGING
#define LOG(...) do {printf("gc_log: ");printf( __VA_ARGS__ );printf("\n");} while(0)
#else
#define LOG(...)
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marks ref
void mark_chunk(byte* ch)
{
  MARK_CHUNK(ch, GC_MARKED);
  LOG("Starting marking chunk: %d", ch-&gc_minor_heap[0]);
  int i;
  for(i=0; i < CHUNK_SIZE(ch)/sizeof(void*); ++i)
    {
      if ( REF_PTR(BITS_AT(ch,i)) )
        {
	  byte* ref_ch = MINOR_CHUNK(BITS_AT(ch,i));
	  LOG("\tChunk referencing chunk %d at offset %d", ref_ch-&gc_minor_heap[0], i);
	  if ( !MARKED(ref_ch) )
	    mark_chunk(ref_ch);
        }
    }
}

void mark_minor(void* refs[], int count)
{
  int i;
  for(i=0; i<count; ++i)
    {
      if ( REF_PTR(refs[i]) )
        {
	  byte* ch = MINOR_CHUNK(refs[i]);
	  mark_chunk(ch);
        }
    }
}

void* find_chunk(int size)
{
  //  chunk_hdr_t* it;
  //  for(it = (chunk_hdr_t*)&gc_major_heap[0]; it->flags; it = 
}



void* major_alloc(int size)
{
  if ( size == 0 ) return 0;
  size = ALIGN(size) + sizeof(int);
  byte* cur;
  for(cur = &gc_major_heap[0];
      (CHUNK_FLAGS(cur) != GC_FLAG_FREE ||
       size > CHUNK_SIZE(cur)) &&
	cur < &gc_major_heap[GC_MAJOR_HEAP_SIZE];
      cur = cur + CHUNK_SIZE(cur))
    ;
  
  if ( cur >= &gc_major_heap[GC_MAJOR_HEAP_SIZE] )
    return 0;

  byte* free_chunk =  cur;
  unsigned int prev_size = CHUNK_SIZE(free_chunk);
  FLAGS(free_chunk) = size;
  MARK_CHUNK(free_chunk, GC_COL_WHITE);
  byte* next_chunk = (cur + size);
  FLAGS(next_chunk) = prev_size-size;
  return (void*)free_chunk;
}

void* minor_alloc(int size)
{
  if ( size == 0 ) return 0;
  //  assert(size != 0);
  size = ALIGN(size);

  if ( size > (GC_MINOR_CHUNK_SIZE - sizeof(int)) )
    return 0; //major_alloc(size);

  if ( gc_cur_min_chunk >= GC_MINOR_CHUNKS )
    {
      //collect_minor();
      //      return minor_alloc(size);
      return 0;
    }
  FLAGS(&gc_minor_heap[gc_cur_min_chunk*GC_MINOR_CHUNK_SIZE]) = size;
  return BITS(&gc_minor_heap[gc_cur_min_chunk++*GC_MINOR_CHUNK_SIZE]);
}

void* gc_alloc(int size)
{
  void* ptr = minor_alloc(size);
  if ( ptr == 0 ) return major_alloc(size);
  return ptr;
}

#define CHUNK_OFFSET(ch) ((((ch))-&gc_minor_heap[0])/GC_MINOR_CHUNK_SIZE)

void gc_print_major()
{
  printf("**List of major heap allocated chunks\n");
  int i;
  byte *cur;
  for(cur = &gc_major_heap[0];
      cur < &gc_major_heap[GC_MAJOR_HEAP_SIZE];
      cur = cur + CHUNK_SIZE(cur))
    {
      int fl = CHUNK_FLAGS(cur);
      char* ch_type = 0;
      switch(fl) {
      case GC_FLAG_FREE: ch_type = "free"; break;
      case GC_COL_WHITE: ch_type = "white"; break;
      case GC_COL_GREY:  ch_type = "grey"; break;
      case GC_COL_BLACK: ch_type = "black"; break;
      }
      printf("\tsize %.3d\tmarked %s\n", CHUNK_SIZE(cur), ch_type);
    }
  printf("**End of major chunks list\n");
}

void gc_print_minor()
{
  printf("**List of minor heap allocated %d chunks\n", gc_cur_min_chunk);
  int i;
  for(i=0; i < gc_cur_min_chunk; ++i)
    {
      byte *ch = &gc_minor_heap[i*GC_MINOR_CHUNK_SIZE];
      printf("\tchunk %.4d\tsize %.3d\tmarked %c\n", CHUNK_OFFSET(ch), CHUNK_SIZE(ch), (MARKED(ch) ? 'y' : 'n'));
    }
  printf("**End of minor chunks list\n");
}

void gc_reset()
{
  gc_cur_min_chunk = 0;
  FLAGS(&gc_major_heap[0]) = GC_MAJOR_HEAP_SIZE;
}


// Basic boundary check for allocation of different sizes of chunks 
BEGIN_TEST(01)
  assert(minor_alloc(0)==0);
  assert(minor_alloc(GC_MINOR_CHUNK_SIZE-sizeof(int))!=0);
  assert(minor_alloc(GC_MINOR_CHUNK_SIZE)==0);
  assert(minor_alloc(GC_MINOR_CHUNK_SIZE-sizeof(int)-2)!=0);
  assert(minor_alloc(GC_MINOR_CHUNK_SIZE-2*sizeof(int))!=0);
  assert(minor_alloc(1)!=0);
  assert(minor_alloc(3)!=0);
  assert(minor_alloc(4)!=0);
  assert(minor_alloc(5)!=0);
  gc_print_minor();
  gc_reset();
END_TEST()

// Basic collection test wihtout referencing elements 
BEGIN_TEST(02)
  unsigned int* ptr1 = minor_alloc(4);
  unsigned int* ptr2 = minor_alloc(4);
  unsigned int* ptr3 = minor_alloc(4);
  void* refs[] = { ptr1, ptr3 };
  mark_minor(refs, 2 );
  gc_print_minor();
  gc_reset();
END_TEST()

// Linked list test 
BEGIN_TEST(03)
  unsigned int* ptr1 = minor_alloc(4);
  unsigned int* ptr2 = minor_alloc(4);
  unsigned int* ptr3 = minor_alloc(4);
  void* refs[] = { ptr1 };
  *ptr1 = (unsigned int)ptr2;
  *ptr2 = (unsigned int)ptr3;
  mark_minor(refs, 1);
  gc_print_minor();
  gc_reset();
END_TEST()


// Circular list
BEGIN_TEST(04)
  unsigned int* ptr1 = minor_alloc(4);
  unsigned int* ptr2 = minor_alloc(4);
  unsigned int* ptr3 = minor_alloc(4);
  void* refs[] = { ptr1 };
  *ptr1 = (unsigned int)ptr2;
  *ptr2 = (unsigned int)ptr3;
  *ptr3 = (unsigned int)ptr1;
  mark_minor(refs, 1);
  gc_print_minor();
  gc_reset();
END_TEST()

// Various values stored in the chunk
BEGIN_TEST(05)
  unsigned int* ptr1 = minor_alloc(252);
  unsigned int* ptr2 = minor_alloc(252);
  unsigned int* ptr3 = minor_alloc(252);
  unsigned int* ptr4 = minor_alloc(252);
  void* refs[] = { ptr1 };
  ptr1[0] = (unsigned int)ptr2;
  ptr1[3] = 3;
  ptr1[4] = 5;
  ptr1[32] = (unsigned int)ptr3;
  ptr1[60] = -1;
  ptr1[61] = -3;
  ptr1[62] = (unsigned int)ptr4;
  mark_minor(refs, 1);
  gc_print_minor();
  gc_reset();
END_TEST()

// Test for exceeding allocation memory of first heap
BEGIN_TEST(06)
  int i;
  for(i=0; minor_alloc(4); i++);
  assert(i==GC_MINOR_CHUNKS);
END_TEST()

// Checking initial layout of elder heap
BEGIN_TEST(07)
gc_reset();
gc_print_major();
END_TEST()  

// checking allocation
BEGIN_TEST(08)
gc_reset();
assert(major_alloc(0)==0);
assert(major_alloc(GC_MAJOR_HEAP_SIZE - sizeof(unsigned int)) != 0);
gc_print_major();
assert(major_alloc(4) == 0);
gc_reset();
assert(major_alloc(GC_MAJOR_HEAP_SIZE - sizeof(unsigned int)+1) == 0);
assert(major_alloc(GC_MAJOR_HEAP_SIZE - 3*sizeof(unsigned int)) != 0);
assert(major_alloc(4)!= 0);
END_TEST()



int main()
{
  test_01();
   test_02();
  test_03();
  test_04();
  test_05();
  test_06();
  test_07();
  test_08();
  return 0;
}

  
