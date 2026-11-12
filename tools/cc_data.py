#!/usr/bin/env python3
"""cc_data.py - the initial bytes of a data range of a cc binary.

    tools/cc_data.py BINARY ADDR LENGTH [--width N]

.data and most named data sections hold no file bytes; the loader builds
them from .rwdi records (Coff.rwdi(); lib/pmlib/loader.pas
process_rwdi): kind 0 copies its bytes to its address; kind 2 (`zero',
the same layout) copies nothing (its records describe sections that have
file bytes: libdsc, cc.a88k's read-only tables); kind 1 repeats the
previous kind 0 or 2 record count-1 more times, end to end (copying
nothing after a kind 2 record); kind 3 is a pad.  A section with file
bytes gives them.  This prints the range asked for as hex lines (`..'
for bytes neither sets), N bytes a line (default 16).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402


def initial(coff, lo, n, origin=None):
    """The n bytes at lo (None where nothing sets one).  origin, a list
    of n, gets each byte's source: 'f' file bytes, 'c' a copy record, 'r'
    a repeat record."""
    out = [None] * n
    # the sections with file bytes
    for name, sva, sz, off, _, _ in coff.sections:
        a, b = max(lo, sva), min(lo + n, sva + sz)
        if sva and off and a < b and name not in ('.blocks', '.lines', '.rwdi'):
            out[a - lo:b - lo] = coff.data[off + a - sva:off + b - sva]
            if origin is not None:
                origin[a - lo:b - lo] = ['f'] * (b - a)
    last = None                 # (address, bytes, copies) of the record repeated
    rw = coff.section('.rwdi')
    for kind, va, addr, data in coff.rwdi():
        if kind in (0, 2):
            last = (addr, data, kind == 0)
            spans = [(addr, data)] if kind == 0 else []
            how = 'c'
        elif kind == 1 and last:
            # count.l after the kind word: the previous record's bytes
            # count-1 more times, following it (none after a kind 2)
            o = rw[3] + va - rw[1]
            count = int.from_bytes(coff.data[o + 2:o + 6], 'big')
            a0, d0, copies = last
            spans = [(a0 + len(d0) * k, d0) for k in range(1, count)] if copies else []
            last = (a0 + len(d0) * (count - 1), d0, copies)
            how = 'r'
        else:
            continue
        for a, d in spans:
            for k in range(max(lo, a), min(lo + n, a + len(d))):
                out[k - lo] = d[k - a]
                if origin is not None:
                    origin[k - lo] = how
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary')
    ap.add_argument('addr')
    ap.add_argument('length')
    ap.add_argument('--width', type=int, default=16)
    a = ap.parse_args()
    lo, n = int(a.addr, 16), int(a.length, 0)
    b = initial(cc.Coff(a.binary), lo, n)
    for o in range(0, n, a.width):
        row = b[o:o + a.width]
        print('%06X  +%04X  %s' % (lo + o, o, ' '.join('..' if x is None else '%02x' % x for x in row)))


if __name__ == '__main__':
    main()
