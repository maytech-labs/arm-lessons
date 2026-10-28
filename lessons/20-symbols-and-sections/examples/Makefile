PARTS := mathlib
include ../../../mk/linux.mk

app: app.s mathlib.s
	$(CC) $(ASFLAGS) -o $@ app.s mathlib.s

%.o: %.s
	$(CC) $(ASFLAGS) -c -o $@ $<
