// fact.c - Exercise 16.10: read the compiler's version of a recursive function.
//     gcc -S -O0 -fno-asynchronous-unwind-tables -o - fact.c
//     gcc -S -O2 -fno-asynchronous-unwind-tables -o - fact.c

long fact(long n) {
    if (n <= 1)
        return 1;
    return n * fact(n - 1);
}
