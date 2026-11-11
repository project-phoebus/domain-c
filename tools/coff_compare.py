#!/usr/bin/env python3
"""coff_compare.py - compare a compiled Pascal program with an Apollo COFF binary.

    tools/coff_compare.py [--binary PATH] [--diff] [--keep DIR] PROGRAM.pas [-- DPC_ARGS...]
                                                                  (from domain_os/)

Compiles PROGRAM.pas with dpc (--root at a decoded mirror of the SR10.2
install's inserts, so that '/sys/ins/...' resolves, and -I at the
repository's top, for 'com/ins/...'; DPC_ARGS are added) and as, and compares each of
its routines with the binary's, as tools/routine_compare.py does for the
kernel: `same', `same-pcrel', `same-placement', `differs (N bytes)',
`size differs', with the similarity (and with registers ignored) of a
routine that is not `same', and with --diff the first differing runs.

    tools/coff_compare.py --list [--binary PATH] [PROGRAM.pas]

The binary (default: the install's com/<program>, or com/<dir> for the
nearest directory of the program's path that names one, or lib/<dir> for
a file under lib/<dir>/) is an Apollo m68k COFF executable or library
(magic 0x197).  Its names come from the file itself:
- the routines from the .blocks debug section: the program's block and
  its procedures, each with its address and its code length;
  a binary linked from several files has one .blocks unit per file
  (Coff.units()), and the file compiled is compared with the unit of its
  name (--unit to name another), its data block at that unit's A5;
- the externals from the transfer vector .aptv: each 6-byte `jmp abs.l'
  slot is relocated against one external symbol, and a call `jsr (X).l'
  is a call of that slot;
- the program's data block is .data (the image has no bytes there: the
  loader builds it), so its own-section references are checked against
  .data's address.
A library (/lib/pmlib: no .aptv) is position-independent code in several
code sections (.text, invoke_code, release_code, ...), each with its own
pure data section and A5; its externals are cells below A5 that .rwdi
relocates (Coff.cells()), and its symbol table names its exports (the
data thunks), its data sections and its assembly units' routines, which
.blocks does not link.  --list prints the units, their sections and
routines, without compiling.
Names are matched without case (dpc upper-cases external names, the
binary's are lower case).  A routine runs to the next routine's start or
the end of its code section, so it takes in the constants that follow it.
"""
import argparse
import bisect
import os
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
# Local patched copy (domain-c): the rest of the tool chain stays in the
# source repository's domain_os/tools until this is merged back.
SOURCE_TOOLS = os.environ.get('SOURCE_TOOLS', os.path.expanduser(
    '~/src/domainos-archeology/source/domain_os/tools'))
sys.path.insert(0, SOURCE_TOOLS)
sys.path.insert(0, HERE)
import pascal_progress as pp  # noqa: E402


class Coff:
    """The sections, symbols and relocations of an Apollo COFF file."""

    def __init__(self, path):
        self.path = path
        d = self.data = open(path, 'rb').read()
        magic, nscns, _, symptr, nsyms, opthdr, _ = struct.unpack('>HHIIIHH', d[:20])
        if magic != 0x197:
            raise SystemExit('%s: not an Apollo COFF file (magic 0x%X)' % (path, magic))
        strtab = symptr + 18 * nsyms

        def name8(e):
            # an 8-byte name, or 0.l and an offset.l into the string table
            # (pmlib's long section names, `seldom_used_pure_data$')
            if e[:4] == b'\0\0\0\0':
                o = strtab + struct.unpack('>I', e[4:8])[0]
                return d[o:d.index(b'\0', o)].decode('latin1')
            return e[:8].rstrip(b'\0').decode('latin1')
        self.sections = []          # (name, vaddr, size, file offset, reloc offset, nreloc)
        self.section_flags = {}     # name -> s_flags
        off = 20 + opthdr
        for _ in range(nscns):
            s = d[off:off + 40]
            off += 40
            name = name8(s)
            _, va, sz, sp, rp, _, nr, _, fl = struct.unpack('>IIIIIIHHI', s[8:40])
            self.sections.append((name, va, sz, sp, rp, nr))
            self.section_flags[name] = fl
        self.symbols = {}           # symbol table index -> name
        self.symtab = []            # (index, name, value, scnum, sclass, aux bytes)
        i = 0
        while i < nsyms:
            e = d[symptr + 18 * i:symptr + 18 * (i + 1)]
            name = name8(e)
            self.symbols[i] = name
            value, scnum, _, sclass, naux = struct.unpack('>IhHBB', e[8:18])
            self.symtab.append((i, name, value, scnum, sclass,
                                d[symptr + 18 * (i + 1):symptr + 18 * (i + 1 + naux)]))
            i += 1 + naux

    def section(self, name):
        for s in self.sections:
            if s[0] == name:
                return s
        return None

    def contents(self, name):
        s = self.section(name)
        return self.data[s[3]:s[3] + s[2]] if s and s[3] else None

    def relocations(self, name):
        """(vaddr, symbol name, type) of each relocation of section name."""
        s = self.section(name)
        out = []
        for k in range(s[5] if s else 0):
            va, si, typ = struct.unpack('>IIH', self.data[s[4] + 10 * k:s[4] + 10 * k + 10])
            out.append((va, self.symbols.get(si), typ))
        return out

    def code_section_at(self, va):
        """The code section (s_flags 0x20, not .unwind) holding va, or None."""
        for s in self.sections:
            if (self.section_flags.get(s[0], 0) & 0x20 and s[0] != '.unwind'
                    and s[1] <= va < s[1] + s[2]):
                return s
        return None

    def rwdi(self):
        """The .rwdi records, in order: (kind, record va, address, bytes).
        Kind 0 copies the bytes to the address; kind 2 has the same layout
        and copies nothing; kind 1 (count.l) repeats the previous record's
        bytes count-1 more times (address and bytes None here); kind 3 is a
        2-byte pad (the loader's process_rwdi, lib/pmlib/loader.pas)."""
        rw = self.section('.rwdi')
        out = []
        if not rw:
            return out
        d, o = self.data[rw[3]:rw[3] + rw[2]], 0
        while o + 2 <= len(d):
            kind = struct.unpack('>H', d[o:o + 2])[0]
            if kind == 1:
                out.append((1, rw[1] + o, None, None))
                o += 6
            elif kind == 3:
                out.append((3, rw[1] + o, None, None))
                o += 2
            elif kind in (0, 2) and o + 10 <= len(d):
                addr, n = struct.unpack('>II', d[o + 2:o + 10])
                out.append((kind, rw[1] + o, addr, d[o + 10:o + 10 + n]))
                o += 10 + n + (n & 1)
            else:
                break
        return out

    def cells(self):
        """{address: symbol name} of the longwords .rwdi fills that a
        relocation names: in a library, the cells below a unit's A5 that
        hold an external's (or a section's) address."""
        relocs = {va: sym for va, sym, _ in self.relocations('.rwdi')}
        out = {}
        for kind, rva, addr, data in self.rwdi():
            if kind != 0:
                continue
            for k in range(0, len(data) - 3, 2):
                if rva + 10 + k in relocs:
                    out[addr + k] = relocs[rva + 10 + k]
        return out

    def file_symbols(self):
        """[(source path, [(name, value, section name, sclass)])]: the
        symbol table's .file entries and the symbols defined after each,
        up to the next (an assembly unit's routines: .blocks does not link
        them)."""
        out = []
        secnames = [s[0] for s in self.sections]
        for i, name, value, scnum, sclass, aux in self.symtab:
            if name.rstrip() == '.file':
                if aux[:4] == b'\0\0\0\0':
                    strtab = (struct.unpack('>I', self.data[8:12])[0]
                              + 18 * struct.unpack('>I', self.data[12:16])[0])
                    o = strtab + struct.unpack('>I', aux[4:8])[0]
                    src = self.data[o:self.data.index(b'\0', o)].decode('latin1')
                else:
                    src = aux[:14].rstrip(b'\0').decode('latin1')
                out.append((src, []))
            elif out and scnum > 0 and name not in secnames:
                out[-1][1].append((name, value, secnames[scnum - 1], sclass))
        return out

    def units(self):
        """The compilation units of .blocks, in order: [{'offset', 'source',
        'text', 'a5', 'blocks'}].  A program linked from several separately
        compiled files (/com/calendar: a program, its modules and shared
        `common' modules) has one unit per file, back to back.  A unit's
        header: +0 `01 00 01 02', +4 1.l, +8 the number of blocks.w, +0xA
        the first block record's offset.l, +0xE the file record's, +0x12
        the timestamp record's, +0x16 the unit's length.l (offsets from
        the unit's start); the next unit starts at the next multiple of 4
        (from the section's start) after it.  The file record: `02 00', a
        count.w of longwords, then the unit's .lines address, its .unwind
        address, 0, its .text start and, when the count is 5, its A5 (the
        unit has a data block); then the source path's string record
        (tag 0x1B, +2 its length.l, the NUL-ended text).  The block
        records as blocks() reads them; a module's record (+2 kind 0) has
        no code (+28 0, not 4) and is left out.

        In a library (/lib/pmlib) the file record lists, after the three
        cells, the start of each code section the unit uses, then each one's
        A5 (in the same order), then the unit's other data sections; a block
        record's +28 is the number of its code section's cell (4, 5, ...)
        and +30 its offset from that start.  'code' is [(section, start,
        A5)]; 'text' the first code start; 'a5' the A5 of the code section
        holding most of the unit's routines.  An assembly unit's file record
        has three cells (.lines, the code start, the data) and its routine
        records are not linked: only its module record is reached, and its
        'symbols' (file_symbols()) name its routines."""
        b = self.contents('.blocks')
        if b is None:
            raise SystemExit('%s: no .blocks section' % self.path)
        s32 = lambda o: struct.unpack('>i', b[o:o + 4])[0]
        u32 = lambda o: struct.unpack('>I', b[o:o + 4])[0]
        u16 = lambda o: struct.unpack('>H', b[o:o + 2])[0]
        out, base = [], 0
        # a library's symbol table has a `.blocks' section symbol per unit
        # (pmlib's units are only word aligned); a program's has none, and
        # the units are found by their lengths
        bsec = self.section('.blocks')
        bases = sorted(v - bsec[1] for _, n, v, _, _, _ in self.symtab if n == '.blocks')
        fsrc = [src for src, _ in self.file_symbols()]
        while base + 0x1A <= len(b) and b[base:base + 4] in (b'\x01\x00\x01\x02', b'\x01\x00\x01\x04'):
            count, first = u16(base + 8), base + u32(base + 0xA)
            frec, length = base + u32(base + 0xE), u32(base + 0x16)
            level, todo = {first: 1}, [first]
            while todo:
                r = todo.pop()
                for o, lv in ((s32(r + 4), level[r]), (s32(r + 8), level[r] + 1)):
                    if o and r + o not in level:
                        level[r + o] = lv
                        todo.append(r + o)
            linked = [r for r in level if not (b[r] == 0x04 and u16(r + 2) == 0)]
            if len(level) != count and linked:
                raise SystemExit('%s: .blocks links reach %d blocks, the unit at +0x%X names %d'
                                 % (self.path, len(level), base, count))
            if b[frec] != 0x02:
                raise SystemExit('%s: .blocks file record not understood at +0x%X'
                                 % (self.path, frec))
            n = u16(frec + 2)
            cells = [u32(frec + 4 + 4 * k) for k in range(n)]
            code = []
            if b[base + 3] >= 4 and n >= 4 and self.code_section_at(cells[3]):
                # version 4 (cc 6.9): .lines, .unwind, an offset (not an
                # address: in cc.a88k it falls inside .text's range), the
                # code start, the A5 when the unit has a data block, then the
                # other data sections it uses (cc.a88k's back end: the
                # read-only operand and instruction tables).  Every block's
                # cell is 4, the code start.
                a5 = cells[4] if n >= 5 and not self.code_section_at(cells[4]) else None
                code = [(self.code_section_at(cells[3])[0], cells[3], a5)]
            elif n >= 4 and cells[2] == 0:
                k = 3
                while k < n and self.code_section_at(cells[k]):
                    k += 1
                starts = cells[3:k]
                a5s = cells[k:k + len(starts)]
                code = [(self.code_section_at(c)[0], c, a5s[j] if j < len(a5s) else None)
                        for j, c in enumerate(starts)]
            else:
                code = [(self.code_section_at(c)[0], c, None) for c in cells[1:]
                        if self.code_section_at(c)]
            blocks, size = [], {}
            for r in sorted(level):
                if b[r] == 0x04 and u16(r + 2) == 0:
                    continue                    # a module: no code
                if b[r] == 0x04 and s32(r + 12) == 0:
                    continue                    # an unnamed C scope block
                    # (kind 0x0902, loc_build.c): part of its function
                cell = u16(r + 28)
                if b[r] != 0x04 or not 4 <= cell <= 3 + len(code):
                    raise SystemExit('%s: .blocks record not understood at +0x%X' % (self.path, r))
                o = r + s32(r + 12)
                name = b[o:b.index(b'\0', o)].decode('latin1')
                blocks.append((name, level[r], cells[cell - 1] + u32(r + 30), u32(r + 24)))
                size[cell - 4] = size.get(cell - 4, 0) + u32(r + 24)
            p = frec + 4 + 4 * n
            # Version 2 (`01 00 01 02'): the string record names the one
            # source file.  Version 4 (`01 00 01 04', the cc 6.9 era
            # compilers): it lists every file the unit read, NUL-separated,
            # the inserts in reverse order of opening (newest first:
            # /sys/ins/base.ins.pas, always included first, is always the
            # last of them) and the unit's own source last; a timestamp record (tag 0x03, count.l, then
            # (time.l, name offset.l) pairs) follows it.  An assembly
            # unit's (c_data.asm) string record follows its block records
            # instead: take the unit's first 0x1B record.
            if b[p] != 0x1B:
                q = b.find(b'\x1b\x00', frec, base + length)
                while q >= 0 and (q - base) & 1:
                    q = b.find(b'\x1b\x00', q + 1, base + length)
                p = q if q >= 0 else p
            files = []
            if b[p] == 0x1B:
                flen = u32(p + 2)
                files = [x.decode('latin1') for x in b[p + 6:p + 6 + flen].split(b'\0') if x]
            source = (files[-1] if b[base + 3] >= 4 else files[0]) if files else None
            if source is None and bases and len(fsrc) == len(bases):
                source = fsrc[bases.index(base)] if base in bases else None
            text = code[0][1] if code else None
            if len(code) > 1:
                a5 = code[max(size, key=size.get)][2] if size else code[0][2]
            else:
                a5 = code[0][2] if code and n >= 5 else None
            out.append({'offset': base, 'source': source, 'text': text, 'a5': a5,
                        'code': code, 'blocks': blocks, 'symbols': [],
                        'version': b[base + 3], 'files': files})
            if bases:
                later = [x for x in bases if x > base]
                if not later:
                    break
                base = later[0]
            else:
                base = (base + length + 3) & ~3
        if not out:
            raise SystemExit('%s: .blocks has no unit' % self.path)
        fs = {src: syms for src, syms in self.file_symbols()}
        for u in out:
            if not u['blocks']:
                u['symbols'] = [(nm, v) for nm, v, _, _ in fs.get(u['source'], [])]
        return out

    def blocks(self):
        """[(name, level, address, code length)] from .blocks, every
        unit's (units()), in record order: a unit's 26-byte header (+8 the
        number of blocks.w, +0xA the first block record's offset.l), the
        name strings, then one 40-byte record per block, reached through
        the links (tag 0x04; offsets.l signed from the record's own start:
        +4 its next sibling, +8 its first child, 0 for none, +0xC its
        name; +2 the kind.w, 0 a module, 0x100 the program, 0x200 a
        procedure, 0x300 a function; +24 the code length.l, +28 the code
        section's cell number.w (0x0004: .text in a program), +30 the
        offset from that section's start.l).  The first record is the unit's
        program's or module's; a block's level is its depth in that tree,
        the program and its siblings 1 (a Fortran program's other units
        are its siblings), a module's routines 2."""
        return [blk for u in self.units() for blk in u['blocks']]


class CoffImage:
    """pascal_progress's image interface over a COFF file's initialized sections."""

    def __init__(self, coff):
        self.coff = coff

    def read(self, va, n):
        """n bytes at va, which must lie in a loaded section with file
        bytes; what follows it comes from the address space as loaded
        (the next sections' bytes, 0 between them), as the kernel image
        has bytes past a routine's end.  None in .data (built by the
        loader) or outside the sections."""
        loaded = [(sva, sz, off) for name, sva, sz, off, _, _ in self.coff.sections
                  if sva and name not in ('.blocks', '.lines')]
        if not any(off and sva <= va < sva + sz for sva, sz, off in loaded):
            return None
        out = bytearray(n)
        for sva, sz, off in loaded:
            lo, hi = max(va, sva), min(va + n, sva + sz)
            if off and lo < hi:
                out[lo - va:hi - va] = self.coff.data[off + lo - sva:off + hi - sva]
        return bytes(out)


class CoffLinkMap:
    """pascal_progress's link-map interface: the program's code segment is
    .text, its data block .data.  A library's other named sections (dpc's
    `[section(invoke_code, invoke_pure_data$)]' code and a `var (sect)'
    block) are found by name."""

    def __init__(self, coff, mapaddr, data_base=None):
        t, d = coff.section('.text'), coff.section('.data')
        self.text, self.data = (t[1], t[2]), (data_base or d[1], d[2])
        self.module_segments = [('I', t[1], t[2], '.text', None),
                                ('D', d[1], d[2], '.data', None)]
        self.named = {s[0].upper(): s[1] for s in coff.sections
                      if s[0] not in ('.text', '.data') and s[1]}
        self.numbered = []
        self.symbols = {n: (a, 0) for n, a in mapaddr.items()}

    def module_segment(self, kind, module, section):
        if section and section.upper() in self.named:
            return self.named[section.upper()], []
        return (self.text[0] if kind == 'I' else self.data[0]), []


def names(coff, unit=None):
    """mapaddr (upper-cased name -> address) and the routines' starts.
    The routines of every unit are named, those of unit (one of
    coff.units(), the file being compared) first: a name two units use
    (calendar's nested `wt' in calendar.pas and disk_passign.pas) is
    unit's.  The starts are every unit's.  A library (no .aptv) adds its
    assembly units' routines and its symbol table's other definitions (the
    exported routines' thunks, the data sections), after the .blocks
    names."""
    mapaddr, starts = {}, []
    units = coff.units()
    for u in ([unit] if unit else []) + [u for u in units if u is not unit]:
        for name, _, start, _ in u['blocks']:
            mapaddr.setdefault(name.upper(), start)
            starts.append(start)
    for va, sym, _ in coff.relocations('.aptv'):
        if sym:
            mapaddr.setdefault(sym.upper(), va - 2)     # the slot's jmp
    if not coff.section('.aptv'):
        for u in units:
            for name, va in u['symbols']:
                mapaddr.setdefault(name.upper(), va)
                if coff.code_section_at(va):
                    starts.append(va)
        for _, name, value, scnum, sclass, _ in coff.symtab:
            if scnum > 0 and sclass in (2, 3, 110) and not name.startswith('.'):
                mapaddr.setdefault(name.upper(), value)
    return mapaddr, sorted(set(starts))


def pick_unit(coff, prog, want=None):
    """The unit a source file is compared with: the one whose source
    path's last component, less `.pas', is want (--unit) or else prog
    (the file's own name); the only one when the binary has one."""
    units = coff.units()
    key = (want or prog).lower()
    if '/' in key:
        # a path less `.pas' (two units of one name: lang/lang/source/
        # token.pas and lang/common/source/token.pas)
        hits = [u for u in units if u['source'] and
                os.path.splitext(u['source'])[0].lower().endswith('/' + key.lstrip('/'))]
        key = key.split('/')[-1]
    else:
        hits = [u for u in units if u['source'] and
                os.path.splitext(u['source'].split('/')[-1])[0].lower() == key]
    if len(hits) == 1:
        return hits[0]
    if len(units) == 1 and not want:
        return units[0]
    raise SystemExit('%s: no single unit from %s.pas (units: %s)' % (
        coff.path, key, ', '.join(u['source'] or '?' for u in units)))


def data_base(coff, unit):
    """The unit's data block's address: .data's start for a binary of one
    unit (its extern-address cells lie below A5, acl's 12 bytes); else
    the unit's A5, less any .rwdi cells relocated against an external
    that lie right below it (none in calendar).  None when the unit has
    no data block.  A library's unit (no .aptv): its A5, the cells below
    it being the pure data's, not the module's variables."""
    if len(coff.units()) == 1:
        return coff.section('.data')[1]
    if unit['a5'] is None:
        return None
    if not coff.section('.aptv'):
        return unit['a5']
    # .rwdi records (Coff.rwdi()): a longword relocated against an
    # external is an extern-address cell
    relocs = {va for va, _, _ in coff.relocations('.rwdi')}
    cells = set()
    for kind, rva, addr, data in coff.rwdi():
        if kind in (0, 2):
            for k in range(0, len(data), 4):
                if rva + 10 + k in relocs:
                    cells.add(addr + k)
    base = unit['a5']
    while base - 4 in cells:
        base -= 4
    return base


def default_binary(program):
    """The install's com/<name> for the program's file name, or else for
    the nearest directory of its path that is one (com/calendar/common/
    hex_io.pas -> com/calendar); a file under lib/<name>/ is a unit of the
    install's lib/<name> (lib/pmlib/loader.pas -> lib/pmlib)."""
    path = os.path.abspath(program)
    d = os.path.dirname(path)
    while d and d != os.path.dirname(d):
        if os.path.basename(os.path.dirname(d)) == 'lib':
            f = os.path.join(pp.INSTALL, 'lib', os.path.basename(d))
            if os.path.isfile(f):
                return f
        d = os.path.dirname(d)
    cand = [os.path.splitext(os.path.basename(path))[0]]
    d = os.path.dirname(path)
    while d and d != os.path.dirname(d):
        cand.append(os.path.basename(d))
        d = os.path.dirname(d)
    for c in cand:
        f = os.path.join(pp.INSTALL, 'com', c)
        if os.path.isfile(f):
            return f
    return os.path.join(pp.INSTALL, 'com', cand[0])


AEGIS_HEADER = b'\x00\x20\x00\x01'     # a 32-byte Aegis type header's start


def aegis_text(data):
    """A file of the install as text: a 32-byte Aegis header stripped, and
    a `rec' file's records (a 4-byte count including itself, the data,
    padded to an even length) joined; a `uasc' file is plain text after
    the header (as rbak's convert_rec and domain-pascal's corpus.py)."""
    if not data.startswith(AEGIS_HEADER) or len(data) < 32:
        return data
    body, out, i = data[32:], [], 0
    while i < len(body):
        n = int.from_bytes(body[i:i + 4], 'big') if i + 4 <= len(body) else 0
        if n < 4 or i + n > len(body):
            return body
        out.append(body[i + 4:i + n])
        i += n + (n & 1)
    return b''.join(out) if body else body


def aegis_root():
    """The `/' dpc includes from: the install's sys/ins inserts as text,
    mirrored under ../tmp/coff_compare/root (refreshed when the install's
    copy is newer)."""
    root = os.path.join(pp.ROOT, '..', 'tmp', 'coff_compare', 'root')
    src = os.path.join(pp.INSTALL, 'sys', 'ins')
    dst = os.path.join(root, 'sys', 'ins')
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(src):
        if not f.endswith('.ins.pas'):
            continue
        a, b = os.path.join(src, f), os.path.join(dst, f)
        if not os.path.exists(b) or os.path.getmtime(b) < os.path.getmtime(a):
            with open(a, 'rb') as i, open(b, 'wb') as o:
                o.write(aegis_text(i.read()))
    return os.path.abspath(root)


def compile_program(pas, work, extra):
    """dpc and as over the program: `/' the decoded inserts (aegis_root),
    and the repository's top (where com/ is) on the include path."""
    s, o = os.path.join(work, 'prog.s'), os.path.join(work, 'prog.o')
    top = os.path.abspath(os.path.join(pp.ROOT, '..'))
    p = subprocess.run([pp.DPC, '--root', aegis_root(), '-I', top] + extra + ['-o', s, pas],
                       capture_output=True, text=True)
    sys.stderr.write(p.stderr)
    if p.returncode or not os.path.exists(s):
        raise SystemExit('dpc failed (%d)' % p.returncode)
    a = subprocess.run([pp.AS, '-m68020', '-o', o, s], capture_output=True, text=True)
    if a.returncode:
        raise SystemExit('as failed:\n' + a.stderr)
    return o


def main():
    argv = sys.argv[1:]
    extra = []
    if '--' in argv:
        k = argv.index('--')
        argv, extra = argv[:k], argv[k + 1:]
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('program', nargs='?')
    ap.add_argument('--list', action='store_true',
                    help='print the binary\'s units and routines (with PROGRAM, its unit only)')
    ap.add_argument('--binary', help='the COFF file (default: the install\'s com/<program>)')
    ap.add_argument('--diff', action='store_true', help='show the first differing runs')
    ap.add_argument('--keep', help='keep the .s and .o in this directory')
    ap.add_argument('--unit', help='the binary\'s unit to compare with, by its source '
                    'file\'s name less .pas (default: the program file\'s name)')
    a = ap.parse_args(argv)
    if not a.program and not (a.list and a.binary):
        ap.error('PROGRAM is required (or --list --binary PATH)')
    binary = a.binary or default_binary(a.program)
    coff = Coff(binary)
    if a.list:
        units = coff.units()
        if a.program or a.unit:
            units = [pick_unit(coff, os.path.splitext(os.path.basename(
                a.program or ''))[0], a.unit)]
        list_units(coff, units)
        return
    prog = os.path.splitext(os.path.basename(a.program))[0]
    unit = pick_unit(coff, prog, a.unit)
    mapaddr, starts = names(coff, unit)

    def next_after(va):
        """The next routine's start, or the end of va's code section."""
        sec = coff.code_section_at(va) or coff.section('.text')
        end = sec[1] + sec[2]
        i = bisect.bisect_right(starts, va)
        return min(starts[i], end) if i < len(starts) else end

    work = a.keep or tempfile.mkdtemp(prefix='coff_compare.')
    os.makedirs(work, exist_ok=True)
    obj = compile_program(os.path.abspath(a.program), work, extra)
    image, linkmap = CoffImage(coff), CoffLinkMap(coff, mapaddr, data_base(coff, unit))
    res = pp.compare_object(obj, linkmap, image, mapaddr, next_after, local_routines=True)
    print('dpc: %s; binary %s%s' % (pp.DPC, binary, '' if len(coff.units()) == 1
                                     else ', unit %s' % unit['source']))
    count, shown, seen = {}, [], set()
    for r in res['routines']:
        count[r['status']] = count.get(r['status'], 0) + 1
        shown.append(r)
        seen.add(r['name'].upper())
        st = r['status'] + (' (%d bytes)' % r['diff'] if r.get('diff') else '')
        if r.get('similarity') is not None:
            st += ' sim %.4f' % r['similarity']
            if r.get('similarity_noreg') is not None:
                st += ' (%.4f mod regs)' % r['similarity_noreg']
        va = mapaddr[r['name'].upper()]
        print('%-20s %-44s ours 0x%X, binary 0x%X at 0x%X, %d unverified reloc(s)'
              % (r['name'], st, r['size'], r['map_size'] or 0, va, r.get('unverified', 0)))
        if a.diff and r['status'] == 'same-pcrel':
            for x in r['pcrel']:
                print('    +0x%X (0x%06X) %s: ours -> +0x%X, binary -> 0x%06X: %s'
                      % (x['off'], va + x['off'], x['insn'], x['ours'], x['image'], x['why']))
        elif a.diff and r['status'] != 'same':
            if r.get('not_pcrel'):
                print('    not same-pcrel: %s' % r['not_pcrel'])
            show_diff(obj, r['name'], va, image)
    missing = [n for n, _, _, _ in unit['blocks'] if n.upper() not in seen]
    if missing:
        print('not in our object: %s' % ', '.join(missing))
    order = ['same', 'same-pcrel', 'same-placement', 'differs', 'size differs']
    mean, n = pp.mean_similarity(shown)
    noreg, _ = pp.mean_similarity(shown, 'similarity_noreg')
    print('%d routine(s): %s; %s' % (sum(count.values()), ', '.join(
        '%d %s' % (count[k], k) for k in order + sorted(set(count) - set(order))
        if k in count), pp.sim_text(mean, n, noreg)))


def list_units(coff, units):
    """--list: each unit's source, code sections (start, A5), data, and
    routines (address, length, level) or, for an assembly unit, its
    symbols; then the library's extern cells by unit A5."""
    cells = coff.cells()
    a5s = sorted({a5 for u in coff.units() for _, _, a5 in u['code'] if a5})
    for u in units:
        print('%s' % (u['source'] or '?'))
        for sec, start, a5 in u['code']:
            print('    code %-18s 0x%06X  A5 %s' % (sec, start, '0x%06X' % a5 if a5 else '-'))
        if u['a5'] is not None:
            print('    data base (A5) 0x%06X' % u['a5'])
        for name, level, va, length in sorted(u['blocks'], key=lambda b: b[2]):
            sec = coff.code_section_at(va)
            print('    %-34s 0x%06X 0x%-5X level %d %s' % (name, va, length, level,
                                                         sec[0] if sec else '?'))
        for name, va in sorted(u['symbols'], key=lambda x: x[1]):
            sec = coff.code_section_at(va)
            print('    %-34s 0x%06X (symbol%s)' % (name, va, ', code' if sec else ''))
        for _, _, a5 in u['code']:
            if a5 is None:
                continue
            lo = max([x for x in a5s if x < a5] or [0])
            below = sorted((c, n) for c, n in cells.items() if lo <= c < a5)
            for c, n in below:
                print('        cell A5-%-5d %s' % (a5 - c, n))
    print('%d unit(s), %d routine(s), %d cell(s)' % (
        len(units), sum(len(u['blocks']) for u in units), len(cells)))


def show_diff(obj, name, va, image):
    import routine_compare
    routine_compare.show_diff(obj, name, va, image)


if __name__ == '__main__':
    main()
