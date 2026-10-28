// first_call.s - call a function with bl and come back with ret (macOS).
//
// C:      long add_one(long n) { return n + 1; }
//         ... exit(add_one(41));
//
// Build:  make
// Run:    ./first_call; echo $?
// Exit status (echo $?): 42

    .global _main
    .text
    .p2align 2

_main:
    mov x0, #41                 // the argument goes in x0
    bl add_one                  // call: x30 = address of the next instruction, jump
    mov x16, #1                 // we come back here; the result is in x0
    svc #0x80                   // exit(add_one(41))

// long add_one(long n)
//   in:  x0 = n
//   out: x0 = n + 1
add_one:
    add x0, x0, #1
    ret                         // jump to the address in x30
