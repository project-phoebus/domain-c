#!/usr/bin/env python3
"""cc_dis.py - disassemble a routine (or an address range) of a cc binary.

    tools/cc_dis.py BINARY NAME|ADDR [LENGTH] [--unit SUBSTR] [--hex]

NAME is a .blocks routine name (the first match, or the one in the unit
whose source path contains SUBSTR); the range runs to the next routine's
start, so the routine's constants are included.  Calls through the
transfer vector are annotated with the external's name, and calls to
routines with theirs.
"""
import argparse
import bisect
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402


def hexindex(line):
    """objdump prints a plain displacement in decimal (`%fp@(12)') but an
    indexed one in hex without a prefix (`%a5@(12,%d1:l)' is 0x12, and
    `%fp@(ffffffffffffffef,%d6:l)' is -0x11).  Rewrite the indexed ones as
    explicit signed hex so they cannot be misread."""
    def fix(m):
        v = int(m.group(2), 16)
        if v >= 1 << 63:
            v -= 1 << 64
        elif v >= 1 << 31 and len(m.group(2)) == 8:
            v -= 1 << 32
        return '%s@(%s0x%x,' % (m.group(1), '-' if v < 0 else '', abs(v))
    return re.sub(r'(%[a-z0-9]+)@\(([0-9a-f]+),(?=%)', fix, line)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary')
    ap.add_argument('what')
    ap.add_argument('length', nargs='?')
    ap.add_argument('--unit')
    ap.add_argument('--hex', action='store_true', help='also dump the bytes')
    a = ap.parse_args()
    coff = cc.Coff(a.binary)
    units = coff.units()
    routines = sorted((st, ln, nm, u['source']) for u in units for nm, _, st, ln in u['blocks'])
    starts = [r[0] for r in routines]
    names = {}
    for st, ln, nm, src in routines:
        names.setdefault(st, nm)
    for va, sym, _ in coff.relocations('.aptv'):
        if sym:
            names.setdefault(va - 2, sym)
    if re.fullmatch(r'(0x)?[0-9a-fA-F]+', a.what) and not any(r[2] == a.what for r in routines):
        start = int(a.what, 16)
    else:
        hits = [r for r in routines if r[2] == a.what and (not a.unit or a.unit in (r[3] or ''))]
        if not hits:
            raise SystemExit('no routine %s' % a.what)
        start = hits[0][0]
        print('; %s in %s, code length 0x%X' % (hits[0][2], hits[0][3], hits[0][1]))
    if a.length:
        end = start + int(a.length, 0)
    else:
        i = bisect.bisect_right(starts, start)
        sec = coff.code_section_at(start)
        end = starts[i] if i < len(starts) and starts[i] < sec[1] + sec[2] else sec[1] + sec[2]
    data = cc.CoffImage(coff).read(start, end - start)
    with tempfile.NamedTemporaryFile(suffix='.bin') as f:
        f.write(data)
        f.flush()
        out = subprocess.run(['m68k-elf-objdump', '-D', '-b', 'binary', '-m', 'm68k:68020',
                              '--adjust-vma=0x%x' % start, f.name],
                             capture_output=True, text=True, check=True).stdout
    for line in out.splitlines():
        m = re.match(r'\s*([0-9a-f]+):', line)
        if not m:
            continue
        line = hexindex(line)
        t = re.search(r'(jsr|jmp|bsr\w*|pea|lea)\s.*?0x([0-9a-f]+)', line)
        if t and int(t.group(2), 16) in names:
            line += '    ; ' + names[int(t.group(2), 16)]
        print(line)


if __name__ == '__main__':
    main()
