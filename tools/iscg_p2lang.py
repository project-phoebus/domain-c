#!/usr/bin/env python3
"""iscg_p2lang.py - the ISC generator's statement language for the pass-2 actions.

The rule file's pass-2 bodies (docs/iscg-design.md 4, 10.5) are written
in a small Pascal-flavoured statement language; this module is its
abstract syntax, its printer (the decompiler, tools/iscg_p2lift.py,
writes bodies through it), its parser and its translation to Pascal
(tools/iscg_gen.py emits the 25 isc_pass_2_<nn>_<topic>.pas modules
through it).

    body     := 'begin' {stmt} 'end'
    stmt     := path '<-' expr ';'
              | 'let' 'result' '<-' expr 'line' NUMBER ';'
              | 'emit' KIND '(' [args] ')' ';'
              | NAME ['(' [args] ')'] ';'                 a procedure call
              | 'if' expr 'then' {stmt} {'elsif' expr 'then' {stmt}}
                ['else' {stmt}] 'end' ';'
              | 'for' NAME ':=' expr 'to' expr 'do' {stmt} 'end' ';'
              | 'temp' NAME ':' TYPE ';'                  a local of the action
    expr     := Pascal's (or, and, not, = <> < <= > >=, + - * div mod,
                unary -), with
                NUMBER, 16#HEX, nil, true, false, 'string', opc$NAME,
                NAME(args) (a function), addr(path), path
    path     := base {'.' sel}
    base     := self | subject | result | solution | $K | NAME
    sel      := ATTRIBUTE | $K | cNNN | wNNN | lNNN | sNNN

- self, subject, result and solution are the action's parameters (the
  solution the rule made, the solution it was made from, the solution
  whose attributes are set: self again, and self's pointer); `$K' is
  subject.$K, the subject's child K; `.' reaches through a pointer.
- Attributes are the image's names (dump_solution's, declarations.isc;
  the inherited attributes' as isc_print_il_node prints them, docs/
  questions.md 271).  cNNN, wNNN and lNNN are the rule's own fields at
  offset NNN (a byte, a word, a longword: the alternatives' choice bytes
  from +136, the pointer locals from +352; the generator lays nothing
  out, the offsets are the image's); sNNN a solution longword the
  attribute declarations do not name.
- `emit KIND(args)' is debug_lir_$KIND_instruction(result.inherited_
  attributes, args) (debug_lir_$label for label).
- `let result <- e line N;' sets solution.live_range to e and stops
  with the original's message when it is nil (the image keeps the
  statement and its line in the input: docs/iscg-design.md 1.2).
- Unsigned comparisons are written u<, u<=, u>, u>= (the image's bhi,
  bcs, ...); the generator compiles them as the plain ones (the operands
  are the unsigned fields).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))


class LangError(Exception):
    pass


PARAMS = ('self', 'subject', 'result', 'solution')
EMIT_KINDS = ('simple', 'load', 'store', 'field', 'branch', 'dispatch', 'mfpr', 'mtpr',
              'operate_and_branch', 'pa_risc_shift_double', 'label')

# --------------------------------------------------------------------------
# the solution's fields: isc_solution_fields.ins.pas names them after the
# image's attributes (docs/questions.md 267), so an attribute's field is
# its name, inside f76 (+76..+87) or f114 (+114, +115) (sol_path); the
# tables give each field's type class and the fields dump_solution does
# not print (by offset)


def sol_path(name, off):
    """The insert's field path of the solution attribute name at off."""
    return ('f76.' if 76 <= off < 88 else 'f114.' if off in (114, 115) else '') + name


# the classes of the enumerated fields (the insert's types: il_kind an
# il$t, kind a solution$t, docs/questions.md 312); a number the rule file
# gives one is written as the element's name (enum_name)
IL_T = 'other:il$t'
SOLUTION_T = 'other:solution$t'
ENUMS = (IL_T, SOLUTION_T)
SOLUTION_KINDS = ['none', 'case_jump_base', 'fp_reg_pair_high', 'fp_reg_pair_low',
                  'local_routine', 'address_mode', 'ctl_reg', 'flow', 'fp_reg', 'fp_reg_pair',
                  'fp_reg_quad', 'ip_reg', 'ip_reg_field', 'ip_reg_scaled', 'literal_32_bits',
                  'literal_64_bits', 'processor_reg', 'sc_reg', 'sr_reg', 'dummy',
                  'any_solution', 'irrelevant', 'proper_subtree', 'void', 'k_max']
_IL_T_NAMES = None


def il_t_names():
    """il$t's elements in order (isc_enumeration.ins.pas)."""
    global _IL_T_NAMES
    if _IL_T_NAMES is None:
        p = os.path.join(ROOT, 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/'
                         'hd69fbe76.000/iscg_input/isc_enumeration.ins.pas')
        m = re.search(r'\bil\$t\s*=\s*\((.*?)\);', open(p, encoding='latin-1').read(), re.S)
        _IL_T_NAMES = [x.strip() for x in re.sub(r'\{[^}]*\}', '', m.group(1)).split(',')]
    return _IL_T_NAMES


def enum_name(cls, v):
    """The element of the enumerated class cls whose ordinal is v."""
    if cls == SOLUTION_T:
        return 'solution$' + SOLUTION_KINDS[v]
    return il_t_names()[v]


# the rules' locals the insert names (docs/questions.md 313): +136 ..
# +341 the bytes of case_value, +342 .. +348 the chain rules' cycle
# guard, one flag per register kind
ALREADY = ['already_address_mode', 'already_fp_reg', 'already_fp_reg_pair',
           'already_fp_reg_quad', 'already_ip_reg', 'already_ip_reg_field',
           'already_processor_reg']

# (offset, size) -> (insert path, class) for the whole longwords, words,
# bytes
SOL_FIELDS = {
    (0, 4): ('object_with_name', 'up'), (4, 4): ('base_register', 'isp'),
    (8, 4): ('index_register', 'isp'), (12, 4): ('l12', 'i32'), (16, 4): ('false_label', 'up'),
    (20, 4): ('live_range', 'lr'), (24, 4): ('live_range_of_imaginary_part', 'lr'),
    (28, 4): ('advancing_displacement', 'i32'), (32, 4): ('bits_known', 'i32'),
    (36, 4): ('bits_trusted', 'i32'), (40, 4): ('bits_known_of_fetched_value', 'i32'),
    (44, 4): ('bits_trusted_of_fetched_value', 'i32'), (48, 4): ('literal_32_bits_value', 'i32'),
    (52, 4): ('pass_1_size', 'i32'),
    (56, 2): ('bytes', 'i16'), (58, 2): ('fp_reg_max', 'i16'), (60, 2): ('fp_reg_result', 'i16'),
    (62, 2): ('fp_reg_pair_max', 'i16'), (64, 2): ('fp_reg_pair_result', 'i16'),
    (66, 2): ('fp_reg_quad_max', 'i16'), (68, 2): ('fp_reg_quad_result', 'i16'),
    (70, 2): ('ip_reg_max', 'i16'), (72, 2): ('ip_reg_result', 'i16'),
    (74, 2): ('n_bytes_to_back_up', 'i16'),
    (76, 1): ('f76.bit_position_of_lsb', 'u8'), (77, 1): ('f76.field_precision', 'u8'),
    (78, 1): ('f76.physical_register_number', 'u8'), (79, 1): ('f76.scale', 'u8'),
    (80, 1): ('f76.slevel_attribute', 'u8'), (85, 1): ('f76.b85', 'u8'),
    (86, 1): ('f76.b86', 'u8'), (87, 1): ('f76.b87', 'u8'),
    (88, 4): ('before_transform', 'isp'), (92, 2): ('code_bytes', 'u16'), (94, 2): ('delay', 'u16'),
    (96, 2): ('evaluation_order', 'i16'), (98, 2): ('il_kind', IL_T), (100, 4): ('il', 'up'),
    (104, 4): ('inherited_attributes', 'inh'), (108, 2): ('kind', SOLUTION_T),
    (110, 2): ('memory_references', 'u16'), (112, 2): ('which_transform', 'i16'),
    (114, 1): ('f114.number_of_children', 'u8'),
}
for _k in range(5):
    SOL_FIELDS[(116 + 4 * _k, 4)] = ('children[%d]' % (_k + 1), 'isp')
# (offset, bit) -> insert path, for the booleans (+81 .. +84 in f76, +115
# in f114; f76.b84_4_0 and f114.b2 .. b0 are not attributes)
SOL_BITS = {
    (81, 7): 'all_zeroes_or_all_ones', (81, 6): 'arg_block_location',
    (81, 5): 'bit_7_was_sign_extended', (81, 4): 'bit_15_was_sign_extended',
    (81, 3): 'dead_end', (81, 2): 'derived_from_literal',
    (81, 1): 'embedded_strength_reduction_temporary', (81, 0): 'field_requires_sign_extend',
    (82, 7): 'has_a_symbolic_displacement', (82, 6): 'is_atomic', (82, 5): 'is_complex',
    (82, 4): 'is_destroyable', (82, 3): 'is_dynm_vat', (82, 2): 'is_entire_object',
    (82, 1): 'is_physical', (82, 0): 'is_set_temporary',
    (83, 7): 'is_volatile', (83, 6): 'literal_64_bits_value_is_zero',
    (83, 5): 'literal_derived_from_floating_constant', (83, 4): 'materialize_true_as_1',
    (83, 3): 'physical_register', (83, 2): 'physical_register_from_function_call',
    (83, 1): 'physical_register_is_no_modify', (83, 0): 'physical_register_user_declared',
    (84, 7): 'uses_the_base_register', (84, 6): 'uses_the_displacement',
    (84, 5): 'uses_the_index_register',
    (115, 7): 'already_preserved', (115, 6): 'builtin_could_deadlock_sched',
    (115, 5): 'builtin_is_local_cse', (115, 4): 'builtin_local_cse_has_been_preserved',
    (115, 3): 'already_through_pass_2', (115, 2): 'b2', (115, 1): 'b1', (115, 0): 'b0',
}
SOL_BITS = {_k: sol_path(_n, _k[0]) for _k, _n in SOL_BITS.items()}

# the inherited attributes (isc_attribute_records.ins.pas, whose fields
# carry the image's names: docs/questions.md 271): name -> (offset, size
# or bit, insert path, class); the path is the name, inside pos (+32,
# +34) or f38 (+38, +39)
INH_ATTRS = {
    'il': (0, 4, 'node'), 'exception_frame': (4, 4, 'node'),
    'original_il': (12, 4, 'node'), 'conditional_target': (16, 4, 'i32'),
    'call_instruction_ptr': (20, 4, 'up'), 'fetch_precision': (24, 4, 'i32'),
    'required_precision': (28, 4, 'i32'),
    'source_line_number': (32, 2, 'i16'), 'stmt_number': (34, 2, 'i16'),
    'parent_il_kind': (36, 1, 'char'), 'required_arithmetic': (38, 1, 'u8'),
    'conditional_sense': (39, 'b7', 'bool'),
    'immediate_parent_has_signed': (39, 'b6', 'bool'),
    'immediate_parent_wants_lvalue': (39, 'b5', 'bool'),
    'immediate_parent_wants_set_temporary': (39, 'b4', 'bool'),
    'immediate_parent_wants_signed': (39, 'b3', 'bool'),
    'inside_a_cse': (39, 'b2', 'bool'),
}
INH_ATTRS = {_n: (_o, _s, ('pos.' if _o in (32, 34) else 'f38.' if _o in (38, 39) else '') + _n, _c)
             for _n, (_o, _s, _c) in INH_ATTRS.items()}
INH_BY_OFF = {}
for _n, (_o, _s, _p, _c) in INH_ATTRS.items():
    INH_BY_OFF[(_o, _s if isinstance(_s, int) else int(_s[1:]) + 100)] = _n

PASCAL_TYPE = {'isp': 'isc_solution_ptr_t', 'sp': 'solution_ptr_t', 'lr': 'lr_ptr_t',
               'up': 'univ_ptr', 'node': 'univ_ptr', 'inh': 'inherited_attributes_ptr_t', 'i16': 'integer',
               'u16': 'integer', 'i32': 'integer32', 'u8': 'integer', 'bool': 'boolean',
               'char': 'char'}
POINTERS = ('isp', 'sp', 'lr', 'up', 'inh', 'node')
TEMP_TYPES = {'solution': 'isp', 'pointer': 'up', 'integer': 'i16', 'integer32': 'i32',
              'boolean': 'bool', 'live_range': 'lr'}
TEMP_TYPE_NAMES = {v: k for k, v in TEMP_TYPES.items()}

# the globals the actions read: name -> class (isc_var_externs.ins.pas,
# backend.ins.pas)
GLOBALS = {}


def attribute_table(rules_dir=None):
    """{name: (offset, size, bit)} from declarations.isc's attribute lines
    (size 1, 2, 4; bit None but for a boolean)."""
    d = rules_dir or os.path.join(ROOT, 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/rules')
    out = {'object_with_name': (0, 4, None)}
    text = open(os.path.join(d, 'declarations.isc')).read()
    for m in re.finditer(r'^attribute (\w+) \+(\d+)(?:\.(\d))? (\w+);', text, re.M):
        name, off, bit, typ = m.group(1), int(m.group(2)), m.group(3), m.group(4)
        if typ == 'local':
            continue
        size = {'integer': 2, 'integer32': 4, 'byte': 1, 'pointer': 4, 'boolean': 1}[typ]
        out[name] = (off, size, int(bit) if bit is not None else None)
    return out


ATTRS = None
ATTR_BY_OFF = None


def attrs():
    global ATTRS, ATTR_BY_OFF
    if ATTRS is None:
        ATTRS = attribute_table()
        ATTR_BY_OFF = {}
        for n, (o, s, b) in ATTRS.items():
            ATTR_BY_OFF[(o, s, b)] = n
    return ATTRS


def sol_name(off, size, bit=None):
    """The language's name of a solution field (None if it has none)."""
    attrs()
    n = ATTR_BY_OFF.get((off, size, bit))
    if n:
        return n
    if bit is not None:
        return None
    if 116 <= off < 136 and size == 4 and off % 4 == 0:
        return '$%d' % ((off - 116) // 4 + 1)
    if 136 <= off < 432:
        return {1: 'c', 2: 'w', 4: 'l'}[size] + str(off)
    if (off, size) in SOL_FIELDS:
        return 's%d' % off if size == 4 else ('h%d' % off if size == 2 else 'b%d' % off)
    return None


# --------------------------------------------------------------------------
# routine headings (the inserts the modules open)

HEADING = re.compile(r'\b(procedure|function)\s+([\w$]+)\s*(\((.*?)\))?\s*(?::\s*([\w$]+))?\s*;'
                     r'\s*(?:options\s*\(([^)]*)\)\s*;)?\s*extern\s*;', re.S | re.I)


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


def type_class(t):
    t = t.strip().lower()
    for k, v in PASCAL_TYPE.items():
        if v == t and k not in ('u16', 'u8'):
            return k
    if t in ('il_$node_ptr_t',):
        return 'up'
    return 'other:' + t


# routines whose heading lies in an insert the INCLUDES list opens only
# through another (globals.ins.pas): name -> insert
EXTRA = {'smcontk': 'lang/lang/source/token.ins.pas'}


def extra_heading_text(name):
    """The heading of EXTRA's routine as its insert writes it."""
    text = strip_comments(open(os.path.join(ROOT, EXTRA[name]), encoding='latin-1').read())
    for m in HEADING.finditer(text):
        if m.group(2).lower() == name:
            return ' '.join(m.group(0).split())
    raise LangError('no heading for %s in %s' % (name, EXTRA[name]))


def read_headings(include_text):
    """{name (lower): {'params': [(name, mode, class, univ)], 'ret': class or
    None, 'val_param': bool, 'variable': bool}} from the inserts the
    INCLUDES text opens (the tree's)."""
    out = {}
    for path in re.findall(r"%include '([^']+)'", include_text):
        p = os.path.join(ROOT, path.lstrip('/'))
        if not os.path.exists(p):
            continue
        text = strip_comments(open(p, encoding='latin-1').read())
        for m in HEADING.finditer(text):
            name = m.group(2).lower()
            params = []
            if m.group(4):
                for grp in m.group(4).split(';'):
                    if ':' not in grp:
                        continue
                    names, typ = grp.rsplit(':', 1)
                    mode = 'value'
                    names = names.strip()
                    for md in ('in out', 'var', 'in', 'out'):
                        if names.lower().startswith(md + ' '):
                            mode = md
                            names = names[len(md):].strip()
                            break
                    univ = typ.strip().lower().startswith('univ ')
                    if univ:
                        typ = typ.strip()[5:]
                    for n in names.split(','):
                        params.append((n.strip(), mode, type_class(typ), univ))
            opts = (m.group(6) or '').lower()
            out[name] = {'params': params, 'ret': type_class(m.group(5)) if m.group(5) else None,
                         'val_param': 'val_param' in opts, 'variable': 'variable' in opts}
        # the globals the actions may read
        for m in re.finditer(r'^\s*([\w$]+)\s*:\s*extern\s+([\w$]+)\s*;', text, re.M):
            GLOBALS.setdefault(m.group(1).lower(), type_class(m.group(2)))
    for name, path in EXTRA.items():
        if name not in out:
            sub = read_headings_of(path)
            if name in sub:
                out[name] = sub[name]
    return out


def read_headings_of(path):
    return read_headings("%%include '%s';" % path) if path else {}


# --------------------------------------------------------------------------
# the abstract syntax
#
# expressions: ('num', v) ('nil',) ('bool', b) ('str', s) ('opc', name)
# ('ilk', name) ('cname', name, v) (a named constant: a register class,
# tree or assignment operator, value v; il_names)
#   ('path', base, [sel...])  base a parameter, '$K' or a name; sel an
#   attribute name, '$K', cNNN ...
#   ('call', name, [args]) ('addr', path) ('bin', op, a, b) ('un', op, a)
# statements: ('set', path, expr) ('let', expr, line) ('emit', kind, [args])
#   ('call', name, [args]) ('if', [(cond, [stmts])...], [else stmts] or None)
#   ('for', name, lo, hi, [stmts]) ('temp', name, type)

PREC = {'or': 1, 'and': 2, '=': 3, '<>': 3, '<': 3, '<=': 3, '>': 3, '>=': 3,
        'u<': 3, 'u<=': 3, 'u>': 3, 'u>=': 3, '+': 4, '-': 4, '!': 4, '*': 5, 'div': 5,
        'mod': 5, '&': 5}
BUILTINS = {'lshft': 'i32', 'rshft': 'i32', 'arshft': 'i32'}


def fmt_expr(e, prec=0):
    k = e[0]
    if k == 'cname':
        return e[1]
    if k == 'bin' and e[1] in ('=', '<>', '<', '<=', '>', '>=', 'u<', 'u<=', 'u>', 'u>='):
        a, b = named_operand(e[2], e[3]), named_operand(e[3], e[2])
        if a is not e[2] or b is not e[3]:
            e = ('bin', e[1], a, b)
    if k == 'num':
        v = e[1]
        return ('16#%X' % v if v >= 4096 else str(v)) if v >= 0 else (
            '-16#%X' % -v if -v >= 4096 else str(v))
    if k == 'nil':
        return 'nil'
    if k == 'bool':
        return 'true' if e[1] else 'false'
    if k == 'str':
        return "'" + e[1].replace("'", "''") + "'"
    if k == 'real':
        return repr(float(e[1]))
    if k in ('opc', 'ilk'):
        return e[1]
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
        p = PREC[e[1]]
        s = '%s %s %s' % (fmt_expr(e[2], p), e[1], fmt_expr(e[3], p + 1))
        return '(%s)' % s if p < prec or (p == 3 and prec == 3) else s
    raise LangError('expression %r' % (e,))


def fmt_stmts(stmts, ind):
    out = []
    for s in stmts:
        out.extend(fmt_stmt(s, ind))
    return out


def fmt_stmt(s, ind):
    k = s[0]
    if k == 'set':
        return [ind + '%s <- %s;' % (fmt_expr(s[1]), fmt_expr(named_operand(s[2], s[1])))]
    if k == 'let':
        return [ind + 'let result <- %s line %d;' % (fmt_expr(s[1]), s[2])]
    if k == 'emit':
        return [ind + 'emit %s(%s);' % (s[1], ', '.join(fmt_expr(a) for a in s[2]))]
    if k == 'call':
        return [ind + ('%s(%s);' % (s[1], ', '.join(fmt_expr(a) for a in s[2]))
                       if s[2] else '%s;' % s[1])]
    if k == 'temp':
        return [ind + 'temp %s: %s;' % (s[1], s[2])]
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
    raise LangError('statement %r' % (s,))


def fmt_body(stmts, ind='    '):
    if not stmts:
        return []
    return [ind[:-2] + 'begin'] + fmt_stmts(stmts, ind) + [ind[:-2] + 'end;']


# --------------------------------------------------------------------------
# parsing

TOK = re.compile(r"\s*(16#[0-9A-Fa-f]+|'(?:[^']|'')*'|\$\d+|<-|:=|<>|<=|>=|u<=|u>=|u<|u>|"
                 r"\d+\.\d+(?:[eE][-+]?\d+)?|"
                 r"[A-Za-z_][A-Za-z0-9_$]*|\d+|\S)")


def tokenize(text):
    out, pos = [], 0
    text = strip_comments(text)
    while True:
        m = TOK.match(text, pos)
        if not m:
            if text[pos:].strip():
                raise LangError('cannot read %r' % text[pos:pos + 20])
            return out
        out.append(m.group(1))
        pos = m.end()


class Parser:
    def __init__(self, toks):
        self.t = toks
        self.i = 0

    def peek(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else None

    def next(self):
        tok = self.peek()
        self.i += 1
        return tok

    def expect(self, tok):
        if self.peek() != tok:
            raise LangError('expected %r, found %r (in %s)' % (
                tok, self.peek(), ' '.join(self.t[max(0, self.i - 8):self.i + 4])))
        self.i += 1

    def body(self):
        self.expect('begin')
        stmts = self.stmts(('end',))
        self.expect('end')
        if self.peek() == ';':
            self.i += 1
        return stmts

    def stmts(self, stops):
        out = []
        while self.peek() not in stops:
            if self.peek() is None:
                raise LangError('unexpected end')
            out.append(self.stmt())
        return out

    def stmt(self):
        t = self.peek()
        if t == 'if':
            self.i += 1
            arms = []
            c = self.expr()
            self.expect('then')
            arms.append((c, self.stmts(('elsif', 'else', 'end'))))
            els = None
            while True:
                if self.peek() == 'elsif':
                    self.i += 1
                    c = self.expr()
                    self.expect('then')
                    arms.append((c, self.stmts(('elsif', 'else', 'end'))))
                elif self.peek() == 'else':
                    self.i += 1
                    els = self.stmts(('end',))
                else:
                    break
            self.expect('end')
            self.expect(';')
            return ('if', arms, els)
        if t == 'for':
            self.i += 1
            v = self.next()
            self.expect(':=')
            lo = self.expr()
            self.expect('to')
            hi = self.expr()
            self.expect('do')
            body = self.stmts(('end',))
            self.expect('end')
            self.expect(';')
            return ('for', v, lo, hi, body)
        if t == 'temp':
            self.i += 1
            n = self.next()
            self.expect(':')
            typ = self.next()
            self.expect(';')
            return ('temp', n, typ)
        if t == 'let':
            self.i += 1
            self.expect('result')
            self.expect('<-')
            e = self.expr()
            self.expect('line')
            line = int(self.next())
            self.expect(';')
            return ('let', e, line)
        if t == 'emit':
            self.i += 1
            kind = self.next()
            args = self.args()
            self.expect(';')
            return ('emit', kind, args)
        lhs = self.primary()
        if self.peek() == '<-':
            self.i += 1
            e = self.expr()
            self.expect(';')
            return ('set', lhs, e)
        self.expect(';')
        if lhs[0] == 'call':
            return ('call', lhs[1], lhs[2])
        if lhs[0] == 'path' and not lhs[2]:
            return ('call', lhs[1], [])
        raise LangError('not a statement: %s' % fmt_expr(lhs))

    def args(self):
        self.expect('(')
        out = []
        while self.peek() != ')':
            out.append(self.expr())
            if self.peek() == ',':
                self.i += 1
        self.expect(')')
        return out

    def expr(self, prec=1):
        left = self.unary()
        while True:
            op = self.peek()
            if op not in PREC or PREC[op] < prec:
                return left
            self.i += 1
            right = self.expr(PREC[op] + 1)
            left = ('bin', op, left, right)

    def unary(self):
        if self.peek() == 'not':
            self.i += 1
            return ('un', 'not', self.unary())
        if self.peek() == '-':
            self.i += 1
            e = self.unary()
            if e[0] in ('num', 'real'):
                return (e[0], -e[1])
            return ('un', '-', e)
        return self.primary()

    def primary(self):
        t = self.next()
        if t == '(':
            e = self.expr()
            self.expect(')')
            return e
        if t.startswith('16#'):
            return ('num', int(t[3:], 16))
        if t.isdigit():
            return ('num', int(t))
        if re.match(r'\d+\.\d', t):
            return ('real', float(t))
        if t.startswith("'"):
            return ('str', t[1:-1].replace("''", "'"))
        if t == 'nil':
            return ('nil',)
        if t in ('true', 'false'):
            return ('bool', t == 'true')
        if t.lower().startswith('opc$'):
            return ('opc', t.lower())
        if t.lower() in il_kind_names():
            return ('ilk', t.lower())
        if t.lower() in il_names():
            return ('cname', t.lower(), il_names()[t.lower()][1])
        if t == 'addr':
            self.expect('(')
            p = self.primary()
            self.expect(')')
            return ('addr', p)
        if self.peek() == '(':
            return ('call', t.lower(), self.args())
        if self.peek() == '[':
            self.i += 1
            ix = self.expr()
            self.expect(']')
            e = ('index', t.lower(), ix)
            if self.peek() != '.':
                return e
            base = e
            sels = []
            while self.peek() == '.':
                self.i += 1
                sels.append(self.next())
            return ('path', base, sels)
        base = t
        sels = []
        if base.startswith('$'):
            base, sels = 'subject', [t]
        while self.peek() == '.':
            self.i += 1
            sels.append(self.next())
        return ('path', base, sels)


def parse_body(text):
    p = Parser(tokenize(text))
    out = p.body()
    if p.peek() is not None:
        raise LangError('text after the body: %r' % p.peek())
    return out


# --------------------------------------------------------------------------
# the IL node kinds (il.ins.pas's il_$kind_t): a rule names a kind by its
# name ('ilk', name), written as the name

_IL_KINDS = None


def il_kind_names():
    global _IL_KINDS
    if _IL_KINDS is None:
        import os
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..',
                         'lang', 'lang', 'source', 'il.ins.pas')
        m = re.search(r'\bil_\$kind_t = \((.*?)\);', open(p, encoding='latin1').read(), re.S)
        _IL_KINDS = frozenset(x.strip() for x in re.sub(r'\{[^}]*\}', '', m.group(1)).split(','))
    return _IL_KINDS


# the register classes (il.ins.pas's rlen_ constants) and the tree and
# assignment operators (il_$top_t, il_$aop_t) by name: an IL node's word at
# +24 (a tree's register class), +36 (a tree's operator) or +76 (an
# assignment's operator) compared with or set to a number is written with
# the value's name ('cname', name, value)

_IL_NAMES = None
NAMED_WORDS = {'w24': 'rlen', 'w36': 'top', 'w76': 'aop'}


def il_names():
    """{name: (what, value)} of the named constants."""
    global _IL_NAMES
    if _IL_NAMES is None:
        import os
        p = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..',
                         'lang', 'lang', 'source', 'il.ins.pas')
        text = open(p, encoding='latin1').read()
        out = {}
        for what, ty in (('top', 'il_$top_t'), ('aop', 'il_$aop_t')):
            m = re.search(r'\b%s = \((.*?)\);' % re.escape(ty), text, re.S)
            for v, x in enumerate(re.sub(r'\{[^}]*\}', '', m.group(1)).split(',')):
                out[x.strip()] = (what, v)
        for m in re.finditer(r'^  (rlen_\w+) = (\d+);', text, re.M):
            out[m.group(1)] = ('rlen', int(m.group(2)))
        for m in re.finditer(r'^  (math_\w+) = (\d+);', text, re.M):
            out[m.group(1)] = ('math', int(m.group(2)))
        _IL_NAMES = out
    return _IL_NAMES


# the operand modifiers (a tree node's words at +26 and +28, its
# descriptor's opmod1 and opmod2; docs/questions.md 326 (d)): what each
# holds depends on the operator, as list_tree's print_tree_exp gives it
# (its u1 and u2, print_opmod_use): a register class (uses 1 opr1 .. 6
# dst) or, in opmod1 of an F_MATH tree, the math function (use 11).  The
# others stay numbers: a condition code (use 7, which the ISC also
# treats as a signed number: `24 + abs(...)', `< 0'), bytes, bits, a
# linkage register, an alignment, and the uses list_tree does not give
# (EXTEND's opmod2).  A number compared with an opmod of the subject's
# node or of a child's whose operator the rule's pattern names is
# written by name when every operator the pattern allows there gives it
# the same use (opmod_operand); the rule file keeps the number.
_SHIFT_MUL_DIV = ('lshf_top', 'rshf_top', 'alshf_top', 'arshf_top', 'mul_top', 'isc_mul_top',
                  'divide_top', 'div_top', 'signed_div_top', 'unsigned_div_top', 'mod_top',
                  'signed_mod_top', 'unsigned_mod_top', 'isc_signed_mod_top',
                  'isc_unsigned_mod_top', 'isc_signed_rem_top', 'isc_unsigned_rem_top')
_COMPARES = ('bit_field_cmp_top', 'compare_top', 'f_compare_top', 'set_compare_top',
             'agg_compare_top', 'isc_agg_cmp_top', 'isc_agg_lex_cmp_top')
OPMOD_USE = {
    'w26': dict([(o, 'rlen') for o in _SHIFT_MUL_DIV + _COMPARES + (
        'extend_top', 'bit_test_top', 'bit_set_top', 'index_top', 'unpack_top', 'isc_addr_top',
        'f_extend_top', 'set_bit_in_set_top', 'set_range_in_set_top')] +
                [('f_math_top', 'math')]),
    'w28': dict((o, 'rlen') for o in _SHIFT_MUL_DIV + ('f_math_top', 'f_expon_top')),
}
_PATTERN_OPS = {}


def set_patterns(transforms):
    """The operators each rule's pattern names, by position (() the
    subject, (k,) its child k, (k, j) that child's child j ...), from the
    rule file's transforms (iscg_gen.Rules: alts [(subject, children)];
    a solution kind where the pattern names no operator)."""
    _PATTERN_OPS.clear()
    for r, t in transforms.items():
        ops = {}

        def walk(kids, at):
            for k, spec in kids.items():
                if spec[0] == 'op':
                    ops.setdefault(at + (k,), set()).add(spec[1])
                    walk(spec[2], at + (k,))
                else:
                    ops.setdefault(at + (k,), set()).add(None)
        for subj, kids in t['alts']:
            ops.setdefault((), set()).add(subj)
            walk(kids, ())
        _PATTERN_OPS[r] = ops


def opmod_operand(rule, x, other):
    """x, a number, by name when other is an operand modifier whose use
    the pattern of rule fixes (OPMOD_USE)."""
    if x[0] != 'num' or other[0] != 'path' or not other[2] or other[2][-1] not in OPMOD_USE:
        return x
    sels = list(other[2][:-1])
    if other[1] == 'subject':
        if not sels or sels[-1] != 'il':
            return x
        sels = sels[:-1]
    elif other[1] != 'il' or sels:
        return x
    if not all(re.match(r'\$\d+$', s) for s in sels):
        return x
    ops = _PATTERN_OPS.get(rule, {}).get(tuple(int(s[1:]) for s in sels))
    if not ops:
        return x
    uses = {OPMOD_USE[other[2][-1]].get(o) for o in ops}
    if len(uses) != 1 or None in uses:
        return x
    what = uses.pop()
    for n, (w, v) in il_names().items():
        if w == what and v == x[1]:
            return ('cname', n, v)
    return x


def unname(x):
    """x with its named constants as the numbers they are (('cname', n,
    v) -> ('num', v)): a printed body reads back as the lifted one."""
    if isinstance(x, tuple):
        if x and x[0] == 'cname':
            return ('num', x[2])
        return tuple(unname(y) for y in x)
    if isinstance(x, list):
        return [unname(y) for y in x]
    return x


def named_operand(x, other):
    """x, a number, by name when other is an IL node's named word."""
    if x[0] != 'num' or other[0] != 'path' or len(other[2]) < 2 or \
            other[2][-2] != 'il' or other[2][-1] not in NAMED_WORDS:
        return x
    what = NAMED_WORDS[other[2][-1]]
    for n, (w, v) in il_names().items():
        if w == what and v == x[1]:
            return ('cname', n, v)
    return x


# --------------------------------------------------------------------------
# Pascal

class Emitter:
    """One action's body as Pascal (Domain Pascal for dpc), with the
    insert's field names and the casts the types need."""

    def __init__(self, rule, headings, line_of=None):
        self.rule = rule
        self.h = headings
        self.temps = {}
        attrs()

    # ---- paths
    def path(self, e):
        """(Pascal text, class, kind) of a path; kind 'rec' for a record
        variable (self, result), else a value."""
        base, sels = e[1], list(e[2])
        if isinstance(base, tuple):
            text, cls = self.expr1(base)
        elif base in ('self', 'result'):
            text, cls = base, 'rec'
        elif base in ('subject', 'solution'):
            text, cls = base, 'isp'
        elif base in self.temps:
            text, cls = base, self.temps[base]
        elif base.lower() in GLOBALS:
            text, cls = base.lower(), GLOBALS[base.lower()]
        else:
            raise LangError('rule %d: unknown name %s' % (self.rule, base))
        for s in sels:
            text, cls = self.select(text, cls, s)
        return text, cls

    def deref(self, text, cls):
        if cls == 'rec':
            return text
        if cls == 'isp':
            return text + '^'
        if cls in ('sp', 'up', 'lr'):
            return 'isc_solution_ptr_t(%s)^' % text
        raise LangError('rule %d: %s is not a solution' % (self.rule, text))

    def select(self, text, cls, s):
        if cls == 'other:at_switches_t':
            return '%s.%s' % (text, s), 'bool'
        if cls == 'node':
            # an IL node's field by offset (no names: the node's kind is
            # not known here): the module's view p2_node_t
            m = re.match(r'([bwl])(\d+)$', s)
            if not m:
                raise LangError('rule %d: node field %s' % (self.rule, s))
            off = int(m.group(2))
            v = 'p2_node_ptr_t(%s)^.' % text
            if m.group(1) == 'b':
                return v + 'b[%d]' % off, 'u8'
            if m.group(1) == 'w':
                return v + 'w[%d]' % (off // 2), 'i16'
            return v + 'p[%d]' % (off // 4), 'node'
        if cls == 'inh':
            if s not in INH_ATTRS:
                raise LangError('rule %d: no inherited attribute %s' % (self.rule, s))
            _, _, p, c = INH_ATTRS[s]
            return '%s^.%s' % (text, p), c
        r = self.deref(text, cls)
        if s.startswith('$'):
            return '%s.children[%s]' % (r, s[1:]), 'isp'
        m = re.match(r'([cwls])(\d+)$', s)
        if m and not s in ATTRS:
            kind, off = m.group(1), int(m.group(2))
            if kind == 'c' and 136 <= off < 342:
                # the rules' byte locals: the insert's case_value
                return '%s.case_value[%d]' % (r, off), 'u8'
            if kind == 'c' and 342 <= off <= 348:
                # the chain rules' cycle guard (docs/questions.md 313)
                return '%s.%s' % (r, ALREADY[off - 342]), 'bool'
            if kind == 'l' and off >= 352 and off % 4 == 0:
                return '%s.fields[%d]' % (r, (off - 352) // 4), 'isp'
            if kind == 's' and (off, 4) in SOL_FIELDS:
                p, c = SOL_FIELDS[(off, 4)]
                return '%s.%s' % (r, p), c
            if 136 <= off < 432 and kind in 'cwl':
                v = 'p2_locals_ptr_t(addr(%s))^.' % r
                if kind == 'c':
                    return v + 'c[%d]' % off, 'u8'
                if kind == 'w':
                    return v + 'w[%d]' % (off // 2), 'i16'
                if off % 4 == 0:
                    return v + 'p[%d]' % (off // 4), 'isp'
                return v + 'p2[%d]' % ((off - 2) // 4), 'isp'
            raise LangError('rule %d: field %s' % (self.rule, s))
        if s not in ATTRS:
            raise LangError('rule %d: no attribute %s' % (self.rule, s))
        off, size, bit = ATTRS[s]
        if bit is not None:
            if (off, bit) in SOL_BITS:
                return '%s.%s' % (r, SOL_BITS[(off, bit)]), 'bool'
            raise LangError('rule %d: bit %s' % (self.rule, s))
        p, c = SOL_FIELDS[(off, size)]
        if s in ('il', 'object_with_name'):
            c = 'node'
        return '%s.%s' % (r, p), c

    # ---- expressions
    def expr(self, e, want=None):
        text, cls = self.expr1(e)
        return self.coerce(text, cls, want) if want else text

    def coerce(self, text, cls, want):
        if want is None or cls == want:
            return text
        if cls == 'rec':
            return text
        if cls == 'node' and want == 'up' or want == 'node' and cls == 'up':
            return text
        if want in ENUMS and cls == 'num' and re.match(r'\d+$', text):
            return enum_name(want, int(text))
        if cls in ENUMS and want in ('i16', 'u8', 'u16', 'i32'):
            return 'ord(%s)' % text
        if want in POINTERS:
            if cls == 'num' and text == '0':
                return 'nil'
            if cls in ('i32', 'i16'):
                return '%s(%s)' % (PASCAL_TYPE[want], text)
            if cls in ('up', 'nil', 'str') or want == 'up':
                return text
            if cls in POINTERS:
                return '%s(%s)' % (PASCAL_TYPE[want], text)
            return text
        if want == 'i32' and cls in POINTERS:
            return 'integer32(%s)' % text
        if want in ('i16', 'u8', 'u16', 'i32') and cls == 'char':
            return 'ord(%s)' % text
        if want == 'char' and cls in ('i16', 'u8', 'u16', 'i32', 'num'):
            return 'chr(%s)' % text
        if want.startswith('other:') and want.endswith('_ptr_t') and cls in POINTERS:
            return '%s(%s)' % (want[6:], text)
        if want.startswith('other:') and cls in ('i16', 'u8', 'u16', 'i32', 'num'):
            return '%s(%s)' % (want[6:], text)
        return text

    def expr1(self, e):
        k = e[0]
        if k == 'num':
            v = e[1]
            if v == -0x80000000:
                return '(-16#7FFFFFFF - 1)', 'num'
            if v >= 4096:
                return '16#%X' % v, 'num'
            if v <= -4096:
                return '-16#%X' % -v, 'num'
            return str(v), 'num'
        if k == 'nil':
            return 'nil', 'nil'
        if k == 'bool':
            return ('true' if e[1] else 'false'), 'bool'
        if k == 'str':
            return "'" + e[1].replace("'", "''") + "'", 'str'
        if k == 'real':
            return repr(float(e[1])), 'real'
        if k == 'opc':
            return 'ord(%s)' % e[1], 'num'
        if k == 'ilk':
            return e[1], 'ilk'
        if k == 'cname':
            # a register class is an integer constant; an operator is
            # compared with the node's word as a number
            if il_names()[e[1]][0] in ('rlen', 'math'):
                return e[1], 'num'
            return 'ord(%s)' % e[1], 'num'
        if k == 'path':
            t, c = self.path(e)
            return t, c
        if k == 'addr':
            t, c = self.path(e[1])
            return 'addr(%s)' % t, 'up'
        if k == 'index':
            if e[1] in ('isc_literal_solutions', 'lir_3c60', 'lir_3d60', 'lir_3e60'):
                return '%s[%s]' % (e[1], self.expr(e[2])), 'sp'
            if e[1] == 'lir_3f90':
                return 'lir_3f90[%s]' % self.expr(e[2]), 'lr'
            m = re.match(r'readonly_w(\d+)$', e[1])
            if m:
                # a word table of isc_readonly_tables at +N (isc_types.ins.pas
                # names none there): the module's view by word
                return 'p2_readonly_ptr_t(addr(isc_readonly_tables))^.w[%d + %s]' % (
                    int(m.group(1)) // 2, self.paren(e[2], 4)), 'i16'
            if e[1].startswith('opcode_'):
                return 'isc_tool_generated_readonly_tables.%s[%s]' % (
                    e[1], self.expr(e[2], IL_T)), 'i16'
            raise LangError('rule %d: no table %s' % (self.rule, e[1]))
        if k == 'call' and e[1] in BUILTINS:
            return '%s(%s)' % (e[1], ', '.join(self.expr(a, 'i32') for a in e[2])), BUILTINS[e[1]]
        if k == 'call':
            h = self.h.get(e[1])
            if not h or h['ret'] is None:
                raise LangError('rule %d: no function %s' % (self.rule, e[1]))
            return self.call_text(e[1], e[2]), h['ret']
        if k == 'un':
            if e[1] == 'not':
                return 'not ' + self.paren(e[2], 6), 'bool'
            t, c = self.expr1(e[2])
            return '-' + self.paren(e[2], 6), c if c != 'num' else 'num'
        if k == 'bin':
            op = e[1]
            p = PREC[op]
            if p == 3:
                # an operand modifier's register class or math function
                # by name (opmod_operand)
                a, b = opmod_operand(self.rule, e[2], e[3]), opmod_operand(self.rule, e[3], e[2])
                if a is not e[2] or b is not e[3]:
                    e = ('bin', op, a, b)
            if op in ('and', 'or'):
                return '%s %s %s' % (self.paren(e[2], p), op, self.paren(e[3], p + 1)), 'bool'
            lt, lc = self.expr1(e[2])
            rt, rc = self.expr1(e[3])
            numeric = ('num', 'i16', 'u16', 'u8', 'i32')
            # a pointer field in arithmetic or compared with a number
            if lc in POINTERS and (rc in numeric or p > 3):
                lt, lc = 'integer32(%s)' % lt, 'i32'
            if rc in POINTERS and (lc in numeric or p > 3):
                rt, rc = 'integer32(%s)' % rt, 'i32'
            if lc == 'char' and rc in numeric:
                lt, lc = 'ord(%s)' % lt, 'i16'
            if rc == 'char' and lc in numeric:
                rt, rc = 'ord(%s)' % rt, 'i16'
            # an enumerated field compared with a number: the element
            if lc in ENUMS and rc == 'num' and re.match(r'\d+$', rt):
                rt, rc = enum_name(lc, int(rt)), lc
            if rc in ENUMS and lc == 'num' and re.match(r'\d+$', lt):
                lt, lc = enum_name(rc, int(lt)), rc
            if lc in POINTERS and rc in POINTERS and lc != rc and 'up' not in (lc, rc):
                rt = '%s(%s)' % (PASCAL_TYPE[lc], rt)
            lt = self.wrap(e[2], lt, p)
            rt = self.wrap(e[3], rt, p + 1)
            pop = op[1:] if op.startswith('u') else op
            cls = 'bool' if p == 3 else (lc if lc != 'num' else rc)
            return '%s %s %s' % (lt, pop, rt), cls
        raise LangError('rule %d: expression %r' % (self.rule, e))

    def wrap(self, e, text, prec):
        if e[0] == 'bin' and PREC[e[1]] < prec or (e[0] == 'bin' and PREC[e[1]] == 3
                                                    and prec >= 3):
            return '(%s)' % text
        return text

    def paren(self, e, prec):
        t, _ = self.expr1(e)
        return self.wrap(e, t, prec) if e[0] == 'bin' else (
            '(%s)' % t if e[0] == 'un' and prec > 5 else t)

    def call_text(self, name, args):
        h = self.h.get(name)
        if h is None:
            raise LangError('rule %d: no heading for %s' % (self.rule, name))
        ps = h['params']
        if len(args) != len(ps) and not h['variable']:
            raise LangError('rule %d: %s takes %d arguments, %d given'
                            % (self.rule, name, len(ps), len(args)))
        out = []
        for k, a in enumerate(args):
            want = ps[k][2] if k < len(ps) else None
            if want and (ps[k][3] or (want.startswith('other:') and a[0] == 'str')):
                want = None
            out.append(self.expr(a, want))
        return '%s(%s)' % (name, ', '.join(out)) if args else name

    # ---- statements
    def stmts(self, ss, ind):
        out = []
        for s in ss:
            out.extend(self.stmt(s, ind))
        return out

    def stmt(self, s, ind):
        k = s[0]
        if k == 'temp':
            return []
        if k == 'set':
            lt, lc = self.path(s[1])
            return self.lines(ind, '%s := %s;' % (lt, self.expr(s[2], lc)))
        if k == 'let':
            t = self.expr(s[1], 'lr')
            msg = ("ISC: A ''let result <- ...;'' in pattern %d (line number %d) used a nil "
                   "live_range.%%$" % (self.rule, s[2]))
            return (self.lines(ind, 'solution^.live_range := %s;' % t)
                    + [ind + 'if solution^.live_range = nil then',
                       ind + '  if not at_backend_switches.sw11 then',
                       ind + "    bug_check('%s');" % msg])
        if k == 'emit':
            name = 'debug_lir_$label' if s[1] == 'label' else 'debug_lir_$%s_instruction' % s[1]
            args = [('path', 'result', ['inherited_attributes'])] + list(s[2])
            return self.lines(ind, self.call_text(name, args) + ';')
        if k == 'call':
            return self.lines(ind, self.call_text(s[1], s[2]) + ';')
        if k == 'if':
            out = []
            for j, (c, body) in enumerate(s[1]):
                out.append(ind + ('if ' if j == 0 else 'else if ') + self.expr(c) + ' then begin')
                out.extend(self.stmts(body, ind + '  '))
                out.append(ind + 'end')
            if s[2] is not None:
                out[-1] += ' else begin'
                out.extend(self.stmts(s[2], ind + '  '))
                out.append(ind + 'end')
            out[-1] += ';'
            return out
        if k == 'for':
            out = [ind + 'for %s := %s to %s do begin' % (s[1], self.expr(s[2], 'i32'),
                                                          self.expr(s[3], 'i32'))]
            out.extend(self.stmts(s[4], ind + '  '))
            out.append(ind + 'end;')
            return out
        raise LangError('rule %d: statement %r' % (self.rule, s))

    def lines(self, ind, text):
        if len(ind) + len(text) <= 78:
            return [ind + text]
        # break after commas
        out, cur = [], ind
        for part in re.split(r'(?<=,) ', text):
            if len(cur) + len(part) + 1 > 78 and cur.strip():
                out.append(cur.rstrip())
                cur = ind + '    '
            cur += part + ' '
        out.append(cur.rstrip())
        return out

    def routine(self, stmts):
        """The body's declarations and statements."""
        decl = []
        for s in walk(stmts):
            if s[0] == 'temp':
                if s[2] not in TEMP_TYPES:
                    raise LangError('rule %d: temp type %s' % (self.rule, s[2]))
                self.temps[s[1]] = TEMP_TYPES[s[2]]
                decl.append('  %s: %s;' % (s[1], PASCAL_TYPE[TEMP_TYPES[s[2]]]))
            elif s[0] == 'for' and s[1] not in self.temps:
                self.temps[s[1]] = 'i32'
                decl.append('  %s: integer32;' % s[1])
        body = self.stmts(stmts, '  ')
        return (['var'] + decl if decl else []), body


def walk(stmts):
    for s in stmts:
        yield s
        if s[0] == 'if':
            for _, b in s[1]:
                yield from walk(b)
            if s[2]:
                yield from walk(s[2])
        elif s[0] == 'for':
            yield from walk(s[4])
