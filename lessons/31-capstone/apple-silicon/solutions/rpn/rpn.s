// rpn.s - a reverse Polish notation calculator (lesson 31, project 2, macOS)
//
// Build: make
// Run:   printf '3 4 + 2 *\n1 0 /\n1 2 swap -\n' | ./rpn
// Expected output:
//   14
//   error: division by zero
//   1
// Tests: ../../../tests/check.sh rpn ./rpn
//        (from this directory)
//
// Every input line is evaluated on its own, with an empty stack of up to 64
// longs. Tokens: numbers (anything strtol reads completely), + - * / %,
// dup, swap, drop.
//
// C version (abridged):
//   void eval_line(char *p) {
//       long st[64]; int n = 0, tokens = 0; char *end;
//       for (;;) {
//           while (*p == ' ' || *p == '\t' || *p == '\n') p++;
//           if (*p == 0) break;
//           char *tok = p;
//           while (*p && *p != ' ' && *p != '\t' && *p != '\n') p++;
//           if (*p) *p++ = 0;                 // cut the token out in place
//           tokens++;
//           long v = strtol(tok, &end, 10);
//           if (*end == 0) {                  // the whole token was a number
//               if (n == 64) { puts("error: stack overflow"); return; }
//               st[n++] = v; continue;
//           }
//           if (single character + - * / %) {
//               if (n < 2) { puts("error: stack underflow"); return; }
//               long b = st[--n], a = st[--n];
//               if ((op == '/' || op == '%') && b == 0) {
//                   puts("error: division by zero"); return;
//               }
//               st[n++] = a OP b;
//           } else if (strcmp(tok, "dup") == 0) { ... }
//           else if (strcmp(tok, "swap") == 0) { ... }
//           else if (strcmp(tok, "drop") == 0) { ... }
//           else { printf("error: unknown token '%s'\n", tok); return; }
//       }
//       if (tokens == 0) return;
//       if (n == 1) printf("%ld\n", st[0]);
//       else printf("error: %d values left on stack\n", n);
//   }
//
//   int main(void) {
//       char line[1024];
//       while (fgets(line, sizeof line, stdin)) eval_line(line);
//       return 0;
//   }

    .equ MAXSTACK, 64

    .text

// ---------------------------------------------------------------------------
// void eval_line(char *p)
//   x19 = p, w20 = n (stack depth), w21 = token count, x22 = tok
// Frame (576 bytes):
//   [sp, #0]   x29, x30
//   [sp, #16]  x19, x20
//   [sp, #32]  x21, x22
//   [sp, #48]  end   (strtol writes here)
//   [sp, #64]  st[64], 512 bytes
// ---------------------------------------------------------------------------
    .p2align 2
eval_line:
    sub sp, sp, #576
    stp x29, x30, [sp]
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    mov x19, x0
    mov w20, #0
    mov w21, #0

next_token:
    // skip spaces, tabs and newlines
    ldrb w9, [x19]
    cmp w9, #' '
    b.eq 1f
    cmp w9, #'\t'
    b.eq 1f
    cmp w9, #'\n'
    b.eq 1f
    cbz w9, line_end
    b token_start
1:  add x19, x19, #1
    b next_token

token_start:
    mov x22, x19                // tok = p
2:  ldrb w9, [x19]
    cbz w9, token_cut
    cmp w9, #' '
    b.eq 3f
    cmp w9, #'\t'
    b.eq 3f
    cmp w9, #'\n'
    b.eq 3f
    add x19, x19, #1
    b 2b
3:  strb wzr, [x19], #1         // *p++ = 0
token_cut:
    add w21, w21, #1

    // --- is it a number? ---------------------------------------------------
    mov x0, x22
    add x1, sp, #48             // &end
    mov w2, #10
    bl _strtol                   // x0 = value
    ldr x9, [sp, #48]           // end
    ldrb w10, [x9]
    cbnz w10, not_number
    cmp x9, x22                 // an empty token never gets here, but be safe
    b.eq not_number
    cmp w20, #MAXSTACK
    b.ge err_overflow
    add x9, sp, #64
    str x0, [x9, w20, uxtw #3]  // st[n++] = v
    add w20, w20, #1
    b next_token

not_number:
    ldrb w9, [x22]
    ldrb w10, [x22, #1]
    cbnz w10, word_token        // longer than one character
    cmp w9, #'+'
    b.eq binary_op
    cmp w9, #'-'
    b.eq binary_op
    cmp w9, #'*'
    b.eq binary_op
    cmp w9, #'/'
    b.eq binary_op
    cmp w9, #'%'
    b.eq binary_op
    b err_unknown

    // --- + - * / % ---------------------------------------------------------
    // w9 still holds the operator character.
binary_op:
    cmp w20, #2
    b.lt err_underflow
    add x13, sp, #64            // x13 = st
    sub w20, w20, #1
    ldr x12, [x13, w20, uxtw #3] // b = st[--n]
    sub w20, w20, #1
    ldr x11, [x13, w20, uxtw #3] // a = st[--n]
    cmp w9, #'+'
    b.ne 4f
    add x0, x11, x12
    b push_result
4:  cmp w9, #'-'
    b.ne 5f
    sub x0, x11, x12
    b push_result
5:  cmp w9, #'*'
    b.ne 6f
    mul x0, x11, x12
    b push_result
6:  cbz x12, err_divzero        // '/' or '%' from here on
    sdiv x0, x11, x12           // q = a / b (truncates toward zero, like C)
    cmp w9, #'/'
    b.eq push_result
    msub x0, x0, x12, x11       // r = a - q * b
push_result:
    str x0, [x13, w20, uxtw #3] // st[n++] = result
    add w20, w20, #1
    b next_token

    // --- dup swap drop -------------------------------------------------------
word_token:
    mov x0, x22
    adrp x1, w_dup@PAGE
    add x1, x1, w_dup@PAGEOFF
    bl _strcmp
    cbz w0, op_dup
    mov x0, x22
    adrp x1, w_swap@PAGE
    add x1, x1, w_swap@PAGEOFF
    bl _strcmp
    cbz w0, op_swap
    mov x0, x22
    adrp x1, w_drop@PAGE
    add x1, x1, w_drop@PAGEOFF
    bl _strcmp
    cbz w0, op_drop
    b err_unknown

op_dup:
    cbz w20, err_underflow
    cmp w20, #MAXSTACK
    b.ge err_overflow
    add x13, sp, #64
    sub w9, w20, #1
    ldr x0, [x13, w9, uxtw #3]  // top
    b push_result

op_swap:
    cmp w20, #2
    b.lt err_underflow
    add x13, sp, #64
    sub w9, w20, #1
    sub w10, w20, #2
    ldr x11, [x13, w9, uxtw #3]
    ldr x12, [x13, w10, uxtw #3]
    str x12, [x13, w9, uxtw #3]
    str x11, [x13, w10, uxtw #3]
    b next_token

op_drop:
    cbz w20, err_underflow
    sub w20, w20, #1
    b next_token

    // --- end of the line ------------------------------------------------------
line_end:
    cbz w21, done               // blank line: print nothing
    cmp w20, #1
    b.ne err_left
    adrp x0, fmt_value@PAGE
    add x0, x0, fmt_value@PAGEOFF
    ldr x9, [sp, #64]           // st[0]
    sub sp, sp, #16
    str x9, [sp]                // variadic: on the stack
    bl _printf
    add sp, sp, #16
    b done

err_left:
    adrp x0, fmt_left@PAGE
    add x0, x0, fmt_left@PAGEOFF
    sub sp, sp, #16
    str x20, [sp]               // variadic: n (upper half of x20 is zero)
    bl _printf
    add sp, sp, #16
    b done
err_unknown:
    adrp x0, fmt_unknown@PAGE
    add x0, x0, fmt_unknown@PAGEOFF
    sub sp, sp, #16
    str x22, [sp]               // variadic: tok
    bl _printf
    add sp, sp, #16
    b done
err_overflow:
    adrp x0, msg_overflow@PAGE
    add x0, x0, msg_overflow@PAGEOFF
    b err_puts
err_underflow:
    adrp x0, msg_underflow@PAGE
    add x0, x0, msg_underflow@PAGEOFF
    b err_puts
err_divzero:
    adrp x0, msg_divzero@PAGE
    add x0, x0, msg_divzero@PAGEOFF
err_puts:
    bl _puts                     // puts adds the newline
done:
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp]
    add sp, sp, #576
    ret

// ---------------------------------------------------------------------------
// int main(void)
// ---------------------------------------------------------------------------
    .global _main
    .p2align 2
_main:
    sub sp, sp, #1040           // 16 for x29/x30 + 1024 for line
    stp x29, x30, [sp]
    mov x29, sp
read_line:
    add x0, sp, #16
    mov w1, #1024
    adrp x2, ___stdinp@GOTPAGE
    ldr x2, [x2, ___stdinp@GOTPAGEOFF]
    ldr x2, [x2]                // stdin
    bl _fgets
    cbz x0, main_done
    add x0, sp, #16
    bl eval_line
    b read_line
main_done:
    mov w0, #0
    ldp x29, x30, [sp]
    add sp, sp, #1040
    ret

    .section __TEXT,__cstring
w_dup:         .asciz "dup"
w_swap:        .asciz "swap"
w_drop:        .asciz "drop"
fmt_value:     .asciz "%ld\n"
fmt_left:      .asciz "error: %d values left on stack\n"
fmt_unknown:   .asciz "error: unknown token '%s'\n"
msg_overflow:  .asciz "error: stack overflow"
msg_underflow: .asciz "error: stack underflow"
msg_divzero:   .asciz "error: division by zero"
