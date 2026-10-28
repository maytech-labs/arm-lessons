// ex7.s - a command table: look a name up with strcmp, call its function (lesson 24, exercise 24.7, macOS)
//
// Build: make ex7
// Run:   ./ex7
// Expected output:
//   > hello
//   Hello!
//   > count
//   1 2 3
//   > nope
//   unknown command: nope
//   > help
//     hello
//     count
//     help
//
// The C version:
//   struct command { const char *name; void (*run)(void); };   // 16 bytes
//   struct command commands[] = {
//       {"hello", cmd_hello}, {"count", cmd_count}, {"help", cmd_help}, {0, 0},
//   };
//   void cmd_hello(void) { puts("Hello!"); }
//   void cmd_count(void) { puts("1 2 3"); }
//   void cmd_help(void)  {
//       for (struct command *c = commands; c->name; c++) printf("  %s\n", c->name);
//   }
//   void dispatch(const char *word) {
//       printf("> %s\n", word);
//       for (struct command *c = commands; c->name; c++)
//           if (strcmp(c->name, word) == 0) { c->run(); return; }
//       printf("unknown command: %s\n", word);
//   }
//   const char *script[4] = {"hello", "count", "nope", "help"};
//   int main(void) { for (long i = 0; i < 4; i++) dispatch(script[i]); }

    .equ CMD_NAME, 0
    .equ CMD_RUN,  8
    .equ CMD_SIZE, 16
    .equ NSCRIPT,  4

    .text
    .global _main
    .p2align 2

cmd_hello:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, str_hello@PAGE
    add  x0, x0, str_hello@PAGEOFF
    bl   _puts
    ldp x29, x30, [sp], #16
    ret

cmd_count:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, str_count@PAGE
    add  x0, x0, str_count@PAGEOFF
    bl   _puts
    ldp x29, x30, [sp], #16
    ret

cmd_help:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    sub sp, sp, #16                 // room for printf's variadic arguments
    adrp x19, commands@PAGE
    add  x19, x19, commands@PAGEOFF
cmd_help_loop:
    ldr  x9, [x19, #CMD_NAME]
    cbz  x9, cmd_help_done          // the {0, 0} entry ends the table
    str  x9, [sp]
    adrp x0, fmt_help@PAGE
    add  x0, x0, fmt_help@PAGEOFF
    bl   _printf
    add  x19, x19, #CMD_SIZE
    b    cmd_help_loop
cmd_help_done:
    add sp, sp, #16
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void dispatch(const char *word)
dispatch:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                     // word
    sub sp, sp, #16                 // room for printf's variadic arguments
    str x0, [sp]                    // the same slot serves both printf calls
    adrp x0, fmt_prompt@PAGE
    add  x0, x0, fmt_prompt@PAGEOFF
    bl   _printf
    adrp x20, commands@PAGE         // c = commands
    add  x20, x20, commands@PAGEOFF
dispatch_loop:
    ldr  x0, [x20, #CMD_NAME]
    cbz  x0, dispatch_unknown
    mov  x1, x19
    bl   _strcmp
    cbz  w0, dispatch_found
    add  x20, x20, #CMD_SIZE
    b    dispatch_loop
dispatch_found:
    ldr  x9, [x20, #CMD_RUN]
    blr  x9                         // c->run()
    b    dispatch_done
dispatch_unknown:
    adrp x0, fmt_unknown@PAGE
    add  x0, x0, fmt_unknown@PAGEOFF
    bl   _printf
dispatch_done:
    add sp, sp, #16
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

_main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    adrp x19, script@PAGE
    add  x19, x19, script@PAGEOFF
    mov  x20, #0
main_loop:
    cmp  x20, #NSCRIPT
    b.ge main_done
    ldr  x0, [x19, x20, lsl #3]
    bl   dispatch
    add  x20, x20, #1
    b    main_loop
main_done:
    mov w0, #0
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

    .data
    .p2align 3
commands:
    .quad name_hello, cmd_hello
    .quad name_count, cmd_count
    .quad name_help,  cmd_help
    .quad 0, 0
script:
    .quad name_hello, name_count, name_nope, name_help

    .section __TEXT,__cstring
name_hello:  .asciz "hello"
name_count:  .asciz "count"
name_help:   .asciz "help"
name_nope:   .asciz "nope"
str_hello:   .asciz "Hello!"
str_count:   .asciz "1 2 3"
fmt_help:    .asciz "  %s\n"
fmt_prompt:  .asciz "> %s\n"
fmt_unknown: .asciz "unknown command: %s\n"
