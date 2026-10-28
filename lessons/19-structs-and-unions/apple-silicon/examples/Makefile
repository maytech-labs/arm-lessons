include ../../../../mk/apple.mk

# Programs that need a C file get their own rules; byvalue.s and bitfields.s
# have no main of their own.
all: offsets
offsets: offsets.c
	$(CC) $(ASFLAGS) -o $@ $<
byvalue: byvalue_main.c byvalue.s
	$(CC) $(ASFLAGS) -o $@ byvalue_main.c byvalue.s
bitfields: bitfields_main.c bitfields.s
	$(CC) $(ASFLAGS) -o $@ bitfields_main.c bitfields.s
clean: clean-c
clean-c:
	rm -rf offsets *.dSYM
