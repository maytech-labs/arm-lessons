# Lesson 19 exercises

Work in `lessons/19-structs-and-unions/linux/work/` (on macOS: `apple-silicon/work/`) inside the container. Copy
`examples/Makefile` and `examples/offsets.c` into it; extend `offsets.c` to
check any layout you compute by hand.

Try each exercise before looking at the answers: programs are in
[linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

If you installed arm-tools ([lesson 00](../00-setup/README.md#recommended-arm-tools)), lint your work before
you check the answers. In a Mac terminal, from this lesson's folder, run
`armtool lint linux/work` (or `apple-silicon/work`). It catches many
mistakes before you run anything.

## Exercise 19.1 [warm-up]

Give the offset of every member and the size of each struct:

```c
struct a { char c; long l; };
struct b { int i; short s; char c; };
struct c { char c1; short s; char c2; int i; };
struct d { char name[10]; long id; };
struct e { struct b inner; char flag; };
```

Check your answers with `offsets.c`.

## Exercise 19.2 [warm-up]

Reorder the members of `struct c` and `struct d` above to make them as small
as possible. What sizes do you get?

## Exercise 19.3 [core]

Write `ex3.s` with an array of three `struct rect { long x, y, w, h; }`:
`{0,0,4,5}`, `{2,3,10,1}`, `{1,1,3,3}`. Walk it with a pointer, adding up the
areas and finding the widest rectangle.

Check: `total area 39, widest is rect 1 at (2, 3)`.

## Exercise 19.4 [core]

`struct date { short year; char month; char day; }` is 4 bytes. Write `ex4.s`
with an array of dates (2026-10-27, 1969-07-20, 1969-11-19, 1991-08-25) that
finds the earliest by comparing `year << 16 | month << 8 | day`. Print it with
`%04d-%02d-%02d`.

Check: `earliest: 1969-07-20`.

## Exercise 19.5 [core]

Write `ex5.s` with
`struct minmax { long min, max; } find_minmax(const long *a, long n);` and a
C driver `ex5_main.c` that calls it on `{3, 42, -7, 0, 15}`. Where does the
result come back?

Check: `min -7, max 42`.

## Exercise 19.6 [core]

Write `ex6.s` with
`struct vec3 { long x, y, z; } vec3_add(struct vec3 a, struct vec3 b);` and a C
driver `ex6_main.c`. Which registers hold what when `vec3_add` starts?

Check: `(1, 2, 3) + (10, 20, 30) = (11, 22, 33)`.

## Exercise 19.7 [stretch]

Write `ex7.s` with a tagged union:

```c
enum { INT, STR };
struct value { int tag; union { long i; const char *s; } u; };
```

Work out its layout first. Define an array of three values (`INT 42`,
`STR "hello"`, `INT -1`) in `.data` and print each according to its tag,
choosing the format string with `csel`.

Check:

```
int 42
str hello
int -1
```
