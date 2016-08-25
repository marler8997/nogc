module pns.io;

import pns.stdc.stdio    : printf, fprintf, fflush;
import pns.errorHandling : ErrorHandling, handleError, RefException;
import pns.refcount      : refclass, LineNumber;
import pns.format        : formattedWrite;

import core.stdc.stdio : FILE;
static import core.stdc.stdio;

__gshared File stdout;
__gshared File stderr;
__gshared File stdin;

shared static this()
{
  stdout.handle = core.stdc.stdio.stdout;
  stderr.handle = core.stdc.stdio.stderr;
  stdin.handle  = core.stdc.stdio.stdin;
}

class WriteException : Exception
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}
class WriteRefException : RefException
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}

struct BufferedWriter
{
  File file;
  char[] buffer;
  size_t contentLength;
  void put(const(char)[] str) pure nothrow @nogc
  {
    if(str.length + contentLength > buffer.length) {
      //throw refclass!RefException("this is not implemented, need to flush");
      assert(0, "writefln too large is not implemented");
    }
    buffer[contentLength..contentLength+str.length] = str;
    contentLength += str.length;
  }
  void flush(ErrorHandling errorHandling)() pure
  {
    if(contentLength > 0) {
      file.write!errorHandling(buffer[0..contentLength]);
    }
  }
}


struct File
{
  FILE* handle;
  void write(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message) @safe
  {
    auto written = fprintf(handle, "%.*s\0", message.length, message.ptr);
    if(written != message.length) {
      //debug writefln!errorHandling("only wrote %s out of %s bytes", written, message.length);
      handleError!(errorHandling, WriteException, WriteRefException)
        (__FILE__, __LINE__, "fprintf only wrote %s bytes out of %s", written, message.length);
    }
  }
  void writeln(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message)
  {
    auto written = fprintf(handle, "%.*s\r\n\0", message.length, message.ptr);
    if(written != message.length+2) {
      handleError!(errorHandling, WriteException, WriteRefException)
        (__FILE__, __LINE__, "printf only wrote %s bytes out of %s", written, message.length+2);
    }
  }
  void writefln(ErrorHandling errorHandling=ErrorHandling.throw_, T...)(const(char)[] fmt, T args) @nogc
  {
    char[1024] buffer;
    auto writer = BufferedWriter(this, buffer);
    formattedWrite!errorHandling(&writer.put, fmt, args);
    writer.put("\r\n");
    writer.flush!errorHandling();
  }
  void flush(ErrorHandling errorHandling)()
  {
    auto result = fflush(handle);
    if(result < 0) {
      handleError!(errorHandling, WriteException, WriteRefException)
        (__FILE__, __LINE__, "fflush returned %s", result);
    }
  }
}


void write(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message) @safe
{
  stdout.write!errorHandling(message);
}
void writeln(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message)
{
  stdout.writeln!errorHandling(message);
}
void writefln(ErrorHandling errorHandling=ErrorHandling.throw_, T...)(const(char)[] fmt, T args) @nogc
{
  stdout.writefln!errorHandling(fmt, args);
}

    /+
//
// The write functions
//
// nothrow and nogc should be implied in some cases
void write(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message) pure @safe
{
  auto written = printf("%.*s\0", message.length, message.ptr);
  if(written != message.length) {
    handleError!(errorHandling, WriteException, WriteRefException)
      (__FILE__, __LINE__, "printf only wrote %s bytes out of %s", written, message.length);
  }
}
void writeln(ErrorHandling errorHandling=ErrorHandling.throw_)(const(char)[] message) pure
{
  auto written = printf("%.*s\r\n\0", message.length, message.ptr);
  if(written != message.length+2) {
    handleError!(errorHandling, WriteException, WriteRefException)
      (__FILE__, __LINE__, "printf only wrote %s bytes out of %s", written, message.length+2);
  }
}
void writefln(ErrorHandling errorHandling=ErrorHandling.throw_, T...)(const(char)[] fmt, T args) pure @nogc
{
  char[1024] buffer;
  auto writer = BufferedWriter!true(buffer);
  formattedWrite!errorHandling(&writer.put, fmt, args);
  writer.put("\r\n");
  writer.flush!errorHandling();
}
+/

/*
unittest
{
  write("Hello, World!");
  writeln("Hello, World!");
  
  {
    void test1() @nogc
    {
      write!(ErrorHandling.throwRef)("Hello, World!");
      writeln!(ErrorHandling.throwRef)("Hello, World!");
    }
    test1();
  }
  {
    void test2() @nogc nothrow
    {
      write!(ErrorHandling.assert_)("Hello, World!");
      writeln!(ErrorHandling.assert_)("Hello, World!");
      write!(ErrorHandling.ignore)("Hello, World!");
      writeln!(ErrorHandling.ignore)("Hello, World!");
    }
    test2();
  }
}
*/

