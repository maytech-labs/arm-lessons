// leak.s - a deliberate bug: a memory leak (lesson 21, macOS)
//
// Each pass of the loop mallocs 100 bytes and overwrites the only pointer to
// the previous block, so 2 of the 3 blocks can never be freed.
//
// Build: make leak
// Run:   ./leak
// Expected output (a leak does not crash; it just wastes memory):
//   allocated 3 blocks, freed 1
//
// To see the leak, run it under Apple's leaks tool:
//   leaks --atExit -- ./leak
// It reports "2 leaks for 224 total leaked bytes" (malloc rounds each
// 100-byte block up to 112) and exits with status 1.

    .section __TEXT,__cstring
msg:
    .asciz "allocated 3 blocks, freed 1"

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]         // x19 = p, x20 = i

    mov  x19, #0
    mov  x20, #0
main_loop:                          // for (i = 0; i < 3; i++) p = malloc(100);
    cmp  x20, #3
    b.ge main_loop_done
    mov  x0, #100
    bl   _malloc
    mov  x19, x0                    // BUG: the old value of p is lost
    add  x20, x20, #1
    b    main_loop
main_loop_done:

    mov  x0, x19                    // free(p);   frees only the last block
    bl   _free

    adrp x0, msg@PAGE
    add  x0, x0, msg@PAGEOFF
    bl   _puts

    mov  w0, #0
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
