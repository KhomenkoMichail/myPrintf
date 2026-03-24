#include <stdio.h>

extern "C" int callMyPrintf(const char* format, ...);

int main() {
    int count = callMyPrintf("Hello %c!\nHex: %x\nDec:%k%k %d\nOct: %o\nBin: %b\nStr: %s\n%d %s %x %d%%%c%b\nFloat: %f\n",
                         '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!", -1, "love", 3802, 100, 33, 126, -123.123);

    printf("myPrintf  returned: %d\n", count);

    callMyPrintf("1d - %d\n1f - %f\n2 - %d\n2 - %f\n3 - %d\n3 - %f\n4 - %d\n4 - %f\n5 - %d\n5 - %f\n6 - %d\n6 - %f\n7 - %d\n7 - %f\n8 - %d\n8 - %f\n9 - %d\n9 - %f\n10 - %d\n10 - %f\n11 - %d\n11 - %f\n12 - %d\n12 - %f\n13 - %d\n13 - %f\n",
                 1, 1.1, 2, -2.22, 3, 3.333, 4, -4.4444, 5, 5.55555, 6, -6.666666, 7,
                 7.7777777, 8, -8.88888888, 9, 9.99, -10, 10.10, 11, 11.11, 12, -12.1212, 13, 13.131313);

    callMyPrintf("\n\n\n");

    callMyPrintf("%b\n", printf("Pobeda\n"));

    printf("%f\n", -0.555555555555555555555555555555555);
    return 0;
}
