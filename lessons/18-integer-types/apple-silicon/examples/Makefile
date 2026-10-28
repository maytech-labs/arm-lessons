include ../../../../mk/apple.mk

all: char_sign
char_sign: char_sign.c
	$(CC) -g -O0 -o $@ $<
clean: clean-c
clean-c:
	rm -rf char_sign char_sign.dSYM
