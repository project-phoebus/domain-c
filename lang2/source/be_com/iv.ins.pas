{ lang2/source/be_com/iv.ins.pas - be_com iv.pas's insert (cc.a88k only):
  opened by iv and oli, after the opcode enumeration (oli before
  utils.ins.pas, iv before opcodes/instr_size.init and utils.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  It holds the expressions iv builds (and oli through
  iv_utils_) and the headings of iv.pas's global routines that oli
  calls, read off the frames and narrowed from iv.pas's bodies
  (translator PC4).

  Not known from the original: every type, field, constant and
  parameter name. }

{ batch C (iv, oli): }
const
  { An expression's kinds (iv_expr_t.kind); iv's tables by kind give
    the children (+0x6C0), the instructions that compute one in an
    integer (+0x688) or a floating register (+0x6A2), the operand each
    child becomes (+0x650) and the commuted kind (+0x630). }
  iv_value = 1;                         { a constant }
  iv_lts = 2;                           { a lifetime segment's value }
  iv_operand = 3;                       { an operand (a like register, a
                                          displacement, ...) }
  iv_neg = 4;
  iv_add = 5;
  iv_sub = 6;
  iv_mul = 7;
  iv_rsub = 8;
  iv_transfer = 9;                      { between the register files }
  iv_move = 10;
  iv_load = 11;                         { a constant loaded (not
                                          encodable as an immediate) }
  iv_shift = 12;                        { a multiply by a power of 2 }

type
  { An expression (24 bytes from iv's expression heap): kind (+8); a
    constant's value, a segment, an operand copied whole, or the
    children (+12, +16); canonical (+6) once canonicalized (the leaves
    are made so); rclass (+4) the register file it is computed in, 1
    integer or 2 floating (0 not chosen yet; elaborate_expression and
    propagate_down_type choose); +0 and +10 not seen used yet. }
  iv_expr_ptr_t = ^iv_expr_t;
  iv_expr_t = record
    l0: integer32;                      { +0 }
    rclass: integer;                    { +4 }
    canonical: boolean;                 { +6 }
    b7: boolean;                        { +7 }
    kind: integer;                      { +8 }
    w10: integer;                       { +10 }
    case integer of                     { +12 }
      1: (value: integer32);
      2: (lts: lts_ptr_t);
      3: (opnd: opnd_t);
      4: (left: iv_expr_ptr_t;
          right: iv_expr_ptr_t);
      5: (child: array [1..2] of iv_expr_ptr_t);
  end;

  { The induction records (translator PC5), from iv's five other heaps;
    each kind's records given back go on a free list chained through
    the field noted. }
  iv_lts_ptr_t = ^iv_lts_t;
  iv_addr_ptr_t = ^iv_addr_t;
  iv_iexpr_ptr_t = ^iv_iexpr_t;
  iv_class_ptr_t = ^iv_class_t;
  iv_var_ptr_t = ^iv_var_t;

  { An induction lts (36 bytes): what iv knows of a lifetime segment,
    whose +24 (lts_t.l24) points back to it.  kind (+0): 1 a candidate
    (create_induction_lts' default), 2 confirmed as its variable's
    (ivr_$mark_lifetime_segments_as_induction_variables), 3 (made by
    create_induction_lts of a kind 2 for a variable with a parent), 4 an
    induction expression's instantiation; known (+1 bit 6) incr is
    known; first_in_bb (+1 bit 2) the first of its variable's list in
    its block; ivar (+12) its variable, on whose list (+16) a kind 1..3
    is chained at next (+16, also the free list's link); incr (+20) the
    increment from the variable's start, step (+24) the increment the
    instruction defining it adds (kinds 1..3); a kind 4's induction
    expression at +20. }
  iv_lts_t = record
    h: packed record                    { +0 }
      kind: 0..255;
      b1_7: boolean;                    { +1 }
      known: boolean;                   { .6 }
      b1_5, b1_4, b1_3: boolean;
      first_in_bb: boolean;             { .2 }
      b1_1, b1_0: boolean;
      w2: 0..65535;                     { +2 }
      end;
    lts: lts_ptr_t;                     { +4 }
    l8: integer32;                      { +8 }
    ivar: iv_var_ptr_t;                 { +12 }
    next: iv_lts_ptr_t;                 { +16 }
    case integer of                     { +20 }
      1: (incr: iv_expr_ptr_t;
          step: iv_expr_ptr_t;          { +24 }
          l28: integer32;               { +28 }
          l32: integer32);              { +32 }
      2: (iexpr: iv_iexpr_ptr_t);
  end;

  { An induction address mode (28 bytes): an operand (+20) of an
    instruction (+12) addressed by an induction expression (+0), on whose
    list (+16) it is chained (and on the free list). }
  iv_addr_t = record
    iexpr: iv_iexpr_ptr_t;              { +0 }
    l4: integer32;                      { +4 }
    l8: integer32;                      { +8 }
    instr: instr_ptr_t;                 { +12 }
    next: iv_addr_ptr_t;                { +16 }
    opnd: opnd_ptr_t;                   { +20 }
    l24: integer32;                     { +24 }
  end;

  { An induction expression (22 bytes): an expression (+4) of its class's
    variable, on its class's list (+8, newest first; also the free
    list's link) and numbered (+20) one more than the one it was put in
    front of; its instantiations (induction lts of kind 4, +12) and
    address modes (+16). }
  iv_iexpr_t = record
    class: iv_class_ptr_t;              { +0 }
    expr: iv_expr_ptr_t;                { +4 }
    next: iv_iexpr_ptr_t;               { +8 }
    ltss: iv_lts_ptr_t;                 { +12 }
    addrs: iv_addr_ptr_t;               { +16 }
    num: integer;                       { +20 }
  end;

  { An induction class (20 bytes): on its variable's list (+20/+24)
    doubly chained (+8 next, also the free list's link; +12 prev) and
    numbered (+18); w16 what create_induction_class is given. }
  iv_class_t = record
    ivar: iv_var_ptr_t;                 { +0 }
    iexprs: iv_iexpr_ptr_t;             { +4 }
    next: iv_class_ptr_t;               { +8 }
    prev: iv_class_ptr_t;               { +12 }
    w16: integer;                       { +16 }
    num: integer;                       { +18 }
  end;

  { An induction variable (62 bytes): the segment it is (+0, a loop
    head's exposed segment), the loop (+4, the interval head), its
    increment (+8, once every confirmed segment's is known and equal)
    and initial value (+12, the one input from outside the loop); its
    induction lts (+16) and classes (+20, +24 the last); a secondary
    variable's parent (+28), on whose children list (+54 head, +58
    last) it is doubly chained (+50 next, +54 its previous); a primary
    is on iv's list of variables (iv_vars, chained at +50, also the
    free list's link).  w44 counts its add and sub definitions; kind
    (+48 bits 7..3) the operand kind of its definition; verified (bit
    2), known (bit 1: incr is known), final (bit 0: kept by
    ivr_$finalize_induction_variables, mult (+32) then 1). }
  iv_var_t = record
    lts: lts_ptr_t;                     { +0 }
    head: bb_ptr_t;                     { +4 }
    incr: iv_expr_ptr_t;                { +8 }
    init: iv_expr_ptr_t;                { +12 }
    ltss: iv_lts_ptr_t;                 { +16 }
    classes: iv_class_ptr_t;            { +20 }
    classes_last: iv_class_ptr_t;       { +24 }
    parent: iv_var_ptr_t;               { +28 }
    mult: iv_expr_ptr_t;                { +32 }
    l36: integer32;                     { +36 }
    l40: integer32;                     { +40 }
    w44: integer;                       { +44 }
    w46: integer;                       { +46 }
    f48: packed record                  { +48 }
      kind: 0..31;                      { .7..3 }
      verified: boolean;                { .2 }
      known: boolean;                   { .1 }
      final: boolean;                   { .0 }
      b49: 0..255;                      { +49 }
      end;
    next: iv_var_ptr_t;                 { +50 }
    l54: iv_var_ptr_t;                  { +54: a primary's first child,
                                          a secondary's previous sibling }
    children_last: iv_var_ptr_t;        { +58 }
  end;
{ end batch C }

{ iv.pas (cc.a88k). }

{ IV_UTILS_$DELETE_EXPRESSION - e and its children given back, e nil.
  0x239110, 0x5C bytes; called from oli.  Frame 8:a. }
procedure iv_utils_$delete_expression(
    var e: iv_expr_ptr_t); extern;

{ IV_UTILS_$CREATE_ADD_EXPRESSION - 0x239508, 0x3A bytes; called from oli.
  Frame 8:al; 12:al.  A0.  (The third longword the callers push is
  another call's argument.) }
function iv_utils_$create_add_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_SUB_EXPRESSION - 0x239542, 0x3A bytes; called from oli.
  Frame 8:al; 12:al.  A0. }
function iv_utils_$create_sub_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_MUL_EXPRESSION - 0x23957C, 0x3A bytes; called from oli.
  Frame 8:al; 12:al.  A0. }
function iv_utils_$create_mul_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_VALUE_EXPRESSION - 0x2395E2, 0x30 bytes; called from
  oli.  Frame 8:l.  A0. }
function iv_utils_$create_value_expression(
    v: integer32): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_OPERAND_EXPRESSION - an operand expression of a copy
  of o.  0x239642, 0x3E bytes; called from oli.  Frame 8:a.  A0. }
function iv_utils_$create_operand_expression(
    in o: opnd_t): iv_expr_ptr_t; extern;

{ IV_UTILS_$CANONICALIZE_EXPRESSION - 0x2396DA, 0x74 bytes; called from
  oli.  Frame 8:al.  Result: A0 (callers: A056). }
function iv_utils_$canonicalize_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$DUPLICATE_EXPRESSION - a copy of e.  0x23A73C, 0xC0 bytes;
  called from oli.  Frame 8:al (the body reads one argument; the
  further longwords the frames showed were other calls').  A0. }
function iv_utils_$duplicate_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$ELABORATE_EXPRESSION - e given register files (rclass) and
  made encodable as the operand pos of an opc instruction.  0x23B07E,
  0xA6 bytes; called from oli.  Frame 8:al; 12:w; 14:w; 16:w.  A0. }
function iv_utils_$elaborate_expression(
    e: iv_expr_ptr_t;
    rclass: integer;
    opc: integer;
    pos: integer): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_OPERAND_FROM_EXPRESSION - operand o made the value of
  e in register file rclass, the instructions after at in code_bb.
  0x23B876, 0x78 bytes; called in iv (declared before its body: the
  image's .blocks list puts it with the routines declared first).
  Frame 8:a; 12:l; 16:l; 20:l; 24:w. }
procedure iv_utils_$create_operand_from_expression(
    o: opnd_ptr_t;
    at: instr_ptr_t;
    code_bb: bb_ptr_t;
    e: iv_expr_ptr_t;
    rclass: integer); options(val_param); extern;

{ IV_UTILS_$CREATE_EXPRESSION_FROM_LTS - the expression segment s holds,
  seen from the loop headed by head.  0x23C44A, 0x278 bytes; called in
  iv (declared first, as above).  Frame 8:a; 12:l.  A0. }
function iv_utils_$create_expression_from_lts(
    s: lts_ptr_t;
    head: bb_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$CREATE_EXPRESSION_FROM_OPERAND - operand o's expression, seen
  from the loop headed by head.  0x23C702, 0xA8 bytes; called in iv.
  Frame 8:a; 12:l.  A0. }
function iv_utils_$create_expression_from_operand(
    o: opnd_ptr_t;
    head: bb_ptr_t): iv_expr_ptr_t; options(val_param); extern;

{ IV_UTILS_$LIVE_RANGE_FROM_ELABORATED_EXPRESSION - what an elaborated
  expression e is as an operand: kind 1 a live range lr (an operation's
  instructions made at the head of bb, their operands' +8 the live
  ranges), 2 an operand op (in e), 3 a constant value.  0x23B8EE, 0x2C0
  bytes; called from oli.  Frame 8:a; 12:a; 16:a; 20:a; 24:a; 28:a (all
  by address: oli passes its locals and a module cell for bb). }
procedure iv_utils_$live_range_from_elaborated_expression(
    var e: iv_expr_ptr_t;
    var bb: bb_ptr_t;
    out lr: lr_ptr_t;
    out value: integer32;
    out op: opnd_ptr_t;
    out kind: integer); extern;

{ IV_UTILS_$COMPARE_ADDRESS_EXPRESSIONS - 0x23D5A0, 0x6C bytes; called
  from oli.  Frame 8:al; 12:al.  Result: D0 (callers: D0b2). }
function iv_utils_$compare_address_expressions(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;
