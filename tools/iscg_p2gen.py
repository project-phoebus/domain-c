#!/usr/bin/env python3
"""iscg_p2gen.py - the ISC generator's pass-2 part: the rule file's pass_2
clauses and the 25 isc_pass_2_<nn>_<topic>.pas modules.

Used by tools/iscg_gen.py (reading the clauses, emitting the modules and
the manifest's module lines) and tools/iscg_extract.py (writing the
clauses).  A transform's pass-2 action is one of

    pass_2 image 16#ADDR empty;              a bare `rts' (docs/rev889-patterns.md 165)
    pass_2 image 16#ADDR begin ... end;      a body in the statement language
                                             (tools/iscg_p2lang.py), lifted from
                                             the image by tools/iscg_p2lift.py
    pass_2 image 16#ADDR hand begin ... end; a body written by hand (the
                                             extractor keeps it)
    pass_2 image 16#ADDR residue;            not lifted yet ({ why } before it)

ADDR is the action's address in cc.a88k (for the manifest only).  A
section's module is generated when none of its transforms is residue.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import iscg_p2lang as L  # noqa: E402

P2_END = 0x20042C       # hard_work: the first routine after the pass-2 modules
MODULE = 'isc_pass_2_%02d_%s'
BODY = re.compile(r'\bpass_2\s+image\s+(16#[0-9A-Fa-f]+)\s+(hand\s+)?begin\b')


# --------------------------------------------------------------------------
# the rule file

def extract_bodies(text):
    """The pass_2 bodies cut out of a rule file's text (comments already
    stripped): (text with each body replaced by `body N', {N: (stmts,
    hand)})."""
    out, bodies, pos = [], {}, 0
    while True:
        m = BODY.search(text, pos)
        if not m:
            out.append(text[pos:])
            break
        start = m.end() - len('begin')
        end = match_end(text, start)
        n = len(bodies)
        try:
            stmts = L.parse_body(text[start:end])
        except L.LangError as e:
            raise L.LangError('the pass_2 body at %s: %s' % (m.group(1), e))
        bodies[n] = (stmts, bool(m.group(2)))
        out.append(text[pos:m.start()])
        out.append('pass_2 image %s body %d;' % (m.group(1), n))
        pos = end
        # the body's `end;' is the clause's
        if text[pos:pos + 1] == ';':
            pos += 1
    return ''.join(out), bodies


WORD = re.compile(r"'(?:[^']|'')*'|[A-Za-z_][A-Za-z0-9_$]*|.", re.S)


def match_end(text, start):
    """The offset just past the `end' that closes the `begin' at start."""
    depth = 0
    for m in WORD.finditer(text, start):
        w = m.group(0)
        if w in ('begin', 'if', 'for'):
            depth += 1
        elif w == 'end':
            depth -= 1
            if depth == 0:
                return m.end()
    raise L.LangError('a pass_2 body without its end')


def clause(tr, body, bodies):
    """A transform's pass_2 clause (its tokens after `pass_2')."""
    tr['p2'] = int(body[1][3:], 16) if body[1].startswith('16#') else int(body[1])
    tr['p2_body'] = None
    tr['p2_hand'] = False
    tr['p2_residue'] = 'residue' in body
    if 'empty' in body:
        tr['p2_empty'] = True
    if 'body' in body:
        stmts, hand = bodies[int(body[body.index('body') + 1])]
        tr['p2_body'] = stmts
        tr['p2_hand'] = hand


def fmt_clause(addr, empty, stmts=None, hand=False, why=None):
    """The clause's text (the extractor's)."""
    if empty:
        return ['  pass_2 image 16#%06X empty;' % addr]
    if stmts is None:
        return ['  { not lifted: %s }' % why.replace('{', '(').replace('}', ')'),
                '  pass_2 image 16#%06X residue;' % addr]
    lines = L.fmt_body(stmts, '    ')
    lines[0] = '  pass_2 image 16#%06X %sbegin' % (addr, 'hand ' if hand else '')
    return lines


def hand_bodies(rules_dir):
    """{rule: [lines]} of the hand-written pass_2 bodies in the rule files
    (the extractor keeps them)."""
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
            if re.match(r'\s*pass_2 image 16#[0-9A-F]+ hand begin', lines[k]):
                j = k
                text = ''
                while True:
                    text += lines[j] + '\n'
                    body = text[text.index('begin'):]
                    try:
                        match_end(L.strip_comments(body), 0)
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
    """{section number: (start, end)} of the pass-2 modules (end the next
    module's start, the last's hard_work)."""
    starts = {}
    for s in rules.sections:
        addrs = [rules.transforms[r]['p2'] for r in s['transforms']
                 if rules.transforms[r]['p2'] is not None]
        if addrs:
            starts[s['number']] = min(addrs)
    order = sorted(starts, key=starts.get)
    out = {}
    for k, n in enumerate(order):
        out[n] = (starts[n], starts[order[k + 1]] if k + 1 < len(order) else P2_END)
    return out


def module_file(sec):
    return (MODULE % (sec['number'], sec['topic'])) + '.pas'


def manifest_lines(rules):
    out = []
    rng = module_ranges(rules)
    for s in sorted(rules.sections, key=lambda s: rng.get(s['number'], (0,))[0]):
        if s['number'] not in rng:
            continue
        lo, hi = rng[s['number']]
        a5 = s.get('p2_a5')
        out.append('module\t%s\t%s\t0x%06X\t0x%06X' % (
            module_file(s), '0x%06X' % a5 if a5 else '-', lo, hi))
    out.append('unit\tisc_pass_1_main.pas\tnamed')
    out.append('unit\tisc_pass_2_main.pas\tnamed')
    return out


def complete(rules, sec):
    return all(not rules.transforms[r].get('p2_residue') and
               (rules.transforms[r]['p2_empty'] or rules.transforms[r].get('p2_body') is not None)
               for r in sec['transforms'])


HEADING = '''procedure transform_%d_pass_2(var self: isc_solution_t;
    subject: isc_solution_ptr_t; var result: isc_solution_t;
    solution: isc_solution_ptr_t); options(val_param);'''

FLAGS_VIEW = '''  { The booleans isc_solution_fields.ins.pas lumps into one field
    (f76.b81_7_2, f76.b83_7_4), under the image's names: a view of a
    solution's f76 (+76..+87). }
  p2_flags_ptr_t = ^p2_flags_t;
  p2_flags_t = packed record
    b76, b77, b78, b79, b80: 0..255;    { +76 }
    all_zeroes_or_all_ones: boolean;    { +81 .7 }
    arg_block_location: boolean;        { .6 }
    bit_7_was_sign_extended: boolean;   { .5 }
    bit_15_was_sign_extended: boolean;  { .4 }
    dead_end: boolean;                  { .3 }
    derived_from_literal: boolean;      { .2 }
    b81_1_0: 0..3;
    b82: 0..255;                        { +82 }
    is_volatile: boolean;               { +83 .7 }
    literal_64_bits_value_is_zero: boolean;  { .6 }
    literal_derived_from_floating_constant: boolean;  { .5 }
    materialize_true_as_1: boolean;     { .4 }
    b83_3_0: 0..15;
    end;'''

LOCALS_VIEW = '''  { A rule's own fields where the insert has none of their size: words
    and longwords below +352 (the insert has bytes there, space136),
    bytes and longwords at an offset 4k + 2 from +352 (the insert has
    pointers at 4k): a view of the whole solution by offset / 2, offset
    / 4 (and (offset - 2) / 4) and offset. }
  p2_locals_ptr_t = ^p2_locals_t;
  p2_locals_t = record
    case integer of
      1: (w: array [0..215] of integer);
      2: (p: array [0..107] of isc_solution_ptr_t);
      3: (c: array [0..431] of 0..255);
      4: (w0: integer;
          p2: array [0..106] of isc_solution_ptr_t);
    end;'''


NODE_VIEW = '''  { An IL node's bytes, words and longwords by offset (the actions read
    a node's fields by offset whatever its kind: p2_node_t names none). }
  p2_node_ptr_t = ^p2_node_t;
  p2_node_t = record
    case integer of
      1: (b: array [0..511] of 0..255);
      2: (w: array [0..255] of integer);
      3: (p: array [0..127] of univ_ptr);
    end;'''


READONLY_VIEW = '''  { isc_readonly_tables by word (the actions index word tables in it that
    isc_types.ins.pas's view leaves unnamed). }
  p2_readonly_ptr_t = ^p2_readonly_t;
  p2_readonly_t = record
    w: array [0..1559] of integer;
    end;'''

LIR_TABS = '''var
  { lir.pas's physical registers' solutions by floating register (lir +0x3C60,
    +0x3D60): lir.pvt.pas declares them, which the ISC does not open. }
  lir_3c60: extern array [0..63] of solution_ptr_t;
  lir_3d60: extern array [0..63] of solution_ptr_t;'''


def gen_module(rules, sec, headings, includes, gen_note, pattern_text):
    """The Pascal of a section's pass-2 module."""
    T = rules.transforms
    rng = module_ranges(rules)
    lo, hi = rng[sec['number']]
    allp2 = sorted(T[r]['p2'] for r in T if T[r]['p2'] is not None) + [P2_END]
    name = MODULE % (sec['number'], sec['topic'])
    rs = sec['transforms']
    nempty = sum(1 for r in rs if T[r]['p2_empty'])
    nhand = sum(1 for r in rs if T[r].get('p2_hand'))
    a5 = sec.get('p2_a5')
    head = ['{ %s - the pass-2 actions of the ISC\'s section %d (%s), rules' % (
        name, sec['number'], sec['topic'].replace('_', ' ')),
        '  %d..%d (a DSEE derived object of the iscg_input description; cc.a88k' % (rs[0], rs[-1]),
        '  only): pass_2 (isc_pass_2_main) calls each through its table by the',
        '  rule (which_transform) of a solution the rule made, after the',
        '  solution\'s subject and children are through pass 2.', '']
    head.extend(gen_note.rstrip('\n').split('\n'))
    head.append('')
    head.append('  Image addresses (cc.a88k; no .blocks record: tools/cc_isc_check.py')
    head.append('  compares the routines at the manifest\'s addresses, iscg_names.txt):')
    for r in rs:
        head.append('    transform_%d_pass_2  0x%06X%s' % (r, T[r]['p2'],
                                                         '  (empty)' if T[r]['p2_empty'] else ''))
    head.append('  Code 0x%06X..0x%06X.  %s' % (lo, hi, (
        'A5 0x%06X: the module\'s data, four bytes nothing reads (Rev 8.89' % a5
        if a5 else 'No routine loads A5 (every action is empty); the module\'s')))
    head.append('  gives every module a data block: docs/rev889-patterns.md 330); dpc')
    head.append('  allocates none.  Every non-empty action loads A5 in the image')
    head.append('  (pattern 1); dpc loads it only for data (best effort).  %d of the' % nempty)
    head.append('  %d actions are empty: a bare `rts\' (pattern 165).' % len(rs))
    if nhand:
        head.append('  %d bodies are written by hand in the rule file (not lifted).' % nhand)
    head.append('')
    head.append('  Not known from the original: the module\'s, the routines\' and the')
    head.append('  parameters\' names (docs/questions.md 266), the temporaries\'. }')
    out = head + ['module %s;' % name, '']
    out.append(includes.rstrip('\n'))
    out.append('')
    bodies = {}
    need_flags = need_locals = need_node = need_ro = need_lir = False
    errors = []
    for r in rs:
        if T[r]['p2_empty']:
            continue
        em = L.Emitter(r, headings)
        try:
            decl, body = em.routine(T[r]['p2_body'])
        except L.LangError as e:
            errors.append(str(e))
            continue
        text = '\n'.join(decl + body)
        need_flags |= 'p2_flags_ptr_t' in text
        need_locals |= 'p2_locals_ptr_t' in text
        need_node |= 'p2_node_ptr_t' in text
        need_ro |= 'p2_readonly_ptr_t' in text
        need_lir |= 'lir_3c60' in text or 'lir_3d60' in text
        bodies[r] = (decl, body)
    if errors:
        raise L.LangError('; '.join(errors))
    if need_flags or need_locals or need_node or need_ro:
        out.append('type')
        if need_node:
            out.append(NODE_VIEW)
        if need_ro:
            out.append(READONLY_VIEW)
        if need_flags:
            out.append(FLAGS_VIEW)
        if need_locals:
            out.append(LOCALS_VIEW)
        out.append('')
    if need_lir:
        out.append(LIR_TABS)
        out.append('')
    for r in rs:
        t = T[r]
        k = allp2.index(t['p2'])
        size = allp2[k + 1] - t['p2']
        out.extend(wrap_words('{ transform_%d_pass_2 - rule %d: %s <- %s.' % (
            r, r, t['kind'], pattern_text(t)), 76, '  '))
        out.append('  0x%06X, 0x%X bytes%s. }' % (t['p2'], size,
                                                  ' (an empty action: `rts\')' if t['p2_empty']
                                                  else (', written by hand' if t.get('p2_hand')
                                                        else '')))
        out.append(HEADING % r)
        if t['p2_empty']:
            out.append('begin')
            out.append('end;')
        else:
            decl, body = bodies[r]
            out.extend(decl)
            out.append('begin')
            out.extend(body)
            out.append('end;')
        out.append('')
    return '\n'.join(out).rstrip('\n') + '\n'


def wrap_words(text, width, ind):
    words = text.split(' ')
    lines, cur = [], ''
    for w in words:
        if cur and len(cur) + 1 + len(w) > width:
            lines.append(cur)
            cur = ind + w
        else:
            cur = (cur + ' ' + w) if cur else w
    lines.append(cur)
    return lines


def modules(gen, includes, gen_note):
    """{file name: text} of the complete sections' modules."""
    headings = L.read_headings(includes)
    out = {}
    errors = []
    for sec in gen.r.sections:
        if not complete(gen.r, sec):
            continue
        try:
            out[module_file(sec)] = gen_module(gen.r, sec, headings, includes, gen_note,
                                               pattern_text)
        except L.LangError as e:
            errors.append(str(e))
    if errors:
        raise L.LangError('\n'.join(errors))
    return out


def pattern_text(t):
    parts = []
    for subj, kids in t['alts']:
        parts.append(subj + (' ' + fmt_kids(kids) if kids else ''))
    # alternatives sharing children
    if len(t['alts']) > 1 and all(k == t['alts'][0][1] for _, k in t['alts']):
        return ' | '.join(s for s, _ in t['alts']) + (
            ' ' + fmt_kids(t['alts'][0][1]) if t['alts'][0][1] else '')
    return ' | '.join(parts)


def fmt_kids(kids):
    out = []
    for k in sorted(kids):
        spec = kids[k]
        if spec[0] == 'kind':
            out.append('$%d: %s' % (k, spec[1]))
        elif spec[0] == 'kinds':
            out.append('$%d: [%s]' % (k, ', '.join(spec[1])))
        else:
            out.append('$%d: %s%s' % (k, spec[1], fmt_kids(spec[2]) if spec[2] else '()'))
    return '(' + ', '.join(out) + ')'
