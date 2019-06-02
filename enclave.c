#include <string.h>
#include "enclave_t.h"

static const char str[] = "hello, enclave";

void hello(char *dest, size_t n)
{
    strncpy(dest, str, n);
    dest[n - 1] = '\0';
}
