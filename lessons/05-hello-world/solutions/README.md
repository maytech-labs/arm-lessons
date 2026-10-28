# Lesson 05 answers

Programs: [ex2.s](ex2.s), [ex4.s](ex4.s), [ex5.s](ex5.s), [ex6.s](ex6.s).

## 05.1

1. `x0` = fd, `x1` = buffer address, `x2` = count; `x8` = 64.
2. stdin, stdout, stderr.
3. 4 bytes; 5 bytes (the extra zero).
4. 5: `a b c \t \n`.
5. Both: `adrp` gives the page, `add` adds the offset within it. Neither alone
   is the address.

## 05.3

1. Prints `Hello` with no newline; your prompt appears right after it.
2. Prints `Hello, world!` and a newline, then 26 more bytes of whatever
   follows `msg` in memory: usually zero bytes (invisible, but `xxd` shows
   `00`s). `write` does not care that they are not part of your message.
3. `x1` is the start of the 4 KiB page, not `msg`. `.data` does not start at
   a page boundary, so `x1` points at other bytes of the program. In this tiny
   program you typically see `.ELF` and binary junk: the page happens to start
   with the program file's own header. The exact result depends on the
   layout; that is the point.
4. Prints the message plus one zero byte (`xxd` shows `0a00` at the end).
5. On a terminal it often still appears: when you run a program in a terminal,
   fd 0 is usually the terminal too, opened for reading and writing. Redirect
   input (`./hello < /dev/null`) and nothing is printed: `write` fails. Never
   rely on this.

## 05.7

Delete `mov x0, #0` before the exit. `echo $?` shows `14`, the bytes written.
With fd 7 the write fails: `x0` holds `-9` (`-EBADF`, "bad file descriptor").
The shell shows the low 8 bits of -9, which is 247. Negative results from
system calls are how Linux reports errors.
