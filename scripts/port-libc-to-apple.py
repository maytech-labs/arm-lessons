#!/usr/bin/env python3
"""Port a libc-using (lesson 16+) Linux-track .s file to the Apple track.

- main and C library functions get the Mach-O underscore (_main, _printf, ...)
- adrp/:lo12: -> @PAGE/@PAGEOFF, .rodata -> __TEXT,__const
- calls to printf/sprintf/fprintf/snprintf/dprintf: Apple passes variadic
  arguments on the stack. Before each such call the script inserts a block that
  stores the variadic registers into 8-byte stack slots. It counts the
  conversions in the format string (found from the adrp that loads the format
  argument); if it cannot find the format, it stores every remaining argument
  register.

Integer arguments only: anything with %f/%e/%g (doubles) must be ported by
hand. Always review and run the result.

Usage: scripts/port-libc-to-apple.py SRC.s DST.s
"""
import re
import sys

LIBC = ('printf sprintf snprintf fprintf dprintf puts putchar strlen strcpy strncpy strcat strncat '
        'strcmp strncmp strchr strrchr strstr strdup memcpy memset memmove memcmp toupper tolower '
        'isdigit isspace isalpha atoi atol strtol strtoul malloc calloc realloc free exit abort '
        'qsort bsearch fopen fclose fgets fputs fputc fflush fread fwrite getchar getenv perror '
        'read write open close').split()
VARIADIC = {'printf': 1, 'sprintf': 2, 'dprintf': 2, 'fprintf': 2, 'snprintf': 3}


def split_comment(line):
    in_str = False
    for i, c in enumerate(line):
        if c == '"' and (i == 0 or line[i - 1] != '\\'):
            in_str = not in_str
        if not in_str and line.startswith('//', i):
            return line[:i], line[i:]
    return line, ''


def conversions(fmt):
    fmt = fmt.replace('%%', '')
    return len(re.findall(r'%[-+ #0-9.]*[hlzjt]*[diouxXcsp]', fmt))


def main(src, dst):
    lines = open(src).read().split('\n')
    strings = {}
    for i, l in enumerate(lines):
        m = re.match(r'^(\w+):\s*(?:\.asciz\s+"(.*)")?', l)
        if m:
            body = m.group(2)
            if body is None and i + 1 < len(lines):
                m2 = re.match(r'^\s*\.asciz\s+"(.*)"', lines[i + 1])
                body = m2.group(1) if m2 else None
            if body is not None:
                strings[m.group(1)] = body
    defines_main = any(re.match(r'^main:', l) for l in lines)
    padded = sum(1 for l in lines if re.match(r'^\s+[a-z]{2,4}\s{2,}\S', l)) > len(lines) // 10
    op = (lambda m: m.ljust(8)) if padded else (lambda m: m + ' ')
    out = []
    last_adrp = {}
    for i, line in enumerate(lines):
        if i == 0:
            out.append(re.sub(r'^(// \S+\.s - .*?)(\.?)$',
                              lambda m: m.group(1) + ' (macOS)' + m.group(2), line))
            continue
        code, comment = split_comment(line)
        new = code
        if defines_main:
            new = re.sub(r'(?<![\w.])main\b', '_main', new)
        for f in LIBC:
            new = re.sub(r'^(\s*bl\s+)%s\b' % f, r'\1_' + f, new)
        new = re.sub(r'\b(adrp\s+\w+,\s*)([A-Za-z_][\w.]*)(?!@)\b', r'\1\2@PAGE', new)
        new = re.sub(r':lo12:([A-Za-z_][\w.]*)', r'\1@PAGEOFF', new)
        new = new.replace('.section .rodata', '.section __TEXT,__const')
        m = re.match(r'^(?:\s*\w+:)?\s*adrp\s+x(\d+),\s*(\w+)', code)
        if m:
            last_adrp[int(m.group(1))] = m.group(2)
        m = re.match(r'^(\s*)bl\s+(\w+)', code)
        if m and m.group(2) in VARIADIC:
            ind, fn = m.group(1), m.group(2)
            first = VARIADIC[fn]
            fmt = strings.get(last_adrp.get(first - 1, ''), None)
            n = conversions(fmt) if fmt is not None else 8 - first
            n = min(n, 8 - first)
            if n:
                size = (n * 8 + 15) // 16 * 16
                out.append(f'{ind}{op("sub")}sp, sp, #{size}'.ljust(32) + '// macOS: variadic arguments go on the stack')
                for k in range(n):
                    out.append(f'{ind}{op("str")}x{first + k}, [sp, #{8 * k}]')
                out.append(port_line(new, code, comment))
                out.append(f'{ind}{op("add")}sp, sp, #{size}')
                continue
        out.append(port_line(new, code, comment))
        if m:
            last_adrp.clear()
    open(dst, 'w').write('\n'.join(out))


def port_line(new, code, comment):
    if not comment:
        return new.rstrip()
    if not code.strip():
        return code + comment
    new = new.rstrip()
    return new + ' ' * max(len(code) - len(new), 1) + comment


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
