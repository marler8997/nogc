module pns.std;

import std.stdio : Exception;
import pns.refcount : refclass, refcount, RefException, RefObject;

version(unittest)
{
  import std.stdio : stdout, writeln, writefln;
}


struct File
{
  
}


extern(C) size_t tryOutlen(int handle, void* buffer, size_t length) nothrow @nogc;

class MemIORefException : RefException
{
  this(string msg) pure nothrow @nogc @safe
  {
    super(msg);
  }
}

void outlen(int handle, void* buffer, size_t len) @nogc
{
  auto result = tryOutlen(handle, buffer, len);
  if(result != len) {
    if(result == -1) {
      throw refclass!MemIORefException("out failed");
    } else {
      throw refclass!MemIORefException("out only wrote part of the buffer");
    }
  }
}

void outlim(int handle, void* ptr, void* lim) @nogc
{
  outlen(handle, ptr, lim - ptr);
}


void* ptr(T)(T t) if( is( T == class) )
{
  return cast(void*)t;
}

unittest
{
  
  try {
    throw refclass!RefException("did this work?");
  } catch(RefException e) {
    scope(exit) e.release();
    
    writefln("exception message: %s", e.msg);
  }

  
  writefln("end of block");
  stdout.flush();

  /*
  {
    auto o = refclass!Object();
    writefln("ptr = %s", o.ptr);
    writefln("object refcount is %s", (cast(void*)o).refcount);
  }
  {
    auto o = refclass!RefObject();
    writefln("ptr = %s", o.ptr);
    writefln("object refcount is %s", o.refcount);
    stdout.flush();
  }
  {
    auto o = new RefObject();
    writefln("ptr = %s", o.ptr);
    
  }
  */
}


enum ResultTag {ok, error}
struct Result(T,E) {
  ResultTag tag;
  union Payload {
    T value;
    E error;
  }
  Payload payload;
  //alias this payload; // magic sauce
  
  static Result Ok(T value) {
    Result result;
    result.tag = ResultTag.ok;
    result.payload.value = value;
    return result;
  }
  static Result Error(E error) {
    Result result;
    result.tag = ResultTag.error;
    result.payload.error = error;
    return result;
  }
}

unittest
{
  Result!(T,E) testResultOk(T,E)(T result) {
    return Result!(T,E).Ok(result);
  }
  Result!(T,E) testResultError(T,E)(E error) {
    return Result!(T,E).Error(error);
  }

  {
    auto result = testResultOk!(int,int)(0);
    assert(result.tag == ResultTag.ok);
    assert(result.payload.value == 0);
  }
  
}
