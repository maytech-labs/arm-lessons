#!/usr/bin/env python3
"""Mechanically port a freestanding (lessons 04-15) Linux-track .s file to the
Apple track: _start -> _main, Linux syscall numbers in x8 -> BSD numbers in
x16, svc #0 -> svc #0x80, :lo12: -> @PAGEOFF, adrp sym -> sym@PAGE,
.rodata -> __TEXT,__const. Comment columns are preserved.

Always review the result: comments that mention Linux, gdb, etc. are not
rewritten.

Usage: scripts/port-to-apple.py lessons/NN-x/linux/examples/foo.s lessons/NN-x/apple-silicon/examples/foo.s
"""
import re
import sys

SYSCALLS = {'93': '1', '64': '4', '63': '3', '57': '6', '56': '5'}


def split_comment(line):
    in_str = False
    for i, c in enumerate(line):
        if c == '"' and (i == 0 or line[i - 1] != '\\'):
            in_str = not in_str
        if not in_str and line.startswith('//', i):
            return line[:i], line[i:]
    return line, ''


def port_code(code):
    m = re.match(r'^(\s*mov\s+)x8(,\s*#)(\d+)(\s*)$', code)
    if m and m.group(3) in SYSCALLS:
        code = m.group(1) + 'x16' + m.group(2) + SYSCALLS[m.group(3)] + m.group(4)
    code = re.sub(r'\bsvc(\s+)#0\b(?!x)', r'svc\1#0x80', code)
    code = code.replace('_start', '_main')
    code = re.sub(r'\b(adrp\s+\w+,\s*)([A-Za-z_][\w.]*)(?!@)\b', r'\1\2@PAGE', code)
    code = re.sub(r':lo12:([A-Za-z_][\w.]*)', r'\1@PAGEOFF', code)
    code = code.replace('.section .rodata', '.section __TEXT,__const')
    return code


def port_comment(comment, code):
    m = re.match(r'^\s*mov\s+x8,\s*#(\d+)', code)
    if m and m.group(1) in SYSCALLS:
        comment = re.sub(r'\b%s\b' % m.group(1), SYSCALLS[m.group(1)], comment)
        comment = comment.replace('x8', 'x16').replace('Linux', 'macOS')
    return comment.replace('system call x8', 'system call x16').replace('_start', '_main')


def main(src, dst):
    out = []
    for i, line in enumerate(open(src)):
        line = line.rstrip('\n')
        if i == 0:
            out.append(re.sub(r'^(// \S+\.s - .*?)(\.?)$',
                              lambda m: m.group(1) + ' (macOS)' + m.group(2), line))
            continue
        code, comment = split_comment(line)
        if not comment:
            out.append(port_code(code).rstrip())
        elif not code.strip():
            out.append(code + port_comment(comment, ''))
        else:
            new = port_code(code).rstrip()
            out.append(new + ' ' * max(len(code) - len(new), 1) + port_comment(comment, code))
    open(dst, 'w').write('\n'.join(out) + '\n')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
