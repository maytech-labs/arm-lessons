// stack.s - Exercise 20.4: a stack of longs whose storage is private (macOS).
//
// Exported: stack_push(long), stack_pop(void) -> long, stack_size(void) -> long
// Private:  items[] and count. No other file can see or corrupt them.

    .global stack_push
    .global stack_pop
    .global stack_size

    .equ CAPACITY, 16

    .bss
    .p2align 3
items:  .space CAPACITY * 8     // static long items[16];
count:  .space 8                // static long count;

    .text
    .p2align 2

// void stack_push(long v): ignores pushes beyond CAPACITY
stack_push:
    adrp x9, count@PAGE
    add x9, x9, count@PAGEOFF
    ldr x10, [x9]
    cmp x10, #CAPACITY
    b.hs stack_push_done
    adrp x11, items@PAGE
    add x11, x11, items@PAGEOFF
    str x0, [x11, x10, lsl #3]  // items[count] = v
    add x10, x10, #1
    str x10, [x9]               // count++
stack_push_done:
    ret

// long stack_pop(void): returns 0 if empty
stack_pop:
    adrp x9, count@PAGE
    add x9, x9, count@PAGEOFF
    ldr x10, [x9]
    mov x0, #0
    cbz x10, stack_pop_done
    sub x10, x10, #1
    str x10, [x9]               // count--
    adrp x11, items@PAGE
    add x11, x11, items@PAGEOFF
    ldr x0, [x11, x10, lsl #3]  // return items[count]
stack_pop_done:
    ret

// long stack_size(void)
stack_size:
    adrp x9, count@PAGE
    add x9, x9, count@PAGEOFF
    ldr x0, [x9]
    ret
