module pns.format;

import std.range         : ElementType;
import std.traits        : Unqual, isArray;
import pns.stdc.stdlib   : malloc;
import pns.errorHandling : ErrorHandling, RefException, LineNumber, handleError;
import pns.refcount      : refclass;
import pns.traits        : isSigned, isUnsigned, isIntegral;

class FormatException : Exception
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}
class FormatRefException : RefException
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}

pragma(inline)
char hexDigit(ubyte b) pure nothrow @nogc @safe
{
  return (b < 10) ? cast(char)('0' + b) : cast(char)('a'-10 + b);
}
unittest
{
  assert('0' == 0.hexDigit);
  assert('1' == 1.hexDigit);
  assert('8' == 8.hexDigit);
  assert('9' == 9.hexDigit);
  assert('a' == 10.hexDigit);
  assert('c' == 12.hexDigit);
  assert('f' == 15.hexDigit);
}

string enumValueString(T)(T value) pure nothrow @nogc @safe if( is(T == enum) )
{
  //return "<An Enum Value!>";
  return value.stringof;
}
/*
string (T)(T enumValue) if( is( T == enum ) )
{
  return "AnEnumValue!";
}
*/


//
// TODO: should I use sprintf, or my own custom
//       print functions?

pragma(inline)
void writeNumber(Writer,T)(Writer writer, T number) pure if(isIntegral!T && !is(Unqual!T == T))
{
  writeNumber!(Writer,Unqual!T)(writer, cast(Unqual!T)number);
}
void writeNumber(Writer,T)(Writer writer, T number) pure if(isIntegral!T && is(Unqual!T == T))
{
  char[maxDecimalDigits!T] buffer;

  if(number == 0) {
    writer("0");
  } else {
    static if(isSigned!T) {
      if(number < 0) {
        assert(0, "writeNumber, negative numbers not implemented");
      }
    }
    
    size_t bufferIndex = buffer.length-1;
    while(true) {
      buffer[bufferIndex] = cast(char)((number % 10) + '0');
      number /= 10;
      if(number == 0) {
        break;
      }
      assert(bufferIndex > 0, "writeNumber: number digits is exceeding the maxDecimalDigits count (there's a bug in maxDecimalDigits)");
      bufferIndex--;
    }
    writer(buffer[bufferIndex..$]);
  }
}


void writePointer(Writer)(Writer writer, const(void)* ptr) pure
{
  char[ptr.sizeof*2] str;
  foreach_reverse(i; 0..str.length) {
    str[i] = hexDigit(cast(ubyte)(cast(size_t)ptr%16));
    ptr = cast(void*)((cast(size_t)ptr) >> 4);
  }
  writer(str);
}
unittest
{
  char[256] buffer;
  size_t bufferOffset;
  
  void reset() pure
  {
    bufferOffset = 0;
  }
  void sink(const(char)[] s) pure
  {
    buffer[bufferOffset..bufferOffset+s.length] = s;
    bufferOffset += s.length;
  }


  // TODO: make tests work on systems with different bit widths (64bit, etc)
  reset();
  writePointer(&sink, null);
  assert("00000000" == buffer[0..bufferOffset]);

  reset();
  writePointer(&sink, cast(void*)1);
  assert("00000001" == buffer[0..bufferOffset]);
  
}
immutable(T)[] imalloc(T)(T[] a) pure nothrow @nogc @property @trusted
{
  T* ptr = cast(T*)malloc(a.length);
  assert(ptr, "out of memory at imalloc");
  ptr[0..a.length] = a;
  return cast(immutable(T)[])ptr[0..a.length];
}
string mallocFormat(ErrorHandling errorHandling, Args...)(in char[] fmt, Args args) pure @nogc
{
  return format!(errorHandling, imalloc,Args)(fmt, args);
}

struct StringBuilder
{
  char[] buffer;
  size_t contentOffset;
  void put(const(char)[] str) pure nothrow @nogc
  {
    if(str.length + contentOffset > buffer.length) {
      assert(0, "string too long for current implementation");
    }
    //printf("  StringBuilder.put: adding string '%.*s'\r\n", str.length, str.ptr);
    buffer[contentOffset..contentOffset+str.length] = str;
    contentOffset += str.length;
  }
}

template maxDecimalDigits(T)
{
  static if(isUnsigned!T) {
    static if( T.sizeof == 1 ) {
      enum maxDecimalDigits = 3; // 255
    } else static if( T.sizeof == 2 ) {
      enum maxDecimalDigits = 5; // 65535
    } else static if( T.sizeof == 4 ) {
      enum maxDecimalDigits = 10; // 4294967295
    } else static if( T.sizeof == 8 ) {
      enum maxDecimalDigits = 20; // 18446744073709551615
                                  //   |  |  |  |  |  |
    } else static assert("maxDecimalDigits sizeof not implemented: "~T.sizeof.stringof);
  } else {
    static if( T.sizeof == 1 ) {
      enum maxDecimalDigits = 4; // -128
    } else static if( T.sizeof == 2 ) {
      enum maxDecimalDigits = 6; // -32768
    } else static if( T.sizeof == 4 ) {
      enum maxDecimalDigits = 11; // -2147483648
    } else static if( T.sizeof == 8 ) {
      enum maxDecimalDigits = 20; // -9223372036854775807
                                  //   |  |  |  |  |  |
    } else static assert("maxDecimalDigits sizeof not implemented: "~T.sizeof.stringof);
  }
}

// D's std.format.format function is not pure, so I wrote my own
string format(ErrorHandling errorHandling = ErrorHandling.throw_, alias ToStringMethod=idup, Args...)(in char[] fmt, Args args) pure @safe
{
  char[1024] buffer = void;
  auto builder = StringBuilder(buffer);
  formattedWrite!(errorHandling)(&builder.put, fmt, args);
  return ToStringMethod(buffer[0..builder.contentOffset]);
}

void formattedWrite(ErrorHandling errorHandling = ErrorHandling.throw_, Writer, A...)
  (Writer writer, in const(char)[] fmt, A args) pure @trusted
{
  void appendArg(T)(char padding, size_t width, T arg) pure @nogc {

    static if( is( T == char[] ) ||
               is( T == string ) ||
               is( T == const(char)[] ) ) {
      writer(arg);
    } else static if( isArray!T ) {
      if(arg.length == 0) {
        writer("[]");
      } else {
        writer("[");
        appendArg!(ElementType!T)(arg[0]);
        foreach(item; arg[1..$]) {
          writer(", ");
          appendArg!(ElementType!T)(item);
        }
        writer("]");
      }
    } else static if( is( Unqual!T == char ) ) {
      writer((&arg)[0..1]);
    } else static if( is (T == dchar) ||
                      is (T == const(dchar)) ) {
      // TODO: implement dchar correctly
      writeNumber(writer, cast(uint)arg);
    } else static if( is( T == enum ) ) {
      writer(arg.enumValueString);
    } else static if( isIntegral!(Unqual!T) ) {
      writeNumber(writer, arg);
    } else static if( is( T == void*)        ||
                      is( T == const(void)*) ) {
      writePointer(writer, arg);
    } else static if( is( T == TypeInfo_Class) ) {
      writer(T.stringof);
    } else static if( __traits(compiles, arg.toString!errorHandling(writer) ) ) {
      arg.toString!errorHandling(writer);
    } else static if( __traits(compiles, arg.toString(writer) ) ) {
      arg.toString(writer);
      //} else static if( __traits(hasMember, arg, "toString") ) {
      //arg.toString(writer);
    } else static assert(0, "pns.format does not know how to print the type: "~T.stringof);
    
  }

  auto save = fmt.ptr;
  auto limit = save + fmt.length;
  {
    auto next = save;
    foreach(arg; args) {

      // find next '%' specifier
      while(true){
        if(next >= limit) {
          throw refclass!FormatRefException("too many args for format string");
        }
        auto c = *next;
        if(c == '%') {
          break;
        }
        next++;
      }

      if(next > save) {
        writer(save[0..next-save]);
      }
    
      next++;
      if(next >= limit) {
        throw refclass!FormatRefException("invalid format string: missing format specifier at end of string");
      }

      auto padding = ' ';
      if(*next == '0') {
        padding = '0';
        next++;
        if(next >= limit) {
          throw refclass!FormatRefException("invalid format string: missing incomplete format specifier at end of string");
        }
      }

      size_t width = 0;
      if(*next >= '1' && *next <= '9') {
        width = *next - '0';
        while(1) {
          next++;
          if(next >= limit) {
            throw refclass!FormatRefException("invalid format string: missing incomplete format specifier at end of string");
          }
          if(*next >= '0' && *next <= '9') {
            width *= 10;
            width += *next - '0';
          }
        }
      }
      
      if(*next != 's') {
        throw refclass!FormatRefException("formattedWrite has only implemented s format specifiers");
      }

      appendArg(padding, width, arg);
    
      next++;
      save = next;
    }
  }

  if(save < limit) {
    auto lastPart = save[0..limit-save];
    foreach(c; lastPart) {
      if(c == '%') {
        throw refclass!FormatRefException("not enough args for format string");
      }
    }
    writer(lastPart);
  }
}

