#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "test.h"
// Let's assume constant size of younger heap chunks
#define GC_MINOR_CHUNK_SIZE 256
#define GC_MINOR_HEAP_SIZE (1024*64)
#define GC_MAJOR_HEAP_SIZE (1024*1024*32)
// Let's assume that every data structure is pointer size aligned
#define GC_MINOR_CHUNKS (GC_MINOR_HEAP_SIZE/GC_MINOR_CHUNK_SIZE)
#define GC_MAX_REF_COUNT 65536
// We need to sacrifice first 4 bytes flag/size
// let's first bit to be set if chunk has been marked during collection
// initialy 0

#define WITH_HEADER(size) ((size) + sizeof(int))
#define WITHOUT_HEADER(size) ((size) - sizeof(int))
#define PTR_INDEX(ofs) ((ofs)/sizeof(void*))
#define BYTE_INDEX(ofs) ((ofs)*sizeof(void*))

#define GC_MINOR_RAW_CHUNK_SIZE (WITHOUT_HEADER((GC_MINOR_CHUNK_SIZE)))

#define GC_MINOR_BITS_SIZE (WITHOUT_HEADER(GC_MINOR_CHUNK_SIZE))
#define GC_FLAG_FREE 0
#define GC_COL_WHITE 1
#define GC_COL_GREY 2
#define GC_COL_BLACK 3
#define GC_MARKED 1

#define WITH_HEADER(size) ((size) + sizeof(int))
#define CHUNK_AT(i) (&gc_minor_heap[(i)*GC_MINOR_CHUNK_SIZE])
#define BITS(ch) (WITH_HEADER(ch))
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
#define POINTS_MAJOR(ptr) (((byte*)(ptr)) >= &gc_major_heap[0] && ((byte*)(ptr)) < &gc_major_heap[GC_MAJOR_HEAP_SIZE])
// Calculate address of begining of chunk
#define MINOR_CHUNK(ptr) (((((byte*)(ptr) - &gc_minor_heap[0])/GC_MINOR_CHUNK_SIZE)*GC_MINOR_CHUNK_SIZE)+&gc_minor_heap[0])
// Find if the chunk points to another chunk
#define REF_PTR(ptr) (MEM_TAG((ptr)) && POINTS_MINOR((ptr)))
// Is it marked?
#define MARKED(ch) (FLAGS(ch) & 1)
#define CHUNK_OFFSET(ch) ((((ch))-&gc_minor_heap[0])/GC_MINOR_CHUNK_SIZE)

#define FOR_EACH_MINCH(ch)  for(i=0; i < gc_cur_min_chunk; ++i) { \
  byte *ch = CHUNK_AT(i); do { } while(0)
#define END_FOR_EACH() }

/*
typedef struct
{
  int count;
  void *ptr;
} gc_ref_t;
*/

void* gc_ref_tab[GC_MAX_REF_COUNT];
int gc_ref_count = 0;

// need to be aligned!
typedef char byte;
//typedef unsigned int hdr;
//typedef byte chunk[sizeof(hdr)+GC_MINOR_BITS_SIZE];

// Our first generation heap
byte gc_minor_heap[GC_MINOR_HEAP_SIZE];
// Elder generation heap
byte gc_major_heap[GC_MAJOR_HEAP_SIZE];
// Points to free chunk
int gc_cur_min_chunk = 0;
void* gc_backpatch_table[GC_MINOR_CHUNKS];

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
  for(i=0; i < PTR_INDEX(CHUNK_SIZE(ch)); ++i)
    {
      if ( REF_PTR(BITS_AT(ch,i)) )
        {
	  byte* ptr = BITS_AT(ch,i);
	  byte* ref_ch = MINOR_CHUNK(ptr);
	  int idx = (ch-&gc_minor_heap[0]);
	  //	  gc_backpatch_table[PTR_INDEX(idx)][0] = (void*)ptr;
	  if ( !MARKED(ref_ch) )
	    mark_chunk(ref_ch);
        }
    }
}

void mark_minor(void* refs[], int count)
{
  memset(gc_backpatch_table, 0, sizeof(gc_backpatch_table));
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


void* major_alloc(int size)
{
  if ( size == 0 ) return 0;
  size = WITH_HEADER(ALIGN(size));
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

void backpatch_chunk(byte* ch)
{
  int i;
  for(i=0; i < PTR_INDEX(CHUNK_SIZE(ch)); ++i)
    {
      if ( REF_PTR(BITS_AT(ch,i)) )
        {
	  byte* ptr = BITS_AT(ch,i);
	  byte* ref_ch = MINOR_CHUNK(ptr);
	  if ( MARKED(ref_ch) )
	    {
	      byte* new_ptr = (byte*)gc_backpatch_table[CHUNK_OFFSET(ref_ch)];
	      assert(new_ptr != 0);
	      unsigned int delta = new_ptr-ref_ch;
	      *ptr += delta;
	    }
        }
    }
}

void copy_minor_heap()
{
  int i;
  FOR_EACH_MINCH(ch);
  {
    if ( MARKED(ch) )
      {
	void* ptr = major_alloc(WITHOUT_HEADER(CHUNK_SIZE(ch)));
	assert( ptr != 0 );
	gc_backpatch_table[i] = ptr;
      }
  }
  END_FOR_EACH();
		 
  FOR_EACH_MINCH(ch);
  {
    backpatch_chunk(ch);
  }
  END_FOR_EACH();
  
  FOR_EACH_MINCH(ch);
  {
    if ( MARKED(ch) )
      {
	byte* new_ptr = (byte*)gc_backpatch_table[i];
	assert(new_ptr != 0);
	memcpy(new_ptr, ch, CHUNK_SIZE(ch));
      }
    }
  END_FOR_EACH();
}

void collect_minor()
{
  copy_minor_heap();
}

void* minor_alloc(int size)
{
  if ( size == 0 ) return 0;
  //  assert(size != 0);
  size = ALIGN(size);

  if ( size > (WITHOUT_HEADER(GC_MINOR_CHUNK_SIZE)) )
    return 0; //major_alloc(size);

  if ( gc_cur_min_chunk >= GC_MINOR_CHUNKS )
    {
      //      collect_minor();
      //      return minor_alloc(size);
      return 0;
    }
  FLAGS(CHUNK_AT(gc_cur_min_chunk)) = size;
  return BITS(CHUNK_AT(gc_cur_min_chunk++));
}



/*
void* gc_alloc(int size)
{
  void* ptr = minor_alloc(size);
  if ( ptr == 0 ) return major_alloc(size);
  return ptr;
}
*/


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
      switch(fl) 
	{
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
  FOR_EACH_MINCH(ch);
  {
    printf("\tchunk %.4d\tsize %.3d\tmarked %c\n", CHUNK_OFFSET(ch), CHUNK_SIZE(ch), (MARKED(ch) ? 'y' : 'n'));
  }
  END_FOR_EACH();
  printf("**End of minor chunks list\n");
}

void gc_reset()
{
  gc_cur_min_chunk = 0;
  FLAGS(&gc_major_heap[0]) = GC_MAJOR_HEAP_SIZE;
  memset(gc_backpatch_table, 0, sizeof(gc_backpatch_table));
  gc_ref_count = 0;
}

void gc_add_ref(void* ref)
{
  if ( !POINTS_MINOR(ref) && !POINTS_MAJOR(ref) ) return;
  int i;
  for(i=0; i < gc_ref_count; ++i)
    if ( gc_ref_tab[i] == ref ) return;
  
  for(i=0; i < gc_ref_count; ++i)
    if ( gc_ref_tab[i] == 0 ) 
      {
	gc_ref_tab[i] = ref;
	return;
      }
  assert(gc_ref_count < GC_MAX_REF_COUNT);
  gc_ref_tab[gc_ref_count++] = ref;
  return;
}

void gc_remove_ref(void* ref)
{
  if ( !POINTS_MINOR(ref) && !POINTS_MAJOR(ref) ) return;
  int i;
  for(i=0; i < gc_ref_count-1; ++i)
      if ( gc_ref_tab[i] == ref ) { gc_ref_tab[i] = 0; return; }

  if ( gc_ref_tab[gc_ref_count-1] == ref ) gc_ref_count--;

}

void gc_print_refs()
{
  int i;
  printf("**List of stored references. %d references.\n", gc_ref_count);
  for(i=0; i < gc_ref_count; ++i)
    {
      if ( gc_ref_tab[i] != 0 )
	{
	  char* points_to = "??";
	  void* heap = 0;
	  if ( POINTS_MINOR(gc_ref_tab[i]) ) { points_to = "minor"; heap = gc_minor_heap;}
	  if ( POINTS_MAJOR(gc_ref_tab[i]) ) {points_to = "major";heap = gc_major_heap;}
	  printf("\tReference at offset %.8x(%s)\t->\t%p\n", gc_ref_tab[i] - heap, points_to, *((void**)gc_ref_tab[i]));
	}
      else
	printf("\tEmpty slot\n");
    }
  printf("**End of stored ref list\n");
}

/*
void gc_print_backpatch()
{
  printf("**Printing backpatch table.\n");
  int i;
  for(i=0; i<PTR_INDEX(GC_MINOR_HEAP_SIZE); ++i)
    {
      byte* ptr = (byte*)gc_backpatch_table[i][0];
      if ( ptr != 0 )
	{
	  int mem_offset = BYTE_INDEX(i);
	  int first_index = mem_offset/GC_MINOR_CHUNK_SIZE;
	  int first_offset = PTR_INDEX(mem_offset % GC_MINOR_CHUNK_SIZE);
	  int second_index = CHUNK_OFFSET(ptr);
	  int second_offset = PTR_INDEX((WITHOUT_HEADER((byte*)ptr - &gc_minor_heap[0])%GC_MINOR_CHUNK_SIZE));
	  printf("\tminor chunk %d at %d -> %d at %d\n", first_index, first_offset, second_index, second_offset);
	}
    }
  printf("**End of backpatch table.\n");
}
*/

// Basic boundary check for allocation of different sizes of chunks 
BEGIN_TEST(01)
assert(minor_alloc(0)==0);
assert(minor_alloc(GC_MINOR_RAW_CHUNK_SIZE)!=0);
assert(minor_alloc(GC_MINOR_CHUNK_SIZE)==0);
assert(minor_alloc(GC_MINOR_RAW_CHUNK_SIZE-2)!=0);
assert(minor_alloc(GC_MINOR_RAW_CHUNK_SIZE-sizeof(int))!=0);
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

// Checking allocation on major heap
BEGIN_TEST(08)
gc_reset();
assert(major_alloc(0)==0);
assert(major_alloc(WITHOUT_HEADER(GC_MAJOR_HEAP_SIZE)) != 0);
gc_print_major();
assert(major_alloc(4) == 0);
gc_reset();
assert(major_alloc(WITHOUT_HEADER(GC_MAJOR_HEAP_SIZE)+1) == 0);
assert(major_alloc(WITHOUT_HEADER(GC_MAJOR_HEAP_SIZE) - 2*sizeof(unsigned int)) != 0);
assert(major_alloc(4)!= 0);
gc_print_major();
END_TEST()



// Refs test
BEGIN_TEST(09)
// Initial empty ref table
gc_print_refs();
// Adding invalid reference, shouldnt alter the table
gc_add_ref(0);
gc_print_refs();

// adding one reference from minor heap
gc_add_ref(&gc_minor_heap[0]);
gc_print_refs();

// lets assign a value so printing will yield result
*((void**)&gc_minor_heap[0]) = (void*)0x123456;
// invalid minor pointer
gc_add_ref(&gc_minor_heap[GC_MINOR_HEAP_SIZE]);
// last pointer on minor heap
gc_add_ref(&gc_minor_heap[GC_MINOR_HEAP_SIZE-sizeof(int)]);
// invalid major heap pointer
gc_add_ref(&gc_major_heap[GC_MAJOR_HEAP_SIZE]);
// last pointer on major heap
gc_add_ref(&gc_major_heap[GC_MAJOR_HEAP_SIZE-sizeof(int)]);
gc_print_refs();
// remove last pointer
gc_remove_ref(&gc_major_heap[GC_MAJOR_HEAP_SIZE-sizeof(int)]);
// replace with minor heap ref (which is already, does nothing)
gc_add_ref(&gc_minor_heap[GC_MINOR_HEAP_SIZE-sizeof(int)]);
gc_print_refs();
// add pointer at the end
gc_add_ref(&gc_minor_heap[GC_MINOR_HEAP_SIZE-sizeof(int)-sizeof(int)]);
gc_print_refs();
// remove last pointer
gc_remove_ref(&gc_minor_heap[GC_MINOR_HEAP_SIZE-sizeof(int)-sizeof(int)]);
gc_print_refs();
gc_remove_ref(&gc_minor_heap[0]);
gc_print_refs();
gc_add_ref(&gc_minor_heap[0]);
gc_print_refs();
END_TEST()

// Test for backpatch table
BEGIN_TEST(10)
gc_reset();
unsigned int* ptr1 = minor_alloc(60);
unsigned int* ptr2 = minor_alloc(60);
unsigned int* ptr3 = minor_alloc(60);
unsigned int* ptr4 = minor_alloc(60);
unsigned int* ptr5 = minor_alloc(60);
void* refs[] = { ptr1 };
ptr1[3] = (unsigned int)ptr2;
ptr2[4] = (unsigned int)ptr3;
ptr3[5] = (unsigned int)ptr4;
ptr4[6] = (unsigned int)ptr5;
ptr5[7] = (unsigned int)ptr1;
mark_minor(refs, 1);
copy_minor_heap();
gc_print_minor();
gc_print_major();
//gc_print_backpatch();
gc_reset();
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
  test_09();
  test_10();
  return 0;
}

  
