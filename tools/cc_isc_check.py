#!/usr/bin/env python3
"""cc_isc_check.py - compile and compare the generated ISC's units (cc.a88k).

    tools/cc_isc_check.py [--keep DIR] [--diff] [-v] FILE.pas ...
    tools/cc_isc_check.py --list

The generated ISC's action modules (the 25 pass-1 and 25 pass-2 modules,
docs/iscg-design.md 1.2) were compiled without .blocks records, so
tools/coff_compare.py cannot pick them; and the named units that lie
before anonymous code (isc_pass_1_main, isc_pass_2_main) have a last
routine that coff_compare ends at the next named routine, hundreds of KB
later (isc_pass_2_main's pass_2 at hard_work, 0x73EA4 bytes on).  This
tool reads the generator's manifest (iscg_names.txt, beside the
generated units, written by tools/iscg_gen.py):

  module<TAB>FILE<TAB>A5<TAB>START<TAB>END   an anonymous module: its
                       file (basename), its A5 (its data block; `-'
                       when no routine loads it), its code range
  unit<TAB>FILE<TAB>named                    a named unit (.blocks) whose
                       routines end at the manifest's addresses too
  NAME<TAB>ADDRESS                           an anonymous routine

and, for each FILE given (a path in the tree), compiles it as the gate
does (tools/cc_datacheck.py's compile_unit: dpc -config cc_a88k, the
gap rewrites of tools/cc_gap_rewrites.txt applied to the file and the
inserts), then compares each routine with the image through
coff_compare's library (pascal_progress.compare_object): a module's
routines at the manifest's addresses with the module's A5 as its data
base, a named unit's at its .blocks addresses, every routine ending at
the next start that .blocks or the manifest gives.  Then the data check
(tools/cc_datacheck.py's check) on the same object, a module standing
for a .blocks unit with its A5 and code start.

One line per file in tools/cc_check.sh's form (rc, errors, best-effort
count and the routines' summary), dpc's errors after it; exit status 1
when a file does not compile, a routine of the module is missing from
the object or the object has one the manifest does not name, or the
data check finds a difference.  -v prints every routine; --diff the
first differing runs of each routine that is not `same'.
"""
import argparse
import bisect
import contextlib
import io
import os
import re
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402
import cc_datacheck as dc  # noqa: E402
import pascal_progress as pp  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..'))
BINARY = os.path.join(ROOT, 'ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k')
MANIFEST = dc.ISCG_NAMES


class Manifest:
    def __init__(self, path=MANIFEST):
        self.modules = {}       # basename -> {'file', 'a5', 'start', 'end'}
        self.units = set()      # basenames of named units
        self.routines = {}      # NAME (upper) -> address
        for line in open(path):
            if line.startswith('#') or not line.strip():
                continue
            f = line.rstrip('\n').split('\t')
            if f[0] == 'module' and len(f) == 5:
                self.modules[f[1]] = {'file': f[1],
                                      'a5': None if f[2] == '-' else int(f[2], 16),
                                      'start': int(f[3], 16), 'end': int(f[4], 16)}
            elif f[0] == 'unit' and len(f) == 3:
                self.units.add(f[1])
            elif len(f) == 2:
                self.routines[f[0].upper()] = int(f[1], 16)

    def names(self, f):
        return os.path.basename(f) in self.modules or os.path.basename(f) in self.units

    def module_routines(self, mod):
        return sorted((a, n) for n, a in self.routines.items()
                      if mod['start'] <= a < mod['end'])


def fake_unit(mod, path):
    """A .blocks unit's dict (coff_compare's units()) standing for an
    anonymous module."""
    return {'offset': None, 'source': '//' + path, 'text': mod['start'], 'a5': mod['a5'],
            'code': [('.text', mod['start'], mod['a5'])], 'blocks': [], 'symbols': [],
            'version': 4, 'files': []}


def check_file(f, coff, img, man, inc, rules, keep, verbose, diff):
    """Print f's lines; True when it fails."""
    base = os.path.basename(f)
    mod = man.modules.get(base)
    if mod:
        unit = fake_unit(mod, f)
    else:
        unit = cc.pick_unit(coff, os.path.splitext(base)[0], os.path.splitext(f)[0])
    mapaddr, starts = cc.names(coff, unit if not mod else None)
    for n, a in man.routines.items():
        mapaddr.setdefault(n, a)
    starts = sorted(set(starts) | set(man.routines.values())
                    | {m['start'] for m in man.modules.values()}
                    | {m['end'] for m in man.modules.values()})

    def next_after(va):
        sec = coff.code_section_at(va) or coff.section('.text')
        end = sec[1] + sec[2]
        i = bisect.bisect_right(starts, va)
        return min(starts[i], end) if i < len(starts) else end

    work = (os.path.join(keep, os.path.splitext(f)[0].replace('/', '_') + '.cc.a88k') if keep
            else tempfile.mkdtemp(prefix='cc_isc_check.'))
    os.makedirs(work, exist_ok=True)
    try:
        err = io.StringIO()
        try:
            with contextlib.redirect_stderr(err):
                obj = compile_unit(f, inc, work, rules)
        except RuntimeError as e:
            print('%-50s %-8s rc=1 errors=%d best-effort=0  (%s)'
                  % (f, 'cc.a88k', max(1, str(e).count(': error:')), str(e).split('\n')[0]))
            for line in str(e).splitlines()[1:21]:
                print(line)
            return True
        dpc_out = err.getvalue()
        warns = dpc_out.count('best effort')
        data_base = mod['a5'] if mod else cc.data_base(coff, unit)
        linkmap = cc.CoffLinkMap(coff, mapaddr, data_base,
                                 mod['a5'] if mod else unit.get('a5'))
        res = pp.compare_object(obj, linkmap, cc.CoffImage(coff), mapaddr, next_after,
                                local_routines=True)
        count, seen = {}, set()
        lines = []
        for r in res['routines']:
            count[r['status']] = count.get(r['status'], 0) + 1
            seen.add(r['name'].upper())
            st = r['status'] + (' (%d bytes)' % r['diff'] if r.get('diff') else '')
            if r.get('similarity') is not None:
                st += ' sim %.4f' % r['similarity']
            va = mapaddr[r['name'].upper()]
            lines.append('    %-24s %-34s ours 0x%X, binary 0x%X at 0x%X'
                         % (r['name'].lower(), st, r['size'], r['map_size'] or 0, va))
            if diff and r['status'] != 'same':
                lines.append(None)
                lines.append((r['name'], va))
        bad = False
        if mod:
            want = {n for _, n in man.module_routines(mod)}
            missing = sorted(want - seen, key=lambda n: man.routines[n])
            if missing:
                lines.append('    not in our object: %s' % ', '.join(n.lower() for n in missing))
                bad = True
        else:
            missing = [n for n, _, _, _ in unit['blocks'] if n.upper() not in seen]
            if missing:
                lines.append('    not in our object: %s' % ', '.join(missing))
        order = ['same', 'same-pcrel', 'same-placement', 'differs', 'size differs']
        mean, n = pp.mean_similarity(res['routines'])
        noreg, _ = pp.mean_similarity(res['routines'], 'similarity_noreg')
        summary = '%d routine(s): %s; %s' % (sum(count.values()), ', '.join(
            '%d %s' % (count[k], k) for k in order + sorted(set(count) - set(order))
            if k in count), pp.sim_text(mean, n, noreg))
        print('%-50s %-8s rc=0 errors=0 best-effort=%d  %s' % (f, 'cc.a88k', warns, summary))
        k = 0
        while k < len(lines):
            ln = lines[k]
            if ln is None:
                if verbose or diff:
                    cc.show_diff(obj, lines[k + 1][0], lines[k + 1][1], cc.CoffImage(coff))
                k += 2
                continue
            if verbose or ln.startswith('    not in'):
                print(ln)
            k += 1
        # the data check, a module standing for its .blocks unit
        saved = dc.cc.pick_unit
        if mod:
            dc.cc.pick_unit = lambda *a, **kw: unit
        try:
            dres = dc.check(f, 'a88k', img, obj)
        finally:
            dc.cc.pick_unit = saved
        if dres is not None:
            bad = dc.report(dres, not verbose, verbose) or bad
        sys.stdout.flush()
        return bad
    finally:
        if not keep:
            shutil.rmtree(work, ignore_errors=True)


def compile_unit(f, inc, work, rules):
    """tools/cc_datacheck.py's compile_unit for cc.a88k, dpc's messages kept
    on stderr (the gate counts `: error:' and `best effort' in them)."""
    import subprocess
    src = os.path.join(ROOT, f)
    if f in rules:
        src = os.path.join(work, os.path.basename(f))
        shutil.copy(os.path.join(ROOT, f), src)
        dc.apply_rules(src, rules[f])
    s, o = os.path.join(work, 'prog.s'), os.path.join(work, 'prog.o')
    top = os.path.abspath(os.path.join(pp.ROOT, '..'))
    p = subprocess.run([pp.DPC, '--root', cc.aegis_root(), '-I', top, '-I', ROOT,
                        '-config', 'cc_a88k', '-o', s, src],
                       capture_output=True, text=True, cwd=inc)
    sys.stderr.write(p.stderr)
    if p.returncode or not os.path.exists(s):
        raise RuntimeError('dpc failed (%d)\n%s' % (p.returncode, '\n'.join(
            l for l in p.stderr.splitlines() if 'error' in l)))
    a = subprocess.run([pp.AS, '-m68020', '-o', o, s], capture_output=True, text=True)
    if a.returncode:
        raise RuntimeError('as failed\n' + a.stderr)
    return o


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('files', nargs='*')
    ap.add_argument('--keep', help='keep each compilation in DIR/PATH_OF_UNIT.cc.a88k')
    ap.add_argument('--diff', action='store_true')
    ap.add_argument('-v', action='store_true')
    ap.add_argument('--list', action='store_true', help='print the manifest\'s modules')
    a = ap.parse_args()
    os.chdir(ROOT)
    man = Manifest()
    if a.list:
        for b, m in sorted(man.modules.items(), key=lambda x: x[1]['start']):
            print('%-40s A5 %-8s 0x%06X..0x%06X %3d routine(s)%s' % (
                b, '0x%06X' % m['a5'] if m['a5'] else '-', m['start'], m['end'],
                len(man.module_routines(m)),
                '' if any(os.path.basename(f) == b for f in a.files) else ''))
        for b in sorted(man.units):
            print('%-40s (named unit)' % b)
        return
    files = [os.path.relpath(os.path.abspath(f), ROOT) for f in a.files]
    bad = False
    for f in files:
        if not man.names(f):
            print('%s: not in the manifest (%s)' % (f, os.path.relpath(MANIFEST, ROOT)))
            bad = True
    if bad:
        sys.exit(1)
    coff = cc.Coff(BINARY)
    img = dc.Image(BINARY)
    # the modules' data blocks bound the named units' (cc_datacheck's
    # block_end)
    img.bases = sorted(set(img.bases) | {m['a5'] for m in man.modules.values() if m['a5']})
    rules = dc.read_rules()
    scratch = tempfile.mkdtemp(prefix='cc_isc_check.')
    try:
        inc = dc.prepare_inc(scratch, rules)
        if a.keep:
            os.makedirs(a.keep, exist_ok=True)
        for f in files:
            try:
                bad = check_file(f, coff, img, man, inc, rules, a.keep, a.v, a.diff) or bad
            except SystemExit as e:
                print('%-50s %-8s rc=1 errors=1 best-effort=0  (%s)' % (f, 'cc.a88k', e))
                bad = True
    finally:
        shutil.rmtree(scratch, ignore_errors=True)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
