#!/usr/bin/env python3
"""iscg_p1lift.py - the pass-1 actions of cc.a88k lifted to the statement language.

    tools/iscg_p1lift.py [--binary B] [RULE ...]     print the lifted clauses
    tools/iscg_p1lift.py --stats [--section N]        how many lift, and why not

The decompiler of tools/iscg_p2lift.py (its Lifter: symbolic execution
from the prologue to the epilogue, ifs at post-dominators, temps for
values kept across statements) extended for the pass-1 actions
(docs/iscg-design.md 2.5, 2.6, 10.7):

- the heading (var subject: isc_solution_t; il: univ_ptr; inh:
  inherited_attributes_ptr_t; var work, result: isc_solution_ptr_t):
  subject, il and inh are the language's names; the two var pointers
  are the skeleton's;
- the trace (`write(output, 'Pattern N matched the semantics.');
  writeln(output)', pas_$output at A5-4) is one statement;
- the cost tables: a word or byte of the module's data (A5 + a table's
  offset, or an absolute base above 32 KB) indexed by an alternative's
  choice byte, written inline as the table's contents, `words(4, 4)[
  result.c138]' (iscg_p1lang.py; the generator lays the tables out);
- Rev 8.89's boolean forms: conditions evaluated into bytes (s<cc>,
  not.b, and.b, or.b, a test of bit 7), a boolean function's value
  stored into a packed field (lsr.b #7, shifted, or'ed into a cleared
  bit), adjacent fields cleared, copied or set by one longword or word
  instruction;
- then the skeleton: `result := nil; work := nil;' and the conditions,
  the trace, the cycle guard of the chain rules, new_solution with the
  rule's result kind, which_transform and before_transform, the seven
  already_ copies, the guard's flag, `work := s; result := s' (a
  proper_subtree rule: `result := subject' and the subject's costs).
  What is left is the rule's body; the new solution is `result'.

What it cannot follow raises Unliftable with the reason; tools/iscg_
extract.py then writes the transform's pass_1 as `residue'.
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
import iscg_p2lift as P2  # noqa: E402
import iscg_p1lang as L1  # noqa: E402
from iscg_p2lift import Unliftable, Cell, parse_operand, SZ  # noqa: E402

P1_A5 = 0x4800BC                # isc_pattern_matcher's data: the pass-1 action table
P1_END = 0x18C588               # pass_2: the first routine after the pass-1 modules
PAS_WRITE = 0x4930D2            # pas_$write
PAS_WRITELN = 0x4930CC          # pas_$writeln
ISC_HEAP = 0x48103C             # isc_heap (isc_var_externs.ins.pas)
TRACE = 'isc_user_routines_354'
ALREADY = ['already_address_mode', 'already_fp_reg', 'already_fp_reg_pair',
           'already_fp_reg_quad', 'already_ip_reg', 'already_ip_reg_field',
           'already_processor_reg']        # +342 .. +348
MATCHED = 'Pattern %d matched the semantics.'
CYCLE = 'Infinite cycle prevented by NOT adding this to the work list.'
# the prelude's cells the actions read: address -> (name, class)
GLOBAL_CELLS = {0x2E9E60: ('il_180', 'node')}      # il.ins.pas: the routine's block node
# bytes of a set the actions test bits of: address -> (variable, field,
# the element of the byte's bit 0) (cargs.ins.pas: flags_286 runs from
# element 20 at +0x286 bit 7 down)
GLOBAL_BITS = {0x4437F6: ('cargs_$options', 'flags_286', 13)}
PARAMS = {8: 'subject', 12: 'il', 16: 'inh', 20: 'work', 24: 'result'}


class Lifter(P2.Lifter):
    """A pass-1 action's body, the skeleton still in it."""

    def __init__(self, im, rule, start, end, headings, names, a5_lo, a5_hi):
        self.a5_lo, self.a5_hi = a5_lo, a5_hi      # the module's data block
        self.tables = {}                           # offset -> ('b'|'w', values)
        self.writes = {}
        super().__init__(im, rule, start, end, headings, names)
        self.find_writes()

    # ---- the trace's writes: one statement
    def find_writes(self):
        """write(output, 'text'); writeln(output): start address -> (end,
        text): movew #len; pea text; movel A5@(-4); movew #51; jsr
        pas_$write; lea sp@(12); movel A5@(-4); jsr pas_$writeln."""
        ins = self.ins
        for k in range(len(ins) - 7):
            x = ins[k:k + 8]
            if not (x[0].text.startswith('movew #') and x[0].ops[1] == '%sp@-'
                    and x[1].text.startswith('pea %pc@(') and x[2].text == 'movel %a5@(-4),%sp@-'
                    and x[3].text == 'movew #51,%sp@-' and x[4].text == 'jsr 0x%x' % PAS_WRITE
                    and x[5].text == 'lea %sp@(12),%sp' and x[6].text == 'movel %a5@(-4),%sp@-'
                    and x[7].text == 'jsr 0x%x' % PAS_WRITELN):
                continue
            n = parse_operand(x[0].ops[0])[1]
            a = parse_operand(x[1].ops[0])[1]
            text = self.im.read(a, n).decode('latin-1')
            self.writes[x[0].addr] = (ins[k + 8].addr if k + 8 < len(ins) else None, text)

    def succ(self, k):
        x = self.ins[k]
        if x.addr in self.writes:
            return [self.writes[x.addr][0]]
        return super().succ(k)

    def shape_step(self, x, st):
        if x.addr in self.writes:
            # the writeln's file argument stays on the stack (taken)
            return [tuple(i) for i in st] + [('d', 4, None)]
        return super().shape_step(x, st)

    # ---- the frame and parameters
    def lift(self):
        self.postdom()
        self.shapes()
        st = P2.State()
        st.regs['a6'] = ('frame',)
        st.regs['a5'] = ('data', 0)
        stmts = self.run(self.body, st, {self.epilogue})[0]
        return self.finish(stmts)

    def read(self, op, size, st, out, x):
        loc = self.ea_addr(op, st)
        if loc[0] == 'fp' and loc[1] in PARAMS:
            return ('param', PARAMS[loc[1]])
        if loc[0] == 'a5':
            raise Unliftable('0x%X: A5%+d read' % (x.addr, loc[1]))
        if loc[0] == 'tabmem' and isinstance(loc[1], tuple) and loc[1][0] == 'data':
            return self.mkcell(self.cost_expr(loc, size, x), 'int16', False, out)
        if loc[0] in ('abs', 'absmem') and self.a5_lo <= loc[1] < self.a5_hi:
            raise Unliftable('0x%X: module data read directly' % x.addr)
        if loc[0] == 'mem':
            try:
                self.field(loc[1], loc[2], size)
            except Unliftable:
                try:
                    btyp = self.base_path(loc[1])[1]
                except Unliftable:
                    btyp = None
                if btyp == 'sol' and self.fields_over(loc[2], size):
                    # adjacent fields read as one (a copy split by the store)
                    return ('multi', loc[1], loc[2], size)
        return super().read(op, size, st, out, x)

    def ea_addr(self, op, st):
        if op[0] == 'ind' and op[1] not in ('a5', 'a6', 'a7'):
            b = st.regs.get(op[1])
            if isinstance(b, tuple) and b[0] == 'data':
                return ('dataabs', b[1] + op[2])
        if op[0] == 'idx' and op[4] in 'wl' and op[5] == 1 and op[1] == 'a5':
            i = st.regs.get(op[3])
            if i is None:
                raise Unliftable('operand %r' % (op,))
            return ('tabmem', ('data', 0), i, op[2])
        return super().ea_addr(op, st)

    def cost_expr(self, loc, size, x):
        """A cost table's element: ('cost', 'b'|'w', values, index)."""
        _, b, i, disp = loc
        off = b[1] + disp
        iv = self.val(i)
        if iv[0] == 'cell' and iv[1].expr is not None:
            iv = iv[1].expr
        if size == 2:
            if not (iv[0] == 'bin' and iv[1] == '+' and iv[2] == iv[3]):
                raise Unliftable('0x%X: a word table indexed by %r' % (x.addr, iv[0]))
            iv = iv[2]
        elif size != 1:
            raise Unliftable('0x%X: a %d-byte table' % (x.addr, size))
        kind = 'b' if size == 1 else 'w'
        vals = []
        d = self.im.data(self.a5_lo + off, 17 * size)
        if None in d:
            raise Unliftable('0x%X: table +%d not all set' % (x.addr, off))
        for k in range(17):
            vals.append(int.from_bytes(bytes(d[k * size:k * size + size]), 'big'))
        if off in self.tables and self.tables[off][0] != kind:
            raise Unliftable('0x%X: table +%d read as bytes and words' % (x.addr, off))
        self.tables[off] = (kind, vals)
        if vals[0]:
            raise Unliftable('0x%X: table +%d with a cost for alternative 0' % (x.addr, off))
        n = max([k for k in range(17) if vals[k]] + [0])
        return ('cost', kind, tuple(vals[1:n + 1]), iv, off)

    def base_path(self, b):
        if isinstance(b, tuple) and b[0] == 'param':
            if b[1] == 'subject':
                return ('path', 'subject', []), 'sol'
            if b[1] == 'il':
                return ('path', 'il', []), 'node'
            if b[1] == 'inh':
                return ('path', 'inh', []), 'inh'
            raise Unliftable('a field of the var parameter %s' % b[1])
        return super().base_path(b)

    def typ_of(self, v):
        if isinstance(v, tuple) and v[0] == 'param':
            return {'subject': 'sol', 'il': 'node', 'inh': 'inh'}.get(v[1], 'ptr')
        if isinstance(v, tuple) and v[0] == 'boolbyte':
            return 'bool'
        return super().typ_of(v)

    def val(self, v):
        if isinstance(v, tuple) and v[0] == 'param' and v[1] in ('il', 'inh', 'subject'):
            return ('path', v[1], [])
        if isinstance(v, tuple) and v[0] == 'boolbyte':
            return v[1]
        return super().val(v)

    def store(self, op, size, v, st, out, x):
        loc = self.ea_addr(op, st)
        if loc[0] == 'mem' and isinstance(loc[1], tuple) and loc[1][0] == 'param' and \
                loc[1][1] in ('work', 'result') and loc[2] == 0 and size == 4:
            ve = self.val(v) if not (isinstance(v, tuple) and v[0] == 'param') else (
                ('path', v[1], []))
            if ve == ('num', 0):
                ve = ('nil',)
            self.use(ve)
            out.append(('set', ('path', '@' + loc[1][1], []), ve))
            self.boundary()
            return
        if loc[0] == 'mem' and self.split_store(loc, size, v, st, out, x):
            return
        if loc[0] == 'mem' and isinstance(v, tuple) and v[0] == 'param' and v[1] == 'subject':
            bexpr, n, t = self.field(loc[1], loc[2], size)
            self.emit_set(self.sel(bexpr, n), ('path', 'subject', []), out)
            return
        if loc[0] == 'dataabs':
            raise Unliftable('0x%X: module data set' % x.addr)
        return super().store(op, size, v, st, out, x)

    def split_store(self, loc, size, v, st, out, x):
        """A longword or word store over two or more fields (Rev 8.89 merges
        adjacent clears, copies and constants): one assignment each."""
        base, off = loc[1], loc[2]
        try:
            self.field(base, off, size)
            return False
        except Unliftable:
            pass
        try:
            bexpr, btyp = self.base_path(base)
        except Unliftable:
            return False
        if btyp != 'sol':
            return False
        parts = self.fields_over(off, size)
        if parts is None:
            return False
        for o, s in parts:
            if isinstance(v, tuple) and v[0] == 'num':
                n = v[1] & ((1 << 8 * size) - 1)
                pv = ('num', P2.sext16(n >> 8 * (off + size - o - s) & ((1 << 8 * s) - 1))
                      if s == 2 else n >> 8 * (off + size - o - s) & ((1 << 8 * s) - 1))
            elif isinstance(v, tuple) and v[0] == 'multi' and v[3] == size:
                bexpr2, n2, t2 = self.field(v[1], v[2] + (o - off), s)
                pv = self.sel(bexpr2, n2)
            else:
                return False
            _, n, t = self.field(base, o, s)
            self.emit_set(self.sel(bexpr, n), pv, out)
        return True

    def fields_over(self, off, size):
        """The named fields that tile [off, off + size) exactly, or None."""
        out, o = [], off
        while o < off + size:
            for s in (4, 2, 1):
                if o + s <= off + size and L.sol_name(o, s) is not None:
                    out.append((o, s))
                    o += s
                    break
            else:
                return None
        return out if len(out) > 1 else None

    def mkcell(self, expr, typ, volatile, out):
        return super().mkcell(expr, typ, volatile, out)

    def push_value(self, op, st, out, x):
        if op[0] == 'ind' and op[1] not in ('a5', 'a6', 'a7') and op[2] == 0:
            b = st.regs.get(op[1])
            if isinstance(b, tuple) and b[0] == 'param' and b[1] == 'subject':
                return ('addrof', 'subject')
        return super().push_value(op, st, out, x)

    def call(self, x, st, out):
        # a by-reference argument given as a global's address
        name = self.callee(x)
        h = self.heading(name)
        vals_pending = [it for it in st.stack if it[0] == 'a']
        for it in vals_pending:
            v = it[2]
            if isinstance(v, tuple) and v[0] == 'num' and (v[1] & 0xFFFFFFFF) == ISC_HEAP:
                it[2] = ('addr', ('path', 'isc_heap', []))
        return super().call(x, st, out)

    # ---- instructions pass 2 does not meet
    def step(self, k, st, out):
        x = self.ins[k]
        mn, sz = x.mn, x.sz
        if x.addr in self.writes:
            end, text = self.writes[x.addr]
            out.append(('writeln', text))
            self.boundary()
            st.stack.append(['d', 4, None])
            st.flags = None
            for r in ('d0', 'd1', 'a0', 'a1'):
                st.regs.pop(r, None)
            return end
        if mn == 'movea' and x.ops[0].startswith('#'):
            v = parse_operand(x.ops[0])[1]
            if self.a5_lo <= v < self.a5_hi + 0x10000:
                st.regs[parse_operand(x.ops[1])[1]] = ('data', v - self.a5_lo)
                return None
        if mn == 'lea' and x.ops[0].startswith('%a') and ',%d' in x.ops[0]:
            src = parse_operand(x.ops[0])
            dst = parse_operand(x.ops[1])
            if src[0] == 'idx' and src[1] in st.regs and isinstance(st.regs[src[1]], tuple) and \
                    st.regs[src[1]][0] == 'data' or (src[0] == 'idx' and src[1] == 'a5'):
                b = st.regs.get(src[1], ('data', 0)) if src[1] != 'a5' else ('data', 0)
                i = st.regs.get(src[3])
                if i is None:
                    raise Unliftable('0x%X: %s' % (x.addr, x.text))
                st.regs[dst[1]] = ('idxaddr', b, i, src[2])
                return None
        if mn in ('move', 'movea') and x.ops[0].startswith('%a') and '@(' in x.ops[0]:
            # a load from a table address (lea A5@(0,Dn:w),An; move An@(d))
            op0 = parse_operand(x.ops[0])
            b = st.regs.get(op0[1]) if op0[0] == 'ind' else None
            if isinstance(b, tuple) and b[0] == 'idxaddr' and isinstance(b[1], tuple) and \
                    b[1][0] == 'data':
                loc = ('tabmem', b[1], b[2], b[3] + op0[2])
                v = self.mkcell(self.cost_expr(loc, SZ[sz], x), 'int16', False, out)
                op1 = parse_operand(x.ops[1])
                if mn == 'move' and op1[0] != 'areg':
                    st.flags = ('tst', v, SZ[sz])
                self.store(op1, SZ[sz], v, st, out, x)
                return None
        if mn in ('add',) and x.ops[0].startswith('%a') and '@(' in x.ops[0] and \
                x.ops[1].startswith('%d'):
            op0 = parse_operand(x.ops[0])
            b = st.regs.get(op0[1]) if op0[0] == 'ind' else None
            if isinstance(b, tuple) and b[0] == 'idxaddr' and isinstance(b[1], tuple) and \
                    b[1][0] == 'data':
                loc = ('tabmem', b[1], b[2], b[3] + op0[2])
                a = self.mkcell(self.cost_expr(loc, SZ[sz], x), 'int16', False, out)
                r = x.ops[1].strip('%')
                v = st.regs.get(r)
                if v is None:
                    raise Unliftable('0x%X: %s not known' % (x.addr, r))
                e = ('bin', '+', self.val(v), self.val(a))
                st.regs[r] = self.mkcell(e, 'int32', False, out)
                st.flags = ('tst', st.regs[r], SZ[sz])
                return None
        if mn == 'st' or (mn in ('sne', 'seq', 'smi', 'spl', 'sf') and not x.ops[0].startswith('%d')):
            if mn != 'st':
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            loc = self.ea_addr(parse_operand(x.ops[0]), st)
            if loc[0] != 'mem':
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            bexpr, n, t = self.field(loc[1], loc[2], 1)
            self.emit_set(self.sel(bexpr, n), ('bool', True), out)
            return None
        if mn in ('sne', 'seq', 'smi', 'spl', 'sgt', 'sge', 'slt', 'sle', 'shi', 'sls', 'scc',
                  'scs') and x.ops[0].startswith('%d'):
            c = self.condition(P2.Insn(x.addr, 2, 'b' + mn[1:] + 's 0x0'), st)
            st.regs[x.ops[0][1:]] = ('boolbyte', c)
            return None
        if mn == 'not' and sz == 'b' and x.ops[0].startswith('%d'):
            r = x.ops[0][1:]
            v = st.regs.get(r)
            b = self.as_bool(v)
            if b is None:
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            st.regs[r] = ('boolbyte', L1.negate(b))
            st.flags = ('boolflags', st.regs[r])
            return None
        if mn in ('and', 'or') and sz == 'b' and x.ops[1].startswith('%d') and \
                not x.ops[0].startswith('#'):
            r = x.ops[1][1:]
            v = st.regs.get(r)
            a = self.read(parse_operand(x.ops[0]), 1, st, out, x)
            bv, ba = self.as_bool(v), self.as_bool(a)
            if isinstance(a, tuple) and a[0] == 'boolshift' and v == ('num', 0) and mn == 'or':
                st.regs[r] = a
                return None
            if bv is None or ba is None:
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            st.regs[r] = ('boolbyte', ('bin', 'and' if mn == 'and' else 'or', bv, ba))
            st.flags = ('boolflags', st.regs[r])
            return None
        if mn == 'andi' and sz == 'b' and x.ops[1].startswith('%d') and x.ops[0] == '#-128':
            # a boolean kept in bit 7 (copied into a packed field's bit 7)
            r = x.ops[1][1:]
            b = self.as_bool(st.regs.get(r))
            if b is None:
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            st.regs[r] = ('boolshift', b, 7)
            return None
        if mn == 'lsr' and sz == 'b' and x.ops[1].startswith('%d') and x.ops[0] == '#7':
            r = x.ops[1][1:]
            b = self.as_bool(st.regs.get(r))
            if b is None:
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            st.regs[r] = ('boolshift', b, 0)
            return None
        if mn == 'add' and sz == 'b' and x.ops[0] == x.ops[1] and x.ops[1].startswith('%d'):
            r = x.ops[1][1:]
            v = st.regs.get(r)
            if isinstance(v, tuple) and v[0] == 'boolshift':
                st.regs[r] = ('boolshift', v[1], v[2] + 1)
                return None
        if mn == 'lsl' and sz == 'b' and x.ops[1].startswith('%d') and x.ops[0].startswith('#'):
            r = x.ops[1][1:]
            v = st.regs.get(r)
            if isinstance(v, tuple) and v[0] == 'boolshift':
                st.regs[r] = ('boolshift', v[1], v[2] + parse_operand(x.ops[0])[1])
                return None
        if mn in ('or', 'ori') and sz == 'w' and x.ops[1].startswith('%a') and '@(' in x.ops[1]:
            # a word or of constant bits: the booleans of two bytes
            src = parse_operand(x.ops[0])
            if src[0] == 'dreg':
                v = st.regs.get(src[1])
                if not (isinstance(v, tuple) and v[0] == 'num'):
                    raise Unliftable('0x%X: %s' % (x.addr, x.text))
                mask = v[1]
            elif src[0] == 'imm':
                mask = src[1]
            else:
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            loc = self.ea_addr(parse_operand(x.ops[1]), st)
            if loc[0] != 'mem':
                raise Unliftable('0x%X: %s' % (x.addr, x.text))
            for byte, m in ((loc[2], mask >> 8 & 0xFF), (loc[2] + 1, mask & 0xFF)):
                for b in range(7, -1, -1):
                    if m >> b & 1:
                        p = self.bitpath(loc[1], byte, b)
                        if p is None:
                            raise Unliftable('0x%X: bit %d of +%d' % (x.addr, b, byte))
                        self.emit_set(p, ('bool', True), out)
            st.flags = None
            return None
        if mn in ('lsr', 'asr') and x.ops[1].startswith('%d') and x.ops[0].startswith('#') and \
                sz in 'wl':
            r = x.ops[1][1:]
            v = st.regs.get(r)
            if v is None:
                raise Unliftable('0x%X: %s not known' % (x.addr, r))
            n = parse_operand(x.ops[0])[1]
            e = ('call', 'rshft', [self.val(v), ('num', n)]) if mn == 'lsr' else \
                ('call', 'arshft', [self.val(v), ('num', n)])
            st.regs[r] = self.mkcell(e, 'int32', False, out)
            st.flags = ('tst', st.regs[r], SZ[sz])
            return None
        if mn == 'move' and x.ops[0].startswith('%d') and x.ops[1].startswith('%d') and sz in 'bw':
            # a partial move into a register cleared before: the value
            st.regs[x.ops[1][1:]] = st.regs.get(x.ops[0][1:])
            if st.regs[x.ops[1][1:]] is None:
                raise Unliftable('0x%X: %s not known' % (x.addr, x.ops[0]))
            st.flags = ('tst', st.regs[x.ops[1][1:]], SZ[sz])
            return None
        if mn == 'tst' and sz == 'b' and x.ops[0].startswith('%d'):
            v = st.regs.get(x.ops[0][1:])
            b = self.as_bool(v)
            if b is not None:
                st.flags = ('boolflags', ('boolbyte', b))
                return None
        return super().step(k, st, out)

    def table_expr(self, loc, size, x):
        _, b, i, disp = loc
        if isinstance(b, tuple) and b[0] == 'num' and b[1] == P2.ISC_READONLY and size == 1:
            iv = self.val(i)
            if iv[0] == 'cell' and iv[1].expr is not None:
                iv = iv[1].expr
            return ('index', 'readonly_b%d' % disp, iv)
        return super().table_expr(loc, size, x)

    def global_expr(self, addr, size):
        if addr in GLOBAL_CELLS and size == 4:
            return ('path', GLOBAL_CELLS[addr][0], [])
        return super().global_expr(addr, size)

    def global_type(self, addr):
        if addr in GLOBAL_CELLS:
            return GLOBAL_CELLS[addr][1]
        return super().global_type(addr)

    def bit_expr(self, loc, bit, x):
        if loc[0] == 'mem':
            try:
                bexpr, btyp = self.base_path(loc[1])
            except Unliftable:
                btyp = None
            if btyp == 'node':
                # an IL node's byte by offset, a bit of it
                return ('bin', '<>', ('bin', '&', self.sel(bexpr, 'b%d' % loc[2]),
                                      ('num', 1 << bit)), ('num', 0))
            if btyp in ('sol', 'inh') and self.bitpath(loc[1], loc[2], bit) is None:
                # a bit of a word or longword field (Rev 8.89 tests the byte
                # that holds it: `x & 1 <> 0' as btst #0 of its last byte)
                for o, sz in ((loc[2] - 3, 4), (loc[2] - 2, 4), (loc[2] - 1, 4), (loc[2], 4),
                              (loc[2] - 1, 2), (loc[2], 2)):
                    if o < 0 or not (o <= loc[2] < o + sz):
                        continue
                    try:
                        bexpr2, n, t = self.field(loc[1], o, sz)
                    except Unliftable:
                        continue
                    if t == 'bool':
                        continue
                    sh = 8 * (o + sz - 1 - loc[2]) + bit
                    return ('bin', '<>', ('bin', '&', self.sel(bexpr2, n), ('num', 1 << sh)),
                            ('num', 0))
        if loc[0] == 'abs' and loc[1] in GLOBAL_BITS:
            name, field, base = GLOBAL_BITS[loc[1]]
            return ('bin', 'in', ('num', base + bit), ('path', name, [field]))
        return super().bit_expr(loc, bit, x)

    def read_cell_loc(self, cell, loc):
        cell.loc = loc
        return cell

    def branch(self, k, st, out, stops):
        x = self.ins[k]
        comp = self.compound(k, st, out)
        if comp is None:
            y = self.ins[k + 1] if k + 1 < len(self.ins) else None
            if x.mn == 'bpl' and y is not None and y.mn == 'addq':
                # p2's branch: the signed division idiom
                self._branching = True
                return super().branch(k, st, out, stops)
            self._branching = False
            c = self.condition1(x, st)
            # `not c' falls through
            return self.arms(x, L1.negate(c), self.ins[k + 1].addr, x.target, st, out, stops)
        cond, t, f, written = comp
        for r in written:
            st.regs.pop(r, None)
        st.flags = None
        return self.arms(x, cond, t, f, st, out, stops)

    # ---- compound conditions: short-circuit `and' and `or'
    PURE_CMP = ('cmp', 'cmpi', 'cmpa', 'tst', 'btst')

    def pure_block(self, a, targets):
        """The instructions of a block at a that only computes a condition
        (register loads, compares, tests, set bytes and their algebra)
        and ends in a conditional branch: [index], or None."""
        if a not in self.at or a >= self.epilogue or a in self.writes:
            return None
        k = self.at[a]
        out = []
        while k < len(self.ins):
            y = self.ins[k]
            if y.addr >= self.epilogue or (out and y.addr in targets) or y.addr in self.writes:
                return None
            if y.target is not None:
                if y.mn in ('bra', 'dbf', 'bsr'):
                    return None
                out.append(k)
                return out
            last = y.ops[-1].strip() if y.ops else ''
            dreg = re.match(r'%[ad][0-7]$', last) is not None
            if y.mn in self.PURE_CMP:
                pass
            elif y.mn in ('move', 'movea', 'moveq', 'clr', 'lea', 'and', 'andi', 'or', 'ori',
                          'not', 'add', 'addq', 'sub', 'subq', 'eor') and dreg:
                if '%sp@' in y.text or (y.mn in ('move', 'movea') and '@+' in y.text):
                    return None
            elif y.mn in ('sne', 'seq', 'smi', 'spl', 'sgt', 'sge', 'slt', 'sle', 'shi', 'sls',
                          'scc', 'scs') and dreg:
                pass
            else:
                return None
            out.append(k)
            k += 1
        return None

    def compound(self, k, st, out):
        """(condition, true exit, false exit, registers written) of the
        short-circuit condition that begins with the branch at k, when
        it spans more than this branch; else None."""
        x = self.ins[k]
        if x.mn == 'bpl' and k + 2 < len(self.ins) and self.ins[k + 1].mn == 'addq':
            return None
        targets = set()
        preds = collections.defaultdict(set)
        for y in self.ins:
            if self.body <= y.addr < self.epilogue:
                for s_ in self.succ(self.at[y.addr]):
                    if s_ is not None:
                        preds[s_].add(y.addr)
                if y.target is not None:
                    targets.add(y.target)
        st0 = st.copy()
        self._branching = False
        c0 = self.condition1(x, st0)
        nodes = collections.OrderedDict()
        nodes[x.addr] = [c0, x.target, self.ins[k + 1].addr, {x.addr}]
        states = {x.target: st0, self.ins[k + 1].addr: st0}
        written = set()
        work = sorted({x.target, self.ins[k + 1].addr})
        done = set()
        while work:
            a = work.pop(0)
            if a in done or a in nodes or a <= x.addr:
                continue
            done.add(a)
            blk = self.pure_block(a, targets)
            if blk is None:
                continue
            # every predecessor must be a node of the region
            ps = preds[a]
            owners = set()
            for n in nodes.values():
                owners |= n[3]
            if not ps or not all(p in owners for p in ps):
                continue
            bst = states.get(a)
            if bst is None:
                continue
            bst = bst.copy()
            try:
                for j in blk[:-1]:
                    y = self.ins[j]
                    m = re.search(r',?%([ad][0-7])$', y.text)
                    if m:
                        written.add(m.group(1))
                    self.step(j, bst, out)
                c = self.condition1(self.ins[blk[-1]], bst)
            except Unliftable:
                continue
            y = self.ins[blk[-1]]
            nodes[a] = [c, y.target, self.ins[blk[-1] + 1].addr,
                        {self.ins[j].addr for j in blk}]
            for s_ in (y.target, self.ins[blk[-1] + 1].addr):
                if s_ in states and s_ not in nodes:
                    # a join: the registers both ways agree on
                    old = states[s_]
                    m_ = old.copy()
                    for r in sorted(set(old.regs) | set(bst.regs)):
                        if old.regs.get(r) is not bst.regs.get(r):
                            m_.regs.pop(r, None)
                    states[s_] = m_
                else:
                    states[s_] = bst
                work.append(s_)
            work.sort()
        while len(nodes) > 1:
            red = self.reduce(collections.OrderedDict((a, list(n)) for a, n in nodes.items()))
            if red is not None:
                c, t, f = red
                return c, t, f, sorted(written)
            # not one condition: the last block is a statement's (an exit)
            del nodes[max(nodes)]
        return None

    def reduce(self, nodes):
        """The region's nodes merged into one condition: (c, t, f) or None."""
        first = next(iter(nodes))
        # predecessors counted over the whole graph, by node entry
        changed = True
        while changed:
            changed = False
            for a in list(nodes):
                if a not in nodes:
                    continue
                c, t, f, _ = nodes[a]
                for y in (f, t):
                    refs = sum((n[1] == y) + (n[2] == y) for n in nodes.values())
                    if y not in nodes or y == a or refs != 1:
                        continue
                    cy, ty, fy, _ = nodes[y]
                    new = None
                    if y == f and ty == t:
                        new = (('bin', 'or', c, cy), t, fy)
                    elif y == f and fy == t:
                        new = (('bin', 'or', c, L1.negate(cy)), t, ty)
                    elif y == t and fy == f:
                        new = (('bin', 'and', c, cy), ty, f)
                    elif y == t and ty == f:
                        new = (('bin', 'and', c, L1.negate(cy)), fy, f)
                    if new:
                        nodes[a][0:3] = list(new)
                        del nodes[y]
                        for n in nodes.values():
                            if n[1] == y or n[2] == y:
                                raise Unliftable('0x%X: a condition block shared' % y)
                        changed = True
                        break
        if len(nodes) != 1:
            return None
        c, t, f, _ = nodes[first]
        return c, t, f

    def frame_live(self, a, off):
        """Whether the frame temporary at off is read at or after a before
        it is set."""
        seen, work = set(), [a]
        pat = '%%fp@(%d)' % off
        while work:
            a = work.pop()
            while a in self.at and a not in seen and a < self.epilogue:
                seen.add(a)
                x = self.ins[self.at[a]]
                if pat in x.text:
                    if x.ops and x.ops[-1].strip() == pat and x.mn in ('move', 'clr') and \
                            x.text.count(pat) == 1:
                        break
                    return True
                if x.mn == 'bra':
                    a = x.target
                    continue
                if x.target is not None:
                    work.append(x.target)
                a = self.ins[self.at[a] + 1].addr
        return False

    def arms(self, x, cond, t, f, st, out, stops):
        """`if cond then <t> else <f>' to the merge point (p2's branch)."""
        self.use(cond)
        m = self.merge_point(x.addr)
        stop2 = set(stops) | {m}
        self.bound += 1
        b_then, s_then, e1 = self.run(t, st.copy(), stop2)
        self.bound += 1
        b_else, s_else, e2 = self.run(f, st.copy(), stop2)
        self.bound += 1
        if e1 != e2:
            raise Unliftable('0x%X: the arms end at 0x%X and 0x%X' % (x.addr, e1, e2))
        newst = s_then.copy()
        for r in sorted(set(s_then.regs) | set(s_else.regs)):
            v1, v2 = s_then.regs.get(r), s_else.regs.get(r)
            if v1 is v2:
                continue
            if v1 is not None and v2 is not None and self.same(v1, v2):
                continue
            if v1 is None or v2 is None:
                newst.regs.pop(r, None)
                continue
            if self.live(e1, r):
                c = Cell(None, v1.typ if isinstance(v1, Cell) else 'int32', False, self.bound)
                c.need = True
                self.cells.append(c)
                c.phi = True
                c.mark = ['mark', c]
                out.append(c.mark)
                for body, v in ((b_then, v1), (b_else, v2)):
                    body.append(['phi', c, v])
                newst.regs[r] = c
            else:
                newst.regs.pop(r, None)
        # frame temporaries likewise (a value set on both arms)
        frame = dict(s_then.frame)
        for off in sorted(set(s_then.frame) | set(s_else.frame)):
            v1, v2 = s_then.frame.get(off), s_else.frame.get(off)
            if v1 is v2 or (v1 is not None and v2 is not None and self.same(v1, v2)):
                continue
            if v1 is None or v2 is None or not self.frame_live(e1, off):
                frame.pop(off, None)
                continue
            c = Cell(None, v1.typ if isinstance(v1, Cell) else 'int32', False, self.bound)
            c.need = True
            self.cells.append(c)
            c.phi = True
            c.mark = ['mark', c]
            out.append(c.mark)
            for body, v in ((b_then, v1), (b_else, v2)):
                body.append(['phi', c, v])
            frame[off] = c
        if P2.pending(s_then.stack) != P2.pending(s_else.stack):
            raise Unliftable('0x%X: the arms leave different stacks' % x.addr)
        out.append(('if', [(cond, b_then)], b_else))
        st.regs, st.stack, st.frame, st.flags = newst.regs, newst.stack, frame, None
        return e1

    def as_bool(self, v):
        """A boolean value's expression (a set byte, a boolean function's
        value, a boolean field), or None."""
        if isinstance(v, tuple) and v[0] == 'boolbyte':
            return v[1]
        if isinstance(v, Cell) and v.typ == 'bool':
            return ('cell', v)
        return None

    def condition(self, x, st):
        c = self.condition1(x, st)
        if getattr(self, '_branching', False):
            # a branch's condition reads its values once (a function's
            # value tested at once needs no temp)
            self._branching = False
            self.use(c)
        return c

    def condition1(self, x, st):
        f = st.flags
        cc = x.mn[1:]
        if f is not None and f[0] == 'boolflags':
            b = f[1][1]
            if cc in ('mi', 'ne'):
                return b
            if cc in ('pl', 'eq'):
                return L1.negate(b)
            raise Unliftable('0x%X: %s after a boolean byte' % (x.addr, x.mn))
        if f is not None and f[0] == 'tst' and self.is_bool(f[1]) and cc in ('pl', 'mi'):
            e = self.val(f[1])
            return e if cc == 'mi' else ('un', 'not', e)
        if f is not None and f[0] == 'tst' and f[2] == 1 and cc in ('pl', 'mi') and \
                not (isinstance(f[1], tuple) and f[1][0] == 'mem'):
            # bit 7 of a byte (the values are unsigned)
            e = self.val(f[1])
            return ('bin', '<>' if cc == 'mi' else '=', ('bin', '&', e, ('num', 128)), ('num', 0))
        return super().condition(x, st)

    def finish(self, stmts):
        out = super().finish(stmts)
        return out

    def fix(self, e, top=None):
        if isinstance(e, tuple) and e[0] == 'cost':
            return ('cost', e[1], e[2], self.fix(e[3]))
        return super().fix(e, top)

    def resolve(self, stmts):
        out = []
        for s in stmts:
            if isinstance(s, tuple) and s[0] == 'writeln':
                out.append(s)
                continue
            out.extend(super().resolve([s]))
        return out


# --------------------------------------------------------------------------
# the skeleton

class Skeleton(Exception):
    pass


def is_trace(s, text):
    """`if isc_user_routines_354 then writeln(text)'."""
    return (s[0] == 'if' and len(s[1]) == 1 and not s[2] and
            s[1][0][0] == ('path', TRACE, []) and s[1][0][1] == [('writeln', text)])


def guard_of(c):
    """The already_ flag a cycle guard's condition tests, or None:
    `subject.cNNN & 128 <> 0' (tst.b; bpl)."""
    if c[0] == 'bin' and c[1] == '<>' and c[3] == ('num', 0) and c[2][0] == 'bin' and \
            c[2][1] == '&' and c[2][3] == ('num', 128):
        p = c[2][2]
        if p[0] == 'path' and p[1] == 'subject' and len(p[2]) == 1:
            m = re.match(r'c(34[2-8])$', p[2][0])
            if m:
                return ALREADY[int(m.group(1)) - 342]
    return None


def rename(e, old, new):
    """e with the path base old renamed new."""
    if isinstance(e, tuple):
        if e[0] == 'path' and e[1] == old:
            return ('path', new, e[2])
        return tuple(rename(x, old, new) if isinstance(x, (tuple, list)) else x for x in e)
    if isinstance(e, list):
        return [rename(x, old, new) for x in e]
    return e


def traces(body):
    """`if isc_user_routines_354 then writeln(t)' as `trace t'."""
    out = []
    for s in body:
        if s[0] == 'if' and len(s[1]) == 1 and not s[2] and s[1][0][0] == ('path', TRACE, []) \
                and len(s[1][0][1]) == 1 and s[1][0][1][0][0] == 'writeln':
            out.append(('trace', s[1][0][1][0][1]))
            continue
        if s[0] == 'writeln':
            raise Skeleton('a write outside the trace')
        if s[0] == 'if':
            s = ('if', [(c, traces(b)) for c, b in s[1]], traces(s[2]) if s[2] is not None else None)
        elif s[0] == 'for':
            s = ('for', s[1], s[2], s[3], traces(s[4]))
        out.append(s)
    return out


def is_temp_set(s):
    return s[0] == 'set' and s[1][0] == 'path' and not s[1][2] and \
        re.match(r't\d+$', s[1][1]) is not None


def temps_only(s):
    """A statement that sets temps only (a temp's assignment, or an if
    whose arms set temps)."""
    if is_temp_set(s):
        return True
    if s[0] == 'if':
        return all(temps_only(x) for _, b in s[1] for x in b) and \
            all(temps_only(x) for x in (s[2] or []))
    return False


def abs_idiom(stmts):
    """`if x < 0 then t <- -x else t <- x' (Rev 8.89's abs) as `t <- abs(x)'."""
    out = []
    for s in stmts:
        if s[0] == 'if':
            if len(s[1]) == 1 and s[2] and len(s[2]) == 1 and len(s[1][0][1]) == 1:
                c, b = s[1][0]
                a, e = b[0], s[2][0]
                if c[0] == 'bin' and c[1] == '<' and c[3] == ('num', 0) and is_temp_set(a) and \
                        is_temp_set(e) and a[1] == e[1] and a[2] == ('un', '-', c[2]) and \
                        e[2] == c[2]:
                    out.append(('set', a[1], ('call', 'abs', [c[2]])))
                    continue
            s = ('if', [(c, abs_idiom(b)) for c, b in s[1]],
                 abs_idiom(s[2]) if s[2] is not None else None)
        elif s[0] == 'for':
            s = ('for', s[1], s[2], s[3], abs_idiom(s[4]))
        out.append(s)
    return out


def skeleton(stmts, rule, kind):
    flags, decls, body = skeleton1(abs_idiom(stmts), rule, kind)
    if flags['chain'] and flags['chain'][-1][0] != 'condition':
        raise Skeleton('statements before the trace after the last condition')
    return flags, decls, traces(body)


def skeleton1(stmts, rule, kind):
    """The clause of a lifted action: (flags, body), flags a dict:
    rewrite (a proper_subtree rule), conditions [expr], guard (an
    already_ name) and trace (False for an action without one)."""
    decls = [s for s in stmts if s[0] == 'temp']
    body = [s for s in stmts if s[0] != 'temp']
    flags = {'chain': [], 'guard': None, 'rewrite': False, 'trace': True}
    if body[:2] != [('set', ('path', '@result', []), ('nil',)),
                    ('set', ('path', '@work', []), ('nil',))]:
        raise Skeleton('no `result := nil; work := nil\'')
    rest = body[2:]
    # the conditions: ifs with no else around the rest, up to the trace
    while rest and not is_trace(rest[0], MATCHED % rule):
        if len(rest) == 1 and rest[0][0] == 'if' and len(rest[0][1]) == 1 and not rest[0][2]:
            flags['chain'].append(('condition', rest[0][1][0][0]))
            rest = rest[0][1][0][1]
            continue
        if temps_only(rest[0]):
            # temps set before the conditions
            flags['chain'].append(rest[0])
            rest = rest[1:]
            continue
        break
    if not rest:
        # no trace and no body: a condition whose arm Rev 8.89 dropped
        raise Skeleton('no trace')
    if not is_trace(rest[0], MATCHED % rule):
        raise Skeleton('no trace where the body begins')
    rest = rest[1:]
    if kind == 'proper_subtree':
        if not rest or rest[0] != ('set', ('path', '@result', []), ('path', 'subject', [])):
            raise Skeleton('a proper_subtree rule without `result := subject\'')
        flags['rewrite'] = True
        body = rest[1:]
        for s in L.walk(body):
            if s[0] == 'set' and s[1][0] == 'path' and s[1][1].startswith('@'):
                raise Skeleton('work or result set in the body')
        return flags, decls, body
    # the cycle guard
    if len(rest) == 1 and rest[0][0] == 'if' and len(rest[0][1]) == 1:
        g = guard_of(rest[0][1][0][0])
        if g is not None:
            arm = rest[0][1][0][1]
            if arm != [('if', [(('path', TRACE, []), [('writeln', CYCLE)])], None)]:
                raise Skeleton('a cycle guard without its trace')
            flags['guard'] = g
            rest = rest[0][2] or []
    # the new solution
    if len(rest) < 3:
        raise Skeleton('no new solution')
    s0 = rest[0]
    if not (s0[0] == 'set' and s0[1][0] == 'path' and not s0[1][2] and s0[2][0] == 'call' and
            s0[2][1] == 'new_solution'):
        raise Skeleton('the body does not begin with new_solution')
    t = s0[1][1]
    want = [('path', 'isc_heap', []), ('num', L1.KINDS.index(kind)), ('num', 0),
            ('path', 'inh', []), ('path', 'il', []), ('num', 0)]
    if s0[2][2] != want:
        raise Skeleton('new_solution%s' % L.fmt_expr(('call', '', s0[2][2])))
    if rest[1] != ('set', ('path', t, ['which_transform']), ('num', rule)):
        raise Skeleton('no which_transform')
    if rest[2] != ('set', ('path', t, ['before_transform']), ('path', 'subject', [])):
        raise Skeleton('no before_transform')
    tail = [('set', ('path', t, ['c%d' % (342 + k)]), ('path', 'subject', ['c%d' % (342 + k)]))
            for k in range(7)]
    if flags['guard']:
        tail.append(('set', ('path', t, ['c%d' % (342 + ALREADY.index(flags['guard']))]),
                     ('bool', True)))
    tail += [('set', ('path', '@work', []), ('path', t, [])),
             ('set', ('path', '@result', []), ('path', t, []))]
    if rest[-len(tail):] != tail:
        raise Skeleton('the end is not the already_ copies and work, result')
    body = rest[3:-len(tail)]
    for s in L.walk(body):
        if s[0] == 'set' and s[1][0] == 'path' and s[1][1].startswith('@'):
            raise Skeleton('work or result set in the body')
    decls = [d for d in decls if d[1] != t]
    body = rename(body, t, 'result')
    for s in L.walk(body):
        if s[0] == 'set' and s[1] == ('path', 'result', []):
            raise Skeleton('the new solution reassigned')
    return flags, decls, body


# --------------------------------------------------------------------------

class Image:
    def __init__(self, binary, im=None, sections=None):
        import cc_isc_inventory as inv
        self.inv = im or inv.Image(binary)
        self.p1 = self.inv.action_table(P1_A5)
        self.starts = sorted(set(self.p1))
        self.sections = sections or sections_of(self.inv, self.p1)
        self.a5s = sorted(s['p1_a5'] for s in self.sections) + [P2.P2_A5]
        self.binary = binary
        self.dimg = None

    def read(self, a, n):
        return self.inv.read(a, n)

    def data(self, a, n):
        """The initial bytes at a (None where nothing sets one)."""
        if self.dimg is None:
            import cc_datacheck
            self.dimg = cc_datacheck.Image(self.binary)
        return self.dimg.read(a, n)

    def range_of(self, r):
        va = self.p1[r - 1]
        i = bisect.bisect_right(self.starts, va)
        return va, (self.starts[i] if i < len(self.starts) else P1_END)

    def data_of(self, a5):
        """The module's data block: A5 .. the next module's A5 - 4."""
        return a5, self.a5s[self.a5s.index(a5) + 1] - 4


def sections_of(im, p1):
    """[{number, rules, p1_a5}] by A5, in address order."""
    a5 = {}
    for r in range(1, len(p1) + 1):
        d = im.read(p1[r - 1], 16)
        i = d.find(b'\x4b\xf9')
        a5[r] = int.from_bytes(d[i + 2:i + 6], 'big')
    order = sorted(set(a5.values()), key=lambda x: min(p1[r - 1] for r in a5 if a5[r] == x))
    return [{'number': k + 1, 'p1_a5': x, 'rules': sorted(r for r in a5 if a5[r] == x)}
            for k, x in enumerate(order)]


_HEADINGS = None


def headings():
    global _HEADINGS
    if _HEADINGS is None:
        import iscg_gen
        _HEADINGS = L.read_headings(iscg_gen.INCLUDES)
    return _HEADINGS


def lift_rule(img, r, kind):
    """The lifted clause of rule r's pass-1 action: (clause, None) or
    (None, reason); clause = (flags, decls, body, tables)."""
    va, end = img.range_of(r)
    a5 = None
    for s in img.sections:
        if r in s['rules']:
            a5 = s['p1_a5']
    lo, hi = img.data_of(a5)
    try:
        lf = Lifter(img, r, va, end, headings(), img.inv.names, lo, hi)
        stmts = lf.lift()
        flags, decls, body = skeleton(stmts, r, kind)
        body = L1.macros(body, 'subject' if flags['rewrite'] else 'result')
        clause = L1.Clause(r, flags, decls, body)
        # the tables' layout: the reverse of their order in the body
        order = L1.cost_order(clause)
        offs = sorted(lf.tables)
        if len(order) != len(offs):
            raise Unliftable('%d tables read, %d in the body' % (len(offs), len(order)))
        # the printer and the parser must agree
        text = '\n'.join(L1.fmt_clause_body(clause))
        back = L1.parse_clause_body(text, r, flags['rewrite'])
        if back.key() != clause.key():
            raise Unliftable('the printed clause does not read back')
        clause.offsets = offs
        clause.reversed_ok = [lf.tables[o][1][1:] for o in offs] == [
            list(v) + [0] * (16 - len(v)) for _, v in reversed(order)] and \
            [lf.tables[o][0] for o in offs] == [k for k, _ in reversed(order)]
        if not clause.reversed_ok:
            raise Unliftable('the cost tables are not laid out in the reverse of the clause')
        # the generator must be able to write it
        import iscg_p1gen
        L1.check_emit(clause, kind, headings(), iscg_p1gen)
        return clause, None
    except Unliftable as e:
        return None, str(e)
    except Skeleton as e:
        return None, 'skeleton: %s' % e
    except L.LangError as e:
        return None, 'language: %s' % e


def main():
    import cc_isc_inventory as inv
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('rules', nargs='*', type=int)
    ap.add_argument('--binary', default=inv.DEFAULT_BINARY)
    ap.add_argument('--stats', action='store_true')
    ap.add_argument('--section', type=int)
    ap.add_argument('--raw', action='store_true', help='the lifted statements, no skeleton')
    a = ap.parse_args()
    img = Image(a.binary)
    kinds = inv.tool_tables(img.inv, len(img.p1))[0]
    rules = a.rules or list(range(1, len(img.p1) + 1))
    if a.section:
        rules = [s for s in img.sections if s['number'] == a.section][0]['rules']
    why = collections.Counter()
    ok = 0
    for r in rules:
        if a.raw:
            va, end = img.range_of(r)
            a5 = [sc['p1_a5'] for sc in img.sections if r in sc['rules']][0]
            lo, hi = img.data_of(a5)
            lf = Lifter(img, r, va, end, headings(), img.inv.names, lo, hi)
            for s in lf.lift():
                print('\n'.join(L1.fmt_stmt(s, '  ')) if s[0] != 'writeln' else '  writeln %r' % s[1])
            continue
        clause, reason = lift_rule(img, r, inv.SOLUTION_KINDS[kinds[r - 1]])
        if a.stats:
            if clause is None:
                why[re.sub(r'rule \d+: ', '', re.sub(r'0x[0-9A-F]+: ', '', reason))[:70]] += 1
            else:
                ok += 1
                if not clause.reversed_ok:
                    why['(tables not in reverse order)'] += 1
            continue
        print('{ rule %d }' % r)
        if clause is None:
            print('  residue: %s' % reason)
        else:
            print('\n'.join(L1.fmt_clause_body(clause)))
            if not clause.reversed_ok:
                print('  { tables not in reverse order }')
    if a.stats:
        print('%d of %d lifted' % (ok, len(rules)))
        for k, v in why.most_common(50):
            print('%5d  %s' % (v, k))


if __name__ == '__main__':
    main()
