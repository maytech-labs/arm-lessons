# Lesson 26 solutions

Programs: `ex3.s` to `ex7.s` (build with `make`, run `./ex3` and so on).
Each file's header comment shows the expected output.

## Exercise 26.1

On Linux every variadic argument goes where a normal argument of its type would.

1. `x0` = format, `x1` = `"x"`, `x2` = 5.
2. `x0` = format, `d0` = 1.5, `x1` = 2, `d1` = 3.5. Integers and doubles count
   separately, so 2 is in `x1` even though it is the second argument.
3. `x0` = format, `x1`-`x7` = 1 to 7, and 8 in the 8-byte slot at `[sp]`.
4. The default promotions turn `'z'` into the `int` 122 and `2.0f` into the
   `double` 2.0. So `x1` = 122 and `d0` = 2.0 as a double (not a float in `s0`).

## Exercise 26.2

1. Two named integer-class parameters (`a`, `b`) and one named FP parameter
   (`c`): `__gr_offs = -(8 - 2) * 8 = -48` and `__vr_offs = -(8 - 1) * 16 = -112`.
2. `x2`-`x7` and `q1`-`q7`. (`x0`, `x1` and `q0` hold the named parameters.)
3. `x0` = 1, `x1` = `"s"`, `d0` = 2.0, then the unnamed ints: 10 to 60 in `x2`-`x7`,
   and 70 on the stack at `[sp]`.
4. Nothing in the call says how many arguments there are. The registers
   `x2`-`x7` always contain *something*, and the stack above `sp` always
   contains *something*; the function cannot tell real arguments from leftovers.
   It needs a count, a format string, or a terminator (like a final `NULL`).

## Exercise 26.8

1. `w0` = 3, `x1` = 1, `d0` = 2.0, `x2` = 3. The double does not use an `x`
   register.
2. `show` asks for three ints, so it reads the GR save area three times: `x1`
   (1), `x2` (3), then `x3`, which was never set by the caller. It prints
   `1 3 ` followed by whatever happened to be in `x3`. In the container it
   printed `1 3 1519061216` once and `1 3 2052523712` another time.
3. On macOS all three are on the stack in 8-byte slots: 1, the bits of 2.0
   (`0x4000000000000000`), 3. Reading three ints reads the low 4 bytes of each
   slot: 1, 0 (the low half of 2.0's bits), 3. It prints `1 0 3`.
4. The same wrong program gives different wrong answers on different ABIs, and
   on Linux even different answers from run to run. Passing the wrong type to a
   variadic function is undefined behaviour; neither the compiler nor the CPU
   catches it (gcc's `-Wformat` only checks `printf`-style format strings).
