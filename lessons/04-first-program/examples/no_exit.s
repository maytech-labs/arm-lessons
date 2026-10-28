// no_exit.s - a broken program: it never calls exit.
//
// After the last mov, the CPU just fetches whatever bytes come next in memory.
// They are not instructions we wrote, so the program crashes.
//
// Build:  make
// Run:    ./no_exit; echo $?
// Exit status (echo $?): 132, after "Illegal instruction" (the exact crash
//                        can differ; any crash means the bug is there)

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #1                  // set up an exit status...
    mov x8, #93                 // ...and the system call number...
                                // ...but forget the svc
