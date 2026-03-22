#include <stdio.h>

extern "C" int callMyPrintf(const char* format, ...);

int main() {
    int count = callMyPrintf("Hello %c!\nHex: %x\nDec: %d\nOct: %o\nBin: %b\nStr: %s\n",
                         '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!");

    printf("myPrintf returned: %d\n", count);
    return 0;
}
