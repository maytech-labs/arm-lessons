// const_write.s - a broken program: it writes into read-only data (macOS).
//
// C:      const char msg[] = "hello";
//         ((char *)msg)[0] = 'j';          // undefined behaviour: msg is const
//
// Build:  make
// Run:    ./const_write; echo $?
// Exit status (echo $?): 138, after "Bus error" (macOS reports a write to
//                        read-only memory as SIGBUS, signal 10)

    .global _main

    .section __TEXT,__const
msg:
    .asciz "hello"

    .text
    .p2align 2
_main:
    adrp x0, msg@PAGE
    add x0, x0, msg@PAGEOFF
    mov w1, #'j'
    strb w1, [x0]               // the page is mapped read-only: the CPU faults
    mov w0, #0
    ret
