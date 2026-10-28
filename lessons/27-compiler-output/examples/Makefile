include ../../../mk/linux.mk

# bench.s has no main: link it with its C driver, compiled with -O2.
bench: bench.s bench_main.c
	$(CC) $(ASFLAGS) -O2 -o $@ $^

# The C original of triangles.s, to compare against.
all: triangles_c
triangles_c: triangles.c
	$(CC) -g -O0 -o $@ $<

clean: clean-extra
clean-extra:
	rm -f triangles_c

.PHONY: clean-extra
