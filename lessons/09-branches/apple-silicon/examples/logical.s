// logical.s - && and || with short-circuit evaluation (macOS).
//
// C:      long x = 15;
//         long c = '\n';
//         long r = 0;
//         if (x >= 10 && x <= 20) r += 1;     // range check
//         if (c == ' ' || c == '\n') r += 2;  // is it white space?
//         return r;
// Build:  make
// Run:    ./logical; echo $?
// Expect: exit status 3

    .global _main               // make _main visible to the linker
    .text                       // code section
    .p2align 2                  // align instructions to 4 bytes

_main:
    mov x1, #15                 // x = 15
    mov x2, #'\n'               // c = 10
    mov x0, #0                  // r = 0

    // &&: if EITHER test fails, skip the body.
    cmp x1, #10                 // first test: x >= 10 ?
    b.lt end_and                //   false: whole && is false, skip (short-circuit)
    cmp x1, #20                 // second test: x <= 20 ?
    b.gt end_and                //   false: skip
    add x0, x0, #1              // both true: r += 1
end_and:

    // ||: if EITHER test succeeds, jump straight into the body.
    cmp x2, #' '                // first test: c == ' ' ?
    b.eq or_body                //   true: whole || is true, run the body now
    cmp x2, #'\n'               // second test: c == '\n' ?
    b.ne end_or                 //   false too: skip the body
or_body:
    add x0, x0, #2              // r += 2
end_or:
    mov x16, #1                 // 1 = exit
    svc #0x80                   // exit(r)
