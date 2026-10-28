# Lesson 17: Strings

## Goals

After this lesson you can:

- explain exactly what a C string is in memory
- write your own `strlen`, `strcmp`, `strncmp`, `strcpy`, `strcat` and `strchr`
  in assembly, and check them against the C library's
- change letter case with a single bit, and reverse a string in place
- convert a number to text in any base (`itoa`), and text to a number with
  proper error checking (`atoi`)
- explain what a buffer overflow is, and see one happen

## Before you start

You need lesson 11 (byte loads and stores, post-index addressing), lesson 12
(pointers and pointer arithmetic), lesson 15 (the calling convention) and
lesson 16 (calling `printf`, `puts` and friends). Every program here prints
with `printf`, so on a Mac remember the variadic rule from lesson 16.

## What a C string is

C has no string type. A "string" is just a pointer to a `char`, and the
characters continue in memory until a byte with the value 0, the *null
terminator*, written `'\0'` in C.

```c
char greeting[] = "Hi!";
```

is four bytes:

```
address:  g+0   g+1   g+2   g+3
byte:     0x48  0x69  0x21  0x00
char:     'H'   'i'   '!'   '\0'
```

You already know the assembler version: `.asciz "Hi!"` emits the characters
followed by a zero byte (`.ascii` does not add the zero).

Two consequences that every function in this lesson follows from:

- **The length is not stored anywhere.** To find it you must walk the bytes
  until you find the 0. `sizeof greeting` is 4 (the array, including the 0),
  `strlen(greeting)` is 3 (the characters before the 0).
- **Every string function is a loop over bytes** that stops at the 0. In
  assembly that means `ldrb` (load one byte, zero-extended) and `strb` (store
  one byte), usually with post-index addressing so the pointer moves along:
  `ldrb w2, [x1], #1` is `c = *p++`.

The C library functions are declared in `<string.h>`. We will write our own
versions with a `my_` prefix, so that they do not clash with the real ones, and
call both to compare.

## `strlen`

In C:

```c
size_t my_strlen(const char *s) {
    const char *p = s;
    while (*p != '\0') p++;
    return p - s;
}
```

In assembly, from [`linux/examples/mystrlen.s`](linux/examples/mystrlen.s):

```asm
// size_t my_strlen(const char *s)
my_strlen:
    mov     x1, x0                  // p = s
strlen_loop:
    ldrb    w2, [x1], #1            // c = *p++
    cbnz    w2, strlen_loop         // keep going until c == 0
    sub     x0, x1, x0              // p is now one past the 0 byte,
    sub     x0, x0, #1              // so the length is p - s - 1
    ret
```

Because `ldrb ..., #1` moves `p` *after* loading, `p` ends up one byte past
the terminator, hence the `- 1`. `size_t` is an unsigned 64-bit type, so the
result goes in `x0`. This is a leaf function: no calls, no frame, and it uses
only caller-saved registers.

The program calls `my_strlen` and the C library's `strlen` on the same
strings and prints both. Predict the three lengths (the third string is
`"a longer string, with spaces"`), then:

```console
$ make mystrlen
$ ./mystrlen
my_strlen("hello") = 5, strlen = 5
my_strlen("") = 0, strlen = 0
my_strlen("a longer string, with spaces") = 28, strlen = 28
```

The empty string `""` is one byte, the terminator, and its length is 0.

## `strcmp` and `strncmp`

`strcmp(a, b)` compares two strings in dictionary order and returns a
negative number if `a` comes first, 0 if they are equal, and a positive
number if `b` comes first. It compares character by character until they
differ or the strings end:

```c
int my_strcmp(const char *a, const char *b) {
    unsigned char ca, cb;
    do {
        ca = *a++;
        cb = *b++;
    } while (ca == cb && ca != '\0');
    return ca - cb;
}
```

The characters are compared as `unsigned char` (the C standard says so), which
is exactly what `ldrb` gives you:

```asm
my_strcmp:
strcmp_loop:
    ldrb    w2, [x0], #1            // ca = *a++  (ldrb: unsigned, as C requires)
    ldrb    w3, [x1], #1            // cb = *b++
    cmp     w2, w3
    b.ne    strcmp_done             // different: done
    cbnz    w2, strcmp_loop         // same and not the end: keep going
strcmp_done:
    sub     w0, w2, w3              // ca - cb (0 if both ended together)
    ret
```

Trace `my_strcmp("app", "apple")` by hand before reading on. The first three
characters match. Then `ca = '\0'` (0) and `cb = 'l'` (108): they differ, so
the result is `0 - 108 = -108`, negative: `"app"` comes first. A prefix is
always "less" than the longer string, because 0 is smaller than any character.

The C standard promises only the **sign** of the result. Some C libraries
return the difference of the bytes, others any negative or positive number, so
never test `strcmp(a, b) == -1`; test `< 0`. The program prints the sign of
both results, using a small helper:

```asm
// int sign(int x): -1, 0 or 1
sign:
    cmp     w0, #0
    cset    w0, gt                  // w0 = (x > 0)
    csinv   w0, w0, wzr, ge         // if !(x >= 0) w0 = ~0 = -1
    ret
```

`strncmp(a, b, n)` is the same but stops after at most `n` characters, so
`strncmp("apple", "apricot", 2)` is 0: the first two characters match. The
only change is a counter that is checked first:

```asm
my_strncmp:
strncmp_loop:
    cbz     x2, strncmp_equal       // compared n characters: equal so far
    sub     x2, x2, #1
    ldrb    w3, [x0], #1
    ...                             // then exactly like my_strcmp
strncmp_equal:
    mov     w0, #0
    ret
```

[`linux/examples/mystrcmp.s`](linux/examples/mystrcmp.s):

```console
$ ./mystrcmp
strcmp("apple", "apricot"): mine -1, libc -1
strcmp("apple", "apple"): mine 0, libc 0
strcmp("pear", "peach"): mine 1, libc 1
strcmp("app", "apple"): mine -1, libc -1
strncmp("apple", "apricot", 2): mine 0, libc 0
strncmp("apple", "apricot", 3): mine -1, libc -1
```

Notice the "compare two strings with `==`" trap from C does not exist in
assembly in the same way, but its cousin does: `cmp x0, x1` on two string
*pointers* asks "are these the same address?", not "do they hold the same
text?". To compare text you need the loop.

## `strcpy` and `strcat`

`strcpy(dst, src)` copies the characters of `src`, including the terminator,
into the memory at `dst`, and returns `dst`. `strcat(dst, src)` appends:
it finds the end of `dst` and copies `src` there.

```c
char *my_strcpy(char *dst, const char *src) {
    char *d = dst;
    while ((*d++ = *src++) != '\0') { }
    return dst;
}
```

```asm
my_strcpy:
    mov     x2, x0                  // d = dst (x0 stays dst, for the return)
strcpy_loop:
    ldrb    w3, [x1], #1            // c = *src++
    strb    w3, [x2], #1            // *d++ = c   (copies the 0 too)
    cbnz    w3, strcpy_loop
    ret
```

The test is *after* the store, so the terminator gets copied before the loop
stops. `my_strcat` is "walk to the 0 of `dst`, then do `my_strcpy` from there".

Neither function knows how big `dst` is. **The caller must make sure it is
big enough**: for `strcpy`, `strlen(src) + 1` bytes; for `strcat`,
`strlen(dst) + strlen(src) + 1`. In [`linux/examples/mystrcpy.s`](linux/examples/mystrcpy.s)
the destination is a 64-byte buffer in `.bss`, more than enough:

```asm
    .bss
buf:
    .space  64                      // char buf[64]: big enough, we checked
```

`main` builds `"Hello, world!"` in four steps. One small trick: `my_strcat`
returns `dst` in `x0`, which is exactly the argument `puts` wants, so
`bl my_strcat` is directly followed by `bl puts`.

```console
$ ./mystrcpy
Hello, world!
length 13
```

## `strchr`

`strchr(s, c)` returns a pointer to the first `c` in `s`, or `NULL` (address
0) if there is none. Searching for `'\0'` is allowed and finds the terminator.

```c
char *my_strchr(const char *s, int c) {
    for (;; s++) {
        if (*s == (char)c) return (char *)s;
        if (*s == '\0')    return NULL;
    }
}
```

```asm
my_strchr:
    and     w1, w1, #0xff           // C converts c to a char first
strchr_loop:
    ldrb    w2, [x0]
    cmp     w2, w1
    b.eq    strchr_found            // test for c BEFORE testing for the end,
    cbz     w2, strchr_missing      // so that searching for '\0' works
    add     x0, x0, #1
    b       strchr_loop
strchr_missing:
    mov     x0, #0                  // NULL
strchr_found:
    ret
```

The result is a pointer *into* the original string. Printing it with `%s`
prints the rest of the string from that point, and subtracting the start
address gives the index. [`linux/examples/mystrchr.s`](linux/examples/mystrchr.s)
searches `"hello world.txt"`:

```console
$ ./mystrchr
'w' -> "world.txt" (index 6)
'.' -> ".txt" (index 11)
'z' -> not found
'\0' -> "" (index 15)
```

Never pass `NULL` to `printf("%s")` or `puts`. That is why the program checks
with `cbz x0, ...` before printing.

## Changing case with one bit

Look at the ASCII codes of a letter in both cases:

```
'A' = 0x41 = 0100 0001        'a' = 0x61 = 0110 0001
'Z' = 0x5a = 0101 1010        'z' = 0x7a = 0111 1010
```

They differ only in bit 5 (value `0x20`). So:

| Operation | Bit trick | Instruction |
|-----------|-----------|-------------|
| to upper case | clear bit 5: `c & ~0x20` | `and w0, w0, #~0x20` (or `bic`) |
| to lower case | set bit 5: `c \| 0x20` | `orr w0, w0, #0x20` |
| swap case | flip bit 5: `c ^ 0x20` | `eor w0, w0, #0x20` |

Only for letters, though: `'0' & ~0x20` is `0x10`, which is not a digit any
more. So first check the range. A neat trick does both ends of the range with
one unsigned comparison:

```asm
// int my_toupper(int c)
my_toupper:
    sub     w1, w0, #'a'            // w1 = c - 'a'
    cmp     w1, #25                 // one unsigned compare checks both ends:
    b.hi    toupper_done            // c < 'a' wraps to a huge number
    and     w0, w0, #~0x20          // clear bit 5
toupper_done:
    ret
```

If `c` is between `'a'` and `'z'`, `c - 'a'` is 0 to 25. If `c` is bigger,
it is more than 25. If `c` is *smaller* than `'a'`, the subtraction goes
negative, and a negative number viewed as unsigned is huge, so `b.hi` (unsigned
"higher") catches it too. You will use this "subtract, then one unsigned
compare" pattern for digits in `atoi` below.

[`linux/examples/case.s`](linux/examples/case.s) converts a string in place (it is in
`.data`, because we change it), then compares `my_toupper`/`my_tolower` with
libc's `toupper`/`tolower` for every byte value from 0 to 255:

```console
$ ./case
Hello, World 42!
HELLO, WORLD 42!
hello, world 42!
mismatches with libc for 0..255: 0
```

The counting uses `cinc w20, w20, ne`: "increment if not equal".

## Reversing in place

Two pointers, one at each end, swapping and moving towards each other:

```c
void reverse(char *s) {
    char *i = s, *j = s + strlen(s) - 1;
    while (i < j) { char t = *i; *i++ = *j; *j-- = t; }
}
```

```asm
rev_loop:
    cmp     x0, x1                  // while (i < j), as unsigned addresses
    b.hs    rev_done
    ldrb    w2, [x0]                // swap *i and *j
    ldrb    w3, [x1]
    strb    w3, [x0], #1            // *i++ = old *j
    strb    w2, [x1], #-1           // *j-- = old *i
    b       rev_loop
```

Addresses are unsigned, so the comparison uses `b.hs`. For the empty string,
`j` starts at `s - 1`, which is below `i`, so the loop does nothing. Predict
what happens for `"a"` (one character), then run
[`linux/examples/reverse.s`](linux/examples/reverse.s):

```console
$ ./reverse
stressed -> desserts
abc -> cba
a -> a
 ->
```

## Number to text: `itoa`

`printf("%ld")` turns a number into digits. How? Repeated division. The
remainder of dividing by 10 is the last digit; divide by 10 and repeat:

```
12345 % 10 = 5    12345 / 10 = 1234
 1234 % 10 = 4     1234 / 10 = 123
  123 % 10 = 3      123 / 10 = 12
   12 % 10 = 2       12 / 10 = 1
    1 % 10 = 1        1 / 10 = 0   stop
```

The digits come out backwards (`5 4 3 2 1`), so we store them and reverse
them at the end. The same works for any base; digits above 9 are the letters
`a`, `b`, ... (so base 16 uses `0-9a-f`, base 36 uses `0-9a-z`).

Negative numbers: write a `-`, then convert the *magnitude*. There is one
trap. The most negative `long`, `LONG_MIN = -9223372036854775808`, has no
positive counterpart: `LONG_MAX` is only `9223372036854775807`. In C, `-value`
overflows. But in the hardware, `neg` of `0x8000000000000000` is
`0x8000000000000000` again, which read as an *unsigned* number is exactly
9223372036854775808, the correct magnitude. So we treat the magnitude as
unsigned and divide with `udiv`, and every value works.

```c
char *my_itoa(long value, char *buf, int base) {
    char *p = buf;
    unsigned long u = value;
    if (value < 0) { *p++ = '-'; u = -u; }
    char *digits = p;
    do {                                     // do-while: 0 gives "0"
        int d = u % base;
        *p++ = d < 10 ? '0' + d : 'a' + d - 10;
        u /= base;
    } while (u != 0);
    *p = '\0';
    reverse the characters from digits to p - 1;
    return buf;
}
```

From [`linux/examples/itoa.s`](linux/examples/itoa.s):

```asm
my_itoa:
    mov     x3, x1                  // p = buf
    mov     x4, x0                  // u = value
    mov     w5, w2                  // x5 = base (writing w5 zeroes the top)
    tbz     x0, #63, itoa_digits    // sign bit clear: not negative
    mov     w6, #'-'
    strb    w6, [x3], #1            // *p++ = '-'
    neg     x4, x0                  // u = -value
itoa_digits:
    mov     x8, x3                  // digits = p
itoa_loop:
    udiv    x6, x4, x5              // q = u / base
    msub    x7, x6, x5, x4          // d = u - q * base
    cmp     x7, #10
    b.lo    itoa_decimal
    add     x7, x7, #('a' - 10)     // 10 -> 'a', 11 -> 'b', ...
    b       itoa_store
itoa_decimal:
    add     x7, x7, #'0'
itoa_store:
    strb    w7, [x3], #1            // *p++ = digit
    mov     x4, x6                  // u = q
    cbnz    x4, itoa_loop
    strb    wzr, [x3]               // *p = '\0'
    ...                             // then reverse, as in reverse.s
```

`base` is an `int`, so it arrives in `w2`; `mov w5, w2` copies it and clears
the top half of `x5`, ready for a 64-bit `udiv`. Why is the loop a
"do-while"? So that the value 0 produces one digit, `"0"`, instead of an empty
string.

How big must `buf` be? The longest result is base 2 of a negative number:
`-`, 64 digits, and the terminator, 66 bytes. The program uses 72.

`main` walks a table of `(value, base)` pairs and prints each with
`printf("%ld in base %d: %s\n", ...)`, so libc's own conversion (`%ld`) sits
next to ours. Predict the line for `255` in base 2 and for `-255` in base 16:

```console
$ ./itoa
0 in base 10: 0
12345 in base 10: 12345
-42 in base 10: -42
255 in base 16: ff
255 in base 2: 11111111
-255 in base 16: -ff
35 in base 36: z
9223372036854775807 in base 10: 9223372036854775807
-9223372036854775808 in base 10: -9223372036854775808
-9223372036854775808 in base 16: -8000000000000000
```

## Text to number: `atoi` with validation

The reverse direction: multiply what you have by 10 and add the next digit.

```
"345":  n = 0
'3':    n = 0 * 10 + 3 = 3
'4':    n = 3 * 10 + 4 = 34
'5':    n = 34 * 10 + 5 = 345
```

A character is a digit if it is between `'0'` and `'9'`, and its value is
`c - '0'`. That is the same subtract-then-unsigned-compare trick as `toupper`.

libc's `atoi` and `atol` are sloppy: they stop at the first non-digit and
never report an error. `atol("12x")` is 12 and `atol("abc")` is 0, so you
cannot tell bad input from a real zero. We will write a stricter version that
returns a success flag and passes the number back through a pointer:

```c
int parse_long(const char *s, long *out) {   // 1 = ok, 0 = invalid
    int negative = 0;
    if (*s == '-') { negative = 1; s++; }
    else if (*s == '+') { s++; }
    if (*s < '0' || *s > '9') return 0;      // need at least one digit
    long n = 0;
    for (; *s != '\0'; s++) {
        if (*s < '0' || *s > '9') return 0;  // junk after the digits
        n = n * 10 + (*s - '0');
    }
    *out = negative ? -n : n;
    return 1;
}
```

The heart of it in assembly, from [`linux/examples/atoi.s`](linux/examples/atoi.s):

```asm
parse_loop:
    ldrb    w4, [x0], #1
    cbz     w4, parse_end
    sub     w5, w4, #'0'
    cmp     w5, #9
    b.hi    parse_fail
    madd    x2, x2, x6, x5          // n = n * 10 + digit   (x6 = 10)
    b       parse_loop
parse_end:
    cbz     w3, parse_store
    neg     x2, x2
parse_store:
    str     x2, [x1]                // *out = n
    mov     w0, #1
    ret
```

`madd x2, x2, x6, x5` is `x2 = x5 + x2 * x6`. It can use `x5` safely because
writing `w5` with `sub` cleared the upper 32 bits.

The caller needs somewhere for `parse_long` to put the number. `main` keeps a
local `long n` in its own stack frame at `[sp, #40]` and passes its address,
`add x1, sp, #40`. That is C's `parse_long(s, &n)`.

The test inputs are reached through a table of pointers:

```asm
    .data
    .p2align 3
inputs:
    .quad   in1, in2, in3, in4, in5, in6, in7, in8
```

`.quad in1` stores the *address* of `in1`. Such a table goes in `.data`, not
`.rodata`: the real addresses are only known when the program is loaded, and
the loader has to write them in. Lesson 20 explains why.

```console
$ ./atoi
"123": 123 (atol says 123)
"-45": -45 (atol says -45)
"+7": 7 (atol says 7)
"0": 0 (atol says 0)
"": invalid (atol says 0)
"-": invalid (atol says 0)
"12x": invalid (atol says 12)
" 5": invalid (atol says 5)
```

`parse_long` still has one hole: a number with too many digits, like
`"99999999999999999999"`, silently wraps around. Exercise 17.8 fixes it.

## Buffer overflows

`strcpy` copies until it finds a 0 in the *source*. It has no idea where the
*destination* ends. If the source is longer than the destination, it keeps
writing into whatever memory comes next. That is a **buffer overflow**, and it
is the most famous bug in C.

[`linux/examples/overflow.s`](linux/examples/overflow.s) puts two 8-byte arrays next to
each other in `.data`:

```asm
    .data
name:
    .space  8                       // char name[8]
secret:
    .asciz  "s3cr3t"                // the very next bytes in memory
    .space  1                       // (pad secret to 8 bytes)
```

then does `strcpy(name, "Bartholomew")`: 11 characters plus the terminator,
12 bytes, into an 8-byte buffer. Before running it, work out which bytes land
in `secret`, and predict what `secret` will print as.

```
name:    B  a  r  t  h  o  l  o       (8 bytes: full)
secret:  m  e  w  \0 3  t  \0 \0      (the last 4 bytes of the copy land here)
```

```console
$ ./overflow
secret = s3cr3t
name = Bartholomew, secret = mew
name = Barthol, secret = s3cr3t
```

Two things happened. `secret` was overwritten with `"mew"`. And `name` now
prints as `Bartholomew` even though it only holds 8 bytes: `printf` keeps
reading past its end, into `secret`, until it finds the 0.

The program then does it properly with `safe_copy(dst, src, size)`, which
copies at most `size - 1` characters and always writes a terminator. The name
is cut to `Barthol` (7 characters + 0 = 8 bytes) and nothing else is touched.

On the stack an overflow is worse: a local buffer sits near saved registers,
including saved frame records with return addresses. Overwrite one, and a
`ret` jumps wherever the attacker's bytes say. Compilers add *stack
protectors* (a check value next to the buffer) to catch this, and C
libraries offer bounded functions (`snprintf`, `strncpy`, `strlcpy`), but in
assembly you have only your own care: **know the size of every buffer you
write into.**

## C to assembly

| C | Assembly |
|---|----------|
| `"Hi"` | `.asciz "Hi"`: bytes `'H' 'i' 0` |
| `c = *p++;` (char) | `ldrb w2, [x1], #1` |
| `*d++ = c;` | `strb w3, [x2], #1` |
| `while (*p) p++;` | `ldrb` + `cbnz` loop |
| `if (*s == '\0')` | `cbz w2, ...` |
| `s == t` (pointers) | `cmp x0, x1`: same address, not same text |
| `strcmp(a, b) < 0` | call it, then `cmp w0, #0` / `b.lt` |
| `c >= 'a' && c <= 'z'` | `sub w1, w0, #'a'` / `cmp w1, #25` / `b.ls` (in range) |
| `toupper(c)` (for a letter) | `and w0, w0, #~0x20` |
| `tolower(c)` (for a letter) | `orr w0, w0, #0x20` |
| `d = u % b; u /= b;` | `udiv q, u, b` / `msub d, q, b, u` / `mov u, q` |
| `'0' + d` | `add w7, w7, #'0'` |
| `n = n * 10 + d;` | `madd x2, x2, x6, x5` with `x6 = 10` |
| `long n; f(&n);` | a stack slot, `add x1, sp, #off` |
| `return NULL;` | `mov x0, #0` |

## Common mistakes

- **Forgetting the terminator.** Writing `.ascii` instead of `.asciz`, or a
  copy loop that tests before storing, leaves a string with no end. The next
  `printf` prints garbage after it, or crashes.
- **`ldr` instead of `ldrb`.** `ldr w2, [x1]` loads four characters at once;
  the zero test then fails on almost every string. Characters are bytes.
- **`ldrsb` instead of `ldrb` in `strcmp`.** Characters above 127 then compare
  as negative, and `"\xe9"` (an accented letter in Latin-1) sorts before `"a"`.
  C compares as `unsigned char`.
- **Off-by-one in `strlen`.** With post-index `ldrb`, the pointer ends one past
  the terminator; forget the `- 1` and every length is one too big.
- **Changing a string in `.rodata`.** `str_upper` on a string in
  `.section .rodata` crashes with `Segmentation fault`. Strings you modify
  belong in `.data` or `.bss`.
- **Destination too small.** `strcpy`, `strcat`, and your own copies write as
  much as the source has. Count `strlen + 1` bytes.
- **Testing the end before the character in `strchr`.** Then `strchr(s, '\0')`
  returns `NULL` instead of a pointer to the terminator.
- **Using `sdiv` in `itoa`.** It works until `LONG_MIN`, whose negation
  overflows. Convert the magnitude as unsigned with `udiv`.
- **A while loop in `itoa`.** `while (u != 0)` produces nothing for 0; use a
  do-while (test at the bottom).
- **Comparing `strcmp`'s result with -1 or 1.** Only the sign is defined.

## Recap

- A C string is bytes ending in a 0 byte. Its length is not stored; you find
  it by walking.
- String functions are byte loops: `ldrb`/`strb` with post-index addressing,
  `cbz`/`cbnz` to stop at the terminator.
- `strcmp` compares as unsigned bytes and only its sign matters.
- Upper and lower case differ in bit 5: clear it with `and #~0x20`, set it
  with `orr #0x20`, after a range check.
- "Subtract the low end, compare unsigned with the width" checks a range with
  one branch.
- `itoa` divides repeatedly and reverses; use the unsigned magnitude so that
  `LONG_MIN` works. `atoi` multiplies by 10 and adds; validate every character.
- Nothing stops a copy from running off the end of a buffer except you.

## Homework

[exercises.md](exercises.md)
