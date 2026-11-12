{ iv - the PRISM back end's induction variable phase (IV): the loops'
  induction variables and the expressions of them found (ivr_, ixr_),
  strength reduced (ixt_), and the expression utilities (iv_utils_) oli
  shares.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x238DB0  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x238DD2  iv_$begin_compilation
    --------  0x238EE0  iv_$end_compilation
    --------  0x238EE2  iv_$end_routine
    --------  0x238F3C  zero (internal)
    --------  0x239040  alloc_expression (internal)
    --------  0x2390FC  free_expression (internal)
    --------  0x239110  iv_utils_$delete_expression
    --------  0x23916C  order_expressions (internal)
    --------  0x2392CE  get_canonical_compare_node (internal)
    --------  0x2393BC  get_canonical_base_node (internal)
    --------  0x2393F4  get_canonical_remaining_node (internal)
    --------  0x239414  has_canonical_form (internal)
    --------  0x23942A  canonical_base_node_is_positive (internal)
    --------  0x239438  build_multiplier_from_base (internal)
    --------  0x239508  iv_utils_$create_add_expression
    --------  0x239542  iv_utils_$create_sub_expression
    --------  0x23957C  iv_utils_$create_mul_expression
    --------  0x2395B6  iv_utils_$create_neg_expression
    --------  0x2395E2  iv_utils_$create_value_expression
    --------  0x239612  iv_utils_$create_lts_expression
    --------  0x239642  iv_utils_$create_operand_expression
    --------  0x239680  create_transfer_expression (internal)
    --------  0x2396A0  create_move_expression (internal)
    --------  0x2396C0  iv_utils_$expression_is_zero (internal)
    --------  0x2396DA  iv_utils_$canonicalize_expression
    --------  0x23974E  create_add_or_sub_expression (internal)
    --------  0x239776  same_base_operand (internal)
    --------  0x2397DC  operand_offset_difference (internal)
    --------  0x239828  clean_up_additive_canonical_result (internal)
    --------  0x239BA4  canonicalize_add_expression (internal)
    --------  0x239F5C  canonicalize_sub_expression (internal)
    --------  0x23A374  canonicalize_mul_expression (internal)
    --------  0x23A5DA  canonicalize_neg_expression (internal)
    --------  0x23A6FA  canonicalize_rsub_expression (internal)
    --------  0x23A73C  iv_utils_$duplicate_expression
    --------  0x23A830  iv_utils_$compare_expressions
    --------  0x23A956  propagate_up_cost (internal)
    --------  0x23AACC  can_encode_as_register (internal)
    --------  0x23AB0E  first_operand_can_change (internal)
    --------  0x23AB78  propagate_down_type (internal)
    --------  0x23AED4  elaborate_expression (internal)
    --------  0x23B07E  iv_utils_$elaborate_expression
    A5 0x486500: the module's data: instr_size (+0, instr_size.init),
    iv_opc_kind (+0x330: the expression kind of an opcode), iv_commuted
    (+0x630), iv_opnd_pos (+0x650), iv_opc (+0x688, two rows),
    iv_opc_set (+0x300), iv_nchildren (+0x6C0), the six heaps (+0x6E0 .. +0x758),
    the free lists (+0x778 .. +0x788, +0x7B0), iv_elab_class (+0x7C0).

  The expression utilities' callers in other units reach them through
  iv.ins.pas.  The global routines only iv calls are declared here
  (module-level: they load A5).

  Not known from the original: every local, parameter, cell and type
  name. }

{ TODO(pascal) iv: 43 of the image's 127 routines (the expressions, the
  heaps).  Remaining, in address order: alloc_induction_lts (0x238F62),
  alloc_induction_addr, alloc_induction_expr, alloc_induction_class,
  alloc_induction_variable, create_induction_addr (0x2390B0),
  find_last_instruction (0x23B124) .. iv_$process_routine (0x23FF80):
  the operands made from elaborated expressions, the induction
  records, the loop invariance tests, the candidates' propagation and
  verification (ivr_), the induction expressions' recognition (ixr_)
  and transformation (ixt_), the walks and process_routine.  The heaps'
  other records (induction lts 36 bytes, address mode 28, induction
  expression 22, class 20, variable 62; free lists chained at +16, +16,
  +8, +8, +50) are declared when those routines are written. }
module iv;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/iv.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_size.init';
%include 'lang2/source/be_com/utils.ins.pas';

type
  iv_cost_t = array [1..2] of integer;

  { iv's view of a block (fields batch A has not named; backend.ins.pas
    bb_t): an interval head's first member (+138) and the next member
    of the interval a block is in (+142; com's next142). }
  iv_bb_v_ptr_t = ^iv_bb_v_t;
  iv_bb_v_t = record
    space0: array [0..137] of char;
    first138: bb_ptr_t;                 { +138 }
    next142: bb_ptr_t;                  { +142 }
  end;

  { A join birthpoint's input, as utils.pas's ut_jbi_t: chained from
    the join instruction's operand 3 (+8) at next_op. }
  iv_jbi_ptr_t = ^iv_jbi_t;
  iv_jbi_t = record
    next: iv_jbi_ptr_t;                 { +0 }
    next_op: iv_jbi_ptr_t;              { +4 }
    lts: lts_ptr_t;                     { +8 }
  end;

  { A literal pool operand's constant (its link, an IL node made by
    smcontk): w4 its type (constants of types 0, 3, 4, 7 and 10 are
    taken), value (+8). }
  iv_node_v_ptr_t = ^iv_node_v_t;
  iv_node_v_t = record
    w0: integer;                        { +0 }
    w2: integer;                        { +2 }
    w4: integer;                        { +4 }
    w6: integer;                        { +6 }
    value: integer32;                   { +8 }
  end;

  { What apply_to_creating_induction_segments and
    iv_$walk_basic_blocks_in_order call (`jsr (A1)', addresses passed
    by `move.l #addr': pattern 104): given a segment's or a block's
    slot by address. }
  iv_lts_proc_t = ^procedure(
      var s: lts_ptr_t);
  iv_bb_proc_t = ^procedure(
      var bb: bb_ptr_t);

var
  { +0x300: the opcodes an expression is made from (those with a kind
    in iv_opc_kind): a set of 0..383, 48 bytes, tested `move.w #383;
    sub.w opc; lsr.w #3; btst opc,(A5+0x300,D0.w)'. }
  iv_opc_set: set of 0..383 := [75, 77, 79, 81, 83, 92, 105, 106, 116,
    126, 135, 137, 138, 144, 178];

  { +0x330: the expression kind an instruction of each opcode computes
    (0 none). }
  iv_opc_kind: array [0..211] of integer := [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 0 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 16 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 32 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 48 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 4, 0, 5,  { 64 }
    0, 6, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0,  { 80 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 11, 0, 0, 0, 0, 0,  { 96 }
    0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0,  { 112 }
    0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 0, 0, 0, 0, 0,  { 128 }
    10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 144 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 160 }
    0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 176 }
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  { 192 }
    0, 0, 0, 0];                        { 208 }

  { +0x630: the kind an expression of each kind becomes with its
    children exchanged (0 none). }
  iv_commuted: array [0..15] of integer := [
    0, 0, 0, 0, 0, 5, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  { +0x650: the instruction operand each child of an expression of each
    kind becomes. }
  iv_opnd_pos: array [0..13, 1..2] of integer := [
    [0, 0], [0, 0], [0, 0], [0, 0], [1, 0], [2, 1], [2, 1], [2, 1],
    [2, 1], [1, 0], [1, 0], [0, 0], [1, 2], [0, 0]];

  { +0x688: the opcode that computes an expression of each kind in an
    integer register (row 1: neg, add, sub, -, rsub, mffp, move, loadl,
    lsl) and in a floating one (row 2, +0x6A2: negi, addi, subi, muli,
    -, mtfp, copys, loads): one table by register file and kind, indexed
    A5 + 0x66E + 26 rclass + 2 kind (create_operand_from_elaborated_
    expression). }
  iv_opc: array [1..2, 0..12] of integer := [
    [0, 0, 0, 0, 77, 79, 81, 0, 83, 116, 75, 105, 92],
    [0, 0, 0, 0, 135, 137, 138, 178, 0, 126, 144, 106, 0]];

  { +0x6C0: the children of an expression of each kind. }
  iv_nchildren: array [0..12] of integer := [
    0, 0, 0, 0, 1, 2, 2, 2, 2, 1, 1, 0, 2];

  { +0x6E0 .. +0x758: the heaps, with their names. }
  iv_iexpr_heap: mrh_$heap_t;           { +0x6E0: induction expressions
                                          (22 bytes) }
  iv_addr_heap: mrh_$heap_t;            { +0x6F8: induction address
                                          modes (28) }
  iv_class_heap: mrh_$heap_t;           { +0x710: induction classes (20) }
  iv_lts_heap: mrh_$heap_t;             { +0x728: induction lts (36) }
  iv_var_heap: mrh_$heap_t;             { +0x740: induction variables
                                          (62) }
  iv_expr_heap: mrh_$heap_t;            { +0x758: expressions (24) }

  { +0x778 .. +0x788, +0x7B0: the records given back, for reuse. }
  iv_free_class: iv_class_ptr_t;        { +0x778 (chained at +8) }
  iv_free_iexpr: iv_iexpr_ptr_t;        { +0x77C (+8) }
  iv_free_addr: iv_addr_ptr_t;          { +0x780 (+16) }
  iv_free_lts: iv_lts_ptr_t;            { +0x784 (+16) }
  iv_free_var: iv_var_ptr_t;            { +0x788 (+50) }
  iv_free_expr: iv_expr_ptr_t;          { +0x7B0 (+12) }

  { +0x798 .. +0x7AC: the routine's state. }
  iv_vars_last: iv_var_ptr_t;           { +0x798: the last on iv_vars }
  iv_vars: iv_var_ptr_t;                { +0x79C: the primary induction
                                          variables, chained at +50 }
  iv_head: bb_ptr_t;                    { +0x7A0: the loop (interval head)
                                          being worked on }
  iv_rtn: rtn_ptr_t;                    { +0x7AC: the routine }

  { +0x7C0: how elaborate_expression picks the register file of an
    expression's children by its kind: 1 its own (none), 2 the segment's
    definition's kind, 3 integer, 4 floating. }
  iv_elab_class: array [0..12] of integer := [
    0, 1, 2, 3, 1, 1, 1, 4, 3, 1, 1, 1, 3];

{ iv_$begin_compilation - the heaps made.  0x238DD2, 0xA0 bytes: each
  heap's flags and size pushed as one longword (pattern 105). }

procedure iv_$begin_compilation;
begin
  mrh_$initialize(iv_expr_heap, 1, 24, 'expression%');
  mrh_$initialize(iv_var_heap, 1, 62, 'induction variable%');
  mrh_$initialize(iv_class_heap, 1, 20, 'induction class%');
  mrh_$initialize(iv_addr_heap, 1, 28, 'induction address mode%');
  mrh_$initialize(iv_iexpr_heap, 1, 22, 'induction expression%');
  mrh_$initialize(iv_lts_heap, 1, 36, 'induction lts%');
end;

{ iv_$end_compilation - nothing.  0x238EE0, 2 bytes. }

procedure iv_$end_compilation;
begin
end;

{ iv_$end_routine - the heaps released (the free lists are not
  cleared).  0x238EE2, 0x5A bytes. }

procedure iv_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(iv_expr_heap);
  mrh_$release_all(iv_var_heap);
  mrh_$release_all(iv_class_heap);
  mrh_$release_all(iv_iexpr_heap);
  mrh_$release_all(iv_addr_heap);
  mrh_$release_all(iv_lts_heap);
end;

{ zero - n bytes from p cleared, one by one.  0x238F3C, 0x26 bytes, no
  frame (unlike at_backend's and zzzzz's longword helpers, pattern
  100). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  bytes_t = packed array [1..65536] of char;
var
  b: ^bytes_t;
  k: integer32;
begin
  b := p;
  for k := 1 to n do
    b^[k] := chr(0);
end;

{ alloc_induction_lts - an induction lts, reused from the free list
  (cleared) or new.  0x238F62, 0x36 bytes, no A5: A0.  The other
  allocators are alike (pattern 98's per-unit helpers' shape). }

function alloc_induction_lts: iv_lts_ptr_t; internal;
var
  l: iv_lts_ptr_t;
begin
  if iv_free_lts = nil then
    l := mrh_$alloc_fixed(iv_lts_heap)
  else begin
    l := iv_free_lts;
    iv_free_lts := l^.next;
    zero(l, 36);
  end;
  alloc_induction_lts := l;
end;

{ alloc_induction_addr - an induction address mode.  0x238F98, 0x38
  bytes. }

function alloc_induction_addr: iv_addr_ptr_t; internal;
var
  a: iv_addr_ptr_t;
begin
  if iv_free_addr = nil then
    a := mrh_$alloc_fixed(iv_addr_heap)
  else begin
    a := iv_free_addr;
    iv_free_addr := a^.next;
    zero(a, 28);
  end;
  alloc_induction_addr := a;
end;

{ alloc_induction_expr - an induction expression.  0x238FD0, 0x38
  bytes. }

function alloc_induction_expr: iv_iexpr_ptr_t; internal;
var
  x: iv_iexpr_ptr_t;
begin
  if iv_free_iexpr = nil then
    x := mrh_$alloc_fixed(iv_iexpr_heap)
  else begin
    x := iv_free_iexpr;
    iv_free_iexpr := x^.next;
    zero(x, 22);
  end;
  alloc_induction_expr := x;
end;

{ alloc_induction_class - an induction class.  0x239008, 0x38 bytes. }

function alloc_induction_class: iv_class_ptr_t; internal;
var
  c: iv_class_ptr_t;
begin
  if iv_free_class = nil then
    c := mrh_$alloc_fixed(iv_class_heap)
  else begin
    c := iv_free_class;
    iv_free_class := c^.next;
    zero(c, 20);
  end;
  alloc_induction_class := c;
end;

{ alloc_expression - an expression, reused from the free list (cleared)
  or new.  0x239040, 0x38 bytes, no A5: A0. }

function alloc_expression: iv_expr_ptr_t; internal;
var
  e: iv_expr_ptr_t;
begin
  if iv_free_expr = nil then
    e := mrh_$alloc_fixed(iv_expr_heap)
  else begin
    e := iv_free_expr;
    iv_free_expr := e^.left;
    zero(e, 24);
  end;
  alloc_expression := e;
end;

{ alloc_induction_variable - an induction variable.  0x239078, 0x38
  bytes. }

function alloc_induction_variable: iv_var_ptr_t; internal;
var
  v: iv_var_ptr_t;
begin
  if iv_free_var = nil then
    v := mrh_$alloc_fixed(iv_var_heap)
  else begin
    v := iv_free_var;
    iv_free_var := v^.next;
    zero(v, 62);
  end;
  alloc_induction_variable := v;
end;

{ create_induction_addr - an address mode of operand o (of its
  instruction) by induction expression x, put first on x's list; l4
  and l24 as given.  0x2390B0, 0x4C bytes, no A5. }

function create_induction_addr(
    x: iv_iexpr_ptr_t;
    l4: integer32;
    o: opnd_ptr_t;
    l24: integer32): iv_addr_ptr_t; options(val_param); internal;
var
  a: iv_addr_ptr_t;
begin
  a := alloc_induction_addr;
  a^.iexpr := x;
  a^.l4 := l4;
  a^.opnd := o;
  a^.l24 := l24;
  a^.instr := utils_ins_$operands_instruction(o);
  a^.next := x^.addrs;
  x^.addrs := a;
  create_induction_addr := a;
end;

{ free_expression - e put on the free list (not its children), e nil.
  0x2390FC, 0x14 bytes, no frame. }

procedure free_expression(
    var e: iv_expr_ptr_t); internal;
begin
  e^.left := iv_free_expr;
  iv_free_expr := e;
  e := nil;
end;

{ iv_utils_$delete_expression - e and its children (by the kind's
  count) given back.  0x239110, 0x5C bytes: recursive. }

procedure iv_utils_$delete_expression(
    var e: iv_expr_ptr_t);
var
  k: integer32;
begin
  if e <> nil then begin
    for k := 1 to iv_nchildren[e^.kind] do
      iv_utils_$delete_expression(e^.child[k]);
    free_expression(e);
  end;
end;

{ order_expressions - the order of two canonical compare nodes: by
  kind; constants equal; operands by kind, displacements by their node
  and value, like registers by their live range's number (1 for
  others); segments by block order, then by the operand within one
  instruction, else 1 when a's definition comes first in a's block, -1
  when b's does.  0x23916C, 0x162 bytes, no A5: the orders and numbers
  compared unsigned. }

function order_expressions(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): integer32; options(val_param); internal;
var
  d: integer32;
  ia, ib, i: instr_ptr_t;
begin
  d := a^.kind - b^.kind;
  if d = 0 then
    if a^.kind <> iv_value then
      if a^.kind = iv_operand then begin
        d := ord(a^.opnd.h.kind) - ord(b^.opnd.h.kind);
        if d = 0 then
          case a^.opnd.h.kind of
            operand$displacement_arg_block, operand$displacement_stack_frame,
            operand$displacement_literal_pool: begin
              d := integer32(a^.opnd.link) - integer32(b^.opnd.link);
              if d = 0 then
                d := a^.opnd.value - b^.opnd.value;
            end;
            operand$ip_reg_like, operand$fp_reg_like,
            operand$fp_reg_pair_like:
              d := a^.opnd.lts^.lr^.num - b^.opnd.lts^.lr^.num;
            otherwise
              d := 1;
          end;
      end
      else if a^.kind = iv_lts then begin
        if a^.lts = b^.lts then
          d := 0
        else begin
          d := a^.lts^.bb^.order - b^.lts^.bb^.order;
          if d = 0 then begin
            ia := utils_ins_$operands_instruction(a^.lts^.refs);
            ib := utils_ins_$operands_instruction(b^.lts^.refs);
            if ia = ib then
              d := a^.lts^.refs^.h.num - b^.lts^.refs^.h.num
            else begin
              i := a^.lts^.bb^.first;
              while i <> nil do begin
                if i = ia then begin
                  d := 1;
                  exit;
                end;
                if i = ib then begin
                  d := -1;
                  exit;
                end;
                i := i^.next;
              end;
            end;
          end;
        end;
      end
      else
        d := 1;
  order_expressions := d;
end;

{ get_canonical_compare_node - what orders a canonical expression: a
  leaf itself; for a sum or difference its base (the right child); for
  a negation its operand or segment, or the segment a multiple of it
  multiplies; for a multiple the segment it multiplies; nil for
  anything else.  0x2392CE, 0xEE bytes, no A5: jump tables by kind. }

function get_canonical_compare_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r, x, y: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    case e^.kind of
      iv_value, iv_lts, iv_operand:
        r := e;
      iv_add, iv_sub: begin
        x := e^.right;
        case x^.kind of
          iv_value, iv_lts, iv_operand:
            r := x;
          iv_neg: begin
            y := x^.left;
            if (y^.kind = iv_lts) or (y^.kind = iv_operand) then
              r := y
            else if y^.kind = iv_mul then
              if y^.left^.kind = iv_lts then
                r := y^.left;
          end;
          iv_mul:
            if x^.left^.kind = iv_lts then
              r := x^.left;
          otherwise
            ;
        end;
      end;
      iv_neg: begin
        y := e^.left;
        if (y^.kind = iv_lts) or (y^.kind = iv_operand) then
          r := y
        else if y^.kind = iv_mul then
          if y^.left^.kind = iv_lts then
            r := y^.left;
      end;
      iv_mul:
        if e^.left^.kind = iv_lts then
          r := e^.left;
      otherwise
        ;
    end;
  get_canonical_compare_node := r;
end;

{ get_canonical_base_node - a sum's or difference's right child, any
  other expression of kind 1..7 itself.  0x2393BC, 0x38 bytes, no
  frame. }

function get_canonical_base_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    case e^.kind of
      iv_value, iv_lts, iv_operand, iv_neg, iv_mul:
        r := e;
      iv_add, iv_sub:
        r := e^.right;
      otherwise
        ;
    end;
  get_canonical_base_node := r;
end;

{ get_canonical_remaining_node - a sum's or difference's left child,
  else nil.  0x2393F4, 0x20 bytes, no frame. }

function get_canonical_remaining_node(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r: iv_expr_ptr_t;
begin
  r := nil;
  if e <> nil then
    if (e^.kind = iv_sub) or (e^.kind = iv_add) then
      r := e^.left;
  get_canonical_remaining_node := r;
end;

{ has_canonical_form - e has a compare node.  0x239414, 0x16 bytes. }

function has_canonical_form(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  has_canonical_form := get_canonical_compare_node(e) <> nil;
end;

{ canonical_base_node_is_positive - e is not a difference (its base is
  added).  0x23942A, 0xE bytes, no frame. }

function canonical_base_node_is_positive(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  canonical_base_node_is_positive := e^.kind <> iv_sub;
end;

function iv_utils_$create_neg_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); forward;

{ build_multiplier_from_base - the factor of a base node's compare node
  (positive: added, else subtracted): 1 or -1 for a leaf, a multiple's
  factor, a negation's leaf -1 or 1 and its multiple's factor negated;
  nil for anything else.  0x239438, 0xD0 bytes, no A5: the sign as
  ord(positive) * 2 - 1. }

function build_multiplier_from_base(
    e: iv_expr_ptr_t;
    positive: boolean): iv_expr_ptr_t; options(val_param); internal;
var
  r, x: iv_expr_ptr_t;
begin
  r := nil;
  case e^.kind of
    iv_value, iv_lts, iv_operand:
      r := iv_utils_$create_value_expression(ord(positive) * 2 - 1);
    iv_mul: begin
      r := e^.right;
      if not positive then
        r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(r));
    end;
    iv_neg: begin
      x := e^.left;
      case x^.kind of
        iv_value, iv_lts, iv_operand:
          r := iv_utils_$create_value_expression(1 - ord(positive) * 2);
        iv_mul: begin
          r := x^.right;
          if positive then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(r));
        end;
        otherwise
          ;
      end;
    end;
    otherwise
      ;
  end;
  build_multiplier_from_base := r;
end;

{ iv_utils_$create_add_expression .. iv_utils_$create_operand_expression
  - an expression of each kind (the leaves made canonical).  0x239508
  (0x3A bytes), 0x239542 (0x3A), 0x23957C (0x3A), 0x2395B6 (0x2C),
  0x2395E2 (0x30), 0x239612 (0x30), 0x239642 (0x3E: the operand copied
  as three longwords); A0. }

function iv_utils_$create_add_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_add;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_add_expression := e;
end;

function iv_utils_$create_sub_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_sub;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_sub_expression := e;
end;

function iv_utils_$create_mul_expression(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_mul;
  e^.left := a;
  e^.right := b;
  iv_utils_$create_mul_expression := e;
end;

function iv_utils_$create_neg_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param);
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_neg;
  e^.left := a;
  iv_utils_$create_neg_expression := e;
end;

function iv_utils_$create_value_expression(
    v: integer32): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_value;
  e^.value := v;
  e^.canonical := true;
  iv_utils_$create_value_expression := e;
end;

function iv_utils_$create_lts_expression(
    l: lts_ptr_t): iv_expr_ptr_t; options(val_param);
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_lts;
  e^.lts := l;
  e^.canonical := true;
  iv_utils_$create_lts_expression := e;
end;

function iv_utils_$create_operand_expression(
    in o: opnd_t): iv_expr_ptr_t;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_operand;
  e^.opnd := o;
  e^.canonical := true;
  iv_utils_$create_operand_expression := e;
end;

{ create_transfer_expression, create_move_expression - an expression
  moving a between the register files, or within one.  0x239680,
  0x2396A0 (0x20 bytes each), no A5. }

function create_transfer_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_transfer;
  e^.left := a;
  create_transfer_expression := e;
end;

function create_move_expression(
    a: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  e: iv_expr_ptr_t;
begin
  e := alloc_expression;
  e^.kind := iv_move;
  e^.left := a;
  create_move_expression := e;
end;

{ iv_utils_$expression_is_zero - e is the constant 0.  0x2396C0, 0x1A
  bytes, no frame (internal: no A5). }

function iv_utils_$expression_is_zero(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  iv_utils_$expression_is_zero := (e^.kind = iv_value) and (e^.value = 0);
end;

{ forward: the canonicalizations call each other. }
function canonicalize_add_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_sub_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_mul_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_neg_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function canonicalize_rsub_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal; forward;
function iv_utils_$compare_expressions(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): boolean; options(val_param); forward;

{ iv_utils_$canonicalize_expression - e in canonical form (a sum of
  terms ordered by their compare nodes, constants folded), unless it is
  already.  0x2396DA, 0x74 bytes: a jump table by kind. }

function iv_utils_$canonicalize_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t;
begin
  if e <> nil then
    if not e^.canonical then
      case e^.kind of
        iv_neg:
          e := canonicalize_neg_expression(e);
        iv_add:
          e := canonicalize_add_expression(e);
        iv_sub:
          e := canonicalize_sub_expression(e);
        iv_mul:
          e := canonicalize_mul_expression(e);
        iv_rsub:
          e := canonicalize_rsub_expression(e);
        otherwise
          ;
      end;
  iv_utils_$canonicalize_expression := e;
end;

{ create_add_or_sub_expression - a + b when add, else a - b.  0x23974E,
  0x28 bytes, no A5: add a byte at (8,A6), a and b at (10,A6),
  (14,A6). }

function create_add_or_sub_expression(
    add: boolean;
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
begin
  if add then
    create_add_or_sub_expression := iv_utils_$create_add_expression(a, b)
  else
    create_add_or_sub_expression := iv_utils_$create_sub_expression(a, b);
end;

{ same_base_operand - a and b are displacement operands (arg block,
  stack frame, literal pool, XSB) of one kind and node.  0x239776, 0x66
  bytes, no A5. }

function same_base_operand(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
begin
  r := false;
  if (a^.kind = iv_operand) and (b^.kind = iv_operand) then
    if b^.opnd.h.kind = a^.opnd.h.kind then
      if a^.opnd.h.kind in [operand$displacement_arg_block..
                            operand$displacement_XSB_base] then
        if b^.opnd.link = a^.opnd.link then
          r := true;
  same_base_operand := r;
end;

{ operand_offset_difference - the constant a's displacement minus b's (0
  unless a is a displacement).  0x2397DC, 0x4C bytes, no A5: the
  constant expression's A0 left as the result (pattern 32). }

function operand_offset_difference(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  d: integer32;
begin
  if a^.opnd.h.kind in [operand$displacement_arg_block..
                        operand$displacement_XSB_base] then
    d := a^.opnd.value - b^.opnd.value
  else
    d := 0;
  operand_offset_difference := iv_utils_$create_value_expression(d);
end;

{ clean_up_additive_canonical_result - a canonical sum or difference
  simplified: + 0 dropped, - -x and + -x turned around, displacements
  of one base subtracted into a constant, a*x +- b*x and a*c +- b*(-c)
  made (a +- b)*x, x - x made 0 and x + x made 2*x (for multiples).
  0x239828, 0x37C bytes, no A5: the parameter given back through its
  own address. }

function clean_up_additive_canonical_result(
    e: iv_expr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  r, a, b, d, t, t2: iv_expr_ptr_t;
begin
  r := e;
  if (e^.kind = iv_add) or (e^.kind = iv_sub) then begin
    a := e^.left;
    b := e^.right;
    if iv_utils_$expression_is_zero(b) then begin
      t := b;
      free_expression(t);
      free_expression(e);
      r := a;
    end
    else if b^.kind = iv_neg then begin
      a := b^.left;
      t := b;
      free_expression(t);
      if r^.kind = iv_add then
        r^.kind := iv_sub
      else
        r^.kind := iv_add;
      r^.right := a;
    end
    else if b^.kind = iv_operand then begin
      if (r^.kind = iv_sub) and same_base_operand(a, b) then begin
        a := operand_offset_difference(a, b);
        iv_utils_$delete_expression(e);
        r := a;
      end
      else if (r^.kind = iv_add) and (a^.kind = iv_neg)
          and same_base_operand(a^.left, b) then begin
        a := operand_offset_difference(b, a^.left);
        iv_utils_$delete_expression(e);
        r := a;
      end
      else begin
        d := nil;
        if (r^.kind = iv_sub) and (a^.kind = iv_add)
            and same_base_operand(a^.right, b) then
          d := operand_offset_difference(a^.right, b)
        else if (r^.kind = iv_add) and (a^.kind = iv_sub)
            and same_base_operand(b, a^.right) then
          d := operand_offset_difference(b, a^.right);
        if d <> nil then begin
          free_expression(e);
          r := iv_utils_$create_add_expression(a^.left, d);
          free_expression(a^.right);
          t := a;
          free_expression(t);
          t2 := b;
          free_expression(t2);
        end;
      end;
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and (b^.left^.kind <> iv_lts) and (a^.left^.kind <> iv_lts)
        and (b^.right^.kind = iv_lts) and (a^.right^.kind = iv_lts)
        and (b^.right^.lts = a^.right^.lts) then begin
      r := iv_utils_$create_mul_expression(
          iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(r^.kind = iv_add, a^.left, b^.left)),
          a^.right);
      free_expression(b^.right);
      t := b;
      free_expression(t);
      t2 := a;
      free_expression(t2);
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and (b^.left^.kind <> iv_lts) and (a^.left^.kind <> iv_lts)
        and (a^.right^.kind = iv_value) and (b^.right^.kind = iv_value)
        and (-a^.right^.value = b^.right^.value) then begin
      r := iv_utils_$create_mul_expression(
          iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(r^.kind <> iv_add, a^.left, b^.left)),
          a^.right);
      free_expression(b^.right);
      t := b;
      free_expression(t);
      t2 := a;
      free_expression(t2);
    end
    else if (b^.kind = iv_mul) and (a^.kind = iv_mul)
        and iv_utils_$compare_expressions(b, a) then
      if r^.kind = iv_sub then begin
        iv_utils_$delete_expression(r);
        r := iv_utils_$create_value_expression(0);
      end
      else begin
        t := a;
        iv_utils_$delete_expression(t);
        free_expression(r);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(b, iv_utils_$create_value_expression(2)));
      end;
  end;
  clean_up_additive_canonical_result := r;
end;

{ canonicalize_add_expression - a sum in canonical form: the children
  canonical; when both have compare nodes the terms are merged in
  their order (the greater term's remainder added to the other side),
  equal constants folded and equal terms' multipliers added; a term
  with no compare node kept on the left.  0x239BA4, 0x3B8 bytes, no
  A5. }

function canonicalize_add_expression;
var
  r, l, rt, cr, cl, br, bl, rr, rl, t: iv_expr_ptr_t;
  ord_: integer32;
  pos, pr, pl: boolean;
  v: integer32;
begin
  if e^.canonical then begin
    canonicalize_add_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  l := e^.left;
  rt := e^.right;
  r := e;
  if has_canonical_form(rt) then begin
    if has_canonical_form(l) then begin
      cr := get_canonical_compare_node(rt);
      cl := get_canonical_compare_node(l);
      br := get_canonical_base_node(rt);
      bl := get_canonical_base_node(l);
      rr := get_canonical_remaining_node(rt);
      rl := get_canonical_remaining_node(l);
      ord_ := order_expressions(cl, cr);
      if ord_ > 0 then begin
        if rr <> nil then begin
          free_expression(e);
          pos := canonical_base_node_is_positive(rt);
          t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(l, rr));
          r := create_add_or_sub_expression(pos, t, br);
          if r^.left^.kind = iv_value then
            r := iv_utils_$canonicalize_expression(r);
        end;
      end
      else if ord_ < 0 then begin
        free_expression(e);
        if rl <> nil then
          r := iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(canonical_base_node_is_positive(l),
                  iv_utils_$create_add_expression(rt, rl), bl))
        else
          r := iv_utils_$create_add_expression(rt, l);
      end
      else if cr^.kind = iv_value then begin
        free_expression(e);
        if canonical_base_node_is_positive(rt) then
          v := cr^.value
        else
          v := -cr^.value;
        if canonical_base_node_is_positive(l) then
          v := v + cl^.value
        else
          v := v - cl^.value;
        r := iv_utils_$create_value_expression(v);
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$create_add_expression(
                iv_utils_$canonicalize_expression(
                    iv_utils_$create_add_expression(rl, rr)), r)
          else
            r := iv_utils_$create_add_expression(rr, r);
        end
        else if rl <> nil then
          r := iv_utils_$create_add_expression(rl, r);
      end
      else begin
        free_expression(e);
        pr := canonical_base_node_is_positive(rt);
        pl := canonical_base_node_is_positive(l);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(
                iv_utils_$create_add_expression(build_multiplier_from_base(bl, pl),
                                                build_multiplier_from_base(br, pr)),
                cr));
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                r, iv_utils_$create_add_expression(rr, rl)))
          else
            r := iv_utils_$canonicalize_expression(
                iv_utils_$create_add_expression(rr, r));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rl, r));
      end;
    end
    else begin
      br := get_canonical_base_node(rt);
      rr := get_canonical_remaining_node(rt);
      if rr <> nil then begin
        free_expression(e);
        pos := canonical_base_node_is_positive(rt);
        t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(l, rr));
        r := create_add_or_sub_expression(pos, t, br);
      end;
    end;
  end
  else if has_canonical_form(l) then begin
    free_expression(e);
    bl := get_canonical_base_node(l);
    rl := get_canonical_remaining_node(l);
    if rl <> nil then begin
      pos := canonical_base_node_is_positive(l);
      t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rt, rl));
      r := create_add_or_sub_expression(pos, t, bl);
    end
    else
      r := iv_utils_$create_add_expression(rt, bl);
  end;
  r := clean_up_additive_canonical_result(r);
  r^.canonical := true;
  canonicalize_add_expression := r;
end;

{ canonicalize_sub_expression - a difference in canonical form, as a
  sum: the subtracted side negated.  0x239F5C, 0x418 bytes, no A5. }

function canonicalize_sub_expression;
var
  r, l, rt, cr, cl, br, bl, rr, rl, t, n: iv_expr_ptr_t;
  ord_: integer32;
  neg, p, pr, pl: boolean;
  v: integer32;
begin
  if e^.canonical then begin
    canonicalize_sub_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  l := e^.left;
  rt := e^.right;
  r := e;
  if has_canonical_form(rt) then begin
    if has_canonical_form(l) then begin
      cr := get_canonical_compare_node(rt);
      cl := get_canonical_compare_node(l);
      br := get_canonical_base_node(rt);
      bl := get_canonical_base_node(l);
      rr := get_canonical_remaining_node(rt);
      rl := get_canonical_remaining_node(l);
      ord_ := order_expressions(cl, cr);
      if ord_ > 0 then begin
        if rr <> nil then begin
          free_expression(e);
          neg := not canonical_base_node_is_positive(rt);
          t := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(l, rr));
          if neg then
            r := iv_utils_$create_add_expression(t, br)
          else
            r := iv_utils_$create_sub_expression(t, br);
          if r^.left^.kind = iv_value then
            r := iv_utils_$canonicalize_expression(r);
        end;
      end
      else if ord_ < 0 then begin
        free_expression(e);
        n := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(rt));
        if rl <> nil then
          r := iv_utils_$canonicalize_expression(
              create_add_or_sub_expression(canonical_base_node_is_positive(l),
                  iv_utils_$create_add_expression(n, rl), bl))
        else
          r := iv_utils_$create_add_expression(n, l);
      end
      else if cr^.kind = iv_value then begin
        free_expression(e);
        if canonical_base_node_is_positive(rt) then
          v := -cr^.value
        else
          v := cr^.value;
        if canonical_base_node_is_positive(l) then
          v := v + cl^.value
        else
          v := v - cl^.value;
        r := iv_utils_$create_value_expression(v);
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_sub_expression(rl, rr), r))
          else
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_neg_expression(rr), r));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(rl, r));
      end
      else begin
        free_expression(e);
        pr := canonical_base_node_is_positive(rt);
        pl := canonical_base_node_is_positive(l);
        r := iv_utils_$canonicalize_expression(
            iv_utils_$create_mul_expression(
                iv_utils_$create_sub_expression(build_multiplier_from_base(bl, pl),
                                                build_multiplier_from_base(br, pr)),
                cr));
        if rr <> nil then begin
          if rl <> nil then
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                r, iv_utils_$create_sub_expression(rl, rr)))
          else
            r := iv_utils_$canonicalize_expression(
                iv_utils_$create_sub_expression(r, rr));
        end
        else if rl <> nil then
          r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(r, rl));
      end;
    end
    else begin
      br := get_canonical_base_node(rt);
      rr := get_canonical_remaining_node(rt);
      if rr <> nil then begin
        free_expression(e);
        neg := not canonical_base_node_is_positive(rt);
        t := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(l, rr));
        if neg then
          r := iv_utils_$create_add_expression(t, br)
        else
          r := iv_utils_$create_sub_expression(t, br);
      end;
    end;
  end
  else if has_canonical_form(l) then begin
    free_expression(e);
    bl := get_canonical_base_node(l);
    rl := get_canonical_remaining_node(l);
    if rl <> nil then begin
      p := canonical_base_node_is_positive(l);
      t := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(rt), rl));
      if p then
        r := iv_utils_$create_add_expression(t, bl)
      else
        r := iv_utils_$create_sub_expression(t, bl);
    end
    else
      r := iv_utils_$create_add_expression(
          iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(rt)), bl);
  end;
  r := clean_up_additive_canonical_result(r);
  r^.canonical := true;
  canonicalize_sub_expression := r;
end;

{ canonicalize_mul_expression - a product in canonical form: by 0, 1 and
  -1 simplified, constants folded, a constant moved inside a negation,
  a multiple or a canonical sum or difference; a constant on the left
  moved right.  0x23A374, 0x266 bytes, no A5: the product by M$MIS. }

function canonicalize_mul_expression;
var
  r, l, rt, t, d: iv_expr_ptr_t;
begin
  if e^.canonical then begin
    canonicalize_mul_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  e^.right := iv_utils_$canonicalize_expression(e^.right);
  rt := e^.right;
  l := e^.left;
  r := e;
  if rt^.kind = iv_value then begin
    if rt^.value = 0 then begin
      free_expression(e);
      r := rt;
      t := l;
      iv_utils_$delete_expression(t);
    end
    else if rt^.value = 1 then begin
      free_expression(e);
      r := l;
      t := rt;
      iv_utils_$delete_expression(t);
    end
    else if rt^.value = -1 then begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_neg_expression(l));
      t := rt;
      iv_utils_$delete_expression(t);
    end
    else
      case l^.kind of
        iv_value: begin
          free_expression(e);
          r := rt;
          r^.value := l^.value * r^.value;
          t := l;
          free_expression(t);
        end;
        iv_neg: begin
          free_expression(e);
          rt^.value := -rt^.value;
          r := iv_utils_$canonicalize_expression(
              iv_utils_$create_mul_expression(l^.left, rt));
          t := l;
          free_expression(t);
        end;
        iv_mul:
          if l^.right^.kind = iv_value then begin
            free_expression(e);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_mul_expression(
                l^.left, iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        iv_add:
          if has_canonical_form(l) then begin
            free_expression(e);
            d := iv_utils_$duplicate_expression(rt);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
                iv_utils_$create_mul_expression(l^.left, d),
                iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        iv_sub:
          if has_canonical_form(l) then begin
            free_expression(e);
            d := iv_utils_$duplicate_expression(rt);
            r := iv_utils_$canonicalize_expression(iv_utils_$create_sub_expression(
                iv_utils_$create_mul_expression(l^.left, d),
                iv_utils_$create_mul_expression(l^.right, rt)));
          end;
        otherwise
          ;
      end;
  end
  else if l^.kind = iv_value then begin
    free_expression(e);
    r := canonicalize_mul_expression(iv_utils_$create_mul_expression(rt, l));
  end;
  r^.canonical := true;
  canonicalize_mul_expression := r;
end;

{ canonicalize_neg_expression - a negation in canonical form: a constant
  negated, - -x made x, -(a - b) made -a + b, -(a + b) made -a + -b, a
  multiple's constant negated.  0x23A5DA, 0x120 bytes, no A5. }

function canonicalize_neg_expression;
var
  r, l, t: iv_expr_ptr_t;
begin
  if e^.canonical then begin
    canonicalize_neg_expression := e;
    return;
  end;
  e^.left := iv_utils_$canonicalize_expression(e^.left);
  l := e^.left;
  r := e;
  case l^.kind of
    iv_value: begin
      l^.value := -l^.value;
      free_expression(e);
      r := l;
    end;
    iv_neg: begin
      free_expression(e);
      r := l^.left;
      t := l;
      free_expression(t);
    end;
    iv_sub: begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(l^.left), l^.right));
      t := l;
      free_expression(t);
    end;
    iv_add: begin
      free_expression(e);
      r := iv_utils_$canonicalize_expression(iv_utils_$create_add_expression(
          iv_utils_$create_neg_expression(l^.left),
          iv_utils_$create_neg_expression(l^.right)));
      t := l;
      free_expression(t);
    end;
    iv_mul:
      if l^.right^.kind = iv_value then begin
        free_expression(e);
        l^.right^.value := -l^.right^.value;
        r := l;
      end;
    otherwise
      ;
  end;
  r^.canonical := true;
  canonicalize_neg_expression := r;
end;

{ canonicalize_rsub_expression - a reversed difference made a difference
  and canonicalized.  0x23A6FA, 0x42 bytes, no A5: the canonical
  form's A0 left as the result (pattern 32). }

function canonicalize_rsub_expression;
var
  l, r: iv_expr_ptr_t;
begin
  l := iv_utils_$canonicalize_expression(e^.left);
  r := iv_utils_$canonicalize_expression(e^.right);
  e^.kind := iv_sub;
  e^.left := r;
  e^.right := l;
  canonicalize_rsub_expression := iv_utils_$canonicalize_expression(e);
end;

{ iv_utils_$duplicate_expression - a copy of e (nil for nil).  0x23A73C,
  0xC0 bytes: recursive; the message ends in %. (as the image has it). }

function iv_utils_$duplicate_expression(
    e: iv_expr_ptr_t): iv_expr_ptr_t;
var
  r: iv_expr_ptr_t;
  k: integer32;
begin
  if e = nil then
    r := nil
  else if iv_nchildren[e^.kind] > 0 then begin
    r := alloc_expression;
    r^.kind := e^.kind;
    for k := 1 to iv_nchildren[e^.kind] do
      r^.child[k] := iv_utils_$duplicate_expression(e^.child[k]);
  end
  else
    case e^.kind of
      iv_value:
        r := iv_utils_$create_value_expression(e^.value);
      iv_operand:
        r := iv_utils_$create_operand_expression(e^.opnd);
      iv_lts:
        r := iv_utils_$create_lts_expression(e^.lts);
      otherwise
        bug_check('IV_$duplicate_expression: Unknown expression type%.');
    end;
  iv_utils_$duplicate_expression := r;
end;

{ iv_utils_$compare_expressions - a and b are the same expression (both
  nil, or of one kind with equal children, values, segments or
  operands: displacements by node and value, like registers by
  segment).  0x23A830, 0xEE bytes: recursive. }

function iv_utils_$compare_expressions;
var
  r: boolean;
  k: integer32;
begin
  r := false;
  if (a = nil) and (b = nil) then
    r := true
  else if (a <> nil) and (b <> nil) then
    if a^.kind = b^.kind then
      if iv_nchildren[a^.kind] > 0 then begin
        for k := 1 to iv_nchildren[a^.kind] do
          if not iv_utils_$compare_expressions(a^.child[k], b^.child[k]) then begin
            iv_utils_$compare_expressions := false;
            return;
          end;
        r := true;
      end
      else
        case a^.kind of
          iv_value:
            r := a^.value = b^.value;
          iv_lts:
            r := a^.lts = b^.lts;
          iv_operand:
            if a^.opnd.h.kind = b^.opnd.h.kind then
              case a^.opnd.h.kind of
                operand$displacement_arg_block, operand$displacement_stack_frame,
                operand$displacement_literal_pool:
                  r := (a^.opnd.link = b^.opnd.link)
                       and (a^.opnd.value = b^.opnd.value);
                operand$ip_reg_like, operand$fp_reg_like,
                operand$fp_reg_pair_like:
                  r := a^.opnd.lts = b^.opnd.lts;
                otherwise
                  ;
              end;
          otherwise
            ;
        end;
  iv_utils_$compare_expressions := r;
end;

{ propagate_up_cost - the cost of computing e in each register file (1
  integer, 2 floating): a transfer (1) unless its file is chosen, a
  constant integer, an operand floating when it is a floating register,
  else the children's sums, each then at most the other's plus a
  transfer.  0x23A956, 0x176 bytes, no A5: recursive. }

procedure propagate_up_cost(
    var cost: iv_cost_t;
    e: iv_expr_ptr_t); options(val_param); internal;
var
  k, j: integer;
  n: integer32;
  sub: iv_cost_t;
begin
  for k := 1 to 2 do
    cost[k] := 0;
  if e^.rclass <> 0 then begin
    for k := 1 to 2 do
      if k <> e^.rclass then
        cost[k] := 1;
  end
  else if e^.kind = iv_value then begin
    for k := 1 to 2 do
      if k <> 1 then
        cost[k] := 1;
  end
  else if e^.kind = iv_operand then begin
    if e^.opnd.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                          operand$fp_reg_like] then begin
      for k := 1 to 2 do
        if k <> 2 then
          cost[k] := 1;
    end
    else
      for k := 1 to 2 do
        if k <> 1 then
          cost[k] := 1;
  end
  else if iv_nchildren[e^.kind] > 0 then begin
    for n := 1 to iv_nchildren[e^.kind] do begin
      propagate_up_cost(sub, e^.child[n]);
      for k := 1 to 2 do
        cost[k] := cost[k] + sub[k];
    end;
    for k := 1 to 2 do
      for j := 1 to 2 do
        if cost[k] > cost[j] + 1 then
          if j <> k then
            cost[k] := cost[j] + 1;
  end;
end;

{ can_encode_as_register - e can be an instruction's register operand:
  not a constant, and an operand only when it is a like register (or a
  case jump base).  0x23AACC, 0x42 bytes, no A5. }

function can_encode_as_register(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
begin
  if e^.kind = iv_value then
    can_encode_as_register := false
  else if e^.kind = iv_operand then
    can_encode_as_register := e^.opnd.h.kind in [operand$ip_reg_like,
        operand$fp_reg_like, operand$fp_reg_pair_like, operand$case_jump_base]
  else
    can_encode_as_register := true;
end;

{ first_operand_can_change - the child that becomes e's operand 1 can be
  a register.  0x23AB0E, 0x6A bytes, no A5 (iv's tables through the
  caller's A5). }

function first_operand_can_change(
    e: iv_expr_ptr_t): boolean; options(val_param); internal;
var
  k: integer32;
begin
  first_operand_can_change := false;
  for k := 1 to iv_nchildren[e^.kind] do
    if iv_opnd_pos[e^.kind, k] = 1 then begin
      first_operand_can_change := can_encode_as_register(e^.child[k]);
      return;
    end;
end;

{ propagate_down_type - e (and its children) computed in register file
  t: a multiply by a power of 2 in integers made a shift; the children's
  file the cheaper (propagate_up_cost); in integers a child that cannot
  be a register made an immediate (the commuted instruction's when only
  operand 1 takes one), a move or a load; a transfer added where the
  files differ, a constant in floating registers loaded, an operand
  moved and transferred.  0x23AB78, 0x35C bytes, no A5: recursive. }

function propagate_down_type(
    e: iv_expr_ptr_t;
    t: integer): iv_expr_ptr_t; options(val_param); internal;
label
  1, 2;
var
  best, k: integer;
  n, b: integer32;
  pos: integer32;
  cost, sub: iv_cost_t;
  c, x: iv_expr_ptr_t;
begin
  if e = nil then
    goto 2;
  if e^.rclass = t then
    goto 2;
  if e^.rclass <> 0 then
    e := create_transfer_expression(e)
  else begin
    if (e^.kind = iv_mul) and (t = 1) then
      for b := 0 to 31 do
        if lshft(1, b) = e^.right^.value then begin
          e^.kind := iv_shift;
          e^.right^.value := b;
          exit;
        end;
    if iv_nchildren[e^.kind] <= 0 then
      goto 1;
    best := t;
    if 1 < iv_nchildren[e^.kind] then begin
      for k := 1 to 2 do
        cost[k] := 0;
      for n := 1 to iv_nchildren[e^.kind] do begin
        propagate_up_cost(sub, e^.child[n]);
        for k := 1 to 2 do
          cost[k] := cost[k] + sub[k];
      end;
      for k := 1 to 2 do
        if cost[best] > cost[k] + 1 then
          best := k;
    end;
    for n := 1 to iv_nchildren[e^.kind] do
      e^.child[n] := propagate_down_type(e^.child[n], best);
    if (e^.kind = iv_mul) and (best = 1) then
      for b := 0 to 31 do
        if lshft(1, b) = e^.right^.value then begin
          e^.kind := iv_shift;
          e^.right^.value := b;
          exit;
        end;
    if best = 1 then
      for n := 1 to iv_nchildren[e^.kind] do begin
        pos := iv_opnd_pos[e^.kind, n];
        if not can_encode_as_register(e^.child[n]) then begin
          c := e^.child[n];
          if c^.kind = iv_value then begin
            if not lir_$can_encode_as_immediate_operand(c^.value,
                       iv_opc[1, e^.kind], univ_ptr(pos)) then
              if (pos <> 1) and (iv_commuted[e^.kind] <> 0)
                  and first_operand_can_change(e)
                  and lir_$can_encode_as_immediate_operand(c^.value,
                          iv_opc[1, iv_commuted[e^.kind]], univ_ptr(1)) then begin
                x := e^.right;
                e^.right := e^.left;
                e^.left := x;
                e^.kind := iv_commuted[e^.kind];
              end
              else if lir_$can_encode_as_immediate_operand(c^.value,
                          ord(opc$move), univ_ptr(1)) then begin
                e^.child[n] := create_move_expression(e^.child[n]);
                e^.child[n]^.rclass := 1;
              end
              else
                e^.child[n]^.kind := iv_load;
          end
          else if pos <> 1 then
            if (iv_commuted[e^.kind] <> 0) and first_operand_can_change(e) then begin
              x := e^.right;
              e^.right := e^.left;
              e^.left := x;
              e^.kind := iv_commuted[e^.kind];
            end
            else begin
              e^.child[n] := create_move_expression(e^.child[n]);
              e^.child[n]^.rclass := 1;
            end;
        end;
      end;
    e^.rclass := best;
    if best <> t then
      e := create_transfer_expression(e);
  end;
1:
  e^.rclass := t;
  if (e^.kind = iv_value) and (t <> 1) then
    e^.kind := iv_load
  else if (e^.kind = iv_operand) and (t <> 1) then begin
    e^.rclass := 1;
    e := create_move_expression(e);
    e^.rclass := 1;
    e := create_transfer_expression(e);
    e^.rclass := t;
  end;
2:
  propagate_down_type := e;
end;

{ elaborate_expression - e's register files chosen from the leaves up:
  a multiple by a power of 2 integer, by a negative one negated; the
  children elaborated in the file the kind wants (iv_elab_class: a
  segment's its definition's operand kind); a + -b, -a + b and a - -b
  turned into differences and sums; then e in that file, and when
  force in t (and a multiple in integers).  0x23AED4, 0x1AA bytes, no
  A5: recursive. }

function elaborate_expression(
    e: iv_expr_ptr_t;
    t: integer;
    force: boolean): iv_expr_ptr_t; options(val_param); internal;
var
  w, cls: integer;
  v, n: integer32;
  x: iv_expr_ptr_t;
begin
  w := 0;
  cls := iv_elab_class[e^.kind];
  if e^.kind = iv_mul then
    if e^.right^.kind = iv_value then begin
      v := e^.right^.value;
      if v > 0 then begin
        if (~(v - 1) & v) = v then
          cls := 1;
      end
      else if v < 0 then
        if (-v & v) = -v then begin
          e^.right^.value := -v;
          e := iv_utils_$create_neg_expression(e);
          cls := iv_elab_class[e^.kind];
        end;
    end;
  case cls of
    3:
      w := 1;
    4:
      w := 2;
    2:
      w := ord(e^.lts^.refs^.h.kind);
    otherwise
      ;
  end;
  for n := 1 to iv_nchildren[e^.kind] do
    e^.child[n] := elaborate_expression(e^.child[n], w, w <> 0);
  if e^.kind = iv_add then begin
    if e^.left^.kind = iv_neg then begin
      x := e^.left^.left;
      free_expression(e^.left);
      e^.kind := iv_sub;
      e^.left := e^.right;
      e^.right := x;
    end
    else if e^.right^.kind = iv_neg then begin
      x := e^.right^.left;
      free_expression(e^.right);
      e^.kind := iv_sub;
      e^.right := x;
    end;
  end
  else if e^.kind = iv_sub then
    if e^.right^.kind = iv_neg then begin
      x := e^.right^.left;
      free_expression(e^.right);
      e^.kind := iv_add;
      e^.right := x;
    end;
  if w <> 0 then
    e := propagate_down_type(e, w);
  if force then
    if (t <> w) or ((e^.kind = iv_mul) and (t = 1)) then
      e := propagate_down_type(e, t);
  elaborate_expression := e;
end;

{ iv_utils_$elaborate_expression - e elaborated in rclass, a constant
  left as the immediate operand pos of opc when it encodes so, else
  moved (or loaded), an operand that cannot be a register moved.
  0x23B07E, 0xA6 bytes: pos passed on as a longword. }

function iv_utils_$elaborate_expression;
var
  r: iv_expr_ptr_t;
  p: integer32;
begin
  r := elaborate_expression(e, rclass, true);
  p := pos;
  if r^.kind = iv_value then begin
    if not lir_$can_encode_as_immediate_operand(r^.value, opc, univ_ptr(p)) then
      if lir_$can_encode_as_immediate_operand(r^.value, ord(opc$move),
                                              univ_ptr(1)) then begin
        r := create_move_expression(r);
        r^.rclass := 1;
      end
      else
        r^.kind := iv_load;
  end
  else if r^.kind = iv_operand then
    if not can_encode_as_register(r) then begin
      r := create_move_expression(r);
      r^.rclass := 1;
    end;
  iv_utils_$elaborate_expression := r;
end;

{ find_last_instruction - the block's last instruction, or the first of
  the branches and jumps (classes 1, 5, 6) just before it.  0x23B124,
  0x46 bytes, no A5: `moveq #98; btst' of the opcode's class. }

function find_last_instruction(
    bb: bb_ptr_t): instr_ptr_t; options(val_param); internal;
var
  i, p: instr_ptr_t;
begin
  i := bb^.last;
  p := i^.prev;
  while p <> nil do begin
    if not (instruction_attributes[p^.opc].class
            in [class$branch, class$fp_branch, class$jump]) then
      exit;
    i := p;
    p := p^.prev;
  end;
  find_last_instruction := i;
end;

{ add_operand_to_segment - operand o made a reference of kind to
  segment s with properties rrp (also its live range's), chained on
  s's references: last when it means to modify, after the definition
  when it reads and the first reference writes, else first.  0x23B16A,
  0x8C bytes, no A5. }

procedure add_operand_to_segment(
    o: opnd_ptr_t;
    s: lts_ptr_t;
    rrp: integer;
    kind: integer); options(val_param); internal;
var
  p: ^opnd_ptr_t;
begin
  s^.rrp := rrp$set_t(integer(s^.rrp) ! rrp);
  opnd_bytes_ptr_t(o)^.rrp := rrp;
  o^.h.count := 0;
  opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! kind;
  o^.lts := s;
  o^.link := nil;
  s^.lr^.rrp := rrp$set_t(integer(s^.lr^.rrp) ! rrp);
  p := addr(s^.refs);
  if (rrp & 16#20) <> 0 then begin
    while p^ <> nil do
      p := addr(p^^.link);
  end
  else if (rrp & 16#10) <> 0 then
    if p^ <> nil then
      if (opnd_bytes_ptr_t(p^)^.rrp & 12) <> 0 then
        p := addr(p^^.link);
  o^.link := p^;
  p^ := o;
end;

{ create_operand_from_elaborated_expression - operand o made what the
  elaborated expression e computes, for an instruction in block use_bb:
  a segment's value read (from the live range's last segment in the
  block, or an exposed one with a birthpoint made for it), an operand
  copied (keeping o's number), a constant an immediate; an operation an
  instruction (after at, else before code_bb's closing branches)
  computing a new live range, its operands made recursively (a child
  that cannot be the register an operand other than 1 needs, or an
  operand as operand 1 of other than an add or move, moved first; a
  shift by a constant the operand's scale where the opcode takes it;
  a commutative operation's children exchanged for that); a constant
  loaded from the literal pool.  0x23B1F6, 0x680 bytes, no A5:
  recursive; the opcode from iv_opc by e's register file and kind. }

procedure create_operand_from_elaborated_expression(
    o: opnd_ptr_t;
    var e: iv_expr_ptr_t;
    at: instr_ptr_t;
    use_bb: bb_ptr_t;
    code_bb: bb_ptr_t); options(val_param); internal;
var
  s, d, f: lts_ptr_t;
  lr: lr_ptr_t;
  prev: lts_ptr_t;
  created: boolean;
  n, k, pos, a, b: integer32;
  opc: integer;
  shift: integer32;
  c, x: iv_expr_ptr_t;
  i: instr_ptr_t;
  r: opnd_ptr_t;
begin
  case e^.kind of
    iv_lts: begin
      d := e^.lts;
      created := false;
      lr := d^.lr;
      if use_bb = code_bb then begin
        s := utils_$find_last_lts_in_bb(lr, use_bb, prev);
        if s = nil then begin
          s := utils_$get_final_lts(lr, use_bb, created);
          utils_$put_lts_on_exposed_list(s);
        end;
      end
      else
        s := utils_$get_exposed_lts(lr, use_bb, created);
      if created then begin
        if d^.f2.exposed then
          if d^.l44 <> nil then
            d := d^.l44;
        if not d^.f2.final then
          if use_bb <> d^.bb then
            utils_$put_lts_on_final_list(d);
        utils_$add_birthpoint(d, use_bb, true);
      end;
      add_operand_to_segment(o, s, 16, e^.rclass);
    end;
    iv_operand: begin
      k := o^.h.num;
      o^ := e^.opnd;
      o^.h.num := k;
    end;
    iv_value: begin
      o^.h.kind := operand$immediate;
      o^.value := e^.value;
      o^.link := nil;
      opnd_bytes_ptr_t(o)^.rrp := 16;
      o^.h.bytes := 4;
      o^.h.count := 0;
    end;
    otherwise begin
      n := iv_nchildren[e^.kind];
      opc := iv_opc[e^.rclass, e^.kind];
      if at = nil then
        at := find_last_instruction(code_bb);
      for k := 1 to n do begin
        c := e^.child[k];
        if (iv_opnd_pos[e^.kind, k] <> 1) and not can_encode_as_register(c)
            and (e^.kind <> iv_shift) then begin
          c := create_move_expression(c);
          c^.rclass := c^.left^.rclass;
          e^.child[k] := c;
        end
        else if (iv_opnd_pos[e^.kind, k] = 1) and (e^.kind <> iv_add)
            and (c^.kind = iv_operand) and (e^.kind <> iv_move) then begin
          c := create_move_expression(c);
          c^.rclass := c^.left^.rclass;
          e^.child[k] := c;
        end;
      end;
      if n = 2 then
        if iv_commuted[e^.kind] <> 0 then begin
          a := iv_opnd_pos[e^.kind, 1];
          b := iv_opnd_pos[e^.kind, 2];
          if can_encode_as_register(e^.child[a]) then begin
            c := e^.child[a];
            if not ((c^.kind = iv_shift) and (c^.right^.kind = iv_value)
                    and tm_utils_$can_convert_to_ip_reg_operand(opc, 1,
                            c^.right^.value)
                    and can_encode_as_register(c^.left)) then begin
              c := e^.child[b];
              if c^.kind = iv_shift then
                if c^.right^.kind = iv_value then
                  if tm_utils_$can_convert_to_ip_reg_operand(
                         iv_opc[e^.rclass, iv_commuted[e^.kind]], 1,
                         c^.right^.value) then
                    if can_encode_as_register(c^.left) then begin
                      x := e^.left;
                      e^.left := e^.right;
                      e^.right := x;
                      e^.kind := iv_commuted[e^.kind];
                      opc := iv_opc[e^.rclass, e^.kind];
                    end;
            end;
          end;
        end;
      i := lir_$optimizer_new_instruction(at, opc, false);
      i^.h.b0_6 := false;
      for k := 1 to i^.h.nopnds do
        i^.opnds[k].h.num := k;
      for k := 1 to n do begin
        pos := iv_opnd_pos[e^.kind, k];
        shift := 0;
        c := e^.child[k];
        if c^.kind = iv_shift then
          if c^.right^.kind = iv_value then
            if tm_utils_$can_convert_to_ip_reg_operand(opc, pos,
                                                       c^.right^.value) then
              if can_encode_as_register(c^.left) then begin
                shift := c^.right^.value;
                c := c^.left;
              end;
        create_operand_from_elaborated_expression(addr(i^.opnds[pos]), c, i,
                                                  code_bb, code_bb);
        if shift <> 0 then
          i^.opnds[pos].h.count := shift;
      end;
      if e^.kind = iv_load then begin
        discard(sym_$reformat_literal_operand(smcontk(82, e^.value), 4, 0,
                                              addr(i^.opnds[1])));
        opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
        i^.opnds[1].h.kind := operand$displacement_literal_pool;
        i^.opnds[1].h.bytes := 4;
        opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
        i^.opnds[2].h.kind := operand$ip_reg_like;
        i^.opnds[2].value := lir_main_c48;   { a segment (lir_main +0xC48) }
        i^.h.b2_5 := false;
        n := 2;
      end;
      r := addr(i^.opnds[n + 1]);
      opnd_bytes_ptr_t(r)^.rrp := 8;
      opnd_bytes_ptr_t(r)^.b3 := (opnd_bytes_ptr_t(r)^.b3 & 16#E0) ! e^.rclass;
      opnd_bytes_ptr_t(o)^.rrp := 16;
      opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! e^.rclass;
      lr := lir_$new_live_range_for_kind(e^.rclass);
      lr^.rrp := rrp$set_t(integer(lr^.rrp) ! 24);
      if use_bb = code_bb then begin
        lir_utils_$add_lts_to_lr(24, lr, code_bb, s);
        r^.lts := s;
        r^.link := o;
        o^.lts := s;
        o^.link := nil;
        s^.refs := r;
      end
      else begin
        bv_$make_live_range_complex(iv_rtn, lr);
        f := utils_$get_final_lts(lr, code_bb, created);
        s := utils_$get_exposed_lts(lr, use_bb, created);
        o^.lts := s;
        o^.link := nil;
        s^.refs := o;
        s^.rrp := s^.rrp + [rrp$read];
        r^.lts := f;
        r^.link := nil;
        f^.refs := r;
        f^.rrp := f^.rrp + [rrp$write];
        utils_$add_birthpoint(f, use_bb, true);
      end;
    end;
  end;
end;

{ iv_utils_$create_operand_from_expression - operand o (of an
  instruction in its block) made the value of a copy of e elaborated in
  register file rclass for its place, the instructions put after at
  in code_bb.  0x23B876, 0x78 bytes. }

procedure iv_utils_$create_operand_from_expression;
var
  i: instr_ptr_t;
  r: iv_expr_ptr_t;
begin
  i := utils_ins_$operands_instruction(o);
  r := iv_utils_$elaborate_expression(iv_utils_$duplicate_expression(e),
                                      rclass, i^.opc, o^.h.num);
  create_operand_from_elaborated_expression(o, r, at, i^.bb, code_bb);
  iv_utils_$delete_expression(r);
end;

{ iv_utils_$live_range_from_elaborated_expression - e as an operand: a
  segment its live range (kind 1), an operand itself (2), a constant
  its value (3); an operation an instruction made at the head of bb
  writing a new live range (kind 1), its operands filled from its
  children (a live range in their +8; an operand copied takes the
  child's number k, though it goes to slot pos), a constant loaded from
  the literal pool.  0x23B8EE, 0x2C0 bytes: recursive. }

procedure iv_utils_$live_range_from_elaborated_expression;
var
  n, k, pos: integer32;
  opc: integer;
  i: instr_ptr_t;
  p: opnd_ptr_t;
  clr: lr_ptr_t;
  cvalue: integer32;
  cop: opnd_ptr_t;
  ckind: integer;
begin
  case e^.kind of
    iv_lts:
      lr := e^.lts^.lr;
    iv_operand: begin
      op := addr(e^.opnd);
      kind := 2;
      return;
    end;
    iv_value: begin
      value := e^.value;
      kind := 3;
      return;
    end;
    otherwise begin
      n := iv_nchildren[e^.kind];
      opc := iv_opc[e^.rclass, e^.kind];
      i := lir_$optimizer_new_instruction(bb^.first, opc, false);
      i^.h.b0_6 := false;
      for k := 1 to i^.h.nopnds do
        i^.opnds[k].h.num := k;
      for k := 1 to n do begin
        pos := iv_opnd_pos[e^.kind, k];
        p := addr(i^.opnds[pos]);
        opnd_bytes_ptr_t(p)^.rrp := 16;
        iv_utils_$live_range_from_elaborated_expression(e^.child[k], bb, clr,
                                                        cvalue, cop, ckind);
        case ckind of
          1: begin
            opnd_bytes_ptr_t(p)^.b3 := (opnd_bytes_ptr_t(p)^.b3 & 16#E0)
                                       ! e^.child[k]^.rclass;
            p^.ptr := clr;
          end;
          3: begin
            p^.h.kind := operand$immediate;
            p^.value := cvalue;
            p^.link := nil;
            p^.h.bytes := 4;
            p^.h.count := 0;
          end;
          2: begin
            p^ := cop^;
            p^.h.num := k;
          end;
          otherwise
            ;
        end;
      end;
      if e^.kind = iv_load then begin
        discard(sym_$reformat_literal_operand(smcontk(82, e^.value), 4, 0,
                                              addr(i^.opnds[1])));
        opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
        i^.opnds[1].h.kind := operand$displacement_literal_pool;
        i^.opnds[1].h.bytes := 4;
        opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
        i^.opnds[2].h.kind := operand$ip_reg_like;
        i^.opnds[2].value := lir_main_c48;   { a segment (lir_main +0xC48) }
        i^.h.b2_5 := false;
        n := 2;
      end;
      opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.rrp := 8;
      opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.b3 :=
          (opnd_bytes_ptr_t(addr(i^.opnds[n + 1]))^.b3 & 16#E0) ! e^.rclass;
      clr := lir_$new_live_range_for_kind(e^.rclass);
      i^.opnds[n + 1].ptr := clr;
      lr := clr;
    end;
  end;
  kind := 1;
end;

{ increments_are_equal - both induction lts' increments are known and
  the same.  0x23BBAE, 0x3A bytes, no A5. }

function increments_are_equal(
    a: iv_lts_ptr_t;
    b: iv_lts_ptr_t): boolean; options(val_param); internal;
begin
  increments_are_equal := false;
  if a^.h.known then
    if b^.h.known then
      increments_are_equal := iv_utils_$compare_expressions(a^.incr, b^.incr);
end;

{ create_induction_lts - segment s's induction lts of kind for variable
  v (kinds 1..3 put first on v's list; a kind 2 of a secondary variable
  made 3), its increment known as v's.  0x23BBE8, 0x6C bytes, no A5:
  `moveq #14; btst kind' for kinds 1..3; frame 8:w 10:l 14:l
  (pattern 125). }

function create_induction_lts(
    kind: integer;
    s: lts_ptr_t;
    v: iv_var_ptr_t): iv_lts_ptr_t; options(val_param); internal;
var
  l: iv_lts_ptr_t;
begin
  l := alloc_induction_lts;
  l^.h.kind := kind;
  l^.ivar := v;
  l^.lts := s;
  if kind in [1..3] then begin
    l^.next := v^.ltss;
    v^.ltss := l;
  end;
  if kind = 2 then
    if v^.parent <> nil then
      l^.h.kind := 3;
  l^.h.known := v^.f48.known;
  s^.l24 := integer32(l);
  create_induction_lts := l;
end;

{ free_induction_lts - l put on the free list.  0x23BC54, 0x10 bytes,
  no frame. }

procedure free_induction_lts(
    l: iv_lts_ptr_t); options(val_param); internal;
begin
  l^.next := iv_free_lts;
  iv_free_lts := l;
end;

{ iv_utils_$delete_induction_lts - l given back: a kind 1..3's
  expressions deleted and l taken off its variable's list, a kind 4's
  off its induction expression's; its segment's +24 cleared when it
  points to l.  The caller's pointer is not cleared.  0x23BC64, 0xC0
  bytes (loads A5): a jump table by kind - 1. }

procedure iv_utils_$delete_induction_lts(
    var lp: iv_lts_ptr_t);
var
  l, x: iv_lts_ptr_t;
  p: ^iv_lts_ptr_t;
begin
  l := lp;
  if l = nil then
    return;
  case l^.h.kind of
    1, 2, 3: begin
      iv_utils_$delete_expression(l^.incr);
      iv_utils_$delete_expression(l^.step);
      p := addr(l^.ivar^.ltss);
      x := p^;
      while x <> nil do begin
        if x = l then begin
          p^ := x^.next;
          exit;
        end;
        p := addr(x^.next);
        x := x^.next;
      end;
    end;
    4: begin
      p := addr(l^.iexpr^.ltss);
      x := p^;
      while x <> nil do begin
        if x = l then begin
          p^ := x^.next;
          exit;
        end;
        p := addr(x^.next);
        x := x^.next;
      end;
    end;
    otherwise
      ;
  end;
  if l^.lts <> nil then begin
    if iv_lts_ptr_t(l^.lts^.l24) = l then
      l^.lts^.l24 := 0;
  end;
  l^.lts := nil;
  free_induction_lts(l);
end;

{ free_induction_addr - a put on the free list.  0x23BD24, 0x10 bytes,
  no frame. }

procedure free_induction_addr(
    a: iv_addr_ptr_t); options(val_param); internal;
begin
  a^.next := iv_free_addr;
  iv_free_addr := a;
end;

{ iv_utils_$delete_induction_addr - a taken off its induction
  expression's list (which must hold it: no nil test) and given back.
  0x23BD34, 0x3C bytes, no A5. }

procedure iv_utils_$delete_induction_addr(
    a: iv_addr_ptr_t); options(val_param); internal;
var
  p: ^iv_addr_ptr_t;
  x: iv_addr_ptr_t;
begin
  p := addr(a^.iexpr^.addrs);
  x := p^;
  while x <> a do begin
    p := addr(x^.next);
    x := x^.next;
  end;
  p^ := x^.next;
  free_induction_addr(a);
end;

{ free_induction_expr - x put on the free list.  0x23BD70, 0x10 bytes,
  no frame. }

procedure free_induction_expr(
    x: iv_iexpr_ptr_t); options(val_param); internal;
begin
  x^.next := iv_free_iexpr;
  iv_free_iexpr := x;
end;

{ create_induction_expr - an induction expression of e put first on
  class c's list, numbered one more than the one before it (1 for the
  first).  0x23BD80, 0x4C bytes, no A5. }

function create_induction_expr(
    c: iv_class_ptr_t;
    e: iv_expr_ptr_t): iv_iexpr_ptr_t; options(val_param); internal;
var
  x: iv_iexpr_ptr_t;
begin
  x := alloc_induction_expr;
  if c^.iexprs = nil then
    x^.num := 1
  else
    x^.num := c^.iexprs^.num + 1;
  x^.class := c;
  x^.expr := e;
  x^.next := c^.iexprs;
  c^.iexprs := x;
  create_induction_expr := x;
end;

{ create_induction_class - a class of variable v put last on v's list,
  numbered one more than the last (1 for the first).  0x23BDCC, 0x58
  bytes, no A5: frame 8:w 10:l. }

function create_induction_class(
    w16: integer;
    v: iv_var_ptr_t): iv_class_ptr_t; options(val_param); internal;
var
  c: iv_class_ptr_t;
begin
  c := alloc_induction_class;
  c^.ivar := v;
  c^.w16 := w16;
  c^.prev := v^.classes_last;
  if v^.classes = nil then begin
    v^.classes := c;
    c^.num := 1;
  end
  else begin
    v^.classes_last^.next := c;
    c^.num := v^.classes_last^.num + 1;
  end;
  v^.classes_last := c;
  create_induction_class := c;
end;

{ free_induction_class - c put on the free list.  0x23BE24, 0x10 bytes,
  no frame. }

procedure free_induction_class(
    c: iv_class_ptr_t); options(val_param); internal;
begin
  c^.next := iv_free_class;
  iv_free_class := c;
end;

{ create_induction_variable - a variable of kind for segment s in the
  loop iv_head: a primary (no parent) put last on iv_vars, a secondary
  last on its parent's children (its known flag the parent's); s given
  a kind 1 induction lts with a zero increment, known.  0x23BE34, 0xD0
  bytes, no A5. }

function create_induction_variable(
    s: lts_ptr_t;
    parent: iv_var_ptr_t;
    kind: integer): iv_var_ptr_t; options(val_param); internal;
var
  v: iv_var_ptr_t;
  l: iv_lts_ptr_t;
begin
  v := alloc_induction_variable;
  v^.lts := s;
  v^.head := iv_head;
  v^.parent := parent;
  v^.f48.kind := kind;
  if parent = nil then begin
    if iv_vars = nil then
      iv_vars := v
    else
      iv_vars_last^.next := v;
    iv_vars_last := v;
  end;
  if s <> nil then begin
    l := create_induction_lts(1, s, v);
    l^.incr := iv_utils_$create_value_expression(0);
    l^.step := nil;
    l^.h.known := true;
  end;
  if parent <> nil then begin
    v^.f48.known := parent^.f48.known;
    if parent^.l54 = nil then
      parent^.l54 := v
    else begin
      v^.l54 := parent^.children_last;
      parent^.children_last^.next := v;
    end;
    parent^.children_last := v;
  end;
  create_induction_variable := v;
end;

{ free_induction_variable - v put on the free list.  0x23BF04, 0x10
  bytes, no frame. }

procedure free_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
begin
  v^.next := iv_free_var;
  iv_free_var := v;
end;

{ iv_utils_$delete_induction_expr - x's instantiations and address modes
  deleted, its expression, and x taken off its class's list and given
  back.  0x23BF14, 0x9C bytes, no A5. }

procedure iv_utils_$delete_induction_expr(
    x: iv_iexpr_ptr_t); options(val_param); internal;
var
  l, ln, t: iv_lts_ptr_t;
  a, an: iv_addr_ptr_t;
  p: ^iv_iexpr_ptr_t;
  y: iv_iexpr_ptr_t;
begin
  l := x^.ltss;
  while l <> nil do begin
    ln := l^.next;
    t := l;
    iv_utils_$delete_induction_lts(t);
    l := ln;
  end;
  a := x^.addrs;
  while a <> nil do begin
    an := a^.next;
    iv_utils_$delete_induction_addr(a);
    a := an;
  end;
  if x^.expr <> nil then
    iv_utils_$delete_expression(x^.expr);
  p := addr(x^.class^.iexprs);
  y := p^;
  while y <> nil do begin
    if y = x then begin
      p^ := y^.next;
      exit;
    end;
    p := addr(y^.next);
    y := y^.next;
  end;
  free_induction_expr(x);
end;

{ iv_utils_$delete_induction_class - c's induction expressions deleted,
  c taken off its variable's list and given back.  0x23BFB0, 0x78
  bytes, no A5. }

procedure iv_utils_$delete_induction_class(
    c: iv_class_ptr_t); options(val_param); internal;
var
  x, xn: iv_iexpr_ptr_t;
  v: iv_var_ptr_t;
begin
  x := c^.iexprs;
  while x <> nil do begin
    xn := x^.next;
    iv_utils_$delete_induction_expr(x);
    x := xn;
  end;
  v := c^.ivar;
  if c^.next <> nil then
    c^.next^.prev := c^.prev;
  if c^.prev <> nil then
    c^.prev^.next := c^.next;
  if v^.classes = c then
    v^.classes := c^.next;
  if v^.classes_last = c then
    v^.classes_last := c^.prev;
  free_induction_class(c);
end;

{ iv_utils_$delete_induction_variable - v's classes and induction lts
  deleted; a secondary taken off its parent's children, a primary's
  children deleted and it taken off iv_vars; v given back.  0x23C028,
  0xEA bytes, no A5: recursive. }

procedure iv_utils_$delete_induction_variable(
    v: iv_var_ptr_t); options(val_param); internal;
var
  c, cn: iv_class_ptr_t;
  l, ln, t: iv_lts_ptr_t;
  pa, w, wn, prev: iv_var_ptr_t;
  p: ^iv_var_ptr_t;
begin
  c := v^.classes;
  while c <> nil do begin
    cn := c^.next;
    iv_utils_$delete_induction_class(c);
    c := cn;
  end;
  l := v^.ltss;
  while l <> nil do begin
    ln := l^.next;
    t := l;
    iv_utils_$delete_induction_lts(t);
    l := ln;
  end;
  pa := v^.parent;
  if pa <> nil then begin
    if pa^.l54 = v then
      pa^.l54 := v^.next
    else
      v^.l54^.next := v^.next;
    if pa^.children_last = v then
      pa^.children_last := v^.l54
    else
      v^.next^.l54 := v^.l54;
  end
  else begin
    w := v^.l54;
    while w <> nil do begin
      wn := w^.next;
      iv_utils_$delete_induction_variable(w);
      w := wn;
    end;
    prev := nil;
    p := addr(iv_vars);
    w := p^;
    while w <> nil do begin
      if w = v then begin
        p^ := w^.next;
        if iv_vars_last = w then
          iv_vars_last := prev;
        exit;
      end;
      prev := w;
      p := addr(w^.next);
      w := w^.next;
    end;
  end;
  free_induction_variable(v);
end;

{ interval_contains_bb - bb is in the interval headed by head (any
  block when head is nil): head is bb or reached up bb's interval heads
  (+70).  0x23C112, 0x2E bytes, no frame. }

function interval_contains_bb(
    bb: bb_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
begin
  if head = nil then
    interval_contains_bb := true
  else begin
    while (bb <> nil) and (bb <> head) do
      bb := bb^.l70;
    interval_contains_bb := bb <> nil;
  end;
end;

function operand_is_loop_invariant(
    o: opnd_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal; forward;

{ lts_is_loop_invariant - segment s (the final segment that reaches an
  exposed one) does not change in the loop headed by head: defined
  outside it, or by an instruction of a kind whose operands are
  invariant (a load of a literal pool constant of types 0, 3, 4, 7,
  10; an add, sub, rsub or muli; a neg, move, copys, mffp or mtfp; an
  lsl by an immediate).  0x23C140, 0x16C bytes, no A5: the opcodes
  compared one by one; recursive through operand_is_loop_invariant. }

function lts_is_loop_invariant(
    s: lts_ptr_t;
    head: bb_ptr_t): boolean; options(val_param); internal;
var
  i: instr_ptr_t;
  r: boolean;
begin
  if s^.f2.exposed then
    if s^.l44 <> nil then
      s := s^.l44;
  if not interval_contains_bb(s^.bb, head) then
    r := true
  else begin
    i := utils_ins_$operands_instruction(s^.refs);
    r := false;
    case i^.opc of
      106, 105:                         { loads, loadl }
        if s^.refs^.h.num = 3 then
          if i^.opnds[1].h.kind = operand$displacement_literal_pool then
            if iv_node_v_ptr_t(i^.opnds[1].link)^.w4 in [0, 3, 4, 7, 10] then
              r := true;
      178, 83, 138, 81, 137, 79:        { muli, rsub, subi, sub, addi, add }
        if s^.refs^.h.num = 3 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            if operand_is_loop_invariant(addr(i^.opnds[2]), head) then
              r := true;
      135, 77, 75, 144, 116, 126:       { negi, neg, move, copys, mffp, mtfp }
        if s^.refs^.h.num <> 1 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            r := true;
      92:                               { lsl }
        if s^.refs^.h.num <> 1 then
          if operand_is_loop_invariant(addr(i^.opnds[1]), head) then
            if i^.opnds[2].h.kind = operand$immediate then
              r := true;
      otherwise
        ;
    end;
  end;
  lts_is_loop_invariant := r;
end;

{ operand_is_loop_invariant - o (none, a constant, a like register, a
  displacement, ...) does not change in the loop headed by head; a
  register's segment by lts_is_loop_invariant, never a physical
  register's.  0x23C2AC, 0x6A bytes, no A5: masks 16#10FF7001, 126 and
  16#27000 (the last's kinds already taken by the first). }

function operand_is_loop_invariant;
var
  k: operand$t;
begin
  if o = nil then
    operand_is_loop_invariant := true
  else begin
    k := o^.h.kind;
    if k in [operand$none, operand$ip_reg_like..operand$fp_reg_pair_like,
             operand$flow_graph_edge..operand$immediate,
             operand$exception_information] then
      operand_is_loop_invariant := true
    else if k in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
      if o^.lts^.lr^.f2.physical then
        operand_is_loop_invariant := false
      else
        operand_is_loop_invariant := lts_is_loop_invariant(o^.lts, head);
    end
    else if k in [operand$ip_reg_like..operand$fp_reg_pair_like,
                  operand$case_jump_base] then
      operand_is_loop_invariant := true
    else
      operand_is_loop_invariant := false;
  end;
end;

{ find_definition - whether one definition of the live range reaches bb
  (from its marked blocks, l134 the segment, mark146 yes): a block
  without predecessors (or a predecessor reached by none) has none;
  blocks on the path marked no while searched, then yes with the
  definition (l134) when every predecessor reached gives the same one.
  0x23C316, 0xA4 bytes, no A5: recursive over the predecessors. }

function find_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    yes: integer32;
    no: integer32): boolean; options(val_param); internal;
label
  9;
var
  e: fg_edge_ptr_t;
  def, x: univ_ptr;
  none: boolean;
begin
  if bb^.mark146 = yes then begin
    find_definition := true;
    return;
  end;
  if bb^.mark146 = no then begin
    find_definition := false;
    return;
  end;
  if bb^.preds = nil then
    goto 9;
  bb^.mark146 := no;
  def := nil;
  none := true;
  e := bb^.preds;
  while e <> nil do begin
    if find_definition(lr, e^.source, yes, no) then begin
      none := false;
      x := e^.source^.l134;
      if x = nil then
        goto 9;
      if def = nil then
        def := x
      else if def <> x then
        goto 9;
    end;
    e := e^.next_pred;
  end;
  if none then begin
    bb^.mark146 := no;
    find_definition := false;
  end
  else begin
    bb^.mark146 := yes;
    bb^.l134 := def;
    find_definition := true;
  end;
  return;
9:
  bb^.l134 := nil;
  bb^.mark146 := yes;
  find_definition := true;
end;

{ iv_utils_$locate_definition - the one definition of live range lr
  that reaches bb, or nil: each block's first writing segment (by the
  live range's list) marked as its definition, then find_definition
  with two new marks.  0x23C3BA, 0x90 bytes, no A5. }

function iv_utils_$locate_definition(
    lr: lr_ptr_t;
    bb: bb_ptr_t): lts_ptr_t; options(val_param); internal;
var
  yes, no: integer32;
  s: lts_ptr_t;
  b: bb_ptr_t;
begin
  iv_rtn^.marks := iv_rtn^.marks + 1;
  yes := iv_rtn^.marks;
  iv_rtn^.marks := iv_rtn^.marks + 1;
  no := iv_rtn^.marks;
  s := lr^.ltss;
  b := nil;
  while s <> nil do begin
    if s^.bb <> b then
      if (integer(s^.rrp) & 12) <> 0 then begin
        b := s^.bb;
        b^.l134 := s;
        b^.mark146 := yes;
      end;
    s := s^.next;
  end;
  if find_definition(lr, bb, yes, no) then
    iv_utils_$locate_definition := bb^.l134
  else
    iv_utils_$locate_definition := nil;
end;

{ iv_utils_$create_expression_from_lts - the expression segment s (or the
  final segment that reaches it) holds, seen from the loop headed by
  head: what its defining instruction computes when that has a kind
  (iv_opc_set), its operands' expressions (a shift by a constant made a
  multiply by its power of 2; a move or transfer its operand's; nil
  when an operand has none), canonicalized; a literal pool constant's
  value; else the segment itself when it is defined outside the loop
  and is the one definition reaching head (always when head is nil);
  nil otherwise (a segment of the loop with no expression is a
  bug).  0x23C44A, 0x278 bytes. }

function iv_utils_$create_expression_from_lts;
var
  r, x: iv_expr_ptr_t;
  i: instr_ptr_t;
  k, n, j: integer32;
  ch: array [1..2] of iv_expr_ptr_t;
begin
  if s^.f2.exposed then
    if s^.l44 <> nil then
      s := s^.l44;
  r := nil;
  i := utils_ins_$operands_instruction(s^.refs);
  if (opnd_bytes_ptr_t(s^.refs)^.rrp & 12) <> 0 then
    if i^.opc in iv_opc_set then begin
      k := iv_opc_kind[i^.opc];
      n := iv_nchildren[k];
      if n > 0 then begin
        for j := 1 to n do
          ch[j] := nil;
        for j := 1 to n do begin
          x := iv_utils_$create_expression_from_operand(
                   addr(i^.opnds[iv_opnd_pos[k, j]]), head);
          if x = nil then
            exit;
          ch[j] := x;
        end;
        if x <> nil then
          case k of
            iv_shift:
              if ch[2]^.kind <> iv_value then
                x := nil
              else begin
                r := alloc_expression;
                for j := 1 to n do
                  r^.child[j] := ch[j];
                r^.kind := iv_mul;
                r^.right^.value := lshft(1, r^.right^.value);
              end;
            iv_transfer, iv_move:
              r := x;
            otherwise begin
              r := alloc_expression;
              r^.kind := k;
              for j := 1 to n do
                r^.child[j] := ch[j];
              r := iv_utils_$canonicalize_expression(r);
            end;
          end;
        if x = nil then
          for j := 1 to n do
            if ch[j] <> nil then
              iv_utils_$delete_expression(ch[j]);
      end
      else if s^.refs^.h.num = 3 then
        if i^.opnds[1].h.kind = operand$displacement_literal_pool then
          if iv_node_v_ptr_t(i^.opnds[1].link)^.w4 in [0, 3, 4, 7, 10] then
            r := iv_utils_$create_value_expression(
                     iv_node_v_ptr_t(i^.opnds[1].link)^.value);
    end;
  if r = nil then
    if head = nil then
      r := iv_utils_$create_lts_expression(s)
    else if interval_contains_bb(s^.bb, head) then
      bug_check('IV_$create_expression_from_lts: Unknown instruction type found%.')
    else if s^.f2.final then
      if iv_utils_$locate_definition(s^.lr, head) = s then
        r := iv_utils_$create_lts_expression(s);
  iv_utils_$create_expression_from_lts := r;
end;

{ iv_utils_$create_expression_from_operand - o's expression seen from the
  loop headed by head: an immediate a constant, an operand that does not
  change (operand_is_loop_invariant's first mask) itself, a register's
  segment's expression (times 2**scale), nil for a physical register
  or anything else.  0x23C702, 0xA8 bytes. }

function iv_utils_$create_expression_from_operand;
var
  k: operand$t;
  r: iv_expr_ptr_t;
  s: lts_ptr_t;
  c: integer32;
begin
  k := o^.h.kind;
  if k = operand$immediate then
    r := iv_utils_$create_value_expression(o^.value)
  else if k in [operand$none, operand$ip_reg_like..operand$fp_reg_pair_like,
                operand$flow_graph_edge..operand$immediate,
                operand$exception_information] then
    r := iv_utils_$create_operand_expression(o^)
  else if k in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    if o^.lts^.lr^.f2.physical then
      r := nil
    else begin
      s := o^.lts;
      if s^.f2.exposed then
        if s^.l44 <> nil then
          s := s^.l44;
      r := iv_utils_$create_expression_from_lts(s, head);
      if r <> nil then begin
        c := o^.h.count;
        if c <> 0 then
          r := iv_utils_$create_mul_expression(r,
                   iv_utils_$create_value_expression(lshft(1, c)));
      end;
    end;
  end
  else
    r := nil;
  iv_utils_$create_expression_from_operand := r;
end;

{ propagate_induction_increment - l (a segment o's instruction defines
  from the one with induction lts from) given from's known flag, step
  the expression of o (the operand added; negated for a subtraction),
  incr from's increment plus step.  0x23C7AA, 0xA6 bytes, no A5: frame
  8:a 12:a 16:l 20:b. }

procedure propagate_induction_increment(
    l: iv_lts_ptr_t;
    from: iv_lts_ptr_t;
    o: opnd_ptr_t;
    neg: boolean); options(val_param); internal;
var
  x, y: iv_expr_ptr_t;
begin
  l^.h.known := from^.h.known;
  l^.incr := nil;
  l^.step := nil;
  if o <> nil then begin
    x := iv_utils_$create_expression_from_operand(o, iv_head);
    if neg then
      x := iv_utils_$canonicalize_expression(
               iv_utils_$create_neg_expression(x));
    l^.step := x;
  end;
  if from^.h.known then begin
    y := iv_utils_$duplicate_expression(from^.incr);
    if o <> nil then
      y := iv_utils_$canonicalize_expression(
               iv_utils_$create_add_expression(y,
                   iv_utils_$duplicate_expression(x)));
    l^.incr := y;
  end;
end;
