#include <stdio.h>

extern "C" int callMyPrintf(const char* format, ...);

int main() {
    int count = callMyPrintf("Hello %c!\nHex: %x\nDec:%k%k %d\nOct: %o\nBin: %b\nStr: %s\n%d %s %x %d%%%c%b\nFloat: %f/n",
                         '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!", -1, "love", 3802, 100, 33, 126, 123.123);

    printf("myPrintf  returned: %d\n", count);
    return 0;
}
