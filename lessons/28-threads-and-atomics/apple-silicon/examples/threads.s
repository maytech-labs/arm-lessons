// threads.s - start four threads, give each one a struct describing its
// share of the work, wait for them all, then print what each one computed.
//
// Each thread sums a range of numbers: thread 0 sums 1..250, thread 1 sums
// 251..500, and so on. The threads share nothing except their own struct, so
// there is no race and the output is always the same.
//
// Build: make threads        (no -pthread needed on macOS)
// Run:   ./threads
// Expected output:
//     thread 0: sum of 1..250 = 31375
//     thread 1: sum of 251..500 = 93875
//     thread 2: sum of 501..750 = 156375
//     thread 3: sum of 751..1000 = 218875
//     total = 500500

    .equ NTHREADS, 4
    .equ CHUNK, 250

// struct work { long start; long end; long result; };   // end is exclusive
    .equ W_START,  0
    .equ W_END,    8
    .equ W_RESULT, 16
    .equ W_SIZE,   24

    .text
    .global _main

// void *sum_range(void *arg)
// arg points to a struct work. Sum start..end-1 into result. Return NULL.
// A leaf function: it calls nothing, so it needs no frame.
sum_range:
    ldr     x1, [x0, #W_START]      // i = w->start
    ldr     x2, [x0, #W_END]        // end = w->end
    mov     x3, #0                  // sum = 0
sum_loop:
    cmp     x1, x2
    b.ge    sum_done                // while (i < end)
    add     x3, x3, x1              //     sum += i
    add     x1, x1, #1              //     i++
    b       sum_loop
sum_done:
    str     x3, [x0, #W_RESULT]     // w->result = sum
    mov     x0, #0                  // return NULL
    ret

_main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    adrp    x19, work@PAGE
    add     x19, x19, work@PAGEOFF    // x19 = &work[0]
    adrp    x20, tids@PAGE
    add     x20, x20, tids@PAGEOFF    // x20 = &tids[0]

    // for (i = 0; i < NTHREADS; i++) { fill work[i]; pthread_create(...); }
    mov     x21, #0
create_loop:
    mov     x9, #W_SIZE
    madd    x3, x21, x9, x19        // x3 = &work[i]   (4th argument)
    mov     x9, #CHUNK
    mul     x10, x21, x9            // i * 250
    add     x11, x10, #1
    str     x11, [x3, #W_START]     // start = i*250 + 1
    add     x11, x10, #(CHUNK + 1)
    str     x11, [x3, #W_END]       // end   = i*250 + 251
    str     xzr, [x3, #W_RESULT]    // result = 0
    add     x0, x20, x21, lsl #3    // &tids[i]
    mov     x1, #0                  // attr = NULL (defaults)
    adr     x2, sum_range           // the function the thread runs
    bl      _pthread_create          // pthread_create(&tids[i], NULL, sum_range, &work[i])
    add     x21, x21, #1
    cmp     x21, #NTHREADS
    b.lo    create_loop

    // for (i = 0; i < NTHREADS; i++) pthread_join(tids[i], NULL);
    mov     x21, #0
join_loop:
    ldr     x0, [x20, x21, lsl #3]  // tids[i] (a value, not an address)
    mov     x1, #0                  // we do not want the return value
    bl      _pthread_join
    add     x21, x21, #1
    cmp     x21, #NTHREADS
    b.lo    join_loop

    // Every thread has finished, so reading the results is safe now.
    mov     x21, #0                 // i
    mov     x22, #0                 // total
print_loop:
    mov     x9, #W_SIZE
    madd    x9, x21, x9, x19        // &work[i]
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    mov     x1, x21                 // i
    ldr     x2, [x9, #W_START]
    ldr     x3, [x9, #W_END]
    sub     x3, x3, #1              // print the last number included
    ldr     x4, [x9, #W_RESULT]
    add     x22, x22, x4            // total += result
    sub     sp, sp, #32             // variadic arguments go on the stack
    stp     x1, x2, [sp]
    stp     x3, x4, [sp, #16]
    bl      _printf
    add     sp, sp, #32
    add     x21, x21, #1
    cmp     x21, #NTHREADS
    b.lo    print_loop

    adrp    x0, totalfmt@PAGE
    add     x0, x0, totalfmt@PAGEOFF
    mov     x1, x22
    sub     sp, sp, #16             // variadic arguments go on the stack
    str     x1, [sp]
    bl      _printf
    add     sp, sp, #16

    mov     w0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
fmt:      .asciz "thread %ld: sum of %ld..%ld = %ld\n"
totalfmt: .asciz "total = %ld\n"

    .bss
    .p2align 3
tids:   .space NTHREADS * 8         // pthread_t tids[4];  (8 bytes each)
work:   .space NTHREADS * W_SIZE    // struct work work[4];
