# Lesson 02 on macOS: Signed numbers

Nothing differs. Two's complement, the signed ranges, carry and overflow,
sign and zero extension, and little-endian byte order are all exactly the
same on Apple Silicon. C's `int` is 32 bits and `long` is 64 bits on both
Linux and macOS.

(One C detail that does differ, plain `char` being signed on macOS and
unsigned on Linux, is covered in lesson 18.)

Do [the main lesson](../../lessons/02-signed-numbers/README.md) and its
[exercises](../../lessons/02-signed-numbers/exercises.md).
