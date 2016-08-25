module pns.stdc.stdlib;


extern(C)
{
  void* malloc(size_t size) pure nothrow @nogc;
  void* calloc(size_t size) pure nothrow @nogc;
  void* realloc(size_t size) pure nothrow @nogc;
  void free(void* ptr) pure nothrow @nogc;
  char* alloca(size_t size) pure nothrow @nogc;
}
