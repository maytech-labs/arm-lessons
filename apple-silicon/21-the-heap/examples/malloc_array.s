// malloc_array.s - malloc an array of 5 longs, fill it, print it, free it (lesson 21, macOS)
//
// Build: make malloc_array
// Run:   ./malloc_array
// Expected output:
//   a[0] = 0
//   a[1] = 1
//   a[2] = 4
//   a[3] = 9
//   a[4] = 16

    .equ COUNT, 5
    .equ LONG_SIZE, 8               // sizeof(long)

    .section __TEXT,__cstring
fmt:
    .asciz "a[%ld] = %ld\n"

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = a, x20 = i

    // long *a = malloc(COUNT * sizeof(long));
    mov  x0, #(COUNT * LONG_SIZE)   // the assembler does this multiply: 40
    bl   _malloc
    cbz  x0, main_fail              // if (a == NULL) return 1;
    mov  x19, x0

    // for (i = 0; i < COUNT; i++) a[i] = i * i;
    mov  x20, #0
main_fill:
    cmp  x20, #COUNT
    b.ge main_fill_done
    mul  x1, x20, x20
    str  x1, [x19, x20, lsl #3]     // a[i]: address a + i*8
    add  x20, x20, #1
    b    main_fill
main_fill_done:

    // for (i = 0; i < COUNT; i++) printf("a[%ld] = %ld\n", i, a[i]);
    mov  x20, #0
main_print:
    cmp  x20, #COUNT
    b.ge main_print_done
    adrp x0, fmt@PAGE
    add  x0, x0, fmt@PAGEOFF
    mov  x1, x20
    ldr  x2, [x19, x20, lsl #3]
    sub  sp, sp, #16                // variadic args go on the stack (Apple)
    str  x1, [sp]
    str  x2, [sp, #8]
    bl   _printf
    add  sp, sp, #16
    add  x20, x20, #1
    b    main_print
main_print_done:

    // free(a);
    mov  x0, x19
    bl   _free

    mov  w0, #0
main_done:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
