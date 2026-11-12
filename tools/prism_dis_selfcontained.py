#!/usr/bin/env python3
"""prism_dis.py - disassemble the text of an Apollo a88k (PRISM, DN10000) COFF file.

    tools/prism_dis.py FILE [--prasm] [--routine NAME ...] [--range LO HI] [--all]
    tools/prism_dis.py FILE --stats [-v]      the decode and control-flow checks
    tools/prism_dis.py --table                the decode table, opcode by opcode

The decoder is built from DOMAIN C 6.9's own opcode tables, taken from
its PRISM back end (cc.a88k) and carried here as literals (`the decode
tables', at the end): instruction_assembly (the register form's and the
immediate form's templates, +0 and +4; each operand's field kind, +36),
instruction_attributes (each operand's form,
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

Symbols: the routines and their lengths from .blocks (versions 2 to 4
of the units; tools/coff_compare.py's reader) and, for what .blocks does
not describe (a stripped file, an assembly unit), from .unwind (a group's header: start, length << 7 | 4, the group's bytes, 0;
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
entry and after calls (the domain-c repository's docs/prism-isa.md,
"Validated against SR10.4 binaries").
"""
import argparse
import bisect
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402

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
    """coff_compare.Coff's reader (either Apollo magic), with the initial
    data bytes the loader builds."""

    def read(self, va, n):
        """The initial bytes at va (None for bytes nothing sets): the
        sections with file bytes, then .rwdi's copy and repeat records
        (tools/coff_data.py's rules: an a88k program's .data often has no
        file bytes)."""
        import coff_data
        return coff_data.initial(self, va, n)

    def word(self, va):
        b = self.read(va, 4)
        if None in b:
            return None
        return struct.unpack('>I', bytes(b))[0]


# --------------------------------------------------------------------------
# The opcode tables

class Opcode:
    pass


def load_tables():
    """The opcodes and the forms' names, from the decode tables (the image's
    sections, their records' fields as the image has them)."""
    forms = list(OF_STRING)
    ops = []
    for n in range(212):
        w0, w4, a8, a9, layout, prasm_op, aname, opnd = INSTRUCTION_ASSEMBLY[n]
        t_forms, t_b2, t7, t11, t19 = INSTRUCTION_ATTRIBUTES[n]
        t14 = t_b2[2]                           # instruction_attributes +14
        o = Opcode()
        o.num = n
        o.w0, o.w4 = w0, w4
        o.squash = bool(a8 & 0x20)
        o.fiveop = bool(a8 & 0x10)
        o.name_len = a9 >> 4
        o.half = (a9 >> 1) & 7
        o.layout = layout
        o.prasm_op = prasm_op                   # +11, a8 & 15 characters
        o.aname = aname                         # +19, name_len characters
        o.opnd = opnd
        o.mnem = INSTRUCTION_MNEMONIC[n]
        o.cls = t7
        o.nshown = t11 & 7
        o.forms = list(t_forms)
        o.opnd_b2 = list(t_b2)
        o.width_flag = bool(t14 & 2)            # b14_7_1 odd
        o.cc_flag = bool(t14 & 1)               # b14_0
        o.size_log2 = t19 & 7
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
    def __init__(self):
        self.ops, self.forms = load_tables()
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
        # the routines .blocks does not describe (a stripped file, an
        # assembly unit) from .unwind
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
    ap.add_argument('--prasm', action='store_true', help='the -PRASM form')
    ap.add_argument('--routine', action='append', default=[])
    ap.add_argument('--range', nargs=2)
    ap.add_argument('--all', action='store_true', help='every text section, word by word')
    ap.add_argument('--stats', action='store_true')
    ap.add_argument('--table', action='store_true')
    ap.add_argument('-v', '--verbose', action='store_true')
    a = ap.parse_args()
    dec = Decoder()
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


# ---- the decode tables ---------------------------------------------------
# DOMAIN C 6.9's own opcode tables, from its PRISM back end cc.a88k (an
# m68k COFF image: domain-c's ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k,
# 3571332 bytes, sha256 db37399931f6c408...),
# these read-only sections (address, size in the image):
#   of_string_length             0x2B712C     88 bytes
#   of_string                    0x2B7184   1464 bytes
#   instruction_mnemonic_length  0x2B773C    768 bytes
#   instruction_mnemonic         0x2B7A3C   4608 bytes
#   instruction_attributes       0x2B8C3C   4240 bytes
#   instruction_assembly         0x2B9CCC   9328 bytes
# printed by domain-c's tools/prism_tables_gen.py (it reads the image and
# prints this block, to the end of OF_STRING): regenerate, do not edit.
# Only what load_tables() reads: 212 opcodes, 43 forms, of a record the bytes
# it parses (instruction_mnemonic and its lengths have 384 entries).

# instruction_assembly, 44 bytes an opcode: +0 the register form's template,
# +4 the immediate form's; +8 0x20 squash, 0x10 five operands, 0x0F the
# -PRASM operator's length; +9 the name's length << 4 | half << 1; +10 the
# -PRASM layout; +11 the -PRASM operator; +19 the name; +36 the four
# operands' halfwords (field kind << 3 | format << 1)
INSTRUCTION_ASSEMBLY = [
    (0x00000000, 0x00000000, 0x00, 0x00, 0, '', '', (0x0000, 0x0000, 0x0000, 0x0000)),  # 0
    (0x00000000, 0x00000000, 0x26, 0x60, 4, 'BNEVER', 'bnever', (0x0020, 0x0000, 0x0000, 0x0000)),  # 1 BNEVER
    (0x27300000, 0x2F300000, 0x25, 0x30, 4, 'BNL2V', 'BNL', (0x0020, 0x0000, 0x0000, 0x0000)),  # 2 BNL2V
    (0x27100000, 0x2F100000, 0x24, 0x20, 4, 'BL2V', 'BL', (0x0020, 0x0000, 0x0000, 0x0000)),  # 3 BL2V
    (0x27700000, 0x2F700000, 0x24, 0x30, 4, 'BNL2', 'BNL', (0x0020, 0x0000, 0x0000, 0x0000)),  # 4 BNL2
    (0x27500000, 0x2F500000, 0x23, 0x20, 4, 'BL2', 'BL', (0x0020, 0x0000, 0x0000, 0x0000)),  # 5 BL2
    (0x27B00000, 0x2FB00000, 0x24, 0x30, 4, 'BNZ3', 'BNZ', (0x0020, 0x0000, 0x0000, 0x0000)),  # 6 BNZ3
    (0x27900000, 0x2F900000, 0x23, 0x20, 4, 'BZ3', 'BZ', (0x0020, 0x0000, 0x0000, 0x0000)),  # 7 BZ3
    (0x24500000, 0x2C500000, 0x23, 0x30, 4, 'BGT', 'BGT', (0x0020, 0x0000, 0x0000, 0x0000)),  # 8 BGT
    (0x24700000, 0x2C700000, 0x23, 0x30, 4, 'BLE', 'BLE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 9 BLE
    (0x24900000, 0x2C900000, 0x23, 0x30, 4, 'BGE', 'BGE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 10 BGE
    (0x24B00000, 0x2CB00000, 0x23, 0x30, 4, 'BLT', 'BLT', (0x0020, 0x0000, 0x0000, 0x0000)),  # 11 BLT
    (0x24D00000, 0x2CD00000, 0x23, 0x30, 4, 'BHI', 'BHI', (0x0020, 0x0000, 0x0000, 0x0000)),  # 12 BHI
    (0x24F00000, 0x2CF00000, 0x23, 0x30, 4, 'BLS', 'BLS', (0x0020, 0x0000, 0x0000, 0x0000)),  # 13 BLS
    (0x25100000, 0x2D100000, 0x23, 0x30, 4, 'BLO', 'BLO', (0x0020, 0x0000, 0x0000, 0x0000)),  # 14 BLO
    (0x25300000, 0x2D300000, 0x23, 0x30, 4, 'BHS', 'BHS', (0x0020, 0x0000, 0x0000, 0x0000)),  # 15 BHS
    (0x25500000, 0x2D500000, 0x23, 0x30, 4, 'BNN', 'BNN', (0x0020, 0x0000, 0x0000, 0x0000)),  # 16 BNN
    (0x25700000, 0x2D700000, 0x22, 0x20, 4, 'BN', 'BN', (0x0020, 0x0000, 0x0000, 0x0000)),  # 17 BN
    (0x25900000, 0x2D900000, 0x23, 0x30, 4, 'BNE', 'BNE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 18 BNE
    (0x25B00000, 0x2DB00000, 0x23, 0x30, 4, 'BEQ', 'BEQ', (0x0020, 0x0000, 0x0000, 0x0000)),  # 19 BEQ
    (0x25D00000, 0x2DD00000, 0x23, 0x30, 4, 'BNV', 'BNV', (0x0020, 0x0000, 0x0000, 0x0000)),  # 20 BNV
    (0x25F00000, 0x2DF00000, 0x22, 0x20, 4, 'BV', 'BV', (0x0020, 0x0000, 0x0000, 0x0000)),  # 21 BV
    (0x20500000, 0x28500000, 0x24, 0x40, 4, 'BFEQ', 'BFEQ', (0x0020, 0x0000, 0x0000, 0x0000)),  # 22 FBEQ
    (0x20700000, 0x28700000, 0x24, 0x40, 4, 'BFNE', 'BFNE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 23 FBNE
    (0x20900000, 0x28900000, 0x25, 0x50, 4, 'BFOGT', 'BFOGT', (0x0020, 0x0000, 0x0000, 0x0000)),  # 24 FBGT
    (0x21500000, 0x29500000, 0x25, 0x50, 4, 'BFOLE', 'BFOLE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 25 FBLE
    (0x20D00000, 0x28D00000, 0x25, 0x50, 4, 'BFOGE', 'BFOGE', (0x0020, 0x0000, 0x0000, 0x0000)),  # 26 FBGE
    (0x21100000, 0x29100000, 0x25, 0x50, 4, 'BFOLT', 'BFOLT', (0x0020, 0x0000, 0x0000, 0x0000)),  # 27 FBLT
    (0x24500000, 0x2C500000, 0x03, 0x30, 4, 'BGT', 'BGT', (0x0000, 0x0000, 0x0000, 0x0000)),  # 28 TRAP_GT
    (0x24700000, 0x2C700000, 0x03, 0x30, 4, 'BLE', 'BLE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 29 TRAP_LE
    (0x24900000, 0x2C900000, 0x03, 0x30, 4, 'BGE', 'BGE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 30 TRAP_GE
    (0x24B00000, 0x2CB00000, 0x03, 0x30, 4, 'BLT', 'BLT', (0x0000, 0x0000, 0x0000, 0x0000)),  # 31 TRAP_LT
    (0x24D00000, 0x2CD00000, 0x03, 0x30, 4, 'BHI', 'BHI', (0x0000, 0x0000, 0x0000, 0x0000)),  # 32 TRAP_HI
    (0x24F00000, 0x2CF00000, 0x03, 0x30, 4, 'BLS', 'BLS', (0x0000, 0x0000, 0x0000, 0x0000)),  # 33 TRAP_LS
    (0x25100000, 0x2D100000, 0x03, 0x30, 4, 'BLO', 'BLO', (0x0000, 0x0000, 0x0000, 0x0000)),  # 34 TRAP_LO
    (0x25300000, 0x2D300000, 0x03, 0x30, 4, 'BHS', 'BHS', (0x0000, 0x0000, 0x0000, 0x0000)),  # 35 TRAP_HS
    (0x25500000, 0x2D500000, 0x03, 0x30, 4, 'BNN', 'BNN', (0x0000, 0x0000, 0x0000, 0x0000)),  # 36 TRAP_NN
    (0x25700000, 0x2D700000, 0x02, 0x20, 4, 'BN', 'BN', (0x0000, 0x0000, 0x0000, 0x0000)),  # 37 TRAP_N
    (0x25900000, 0x2D900000, 0x03, 0x30, 4, 'BNE', 'BNE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 38 TRAP_NE
    (0x25B00000, 0x2DB00000, 0x03, 0x30, 4, 'BEQ', 'BEQ', (0x0000, 0x0000, 0x0000, 0x0000)),  # 39 TRAP_EQ
    (0x25D00000, 0x2DD00000, 0x03, 0x30, 4, 'BNV', 'BNV', (0x0000, 0x0000, 0x0000, 0x0000)),  # 40 TRAP_NV
    (0x25F00000, 0x2DF00000, 0x02, 0x20, 4, 'BV', 'BV', (0x0000, 0x0000, 0x0000, 0x0000)),  # 41 TRAP_V
    (0x20500000, 0x28500000, 0x04, 0x40, 4, 'BFEQ', 'BFEQ', (0x0078, 0x0000, 0x0000, 0x0000)),  # 42 TRAP_FEQ
    (0x20700000, 0x28700000, 0x04, 0x40, 4, 'BFNE', 'BFNE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 43 TRAP_FNE
    (0x20900000, 0x28900000, 0x05, 0x50, 4, 'BFOGT', 'BFOGT', (0x0078, 0x0000, 0x0000, 0x0000)),  # 44 TRAP_FGT
    (0x21500000, 0x29500000, 0x05, 0x50, 4, 'BFOLE', 'BFOLE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 45 TRAP_FLE
    (0x20D00000, 0x28D00000, 0x05, 0x50, 4, 'BFOGE', 'BFOGE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 46 TRAP_FGE
    (0x21100000, 0x29100000, 0x05, 0x50, 4, 'BFOLT', 'BFOLT', (0x0078, 0x0000, 0x0000, 0x0000)),  # 47 TRAP_FLT
    (0x24500000, 0x2C500000, 0x03, 0x30, 4, 'BGT', 'BGT', (0x0000, 0x0000, 0x0000, 0x0000)),  # 48 TRAPD_GT
    (0x24700000, 0x2C700000, 0x03, 0x30, 4, 'BLE', 'BLE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 49 TRAPD_LE
    (0x24900000, 0x2C900000, 0x03, 0x30, 4, 'BGE', 'BGE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 50 TRAPD_GE
    (0x24B00000, 0x2CB00000, 0x03, 0x30, 4, 'BLT', 'BLT', (0x0000, 0x0000, 0x0000, 0x0000)),  # 51 TRAPD_LT
    (0x24D00000, 0x2CD00000, 0x03, 0x30, 4, 'BHI', 'BHI', (0x0000, 0x0000, 0x0000, 0x0000)),  # 52 TRAPD_HI
    (0x24F00000, 0x2CF00000, 0x03, 0x30, 4, 'BLS', 'BLS', (0x0000, 0x0000, 0x0000, 0x0000)),  # 53 TRAPD_LS
    (0x25100000, 0x2D100000, 0x03, 0x30, 4, 'BLO', 'BLO', (0x0000, 0x0000, 0x0000, 0x0000)),  # 54 TRAPD_LO
    (0x25300000, 0x2D300000, 0x03, 0x30, 4, 'BHS', 'BHS', (0x0000, 0x0000, 0x0000, 0x0000)),  # 55 TRAPD_HS
    (0x25500000, 0x2D500000, 0x03, 0x30, 4, 'BNN', 'BNN', (0x0000, 0x0000, 0x0000, 0x0000)),  # 56 TRAPD_NN
    (0x25700000, 0x2D700000, 0x02, 0x20, 4, 'BN', 'BN', (0x0000, 0x0000, 0x0000, 0x0000)),  # 57 TRAPD_N
    (0x25900000, 0x2D900000, 0x03, 0x30, 4, 'BNE', 'BNE', (0x0000, 0x0000, 0x0000, 0x0000)),  # 58 TRAPD_NE
    (0x25B00000, 0x2DB00000, 0x03, 0x30, 4, 'BEQ', 'BEQ', (0x0000, 0x0000, 0x0000, 0x0000)),  # 59 TRAPD_EQ
    (0x25D00000, 0x2DD00000, 0x03, 0x30, 4, 'BNV', 'BNV', (0x0000, 0x0000, 0x0000, 0x0000)),  # 60 TRAPD_NV
    (0x25F00000, 0x2DF00000, 0x02, 0x20, 4, 'BV', 'BV', (0x0000, 0x0000, 0x0000, 0x0000)),  # 61 TRAPD_V
    (0x20500000, 0x28500000, 0x04, 0x40, 4, 'BFEQ', 'BFEQ', (0x0078, 0x0000, 0x0000, 0x0000)),  # 62 TRAPD_FEQ
    (0x20700000, 0x28700000, 0x04, 0x40, 4, 'BFNE', 'BFNE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 63 TRAPD_FNE
    (0x20900000, 0x28900000, 0x05, 0x50, 4, 'BFOGT', 'BFOGT', (0x0078, 0x0000, 0x0000, 0x0000)),  # 64 TRAPD_FGT
    (0x21500000, 0x29500000, 0x05, 0x50, 4, 'BFOLE', 'BFOLE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 65 TRAPD_FLE
    (0x20D00000, 0x28D00000, 0x05, 0x50, 4, 'BFOGE', 'BFOGE', (0x0078, 0x0000, 0x0000, 0x0000)),  # 66 TRAPD_FGE
    (0x21100000, 0x29100000, 0x05, 0x50, 4, 'BFOLT', 'BFOLT', (0x0078, 0x0000, 0x0000, 0x0000)),  # 67 TRAPD_FLT
    (0x00000000, 0x00000000, 0x03, 0x20, 4, 'BZ3', 'BZ', (0x0000, 0x0000, 0x0000, 0x0000)),  # 68 TRAP
    (0x24300000, 0x2C300000, 0x21, 0x10, 4, 'B', 'B', (0x0020, 0x0000, 0x0000, 0x0000)),  # 69 JUMP
    (0x00000000, 0x00000000, 0x20, 0x80, 0, '', 'dispatch', (0x0020, 0x0000, 0x0000, 0x0000)),  # 70 DISPATCH
    (0x13E0CF60, 0x13E0CF60, 0x01, 0x60, 25, '7', 'EXTEND', (0x0000, 0x0000, 0x0000, 0x0000)),  # 71 TSTB
    (0x13E0DF60, 0x13E0DF60, 0x02, 0x60, 25, '15', 'EXTEND', (0x0000, 0x0000, 0x0000, 0x0000)),  # 72 TSTW
    (0x13FF6000, 0x13FF6000, 0x01, 0x30, 20, '?', 'SUB', (0x0000, 0x0000, 0x0000, 0x0000)),  # 73 TST
    (0x13E06800, 0x1FE00000, 0x01, 0x30, 3, '?', 'SUB', (0x0020, 0x0008, 0x0000, 0x0000)),  # 74 CMP
    (0x101F2000, 0x181F0000, 0x41, 0x30, 14, '?', 'ADD', (0x0020, 0x0010, 0x0000, 0x0000)),  # 75 MOVE
    (0x101F2000, 0x181F0000, 0x01, 0x30, 14, '?', 'ADD', (0x0020, 0x0010, 0x0000, 0x0000)),  # 76 PMOVE
    (0x101F2800, 0x101F2800, 0x41, 0x30, 21, '-', 'SUB', (0x0000, 0x0010, 0x0000, 0x0000)),  # 77 NEG
    (0x1400907F, 0x1400907F, 0x41, 0x30, 21, '~', 'XOR', (0x0008, 0x0010, 0x0000, 0x0000)),  # 78 COM
    (0x10002000, 0x18000000, 0x41, 0x30, 3, '+', 'ADD', (0x0020, 0x0008, 0x0010, 0x0000)),  # 79 ADD
    (0x10001800, 0x14001800, 0x41, 0x40, 24, '+', 'ADDC', (0x0020, 0x0008, 0x0010, 0x0000)),  # 80 ADDC
    (0x10002800, 0x14002800, 0x41, 0x30, 3, '-', 'SUB', (0x0020, 0x0008, 0x0010, 0x0000)),  # 81 SUB
    (0x10003800, 0x14003800, 0x41, 0x40, 24, '-', 'SUBC', (0x0020, 0x0008, 0x0010, 0x0000)),  # 82 SUBC
    (0x10003000, 0x14003000, 0x41, 0x40, 18, '-', 'SUBR', (0x0020, 0x0008, 0x0010, 0x0000)),  # 83 RSUB
    (0x10000800, 0x14000800, 0x41, 0x30, 3, '&', 'AND', (0x0024, 0x0008, 0x0010, 0x0000)),  # 84 AND
    (0x10000000, 0x14000000, 0x41, 0x20, 3, '|', 'OR', (0x0024, 0x0008, 0x0010, 0x0000)),  # 85 OR
    (0x10001000, 0x14001000, 0x41, 0x30, 3, '^', 'XOR', (0x0024, 0x0008, 0x0010, 0x0000)),  # 86 XOR
    (0x10008160, 0x10008160, 0x41, 0x60, 7, '0', 'EXTEND', (0x0000, 0x0010, 0x0000, 0x0000)),  # 87 EXTEND0
    (0x10008F60, 0x10008F60, 0x41, 0x60, 7, '7', 'EXTEND', (0x0000, 0x0010, 0x0000, 0x0000)),  # 88 EXTEND7
    (0x10009F60, 0x10009F60, 0x42, 0x60, 7, '15', 'EXTEND', (0x0000, 0x0010, 0x0000, 0x0000)),  # 89 EXTEND15
    (0x1000BE40, 0x1000BE40, 0x44, 0x40, 2, 'SHRA', 'SHRA', (0x0000, 0x0038, 0x0010, 0x0000)),  # 90 ASR
    (0x1000BE00, 0x1000BE00, 0x42, 0x40, 2, '>>', 'SHRL', (0x0000, 0x0038, 0x0010, 0x0000)),  # 91 LSR
    (0x1000BEC0, 0x1000BEC0, 0x42, 0x40, 2, '<<', 'SHLL', (0x0000, 0x0040, 0x0008, 0x0000)),  # 92 LSL
    (0x100080E0, 0x100080E0, 0x47, 0x70, 11, 'ISOLATE', 'ISOLATE', (0x0000, 0x0040, 0x0008, 0x0000)),  # 93 ISOLATE
    (0x100080C0, 0x100080C0, 0x46, 0x60, 15, 'CLRINS', 'CLRINS', (0x0000, 0x0040, 0x0008, 0x0000)),  # 94 CLRINS
    (0x100080A0, 0x100080A0, 0x41, 0x80, 9, '?', 'TRANSFER', (0x0000, 0x0040, 0x0008, 0x0000)),  # 95 TRANSFER
    (0x10008080, 0x14000080, 0x46, 0x60, 10, 'INSERT', 'INSERT', (0x0020, 0x0040, 0x0008, 0x0000)),  # 96 INSERT
    (0x10008000, 0x10008000, 0x41, 0x70, 8, '?', 'EXTRACT', (0x0020, 0x0038, 0x0010, 0x0000)),  # 97 EXTRACTU
    (0x00000000, 0x00000000, 0x01, 0x60, 8, '?', 'WIDENB', (0x0020, 0x0038, 0x0010, 0x0000)),  # 98 WIDENB
    (0x00000000, 0x00000000, 0x01, 0x60, 8, '?', 'WIDENW', (0x0020, 0x0038, 0x0010, 0x0000)),  # 99 WIDENW
    (0x3FE00100, 0x3FE00100, 0x00, 0x60, 0, '', 'synchb', (0x0000, 0x0000, 0x0000, 0x0000)),  # 100 SYNCHB
    (0x3FE00900, 0x3FE00900, 0x00, 0x60, 0, '', 'synchw', (0x0000, 0x0000, 0x0000, 0x0000)),  # 101 SYNCHW
    (0x3FE01100, 0x3FE01100, 0x00, 0x50, 0, '', 'synch', (0x0000, 0x0000, 0x0000, 0x0000)),  # 102 SYNCH
    (0x34000000, 0x40000000, 0x41, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0010, 0x0000)),  # 103 LOADBU
    (0x34000800, 0x50000000, 0x41, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0010, 0x0000)),  # 104 LOADWU
    (0x34001000, 0x60000000, 0x41, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0010, 0x0000)),  # 105 LOADL
    (0x34002800, 0x74000000, 0x01, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0050, 0x0000)),  # 106 LOADS
    (0x00000000, 0x00000000, 0x01, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0018, 0x0000)),  # 107 LOADSE
    (0x34002000, 0x70000000, 0x01, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0018, 0x0000)),  # 108 LOADSO
    (0x34003800, 0x6C000000, 0x01, 0x40, 13, '_', 'LOAD', (0x0020, 0x0008, 0x0018, 0x0000)),  # 109 LOADD
    (0x34001800, 0x34001800, 0x01, 0x50, 17, '_', 'LOADQ', (0x0008, 0x0010, 0x0000, 0x0000)),  # 110 LOAD_PAIR
    (0x7C002000, 0x7C002000, 0x01, 0x40, 14, '_', 'mfcc', (0x0010, 0x0000, 0x0000, 0x0000)),  # 111 MFNEXTCC
    (0x7C002000, 0x7C002000, 0x01, 0x40, 14, '_', 'mfcc', (0x0010, 0x0000, 0x0000, 0x0000)),  # 112 MFIPPSW
    (0xFC1F0200, 0xFC1F0200, 0x01, 0x40, 14, '_', 'MFPR', (0x0010, 0x0000, 0x0000, 0x0000)),  # 113 MFFPCC
    (0xFC1F0200, 0xFC1F0200, 0x01, 0x40, 14, '_', 'MFPR', (0x0010, 0x0000, 0x0000, 0x0000)),  # 114 MFFPPSW
    (0x7C002000, 0x7C002000, 0x41, 0x40, 14, '_', 'MFPR', (0x0034, 0x0008, 0x0010, 0x0000)),  # 115 MFPR
    (0xFC1F2100, 0xFC1F2100, 0x41, 0x40, 14, '_', 'MFPR', (0x0030, 0x0010, 0x0000, 0x0000)),  # 116 MFFP
    (0xFFFF2204, 0xFFFF2204, 0x01, 0x40, 14, '_', 'MFPR', (0x0000, 0x0000, 0x0000, 0x0000)),  # 117 FPQUIESCE
    (0x30000000, 0x48000000, 0x01, 0x50, 19, '_', 'STORE', (0x0010, 0x0020, 0x0008, 0x0000)),  # 118 STOREB
    (0x30000800, 0x58000000, 0x01, 0x50, 19, '_', 'STORE', (0x0010, 0x0020, 0x0008, 0x0000)),  # 119 STOREW
    (0x30001000, 0x68000000, 0x01, 0x50, 19, '_', 'STORE', (0x0010, 0x0020, 0x0008, 0x0000)),  # 120 STOREL
    (0x30002800, 0x5C000000, 0x01, 0x50, 19, '_', 'STORE', (0x0050, 0x0020, 0x0008, 0x0000)),  # 121 STORES
    (0x00000000, 0x00000000, 0x01, 0x50, 19, '_', 'STORE', (0x0018, 0x0020, 0x0008, 0x0000)),  # 122 STORESE
    (0x30002000, 0x78000000, 0x01, 0x50, 19, '_', 'STORE', (0x0018, 0x0020, 0x0008, 0x0000)),  # 123 STORESO
    (0x30003800, 0x4C000000, 0x01, 0x50, 19, '_', 'STORE', (0x0018, 0x0020, 0x0008, 0x0000)),  # 124 STORED
    (0x7C000000, 0x7C000000, 0x01, 0x40, 14, '_', 'MTPR', (0x0010, 0x0034, 0x0008, 0x0000)),  # 125 MTPR
    (0xFC1F0100, 0xFC1F0100, 0x01, 0x40, 14, '_', 'MTPR', (0x0010, 0x0030, 0x0000, 0x0000)),  # 126 MTFP
    (0x2400F01F, 0x2400F01F, 0x06, 0x60, 6, 'ENABLE', 'B priv', (0x0000, 0x0000, 0x0000, 0x0000)),  # 127 ENABLE
    (0x2400701F, 0x2400701F, 0x07, 0x60, 6, 'DISABLE', 'B priv', (0x0000, 0x0000, 0x0000, 0x0000)),  # 128 DISABLE
    (0x20000000, 0x28000000, 0x24, 0x40, 5, 'CALL', 'CALL', (0x0020, 0x0010, 0x0000, 0x0000)),  # 129 CALL
    (0x23E0201F, 0x23E0201F, 0x03, 0x30, 23, 'SVC', 'SVC', (0x0048, 0x0000, 0x0000, 0x0000)),  # 130 SVC
    (0x23E0201F, 0x23E0201F, 0x03, 0x30, 23, 'SVC', 'SVC', (0x0048, 0x0048, 0x0000, 0x0000)),  # 131 SVC2
    (0x24300000, 0x24300000, 0x21, 0x10, 4, 'B', 'B', (0x0000, 0x0000, 0x0000, 0x0000)),  # 132 RETURN
    (0x3CD40000, 0x3CD40000, 0x01, 0x76, 14, 'I', 'COPY.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 133 MOVEI
    (0x3CD40000, 0x3CD40000, 0x01, 0x76, 14, 'I', 'COPY.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 134 PMOVEI
    (0x3E3C0000, 0x3E3C0000, 0x01, 0x56, 21, '-', 'NEG.I', (0x0070, 0x0088, 0x0000, 0x0000)),  # 135 NEGI
    (0x3CCC0000, 0x3CCC0000, 0x01, 0x56, 21, '~', 'COM.I', (0x0070, 0x0088, 0x0000, 0x0000)),  # 136 COMI
    (0x3E040000, 0x3E040000, 0x01, 0x5E, 3, '+', 'ADD.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 137 ADDI
    (0x3E2C0000, 0x3E2C0000, 0x01, 0x5E, 3, '-', 'SUB.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 138 SUBI
    (0x3CAC0000, 0x3CAC0000, 0x01, 0x5E, 3, '&', 'AND.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 139 ANDI
    (0x3C9C0000, 0x3C9C0000, 0x01, 0x4E, 3, '|', 'OR.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 140 ORI
    (0x3CFC0000, 0x3CFC0000, 0x01, 0x5E, 3, '^', 'XOR.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 141 XORI
    (0x36340000, 0x36340000, 0x85, 0x82, 12, 'FLOAT', 'FLOAT.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 142 CVTIS
    (0x363C0000, 0x363C0000, 0x85, 0x82, 12, 'FLOAT', 'FLOAT.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 143 CVTID
    (0x3CD40000, 0x3CD40000, 0x01, 0x70, 14, '_', 'COPY.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 144 COPYS
    (0x3CD40000, 0x3CD40000, 0x01, 0x70, 14, '_', 'COPY.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 145 PCOPYS
    (0x32640000, 0x32640000, 0x81, 0x70, 14, '_', 'MOVE.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 146 MOVES
    (0x32540000, 0x32540000, 0x81, 0x60, 21, '-', 'NEG.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 147 NEGS
    (0x32440000, 0x32440000, 0x83, 0x60, 12, 'ABS', 'ABS.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 148 ABSS
    (0x36B40000, 0x36B40000, 0x84, 0x70, 12, 'DBLE', 'DBLE.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 149 CVTSD
    (0x36140000, 0x36140000, 0x05, 0x94, 12, 'ROUND', 'ROUNDI.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 150 ROUNDSI
    (0x36E40000, 0x36E40000, 0x85, 0x80, 12, 'ROUND', 'ROUND.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 151 ROUNDS
    (0x36940000, 0x36940000, 0x05, 0x94, 12, 'TRUNC', 'TRUNCI.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 152 TRUNCSI
    (0x36F40000, 0x36F40000, 0x85, 0x80, 12, 'TRUNC', 'TRUNC.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 153 TRUNCS
    (0x32840000, 0x32840000, 0x81, 0x60, 3, '+', 'ADD.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 154 ADDS
    (0x32940000, 0x32940000, 0x81, 0x60, 3, '-', 'SUB.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 155 SUBS
    (0x13B40000, 0x13B40000, 0x01, 0x60, 3, '?', 'CMP.FS', (0x0078, 0x0080, 0x0000, 0x0000)),  # 156 CMPS
    (0x13640000, 0x13640000, 0x01, 0x80, 16, '_', 'CLASS.FS', (0x0070, 0x0000, 0x0000, 0x0000)),  # 157 CLASSS
    (0x13240000, 0x13240000, 0x01, 0x60, 20, '?', 'TST.FS', (0x0070, 0x0000, 0x0000, 0x0000)),  # 158 TSTS
    (0x32240000, 0x32240000, 0x81, 0x60, 3, '-', 'MIN.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 159 MINS
    (0x32340000, 0x32340000, 0x81, 0x60, 3, '-', 'MAX.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 160 MAXS
    (0x38DC0000, 0x38DC0000, 0x04, 0x70, 12, 'COPY', 'COPY.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 161 COPYD
    (0x38DC0000, 0x38DC0000, 0x04, 0x70, 12, 'COPY', 'COPY.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 162 PCOPYD
    (0x326C0000, 0x326C0000, 0x84, 0x70, 12, 'MOVE', 'MOVE.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 163 MOVED
    (0x325C0000, 0x325C0000, 0x81, 0x60, 21, '-', 'NEG.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 164 NEGD
    (0x324C0000, 0x324C0000, 0x83, 0x60, 12, 'ABS', 'ABS.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 165 ABSD
    (0x36BC0000, 0x36BC0000, 0x84, 0x70, 12, 'SNGL', 'SNGL.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 166 CVTDS
    (0x361C0000, 0x361C0000, 0x05, 0x94, 12, 'ROUND', 'ROUNDI.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 167 ROUNDDI
    (0x36EC0000, 0x36EC0000, 0x85, 0x80, 12, 'ROUND', 'ROUND.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 168 ROUNDD
    (0x369C0000, 0x369C0000, 0x05, 0x94, 12, 'TRUNC', 'TRUNCI.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 169 TRUNCDI
    (0x36FC0000, 0x36FC0000, 0x85, 0x80, 12, 'TRUNC', 'TRUNC.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 170 TRUNCD
    (0x328C0000, 0x328C0000, 0x81, 0x60, 3, '+', 'ADD.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 171 ADDD
    (0x329C0000, 0x329C0000, 0x81, 0x60, 3, '-', 'SUB.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 172 SUBD
    (0x13BC0000, 0x13BC0000, 0x01, 0x60, 3, '?', 'CMP.FD', (0x0078, 0x0080, 0x0000, 0x0000)),  # 173 CMPD
    (0x136C0000, 0x136C0000, 0x01, 0x90, 16, '_', 'CLASSD.FD', (0x0070, 0x0000, 0x0000, 0x0000)),  # 174 CLASSD
    (0x132C0000, 0x132C0000, 0x01, 0x60, 20, '?', 'TST.FD', (0x0070, 0x0000, 0x0000, 0x0000)),  # 175 TSTD
    (0x322C0000, 0x322C0000, 0x81, 0x60, 3, '-', 'MIN.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 176 MIND
    (0x323C0000, 0x323C0000, 0x81, 0x60, 3, '-', 'MAX.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 177 MAXD
    (0x3EFC0000, 0x3EFC0000, 0x01, 0x5E, 3, '*', 'MUL.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 178 MULI
    (0x3E840000, 0x00000000, 0x01, 0x5E, 3, '/', 'DIV.I', (0x0078, 0x0080, 0x0088, 0x0000)),  # 179 DIVI
    (0x30140000, 0x00000000, 0x84, 0x70, 12, 'SQRT', 'SQRT.FS', (0x0070, 0x0088, 0x0000, 0x0000)),  # 180 SQRTS
    (0x30440000, 0x30440000, 0x81, 0x60, 3, '*', 'MUL.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 181 MULS
    (0x30040000, 0x30040000, 0x81, 0x70, 3, '/', 'DIVS.FS', (0x0078, 0x0080, 0x0088, 0x0000)),  # 182 DIVS
    (0x301C0000, 0x00000000, 0x84, 0x70, 12, 'SQRT', 'SQRT.FD', (0x0070, 0x0088, 0x0000, 0x0000)),  # 183 SQRTD
    (0x304C0000, 0x304C0000, 0x81, 0x60, 3, '*', 'MUL.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 184 MULD
    (0x300C0000, 0x00000000, 0x81, 0x60, 3, '/', 'DIV.FD', (0x0078, 0x0080, 0x0088, 0x0000)),  # 185 DIVD
    (0x80000000, 0x80000000, 0x11, 0xA0, 1, '+', 'mul_ADD.FS', (0x0058, 0x0060, 0x0000, 0x0000)),  # 186 ADDS5
    (0xC0000000, 0xC0000000, 0x11, 0xA0, 1, '-', 'mul_SUB.FS', (0x0058, 0x0060, 0x0000, 0x0000)),  # 187 SUBS5
    (0x40000000, 0x40000000, 0x15, 0xD4, 12, 'TRUNC', 'mul_TRUNCI.FS', (0x0058, 0x0060, 0x0000, 0x0000)),  # 188 TRUNCSI5
    (0x00000040, 0x00000040, 0x11, 0xA0, 1, '+', 'mul_ADD.FD', (0x0058, 0x0060, 0x0000, 0x0000)),  # 189 ADDD5
    (0x00000041, 0x00000041, 0x11, 0xA0, 1, '-', 'mul_SUB.FD', (0x0058, 0x0060, 0x0000, 0x0000)),  # 190 SUBD5
    (0x00000000, 0x00000000, 0x15, 0xD4, 12, 'TRUNC', 'mul_TRUNCI.FD', (0x0058, 0x0068, 0x0000, 0x0000)),  # 191 TRUNCDI5
    (0x13FF001F, 0x13FF001F, 0x03, 0x20, 26, 'NOP', 'OR', (0x0000, 0x0000, 0x0000, 0x0000)),  # 192 NOP
    (0x04C40000, 0x04C40000, 0x04, 0x40, 26, 'FNOP', 'FNOP', (0x0000, 0x0000, 0x0000, 0x0000)),  # 193 FNOP
    (0x00000000, 0x00000000, 0x03, 0x20, 26, 'NOP', 'OR', (0x0000, 0x0000, 0x0000, 0x0000)),  # 194 IPCCNOP
    (0x101F0000, 0x101F0000, 0x01, 0x80, 14, '?', 'shiftnop', (0x0020, 0x0010, 0x0000, 0x0000)),  # 195 SHIFTNOP
    (0x00000000, 0x00000000, 0x05, 0x50, 26, 'ENTRY', 'entry', (0x0000, 0x0000, 0x0000, 0x0000)),  # 196 ENTRY
    (0x00000000, 0x00000000, 0x00, 0x50, 0, '', 'limit', (0x0000, 0x0000, 0x0000, 0x0000)),  # 197 LIMIT
    (0x00000000, 0x00000000, 0x00, 0x60, 0, '', 'label$', (0x0000, 0x0000, 0x0000, 0x0000)),  # 198 EPILOGUE
    (0x00000000, 0x00000000, 0x00, 0x50, 0, '', 'label', (0x0000, 0x0000, 0x0000, 0x0000)),  # 199 LABEL
    (0x00000000, 0x00000000, 0x00, 0x60, 0, '', 'label$', (0x0000, 0x0000, 0x0000, 0x0000)),  # 200 LABEL$
    (0x00000000, 0x00000000, 0x00, 0x30, 0, '', 'seq', (0x0000, 0x0000, 0x0000, 0x0000)),  # 201 SEQ
    (0x00000000, 0x00000000, 0x00, 0x70, 0, '', 'mem_seq', (0x0000, 0x0000, 0x0000, 0x0000)),  # 202 MMT_SEQ
    (0x00000000, 0x00000000, 0x00, 0x70, 0, '', 'join_bp', (0x0000, 0x0000, 0x0000, 0x0000)),  # 203 JOIN_BP
    (0x00000000, 0x00000000, 0x05, 0x50, 26, 'LTORG', 'ltorg', (0x0000, 0x0000, 0x0000, 0x0000)),  # 204 LTORG
    (0x00000000, 0x00000000, 0x05, 0x50, 26, 'LTORG', 'ltorg', (0x0000, 0x0000, 0x0000, 0x0000)),  # 205 TABLEB
    (0x00000000, 0x00000000, 0x05, 0x50, 26, 'LTORG', 'ltorg', (0x0000, 0x0000, 0x0000, 0x0000)),  # 206 TABLEW
    (0x00000000, 0x00000000, 0x05, 0x50, 26, 'LTORG', 'ltorg', (0x0000, 0x0000, 0x0000, 0x0000)),  # 207 TABLEL
    (0x00000000, 0x00000000, 0x00, 0x60, 0, '', 'costly', (0x0000, 0x0000, 0x0000, 0x0000)),  # 208 COSTLY
    (0x00000000, 0x00000000, 0x00, 0x80, 0, '', 'bugcheck', (0x0000, 0x0000, 0x0000, 0x0000)),  # 209 BUGCHECK
    (0x00000000, 0x00000000, 0x00, 0x40, 0, '', 'none', (0x0000, 0x0000, 0x0000, 0x0000)),  # 210 NONE
    (0x00000000, 0x00000000, 0x41, 0x30, 14, '?', 'ADD', (0x0000, 0x0000, 0x0000, 0x0000)),  # 211 ADJ_MOVE
]

# instruction_attributes, 20 bytes an opcode: operands 1..4's forms (+4, +8,
# +12, +16) and their bytes 2 (+6, +10, +14, +18; +14 also the width and .CC
# flags); +7 the class; +11 (& 7 the operands shown); +19 (& 7 log2 of the
# access size)
INSTRUCTION_ATTRIBUTES = [
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 0, 0x00, 0x00),  # 0
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x09, 0x07),  # 1 BNEVER
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 2 BNL2V
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 3 BL2V
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 4 BNL2
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 5 BL2
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 6 BNZ3
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 7 BZ3
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 8 BGT
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 9 BLE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 10 BGE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 11 BLT
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 12 BHI
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 13 BLS
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 14 BLO
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 15 BHS
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 16 BNN
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 17 BN
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 18 BNE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 19 BEQ
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 20 BNV
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 1, 0x11, 0x4F),  # 21 BV
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 22 FBEQ
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 23 FBNE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 24 FBGT
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 25 FBLE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 26 FBGE
    ((2, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 5, 0x11, 0xCF),  # 27 FBLT
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 28 TRAP_GT
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 29 TRAP_LE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 30 TRAP_GE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 31 TRAP_LT
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 32 TRAP_HI
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 33 TRAP_LS
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 34 TRAP_LO
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 35 TRAP_HS
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 36 TRAP_NN
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 37 TRAP_N
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 38 TRAP_NE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 39 TRAP_EQ
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 40 TRAP_NV
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0x4F),  # 41 TRAP_V
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 42 TRAP_FEQ
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 43 TRAP_FNE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 44 TRAP_FGT
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 45 TRAP_FLE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 46 TRAP_FGE
    ((22, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xA1, 0xCF),  # 47 TRAP_FLT
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 48 TRAPD_GT
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 49 TRAPD_LE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 50 TRAPD_GE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 51 TRAPD_LT
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 52 TRAPD_HI
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 53 TRAPD_LS
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 54 TRAPD_LO
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 55 TRAPD_HS
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 56 TRAPD_NN
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 57 TRAPD_N
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 58 TRAPD_NE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 59 TRAPD_EQ
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 60 TRAPD_NV
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0x4F),  # 61 TRAPD_V
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 62 TRAPD_FEQ
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 63 TRAPD_FNE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 64 TRAPD_FGT
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 65 TRAPD_FLE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 66 TRAPD_FGE
    ((4, 0, 0, 0), (0x80, 0x00, 0x00, 0x00), 27, 0xB1, 0xCF),  # 67 TRAPD_FLT
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 14, 0x90, 0x07),  # 68 TRAP
    ((1, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 6, 0x09, 0x07),  # 69 JUMP
    ((1, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 6, 0x09, 0x07),  # 70 DISPATCH
    ((18, 0, 0, 0), (0x00, 0x00, 0x00, 0x02), 0, 0x11, 0x08),  # 71 TSTB
    ((18, 0, 0, 0), (0x00, 0x00, 0x00, 0x02), 0, 0x11, 0x09),  # 72 TSTW
    ((18, 0, 0, 0), (0x00, 0x00, 0x00, 0x02), 0, 0x11, 0x0A),  # 73 TST
    ((3, 18, 0, 0), (0x00, 0x00, 0x00, 0x02), 0, 0x1A, 0x0A),  # 74 CMP
    ((10, 18, 0, 0), (0x01, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 75 MOVE
    ((18, 18, 0, 0), (0x01, 0xC0, 0x00, 0x00), 18, 0x12, 0x02),  # 76 PMOVE
    ((18, 18, 0, 0), (0x00, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 77 NEG
    ((18, 18, 0, 0), (0x00, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 78 COM
    ((10, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 79 ADD
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x2B, 0x4A),  # 80 ADDC
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 81 SUB
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x2B, 0x4A),  # 82 SUBC
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 83 RSUB
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 84 AND
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 85 OR
    ((7, 18, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 86 XOR
    ((18, 18, 0, 0), (0x00, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 87 EXTEND0
    ((18, 18, 0, 0), (0x00, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 88 EXTEND7
    ((18, 18, 0, 0), (0x00, 0xC0, 0x01, 0x00), 0, 0x1A, 0x0A),  # 89 EXTEND15
    ((18, 16, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 90 ASR
    ((18, 16, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 91 LSR
    ((18, 16, 18, 0), (0x00, 0x00, 0xC1, 0x00), 0, 0x23, 0x0A),  # 92 LSL
    ((18, 16, 18, 0), (0x00, 0x00, 0xC3, 0x00), 0, 0x23, 0x0A),  # 93 ISOLATE
    ((18, 16, 18, 0), (0x00, 0x00, 0xC3, 0x00), 0, 0x23, 0x0A),  # 94 CLRINS
    ((18, 16, 18, 0), (0x00, 0x00, 0x83, 0x00), 0, 0x2B, 0x0A),  # 95 TRANSFER
    ((9, 16, 18, 0), (0x00, 0x00, 0x83, 0x00), 0, 0x2B, 0x0A),  # 96 INSERT
    ((18, 16, 18, 0), (0x00, 0x00, 0xC3, 0x00), 0, 0x23, 0x0A),  # 97 EXTRACTU
    ((18, 16, 18, 0), (0x00, 0x00, 0xC2, 0x02), 0, 0x23, 0x08),  # 98 WIDENB
    ((18, 16, 18, 0), (0x00, 0x00, 0xC2, 0x02), 0, 0x23, 0x09),  # 99 WIDENW
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 10, 0x10, 0x00),  # 100 SYNCHB
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 10, 0x10, 0x01),  # 101 SYNCHW
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 10, 0x10, 0x02),  # 102 SYNCH
    ((10, 18, 18, 0), (0x00, 0x40, 0xC5, 0x00), 16, 0xB3, 0x08),  # 103 LOADBU
    ((10, 18, 18, 0), (0x00, 0x40, 0xC5, 0x00), 16, 0xB3, 0x09),  # 104 LOADWU
    ((10, 18, 18, 0), (0x00, 0x40, 0xC5, 0x00), 16, 0xB3, 0x0A),  # 105 LOADL
    ((10, 18, 19, 0), (0x00, 0x40, 0xC4, 0x00), 16, 0xAB, 0x02),  # 106 LOADS
    ((10, 18, 19, 0), (0x00, 0x40, 0xC4, 0x00), 16, 0xAB, 0x02),  # 107 LOADSE
    ((10, 18, 19, 0), (0x00, 0x40, 0xC4, 0x00), 16, 0xAB, 0x02),  # 108 LOADSO
    ((10, 18, 4, 0), (0x00, 0x40, 0xC4, 0x00), 16, 0xB3, 0x03),  # 109 LOADD
    ((18, 18, 18, 0), (0x00, 0xC4, 0xC8, 0x00), 15, 0xA3, 0x07),  # 110 LOAD_PAIR
    ((18, 0, 0, 0), (0xC4, 0x00, 0x00, 0x00), 0, 0x11, 0x4F),  # 111 MFNEXTCC
    ((18, 0, 0, 0), (0xC4, 0x00, 0x00, 0x00), 0, 0x09, 0x07),  # 112 MFIPPSW
    ((18, 0, 0, 0), (0xC4, 0x00, 0x00, 0x00), 0, 0x11, 0xCF),  # 113 MFFPCC
    ((18, 0, 0, 0), (0xC4, 0x00, 0x00, 0x00), 0, 0x09, 0x07),  # 114 MFFPPSW
    ((13, 18, 18, 0), (0x00, 0x00, 0xC5, 0x00), 22, 0x2B, 0x0A),  # 115 MFPR
    ((19, 18, 0, 0), (0x00, 0xC4, 0x01, 0x00), 12, 0x1A, 0x0A),  # 116 MFFP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 12, 0x00, 0x07),  # 117 FPQUIESCE
    ((18, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x00),  # 118 STOREB
    ((18, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x01),  # 119 STOREW
    ((18, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x02),  # 120 STOREL
    ((19, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x02),  # 121 STORES
    ((19, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x02),  # 122 STORESE
    ((19, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xB3, 0x02),  # 123 STORESO
    ((4, 10, 18, 0), (0x00, 0x00, 0x40, 0x00), 21, 0xBB, 0x03),  # 124 STORED
    ((18, 13, 18, 0), (0x00, 0x00, 0x00, 0x00), 23, 0x2B, 0x07),  # 125 MTPR
    ((18, 19, 0, 0), (0x00, 0xC4, 0x00, 0x00), 12, 0x12, 0x07),  # 126 MTFP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 7, 0x10, 0x07),  # 127 ENABLE
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 7, 0x10, 0x07),  # 128 DISABLE
    ((1, 18, 0, 0), (0x04, 0xC0, 0x00, 0x03), 2, 0x42, 0x3F),  # 129 CALL
    ((20, 18, 0, 0), (0x00, 0x00, 0x00, 0x03), 20, 0x41, 0x3F),  # 130 SVC
    ((20, 20, 0, 0), (0x00, 0x00, 0x00, 0x03), 20, 0x42, 0x3F),  # 131 SVC2
    ((18, 0, 0, 0), (0x04, 0x00, 0x00, 0x00), 24, 0x19, 0x07),  # 132 RETURN
    ((19, 19, 0, 0), (0x01, 0xC8, 0x00, 0x00), 8, 0x1A, 0x02),  # 133 MOVEI
    ((19, 19, 0, 0), (0x01, 0xC0, 0x00, 0x00), 18, 0x12, 0x02),  # 134 PMOVEI
    ((19, 19, 0, 0), (0x00, 0xC8, 0x00, 0x00), 8, 0x12, 0x02),  # 135 NEGI
    ((19, 19, 0, 0), (0x00, 0xC8, 0x00, 0x00), 8, 0x12, 0x02),  # 136 COMI
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 137 ADDI
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 138 SUBI
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 139 ANDI
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 140 ORI
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 141 XORI
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 8, 0x1A, 0x8F),  # 142 CVTIS
    ((19, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 8, 0x22, 0x8F),  # 143 CVTID
    ((19, 19, 0, 0), (0x01, 0xC8, 0x00, 0x00), 17, 0x1A, 0x02),  # 144 COPYS
    ((19, 19, 0, 0), (0x01, 0xC0, 0x00, 0x00), 18, 0x12, 0x02),  # 145 PCOPYS
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0x9A, 0x8A),  # 146 MOVES
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0x9A, 0x8A),  # 147 NEGS
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0x9A, 0x8A),  # 148 ABSS
    ((19, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0xA2, 0x8F),  # 149 CVTSD
    ((19, 19, 0, 0), (0x00, 0xC8, 0x00, 0x00), 17, 0x92, 0x07),  # 150 ROUNDSI
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0x9A, 0x8A),  # 151 ROUNDS
    ((19, 19, 0, 0), (0x02, 0xC8, 0x00, 0x00), 17, 0x92, 0x07),  # 152 TRUNCSI
    ((19, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 17, 0x9A, 0x8A),  # 153 TRUNCS
    ((19, 19, 19, 0), (0x02, 0x00, 0xC9, 0x00), 17, 0xA3, 0x8A),  # 154 ADDS
    ((19, 19, 19, 0), (0x02, 0x00, 0xC9, 0x00), 17, 0xA3, 0x8A),  # 155 SUBS
    ((19, 19, 0, 0), (0x00, 0x00, 0x00, 0x01), 17, 0x9A, 0x8A),  # 156 CMPS
    ((19, 0, 0, 0), (0x00, 0x00, 0x00, 0x01), 17, 0x11, 0x8A),  # 157 CLASSS
    ((19, 0, 0, 0), (0x00, 0x00, 0x00, 0x01), 17, 0x11, 0x8A),  # 158 TSTS
    ((19, 19, 19, 0), (0x02, 0x00, 0xC9, 0x00), 17, 0xA3, 0x8A),  # 159 MINS
    ((19, 19, 19, 0), (0x02, 0x00, 0xC9, 0x00), 17, 0xA3, 0x8A),  # 160 MAXS
    ((4, 4, 0, 0), (0x01, 0xC8, 0x00, 0x00), 3, 0x2A, 0x03),  # 161 COPYD
    ((4, 4, 0, 0), (0x01, 0xC0, 0x00, 0x00), 18, 0x22, 0x03),  # 162 PCOPYD
    ((4, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xAA, 0x8B),  # 163 MOVED
    ((4, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xAA, 0x8B),  # 164 NEGD
    ((4, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xAA, 0x8B),  # 165 ABSD
    ((4, 19, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xA2, 0x8F),  # 166 CVTDS
    ((4, 19, 0, 0), (0x00, 0xC8, 0x00, 0x00), 3, 0x9A, 0x07),  # 167 ROUNDDI
    ((4, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xAA, 0x8B),  # 168 ROUNDD
    ((4, 19, 0, 0), (0x02, 0xC8, 0x00, 0x00), 3, 0x9A, 0x07),  # 169 TRUNCDI
    ((4, 4, 0, 0), (0x00, 0xC8, 0x01, 0x00), 3, 0xAA, 0x8B),  # 170 TRUNCD
    ((4, 4, 4, 0), (0x02, 0x00, 0xC9, 0x00), 3, 0xBB, 0x8B),  # 171 ADDD
    ((4, 4, 4, 0), (0x02, 0x00, 0xC9, 0x00), 3, 0xBB, 0x8B),  # 172 SUBD
    ((4, 4, 0, 0), (0x00, 0x00, 0x00, 0x01), 3, 0xAA, 0x8B),  # 173 CMPD
    ((4, 0, 0, 0), (0x00, 0x00, 0x00, 0x01), 3, 0x99, 0x8B),  # 174 CLASSD
    ((4, 0, 0, 0), (0x00, 0x00, 0x00, 0x01), 3, 0x99, 0x8B),  # 175 TSTD
    ((4, 4, 4, 0), (0x02, 0x00, 0xC9, 0x00), 3, 0xBB, 0x8B),  # 176 MIND
    ((4, 4, 4, 0), (0x02, 0x00, 0xC9, 0x00), 3, 0xBB, 0x8B),  # 177 MAXD
    ((19, 19, 19, 0), (0x00, 0x00, 0xC8, 0x00), 8, 0x1B, 0x02),  # 178 MULI
    ((19, 19, 19, 0), (0x00, 0x00, 0xF8, 0x00), 8, 0x1B, 0x02),  # 179 DIVI
    ((19, 19, 0, 0), (0x00, 0xDC, 0x01, 0x00), 17, 0x9A, 0x8A),  # 180 SQRTS
    ((19, 19, 19, 0), (0x02, 0x00, 0xC9, 0x00), 17, 0xA3, 0x8A),  # 181 MULS
    ((19, 19, 19, 0), (0x00, 0x00, 0xD5, 0x00), 17, 0xA3, 0x8A),  # 182 DIVS
    ((4, 4, 0, 0), (0x00, 0xF4, 0x01, 0x00), 3, 0xAA, 0x8B),  # 183 SQRTD
    ((4, 4, 4, 0), (0x02, 0x00, 0xC9, 0x00), 3, 0xBB, 0x8B),  # 184 MULD
    ((4, 4, 4, 0), (0x00, 0x00, 0xDD, 0x00), 3, 0xBB, 0x8B),  # 185 DIVD
    ((19, 19, 0, 0), (0x02, 0x88, 0x00, 0x00), 17, 0x9A, 0x02),  # 186 ADDS5
    ((19, 19, 0, 0), (0x02, 0x88, 0x00, 0x00), 17, 0x9A, 0x02),  # 187 SUBS5
    ((19, 19, 0, 0), (0x02, 0xC8, 0x00, 0x00), 17, 0x92, 0x07),  # 188 TRUNCSI5
    ((4, 4, 0, 0), (0x02, 0x88, 0x00, 0x00), 3, 0xB2, 0x03),  # 189 ADDD5
    ((4, 4, 0, 0), (0x02, 0x88, 0x00, 0x00), 3, 0xB2, 0x03),  # 190 SUBD5
    ((4, 19, 0, 0), (0x02, 0xC8, 0x00, 0x00), 3, 0x9A, 0x07),  # 191 TRUNCDI5
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 0, 0x00, 0x07),  # 192 NOP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 8, 0x00, 0x07),  # 193 FNOP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x02), 13, 0x10, 0x4F),  # 194 IPCCNOP
    ((18, 18, 0, 0), (0x00, 0xC0, 0x00, 0x00), 0, 0x12, 0x07),  # 195 SHIFTNOP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 4, 0x19, 0x07),  # 196 ENTRY
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 11, 0x18, 0x07),  # 197 LIMIT
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 19, 0x00, 0x07),  # 198 EPILOGUE
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 19, 0x00, 0x07),  # 199 LABEL
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 19, 0x00, 0x07),  # 200 LABEL$
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 9, 0x00, 0x07),  # 201 SEQ
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 9, 0x00, 0x07),  # 202 MMT_SEQ
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 26, 0x18, 0x07),  # 203 JOIN_BP
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 25, 0x09, 0x07),  # 204 LTORG
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 25, 0x09, 0x07),  # 205 TABLEB
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 25, 0x09, 0x07),  # 206 TABLEW
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 25, 0x09, 0x07),  # 207 TABLEL
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 0, 0x00, 0x07),  # 208 COSTLY
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 0, 0x00, 0x07),  # 209 BUGCHECK
    ((0, 0, 0, 0), (0x00, 0x00, 0x00, 0x00), 0, 0x00, 0x07),  # 210 NONE
    ((0, 0, 0, 0), (0x01, 0x00, 0x01, 0x00), 0, 0x08, 0x0A),  # 211 ADJ_MOVE
]

# instruction_mnemonic (with instruction_mnemonic_length): the classic
# listing's names, by opcode
INSTRUCTION_MNEMONIC = [
    '', 'BNEVER', 'BNL2V', 'BL2V', 'BNL2', 'BL2', 'BNZ3', 'BZ3', 'BGT', 'BLE',
    'BGE', 'BLT', 'BHI', 'BLS', 'BLO', 'BHS', 'BNN', 'BN', 'BNE', 'BEQ', 'BNV',
    'BV', 'FBEQ', 'FBNE', 'FBGT', 'FBLE', 'FBGE', 'FBLT', 'TRAP_GT', 'TRAP_LE',
    'TRAP_GE', 'TRAP_LT', 'TRAP_HI', 'TRAP_LS', 'TRAP_LO', 'TRAP_HS',
    'TRAP_NN', 'TRAP_N', 'TRAP_NE', 'TRAP_EQ', 'TRAP_NV', 'TRAP_V', 'TRAP_FEQ',
    'TRAP_FNE', 'TRAP_FGT', 'TRAP_FLE', 'TRAP_FGE', 'TRAP_FLT', 'TRAPD_GT',
    'TRAPD_LE', 'TRAPD_GE', 'TRAPD_LT', 'TRAPD_HI', 'TRAPD_LS', 'TRAPD_LO',
    'TRAPD_HS', 'TRAPD_NN', 'TRAPD_N', 'TRAPD_NE', 'TRAPD_EQ', 'TRAPD_NV',
    'TRAPD_V', 'TRAPD_FEQ', 'TRAPD_FNE', 'TRAPD_FGT', 'TRAPD_FLE', 'TRAPD_FGE',
    'TRAPD_FLT', 'TRAP', 'JUMP', 'DISPATCH', 'TSTB', 'TSTW', 'TST', 'CMP',
    'MOVE', 'PMOVE', 'NEG', 'COM', 'ADD', 'ADDC', 'SUB', 'SUBC', 'RSUB', 'AND',
    'OR', 'XOR', 'EXTEND0', 'EXTEND7', 'EXTEND15', 'ASR', 'LSR', 'LSL',
    'ISOLATE', 'CLRINS', 'TRANSFER', 'INSERT', 'EXTRACTU', 'WIDENB', 'WIDENW',
    'SYNCHB', 'SYNCHW', 'SYNCH', 'LOADBU', 'LOADWU', 'LOADL', 'LOADS',
    'LOADSE', 'LOADSO', 'LOADD', 'LOAD_PAIR', 'MFNEXTCC', 'MFIPPSW', 'MFFPCC',
    'MFFPPSW', 'MFPR', 'MFFP', 'FPQUIESCE', 'STOREB', 'STOREW', 'STOREL',
    'STORES', 'STORESE', 'STORESO', 'STORED', 'MTPR', 'MTFP', 'ENABLE',
    'DISABLE', 'CALL', 'SVC', 'SVC2', 'RETURN', 'MOVEI', 'PMOVEI', 'NEGI',
    'COMI', 'ADDI', 'SUBI', 'ANDI', 'ORI', 'XORI', 'CVTIS', 'CVTID', 'COPYS',
    'PCOPYS', 'MOVES', 'NEGS', 'ABSS', 'CVTSD', 'ROUNDSI', 'ROUNDS', 'TRUNCSI',
    'TRUNCS', 'ADDS', 'SUBS', 'CMPS', 'CLASSS', 'TSTS', 'MINS', 'MAXS',
    'COPYD', 'PCOPYD', 'MOVED', 'NEGD', 'ABSD', 'CVTDS', 'ROUNDDI', 'ROUNDD',
    'TRUNCDI', 'TRUNCD', 'ADDD', 'SUBD', 'CMPD', 'CLASSD', 'TSTD', 'MIND',
    'MAXD', 'MULI', 'DIVI', 'SQRTS', 'MULS', 'DIVS', 'SQRTD', 'MULD', 'DIVD',
    'ADDS5', 'SUBS5', 'TRUNCSI5', 'ADDD5', 'SUBD5', 'TRUNCDI5', 'NOP', 'FNOP',
    'IPCCNOP', 'SHIFTNOP', 'ENTRY', 'LIMIT', 'EPILOGUE', 'LABEL', 'LABEL$',
    'SEQ', 'MMT_SEQ', 'JOIN_BP', 'LTORG', 'TABLEB', 'TABLEW', 'TABLEL',
    'COSTLY', 'BUGCHECK', 'NONE', 'ADJ_MOVE',
]

# of_string (with of_string_length): the operand forms' names, by of$t
OF_STRING = [
    'none',  # 0
    'ip_reg_or_long_pc_disp',  # 1
    'ip_reg_or_basic_block',  # 2
    'ip_compare_a_operand',  # 3
    'fp_reg_pair',  # 4
    'short_pc_disp',  # 5
    'ip_reg_or_s_immed11',  # 6
    'ip_reg_scaled_or_s_immed8',  # 7
    's_immed16',  # 8
    'ip_reg_or_s_immed8',  # 9
    'ip_reg_scaled_or_s_immed16',  # 10
    'ip_reg_or_s_immed16',  # 11
    'ip_reg_or_u_i16_or_hi_i16',  # 12
    'u_immed13',  # 13
    'ip_reg_or_and_or_bic_u_immed16',  # 14
    'sc_reg_or_u_immed5',  # 15
    'ip_reg_or_u_immed5',  # 16
    'fp_reg_quad',  # 17
    'ip_reg',  # 18
    'fp_reg',  # 19
    'u_immed4',  # 20
    'ip_reg_scaled_or_pa_add_immed',  # 21
    'trap_serialize_register',  # 22
    'ip_reg_or_s_immed5',  # 23
    '0_mod_2_s_immed16',  # 24
    '0_mod_4_s_immed16',  # 25
    'ip_reg_or_s_u_hi_immed16',  # 26
    'ip_reg_or_0_mod_2_s_immed16',  # 27
    'ip_reg_or_0_mod_4_s_immed16',  # 28
    'ip_reg_or_0_mod_8_s_immed16',  # 29
    'ip_reg_or_0_mod_16_s_immed16',  # 30
    'ip_reg_or_s_immed14',  # 31
    'control_register',  # 32
    'ip_reg_scaled_3_or_s_immed5',  # 33
    'ip_reg_scaled_2_or_s_immed5',  # 34
    'signed_immed11',  # 35
    'ip_reg_scaled_2_or_s_immed14',  # 36
    'ip_reg_scaled_or_pa_move_immed',  # 37
    'u_immed5',  # 38
    'ip_reg_scaled_3_or_s_immed14',  # 39
    'signed_immed14',  # 40
    'space_register',  # 41
    'ip_reg_scaled_1_or_s_immed14',  # 42
]  # end of OF_STRING


if __name__ == '__main__':
    main()
