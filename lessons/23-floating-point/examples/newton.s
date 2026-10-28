// newton.s - square root by Newton's method, printing every step (lesson 23)
//
// Build: make newton
// Run:   ./newton
// Expected output:
//   step 1: x = 1.500000000000
//   step 2: x = 1.416666666667
//   step 3: x = 1.414215686275
//   step 4: x = 1.414213562375
//   step 5: x = 1.414213562373
//   step 6: x = 1.414213562373
//   newton: 1.414213562373
//   fsqrt:  1.414213562373

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    fmov d0, #2.0
    bl newton_sqrt              // d0 = newton_sqrt(2.0)
    adrp x0, f_newton
    add x0, x0, :lo12:f_newton
    bl printf

    fmov d0, #2.0
    fsqrt d0, d0                // the hardware answer, for comparison
    adrp x0, f_fsqrt
    add x0, x0, :lo12:f_fsqrt
    bl printf

    mov w0, #0
    ldp x29, x30, [sp], #16
    ret

// double newton_sqrt(double a)
//     double x = a;
//     do {
//         double next = (x + a / x) * 0.5;
//         diff = fabs(next - x);
//         x = next;
//         printf("step %ld: x = %.12f\n", ++step, x);
//     } while (diff >= 1e-12 && step < 50);
//     return x;
newton_sqrt:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp d8, d9, [sp, #16]       // a, x
    stp d10, d11, [sp, #32]     // tolerance, diff
    str x19, [sp, #48]          // step counter

    fmov d8, d0                 // d8 = a
    fmov d9, d0                 // d9 = x = a (first guess)
    adrp x0, tolerance
    ldr d10, [x0, :lo12:tolerance]  // d10 = 1e-12
    mov x19, #0                 // step = 0

newton_loop:
    fdiv d0, d8, d9             // a / x
    fadd d0, d0, d9             // x + a / x
    fmov d1, #0.5
    fmul d0, d0, d1             // next = (x + a / x) * 0.5
    fsub d1, d0, d9
    fabs d11, d1                // diff = fabs(next - x)
    fmov d9, d0                 // x = next

    add x19, x19, #1            // step++
    mov x1, x19                 // printf(f_step, step, x): x is in d0
    adrp x0, f_step
    add x0, x0, :lo12:f_step
    bl printf                   // may clobber d0-d7, but not d8-d15

    cmp x19, #50                // safety limit
    b.ge newton_done
    fcmp d11, d10               // diff < tolerance ?
    b.mi newton_done            //   yes: stop
    b newton_loop

newton_done:
    fmov d0, d9                 // return x
    ldr x19, [sp, #48]
    ldp d10, d11, [sp, #32]
    ldp d8, d9, [sp, #16]
    ldp x29, x30, [sp], #64
    ret

    .section .rodata
    .p2align 3
tolerance: .double 1e-12
f_step:    .asciz "step %ld: x = %.12f\n"
f_newton:  .asciz "newton: %.12f\n"
f_fsqrt:   .asciz "fsqrt:  %.12f\n"
