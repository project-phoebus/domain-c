#!/usr/bin/env python3
"""iscg_p1lang.py - the statement language of the pass-1 actions.

The pass-2 language (tools/iscg_p2lang.py: its expressions, paths,
statements, printer, parser and Pascal) with what the pass-1 actions
add (docs/iscg-design.md 2.5, 2.6, 10.7):

    clause   := 'pass_1' 'image' ADDR ['rewrite'] ['hand'] 'begin'
                  {temp} {{stmt} 'condition' expr ';'} ['cycle_guard' ALREADY ';'] ['cycle_mark' ALREADY ';']
                  {stmt}
                'end' ';'
              | 'pass_1' 'image' ADDR 'residue' ';'
    stmt     := ... (pass 2's)
              | 'copy' ATTR {',' ATTR} 'from' path ['to' path] ';'
              | 'sum' ATTR {',' ATTR} 'of' path {',' path} ['to' path] ';'
              | 'trace' 'string' ';'
    expr     := ... | ('bytes' | 'words') ['@' NUMBER] '(' NUMBER {',' NUMBER} ')' '[' expr ']'

- The clause is the action's body; the generator writes the skeleton
  around it: `result := nil; work := nil;', then for each `condition'
  an `if' (nested, in order: the image tests them one after another;
  statements between them are evaluated between the tests),
  the trace `Pattern N matched the semantics.', for a `cycle_guard' the
  test of the subject's already_ flag (`Infinite cycle prevented ...'),
  the new solution (new_solution with the rule's result kind, its
  which_transform and before_transform), the statements, the seven
  already_ flags copied from the subject, the guard's flag set (a
  `cycle_mark' sets the flag without the guard's test), and
  `work := s; result := s'.  A `rewrite' clause (the proper_subtree
  rules) makes no solution: after the trace `result := subject', and
  its statements set the subject's attributes.
- In the statements `result' is the new solution (a pointer), `subject'
  the solution it is made from (the var parameter; `subject' alone is
  its address, before_transform), `$K' the subject's child K, `il' and
  `inh' the parameters (the node and its inherited attributes).
- `copy f, g from P' is `result.f <- P.f; result.g <- P.g;' (`to S':
  S.f ...); `sum f, g of P, Q' is `result.f <- P.f + Q.f; result.g <-
  P.g + Q.g;'.  `trace 'text'' is `if isc_user_routines_354 then
  writeln(text)'.
- `bytes(v1, ..., vn)[e]' and `words(...)[e]' are a cost table's entry
  e: a module variable (packed array [0..16] of 0..255, array [0..16]
  of integer), entry k vk for k = 1..n, entries 0 and n + 1 .. 16 zero.
  The generator lays a rule's tables out in the reverse of their order
  in its clause, the rules' in rule order (the image's layout: Rev 8.89
  begins each on 8 bytes); `bytes@k(...)' places a table k-th in its
  rule's layout (written for every table of a rule whose layout is not
  the reverse of the clause).
"""
import re

import iscg_p2lang as L

KINDS = ['none', 'case_jump_base', 'fp_reg_pair_high', 'fp_reg_pair_low',
         'local_routine', 'address_mode', 'ctl_reg', 'flow', 'fp_reg',
         'fp_reg_pair', 'fp_reg_quad', 'ip_reg', 'ip_reg_field',
         'ip_reg_scaled', 'literal_32_bits', 'literal_64_bits',
         'processor_reg', 'sc_reg', 'sr_reg', 'dummy', 'any_solution',
         'irrelevant', 'proper_subtree', 'void', 'k_max']     # solution$t
ALREADY = ['already_address_mode', 'already_fp_reg', 'already_fp_reg_pair',
           'already_fp_reg_quad', 'already_ip_reg', 'already_ip_reg_field',
           'already_processor_reg']
TRACE = 'isc_user_routines_354'
L.PREC.setdefault('in', 3)          # `k in set' (a set's element)
L.BUILTINS.setdefault('abs', 'i32')
# inserts globals.ins.pas opens whose routines the actions call
EXTRA_INSERTS = ['lang/lang/source/debug_sym_dmp.ins.pas',
                 'lang/lang/source/globals_from_frontend.ins.pas']


def extra_headings():
    """The headings of EXTRA_INSERTS (iscg_p2lang's EXTRA set aside: its
    lookup recurses)."""
    saved = dict(L.EXTRA)
    L.EXTRA.clear()
    try:
        out = {}
        for path in EXTRA_INSERTS:
            for k, v in L.read_headings("%%include '%s';" % path).items():
                out.setdefault(k, v)
        return out
    finally:
        L.EXTRA.update(saved)
# the run time's arithmetic (the lifter writes them as operators)
RUNTIME_HEADINGS = {n: {'params': [('a', 'value', 'i32', False),
                                   ('b', 'value', 'i32' if n[-1] == 'l' else 'i16', False)],
                        'ret': 'i32' if n[-3] == 'l' else 'i16', 'val_param': True,
                        'variable': False}
                    for n in ('m$mis$lll', 'm$dis$lll', 'm$ois$lll', 'm$ois$wlw', 'm$mis$llw',
                              'm$dis$llw')}
# the prelude's cells the actions read that the inserts the modules open
# declare only through globals.ins.pas
EXTRA_GLOBALS = {'il_180': 'node', 'cargs_$options': 'other:cargs_$options_t'}


def negate(c):
    if c[0] == 'un' and c[1] == 'not':
        return c[2]
    if c[0] == 'bin' and c[1] in ('and', 'or'):
        return ('bin', 'or' if c[1] == 'and' else 'and', negate(c[2]), negate(c[3]))
    if c[0] == 'bool':
        return ('bool', not c[1])
    inv = {'=': '<>', '<>': '=', '<': '>=', '>=': '<', '>': '<=', '<=': '>',
           'u<': 'u>=', 'u>=': 'u<', 'u>': 'u<=', 'u<=': 'u>'}
    if c[0] == 'bin' and c[1] in inv:
        return ('bin', inv[c[1]], c[2], c[3])
    return ('un', 'not', c)


class Clause:
    def __init__(self, rule, flags, decls, body):
        self.rule = rule
        self.flags = flags
        self.decls = decls
        self.body = body
        self.offsets = None
        self.reversed_ok = True
        self.hand = False

    def key(self):
        f = self.flags
        return (tuple(map(repr, f['chain'])), f['guard'], f.get('mark'), f['rewrite'], f['trace'],
                tuple(map(repr, self.decls)),
                tuple(map(repr, self.body)))


# --------------------------------------------------------------------------
# macros

def macros(body, target):
    """Runs of copies from one path (`copy') and of sums over the same
    paths (`sum') into the target, in place of their assignments."""
    out = []
    i = 0
    while i < len(body):
        s = body[i]
        c = as_copy(s, target)
        if c:
            j = i + 1
            fields = [c[0]]
            while j < len(body):
                c2 = as_copy(body[j], target)
                if not c2 or c2[1] != c[1] or c2[0] in fields:
                    break
                fields.append(c2[0])
                j += 1
            if len(fields) >= 2:
                out.append(('copy', fields, c[1], target))
                i = j
                continue
        m = as_sum(s, target)
        if m:
            j = i + 1
            fields = [m[0]]
            while j < len(body):
                m2 = as_sum(body[j], target)
                if not m2 or m2[1] != m[1] or m2[0] in fields:
                    break
                fields.append(m2[0])
                j += 1
            if len(fields) >= 2:
                out.append(('sum', fields, m[1], target))
                i = j
                continue
        if s[0] == 'if':
            s = ('if', [(c, macros(b, target)) for c, b in s[1]],
                 macros(s[2], target) if s[2] is not None else None)
        elif s[0] == 'for':
            s = ('for', s[1], s[2], s[3], macros(s[4], target))
        out.append(s)
        i += 1
    return out


def attr_name(n):
    return n in L.attrs() and not n.startswith('$')


def as_copy(s, target):
    """(field, source path) of `target.f <- P.f', P a path."""
    if s[0] != 'set' or s[1][0] != 'path' or s[1][1] != target or len(s[1][2]) != 1:
        return None
    f = s[1][2][0]
    if not attr_name(f):
        return None
    e = s[2]
    if e[0] == 'path' and isinstance(e[1], str) and e[2] and e[2][-1] == f and \
            ('path', e[1], e[2][:-1]) != ('path', target, []):
        return f, ('path', e[1], e[2][:-1])
    return None


def as_sum(s, target):
    """(field, (paths)) of `target.f <- P.f + Q.f + ...' (two or more)."""
    if s[0] != 'set' or s[1][0] != 'path' or s[1][1] != target or len(s[1][2]) != 1:
        return None
    f = s[1][2][0]
    if not attr_name(f):
        return None
    terms = []
    e = s[2]
    while e[0] == 'bin' and e[1] == '+':
        terms.append(e[3])
        e = e[2]
    terms.append(e)
    terms.reverse()
    if len(terms) < 2:
        return None
    srcs = []
    for t in terms:
        if not (t[0] == 'path' and isinstance(t[1], str) and t[2] and t[2][-1] == f):
            return None
        srcs.append(('path', t[1], t[2][:-1]))
    return f, tuple(srcs)


def expand(s):
    """A macro statement's assignments."""
    if s[0] == 'copy':
        _, fields, src, target = s
        return [('set', ('path', target, [f]), ('path', src[1], src[2] + [f])) for f in fields]
    if s[0] == 'sum':
        _, fields, srcs, target = s
        out = []
        for f in fields:
            e = ('path', srcs[0][1], srcs[0][2] + [f])
            for p in srcs[1:]:
                e = ('bin', '+', e, ('path', p[1], p[2] + [f]))
            out.append(('set', ('path', target, [f]), e))
        return out
    raise L.LangError('not a macro: %r' % (s,))


# --------------------------------------------------------------------------
# printing

def fmt_expr(e, prec=0):
    k = e[0]
    if k == 'cost':
        return '%s%s(%s)[%s]' % ('bytes' if e[1] == 'b' else 'words',
                                 '@%d' % e[4][1] if len(e) > 4 else '',
                                 ', '.join(str(v) for v in e[2]), fmt_expr(e[3]))
    if k == 'path':
        base, sels = e[1], e[2]
        if isinstance(base, tuple):
            base = fmt_expr(base)
        if base == 'subject' and sels and sels[0].startswith('$'):
            return '.'.join(sels)
        return '.'.join([base] + list(sels))
    if k == 'index':
        return '%s[%s]' % (e[1], fmt_expr(e[2]))
    if k == 'call':
        return '%s(%s)' % (e[1], ', '.join(fmt_expr(a) for a in e[2]))
    if k == 'addr':
        return 'addr(%s)' % fmt_expr(e[1])
    if k == 'un':
        if e[1] == 'not':
            s = 'not ' + fmt_expr(e[2], 6)
        else:
            s = '-' + fmt_expr(e[2], 6)
        return '(%s)' % s if prec > 5 else s
    if k == 'bin':
        p = L.PREC[e[1]]
        s = '%s %s %s' % (fmt_expr(e[2], p), e[1], fmt_expr(e[3], p + 1))
        return '(%s)' % s if p < prec or (p == 3 and prec == 3) else s
    return L.fmt_expr(e, prec)


def fmt_path(p):
    return fmt_expr(p)


def fmt_stmt(s, ind):
    k = s[0]
    if k == 'set':
        return [ind + '%s <- %s;' % (fmt_expr(s[1]), fmt_expr(s[2]))]
    if k == 'call':
        return [ind + ('%s(%s);' % (s[1], ', '.join(fmt_expr(a) for a in s[2]))
                       if s[2] else '%s;' % s[1])]
    if k == 'temp':
        return [ind + 'temp %s: %s;' % (s[1], s[2])]
    if k == 'condition':
        return [ind + 'condition %s;' % fmt_expr(s[1])]
    if k == 'cycle_guard':
        return [ind + 'cycle_guard %s;' % s[1]]
    if k == 'cycle_mark':
        return [ind + 'cycle_mark %s;' % s[1]]
    if k == 'trace':
        return [ind + 'trace %s;' % fmt_expr(('str', s[1]))]
    if k == 'writeln':
        return [ind + 'writeln %s;' % fmt_expr(('str', s[1]))]
    if k == 'copy':
        _, fields, src, target = s
        return [ind + 'copy %s from %s%s;' % (', '.join(fields), fmt_path(src),
                                              '' if target == 'result' else ' to ' + target)]
    if k == 'sum':
        _, fields, srcs, target = s
        return [ind + 'sum %s of %s%s;' % (', '.join(fields), ', '.join(fmt_path(p) for p in srcs),
                                           '' if target == 'result' else ' to ' + target)]
    if k == 'if':
        out = []
        for j, (c, body) in enumerate(s[1]):
            out.append(ind + ('if ' if j == 0 else 'elsif ') + fmt_expr(c) + ' then')
            out.extend(fmt_stmts(body, ind + '  '))
        if s[2] is not None:
            out.append(ind + 'else')
            out.extend(fmt_stmts(s[2], ind + '  '))
        out.append(ind + 'end;')
        return out
    if k == 'for':
        out = [ind + 'for %s := %s to %s do' % (s[1], fmt_expr(s[2]), fmt_expr(s[3]))]
        out.extend(fmt_stmts(s[4], ind + '  '))
        out.append(ind + 'end;')
        return out
    raise L.LangError('statement %r' % (s,))


def fmt_stmts(stmts, ind):
    out = []
    for s in stmts:
        out.extend(fmt_stmt(s, ind))
    return out


def clause_stmts(c):
    """The clause as one statement list (as printed)."""
    f = c.flags
    out = list(c.decls) + list(f['chain'])
    if f['guard']:
        out.append(('cycle_guard', f['guard']))
    if f.get('mark'):
        out.append(('cycle_mark', f['mark']))
    return out + list(c.body)


def fmt_clause_body(c, ind='    '):
    return ['  begin'] + fmt_stmts(clause_stmts(c), ind) + ['  end;']


def fmt_clause(addr, c, why=None):
    """The transform's pass_1 clause lines (the extractor's)."""
    if c is None:
        return ['  { not lifted: %s }' % why.replace('{', '(').replace('}', ')'),
                '  pass_1 image 16#%06X residue;' % addr]
    lines = fmt_clause_body(c)
    words = ['pass_1', 'image', '16#%06X' % addr]
    if c.flags['rewrite']:
        words.append('rewrite')
    if c.hand:
        words.append('hand')
    if c.flags.get('dropped'):
        words.append('dropped')
    lines[0] = '  %s begin' % ' '.join(words)
    return lines


# --------------------------------------------------------------------------
# parsing

class Parser(L.Parser):
    def stmt(self):
        t = self.peek()
        if t == 'condition':
            self.i += 1
            e = self.expr()
            self.expect(';')
            return ('condition', e)
        if t in ('cycle_guard', 'cycle_mark'):
            self.i += 1
            n = self.next()
            self.expect(';')
            if n not in ALREADY:
                raise L.LangError('%s %s' % (t, n))
            return (t, n)
        if t == 'trace':
            self.i += 1
            s = self.next()
            self.expect(';')
            return ('trace', s[1:-1].replace("''", "'"))
        if t in ('copy', 'sum'):
            self.i += 1
            fields = [self.next()]
            while self.peek() == ',':
                self.i += 1
                fields.append(self.next())
            self.expect('from' if t == 'copy' else 'of')
            srcs = [self.primary()]
            while t == 'sum' and self.peek() == ',':
                self.i += 1
                srcs.append(self.primary())
            target = 'result'
            if self.peek() == 'to':
                self.i += 1
                target = self.next()
            self.expect(';')
            if t == 'copy':
                return ('copy', fields, srcs[0], target)
            return ('sum', fields, tuple(srcs), target)
        return super().stmt()

    def primary(self):
        t = self.peek()
        if t in ('bytes', 'words') and self.peek(1) in ('(', '@'):
            self.i += 1
            place = None
            if self.peek() == '@':
                self.i += 1
                place = int(self.next())
            self.expect('(')
            vals = []
            while self.peek() != ')':
                vals.append(int(self.next()))
                if self.peek() == ',':
                    self.i += 1
            self.expect(')')
            self.expect('[')
            ix = self.expr()
            self.expect(']')
            if place is not None:
                return ('cost', 'b' if t == 'bytes' else 'w', tuple(vals), ix, ('pos', place))
            return ('cost', 'b' if t == 'bytes' else 'w', tuple(vals), ix)
        return super().primary()


def parse_clause_body(text, rule, rewrite=False):
    """A clause's `begin ... end' read back into a Clause."""
    p = Parser(L.tokenize(text))
    stmts = p.body()
    if p.peek() is not None:
        raise L.LangError('text after the body: %r' % p.peek())
    return clause_of(stmts, rule, rewrite)


def clause_of(stmts, rule, rewrite=False):
    flags = {'chain': [], 'guard': None, 'rewrite': rewrite, 'trace': True, 'mark': None}
    decls = []
    i = 0
    while i < len(stmts) and stmts[i][0] == 'temp':
        decls.append(stmts[i])
        i += 1
    rest = stmts[i:]
    ks = [j for j, s in enumerate(rest) if s[0] == 'condition']
    if ks:
        flags['chain'] = rest[:ks[-1] + 1]
        rest = rest[ks[-1] + 1:]
    if rest and rest[0][0] == 'cycle_guard':
        flags['guard'] = rest[0][1]
        rest = rest[1:]
    if rest and rest[0][0] == 'cycle_mark':
        flags['mark'] = rest[0][1]
        rest = rest[1:]
    for s in L.walk(rest):
        if s[0] in ('condition', 'cycle_guard', 'cycle_mark', 'temp'):
            raise L.LangError('rule %d: %s out of place' % (rule, s[0]))
    return Clause(rule, flags, decls, rest)


# --------------------------------------------------------------------------
# the cost tables

def walk_exprs_stmt(s):
    """The expressions of a statement in printing order."""
    k = s[0]
    if k == 'set':
        return [s[1], s[2]]
    if k == 'call':
        return list(s[2])
    if k == 'condition':
        return [s[1]]
    if k == 'if':
        out = []
        for c, b in s[1]:
            out.append(c)
            for x in b:
                out.extend(walk_exprs_stmt(x))
        for x in s[2] or []:
            out.extend(walk_exprs_stmt(x))
        return out
    if k == 'for':
        out = [s[2], s[3]]
        for x in s[4]:
            out.extend(walk_exprs_stmt(x))
        return out
    return []


def costs_in(e, out):
    """The cost tables of e in printing order (left to right)."""
    if not isinstance(e, tuple):
        return
    k = e[0]
    if k == 'cost':
        out.append((e[1], e[2], e[4] if len(e) > 4 else None))
        costs_in(e[3], out)
        return
    if k == 'bin':
        costs_in(e[2], out)
        costs_in(e[3], out)
    elif k == 'un':
        costs_in(e[2], out)
    elif k == 'call':
        for a in e[2]:
            costs_in(a, out)
    elif k in ('addr',):
        costs_in(e[1], out)
    elif k == 'index':
        costs_in(e[2], out)
    elif k == 'path' and isinstance(e[1], tuple):
        costs_in(e[1], out)


def cost_order(c):
    """[(kind, values)] of the clause's tables in printing order."""
    return [(k, v) for k, v, _ in cost_nodes(c)]


def cost_nodes(c):
    """[(kind, values, extra)] in printing order (extra: ('off', o) from
    the lifter, ('pos', k) a written place, or None)."""
    out = []
    for s in clause_stmts(c):
        for e in walk_exprs_stmt(s):
            costs_in(e, out)
    return out


def cost_offsets(c):
    return [x[1] for _, _, x in cost_nodes(c)]


def map_costs(e, f):
    """e with each cost node replaced by f(node), in printing order."""
    if isinstance(e, tuple):
        if e and e[0] == 'cost':
            return f(('cost', e[1], e[2], map_costs(e[3], f)) + tuple(e[4:]))
        return tuple(map_costs(x, f) for x in e)
    if isinstance(e, list):
        return [map_costs(x, f) for x in e]
    return e


def set_cost_places(c, places):
    """The clause's cost nodes without the lifter's offsets: with places
    (the layout's numbers, in printing order) when given."""
    it = iter(places or [])

    def f(n):
        base = n[:4]
        return base + (('pos', next(it)),) if places else base
    c.flags['chain'] = [map_costs(s, f) for s in c.flags['chain']]
    c.body = [map_costs(s, f) for s in c.body]


def rule_tables(c):
    """([(name, kind)] in printing order, [(name, kind, values)] in the
    module's order) of a clause's cost tables."""
    nodes = cost_nodes(c)
    n = len(nodes)
    printed, layout = [], []
    places = [x[1] if x and x[0] == 'pos' else None for _, _, x in nodes]
    if any(p is not None for p in places):
        if sorted(places) != list(range(1, n + 1)):
            raise L.LangError('rule %d: the tables\' places are not 1..%d' % (c.rule, n))
    else:
        places = [n - k for k in range(n)]
    for (kind, vals, _), p in zip(nodes, places):
        printed.append(('cost_%d_%d' % (c.rule, p), kind))
    for p in range(1, n + 1):
        k = places.index(p)
        layout.append(('cost_%d_%d' % (c.rule, p), nodes[k][0], nodes[k][1]))
    return printed, layout


# --------------------------------------------------------------------------
# Pascal

class Emitter(L.Emitter):
    """A pass-1 action's statements as Pascal: `result' is the local
    `solution' (the new solution), `subject' the var parameter, il and
    inh the parameters; tables by the generator's names."""

    def __init__(self, rule, headings, tables):
        super().__init__(rule, headings)
        self.tables = tables            # [(name, kind)] in printing order
        self.ti = 0
        self.int_fields = set()         # the rule's own longwords that hold integers

    def path(self, e):
        base, sels = e[1], list(e[2])
        if isinstance(base, str) and base in ('result', 'subject', 'il', 'inh'):
            if base == 'result':
                text, cls = 'solution', 'isp'
            elif base == 'subject':
                if not sels:
                    return 'addr(subject)', 'isp'
                text, cls = 'subject', 'rec'
            elif base == 'il':
                text, cls = 'il', 'node'
            else:
                text, cls = 'inh', 'inh'
            for s in sels:
                text, cls = self.select(text, cls, s)
            return text, cls
        return super().path(e)

    def select(self, text, cls, s):
        if cls == 'node' and re.match(r'sb\d+$', s):
            # a node's byte read as signed (ext.w)
            return 'p1_snode_ptr_t(%s)^.sb[%d]' % (text, int(s[2:])), 'i16'
        m = re.match(r'l(\d+)$', s)
        if m and int(m.group(1)) in self.int_fields and cls in ('rec', 'isp', 'sp', 'up', 'lr'):
            r = self.deref(text, cls)
            off = int(m.group(1))
            return 'p1_int_fields_ptr_t(addr(%s))^.i[%d]' % (r, (off - 352) // 4), 'i32'
        if cls == 'other:cargs_$options_t':
            return '%s.%s' % (text, s), ('set' if s.startswith('flags') else 'bool')
        m = re.match(r'c(34[2-8])$', s)
        if m and cls in ('rec', 'isp', 'sp', 'up', 'lr'):
            r = self.deref(text, cls)
            return 'p1_already_ptr_t(addr(%s))^.%s' % (r, ALREADY[int(m.group(1)) - 342]), 'bool'
        return super().select(text, cls, s)

    def expr1(self, e):
        if e[0] == 'num' and e[1] < 0:
            # a negative number is an operand of & and the others too
            t, c = super().expr1(e)
            return '(%s)' % t, c
        if e[0] == 'index' and e[1] == 'lir_4090':
            return 'lir_4090[%s]' % self.expr(e[2]), 'lr'
        if e[0] == 'index' and re.match(r'readonly_l\d+$', e[1]):
            return 'p1_readonly_ptr_t(addr(isc_readonly_tables))^.l[%d + %s]' % (
                int(e[1][10:]) // 4, self.paren(e[2], 4)), 'i32'
        if e[0] == 'index' and re.match(r'readonly_b\d+$', e[1]):
            # a byte table of isc_readonly_tables at +N: the module's view
            return 'p1_readonly_ptr_t(addr(isc_readonly_tables))^.b[%d + %s]' % (
                int(e[1][10:]), self.paren(e[2], 4)), 'u8'
        if e[0] == 'bin' and e[1] in ('=', '<>') and e[3] == ('nil',):
            t, c = self.expr1(e[2])
            if c in ('i32', 'i16', 'u16', 'u8', 'num'):
                return '%s %s 0' % (t, e[1]), 'bool'
        if e[0] == 'bin' and e[1] in ('and', 'or'):
            # Pascal binds and/or tighter than the comparisons
            def opnd(x):
                t, _ = self.expr1(x)
                if x[0] == 'bin' and not (x[1] == 'and' or (x[1] == 'or' and e[1] == 'or')):
                    return '(%s)' % t
                if x[0] == 'un' and x[1] == '-':
                    return '(%s)' % t
                return t
            return '%s %s %s' % (opnd(e[2]), e[1], opnd(e[3])), 'bool'
        if e[0] == 'un' and e[1] == 'not':
            t, _ = self.expr1(e[2])
            return 'not ' + ('(%s)' % t if e[2][0] == 'bin' else t), 'bool'
        if e[0] == 'bin' and e[1] == 'in':
            return '%s in %s' % (self.expr(e[2]), self.expr(e[3])), 'bool'
        if e[0] == 'cost':
            if self.ti >= len(self.tables):
                raise L.LangError('rule %d: more tables than laid out' % self.rule)
            name, kind = self.tables[self.ti]
            self.ti += 1
            return '%s[%s]' % (name, self.expr(e[3], 'i16')), 'i16'
        return super().expr1(e)

    def call_text(self, name, args):
        h = self.h.get(name)
        if h is not None:
            ps = h['params']
            out = []
            fix = False
            for k, a in enumerate(args):
                if a == ('path', 'subject', []) and k < len(ps) and (
                        ps[k][1] != 'value' or not h['val_param']):
                    fix = True
            if fix:
                args2 = [('path', '@subject_rec', []) if (a == ('path', 'subject', []) and
                         k < len(ps) and (ps[k][1] != 'value' or not h['val_param'])) else a
                         for k, a in enumerate(args)]
                return super().call_text(name, args2)
        return super().call_text(name, args)

    def stmt(self, s, ind):
        k = s[0]
        if k in ('copy', 'sum'):
            out = []
            for x in expand(s):
                out.extend(self.stmt(x, ind))
            return out
        if k == 'trace':
            return [ind + 'if %s then begin' % TRACE,
                    ind + "  write('%s');" % s[1].replace("'", "''"),
                    ind + '  writeln;',
                    ind + 'end;']
        if k in ('condition', 'cycle_guard', 'cycle_mark'):
            raise L.LangError('rule %d: %s in the body' % (self.rule, k))
        return super().stmt(s, ind)


def subject_rec_path(em):
    """The by-reference subject (the record itself)."""
    return 'subject', 'rec'


_orig_path = Emitter.path


def _path(self, e):
    if e[1] == '@subject_rec':
        return 'subject', 'rec'
    return _orig_path(self, e)


Emitter.path = _path


def check_emit(c, kind, headings, gen):
    """Raise LangError when the generator cannot write the clause."""
    for k, v in EXTRA_GLOBALS.items():
        L.GLOBALS.setdefault(k, v)
    tables, _ = rule_tables(c)
    gen.routine(c.rule, {'p1_clause': c, 'kind': kind}, headings, tables)


POINTER_ATTRS = ('before_transform', 'il', 'inherited_attributes', 'base_register',
                 'index_register', 'false_label', 'live_range', 'live_range_of_imaginary_part',
                 'object_with_name')


def int_fields(stmts, headings):
    """The rule's own longwords (+352 ..) the clause gives numbers: set
    from a number other than 0, arithmetic or an integer function, or
    compared with a number other than 0."""
    out = set()

    def lfield(p):
        if p[0] == 'path' and p[2]:
            m = re.match(r'l(\d+)$', p[2][-1])
            if m and int(m.group(1)) >= 352 and int(m.group(1)) % 4 == 0:
                return int(m.group(1))
        return None

    def numeric(e):
        if e[0] == 'num':
            return e[1] != 0
        if e[0] == 'bin' and e[1] in ('+', '-', '*', 'div', 'mod', '&', '!'):
            return True
        if e[0] == 'un' and e[1] == '-':
            return True
        if e[0] == 'cost':
            return True
        if e[0] == 'path' and e[2]:
            n = e[2][-1]
            if re.match(r'(w|b|sb)\d+$', n):
                return True
            a = L.attrs().get(n)
            if a and a[2] is None and n not in POINTER_ATTRS:
                return True
        if e[0] == 'call':
            h = headings.get(e[1])
            return (bool(h) and h['ret'] in ('i32', 'i16', 'u8')) or e[1] in L.BUILTINS
        return False

    def scan(e):
        if not isinstance(e, tuple):
            return
        if e[0] == 'bin' and e[1] in ('=', '<>', '<', '<=', '>', '>=', 'u<', 'u<=', 'u>', 'u>='):
            for a, b in ((e[2], e[3]), (e[3], e[2])):
                f = lfield(a)
                if f is not None and numeric(b):
                    out.add(f)
        for x in e[1:]:
            if isinstance(x, tuple):
                scan(x)
            elif isinstance(x, list):
                for y in x:
                    scan(y)
    for s in L.walk(stmts):
        if s[0] == 'set':
            f = lfield(s[1])
            if f is not None and numeric(s[2]):
                out.add(f)
        for e in (walk_exprs_stmt(s) if s[0] != 'if' else [c for c, _ in s[1]]):
            scan(e)
    return out


def _coerce(self, text, cls, want):
    if cls == 'nil' and want in ('i32', 'i16', 'u16', 'u8'):
        return '0'
    if cls == 'bool' and want in ('u8', 'char'):
        # a boolean kept in a byte of the rule's own (Rev 8.89's true is
        # 16#FF: the tests read bit 7)
        return ('255 * ord(%s)' if want == 'u8' else 'chr(255 * ord(%s))') % text
    return L.Emitter.coerce(self, text, cls, want)


Emitter.coerce = _coerce


def paths_in(s):
    """The paths a statement reads or sets (its expressions')."""
    out = []

    def walk(e):
        if isinstance(e, tuple):
            if e and e[0] == 'path':
                out.append(e)
            for x in e[1:]:
                walk(x)
        elif isinstance(e, list):
            for x in e:
                walk(x)
    walk(s)
    return out
