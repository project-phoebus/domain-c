#!/usr/bin/env python3
"""cc_data.py - the initial bytes of a .data range of a cc binary.

    tools/cc_data.py BINARY ADDR LENGTH [--width N]

.data and the named data sections hold no file bytes; the loader builds
them from .rwdi records (Coff.rwdi(): kind 0 copies bytes to an address,
kind 1 repeats the previous record).  This applies the records to the
range asked for and prints it as hex lines (`..' for bytes no record
sets), N bytes a line (default 16).
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402


def initial(coff, lo, n):
    out = [None] * n
    last = None
    for kind, _, addr, data in coff.rwdi():
        if kind == 0:
            last = (addr, data)
            spans = [(addr, data)]
        elif kind == 1 and last:
            spans = []      # repeat counts are rare; not applied here
        else:
            continue
        for a, d in spans:
            for k in range(max(lo, a), min(lo + n, a + len(d))):
                out[k - lo] = d[k - a]
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
