// first_call.s - call a function with bl and come back with ret.
//
// C:      long add_one(long n) { return n + 1; }
//         ... exit(add_one(41));
//
// Build:  make
// Run:    ./first_call; echo $?
// Exit status (echo $?): 42

    .global _start
    .text
    .p2align 2

_start:
    mov x0, #41                 // the argument goes in x0
    bl add_one                  // call: x30 = address of the next instruction, jump
    mov x8, #93                 // we come back here; the result is in x0
    svc #0                      // exit(add_one(41))

// long add_one(long n)
//   in:  x0 = n
//   out: x0 = n + 1
add_one:
    add x0, x0, #1
    ret                         // jump to the address in x30
