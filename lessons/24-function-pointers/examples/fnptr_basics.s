// fnptr_basics.s - take the address of a function and call it through a register (lesson 24)
//
// Build: make fnptr_basics
// Run:   ./fnptr_basics
// Expected output (the address changes every run):
//   add_ints lives at 0xaaaad5c10794
//   op(7, 2) = 9
//   op(7, 2) = 5
//   hello from puts, called through a pointer
//
// The C version:
//   int add_ints(int a, int b) { return a + b; }
//   int sub_ints(int a, int b) { return a - b; }
//   int main(void) {
//       int (*op)(int, int);
//       printf("add_ints lives at %p\n", (void *)add_ints);
//       op = add_ints;  printf("op(7, 2) = %d\n", op(7, 2));
//       op = sub_ints;  printf("op(7, 2) = %d\n", op(7, 2));
//       int (*say)(const char *) = puts;
//       say("hello from puts, called through a pointer");
//       return 0;
//   }

    .text
    .global main
    .p2align 2

// int add_ints(int a, int b)
add_ints:
    add w0, w0, w1
    ret

// int sub_ints(int a, int b)
sub_ints:
    sub w0, w0, w1
    ret

main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]              // x19 will hold our function pointer

    // A function's name is just a label: its address is a number like any other.
    adrp x0, fmt_addr
    add  x0, x0, :lo12:fmt_addr
    adr  x1, add_ints               // x1 = &add_ints
    bl   printf

    // op = add_ints; op(7, 2)
    adr  x19, add_ints              // x19 = op
    mov  w0, #7
    mov  w1, #2
    blr  x19                        // call the address in x19; x30 = return address
    mov  w1, w0
    adrp x0, fmt_op
    add  x0, x0, :lo12:fmt_op
    bl   printf

    // op = sub_ints; op(7, 2) - same call instruction, different function
    adrp x19, sub_ints              // adrp + add reaches any address, not just +/-1 MiB
    add  x19, x19, :lo12:sub_ints
    mov  w0, #7
    mov  w1, #2
    blr  x19
    mov  w1, w0
    adrp x0, fmt_op
    add  x0, x0, :lo12:fmt_op
    bl   printf

    // say = puts; puts lives in libc, so its address comes from the GOT.
    adrp x19, :got:puts             // page of the GOT slot holding &puts
    ldr  x19, [x19, :got_lo12:puts] // x19 = &puts
    adrp x0, msg
    add  x0, x0, :lo12:msg
    blr  x19

    mov  w0, #0
    ldr  x19, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret

    .section .rodata
fmt_addr: .asciz "add_ints lives at %p\n"
fmt_op:   .asciz "op(7, 2) = %d\n"
msg:      .asciz "hello from puts, called through a pointer"
