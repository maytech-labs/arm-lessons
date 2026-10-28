// ex4.s - Exercise 28.4: parallel sum of 1..4000000 with four threads.
// Each thread gets a struct work { long start; long end; } (end exclusive),
// sums its range into a local register, then adds that partial sum to the
// shared global total with ONE atomic instruction (ldadd).
//
// Build: make ex4
// Run:   ./ex4
// Expected output, every time:
//     total = 8000002000000

    .arch armv8.1-a

    .equ NTHREADS, 4
    .equ W_START, 0
    .equ W_END,   8
    .equ W_SIZE,  16

    .text
    .global _main

// void *partial(void *arg)
partial:
    ldr     x1, [x0, #W_START]      // i
    ldr     x2, [x0, #W_END]        // end
    mov     x3, #0                  // local sum: no other thread can see it
part_loop:
    cmp     x1, x2
    b.ge    part_done
    add     x3, x3, x1
    add     x1, x1, #1
    b       part_loop
part_done:
    adrp    x4, total@PAGE
    add     x4, x4, total@PAGEOFF
    ldadd   x3, xzr, [x4]           // total += sum, atomically (old value discarded)
    mov     x0, #0
    ret

_main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]
    adrp    x19, work@PAGE
    add     x19, x19, work@PAGEOFF
    adrp    x20, tids@PAGE
    add     x20, x20, tids@PAGEOFF
    movz    x9, #0x4240             // chunk = 1000000
    movk    x9, #0xf, lsl #16

    mov     x21, #0
create_loop:
    add     x3, x19, x21, lsl #4    // &work[i]  (16-byte structs)
    mul     x10, x21, x9            // i * chunk
    add     x11, x10, #1
    str     x11, [x3, #W_START]     // start = i*chunk + 1
    add     x11, x11, x9
    str     x11, [x3, #W_END]       // end = start + chunk
    add     x0, x20, x21, lsl #3
    mov     x1, #0
    adr     x2, partial
    bl      _pthread_create
    movz    x9, #0x4240             // x9 is caller-saved: reload it
    movk    x9, #0xf, lsl #16
    add     x21, x21, #1
    cmp     x21, #NTHREADS
    b.lo    create_loop

    mov     x21, #0
join_loop:
    ldr     x0, [x20, x21, lsl #3]
    mov     x1, #0
    bl      _pthread_join
    add     x21, x21, #1
    cmp     x21, #NTHREADS
    b.lo    join_loop

    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    adrp    x1, total@PAGE
    ldr     x1, [x1, total@PAGEOFF]
    sub     sp, sp, #16             // variadic arguments go on the stack
    str     x1, [sp]
    bl      _printf
    add     sp, sp, #16

    mov     w0, #0
    ldr     x21, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
fmt:    .asciz "total = %ld\n"

    .bss
    .p2align 3
tids:   .space NTHREADS * 8
work:   .space NTHREADS * W_SIZE
total:  .space 8
