#!/usr/bin/env python3
"""Generate the mdBook source for the course website, then (optionally) build it.

The lessons stay where they are; this script copies the markdown into
build/book/src/ in book order, writes SUMMARY.md from docs/curriculum.md, and
rewrites links:

- links to markdown that is part of the book point to its page in the book
  (README.md files become index.md, which mdBook serves as index.html);
- links to anything else (programs, Makefiles, directories, repo-only docs)
  point to the file on GitHub.

Usage:
    scripts/build-book.py            # write build/book/ (book.toml + src/)
    scripts/build-book.py --build    # ...and run `mdbook build` there

The site is written to build/book/html/.
"""
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'build', 'book')
SRC = os.path.join(OUT, 'src')
GITHUB = 'https://github.com/maytech-labs/arm-lessons'

BOOK_TOML = f'''[book]
title = "ARM64 Assembly, from Zero to C"
description = "A slow, thorough, hands-on course in AArch64 assembly for Linux and Apple Silicon."
language = "en"
src = "src"

[build]
build-dir = "html"
create-missing = false

[output.html]
git-repository-url = "{GITHUB}"
git-repository-icon = "fa-github"
'''

# Repo docs that become book pages: (repo path, title), in order.
FRONT = [('README.md', 'Introduction')]
GUIDE = [
    ('docs/curriculum.md', 'Curriculum'),
    ('docs/toolchain.md', 'Toolchain'),
    ('docs/platform-differences.md', 'Linux vs Apple Silicon'),
    ('docs/apple-silicon.md', 'The Apple Silicon flavor'),
]
REFERENCE = [
    ('docs/reference/aarch64-cheatsheet.md', 'AArch64 cheat sheet'),
    ('docs/glossary.md', 'Glossary'),
    ('docs/reference/further-reading.md', 'Further reading'),
    ('docs/lesson-style-guide.md', 'How lessons are written'),
]


def book_path(repo_path):
    """Where a repo markdown file lives inside the book."""
    d, f = os.path.split(repo_path)
    if f == 'README.md':
        f = 'index.md'
    return os.path.join(d, f) if d else f


def lessons():
    """(part title, [(slug, title)]) from docs/curriculum.md."""
    parts = []
    for line in open(os.path.join(REPO, 'docs/curriculum.md')):
        m = re.match(r'^## (Part .*)$', line)
        if m:
            parts.append((m.group(1), []))
        m = re.match(r'^\| \d\d \| `(\d\d-[\w-]+)` \|', line)
        if m and parts:
            slug = m.group(1)
            first = open(os.path.join(REPO, 'lessons', slug, 'README.md')).readline()
            title = re.sub(r'^#\s*', '', first).strip()
            parts[-1][1].append((slug, title))
    return parts


def all_pages():
    pages = list(FRONT) + GUIDE + REFERENCE
    for _, items in lessons():
        for slug, title in items:
            base = f'lessons/{slug}'
            for name, t in (('README.md', title), ('apple-silicon/README.md', 'On Apple Silicon'),
                            ('exercises.md', 'Exercises'), ('answers.md', 'Answers')):
                if os.path.exists(os.path.join(REPO, base, name)):
                    pages.append((f'{base}/{name}', t))
    decisions = sorted(f for f in os.listdir(os.path.join(REPO, 'docs/decisions'))
                       if f.endswith('.md') and f[0].isdigit() and not f.startswith('0000'))
    pages.append(('docs/decisions/README.md', 'Decision records'))
    pages += [(f'docs/decisions/{f}', f[:-3]) for f in decisions]
    return pages


LINK = re.compile(r'(\]\()([^)\s]+)(\))')


def rewrite(repo_path, text, in_book):
    here = os.path.dirname(repo_path)
    out_dir = os.path.dirname(book_path(repo_path))

    def fix(m):
        target = m.group(2)
        if re.match(r'^[a-z]+:', target) or target.startswith('#'):
            return m.group(0)
        path, sep, anchor = target.partition('#')
        resolved = os.path.normpath(os.path.join(here, path))
        if resolved.startswith('..'):
            return m.group(0)
        if resolved in in_book:
            new = os.path.relpath(book_path(resolved), out_dir or '.')
        else:
            kind = 'tree' if os.path.isdir(os.path.join(REPO, resolved)) else 'blob'
            new = f'{GITHUB}/{kind}/main/{resolved}'
        return m.group(1) + new + (sep + anchor if sep else '') + m.group(3)

    return LINK.sub(fix, text)


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    os.makedirs(SRC)
    open(os.path.join(OUT, 'book.toml'), 'w').write(BOOK_TOML)
    pages = all_pages()
    in_book = {p for p, _ in pages}
    for repo_path, _ in pages:
        text = open(os.path.join(REPO, repo_path)).read()
        dst = os.path.join(SRC, book_path(repo_path))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'w').write(rewrite(repo_path, text, in_book))

    s = ['# Summary', '', f'[Introduction]({book_path("README.md")})', '', '# Getting started', '']
    s += [f'- [{t}]({book_path(p)})' for p, t in GUIDE]
    for part, items in lessons():
        s += ['', f'# {part}', '']
        for slug, title in items:
            base = f'lessons/{slug}'
            s.append(f'- [{title}]({book_path(base + "/README.md")})')
            for name, t in (('apple-silicon/README.md', 'On Apple Silicon'),
                            ('exercises.md', 'Exercises'), ('answers.md', 'Answers')):
                if f'{base}/{name}' in in_book:
                    s.append(f'  - [{t}]({book_path(base + "/" + name)})')
    s += ['', '# Reference', '']
    s += [f'- [{t}]({book_path(p)})' for p, t in REFERENCE]
    s.append(f'- [Decision records]({book_path("docs/decisions/README.md")})')
    s += [f'  - [{t}]({book_path(p)})' for p, t in pages if p.startswith('docs/decisions/0')]
    open(os.path.join(SRC, 'SUMMARY.md'), 'w').write('\n'.join(s) + '\n')
    print(f'wrote {len(pages)} pages to {os.path.relpath(SRC, REPO)}')

    if '--build' in sys.argv:
        subprocess.check_call(['mdbook', 'build'], cwd=OUT)
        print(f'site in {os.path.relpath(os.path.join(OUT, "html"), REPO)}')


if __name__ == '__main__':
    main()
