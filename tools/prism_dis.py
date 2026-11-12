#!/usr/bin/env python3
"""prism_dis.py - disassemble the text of an Apollo a88k (PRISM, DN10000) COFF file.

    tools/prism_dis.py FILE [--prasm] [--routine NAME ...] [--range LO HI] [--all]
    tools/prism_dis.py FILE --stats [-v]      the decode and control-flow checks
    tools/prism_dis.py --table                the decode table, opcode by opcode

The decoder is built from DOMAIN C 6.9's own opcode tables, read from the
image (cc.a88k, --image to name another copy): instruction_assembly (the
register form's and the immediate form's templates, +0 and +4; each
operand's field kind, +36), instruction_attributes (each operand's form,
the class, the shown operand count, the access size), instruction_mnemonic
(the classic listing's names) and of_string (the forms' names).  asm.pas
(asm_$process_routine's pass 2) is the encoder this inverts:

- a word is matched against each opcode's register form (the template's
  fixed bits; the operand fields free), its immediate form (+4, a kind 4
  or 5 operand an immediate by its form) and, for a load or store, the
  modified form (+0 with bit 27: an 8-bit displacement, the addressing
  mode and qualifier); the opcode's own fields (the squash mode 19..18, a
  field's width 13..9, a load's or store's mode 10..9 and qualifier 8..7,
  load_pair's offset, the condition-code bits 14/26) are free too;
- opcodes with the same encoding are one entry (move/pmove, copys/movei,
  the conditional traps are their branches: asm encodes them so); when
  several entries match, the one whose fixed bits include every other's
  is taken (MOVE is ADD with R31, TST and CMP are SUB/ADD into R31, ...);
  a word that two unrelated entries match is `ambiguous';
- bit 31 of an integer word pairs it with the next word, a floating one
  (asm: +2 bit 7, a floating companion, or the NOP before a lone
  floating instruction; bin: the FNOP after a continued integer one, the
  second word of a floating control transfer, (word & 0xFFF) | 0xE40000):
  the next word is decoded against the floating classes (fp_double,
  fp_single, the FP-immediate class and the five-operand forms) only.

Symbols: the routines and their lengths from .blocks (versions 2 and 4
of the 6.x compilers' units; tools/coff_compare.py's reader) and, for
what .blocks does not describe (a stripped file, a version 3 unit), from
.unwind (a group's header: start, length << 7 | 4, the group's bytes, 0;
then a record per routine: start, length << 7, two words: the saved
R21..R12 in the third's bits 29..20, the registers at the frame's +4,
+12 and the return address's in the fourth's 31..27, 26..22, 21..17);
the symbol table's names; and the routine descriptors in .data (six
words, found by their shape, named by a symbol when there is one: LOADL
R0,[PC,0x14]; ADD R2 := PC + d (the unit's data base); MOVE R23,R1; B.SA
[R0]; the push (or R0 := -frame/8) in the slot; the code address: the
routine's start + 8 when its own first words push the frame, else its
start).

The listing: the location, the word, `+' for a word paired with the next,
then lst.pas's classic form (instruction_mnemonic, the size, qualifier,
squash and .CC suffixes, the operands: Rn, Sn, Dn, `#' before an
immediate of the forms lst marks, a memory operand as [disp,base] with
`++'/`--' for a modified base, a branch's register as [Rn], R30 as PC,
a literal pool displacement as lst's h'xxxxx-*) or with --prasm the
-PRASM form (the assignment at column 31, `;', the instruction_assembly
name and operands).  Targets and PC-relative data are given as addresses
with the symbol they fall in.

--stats walks every routine from its entry (the delay slot: run never
(.SN), when taken (.ST), when falling through (.SF), always (.SA); a
paired word and its floating companion one bundle; case dispatches
through their tables) and reports the decode counts on and off the
executed paths, calls (on a routine's start?), branches (inside their
routine?), PC-relative loads (on words no path executes?), data-base
references (R2/R21 + d inside the data?), the prologue and epilogue
shapes, the saved registers against .unwind, the registers read on
entry and after calls (docs/prism-isa.md, "Validated against SR10.4
binaries").
"""
import argparse
import bisect
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOP = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402

IMAGE = os.path.join(TOP, 'ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k')

# instruction classes (backend.ins.pas class$...)
ALU, BRANCH, CALL, FP_DOUBLE, ENTRY, FP_BRANCH, JUMP, ENABLE, IMMEDIATE, SEQ, SYNCH, LIMIT, \
    FP_CONTROL, IPCCNOP, TRAP, LOAD_PAIR, LOAD, FP_SINGLE, PMOVE, LABEL, SVC, STORE, MFPR, \
    MTPR, RETURN, TABLE, JOIN_BP, TRAP_COND = range(28)
FP_CLASSES = (FP_DOUBLE, IMMEDIATE, FP_SINGLE)
NO_WORD_CLASSES = (ENTRY, SEQ, LIMIT, IPCCNOP, TRAP, PMOVE, LABEL, TABLE, JOIN_BP, TRAP_COND)

# operand forms (of$t) by number: the ones the encoder treats specially
F_LONG_PC, F_BB, F_COMPARE, F_FPPAIR = 1, 2, 3, 4
SIGNED16 = {8, 10, 11, 24, 25, 27, 28, 29, 30}
UNSIGNED16 = {16, 20}
HIGH16 = {12, 14, 26}
IMMED8 = {7, 9}
SCALED = {7, 10, 21, 33, 34, 36, 37, 39, 42}
# lst marks an immediate of these forms with `#' (the set at 0x251734)
HASH_FORMS = {3} | set(range(6, 17)) | {20, 21} | set(range(23, 32)) | set(range(33, 41)) | {42}

SQUASH_NAMES = ['.SN', '.ST', '.SF', '.SA']
# asm: field = (57 >> 2 * mode) & 3; the inverse
FIELD_TO_MODE = {((57 >> (2 * m)) & 3): m for m in range(4)}
LSQ_CLASSIC = ['', '.L', '.U', '.P']
LSQ_PRASM = ['', '.LOCK', '.UNLOCK', '.PHYS']


def bits(hi, lo):
    return ((1 << (hi - lo + 1)) - 1) << lo


def sext(v, n):
    return v - (1 << n) if v & (1 << (n - 1)) else v


# --------------------------------------------------------------------------
# Apollo COFF (a88k magic 0x194, m68k 0x197)

class Coff(cc.Coff):
    """coff_compare.Coff's reader, for either Apollo magic."""

    def __init__(self, path):
        self.path = path
        d = self.data = open(path, 'rb').read()
        magic, nscns, _, symptr, nsyms, opthdr, _ = struct.unpack('>HHIIIHH', d[:20])
        if magic not in (0x194, 0x197):
            raise SystemExit('%s: not an Apollo COFF file (magic 0x%X)' % (path, magic))
        self.magic = magic
        strtab = symptr + 18 * nsyms

        def name8(e):
            if e[:4] == b'\0\0\0\0':
                o = strtab + struct.unpack('>I', e[4:8])[0]
                return d[o:d.index(b'\0', o)].decode('latin1')
            return e[:8].rstrip(b'\0').decode('latin1')
        self.sections, self.section_flags = [], {}
        off = 20 + opthdr
        for _ in range(nscns):
            s = d[off:off + 40]
            off += 40
            name = name8(s)
            _, va, sz, sp, rp, _, nr, _, fl = struct.unpack('>IIIIIIHHI', s[8:40])
            self.sections.append((name, va, sz, sp, rp, nr))
            self.section_flags[name] = fl
        self.symbols, self.symtab = {}, []
        i = 0
        while i < nsyms:
            e = d[symptr + 18 * i:symptr + 18 * (i + 1)]
            name = name8(e)
            self.symbols[i] = name
            value, scnum, _, sclass, naux = struct.unpack('>IhHBB', e[8:18])
            self.symtab.append((i, name, value, scnum, sclass,
                                d[symptr + 18 * (i + 1):symptr + 18 * (i + 1 + naux)]))
            i += 1 + naux

    def read(self, va, n):
        """The initial bytes at va (None for bytes nothing sets): the
        sections with file bytes, then .rwdi's copy and repeat records
        (tools/cc_data.py's rules: an a88k program's .data often has no
        file bytes)."""
        import cc_data
        return cc_data.initial(self, va, n)

    def word(self, va):
        b = self.read(va, 4)
        if None in b:
            return None
        return struct.unpack('>I', bytes(b))[0]


# --------------------------------------------------------------------------
# The opcode tables

class Opcode:
    pass


def load_tables(image):
    img = cc.Coff(image)

    def sec(name):
        b = img.contents(name)
        if b is None:
            raise SystemExit('%s: no section %s' % (image, name))
        return b
    asm, attr = sec('instruction_assembly'), sec('instruction_attributes')
    mn, mnl = sec('instruction_mnemonic'), sec('instruction_mnemonic_length')
    ofs, ofl = sec('of_string'), sec('of_string_length')
    forms = [ofs[34 * k:34 * k + struct.unpack('>H', ofl[2 * k:2 * k + 2])[0]].decode()
             for k in range(43)]
    ops = []
    for n in range(212):
        a = asm[44 * n:44 * n + 44]
        t = attr[20 * n:20 * n + 20]
        o = Opcode()
        o.num = n
        o.w0, o.w4 = struct.unpack('>II', a[:8])
        o.squash = bool(a[8] & 0x20)
        o.fiveop = bool(a[8] & 0x10)
        prasm_len = a[8] & 15
        o.name_len = a[9] >> 4
        o.half = (a[9] >> 1) & 7
        o.layout = a[10]
        o.prasm_op = a[11:11 + prasm_len].decode('latin1')
        o.aname = a[19:19 + o.name_len].decode('latin1')
        o.opnd = struct.unpack('>HHHH', a[36:44])
        o.mnem = mn[12 * n:12 * n + struct.unpack('>H', mnl[2 * n:2 * n + 2])[0]].decode('latin1')
        o.cls = t[7]
        o.nshown = t[11] & 7
        o.forms = [t[4 * k] for k in range(1, 5)]
        o.opnd_b2 = [t[4 * k + 2] for k in range(1, 5)]
        o.width_flag = bool(t[14] & 2)           # b14_7_1 odd
        o.cc_flag = bool(t[14] & 1)              # b14_0
        o.size_log2 = t[19] & 7
        o.kinds = [(o.opnd[k] & 0xF8) >> 3 for k in range(4)]
        o.fmts = [(o.opnd[k] & 6) >> 1 for k in range(4)]
        ops.append(o)
    return ops, forms


class Enc:
    """One encoding of an opcode: its template and the bits it fixes."""

    def __repr__(self):
        return '<%s %s %08X/%08X>' % (self.op.mnem, self.form, self.template, self.mask)


def operand_fields(op, k, form_kind):
    """The bits operand k (0-based) takes in the word, for the encoding
    form_kind 'R' (register), 'I' (immediate), 'M' (modified load/store)."""
    kind, form = op.kinds[k], op.forms[k]
    if kind == 0:
        return bits(4, 0)
    if kind in (1,):
        return bits(20, 16)
    if kind in (2, 3, 10):
        return bits(25, 21)
    if kind in (4, 5):
        if form_kind == 'R':
            return bits(4, 0) | (bits(6, 5) if form in SCALED else 0)
        if form_kind == 'M':
            return bits(6, 0) | bits(15, 15)
        if form in (F_LONG_PC, F_BB):
            return bits(17, 0)
        if form in IMMED8:
            return bits(6, 0) | bits(15, 15)
        if form in HIGH16:
            return bits(15, 0) | bits(27, 27)
        return bits(15, 0)
    if kind == 6:
        return bits(12, 0)                  # (a single's: its number times 4)
    if kind == 7:
        return bits(20, 16) | bits(8, 8)
    if kind == 8:
        return bits(25, 21) | bits(8, 8)
    if kind == 9:
        return bits(9, 6)
    if kind == 11:
        return bits(23, 18)
    if kind == 12:
        return bits(29, 24)
    if kind == 13:
        return bits(29, 25) | bits(0, 0)
    if kind == 14:
        return bits(11, 0)
    if kind == 15:
        return bits(5, 0)
    if kind == 16:
        return bits(11, 6)
    if kind == 17:
        return bits(17, 12)
    raise ValueError(kind)


def build_encodings(ops):
    """The encodings the decoder matches, duplicates folded."""
    encs = []
    prefer = {144: 0, 161: 0}           # COPYS, COPYD over MOVEI, PCOPYD ...
    for op in ops:
        if op.num == 0 or op.cls in NO_WORD_CLASSES:
            continue
        if op.w0 == 0 and op.w4 == 0 and op.num != 1 and not op.fiveop:
            continue                        # widenb/w, loadse, storese, dispatch ...
        n = op.nshown
        has_imm = any(op.kinds[k] in (4, 5) and op.forms[k] not in (18,) for k in range(n))
        variants = [('R', op.w0)]
        if has_imm and op.w4 not in (0,):
            variants.append(('I', op.w4))
        elif has_imm and op.num == 1:
            variants.append(('I', op.w4))
        if op.cls in (LOAD, STORE) and has_imm:
            variants.append(('M', op.w0 | (1 << 27)))
        space = 'fp' if (op.cls in FP_CLASSES) else 'int'
        for fk, tmpl in variants:
            if fk == 'R' and op.num == 1:
                continue                    # bnever's register form: 0, nothing
            free = 0
            for k in range(n):
                if op.kinds[k] in (4, 5) and fk == 'R' and op.forms[k] not in (18, 22) \
                        and op.forms[k] in (F_LONG_PC, F_BB) and op.num == 1:
                    continue
                free |= operand_fields(op, k, fk)
            if op.squash:
                free |= bits(19, 18)
            elif op.width_flag:
                free |= bits(13, 9)
            elif op.cls in (LOAD, STORE) and (fk in ('R', 'M')):
                free |= bits(10, 7)
            elif op.cls == LOAD_PAIR:
                free |= bits(10, 5) | bits(15, 14)
            elif op.cls == SYNCH:
                free |= bits(20, 16)
            op.cc_bit = None
            if op.cc_flag and space == 'int':
                # asm: bit 26 for an immediate compare-form operand 1 in
                # the immediate form, else bit 14 (in the floating classes
                # bit 14 is a register field's: their condition codes are
                # the floating ones, bit 24)
                e_cc = 26 if (fk == 'I' and op.forms[0] in (F_COMPARE, 10)) else 14
                free |= 1 << e_cc
            if space == 'int':
                free |= bits(31, 31)            # the pair bit
            elif not op.fiveop and op.num != 193:
                free |= bits(24, 24)            # sets the floating condition codes
            # a template bit inside a field is or-ed in (MFFP's and MTFP's
            # 0x100 under the register's number times 4): it must be set
            free &= ~tmpl
            if op.fiveop:
                # the multiply's fields stay (asm: the word is not cleared)
                free |= bits(17, 0)
                if op.w0 & 0xC0000000 == 0:
                    free &= ~bits(6, 6)         # the double forms: 6 and 0 say which
                    if op.num != 191:
                        free &= ~bits(0, 0)
            e = Enc()
            e.op, e.form, e.space = op, fk, space
            e.mask = 0xFFFFFFFF & ~free
            e.template = tmpl & e.mask
            e.alias = []
            dup = next((x for x in encs if x.mask == e.mask and x.template == e.template
                        and x.space == e.space), None)
            if dup:
                if prefer.get(op.num, 1) < prefer.get(dup.op.num, 1):
                    dup.alias.append(dup.op)
                    dup.op = op
                else:
                    dup.alias.append(op)
                continue
            encs.append(e)
    # the second word of a floating control transfer (bin)
    e = Enc()
    e.op = Opcode()
    e.op.__dict__.update(num=-1, mnem='FPCTL2', aname='FPCTL2', cls=FP_CONTROL, nshown=0,
                         squash=False, kinds=[], forms=[], fmts=[], layout=26, prasm_op='',
                         half=0, size_log2=0, width_flag=False, cc_flag=False, fiveop=False,
                         w0=0x00E40000, w4=0x00E40000, opnd_b2=[0] * 4)
    e.form, e.space, e.mask, e.template, e.alias = 'R', 'fp', 0xFFFFF000, 0x00E40000, []
    encs.append(e)
    return encs


# --------------------------------------------------------------------------
# Decoding

class Operand:
    """lst's view of an operand: kind 'r' (integer register), 's' (single),
    'd' (double), 'i' (immediate), 'b' (branch target), 'c' (call
    target), 'n' (none)."""

    def __init__(self, kind, num=0, value=0, scale=0):
        self.kind, self.num, self.value, self.scale = kind, num, value, scale

    def is_reg(self):
        return self.kind in 'rsd'


class Insn:
    pass


def decode_with(e, w, addr):
    """The instruction e makes of w at addr, or None when a field
    constraint fails."""
    op = e.op
    ins = Insn()
    ins.enc, ins.op, ins.word, ins.addr = e, op, w, addr
    ins.pair = e.space == 'int' and bool(w & 0x80000000)
    ins.modify = ins.lsq = 0
    ins.width = ins.offset = 0
    ins.cc = ins.fcc = False
    ins.opnds = []
    for k in range(op.nshown):
        kind, form = op.kinds[k], op.forms[k]
        fp = 'd' if form == F_FPPAIR else 's'
        if kind == 0:
            o = Operand('r', w & 31)
        elif kind == 1:
            o = Operand('r', (w >> 16) & 31)
        elif kind == 2:
            o = Operand('r', (w >> 21) & 31)
        elif kind == 3:
            n = ((w >> 21) & 31) * 2
            if op.mnem in ('LOADSO', 'STORESO'):
                o = Operand('s', n + 1)
            else:
                o = Operand(fp if form in (F_FPPAIR, 19) else 'd', n)
        elif kind == 10:
            o = Operand('s', ((w >> 21) & 31) * 2)
        elif kind in (4, 5):
            if e.form == 'R':
                o = Operand('r', w & 31, scale=(w >> 5) & 3 if form in SCALED else 0)
            elif e.form == 'M':
                o = Operand('i', value=(w & 127) - (128 if w & 0x8000 else 0))
            elif form in (F_LONG_PC, F_BB):
                o = Operand('c' if op.cls == CALL else 'b',
                            value=(addr + 4 * sext(w & 0x3FFFF, 18)) & 0xFFFFFFFF)
            elif form == F_COMPARE:
                o = Operand('i', value=-sext(w & 0xFFFF, 16))
            elif form in IMMED8:
                o = Operand('i', value=(w & 127) - (128 if w & 0x8000 else 0))
            elif form in HIGH16:
                v = w & 0xFFFF
                o = Operand('i', value=(v << 16) if w & (1 << 27) else v)
            elif form in UNSIGNED16:
                o = Operand('i', value=w & 0xFFFF)
            else:
                o = Operand('i', value=sext(w & 0xFFFF, 16))
        elif kind == 6:
            if form == 19:
                v = w & 8191 & ~e.op.w0
                if v & 3 or v >= 256:
                    return None
                o = Operand('s', v >> 2)
            else:
                o = Operand('i', value=w & 8191)
        elif kind == 7:
            o = Operand('i', value=(w >> 16) & 31) if w & 0x100 else Operand('r', (w >> 16) & 31)
        elif kind == 8:
            o = Operand('i', value=(w >> 21) & 31) if w & 0x100 else Operand('r', (w >> 21) & 31)
        elif kind == 9:
            o = Operand('i', value=(w >> 6) & 15)
        elif kind == 11:
            o = Operand(fp, (w >> 18) & 63)
        elif kind == 12:
            o = Operand(fp, (w >> 24) & 63)
        elif kind == 13:
            o = Operand('s', ((w >> 24) & 62) | (w & 1))
        elif kind == 14:
            if ((w >> 6) & 63) != (w & 63):
                return None
            o = Operand(fp, w & 63)
        elif kind == 15:
            o = Operand(fp, w & 63)
        elif kind == 16:
            o = Operand(fp, (w >> 6) & 63)
        elif kind == 17:
            o = Operand(fp, (w >> 12) & 63)
        else:
            return None
        if o.kind == 'd' and o.num & 1:
            return None                         # a double is an even/odd pair
        ins.opnds.append(o)
    if op.squash:
        ins.modify = FIELD_TO_MODE[(w >> 18) & 3]
    elif op.width_flag:
        ins.width = ((w >> 9) & 31) + 1
    elif op.cls in (LOAD, STORE) and e.form in ('R', 'M'):
        ins.modify, ins.lsq = (w >> 9) & 3, (w >> 7) & 3
    elif op.cls == LOAD_PAIR:
        ins.offset = ((w >> 5) & 63) | (64 if w & 0x4000 else 0)
        if w & 0x8000:
            ins.offset -= 128
    if op.cc_flag and e.space == 'int':
        if e.form == 'I' and op.forms[0] in (F_COMPARE, 10):
            ins.cc = bool(w & (1 << 26))
        else:
            ins.cc = bool(w & (1 << 14))
    if e.space == 'fp' and not op.fiveop:
        ins.fcc = bool(w & (1 << 24))
    if op.mnem in ('TSTB', 'TSTW', 'TST', 'CMP', 'CMPS', 'CMPD', 'TSTS', 'TSTD'):
        ins.cc = True
    return ins


class Decoder:
    def __init__(self, image=IMAGE):
        self.ops, self.forms = load_tables(image)
        self.encs = build_encodings(self.ops)
        self.by_space = {'int': [e for e in self.encs if e.space == 'int'],
                         'fp': [e for e in self.encs if e.space == 'fp']}
        self.cache = {}

    def decode(self, w, addr, space='int'):
        """(status, [insn]): status 'unique', 'specialized' (the most
        specific of nested matches), 'ambiguous' or 'none'."""
        key = (w, space)
        if key in self.cache:
            status, encs = self.cache[key]
        else:
            m = [e for e in self.by_space[space] if w & e.mask == e.template]
            m = [e for e in m if decode_with(e, w, 0) is not None]
            if not m:
                status = 'none'
            elif len(m) == 1:
                status = 'unique'
            else:
                pop = lambda e: bin(e.mask).count('1')  # noqa: E731
                best = max(m, key=lambda e: (pop(e), -e.op.num))
                # one match whose fixed bits every other's include: the
                # word is that general instruction, the others its
                # special cases (MOVE and TST are ADD into or from R31)
                general = [g for g in m if all(e.mask & g.mask == g.mask for e in m)]
                if all(e.mask & best.mask == e.mask for e in m):
                    status, m = 'specialized', [best] + [e for e in m if e is not best]
                elif general:
                    # special cases that overlap but do not nest (CMP #-1,R31
                    # is MOVE.CC #1,R31 is ADD.CC #1,R31,R31): one machine
                    # instruction, named by the most specific, then the
                    # lowest opcode
                    status, m = 'equivalent', [best] + [e for e in m if e is not best]
                else:
                    m.sort(key=lambda e: -pop(e))
                    status = 'ambiguous'
            encs = m
            self.cache[key] = (status, encs)
        return status, [decode_with(e, w, addr) for e in encs]


# --------------------------------------------------------------------------
# The binary: routines, symbols, descriptors

class Program:
    def __init__(self, path, dec):
        self.coff = c = Coff(path)
        self.dec = dec
        self.texts = [s for s in c.sections if c.section_flags.get(s[0], 0) & 0x20
                      and s[0] != '.unwind' and s[3]]
        self.routines = []                  # (start, length, name, unit)
        try:
            for u in c.units():
                for name, level, start, length in u['blocks']:
                    self.routines.append((start, length, name, u))
        except SystemExit:
            pass
        self.routines.sort(key=lambda r: r[0])
        self.starts = [r[0] for r in self.routines]
        self.labels = {}                    # address -> name
        self.tables = []                    # case tables (address, entry size, count, dispatch)
        for start, length, name, u in self.routines:
            self.labels.setdefault(start, name)
        self.data_syms = {}
        self.descriptors = {}               # code address -> descriptor name
        self.desc_words = {}                # code address -> the stub's six words
        for _, name, value, scnum, sclass, _ in c.symtab:
            if scnum <= 0 or name.startswith('.'):
                continue
            sname = c.sections[scnum - 1][0]
            if c.section_flags.get(sname, 0) & 0x20 and sname != '.unwind':
                self.labels.setdefault(value, name)
            else:
                self.data_syms.setdefault(value, name)
                tgt = self.descriptor_target(value)
                if tgt is not None:
                    self.descriptors.setdefault(tgt, name)
                    self.desc_words.setdefault(tgt, struct.unpack('>6I', bytes(self.coff.read(value, 24))))
        self.text_lo = min((s[1] for s in self.texts), default=0)
        self.text_hi = max((s[1] + s[2] for s in self.texts), default=0)
        self.dsyms = sorted(self.data_syms.items())
        # descriptors without a symbol (a stripped file): the stub's shape
        # anywhere in .data
        self.desc_db = {}                   # code address -> the R2 its descriptor sets
        d = c.section('.data')
        if d:
            mem = c.read(d[1], d[2])
            for o in range(0, len(mem) - 23, 4):
                if mem[o:o + 4] != [0x60, 0x1E, 0x00, 0x14] or mem[o + 12:o + 16] != [0x24, 0x30, 0, 0]:
                    continue
                if None in mem[o:o + 24] or mem[o + 4] != 0x18 or mem[o + 5] != 0x5E:
                    continue
                w = struct.unpack('>6I', bytes(mem[o:o + 24]))
                va = d[1] + o
                self.desc_words.setdefault(w[5], w)
                self.descriptors.setdefault(w[5], self.data_syms.get(va, 'desc_%X' % va))
                self.desc_db[w[5]] = va + 4 + sext(w[1] & 0xFFFF, 16)
        # the routines .blocks does not describe (a stripped file, a
        # version 3 .blocks unit, an assembly unit) from .unwind
        nb = len(self.routines)
        covered = [(r[0], r[0] + r[1]) for r in self.routines]
        for start, length, w2, w3 in self.unwind_entries():
            if any(lo <= start < hi for lo, hi in covered):
                continue
            name = self.labels.get(start) or self.descriptors.get(start) or \
                self.descriptors.get(start + 8) or 'sub_%X' % start
            self.routines.append((start, length, name, None))
        self.routines_from = '.blocks' if len(self.routines) == nb else \
            ('.unwind' if not nb else '.blocks+.unwind')
        self.routines.sort(key=lambda r: r[0])
        self.starts = [r[0] for r in self.routines]
        for start, length, name, u in self.routines:
            self.labels.setdefault(start, name)
        # each routine's data base: its unit's A5, or the R2 its descriptor sets
        # (a routine without one: the previous routine's, the same unit's)
        self.db = {}
        last = None
        for start, length, name, u in self.routines:
            v = (u or {}).get('a5') or self.desc_db.get(start) or self.desc_db.get(start + 8)
            if v is None and u is None:
                v = last
            self.db[start] = v
            last = v
        self.unwind = {e[0]: e for e in self.unwind_entries()}

    def unwind_entries(self):
        """The routines of .unwind: groups of 16-byte records, a group's
        header (its start, its length << 7 | 4, the group's bytes, 0)
        before its routines' records (start, length << 7 | flags, two words:
        the first's bits 29..20 the saved R21..R12)."""
        u = self.coff.contents('.unwind')
        out = []
        if not u:
            return out
        for o in range(0, len(u) - 15, 16):
            w = struct.unpack('>4I', u[o:o + 16])
            if w[1] & 4 or not self.in_text(w[0]):
                continue
            out.append((w[0], w[1] >> 7, w[2], w[3]))
        return out

    def descriptor_target(self, va):
        """A routine descriptor's code address (the routine's start + 8),
        or None: LOADL R0,[PC,0x14]; ADD R2 := PC + n; word; B [R0]; word;
        the address."""
        b = self.coff.read(va, 24)
        if None in b:
            return None
        w = struct.unpack('>6I', bytes(b))
        if w[0] != 0x601E0014 or w[3] != 0x24300000 or w[1] & 0xFFFF0000 != 0x185E0000:
            return None
        return w[5]

    def text_word(self, va):
        for name, sva, sz, off, _, _ in self.texts:
            if sva <= va < sva + sz:
                return struct.unpack('>I', self.coff.data[off + va - sva:off + va - sva + 4])[0]
        return None

    def in_text(self, va):
        return any(s[1] <= va < s[1] + s[2] for s in self.texts)

    def routine_at(self, va):
        i = bisect.bisect_right(self.starts, va) - 1
        if i >= 0:
            start, length, name, u = self.routines[i]
            if start <= va < start + length:
                return self.routines[i]
        return None

    def where(self, va):
        """`name+off' for a code or data address."""
        r = self.routine_at(va)
        if r:
            return r[2] + ('+0x%X' % (va - r[0]) if va != r[0] else '')
        if va in self.labels:
            return self.labels[va]
        if self.dsyms:
            i = bisect.bisect_right(self.dsyms, (va, '\xff')) - 1
            if i >= 0 and va - self.dsyms[i][0] < 0x10000:
                v, n = self.dsyms[i]
                return n + ('+0x%X' % (va - v) if va != v else '')
        return None

    def decode_range(self, lo, hi):
        """[(addr, word, status, insns, space)] for lo..hi, with the pairing."""
        out = []
        space = 'int'
        a = lo
        while a < hi:
            if a in self.labels:
                space = 'int'                   # a routine starts with an integer word
            w = self.text_word(a)
            if w is None:
                w = self.coff.word(a) or 0     # a descriptor in .data (--range)
            status, insns = self.dec.decode(w, a, space)
            used = space
            if status == 'none' and space == 'fp':
                # not a floating word: try it as an integer one
                st2, in2 = self.dec.decode(w, a, 'int')
                if st2 != 'none':
                    status, insns, used = st2, in2, 'int'
                    status = status + '-after-pair'
            out.append((a, w, status, insns, used))
            space = 'fp' if (used == 'int' and insns and insns[0].pair) else 'int'
            a += 4
        return out


# --------------------------------------------------------------------------
# The listing (lst.pas)

def add_hex(n):
    n &= 0xFFFFFFFF
    return ("h'%X" % n) if n > 9 else '%X' % n


def fmt_int(n):
    return str(n)


class Lister:
    def __init__(self, prog, prasm=False):
        self.prog, self.prasm = prog, prasm

    def reg(self, ins, k):
        o = ins.opnds[k]
        if not self.prasm:
            s = {'r': 'R', 's': 'S', 'd': 'D'}[o.kind] + str(o.num)
            if o.kind == 'r' and o.scale:
                s += '*' + '1248'[o.scale]
            return s
        if o.kind == 'r':
            s = '.%d' % o.num
            if o.scale:
                s += '*' + '1248'[o.scale]
            return s
        if o.kind == 's':
            return '.FS%d' % o.num + ('.H' if ins.op.half & (1 << k) else '')
        return '.FD%d' % o.num

    def is_pc(self, ins, k):
        o = ins.opnds[k]
        return o.kind == 'r' and o.num == 30

    def memop_index(self, ins):
        """(displacement operand, base operand) of a load or store, 0-based."""
        c = ins.op.cls
        if c in (LOAD, MFPR):
            return 0, 1
        if c in (STORE, MTPR):
            return 1, 2
        return None, None

    def implied(self, ins):
        d, b = self.memop_index(ins)
        if d is None or d >= len(ins.opnds):
            return False
        o = ins.opnds[d]
        if o.kind != 'i' or self.is_pc(ins, b):
            return False
        size = 1 << ins.op.size_log2
        return o.value == 0 or (ins.modify != 0 and o.value in (size, -size))

    def operand(self, ins, k, fmt=0):
        o = ins.opnds[k]
        if o.is_reg():
            if o.kind == 'r' and o.num == 30:
                return '.PC' if self.prasm else 'PC'
            return self.reg(ins, k)
        if o.kind in 'bc':
            return 'h\'%X' % o.value
        if fmt == 2:
            return add_hex(o.value)
        if self.prasm and ins.op.forms[k] == F_COMPARE:
            return fmt_int(-o.value)
        return fmt_int(o.value)

    def pool_disp(self, ins, k):
        o = ins.opnds[k]
        return "h'%05X-*" % ((ins.addr + o.value) & 0xFFFFF)

    def classic(self, ins):
        op = ins.op
        name = op.mnem
        if name == 'JUMP' and ins.opnds[0].kind == 'r' and ins.opnds[0].num == 22:
            name = 'RETURN'                     # the same word (opcodes 69, 132)
        if op.cls in (LOAD, STORE):
            name += LSQ_CLASSIC[ins.lsq]
        elif op.squash:
            name += SQUASH_NAMES[ins.modify]
        if ins.cc or ins.fcc:
            name += '.CC'
        parts = []
        dk, bk = self.memop_index(ins)
        implied = self.implied(ins)
        k = 0
        n = len(ins.opnds)
        while k < n:
            o = ins.opnds[k]
            pre = ''
            if op.width_flag and op.opnd_b2[k] & 0xC0:
                pre = '#%d,' % ins.width
            if k == dk and bk is not None and bk < n:
                pc = self.is_pc(ins, bk)
                if o.kind == 'i' and pc:
                    disp = self.pool_disp(ins, k)
                elif o.kind == 'i':
                    v = o.value
                    disp = fmt_int(-v if (ins.modify and v < 0) else v)
                else:
                    disp = self.reg(ins, k)
                base = self.operand(ins, bk)
                neg = o.kind == 'i' and o.value < 0
                mm = '--' if neg else '++'
                if ins.modify == 1:
                    s = ('' if implied else self.operand(ins, k) + ',') + base + mm
                elif ins.modify == 2:
                    s = ('' if implied else disp + ',') + mm + base
                else:
                    s = ('' if implied else disp + ',') + base
                parts.append(pre + '[' + s + ']')
                k += 2
                continue
            if op.squash and o.kind == 'r' and op.forms[k] in (F_LONG_PC, F_BB):
                parts.append('[' + self.reg(ins, k) + ']')
            elif op.cls == LOAD_PAIR and k == 0:
                parts.append('[' + ('%d,' % ins.offset if ins.offset else '') + self.reg(ins, k) + ']')
            else:
                h = '#' if (not o.is_reg() and o.kind == 'i' and op.forms[k] in HASH_FORMS) else ''
                parts.append(pre + h + self.operand(ins, k, op.fmts[k]))
            k += 1
        return '%-10s %s' % (name, ','.join(parts))

    # -PRASM (lst_$prasm_display_code_cell and the opcode column)
    def p_opa(self, ins, k, hash_, implied):
        o = ins.opnds[k]
        if o.is_reg():
            return self.reg(ins, k)
        if implied:
            return ''
        s = '#' if hash_ else ''
        v = o.value
        if o.kind in 'bc':
            return s + add_hex(v)
        if v >= 0:
            return s + add_hex(v)
        if ins.modify:
            return s + add_hex(-v)
        return s + '-' + add_hex(-v)

    def p_cc(self, ins):
        return '.CC' if ins.cc else ('.FCC' if ins.fcc else '')

    def p_branch(self, ins, k):
        o = ins.opnds[k]
        if o.kind == 'r':
            return '[' + self.reg(ins, k) + ']'
        return add_hex(o.value)

    def p_addr(self, ins, implied):
        c = ins.op.cls
        base, d = {LOAD_PAIR: (0, None), LOAD: (1, 0), STORE: (2, 1)}.get(c, (None, None))
        if base is None:
            return '?'
        sign = '+'
        if d is not None and ins.opnds[d].kind == 'i' and ins.opnds[d].value < 0:
            sign = '-'
        s = '['
        if ins.modify == 2:
            s += sign * 2
        s += self.operand(ins, base)
        if ins.modify == 1:
            s += sign * 2
        if not implied:
            s += ','
            if c == LOAD_PAIR:
                s += add_hex(ins.offset)
            else:
                s += self.p_opa(ins, d, False, False)
        return s + ']' + self.p_suffix(ins)

    def p_suffix(self, ins):
        m = ins.op.mnem
        s = {'LOADBU': '.B', 'STOREB': '.B', 'LOADWU': '.S', 'STOREW': '.S', 'LOADL': '.L',
             'STOREL': '.L', 'LOAD_PAIR': '.Q', 'LOADS': '.FS', 'STORES': '.FS',
             'LOADSO': '.FS', 'STORESO': '.FS', 'LOADD': '.FD', 'STORED': '.FD'}.get(m, '.?')
        if m != 'LOAD_PAIR':
            s += LSQ_PRASM[ins.lsq]
        return s

    def prasm_form(self, ins):
        op = ins.op
        lay, opn = op.layout, op.prasm_op
        imp = self.implied(ins)
        r = lambda k: self.reg(ins, k) if k < len(ins.opnds) else '?'  # noqa: E731
        a = lambda k, h=True: self.p_opa(ins, k, h, imp) if k < len(ins.opnds) else '?'  # noqa: E731

        def lhs(k):
            return (r(k) if k >= 0 else '') + self.p_cc(ins) + ' = '
        num = op.num
        if lay == 1:
            return '%s %s= %s' % (r(1), opn, a(0))
        if lay == 2:
            return '%s = %s %s %s' % (r(2) + self.p_cc(ins), r(0), opn, a(1))
        if lay in (3, 24):
            if num in (173, 156, 74):
                head = self.p_cc(ins)
            else:
                head = r(2) + self.p_cc(ins)
                if len(ins.opnds) > 2 and ins.opnds[2].num == ins.opnds[1].num and \
                        lay != 24 and len(opn) <= 2:
                    return '%s %s= %s' % (head, opn, a(0))
            return '%s = %s%s %s %s' % (head, 'C + ' if lay == 24 else '', r(1), opn, a(0))
        if lay == 4:
            return '%s%s %s' % (opn, SQUASH_NAMES[ins.modify], self.p_branch(ins, 0))
        if lay == 5:
            return '%s%s%s %s' % (lhs(1), opn, SQUASH_NAMES[ins.modify], self.p_branch(ins, 0))
        if lay == 6:
            return 'BNEVER.SA [.31], %s%s' % ('NO_TRAP, ' if num == 127 else '', opn)
        if lay == 7:
            return '%sEXTEND(%s,%s)' % (lhs(1), r(0), opn)
        bf = lambda k: '<%s,%s>' % (a(k, False), add_hex(ins.width))  # noqa: E731
        if lay == 8:
            return '%s%s%s' % (lhs(2), r(0), bf(1))
        if lay == 9:
            return '%s%s%s = %s<0' % (r(2), bf(1), self.p_cc(ins), r(0))
        if lay == 10:
            return '%s%s%s = %s' % (r(2), bf(1), self.p_cc(ins), a(0))
        if lay == 11:
            return '%s%s(%s%s)' % (lhs(2), opn, r(0), bf(1))
        if lay in (12, 21):
            return '%s%s%s%s%s' % (lhs(1), opn, '(' if lay == 12 else '', r(0),
                                   ')' if lay == 12 else '')
        if lay == 13:
            return lhs(2) + self.p_addr(ins, imp)
        if lay == 14:
            return lhs(1) + a(0)
        if lay == 15:
            return '%s%s(%s<0,%d>,%s)' % (lhs(2), opn, r(0), ins.width, a(1, False))
        if lay == 16:
            return '%s%s(%s)' % (lhs(-1), opn, r(0))
        if lay == 17:
            return '(%s,%s)%s = %s' % (r(1), r(2), '.CC' if ins.cc else '', self.p_addr(ins, imp))
        if lay == 18:
            return '%s( %s) - %s' % (lhs(2), a(0), r(1))
        if lay == 19:
            return '%s = %s' % (self.p_addr(ins, imp), r(0))
        if lay == 20:
            return '%s%s?' % (lhs(-1), r(0))
        if lay == 23:
            return '%s #%d' % (opn, ins.opnds[0].value if ins.opnds else 0)
        if lay == 25:
            return '.31.CC = EXTEND( %s, %s )' % (r(0), opn)
        if lay == 26:
            return opn
        return ''

    def prasm_line(self, ins):
        op = ins.op
        alg = self.prasm_form(ins)
        name = op.aname
        if op.cls in (LOAD, STORE):
            name += self.p_suffix(ins)
        elif op.squash:
            name += SQUASH_NAMES[ins.modify]
        if ins.cc or ins.fcc:
            name += '.CC'
        parts = []
        for k in range(len(ins.opnds)):
            if k == 1 and op.num == 75:
                parts.append('.31')
            o = ins.opnds[k]
            if o.is_reg():
                parts.append(self.operand(ins, k))
            else:
                parts.append(('#' if o.kind == 'i' and op.forms[k] in HASH_FORMS else '')
                             + self.operand(ins, k, op.fmts[k]))
        tail = {74: ',.31', 73: ',.31,.31'}.get(op.num, '')
        if op.num == 192:
            parts = ['.31,.31,.31']
        return '%-37s; %-10s %s%s' % (alg, name, ','.join(parts), tail)

    def comment(self, ins):
        """The target's symbol, a PC-relative datum."""
        p = self.prog
        for k, o in enumerate(ins.opnds):
            if o.kind in 'bc':
                w = p.where(o.value)
                d = p.descriptors.get(o.value)
                if o.value in p.labels and o.value not in [r[0] for r in p.routines]:
                    w = p.labels[o.value]
                return '<%s>' % (w or d or '?')
        dk, bk = self.memop_index(ins)
        if dk is not None and bk is not None and bk < len(ins.opnds) and self.is_pc(ins, bk) \
                and ins.opnds[dk].kind == 'i':
            t = ins.addr + ins.opnds[dk].value
            w = p.text_word(t & ~3)
            return '= 0x%08X @%X' % (w, t) if w is not None else '@%X' % t
        if ins.op.mnem in ('ADD', 'MOVE') and len(ins.opnds) >= 2 and ins.enc.form == 'I':
            if ins.opnds[1].kind == 'r' and ins.opnds[1].num == 30:
                t = ins.addr + ins.opnds[0].value
                return '@%X %s' % (t, p.where(t) or '')
        return ''

    def line(self, a, w, status, insns, space):
        if status == 'none':
            b = struct.pack('>I', w)
            txt = ''.join(chr(c) if 32 <= c < 127 else '.' for c in b)
            return '%06X: %08X   %-10s %s' % (a, w, 'DC.L', "h'%08X  ; %s" % (w, txt))
        ins = insns[0]
        body = self.prasm_line(ins) if self.prasm else self.classic(ins)
        # lst.pas (lst_$display_code_cell): a continued instruction (an
        # integer word with bit 31, issued with the floating word after
        # it; and an fp_control word, whose FPCTL2 follows) ends in " R"
        # in the classic listing, ", ..." in -PRASM; the word that
        # continues it has no location of its own
        cont = ins.pair or getattr(ins.op, 'cls', None) == 'fp_control'
        if cont and not self.prasm:
            body += ' R'
        elif cont:
            # -PRASM: ", ..." after the instruction, before the `;' column
            alg, sep, rest = body.partition(';')
            body = ('%-37s' % (alg.rstrip() + ', ...')) + sep + rest
        c = self.comment(ins)
        if status.startswith('ambiguous'):
            c = (c + ' ' if c else '') + '(or ' + ', '.join(i.op.mnem for i in insns[1:]) + ')'
        if status.endswith('after-pair'):
            c = (c + ' ' if c else '') + '(integer word after a pair)'
        loc = '        ' if space == 'fp' else '%06X: ' % a
        s = '%s%08X   %s' % (loc, w, body)
        if c:
            s = '%-64s ; %s' % (s, c)
        return s


# --------------------------------------------------------------------------
# The checks

CALLEE_SAVED_INT = set(range(10, 22))
CALLEE_SAVED_FP = set(range(4, 8)) | set(range(52, 64))
ARG_INT = set(range(4, 10))
ARG_FP = set(range(8, 20))
NO_DEST = {'CMP', 'TST', 'TSTB', 'TSTW', 'CMPS', 'CMPD', 'TSTS', 'TSTD', 'CLASSS', 'CLASSD',
           'NOP', 'FNOP', 'FPQUIESCE', 'SYNCH', 'SYNCHB', 'SYNCHW', 'ENABLE', 'DISABLE',
           'SVC', 'MTPR', 'MTFP'}


def flow(insn):
    """(kind, target): 'branch' (conditional), 'jump' (unconditional),
    'call', 'return' (B [R22]), 'ijump', 'icall', 'ibranch' (by register),
    or (None, None)."""
    op = insn.op
    if op.cls in (BRANCH, FP_BRANCH) and op.mnem != 'BNEVER':
        o = insn.opnds[0]
        return ('branch', o.value) if o.kind == 'b' else ('ibranch', None)
    if op.cls == JUMP or op.mnem == 'RETURN':
        o = insn.opnds[0]
        if o.kind == 'b':
            return 'jump', o.value
        return ('return', None) if o.num == 22 else ('ijump', None)
    if op.cls == CALL:
        o = insn.opnds[0]
        return ('call', o.value) if o.kind == 'c' else ('icall', None)
    return None, None


def regs_of(ins):
    """(reads, writes): sets of 'Rn' and 'Fn' (a double both halves)."""
    def names(o):
        if o.kind == 'r':
            return {'R%d' % o.num}
        if o.kind == 's':
            return {'F%d' % o.num}
        if o.kind == 'd':
            return {'F%d' % o.num, 'F%d' % (o.num + 1)}
        return set()
    op = ins.op
    rd, wr = set(), set()
    ops = ins.opnds
    if not ops:
        return rd, wr
    if op.cls in (STORE, MTPR) or op.mnem in NO_DEST or op.cls in (BRANCH, FP_BRANCH, JUMP):
        for o in ops:
            rd |= names(o)
    elif op.cls == CALL:
        rd |= names(ops[0])
        wr |= names(ops[1])
    elif op.cls == LOAD_PAIR:
        rd |= names(ops[0])
        wr |= names(ops[1]) | names(ops[2])
    else:
        for o in ops[:-1]:
            rd |= names(o)
        wr |= names(ops[-1])
        if op.mnem == 'INSERT':
            rd |= names(ops[-1])
    if op.cls in (LOAD, STORE) and ins.modify:
        b = ops[1] if op.cls == LOAD else ops[2]
        wr |= names(b)
    rd.discard('R31')
    wr.discard('R31')
    return rd, wr


class Routine:
    pass


def db_registers(prog, rt, insn):
    """The registers holding the unit's data base in rt: R2 (set by the
    descriptor), R21, and any copy MOVE R2,Rx."""
    regs = {2, 21}
    for a in range(rt.start, rt.end, 4):
        i = insn(a)
        if i is not None and i.op.mnem == 'MOVE' and i.enc.form == 'R' and \
                i.opnds[0].kind == 'r' and i.opnds[0].num in regs:
            regs.add(i.opnds[1].num)
    return regs


def dispatch_targets(prog, rt, a, insn, size):
    """A case dispatch's targets (asm_$build_dispatch_table): CMP #n,Ri;
    BHI out; LOAD{BU,WU,L} [Ri*s,Rt],Rj; ADD Rj,PC,Rk; JUMP [Rk]: the
    entries are displacements from the ADD; the table's address comes from
    ADD #d,PC,Rt or from a cell of the data (LOADL [d,DB],Rt)."""
    j = insn(a)
    rk = j.opnds[0].num
    add = ld = None
    b = a - 4
    while b >= rt.start and b >= a - 16:
        i = insn(b)
        if i is None:
            return None
        if add is None and i.op.mnem == 'ADD' and i.enc.form == 'R' and i.opnds[2].num == rk \
                and i.opnds[1].num == 30 and i.opnds[0].kind == 'r':
            add = (b, i)
        elif add is not None and i.op.cls == LOAD and i.enc.form == 'R' and \
                i.opnds[2].num == add[1].opnds[0].num:
            ld = (b, i)
            break
        b -= 4
    if not ld:
        return None
    ri, rtab = ld[1].opnds[0].num, ld[1].opnds[1].num
    esize = {'LOADBU': 1, 'LOADWU': 2, 'LOADL': 4}.get(ld[1].op.mnem)
    if esize is None:
        return None
    n = None
    b = ld[0] - 4
    while b >= rt.start and b >= ld[0] - 64:
        i = insn(b)
        if i is not None and i.op.mnem == 'CMP' and i.enc.form == 'I' and i.opnds[1].num == ri:
            n = i.opnds[0].value + 1
            break
        b -= 4
    if n is None or not 0 < n <= 4096:
        return None
    table = None
    dbs = db_registers(prog, rt, insn)
    a5 = prog.db.get(rt.start)
    b = ld[0] - 4
    while b >= rt.start:
        i = insn(b)
        p = insn(b - 4)
        if p is not None and flow(p)[0] is not None and p.modify == 1:
            b -= 4                          # a slot run only when its branch is taken
            continue
        if i is not None and regs_of(i)[1] & {'R%d' % rtab}:
            if i.op.mnem == 'ADD' and i.enc.form == 'I' and i.opnds[1].num == 30:
                table = b + i.opnds[0].value
            elif i.op.mnem == 'LOADL' and i.enc.form == 'I' and i.opnds[1].num in dbs and a5:
                table = prog.coff.word(a5 + i.opnds[0].value)
            break
        b -= 4
    if table is None or not prog.in_text(table):
        return None
    out = []
    for k in range(n):
        t = table + esize * k
        w = prog.text_word(t & ~3)
        if w is None:
            return None
        if esize == 1:
            v = (w >> (8 * (3 - (t & 3)))) & 0xFF
        elif esize == 2:
            v = (w >> (16 if not t & 2 else 0)) & 0xFFFF
        else:
            v = sext(w, 32)
        out.append(add[0] + v)
    prog.tables.append((table, esize, n, a))
    return out


def analyse(prog, verbose=False, out=sys.stdout):
    """The checks of --stats: decoding, control flow, the frame and
    register conventions, PC- and data-base-relative references."""
    lst = Lister(prog)
    words = {}
    for name, sva, sz, off, _, _ in prog.texts:
        for row in prog.decode_range(sva, sva + sz):
            words[row[0]] = row

    def insn(a):
        r = words.get(a)
        if r is None or r[2] == 'none':
            return None
        return r[3][0]

    def size(a):
        i = insn(a)
        return 8 if (i is not None and i.pair) else 4

    R = {'calls': 0, 'calls_start': 0, 'calls_desc': 0, 'calls_bad': [],
         'icalls': 0, 'br': 0, 'br_in': 0, 'br_out': [], 'jumps_out': [],
         'pool': 0, 'pool_data': 0, 'pool_bad': [], 'pcadd': 0, 'pcadd_data': 0,
         'returns': 0, 'ijumps': 0, 'stuck': [], 'slot_calls': 0, 'slot_calls_ok': 0, 'slot_transfers': 0, 'ibranches': 0, 'off_end': [],
         'dispatches': 0, 'cases': 0, 'cases_in': 0}
    code = set()                          # words executed on some path
    routines = []

    def note_call(rt, a, kind, tgt):
        rt.calls.append(a)
        if kind == 'call':
            R['calls'] += 1
            if tgt in prog.starts:
                R['calls_start'] += 1
            elif tgt - 8 in prog.starts or tgt in prog.labels:
                R['calls_desc'] += 1
            else:
                R['calls_bad'].append((rt.name, a, tgt))
        else:
            R['icalls'] += 1
    for start, length, name, u in prog.routines:
        rt = Routine()
        rt.start, rt.end, rt.name, rt.unit = start, start + length, name, u
        rt.returns, rt.calls = [], []
        todo, seen = [start], set()
        while todo:
            a = todo.pop()
            while a not in seen and a in words:
                if not rt.start <= a < rt.end:
                    # past the routine's end: the call before does not
                    # return (pfm_$error_trap, exit: the routine has no
                    # return of its own there)
                    R['off_end'].append((name, a))
                    break
                seen.add(a)
                i = insn(a)
                if i is None:
                    R['stuck'].append((name, a))
                    break
                code.add(a)
                if i.pair:
                    code.add(a + 4)
                kind, tgt = flow(i)
                nxt = a + size(a)
                if kind is None:
                    a = nxt
                    continue
                # a transfer: its delay slot is the next bundle, run
                # (lst's suffix) never (.SN), when it is taken (.ST), when
                # it falls through (.SF) or always (.SA); after it the
                # fall-through, or a call's return, is the bundle after
                slot, after = nxt, nxt + size(nxt)
                si = insn(slot)
                mode = i.modify
                if kind in ('call', 'icall'):
                    note_call(rt, a, kind, tgt)
                if kind in ('branch', 'jump'):
                    R['br'] += 1
                    if rt.start <= tgt < rt.end:
                        R['br_in'] += 1
                        todo.append(tgt)
                    else:
                        R['br_out' if kind == 'branch' else 'jumps_out'].append((name, a, tgt))
                if kind == 'return':
                    ts = dispatch_targets(prog, rt, a, insn, size)
                    if ts:
                        kind = 'ijump'          # a case dispatch through R22
                    else:
                        R['returns'] += 1
                        rt.returns.append(a)
                if kind == 'ibranch':
                    R['ibranches'] += 1
                if kind == 'ijump':
                    R['ijumps'] += 1
                    ts = dispatch_targets(prog, rt, a, insn, size)
                    if ts:
                        R['dispatches'] += 1
                        R['cases'] += len(ts)
                        for t in ts:
                            if rt.start <= t < rt.end:
                                R['cases_in'] += 1
                                todo.append(t)
                if kind in ('branch', 'ibranch') and mode in (2, 3):
                    # the slot runs on the fall-through: it is the next
                    # instruction of that path, whatever it is (a second
                    # branch testing the next condition codes, a call
                    # that returns past its own slot)
                    if si is not None and flow(si)[0] in ('call', 'icall'):
                        R['slot_calls'] += 1
                        sa = slot + size(slot)
                        if kind == 'branch' and sa + size(sa) == tgt:
                            R['slot_calls_ok'] += 1
                    elif si is not None and flow(si)[0] is not None:
                        R['slot_transfers'] += 1
                    a = slot
                    continue
                if mode != 0 and si is not None:
                    code.add(slot)
                    if si.pair:
                        code.add(slot + 4)
                    if flow(si)[0] is not None:
                        R['stuck'].append((name, slot))
                if kind in ('branch', 'ibranch', 'call', 'icall'):
                    a = after
                    continue
                break
        routines.append(rt)
    # PC-relative references: a load or store from [PC,d] (the literal
    # pool) and ADD Rx := PC + d (an address in the text)
    for a in sorted(code):
        i = insn(a)
        if i is None:
            continue
        dk, bk = lst.memop_index(i)
        if dk is not None and bk is not None and bk < len(i.opnds) and lst.is_pc(i, bk) \
                and i.opnds[dk].kind == 'i':
            t = a + i.opnds[dk].value
            R['pool'] += 1
            n = 1 << i.op.size_log2
            if prog.in_text(t) and not any(x in code for x in range(t & ~3, t + n, 4)):
                R['pool_data'] += 1
            else:
                R['pool_bad'].append((prog.where(a), a, t))
        elif i.op.mnem in ('ADD',) and i.enc.form == 'I' and i.opnds[1].kind == 'r' \
                and i.opnds[1].num == 30:
            R['pcadd'] += 1
            t = a + i.opnds[0].value
            if prog.in_text(t) and t not in code:
                R['pcadd_data'] += 1
    # the frame and register conventions
    conv = check_conventions(prog, routines, insn, size, code)
    # the data base (R2 on entry through a descriptor; R21 kept by callers)
    dbr = check_data_refs(prog, routines, insn, code)
    # the words
    st = {k: [0, 0] for k in ('unique', 'specialized', 'equivalent', 'ambiguous', 'none')}
    none_code, none_data, amb = {}, {}, {}
    for a, (a0, w, s, insns, sp) in words.items():
        key = s.replace('-after-pair', '')
        st[key][0 if a in code else 1] += 1
        if key == 'none':
            (none_code if a in code else none_data).setdefault(w, []).append(a)
        if key in ('ambiguous', 'equivalent'):
            amb.setdefault(w, (a, [x.op.mnem for x in insns], key))
    unreached = classify_unreached(prog, words, code, insn)
    R.update(words=len(words), code=len(code & set(words)), st=st, none_code=none_code,
             none_data=none_data, amb=amb, conv=conv, dbr=dbr, unreached=unreached,
             routines=len(routines))
    report(prog, R, verbose, out)
    R['words_map'], R['code_set'] = words, code
    return R


def check_conventions(prog, routines, insn, size, code):
    """The prologue's and epilogue's shapes, the saved registers, the
    argument registers read on entry, the result register read after a
    call."""
    C = {'shape': {}, 'saved_int': {}, 'saved_fp': {}, 'arg_homes': 0, 'other_saves': {},
         'bad_saves': [], 'returns': 0, 'ret_slot': {}, 'restore_ok': 0, 'restore_bad': [],
         'entry_reads': {}, 'after_call': {}, 'call_sets': {}, 'frame_sizes': [],
         'unwind': 0, 'unwind_ok': 0, 'unwind_bad': [], 'unwind_ra': {},
         'unwind_mask_ok': 0}

    def is_push(i, k=None):
        # STOREL R1,[n,--R23] (an 8-bit displacement) or [R0*8,++R23]
        return (i is not None and i.op.mnem == 'STOREL' and i.modify == 2 and
                i.opnds[0].num == 1 and i.opnds[2].num == 23)
    for rt in routines:
        a = rt.start
        i0, i1, i2 = insn(a), insn(a + 4), insn(a + 8)
        mv = i0 is not None and i0.op.mnem == 'MOVE' and i0.word & 0x7FFFFFFF == 0x103F2017
        frame = None
        if mv and is_push(i1) and i1.opnds[1].kind == 'i':
            shape, frame, a = 'MOVE R23,R1; STOREL R1,[n,--R23]', -i1.opnds[1].value, a + 8
        elif mv and i1 is not None and i1.op.mnem == 'MOVE' and i1.opnds[1].num == 0 and \
                i1.opnds[0].kind == 'i' and is_push(i2):
            shape, frame, a = 'MOVE R23,R1; MOVE #-k,R0; STOREL R1,[R0*8,++R23]', \
                -8 * i1.opnds[0].value, a + 12
        elif rt.start in prog.desc_words and prog.desc_words[rt.start][2] & 0x7FFFFFFF == 0x103F2017:
            # the descriptor's B [R0] slot: the push, or R0 := -k for one
            # of more than 128 bytes (the routine's first word the push)
            st_, si = prog.dec.decode(prog.desc_words[rt.start][4], 0)
            si = si[0] if si else None
            if is_push(si) and si.opnds[1].kind == 'i':
                shape, frame = 'entered from its descriptor, whose slot pushes the frame', -si.opnds[1].value
            elif si is not None and si.op.mnem == 'MOVE' and si.opnds[1].num == 0 and is_push(i0):
                shape, frame, a = 'entered from its descriptor (R0 := -k), STOREL R1,[R0*8,++R23]', \
                    -8 * si.opnds[0].value, a + 4
            else:
                shape = 'entered from its descriptor, no frame'
        else:
            shape = 'no frame'
        C['shape'][shape] = C['shape'].get(shape, 0) + 1
        if frame:
            C['frame_sizes'].append(frame)
        # the saves: stores of registers to [d,R23] before the first transfer
        saved = {}
        b = a
        while b < rt.end:
            i = insn(b)
            if i is None or flow(i)[0] is not None:
                break
            if i.op.cls == STORE and i.opnds[2].kind == 'r' and i.opnds[2].num == 23 \
                    and i.opnds[1].kind == 'i' and not i.modify:
                o = i.opnds[0]
                if o.kind == 'r':
                    if o.num in CALLEE_SAVED_INT or o.num == 22:
                        saved.setdefault('R%d' % o.num, i.opnds[1].value)
                        C['saved_int'][o.num] = C['saved_int'].get(o.num, 0) + 1
                        if frame is None and o.num != 22:
                            C['bad_saves'].append((rt.name, b, 'R%d without a frame' % o.num))
                    elif o.num in ARG_INT:
                        C['arg_homes'] += 1
                    else:
                        C['other_saves']['R%d' % o.num] = C['other_saves'].get('R%d' % o.num, 0) + 1
                else:
                    regs = [o.num, o.num + 1] if o.kind == 'd' else [o.num]
                    for r in regs:
                        if r in CALLEE_SAVED_FP:
                            saved.setdefault('F%d' % r, i.opnds[1].value)
                            C['saved_fp'][r] = C['saved_fp'].get(r, 0) + 1
                        elif r in ARG_FP:
                            C['arg_homes'] += 1
                        else:
                            C['bad_saves'].append((rt.name, b, 'F%d' % r))
            b += size(b)
        rt.saved, rt.frame = saved, frame
        # .unwind's record of the routine: its third word's bits 29..20
        # are the saved R21..R12 (those not in the frame's +4 and +12),
        # its fourth word's bits 31..27 the register saved at +4 (R10, or
        # R21; 31 for none), 26..22 the one at +12 (R11), 21..17 the
        # return address's (R22)
        uw = prog.unwind.get(rt.start)
        if uw is not None:
            at = {off: int(r[1:]) for r, off in saved.items() if r[0] == 'R'}
            mask = (uw[2] >> 20) & 0x3FF
            mine = sum(1 << (int(r[1:]) - 12) for r, off in saved.items()
                       if r[0] == 'R' and 12 <= int(r[1:]) <= 21 and off not in (4, 12))
            s4, s12, sra = (uw[3] >> 27) & 31, (uw[3] >> 22) & 31, (uw[3] >> 17) & 31
            C['unwind'] += 1
            if mask == mine:
                C['unwind_mask_ok'] += 1
            if mask == mine and s4 == at.get(4, 31) and s12 == at.get(12, 31):
                C['unwind_ok'] += 1
            else:
                C['unwind_bad'].append((rt.name, rt.start, mask, mine, s4, at.get(4, 31),
                                        s12, at.get(12, 31)))
            C['unwind_ra'][sra] = C['unwind_ra'].get(sra, 0) + 1
        # entry: registers read before written, on the straight line from
        # the entry (the saves' reads not counted)
        rd_first, written = set(), set()
        b = rt.start
        while b < rt.end:
            i = insn(b)
            if i is None:
                break
            r, w = regs_of(i)
            if i.op.cls == STORE and i.opnds[2].kind == 'r' and i.opnds[2].num == 23:
                r = r - set(saved) - {'R1'}
            if b == rt.start and is_push(i):
                r = r - {'R0'}                  # the frame's size from the descriptor
            rd_first |= (r - written)
            written |= w
            if flow(i)[0] is not None:
                break
            b += size(b)
        for x in rd_first - {'R23', 'R2', 'R21', 'R30', 'R1', 'R22'}:
            C['entry_reads'][x] = C['entry_reads'].get(x, 0) + 1
        # each return: B [R22] with its slot, and the registers reloaded
        # before it from [d,R23] (LOAD_PAIR [R23],R23,R10 pops the frame)
        for ra in rt.returns:
            C['returns'] += 1
            ri = insn(ra)
            sl = insn(ra + size(ra))
            key = '-' if sl is None else sl.op.mnem
            if sl is not None and sl.op.cls == LOAD_PAIR:
                key = 'LOAD_PAIR [%s]' % sl.opnds[0].num
            key += ' ' + SQUASH_NAMES[ri.modify]
            C['ret_slot'][key] = C['ret_slot'].get(key, 0) + 1
            restored = set()
            b = ra - 4
            seq = [sl] if sl is not None and ri.modify else []
            while b >= rt.start and len(seq) < 40:
                i = insn(b)
                if i is None or flow(i)[0] is not None:
                    break
                seq.append(i)
                b -= 4
            for i in seq:
                if i.op.cls == LOAD_PAIR and i.opnds[0].num == 23:
                    restored |= {'R%d' % i.opnds[1].num, 'R%d' % i.opnds[2].num}
                elif i.op.cls == LOAD and i.opnds[1].kind == 'r' and i.opnds[1].num == 23:
                    restored |= regs_of(i)[1]
            want = set(saved) | ({'R23'} if frame is not None else set())
            got = {x for x in restored if x == 'R23' or (x[0] == 'R' and int(x[1:]) in
                                                         CALLEE_SAVED_INT | {22}) or
                   (x[0] == 'F' and int(x[1:]) in CALLEE_SAVED_FP)}
            if want == got:
                C['restore_ok'] += 1
            else:
                C['restore_bad'].append((rt.name, ra, sorted(want - got), sorted(got - want)))
        # after each call: registers read before written in the next bundles
        for ca in rt.calls:
            ci = insn(ca)
            after = ca + size(ca)
            after += size(after)
            rd, wr = set(), set()
            b = after
            while b < rt.end and b < after + 4 * 12:
                i = insn(b)
                if i is None:
                    break
                r, w = regs_of(i)
                rd |= (r - wr)
                wr |= w
                if flow(i)[0] is not None:
                    break
                b += size(b)
            for x in rd:
                C['after_call'][x] = C['after_call'].get(x, 0) + 1
            # the registers set in the call's straight-line block before
            # it, and in an executed delay slot
            sets = set()
            b = ca - 4
            while b >= rt.start and b > ca - 4 * 16:
                i = insn(b)
                if i is None or flow(i)[0] is not None:
                    break
                sets |= regs_of(i)[1]
                b -= 4
            sl = insn(ca + size(ca))
            if sl is not None and ci.modify:
                sets |= regs_of(sl)[1]
            for x in sets:
                C['call_sets'][x] = C['call_sets'].get(x, 0) + 1
    return C


def string_at(prog, va):
    b = prog.coff.read(va, 64)
    s = bytearray()
    for c in b:
        if c is None:
            return None
        if c == 0:
            return bytes(s) if s else None
        if not (32 <= c < 127 or c in (9, 10, 13)):
            return None
        s.append(c)
    return bytes(s)


def check_data_refs(prog, routines, insn, code):
    """Loads, stores and address computations off R2 and R21 (the unit's
    data base, .blocks' A5): in .data?  An address taken (ADD #d,base,Rx)
    that is a NUL-ended text?"""
    D = {'refs': 0, 'in_data': 0, 'out': [], 'addr': 0, 'strings': 0, 'samples': []}
    dsec = [s for s in prog.coff.sections if s[0] not in ('.text', '.unwind', '.lines', '.blocks',
                                                          '.rwdi', '.sri', '.mir', '.inlib')
            and s[1]]
    lo = min((s[1] for s in dsec), default=0)
    hi = max((s[1] + s[2] for s in dsec), default=0)
    for rt in routines:
        a5 = prog.db.get(rt.start)
        if not a5:
            continue
        for a in range(rt.start, rt.end, 4):
            if a not in code:
                continue
            i = insn(a)
            if i is None:
                continue
            base = disp = None
            c = i.op.cls
            if c in (LOAD, STORE) and i.enc.form == 'I':
                d, b = (0, 1) if c == LOAD else (1, 2)
                base, disp = i.opnds[b], i.opnds[d].value
            elif i.op.mnem == 'ADD' and i.enc.form == 'I':
                base, disp = i.opnds[1], i.opnds[0].value
            if base is None or base.kind != 'r' or base.num not in (2, 21):
                continue
            t = a5 + disp
            D['refs'] += 1
            if lo <= t < hi:
                D['in_data'] += 1
            else:
                D['out'].append((rt.name, a, t))
            if i.op.mnem == 'ADD':
                D['addr'] += 1
                s = string_at(prog, t)
                if s:
                    D['strings'] += 1
                    if len(D['samples']) < 6:
                        D['samples'].append((rt.name, a, t, s[:40]))
    return D


def classify_unreached(prog, words, code, insn):
    """The words no path from a routine's entry executes: between routines
    (alignment), referenced as a PC-relative datum (a literal pool), the
    exception stub's form, or else."""
    pool = set()
    lst = Lister(prog)
    for a in code:
        i = insn(a)
        if i is None:
            continue
        dk, bk = lst.memop_index(i)
        if dk is not None and bk is not None and bk < len(i.opnds) and lst.is_pc(i, bk) \
                and i.opnds[dk].kind == 'i':
            t = a + i.opnds[dk].value
            for x in range(t & ~3, t + (1 << i.op.size_log2), 4):
                pool.add(x)
    tab = set()
    for t, es, n, _ in prog.tables:
        for x in range(t & ~3, t + es * n, 4):
            tab.add(x)
    U = {'between': {}, 'pool': 0, 'squashed_slot': 0, 'other': 0, 'other_spans': [], 'table': 0}
    run = None
    for a in sorted(words):
        if a in code:
            run = None
            continue
        w = words[a][1]
        if a in tab:
            U['table'] += 1
        elif prog.routine_at(a) is None:
            U['between'][w] = U['between'].get(w, 0) + 1
        elif a in pool:
            U['pool'] += 1
        elif insn(a - 4) is not None and flow(insn(a - 4))[0] is not None:
            U['squashed_slot'] += 1
        else:
            U['other'] += 1
            if run and run[1] == a - 4:
                run[1] = a
            else:
                run = [a, a]
                U['other_spans'].append(run)
    return U


def report(prog, R, verbose, out):
    p = lambda *a: print(*a, file=out)  # noqa: E731
    top = lambda d, n=14: ' '.join('%s:%d' % kv for kv in sorted(d.items(), key=lambda x: -x[1])[:n])  # noqa: E731
    st = R['st']
    p('%s' % prog.coff.path)
    p('  text: %d words; %d routines (%s); %d words executed on some path from their entries'
      % (R['words'], R['routines'], prog.routines_from, R['code']))
    p('  decode     %8s %8s %8s' % ('all', 'code', 'other'))
    for k in ('unique', 'specialized', 'equivalent', 'ambiguous', 'none'):
        p('    %-11s %7d %8d %8d' % (k, st[k][0] + st[k][1], st[k][0], st[k][1]))
    p('  calls by displacement %d: %d on a routine start, %d on a start + 8 or a symbol, %d elsewhere;'
      ' %d calls by register' % (R['calls'], R['calls_start'], R['calls_desc'],
                                 len(R['calls_bad']), R['icalls']))
    p('  branches and jumps by displacement %d: %d inside their routine (%d jumps leave it)'
      % (R['br'], R['br_in'], len(R['jumps_out'])))
    p('  in the delay slot of a branch that runs it on the fall-through: %d calls (%d returning to the'
      ' branch\'s target), %d branches' % (R['slot_calls'], R['slot_calls_ok'], R['slot_transfers']))
    p('  paths that run past the routine\'s end (after a call that does not return) %d'
      % len(R['off_end']))
    p('  returns B [R22] %d; conditional branches by register %d; jumps by register %d (%d case'
      ' dispatches resolved: %d cases, %d inside the routine); paths stopped at a bad word or a'
      ' transfer in a slot %d' % (R['returns'], R['ibranches'], R['ijumps'], R['dispatches'],
                                  R['cases'], R['cases_in'], len(R['stuck'])))
    p('  PC-relative loads/stores %d: %d on words no path executes; ADD Rx := PC + d %d (%d off the code)'
      % (R['pool'], R['pool_data'], R['pcadd'], R['pcadd_data']))
    D = R['dbr']
    p('  data-base (R2/R21 + d, the unit\'s A5) references %d: %d in the data sections;'
      ' %d addresses taken, %d of them NUL-ended text' % (D['refs'], D['in_data'], D['addr'],
                                                         D['strings']))
    C = R['conv']
    p('  prologues: %s' % '; '.join('%s %d' % kv for kv in sorted(C['shape'].items(),
                                                                key=lambda x: -x[1])))
    if C['frame_sizes']:
        p('  frame sizes %d..%d bytes' % (min(C['frame_sizes']), max(C['frame_sizes'])))
    p('  saved integer registers: %s' % ' '.join('R%d:%d' % kv for kv in sorted(C['saved_int'].items())))
    if C['saved_fp']:
        p('  saved floating registers: %s' % ' '.join('F%d:%d' % kv for kv in sorted(C['saved_fp'].items())))
    p('  argument registers stored to the frame on entry %d; other registers stored there: %s;'
      ' odd saves %d' % (C['arg_homes'], top(C['other_saves']), len(C['bad_saves'])))
    p('  returns\' delay slots: %s' % ', '.join('%s %d' % kv for kv in
                                              sorted(C['ret_slot'].items(), key=lambda x: -x[1])))
    p('  returns restoring exactly the saved registers: %d of %d' % (C['restore_ok'], C['returns']))
    p('  .unwind records: %d; the saved R12..R21 mask the prologue\'s %d; also the registers at +4 and +12'
      ' the stores\' before the first transfer %d; the return-address register: %s' % (
          C['unwind'], C['unwind_mask_ok'], C['unwind_ok'],
          ' '.join('R%d:%d' % kv for kv in sorted(C['unwind_ra'].items()))))
    p('  read before written on entry: %s' % top(C['entry_reads']))
    p('  set before a call: %s' % top(C['call_sets']))
    p('  read after a call before written: %s' % top(C['after_call']))
    U = R['unreached']
    p('  words no path executes: %d case tables, %d between routines (%s), %d literal pool, '
      '%d squashed delay slots, %d other' % (
          U['table'], sum(U['between'].values()),
          top(dict(('%08X' % k, v) for k, v in U['between'].items()), 4),
          U['pool'], U['squashed_slot'], U['other']))
    if R['amb']:
        p('  equivalent or ambiguous words: %s' % '; '.join(
            '%08X at %X (%s, %s)' % (w, a, '/'.join(m), k) for w, (a, m, k) in list(R['amb'].items())[:8]))
    if R['none_code']:
        p('  undecoded words on executed paths: %s' % ' '.join(
            '%08X@%X' % (w, al[0]) for w, al in list(R['none_code'].items())[:20]))
    if verbose:
        for what in ('calls_bad', 'br_out', 'jumps_out', 'pool_bad', 'stuck'):
            for x in R[what][:12]:
                p('    %s: %s' % (what, ' '.join(str(y) if not isinstance(y, int) else '%X' % y
                                                 for y in x)))
        for x in C['bad_saves'][:12]:
            p('    bad save: %s %X %s' % x)
        for x in C['unwind_bad'][:12]:
            p('    unwind differs: %s %X mask %03X/%03X +4 R%d/R%d +12 R%d/R%d' % x)
        for x in C['restore_bad'][:12]:
            p('    restore differs: %s %X missing %s extra %s' % x)
        for x in D['out'][:12]:
            p('    data-base reference outside the data: %s %X -> %X' % x)
        for x in D['samples']:
            p('    string: %s %X -> %X %r' % x)
        for s in U['other_spans'][:30]:
            p('    unreached: %X..%X %s' % (s[0], s[1], prog.where(s[0])))
        for w, al in sorted(R['none_data'].items(), key=lambda x: -len(x[1]))[:30]:
            p('    undecoded off the paths: %08X x%d at %s' % (w, len(al), ' '.join('%X' % x for x in al[:4])))


# --------------------------------------------------------------------------

def dump_table(dec):
    for e in dec.encs:
        op = e.op
        ks = ', '.join('%d/%s' % (op.kinds[k], dec.forms[op.forms[k]]) for k in range(op.nshown))
        al = (' (= %s)' % ', '.join(a.mnem for a in e.alias)) if e.alias else ''
        print('%3d %-10s %s %-3s %08X/%08X  %s%s' % (op.num, op.mnem, e.form, e.space, e.template,
                                                    e.mask, ks, al))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('file', nargs='?')
    ap.add_argument('--image', default=IMAGE)
    ap.add_argument('--prasm', action='store_true', help='the -PRASM form')
    ap.add_argument('--routine', action='append', default=[])
    ap.add_argument('--range', nargs=2)
    ap.add_argument('--all', action='store_true', help='every text section, word by word')
    ap.add_argument('--stats', action='store_true')
    ap.add_argument('--table', action='store_true')
    ap.add_argument('-v', '--verbose', action='store_true')
    a = ap.parse_args()
    dec = Decoder(a.image)
    if a.table:
        dump_table(dec)
        return
    if not a.file:
        ap.error('a file')
    prog = Program(a.file, dec)
    if a.stats:
        analyse(prog, a.verbose)
        return
    lst = Lister(prog, a.prasm)
    spans = []
    if a.range:
        spans.append((int(a.range[0], 16), int(a.range[1], 16)))
    for nm in a.routine:
        hits = [r for r in prog.routines if r[2] == nm]
        if not hits:
            hits = [(v, 0x100, nm, None) for v, n in prog.labels.items() if n == nm]
        if not hits:
            raise SystemExit('%s: no routine %s' % (a.file, nm))
        for start, length, name, u in hits:
            spans.append((start, start + length))
    if a.all or not spans:
        spans += [(s[1], s[1] + s[2]) for s in prog.texts]
    for lo, hi in spans:
        for row in prog.decode_range(lo, hi):
            if row[0] in prog.labels:
                print('%s:' % prog.labels[row[0]])
            elif row[0] + 8 in prog.descriptors and row[0] not in prog.labels:
                pass
            print(lst.line(*row))


if __name__ == '__main__':
    main()
