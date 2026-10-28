// double_free.s - a deliberate bug: freeing the same block twice (lesson 21, macOS)
//
// Build: make double_free
// Run:   ./double_free
// Expected output (macOS malloc notices the bug and kills the program):
//   freed once
// then the shell reports the crash (zsh: "trace trap ./double_free").
// Expected exit status: 133 (128 + 5: killed by signal 5, SIGTRAP).
// Some macOS versions print a "malloc: *** error for object ..." line first
// and abort instead: status 134 (SIGABRT).

    .section __TEXT,__cstring
msg:
    .asciz "freed once"

    .text
    .global _main
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]

    mov  x0, #32                    // p = malloc(32);
    bl   _malloc
    cbz  x0, main_fail
    mov  x19, x0

    mov  x0, x19                    // free(p);   correct
    bl   _free
    adrp x0, msg@PAGE
    add  x0, x0, msg@PAGEOFF
    bl   _puts
    mov  x0, #0                     // fflush(NULL): push the message out now,
    bl   _fflush                    // because a crash will not (see lesson 25)

    mov  x0, x19                    // free(p);   BUG: p no longer belongs to us
    bl   _free

    mov  w0, #0                     // never reached
main_done:
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
main_fail:
    mov  w0, #1
    b    main_done
