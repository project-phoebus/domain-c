#!/usr/bin/env python3
"""cc_addrcheck.py - check the image address tables in unit headers.

    tools/cc_addrcheck.py FILE.pas ...

A unit header lists `0xMMMMMM  0xAAAAAA  name' rows: the routine's address
in cc.m68k and in cc.a88k (either may be `--------' for a unit missing from
one binary).  Each is checked against the binary's .blocks for the unit
whose source file has the same name.  Exit status 1 on a mismatch.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..'))
BINS = [os.path.join(ROOT, 'ctape/install/ri.apollo.cc.v.6.9.m/cc.m68k'),
        os.path.join(ROOT, 'ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k')]


def table(path):
    out = {}
    for u in cc.Coff(path).units():
        key = (u['source'] or '').split('/')[-1]
        for nm, _, st, _ in u['blocks']:
            out.setdefault((key, nm.lower()), []).append(st)
    return out


def main():
    tabs = [table(b) for b in BINS]
    bad = 0
    for f in sys.argv[1:]:
        base = os.path.basename(f)
        for m in re.finditer(r'^\s+(0x[0-9A-F]{6}|-{8})  (0x[0-9A-F]{6}|-{8})  (\S+)',
                             open(f).read(), re.M):
            for k, t in enumerate(tabs):
                v = m.group(k + 1)
                if v.startswith('-'):
                    continue
                if int(v, 16) not in t.get((base, m.group(3).lower()), []):
                    print('%s: %s: %s not at %s in %s' % (
                        f, m.group(3), v, [hex(x) for x in t.get((base, m.group(3).lower()), [])],
                        os.path.basename(BINS[k])))
                    bad = 1
    sys.exit(bad)


if __name__ == '__main__':
    main()
