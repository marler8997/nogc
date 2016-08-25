module pns.errorHandling;

import pns.refcount : refclass, releaseRefMem, LineNumber;
import pns.format    : format, mallocFormat;

version(unittest) {
  import pns.io : write, writeln, writefln;
}

enum ErrorHandling {
  throw_, throwRef, assert_, /*toStdout,*/ ignore
}

void handleError(ErrorHandling errorHandling, Exception, RefException, Args...)(string file, LineNumber lineNumber, Args args) pure
{
  static if(errorHandling == ErrorHandling.throw_) {
    throw new Exception(format!errorHandling(args), file, lineNumber);
   } else static if(errorHandling == ErrorHandling.throwRef) {
    throw refclass!RefException(mallocFormat!errorHandling(args), file, lineNumber);
  } else static if(errorHandling == ErrorHandling.assert_) {
    assert(0, mallocFormat!errorHandling(args));
  }
  // else, error is ignored
}

unittest
{
  try {
    handleError!(ErrorHandling.throw_, Exception, RefException)(__FILE__, __LINE__, "you threw an exception! (x=%s)", 3);
  } catch(Exception e) {
    assert(e.msg == "you threw an exception! (x=3)");
  }

  void testNoGc() @nogc
  {
    try {
      handleError!(ErrorHandling.throwRef, Exception, RefException)(__FILE__, __LINE__, "you threw an exception! (x=%s)", 3);
    } catch(RefException e) {
      assert(e.msg == "you threw an exception! (x=3)");
    }
  }
  testNoGc();
  void testNoThrowNoGc() nothrow @nogc
  {
    // Cannot test the assert, but, I can make sure that this will
    // compile with nothrow and @nogc by using the compiles trait.
    assert(__traits(compiles, handleError!(ErrorHandling.assert_, Exception, RefException)(__FILE__, __LINE__, "you threw an exception! (x=%s)", 3)));
    
    handleError!(ErrorHandling.ignore, Exception, RefException)(__FILE__, __LINE__, "you threw an exception! (x=%s)", 3);
  }
  testNoThrowNoGc();
}

// Note: this should never be allocated on the garbage collector
// heap, it should always be allocated on the nogc heap.
// Use: throw refclass!MyException(args...);
class RefException : Exception
{
  this(string msg, string file = __FILE__, LineNumber line = cast(LineNumber)__LINE__, Throwable next = null) pure nothrow @nogc @safe
  {
    super(msg, file, line, next);
  }
  final size_t refcount() const pure nothrow @nogc @trusted
  {
    return *((cast(size_t*)this) - 1);
  }
  final void release() const pure @nogc @trusted
  {
    //writeln("RefException.release called");
    releaseRefMem(cast(void*)this);
  }
}
