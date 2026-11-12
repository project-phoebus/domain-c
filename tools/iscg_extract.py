#!/usr/bin/env python3
"""iscg_extract.py - the ISC generator's input, recovered from cc.a88k.

    tools/iscg_extract.py [--binary B] [--out DIR] [--json FILE]

Writes the rule file of the ISC generator (docs/iscg-design.md,
docs/questions.md 151: the generated ISC is rebuilt as the generator's
input plus tools/iscg_gen.py) under DIR (default
moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/rules):

  declarations.isc   the solution kinds, the attribute declarations
                     (dump_solution's names, with the offset each is
                     read at), the operator declarations (isc_pass_1_
                     main's isc_<kind>[_<op>] routines lifted by
                     tools/iscg_pass1.py: their il$t, children,
                     inherited attributes and permissible sets, or
                     `fixed' for those it does not understand), and the
                     six opcode maps
                     (isc_tool_generated_readonly_tables by il$t)
  NN_topic.isc       one file per section, NN 01..25 in the image's
                     address order (the pass-1 and pass-2 modules of the
                     section: docs/iscg-design.md 1.2), each rule's
                     header in rule order: number, result kind, pattern
                     (the IL operators it is tried under and the child
                     kinds, nested patterns as operator(children)), the
                     flags (check_permissible, no_could_deadlock_child),
                     the pass-1 action's image address (a placeholder:
                     the body comes later) and the pass-2 action: its
                     address and its body, lifted to the statement
                     language by tools/iscg_p2lift.py (`residue' where it
                     cannot be; a body marked `hand' in the files being
                     replaced is kept: tools/iscg_p2gen.py)
  readonly.isc       isc_readonly_tables (the ISC's hand-kept tables,
                     defined by isc_vars): its bytes, as words

The pattern of every rule is decoded from pattern_matcher (isc_pattern_
matcher) by following each arm of its two case statements from the jump
table, through the shared tails (Rev 8.89 cross-jumping), so that a try
reached by a jump into another arm is counted under each arm; every
test's failing branch is checked to lead to the same remaining tries as
the call's return.  The extraction fails if anything is not understood.

--json FILE also writes the decoded matcher and tables as JSON.
"""
import argparse
import collections
import json
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cc_isc_inventory as inv  # noqa: E402
import iscg_p2gen  # noqa: E402
import iscg_p2lift  # noqa: E402
import iscg_pass1  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, '..'))
RULES_DIR = os.path.join(ROOT, 'moon_unit', 'isc_prism_dervobjs', 'dseeaggs', 'iscg_input',
                         'rules')
KINDS = inv.SOLUTION_KINDS
NRULES_MAX = 2000
ISC_READONLY = 0x2BCDFC
ISC_READONLY_LEN = 3120

# The sections' topics (docs/iscg-design.md 1.2, docs/questions.md 266),
# by the section's number in address order.
TOPICS = {
    1: 'address_modes', 2: 'assignments', 3: 'single_float', 4: 'integer_arithmetic',
    5: 'calls', 6: 'double_float', 7: 'constants', 8: 'cses', 9: 'addresses_and_fields',
    10: 'extends', 11: 'flow', 12: 'leaves', 13: 'logical', 14: 'chains',
    15: 'processor_registers', 16: 'sets', 17: 'set_assignments', 18: 'shifts',
    19: 'strings', 20: 'variables', 21: 'proper_subtrees', 22: 'use_def',
    23: 'aggregate_assignments', 24: 'operator_assignments', 25: 'compares',
}


class Fail(Exception):
    pass


# --------------------------------------------------------------------------
# the matcher

TEST_EQ_IMM = re.compile(r'cmpiw #(-?\d+),%(a\d)@\((\d+)\)$')
TEST_EQ_REG = re.compile(r'cmpw %(a\d)@\((\d+)\),%(d\d)$')
LOAD_PATH0 = re.compile(r'moveal %a3@\((\d+)\),%(a\d)$')
LOAD_PATH = re.compile(r'moveal %(a\d)@\((\d+)\),%(a\d)$')
LOAD_CONST = re.compile(r'(?:moveq|movel) #(-?\d+),%(d\d)$')
LOAD_FIELD = re.compile(r'movew %(a\d)@\((\d+)\),%(d\d)$')
BTST = re.compile(r'btst %(d\d),%(d\d)$')
BCC = re.compile(r'(bne|beq)[sw]? (0x[0-9a-f]+)$')
BRA = re.compile(r'bra[sw]? (0x[0-9a-f]+)$')
PEA_RULE = re.compile(r'pea (0x[0-9a-f]+)$')
ARG = re.compile(r'(movel %fp@\((20|28)\),%sp@-|movel %d[345],%sp@-|pea %a3@)$')


def child_index(off):
    if off < 116 or (off - 116) % 4 or off >= 136:
        raise Fail('child offset %d' % off)
    return (off - 116) // 4 + 1


class Matcher:
    """pattern_matcher decoded: arms[(field, value)] = [(rule, guard)],
    field 108 (the subject's kind) or 98 (a proper_subtree's il$t);
    guard = [(path, field, op, value)] in the image's order."""

    def __init__(self, im, pm, hw):
        data = im.read(pm[0], pm[1])
        ins = inv.objdump(data, pm[0])
        self.ins = [(a, n, inv.hexindex(t)) for a, n, t, h in ins]
        self.at = {a: k for k, (a, n, t) in enumerate(self.ins)}
        self.hw = hw
        self.im = im
        self.tables = []
        for k, (a, n, t) in enumerate(self.ins):
            m = re.match(r'jmp %pc@\((0x[0-9a-f]+),%d0:w\)', t)
            if not m:
                continue
            T = int(m.group(1), 16)
            field = base = bound = None
            for j in range(k - 1, max(0, k - 10), -1):
                tj = self.ins[j][2]
                mm = re.match(r'cmpiw #(\d+),%d0$', tj)
                if mm and bound is None:
                    bound = int(mm.group(1))
                mm = re.match(r'subqw #(\d+),%d0$', tj)
                if mm:
                    base = int(mm.group(1))
                mm = re.match(r'bccw (0x[0-9a-f]+)$', tj)
                if mm:
                    oor = int(mm.group(1), 16)
                mm = re.match(r'movew %a3@\((\d+)\),%d0$', tj)
                if mm:
                    field = int(mm.group(1))
                    break
            d = im.read(T, 2 * bound)
            ents = [T + struct.unpack('>h', d[2 * i:2 * i + 2])[0] for i in range(bound)]
            self.tables.append({'field': field, 'base': base, 'entries': ents,
                                'out_of_range': oor, 'at': T})
        if [t['field'] for t in self.tables] != [108, 98]:
            raise Fail('jump tables %s' % [t['field'] for t in self.tables])
        outer, inner = self.tables
        # the inner case's otherwise is its out-of-range branch; the outer
        # case's in-range entries without an arm go to the case's end
        self.exit = collections.Counter(outer['entries']).most_common(1)[0][0]
        self.inner_otherwise = inner['out_of_range']
        self.outer_otherwise = outer['out_of_range']
        self.dispatch = inner['at']
        self.memo = {}

    def decode_from(self, addr, regs):
        """The tries from addr to the case's end: [(rule, guard)]."""
        key = (addr, tuple(sorted(regs.items())))
        if key in self.memo:
            return self.memo[key]
        regs = dict(regs)
        tries = []
        guard = []
        fails = []
        rule = None
        k = self.at.get(addr)
        if k is None:
            raise Fail('no instruction at 0x%X' % addr)
        steps = 0
        while True:
            steps += 1
            if steps > 100000:
                raise Fail('loop at 0x%X' % addr)
            a, n, t = self.ins[k]
            if a == self.exit:
                if guard or rule is not None:
                    raise Fail('tests without a call before 0x%X' % a)
                break
            m = LOAD_PATH0.match(t)
            if m:
                regs[m.group(2)] = ('path', (child_index(int(m.group(1))),))
                k += 1
                continue
            m = LOAD_PATH.match(t)
            if m:
                src = regs.get(m.group(1))
                if not src or src[0] != 'path':
                    raise Fail('0x%X: %s' % (a, t))
                regs[m.group(3)] = ('path', src[1] + (child_index(int(m.group(2))),))
                k += 1
                continue
            m = LOAD_CONST.match(t)
            if m:
                regs[m.group(2)] = ('const', int(m.group(1)))
                k += 1
                continue
            m = LOAD_FIELD.match(t)
            if m:
                src = regs.get(m.group(1))
                if not src or src[0] != 'path':
                    raise Fail('0x%X: %s' % (a, t))
                regs[m.group(3)] = ('field', src[1], int(m.group(2)))
                k += 1
                continue
            test = None
            m = TEST_EQ_IMM.match(t)
            if m:
                src = regs.get(m.group(2))
                if not src or src[0] != 'path':
                    raise Fail('0x%X: %s' % (a, t))
                test = (src[1], int(m.group(3)), '=', int(m.group(1)))
                fail_on = 'bne'
            m = TEST_EQ_REG.match(t)
            if m:
                src, c = regs.get(m.group(1)), regs.get(m.group(3))
                if not src or src[0] != 'path' or not c or c[0] != 'const':
                    raise Fail('0x%X: %s' % (a, t))
                test = (src[1], int(m.group(2)), '=', c[1])
                fail_on = 'bne'
            m = BTST.match(t)
            if m:
                f, c = regs.get(m.group(1)), regs.get(m.group(2))
                if not f or f[0] != 'field' or not c or c[0] != 'const':
                    raise Fail('0x%X: %s' % (a, t))
                test = (f[1], f[2], 'in', c[1] & 0xFFFFFFFF)
                fail_on = 'beq'
            if test:
                mb = BCC.match(self.ins[k + 1][2])
                if not mb or mb.group(1) != fail_on:
                    raise Fail('0x%X: a test not followed by its failing branch' % a)
                guard.append(test)
                fails.append(int(mb.group(2), 16))
                k += 2
                continue
            m = PEA_RULE.match(t)
            if m:
                rule = int(m.group(1), 16)
                k += 1
                continue
            if ARG.match(t):
                k += 1
                continue
            m = re.match(r'bsrw (0x[0-9a-f]+)', t)
            if m and int(m.group(1), 16) == self.hw:
                if rule is None:
                    raise Fail('0x%X: a call without a rule' % a)
                if not re.match(r'lea %sp@\(28\),%sp$', self.ins[k + 1][2]):
                    raise Fail('0x%X: no lea after the call' % a)
                nxt = self.ins[k + 2][0]
                for r in ('d0', 'd1', 'a0', 'a1'):
                    regs.pop(r, None)
                rest = self.decode_from(nxt, regs)
                # every failing test must lead to the same remaining tries
                for f in fails:
                    if f != nxt and self.decode_from(f, {}) != rest:
                        raise Fail('0x%X: rule %d: a failing test (to 0x%X) skips other tries'
                                   % (a, rule, f))
                tries.append((rule, tuple(guard)))
                tries.extend(rest)
                break
            m = BRA.match(t)
            if m:
                k = self.at[int(m.group(1), 16)]
                continue
            raise Fail('0x%X: not understood: %s' % (a, t))
        self.memo[key] = tuple(tries)
        return self.memo[key]

    def decode(self):
        outer, inner = self.tables
        arms = collections.OrderedDict()
        layout = {'outer_labels': [], 'inner_labels': []}
        for i, e in enumerate(outer['entries']):
            v = i + outer['base']
            if e == self.exit:
                layout['outer_labels'].append(v)       # labelled, no tries
                continue
            if e == self.outer_otherwise:
                continue
            layout['outer_labels'].append(v)
            if self.at.get(e) is not None and self.ins[self.at[e]][2].startswith(
                    'movew %a3@(98),%d0'):
                if v != 22:
                    raise Fail('the il$t case under kind %d' % v)
                continue
            arms[(108, v)] = self.decode_from(e, {})
        for i, e in enumerate(inner['entries']):
            v = i + inner['base']
            if e == self.inner_otherwise:
                continue
            layout['inner_labels'].append(v)
            arms[(98, v)] = self.decode_from(e, {})
        self.layout = layout
        return arms


def canon_guard(guard):
    """The guard as a tree: {path: {field: (op, value)}}; and whether the
    image's order is the tree's preorder (kind, operator, children in
    order)."""
    tree = {}
    for path, f, op, v in guard:
        tree.setdefault(tuple(path), {})[f] = (op, v)
    out = []

    def walk(p):
        t = tree.get(p, {})
        for f in (108, 98):
            if f in t:
                out.append((p, f) + t[f])
        kids = sorted({q[len(p)] for q in tree if len(q) > len(p) and q[:len(p)] == p})
        for kk in kids:
            walk(p + (kk,))
    walk(())
    return tree, out == [tuple(g) for g in guard]


# --------------------------------------------------------------------------
# the rule file's text

def kind_name(v):
    return KINDS[v]


def kinds_of_mask(mask):
    return [KINDS[b] for b in range(32) if mask >> b & 1]


def op_name(ils, v):
    n = ils.get(v)
    if not n or not n.startswith('il_'):
        raise Fail('il$t %d has no name' % v)
    return n[3:]


def fmt_children(tree, path, ils):
    kids = sorted({q[len(path)] for q in tree if len(q) == len(path) + 1 and q[:len(path)] == path})
    if not kids:
        return ''
    parts = []
    for kk in kids:
        p = path + (kk,)
        t = tree[p]
        sub = fmt_children(tree, p, ils)
        if 98 in t:
            if t.get(108) != ('=', 22):
                raise Fail('an operator test on a child not a proper_subtree')
            op, v = t[98]
            spec = op_name(ils, v) + (sub if sub else '()')
        else:
            op, v = t[108]
            if op == '=':
                spec = kind_name(v)
            else:
                spec = '[' + ', '.join(kinds_of_mask(v)) + ']'
            if sub:
                raise Fail('children under a child without an operator')
        parts.append('$%d: %s' % (kk, spec))
    return '(' + ', '.join(parts) + ')'


def rule_patterns(arms, ils):
    """{rule: [(subject text, children text)]} in arm order."""
    out = collections.defaultdict(list)
    for (field, v), tries in arms.items():
        for rule, guard in tries:
            tree, ok = canon_guard(guard)
            if not ok:
                raise Fail('rule %d: the tests are not in pattern order' % rule)
            if field == 108:
                if tree:
                    raise Fail('rule %d: a chain pattern with child tests' % rule)
                subj, kids = kind_name(v), ''
            else:
                subj = op_name(ils, v)
                kids = fmt_children(tree, (), ils)
            out[rule].append((subj, kids))
    return out


def fmt_pattern(alts):
    """op1 | op2 (children), grouped where the children agree, in the order
    the operators' arms come."""
    groups = collections.OrderedDict()
    for subj, kids in alts:
        groups.setdefault(kids, []).append(subj)
    parts = []
    for kids, subjs in groups.items():
        parts.append(' | '.join(subjs) + (' ' + kids if kids else ''))
    return '\n          | '.join(parts) if len(parts) > 1 else parts[0]


# --------------------------------------------------------------------------
# the rest of the image

def a5_of_action(im, va):
    d = im.read(va, 16)
    i = d.find(b'\x4b\xf9')
    if i < 0 or i > 10:
        return None
    return int.from_bytes(d[i + 2:i + 6], 'big')


def named_routine(im, name):
    for st, ln, nm, src, lv in im.blocks:
        if nm == name:
            r = inv.Routine(st)
            r.name, r.length, r.unit = nm, ln, src
            inv.analyze(im, r, st + ln)
            return r
    raise Fail('no routine %s' % name)


def operators(im):
    rs = []
    for st, ln, nm, src, lv in sorted(im.blocks):
        if src and 'isc_pass_1_main' in src:
            r = inv.Routine(st)
            r.name, r.length, r.unit = nm, ln, src
            rs.append(r)
    import concurrent.futures
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(lambda r: inv.analyze(im, r, r.start + r.length), rs))
    if not any(r.name == 'pass_1' for r in rs):
        rs.append(named_routine(im, 'pass_1'))
    ops = inv.decode_il_routines(im, rs)
    pass1_operators(im, rs, ops)
    return ops


def pass1_operators(im, rs, ops):
    """isc_pass_1_main's operator routines lifted to the rule file's
    statements (tools/iscg_pass1.py), each pass_1 call's child position,
    and the dispatch tables isc_pass_1_begin_compilation fills, checked
    against the routines' names."""
    by = {r.name: r for r in rs}
    pass1 = by['pass_1'].start
    for d in ops:
        r = by[d['name']]
        d['lifted'], d['why'] = iscg_pass1.lift_routine(
            r.insns, im.names, pass1, lambda a, n: im.read(a, n).decode('latin1'))
        d['positions'] = iscg_pass1.call_positions(r.insns, pass1)
        # the inventory's reading misses a count stored through a data
        # register's copy (branch_node); the lifter's then stands
        for f in ('w98', 'nchildren'):
            if d['lifted'] and d[f] is None:
                d[f] = d['lifted'][f]
        if d['lifted'] and (d['lifted']['w98'] != d['w98'] or
                            d['lifted']['nchildren'] != d['nchildren']):
            raise Fail('%s: lifted il$t/children differ' % d['name'])
    # the dispatch tables: A5 offset -> routine, from the stores
    names = {r.start: r.name for r in rs}
    have = {}
    for a, n, t, h in by['isc_pass_1_begin_compilation'].insns:
        m = re.match(r'movel #(\d+),%a5@(?:\((\d+)\))?$', t)
        if m:
            have[int(m.group(2) or 0)] = names.get(int(m.group(1)))
    want = iscg_pass1.dispatch_entries([d['name'] for d in ops])
    if want != have:
        bad = sorted(set(want.items()) ^ set(have.items()))[:6]
        raise Fail('isc_pass_1_begin_compilation\'s tables are not the names\' (%s)' % bad)


def attribute_type(off, acc):
    m = re.match(r'btst #(\d),', acc)
    if m:
        return 'boolean', int(m.group(1))
    if acc.startswith('tstb') and off in (81, 82, 83, 84, 115):
        return 'boolean', 7
    if acc.startswith('moveb'):
        return 'byte', None
    if 28 <= off <= 52:
        return 'integer32', None
    if 56 <= off <= 74 or off in (92, 94, 96, 98, 108, 110, 112):
        return 'integer', None
    if off in (114,):
        return 'byte', None
    if off in (0, 4, 8, 16, 20, 24, 88, 100, 104) or off >= 352:
        return 'pointer', None
    if 136 <= off < 352:
        return 'local', None
    return 'unknown', None


def extract(binary):
    im = inv.Image(binary)
    p1 = im.action_table(inv.P1_A5)
    p2 = im.action_table(inv.P2_A5)
    if len(p1) != len(p2):
        raise Fail('action tables %d and %d' % (len(p1), len(p2)))
    nrules = len(p1)
    result_kind, per_il, tail = inv.tool_tables(im, nrules)
    f1, f2 = inv.rule_flags(im, nrules)
    pm = named_routine(im, 'pattern_matcher')
    hw = named_routine(im, 'hard_work')
    mt = Matcher(im, (pm.start, pm.length), hw.start)
    arms = mt.decode()
    ils = inv.il_names()
    pats = rule_patterns(arms, ils)
    missing = [r for r in range(1, nrules + 1) if r not in pats]
    if missing:
        raise Fail('rules the matcher never tries: %s' % missing)
    # sections: the pass-1 modules in address order, by A5
    a5 = {r: a5_of_action(im, p1[r - 1]) for r in range(1, nrules + 1)}
    if None in a5.values():
        raise Fail('a pass-1 action without an A5')
    order = sorted(set(a5.values()), key=lambda x: min(p1[r - 1] for r in a5 if a5[r] == x))
    sec_of = {r: order.index(a5[r]) + 1 for r in a5}
    sections = []
    for s, x in enumerate(order, 1):
        rules = sorted(r for r in a5 if a5[r] == x)
        if rules != list(range(rules[0], rules[-1] + 1)):
            raise Fail('section %d is not a run of rules' % s)
        p2a5 = sorted({a5_of_action(im, p2[r - 1]) for r in rules} - {None})
        sections.append({'number': s, 'topic': TOPICS[s], 'rules': rules, 'p1_a5': x,
                         'p2_a5': p2a5[0] if p2a5 else None,
                         'p1_range': [min(p1[r - 1] for r in rules),
                                      max(p1[r - 1] for r in rules)],
                         'p2_range': [min(p2[r - 1] for r in rules),
                                      max(p2[r - 1] for r in rules)]})
    empty2 = [r for r in range(1, nrules + 1) if im.read(p2[r - 1], 2) == b'\x4e\x75']
    fields = inv.decode_fields(im, [named_routine(im, 'dump_solution')])
    ops = operators(im)
    # the pass-2 actions' bodies, lifted (tools/iscg_p2lift.py)
    p2img = iscg_p2lift.Image(binary, im)
    p2_bodies = {r: iscg_p2lift.lift_rule(p2img, r) for r in range(1, nrules + 1)}
    return {
        'nrules': nrules, 'result_kind': result_kind, 'per_il': per_il, 'tail': tail,
        'check_permissible': [bool(x) for x in f1], 'no_could_deadlock_child': [bool(x) for x in f2],
        'p1': p1, 'p2': p2, 'empty_p2': empty2,
        'arms': [[k[0], k[1], [[r, [[list(g[0])] + list(g[1:]) for g in gd]] for r, gd in v]]
                 for k, v in arms.items()],
        'layout': mt.layout, 'patterns': pats, 'sections': sections, 'section_of': sec_of,
        'fields': fields, 'operators': ops, 'ils': ils, 'p2_bodies': p2_bodies,
        'readonly': list(im.read(ISC_READONLY, ISC_READONLY_LEN)),
    }


# --------------------------------------------------------------------------
# writing

HEADER = '''{ %s - the ISC generator's input (docs/iscg-design.md), %s.
  Written by tools/iscg_extract.py from cc.a88k; tools/iscg_gen.py
  generates the ISC's Pascal from these files.  Not known from the
  original: the language's syntax (only "pattern", "transform" and
  `let result <- ...;' survive in the image), the files' names and
  layout. }

'''


def write_rules(x, out):
    os.makedirs(out, exist_ok=True)
    hand = iscg_p2gen.hand_bodies(out)      # kept: written by hand
    ils = x['ils']
    n = x['nrules']
    written = []
    # declarations
    lines = [HEADER % ('declarations.isc', 'the declarations')]
    lines.append('{ The solution kinds (solution$t: the SOLUTION$ identifiers). }')
    lines.append('kinds ' + ', '.join(KINDS) + ';')
    lines.append('')
    lines.append('{ The attributes, as dump_solution prints them: name, offset (and bit)')
    lines.append('  in the solution, size class. }')
    for name, off, acc in x['fields']:
        if off is None:
            lines.append('attribute %s;' % name)
            continue
        typ, bit = attribute_type(off, acc)
        lines.append('attribute %s +%d%s %s;' % (name, off, '.%d' % bit if bit is not None else '',
                                               typ))
    lines.append('')
    # the matcher's per-operator unions (the derived permissible sets)
    unions = collections.defaultdict(lambda: collections.defaultdict(int))
    for (field, v), tries in x['arms_raw'].items():
        if field != 98:
            continue
        for rule, guard in tries:
            for path, f, op, val in guard:
                if len(path) == 1 and f == 108:
                    unions[v][path[0]] |= (1 << val) if op == '=' else val
    lines.extend(iscg_pass1.OPERATORS_COMMENT)
    for d in [d for d in x['operators'] if d['name'] != 'isc_pass_1_begin_compilation']:
        lines.append(iscg_pass1.format_operator(
            d, d.get('lifted'), d.get('positions', []), unions.get(d['w98'], {}),
            ils, KINDS, lambda v: op_name(ils, v)))
    lines.append('')
    lines.append('{ The opcode maps: by il$t, the opcode of the operation (isc_tool_')
    lines.append('  generated_readonly_tables after the result kinds, 178 words each). }')
    ops = inv.opcode_names()
    names = ['opcode_rr_reversed', 'opcode_rr', 'opcode_immediate', 'opcode_double',
             'opcode_immediate_negated', 'opcode_single']
    for k, t in enumerate(x['per_il']):
        ents = ['%s -> %s' % (op_name(ils, i), ops[v][4:] if v in ops else v)
                for i, v in enumerate(t) if v]
        lines.append('map %s\n  %s;' % (names[k], ',\n  '.join(ents)))
    lines.append('')
    with open(os.path.join(out, 'declarations.isc'), 'w') as f:
        f.write('\n'.join(lines))
    written.append('declarations.isc')
    # sections
    for s in x['sections']:
        fn = '%02d_%s.isc' % (s['number'], s['topic'])
        lines = [HEADER % (fn, 'section %d, rules %d..%d' % (s['number'], s['rules'][0],
                                                              s['rules'][-1]))]
        lines.append('section %02d %s  image pass_1 a5 16#%06X, pass_2 a5 %s;' % (
            s['number'], s['topic'], s['p1_a5'],
            '16#%06X' % s['p2_a5'] if s['p2_a5'] else 'none'))
        lines.append('')
        for r in s['rules']:
            flags = []
            if x['check_permissible'][r - 1]:
                flags.append('check_permissible')
            if x['no_could_deadlock_child'][r - 1]:
                flags.append('no_could_deadlock_child')
            lines.append('transform %d  %s <- %s' % (r, KINDS[x['result_kind'][r - 1]],
                                                    fmt_pattern(x['patterns'][r])))
            if flags:
                lines.append('  ' + ' '.join(flags) + ';')
            lines.append('  pass_1 image 16#%06X;' % x['p1'][r - 1])
            if r in hand:
                lines.extend(hand[r])
            else:
                stmts, why = x['p2_bodies'][r]
                lines.extend(iscg_p2gen.fmt_clause(x['p2'][r - 1], r in x['empty_p2'],
                                                   stmts, False, why))
            lines.append('end;')
            lines.append('')
        with open(os.path.join(out, fn), 'w') as f:
            f.write('\n'.join(lines))
        written.append(fn)
    # isc_readonly_tables
    b = x['readonly']
    lines = [HEADER % ('readonly.isc', 'the section isc_readonly_tables (the ISC\'s own tables, '
                       'not the generator\'s: isc_vars defines it)')]
    lines.append('readonly isc_readonly_tables %d bytes' % len(b))
    words = [b[i] << 8 | b[i + 1] for i in range(0, len(b), 2)]
    for i in range(0, len(words), 8):
        lines.append('  +16#%03X %s' % (2 * i, ' '.join('%04X' % w for w in words[i:i + 8])))
    lines.append('end;')
    lines.append('')
    with open(os.path.join(out, 'readonly.isc'), 'w') as f:
        f.write('\n'.join(lines))
    written.append('readonly.isc')
    # the matcher's case labels that hold no tries (the layout of the
    # generated case statement)
    return written


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--binary', default=inv.DEFAULT_BINARY)
    ap.add_argument('--out', default=RULES_DIR)
    ap.add_argument('--json')
    a = ap.parse_args()
    try:
        x = extract(a.binary)
    except Fail as e:
        sys.exit('iscg_extract: %s' % e)
    arms = collections.OrderedDict(((f, v), [(r, [tuple([tuple(g[0])] + g[1:]) for g in gd])
                                             for r, gd in tries]) for f, v, tries in x['arms'])
    x['arms_raw'] = arms
    files = write_rules(x, a.out)
    # the round trip: the generator's reading of the files just written
    # must give the matcher decoded from the image, try for try
    import iscg_gen
    g = iscg_gen.Gen(iscg_gen.Rules(a.out))
    mine = [((f, v), [(r, [tuple(t) for t in gd]) for r, gd in tries])
            for f, v, tries in g.arms(guards=True)]
    theirs = [(k, [(r, [tuple(t) for t in gd]) for r, gd in tries]) for k, tries in arms.items()]
    if mine != theirs:
        bad = [k for (k, a1), (k2, a2) in zip(mine, theirs) if (k, a1) != (k2, a2)]
        sys.exit('iscg_extract: the rule file does not give the image\'s matcher (arms %s)'
                 % bad[:5])
    if a.json:
        y = dict(x)
        y.pop('arms_raw')
        y['patterns'] = {str(k): v for k, v in x['patterns'].items()}
        y['section_of'] = {str(k): v for k, v in x['section_of'].items()}
        with open(a.json, 'w') as f:
            json.dump(y, f, indent=1)
    print('%d rules, %d tries in %d arms; %d files in %s' % (
        x['nrules'], sum(len(v) for v in arms.values()), len(arms), len(files),
        os.path.relpath(a.out, ROOT)))


if __name__ == '__main__':
    main()
