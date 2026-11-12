#!/usr/bin/env python3
"""iscg_p2lift.py - the pass-2 actions of cc.a88k lifted to the statement language.

    tools/iscg_p2lift.py [--binary B] [RULE ...]     print the lifted bodies
    tools/iscg_p2lift.py --stats                      how many lift, and why not

A decompiler from a pass-2 action's code (Pascal Rev 8.89, m68k) to the
rule file's statement language (tools/iscg_p2lang.py), used by
tools/iscg_extract.py.  It follows the action's control flow from the
prologue to the epilogue, executing each instruction symbolically:

- registers, the frame's temporaries and the argument pushes hold
  expressions; a store is an assignment, a `jsr' a call whose arguments
  are the pushes its heading (the inserts the modules open) asks for, a
  call's value the function's;
- a conditional branch is an `if' whose arms run to the nearest
  post-dominator where no argument is pending (Rev 8.89's cross-jumped
  argument tails are thereby duplicated into each arm: the source had
  them); a `dbf' loop is a `for';
- a register value used across a statement boundary that the boundary
  may have changed (a call's value, a field stored meanwhile) becomes a
  `temp' of the action; any other is written again where it is used;
- the idioms: `sne; lsr #7; lsl #k; or' into a cleared bit (a boolean
  copied), `bpl; addq #2^k-1; asr #k' (div), debug_lir_ calls with
  result's inherited attributes (`emit'), the nil check of `let result
  <- ...;' (bug_check with the pattern's message and the input's line).

What it cannot follow raises Unliftable with the reason; tools/iscg_
extract.py then writes the transform's pass_2 as `residue' for a hand-
written body.
"""
import argparse
import bisect
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import iscg_p2lang as L  # noqa: E402

P2_A5 = 0x47F788
P2_END = 0x20042C               # hard_work: the first routine after the pass-2 modules
ISC_USER_A5 = 0x480E00          # isc_user_routines' data (isc_var_externs.ins.pas)
AT_SWITCHES = 0x485D30          # at_backend_switches (backend.ins.pas)
TOOL_TABLES = 0x2BC13C          # isc_tool_generated_readonly_tables (isc.pvt.pas)
MAPS = ['opcode_rr_reversed', 'opcode_rr', 'opcode_immediate', 'opcode_double',
        'opcode_immediate_negated', 'opcode_single']
INCLUDES = None


class Unliftable(Exception):
    pass


# --------------------------------------------------------------------------
# instructions

OPND = re.compile(r'''
    %(?P<reg>[ad][0-7]|fp|sp|pc)(?P<rest>@.*)?$ |
    \#(?P<imm>-?\d+|-?0x[0-9a-f]+)$ |
    (?P<abs>-?0x[0-9a-f]+|\d+)$
''', re.X)


def reg_name(r):
    return {'fp': 'a6', 'sp': 'a7'}.get(r, r)


def parse_operand(s):
    s = s.strip()
    m = OPND.match(s)
    if not m:
        raise Unliftable('operand %s' % s)
    if m.group('imm') is not None:
        return ('imm', int(m.group('imm'), 0))
    if m.group('abs') is not None:
        return ('abs', int(m.group('abs'), 0) & 0xFFFFFFFF)
    r = m.group('reg')
    rest = m.group('rest')
    if r == 'pc':
        mm = re.match(r'@\((0x[0-9a-f]+)\)$', rest or '')
        if not mm:
            raise Unliftable('operand %s' % s)
        return ('pcrel', int(mm.group(1), 16))
    r = reg_name(r)
    if rest is None:
        return ('dreg' if r[0] == 'd' else 'areg', r)
    if rest == '@':
        return ('ind', r, 0)
    if rest == '@-':
        return ('predec', r)
    if rest == '@+':
        return ('postinc', r)
    mm = re.match(r'@\((-?\d+)\)$', rest)
    if mm:
        return ('ind', r, int(mm.group(1)))
    mm = re.match(r'@\((-?0x[0-9a-f]+),%([ad][0-7]):([wl])(?::(\d))?\)$', rest)
    if mm:
        return ('idx', r, int(mm.group(1), 16), mm.group(2), mm.group(3), int(mm.group(4) or 1))
    raise Unliftable('operand %s' % s)


SIZED = ['movea', 'move', 'moveq', 'movem', 'clr', 'pea', 'lea', 'subq', 'addq', 'cmpa', 'cmpi',
         'cmp', 'tst', 'btst', 'bset', 'bclr', 'ori', 'or', 'andi', 'and', 'addi', 'add', 'suba',
         'sub', 'neg', 'lsr', 'lsl', 'asr', 'asl', 'link', 'ext', 'not', 'eor', 'muls', 'mulu',
         'divs', 'chk']
BRANCH = re.compile(r'^(b(?:ra|eq|ne|pl|mi|ge|gt|le|lt|hi|ls|cc|cs|sr))[sw]?$')


class Insn:
    __slots__ = ('addr', 'size', 'mn', 'sz', 'ops', 'text', 'target')

    def __init__(self, addr, size, text):
        self.addr, self.size, self.text = addr, size, text
        parts = text.split(None, 1)
        m = parts[0]
        self.target = None
        self.sz = None
        bm = BRANCH.match(m)
        if bm:
            self.mn = bm.group(1)
        elif m in ('rts', 'unlk', 'jsr', 'dbf', 'sne', 'seq', 'smi', 'spl', 'sgt', 'sge', 'slt',
                   'sle', 'shi', 'sls', 'scc', 'scs', 'moveq', '.short', 'nop'):
            self.mn = m
        else:
            for base in SIZED:
                if m.startswith(base) and len(m) == len(base) + 1 and m[-1] in 'bwl':
                    self.mn, self.sz = base, m[-1]
                    break
            else:
                self.mn = m
        ops = []
        if len(parts) > 1 and self.mn not in ('.short',):
            ops = split_ops(parts[1])
        self.ops = ops
        if self.mn.startswith('b') and BRANCH.match(m) or self.mn in ('dbf',):
            self.target = int(ops[-1], 16)


def split_ops(s):
    out, depth, cur = [], 0, ''
    for ch in s:
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(cur)
            cur = ''
        else:
            cur += ch
    if cur:
        out.append(cur)
    return out


SZ = {'b': 1, 'w': 2, 'l': 4}


# --------------------------------------------------------------------------
# values: the language's expressions, and cells (a register's value that
# may become a temp)

class Cell:
    _n = 0

    def __init__(self, expr, typ, volatile, at):
        self.expr = expr        # the value, a language expression (may hold cells)
        self.typ = typ          # 'sol', 'inh', 'lr', 'ptr', 'int16', 'int32', 'bool', ...
        self.volatile = volatile  # a call's value
        self.at = at            # the boundary count when made
        self.uses = 0
        self.temp = None
        self.need = False
        self.dirty = False
        self.mark = None

    def __repr__(self):
        return 'Cell(%r)' % (self.expr,)


def C(e):
    return e


class Lifter:
    def __init__(self, im, rule, start, end, headings, names):
        self.im = im
        self.rule = rule
        self.start, self.end = start, end
        self.h = headings
        self.names = names
        self.tempn = 0
        self.heads = set()
        self.cells = []
        self.bound = 0
        data = im.read(start, end - start)
        import cc_isc_inventory as inv
        self.ins = []
        for a, n, t, hx in inv.objdump(data, start):
            t = inv.hexindex(t)
            self.ins.append(Insn(a, n, t))
        self.at = {x.addr: k for k, x in enumerate(self.ins)}
        self.parse_frame()

    # ---- the frame
    def parse_frame(self):
        ins = self.ins
        if not ins or ins[0].mn != 'link':
            raise Unliftable('no link')
        self.linksize = -parse_operand(ins[0].ops[1])[1]
        k = 1
        self.saved = []
        while k < len(ins):
            x = ins[k]
            if x.mn == 'pea' and re.match(r'%a[2-5]@$', x.ops[0]):
                self.saved.append(x.ops[0][1:3])
            elif x.mn == 'move' and x.sz == 'l' and re.match(r'%d[2-7]$', x.ops[0]) and \
                    x.ops[1] == '%sp@-':
                self.saved.append(x.ops[0][1:])
            elif x.mn == 'movem':
                pass
            else:
                break
            k += 1
        if ins[k].mn != 'lea' or reg_name(ins[k].ops[1].strip('%')) != 'a5':
            raise Unliftable('no A5 load')
        self.a5 = parse_operand(ins[k].ops[0])[1]
        self.body = ins[k + 1].addr
        # the epilogue: restores, unlk, rts
        u = [i for i, x in enumerate(ins) if x.mn == 'unlk']
        if len(u) != 1 or ins[u[0] + 1].mn != 'rts':
            raise Unliftable('%d epilogues' % len(u))
        j = u[0]
        while j > 0 and (ins[j - 1].mn in ('movea', 'move', 'movem') and '%fp@(-' in ins[j - 1].text
                         and not ins[j - 1].text.endswith('%sp@-')
                         and re.search(r'%fp@\(-\d+\),%[ad]', ins[j - 1].text)):
            j -= 1
        self.epilogue = ins[j].addr
        self.code_end = ins[u[0] + 1].addr + 2

    # ---- control flow
    def succ(self, k):
        x = self.ins[k]
        if x.addr >= self.epilogue:
            return []
        nxt = self.ins[k + 1].addr if k + 1 < len(self.ins) else None
        if x.mn == 'bra':
            return [x.target]
        if x.target is not None and x.mn != 'bsr':
            return [x.target, nxt]
        if x.mn in ('rts',):
            return []
        return [nxt]

    def postdom(self):
        """ipdom[addr] over the instruction graph (the epilogue is the exit)."""
        addrs = [x.addr for x in self.ins if self.body <= x.addr <= self.epilogue]
        succ = {a: [s for s in self.succ(self.at[a]) if s is not None] for a in addrs}
        for a in addrs:
            for s in succ[a]:
                if s not in self.at or s < self.body:
                    raise Unliftable('a branch to 0x%X' % s)
        # reverse postorder on the reversed graph from the exit
        pred = collections.defaultdict(list)
        for a, ss in succ.items():
            for s in ss:
                pred[s].append(a)
        order, seen = [], set()
        stack = [(self.epilogue, iter(pred[self.epilogue]))]
        seen.add(self.epilogue)
        while stack:
            n, it = stack[-1]
            for p in it:
                if p not in seen:
                    seen.add(p)
                    stack.append((p, iter(pred[p])))
                    break
            else:
                order.append(n)
                stack.pop()
        rpo = list(reversed(order))
        index = {n: i for i, n in enumerate(rpo)}
        ipdom = {self.epilogue: self.epilogue}

        def intersect(a, b):
            while a != b:
                while index[a] > index[b]:
                    a = ipdom[a]
                while index[b] > index[a]:
                    b = ipdom[b]
            return a
        changed = True
        while changed:
            changed = False
            for n in rpo[1:]:
                cands = [s for s in succ[n] if s in ipdom and s in index]
                if not cands:
                    continue
                new = cands[0]
                for s in cands[1:]:
                    new = intersect(new, s)
                if ipdom.get(n) != new:
                    ipdom[n] = new
                    changed = True
        missing = [a for a in addrs if a not in ipdom]
        if missing:
            raise Unliftable('no way to the exit from 0x%X' % missing[0])
        self.ipdom = ipdom

    def shapes(self):
        """The argument stack's shape at each instruction: the number of
        pushes not yet taken by a call (Rev 8.89 leaves pads and taken
        arguments to a later pop)."""
        shape = {self.body: ()}
        work = [self.body]
        while work:
            a = work.pop()
            k = self.at[a]
            x = self.ins[k]
            st = self.shape_step(x, shape[a])
            for s in self.succ(k):
                if s is None:
                    continue
                t = tuple(st)
                if s in shape:
                    if pending(shape[s]) != pending(t):
                        raise Unliftable('stack shapes differ at 0x%X' % s)
                else:
                    shape[s] = t
                    work.append(s)
        self.shape = shape

    def shape_step(self, x, st):
        # items: ['a', size, None] a pending argument, ['d', size] taken,
        # ['p', 2] a pad
        st = [list(i) for i in st]
        if x.mn == 'pea' or (x.ops and x.ops[-1].strip() == '%sp@-' and x.mn in ('move', 'clr')):
            st.append(['a', 4 if x.mn == 'pea' else max(2, SZ[x.sz]), None])
        elif x.mn in ('subq', 'sub') and x.ops[-1] == '%sp':
            n = parse_operand(x.ops[0])[1]
            st.extend([['p', 2, None] for _ in range(n // 2)])
        elif x.mn in ('addq', 'lea', 'add') and x.ops[-1] == '%sp':
            n = parse_operand(x.ops[0])[1] if x.mn != 'lea' else int(
                re.match(r'%sp@\((\d+)\)', x.ops[0]).group(1))
            pop_items(st, n, x)
        elif x.mn == 'jsr':
            self.take_args(self.callee(x), st, x)
        return [tuple(i) for i in st]

    def take_args(self, name, st, x):
        """The arguments of a call of name: the pending pushes from the
        top, matched to its parameters by size (a longword push may hold
        two word arguments: Rev 8.89 merges two constant words); they are
        marked taken.  -> [value per parameter] (None in the shape pass)."""
        h = self.heading(name)
        top = [i for i in range(len(st)) if st[i][0] == 'a']
        if h['variable']:
            k = len(st)
            while k > 0 and st[k - 1][0] == 'a':
                k -= 1
            sizes = [4] * (len(st) - k)
            if len(sizes) < 1:
                raise Unliftable('0x%X: %s with no arguments' % (x.addr, name))
        else:
            sizes = [param_size(h, p) for p in h['params']]
        vals = []
        i = len(st) - 1
        NONE = ('none',)
        half = NONE
        for sz in sizes:
            if half is not NONE:
                if sz != 2:
                    raise Unliftable('0x%X: %s: a longword push for a longword and a word'
                                     % (x.addr, name))
                vals.append(half)
                half = NONE
                continue
            if i < 0 or st[i][0] != 'a':
                raise Unliftable('0x%X: %s: %d parameters, fewer pushes' % (x.addr, name, len(sizes)))
            it = st[i]
            if it[1] == sz:
                vals.append(it[2])
            elif it[1] == 4 and sz == 2:
                v = it[2]
                if v is None:
                    hi = lo = None
                elif isinstance(v, tuple) and v[0] == 'num':
                    hi, lo = ('num', sext16(v[1] >> 16)), ('num', sext16(v[1] & 0xFFFF))
                else:
                    raise Unliftable('0x%X: %s: two word arguments in one push' % (x.addr, name))
                vals.append(hi)
                half = lo
            else:
                raise Unliftable('0x%X: %s: a %d-byte push for a %d-byte parameter'
                                 % (x.addr, name, it[1], sz))
            st[i] = ['d', it[1], None]
            i -= 1
        if half is not NONE:
            raise Unliftable('0x%X: %s: a push split past the parameters' % (x.addr, name))
        return vals

    def clean(self, a):
        return not any(i[0] == 'a' for i in self.shape.get(a, ()))

    def merge_point(self, a):
        m = self.ipdom[a]
        while m != self.epilogue and not self.clean(m):
            m = self.ipdom[m]
        return m

    def callee(self, x):
        t = parse_operand(x.ops[0])
        if t[0] != 'abs':
            raise Unliftable('0x%X: %s' % (x.addr, x.text))
        name = self.names.get(t[1])
        if not name:
            raise Unliftable('0x%X: a call of 0x%X' % (x.addr, t[1]))
        return name.lower()

    def heading(self, name):
        h = self.h.get(name)
        if h is None:
            raise Unliftable('no heading for %s' % name)
        return h

    # ---- running
    def lift(self):
        self.postdom()
        self.shapes()
        st = State()
        st.regs['a6'] = ('frame',)
        stmts = self.run(self.body, st, {self.epilogue})[0]
        return self.finish(stmts)

    def new_cell(self, expr, typ, volatile, out):
        c = Cell(expr, typ, volatile, self.bound)
        self.cells.append(c)
        c.mark = ['mark', c]
        out.append(c.mark)
        return c

    def run(self, a, st, stops):
        """Statements from a to the first of stops; (stmts, state, stop)."""
        out = []
        loops = {}
        while True:
            if a in stops:
                return out, st, a
            if a not in self.at:
                raise Unliftable('no instruction at 0x%X' % a)
            k = self.at[a]
            x = self.ins[k]
            # a loop's head: the target of a later dbf
            back = [y for y in self.ins[k:] if y.mn == 'dbf' and y.target == a]
            if back and a not in loops and a not in self.heads:
                loops[a] = True
                a = self.loop(a, back[0], st, out)
                continue
            if x.target is not None and x.mn not in ('bra', 'dbf', 'bsr'):
                a = self.branch(k, st, out, stops)
                continue
            if x.mn == 'bra':
                if x.target <= a:
                    raise Unliftable('0x%X: a backward branch' % a)
                a = x.target
                continue
            nxt = self.step(k, st, out)
            a = nxt if nxt is not None else self.ins[k + 1].addr

    def loop(self, head, dbf, st, out):
        """for t := 1 to n do body, n - 1 in dbf's register at the head."""
        reg = dbf.ops[0].strip('%')
        cnt = st.regs.get(reg)
        if cnt is None:
            raise Unliftable('0x%X: a loop count not known' % head)
        hi = self.simplify(('bin', '+', self.val(cnt), ('num', 1)))
        body_st = st.copy()
        body_st.regs.pop(reg, None)
        self.bound += 1
        self.heads.add(head)
        body, end_st, _ = self.run(head, body_st, {dbf.addr})
        self.heads.discard(head)
        self.bound += 1
        self.tempn += 1
        var = 'i%d' % self.tempn
        out.append(('for', var, ('num', 1), hi, body))
        # the 32-bit count's tail: clr.w Dn; subq.l #1,Dn; bcc head
        k = self.at[dbf.addr] + 1
        tail = self.ins[k:k + 3]
        if len(tail) == 3 and tail[0].mn == 'clr' and tail[2].target == head:
            k += 3
        for r in list(st.regs):
            if end_st.regs.get(r) is not st.regs.get(r):
                st.regs.pop(r, None)
        st.regs.pop(reg, None)
        st.flags = None
        return self.ins[k].addr

    def branch(self, k, st, out, stops):
        x = self.ins[k]
        cond = self.condition(x, st)
        nxt = self.ins[k + 1].addr
        # the signed division idiom: bpl +2; addq #2^k-1,Dn; asr #k,Dn
        if x.mn == 'bpl' and k + 2 < len(self.ins):
            y, z = self.ins[k + 1], self.ins[k + 2]
            if (y.mn == 'addq' and z.mn == 'asr' and x.target == z.addr and y.ops[1] == z.ops[1]
                    and parse_operand(y.ops[0])[1] == (1 << parse_operand(z.ops[0])[1]) - 1):
                r = z.ops[1].strip('%')
                v = st.regs.get(r)
                q = ('bin', 'div', self.val(v), ('num', 1 << parse_operand(z.ops[0])[1]))
                st.regs[r] = self.mkcell(q, 'int32', False, out)
                st.flags = ('tst', ('cell', st.regs[r]), 4)
                return self.ins[k + 3].addr
        m = self.merge_point(x.addr)
        for s in stops:
            pass
        stop2 = set(stops) | {m}
        self.bound += 1
        b_then, s_then, e1 = self.run(nxt, st.copy(), stop2)
        self.bound += 1
        b_else, s_else, e2 = self.run(x.target, st.copy(), stop2)
        self.bound += 1
        if e1 != e2:
            raise Unliftable('0x%X: the arms end at 0x%X and 0x%X' % (x.addr, e1, e2))
        # registers whose values differ after the arms
        newst = s_then.copy()
        for r in set(s_then.regs) | set(s_else.regs):
            v1, v2 = s_then.regs.get(r), s_else.regs.get(r)
            if v1 is v2:
                continue
            if v1 is not None and v2 is not None and self.same(v1, v2):
                continue
            if self.live(e1, r):
                c = Cell(None, (v1 or v2).typ if isinstance(v1 or v2, Cell) else 'int32', False,
                         self.bound)
                c.need = True
                self.cells.append(c)
                c.phi = True
                c.mark = ['mark', c]
                out.append(c.mark)
                for body, v in ((b_then, v1), (b_else, v2)):
                    if v is None:
                        raise Unliftable('0x%X: %s set on one arm only' % (x.addr, r))
                    body.append(['phi', c, v])
                newst.regs[r] = c
            else:
                newst.regs.pop(r, None)
        if pending(s_then.stack) != pending(s_else.stack):
            raise Unliftable('0x%X: the arms leave different stacks' % x.addr)
        newst.flags = None
        # `not cond' falls through to the then arm
        out.append(('if', [(self.negate(cond), b_then)], b_else))
        st.regs, st.stack, st.frame, st.flags = newst.regs, newst.stack, newst.frame, None
        st.frame = dict(s_then.frame)
        return e1

    def live(self, a, r):
        """Whether register r is read at or after a before it is set (a
        call ends d0/d1/a0/a1)."""
        seen = set()
        work = [a]
        pat = re.compile(r'%' + ('fp' if r == 'a6' else r) + r'\b')
        while work:
            a = work.pop()
            while a in self.at and a not in seen and a < self.epilogue:
                seen.add(a)
                x = self.ins[self.at[a]]
                if x.mn == 'jsr' and r in ('d0', 'd1', 'a0', 'a1'):
                    break
                reads = pat.findall(x.text)
                if reads:
                    last = x.ops[-1].strip() if x.ops else ''
                    if (last == '%' + r and len(reads) == 1
                            and x.mn in ('move', 'movea', 'moveq', 'lea', 'clr')):
                        break
                    return True
                if x.mn == 'bra':
                    a = x.target
                    continue
                if x.target is not None:
                    work.append(x.target)
                a = self.ins[self.at[a] + 1].addr
        return False

    def same(self, v1, v2):
        return self.val(v1) == self.val(v2)

    # ---- conditions
    def condition(self, x, st):
        f = st.flags
        if f is None:
            raise Unliftable('0x%X: a branch on unknown flags' % x.addr)
        cc = x.mn[1:]
        if f[0] == 'cmp':
            # flags of dst - src
            _, src, dst, size = f
            ops = {'eq': '=', 'ne': '<>', 'gt': '>', 'ge': '>=', 'lt': '<', 'le': '<=',
                   'hi': 'u>', 'cc': 'u>=', 'cs': 'u<', 'ls': 'u<='}
            if cc not in ops:
                raise Unliftable('0x%X: %s after a compare' % (x.addr, x.mn))
            a, b = self.val(dst), self.val(src)
            if b == ('num', 0) and self.is_ptr(dst):
                b = ('nil',)
            return self.cmp(ops[cc], a, b)
        if f[0] == 'tst':
            _, v, size = f
            e = self.val(v)
            if cc in ('eq', 'ne'):
                if self.is_bool(v):
                    return e if cc == 'ne' else ('un', 'not', e)
                z = ('nil',) if self.is_ptr(v) else ('num', 0)
                return self.cmp('=' if cc == 'eq' else '<>', e, z)
            if cc in ('pl', 'mi'):
                if size == 1 and isinstance(v, tuple) and v[0] == 'mem':
                    b = self.bitpath(v[1], v[2], 7)
                    if b is not None:
                        return b if cc == 'mi' else ('un', 'not', b)
                return self.cmp('>=' if cc == 'pl' else '<', e, ('num', 0))
            ops = {'gt': '>', 'ge': '>=', 'lt': '<', 'le': '<='}
            if cc in ops:
                return self.cmp(ops[cc], e, ('num', 0))
            raise Unliftable('0x%X: %s after a test' % (x.addr, x.mn))
        if f[0] == 'tstbyte':
            if cc in ('pl', 'mi'):
                b = self.bitpath(f[1], f[2], 7)
                if b is None:
                    raise Unliftable('0x%X: bit 7 of +%d' % (x.addr, f[2]))
                return b if cc == 'mi' else ('un', 'not', b)
            e = self.load_expr(('mem', f[1], f[2], 1))
            if cc in ('eq', 'ne'):
                return self.cmp('=' if cc == 'eq' else '<>', e, ('num', 0))
            raise Unliftable('0x%X: %s after tst.b' % (x.addr, x.mn))
        if f[0] == 'bit':
            if cc == 'ne':
                return f[1]
            if cc == 'eq':
                return ('un', 'not', f[1])
            raise Unliftable('0x%X: %s after btst' % (x.addr, x.mn))
        raise Unliftable('0x%X: flags %r' % (x.addr, f[0]))

    def cmp(self, op, a, b):
        if a[0] == 'num' and b[0] != 'num':
            flip = {'=': '=', '<>': '<>', '<': '>', '>': '<', '<=': '>=', '>=': '<=',
                    'u<': 'u>', 'u>': 'u<', 'u<=': 'u>=', 'u>=': 'u<='}
            return ('bin', flip[op], b, a)
        return ('bin', op, a, b)

    def negate(self, c):
        if c[0] == 'un' and c[1] == 'not':
            return c[2]
        if c[0] == 'bin':
            inv = {'=': '<>', '<>': '=', '<': '>=', '>=': '<', '>': '<=', '<=': '>',
                   'u<': 'u>=', 'u>=': 'u<', 'u>': 'u<=', 'u<=': 'u>'}
            if c[1] in inv:
                return ('bin', inv[c[1]], c[2], c[3])
        return ('un', 'not', c)

    # ---- values
    def mkcell(self, expr, typ, volatile, out):
        return self.new_cell(expr, typ, volatile, out)

    def val(self, v):
        """The expression of a value (register content, push, ...)."""
        if isinstance(v, Cell):
            return ('cell', v)
        if v is None:
            raise Unliftable('a value not known')
        if isinstance(v, tuple) and v[0] in ('mem',):
            return self.load_expr(v)
        if isinstance(v, tuple) and v[0] in ('frame', 'gaddr', 'ptr', 'pcrel'):
            raise Unliftable('an address used as a value: %r' % (v,))
        return v

    def typ_of(self, v):
        if isinstance(v, Cell):
            return v.typ
        if isinstance(v, tuple):
            if v[0] == 'param':
                return 'sol'
            if v[0] == 'mem':
                return self.mem_type(v)
            if v[0] == 'num':
                return 'int32'
            if v[0] == 'cell':
                return v[1].typ
        return None

    def is_ptr(self, v):
        return self.typ_of(v) in ('sol', 'inh', 'lr', 'ptr', 'label', 'node')

    def is_bool(self, v):
        return self.typ_of(v) == 'bool'

    def base_path(self, b):
        """The language path (and its type) a pointer value b stands for:
        ('param', name) a parameter, a cell, ..."""
        if isinstance(b, Cell):
            return ('cell', b), b.typ
        if isinstance(b, tuple) and b[0] == 'param':
            return ('path', b[1], []), 'sol'
        if isinstance(b, tuple) and b[0] == 'mem':
            return self.load_expr(b), self.mem_type(b)
        if isinstance(b, tuple) and b[0] == 'index' and b[1] == 'isc_literal_solutions':
            return b, 'sol'
        raise Unliftable('a pointer not known: %r' % (b[0] if isinstance(b, tuple) else b,))

    def field(self, base, off, size, bit=None):
        """(selector name, type) of base's field at off."""
        bexpr, btyp = self.base_path(base)
        if btyp == 'sol':
            n = L.sol_name(off, size, bit)
            if n is None:
                raise Unliftable('solution field +%d (%d bytes%s)' % (
                    off, size, ', bit %d' % bit if bit is not None else ''))
            return bexpr, n, self.sel_type(n, size)
        if btyp == 'inh':
            key = (off, size if bit is None else bit + 100)
            n = L.INH_BY_OFF.get(key)
            if n is None:
                raise Unliftable('inherited attribute +%d' % off)
            return bexpr, n, {'up': 'ptr', 'i32': 'int32', 'i16': 'int16', 'char': 'int8',
                              'u8': 'int8', 'bool': 'bool'}[L.INH_ATTRS[n][3]]
        raise Unliftable('a field +%d of a %s' % (off, btyp))

    def sel_type(self, n, size):
        if n.startswith('$') or n in ('before_transform', 'base_register', 'index_register'):
            return 'sol'
        if n.startswith('l') and n[1:].isdigit() and int(n[1:]) >= 352:
            return 'sol'
        if n == 'inherited_attributes':
            return 'inh'
        if n in ('il', 'object_with_name'):
            return 'node'
        if n in ('live_range', 'live_range_of_imaginary_part'):
            return 'lr'
        if n == 'false_label':
            return 'label'
        a = L.attrs().get(n)
        if a and a[2] is not None:
            return 'bool'
        return {1: 'int8', 2: 'int16', 4: 'int32'}[size]

    def mem_type(self, m):
        _, base, off, size = m[:4]
        if isinstance(base, tuple) and base[0] == 'glob':
            return self.global_type(base[1])
        try:
            _, n, t = self.field(base, off, size)
        except Unliftable:
            return None
        return t

    def load_expr(self, m):
        _, base, off, size = m[:4]
        if isinstance(base, tuple) and base[0] == 'gaddr':
            return self.global_expr(base[1] + off, size)
        bexpr, n, t = self.field(base, off, size)
        return self.sel(bexpr, n)

    def sel(self, bexpr, n):
        return ('sel', bexpr, n)

    def table_expr(self, loc, size, x):
        """A word of a table indexed by a register: the opcode maps of
        isc_tool_generated_readonly_tables by an il$t (index doubled)."""
        _, b, i, disp = loc
        if not (isinstance(b, tuple) and b[0] == 'num' and b[1] == TOOL_TABLES and size == 2):
            raise Unliftable('0x%X: a table at %r' % (x.addr, b))
        off = disp - 1126
        if off < 0 or off % 356 or off // 356 >= len(MAPS):
            raise Unliftable('0x%X: the tool tables +%d' % (x.addr, disp))
        iv = self.val(i)
        if iv[0] == 'cell':
            iv = iv[1].expr
        if not (iv[0] == 'bin' and iv[1] == '+' and iv[2] == iv[3]):
            raise Unliftable('0x%X: a table index not doubled' % x.addr)
        return ('index', MAPS[off // 356], iv[2])

    def global_expr(self, addr, size):
        off = addr - ISC_USER_A5
        if 0x258 - 4 <= off < 0x258 + 4 * 33 and off % 4 == 0 and size == 4:
            return ('index', 'isc_literal_solutions', ('num', (off - 0x258) // 4))
        name = 'isc_user_routines_%x' % off
        if name in L.GLOBALS:
            return ('path', name, [])
        raise Unliftable('global 0x%X' % addr)

    def global_type(self, addr):
        off = addr - ISC_USER_A5
        if 0x258 - 4 <= off < 0x258 + 4 * 33:
            return 'sol'
        c = L.GLOBALS.get('isc_user_routines_%x' % off)
        return {'sp': 'sol', 'isp': 'sol', 'up': 'ptr', 'i32': 'int32', 'bool': 'bool'}.get(c)

    def simplify(self, e):
        if e[0] == 'bin' and e[1] in ('+', '-') and e[3][0] == 'num' and e[2][0] == 'num':
            return ('num', e[2][1] + e[3][1] if e[1] == '+' else e[2][1] - e[3][1])
        if e[0] == 'bin' and e[1] == '+' and e[3] == ('num', 0):
            return e[2]
        if e[0] == 'bin' and e[1] == '+' and e[2][0] == 'bin' and e[2][1] == '-' and \
                e[2][3][0] == 'num' and e[3][0] == 'num' and e[2][3][1] == e[3][1]:
            return e[2][2]
        return e

    # ---- operands
    def ea_addr(self, op, st):
        """The location an operand names: ('reg', r), ('mem', base, off,
        size), ('push',), ('imm', v) ..."""
        k = op[0]
        if k in ('dreg', 'areg'):
            return ('reg', op[1])
        if k == 'imm':
            return ('imm', op[1])
        if k == 'abs':
            return ('abs', op[1])
        if k == 'pcrel':
            return ('pcrel', op[1])
        if k == 'ind':
            r = op[1]
            if r == 'a6':
                return ('fp', op[2])
            if r == 'a5':
                return ('a5', op[2])
            if r == 'a7':
                return ('sp', op[2])
            b = st.regs.get(r)
            if b is None:
                raise Unliftable('register %s not known' % r)
            if isinstance(b, tuple) and b[0] == 'gaddr':
                return ('absmem', b[1] + op[2])
            if isinstance(b, tuple) and b[0] == 'num' and b[1] == TOOL_TABLES:
                return ('absmem', b[1] + op[2])
            if isinstance(b, tuple) and b[0] == 'ptroff':
                return ('mem', b[1], b[2] + op[2])
            if isinstance(b, tuple) and b[0] == 'idxaddr':
                return ('tabmem', b[1], b[2], b[3] + op[2])
            return ('mem', b, op[2])
        if k == 'predec' and op[1] == 'a7':
            return ('push',)
        raise Unliftable('operand %r' % (op,))

    def read(self, op, size, st, out, x):
        loc = self.ea_addr(op, st)
        k = loc[0]
        if k == 'reg':
            v = st.regs.get(loc[1])
            if v is None:
                raise Unliftable('0x%X: %s not known' % (x.addr, loc[1]))
            return v
        if k == 'imm':
            return ('num', loc[1])
        if k == 'fp':
            off = loc[1]
            params = {8: 'self', 12: 'subject', 16: 'result', 20: 'solution'}
            if off in params:
                return ('param', params[off])
            if off < 0 and off in st.frame:
                return st.frame[off]
            raise Unliftable('0x%X: frame +%d' % (x.addr, off))
        if k == 'mem':
            m = ('mem', loc[1], loc[2], size)
            return self.mkcell(self.load_expr(m), self.mem_type(m), False, out)
        if k == 'tabmem':
            return self.mkcell(self.table_expr(loc, size, x), 'int16', False, out)
        if k == 'sp':
            # a push of what is pushed already (Rev 8.89 copies an argument
            # it pushed for the call before)
            off = loc[1]
            for it in reversed(st.stack):
                if off == 0:
                    if it[1] != max(size, 2) or it[2] is None:
                        raise Unliftable('0x%X: %s' % (x.addr, x.text))
                    return it[2]
                off -= it[1]
                if off < 0:
                    break
            raise Unliftable('0x%X: %s' % (x.addr, x.text))
        if k in ('abs', 'absmem'):
            addr = loc[1]
            if addr in (AT_SWITCHES, AT_SWITCHES + 1):
                raise Unliftable('0x%X: at_backend_switches read whole' % x.addr)
            e = self.global_expr(addr, size)
            return self.mkcell(e, self.global_type(addr), False, out)
        raise Unliftable('0x%X: read %r' % (x.addr, loc))

    def store(self, op, size, v, st, out, x):
        loc = self.ea_addr(op, st)
        k = loc[0]
        if k == 'reg':
            r = loc[1]
            if size < 4 and r[0] == 'd':
                old = st.regs.get(r)
                if not (isinstance(old, tuple) and old == ('num', 0)) and size == 1 and \
                        not (isinstance(v, tuple) and v[0] in ('boolbyte',)):
                    pass
            st.regs[r] = v
            return
        if k == 'push':
            st.stack.append(['a', max(size, 2), v])
            return
        if k == 'fp':
            if loc[1] >= 0:
                raise Unliftable('0x%X: a parameter set' % x.addr)
            st.frame[loc[1]] = v
            return
        if k == 'mem':
            bexpr, n, t = self.field(loc[1], loc[2], size)
            path = self.sel(bexpr, n)
            ve = self.val(v)
            if ve == ('num', 0) and t in ('sol', 'ptr', 'lr', 'node', 'inh', 'label'):
                ve = ('nil',) if t != 'label' else ve
            self.emit_set(path, ve, out)
            return
        if k in ('abs', 'absmem'):
            raise Unliftable('0x%X: a global set' % x.addr)
        raise Unliftable('0x%X: store %r' % (x.addr, loc))

    def emit_set(self, path, ve, out):
        self.use(ve)
        out.append(('set', path, ve))
        self.boundary(path)

    def boundary(self, path=None):
        """A statement was emitted: later uses of a call's value need a
        temp; a stored field's earlier loads are dirty."""
        self.bound += 1
        if path is not None:
            for c in self.cells:
                if not c.temp and c.expr is not None and contains(c.expr, path):
                    c.dirty = True

    def use(self, e):
        for c in cells_in(e):
            c.uses += 1
            if c.volatile and c.at != self.bound:
                c.need = True
            if c.dirty:
                c.need = True

    def push_value(self, op, st, out, x):
        """pea's value: the address an operand names."""
        k = op[0]
        if k == 'abs':
            return ('num', op[1] if op[1] < 0x80000000 else op[1] - (1 << 32))
        if k == 'pcrel':
            return ('str', self.string_at(op[1]))
        if k == 'ind':
            r = op[1]
            if r == 'a6':
                if op[2] < 0:
                    return ('frameaddr', op[2])
                raise Unliftable('0x%X: the address of a parameter' % x.addr)
            b = st.regs.get(r)
            if b is None:
                raise Unliftable('0x%X: %s not known' % (x.addr, r))
            if isinstance(b, tuple) and b[0] == 'ptroff':
                b, op = b[1], ('ind', r, b[2] + op[2])
            if op[2] == 0:
                if isinstance(b, tuple) and b[0] == 'param' and b[1] in ('self', 'result'):
                    return ('addrof', b[1])
                return b
            m = ('mem', b, op[2], 4)
            bexpr, n, t = self.field(b, op[2], 4)
            return ('addr', self.sel(bexpr, n))
        raise Unliftable('0x%X: pea %r' % (x.addr, op))

    def string_at(self, a):
        d = self.im.read(a, 512)
        n = d.find(b'%$')
        if n < 0:
            raise Unliftable('a string at 0x%X' % a)
        return d[:n + 2].decode('latin-1')

    # ---- one instruction
    def step(self, k, st, out):
        x = self.ins[k]
        mn, sz = x.mn, x.sz
        ops = [parse_operand(o) for o in x.ops] if mn not in ('movem', 'jsr') else None
        if mn == 'nop':
            return None
        if mn in ('move', 'movea'):
            size = SZ[sz]
            v = self.read(ops[0], size, st, out, x)
            if mn == 'move' and ops[1][0] != 'areg':
                st.flags = ('tst', v, size)
            self.store(ops[1], size, v, st, out, x)
            return None
        if mn == 'moveq':
            st.regs[ops[1][1]] = ('num', ops[0][1])
            st.flags = ('tst', ('num', ops[0][1]), 4)
            return None
        if mn == 'clr':
            size = SZ[sz]
            st.flags = ('tst', ('num', 0), size)
            self.store(ops[0], size, ('num', 0), st, out, x)
            return None
        if mn == 'pea':
            v = self.push_value(ops[0], st, out, x)
            st.stack.append(['a', 4, v])
            return None
        if mn == 'lea':
            dst = ops[1]
            if dst == ('areg', 'a7'):
                if ops[0][0] != 'ind' or ops[0][1] != 'a7':
                    raise Unliftable('0x%X: %s' % (x.addr, x.text))
                self.pop(ops[0][2], x, st)
                return None
            src = ops[0]
            if src[0] == 'abs':
                st.regs[dst[1]] = ('gaddr', src[1])
                return None
            if src[0] == 'ind' and src[1] not in ('a5', 'a6', 'a7'):
                b = st.regs.get(src[1])
                if b is None:
                    raise Unliftable('0x%X: %s not known' % (x.addr, src[1]))
                if isinstance(b, tuple) and b[0] == 'ptroff':
                    st.regs[dst[1]] = ('ptroff', b[1], b[2] + src[2])
                else:
                    st.regs[dst[1]] = ('ptroff', b, src[2])
                return None
            if src[0] == 'idx' and src[4] == 'w' and src[5] == 1:
                b = st.regs.get(src[1])
                i = st.regs.get(src[3])
                if b is None or i is None:
                    raise Unliftable('0x%X: %s' % (x.addr, x.text))
                st.regs[dst[1]] = ('idxaddr', b, i, src[2])
                return None
            raise Unliftable('0x%X: %s' % (x.addr, x.text))
        if mn in ('subq', 'sub', 'addq', 'add') and ops[-1] == ('areg', 'a7'):
            n = ops[0][1]
            if mn.startswith('sub'):
                st.stack.extend([['p', 2, None]] * (n // 2))
            else:
                self.pop(n, x, st)
            return None
        if mn == 'lea':
            return None
        if mn in ('cmp', 'cmpi', 'cmpa'):
            size = SZ[sz]
            a = self.read(ops[0], size, st, out, x)
            b = self.read(ops[1], size, st, out, x)
            if mn == 'cmpa' and isinstance(a, tuple) and a == ('num', 0):
                pass
            st.flags = ('cmp', a, b, size)
            return None
        if mn == 'tst':
            size = SZ[sz]
            loc = self.ea_addr(ops[0], st)
            if size == 1 and loc[0] == 'mem':
                st.flags = ('tstbyte', loc[1], loc[2])
                return None
            v = self.read(ops[0], size, st, out, x)
            st.flags = ('tst', v, size)
            return None
        if mn == 'btst':
            bit = ops[0]
            if bit[0] != 'imm':
                raise Unliftable('0x%X: btst by register' % x.addr)
            loc = self.ea_addr(ops[1], st)
            st.flags = ('bit', self.bit_expr(loc, bit[1], x))
            return None
        if mn in ('bset', 'bclr'):
            loc = self.ea_addr(ops[1], st)
            if loc[0] != 'mem' or ops[0][0] != 'imm':
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            p = self.bitpath(loc[1], loc[2], ops[0][1])
            if p is None:
                raise Unliftable('0x%X: bit %d of +%d' % (x.addr, ops[0][1], loc[2]))
            self.emit_set(p, ('bool', mn == 'bset'), out)
            return None
        if mn in ('ori', 'or', 'andi', 'and') and ops[1][0] in ('ind',):
            return self.bitops(x, ops, st, out)
        if mn in ('ori', 'or', 'andi', 'and') and ops[1][0] == 'dreg':
            return self.regbits(x, ops, st, out)
        if mn in ('lsr', 'lsl') and ops[1][0] == 'dreg':
            if ops[0][0] != 'imm':
                raise Unliftable('0x%X: a shift by a register' % x.addr)
            v = st.regs.get(ops[1][1])
            n = ops[0][1]
            if isinstance(v, tuple) and v[0] == 'boolbyte' and mn == 'lsr' and n == 7:
                st.regs[ops[1][1]] = ('boolshift', v[1], 0)
                return None
            if isinstance(v, tuple) and v[0] == 'boolshift' and mn == 'lsl':
                st.regs[ops[1][1]] = ('boolshift', v[1], v[2] + n)
                return None
            if mn == 'lsl' and sz == 'l':
                st.regs[ops[1][1]] = self.mkcell(('bin', '*', self.val(v), ('num', 1 << n)),
                                                 'int32', False, out)
                return None
            raise Unliftable('0x%X: %s' % (x.addr, x.text))
        if mn.startswith('s') and len(mn) == 3 and mn[1:] in ('ne', 'eq', 'mi', 'pl') or mn in (
                'sne', 'seq', 'smi', 'spl'):
            c = self.condition(Insn(x.addr, 2, 'b' + mn[1:] + 's 0x0'), st)
            st.regs[ops[0][1]] = ('boolbyte', c)
            return None
        if mn in ('add', 'addi', 'sub', 'subi', 'addq', 'subq', 'suba', 'adda') and \
                ops[1][0] in ('dreg', 'areg'):
            r = ops[1][1]
            a = self.read(ops[0], SZ[sz], st, out, x)
            v = st.regs.get(r)
            if v is None:
                raise Unliftable('0x%X: %s not known' % (x.addr, r))
            op = '+' if mn.startswith('add') else '-'
            e = self.simplify(('bin', op, self.val(v), self.val(a)))
            st.regs[r] = self.mkcell(e, 'int32', False, out) if e[0] != 'num' else e
            st.flags = ('tst', st.regs[r], SZ[sz])
            return None
        if mn == 'neg' and ops[0][0] == 'dreg':
            v = st.regs.get(ops[0][1])
            e = ('un', '-', self.val(v))
            st.regs[ops[0][1]] = self.mkcell(e, 'int32', False, out)
            st.flags = ('tst', st.regs[ops[0][1]], SZ[sz])
            return None
        if mn in ('add', 'addi', 'sub', 'subi', 'addq', 'subq') and ops[1][0] in ('ind',):
            loc = self.ea_addr(ops[1], st)
            if loc[0] != 'mem':
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            size = SZ[sz]
            a = self.read(ops[0], size, st, out, x)
            bexpr, n, t = self.field(loc[1], loc[2], size)
            path = self.sel(bexpr, n)
            op = '+' if mn.startswith('add') else '-'
            self.emit_set(path, ('bin', op, path, self.val(a)), out)
            st.flags = None
            return None
        if mn == 'jsr':
            return self.call(x, st, out)
        if mn == 'asr' and ops[1][0] == 'dreg':
            v = st.regs.get(ops[1][1])
            st.regs[ops[1][1]] = self.mkcell(('bin', 'div', self.val(v), ('num', 1 << ops[0][1])),
                                             'int32', False, out)
            st.flags = ('tst', st.regs[ops[1][1]], 4)
            return None
        raise Unliftable('0x%X: %s' % (x.addr, x.text))

    def pop(self, n, x, st):
        pop_items(st.stack, n, x)

    def bit_expr(self, loc, bit, x):
        if loc[0] == 'mem':
            p = self.bitpath(loc[1], loc[2], bit)
            if p is None:
                raise Unliftable('0x%X: bit %d of +%d' % (x.addr, bit, loc[2]))
            return p
        if loc[0] == 'abs' and loc[1] in (AT_SWITCHES, AT_SWITCHES + 1):
            n = (loc[1] - AT_SWITCHES) * 8 + (7 - bit)
            names = ['sw15', 'sw14', 'sw13', 'sw12', 'sw11', 'sw10', 'sw9', 'sw8',
                     'sw7', 'sw6', 'sw5', 'sw4', 'sw3']
            if n < len(names):
                return ('path', 'at_backend_switches', [names[n]])
        raise Unliftable('0x%X: btst %r' % (x.addr, loc))

    def bitpath(self, base, off, bit):
        try:
            bexpr, btyp = self.base_path(base)
        except Unliftable:
            return None
        if btyp == 'sol':
            n = L.sol_name(off, 1, bit)
        elif btyp == 'inh':
            n = L.INH_BY_OFF.get((off, bit + 100))
        else:
            n = None
        return self.sel(bexpr, n) if n else None

    def bitops(self, x, ops, st, out):
        """and/or into a solution byte: clearing and setting its booleans."""
        loc = self.ea_addr(ops[1], st)
        if loc[0] != 'mem' or x.sz != 'b':
            raise Unliftable('0x%X: %s' % (x.addr, x.text))
        src = ops[0]
        if src[0] == 'imm':
            mask = src[1] & 0xFF
            if x.mn.startswith('and'):
                bits = [b for b in range(8) if not mask >> b & 1]
                for b in bits:
                    st.pending_clear[(id(loc[1]), loc[2], b)] = True
                # a clear followed by an or of a copied boolean is one
                # assignment; a clear alone sets false
                k = self.at[x.addr] + 1
                y = self.ins[k]
                if y.mn == 'or' and y.ops[1] == x.ops[1] and len(bits) == 1:
                    st.flags = None
                    st.clear_next = (loc, bits[0])
                    return None
                for b in bits:
                    p = self.bitpath(loc[1], loc[2], b)
                    if p is None:
                        raise Unliftable('0x%X: bit %d of +%d' % (x.addr, b, loc[2]))
                    self.emit_set(p, ('bool', False), out)
                return None
            for b in range(7, -1, -1):
                if mask >> b & 1:
                    p = self.bitpath(loc[1], loc[2], b)
                    if p is None:
                        raise Unliftable('0x%X: bit %d of +%d' % (x.addr, b, loc[2]))
                    self.emit_set(p, ('bool', True), out)
            return None
        if src[0] == 'dreg' and x.mn == 'or':
            v = st.regs.get(src[1])
            cl = getattr(st, 'clear_next', None)
            if isinstance(v, tuple) and v[0] == 'boolshift' and cl and cl[1] == v[2]:
                p = self.bitpath(loc[1], loc[2], v[2])
                if p is None:
                    raise Unliftable('0x%X: bit %d of +%d' % (x.addr, v[2], loc[2]))
                self.emit_set(p, v[1], out)
                st.clear_next = None
                return None
        raise Unliftable('0x%X: %s' % (x.addr, x.text))

    def regbits(self, x, ops, st, out):
        r = ops[1][1]
        v = st.regs.get(r)
        s = self.read(ops[0], SZ[x.sz], st, out, x) if ops[0][0] != 'imm' else ('num', ops[0][1])
        if x.mn == 'or' and v == ('num', 0) and isinstance(s, tuple) and s[0] == 'boolshift':
            st.regs[r] = s
            return None
        raise Unliftable('0x%X: %s' % (x.addr, x.text))

    def call(self, x, st, out):
        name = self.callee(x)
        h = self.heading(name)
        vals = self.take_args(name, st.stack, x)
        params = h['params'] if not h['variable'] else (
            h['params'][:len(vals)] + [('a', 'in', 'other:arg', True)] * max(0, len(vals) - len(h['params'])))
        args = []
        for j, (pname, mode, cls, univ) in enumerate(params):
            byref = mode != 'value' or not h['val_param']
            v = vals[j]
            if byref:
                if isinstance(v, tuple) and v[0] == 'addr':
                    args.append(v[1])
                elif isinstance(v, tuple) and v[0] == 'str':
                    args.append(v)
                elif isinstance(v, tuple) and v[0] == 'frameaddr':
                    fv = st.frame.get(v[1])
                    if fv is None:
                        raise Unliftable('0x%X: a frame temporary not known' % x.addr)
                    args.append(self.val(fv))
                elif isinstance(v, tuple) and v[0] == 'addrof':
                    args.append(('path', v[1], []))
                else:
                    raise Unliftable('0x%X: %s: argument %d by reference: %r' % (
                        x.addr, name, j + 1, v))
            else:
                if isinstance(v, tuple) and v[0] == 'addrof':
                    args.append(('addr', ('path', v[1], [])))
                elif isinstance(v, tuple) and v[0] == 'param':
                    args.append(('path', v[1], []))
                else:
                    e = self.val(v)
                    if pname == 'opc' and e[0] == 'num':
                        e = ('opc', self.opcode(e[1]))
                    if e == ('num', 0) and cls in L.POINTERS:
                        e = ('nil',)
                    args.append(e)
        for r in ('d0', 'd1', 'a0', 'a1'):
            st.regs.pop(r, None)
        st.flags = None
        for a in args:
            self.use(a)
        if h['ret'] is None:
            out.append(('call', name, args))
            self.boundary()
            # a call may change any field: earlier loads are dirty
            for c in self.cells:
                if not c.volatile and c.expr is not None and not c.temp and has_sel(c.expr):
                    c.dirty = True
        else:
            r = 'a0' if h['ret'] in L.POINTERS else 'd0'
            typ = {'isp': 'sol', 'sp': 'sol', 'up': 'ptr', 'lr': 'lr', 'inh': 'inh',
                   'i32': 'int32', 'i16': 'int16', 'bool': 'bool'}.get(h['ret'], 'int32')
            c = self.mkcell(('call', name, args), typ, True, out)
            st.regs[r] = c
            self.bound += 1
            for c2 in self.cells:
                if c2 is not c and not c2.volatile and c2.expr is not None and has_sel(c2.expr):
                    c2.dirty = True
            c.at = self.bound
        return None

    def opcode(self, v):
        global OPCODES
        if OPCODES is None:
            import iscg_gen
            OPCODES = iscg_gen.opcode_names()
        if 0 <= v < len(OPCODES):
            return OPCODES[v]
        raise Unliftable('opcode %d' % v)

    # ---- the end: temps, idioms
    def finish(self, stmts):
        # the cells' temps
        for c in self.cells:
            if c.expr is None:
                continue
            if c.volatile and c.uses != 1:
                c.need = True
            if c.need:
                pass
        # selecting through a call's value needs a temp
        changed = True
        while changed:
            changed = False
            for c in self.cells:
                if c.expr is not None and not c.need:
                    for d in sel_bases(c.expr):
                        if d.volatile and not d.need:
                            d.need = True
                            changed = True
        decls = []
        n = 0
        for c in self.cells:
            if c.need and (c.uses or getattr(c, 'phi', False) or c.volatile):
                n += 1
                c.temp = 't%d' % n
                t = {'sol': 'solution', 'ptr': 'pointer', 'lr': 'live_range', 'int16': 'integer',
                     'int8': 'integer', 'int32': 'integer32', 'bool': 'boolean', 'node': 'pointer',
                     'label': 'pointer', 'inh': 'attributes'}.get(c.typ, 'integer32')
                decls.append(('temp', c.temp, t))
        out = self.resolve(stmts)
        out = idioms(out, self.rule)
        return decls + out

    def resolve(self, stmts):
        out = []
        for s in stmts:
            if isinstance(s, list) and s[0] == 'mark':
                c = s[1]
                if c.temp and c.expr is not None:
                    out.append(('set', ('path', c.temp, []), self.fix(c.expr, top=c)))
                continue
            if isinstance(s, list) and s[0] == 'phi':
                c, v = s[1], s[2]
                out.append(('set', ('path', c.temp or 'phi?', []), self.fix(self.val(v))))
                continue
            k = s[0]
            if k == 'set':
                out.append(('set', self.fix(s[1]), self.fix(s[2])))
            elif k == 'call':
                out.append(('call', s[1], [self.fix(a) for a in s[2]]))
            elif k == 'if':
                out.append(('if', [(self.fix(c), self.resolve(b)) for c, b in s[1]],
                            self.resolve(s[2]) if s[2] is not None else None))
            elif k == 'for':
                out.append(('for', s[1], self.fix(s[2]), self.fix(s[3]), self.resolve(s[4])))
            else:
                raise Unliftable('statement %r' % (s,))
        return out

    def fix(self, e, top=None):
        """Cells to temps or their expressions; sel chains to paths."""
        if isinstance(e, tuple):
            k = e[0]
            if k == 'cell':
                c = e[1]
                if c.temp and c is not top:
                    return ('path', c.temp, [])
                if c.expr is None:
                    raise Unliftable('a value with no expression')
                return self.fix(c.expr)
            if k == 'sel':
                b = self.fix(e[1])
                if b[0] == 'index':
                    return ('path', b, [e[2]])
                if b[0] != 'path':
                    raise Unliftable('a field of %s' % L.fmt_expr(b))
                return ('path', b[1], b[2] + [e[2]])
            if k == 'index':
                return ('index', e[1], self.fix(e[2]))
            if k in ('boolbyte', 'boolshift'):
                raise Unliftable('a boolean byte used as a value')
            if k == 'call':
                return ('call', e[1], [self.fix(a) for a in e[2]])
            if k == 'bin':
                return ('bin', e[1], self.fix(e[2]), self.fix(e[3]))
            if k == 'un':
                return ('un', e[1], self.fix(e[2]))
            if k == 'addr':
                return ('addr', self.fix(e[1]))
            if k in ('path', 'num', 'nil', 'bool', 'str', 'opc'):
                return e
            raise Unliftable('a value %r' % (k,))
        raise Unliftable('a value %r' % (e,))


OPCODES = None


def pop_items(st, n, x):
    """n bytes popped off the argument stack: taken arguments and pads (a
    pop may take part of one: Rev 8.89 keeps two bytes of the last call's
    arguments as the next call's pad)."""
    while n > 0:
        if not st:
            return          # what an arm left (the arms' dead pushes differ)
        it = st[-1]
        if it[0] == 'a':
            raise Unliftable('0x%X: a pop of a pending argument' % x.addr)
        if it[1] <= n:
            st.pop()
            n -= it[1]
        else:
            st[-1] = ['p', it[1] - n, None]
            n = 0


def pending(st):
    return [i[1] for i in st if i[0] == 'a']


def sext16(v):
    v &= 0xFFFF
    return v - 0x10000 if v & 0x8000 else v


WORD_CLASSES = ('i16', 'u16', 'u8', 'bool', 'char')


def param_size(h, p):
    name, mode, cls, univ = p
    if mode != 'value' or not h['val_param']:
        return 4
    if cls in WORD_CLASSES or (cls.startswith('other:') and cls.endswith('$t')):
        return 2
    return 4


class State:
    def __init__(self):
        self.regs = {}
        self.stack = []
        self.frame = {}
        self.flags = None
        self.pending_clear = {}
        self.clear_next = None

    def copy(self):
        s = State()
        s.regs = dict(self.regs)
        s.stack = [list(i) for i in self.stack]
        s.frame = dict(self.frame)
        s.flags = self.flags
        s.clear_next = self.clear_next
        return s


def walk_expr(e):
    if isinstance(e, tuple):
        yield e
        for x in e[1:]:
            if isinstance(x, (tuple, list)):
                if isinstance(x, list):
                    for y in x:
                        yield from walk_expr(y)
                else:
                    yield from walk_expr(x)
            elif isinstance(x, Cell) and x.expr is not None:
                yield from walk_expr(x.expr)


def cells_in(e):
    out = []
    if isinstance(e, tuple):
        if e[0] == 'cell':
            out.append(e[1])
            return out
        for x in e[1:]:
            if isinstance(x, tuple):
                out.extend(cells_in(x))
            elif isinstance(x, list):
                for y in x:
                    out.extend(cells_in(y))
    return out


def sel_bases(e):
    """The cells a field is selected from in e."""
    out = []
    if isinstance(e, tuple):
        if e[0] == 'sel' and isinstance(e[1], tuple) and e[1][0] == 'cell':
            out.append(e[1][1])
        for x in e[1:]:
            if isinstance(x, tuple):
                out.extend(sel_bases(x))
            elif isinstance(x, list):
                for y in x:
                    out.extend(sel_bases(y))
    return out


def has_sel(e):
    return any(isinstance(x, tuple) and x[0] == 'sel' for x in walk_expr(e))


def contains(e, path):
    """Whether e reads the field path names (a sel chain with the same
    last selector: a conservative alias test)."""
    if not (isinstance(path, tuple) and path[0] == 'sel'):
        return False
    for x in walk_expr(e):
        if isinstance(x, tuple) and x[0] == 'sel' and x[2] == path[2]:
            return True
    return False


# --------------------------------------------------------------------------
# idioms over the lifted statements

def is_inh_of_result(e):
    return e == ('path', 'result', ['inherited_attributes'])


def idioms(stmts, rule):
    out = []
    i = 0
    while i < len(stmts):
        s = stmts[i]
        k = s[0]
        if k == 'call' and s[1].startswith('debug_lir_$') and s[2] and is_inh_of_result(s[2][0]):
            m = re.match(r'debug_lir_\$(\w+?)_instruction$', s[1])
            if m and m.group(1) in L.EMIT_KINDS:
                out.append(('emit', m.group(1), s[2][1:]))
                i += 1
                continue
            if s[1] == 'debug_lir_$label':
                out.append(('emit', 'label', s[2][1:]))
                i += 1
                continue
        if k == 'set' and s[1] == ('path', 'solution', ['live_range']) and i + 1 < len(stmts):
            line = let_check(stmts[i + 1], rule)
            if line is not None:
                out.append(('let', s[2], line))
                i += 2
                continue
        if k == 'if':
            arms = [(c, idioms(b, rule)) for c, b in s[1]]
            els = idioms(s[2], rule) if s[2] is not None else None
            if not arms[0][1] and els:
                arms = [(negate_expr(arms[0][0]), els)]
                els = None
            if els is not None and not els:
                els = None
            # else if -> elsif
            while els is not None and len(els) == 1 and els[0][0] == 'if':
                arms.extend(els[0][1])
                els = els[0][2]
            if not any(b for _, b in arms) and not els:
                i += 1
                continue
            out.append(('if', arms, els))
            i += 1
            continue
        if k == 'for':
            out.append(('for', s[1], s[2], s[3], idioms(s[4], rule)))
            i += 1
            continue
        out.append(s)
        i += 1
    return out


def negate_expr(c):
    if c[0] == 'un' and c[1] == 'not':
        return c[2]
    inv = {'=': '<>', '<>': '=', '<': '>=', '>=': '<', '>': '<=', '<=': '>',
           'u<': 'u>=', 'u>=': 'u<', 'u>': 'u<=', 'u<=': 'u>'}
    if c[0] == 'bin' and c[1] in inv:
        return ('bin', inv[c[1]], c[2], c[3])
    return ('un', 'not', c)


LET_MSG = re.compile(r"ISC: A 'let result <- \.\.\.;' in pattern (\d+) \(line number (\d+)\) "
                     r"used a nil live_range\.%\$$")


def let_check(s, rule):
    """The nil check after `solution.live_range <- e': the input's line, or
    None."""
    if s[0] != 'if' or len(s[1]) != 1 or s[2]:
        return None
    c, body = s[1][0]
    if not (c[0] == 'bin' and c[1] == '=' and c[3] == ('nil',)):
        return None
    if len(body) != 1 or body[0][0] != 'if' or len(body[0][1]) != 1 or body[0][2]:
        return None
    c2, b2 = body[0][1][0]
    if c2 != ('un', 'not', ('path', 'at_backend_switches', ['sw11'])):
        return None
    if len(b2) != 1 or b2[0][0] != 'call' or b2[0][1] != 'bug_check':
        return None
    m = LET_MSG.match(b2[0][2][0][1]) if b2[0][2][0][0] == 'str' else None
    if not m or int(m.group(1)) != rule:
        return None
    return int(m.group(2))


# --------------------------------------------------------------------------

class Image:
    def __init__(self, binary, im=None):
        import cc_isc_inventory as inv
        self.inv = im or inv.Image(binary)
        self.p2 = self.inv.action_table(P2_A5)
        self.starts = sorted(set(self.p2))

    def read(self, a, n):
        return self.inv.read(a, n)

    def range_of(self, r):
        va = self.p2[r - 1]
        i = bisect.bisect_right(self.starts, va)
        return va, (self.starts[i] if i < len(self.starts) else P2_END)


_HEADINGS = None


def headings():
    global _HEADINGS
    if _HEADINGS is None:
        import iscg_gen
        _HEADINGS = L.read_headings(iscg_gen.INCLUDES)
    return _HEADINGS


def lift_rule(img, r):
    """The lifted body of rule r's pass-2 action: (stmts, None) or (None,
    reason); ([], None) for an empty action."""
    va, end = img.range_of(r)
    if img.read(va, 2) == b'\x4e\x75':
        return [], None
    try:
        lf = Lifter(img, r, va, end, headings(), img.inv.names)
        stmts = lf.lift()
        # the printer and the parser must agree
        text = '\n'.join(L.fmt_body(stmts))
        if L.parse_body(text) != [s for s in stmts]:
            return None, 'the printed body does not read back'
        return stmts, None
    except Unliftable as e:
        return None, str(e)
    except L.LangError as e:
        return None, 'language: %s' % e


def main():
    import cc_isc_inventory as inv
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('rules', nargs='*', type=int)
    ap.add_argument('--binary', default=inv.DEFAULT_BINARY)
    ap.add_argument('--stats', action='store_true')
    a = ap.parse_args()
    img = Image(a.binary)
    rules = a.rules or list(range(1, len(img.p2) + 1))
    why = collections.Counter()
    ok = 0
    for r in rules:
        stmts, reason = lift_rule(img, r)
        if a.stats:
            if stmts is None:
                why[re.sub(r'0x[0-9A-F]+: ', '', reason)[:60]] += 1
            else:
                ok += 1
            continue
        print('{ rule %d }' % r)
        if stmts is None:
            print('  residue: %s' % reason)
        else:
            print('\n'.join(L.fmt_body(stmts)) or '  (empty)')
    if a.stats:
        print('%d of %d lifted' % (ok, len(rules)))
        for k, v in why.most_common(40):
            print('%5d  %s' % (v, k))


if __name__ == '__main__':
    main()
