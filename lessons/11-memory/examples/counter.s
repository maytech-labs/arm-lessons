// counter.s - load a number from memory, add 1, store it back, load it again.
//
// Build:  make
// Run:    ./counter; echo $?
// Expect: exit status 42
//
// C equivalent:
//     long counter = 41;
//     counter = counter + 1;
//     return counter;

    .global _start              // make _start visible to the linker

    .data                       // writable data
    .p2align 3                  // start on an 8-byte boundary (explained later)
counter:
    .quad 41                    // 8 bytes holding the number 41

    .text
    .p2align 2

_start:
    adrp x1, counter            // x1 = page of counter
    add x1, x1, :lo12:counter   // x1 = address of counter
    ldr x2, [x1]                // x2 = the 8 bytes at address x1  (x2 = 41)
    add x2, x2, #1              // x2 = 42 (only the register changed)
    str x2, [x1]                // store x2 back into memory at x1
    mov x2, #0                  // wipe x2, to prove the next load is real
    ldr x0, [x1]                // x0 = counter, read fresh from memory
    mov x8, #93                 // 93 = exit
    svc #0                      // exit(counter)
