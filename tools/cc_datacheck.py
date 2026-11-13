#!/usr/bin/env python3
"""cc_datacheck.py - compare units' initialized data with the image's.

    tools/cc_datacheck.py [--binary m68k|a88k] [-j N] [--keep DIR [--reuse]]
                          [-q | -v] [FILE.pas|FILE.asm ...]
                          (default: every unit file the gate checks, and
                          the assembly units under lang/)
    tools/cc_datacheck.py [-q | -v] --objects LIST
                          (tools/cc_check.sh's last pass: the objects it
                          compiled, FILE<TAB>m68k|a88k<TAB>OBJECT a line)

tools/cc_check.sh compares code only.  This compiles each unit as the
gate does (the dpc-gap rewrites of tools/cc_gap_rewrites.txt applied to
scratch copies, -config cc_a88k for cc.a88k), takes the object's
initialized data, and compares it byte for byte with the image's initial
bytes for the same unit:

- the module's own data (dpc's `.moddata.M', `.bss.moddata.M', with or
  without a section suffix) against the unit's data block in the image,
  from its A5 (the extern-address cells right below it are the
  loader's; a unit with no code, opinfo, from its .blocks data cell) to
  the next unit's block.  dpc's .moddata starts with its header cells
  when it has any (far constants' addresses, read below A5; the code
  loads A5 as `lea (.Ldata).l,%a5', the section plus their size): they
  are left out, and the section compared from .Ldata on;
- each named section the unit defines (dpc's `.data.overlay.S': a `var
  (s)' block with an initializer) against the image's section S, from
  its start (a named section is an overlay: every unit that declares it
  sees the same storage).  The gate's gap-32 rename (`S_S') is undone.
  A section dpc leaves undefined (a `.comm') is not this unit's.
- an assembly unit (.asm): assembled with m68k-elf-as, its .text against
  the unit's code in the image.

The image's bytes: a section with file bytes (cc.a88k's read-only
tables) gives them; .data and the other loader-built sections take them
from the .rwdi records (tools/cc_data.py's initial(), repeat records
applied).  A byte no record sets is don't-care.  A relocated field of
dpc's data (a pointer) is compared as the address its target has in the
image (a routine's, the unit's data block's, a section's); a field whose
target has no known image address (another unit's cell) is not compared
and is counted as unverified.

Each difference is printed as one line per run of differing bytes (runs
three or fewer bytes apart joined), its offset the image's in the block:

    UNIT BINARY SECTION +OFFSET (SYMBOL+K) [N bytes, KIND]: dpc XX .. | image YY ..

KIND is `data', `past dpc's data' (set bytes of the image's block past
the end of dpc's), `layout: ...' or `known (...)'; `set by a repeat
record' marks bytes a .rwdi repeat record sets (the bytes the old
cc_data.py showed unset: docs/questions.md 238).  A summary line follows
per unit and binary.  A pointer to another unit's cell is resolved by
that cell's place in its unit's comments (Image.cells()).

Layout: dpc lays a module's own cells out after (or before) its defined
ones, aligns them its own way, and gives each byte variable two bytes
where the image packs them (dpc gap 37).  When the block as dpc lays it
out differs from the image's, two other layouts are tried and the one
leaving the fewest differences kept (reported as `laid out otherwise'):
by name (a defined cell, which dpc names, placed where the unit's
comments put it: `name (+0x300', `name; { +0x13C }', `0x2CE8D8  name',
or a name ending in its offset, `lir_main_c89'; the ranges between
named cells follow) and by content (difflib's alignment of the two
blocks, gaps allowed).  A run whose bytes are the other side's one or two
bytes away, or at another differing offset of the block, is reported as
layout too.  A run tools/cc_datacheck_known.txt lists (checked by hand:
layout the alignment misses, a logged dpc gap) is `known'.  Neither
fails.

Exit status 1 when a data difference (not a layout one) is found.
"""
import argparse
import concurrent.futures
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402
import cc_data  # noqa: E402
import pascal_progress as pp  # noqa: E402
import rfc_elf  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..'))
BINS = {'m68k': os.path.join(ROOT, 'ctape/install/ri.apollo.cc.v.6.9.m/cc.m68k'),
        'a88k': os.path.join(ROOT, 'ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k')}
SRC_ROOTS = ['lang', 'lang2', 'ivory', 'us', 'us1', 'moon_unit', 'misc_server']
RULES = os.path.join(HERE, 'cc_gap_rewrites.txt')
KNOWN = os.path.join(HERE, 'cc_datacheck_known.txt')
ISCG_NAMES = os.path.join(ROOT, 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/'
                          'iscg_input/iscg_names.txt')

MODDATA_RE = re.compile(r'^(?:\.bss|\.data)?\.moddata\.(?P<module>[^.]+)(?:\.(?P<section>.+))?$')
OVERLAY_RE = re.compile(r'^\.data\.overlay\.(?P<section>.+)$')
SHF_WRITE = 1


# ---------------------------------------------------------------------------
# The gate's scratch copies and compilation (tools/cc_check.sh)
# ---------------------------------------------------------------------------

def read_rules():
    out = {}
    with open(RULES) as f:
        for line in f:
            line = line.rstrip('\n')
            if not line or line.startswith('#') or '\t' not in line:
                continue
            path, rule = line.split('\t', 1)
            out.setdefault(path, []).append(rule)
    return out


def apply_rules(path, rules):
    for r in rules:
        subprocess.run(['perl', '-pi', '-e', r, path], check=True)


def prepare_inc(scratch, rules):
    """The rewritten inserts at their tree paths under scratch/inc, which
    every compilation runs in (dpc looks an include up in its working
    directory first)."""
    inc = os.path.join(scratch, 'inc')
    os.makedirs(inc, exist_ok=True)
    for path, rs in sorted(rules.items()):
        if not re.search(r'\.(ins|pvt)\.pas$', path):
            continue
        dst = os.path.join(inc, path)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy(os.path.join(ROOT, path), dst)
        apply_rules(dst, rs)
    return inc


def compile_unit(f, binkey, inc, work, rules):
    """The unit's object, compiled as the gate compiles it."""
    os.makedirs(work, exist_ok=True)
    if f.endswith('.asm'):
        o = os.path.join(work, 'prog.o')
        p = subprocess.run([pp.AS, '-m68020', '-o', o, os.path.join(ROOT, f)],
                           capture_output=True, text=True)
        if p.returncode:
            raise RuntimeError('as failed:\n' + p.stderr)
        return o
    src = os.path.join(ROOT, f)
    if f in rules:
        src = os.path.join(work, os.path.basename(f))
        shutil.copy(os.path.join(ROOT, f), src)
        apply_rules(src, rules[f])
    s, o = os.path.join(work, 'prog.s'), os.path.join(work, 'prog.o')
    extra = ['-I', ROOT] + (['-config', 'cc_a88k'] if binkey == 'a88k' else [])
    top = os.path.abspath(os.path.join(pp.ROOT, '..'))
    p = subprocess.run([pp.DPC, '--root', cc.aegis_root(), '-I', top] + extra
                       + ['-o', s, src], capture_output=True, text=True, cwd=inc)
    if p.returncode or not os.path.exists(s):
        errs = [l for l in p.stderr.splitlines() if 'error' in l][:5]
        raise RuntimeError('dpc failed (%d): %s' % (p.returncode, '; '.join(errs)))
    a = subprocess.run([pp.AS, '-m68020', '-o', o, s], capture_output=True, text=True)
    if a.returncode:
        raise RuntimeError('as failed:\n' + a.stderr)
    return o


# ---------------------------------------------------------------------------
# The image
# ---------------------------------------------------------------------------

class Image:
    """A binary's initial bytes: file bytes where a section has them, the
    .rwdi records' (cc_data.initial) elsewhere; None where nothing sets a
    byte."""

    def __init__(self, path):
        self.coff = cc.Coff(path)
        self.units = self.coff.units()
        self.sections = {s[0].lower(): s for s in self.coff.sections if s[1]}
        built = [s for s in self.coff.sections if s[1] and not s[3]
                 and s[0] not in ('.sri', '.mir')]
        self.lo = min(s[1] for s in built)
        hi = max(s[1] + s[2] for s in built)
        self.origin = [None] * (hi - self.lo)
        self.rw = cc_data.initial(self.coff, self.lo, hi - self.lo, self.origin)
        self.mapaddr, _ = cc.names(self.coff)
        # the generated ISC's anonymous routines (the action tables'
        # targets), named by tools/iscg_gen.py's manifest
        if os.path.basename(path) == 'cc.a88k' and os.path.exists(ISCG_NAMES):
            for line in open(ISCG_NAMES):
                f = line.split()
                if len(f) == 2 and not line.startswith('#'):
                    self.mapaddr.setdefault(f[0].upper(), int(f[1], 16))
        self.bases = sorted({b for b in (unit_data_base(self.coff, u) for u in self.units)
                             if b is not None})

    def read(self, va, n):
        out = [None] * n
        for name, sva, sz, off, _, _ in self.coff.sections:
            lo, hi = max(va, sva), min(va + n, sva + sz)
            if not sva or lo >= hi or name in ('.blocks', '.lines', '.rwdi'):
                continue
            if off:
                out[lo - va:hi - va] = self.coff.data[off + lo - sva:off + hi - sva]
            else:
                out[lo - va:hi - va] = self.rw[lo - self.lo:hi - self.lo]
        return out

    def by_repeat(self, va, n):
        """How many of the n bytes at va a .rwdi repeat record sets."""
        a, b = max(va, self.lo), min(va + n, self.lo + len(self.origin))
        return sum(1 for k in range(a, b) if self.origin[k - self.lo] == 'r')

    def section(self, name):
        """The image section of dpc's name (case aside; the gate's gap-32
        `_S' rename undone)."""
        n = name.lower()
        if n in self.sections:
            return self.sections[n]
        if n.endswith('_s') and n[:-2] in self.sections:
            return self.sections[n[:-2]]
        return None

    def cells(self):
        """{NAME: image address} of the cells other units' comments place
        (cell_hints over every unit file; a name two units place
        differently is left out): another unit's cell a pointer in this
        unit's data names."""
        if getattr(self, '_cells', None) is None:
            out, bad = {}, set()
            for f in all_units():
                if not f.endswith('.pas'):
                    continue
                try:
                    u = cc.pick_unit(self.coff, os.path.splitext(os.path.basename(f))[0],
                                     unit_key(f))
                except SystemExit:
                    continue
                b = unit_data_base(self.coff, u)
                if b is None:
                    continue
                text = open(os.path.join(ROOT, f), encoding='latin-1').read()
                for n, o in cell_hints(text, b).items():
                    if n in out and out[n] != b + o:
                        bad.add(n)
                    out[n] = b + o
            self._cells = {n: a for n, a in out.items() if n not in bad}
        return self._cells

    def block_end(self, base, unit_section):
        """The end of the data block at base: the next unit's block, or
        the end of the section holding it."""
        for s in self.coff.sections:
            if s[1] and s[1] <= base < s[1] + s[2]:
                end = s[1] + s[2]
                break
        else:
            return base
        later = [b for b in self.bases if b > base]
        return min(later[0], end) if later else end


# ---------------------------------------------------------------------------
# The comparison
# ---------------------------------------------------------------------------

_EXTERN_CELLS = {}


def extern_cells(coff):
    """The .rwdi longwords relocated against an external (as
    coff_compare.data_base finds them), once per binary."""
    if coff.path not in _EXTERN_CELLS:
        relocs = {va for va, _, _ in coff.relocations('.rwdi')}
        cells = set()
        for kind, rva, addr, data in coff.rwdi():
            if kind in (0, 2):
                for k in range(0, len(data), 4):
                    if rva + 10 + k in relocs:
                        cells.add(addr + k)
        _EXTERN_CELLS[coff.path] = cells
    return _EXTERN_CELLS[coff.path]


def data_base(coff, unit):
    """coff_compare.data_base, its cells found once."""
    if unit['a5'] is None:
        return None
    base = unit['a5']
    cells = extern_cells(coff)
    while base - 4 in cells:
        base -= 4
    return base


def unit_data_base(coff, unit):
    """The unit's data block: coff_compare.data_base, or for a unit with
    no code (opinfo, isc_vars: no A5) its .blocks file record's fourth
    cell when that lies in a data section."""
    b = data_base(coff, unit)
    if b is not None or unit.get('version', 0) < 4:
        return b
    bl = coff.contents('.blocks')
    base = unit['offset']
    frec = base + struct.unpack('>I', bl[base + 0xE:base + 0x12])[0]
    n = struct.unpack('>H', bl[frec + 2:frec + 4])[0]
    if n < 4:
        return None
    cell = struct.unpack('>I', bl[frec + 16:frec + 20])[0]
    for name, sva, sz, off, _, _ in coff.sections:
        if sva and sva <= cell < sva + sz and not off:
            return cell
    return None


HINT_PAREN = re.compile(r'(?<![\w$])([A-Za-z_][\w$]*)\s*\(\+0x([0-9A-Fa-f]+)\b')
HINT_DECL = re.compile(r'^\s*([A-Za-z_][\w$]*)\s*[,;:][^{\n]*\{\s*\+0x([0-9A-Fa-f]+)\b', re.M)
HINT_ADDR = re.compile(r'\b0x([0-9A-Fa-f]{5,6})\s+([A-Za-z_][\w$]*)')
HINT_NAME = re.compile(r'_([0-9a-f]{2,5})$')


def cell_hints(text, base):
    """{NAME: image offset} of the module's cells as the unit's comments
    give them: `name (+0x300' in prose, `name, { +0x13C }' at a
    declaration, `0x2CE8D8  insind' (an address in the data block)."""
    out = {}
    for m in HINT_ADDR.finditer(text):
        a = int(m.group(1), 16)
        if base is not None and a >= base:
            out.setdefault(m.group(2).upper(), a - base)
    for rx in (HINT_DECL, HINT_PAREN):
        for m in rx.finditer(text):
            out.setdefault(m.group(1).upper(), int(m.group(2), 16))
    return out


def layout_shift(size, lst, hints, block_len, mine=None, theirs=None):
    """The image offset less ours of each of our offsets in a module
    data block (dpc gap 37, and dpc's order of own and defined cells): a
    named cell the hints place (or whose name ends in its offset,
    `lir_main_c89') goes there, up to the next placed cell or the
    block's end; a range between named cells (or the rest of a placed
    cell's range: our own cells after it) follows the cell before it, or,
    when that would overlap a placed cell, goes to the one free stretch of
    the image's block long enough, where its bytes match the image's
    best (the split from the placed cell before it, 1, 2, 4 or 8 bytes
    or all the room, chosen the same way)."""
    segs = []                       # [our start, our end, image start or None, split]
    starts = [v for v, _ in lst if v < size]
    if not starts or starts[0] > 0:
        segs.append([0, starts[0] if starts else size, None, None])
    for k, (v, n) in enumerate(lst):
        if v >= size:
            continue
        end = lst[k + 1][0] if k + 1 < len(lst) else size
        io = hints.get(n.upper())
        if io is None:
            m = HINT_NAME.search(n.lower())
            if m and abs(int(m.group(1), 16) - v) <= 32:
                io = int(m.group(1), 16)
        if io is not None and not 0 <= io < max(block_len, size):
            io = None
        if segs and segs[-1][0] == v:
            segs[-1][2] = io if io is not None else segs[-1][2]
            segs[-1][1] = max(segs[-1][1], end)
        elif end > v:
            segs.append([v, end, io, None])
    limit = max(block_len, size)
    ios = sorted(sg[2] for sg in segs if sg[2] is not None)
    k = 0
    while k < len(segs):
        b, e, io, _ = segs[k]
        if io is not None:
            nxt = [x for x in ios if x > io] + [limit]
            room = min(e - b, nxt[0] - io)
            if room < e - b:
                segs[k][1] = b + room
                segs.insert(k + 1, [b + room, e, None, (k, room)])
        k += 1

    def misses(lo, hi, at):
        if mine is None or theirs is None:
            return 0
        return sum(1 for j in range(lo, hi) if at + j - lo < len(theirs)
                   and theirs[at + j - lo] is not None and theirs[at + j - lo] != mine[j])

    def placed_now(skip=None):
        return [(sg[2], sg[2] + sg[1] - sg[0]) for i, sg in enumerate(segs)
                if sg[2] is not None and i != skip]
    cur = 0
    for i, sg in enumerate(segs):
        b, e, io, split = sg
        if io is not None:
            cur = io - b
            continue
        placed = placed_now()

        def free(lo, hi):
            return 0 <= lo and hi <= limit and all(hi <= x or lo >= y for x, y in placed)
        if free(b + cur, e + cur):
            sg[2] = b + cur
        else:
            gaps, at = [], 0
            for x, y in sorted(placed):
                if x > at:
                    gaps.append((at, x))
                at = max(at, y)
            if limit > at:
                gaps.append((at, limit))
            fit = [g for g in gaps if g[1] - g[0] == e - b] or [
                g for g in gaps if g[1] - g[0] >= e - b - 8]
            if len(fit) != 1:
                sg[2] = b if free(b, e) else b + cur
            else:
                g = fit[0]
                best = None
                rooms = [None]
                if split is not None:
                    hk, room = split
                    hb = segs[hk][0]
                    rooms = sorted({r for r in (1, 2, 4, 8, room) if r <= room}, reverse=True)
                for r in rooms:
                    lo = b if r is None else segs[split[0]][0] + r
                    n = e - lo
                    if n > g[1] - g[0]:
                        continue
                    for at in range(g[0], min(g[1] - n, g[0] + 64) + 1):
                        key = (misses(lo, e, at), -(r or 0), at)
                        if best is None or key < best[0]:
                            best = (key, lo, at, r)
                if best is None:
                    sg[2] = b + cur
                else:
                    _, lo, at, r = best
                    if r is not None:
                        segs[split[0]][1] = lo
                        sg[0] = lo
                    sg[2] = at
        cur = sg[2] - sg[0]
    shift = [0] * size
    for b, e, io, _ in segs:
        for j in range(b, min(e, size)):
            shift[j] = io - b
    return shift


def content_shift(mine, theirs, limit=40000):
    """Our offsets' image offsets less ours from aligning our block's
    bytes with the image's (difflib, gaps allowed; an unset image byte
    taken as 0); a byte outside the matching runs follows the run
    before it.  None for a block past limit bytes."""
    import difflib
    if len(mine) > limit or len(theirs) > limit:
        return None
    b = bytes(0 if x is None else x for x in theirs)
    sm = difflib.SequenceMatcher(None, bytes(mine), b, autojunk=False)
    shift, cur, k = [0] * len(mine), 0, 0
    for i, j, n in sm.get_matching_blocks():
        while k < i:
            shift[k] = cur
            k += 1
        cur = j - i
        while k < i + n and k < len(mine):
            shift[k] = cur
            k += 1
    while k < len(mine):
        shift[k] = cur
        k += 1
    return shift


_KNOWN = None


def known(f, binkey, lo):
    """The reason tools/cc_datacheck_known.txt gives for a difference of
    unit file f at image offset lo of its data block, or None.  A line:
    FILE<TAB>BINARY (m68k, a88k or *)<TAB>+0xLO-+0xHI (or *)<TAB>REASON."""
    global _KNOWN
    if _KNOWN is None:
        _KNOWN = []
        if os.path.exists(KNOWN):
            for line in open(KNOWN):
                line = line.rstrip('\n')
                if not line or line.startswith('#'):
                    continue
                path, b, rng, why = line.split('\t', 3)
                if rng == '*':
                    a, z = 0, 1 << 32
                else:
                    a, z = (int(x.lstrip('+'), 16) for x in rng.split('-'))
                _KNOWN.append((path, b, a, z, why))
    for path, b, a, z, why in _KNOWN:
        if path == f and b in ('*', binkey) and a <= lo < z:
            return why
    return None


def unit_key(f):
    return os.path.splitext(f)[0]


# the instructions that load A5 with the module's block (an absolute
# address with a relocation): lea abs.l,%a5 and movea.l #abs,%a5
A5_LOADS = (b'\x4b\xf9', b'\x2a\x7c')


class _HeadlessSection:
    """A .moddata section of dpc's seen from its .Ldata (A5) on: the
    header cells before it dropped."""

    def __init__(self, s, n):
        self._s, self.head = s, n
        self.size = s.size - n

    def __getattr__(self, k):
        return getattr(self._s, k)


class _HeadlessElf:
    """rfc_elf.Elf with the sections of `head' ({section: header size})
    starting at their .Ldata."""

    def __init__(self, elf, cut):
        self._elf, self.cut = elf, cut
        self.sections = [_HeadlessSection(s, cut[s.index]) if s.index in cut else s
                         for s in elf.sections]

    def contents(self, s):
        n = self.cut.get(s.index, 0)
        return self._elf.contents(getattr(s, '_s', s))[n:]

    def __getattr__(self, k):
        return getattr(self._elf, k)


def strip_heads(elf, relocs, syms, head):
    """(elf, relocs, syms) with each .moddata section in head (by name:
    its header's size) seen from its .Ldata on: offsets in the section,
    and addends against it, less the header's size; the header's own
    relocations dropped (its cells are not compared)."""
    cut = {s.index: head[s.name] for s in elf.sections if s.name in head}
    if not cut:
        return elf, relocs, syms
    out = {}
    for i, lst in relocs.items():
        n = cut.get(i, 0)
        out[i] = [(off - n, typ, name, addend - head.get(name, 0))
                  for off, typ, name, addend in lst if off >= n]
    syms = [(nm, v - cut.get(shndx, 0), sz, info, shndx) for nm, v, sz, info, shndx in syms
            if v >= cut.get(shndx, 0)]
    return _HeadlessElf(elf, cut), out, syms


def check(f, binkey, img, obj, verbose=False):
    """[(kind, line)] for unit file f's object against img."""
    out = []
    path, prog = unit_key(f), os.path.splitext(os.path.basename(f))[0]
    try:
        unit = cc.pick_unit(img.coff, prog, path)
    except SystemExit:
        return None
    elf = rfc_elf.Elf(obj)
    syms = elf.symbols()
    relocs, head, code = {}, {}, {}
    for target, off, typ, name, addend in elf.relocations(section_names=True):
        relocs.setdefault(target.index, []).append((off, typ, name, addend))
        if target.flags & 4 and typ == rfc_elf.R_68K_32 and MODDATA_RE.match(name) and off >= 2:
            if target.index not in code:
                code[target.index] = elf.contents(target)
            if code[target.index][off - 2:off] in A5_LOADS:
                head.setdefault(name, set()).add(addend)
    # dpc's header cells: the addresses of far constants (a string past a
    # 16-bit pc-relative reach), which the code reads at negative offsets
    # from A5, lie at the start of dpc's .moddata, before .Ldata (A5);
    # the code loads A5 as `lea (.Ldata).l,%a5', the section plus the
    # header's size.  The image has no such cells (its cells below A5 are
    # the loader's extern addresses: a module's pas_$output at -4): the
    # header is left out of the comparison and the rest taken from A5.
    head = {n: max(a) for n, a in head.items() if len(a) == 1 and max(a) > 0}
    elf, relocs, syms = strip_heads(elf, relocs, syms, head)
    base_of = {}             # our data section index -> image address
    what = {}
    for s in elf.sections:
        if not s.alloc or not s.size:
            continue
        if f.endswith('.asm') and s.name == '.text':
            if unit['text'] is None:
                out.append(('error', '%s %s: the image unit has no code' % (f, binkey)))
                continue
            base_of[s.index] = unit['text']
            what[s.index] = 'code'
            continue
        if not s.flags & SHF_WRITE:
            continue
        m, mo = MODDATA_RE.match(s.name), OVERLAY_RE.match(s.name)
        if m:
            # dpc's +0 is the unit's A5: the image's extern-address
            # cells right below it (coff_compare.data_base) are the
            # loader's, which dpc's block does not hold
            b = unit['a5'] if unit['a5'] is not None else unit_data_base(img.coff, unit)
            if b is None:
                out.append(('error', '%s %s %s: %d bytes, the image unit has no data block'
                            % (f, binkey, s.name, s.size)))
                continue
            base_of[s.index] = b
            what[s.index] = 'moddata'
        elif mo:
            sec = img.section(mo.group('section'))
            if sec is None:
                out.append(('error', '%s %s %s: no image section %s'
                            % (f, binkey, s.name, mo.group('section'))))
                continue
            base_of[s.index] = sec[1]
            what[s.index] = 'overlay'
            if s.size != sec[2]:
                out.append(('error', '%s %s %s: %d bytes, the image section 0x%X'
                            % (f, binkey, s.name, s.size, sec[2])))
        else:
            out.append(('error', '%s %s %s: %d bytes, not a data section this knows'
                        % (f, binkey, s.name, s.size)))
    # our symbols by section, and the image address of each
    by_sec = {}
    for n, v, _, info, shndx in syms:
        if n and shndx < len(elf.sections) and info & 0xF in (0, 1, 2):
            by_sec.setdefault(shndx, []).append((v, n))
    for v in by_sec.values():
        v.sort()
    sec_by_name = {s.name: s.index for s in elf.sections}
    shifts = {}

    def target_addr(name, addend):
        u = name.upper()
        if name in sec_by_name:
            i = sec_by_name[name]
            if i in base_of:
                sh = shifts.get(i) or [0]
                return base_of[i] + addend + sh[min(max(addend, 0), len(sh) - 1)]
            if i in by_sec and elf.sections[i].flags & 4:     # code: by routine
                k = [x for x in by_sec[i] if x[0] <= addend and x[1].upper() in img.mapaddr]
                if k:
                    v, n = k[-1]
                    return img.mapaddr[n.upper()] + addend - v
            return None
        for i, lst in by_sec.items():
            for v, n in lst:
                if n == name and i in base_of:
                    sh = shifts.get(i) or [0]
                    return base_of[i] + v + addend + sh[min(v, len(sh) - 1)]
        if u in img.mapaddr:
            return img.mapaddr[u] + addend
        sec = img.section(name)
        if sec is not None:
            return sec[1] + addend
        a = img.cells().get(u)
        if a is not None:
            return a + addend
        return None

    # the image offset less ours of each byte of a module data block
    try:
        text = open(os.path.join(ROOT, f), encoding='latin-1').read()
    except OSError:
        text = ''
    for i in base_of:
        sz = elf.sections[i].size
        if what[i] == 'moddata':
            blen = img.block_end(base_of[i], None) - base_of[i]
            shifts[i] = layout_shift(sz, by_sec.get(i, []),
                                     cell_hints(text, base_of[i]), blen,
                                     elf.contents(elf.sections[i]),
                                     img.read(base_of[i], max(blen, sz)))
        else:
            shifts[i] = [0] * sz

    hexs = lambda bs: ' '.join('..' if x is None else '%02x' % x for x in bs[:24]) + (
        ' ...' if len(bs) > 24 else '')

    def compare(s, base, mine, care, shift, lst):
        """(difference lines, data count, layout count, bytes compared) of
        our section s against the image at base, our offset j at the
        image's j + shift[j]."""
        lines, ndata, nlayout, ncompared = [], 0, 0, 0
        at = {}
        for j in range(s.size):
            at.setdefault(j + shift[j], j)
        ourend = max(at) + 1 if at else 0
        hi = ourend
        if what[s.index] == 'moddata':
            # the image's block ends at the next unit's: what lies past
            # it is not this unit's
            hi = img.block_end(base, None) - base
            ourend = min(ourend, hi)
        theirs = img.read(base, hi)
        runs, cur = [], None
        for io in range(hi):
            t = theirs[io]
            j = at.get(io)
            if t is None:
                d = False
            elif j is None:
                # past our block, or a byte our layout has no cell for
                d = ('past' if io >= ourend else True) if t != 0 else False
            elif not care[j]:
                d = False
            else:
                ncompared += 1
                d = mine[j] != t
            if d:
                if cur and cur[1] == io and cur[3] == (d == 'past'):
                    cur[1] = io + 1
                else:
                    cur = [io, io + 1, j, d == 'past']
                    runs.append(cur)
        # runs a few equal bytes apart are one difference
        merged = []
        for r in runs:
            if merged and r[3] == merged[-1][3] and r[0] - merged[-1][1] <= 3:
                merged[-1][1] = r[1]
            else:
                merged.append(r)

        def ours_at(k):
            j = at.get(k)
            return mine[j] if j is not None and care[j] else None
        # moved cells: a run whose bytes, ours and the image's, are the
        # other side's at another differing offset of the block (dpc's
        # order of own and defined cells, its alignment of a cell)
        diffset = set()
        for r in merged:
            diffset.update(range(r[0], r[1]))
        ourb = bytes(0 if x is None else x for x in (ours_at(k) for k in range(hi)))
        theirb = bytes(0 if x is None else x for x in theirs)

        def found(seq, arr, lo):
            """Offsets other than lo where seq (trimmed of zeros) lies in
            arr over a differing byte."""
            seq = [0 if x is None else x for x in seq]
            while seq and not seq[0]:
                seq, lo = seq[1:], lo + 1
            while seq and not seq[-1]:
                seq = seq[:-1]
            if sum(1 for x in seq if x) < 2 or len(merged) > 400:
                return None
            pat, out, p = bytes(seq), [], arr.find(bytes(seq))
            while p >= 0 and len(out) < 4:
                if p != lo and any(q in diffset for q in range(p, p + len(pat))):
                    out.append(p)
                p = arr.find(pat, p + 1)
            return out

        for lo, end, j, past in merged:
            ours = [ours_at(k) for k in range(lo, end)]
            img_b = theirs[lo:end]
            sym = ''
            if j is not None:
                cands = [x for x in lst if x[0] <= j]
                if cands:
                    sym = ' (%s+0x%X)' % (cands[-1][1], j - cands[-1][0])
            layout = False
            if what[s.index] == 'moddata' and not past:
                # a cell's shift the names did not place (gap 37, or
                # dpc's alignment of an own cell): around the run (four
                # bytes either side), our bytes are the image's one or
                # two bytes away, two nonzero ones among them
                w = range(max(lo - 4, 0), min(end + 4, hi))
                for dlt in (-1, 1, -2, 2):
                    pairs = [(ours_at(k + dlt), theirs[k]) for k in w]
                    pairs = [(x, y) for x, y in pairs if x is not None and y is not None]
                    if (pairs and all(x == y for x, y in pairs)
                            and sum(1 for _, y in pairs if y) >= 2):
                        layout = True
                        break
            moved = ''
            if what[s.index] == 'moddata' and not layout:
                fi = found(theirs[lo:end], ourb, lo)       # the image's bytes in ours
                fo = None if past else found(ours, theirb, lo)
                if (fi or fo) and fi != [] and fo != []:
                    layout = True
                    moved = 'layout: %s' % '; '.join(
                        x for x in ('the image\'s bytes at our +%s' % ','.join('0x%X' % p for p in fi)
                                    if fi else '',
                                    'ours at the image\'s +%s' % ','.join('0x%X' % p for p in fo)
                                    if fo else '') if x)
            why = None if layout else known(f, binkey, lo)
            if layout or why:
                nlayout += 1
            else:
                ndata += 1
            label = moved or ('past dpc\'s data' if past else (
                'layout: the image\'s bytes shifted' if layout else 'data'))
            if why:
                label = 'known (tools/cc_datacheck_known.txt): %s; %s' % (why, label)
            if img.by_repeat(base + lo, end - lo):
                label += '; set by a repeat record'
            lines.append(('layout' if layout or why else 'data',
                          '%s %s %s +0x%X%s [%d bytes, %s]: dpc %s | image %s'
                          % (f, binkey, s.name, lo, sym, end - lo, label, hexs(ours),
                             hexs(list(img_b)))))
        return lines, ndata, nlayout, ncompared

    ndata = nlayout = nunver = ncompared = 0
    for s in elf.sections:
        if s.index not in base_of:
            continue
        base = base_of[s.index]
        mine = bytearray(elf.contents(s))
        care = [True] * s.size
        for off, typ, name, addend in relocs.get(s.index, []):
            width = pp.RELOC_WIDTH.get(typ, 4)
            t = target_addr(name, addend) if typ == rfc_elf.R_68K_32 else None
            if t is None:
                nunver += 1
                for k in range(off, min(off + width, s.size)):
                    care[k] = False
                continue
            mine[off:off + 4] = (t & 0xFFFFFFFF).to_bytes(4, 'big')
        lst = by_sec.get(s.index, [])
        if what[s.index] == 'moddata' and s.size > img.block_end(base, None) - base:
            nlayout += 1
            out.append(('layout', '%s %s %s: dpc\'s block is 0x%X bytes, the image\'s 0x%X '
                        '(to the next unit\'s); the rest is not compared' % (
                            f, binkey, s.name, s.size, img.block_end(base, None) - base)))
        res = compare(s, base, mine, care, [0] * s.size, lst)
        how = None
        if (res[1] or res[2]) and what[s.index] == 'moddata':
            # other layouts, kept when they leave fewer differences: by
            # name (the hints), and by content (our block aligned with
            # the image's, gaps allowed: dpc's alignment and order of
            # cells, rev889-patterns 50, dpc gap 37)
            cands = []
            if any(shifts[s.index]):
                cands.append(('by name', shifts[s.index]))
            blk = img.read(base, max(s.size, img.block_end(base, None) - base))
            sh = content_shift(mine, blk)
            if sh is not None and any(sh):
                cands.append(('by content', sh))
            if any(shifts[s.index]):
                # by name, then by content
                sn = shifts[s.index]
                n = max(j + sn[j] for j in range(s.size)) + 1
                perm = bytearray(n)
                for j in range(s.size):
                    perm[j + sn[j]] = mine[j]
                sc = content_shift(perm, blk)
                if sc is not None:
                    cands.append(('by name and content',
                                  [sn[j] + sc[j + sn[j]] for j in range(s.size)]))
            for why, sh in cands:
                alt = compare(s, base, mine, care, sh, lst)
                if (alt[1], alt[1] + alt[2]) < (res[1], res[1] + res[2]):
                    res, how = alt, (why, sh)
        if how:
            why, sh = how
            moved, prev = [], 0
            for j in range(s.size):
                if sh[j] != prev:
                    moved.append('our +0x%X at +0x%X' % (j, j + sh[j]))
                    prev = sh[j]
            nlayout += 1
            out.append(('layout', '%s %s %s: laid out otherwise (aligned %s: dpc gap 37, '
                        'dpc\'s order or alignment of cells): %s' % (
                            f, binkey, s.name, why, ', '.join(moved[:10]) + (
                                ', ...' if len(moved) > 10 else ''))))
        out.extend(res[0])
        ndata += res[1]
        nlayout += res[2]
        ncompared += res[3]
    sections = ', '.join('%s %d at 0x%X%s' % (
        elf.sections[i].name, elf.sections[i].size, b,
        ' (after %d bytes of header cells, not compared)' % elf.sections[i].head
        if getattr(elf.sections[i], 'head', 0) else '') for i, b in base_of.items())
    out.append(('summary', '%-48s %-5s %s: %d data difference(s), %d layout, '
                '%d byte(s) compared, %d unverified reloc(s)'
                % (f, binkey, sections or 'no initialized data', ndata, nlayout,
                   ncompared, nunver)))
    return out


# ---------------------------------------------------------------------------

def all_units():
    files = []
    for r in SRC_ROOTS:
        for d, _, fs in os.walk(os.path.join(ROOT, r)):
            for n in fs:
                if (n.endswith('.pas') and not n.endswith('.ins.pas')
                        and not n.endswith('.pvt.pas')) or (n.endswith('.asm') and r == 'lang'):
                    files.append(os.path.relpath(os.path.join(d, n), ROOT))
    return sorted(files)


_IMG = {}
_CTX = {}


def _init(binkeys, inc, rules, keep, reuse):
    for k in binkeys:
        _IMG[k] = Image(BINS[k])
    _CTX.update(inc=inc, rules=rules, keep=keep, reuse=reuse)


def _job(args):
    f, binkey = args
    img = _IMG[binkey]
    path, prog = unit_key(f), os.path.splitext(os.path.basename(f))[0]
    try:
        cc.pick_unit(img.coff, prog, path)
    except SystemExit:
        return f, binkey, None
    keep = _CTX['keep']
    work = (os.path.join(keep, '%s.%s' % (path.replace('/', '_'), binkey)) if keep
            else tempfile.mkdtemp(prefix='cc_datacheck.'))
    try:
        obj = os.path.join(work, 'prog.o')
        if not (_CTX['reuse'] and os.path.exists(obj)):
            obj = compile_unit(f, binkey, _CTX['inc'], work, _CTX['rules'])
        return f, binkey, check(f, binkey, img, obj)
    except RuntimeError as e:
        return f, binkey, [('error', '%s %s: %s' % (f, binkey, e))]
    finally:
        if not keep:
            shutil.rmtree(work, ignore_errors=True)


def report(res, quiet, verbose):
    """Print one unit's lines; True when it has a data difference or an
    error."""
    bad = any(k in ('data', 'error') for k, _ in res)
    if quiet and not bad:
        return False
    for kind, line in res:
        if kind == 'summary':
            if verbose or any(k in ('data', 'layout', 'error') for k, _ in res):
                print(line)
        elif not quiet or kind in ('data', 'error'):
            print('    ' + line)
    sys.stdout.flush()
    return bad


def check_objects(listfile, quiet, verbose):
    """--objects: the objects tools/cc_check.sh kept, checked in one
    process (the images built once)."""
    imgs, bad = {}, False
    for line in open(listfile):
        f, binkey, obj = line.rstrip('\n').split('\t')
        if not os.path.exists(obj):
            continue
        if binkey not in imgs:
            imgs[binkey] = Image(BINS[binkey])
        res = check(f, binkey, imgs[binkey], obj)
        if res is not None:
            bad = report(res, quiet, verbose) or bad
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('files', nargs='*')
    ap.add_argument('--binary', choices=['m68k', 'a88k'], help='one binary only')
    ap.add_argument('-j', type=int, default=os.cpu_count() or 4)
    ap.add_argument('--keep', help='keep each compilation in DIR/PATH_OF_UNIT.BINARY')
    ap.add_argument('--reuse', action='store_true',
                    help='with --keep, check the objects an earlier run kept there '
                    'without compiling them again')
    ap.add_argument('--objects', metavar='LIST',
                    help='check the objects LIST names (FILE<TAB>m68k|a88k<TAB>OBJECT a line, '
                    'tools/cc_check.sh\'s) without compiling')
    ap.add_argument('-q', action='store_true', help='print only the units with a data difference')
    ap.add_argument('-v', action='store_true', help='print every unit\'s summary, even a clean one')
    a = ap.parse_args()
    os.chdir(ROOT)
    if a.objects:
        sys.exit(check_objects(a.objects, a.q, a.v))
    files = [os.path.relpath(os.path.abspath(f), ROOT) for f in a.files] or all_units()
    binkeys = [a.binary] if a.binary else ['m68k', 'a88k']
    rules = read_rules()
    scratch = tempfile.mkdtemp(prefix='cc_datacheck.')
    try:
        inc = prepare_inc(scratch, rules)
        if a.keep:
            os.makedirs(a.keep, exist_ok=True)
        jobs = [(f, b) for f in files for b in binkeys]
        bad = False
        with concurrent.futures.ProcessPoolExecutor(
                max_workers=a.j, initializer=_init,
                initargs=(binkeys, inc, rules, a.keep, a.reuse)) as ex:
            for f, b, res in ex.map(_job, jobs):
                if res is None:
                    continue
                bad = report(res, a.q, a.v) or bad
    finally:
        shutil.rmtree(scratch, ignore_errors=True)
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
