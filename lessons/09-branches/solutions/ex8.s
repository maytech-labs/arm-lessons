// ex8.s - Exercise 09.8: classify a triangle from its three sides.
//
// C:      long a = 3, b = 4, c = 5, k;
//         if (a + b <= c || a + c <= b || b + c <= a) k = 0;   // not a triangle
//         else if (a == b && b == c)                  k = 1;   // equilateral
//         else if (a == b || b == c || a == c)        k = 2;   // isosceles
//         else                                        k = 3;   // scalene
//         return k;
// Build:  make
// Run:    ./ex8; echo $?
// Expect: exit status 3. Try 2,2,2 (1), 5,5,8 (2), 1,2,3 (0).

    .global _start              // make _start visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_start:
    mov x1, #3                  // a
    mov x2, #4                  // b
    mov x3, #5                  // c

    // not a triangle if any one of the three tests is true (||)
    add x4, x1, x2              // a + b
    cmp x4, x3                  // a + b <= c ?
    b.le not_triangle           //   yes: the || is true
    add x4, x1, x3              // a + c
    cmp x4, x2                  // a + c <= b ?
    b.le not_triangle           //   yes
    add x4, x2, x3              // b + c
    cmp x4, x1                  // b + c <= a ?
    b.le not_triangle           //   yes

    // equilateral if both are true (&&)
    cmp x1, x2                  // a == b ?
    b.ne try_isosceles          //   no: the && is false
    cmp x2, x3                  // b == c ?
    b.ne try_isosceles          //   no
    mov x0, #1                  // equilateral
    b done                      // finished

try_isosceles:
    cmp x1, x2                  // a == b ?
    b.eq isosceles              //   yes: the || is true
    cmp x2, x3                  // b == c ?
    b.eq isosceles              //   yes
    cmp x1, x3                  // a == c ?
    b.eq isosceles              //   yes
    mov x0, #3                  // none equal: scalene
    b done                      // finished
isosceles:
    mov x0, #2                  // isosceles
    b done                      // finished
not_triangle:
    mov x0, #0                  // not a triangle
done:
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(k)
