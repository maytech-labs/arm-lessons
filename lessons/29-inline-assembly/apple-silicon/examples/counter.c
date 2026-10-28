// counter.c - read a system register: the virtual timer, at user level.
//
// cntvct_el0 counts at a fixed frequency (cntfrq_el0 ticks per second). There
// is no C way to read them, so this is a genuine use for inline asm.
//
// Build:  make
// Run:    ./counter
// Expected output (the frequency depends on the machine and OS; macOS on recent
// Apple chips reports 1 GHz, the Linux container 24 MHz):
//   timer frequency: 1000000000 Hz
//   the loop took more than 0 ticks: yes
#include <stdio.h>

static inline unsigned long ticks(void) {
    unsigned long t;
    asm volatile("isb\n\t"              // finish earlier instructions first
                 "mrs %0, cntvct_el0"   // mrs: move from system register
                 : "=r"(t));
    return t;
}

int main(void) {
    unsigned long freq;
    asm("mrs %0, cntfrq_el0" : "=r"(freq));
    unsigned long t0 = ticks();
    volatile long sink = 0;
    for (long i = 0; i < 1000000; i++) sink += i;
    unsigned long t1 = ticks();
    printf("timer frequency: %lu Hz\n", freq);
    printf("the loop took more than 0 ticks: %s\n", t1 > t0 ? "yes" : "no");
    return 0;
}
