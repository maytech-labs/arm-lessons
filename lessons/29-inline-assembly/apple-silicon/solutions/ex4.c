// ex4.c - Exercise 29.4: time a function with the virtual counter.
//
// Build:  make
// Run:    ./ex4
// Expected output (the times vary):
//   sum_to(10000000) = 50000005000000
//   took N ticks = M microseconds
//   ok
#include <stdio.h>

static inline unsigned long ticks(void) {
    unsigned long t;
    asm volatile("isb\n\tmrs %0, cntvct_el0" : "=r"(t) :: "memory");
    return t;
}

static unsigned long freq(void) {
    unsigned long f;
    asm("mrs %0, cntfrq_el0" : "=r"(f));
    return f;
}

__attribute__((noinline)) static unsigned long sum_to(unsigned long n) {
    volatile unsigned long s = 0;           // volatile: the loop really runs
    for (unsigned long i = 1; i <= n; i++) s += i;
    return s;
}

int main(void) {
    unsigned long t0 = ticks();
    unsigned long s = sum_to(10000000);
    unsigned long t1 = ticks();
    unsigned long dt = t1 - t0;
    printf("sum_to(10000000) = %lu\n", s);
    printf("took %lu ticks = %lu microseconds\n", dt, dt * 1000000 / freq());
    puts(dt > 0 ? "ok" : "timer did not advance?");
    return 0;
}
