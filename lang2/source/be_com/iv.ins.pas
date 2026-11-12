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

{ IV_UTILS_$LIVE_RANGE_FROM_ELABORATED_EXPRESSION - 0x23B8EE, 0x2C0 bytes;
  called from oli.  Frame 8:a; 12:al; 16:a; 20:a; 24:a; 28:a. }
procedure iv_utils_$live_range_from_elaborated_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr); options(val_param); extern;

{ IV_UTILS_$COMPARE_ADDRESS_EXPRESSIONS - 0x23D5A0, 0x6C bytes; called
  from oli.  Frame 8:al; 12:al.  Result: D0 (callers: D0b2). }
function iv_utils_$compare_address_expressions(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;
