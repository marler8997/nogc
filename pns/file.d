module pns.file;

import pns.errorHandling : ErrorHandling, handleError, RefException, LineNumber;

extern(C) char* alloca(ulong size) nothrow @nogc pure;

extern(Windows) uint GetLastError() nothrow @nogc pure;
extern(Windows) uint GetFileAttributesA(const(char)* filename) pure;

import core.sys.windows.winbase : INVALID_FILE_ATTRIBUTES, FILE_ATTRIBUTE_DIRECTORY, FILE_ATTRIBUTE_NORMAL;


class FileException : Exception
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}
class FileRefException : RefException
{
  this(string msg, string file = __FILE__, LineNumber lineNumber = cast(LineNumber)__LINE__,
       Throwable next = null) pure nothrow @nogc @safe {
    super(msg, file, lineNumber, next);
  }
}



bool exists(const(char)[] filename) pure
{
  auto cFilename = alloca(filename.length + 1);
  assert(cFilename);
  cFilename[0..filename.length] = filename;
  cFilename[filename.length] = 0;
  /*
  debug {
    import std.stdio;
    writefln("Checking for file '%s'", filename);
    stdout.flush();
  }
  */
  return GetFileAttributesA(cFilename) != INVALID_FILE_ATTRIBUTES;
}

import core.sys.windows.winbase : HANDLE, SECURITY_ATTRIBUTES, LPOVERLAPPED;
extern(Windows) HANDLE CreateFileA(const(char)*, uint, uint, SECURITY_ATTRIBUTES*, uint, uint, void*) nothrow @nogc pure;
extern(Windows) uint GetFileSize(HANDLE, uint* fileSizeHigh) nothrow @nogc pure;
extern(Windows) bool CloseHandle(HANDLE) nothrow @nogc pure;
extern(Windows) bool ReadFile(HANDLE, void* buffer, uint bytesToRead, uint* bytesRead, LPOVERLAPPED) nothrow @nogc pure;

import core.sys.windows.winbase :
  INVALID_HANDLE_VALUE, GENERIC_READ, FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING,
  INVALID_FILE_SIZE;
char[] read(ErrorHandling errorHandling = ErrorHandling.throw_)(const(char)[] filename) pure
{
  auto cFilename = alloca(filename.length + 1);
  assert(cFilename);
  cFilename[0..filename.length] = filename;
  cFilename[filename.length] = 0;

  auto fileHandle = CreateFileA(cFilename,
                                GENERIC_READ,
                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                null,
                                OPEN_EXISTING,
                                0, null);
  if(fileHandle == INVALID_HANDLE_VALUE) {
    handleError!(errorHandling, FileException, FileRefException)(__FILE__, __LINE__, "file '%s' does not exist", filename);
    return null;
  }
  scope(exit) { CloseHandle(fileHandle); }

  uint fileSizeHigh;
  uint fileSize = GetFileSize(fileHandle, &fileSizeHigh);
  if(fileSize == INVALID_FILE_SIZE) {
    handleError!(errorHandling, FileException, FileRefException)(__FILE__, __LINE__, "Windows GetFileSize function failed (error=%s)", GetLastError());
    return null;
  }
  if(fileSizeHigh != 0) {
    handleError!(errorHandling, FileException, FileRefException)(__FILE__, __LINE__, "Windows GetFileSize fileSizeHigh is non-zero, this is not implemented");
    return null;
  }
  char[] contents = new char[fileSize];

  uint totalRead = 0;
  while(true) {
    uint lastRead;
    if(!ReadFile(fileHandle, contents.ptr + totalRead, contents.length - totalRead, &lastRead, null)) {
      handleError!(errorHandling, FileException, FileRefException)(__FILE__, __LINE__, "Windows ReadFile (%s bytes) failed (error=%s)", contents.length-totalRead, GetLastError());
    }
    if(lastRead == 0) {
      handleError!(errorHandling, FileException, FileRefException)(__FILE__, __LINE__, "Windows ReadFile returned success, but read 0 bytes out of %s (error=%s)", contents.length-totalRead, GetLastError());
    }
    totalRead += lastRead;
    if(totalRead >= contents.length) {
      break;
    }
  }
  return contents;
}
