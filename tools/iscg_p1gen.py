#!/usr/bin/env python3
"""iscg_p1gen.py - the ISC generator's pass-1 part: the rule file's pass_1
clauses and the 25 isc_pass_1_<nn>_<topic>.pas modules.

Used by tools/iscg_gen.py (reading the clauses, emitting the modules and
the manifest's module lines) and tools/iscg_extract.py (writing the
clauses).  A transform's pass-1 action is one of

    pass_1 image 16#ADDR [rewrite] begin ... end;
                         a clause in the statement language (tools/
                         iscg_p1lang.py), lifted from the image by tools/
                         iscg_p1lift.py; the generator writes the skeleton
    pass_1 image 16#ADDR [rewrite] hand [dropped] begin ... end;
                         written by hand (the extractor keeps it: rules 9
                         and 10, the FPP emulation's real comparison and
                         conversion, and 399, 402); a `dropped' clause is an action whose arm Rev 8.89
                         removed (its conditions' first tests survive, no
                         trace, no solution: rules 399 and 402)
    pass_1 image 16#ADDR residue;
                         not lifted yet ({ why } before it)

ADDR is the action's address in cc.a88k (for the manifest only).  A
section's module is generated when none of its transforms is residue.
The module's data are the cost tables its clauses write inline
(`bytes(...)[e]', `words(...)[e]'), laid out rule by rule, each rule's
in the reverse of their order in its clause (the image's order).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import iscg_p2lang as L  # noqa: E402
import iscg_p1lang as L1  # noqa: E402

P1_END = 0x18C588       # pass_2: the first routine after the pass-1 modules
MODULE = 'isc_pass_1_%02d_%s'
BODY = re.compile(r'\bpass_1\s+image\s+(16#[0-9A-Fa-f]+)\s+(rewrite\s+)?(hand\s+)?'
                  r'(dropped\s+)?begin\b')


# --------------------------------------------------------------------------
# the rule file

def extract_bodies(text):
    """The pass_1 clauses cut out of a rule file's text (comments already
    stripped): (text with each replaced by `pass_1 image A body N;',
    {N: (stmts, rewrite, hand)})."""
    import iscg_p2gen
    out, bodies, pos = [], {}, 0
    while True:
        m = BODY.search(text, pos)
        if not m:
            out.append(text[pos:])
            break
        start = m.end() - len('begin')
        end = iscg_p2gen.match_end(text, start)
        n = len(bodies)
        try:
            p = L1.Parser(L.tokenize(text[start:end]))
            stmts = p.body()
        except L.LangError as e:
            raise L.LangError('the pass_1 clause at %s: %s' % (m.group(1), e))
        bodies[n] = (stmts, bool(m.group(2)), bool(m.group(3)), bool(m.group(4)))
        out.append(text[pos:m.start()])
        out.append('pass_1 image %s body %d;' % (m.group(1), n))
        pos = end
        if text[pos:pos + 1] == ';':
            pos += 1
    return ''.join(out), bodies


def clause(tr, body, bodies):
    """A transform's pass_1 clause (its tokens after `pass_1')."""
    tr['p1_clause'] = None
    tr['p1_residue'] = 'residue' in body
    if 'body' in body:
        stmts, rewrite, hand, dropped = bodies[int(body[body.index('body') + 1])]
        c = L1.clause_of(stmts, tr['rule'], rewrite)
        c.hand = hand
        c.flags['dropped'] = dropped
        tr['p1_clause'] = c


def hand_clauses(rules_dir):
    """{rule: [lines]} of the hand-written pass_1 clauses (kept by the
    extractor)."""
    import iscg_p2gen
    out = {}
    if not os.path.isdir(rules_dir):
        return out
    for fn in sorted(os.listdir(rules_dir)):
        if not re.match(r'\d\d_.*\.isc$', fn):
            continue
        lines = open(os.path.join(rules_dir, fn)).read().split('\n')
        rule = None
        k = 0
        while k < len(lines):
            m = re.match(r'transform (\d+) ', lines[k])
            if m:
                rule = int(m.group(1))
            if re.match(r'\s*pass_1 image 16#[0-9A-F]+ (rewrite )?hand (dropped )?begin',
                        lines[k]):
                j = k
                text = ''
                while True:
                    text += lines[j] + '\n'
                    body = text[text.index('begin'):]
                    try:
                        iscg_p2gen.match_end(L.strip_comments(body), 0)
                        break
                    except L.LangError:
                        j += 1
                        if j >= len(lines):
                            raise
                out[rule] = lines[k:j + 1]
                k = j
            k += 1
    return out


# --------------------------------------------------------------------------
# the modules

def module_ranges(rules):
    starts = {}
    for s in rules.sections:
        addrs = [rules.transforms[r]['p1'] for r in s['transforms']
                 if rules.transforms[r]['p1'] is not None]
        if addrs:
            starts[s['number']] = min(addrs)
    order = sorted(starts, key=starts.get)
    out = {}
    for k, n in enumerate(order):
        out[n] = (starts[n], starts[order[k + 1]] if k + 1 < len(order) else P1_END)
    return out


def module_file(sec):
    return (MODULE % (sec['number'], sec['topic'])) + '.pas'


def complete(rules, sec):
    return all(rules.transforms[r].get('p1_clause') is not None for r in sec['transforms'])


def manifest_lines(rules):
    """The pass-1 modules' `module' lines (every section's: their A5s bound
    the data blocks of the modules before them)."""
    out = []
    rng = module_ranges(rules)
    for s in sorted(rules.sections, key=lambda s: rng.get(s['number'], (0,))[0]):
        if s['number'] not in rng:
            continue
        lo, hi = rng[s['number']]
        out.append('module\t%s\t0x%06X\t0x%06X\t0x%06X' % (module_file(s), s['p1_a5'], lo, hi))
    return out


HEADING = '''procedure transform_%d_pass_1(var subject: isc_solution_t; il: univ_ptr;
    inh: inherited_attributes_ptr_t; var work, result: isc_solution_ptr_t);
    options(val_param);'''

TYPES = '''  { A rule's cost table: by the number of the alternative an instruction
    of the rule takes (0..16; the clause's `bytes(...)[e]', `words(...)
    [e]'), its cost.  Rev 8.89 begins each array on 8 bytes (17 bytes take
    24, 17 words 40: the image's layout); dpc packs them (docs/dpc-gaps.md
    37), so the types carry the padding, the module's last table none. }
  p1_byte_costs_t = packed array [0..23] of 0..255;
  p1_word_costs_t = array [0..19] of integer;
  p1_last_byte_costs_t = packed array [0..16] of 0..255;
  p1_last_word_costs_t = array [0..16] of integer;'''

NEAR_TYPES = '''  { The last table below 32 KB in a module that passes it: rounded to 4
    bytes (the tables past 32 KB begin there; pattern 200). }
  p1_near_last_byte_costs_t = packed array [0..19] of 0..255;
  p1_near_last_word_costs_t = array [0..17] of integer;'''

INT_FIELDS_VIEW = '''  { A rule's own longwords (+352 ..) that hold integers
    (isc_solution_fields.ins.pas declares pointers there). }
  p1_int_fields_ptr_t = ^p1_int_fields_t;
  p1_int_fields_t = record
    x: array [0..175] of integer;               { +0 }
    i: array [0..19] of integer32;              { +352 }
    end;'''

READONLY_VIEW = '''  { isc_readonly_tables by byte and word (the actions index tables in it
    that isc_types.ins.pas's view leaves unnamed). }
  p1_readonly_ptr_t = ^p1_readonly_t;
  p1_readonly_t = record
    case integer of
      1: (w: array [0..1559] of integer);
      2: (b: packed array [0..3119] of 0..255);
      3: (l: array [0..779] of integer32);
    end;'''

SINGLE_VIEW = '''  { A single real and its bits (`temp f: single'; rule 10 takes a real
    constant's bits as a single). }
  p1_single_t = record
    case integer of
      1: (value: real);
      2: (bits: integer32);
    end;'''

SNODE_VIEW = '''  { An IL node's bytes as signed numbers (the actions sign-extend some). }
  p1_snode_ptr_t = ^p1_snode_t;
  p1_snode_t = record
    sb: packed array [0..511] of -128..127;
    end;'''


def table_layout(rules, sec):
    """[(rule, name, kind, values)] of the section's cost tables in the
    module's order; {rule: [(name, kind)] in printing order}."""
    T = rules.transforms
    layout, by_rule = [], {}
    for r in sec['transforms']:
        printed, lay = L1.rule_tables(T[r]['p1_clause'])
        by_rule[r] = printed
        layout.extend((r, n, kind, vals) for n, kind, vals in lay)
    return layout, by_rule


NEAR_LIMIT = 0x8000     # A5-relative (16-bit) displacements reach 32 KB


def place_tables(layout):
    """Rev 8.89's offsets of the module's cost tables (layout: the
    module's order) and the order they are declared in: [(k, offset)] by
    offset.  Each table begins on 8 bytes from its region's base and takes
    17 bytes (byte tables) or 34 (word tables).  A table stays near (from
    A5 + 0, in order) while its start plus three times its 8-rounded size
    (24, 40) is within 32 KB; the rest go far, in order, after the near
    tables' end rounded to 4 (reached through an absolute base in the
    image: pattern 189).  Rules 170/171 (module 02) and 186..188 (module
    24) are the only ones that pass 32 KB; the rule reproduces every
    table's offset in both (2990 tables; docs/rev889-patterns.md 200,
    docs/questions.md 301)."""
    near, far = [], []
    off = None
    for k, (r, n, kind, vals) in enumerate(layout):
        size, padded = (17, 24) if kind == 'b' else (34, 40)
        start = 0 if off is None else (off + 7) // 8 * 8
        if start + 3 * padded <= NEAR_LIMIT:
            near.append((k, start))
            off = start + size
        else:
            far.append(k)
    out = list(near)
    base = cur = (off + 3) // 4 * 4 if off is not None else 0
    for k in far:
        size = 17 if layout[k][2] == 'b' else 34
        start = base + (cur - base + 7) // 8 * 8
        out.append((k, start))
        cur = start + size
    return out, len(near)


def chain_text(em, chain, inner, ind):
    """The conditions and the statements between them around inner."""
    out = []
    depth = 0
    for s in chain:
        if s[0] == 'condition':
            out.append(ind + '  ' * depth + 'if %s then begin' % em.expr(s[1]))
            depth += 1
        else:
            out.extend(em.stmt(s, ind + '  ' * depth))
    out.extend(['  ' * depth + x for x in inner])
    for d in range(depth - 1, -1, -1):
        out.append(ind + '  ' * d + 'end;')
    return out


def trace_lines(text, ind):
    return [ind + 'if isc_user_routines_354 then begin',
            ind + "  write('%s');" % text.replace("'", "''"),
            ind + '  writeln;',
            ind + 'end;']


def routine(r, t, headings, tables):
    """The Pascal of rule r's pass-1 action (declarations, statements)."""
    c = t['p1_clause']
    f = c.flags
    em = L1.Emitter(r, headings, tables)
    em.int_fields = L1.int_fields(list(f['chain']) + list(c.body), headings)
    decls = []
    if not f['rewrite'] and not f.get('dropped'):
        decls.append('  solution: isc_solution_ptr_t;     { the new solution (`result\') }')
    for s in c.decls:
        if s[2] not in L.TEMP_TYPES:
            raise L.LangError('rule %d: temp type %s' % (r, s[2]))
        em.temps[s[1]] = L.TEMP_TYPES[s[2]]
        decls.append('  %s: %s;' % (s[1], L.PASCAL_TYPE[L.TEMP_TYPES[s[2]]]))
    for s in L.walk(list(f['chain']) + list(c.body)):
        if s[0] == 'for' and s[1] not in em.temps:
            em.temps[s[1]] = 'i32'
            decls.append('  %s: integer32;' % s[1])
    L.declare_word_temps(em, list(f['chain']) + list(c.body), decls)
    ind = '  '
    # the chain is printed first: its tables come first
    pre = []
    depth = 0
    for s in f['chain']:
        if s[0] == 'condition':
            pre.append(ind + '  ' * depth + 'if %s then begin' % em.expr(s[1]))
            depth += 1
        else:
            pre.extend(em.stmt(s, ind + '  ' * depth))
    i2 = ind + '  ' * depth
    inner = trace_lines(L1.MATCHED % r if hasattr(L1, 'MATCHED') else
                        'Pattern %d matched the semantics.' % r, i2)
    if f.get('dropped'):
        # the arm Rev 8.89 removed: the conditions' tests alone
        inner = [i2 + '{ the rest of the action: not in the image }']
    elif f['rewrite']:
        inner.append(i2 + 'result := addr(subject);')
        inner.extend(em.stmts(c.body, i2))
    else:
        i3 = i2
        if f['guard']:
            inner.append(i2 + 'if subject.%s then begin' % f['guard'])
            inner.extend(trace_lines(
                'Infinite cycle prevented by NOT adding this to the work list.', i2 + '  '))
            inner.append(i2 + 'end')
            inner.append(i2 + 'else begin')
            i3 = i2 + '  '
        inner.append(i3 + 'solution := new_solution(isc_heap, solution$%s, 0, inh, il, il_none);'
                     % t['kind'])
        inner.append(i3 + 'solution^.which_transform := %d;' % r)
        inner.append(i3 + 'solution^.before_transform := addr(subject);')
        inner.extend(em.stmts(c.body, i3))
        for a in L1.ALREADY:
            inner.extend(em.lines(i3, 'solution^.%s := subject.%s;' % (a, a)))
        if f['guard'] or f.get('mark'):
            inner.append(i3 + 'solution^.%s := true;' % (
                f['guard'] or f['mark']))
        inner.append(i3 + 'work := solution;')
        inner.append(i3 + 'result := solution;')
        if f['guard']:
            inner.append(i2 + 'end;')
    if em.ti != len(tables):
        raise L.LangError('rule %d: %d tables laid out, %d used' % (r, len(tables), em.ti))
    body = [ind + 'result := nil;', ind + 'work := nil;'] + pre + inner
    for d in range(depth - 1, -1, -1):
        body.append(ind + '  ' * d + 'end;')
    return (['var'] + decls if decls else []), body


def gen_module(rules, sec, headings, includes, gen_note, pattern_text, wrap_words, runs):
    T = rules.transforms
    rng = module_ranges(rules)
    lo, hi = rng[sec['number']]
    allp1 = sorted(T[r]['p1'] for r in T if T[r]['p1'] is not None) + [P1_END]
    name = MODULE % (sec['number'], sec['topic'])
    rs = sec['transforms']
    a5 = sec['p1_a5']
    layout, by_rule = table_layout(rules, sec)
    nhand = sum(1 for r in rs if T[r]['p1_clause'].hand)
    placed, nnear = place_tables(layout)
    nbytes = 0
    if placed:
        k, o = placed[-1]
        nbytes = o + (17 if layout[k][2] == 'b' else 34)
    head = ['{ %s - the pass-1 actions of the ISC\'s section %d (%s), rules' % (
        name, sec['number'], sec['topic'].replace('_', ' ')),
        '  %d..%d (a DSEE derived object of the iscg_input description; cc.a88k' % (rs[0], rs[-1]),
        '  only): hard_work (isc_pattern_matcher) calls each through its table',
        '  by the rule (which_transform) when the rule\'s pattern matches a',
        '  solution: the action tests the rule\'s semantic conditions and makes',
        '  the rule\'s solution, its attributes and costs.', '']
    head.extend(gen_note.rstrip('\n').split('\n'))
    head.append('')
    head.append('  Image addresses (cc.a88k; no .blocks record: tools/cc_isc_check.py')
    head.append('  compares the routines at the manifest\'s addresses, iscg_names.txt):')
    for r in rs:
        head.append('    transform_%d_pass_1  0x%06X' % (r, T[r]['p1']))
    head.append('  Code 0x%06X..0x%06X.  A5 0x%06X: the module\'s data, pas_$output at' % (
        lo, hi, a5))
    head.append('  A5-4 (the traces\' file; the writes are dpc gap 4, so dpc allocates')
    if layout and nnear < len(layout):
        head.append('  none) and from A5 the %d cost tables (%d bytes): %d near, the' % (
            len(layout), nbytes, nnear))
        head.append('  last %d past 32 KB after them (Rev 8.89\'s allocation: pattern 200).' % (
            len(layout) - nnear))
    elif layout:
        head.append('  none) and from A5 the %d cost tables (%d bytes).' % (len(layout), nbytes))
    else:
        head.append('  none); no cost tables.')
    head.append('  Every action loads A5 in the image (pattern 1).')
    if nhand:
        head.append('  %d clauses are written by hand in the rule file (not lifted).' % nhand)
    head.append('')
    head.append('  Not known from the original: the module\'s, the routines\', the')
    head.append('  parameters\' and the tables\' names (docs/questions.md 266), the')
    head.append('  temporaries\'. }')
    out = head + ['module %s;' % name, '']
    out.append(includes.rstrip('\n'))
    out.append('')
    bodies = {}
    errors = []
    texts = []
    tabs_of = {}
    for r in rs:
        tabs_of[r] = by_rule[r]
    for r in rs:
        try:
            decl, body = routine(r, T[r], headings, tabs_of[r])
        except L.LangError as e:
            errors.append(str(e))
            continue
        bodies[r] = (decl, body)
        texts.append('\n'.join(decl + body))
    if errors:
        raise L.LangError('; '.join(errors))
    text = '\n'.join(texts)
    import iscg_p2gen as P2G
    views = []
    if layout and nnear < len(layout):
        views.append(NEAR_TYPES)
    if 'p2_node_ptr_t' in text:
        views.append(P2G.NODE_VIEW)
    if 'p2_readonly_ptr_t' in text:
        views.append(P2G.READONLY_VIEW)
    if 'p1_readonly_ptr_t' in text:
        views.append(READONLY_VIEW)
    if 'p1_snode_ptr_t' in text:
        views.append(SNODE_VIEW)
    if 'p1_single_t' in text:
        views.append(SINGLE_VIEW)
    if 'p1_int_fields_ptr_t' in text:
        views.append(INT_FIELDS_VIEW)
    if 'p2_locals_ptr_t' in text:
        views.append(P2G.LOCALS_VIEW)
    if layout:
        views.insert(0, TYPES)
    if views:
        out.append('type')
        out.extend(views)
        out.append('')
    if 'lir_3c60' in text or 'lir_3d60' in text:
        out.append(P2G.LIR_TABS)
        out.append('')
    if layout:
        out.append('var')
        out.append('  { The cost tables, rule by rule (each rule\'s in the reverse of their order')
        if nnear < len(layout):
            out.append('    in its clause): the near ones, then those Rev 8.89 put past 32 KB. }')
        else:
            out.append('    in its clause). }')
        for j, (k, o) in enumerate(placed):
            r, n, kind, vals = layout[k]
            last = j == len(placed) - 1
            if j == nnear - 1 and nnear < len(placed):
                # the last near table: the far ones begin on 4 bytes after it
                typ = 'p1_near_last_' + ('byte' if kind == 'b' else 'word') + '_costs_t'
            else:
                typ = ('p1_last_' if last else 'p1_') + ('byte' if kind == 'b' else 'word') + \
                    '_costs_t'
            full = [0] + list(vals) + [0] * (16 - len(vals))
            items = runs(full, str)
            line = '  %s: %s := [%s];' % (n, typ, ', '.join(items))
            if len(line) <= 78:
                out.append(line)
            else:
                out.append('  %s: %s := [' % (n, typ))
                import iscg_gen
                out.extend(iscg_gen.wrap(items, '      ', end='];'))
        out.append('')
    for r in rs:
        t = T[r]
        k = allp1.index(t['p1'])
        size = allp1[k + 1] - t['p1']
        out.extend(wrap_words('{ transform_%d_pass_1 - rule %d: %s <- %s.' % (
            r, r, t['kind'], pattern_text(t)), 76, '  '))
        out.append('  0x%06X, 0x%X bytes%s. }' % (t['p1'], size,
                                                  ', written by hand' if t['p1_clause'].hand
                                                  else ''))
        out.append(HEADING % r)
        decl, body = bodies[r]
        out.extend(decl)
        out.append('begin')
        out.extend(body)
        out.append('end;')
        out.append('')
    return '\n'.join(out).rstrip('\n') + '\n'


def modules(gen, includes, gen_note):
    """{file name: text} of the complete sections' pass-1 modules."""
    import iscg_p2gen as P2G
    import iscg_gen
    headings = L.read_headings(includes)
    for k, v in L1.extra_headings().items():
        headings.setdefault(k, v)
    for k, v in L1.EXTRA_GLOBALS.items():
        L.GLOBALS.setdefault(k, v)
    out = {}
    errors = []
    for sec in gen.r.sections:
        if not complete(gen.r, sec):
            continue
        try:
            out[module_file(sec)] = gen_module(gen.r, sec, headings, includes, gen_note,
                                               P2G.pattern_text, P2G.wrap_words, iscg_gen.runs)
        except L.LangError as e:
            errors.append(str(e))
    if errors:
        raise L.LangError('\n'.join(errors))
    return out


# --------------------------------------------------------------------------
# the extractor's side

def lift_all(binary, im, kinds):
    """{rule: (clause, why)} of every pass-1 action."""
    import iscg_p1lift as P
    import cc_isc_inventory as inv
    img = P.Image(binary, im)
    out = {}
    for r in range(1, len(img.p1) + 1):
        out[r] = P.lift_rule(img, r, inv.SOLUTION_KINDS[kinds[r - 1]])
    return out


def clause_lines(addr, lifted, hand_lines=None):
    if hand_lines:
        return hand_lines
    c, why = lifted
    return L1.fmt_clause(addr, c, why)
