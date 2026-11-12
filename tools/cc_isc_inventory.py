#!/usr/bin/env python3
"""cc_isc_inventory.py - the generated ISC of cc.a88k: routines, actions, matcher.

    tools/cc_isc_inventory.py [--binary B] routines   [--all]
    tools/cc_isc_inventory.py [--binary B] summary
    tools/cc_isc_inventory.py [--binary B] clusters   [--level 0|1|2] [--pass 1|2] [--show N]
    tools/cc_isc_inventory.py [--binary B] matcher    [--rule R]
    tools/cc_isc_inventory.py [--binary B] tables
    tools/cc_isc_inventory.py [--binary B] il
    tools/cc_isc_inventory.py [--binary B] fields
    tools/cc_isc_inventory.py [--binary B] json OUT

The ISC generator's output (docs/questions.md 151, docs/iscg-design.md)
lies in cc.a88k between isc_debug's start and isc_to_lir's (0x0BD1DC ..
0x2088B0).  .blocks names the routines of isc_debug, isc_main,
isc_pass_1_main, isc_pass_2_main and isc_pattern_matcher; the pattern
actions between 0x0F0B02 and 0x20042C have no record.  This tool finds
every routine in the range from

  - the .blocks records of the iscg_input units;
  - the two action tables, one routine per rule: the pass-1 actions in
    isc_pattern_matcher's data (A5 0x4800BC, rule r at A5 - 4 + 4r,
    called by hard_work) and the pass-2 actions in isc_pass_2_main's
    (A5 0x47F788, called by pass_2); the tables' length (563 rules) is
    where their .rwdi initialization stops;
  - the targets of jsr/bsr from the routines found so far;
  - any remaining `link a6,#-n' that opens a plausible prologue in the
    bytes no routine covers;

and reports each one's address, code length (through its last rts),
span (to the next routine), name (.blocks) or table entry, the A5 it
loads (each of the action modules has its own: the generated actions
are 25 + 25 separately compiled modules without .blocks units) and the
routines it calls.

  routines  one line per routine (--all: also the named ones' callees)
  summary   counts by unit/module, sizes, empty actions
  clusters  the actions grouped by normalized body: level 0 masks only
            addresses, the A5, the rule number and the trace string;
            level 1 also every immediate and displacement; level 2 also
            the callees.  Prints the clusters (largest first) with a
            representative's normalized listing (--show N of them).
  matcher   the rules decoded from pattern_matcher (subject kind, IL
            operator, child kinds), with the per-rule tables (result
            kind, hard_work's two flag bytes)
  tables    isc_tool_generated_readonly_tables decoded: the result kind
            of each rule, then six opcode maps indexed by il$t
  il        isc_pass_1_main's operator routines: the il$t, the number
            of children and each pass_1 call's permissible set, beside
            the union of the kinds the matcher tests at each position
  fields    the solution's attribute names, from dump_solution, with
            the offset (and bit) each is read at
  json      routines, rules and matcher as JSON (for the phase-2
            extractor)

Disassembly is m68k-elf-objdump's, one routine at a time.
"""
import argparse
import bisect
import collections
import concurrent.futures
import json
import os
import re
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import coff_compare as cc  # noqa: E402
import cc_data  # noqa: E402

DEFAULT_BINARY = os.path.join(HERE, '..', 'ctape', 'install', 'ri.apollo.cc.v.6.9.mpx', 'cc.a88k')
ISCG = 'iscg_input'
P1_A5 = 0x4800BC        # isc_pattern_matcher's data: pass-1 action table at +0
P2_A5 = 0x47F788        # isc_pass_2_main's data: pass-2 action table at +0
TOOL_TABLES = 0x2BC13C  # isc_tool_generated_readonly_tables
TOOL_TABLES_LEN = 3264
SOLUTION_KINDS = ['none', 'case_jump_base', 'fp_reg_pair_high', 'fp_reg_pair_low',
                  'local_routine', 'address_mode', 'ctl_reg', 'flow', 'fp_reg',
                  'fp_reg_pair', 'fp_reg_quad', 'ip_reg', 'ip_reg_field',
                  'ip_reg_scaled', 'literal_32_bits', 'literal_64_bits',
                  'processor_reg', 'sc_reg', 'sr_reg', 'dummy', 'any_solution',
                  'irrelevant', 'proper_subtree', 'void', 'k_max']
TRACE = re.compile(rb'Pattern (\d+) matched the semantics\.')


# --------------------------------------------------------------------------
# the image

class Image:
    def __init__(self, path):
        self.coff = cc.Coff(path)
        self.img = cc.CoffImage(self.coff)
        self.units = self.coff.units()
        self.names = {}
        for va, sym, _ in self.coff.relocations('.aptv'):
            if sym:
                self.names.setdefault(va - 2, sym)
        self.blocks = []        # (start, length, name, unit source)
        for u in self.units:
            for nm, lv, st, ln in u['blocks']:
                self.blocks.append((st, ln, nm, u['source'], lv))
                self.names.setdefault(st, nm)
        starts = sorted(u['text'] for u in self.units if u['text'])
        self.unit_starts = starts
        self.iscg = [u for u in self.units if u['source'] and ISCG in u['source']]
        lo = min(u['text'] for u in self.iscg if u['blocks'])
        after = [s for s in starts if s > max(st for st, _, _, src, _ in self.blocks
                                                if src and ISCG in src)]
        self.lo, self.hi = lo, after[0]
        self._init = {}

    def read(self, va, n):
        return self.img.read(va, n)

    def initial(self, lo, n):
        return cc_data.initial(self.coff, lo, n)

    def longs(self, lo, n):
        b = self.initial(lo, 4 * n)
        return [None if None in b[4 * i:4 * i + 4] else
                int.from_bytes(bytes(b[4 * i:4 * i + 4]), 'big') for i in range(n)]

    def unit_of(self, va):
        """The .blocks unit whose code start is the last at or before va."""
        best = None
        for u in self.units:
            if u['text'] and u['text'] <= va and (best is None or u['text'] > best['text']):
                if u['blocks'] or ISCG in (u['source'] or ''):
                    best = u
        return best

    def action_table(self, a5):
        """The routine pointers at a5 + 4(r-1), r = 1.., while .rwdi sets them."""
        out = []
        while True:
            v = self.longs(a5 + 4 * len(out), 1)[0]
            if v is None or not (self.lo <= v < self.hi):
                break
            out.append(v)
        return out


# --------------------------------------------------------------------------
# disassembly

LINE = re.compile(r'\s*([0-9a-f]+):\s+((?:[0-9a-f]{4} ?)+)\s*\t?(.*)$')


def objdump(data, start):
    with tempfile.NamedTemporaryFile(suffix='.bin') as f:
        f.write(data)
        f.flush()
        out = subprocess.run(['m68k-elf-objdump', '-D', '-b', 'binary', '-m', 'm68k:68020',
                              '--adjust-vma=0x%x' % start, f.name],
                             capture_output=True, text=True, check=True).stdout
    insns = []
    for line in out.splitlines():
        m = LINE.match(line)
        if not m:
            if insns and re.match(r'\s*[0-9a-f]+:\s+[0-9a-f]{4}\s*$', line):
                pass
            continue
        a = int(m.group(1), 16)
        hexs = m.group(2).split()
        text = m.group(3).strip()
        if not text and insns and a < insns[-1][0] + insns[-1][1]:
            continue
        insns.append([a, 2 * len(hexs), text, ''.join(hexs)])
    # objdump continues long instructions on a second line without text
    merged = []
    for a, n, t, h in insns:
        if merged and not t and a == merged[-1][0] + merged[-1][1]:
            merged[-1][1] += n
            merged[-1][3] += h
        elif t:
            merged.append([a, n, t, h])
    return merged


def hexindex(text):
    def fix(m):
        v = int(m.group(2), 16)
        if v >= 1 << 63:
            v -= 1 << 64
        elif v >= 1 << 31 and len(m.group(2)) == 8:
            v -= 1 << 32
        return '%s@(%s0x%x,' % (m.group(1), '-' if v < 0 else '', abs(v))
    return re.sub(r'(%[a-z0-9]+)@\(([0-9a-f]+),(?=%)', fix, text)


# the matcher's instructions that are neither tests nor calls: the arguments
# of hard_work, the branches of the tests, the bound checks of the case jumps,
# the trace at the start and the epilogue
BOILER = re.compile(r'^(movel %fp@\(\d+\),%sp@-|movel %d[2-5],%sp@-|pea %a3@|lea %sp@\(\d+\),%sp'
                    r'|b(ne|eq)[sw]? 0x|bsrw 0x|addqw #\d,%sp|movew %a3@\((98|108)\),%d0'
                    r'|subqw #1,%d0|cmpiw #\d+,%d0|bccw 0x|addw %d0,%d0|movew %pc@|jmp %pc@'
                    r'|movel %a5@\(-4\),%sp@-|movew #\d+,%sp@-|pea %pc@|jsr 0x|moveml|unlk|rts'
                    r'|linkw|lea 0x[0-9a-f]+,%a5|movel %fp@\(\d+\),%d\d|moveal %fp@\(\d+\),%a3'
                    r'|addql #1,0x|tstb 0x|bpl[sw] 0x|clrl %sp@-|moveb #0,%a5@)')
BRANCH = re.compile(r'^(b[a-z]+|db[a-z]+|jmp|jsr|bsr[a-z]*)\s+(0x[0-9a-f]+)')
PCREL = re.compile(r'%pc@\((0x[0-9a-f]+)\)')


class Routine:
    def __init__(self, start):
        self.start = start
        self.name = None
        self.length = None
        self.level = None
        self.unit = None
        self.p1_rule = None
        self.p2_rule = None
        self.callers = set()
        self.insns = []
        self.code_end = start
        self.span_end = start
        self.a5 = None
        self.calls = []
        self.consts = []        # pc-relative constant addresses
        self.trace = None

    @property
    def code_len(self):
        return self.code_end - self.start

    @property
    def span(self):
        return self.span_end - self.start

    def kind(self):
        if self.name:
            return 'named'
        if self.p1_rule:
            return 'p1-action'
        if self.p2_rule:
            return 'p2-action'
        if self.callers:
            return 'called'
        return 'unreached'


def analyze(im, r, end):
    """Disassemble r from its start to end (the next routine) and find its
    code's end (its last rts before its first pc-relative constant), the
    A5 it loads, its calls and constants."""
    data = im.read(r.start, end - r.start)
    insns = objdump(data, r.start)
    consts = []
    for a, n, t, h in insns:
        for m in PCREL.finditer(t):
            v = int(m.group(1), 16)
            if r.start < v < end and t.startswith(('pea', 'lea')):
                consts.append(v)
    limit = min([c for c in consts if c > r.start] + [end])
    if r.length:
        limit = r.start + r.length       # a named routine: .blocks has it
    code = [i for i in insns if i[0] < limit]
    last = None
    for k, (a, n, t, h) in enumerate(code):
        if t.startswith('rts') or t.startswith('rtd'):
            last = k
    if last is None:
        last = len(code) - 1
    code = code[:last + 1]
    r.insns = [(a, n, hexindex(t), h) for a, n, t, h in code]
    r.code_end = code[-1][0] + code[-1][1] if code else r.start
    r.span_end = end
    r.consts = sorted(set(consts))
    for a, n, t, h in r.insns[:8]:
        m = re.match(r'lea (0x[0-9a-f]+),%a5', t)
        if m:
            r.a5 = int(m.group(1), 16)
            break
    for a, n, t, h in r.insns:
        m = BRANCH.match(t)
        if m and m.group(1) in ('jsr', 'bsrw', 'bsrs', 'bsrl', 'bsr'):
            r.calls.append(int(m.group(2), 16))
    for c in r.consts:
        d = im.read(c, 64)
        m = TRACE.match(d)
        if m:
            r.trace = int(m.group(1))


PROLOGUE = re.compile(rb'\x4e\x56[\xff\x00]')


def plausible_start(im, va):
    d = im.read(va, 8)
    if d[:2] != b'\x4e\x56':
        return False
    disp = struct.unpack('>h', d[2:4])[0]
    if disp > 0 or disp & 1 or disp < -0x4000:
        return False
    nxt = d[4:6]
    return nxt in (b'\x48\xe7', b'\x48\x55', b'\x48\x53', b'\x48\x52', b'\x4b\xf9',
                   b'\x2f\x0d', b'\x2f\x02', b'\x2f\x03', b'\x20\x6e', b'\x22\x6e',
                   b'\x24\x6e', b'\x26\x6e', b'\x2d\x6e', b'\x4e\x5e') or \
        nxt[:1] in (b'\x20', b'\x22', b'\x24', b'\x26', b'\x28', b'\x2a', b'\x30',
                    b'\x32', b'\x34', b'\x36', b'\x41', b'\x43', b'\x45', b'\x47',
                    b'\x4a', b'\x42', b'\x55', b'\x1d', b'\x2d', b'\x3d', b'\x70')


def inventory(im):
    rs = {}

    def add(va):
        if va not in rs:
            rs[va] = Routine(va)
        return rs[va]

    for st, ln, nm, src, lv in im.blocks:
        if im.lo <= st < im.hi:
            r = add(st)
            r.name, r.level, r.unit, r.length = nm, lv, src, ln
    p1 = im.action_table(P1_A5)
    p2 = im.action_table(P2_A5)
    for k, va in enumerate(p1):
        add(va).p1_rule = k + 1
    for k, va in enumerate(p2):
        add(va).p2_rule = k + 1
    done = set()
    pool = concurrent.futures.ThreadPoolExecutor(max_workers=8)
    while True:
        todo = sorted(set(rs) - done)
        if not todo:
            # look for prologues in the bytes no routine covers
            spans = sorted((r.start, r.code_end) for r in rs.values())
            new = []
            for (s0, e0), (s1, _) in zip(spans, spans[1:] + [(im.hi, im.hi)]):
                gap = im.read(e0, s1 - e0) if s1 > e0 else b''
                for m in PROLOGUE.finditer(gap):
                    va = e0 + m.start()
                    if va & 1 == 0 and plausible_start(im, va) and \
                            not any(c <= va < c + 64 for c in
                                    (x for r in rs.values() for x in r.consts
                                     if s0 <= x < s1)):
                        new.append(va)
            new = [v for v in new if v not in rs]
            if not new:
                break
            for v in new:
                add(v)
            continue
        starts = sorted(rs)
        jobs = {}
        for va in todo:
            i = bisect.bisect_right(starts, va)
            end = starts[i] if i < len(starts) else im.hi
            jobs[va] = pool.submit(analyze, im, rs[va], min(end, im.hi))
        for va, f in jobs.items():
            f.result()
            done.add(va)
        for r in list(rs.values()):
            for c in r.calls:
                if im.lo <= c < im.hi:
                    callee = add(c)
                    callee.callers.add(r.start)
        # a routine found inside another's span shortens that one: redo it
        starts = sorted(rs)
        for va in list(done):
            r = rs[va]
            i = bisect.bisect_right(starts, va)
            end = starts[i] if i < len(starts) else im.hi
            if end != r.span_end:
                done.discard(va)
    for r in rs.values():
        if not r.unit:
            u = im.unit_of(r.start)
            r.unit = u['source'] if u else None
    return [rs[k] for k in sorted(rs)], p1, p2


def modules(rs):
    """The routines grouped into modules, in address order: a named routine
    by its unit; a pass-1 action by the A5 it loads (every one loads it);
    a pass-2 action by the module of its rule's pass-1 action (the pass-2
    modules hold the same rules as the pass-1 ones, in the same order;
    an empty pass-2 action is a bare rts that loads no A5, and two of the
    pass-2 modules have nothing else).  The key is (A5 or None, the
    module's first pass-1 A5 for a pass-2 module)."""
    p1mod = {r.p1_rule: r.a5 for r in rs if r.p1_rule}
    out = collections.OrderedDict()
    for r in rs:
        if r.p2_rule:
            key = ('p2', p1mod[r.p2_rule])
        elif r.p1_rule:
            key = ('p1', r.a5)
        else:
            key = ('named', r.unit)
        out.setdefault(key, []).append(r)
    return out


def module_a5(ms):
    a5s = sorted({r.a5 for r in ms if r.a5 is not None})
    return a5s


def short(src):
    return src.split('/')[-1] if src else '?'


def module_name(im, key, rs):
    if key[0] == 'named':
        return short(key[1])
    p = sorted({r.p1_rule for r in rs if r.p1_rule} | {r.p2_rule for r in rs if r.p2_rule})
    return '(anonymous %s actions, rules %d..%d)' % (key[0], p[0], p[-1])


# --------------------------------------------------------------------------
# normalization and clusters

NUM = re.compile(r'(?<![%\w])(-?0x[0-9a-f]+|-?\d+)(?![\w])')


def normalize(im, r, level):
    rule = r.p1_rule or r.p2_rule
    out = []
    ins = r.insns
    trace_len_idx = set()
    for k, (a, n, t, h) in enumerate(ins):
        m = PCREL.search(t)
        if m and t.startswith('pea') and r.trace is not None and \
                int(m.group(1), 16) in r.consts and k > 0:
            trace_len_idx.add(k - 1)
    for k, (a, n, t, h) in enumerate(ins):
        t = re.sub(r'\s+;.*$', '', t)
        t = re.sub(r'lea 0x[0-9a-f]+,%a5', 'lea A5,%a5', t)
        bm = BRANCH.match(t)
        if bm:
            tgt = int(bm.group(2), 16)
            if bm.group(1) in ('jsr', 'bsrw', 'bsrs', 'bsrl', 'bsr'):
                nm = im.names.get(tgt, '0x%x' % tgt)
                t = 'call %s' % (nm if level < 2 else 'X')
            else:
                t = '%s L%+d' % (bm.group(1), tgt - r.start) if level == 0 else '%s L' % bm.group(1)
        t = PCREL.sub('%pc@(K)', t)
        if k in trace_len_idx:
            t = 'movew #TLEN,%sp@-'
        if rule is not None:
            t = t.replace('#%d,%%a0@(112)' % rule, '#RULE,%a0@(112)')
        t = re.sub(r'(?<![%\w])0x4[0-9a-f]{5}(?![\w])', 'ABS', t)
        if level >= 1:
            t = NUM.sub('N', t)
        out.append(t)
    return tuple(out)


def clusters(im, rs, level, which):
    groups = collections.defaultdict(list)
    for r in rs:
        rule = r.p1_rule if which == 1 else r.p2_rule
        if rule:
            groups[normalize(im, r, level)].append(r)
    return sorted(groups.items(), key=lambda kv: (-len(kv[1]), kv[1][0].start))


# --------------------------------------------------------------------------
# the matcher

def decode_matcher(im, rs):
    """Walk pattern_matcher: its case on the subject's kind (+108), the case
    on the IL operator (+98) for a proper_subtree, and in each arm the
    sequence of guarded hard_work calls.  Each call's guard is the tests
    since the previous call: kind (or op) of a path from the subject (its
    children +116.., their children) equal to a constant or in a set."""
    pm = next(r for r in rs if r.name == 'pattern_matcher')
    hw = next(r for r in rs if r.name == 'hard_work')
    data = im.read(pm.start, pm.code_end - pm.start)
    ins = objdump(data, pm.start)
    ins = [(a, n, hexindex(t)) for a, n, t, h in ins]
    # jump tables: find `jmp %pc@(T,%d0:w)' with the bound check before
    tables = {}
    byaddr = {a: k for k, (a, n, t) in enumerate(ins)}
    for k, (a, n, t) in enumerate(ins):
        m = re.match(r'jmp %pc@\((0x[0-9a-f]+),%d\d:w\)', t)
        if m:
            T = int(m.group(1), 16)
            # bound: `cmpiw #B,%d0' and `subqw #1,%d0' before it
            bound, base = None, 0
            for j in range(k - 1, max(0, k - 8), -1):
                mm = re.match(r'cmpiw #(\d+),%d0', ins[j][2])
                if mm:
                    bound = int(mm.group(1))
                mm = re.match(r'subqw #(\d+),%d0', ins[j][2])
                if mm:
                    base = int(mm.group(1))
                mm = re.match(r'movew %a3@\((\d+)\),%d0', ins[j][2])
                if mm:
                    field = int(mm.group(1))
                    break
            d = im.read(T, 2 * (bound + 1))
            ents = [T + struct.unpack('>h', d[2 * i:2 * i + 2])[0] for i in range(bound + 1)]
            tables[T] = (field, base, ents)
    # arm starts: value -> address
    arms = {}       # address -> (field, value) list
    kind_default = None
    for T, (field, base, ents) in tables.items():
        from collections import Counter
        dflt = Counter(ents).most_common(1)[0][0]
        for i, e in enumerate(ents):
            if e != dflt:
                arms.setdefault(e, []).append((field, i + base))
        tables[T] = (field, base, ents, dflt)
    # walk linearly; symbolic registers
    spans = [(T, T + 2 * len(v[2])) for T, v in tables.items()]

    def inside_table(a):
        return any(lo <= a < hi for lo, hi in spans)
    residue = collections.Counter()
    fails = []
    # the arms' common exit: the case's default (the most common entry)
    ARM_END = [max(set(v[3] for v in tables.values()), key=lambda x: x)]
    rules = []
    regs = {}
    guard = []
    arm = None
    pending = None
    tail = None
    # the shared tail `pea rule; bra TAIL' calls hard_work at TAIL
    for k, (a, n, t) in enumerate(ins):
        if a in arms:
            arm = arms[a]
            guard = []
            regs = {}
        if a in byaddr and any(a == e for T in tables for e in tables[T][2]):
            pass
        m = re.match(r'moveal %a3@\((\d+)\),%(a\d)', t)
        if m:
            off = int(m.group(1))
            regs[m.group(2)] = ((off - 116) // 4 + 1,) if off >= 116 else ('f%d' % off,)
            continue
        m = re.match(r'moveal %(a\d)@\((\d+)\),%(a\d)', t)
        if m and m.group(1) in regs:
            off = int(m.group(2))
            regs[m.group(3)] = regs[m.group(1)] + ((off - 116) // 4 + 1,)
            continue
        m = re.match(r'(?:moveq|movel) #(-?\d+),%(d\d)', t)
        if m:
            regs[m.group(2)] = ('const', int(m.group(1)))
            continue
        m = re.match(r'movew %(a\d)@\((\d+)\),%(d\d)', t)
        if m and m.group(1) in regs:
            regs[m.group(3)] = ('field', regs[m.group(1)], int(m.group(2)))
            continue
        m = re.match(r'cmpiw #(-?\d+),%(a\d)@\((\d+)\)', t)
        if m and m.group(2) in regs:
            guard.append((regs[m.group(2)], int(m.group(3)), '=', int(m.group(1))))
            continue
        m = re.match(r'cmpw %(a\d)@\((\d+)\),%(d\d)', t)
        if m and m.group(1) in regs and regs.get(m.group(3), ('',))[0] == 'const':
            guard.append((regs[m.group(1)], int(m.group(2)), '=', regs[m.group(3)][1]))
            continue
        m = re.match(r'btst %(d\d),%(d\d)', t)
        if m:
            f, s = regs.get(m.group(1)), regs.get(m.group(2))
            if f and s and f[0] == 'field' and s[0] == 'const':
                guard.append((f[1], f[2], 'in', s[1]))
                continue
        m = re.match(r'(b(?:ne|eq)[sw]?) (0x[0-9a-f]+)', t)
        if m and guard:
            fails.append(int(m.group(2), 16))
        m = re.match(r'pea (0x[0-9a-f]+)$', t)
        if m:
            pending = int(m.group(1), 16)
            continue
        m = re.match(r'bsrw (0x[0-9a-f]+)', t)
        if m and int(m.group(1), 16) == hw.start and pending is not None:
            nxt = ins[k + 2][0] if k + 2 < len(ins) else None    # after `lea 28(sp)'
            rules.append({'rule': pending, 'arm': arm, 'guard': list(guard), 'at': a,
                          'nested': sorted({f for f in fails if f != nxt})})
            guard, fails = [], []
            pending = None
            continue
        m = re.match(r'bra[ws]? (0x[0-9a-f]+)', t)
        if m and pending is not None:
            rules.append({'rule': pending, 'arm': arm, 'guard': list(guard), 'at': a,
                          'tail': True, 'nested': sorted(set(fails) - {ARM_END[0]})})
            guard, fails = [], []
            pending = None
            continue
        if not inside_table(a) and not BOILER.match(t):
            residue[re.sub(r'0x[0-9a-f]+|#-?\d+|\d+', 'N', t)] += 1
    return rules, tables, residue


def decode_il_routines(im, rs):
    """isc_pass_1_main's per-IL routines (isc_<kind>[_<op>]): the il$t they
    give the proper_subtree (the word stored through their 22(fp)
    argument), the number of children (26(fp)) and, for each pass_1 call,
    the permissible kinds it passes (a constant, maybe less
    not_permissible_function's) or `inherited' (the routine's own)."""
    out = []
    pass1 = next(r.start for r in rs if r.name == 'pass_1')
    notperm_fn = next(a for a, n in im.names.items() if n == 'not_permissible_function')
    for r in rs:
        if not (r.name and r.name.startswith('isc_') and 'isc_pass_1_main' in (r.unit or '')):
            continue
        w98 = nkids = None
        regs = {}
        calls = []
        notperm = False
        fp22 = fp26 = None
        pushes = None
        for a, n, t, h in r.insns:
            m = re.match(r'movea?l %fp@\(22\),%(a\d)', t)
            if m:
                fp22 = m.group(1)
            m = re.match(r'movea?l %fp@\(26\),%(a\d)', t)
            if m:
                fp26 = m.group(1)
            m = re.match(r'movew #(\d+),%(a\d)@$', t)
            if m and m.group(2) == fp22 and w98 is None:
                w98 = int(m.group(1))
            m = re.match(r'(?:moveq|movel) #(-?\d+),%(d\d|fp@\(-?\d+\))', t)
            if m:
                regs[m.group(2)] = int(m.group(1))
            m = re.match(r'movel %(d\d),%(a\d)@$', t)
            if m and m.group(2) == fp26 and nkids is None and m.group(1) in regs:
                nkids = regs[m.group(1)]
            m = re.match(r'clrl %(a\d)@$', t)
            if m and m.group(2 - 1) == fp26 and nkids is None:
                nkids = 0
            if re.match(r'(jsr|bsr\w*) 0x%x$' % notperm_fn, t):
                notperm = True
            # pass_1's last argument (permissible) is pushed first, after
            # the result's room (`subql #2,sp')
            if t == 'subql #2,%sp':
                pushes = []
            m = re.match(r'movel %(d\d|fp@\(-?\d+\)),%sp@-', t)
            if m and pushes is not None:
                pushes.append(m.group(1))
            if re.match(r'(jsr|bsr\w*) 0x%x$' % pass1, t):
                mask = regs.get(pushes[0]) if pushes else None
                calls.append(('inherited' if mask is None else mask, notperm))
                notperm = False
                pushes = None
        out.append({'name': r.name, 'start': r.start, 'w98': w98, 'nchildren': nkids,
                    'pass_1_calls': calls})
    return out


def decode_fields(im, rs):
    """dump_solution (isc_debug) prints each field of a solution after its
    name: the attribute names of the generator's input.  For each name
    string, the first field access after it: (name, offset, access)."""
    ds = next(r for r in rs if r.name == 'dump_solution')
    ins = ds.insns
    out = []
    for k, (a, n, t, h) in enumerate(ins):
        m = re.match(r'pea %pc@\((0x[0-9a-f]+)\)', t)
        if not m:
            continue
        mm = re.match(r'movew #(\d+),%sp@-', ins[k - 1][2]) if k else None
        ln = int(mm.group(1)) if mm else 0
        text = im.read(int(m.group(1), 16), ln).decode('latin1').strip() if ln else ''
        if not re.match(r'^[a-z_0-9]+ =$', text):
            continue
        acc = None
        for a2, n2, t2, h2 in ins[k + 1:k + 16]:
            x = re.search(r'%a[0-4]@\((\d+)\)', t2)
            if x and not t2.startswith(('pea %pc', 'movel %a5')):
                acc = (int(x.group(1)), t2)
                break
        out.append((text[:-2], acc[0] if acc else None, acc[1] if acc else ''))
    seen, res = set(), []
    for x in out:
        if x[0] not in seen:
            seen.add(x[0])
            res.append(x)
    return res


def fmt_guard(g, ils=None):
    path, field, op, v = g
    p = 'subject' if path == () else '$' + '.'.join(str(x) for x in path)
    if field == 108:
        if op == '=':
            return '%s:%s' % (p, SOLUTION_KINDS[v] if 0 <= v < len(SOLUTION_KINDS) else v)
        ks = [SOLUTION_KINDS[b] for b in range(32) if v >> b & 1]
        return '%s:{%s}' % (p, ','.join(ks))
    if field == 98:
        return '%s.op=%s' % (p, (ils or {}).get(v, v))
    return '%s.+%d %s %s' % (p, field, op, v)


def il_names():
    path = os.path.join(HERE, '..', 'moon_unit', 'isc_prism_dervobjs', 'dseeaggs',
                        'iscg_input', 'hd69fbe76.000', 'iscg_input', 'isc_enumeration.ins.pas')
    try:
        text = open(path).read()
    except OSError:
        return {}
    body = text[text.index('il$t = ('):]
    names = re.findall(r'\b(il_[a-z0-9_]+|il\$k_max)\b', body)
    return {k: n for k, n in enumerate(names)}


def opcode_names():
    path = os.path.join(HERE, '..', 'idccclx', 'be_prism_68k_pool', 'dseemgrs', 'apollo',
                        'dervobjs', 'be_com', 'opcodes.def', 'h7ecfdfe8.000', 'opcodes',
                        'opcode_enumeration.ins.pas')
    try:
        text = open(path).read()
    except OSError:
        return {}
    text = text[text.index('opc$t = (') + len('opc$t = ('):]
    names = re.findall(r'\b(opc\$[a-z0-9_]+)\b', text, re.I)
    seen, out = set(), []
    for n in names:
        if n.lower() not in seen:
            seen.add(n.lower())
            out.append(n.lower())
    return {k: n for k, n in enumerate(out)}


def tool_tables(im, nrules):
    d = im.read(TOOL_TABLES, TOOL_TABLES_LEN)
    w = [struct.unpack('>H', d[2 * i:2 * i + 2])[0] for i in range(TOOL_TABLES_LEN // 2)]
    result_kind = w[:nrules]
    rest = w[nrules:]
    per_il = [rest[178 * k:178 * (k + 1)] for k in range(len(rest) // 178)]
    return result_kind, per_il, rest[178 * len(per_il):]


def rule_flags(im, nrules):
    f1 = im.initial(P1_A5 + 0x8CF + 1, nrules)
    f2 = im.initial(P1_A5 + 0xB07 + 1, nrules)
    return f1, f2


# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--binary', default=DEFAULT_BINARY)
    ap.add_argument('what', choices=['routines', 'summary', 'clusters', 'matcher', 'tables',
                                     'il', 'fields', 'json'])
    ap.add_argument('out', nargs='?')
    ap.add_argument('--level', type=int)
    ap.add_argument('--pass', dest='which', type=int, default=0)
    ap.add_argument('--show', type=int, default=10)
    ap.add_argument('--rule', type=int)
    ap.add_argument('--all', action='store_true')
    a = ap.parse_args()
    im = Image(a.binary)
    rs, p1, p2 = inventory(im)
    mods = modules(rs)
    if a.what == 'routines':
        print('; range 0x%06X..0x%06X, %d routines' % (im.lo, im.hi, len(rs)))
        print('; address  code   span   a5       kind       name / rule / callers')
        for r in rs:
            what = r.name or ''
            if r.p1_rule:
                what += ' p1 rule %d' % r.p1_rule
            if r.p2_rule:
                what += ' p2 rule %d' % r.p2_rule
            if r.trace and r.trace != (r.p1_rule or r.p2_rule):
                what += ' (trace says %d)' % r.trace
            if r.callers and not r.name:
                what += ' called from %s' % ','.join('0x%06X' % c for c in sorted(r.callers))
            if a.all or not r.name:
                calls = sorted({im.names.get(c, '0x%06X' % c) for c in r.calls})
                if calls and not r.name:
                    what += '  calls ' + ','.join(calls)
            print('0x%06X %6d %6d %-8s %-10s %s' % (r.start, r.code_len, r.span,
                                                    '0x%06X' % r.a5 if r.a5 else '-',
                                                    r.kind(), what.strip()))
        return
    if a.what == 'summary':
        print('range 0x%06X..0x%06X (%d bytes), %d routines' % (im.lo, im.hi, im.hi - im.lo,
                                                                 len(rs)))
        kinds = collections.Counter(r.kind() for r in rs)
        print('by kind: %s' % ', '.join('%s %d' % kv for kv in sorted(kinds.items())))
        print('action tables: pass 1 %d rules, pass 2 %d rules' % (len(p1), len(p2)))
        both = [r for r in rs if r.p1_rule and r.p2_rule]
        print('routines in both tables: %d' % len(both))
        mism = [r for r in rs if r.p1_rule and r.trace and r.trace != r.p1_rule]
        print('pass-1 actions whose trace names another rule: %d' % len(mism))
        notrace = [r.p1_rule for r in rs if r.p1_rule and r.trace is None]
        print('pass-1 actions without the trace: %s' % notrace)
        e1 = [r.p1_rule for r in rs if r.p1_rule and r.code_len <= 2]
        e2 = [r.p2_rule for r in rs if r.p2_rule and r.code_len <= 2]
        print('empty (rts only) pass-1 actions: %d %s' % (len(e1), e1))
        print('empty (rts only) pass-2 actions: %d %s' % (len(e2), e2))
        for k in ('p1-action', 'p2-action', 'named', 'called', 'unreached'):
            sel = [r for r in rs if r.kind() == k]
            if sel:
                print('%-10s %5d routines, code %7d bytes, span %7d bytes' % (
                    k, len(sel), sum(r.code_len for r in sel), sum(r.span for r in sel)))
        print()
        print('modules, in address order (a pass-2 module by the rules of a pass-1 one):')
        print('  A5        first     last      routines  empty  p1 rules        p2 rules        unit')
        for key, ms in mods.items():
            r1 = [r.p1_rule for r in ms if r.p1_rule]
            r2 = [r.p2_rule for r in ms if r.p2_rule]
            a5s = module_a5(ms)
            rng = lambda x: ('%d..%d (%d)' % (min(x), max(x), len(x))) if x else '-'
            print('  %-9s 0x%06X  0x%06X  %8d  %5d  %-15s %-15s %s' % (
                ','.join('0x%06X' % x for x in a5s) or '-', ms[0].start, ms[-1].start, len(ms),
                sum(1 for r in ms if r.code_len <= 2), rng(r1), rng(r2),
                module_name(im, key, ms)))
        p2a5 = [module_a5(ms) for key, ms in mods.items() if key[0] == 'p2']
        print('pass-2 modules: %d, %d with one A5, %d with none (all empty)' % (
            len(p2a5), sum(1 for x in p2a5 if len(x) == 1), sum(1 for x in p2a5 if not x)))
        return
    if a.what == 'clusters':
        for which in ([a.which] if a.which else [1, 2]):
            for level in ([a.level] if a.level is not None else [0, 1, 2]):
                cl = clusters(im, rs, level, which)
                sizes = [len(v) for _, v in cl]
                hist = collections.Counter(sizes)
                print('pass %d, level %d: %d actions, %d clusters; singletons %d; sizes %s' % (
                    which, level, sum(sizes), len(cl), hist.get(1, 0),
                    ', '.join('%dx%d' % (s, hist[s]) for s in sorted(hist, reverse=True))))
                for key, members in cl[:a.show]:
                    rules = [m.p1_rule if which == 1 else m.p2_rule for m in members]
                    print('\n  cluster of %d: rules %s' % (len(members), rules if len(rules) < 30
                                                           else rules[:30] + ['...']))
                    calls = sorted({im.names.get(c, '0x%06X' % c) for c in members[0].calls})
                    print('  calls: %s' % ', '.join(calls))
                    for t in key:
                        print('      ' + t)
                print()
        return
    if a.what == 'fields':
        for name, off, acc in decode_fields(im, rs):
            print('%-48s +%-4s %s' % (name, off if off is not None else '?', acc))
        return
    if a.what == 'il':
        ils = il_names()
        rules, tables, residue = decode_matcher(im, rs)
        byop = collections.defaultdict(lambda: collections.defaultdict(int))
        for x in rules:
            for field, v in x['arm'] or []:
                if field == 98:
                    for path, fld, op, val in x['guard']:
                        if len(path) == 1 and fld == 108:
                            byop[v][path[0]] |= (1 << val) if op == '=' else val
        for d in decode_il_routines(im, rs):
            calls = ' '.join(('%s%s' % ('0x%X' % m if isinstance(m, int) else m,
                                        '-np' if np else '')) for m, np in d['pass_1_calls'])
            want = byop.get(d['w98'], {})
            print('%-44s il %-28s n=%s  pass_1: %s   matcher unions: %s' % (
                d['name'], ils.get(d['w98'], d['w98']), d['nchildren'], calls,
                ' '.join('$%d:0x%X' % (k, want[k]) for k in sorted(want))))
        return
    if a.what in ('matcher', 'tables', 'json'):
        nrules = len(p1)
        result_kind, per_il, tail = tool_tables(im, nrules)
        f1, f2 = rule_flags(im, nrules)
        if a.what == 'tables':
            ops = opcode_names()
            ils = il_names()
            print('isc_tool_generated_readonly_tables 0x%06X, %d bytes' % (TOOL_TABLES,
                                                                            TOOL_TABLES_LEN))
            print('+0x000 result kind by rule (1..%d), words:' % nrules)
            for r in range(1, nrules + 1, 16):
                print('   %4d: %s' % (r, ' '.join('%2d' % x for x in result_kind[r - 1:r + 15])))
            for k, t in enumerate(per_il):
                off = 2 * nrules + 356 * k
                print('+0x%03X (%d) table %d by il$t (178 words): nonzero:' % (off, off, k))
                for i, v in enumerate(t):
                    if v:
                        print('      %-32s %3d %s' % (ils.get(i, i), v, ops.get(v, '')))
            print('tail: %s' % tail)
            return
        rules, tables, residue = decode_matcher(im, rs)
        ils = il_names()
        if a.what == 'matcher':
            seen = collections.Counter(x['rule'] for x in rules)
            print('; %d guarded hard_work calls, %d distinct rules of %d; rules never tried: %s'
                  % (len(rules), len(seen), nrules,
                     [r for r in range(1, nrules + 1) if r not in seen]))
            print('; rules tried more than once: %s' % sorted(r for r, n in seen.items() if n > 1))
            nested = [x['rule'] for x in rules if x.get('nested')]
            print('; tries whose failing tests do not all branch to the next try: %s' % nested)
            print('; instructions not understood (neither a test, a call nor boilerplate): %s'
                  % (dict(residue) or 'none'))
            for x in rules:
                if a.rule and x['rule'] != a.rule:
                    continue
                arm = x['arm'] or []
                arms = []
                for field, v in arm:
                    if field == 108:
                        arms.append(SOLUTION_KINDS[v])
                    elif field == 98:
                        arms.append(ils.get(v, str(v)))
                r = x['rule']
                print('rule %3d  %-14s <- %-40s %s   [p1 0x%06X p2 0x%06X%s%s]' % (
                    r, SOLUTION_KINDS[result_kind[r - 1]], '/'.join(arms),
                    ' & '.join(fmt_guard(g, ils) for g in x['guard']),
                    p1[r - 1], p2[r - 1], ' check-kind' if f1[r - 1] else '',
                    ' one-reg' if f2[r - 1] else ''))
            return
        out = {
            'range': [im.lo, im.hi],
            'routines': [{'start': r.start, 'code_len': r.code_len, 'span': r.span,
                          'a5': r.a5, 'name': r.name, 'unit': r.unit,
                          'p1_rule': r.p1_rule, 'p2_rule': r.p2_rule, 'trace': r.trace,
                          'calls': r.calls, 'callers': sorted(r.callers)} for r in rs],
            'rules': [{'rule': k + 1, 'result_kind': result_kind[k], 'flag_8cf': f1[k],
                       'flag_b07': f2[k], 'p1': p1[k], 'p2': p2[k]} for k in range(nrules)],
            'matcher': [{'rule': x['rule'], 'arm': x['arm'], 'guard': x['guard'],
                         'at': x['at']} for x in rules],
            'per_il_tables': per_il,
        }
        with open(a.out or 'isc_inventory.json', 'w') as f:
            json.dump(out, f, indent=1)
        return


if __name__ == '__main__':
    main()
