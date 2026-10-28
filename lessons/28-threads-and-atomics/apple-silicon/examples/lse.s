// lse.s - ARMv8.1 "Large System Extension" atomics: one instruction does the
// whole atomic read-modify-write. Four threads count with ldadd, then main
// shows swp (atomic exchange) and cas (compare and swap) on one thread.
//
// The .arch line tells the assembler this CPU has ARMv8.1 instructions. Without
// it, gcc's assembler rejects ldadd ("selected processor does not support").
//
// Build: make lse            (no -pthread needed on macOS)
// Run:   ./lse
// Expected output, every time:
//     ldadd: counter = 4000000
//     swp 7: got old 4000000, counter = 7
//     cas 7->100: saw 7, counter = 100
//     cas 7->200: saw 100, counter = 100

    .arch armv8.1-a

    .equ NTHREADS, 4

    .text
    .global _main

// void *worker(void *arg): atomically add 1 to counter, one million times.
worker:
    adrp    x1, counter@PAGE
    add     x1, x1, counter@PAGEOFF
    movz    x2, #0x4240             // 1000000
    movk    x2, #0xf, lsl #16
    mov     x3, #1                  // the amount to add
worker_loop:
    ldadd   x3, x4, [x1]            // atomically: x4 = counter; counter += x3
    subs    x2, x2, #1
    b.ne    worker_loop
    mov     x0, #0
    ret

_main:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    adrp    x19, tids@PAGE
    add     x19, x19, tids@PAGEOFF

    mov     x20, #0
create_loop:
    add     x0, x19, x20, lsl #3
    mov     x1, #0
    adr     x2, worker
    mov     x3, #0
    bl      _pthread_create
    add     x20, x20, #1
    cmp     x20, #NTHREADS
    b.lo    create_loop

    mov     x20, #0
join_loop:
    ldr     x0, [x19, x20, lsl #3]
    mov     x1, #0
    bl      _pthread_join
    add     x20, x20, #1
    cmp     x20, #NTHREADS
    b.lo    join_loop

    adrp    x19, counter@PAGE
    add     x19, x19, counter@PAGEOFF // from here on x19 = &counter

    adrp    x0, fmt_add@PAGE
    add     x0, x0, fmt_add@PAGEOFF
    ldr     x1, [x19]
    sub     sp, sp, #16             // variadic arguments go on the stack
    str     x1, [sp]
    bl      _printf
    add     sp, sp, #16

    // swp: old = counter; counter = 7   (C: atomic_exchange)
    mov     x1, #7
    swp     x1, x20, [x19]          // store x1, old value into x20
    adrp    x0, fmt_swp@PAGE
    add     x0, x0, fmt_swp@PAGEOFF
    mov     x1, x20
    ldr     x2, [x19]
    sub     sp, sp, #16             // variadic arguments go on the stack
    stp     x1, x2, [sp]
    bl      _printf
    add     sp, sp, #16

    // cas: if (counter == 7) counter = 100. x20 is "expected" going in and
    // "what memory really held" coming out.
    mov     x20, #7                 // expected
    mov     x1, #100                // desired
    cas     x20, x1, [x19]
    adrp    x0, fmt_cas1@PAGE
    add     x0, x0, fmt_cas1@PAGEOFF
    mov     x1, x20
    ldr     x2, [x19]
    sub     sp, sp, #16             // variadic arguments go on the stack
    stp     x1, x2, [sp]
    bl      _printf
    add     sp, sp, #16

    // Same again: counter is 100 now, not 7, so nothing is stored.
    mov     x20, #7
    mov     x1, #200
    cas     x20, x1, [x19]
    adrp    x0, fmt_cas2@PAGE
    add     x0, x0, fmt_cas2@PAGEOFF
    mov     x1, x20
    ldr     x2, [x19]
    sub     sp, sp, #16             // variadic arguments go on the stack
    stp     x1, x2, [sp]
    bl      _printf
    add     sp, sp, #16

    mov     w0, #0
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

    .section __TEXT,__cstring
fmt_add:  .asciz "ldadd: counter = %ld\n"
fmt_swp:  .asciz "swp 7: got old %ld, counter = %ld\n"
fmt_cas1: .asciz "cas 7->100: saw %ld, counter = %ld\n"
fmt_cas2: .asciz "cas 7->200: saw %ld, counter = %ld\n"

    .bss
    .p2align 3
tids:    .space NTHREADS * 8
counter: .space 8
