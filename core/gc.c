#include <assert.h>
#include <stdio.h>

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
// Mark chunk with least significant bit set to 1
#define MARK_CHUNK(ch) (ch)->flags |= 1;
// Extract chunk size from flag/size field
#define CHUNK_SIZE(ch) ((ch)->flags & (~1))
// Align by 4 bytes boundary (TODO: make it more portable)
#define ALIGN(ptr) (((ptr)+3)&~3)
// if it's not marked
#define MEM_TAG(ptr) (!(((unsigned int)(ptr))&1))
// If the pointer is pointing the first generation heap
#define POINTS_MINOR(ptr) ((ptr) >= (void*)&gc_minor_heap[0] && (ptr) < (void*)&gc_minor_heap[GC_MINOR_CHUNK_SIZE])
// Calculate address of begining of chunk
#define MINOR_CHUNK(ptr) (&gc_minor_heap[((((char*)(ptr)) - (char*)&gc_minor_heap[0])/GC_MINOR_CHUNK_SIZE)])
// Find if the chunk points to another chunk
#define REF_PTR(ptr) (MEM_TAG((ptr)) && POINTS_MINOR((ptr)))
// Is it marked?
#define MARKED(ch) ((ch)->flags & 1)
//#define MJ_CHUNK_SIZE(ch) ((ch)->flags& (3<<
// The chunk structure
typedef struct {
  unsigned int flags; 
  void* bits[GC_MINOR_BITS_SIZE];
} minor_chunk_t;

// Major chunk header
typedef struct {
  unsigned int flags;
} chunk_hdr_t;

// need to be aligned!
typedef char byte;

// Our first generation heap
minor_chunk_t gc_minor_heap[GC_MINOR_CHUNKS];
// Elder generation heap
byte gc_major_heap[GC_MAJOR_HEAP_SIZE];
// Points to free chunk
int gc_cur_min_chunk = 0;
// Some logging/debugging facilities
//#define LOGGING
#ifdef LOGGING
#define LOG(...) do {printf("gc_log: ");printf( __VA_ARGS__ );printf("\n");} while(0)
#else
#define LOG(...)
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marks ref
void mark_chunk(minor_chunk_t* ch)
{
  MARK_CHUNK(ch);
  LOG("Starting marking chunk: %d", ch-&gc_minor_heap[0]);
  int i;
  for(i=0; i < CHUNK_SIZE(ch)/sizeof(void*); ++i)
    {
      if ( REF_PTR(ch->bits[i]) ) 
        {
	  minor_chunk_t* ref_ch = MINOR_CHUNK(ch->bits[i]);
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
	  minor_chunk_t* ch = MINOR_CHUNK(refs[i]);
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
  return 0;
}

void* minor_alloc(int size)
{
  if ( size == 0 ) return 0;
  //  assert(size != 0);
  size = ALIGN(size);

  if ( size > (GC_MINOR_CHUNK_SIZE - sizeof(int)) )
    return major_alloc(size);

  if ( gc_cur_min_chunk >= GC_MINOR_CHUNKS )
    {
      //collect_minor();
      //      return minor_alloc(size);
      return 0;
    }
  gc_minor_heap[gc_cur_min_chunk].flags = size;
  return gc_minor_heap[gc_cur_min_chunk++].bits;
}

#define CHUNK_OFFSET(ch) (((minor_chunk_t*)(ch))-&gc_minor_heap[0])
void gc_print_minor()
{
  printf("**List of minor heap allocated %d chunks\n", gc_cur_min_chunk);
  int i;
  for(i=0; i < gc_cur_min_chunk; ++i)
    {
      minor_chunk_t *ch = &gc_minor_heap[i];
      printf("\tchunk %.4d\tsize %.3d\tmarked %c\n", CHUNK_OFFSET(ch), CHUNK_SIZE(ch), (MARKED(ch) ? 'y' : 'n'));
    }
  printf("**End of chunks list\n");
}

void gc_reset()
{
  gc_cur_min_chunk = 0;
}

void gc_test_01()
{
  printf("Running test 01\n");
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
  printf("Test 01 completed\n");
}

void gc_test_02()
{
 printf("Running test 02\n");
 unsigned int* ptr1 = minor_alloc(4);
 unsigned int* ptr2 = minor_alloc(4);
 unsigned int* ptr3 = minor_alloc(4);
 void* refs[] = { ptr1, ptr3 };
 mark_minor(refs, 3 );
 gc_print_minor();
 printf("Test 02 completed\n");
}


int main()
{
  gc_test_01();
  gc_test_02();
}

