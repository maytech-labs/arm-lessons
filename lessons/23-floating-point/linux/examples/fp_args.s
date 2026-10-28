// fp_args.s - functions that take and return doubles (lesson 23)
//
// Build: make fp_args
// Run:   ./fp_args
// Expected output:
//   average3(1, 2, 4.5) = 2.500000
//   scale(3, 1.250000) = 3.750000
//   sum_squares({1.5, 2, 3}, 3) = 15.250000
//   total = 6.250000

    .text
    .global main
    .p2align 2
main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str d8, [sp, #16]           // we keep a double in d8 across calls

    // double avg = average3(1.0, 2.0, 4.5);
    fmov d0, #1.0               // 1st double argument
    fmov d1, #2.0               // 2nd
    fmov d2, #4.5               // 3rd
    bl average3                 // result in d0
    fmov d8, d0                 // keep it: printf may overwrite d0-d7
    adrp x0, fmt_avg
    add x0, x0, :lo12:fmt_avg
    bl printf                   // printf(fmt_avg, avg): avg still in d0

    // double s = scale(3, 1.25);
    mov x0, #3                  // 1st integer argument -> x0
    fmov d0, #1.25              // 1st double argument  -> d0
    bl scale
    fadd d8, d8, d0             // total = avg + s
    fmov d1, d0                 // printf(fmt_scale, 3, 1.25, s):
    fmov d0, #1.25              //   integers count x1, x2...; doubles d0, d1...
    mov x1, #3
    adrp x0, fmt_scale
    add x0, x0, :lo12:fmt_scale
    bl printf

    // sum_squares(values, 3)
    adrp x0, values
    add x0, x0, :lo12:values    // pointer argument -> x0
    mov x1, #3                  // count -> x1
    bl sum_squares
    adrp x0, fmt_sq
    add x0, x0, :lo12:fmt_sq
    bl printf

    fmov d0, d8                 // printf("total = %f\n", total)
    adrp x0, fmt_total
    add x0, x0, :lo12:fmt_total
    bl printf

    mov w0, #0
    ldr d8, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// double average3(double a, double b, double c)   (leaf: no frame needed)
average3:
    fadd d0, d0, d1             // a + b
    fadd d0, d0, d2             // + c
    fmov d1, #3.0
    fdiv d0, d0, d1             // / 3.0
    ret

// double scale(long n, double x)   -> n * x
scale:
    scvtf d1, x0                // (double)n
    fmul d0, d1, d0             // n * x, returned in d0
    ret

// double sum_squares(const double *a, long n)
sum_squares:
    fmov d0, xzr                // double sum = 0.0;
sum_squares_loop:
    cbz x1, sum_squares_done    // while (n != 0)
    ldr d1, [x0], #8            //   double v = *a++;
    fmadd d0, d1, d1, d0        //   sum = sum + v * v;
    sub x1, x1, #1              //   n--;
    b sum_squares_loop
sum_squares_done:
    ret                         // return sum (in d0)

    .section .rodata
    .p2align 3
values:
    .double 1.5, 2.0, 3.0
fmt_avg:   .asciz "average3(1, 2, 4.5) = %f\n"
fmt_scale: .asciz "scale(%ld, %f) = %f\n"
fmt_sq:    .asciz "sum_squares({1.5, 2, 3}, 3) = %f\n"
fmt_total: .asciz "total = %f\n"
