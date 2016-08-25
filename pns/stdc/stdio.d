module pns.stdc.stdio;

import core.stdc.stdio : FILE;

extern(C) ptrdiff_t fflush(FILE* stream) nothrow @nogc @trusted;

//extern(C) ptrdiff_t fputs(const(char)* str, FILE* stream);
extern(C) ptrdiff_t fprintf(FILE* stream, const(char)* fmt, ...) nothrow @nogc @trusted;
extern(C) ptrdiff_t printf(const(char)* fmt, ...) nothrow @nogc @trusted;

