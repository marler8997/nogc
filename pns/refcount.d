module pns.refcount;

import pns.errorHandling : ErrorHandling, RefException;
import pns.stdc.stdlib : malloc,free;
import pns.io : writeln, writefln, stdout;


alias LineNumber = size_t;

// Note: the RefObject pointer is also
// the pointer in a RefMem struct
class RefObject : Object
{
  ~this() @nogc
  {
    stdout.writeln!(ErrorHandling.assert_)("~RefObject() called");
  }
  size_t refcount()
  {
    return *((cast(size_t*)this) - 1);
  }
  /*
  this(this)
  {
    writefln("this(this) called");
  }
  */
}

T refclass(T, Args...)(auto ref Args args) pure nothrow @nogc @trusted
{
  enum classSize = __traits(classInstanceSize, T);
  
  // allocate class
  auto ptr = malloc(size_t.sizeof + classSize);
  //writefln("refclass allocated at 0x%p", ptr);
  

  
  *(cast(size_t*)ptr) = 1; // ref count
  
  // Initialize the object in its pre-ctor state
  ptr = (cast(size_t*)ptr) + 1;
  ptr[0..classSize] = typeid(T).init[];

  // Call ctor if any
  static if (is(typeof((cast(T)ptr).__ctor(args)))) {
    // T defines a genuine constructor accepting args
    // Go the classic route: write .init first, then call ctor
    (cast(T)ptr).__ctor(args);
  } else static assert(args.length == 0 && !is(typeof(&T.__ctor)),
		       "Don't know how to initialize an object of type "
		       ~ T.stringof ~ " with arguments " ~ Args.stringof);
  
  return cast(T)ptr;
}

size_t refcount(void* ptr) pure nothrow @nogc
{
  return *((cast(size_t*)ptr) - 1);
}
void releaseRefMem(void* ptr) pure @nogc
{
  auto currentRefCount = ptr.refcount;
  if(currentRefCount == 0) {
    throw refclass!RefException("Error: release called but refcount is 0");
  } else {
    currentRefCount--;
    *((cast(size_t*)ptr) - 1) = currentRefCount;
    if(currentRefCount == 0) {
      //writeln("releaseMemRef called (refcount=0) calling free");
      free(ptr);
    } else {
      //writefln("releaseMemRef called (refcount=%d)\r\n", currentRefCount);
    }
  }
}




struct RefMem
{
  private void* ptr;
  private size_t length;

  @disable this();

  @property size_t refcount()
  {
    return *((cast(size_t*)ptr) - 1);
  }
  ~this() @nogc
  {
    //release();
    releaseRefMem(ptr);
  }
  /*
  void release() @nogc
  {
    auto currentRefCount = refcount;
    if(currentRefCount == 0) {
      writeln("Error: release called but refcount is 0");
    } else {
      *((cast(size_t*)ptr) - 1)--;
      writefln("release called (refcount=%d)\r\n", *((cast(size_t*)ptr) - 1));
    }
  }
  */
  static RefMem malloc2(size_t length) @nogc
  {
    auto ptr = malloc(size_t.sizeof + length);
    *(cast(size_t*)ptr) = 1; // ref count
    
    RefMem refmem = void;
    refmem.ptr = (cast(size_t*)ptr) + 1;
    refmem.length = length;
    return refmem;
  }
  
  private static T createClass(T, Args...)(auto ref Args args) @nogc
  {
    enum classSize = __traits(classInstanceSize, T);

    // allocate class
    auto refmem = RefMem.malloc2(classSize);

    // Initialize the object in its pre-ctor state
    refmem.ptr[0..classSize] = typeid(T).init[];

    // Call ctor if any
    static if (is(typeof((cast(T)refmem.ptr).__ctor(args)))) {
      // T defines a genuine constructor accepting args
      // Go the classic route: write .init first, then call ctor
      (cast(T)refmem.ptr).__ctor(args);
    } else static assert(args.length == 0 && !is(typeof(&T.__ctor)),
			 "Don't know how to initialize an object of type "
			 ~ T.stringof ~ " with arguments " ~ Args.stringof);
    
    return cast(T)refmem.ptr;
  }
}
