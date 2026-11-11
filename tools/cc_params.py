#!/usr/bin/env python3
"""cc_params.py - evidence for routine headings in a cc binary.

    tools/cc_params.py BINARY UNIT-SUBSTR [--calls N]

For each routine of the unit whose source path contains UNIT-SUBSTR: its
address and length, whether it loads A5 (global) or not (internal or
nested), whether it reads its static link ((A6) into an address register:
nested), the positive frame offsets it uses with the instructions that use
them (`a' moved to an address register: a by-address parameter, or a
pointer value; `b'/`w'/`l' a value of that width; `p' its address taken by
pea/lea: a by-value parameter passed on by address), whether it sets D0 or
A0 before returning (a function), and up to N call sites (default 2) with
the pushes before the call.

Uses tools/cc_globals.py's disassembly cache.
"""
import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402
import cc_globals  # noqa: E402

FRAME = re.compile(r'%fp@\((\d+)\)')


def kind(text):
    op = text.split()[0]
    if op in ('pea', 'lea'):
        return 'p'
    if op.startswith('moveal') or op.startswith('cmpal') or op.startswith('addal'):
        return 'a'
    if op[-1:] in 'bwl':
        return op[-1]
    return '?'


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary')
    ap.add_argument('unit')
    ap.add_argument('--calls', type=int, default=2)
    a = ap.parse_args()
    coff = cc.Coff(a.binary)
    units, rows = cc_globals.disassemble(coff, a.binary)
    by_routine = collections.defaultdict(list)
    for st, ui, nm, addr, text in rows:
        by_routine[st].append((ui, nm, addr, text))
    starts = {}
    for st, insns in by_routine.items():
        starts[st] = insns[0][1]
    calls = collections.defaultdict(list)
    for st, insns in by_routine.items():
        for i, (ui, nm, addr, text) in enumerate(insns):
            m = re.match(r'(jsr|bsr\w*)\s+0x([0-9a-f]+)', text)
            if m:
                after = [t for _, _, _, t in insns[i + 1:i + 3]]
                calls[int(m.group(2), 16)].append((nm, addr, [t for _, _, _, t in insns[max(0, i - 8):i]], after))
    for ui, u in enumerate(units):
        if a.unit not in (u['source'] or ''):
            continue
        print('# %s' % u['source'])
        for nm, lv, st, ln in sorted(u['blocks'], key=lambda b: b[2]):
            insns = by_routine.get(st, [])
            texts = [t for _, _, _, t in insns]
            a5 = any(re.match(r'lea 0x[0-9a-f]+,%a5', t) for t in texts[:8])
            nested = any(re.match(r'moveal %fp@,%a\d', t) for t in texts)
            offs = collections.defaultdict(set)
            for t in texts:
                for m in FRAME.finditer(t):
                    offs[int(m.group(1))].add(kind(t))
            ret = ''
            for t in reversed(texts[-12:]):
                if re.search(r',%d0$', t) or re.search(r',%a0$', t) or t.startswith(('moveq', 'clrw %d0', 'clrl %d0', 'clrb %d0', 'st %d0')):
                    ret = 'sets ' + ('A0' if t.endswith('%a0') else 'D0')
                    break
            print('\n%-32s 0x%06X 0x%-5X level %d  %s%s  %s' % (
                nm, st, ln, lv, 'A5' if a5 else 'no-A5', ' nested' if nested else '', ret))
            print('    frame: ' + '  '.join('%d:%s' % (o, ''.join(sorted(k))) for o, k in sorted(offs.items())))
            cs = calls.get(st, [])
            uses = collections.Counter()
            for _, _, _, after in cs:
                txt = ' '.join(after)
                # the result register read after the call (stack pops aside)
                for reg in ('%d0', '%a0'):
                    if re.search(reg + r'(?![0-9])', re.sub(r'(addqw|addql|lea) [^;]*%sp[^ ]*', '', txt)):
                        uses[reg] += 1
            print('    %d call sites; result read after: D0 %d, A0 %d' % (len(cs), uses['%d0'], uses['%a0']))
            for cn, caddr, pre, after in cs[:a.calls]:
                print('    call from %s 0x%x: %s  ||  %s' % (cn, caddr, ' ; '.join(pre[-6:]), ' ; '.join(after)))


if __name__ == '__main__':
    main()
