#include <stdio.h>
#include <math.h>

extern "C" int printHardDouble(char* bufferPtr, unsigned long long sign,
                               unsigned long long mantissa, unsigned long long exp)
{
    double value = 0.0;
    const int bias = 1023;

    if (exp == 0) {
        value = (double)mantissa * ldexp(1.0, 1 - bias - 52);
    } else {
        mantissa |= (1ULL << 52);
        value = (double)mantissa * ldexp(1.0, (exp - bias) - 52);
    }

    if (sign) value = -value;

    return sprintf(bufferPtr, "%f", value);
}
