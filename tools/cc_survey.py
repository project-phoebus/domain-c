#!/usr/bin/env python3
"""cc_survey.py - survey the Domain C 6.9 compiler binaries for translation.

    tools/cc_survey.py [--units] [--routines] [--includes] [--compare] BINARY...

Reads each Apollo m68k COFF binary's .blocks (through coff_compare.Coff,
patched here for .blocks version 4) and prints, per compilation unit, its
source path, language, routine count, code start, A5, code bytes (the
routines' own lengths) and span (to the next unit's code start, so with the
constants that follow its routines).  --routines adds each unit's routines,
--includes each unit's inserts in the order the compiler opened them (the
.blocks list reversed: it holds them newest first),
--compare (with two binaries) which units the two share and whether their
routines have the same names and lengths.
"""
import argparse
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402

LANG = {'.pas': 'pas', '.c': 'c', '.ftn': 'ftn', '.asm': 'asm', '.s': 'asm'}


def lang_of(path):
    return LANG.get(os.path.splitext(path or '')[1], '?')


def local_path(path):
    """//foo/bar/baz.pas -> foo/bar/baz.pas (the tree is rooted at '.')."""
    return path[2:] if path and path.startswith('//') else path


def makers(coff):
    """The .mir maker names (the COFF form: kind.w, size.w, 6 bytes, a
    string table offset.l)."""
    d = coff.data
    symptr, nsyms = struct.unpack('>II', d[8:16])
    strtab = symptr + 18 * nsyms
    m = coff.contents('.mir')
    out = []
    if not m:
        return out
    n, o = struct.unpack('>I', m[:4])[0], 4
    for _ in range(n):
        kind, size = struct.unpack('>HH', m[o:o + 4])
        off = struct.unpack('>I', m[o + size - 4:o + size])[0]
        out.append((kind, d[strtab + off:d.index(b'\0', strtab + off)].decode('latin1')))
        o += size
    return out


def survey(path):
    coff = cc.Coff(path)
    units = coff.units()
    text = coff.section('.text')
    starts = sorted({u['text'] for u in units if u['text']} | {text[1] + text[2]})
    rows = []
    for u in units:
        nxt = next((s for s in starts if u['text'] is not None and s > u['text']), None)
        rows.append({
            'source': u['source'], 'lang': lang_of(u['source']),
            'routines': len(u['blocks']), 'text': u['text'], 'a5': u['a5'],
            'code': sum(b[3] for b in u['blocks']),
            'span': (nxt - u['text']) if (nxt and u['text']) else 0,
            'blocks': u['blocks'], 'files': u.get('files', []),
        })
    return coff, rows


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('binary', nargs='+')
    ap.add_argument('--units', action='store_true', default=True)
    ap.add_argument('--routines', action='store_true')
    ap.add_argument('--includes', action='store_true')
    ap.add_argument('--compare', action='store_true')
    a = ap.parse_args()
    results = []
    for path in a.binary:
        coff, rows = survey(path)
        results.append((path, rows))
        print('## %s\n' % os.path.basename(path))
        for kind, name in makers(coff):
            print('- maker: %s%s' % (name, '' if kind == 1 else ' (program)'))
        langs = {}
        for r in rows:
            langs[r['lang']] = langs.get(r['lang'], 0) + 1
        print('- units: %d (%s); routines: %d; routine bytes: %d\n' % (
            len(rows), ', '.join('%s %d' % kv for kv in sorted(langs.items())),
            sum(r['routines'] for r in rows), sum(r['code'] for r in rows)))
        print('| # | file | lang | routines | code start | A5 | routine bytes | span |')
        print('|---|------|------|----------|------------|----|---------------|------|')
        for i, r in enumerate(rows):
            print('| %d | `%s` | %s | %d | %s | %s | %d | %d |' % (
                i, local_path(r['source']), r['lang'], r['routines'],
                '0x%06X' % r['text'] if r['text'] else '-',
                '0x%06X' % r['a5'] if r['a5'] else '-', r['code'], r['span']))
        print()
        if a.routines or a.includes:
            for r in rows:
                print('### `%s`\n' % local_path(r['source']))
                if a.includes:
                    for f in reversed(r['files'][:-1]):
                        print('- include `%s`' % f)
                    print()
                if a.routines:
                    for name, level, start, length in r['blocks']:
                        print('    %-40s 0x%06X 0x%-6X level %d' % (name, start, length, level))
                    print()
    if a.compare and len(results) == 2:
        (pa, ra), (pb, rb) = results
        ia = {r['source']: r for r in ra}
        ib = {r['source']: r for r in rb}
        print('## shared units: %s vs %s\n' % (os.path.basename(pa), os.path.basename(pb)))
        print('| file | routines a | routines b | same names | same lengths |')
        print('|------|------------|------------|------------|--------------|')
        for src in [r['source'] for r in ra if r['source'] in ib]:
            x, y = ia[src], ib[src]
            na = [(b[0], b[3]) for b in x['blocks']]
            nb = [(b[0], b[3]) for b in y['blocks']]
            print('| `%s` | %d | %d | %s | %s |' % (
                local_path(src), len(na), len(nb),
                'yes' if [n for n, _ in na] == [n for n, _ in nb] else 'no',
                'yes' if na == nb else 'no'))
        print('\nonly in %s: %s\n' % (os.path.basename(pa),
              ', '.join('`%s`' % local_path(s) for s in ia if s not in ib)))
        print('only in %s: %s\n' % (os.path.basename(pb),
              ', '.join('`%s`' % local_path(s) for s in ib if s not in ia)))


if __name__ == '__main__':
    main()
