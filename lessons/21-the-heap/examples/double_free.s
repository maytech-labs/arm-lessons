// double_free.s - a deliberate bug: freeing the same block twice (lesson 21)
//
// Build: make double_free
// Run:   ./double_free
// Expected output (glibc notices the bug and kills the program):
//   freed once
//   free(): double free detected in tcache 2
// then the shell reports the abort (bash says "Aborted (core dumped)").
// Expected exit status: 134 (128 + 6: killed by signal 6, SIGABRT)

    .section .rodata
msg:
    .asciz "freed once"

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov  x0, #32                    // p = malloc(32);
    bl   malloc
    cbz  x0, main_fail
    mov  x19, x0

    mov  x0, x19                    // free(p);   correct
    bl   free
    adrp x0, msg
    add  x0, x0, :lo12:msg
    bl   puts
    mov  x0, #0                     // fflush(NULL): push the message out now,
    bl   fflush                     // because abort() will not (see lesson 25)

    mov  x0, x19                    // free(p);   BUG: p no longer belongs to us
    bl   free

    mov  w0, #0                     // never reached
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
