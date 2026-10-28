# Lesson 14 answers

Programs: [ex3.s](linux/solutions/ex3.s) to [ex7.s](linux/solutions/ex7.s).

## 14.1

1. The instruction after `bl sum_squares` in `_start` (`mov x8, #93`).
2. The instruction after the first `bl square` in `sum_squares`
   (`str x0, [sp, #24]`).
3. The instruction after the second `bl square` (`ldr x1, [sp, #24]`).
4. The same as 1: the epilogue's `ldp` restored the value the prologue saved.

1 and 4 are equal: that is the whole point of saving `x30`.

## 14.2

1. Leaf; no.
2. Non-leaf; yes.
3. Leaf: a system call is not a function call; no.
4. Non-leaf; yes (recursion, lesson 15).
5. It does not need to save `x30` *for that jump*: `b` leaves `x30` holding
   the original return address, so when the other function executes `ret`, it
   returns straight to our caller. This is a **tail call** (lesson 15). If it
   made any other `bl` before that, it would need to save and restore `x30`.

## 14.8

- **(a)** Non-leaf without saving `x30`. After `bl square`, `x30` points at the
  `lsl`, so `ret` jumps back to the `lsl` forever (an infinite loop). Add the
  prologue and epilogue.
- **(b)** `c` is in `x2`, but `add` may change `x2`. After the first call,
  `x2` may no longer be `c`. Save `c` in the frame (make the frame 32 bytes)
  before the first `bl` and load it into `x1` afterwards.
- **(c)** The early `ret` skips the epilogue: `x29`, `x30`, and `sp` are not
  restored, so the caller gets a wrong `sp` (and a later `ret` goes wrong).
  Branch to a single epilogue instead:

  ```asm
      mov x0, #0
      b clamp0_done
  clamp0_call:
      bl helper
  clamp0_done:
      ldp x29, x30, [sp], #16
      ret
  ```
