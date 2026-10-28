# Lesson 06 answers

Programs: [ex4.s](ex4.s), [ex7.s](ex7.s). Your addresses may differ from the
ones shown here.

## 06.1

1. `starti`
2. `si`
3. `si 5`
4. `p/x $x3`
5. `p/t $x3`
6. `x/16xb $x1`
7. `x/s $x1`
8. `break loop`
9. `set $x0 = 99`

## 06.2

| After instruction | x0 | x1 | x2 | x3 | x4 |
|-------------------|----|----|----|----|----|
| `mov x0, #1` | 1 | 0 | 0 | 0 | 0 |
| `mov x1, #2` | 1 | 2 | 0 | 0 | 0 |
| `mov x2, #0xff` | 1 | 2 | 255 | 0 | 0 |
| `mov x3, x2` | 1 | 2 | 255 | 255 | 0 |
| `mov w4, #7` | 1 | 2 | 255 | 255 | 7 |
| `mov x0, #42` | 42 | 2 | 255 | 255 | 7 |

On Linux, every register starts at 0 when a freestanding program begins. (On
macOS they do not; see the companion lesson.) Never rely on a starting value:
set every register you use.

## 06.3

1. `0x41 0x52 0x4d 0x21`: `A`, `R`, `M`, `!`.
2. `0xff`, 255.
3. `0xff030201`: little-endian, so the first byte (`01`) is the lowest.
4. `0x55667788  0x11223344`: the low four bytes of the `.quad` come first in
   memory, so the first word is the low half.
5. It prints `"ARM!\001\002\003\377\210wfUD3\"\021*"`: `.ascii` added no zero
   after `ARM!`, so `x/s` keeps reading into `small` and `big` until it finds
   a zero byte.

## 06.4

```
(gdb) starti
(gdb) si 5
(gdb) i r x0 x1 x2
x0  0x410130   <- should be the fd (1), but is the address
x1  0x1        <- should be the address, but is the fd
x2  0x4        <- correct
(gdb) si
(gdb) p $x0
$1 = -9        <- -EBADF: "bad file descriptor"
```

Fix: swap the roles, as in [ex4.s](ex4.s).

## 06.5

Stop at the last `svc` (`starti` then `si 7`, or `break` on a label you add),
then `set $x0 = 7` and `c`. gdb reports `exited with code 07`. `x0` is the
argument to `exit`; `x8` must stay 93 or it would become a different system
call.

## 06.6

`Hello` with no newline; `p $x0` shows 5. `write` wrote exactly as many bytes
as it was told.

## 06.7

```
(gdb) break before_write
(gdb) run
(gdb) i r x0 x1 x2          -> 1, address of msg, 14
(gdb) break before_exit
(gdb) c
(gdb) p $x0                 -> 0, because the mov x0, #0 already ran; to see
                               write's result, look right after the first svc
(gdb) set $x0 = 7
(gdb) c                     -> exited with code 07
```

Labels produce no bytes: `objdump -d` shows the same instructions at the same
addresses, with the new names attached.

## 06.8

`pc` grows by 4 on every step, because every instruction is 4 bytes. After an
`svc` returns, `pc` is the `svc`'s address + 4: the system call returns to the
next instruction.
