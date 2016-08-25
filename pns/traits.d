module pns.traits;

import std.traits : Unqual;

template isSigned(T)
{
  static if(is(Unqual!T == byte) ||
            is(Unqual!T == short) ||
            is(Unqual!T == int) ||
            is(Unqual!T == long) ||
            is(Unqual!T == ptrdiff_t)) {
    enum isSigned = true;
  } else static if(is(Unqual!T == ubyte) ||
                   is(Unqual!T == ushort) ||
                   is(Unqual!T == uint) ||
                   is(Unqual!T == ulong) ||
                   is(Unqual!T == size_t)) {
    enum isSigned = false;
  } else static assert(0, "cannot call isSigned on type: "~Unqual!T.stringof);
}
template isUnsigned(T)
{
  static if(is(Unqual!T == ubyte) ||
            is(Unqual!T == ushort) ||
            is(Unqual!T == uint) ||
            is(Unqual!T == ulong) ||
            is(Unqual!T == size_t)) {
    enum isUnsigned = true;
  } else static if(is(Unqual!T == byte) ||
                   is(Unqual!T == short) ||
                   is(Unqual!T == int) ||
                   is(Unqual!T == long) ||
                   is(Unqual!T == ptrdiff_t)) {
    enum isUnsigned = false;
  } else static assert(0, "cannot call isUnsigned on type: "~T.stringof);
}
template isIntegral(T)
{
  enum isIntegral =
    // signed
    is(Unqual!T == byte) ||
    is(Unqual!T == short) ||
    is(Unqual!T == int) ||
    is(Unqual!T == long) ||
    is(Unqual!T == ptrdiff_t) ||
    // unsigned
    is(Unqual!T == ubyte) ||
    is(Unqual!T == ushort) ||
    is(Unqual!T == uint) ||
    is(Unqual!T == ulong) ||
    is(Unqual!T == size_t);
}
