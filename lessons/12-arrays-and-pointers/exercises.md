# Lesson 12 exercises

Work in `lessons/12-arrays-and-pointers/linux/work/` (on macOS: `apple-silicon/work/`) inside the container:

```console
# mkdir -p work && cd work && cp ../examples/Makefile .
```

Start each program from an example that already has the print block, and
change the data and the loop. Try each exercise before looking at the
answers: programs are in [linux/solutions/](linux/solutions/), written answers in
[answers.md](answers.md).

## Exercise 12.1 [warm-up]

An array starts at address `0x1000`. Give the address of:

1. `a[5]` if `a` is `char a[10]`
2. `a[5]` if `a` is `int a[10]`
3. `a[5]` if `a` is `long a[10]`
4. `m[2][3]` if `m` is `int m[4][6]`
5. the element `p` points at after `p = a; p += 3;` with `int *p`
6. And: if `int *p` holds `0x1018` and `int *q` holds `0x1004`, what is
   `p - q` in C?

## Exercise 12.2 [warm-up]

Write one instruction for each (`x9` = `a`, `x10` = `i`, `x11` = `p`):

1. `x0 = a[i]` for `long a[]`
2. `w0 = a[i]` for `unsigned short a[]`
3. `x0 = a[i]` for `signed char a[]`, as a `long`
4. `a[i] = w0` for `int a[]`
5. `x0 = *p++` for `long *p`
6. `x11 = &a[i]` for `int a[]`

## Exercise 12.3 [core]

Write `ex3.s` that counts the negative numbers in
`int a[] = {3, -1, 4, -1, -5, 9, 2, -6}` and prints the count.

Check: prints `4`. What does it print if you use `ldr w11` and compare `x11`
with 0? Why?

## Exercise 12.4 [core]

Write `ex4.s` that computes the dot product of `{1, 2, 3, 4}` and
`{5, 6, 7, 8}` (the sum of `a[i] * b[i]`) by walking **two pointers** with
post-index loads.

Check: prints `70`.

## Exercise 12.5 [core]

Write `ex5.s` that copies `{1, 2, 3, 4, 5, 6, 7, 8}` into a second array in
reverse order, using a post-index load on the source and a pre-index store
(`[x10, #-4]!`) on the destination, and prints the second array.

Check: prints `8 7 6 5 4 3 2 1`.

## Exercise 12.6 [core]

Using the matrix from `examples/matrix.s`, write `ex6.s` that prints the sum
of each **column**. Walk down a column by adding a whole row's size to a
pointer.

Check: prints `15 18 21 24`.

## Exercise 12.7 [stretch]

Write `ex7.s`: selection sort of the `long` array
`{50, 20, 70, 10, 80, 30, 60, 40}`. For each position `i`, find the index of
the smallest remaining element and swap it into place. Use `csel` to track the
index of the minimum.

Check: prints `10 20 30 40 50 60 70 80`.

## Exercise 12.8 [stretch]

Write `ex8.s` that removes duplicates from the **sorted** array
`{1, 1, 2, 3, 3, 3, 4, 5, 5}` in place, prints the unique values, and exits
with how many there are. Use one index for reading and one for writing.

Check: prints `1 2 3 4 5`; `echo $?` prints `5`.
