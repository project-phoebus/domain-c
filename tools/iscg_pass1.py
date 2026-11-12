"""iscg_pass1.py - isc_pass_1_main's operator routines: lifted from the
image (tools/iscg_extract.py) and emitted from the rule file
(tools/iscg_gen.py).

isc_pass_1_main (docs/iscg-design.md 2.1, 10) has one routine per IL
node kind, tree operator, comparison and assignment operator the ISC
handles, isc_<kind>[_<op>].  Each is called by pass_1 (through the
tables isc_pass_1_begin_compilation fills) with the node, its inherited
attributes, the depth and the permissible kinds, and returns the il$t
of the node's proper_subtree, its number of children and each child's
solutions: for child k a new record of inherited attributes (the
default ones copied from the node's, then the operator's own), the
permissible kinds of that position (a constant, maybe less
not_permissible_function's, or the node's own) and a call of pass_1;
a child without solutions ends the routine (no_solutions).

The rule file's operator declarations (declarations.isc) say this:

  operator isc_tree_node_add_top il add_top children 2
    child 1 il.p40 permissible [address_mode, ip_reg, ...] -np
      fetch_precision <- isc_$precision_from_rlen_and_size(il.w24, -1);
      required_arithmetic <- rlen_arith(il.w24);
    child 2 il.p44 ...
  end;

`child K NODE' makes inherited attributes for NODE (copying the default
ones from inh: call_instruction_ptr, exception_frame, fetch_precision,
inside_a_cse, original_il, required_arithmetic, required_precision,
source_line_number and stmt_number, in that alphabetical order), runs
the statements, and calls pass_1 for NODE with them, storing the list as
child K's; `permissible derived' is the union of the kinds the patterns
test at position K (the matcher's), `inherited' the routine's own;
`-np' removes not_permissible_function(il, K, permissible).  The
statements' left sides are inherited attribute names (isc_debug's,
docs/questions.md 271); the right sides are expressions over il (the
node: il.wN, il.lN, il.pN, il.bN the word, longword, pointer, byte at
+N), inh.<attribute> (the node's own inherited attributes), constants
and calls.  A routine the lifter does not understand whole is the
generator's fixed text (tools/iscg_text.py P1_ROUTINES) or, until it
is written, a TODO of the unit's header.
"""
import re

# inherited_attributes_t: the image's names (isc_print_il_node's), offset,
# size (1 byte, 2 word, 4 longword; 'bN' a bit of +39) and the field of
# isc_attribute_records.ins.pas they are written through.
INH_ATTRS = [
    ('il', 0, 4, 'node'),
    ('exception_frame', 4, 4, 'top'),
    ('original_il', 12, 4, 'stmt'),
    ('conditional_target', 16, 4, 'l16'),
    ('call_instruction_ptr', 20, 4, 'call'),
    ('fetch_precision', 24, 4, 'precision'),
    ('required_precision', 28, 4, 'available'),
    ('source_line_number', 32, 2, 'pos.line'),
    ('stmt_number', 34, 2, 'pos.stmt'),
    ('parent_il_kind', 36, 1, 'b36'),
    ('required_arithmetic', 38, 1, 'f38.arith'),
    ('conditional_sense', 39, 'b7', 'f38.b7'),
    ('immediate_parent_has_signed', 39, 'b6', 'f38.b6'),
    ('immediate_parent_wants_lvalue', 39, 'b5', 'f38.b5'),
    ('immediate_parent_wants_set_temporary', 39, 'b4', 'f38.b4'),
    ('immediate_parent_wants_signed', 39, 'b3', 'f38.b3'),
    ('inside_a_cse', 39, 'b2', 'f38.preserve'),
]
INH_BY_OFF = {}
for _n, _o, _s, _f in INH_ATTRS:
    INH_BY_OFF[(_o, _s)] = _n
INH_FIELD = {n: f for n, o, s, f in INH_ATTRS}
POINTER_ATTRS = ('il', 'exception_frame', 'original_il', 'conditional_target',
                 'call_instruction_ptr')

# the copy every child's attributes start with (alphabetical)
DEFAULT_COPY = ['call_instruction_ptr', 'exception_frame', 'fetch_precision', 'inside_a_cse',
                'original_il', 'required_arithmetic', 'required_precision',
                'source_line_number', 'stmt_number']

HEAP = 0x48103C           # isc_user_routines +0x23C: the ISC heap
PRESERVE_HEAP = 0x481024  # +0x224: the preserved heap (rewritten nodes)
READONLY = 0x2BCDFC       # isc_readonly_tables
TRACE_354 = 0x481154
TRACE_356 = 0x481156
REWRITE_TRACE = ['*********************', 'R E W R I T E ! ! ! !', '*********************']


class NotLifted(Exception):
    pass


# --------------------------------------------------------------------------
# lifting (from the image)

def _strip(t):
    return t.split(';')[0].strip()


class Lifter:
    """Straight-line symbolic reading of an operator routine: the standard
    prologue, then child blocks and simple calls.  Anything else raises
    NotLifted (the routine is fixed text)."""

    def __init__(self, ins, names, pass1, read=None):
        self.read = read              # (address, length) -> the image's text
        self.ins = [(a, _strip(t), t) for a, n, t, h in ins]
        self.names = names            # address -> routine name
        self.pass1 = pass1

    def fail(self, k, why):
        a, t, _ = self.ins[k] if k < len(self.ins) else (0, '', '')
        raise NotLifted('0x%X %s: %s' % (a, t, why))

    def lift(self):
        regs = {}
        k = 0
        ins = self.ins
        # prologue: link, saves, A5, parameter loads
        while k < len(ins):
            t = ins[k][1]
            if t.startswith(('linkw', 'moveml %d', 'moveml %a', 'pea %a5@', 'pea %a3@',
                             'pea %a2@', 'pea %a4@', 'lea 0x44ebe8,%a5')) or \
                    re.match(r'movel %d\d,%sp@-$', t):
                k += 1
                continue
            m = re.match(r'movea?[lw] %fp@\((\d+)\),%([ad]\d)$', t)
            if m:
                regs[m.group(2)] = ('param', int(m.group(1)))
                k += 1
                continue
            m = re.match(r'movea?l %([ad]\d),%([ad]\d)$', t)
            if m and m.group(1) in regs:
                regs[m.group(2)] = regs[m.group(1)]
                k += 1
                continue
            break
        self.k = k
        self.regs = regs
        flags = {}
        # the four outputs
        while len(flags) < 4:
            t = ins[self.k][1]
            m = re.match(r'clrb %(a\d)@$', t)
            if m and regs.get(m.group(1), ('',))[0] == 'param':
                flags[regs[m.group(1)][1]] = 0
                self.k += 1
                continue
            m = re.match(r'movew #(\d+),%(a\d)@$', t)
            if m and regs.get(m.group(2)) == ('param', 22):
                flags[22] = int(m.group(1))
                self.k += 1
                continue
            m = re.match(r'clrl %(a\d)@$', t)
            if m and regs.get(m.group(2 - 1)) == ('param', 26):
                flags[26] = 0
                self.k += 1
                continue
            m = re.match(r'moveq #(\d+),%(d\d)$', t)
            if m:
                regs[m.group(2)] = ('const', int(m.group(1)))
                self.k += 1
                continue
            m = re.match(r'movel %(d\d),%(a\d)@$', t)
            if m and regs.get(m.group(2)) == ('param', 26) and regs.get(m.group(1), ('',))[0] == 'const':
                flags[26] = regs[m.group(1)][1]
                self.k += 1
                continue
            m = re.match(r'movea?l %([ad]\d),%([ad]\d)$', t)
            if m and m.group(1) in regs:
                regs[m.group(2)] = regs[m.group(1)]
                self.k += 1
                continue
            m = re.match(r'movea?[lw] %fp@\((\d+)\),%([ad]\d)$', t)
            if m:
                regs[m.group(2)] = ('param', int(m.group(1)))
                self.k += 1
                continue
            self.fail(self.k, 'prologue')
        if set(flags) != {38, 42, 22, 26} or flags[38] or flags[42]:
            self.fail(self.k, 'prologue outputs %s' % flags)
        self.w98, self.nchildren = flags[22], flags[26]
        self.locals = {}
        self.body = []
        self.children = []
        self.read_body()
        return {'w98': self.w98, 'nchildren': self.nchildren, 'body': self.body}

    # ---- expressions
    def val(self, src, size):
        """The value of an operand as an expression string."""
        regs = self.regs
        m = re.match(r'#(-?\d+)$', src)
        if m:
            return str(int(m.group(1)))
        m = re.match(r'%([ad]\d)$', src)
        if m:
            v = regs.get(m.group(1))
            if v is None:
                raise NotLifted('register %s unknown' % src)
            return self.render(v)
        m = re.match(r'0x([0-9a-f]+)$', src)
        if m:
            a = int(m.group(1), 16)
            if size == 1 and READONLY + 321 <= a < READONLY + 321 + 52 and (a - READONLY - 321) % 2 == 0:
                return 'rlen_arith(%d)' % ((a - READONLY - 321) // 2)
            raise NotLifted('absolute operand %s' % src)
        m = re.match(r'%fp@\((-?\d+)\)$', src)
        if m:
            off = int(m.group(1))
            if off > 0:
                return self.render(('param', off))
            if off in self.locals:
                return self.render(self.locals[off])
            raise NotLifted('local %d unknown' % off)
        m = re.match(r'%(a\d)@\((\d+)\)$', src) or re.match(r'%(a\d)@()$', src)
        if m:
            base = regs.get(m.group(1))
            off = int(m.group(2) or 0)
            return self.field(base, off, size)
        raise NotLifted('operand %s' % src)

    def field(self, base, off, size):
        if base == ('param', 8):
            return 'il.%s%d' % ({4: 'l', 2: 'w', 1: 'b'}[size], off)
        if base == ('param', 12):
            n = INH_BY_OFF.get((off, size))
            if n is None:
                raise NotLifted('inh +%d size %d' % (off, size))
            return 'inh.' + n
        if base and base[0] == 'field':     # a node's field's field
            return '%s.%s%d' % (re.sub(r'\.l(\d+)$', r'.p\1', self.render(base)),
                                {4: 'l', 2: 'w', 1: 'b'}[size], off)
        raise NotLifted('field of %s' % (base,))

    def render(self, v):
        if v[0] == 'param':
            return {8: 'il', 12: 'inh', 16: 'depth', 18: 'permissible'}.get(v[1], 'param%d' % v[1])
        if v[0] == 'const':
            return str(v[1])
        if v[0] in ('expr', 'field'):
            return v[1]
        if v[0] == 'newinh':
            return 'inh_%d' % v[1]
        if v[0] == 'callres':
            self.low_ref[v[1]][2] = True
            return 'n%d' % v[1]
        raise NotLifted('value %s' % (v,))

    # ---- the body
    def read_body(self):
        """Statements to the epilogue: low-level ones first (stores, calls,
        child-list stores, empty tests), then grouped into child blocks."""
        ins = self.ins
        regs = self.regs
        stack = []
        low = []          # ('store', target, value) | ['call', text, used]
        #                   | ('list', k) | ('empty', ...) | ('trace',) | ('made',) ...
        self.low_ref = low
        ninh = 0
        k = self.k
        end = None
        saved = {}        # an else part's address -> the registers at its test
        while k < len(ins):
            t = ins[k][1]
            if ins[k][0] in saved:
                regs.clear()
                regs.update(saved.pop(ins[k][0]))
            if t.startswith(('moveml %fp@', 'unlk')) or re.match(r'movea?l %fp@\(-\d+\),%[ad]\d$', t) \
                    and ins[min(k + 1, len(ins) - 1)][1].startswith(('movea', 'unlk', 'moveml')) \
                    and any(x[1].startswith('unlk') for x in ins[k:k + 4]):
                end = k
                break
            m = re.match(r'moveb 0x%x,%%(d\d)$' % TRACE_356, t)
            if m and ins[k + 1][1] == 'orb 0x%x,%%%s' % (TRACE_354, m.group(1)):
                mb = re.match(r'bpl[sw]? 0x([0-9a-f]+)$', ins[k + 2][1])
                if not mb:
                    self.fail(k, 'trace')
                tgt = int(mb.group(1), 16)
                strs = []
                j = k + 3
                while ins[j][0] != tgt:
                    u = ins[j][1]
                    mm = re.match(r'pea %pc@\(0x([0-9a-f]+)\)$', u)
                    if mm:
                        strs.append(int(mm.group(1), 16))
                    elif not re.match(r'(movew #\d+,%sp@-|movel %a5@\(-4\),%sp@-|jsr 0x4930(d2|cc)'
                                      r'|lea %sp@\(12\),%sp|addqw #4,%sp)$', u):
                        self.fail(j, 'in the trace')
                    j += 1
                if self.read is None or [self.read(a, 21) for a in strs] != REWRITE_TRACE:
                    self.fail(k, 'not the REWRITE trace')
                low.append(('trace',))
                k = j
                continue
            m = re.match(r'movea?l %([ad]\d),%([ad]\d)$', t)
            if m:
                if m.group(1) not in regs:
                    self.fail(k, 'copy of an unknown register')
                regs[m.group(2)] = regs[m.group(1)]
                k += 1
                continue
            m = re.match(r'movea?[lw] %fp@\((\d+)\),%([ad]\d)$', t)
            if m:
                regs[m.group(2)] = ('param', int(m.group(1)))
                k += 1
                continue
            m = re.match(r'movea?l %fp@\((-\d+)\),%([ad]\d)$', t)
            if m:
                off = int(m.group(1))
                if off not in self.locals:
                    self.fail(k, 'local unknown')
                regs[m.group(2)] = self.locals[off]
                k += 1
                continue
            m = re.match(r'(?:moveq|movel) #(-?\d+),%(d\d)$', t)
            if m:
                regs[m.group(2)] = ('const', int(m.group(1)))
                k += 1
                continue
            m = re.match(r'moveal #(\d+),%(a\d)$', t)
            if m:
                regs[m.group(2)] = ('abs', int(m.group(1)))
                k += 1
                continue
            m = re.match(r'movel #(-?\d+),%fp@\((-\d+)\)$', t)
            if m:
                self.locals[int(m.group(2))] = ('const', int(m.group(1)))
                k += 1
                continue
            m = re.match(r'movel %([ad]\d),%fp@\((-\d+)\)$', t)
            if m:
                self.locals[int(m.group(2))] = regs[m.group(1)]
                k += 1
                continue
            m = re.match(r'movea?l %(a\d)@\((\d+)\),%([ad]\d)$', t)
            if m and regs.get(m.group(1)) == ('param', 8):
                regs[m.group(3)] = ('field', 'il.%s%d' % ('p' if m.group(3)[0] == 'a' else 'l',
                                                          int(m.group(2))))
                k += 1
                continue
            m = re.match(r'move([lwb]) %(a\d)@\((\d+)\),%(d\d)$', t)
            if m and regs.get(m.group(2)) is not None:
                size = {'l': 4, 'w': 2, 'b': 1}[m.group(1)]
                regs[m.group(4)] = ('field', self.field(regs[m.group(2)], int(m.group(3)), size))
                k += 1
                continue
            m = re.match(r'lsll #(\d),%(d\d)$', t)
            if m and m.group(2) in regs:
                regs[m.group(2)] = ('expr', '%s * %d' % (self.render(regs[m.group(2)]),
                                                         1 << int(m.group(1))))
                k += 1
                continue
            # depth + 1
            m = re.match(r'movew %(d\d),%(d\d)$', t)
            if m and regs.get(m.group(1)) == ('param', 16) and \
                    ins[k + 1][1] == 'addqw #1,%%%s' % m.group(2):
                regs[m.group(2)] = ('expr', 'depth + 1')
                k += 2
                continue
            if t == 'subql #2,%sp':
                k += 1
                continue
            m = re.match(r'(?:addqw|addql) #(\d),%sp$', t) or re.match(r'lea %sp@\((\d+)\),%sp$', t)
            if m:
                stack = []
                k += 1
                continue
            m = re.match(r'movel #(-?\d+),%sp@-$', t)
            if m:
                v = int(m.group(1))
                stack.append('heap' if v == HEAP else
                             'isc_preserve_heap' if v == PRESERVE_HEAP else str(v))
                k += 1
                continue
            m = re.match(r'pea 0xffffffff$', t)
            if m:
                stack.append('-1')
                k += 1
                continue
            m = re.match(r'pea (\d+)$', t) or re.match(r'pea 0x([0-9a-f]+)$', t)
            if m:
                stack.append(str(int(m.group(1), 16 if 'x' in t else 10)))
                k += 1
                continue
            m = re.match(r'movew #(-?\d+),%sp@-$', t)
            if m:
                stack.append(m.group(1))
                k += 1
                continue
            if t in ('clrw %sp@-', 'clrl %sp@-'):
                stack.append('0')
                k += 1
                continue
            m = re.match(r'move([wl]) (.*),%sp@-$', t)
            if m:
                stack.append(self.val(m.group(2), 4 if m.group(1) == 'l' else 2))
                k += 1
                continue
            m = re.match(r'pea %(a\d)@$', t)
            if m:
                v = regs.get(m.group(1))
                if v is None:
                    self.fail(k, 'pea of an unknown register')
                stack.append(self.render(v))
                k += 1
                continue
            m = re.match(r'(?:jsr|bsrw) 0x([0-9a-f]+)$', t)
            if m:
                a = int(m.group(1), 16)
                name = self.names.get(a)
                if not name:
                    self.fail(k, 'call of an unknown routine')
                args = list(reversed(stack))
                stack = []
                if name == 'new_inherited_attributes':
                    if len(args) != 2 or args[0] != 'heap':
                        self.fail(k, 'new_inherited_attributes(%s)' % args)
                    ninh += 1
                    regs['a0'] = ('newinh', ninh, args[1])
                    low.append(('newinh', ninh, args[1]))
                elif name == 'pass_1':
                    regs['a0'] = ('expr', 'pass_1(%s)' % ', '.join(args))
                    low.append(('pass_1', args))
                elif name == 'solution_list$empty':
                    # the empty test of the list just stored
                    if ins[k + 2][1] != 'tstb %d0' or not re.match(r'b(mi|pl)[sw]? ', ins[k + 3][1]):
                        self.fail(k, 'empty test')
                    low.append(('empty', ins[k + 3][1], ins[k + 4][0] if k + 4 < len(ins) else None))
                    k += 4
                    continue
                elif name in ('isc_$precision_from_rlen_and_size', 'not_permissible_function',
                              'il_node_has_integer_value'):
                    regs['d0'] = ('expr', '%s(%s)' % (name, ', '.join(args)))
                else:
                    low.append(['call', '%s(%s)' % (name, ', '.join(args)), False, len(low)])
                    regs['d0'] = regs['a0'] = ('callres', len(low) - 1)
                k += 1
                continue
            m = re.match(r'moveb %d0,%fp@\((-\d+)\)$', t)
            if m and regs.get('d0'):
                self.locals[int(m.group(1))] = regs['d0']
                k += 1
                continue
            if t == 'notb %d0':
                m1 = re.match(r'andb %fp@\((-\d+)\),%d0$', ins[k + 1][1])
                m2 = re.match(r'bpl[sw]? 0x([0-9a-f]+)$', ins[k + 2][1])
                if m1 and m2 and int(m1.group(1)) in self.locals:
                    cond = '%s and not %s' % (self.render(self.locals[int(m1.group(1))]),
                                              self.render(regs['d0']))
                    low.append(('if', cond, int(m2.group(1), 16)))
                    saved[int(m2.group(1), 16)] = dict(regs)
                    k += 3
                    continue
                self.fail(k, 'a condition')
            m = re.match(r'bra[sw]? 0x([0-9a-f]+)$', t)
            if m:
                low.append(('bra', int(m.group(1), 16), ins[k][0]))
                saved.setdefault(int(m.group(1), 16), dict(regs))
                k += 1
                continue
            m = re.match(r'notl %d0$', t)
            if m and re.match(r'andl %d0,%(d\d)$', ins[k + 1][1]):
                d = re.match(r'andl %d0,%(d\d)$', ins[k + 1][1]).group(1)
                np = regs['d0'][1]
                regs[d] = ('expr', '%s -np' % self.render(regs[d]))
                low.append(('np', np))
                k += 2
                continue
            if t == 'notl %d0' and ins[k + 1][1] == 'subql #2,%sp' and \
                    re.match(r'andl %d0,%(d\d)$', ins[k + 2][1]):
                d = re.match(r'andl %d0,%(d\d)$', ins[k + 2][1]).group(1)
                np = regs['d0'][1]
                regs[d] = ('expr', '%s -np' % self.render(regs[d]))
                low.append(('np', np))
                k += 3
                continue
            # the default inherited attributes' bit (inside_a_cse) and other
            # bit copies: btst #b,X; sne R; clrl R2; lsrb #7,R; lslb #c,R;
            # orb R,R2; andib #m,Y; orb R2,Y
            m = re.match(r'btst #(\d),(.*)$', t)
            if m and k + 7 < len(ins):
                seq = [ins[k + j][1] for j in range(1, 8)]
                m1 = re.match(r'sne %(d\d)$', seq[0])
                m2 = re.match(r'clrl %(d\d)$', seq[1])
                m4 = re.match(r'lslb #(\d),', seq[3])
                m6 = re.match(r'andib #(-?\d+),(.*)$', seq[5])
                m7 = re.match(r'orb %d\d,(.*)$', seq[6])
                if m1 and m2 and seq[2].startswith('lsrb #7') and m4 and m6 and m7:
                    if re.match(r'%d\d$', m.group(2)):
                        src = self.bit_operand_reg(m.group(2)[1:], int(m.group(1)))
                    else:
                        src = self.bit_operand(m.group(2), int(m.group(1)))
                    dst = self.bit_target(m6.group(2), int(m4.group(1)))
                    low.append(('store', dst, src) if dst[0] == 'inh' else ('nstore', dst[1], src))
                    k += 8
                    continue
            m = re.match(r'b(set|clr) #(\d),(.*)$', t)
            if m:
                dst = self.bit_target(m.group(3), int(m.group(2)))
                low.append(('store', dst, 'true' if m.group(1) == 'set' else 'false'))
                k += 1
                continue
            # the whole record copied: moveq #4,R; movel a@+,b@+ (2); dbf
            m = re.match(r'movel %(a\d)@\+,%(a\d)@\+$', t)
            if m and ins[k - 1][1].startswith('moveq #4,') and ins[k + 1][1] == t and \
                    ins[k + 2][1].startswith('dbf'):
                src, dst = regs.get(m.group(1)), regs.get(m.group(2))
                if src != ('param', 12) or not dst or dst[0] != 'newinh':
                    self.fail(k, 'record copy')
                low.append(('copy_all', dst[1]))
                k += 3
                continue
            # required_precision and source_line_number in one: lea X@(28),A;
            # movel A@+,Y@(28); movel A@,Y@(32)
            m = re.match(r'lea %(a\d)@\(28\),%(a\d)$', t)
            if m and regs.get(m.group(1)) == ('param', 12):
                m1 = re.match(r'movel %(a\d)@\+,%(a\d)@\(28\)$', ins[k + 1][1])
                m2 = re.match(r'movel %(a\d)@,%(a\d)@\(32\)$', ins[k + 2][1])
                if not (m1 and m2):
                    self.fail(k, 'the copy of +28')
                dst = regs.get(m1.group(2))
                if not dst or dst[0] != 'newinh':
                    self.fail(k, 'the copy of +28')
                for n in ('required_precision', 'source_line_number', 'stmt_number'):
                    low.append(('store', ('inh', dst[1], n), 'inh.' + n))
                k += 3
                continue
            # rlen_arith: (moveal #READONLY,A); movew X,D; addw D,D;
            # lea A@(0,D:w),A; moveb A@(321),Y@(38)
            m = re.match(r'addw %(d\d),%(d\d)$', t)
            if m and m.group(1) == m.group(2) and regs.get(m.group(1), ('',))[0] == 'field':
                d = m.group(1)
                m3 = re.match(r'lea %(a\d)@\(0x0,%' + d + r':w\),%(a\d)$', ins[k + 1][1])
                m4 = re.match(r'moveb %(a\d)@\(321\),%(a\d)@\(38\)$', ins[k + 2][1])
                if m3 and m4 and regs.get(m3.group(1)) == ('abs', READONLY) and \
                        m4.group(1) == m3.group(2):
                    dst = regs.get(m4.group(2))
                    if not dst or dst[0] != 'newinh':
                        self.fail(k, 'rlen_arith target')
                    low.append(('store', ('inh', dst[1], 'required_arithmetic'),
                                'rlen_arith(%s)' % regs[d][1]))
                    k += 3
                    continue
                self.fail(k, 'readonly table')
            # stores
            m = re.match(r'move([lwb]) (.*),%(a\d)@(?:\((\d+)\))?$', t)
            if m:
                size = {'l': 4, 'w': 2, 'b': 1}[m.group(1)]
                base = regs.get(m.group(3))
                off = int(m.group(4) or 0)
                src = m.group(2)
                if base and base[0] == 'newinh':
                    n = INH_BY_OFF.get((off, size))
                    if n is None:
                        self.fail(k, 'inh field +%d' % off)
                    low.append(('store', ('inh', base[1], n), self.val(src, size)))
                    k += 1
                    continue
                if base and base[0] == 'callres':
                    fld = {4: 'p' if src.startswith('%a') or '@' in src else 'l',
                           2: 'w', 1: 'b'}[size]
                    v = self.val(src, size)
                    if fld == 'p':
                        v = re.sub(r'^il\.l(\d+)$', r'il.p\1', v)
                    low.append(('nstore', '%s.%s%d' % (self.render(base), fld, off), v))
                    k += 1
                    continue
                if base == ('param', 30) and size == 4 and src == '%a0' and off == 0:
                    low.append(('list', 0))
                    k += 1
                    continue
                if base and base[0] == 'param' and base[1] == 34 and size == 4 and src == '%a0' \
                        and off % 4 == 0 and off < 20:
                    low.append(('list', off // 4 + 1))
                    k += 1
                    continue
                self.fail(k, 'store')
            m = re.match(r'st %(a\d)@$', t)
            if m and regs.get(m.group(1), ('',))[0] == 'callres':
                low.append(('nstore', '%s.b0' % self.render(regs[m.group(1)]), 'true'))
                k += 1
                continue
            # bit 7 copied: tstb X; smi D; clrl D2; andib #-128,D; orb D,D2;
            # andib #127,Y; orb D2,Y
            m = re.match(r'tstb %(a\d)@\((\d+)\)$', t)
            if m and k + 6 < len(ins) and re.match(r'smi %d\d$', ins[k + 1][1]) and \
                    ins[k + 3][1].startswith('andib #-128,') and \
                    re.match(r'andib #127,%(a\d)@\((\d+)\)$', ins[k + 5][1]):
                src = self.bit_operand('%%%s@(%s)' % (m.group(1), m.group(2)), 7)
                mm = re.match(r'andib #127,%(a\d)@\((\d+)\)$', ins[k + 5][1])
                dst = self.bit_target('%%%s@(%s)' % (mm.group(1), mm.group(2)), 7)
                low.append(('store', dst, src) if dst[0] == 'inh' else ('nstore', dst[1], src))
                k += 7
                continue
            m = re.match(r'st %(a\d)@$', t)
            if m and regs.get(m.group(1)) == ('param', 38):
                j = k
                while re.match(r'moveal %[ad]\d,%a\d$', ins[j - 1][1]):
                    j -= 1
                low.append(('made', ins[j][0]))
                k += 1
                continue
            if m and regs.get(m.group(1)) == ('param', 42):
                low.append(('no_solutions', ins[k][0], ins[k + 1][0]))
                k += 1
                continue
            self.fail(k, 'not understood')
        if end is None:
            self.fail(k, 'no epilogue')
        self.exit_addr = ins[end][0]
        self.low = low
        self.group(low)

    def bit_operand(self, src, bit):
        m = re.match(r'%(a\d)@\((\d+)\)$', src)
        if not m:
            raise NotLifted('bit operand %s' % src)
        base, off = self.regs.get(m.group(1)), int(m.group(2))
        if base == ('param', 12) and off == 39:
            n = INH_BY_OFF.get((39, 'b%d' % bit))
            if n:
                return 'inh.' + n
        if base == ('param', 8):
            return 'il.b%d.%d' % (off, bit)
        raise NotLifted('bit operand %s' % src)

    def bit_operand_reg(self, reg, bit):
        v = self.regs.get(reg)
        if v and v[0] == 'field':
            return '%s.%d' % (v[1], bit)
        raise NotLifted('bit operand %s' % reg)

    def bit_target(self, dst, bit):
        m = re.match(r'%(a\d)@\((\d+)\)$', dst)
        if not m:
            raise NotLifted('bit target %s' % dst)
        base, off = self.regs.get(m.group(1)), int(m.group(2))
        if base and base[0] == 'newinh' and off == 39:
            n = INH_BY_OFF.get((39, 'b%d' % bit))
            if n:
                return ('inh', base[1], n)
        if base and base[0] == 'callres':
            return ('node', '%s.b%d.%d' % (self.render(base), off, bit))
        raise NotLifted('bit target %s' % dst)

    def group(self, low):
        """The low-level statements as child blocks and calls (and one
        if/else: a rewrite under a condition, the operator's children
        otherwise)."""
        ifs = [k for k, x in enumerate(low) if x[0] == 'if']
        if len(ifs) > 1 or (ifs and ifs[0] != 0):
            raise NotLifted('conditions')
        if ifs:
            cond, else_at = re.sub(r'\bil\.l(\d+)\b', r'il.p\1', low[0][1]), low[0][2]
            j = next(k for k, x in enumerate(low) if x[0] == 'bra')
            then, rest = low[1:j], low[j + 1:]
            made_at = low[j][1]
            made = [x for x in rest if x[0] == 'made' and x[1] == made_at]
            if len(made) != 1:
                raise NotLifted('the condition\'s branch')
            rest = [x for x in rest if x is not made[0]]
            for x in rest:
                if x[0] == 'bra' and x[1] not in (self.exit_addr,):
                    raise NotLifted('a branch in the else part')
            rest = [x for x in rest if x[0] != 'bra']
            body_then = self.group_items(then + made)
            body_else = self.group_items(rest)
            self.body = [('if', cond, body_then, body_else)]
        else:
            self.body = self.group_items(low)
        self.check_tests(low)

    def group_items(self, low):
        body = []
        i = 0
        while i < len(low):
            s = low[i]
            if s[0] == 'no_solutions':
                i += 1
                continue
            if s[0] == 'call':
                text = re.sub(r'\bil\.l(\d+)\b', r'il.p\1', s[1])
                if s[2]:
                    body.append(('let', 'n%d' % s[3], text))
                else:
                    body.append(('call', text))
                i += 1
                continue
            if s[0] in ('trace', 'made'):
                body.append((s[0],))
                i += 1
                continue
            if s[0] == 'nstore':
                body.append(('nstore', s[1], s[2]))
                i += 1
                continue
            if s[0] != 'newinh':
                raise NotLifted('statement %s' % (s,))
            n, node = s[1], re.sub(r'^il\.l(\d+)$', r'il.p\1', s[2])
            i += 1
            stmts = []
            copy_all = False
            while i < len(low) and low[i][0] in ('store', 'copy_all'):
                if low[i][0] == 'copy_all':
                    if stmts or low[i][1] != n:
                        raise NotLifted('record copy after statements')
                    copy_all = True
                else:
                    tgt, v = low[i][1], low[i][2]
                    if tgt[1] != n:
                        raise NotLifted('a store into another child\'s attributes')
                    if tgt[2] in POINTER_ATTRS:
                        v = re.sub(r'^il\.l(\d+)$', r'il.p\1', v)
                    stmts.append((tgt[2], v))
                i += 1
            np = None
            if i < len(low) and low[i][0] == 'np':
                np = low[i][1]
                i += 1
            if i >= len(low) or low[i][0] != 'pass_1':
                raise NotLifted('no pass_1 after the attributes')
            args = list(low[i][1])
            args[0] = re.sub(r'^il\.l(\d+)$', r'il.p\1', args[0])
            i += 1
            if args[0] != node or args[1] != 'inh_%d' % n:
                raise NotLifted('pass_1(%s) for %s' % (args, node))
            kpos = None
            if i < len(low) and low[i][0] == 'list':
                kpos = low[i][1]
                i += 1
            else:
                raise NotLifted('pass_1\'s list not stored')
            if kpos:
                if i >= len(low) or low[i][0] != 'empty':
                    raise NotLifted('no empty test')
                i += 1
            mask = args[3]
            if np is not None:
                exp = 'not_permissible_function(il, %d, permissible)' % kpos
                if np != exp or not mask.endswith(' -np'):
                    raise NotLifted('not_permissible_function: %s' % np)
            if args[2] != ('depth' if kpos == 0 else 'depth + 1'):
                raise NotLifted('depth %s' % args[2])
            # the default copy
            if not copy_all:
                head = [a for a, v in stmts[:len(DEFAULT_COPY)]]
                if head != DEFAULT_COPY or any(v != 'inh.' + a for a, v in
                                                 stmts[:len(DEFAULT_COPY)]):
                    raise NotLifted('child %d: not the default copy: %s' % (kpos, stmts[:9]))
                stmts = stmts[len(DEFAULT_COPY):]
            body.append(('child', kpos, node, copy_all, stmts, mask))
        return body

    def check_tests(self, low):
        # the empty tests' control flow: every test but the last leaves when
        # empty (to `no_solutions := true'), the last sets it on the way out
        tail = [s for s in low if s[0] == 'no_solutions']
        tests = [s for s in low if s[0] == 'empty']
        if tests:
            if len(tail) != 1:
                raise NotLifted('no_solutions stores: %d' % len(tail))
            st_at, after = tail[0][1], tail[0][2]
            for s in tests:
                m = re.match(r'b(mi|pl)[sw]? 0x([0-9a-f]+)$', s[1])
                tgt = int(m.group(2), 16)
                if m.group(1) == 'mi' and tgt == st_at:
                    continue
                if m.group(1) == 'pl' and s is tests[-1] and s[2] == st_at:
                    continue
                raise NotLifted('the empty tests\' branches')


def lift_routine(insns, names, pass1, read=None):
    """(lifted dict, None) or (None, why)."""
    try:
        return Lifter(insns, names, pass1, read).lift(), None
    except (NotLifted, IndexError, KeyError) as e:
        return None, str(e)


def call_positions(insns, pass1):
    """For each pass_1 call of a routine, the child position its list is
    stored at (children[k]) or None (another use: the routine's own
    list, a rewrite)."""
    regs = {}
    out = []
    ins = [_strip(t) for a, n, t, h in insns]
    for k, t in enumerate(ins):
        m = re.match(r'movea?l %fp@\((\d+)\),%([ad]\d)$', t)
        if m:
            regs[m.group(2)] = int(m.group(1))
            continue
        m = re.match(r'movea?l %([ad]\d),%([ad]\d)$', t)
        if m:
            regs[m.group(2)] = regs.get(m.group(1))
            continue
        if re.match(r'(jsr|bsrw?) 0x%x$' % pass1, t):
            pos = None
            for u in ins[k + 1:k + 6]:
                m = re.match(r'movea?l %([ad]\d),%([ad]\d)$', u)
                if m:
                    regs[m.group(2)] = regs.get(m.group(1))
                    continue
                m = re.match(r'movel %a0,%(a\d)@(?:\((\d+)\))?$', u)
                if m:
                    if regs.get(m.group(1)) == 34:
                        pos = int(m.group(2) or 0) // 4 + 1
                    break
                if not u.startswith(('lea %sp', 'addqw')):
                    break
            out.append(pos)
    return out


# --------------------------------------------------------------------------
# the rule file's text

def mask_text(mask, pos, unions, kinds):
    """A pass_1 call's permissible set: `inherited', `derived' (the union
    of the kinds the operator's patterns test at child position pos) or
    the kinds; ` -np' when not_permissible_function's are removed."""
    np = False
    if isinstance(mask, str):
        if mask.endswith(' -np'):
            np, mask = True, mask[:-4]
        mask = 'inherited' if mask in ('permissible', 'inherited') else int(mask) & 0xFFFFFFFF
    if mask == 'inherited':
        s = 'inherited'
    elif pos is not None and unions.get(pos) == mask:
        s = 'derived'
    else:
        s = '[' + ', '.join(kinds[b] for b in range(32) if mask >> b & 1) + ']'
    return s + (' -np' if np else '')


def format_operator(d, lifted, positions, unions, ils, kinds, op_name):
    """The operator declaration of one isc_pass_1_main routine."""
    il = op_name(d['w98']) if d['w98'] is not None and d['w98'] in ils else None
    head = 'operator %s%s%s image 16#%06X;' % (
        d['name'], ' il %s' % il if il else '',
        ' children %d' % d['nchildren'] if d['nchildren'] is not None else '', d['start'])
    L = [head]
    if lifted is not None:
        format_body(L, lifted['body'], '  ', unions, kinds, op_name)
    else:
        calls = []
        for (mask, np), pos in zip(d['pass_1_calls'], positions):
            m = mask if mask == 'inherited' else int(mask) & 0xFFFFFFFF
            s = mask_text(m, pos, unions, kinds) + (' -np' if np else '')
            calls.append(s if pos is None else '%d: %s' % (pos, s))
        L.append('  fixed;')
        if calls:
            L.append('  pass_1 %s;' % ', '.join(calls))
    L.append('end;')
    return '\n'.join(L)


def format_body(L, body, ind, unions, kinds, op_name):
    for b in body:
        if b[0] == 'call':
            L.append('%scall %s;' % (ind, b[1]))
        elif b[0] == 'let':
            L.append('%slet %s <- %s;' % (ind, b[1], b[2]))
        elif b[0] == 'trace':
            L.append('%strace rewrite;' % ind)
        elif b[0] == 'made':
            L.append('%ssolutions_made;' % ind)
        elif b[0] == 'nstore':
            L.append('%s%s <- %s;' % (ind, b[1], b[2]))
        elif b[0] == 'if':
            L.append('%sif %s;' % (ind, b[1]))
            format_body(L, b[2], ind + '  ', unions, kinds, op_name)
            L.append('%selse;' % ind)
            format_body(L, b[3], ind + '  ', unions, kinds, op_name)
            L.append('%sendif;' % ind)
        else:
            _, kpos, node, copy_all, stmts, mask = b
            L.append('%schild %s %s%s' % (ind, kpos or 'solutions', node,
                                          ' copy_all' if copy_all else ''))
            for a, v in stmts:
                if a == 'parent_il_kind':
                    v = op_name(int(v) & 255)
                L.append('%s  %s <- %s;' % (ind, a, v))
            L.append('%s  permissible %s;' % (ind, mask_text(mask, kpos, unions, kinds)))


def parse_operator(ts, i, fn, num):
    """The tokens of an operator declaration from ts[i] (after `operator')
    to its `end;': (dict, the index after it)."""
    d = {'name': ts[i], 'il': None, 'children': None, 'body': [], 'fixed': False,
         'pass_1': None, 'image': None}
    i += 1
    while ts[i] != ';':
        if ts[i] == 'image':
            d['image'] = num(ts[i + 1])
            i += 2
        elif ts[i] == 'il':
            d['il'] = ts[i + 1]
            i += 2
        elif ts[i] == 'children':
            d['children'] = num(ts[i + 1])
            i += 2
        else:
            raise ValueError('%s: operator %s: %r' % (fn, d['name'], ts[i]))
    i += 1
    child = None
    stack = []
    while ts[i] != 'end':
        j = ts.index(';', i)
        if ts[i] == 'if':
            node = ('if', join_expr(ts[i + 1:j]), [], [])
            d['body'].append(node)
            stack.append(d['body'])
            d['body'] = node[2]
            child = None
        elif ts[i] == 'else':
            d['body'] = stack[-1][-1][3]
            child = None
        elif ts[i] == 'endif':
            d['body'] = stack.pop()
            child = None
        elif ts[i] == 'fixed':
            d['fixed'] = True
        elif ts[i] == 'pass_1':
            d['pass_1'] = ' '.join(ts[i + 1:j])
        elif ts[i] == 'call':
            d['body'].append(('call', join_expr(ts[i + 1:j])))
        elif ts[i] == 'let':
            d['body'].append(('let', ts[i + 1], join_expr(ts[i + 3:j])))
        elif ts[i] == 'trace':
            d['body'].append(('trace',))
        elif ts[i] == 'solutions_made':
            d['body'].append(('made',))
        elif ts[i] == 'child':
            k = i + 2
            node = [ts[k]]
            while ts[k + 1] == '.':
                node += ts[k + 1:k + 3]
                k += 2
            k += 1
            child = {'k': 0 if ts[i + 1] == 'solutions' else num(ts[i + 1]),
                     'node': ''.join(node), 'copy_all': False, 'stmts': [], 'mask': None}
            d['body'].append(('child', child))
            if ts[k] == 'copy_all':
                child['copy_all'] = True
                k += 1
            if ts[k] == 'permissible':
                child['mask'] = ts[k + 1:j]
                child = None
            elif ts[k + 1] == '<-':
                child['stmts'].append((ts[k], join_expr(ts[k + 2:j])))
            else:
                raise ValueError('%s: operator %s: %r' % (fn, d['name'], ts[k]))
        elif ts[i] == 'permissible' and child is not None:
            child['mask'] = ts[i + 1:j]
            child = None
        elif ts[i + 1] == '<-' and child is not None:
            child['stmts'].append((ts[i], join_expr(ts[i + 2:j])))
        elif '<-' in ts[i:j] and re.match(r'n\d+$', ts[i]):
            a = ts.index('<-', i)
            d['body'].append(('nstore', join_expr(ts[i:a]), join_expr(ts[a + 1:j])))
        else:
            raise ValueError('%s: operator %s: %r' % (fn, d['name'], ts[i]))
        i = j + 1
    return d, i + 2


def join_expr(toks):
    """Tokens back to the expression's text (the rule file's spacing)."""
    out = ''
    for t in toks:
        if t == ',':
            out += ', '
        elif t in ('.', '(', ')') or out.endswith(('(', '.', ', ')) or not out:
            out += t
        else:
            out += ' ' + t
    return out


# --------------------------------------------------------------------------
# the dispatch: the IL node kinds, tree operators and assignment operators
# (the enumerations whose names isc_user_routines writes: an_kind_t,
# ur_top_t, ur_aop_t), and the A5 offsets of isc_pass_1_main's tables

OPERATORS_COMMENT = [
    "{ The operators: isc_pass_1_main's routine for each IL node kind, tree,",
    "  comparison and assignment operator (pass_1 dispatches on the node's",
    "  kind, isc_tree_node and isc_cmp_tree_node on +36, isc_assign_node on",
    "  +76, through the tables isc_pass_1_begin_compilation fills from the",
    "  routines' names), the il$t its proper_subtree gets and its number of",
    "  children; then, per child, the node (il.pN: the pointer at +N), the",
    "  statements that set the child's inherited attributes after the",
    "  default ones are copied from the node's (copy_all: the whole record",
    "  copied instead), and its permissible set (derived: the union of the",
    "  kinds the patterns test at that position; inherited: the node's own;",
    "  -np: less not_permissible_function's).  `fixed': the routine is the",
    "  generator's fixed text (tools/iscg_text.py P1_ROUTINES; its pass_1",
    "  calls' sets listed, position: set). }",
]

TABLES = [  # (prefix, enumeration, A5 offset, entries)
    ('isc_tree_node_', 'ur_top_t', 0, 90),
    ('isc_cmp_tree_node_', 'ur_top_t', 360, 90),
    ('isc_assign_node_', 'ur_aop_t', 720, 38),
    ('isc_', 'an_kind_t', 872, 237),
]
TABLE_NAMES = {0: 'p1_tree_op', 360: 'p1_cmp_op', 720: 'p1_assign_op', 872: 'p1_kind'}


def enumerations(root):
    """{name: [identifiers]} of isc_user_routines.pas's an_kind_t, ur_top_t,
    ur_aop_t."""
    import os
    text = open(os.path.join(root, 'lang2', 'source', 'isc', 'isc_user_routines.pas'),
                encoding='latin1').read()
    out = {}
    for n in ('an_kind_t', 'ur_top_t', 'ur_aop_t'):
        m = re.search(r'\b%s = \((.*?)\);' % re.escape(n), text, re.S)
        out[n] = [x.strip() for x in m.group(1).split(',')]
    return out


_ENUMS = None


def enums():
    global _ENUMS
    if _ENUMS is None:
        import os
        _ENUMS = enumerations(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
    return _ENUMS


def dispatch_of(name):
    """(A5 offset of the table, index) of a routine by its name, or None."""
    e = enums()
    for prefix, en, base, n in TABLES:
        if name.startswith(prefix) and name[len(prefix):] in e[en]:
            k = e[en].index(name[len(prefix):])
            if k < n:
                return base, k
    return None


def dispatch_entries(names):
    """{A5 offset of the cell: routine} for every routine the tables name."""
    out = {}
    for nm in names:
        d = dispatch_of(nm)
        if d:
            out[d[0] + 4 * d[1]] = nm
    return out


# --------------------------------------------------------------------------
# emitting isc_pass_1_main.pas (tools/iscg_gen.py)

HEADING = '''(
    il: univ_ptr;
    inh: inherited_attributes_ptr_t;
    depth: integer;
    permissible: solution$set_t;
    var il_kind: integer;
    var number_of_children: integer32;
    var solutions: solution_list_ptr_t;
    var children: p1_children_t;
    var solutions_made: boolean;
    var no_solutions: boolean); options(val_param)'''

FIXED_ADDRESSES = [('cross_product_to_solutions_of_parent', 0x0DB4B4),
                   ('isc_pass_1_begin_compilation', 0x0EFE96), ('pass_1', 0x0F04BC)]
DISPATCHERS = {
    'isc_tree_node': ('p1_tree_op', 'tr_op', 36, ' tree', 0x0EFDB6, 0x5E),
    'isc_cmp_tree_node': ('p1_cmp_op', 'tr_op', 36, ' comparison', 0x0E385A, 0x60),
    'isc_assign_node': ('p1_assign_op', 'as_op', 76, 'n assignment', 0x0E182E, 0x60),
}
# argument casts the headings need (process_eval_node's second
# parameter is a node in isc_routine_externs.ins.pas; the image passes inh)
CALL_CASTS = {('process_eval_node', 1): 'isc_node_ptr_t'}
# pointer arguments the image passes as a cleared longword
CALL_NIL = {('rewrite_$routine_call', 1)}


def node_ref(path):
    """il.p40.l20 -> Pascal."""
    parts = path.split('.')
    if parts[0] != 'il' and not re.match(r'n\d+$', parts[0]):
        raise ValueError('not a node path: %s' % path)
    e = parts[0]
    for p in parts[1:]:
        m = re.match(r'([plwb])(\d+)$', p)
        if not m:
            raise ValueError('node path %s' % path)
        off = int(m.group(2))
        base = 'isc_node_ptr_t(%s)^' % e
        if m.group(1) in 'pl':
            if off % 4 or off < 4:
                raise ValueError('node path %s' % path)
            e = '%s.x%s[%d]' % (base, m.group(1), off // 4)
        elif m.group(1) == 'w' and off == 2:
            e = '%s.kind' % base
        elif m.group(1) == 'w':
            e = '%s.xw[%d]' % (base, off // 2)
        else:
            e = 'ord(p1_node_bytes_ptr_t(%s)^[%d])' % (e, off)
    return e


def bit_ref(path, bit):
    """il.b30.6 / il.l4.20 -> Pascal (bit of a byte, of a big-endian
    longword)."""
    m = re.match(r'(.*)\.([bl])(\d+)$', path)
    base, kind, off = m.group(1), m.group(2), int(m.group(3))
    if kind == 'l':
        off, bit = off + 3 - bit // 8, bit % 8
    b = base if re.match(r'(il|n\d+)$', base) else node_ref(base)
    return 'p1_node_bytes_ptr_t(%s)^[%d].b%d' % (b, off, bit)


def expr(e):
    """A rule-file expression -> Pascal."""
    def rep(m):
        s = m.group(0)
        mm = re.match(r'((?:il|n\d+)(?:\.[plwb]\d+)+)\.(\d)$', s) or \
            re.match(r'((?:il|n\d+)(?:\.[plwb]\d+)+)\.(\d\d)$', s)
        if mm:
            return bit_ref(mm.group(1), int(mm.group(2)))
        return node_ref(s)
    e = re.sub(r'\b(?:il|n\d+)(?:\.[plwb]\d+)+(?:\.\d+)?', rep, e)
    e = re.sub(r'\binh\.(\w+)', lambda m: inh_ref('inh', m.group(1)), e)
    e = re.sub(r'\brlen_arith\(', 'p1_readonly_view_ptr_t(addr(isc_readonly_tables))^.rlen_arith[', e)
    if 'rlen_arith[' in e:
        # the call's closing parenthesis becomes the index's bracket
        i = e.index('rlen_arith[') + len('rlen_arith[')
        depth = 0
        for j in range(i, len(e)):
            if e[j] == '(':
                depth += 1
            elif e[j] == ')':
                if depth == 0:
                    e = e[:j] + ']' + e[j + 1:]
                    break
                depth -= 1
    return e


def inh_ref(base, name):
    if name == 'parent_il_kind':
        return 'p1_inh_view_ptr_t(%s)^.parent_il_kind' % base
    f = INH_FIELD.get(name)
    if f is None:
        raise ValueError('no inherited attribute %s' % name)
    return '%s^.%s' % (base, f)


def call_text(c):
    m = re.match(r'([\w$]+)\((.*)\)$', c)
    if not m:
        return c
    name, args = m.group(1), split_args(m.group(2))
    out = []
    for k, a in enumerate(args):
        a = expr(a)
        if (name, k) in CALL_NIL and a == '0':
            a = 'nil'
        if (name, k) in CALL_CASTS:
            a = '%s(%s)' % (CALL_CASTS[(name, k)], a)
        out.append(a)
    return '%s(%s)' % (name, ', '.join(out))


def split_args(s):
    out, depth, cur = [], 0, ''
    for ch in s:
        if ch == ',' and depth == 0:
            out.append(cur.strip())
            cur = ''
            continue
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def mask_pascal(toks, k, unions, kinds):
    """The permissible set of child k's pass_1 call."""
    np = '-' in toks and 'np' in toks
    toks = [t for t in toks if t not in ('-', 'np', '-np')]
    if toks == ['inherited']:
        s = 'permissible'
    else:
        if toks == ['derived']:
            mask = unions.get(k)
            if mask is None:
                raise ValueError('no patterns test position %d' % k)
            names = [kinds[b] for b in range(32) if mask >> b & 1]
        else:
            names = [t for t in toks if t not in ('[', ']', ',')]
        s = '[' + ', '.join('solution$' + n for n in names) + ']'
    if np:
        s += ' - not_permissible_function(il, %d, permissible)' % k
    return s


def wrap_stmt(text, ind, width=78):
    """A long statement broken after a comma."""
    if len(ind + text) <= width:
        return [ind + text]
    cut = text.rfind(', ', 0, width - len(ind))
    if cut < 0:
        return [ind + text]
    return [ind + text[:cut + 1]] + wrap_stmt(text[cut + 2:], ind + '    ', width)


def emit_operator(op, unions, kinds):
    """One generated operator routine: (Pascal lines, number of children
    blocks)."""
    name = op['name']
    flat = flatten(op['body'])
    kids = [b[1] for b in flat if b[0] == 'child']
    lets = [b[1] for b in flat if b[0] == 'let']
    L = []
    what = []
    if op['il']:
        what.append('the proper_subtree il_%s' % op['il'])
    n = op['children'] or 0
    what.append('%d child%s' % (n, '' if n == 1 else 'ren'))
    L.append('{ %s - %s%s. }' % (name, ', '.join(what),
                                 ' (0x%06X)' % op['image'] if op['image'] else ''))
    L.append('')
    L.append('procedure %s%s;' % (name, HEADING))
    if kids or lets:
        L.append('var')
    if kids:
        L.append('  ' + ', '.join(sorted({'inh_%d' % (c['k'] or 1) for c in kids})) +
                 ': inherited_attributes_ptr_t;')
    if lets:
        L.append('  ' + ', '.join(lets) + ': univ_ptr;')
    L.append('begin')
    L.append('  solutions_made := false;')
    L.append('  no_solutions := false;')
    L.append('  il_kind := ord(il_%s);' % op['il'])
    L.append('  number_of_children := %d;' % n)
    emit_body(L, op['body'], '  ', unions, kinds)
    L.append('end;')
    return L


def flatten(body):
    out = []
    for b in body:
        out.append(b)
        if b[0] == 'if':
            out.extend(flatten(b[2]) + flatten(b[3]))
    return out


def emit_body(L, body, ind, unions, kinds):
    kids = [b[1] for b in body if b[0] == 'child']
    opened = 0
    for b in body:
        if b[0] == 'if':
            L.extend(wrap_stmt('if %s then begin' % call_text_expr(b[1]), ind))
            emit_body(L, b[2], ind + '  ', unions, kinds)
            L.append('%send' % ind)
            L.append('%selse begin' % ind)
            emit_body(L, b[3], ind + '  ', unions, kinds)
            L.append('%send;' % ind)
            continue
        if b[0] == 'nstore':
            L.extend(wrap_stmt('%s := %s;' % (node_target(b[1]), expr(b[2])), ind))
            continue
        if b[0] == 'call':
            L.extend(wrap_stmt(call_text(b[1]) + ';', ind))
            continue
        if b[0] == 'let':
            L.extend(wrap_stmt('%s := %s;' % (b[1], call_text(b[2])), ind))
            continue
        if b[0] == 'trace':
            L.extend(ind + x for x in REWRITE_TRACE_PASCAL)
            continue
        if b[0] == 'made':
            L.append('%ssolutions_made := true;' % ind)
            continue
        c = b[1]
        k = c['k']
        v = 'inh_%d' % (k or 1)
        L.extend(wrap_stmt('%s := new_inherited_attributes(isc_heap, %s);' % (v, expr(c['node'])),
                           ind))
        if c['copy_all']:
            L.append('%s%s^ := inh^;' % (ind, v))
        else:
            for a in DEFAULT_COPY:
                if a == 'stmt_number':
                    continue        # one longword with source_line_number
                if a == 'source_line_number':
                    L.append('%s%s^.pos := inh^.pos;' % (ind, v))
                    continue
                L.append('%s%s := %s;' % (ind, inh_ref(v, a), inh_ref('inh', a)))
        for a, val in c['stmts']:
            if a == 'parent_il_kind':
                val = 'ord(il_%s)' % val
            else:
                val = expr(val)
            L.extend(wrap_stmt('%s := %s;' % (inh_ref(v, a), val), ind))
        if k == 0:
            L.extend(wrap_stmt('solutions := pass_1(%s, %s, depth, %s);' % (
                expr(c['node']), v, mask_pascal(c['mask'], k, unions, kinds)), ind))
            continue
        L.extend(wrap_stmt('children[%d] := pass_1(%s, %s, depth + 1, %s);' % (
            k, expr(c['node']), v, mask_pascal(c['mask'], k, unions, kinds)), ind))
        L.append('%sif solution_list$empty(children[%d]) then' % (ind, k))
        L.append('%s  no_solutions := true' % ind)
        if c is [x for x in kids if x['k']][-1]:
            L[-1] += ';'
        else:
            L.append('%selse begin' % ind)
            ind += '  '
            opened += 1
    for _ in range(opened):
        ind = ind[:-2]
        L.append('%send;' % ind)


def node_target(t):
    """A rewritten node's field as an assignment's left side."""
    m = re.match(r'(n\d+)\.b0$', t)
    if m:
        return 'isc_node_ptr_t(%s)^.rewritten' % m.group(1)
    return expr(t)


def call_text_expr(e):
    """A condition: its calls' arguments translated."""
    return re.sub(r'([\w$]+\([^()]*\))', lambda m: call_text(m.group(1)), e)


def emit_unit(rules, unions_by_il, kinds, il_index, text):
    """isc_pass_1_main.pas: text is tools/iscg_text.py."""
    ops = rules.operators
    e = enums()
    todo = [op['name'] for op in ops
            if op['fixed'] and op['name'] not in DISPATCHERS
            and op['name'] not in text.P1_ROUTINES]
    addrs = sorted([(op['image'], op['name']) for op in ops if op['image']] +
                   [(a, n) for n, a in FIXED_ADDRESSES])
    head = text.P1_HEAD.replace('@ADDRESSES@', '\n'.join(
        '    --------  0x%06X  %s' % (a, n) for a, n in addrs))
    if todo:
        t = ['', '  Not generated yet (declared extern below; the operator',
             '  declarations mark them `fixed\'; their text is to be read off the',
             '  image into tools/iscg_text.py P1_ROUTINES): %d routines,' % len(todo)]
        t.extend(wrap_list(todo, '    '))
        head = head.replace('@TODO@', '\n'.join(t) + '\n')
    else:
        head = head.replace('@TODO@', '')
    L = [head, '']
    L.append(INCLUDES_P1.rstrip('\n'))
    L.append('')
    enum_lines = []
    for pas, en in (('an_kind_t', 'an_kind_t'), ('p1_top_t', 'ur_top_t'),
                    ('p1_aop_t', 'ur_aop_t')):
        enum_lines.append('  %s = (' % pas)
        enum_lines.extend(wrap_list(e[en], '    ', end=');'))
    L.append(text.P1_TYPES.replace('@ENUMS@', '\n'.join(enum_lines)))
    L.append('')
    L.append(text.P1_DATA)
    L.append('')
    L.append(text.CROSS_PRODUCT)
    L.append('')
    for op in ops:
        name = op['name']
        if name in DISPATCHERS:
            tb, fld, off, what, a, ln = DISPATCHERS[name]
            t = text.DISPATCH
            for k, v in (('@NAME@', name), ('@TABLE@', tb), ('@FIELD@', fld),
                         ('@OFF@', str(off)), ('@WHAT@', what), ('@ADDR@', '0x%06X' % a),
                         ('@LEN@', '0x%X' % ln)):
                t = t.replace(k, v)
            L.append(t)
        elif name == 'isc_unrecognized_il_node':
            L.append(text.UNRECOGNIZED_IL_NODE)
        elif op['fixed']:
            if name in text.P1_ROUTINES:
                L.append(text.P1_ROUTINES[name])
            else:
                L.append('{ %s (0x%06X): not generated yet (the unit\'s header). }' % (
                    name, op['image']))
                L.append('')
                L.append('procedure %s%s; extern;' % (name, HEADING))
        else:
            L.extend(emit_operator(op, unions_by_il.get(il_index.get('il_%s' % op['il'])) or {},
                                   kinds))
        L.append('')
    # isc_pass_1_begin_compilation: in the declarations' order, each
    # table's defaults before its first routine
    L.append(text.BEGIN_COMPILATION_HEAD)
    seen = set()
    for op in ops:
        d = dispatch_of(op['name'])
        if d is None:
            continue
        base, k = d
        tb = TABLE_NAMES[base]
        if base not in seen:
            seen.add(base)
            n = [t[3] for t in TABLES if t[2] == base][0]
            L.append('  for i := 0 to %d do' % (n - 1))
            L.append('    %s[i] := addr(isc_unrecognized_il_node);' % tb)
        L.append('  %s[%d] := addr(%s);' % (tb, k, op['name']))
    L.append('end;')
    L.append('')
    L.append(text.PASS_1)
    return '\n'.join(L) + '\n'


def wrap_list(items, indent, width=78, end=''):
    lines, cur = [], indent
    for k, it in enumerate(items):
        s = it + (',' if k < len(items) - 1 else end)
        if len(cur) + len(s) + 1 > width and cur.strip():
            lines.append(cur.rstrip())
            cur = indent
        cur += s + ' '
    if cur.strip():
        lines.append(cur.rstrip())
    return lines


INCLUDES_P1 = '''%include '/sys/ins/base.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas';
%include 'lang2/source/isc/isc_consts.ins.pas';
%include 'lang2/source/isc/isc_types.ins.pas';
%include 'lang2/source/isc/isc_routine_externs.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';
'''


REWRITE_TRACE_PASCAL = [
    'if isc_user_routines_356 or isc_user_routines_354 then begin',
    "  write('*********************');",
    '  writeln;',
    "  write('R E W R I T E ! ! ! !');",
    '  writeln;',
    "  write('*********************');",
    '  writeln;',
    '  writeln;',
    'end;',
]
