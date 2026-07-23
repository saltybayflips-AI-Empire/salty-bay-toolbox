"""Advisory linter for the bug class that killed the Comp Tool launcher on
7/23/26: an unescaped ( or ) inside a parenthesized IF/FOR block. cmd.exe
parses the whole block before running it, so one bare paren - even in a
comment - aborts the entire script with 'X was unexpected at this time'
before it can print anything. The window flashes and closes.

Also flags non-ASCII bytes, which render as garbage on another codepage.

This is the EARLY WARNING. The real gate is the smoke test that actually
executes each launcher and asserts it does not die.

Usage:  python bat_paren_audit.py <folder> [<folder> ...]
Exit 1 if anything is found.
"""
import sys, os, glob

def depth_delta(line):
    """Block depth change. cmd only enters block mode when an IF/FOR/ELSE
    line ends in '(' - a stray paren in a top-level ECHO or REM does not open
    one. Getting this right is what stops the linter crying wolf on every
    parenthesis in a banner."""
    s = line.strip().replace('^(', '').replace('^)', '')
    low = s.lower()
    if low.startswith('rem') or low.startswith('::'):
        return 0
    if s in (')', ')else(', ') else ('):
        return 0 if 'else' in low else -1
    opener = (low.startswith('if ') or low.startswith('for ')
              or low.startswith('else ') or low.startswith(') else '))
    if opener and s.endswith('('):
        return 1
    return 0

def scan(path):
    hits = []
    text = open(path, 'rb').read().decode('utf-8', errors='replace')
    depth = 0
    for i, raw in enumerate(text.splitlines(), 1):
        s = raw.strip()
        low = s.lower()
        try:
            raw.encode('ascii')
        except UnicodeEncodeError:
            bad = ''.join(sorted({c for c in raw if ord(c) > 127}))
            hits.append((i, 'NON-ASCII', f'{bad!r} in: {s[:70]}'))
        is_comment_or_echo = (low.startswith('rem') or low.startswith('echo')
                              or low.startswith('::'))
        if depth > 0 and is_comment_or_echo:
            stripped = s.replace('^(', '').replace('^)', '')
            if '(' in stripped or ')' in stripped:
                hits.append((i, 'PAREN-IN-BLOCK', f'depth {depth}: {s[:85]}'))
        depth = max(0, depth + depth_delta(raw))
    return hits

total = 0
for root in sys.argv[1:]:
    for path in sorted(glob.glob(os.path.join(root, '**', '*.bat'), recursive=True)):
        if os.sep + '.git' + os.sep in path:
            continue
        hits = scan(path)
        if hits:
            print(f'\n=== {path}')
            for line, kind, msg in hits:
                print(f'  L{line:<4} {kind:<15} {msg}')
                total += 1
print(f'\nTOTAL FINDINGS: {total}')
sys.exit(1 if total else 0)
