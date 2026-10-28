// bench_main.c - times sum_squares_asm (bench.s) against the same loop in C.
//
// Build: make            (clang -O2, linked with bench.s)
// Run:   ./bench
// See bench.s for the expected output. The sums must match; the times vary.
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N    1000000
#define REPS 200

long sum_squares_asm(const int *a, long n);

// noinline stops the compiler from merging this into main and
// computing the answer once instead of REPS times.
__attribute__((noinline))
long sum_squares_c(const int *a, long n) {
    long s = 0;
    for (long i = 0; i < n; i++)
        s += (long)a[i] * a[i];
    return s;
}

static double seconds(clock_t start) {
    return (double)(clock() - start) / CLOCKS_PER_SEC;
}

int main(void) {
    int *a = malloc(N * sizeof *a);
    if (a == NULL)
        return 1;
    for (long i = 0; i < N; i++)
        a[i] = (int)(i % 1000);

    // volatile: the compiler must really read n before every call, and
    // really store every result, so it cannot skip or merge the calls.
    volatile long n = N;
    volatile long sink;
    clock_t start;

    start = clock();
    for (int r = 0; r < REPS; r++)
        sink = sum_squares_asm(a, n);
    printf("asm:     sum = %ld   time = %.3f s\n", (long)sink, seconds(start));

    start = clock();
    for (int r = 0; r < REPS; r++)
        sink = sum_squares_c(a, n);
    printf("C -O2:   sum = %ld   time = %.3f s\n", (long)sink, seconds(start));

    free(a);
    return 0;
}
