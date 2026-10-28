// no_exit.s - a broken program: it never calls exit (macOS).
//
// After the last mov, the CPU just fetches whatever bytes come next in memory.
// They are not instructions we wrote, so the program crashes.
//
// Build:  make
// Run:    ./no_exit; echo $?
// Exit status (echo $?): 132, after "Illegal instruction" (the exact crash
//                        can differ; any crash means the bug is there)

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #1                  // set up an exit status...
    mov x16, #1                 // ...and the system call number...
                                // ...but forget the svc
