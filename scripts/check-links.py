#!/usr/bin/env python3
"""Check that every relative link in the repo's markdown files points to a file
or directory that exists. Exits non-zero if any link is broken.

Usage: scripts/check-links.py
"""
import os
import re
import subprocess
import sys

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
files = subprocess.check_output(['git', 'ls-files', '*.md'], cwd=repo).decode().split()
broken = 0
total = 0
for f in files:
    text = open(os.path.join(repo, f)).read()
    text = re.sub(r'```.*?```', '', text, flags=re.S)       # ignore code blocks
    for target in re.findall(r'\]\(([^)\s]+)\)', text):
        if re.match(r'^[a-z]+:', target) or target.startswith('#'):
            continue
        total += 1
        path = os.path.normpath(os.path.join(repo, os.path.dirname(f), target.split('#')[0]))
        if not os.path.exists(path):
            broken += 1
            print(f'{f}: broken link {target}')
print(f'{total} links checked, {broken} broken')
sys.exit(1 if broken else 0)
