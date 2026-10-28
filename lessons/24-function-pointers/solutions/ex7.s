// ex7.s - a command table: look a name up with strcmp, call its function (lesson 24, exercise 24.7)
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
    .global main
    .p2align 2

cmd_hello:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, str_hello
    add  x0, x0, :lo12:str_hello
    bl   puts
    ldp x29, x30, [sp], #16
    ret

cmd_count:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, str_count
    add  x0, x0, :lo12:str_count
    bl   puts
    ldp x29, x30, [sp], #16
    ret

cmd_help:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    adrp x19, commands
    add  x19, x19, :lo12:commands
cmd_help_loop:
    ldr  x1, [x19, #CMD_NAME]
    cbz  x1, cmd_help_done          // the {0, 0} entry ends the table
    adrp x0, fmt_help
    add  x0, x0, :lo12:fmt_help
    bl   printf
    add  x19, x19, #CMD_SIZE
    b    cmd_help_loop
cmd_help_done:
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

// void dispatch(const char *word)
dispatch:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    mov x19, x0                     // word
    mov x1, x0
    adrp x0, fmt_prompt
    add  x0, x0, :lo12:fmt_prompt
    bl   printf
    adrp x20, commands              // c = commands
    add  x20, x20, :lo12:commands
dispatch_loop:
    ldr  x0, [x20, #CMD_NAME]
    cbz  x0, dispatch_unknown
    mov  x1, x19
    bl   strcmp
    cbz  w0, dispatch_found
    add  x20, x20, #CMD_SIZE
    b    dispatch_loop
dispatch_found:
    ldr  x9, [x20, #CMD_RUN]
    blr  x9                         // c->run()
    b    dispatch_done
dispatch_unknown:
    mov  x1, x19
    adrp x0, fmt_unknown
    add  x0, x0, :lo12:fmt_unknown
    bl   printf
dispatch_done:
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

main:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    adrp x19, script
    add  x19, x19, :lo12:script
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

    .section .rodata
name_hello:  .asciz "hello"
name_count:  .asciz "count"
name_help:   .asciz "help"
name_nope:   .asciz "nope"
str_hello:   .asciz "Hello!"
str_count:   .asciz "1 2 3"
fmt_help:    .asciz "  %s\n"
fmt_prompt:  .asciz "> %s\n"
fmt_unknown: .asciz "unknown command: %s\n"
