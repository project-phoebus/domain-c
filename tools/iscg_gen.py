#!/usr/bin/env python3
"""iscg_gen.py - the ISC generator: Pascal of the image's shape from the rule file.

    tools/iscg_gen.py [--rules DIR] [--out DIR]      write the generated units
    tools/iscg_gen.py --check                         fail if the committed
                                                      units differ from what
                                                      the rule file generates

The rule file (moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/rules/,
written by tools/iscg_extract.py from cc.a88k and to be completed by
hand: docs/iscg-design.md) is the ISC generator's input; this is the
generator (docs/questions.md 151).  It emits, into the iscg_input
derived-object directory (--out; default moon_unit/isc_prism_dervobjs/
dseeaggs/iscg_input/hd69fbe76.000/iscg_input):

  isc_pattern_matcher.pas  hard_work (the generator's fixed text) and
                           pattern_matcher: the fixed traces around
                           `case solution^.kind of' with an arm per
                           solution kind (a chain rule's tries) and, for
                           a proper_subtree, `case solution^.il_kind
                           of' with an arm per IL operator some pattern
                           names; each arm the tries of the rules tried
                           under it, in rule order, a try being the
                           pattern's tests (preorder: a child's kind,
                           its operator, its children) and a call of
                           hard_work.  Data: the pass-1 action table
                           (transform_<r>_pass_1, extern until the action
                           modules are generated) and the two per-rule
                           flag tables (check_permissible,
                           no_could_deadlock_child).
  isc_pass_2_main.pas      pass_2 (fixed text) and the pass-2 action
                           table (transform_<r>_pass_2, extern; an empty
                           action too, docs/rev889-patterns.md 165).
  isc_vars.pas             no code: the sections isc_tool_generated_
                           readonly_tables (each rule's result kind, the
                           six opcode maps) and isc_readonly_tables (the
                           ISC's own tables, from readonly.isc).
  isc_pass_1_main.pas      pass 1: the operator routines from the operator
                           declarations, isc_pass_1_begin_compilation's
                           dispatch from their names, and the fixed text
                           (pass_1, cross_product_to_solutions_of_parent,
                           isc_unrecognized_il_node, the dispatchers):
                           tools/iscg_pass1.py.
  iscg_names.txt           the manifest: each generated anonymous
                           routine's name and its address in cc.a88k
                           (from the rule file's `image' clauses), for
                           the data check (tools/cc_datacheck.py), and
                           the pass-2 modules' files, A5s and code
                           ranges, for tools/cc_isc_check.py.
  isc_pass_2_NN_topic.pas  a section's pass-2 actions, from the
                           transforms' pass_2 bodies (tools/iscg_p2gen.py,
                           tools/iscg_p2lang.py), for each section none of
                           whose actions is still residue.

The attribute names of the rule file are the image's (dump_solution's,
isc_print_il_node's), and isc_solution_fields.ins.pas and
isc_attribute_records.ins.pas name their fields after them
(docs/questions.md 267, 271): an attribute is read through the field of
its name (tools/iscg_p2lang.py sol_path, tools/iscg_pass1.py inh_path).
"""
import argparse
import difflib
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
ISCG = 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input'
RULES_DIR = os.path.join(ROOT, ISCG, 'rules')
OUT_DIR = os.path.join(ROOT, ISCG, 'hd69fbe76.000', 'iscg_input')
OUTPUTS = ['isc_pattern_matcher.pas', 'isc_pass_2_main.pas', 'isc_vars.pas', 'iscg_names.txt',
           'isc_pass_1_main.pas']

INCLUDES = '''%include '/sys/ins/base.ins.pas';
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


class Bad(Exception):
    pass


# --------------------------------------------------------------------------
# the rule file

def strip_comments(text):
    out, depth = [], 0
    for ch in text:
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        elif depth == 0:
            out.append(ch)
    return ''.join(out)


TOKEN = re.compile(r'\s*(16#[0-9A-Fa-f]+|\$\d+|<-|->|[A-Za-z_][A-Za-z0-9_$]*|[+-]?\d+|\S)')


def tokens(text):
    pos, out = 0, []
    text = text.rstrip()
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            break
        out.append(m.group(1))
        pos = m.end()
    return out


def num(t):
    return int(t[3:], 16) if t.startswith('16#') else int(t)


class Rules:
    def __init__(self, d):
        self.kinds = []
        self.attributes = []
        self.operators = []
        self.maps = []
        self.sections = []
        self.transforms = {}
        self.readonly = None
        for fn in sorted(os.listdir(d)):
            if fn.endswith('.isc'):
                self.parse(fn, strip_comments(open(os.path.join(d, fn)).read()))
        n = max(self.transforms)
        if sorted(self.transforms) != list(range(1, n + 1)):
            raise Bad('the transforms are not numbered 1..%d' % n)
        self.nrules = n

    def parse(self, fn, text):
        text, bodies = iscg_p2gen.extract_bodies(text)     # the pass_2 bodies
        text, p1bodies = iscg_p1gen.extract_bodies(text)   # the pass_1 clauses
        ts = tokens(text)
        i = 0

        def expect(t):
            nonlocal i
            if ts[i] != t:
                raise Bad('%s: expected %r, found %r (token %d)' % (fn, t, ts[i], i))
            i += 1

        def upto(t):
            nonlocal i
            j = ts.index(t, i)
            out = ts[i:j]
            i = j + 1
            return out

        while i < len(ts):
            t = ts[i]
            i += 1
            if t == 'kinds':
                self.kinds = [x for x in upto(';') if x != ',']
            elif t == 'attribute':
                self.attributes.append(upto(';'))
            elif t == 'operator':
                # isc_pass_1_main's operator declarations (tools/iscg_pass1.py)
                op, i = iscg_pass1.parse_operator(ts, i, fn, num)
                self.operators.append(op)
            elif t == 'map':
                name = ts[i]
                i += 1
                body = upto(';')
                ents = []
                k = 0
                while k < len(body):
                    if body[k] == ',':
                        k += 1
                        continue
                    if body[k + 1] != '->':
                        raise Bad('%s: map %s' % (fn, name))
                    ents.append((body[k], body[k + 2]))
                    k += 3
                self.maps.append((name, ents))
            elif t == 'section':
                body = upto(';')
                sec = {'number': num(body[0]), 'topic': body[1], 'transforms': []}
                if 'image' in body:
                    j = body.index('image')
                    sec['p1_a5'] = num(body[j + 3])
                    sec['p2_a5'] = None if body[j + 7] == 'none' else num(body[j + 7])
                self.sections.append(sec)
            elif t == 'transform':
                r = num(ts[i])
                i += 1
                kind = ts[i]
                i += 1
                expect('<-')
                j = i
                while ts[j] not in ('pass_1', 'check_permissible', 'no_could_deadlock_child',
                                    'end'):
                    j += 1
                alts = parse_pattern(ts[i:j], fn, r)
                i = j
                tr = {'rule': r, 'kind': kind, 'alts': alts, 'flags': set(), 'p1': None,
                      'p2': None, 'p2_empty': False, 'section': self.sections[-1]['number']}
                while ts[i] != 'end':
                    if ts[i] in ('check_permissible', 'no_could_deadlock_child'):
                        tr['flags'].add(ts[i])
                        i += 1
                        if ts[i] == ';':
                            i += 1
                    elif ts[i] in ('pass_1', 'pass_2'):
                        which = ts[i]
                        body = upto_from(ts, i + 1, ';')
                        i += len(body) + 2
                        if body[:1] == ['image']:
                            tr['p1' if which == 'pass_1' else 'p2'] = num(body[1])
                            if 'empty' in body:
                                tr['p2_empty'] = True
                            if which == 'pass_2':
                                iscg_p2gen.clause(tr, body, bodies)
                            else:
                                iscg_p1gen.clause(tr, body, p1bodies)
                    else:
                        raise Bad('%s: transform %d: %r' % (fn, r, ts[i]))
                expect('end')
                expect(';')
                if r in self.transforms:
                    raise Bad('transform %d twice' % r)
                self.transforms[r] = tr
                self.sections[-1]['transforms'].append(r)
            elif t == 'readonly':
                # the words are read from the text: hexadecimal digits
                # do not tokenize
                name = ts[i]
                size = num(ts[i + 1])
                m = re.search(r'readonly\s+%s\s+%d\s+bytes\s*\n(.*?)\nend;' % (name, size),
                              text, re.S)
                if not m:
                    raise Bad('%s: readonly %s' % (fn, name))
                words = []
                for line in m.group(1).splitlines():
                    f = line.split()
                    if not f:
                        continue
                    if num(f[0][1:]) != 2 * len(words):
                        raise Bad('%s: offset %s' % (fn, f[0]))
                    words.extend(int(w, 16) for w in f[1:])
                i = ts.index('end', i) + 2
                if 2 * len(words) != size:
                    raise Bad('%s: %d words for %d bytes' % (fn, len(words), size))
                self.readonly = (name, words)
            else:
                raise Bad('%s: unexpected %r' % (fn, t))


def upto_from(ts, i, t):
    return ts[i:ts.index(t, i)]


def parse_pattern(ts, fn, r):
    """[(subject, children)] where children = {k: spec}, spec = ('kind',
    name) | ('kinds', [names]) | ('op', name, children)."""
    alts, pending, i = [], [], 0

    def children(i):
        # ts[i] == '('
        kids = {}
        i += 1
        while ts[i] != ')':
            if ts[i] == ',':
                i += 1
                continue
            if not ts[i].startswith('$') or ts[i + 1] != ':':
                raise Bad('%s: transform %d: pattern at %r' % (fn, r, ts[i]))
            k = int(ts[i][1:])
            i += 2
            if ts[i] == '[':
                j = ts.index(']', i)
                kids[k] = ('kinds', [x for x in ts[i + 1:j] if x != ','])
                i = j + 1
            elif ts[i + 1] == '(':
                name = ts[i]
                sub, i = children(i + 1)
                kids[k] = ('op', name, sub)
            else:
                kids[k] = ('kind', ts[i])
                i += 1
        return kids, i + 1

    while i < len(ts):
        if ts[i] == '|':
            i += 1
            continue
        pending.append(ts[i])
        i += 1
        if i < len(ts) and ts[i] == '(':
            kids, i = children(i)
            alts.extend((p, kids) for p in pending)
            pending = []
    alts.extend((p, {}) for p in pending)
    return alts


# --------------------------------------------------------------------------
# the enumerations

def il_names():
    text = open(os.path.join(OUT_DIR, 'isc_enumeration.ins.pas')).read()
    body = text[text.index('il$t = ('):]
    body = body[:body.index(');')]
    names = re.findall(r'\b(il_[a-z0-9_]+|il\$k_max)\b', strip_comments(body))
    return names


def readonly_fields():
    """isc_types.ins.pas's isc_readonly_tables_t: [(name, lo, hi, type)]."""
    text = strip_comments(open(os.path.join(ROOT, 'lang2/source/isc/isc_types.ins.pas')).read())
    body = text[text.index('isc_readonly_tables_t = record') + len('isc_readonly_tables_t = record'):]
    body = body[:body.index('end;')]
    out = []
    for m in re.finditer(r'(\w+)\s*:\s*array\s*\[\s*(\d+)\s*\.\.\s*(\d+)\s*\]\s*of\s*(\w+)\s*;',
                         body):
        out.append((m.group(1), int(m.group(2)), int(m.group(3)), m.group(4).lower()))
    if not out:
        raise Bad('isc_readonly_tables_t not found')
    return out


def opcode_names():
    path = os.path.join(ROOT, 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/'
                        'opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas')
    text = strip_comments(open(path).read())
    text = text[text.index('opc$t = (') + len('opc$t = ('):]
    text = text[:text.index(')')]
    return [n.strip().lower() for n in text.split(',')]


# --------------------------------------------------------------------------
# emitting Pascal

def wrap(items, indent, width=78, sep=', ', end=''):
    lines, cur = [], indent
    for k, it in enumerate(items):
        s = it + (sep.rstrip() if k < len(items) - 1 else end)
        if len(cur) + len(s) + 1 > width and cur.strip():
            lines.append(cur.rstrip())
            cur = indent
        cur += s + ' '
    if cur.strip():
        lines.append(cur.rstrip())
    return lines


def runs(values, fmt):
    """Initializer items with `n of v' for runs of three or more."""
    out, i = [], 0
    while i < len(values):
        j = i
        while j < len(values) and values[j] == values[i]:
            j += 1
        if j - i >= 3:
            out.append('%d of %s' % (j - i, fmt(values[i])))
        else:
            out.extend(fmt(values[i]) for _ in range(j - i))
        i = j
    return out


class Gen:
    def __init__(self, rules):
        self.r = rules
        self.ils = il_names()
        self.kinds = rules.kinds
        self.il_index = {n: k for k, n in enumerate(self.ils)}

    def is_kind(self, name):
        isil = ('il_' + name) in self.il_index
        iskind = name in self.kinds
        if isil and iskind:
            raise Bad('%s is both a solution kind and an operator' % name)
        if not isil and not iskind:
            raise Bad('%s is neither a solution kind nor an operator' % name)
        return iskind

    # ---- the matcher
    def arms(self, guards=False):
        """[(field, value, [(rule, tests)])] in the case statements' order
        (guards: the tests as (path, field, op, value), the decoded
        matcher's form, for tools/iscg_extract.py's round trip)."""
        by = {}
        for r in range(1, self.r.nrules + 1):
            for subj, kids in self.r.transforms[r]['alts']:
                if self.is_kind(subj):
                    if kids:
                        raise Bad('rule %d: a chain pattern with children' % r)
                    key = (108, self.kinds.index(subj))
                else:
                    key = (98, self.il_index['il_' + subj])
                by.setdefault(key, []).append(
                    (r, self.guard(kids, ()) if guards else self.tests(kids, 'solution')))
        return [(f, v, by[(f, v)]) for f, v in sorted(by, key=lambda k: (-k[0], k[1]))]

    def guard(self, kids, path):
        out = []
        for k in sorted(kids):
            p = path + (k,)
            spec = kids[k]
            if spec[0] == 'kind':
                out.append((p, 108, '=', self.kinds.index(spec[1])))
            elif spec[0] == 'kinds':
                out.append((p, 108, 'in', sum(1 << self.kinds.index(x) for x in spec[1])))
            else:
                out.append((p, 108, '=', self.kinds.index('proper_subtree')))
                out.append((p, 98, '=', self.il_index['il_' + spec[1]]))
                out.extend(self.guard(spec[2], p))
        return out

    def tests(self, kids, base):
        out = []
        for k in sorted(kids):
            p = '%s^.children[%d]' % (base, k)
            spec = kids[k]
            if spec[0] == 'kind':
                self.kind_ok(spec[1])
                out.append('(%s^.kind = solution$%s)' % (p, spec[1]))
            elif spec[0] == 'kinds':
                for x in spec[1]:
                    self.kind_ok(x)
                out.append('(%s^.kind in [%s])' % (
                    p, ', '.join('solution$' + x for x in spec[1])))
            else:
                if 'il_' + spec[1] not in self.il_index:
                    raise Bad('no operator %s' % spec[1])
                out.append('(%s^.kind = solution$proper_subtree)' % p)
                out.append('(%s^.il_kind = il_%s)' % (p, spec[1]))
                out.extend(self.tests(spec[2], p))
        return out

    def kind_ok(self, name):
        if name not in self.kinds:
            raise Bad('no solution kind %s' % name)

    def matcher_case(self):
        L = []
        arms = self.arms()
        call = ('hard_work(solution, work_list, solutions_of_parent, il, inh, '
                'permissible, %d);')

        def emit_tries(tries, ind):
            # one `if' per test, nested: the image tests in order and
            # leaves at the first that fails (a child is read only when
            # the tests before it hold; dpc evaluates `and' whole)
            for r, tests in tries:
                d = ind
                for t in tests:
                    t = t[1:-1]
                    line = d + 'if ' + t + ' then'
                    if len(line) > 78 and ' in [' in t:
                        a, b = t.split(' in [', 1)
                        items = [x.strip() for x in b[:-1].split(',')]
                        L.append(d + 'if ' + a + ' in')
                        w = wrap(items, d + '     ', end='] then')
                        w[0] = d + '    [' + w[0].strip()
                        L.extend(w)
                    else:
                        L.append(line)
                    d += '  '
                L.append(d + call % r)
        L.append('  case solution^.kind of')
        kind_arms = {v: t for f, v, t in arms if f == 108}
        il_arms = [(v, t) for f, v, t in arms if f == 98]
        prop = self.kinds.index('proper_subtree')
        empty = [k for k in range(1, len(self.kinds) - 1)
                 if k not in kind_arms and k != prop]
        for k in range(1, len(self.kinds) - 1):
            if k in kind_arms:
                L.append('    solution$%s: begin' % self.kinds[k])
                emit_tries(kind_arms[k], '      ')
                L.append('      end;')
            elif k == prop:
                L.append('    solution$proper_subtree:')
                L.append('      case solution^.il_kind of')
                for v, tries in il_arms:
                    L.append('        %s: begin' % self.ils[v])
                    emit_tries(tries, '          ')
                    L.append('          end;')
                L.append('        otherwise')
                L.extend('          ' + x for x in (UNRECOGNIZED % ('il_kind', 'il_kind')).split('\n'))
                L.append('        end;')
        L.extend(wrap(['solution$' + self.kinds[k] for k in empty], '    ', end=':'))
        L.append('      ;')
        L.append('    otherwise')
        L.extend('      ' + x for x in (UNRECOGNIZED % ('kind', 'kind')).split('\n'))
        L.append('    end;')
        return L

    def isc_pattern_matcher(self):
        n = self.r.nrules
        T = self.r.transforms
        L = [PM_HEAD.rstrip('\n'), '']
        L.append(INCLUDES.rstrip('\n'))
        L.append('')
        L.append(PM_TYPES.rstrip('\n'))
        L.append('')
        L.append('{ The pass-1 actions (the 25 pass-1 modules: transform_<r>_pass_1, r the')
        L.append('  rule; not generated yet). }')
        for r in range(1, n + 1):
            L.append('procedure transform_%d_pass_1(var subject: isc_solution_t; il: univ_ptr;' % r)
            L.append('    inh: inherited_attributes_ptr_t; var work, result: isc_solution_ptr_t);')
            L.append('    options(val_param); extern;')
        L.append('')
        L.append('var')
        L.append('  { +0x000: by rule, its pass-1 action (hard_work calls it). }')
        L.append('  pm_pass_1_action: array [1..%d] of pm_pass_1_action_t := [' % n)
        L.extend(wrap(['addr(transform_%d_pass_1)' % r for r in range(1, n + 1)],
                      '      ', end='];'))
        L.append('  pm_unused_8cc: integer32;          { +0x8CC: nothing reads or sets it }')
        L.append('  { +0x8D0: by rule, whether its result kind must be permissible. }')
        L.append('  pm_check_permissible: array [1..%d] of boolean := [' % n)
        L.extend(wrap(runs([('check_permissible' in T[r]['flags']) for r in range(1, n + 1)],
                           lambda b: 'true' if b else 'false'), '      ', end='];'))
        L.append('  pm_proper_subtree_seen: boolean;   { +0xB04: a proper_subtree kept in')
        L.append('                                       this call of pattern_matcher }')
        L.append('  { +0xB08: by rule, whether none of the subject\'s children may hold a')
        L.append('    register that may deadlock the scheduler (else at most one). }')
        L.append('  pm_no_could_deadlock_child: array [1..%d] of boolean := [' % n)
        L.extend(wrap(runs([('no_could_deadlock_child' in T[r]['flags'])
                            for r in range(1, n + 1)],
                           lambda b: 'true' if b else 'false'), '      ', end='];'))
        L.append('')
        L.append(HARD_WORK.rstrip('\n'))
        L.append('')
        pm = PATTERN_MATCHER.rstrip('\n')
        a, b = pm.split('@CASE@\n')
        L.append(a.rstrip('\n'))
        L.extend(self.matcher_case())
        L.append(b.rstrip('\n'))
        return '\n'.join(L) + '\n'

    # ---- pass 2
    def isc_pass_2_main(self):
        n = self.r.nrules
        L = [P2_HEAD.rstrip('\n'), '']
        L.append(INCLUDES.rstrip('\n'))
        L.append('')
        L.append(P2_TYPES.rstrip('\n'))
        L.append('')
        L.append('{ The pass-2 actions (the 25 pass-2 modules: transform_<r>_pass_2, r the')
        L.append('  rule; not generated yet). }')
        for r in range(1, n + 1):
            L.append('procedure transform_%d_pass_2(var self: isc_solution_t;' % r)
            L.append('    subject: isc_solution_ptr_t; var result: isc_solution_t;')
            L.append('    solution: isc_solution_ptr_t); options(val_param); extern;')
        L.append('')
        L.append('var')
        L.append('  { +0x000: by rule, its pass-2 action (pass_2 calls it). }')
        L.append('  p2_pass_2_action: array [1..%d] of p2_pass_2_action_t := [' % n)
        L.extend(wrap(['addr(transform_%d_pass_2)' % r for r in range(1, n + 1)],
                      '      ', end='];'))
        L.append('')
        L.append(PASS_2.rstrip('\n'))
        return '\n'.join(L) + '\n'

    # ---- isc_vars
    def isc_vars(self):
        n = self.r.nrules
        T = self.r.transforms
        ops = opcode_names()
        L = [VARS_HEAD.rstrip('\n'), '']
        L.append("%include 'lang2/source/isc/isc_var_defines.ins.pas';")
        L.append(INCLUDES.rstrip('\n'))
        L.append('')
        L.append('{ isc_tool_generated_readonly_tables: each rule\'s result kind, then the')
        L.append('  opcode maps by il$t (isc.pvt.pas declares the section). }')
        L.append('define isc_tool_generated_readonly_tables := [')
        items = runs([T[r]['kind'] for r in range(1, n + 1)], lambda k: 'ord(solution$%s)' % k)
        L.append('    [')
        L.extend(wrap(items, '      ', end='],'))
        maps = dict(self.r.maps)
        for name in MAP_ORDER:
            ents = {('il_' + a): b for a, b in maps.get(name, [])}
            for a in ents:
                if a not in self.il_index:
                    raise Bad('map %s: no operator %s' % (name, a))
            vals = []
            for il in self.ils:
                if il in ents:
                    o = 'opc$' + ents[il]
                    if o not in ops:
                        raise Bad('map %s: no opcode %s' % (name, o))
                    vals.append(o)
                else:
                    vals.append(None)
            L.append('    { %s }' % name)
            L.append('    [')
            L.extend(wrap(runs(vals, lambda v: '0' if v is None else 'ord(%s)' % v), '      ',
                          end='],'))
        L.append('    0];')
        L.append('')
        name, words = self.r.readonly
        data = b''.join(bytes([w >> 8, w & 255]) for w in words)
        L.append('{ %s: the ISC\'s own tables (readonly.isc), by the views of' % name)
        L.append('  isc_types.ins.pas\'s isc_readonly_tables_t, which declares the section. }')
        L.append('define %s := [' % name)
        fields = readonly_fields()
        off = 0
        for k, (fname, lo, hi, typ) in enumerate(fields):
            size = {'char': 1, 'integer': 2, 'integer32': 4}[typ]
            vals = []
            for j in range(hi - lo + 1):
                vals.append(int.from_bytes(data[off:off + size], 'big', signed=True))
                off += size
            fmt = (lambda v: 'chr(%d)' % (v & 255)) if typ == 'char' else str
            L.append('    { %s }' % fname)
            L.append('    [')
            L.extend(wrap(runs(vals, fmt), '      ', end=']];' if k == len(fields) - 1 else '],'))
        if off != len(data):
            raise Bad('isc_readonly_tables_t covers %d bytes of %d' % (off, len(data)))
        return '\n'.join(L) + '\n'

    def names(self):
        L = ['# iscg_names.txt - generated by tools/iscg_gen.py from the rule file: each',
             '# anonymous routine the generated units name, and its address in cc.a88k',
             '# (the rule file\'s image clauses).  NAME<TAB>ADDRESS.',
             '# tools/cc_isc_check.py also reads the modules and units:',
             '#   module<TAB>FILE<TAB>A5<TAB>START<TAB>END  an anonymous module (A5 `-\': no',
             '#                                           routine loads one)',
             '#   unit<TAB>FILE<TAB>named                   a named unit before anonymous code']
        L.extend(iscg_p1gen.manifest_lines(self.r))
        L.extend(self.p2_manifest_lines())
        for r in range(1, self.r.nrules + 1):
            t = self.r.transforms[r]
            if t['p1'] is not None:
                L.append('transform_%d_pass_1\t0x%06X' % (r, t['p1']))
            if t['p2'] is not None:
                L.append('transform_%d_pass_2\t0x%06X' % (r, t['p2']))
        return '\n'.join(L) + '\n'

    def p2_manifest_lines(self):
        return iscg_p2gen.manifest_lines(self.r)

    def all(self):
        out = {'isc_pattern_matcher.pas': self.isc_pattern_matcher(),
               'isc_pass_2_main.pas': self.isc_pass_2_main(),
               'isc_vars.pas': self.isc_vars(),
               'iscg_names.txt': self.names(),
               'isc_pass_1_main.pas': self.isc_pass_1_main()}
        # the pass-2 modules of the sections whose actions are all written
        out.update(iscg_p2gen.modules(self, INCLUDES, GEN_NOTE))
        # the pass-1 modules likewise (tools/iscg_p1gen.py)
        out.update(iscg_p1gen.modules(self, INCLUDES, GEN_NOTE))
        return out

    # ---- isc_pass_1_main (tools/iscg_pass1.py)
    def isc_pass_1_main(self):
        # each operator's derived permissible sets: by il$t and child
        # position, the union of the kinds its patterns test there
        unions = {}
        for f, v, tries in self.arms(guards=True):
            if f != 98:
                continue
            for r, guard in tries:
                for path, fld, op, val in guard:
                    if len(path) == 1 and fld == 108:
                        u = unions.setdefault(v, {})
                        u[path[0]] = u.get(path[0], 0) | ((1 << val) if op == '=' else val)
        import iscg_text
        return iscg_pass1.emit_unit(self.r, unions, self.kinds, self.il_index, iscg_text)


MAP_ORDER = ['opcode_rr_reversed', 'opcode_rr', 'opcode_immediate', 'opcode_double',
             'opcode_immediate_negated', 'opcode_single']

sys.path.insert(0, HERE)
import iscg_pass1  # noqa: E402
from iscg_text import (PM_HEAD, PM_TYPES, HARD_WORK, PATTERN_MATCHER,  # noqa: E402
                       P2_HEAD, P2_TYPES, PASS_2, VARS_HEAD, UNRECOGNIZED, GEN_NOTE)
import iscg_p2gen  # noqa: E402
import iscg_p1gen  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--rules', default=RULES_DIR)
    ap.add_argument('--out', default=OUT_DIR)
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    try:
        out = Gen(Rules(a.rules)).all()
    except (Bad, iscg_p2gen.L.LangError) as e:
        sys.exit('iscg_gen: %s' % e)
    if a.check:
        bad = 0
        for fn, text in out.items():
            path = os.path.join(a.out, fn)
            try:
                have = open(path).read()
            except OSError:
                have = ''
            if have != text:
                bad = 1
                print('iscg_gen --check: %s differs from what the rule file generates:'
                      % os.path.relpath(path, ROOT))
                for line in list(difflib.unified_diff(have.splitlines(), text.splitlines(),
                                                      'committed', 'generated',
                                                      lineterm=''))[:20]:
                    print('  ' + line)
        if not bad:
            print('iscg_gen --check: %d generated files agree with the rule file' % len(out))
        sys.exit(bad)
    for fn, text in out.items():
        with open(os.path.join(a.out, fn), 'w') as f:
            f.write(text)
    print('iscg_gen: wrote %s' % ', '.join(out))


if __name__ == '__main__':
    main()
