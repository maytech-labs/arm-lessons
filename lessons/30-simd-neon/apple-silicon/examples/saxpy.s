// saxpy.s - y = a*x + y on float arrays, four floats per instruction (macOS).
//
// C:      float x[8] = {1..8}, y[8] = {100, ..., 800};  float a = 2.5;
//         for (i = 0; i < 8; i++) y[i] = a * x[i] + y[i];
//
// The results are converted to int for printing (lesson 23 covers printing
// doubles; this keeps the example about vectors).
//
// Build:  make
// Run:    ./saxpy
// Expected output:
//   102 205 307 410 512 615 717 820

    .global _main

    .data
    .p2align 4
x:  .float 1, 2, 3, 4, 5, 6, 7, 8
y:  .float 100, 200, 300, 400, 500, 600, 700, 800
    .equ N, 8                   // elements in each array
alpha:
    .float 2.5

    .section __TEXT,__const
num:    .asciz "%d"
sep:    .asciz " "
nl:     .asciz "\n"

    .text
    .p2align 2
_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]

    adrp x9, x@PAGE
    add x9, x9, x@PAGEOFF
    adrp x10, y@PAGE
    add x10, x10, y@PAGEOFF
    adrp x11, alpha@PAGE
    add x11, x11, alpha@PAGEOFF
    ldr s2, [x11]               // a, in lane 0 of v2
    mov x12, #N
1:  ld1 {v0.4s}, [x9], #16      // 4 x values
    ld1 {v1.4s}, [x10]          // 4 y values
    fmla v1.4s, v0.4s, v2.s[0]  // y += x * a   (a: lane 0 of v2, used for every lane)
    st1 {v1.4s}, [x10], #16     // store 4 results
    subs x12, x12, #4           // N is a multiple of 4 here: no tail needed
    b.ne 1b

    adrp x19, y@PAGE            // print the results as ints
    add x19, x19, y@PAGEOFF
    mov x20, #0
2:  ldr s0, [x19, x20, lsl #2]
    fcvtzs w1, s0               // (int)y[i]
    adrp x0, num@PAGE
    add x0, x0, num@PAGEOFF
    sub sp, sp, #16             // macOS: variadic arguments go on the stack
    str x1, [sp, #0]
    bl _printf
    add sp, sp, #16
    add x20, x20, #1
    cmp x20, #N
    b.eq 3f
    adrp x0, sep@PAGE
    add x0, x0, sep@PAGEOFF
    bl _printf
    b 2b
3:  adrp x0, nl@PAGE
    add x0, x0, nl@PAGEOFF
    bl _printf

    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
