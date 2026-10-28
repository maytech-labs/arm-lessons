// students.s - an array of structs: find the best score and print the name.
//
// C:      struct student { char name[16]; int age; int score; };   // 24 bytes
//         struct student class[4] = {...};
//         struct student *best = &class[0];
//         for (long i = 1; i < 4; i++)
//             if (class[i].score > best->score) best = &class[i];
//         printf("best: %s, age %d, score %d\n", best->name, best->age, best->score);
//
// Build:  make
// Run:    ./students
// Expected output:
//   best: Grace, age 85, score 97

    .global main

    .equ STUDENT_NAME, 0
    .equ STUDENT_AGE, 16
    .equ STUDENT_SCORE, 20
    .equ STUDENT_SIZE, 24
    .equ COUNT, 4

    .data
    .p2align 2
class:
    .ascii "Ada\0\0\0\0\0\0\0\0\0\0\0\0\0"     // name: exactly 16 bytes
    .word 36, 91                                // age, score
    .ascii "Grace\0\0\0\0\0\0\0\0\0\0\0"
    .word 85, 97
    .ascii "Alan\0\0\0\0\0\0\0\0\0\0\0\0"
    .word 41, 88
    .ascii "Linus\0\0\0\0\0\0\0\0\0\0\0"
    .word 21, 79

    .section .rodata
fmt:    .asciz "best: %s, age %d, score %d\n"

    .text
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x9, class
    add x9, x9, :lo12:class     // x9 = &class[0]
    mov x10, x9                 // best = &class[0]
    mov x11, #1                 // i = 1
    mov x12, #STUDENT_SIZE
loop:
    cmp x11, #COUNT
    b.ge done
    madd x13, x11, x12, x9      // &class[i] = class + i * sizeof(struct student)
    ldr w14, [x13, #STUDENT_SCORE]
    ldr w15, [x10, #STUDENT_SCORE]
    cmp w14, w15
    csel x10, x13, x10, gt      // if (class[i].score > best->score) best = &class[i]
    add x11, x11, #1
    b loop
done:
    add x1, x10, #STUDENT_NAME  // best->name: the address of the array member
    ldr w2, [x10, #STUDENT_AGE]
    ldr w3, [x10, #STUDENT_SCORE]
    adrp x0, fmt
    add x0, x0, :lo12:fmt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret
