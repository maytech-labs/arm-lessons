# Lesson 10 answers

Programs: [ex2.s](ex2.s) to [ex9.s](ex9.s).

## 10.1

| Reaching `loop` | x0 | x1 |
|-----------------|----|----|
| 1st | 0 | 4 |
| 2nd | 8 | 3 |
| 3rd | 14 | 2 |
| 4th | 18 | 1 |
| 5th | 20 | 0 |

Exit status 20; the body runs 4 times. In C:

```c
long sum = 0;
for (long i = 4; i != 0; i--) sum += 2 * i;
```

## 10.3

The invariant `a = fib(k), b = fib(k + 1)` holds before the first pass
(k = 0) and each pass moves k on by one. After 13 passes, `a = fib(13)`.

## 10.9

Each `csel` overrides the previous choice when its test passes, so the
checks must go from least to most specific: 3, then 5, then 15. Checking 15
first would be overwritten by the 3 and 5 checks.
