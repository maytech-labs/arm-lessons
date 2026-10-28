// const_write.s - a broken program: it writes into read-only data.
//
// C:      const char msg[] = "hello";
//         ((char *)msg)[0] = 'j';          // undefined behaviour: msg is const
//
// Build:  make
// Run:    ./const_write; echo $?
// Exit status (echo $?): 139, after "Segmentation fault"

    .global main

    .section .rodata
msg:
    .asciz "hello"

    .text
    .p2align 2
main:
    adrp x0, msg
    add x0, x0, :lo12:msg
    mov w1, #'j'
    strb w1, [x0]               // the page is mapped read-only: the CPU faults
    mov w0, #0
    ret
