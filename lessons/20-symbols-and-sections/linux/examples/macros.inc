// macros.inc - assembler macros shared by .s files that .include this one.

// LOAD_ADDR reg, symbol: put the address of symbol in reg (two instructions)
    .macro LOAD_ADDR reg, sym
    adrp \reg, \sym
    add \reg, \reg, :lo12:\sym
    .endm

// PROLOGUE / EPILOGUE: the standard frame record, 16 bytes
    .macro PROLOGUE
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    .endm

    .macro EPILOGUE
    ldp x29, x30, [sp], #16
    ret
    .endm
