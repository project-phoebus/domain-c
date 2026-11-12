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
    (+0x630), iv_opnd_pos (+0x650), iv_ip_opc and iv_fp_opc (+0x688,
    +0x6A2), iv_nchildren (+0x6C0), the six heaps (+0x6E0 .. +0x758),
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

var
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

  { +0x688, +0x6A2: the opcode that computes an expression of each kind
    in an integer register (neg, add, sub, -, rsub, mffp, move, loadl,
    lsl) and in a floating one (negi, addi, subi, muli, -, mtfp, copys,
    loads). }
  iv_ip_opc: array [0..12] of integer := [
    0, 0, 0, 0, 77, 79, 81, 0, 83, 116, 75, 105, 92];
  iv_fp_opc: array [0..12] of integer := [
    0, 0, 0, 0, 135, 137, 138, 178, 0, 126, 144, 106, 0];

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
  iv_free_class: univ_ptr;              { +0x778 (chained at +8) }
  iv_free_iexpr: univ_ptr;              { +0x77C (+8) }
  iv_free_addr: univ_ptr;               { +0x780 (+16) }
  iv_free_lts: univ_ptr;                { +0x784 (+16) }
  iv_free_var: univ_ptr;                { +0x788 (+50) }
  iv_free_expr: iv_expr_ptr_t;          { +0x7B0 (+12) }

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
                       iv_ip_opc[e^.kind], univ_ptr(pos)) then
              if (pos <> 1) and (iv_commuted[e^.kind] <> 0)
                  and first_operand_can_change(e)
                  and lir_$can_encode_as_immediate_operand(c^.value,
                          iv_ip_opc[iv_commuted[e^.kind]], univ_ptr(1)) then begin
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
