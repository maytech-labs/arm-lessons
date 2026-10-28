# Lesson 20 answers

Programs: [ex3.s](linux/solutions/ex3.s), [ex4.s](linux/solutions/ex4.s) with [stack.s](linux/solutions/stack.s),
[ex5.s](linux/solutions/ex5.s), [ex7.s](linux/solutions/ex7.s).

## 20.1

1. `.bss`, global (initialised to zero)
2. `.data`, global
3. `.bss`, local
4. `.rodata`, global
5. The **strings** are in `.rodata`; the **array of pointers** is not
   `const` itself (only what it points at), so it is writable: `.data`, local.
   (`static const char *const names[]` would be read-only, but since it holds
   addresses it typically still goes in a relocated read-only data section,
   `.data.rel.ro`.)
6. `.text`, global
7. `.text`, local
8. Nothing is defined: it is just an undefined symbol (`U`) wherever it is used.

## 20.2

In the linked `app`, `printf` (and other C library functions) is still `U`:
it lives in the shared C library, `libc.so.6`, and is resolved when the
program is loaded, not when it is linked.

## 20.4

Referring to `count` from `ex4.s` fails with
`undefined reference to 'count'`: without `.global`, the symbol never leaves
`stack.s`. That is the point: nothing outside the module can corrupt its state.

## 20.6

1. A symbol is used but no file exports it.
2. Two files export the same symbol.
3. `.bss` only reserves zeroed space; it cannot hold data.
4. The assembler cannot find a `1:` before that line (GNU as: `backward ref to unknown label "1:"`).

## 20.7

The strings are constants: `.rodata`. The table holds their *addresses*, which
are only known once the program is loaded at a final address, so the loader may
have to write them: the table goes in `.data`. On macOS this is required; on
Linux, a table of addresses in `.rodata` still works but makes the linker add
"text relocations".
