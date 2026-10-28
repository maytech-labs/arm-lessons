// encoding.s - a few instructions to look at with objdump. Exits with status 42.
//
// This lesson is about what instructions ARE, not how to write programs.
// You will learn to write a file like this yourself in lesson 04; for now,
// read it, build it, and look inside it.
//
// Build:  make
// Run:    ./encoding
// Look:   objdump -d encoding
// Exit status (echo $?): 42

    .global _start              // let the linker see _start (lesson 04)
    .text                       // code goes in the .text section
    .p2align 2                  // instructions must start at a multiple of 4 (lesson 04)
_start:                         // execution begins at this label
    mov x0, #1                  // x0 = 1
    mov x0, #2                  // x0 = 2 (replaces the 1)
    mov x0, #42                 // x0 = 42
    mov x1, #42                 // x1 = 42: same number, different register
    mov x2, #42                 // x2 = 42
    mov w0, #42                 // w0 = 42: the low 32 bits of x0; upper 32 become 0
    mov x8, #93                 // x8 = 93: the Linux system call number for exit (lesson 04)
    svc #0                      // system call: exit with status x0 = 42 (lesson 04)
