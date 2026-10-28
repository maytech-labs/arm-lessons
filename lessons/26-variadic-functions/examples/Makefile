include ../../../mk/linux.mk

# sum.s and myprintf.s have no main: link each with its C test driver.
sum: sum.s sum_test.c
	$(CC) $(ASFLAGS) -o $@ $^

myprintf: myprintf.s myprintf_test.c
	$(CC) $(ASFLAGS) -o $@ $^

# pfdemo.s calls myprintf, so it needs myprintf.s too.
pfdemo: pfdemo.s myprintf.s
	$(CC) $(ASFLAGS) -o $@ $^
