include ../../../../mk/linux.mk

# Programs made from a C file plus an assembly file need their own rules.
# The shared rules would try to link sum3.s and greet.s on their own.
sum3: sum3_main.c sum3.s
	$(CC) $(ASFLAGS) -o $@ sum3_main.c sum3.s

greet: greet_main.c greet.s
	$(CC) $(ASFLAGS) -o $@ greet_main.c greet.s
