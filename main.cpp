#include <stdio.h>
#include <math.h>

extern "C" int callMyPrintf(const char* format, ...);

int main() {

    int count = callMyPrintf("Hello %c!\nHex: %x\nDec:%k%k %d\nOct: %o\nBin: %b\nStr: %s\n%d %s %x %d%%%c%b\nFloat: %f\n",
                         '!', 0xDEADBEEF, -123, 777, 255, "Ura Ura Ura!", -1, "love", 3802, 100, 33, 126, -123.123);


    callMyPrintf("1d - %d\n1f - %f\n2 - %d\n2 - %f\n3 - %d\n3 - %f\n4 - %d\n4 - %f\n5 - %d\n5 - %f\n6 - %d\n6 - %f\n7 - %d\n7 - %f\n8 - %d\n8 - %f\n9 - %d\n9 - %f\n10 - %d\n10 - %f\n11 - %d\n11 - %f\n12 - %d\n12 - %f\n13 - %d\n13 - %f\n",
                 1, 1.1, 2, -2.22, 3, 3.333, 4, -4.4444, 5, 5.55555, 6, -6.666666, 7,
                 7.7777777, 8, -8.88888888, 9, 9.99, -10, 10.10, 11, 11.11, 12, -12.1212, 13, 13.131313);

    callMyPrintf("%b\n", printf("Pobeda\n"));

    double a = 0.0;
    double b = 1.0;
    double c = -123456789.0;
    double d = 9007199254740992.0;
    double e = -9007199254740992.0;
    double f = 123456789012345.0;
    double g = 0.5;
    double h = -0.75;
    double k = 123.456789;
    double l = 0.000001;
    double m = 1000000.0000001;
    double n = -98765.4321;
    double o = 1.7976931348623157e+308;
    double p = -1.7976931348623157e+308;
    double q = 2.225073858507201e-308;
    double r = INFINITY;
    double s = -INFINITY;
    double t = NAN;
    double u = 1.234567890123456e200;
    double v = -1.234567890123456e-200;
    double w = 0.1 + 0.2;
    double x = 1.0 / 3.0;
    double y = 12345678901234567890.123456;
    double z = -9876543210987654321.987654;

    callMyPrintf("a = %f\n", a);
    callMyPrintf("b = %f\n", b);
    callMyPrintf("c = %f\n", c);
    callMyPrintf("d = %f\n", d);
    callMyPrintf("e = %f\n", e);
    callMyPrintf("f = %f\n", f);
    callMyPrintf("g = %f\n", g);
    callMyPrintf("h = %f\n", h);
    callMyPrintf("k = %f\n", k);
    callMyPrintf("l = %f\n", l);
    callMyPrintf("m = %f\n", m);
    callMyPrintf("n = %f\n", n);
    callMyPrintf("o = %f\n", o);
    callMyPrintf("p = %f\n", p);
    callMyPrintf("q = %f\n", q);
    callMyPrintf("r = %f\n", r);
    callMyPrintf("s = %f\n", s);
    callMyPrintf("t = %f\n", t);
    callMyPrintf("u = %f\n", u);
    callMyPrintf("v = %f\n", v);
    callMyPrintf("w = %f\n", w);
    callMyPrintf("x = %f\n", x);
    callMyPrintf("y = %f\n", y);
    callMyPrintf("z = %f\n", z);

    return 0;
}
