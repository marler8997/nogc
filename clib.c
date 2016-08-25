#include <fcntl.h>

// TODO: define properly
#define MAX_SIZE 0xFFFFFFFF





// Returns number of characters written
// On error: returns -1 on error
size_t tryOutlen(int handle, void* buffer, size_t length)
{
  return write(handle, buffer, length);
}
