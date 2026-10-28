// ex5.s - Exercise 19.5: return a 16-byte struct in x0:x1 (with ex5_main.c) (macOS).
//
//   struct minmax { long min, max; };
//   struct minmax find_minmax(const long *a, long n);    // n >= 1
//
// Build:  make
// Run:    ./ex5
// Expected output:
//   min -7, max 42

    .global _find_minmax
    .text
    .p2align 2

_find_minmax:
    ldr x9, [x0], #8            // min = max = a[0]
    mov x10, x9
    subs x1, x1, #1
    b.eq find_minmax_done
find_minmax_loop:
    ldr x11, [x0], #8
    cmp x11, x9
    csel x9, x11, x9, lt
    cmp x11, x10
    csel x10, x11, x10, gt
    subs x1, x1, #1
    b.ne find_minmax_loop
find_minmax_done:
    mov x0, x9                  // result.min
    mov x1, x10                 // result.max
    ret
