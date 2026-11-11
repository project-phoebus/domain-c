#!/usr/bin/env python3
"""cc_globals.py - catalogue the absolute references into .data of a cc binary.

    tools/cc_globals.py BINARY [--unit SUBSTR] [--min-units N] [--refs]

A Domain Pascal module's own variables are reached through its A5; a
variable another unit `define's is reached absolutely (`lea abs.l', `move
abs.l', `pea abs.l', ...).  The .data section holds every unit's data block
back to back, so each absolutely referenced address belongs to the unit whose
block (its A5 up to the next unit's A5) contains it: the unit that defines
it.  For each such cell this prints the owning unit, the offset from its A5,
the access widths seen (b/w/l from the instruction's size; `a' an address
taken by lea/pea/movea #; `P' loaded into an address register: a pointer) and the units and routines that reference it.

The disassembly of every routine (m68k-elf-objdump) is cached under
$TMPDIR/cc_globals.<binary>.<size>.txt.
"""
import argparse
import bisect
import collections
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402


def disassemble(coff, path):
    """[(routine start, unit index, routine name, address, text)] for every
    instruction of every .blocks routine (cached)."""
    cache = os.path.join(tempfile.gettempdir(), 'cc_globals.%s.%d.txt' % (
        os.path.basename(path), os.path.getsize(path)))
    units = coff.units()
    routines = sorted((st, ln, nm, ui) for ui, u in enumerate(units)
                      for nm, _, st, ln in u['blocks'])
    if not os.path.exists(cache):
        img = cc.CoffImage(coff)
        with open(cache + '.tmp', 'w') as out:
            for st, ln, nm, ui in routines:
                data = img.read(st, ln)
                with tempfile.NamedTemporaryFile(suffix='.bin') as f:
                    f.write(data)
                    f.flush()
                    dis = subprocess.run(
                        ['m68k-elf-objdump', '-D', '-b', 'binary', '-m', 'm68k:68020',
                         '--adjust-vma=0x%x' % st, f.name],
                        capture_output=True, text=True, check=True).stdout
                for line in dis.splitlines():
                    m = re.match(r'\s*([0-9a-f]+):\s+(?:[0-9a-f]{4} ?)+\s+(.*)$', line)
                    if m:
                        out.write('%x\t%d\t%s\t%s\t%s\n' % (st, ui, nm, m.group(1), m.group(2)))
        os.rename(cache + '.tmp', cache)
    rows = []
    with open(cache) as f:
        for line in f:
            st, ui, nm, addr, text = line.rstrip('\n').split('\t', 4)
            rows.append((int(st, 16), int(ui), nm, int(addr, 16), text))
    return units, rows


SIZE = {'b': 'b', 'w': 'w', 'l': 'l'}


def width(text):
    """The access width of an instruction's absolute operand."""
    op = text.split()[0] if text.split() else ''
    if op in ('lea', 'pea') or text.startswith('moveal #') or text.startswith('movel #'):
        return 'a'
    if op.startswith(('bset', 'bclr', 'btst', 'bchg', 'st', 'sf', 'sne', 'seq')) and not op.startswith('sub'):
        return 'b'
    if re.match(r'moveal 0x[0-9a-f]+,%a\d', text):
        return 'P'                      # loaded into an address register
    if op[-1:] in SIZE and op not in ('bsr', 'bra'):
        return SIZE[op[-1]]
    return '?'


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary')
    ap.add_argument('--unit', help='only cells owned by the unit whose path contains this')
    ap.add_argument('--min-units', type=int, default=1,
                    help='only cells referenced from at least N units (default 1)')
    ap.add_argument('--refs', action='store_true', help='list each referencing routine')
    a = ap.parse_args()
    coff = cc.Coff(a.binary)
    units, rows = disassemble(coff, a.binary)
    # .data and the other data sections (opt$data, codegen$data, ...):
    # those with no file contents (their initial bytes come from .rwdi).
    ranges = [(sec[1], sec[1] + sec[2]) for sec in coff.sections
              if sec[3] == 0 and sec[1] != 0]
    lo = min(r[0] for r in ranges)
    a5s = sorted({u['a5'] for u in units if u['a5']})
    owner = {}
    for ui, u in enumerate(units):
        if u['a5']:
            owner.setdefault(u['a5'], []).append(ui)
    cells = collections.defaultdict(lambda: {'w': set(), 'units': set(), 'routines': set()})
    for st, ui, nm, addr, text in rows:
        vals = [int(m.group(1), 16) for m in re.finditer(r'0x([0-9a-f]{5,8})\b', text)]
        # objdump prints a `movea.l #abs' / `move.l #abs' in decimal
        vals += [int(m.group(1)) for m in re.finditer(r'#(\d{6,8})\b', text)]
        for v in vals:
            if any(a <= v < b for a, b in ranges) and '%pc' not in text:
                c = cells[v]
                c['w'].add(width(text))
                c['units'].add(ui)
                c['routines'].add((nm, addr))
    by_owner = collections.defaultdict(list)
    for v in sorted(cells):
        i = bisect.bisect_right(a5s, v) - 1
        base = a5s[i] if i >= 0 else lo
        by_owner[base].append(v)
    for base in sorted(by_owner):
        names = ', '.join(units[ui]['source'].split('/')[-1] for ui in owner.get(base, [])) or '(before the first A5)'
        if a.unit and not any(a.unit in (units[ui]['source'] or '') for ui in owner.get(base, [])):
            continue
        vs = [v for v in by_owner[base] if len(cells[v]['units']) >= a.min_units]
        if not vs:
            continue
        print('## A5 0x%06X  %s  (%d cells)' % (base, names, len(vs)))
        for v in vs:
            c = cells[v]
            us = sorted({units[ui]['source'].split('/')[-1].replace('.pas', '') for ui in c['units']})
            print('  0x%06X  +0x%-5X %-6s %3d units  %s' % (
                v, v - base, ''.join(sorted(c['w'])), len(us),
                ' '.join(us[:8]) + (' ...' if len(us) > 8 else '')))
            if a.refs:
                for nm, addr in sorted(c['routines'], key=lambda r: r[1]):
                    print('              %06x %s' % (addr, nm))


if __name__ == '__main__':
    main()
