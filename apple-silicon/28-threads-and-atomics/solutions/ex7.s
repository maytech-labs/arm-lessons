// ex7.s - Exercise 28.7: a lock-free stack (a "Treiber stack"), push only.
// Four threads each malloc 1000 nodes and push them onto one shared list
// with a compare-and-swap loop. Afterwards main walks the list, counts the
// nodes, adds up their values, and frees them.
//
//     struct node { struct node *next; long value; };    // 16 bytes
//     thread t pushes values t*1000 + 0 .. t*1000 + 999
//
// Build: make ex7
// Run:   ./ex7               (run it several times)
// Expected output, every time:
//     nodes = 4000, sum = 7998000

    .arch armv8.1-a

    .equ NTHREADS, 4
    .equ PER_THREAD, 1000
    .equ N_NEXT, 0
    .equ N_VALUE, 8
    .equ N_SIZE, 16

    .text
    .global _main

// void push(struct node **head, struct node *n)
//     old = *head;
//     do { n->next = old; } while (!CAS(head, &old, n));
push:
    ldr     x2, [x0]                // old = *head (a guess; CAS checks it)
push_retry:
    str     x2, [x1, #N_NEXT]       // n->next = old
    mov     x3, x2                  // cas overwrites its first register
    casl    x3, x1, [x0]            // if (*head == x3) *head = n;  x3 = what *head was
                                    // (release: n->next and n->value are visible first)
    cmp     x3, x2
    b.eq    push_done               // *head was still old: we are on the list
    mov     x2, x3                  // someone pushed first: retry with the new head
    b       push_retry
push_done:
    ret

// void *worker(void *arg): arg = thread number t
worker:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    mov     x9, #PER_THREAD
    mul     x19, x0, x9             // value = t * 1000
    add     x20, x19, #PER_THREAD   // stop = value + 1000
    adrp    x21, head@PAGE
    add     x21, x21, head@PAGEOFF
w_loop:
    mov     x0, #N_SIZE
    bl      _malloc                  // malloc is thread-safe
    mov     x22, x0
    str     x19, [x22, #N_VALUE]
    mov     x0, x21
    mov     x1, x22
    bl      push
    add     x19, x19, #1
    cmp     x19, x20
    b.lo    w_loop
    mov     x0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

_main:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    adrp    x19, tids@PAGE
    add     x19, x19, tids@PAGEOFF

    mov     x20, #0
create_loop:
    add     x0, x19, x20, lsl #3
    mov     x1, #0
    adr     x2, worker
    mov     x3, x20                 // arg = (void *)t
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

    // Walk the list: count, sum, free.
    adrp    x19, head@PAGE
    ldr     x19, [x19, head@PAGEOFF]  // n = head
    mov     x20, #0                 // count
    mov     x21, #0                 // sum
walk:
    cbz     x19, walk_done
    add     x20, x20, #1
    ldr     x9, [x19, #N_VALUE]
    add     x21, x21, x9
    ldr     x22, [x19, #N_NEXT]     // remember next before freeing n
    mov     x0, x19
    bl      _free
    mov     x19, x22
    b       walk
walk_done:
    adrp    x0, fmt@PAGE
    add     x0, x0, fmt@PAGEOFF
    mov     x1, x20
    mov     x2, x21
    sub     sp, sp, #16             // variadic arguments go on the stack
    stp     x1, x2, [sp]
    bl      _printf
    add     sp, sp, #16

    mov     w0, #0
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

    .section __TEXT,__cstring
fmt:    .asciz "nodes = %ld, sum = %ld\n"

    .bss
    .p2align 3
tids:   .space NTHREADS * 8
head:   .space 8                    // struct node *head = NULL;
