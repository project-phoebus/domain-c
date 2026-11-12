#!/usr/bin/env python3
"""cc_enumnames.py - the enumeration name tables of a cc binary.

    tools/cc_enumnames.py BINARY                    (list every table)
    tools/cc_enumnames.py BINARY ADDR [--pascal]    (one table's names)

Domain Pascal compiles `write' of an enumerated value with a table of
the type's identifiers in the code section after the routine's
constants: a count word, then each identifier, upper case, as a
length byte and its characters, in ordinal order.  The identifiers are
the source's, so a type written by some routine of the binary has its
element names here (the PRISM opcodes, OPC$..., in isc_to_lir's
end_statement; the IL node kinds in add_node and the ISC's printers).

The scan looks at every even address of the code sections for a count
2..2000 followed by that many identifiers ([A-Z_][A-Z0-9_$]*).  ADDR is
the table's address (its count word) as the listing prints it.
--pascal prints the names in lower case, comma separated, as a
declaration's element list.
"""
import argparse
import bisect
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402

IDENT = re.compile(rb'^[A-Z_][A-Z0-9_$]*$')


def table_at(d, o):
    """The names of the table at offset o of d, or None."""
    n = struct.unpack('>H', d[o:o + 2])[0]
    if not 2 <= n <= 2000:
        return None, o
    p, names = o + 2, []
    for _ in range(n):
        if p >= len(d):
            return None, o
        ln = d[p]
        nm = d[p + 1:p + 1 + ln]
        if ln == 0 or not IDENT.match(nm):
            return None, o
        names.append(nm.decode())
        p += 1 + ln
    return names, p


def code_sections(coff):
    for s in coff.sections:
        if coff.section_flags.get(s[0], 0) & 0x20 and s[3] and s[0] != '.unwind':
            yield s


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary')
    ap.add_argument('addr', nargs='?')
    ap.add_argument('--pascal', action='store_true')
    a = ap.parse_args()
    coff = cc.Coff(a.binary)
    if a.addr:
        va = int(a.addr, 16)
        for s in code_sections(coff):
            if s[1] <= va < s[1] + s[2]:
                d = coff.data[s[3]:s[3] + s[2]]
                names, _ = table_at(d, va - s[1])
                if names is None:
                    raise SystemExit('no name table at 0x%X' % va)
                if a.pascal:
                    print(',\n'.join('    %s' % n.lower() for n in names))
                else:
                    for k, n in enumerate(names):
                        print('%4d  %s' % (k, n))
                return
        raise SystemExit('0x%X is in no code section' % va)
    routines = sorted((st, nm) for u in coff.units() for nm, _, st, _ in u['blocks'])
    starts = [r[0] for r in routines]
    for s in code_sections(coff):
        d = coff.data[s[3]:s[3] + s[2]]
        o = 0
        while o < len(d) - 4:
            names, p = table_at(d, o)
            if names:
                va = s[1] + o
                i = bisect.bisect_right(starts, va) - 1
                print('0x%06X %4d names (in %s): %s' % (
                    va, len(names), routines[i][1] if i >= 0 else '?',
                    ' '.join(names[:6]) + (' ...' if len(names) > 6 else '')))
                o = (p + 1) & ~1
            else:
                o += 2


if __name__ == '__main__':
    main()
