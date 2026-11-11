{ c_expr_sem - the expression semantics: the expression stack
  (cexs_stack, cexs_23bc its top) on which the parser (c_expr_syn)
  pushes operands (body_opr: names, members, dereferences, constants,
  strings) and which expr_op reduces by the operators, checking and
  converting the operands' types (coerce, the usual arithmetic
  conversions) and building the IL tree nodes (add_tn, add_pn, add_dn,
  ...) of the result; the builtin functions' trees; the parameters'
  adjustments of a call (adjust_parm) and the test of a condition
  against zero (test_ne_zero).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries,
  its code 0x280 higher in cc.a88k):
    cc.m68k   cc.a88k
    0x049BB8  0x049E38  init_exp_tbl
    0x049C0A  0x049E8A  init_aux
    0x049CAE  0x049F2E  get_oc
    0x049D36  0x049FB6  adjust_length
    0x049E70  0x04A0F0  float_operand
    0x04A678  0x04A8F8  coerce
    0x049FA0  0x04A220  common_enum_code
    0x04A060  0x04A2E0  common_integer_code
    0x04A170  0x04A3F0  pointer_and_integer_or_enum
    0x04A23E  0x04A4BE  pointer_to_pointer
    0x04A3A0  0x04A620  real_to_integer_or_enum
    0x04A4AA  0x04A72A  real_to_real
    0x04A9C0  0x04AC40  reference_operand
    0x04B5E0  0x04B860  body_opr
    0x04B078  0x04B2F8  find_field
    0x04B19A  0x04B41A  find_field_member
    0x04B0CA  0x04B34A  find_field_partial
    0x04B2F6  0x04B576  exposed_member
    0x04B39C  0x04B61C  select_field
    0x04B462  0x04B6E2  stack_operand
    0x04BB14  0x04BD94  scl_cmp
    0x04BC90  0x04BF10  push_con
    0x04BCD0  0x04BF50  push_fcon
    0x04BD74  0x04BFF4  swap_top
    0x04CDBA  0x04D03A  expr_op
    0x04BDD6  0x04C056  boolean_result
    0x04BE2E  0x04C0AE  do_coerce
    0x04C448  0x04C6C8  double_coerce
    0x04BFD0  0x04C250  fixup_bounds
    0x04C06A  0x04C2EA  coerce_as_usual
    0x04C136  0x04C3B6  coerce_dominant
    0x04C242  0x04C4C2  value_preserve
    0x04C61A  0x04C89A  mult_div_mod_prep
    0x04C6BA  0x04C93A  mult_div_mod_sign
    0x04C72C  0x04C9AC  power_of_two
    0x04C91E  0x04CB9E  build_builtin_tree
    0x04C85A  0x04CADA  de_ref
    0x04CC5A  0x04CEDA  result_signedness
    0x04CD6A  0x04CFEA  check_for_out_of_bounds
    0x04CCAC  0x04CF2C  get_number_of_elements
    0x04F974  0x04FBF4  adjust_parm
    0x04FA40  0x04FCC0  test_ne_zero
    0x04FC62  0x04FEE2  adjust_blk_for_db
    A5 0x1400B0 (cc.m68k), 0x2C00B0 (cc.a88k), 0x23C0 bytes, all
    initialized: twelve words (+0x0) and four limits (+0x18), the
    operand classes (eleven sets of node kinds, +0x28), the operators'
    table (+0x172), the expression stack (128 entries of 64 bytes from
    +0x390), the basic types (+0x2390..+0x23B8, c_globals.ins.pas), the
    stack's top (+0x23BC) and a flag (+0x23BE).

  The routines other units call load A5; get_oc, adjust_length,
  float_operand, reference_operand, scl_cmp and swap_top do not and are
  internal (they reach the module's data on their callers' A5).  The
  nested routines come before their parents in the image: coerce's six
  (which take coerce's frame from their dynamic link, docs/rev889-
  patterns.md 25), body_opr's six (find_field_partial nested in
  find_field_member), expr_op's ten (fixup_bounds, coerce_as_usual,
  coerce_dominant and value_preserve nested in double_coerce, de_ref in
  build_builtin_tree, get_number_of_elements in
  check_for_out_of_bounds).

  The stack's entries are c_objtype.ins.pas's c_exp_t; Rev 8.89
  addresses entry k's fields from A5 + 64k + 0x390 (the next entry) at
  negative displacements (-64 node, -36 the type, -20 its size, -6 the
  line).

  dpc gaps (docs/dpc-gaps.md): 6 and 7 (the real conversions and
  constants of float_operand, real_to_real, push_fcon, test_ne_zero), 8
  (`in' on the node kinds' and operators' constant sets), 14 (expr_op's
  nested routines leave by goto 99), 25 (expr_op exceeds dpc's virtual
  registers: its cases from subtraction on are left out of the check).

  Probable slips of the original kept (docs/questions.md 60): expr_op's
  `?:' reads entry ib + 1's bounds; check_for_out_of_bounds flags a
  subscript past the end.
}
module c_expr_sem;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/fpp.ins.pas';
%include '/sys/ins/fpp.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';

define
  cexs_stack;                           { +0x390 (c_globals.ins.pas) }
  char_type;                            { +0x2390 }
  short_type;                           { +0x2394 }
  int_type;                             { +0x2398 }
  uchar_type;                           { +0x239C }
  ushort_type;                          { +0x23A0 }
  uint_type;                            { +0x23A4 }
  float_type;                           { +0x23A8 }
  double_type;                          { +0x23AC }
  void_type;                            { +0x23B0 }
  cexs_23b4;                            { +0x23B4 }
  cexs_23b8;                            { +0x23B8 }
  cexs_23bc;                            { +0x23BC }

type
  { An operand class: a set of type node kinds (30 bytes, `btst' with
    the byte index (239 - kind) div 8). }
  kind_set_t = set of 0..239;

  { The bytes of a c_desc_t (init_aux clears them one by one). }
  desc_bytes_t = array [1..16] of char;
  desc_bytes_ptr_t = ^desc_bytes_t;

  { A length compared zero-extended (adjust_length). }
  ulen_t = 0..65535;

  { Views for expr_op's address of a function: the 20 bytes of
    attributes copied from a block's +312 to a declaration's +12, a
    block's flags at +374 read as a longword. }
  attr20_t = array [1..5] of integer32;
  attr20_ptr_t = ^attr20_t;
  int32_ptr_t = ^integer32;

  { An operator's entry in op_tab (8 bytes). }
  op_t = record
    left: integer;                      { +0: the first operand's class
                                          (exp_class), 0 none }
    right: integer;                     { +2: the second's }
    tnop: integer;                      { +4: the tree operator (add_tn) }
    coerce: boolean;                    { +6: convert to a common type }
    b7: boolean;                        { +7 }
  end;

{ ARITH - lang2/source/lt_utils/source/arith.pas (cc.m68k 0x075350):
  op 0 add, 2 multiply, saturating.  c_expr_sem opens no insert that
  declares it (arith.ins.pas is not in its list), so it is declared
  here, the operation a word. }
function arith(
    op: integer;
    a: integer32;
    b: integer32): integer32; options(val_param); extern;

var
  cexs_cond: array [0..11] of integer := [7, 6, 15, 12, 13, 14, 7, 6, 3, 4, 5, 2];
                                        { +0x0: the condition codes of
                                          the comparisons 0..5 (==, !=,
                                          <=, >=, <, >; scl_cmp,
                                          expr_op), signed (EQ, NE, LE,
                                          GE, LT, GT), then unsigned at
                                          +6 (EQ, NE, LS, CC, CS, HI) }
  cexs_limits: array [1..4] of integer32 := [127, 32767, 255, 65535];
                                        { +0x18: the greatest values of
                                          char, short, unsigned char and
                                          unsigned short (no reference
                                          in the unit) }
  exp_class: array [1..11] of kind_set_t := [
    [73, 122..123, 126, 129..130, 132, 134, 136],
    [73, 122..123, 126, 129..130, 134, 136],
    [73, 122..123, 126, 129..130],
    [73, 122, 129],
    [73, 134],
    [73, 122..123, 129],
    [73, 122, 129],
    [73, 122..123, 129..130],
    [73, 122..123, 129, 134, 136],
    [73, 122..123, 129..130],
    [73, 123]];
                                        { +0x28: the operand classes
                                          (op_tab's left and right): 73
                                          and the type kinds allowed }
  op_tab: array [0..65] of op_t := [
    [1, 1, 12, true, false], [1, 1, 12, true, false], [2, 2, 12, true, false],
    [2, 2, 12, true, false], [3, 3, 12, true, false], [3, 3, 12, true, false],
    [4, 5, 11, false, false], [0, 0, 25, false, false], [10, 10, 1, false, false],
    [10, 10, 2, false, false], [0, 0, 0, false, false], [9, 9, 3, false, false],
    [6, 6, 4, false, false], [0, 0, 0, false, false], [7, 7, 6, false, false],
    [0, 0, 0, false, false], [8, 0, 57, false, false], [0, 0, 0, false, false],
    [0, 0, 16, false, false], [0, 0, 13, false, false], [6, 0, 0, false, false],
    [6, 0, 7, false, false], [0, 0, 0, false, false], [0, 0, 0, false, false],
    [0, 0, 51, true, false], [8, 8, 52, false, false], [8, 8, 53, false, false],
    [0, 0, 0, false, false], [0, 0, 0, false, false], [7, 7, 27, true, false],
    [7, 7, 28, true, false], [7, 7, 27, true, false], [0, 0, 41, false, false],
    [7, 7, 9, true, false], [7, 7, 10, true, false], [0, 0, 0, false, false],
    [7, 7, 28, true, false], [0, 0, 41, false, false], [0, 0, 41, false, false],
    [0, 0, 41, false, false], [0, 0, 41, false, false], [0, 0, 41, false, false],
    [0, 0, 41, false, false], [7, 7, 28, true, false], [0, 0, 0, false, false],
    [7, 7, 44, true, false], [7, 0, 8, true, false], [9, 9, 3, false, false],
    [0, 0, 0, false, false], [10, 10, 1, false, false], [10, 10, 2, false, false],
    [0, 0, 41, false, false], [0, 0, 41, false, false], [0, 0, 41, false, false],
    [0, 0, 42, false, false], [0, 0, 0, false, false], [0, 0, 0, false, false],
    [0, 0, 0, false, false], [0, 0, 0, false, false], [0, 0, 0, false, false],
    [0, 0, 0, false, false], [0, 0, 0, false, false], [0, 0, 0, false, false],
    [0, 0, 0, false, false], [0, 0, 0, false, false], [0, 0, 0, false, false]];
                                        { +0x172: by expr_op's
                                          operator: the operands'
                                          classes, the tree operator,
                                          whether the operands are
                                          converted to a common type.
                                          59 entries reach +0x350 (the
                                          stack's unused entry 0); the
                                          builtins' codes 60..65 read on
                                          into it (zeros) }
  cexs_23be: boolean;                   { +0x23BE: set by coerce when an
                                          enumeration is converted
                                          (diagnostic 205) }

{ init_exp_tbl - under -ANSI (cargs_$options.ansi) structures (132)
  are not of the first operand class.

  0x049BB8, 0x34 bytes, link #0: the first set and-ed with the
  complement of [132] (`moveq #6; dbf' of `and.l', then `and.w', the
  constant after the routine, its word 12 0xFFEF).

  Not known from the original:
  - the names. }

procedure init_exp_tbl;
begin
  if cargs_$options.ansi then
    exp_class[1] := exp_class[1] - [132];
end;

{ init_aux - d is the descriptor of a value of type t: its size,
  register class (get_rlen), whether it is an array (127) and, for an
  integral type, whether it is one of the signed basic types (char,
  short, int, float, double).

  0x049C0A, 0xA4 bytes, link #-4: the 16 bytes cleared by a `dbf' loop
  of `clr.b (-1,A3,D1.w)' from 1; the flags stored with `seq', `lsr.b
  #7', `lsl.b #2' into +10 bit 2, `bset'/`bclr' #6; the kind tested
  for 127 again inside the test for 122 (never true).

  Not known from the original:
  - the names. }

procedure init_aux;
var
  b: desc_bytes_ptr_t;
  i: integer;
begin
  b := addr(d);
  for i := 1 to 16 do
    b^[i] := chr(0);
  d.rlen := get_rlen(t);
  d.flags.b2 := t.base^.kind = 127;
  with t.base^ do
    if kind = 122 then
      d.flags.b6 := (kind = 127) or (t.base = double_type) or
                    (t.base = float_type) or (t.base = int_type) or
                    (t.base = char_type) or (t.base = short_type);
  d.size := t.size;
end;

{ get_oc - the operand class of entry k's type: 5 floating (123), 4 an
  array of kind 127, 3 or 4 another array or a structure (131, 132:
  up to 4 bytes or more), 1 or 2 a set or kind 136 (up to 4 bytes or
  more), else 0.

  0x049CAE, 0x88 bytes, link #-12: the size read first; a jump table
  on kind - 123 (`cmpi.w #14; bcc'); the result in D0.

  Not known from the original:
  - the names. }

function get_oc(
    k: integer): integer; options(val_param); internal;
var
  size: integer32;
begin
  with cexs_stack[k] do begin
    size := typ.size;
    case typ.base^.kind of
      123: get_oc := 5;
      127: get_oc := 4;
      131, 132:
        if size <= 4 then
          get_oc := 3
        else
          get_oc := 4;
      134, 136:
        if size <= 4 then
          get_oc := 1
        else
          get_oc := 2;
      otherwise
        get_oc := 0;
    end;
  end;
end;

{ adjust_length - widen entry k's integral or enumeration operand to
  len bytes (1 char, 2 short, else int; unsigned unless the type is
  signed), or narrow it when mode is 1: coerce to the basic type, then
  the entry keeps its own type node, qualifiers (b25_5, b25_4) and, for
  an integer constant (80..82), its bounds.

  0x049D36, 0x13A bytes, link #-76: len zero-extended (`clr.l; move.w')
  and compared with the size (`bgt', `beq'); coerce's result not read.

  Not known from the original:
  - the names; why coerce's result is ignored. }

procedure adjust_length(
    k: integer;
    mode: integer;
    len: ulen_t); options(val_param); internal;
var
  tt: type_exp_t;                       { -64 }
  saved: type_exp_t;                    { -32 }
  t: c_type_ptr_t;
  sgn: boolean;
begin
  with cexs_stack[k] do
    if (len > typ.size) or ((len <> typ.size) and (mode = 1)) then begin
      t := typ.base;
      if t^.kind = 122 then
        sgn := t^.signed
      else if t^.kind = 129 then
        sgn := t^.enum_int^.signed
      else
        sgn := true;
      if len = 1 then
        if sgn then t := char_type else t := uchar_type
      else if len = 2 then
        if sgn then t := short_type else t := ushort_type
      else
        if sgn then t := int_type else t := uint_type;
      type_exp(t, addr(tt));
      saved := typ;
      typ.base := t;
      discard(coerce(tt, k, true));
      typ.base := saved.base;
      typ.flags.b25_5 := saved.flags.b25_5;
      typ.flags.b25_4 := saved.flags.b25_4;
      if (node^.kind = 80) or (node^.kind = 82) or (node^.kind = 81) then begin
        typ.low := saved.low;
        typ.high := saved.high;
      end;
    end;
end;

{ float_operand - convert entry k's integral or enumeration operand to
  the floating type t: an integer constant (80..82) becomes a real
  constant (rlcontk for a float, dpcontk), anything else is widened to
  2 or 4 bytes (4 for an unsigned short) and converted (add_tn 39, the
  source's size in the descriptor's +6, its signedness in bit 6).

  0x049E70, 0x130 bytes, link #-52: the constant's value converted by
  `jsr fpp_$' (operation words 0x00C4 0x0080: a longword to a double)
  into -52 and copied to -16.

  Not known from the original:
  - the names. }

procedure float_operand(
    k: integer;
    t: c_type_ptr_t); options(val_param); internal;
var
  tmp: double;                          { -52 }
  len: integer;                         { -38 }
  desc: c_desc_t;                       { -32 }
  r: double;                            { -16 }
  size: integer32;
  sgn: boolean;
begin
  with cexs_stack[k] do
    if (typ.base^.kind = 122) or (typ.base^.kind = 129) then
      if (node^.kind = 80) or (node^.kind = 82) or (node^.kind = 81) then begin
        r := node^.int_value;
        if t^.len = 6 then
          node := rlcontk(r)
        else
          node := dpcontk(r);
        type_exp(t, addr(typ));
      end
      else begin
        len := 2;
        if typ.base^.kind = 129 then
          sgn := typ.base^.enum_int^.signed
        else
          sgn := typ.base^.signed;
        if not sgn and (typ.base^.len = 2) then
          len := 4;
        adjust_length(k, 0, len);
        size := typ.size;
        type_exp(t, addr(typ));
        init_aux(desc, typ);
        desc.w6 := size;
        desc.flags.b6 := sgn;
        add_tn(39, desc, k, k);
      end;
end;

{ coerce - convert entry k's operand to the type t: true when it could
  be (the types the same, or one of them il_178, or a conversion
  exists); else the entry's type becomes il_178.  A conversion leaves a
  tree node of operator op (18 an integral conversion, 39 a floating
  one) over the operand (add_tn) and the entry's size t's; the entry
  takes t's type.  check makes pointer conversions check alignment and
  qualifiers (diagnostics 242, 249, 279, 297, 80).  cexs_23be is set
  when an enumeration is converted.

  0x04A678, 0x348 bytes, link #-188: the cases jump tables on kind -
  122 (`cmpi.w #9; bcc') for the same types (122, 129), the target
  (122, 123, 129, 130) and the source; for a pointer target and a
  floating one the source's kinds compared in turn (129, 122, 130;
  129, 122, 123); the integral target's unsigned source and signed
  target (unless -XANSI, cargs_$options.xansi) take the unsigned type
  of the same length (traditional C's unsigned preservation).  The
  copies of t into the entry are 26 bytes (six `move.l' and a `move.w').

  Not known from the original:
  - the names. }

function coerce;
var
  d: double;                            { -8 }
  crec: pfm_$cleanup_rec;               { -72 }
  desc: c_desc_t;                       { -88 }
  tt: type_exp_t;                       { -120 }
  r: real;                              { -156 }
  status: status_$t;                    { -160 }
  p: c_type_ptr_t;                      { -164 }
  op: integer;                          { -166 }
  overflow: boolean;                    { -172 }
  sgn: boolean;                         { -176 }
  ok: boolean;                          { -180 }
  tsgn: boolean;

{ common_enum_code - the conversion of entry top's operand to an
  enumeration (or from one) of another size: none for a constant
  (80..86, 200), else operator 18 with the source's size and
  signedness.

  0x049FA0, 0xA6 bytes, link #-8; coerce's frame from (A6).  The
  constant kinds are `btst' on a 26-byte set (docs/dpc-gaps.md 8).

  Not known from the original:
  - the names. }

procedure common_enum_code;
begin
  with cexs_stack[top] do begin
    if not (node^.kind in [80..86, 200]) then begin
      desc.w6 := typ.size;
      if typ.base^.kind = 129 then
        desc.flags.b6 := typ.base^.enum_int^.signed
      else if typ.base^.kind = 122 then
        desc.flags.b6 := typ.base^.signed
      else if typ.base^.kind = 130 then
        desc.flags.b6 := false;
      op := 18;
    end;
    ok := true;
  end;
end;

{ common_integer_code - an integral conversion between sizes: unless
  the operand is a constant, a tree node of operator 18 to the basic
  type of t's size and the source's signedness, made here (add_tn).

  0x04A060, 0x110 bytes, link #-8; coerce's frame from (A6) (its sgn
  holds the source's signedness; its tt the basic type, not set for a
  size other than 1, 2 or 4).

  Not known from the original:
  - the names. }

procedure common_integer_code;
begin
  with cexs_stack[top] do begin
    if not (node^.kind in [80..86, 200]) then begin
      sgn := typ.base^.signed;
      case t.size of
        1: if sgn then type_exp(char_type, addr(tt))
           else type_exp(uchar_type, addr(tt));
        2: if sgn then type_exp(short_type, addr(tt))
           else type_exp(ushort_type, addr(tt));
        4: if sgn then type_exp(int_type, addr(tt))
           else type_exp(uint_type, addr(tt));
        otherwise ;
      end;
      init_aux(desc, tt);
      desc.w6 := typ.size;
      desc.flags.b6 := sgn;
      add_tn(18, desc, top, top);
      op := 0;
    end;
    ok := true;
  end;
end;

{ pointer_and_integer_or_enum - a pointer to an integer or the reverse:
  a pointer's register class (5) taken as an integer's (4); of another
  size, a constant takes t's size, else operator 18.

  0x04A170, 0xCE bytes, link #-8; coerce's frame from (A6).

  Not known from the original:
  - the names. }

procedure pointer_and_integer_or_enum;
begin
  with cexs_stack[top] do begin
    if desc.rlen = 5 then
      desc.rlen := 4;
    if typ.size <> t.size then
      if node^.kind in [80..86, 200] then
        typ.size := t.size
      else begin
        desc.w6 := typ.size;
        if typ.base^.kind = 129 then
          desc.flags.b6 := typ.base^.enum_int^.signed
        else if typ.base^.kind = 122 then
          desc.flags.b6 := typ.base^.signed
        else if typ.base^.kind = 130 then
          desc.flags.b6 := false;
        op := 18;
      end;
    ok := true;
  end;
end;

{ pointer_to_pointer - a pointer to another pointer type: when the
  alignment checks apply ((6 in cpu) <> alnchk) a pointer to a more
  strictly aligned type is diagnosed (249 from a pointer to char,
  unsigned char or void, else 242); with check, dropping const (19) or
  volatile (0) is diagnosed (279, 297), and incompatible pointed-to
  types (check_types; 80).

  0x04A23E, 0x162 bytes, link #-8; coerce's frame from (A6); the
  alignments are the pointer types' attribute words at +20.

  Not known from the original:
  - the names. }

procedure pointer_to_pointer;
begin
  with cexs_stack[top] do begin
    if (6 in cargs_$options.cpu) <> cargs_$options.alnchk then
      if t.base^.ptr_attr.align > typ.base^.ptr_attr.align then begin
        p := def_drop_tnames(typ.base^.ptr_to);
        if (p = char_type) or (p = uchar_type) or (p^.kind = 210) then
          error1(249, line, sym)
        else
          error1(242, line, sym);
      end;
    if check and (19 in typ.base^.ptr_attr.bits) and
       not (19 in t.base^.ptr_attr.bits) then
      error1(279, line, sym);
    if check and (0 in typ.base^.ptr_attr.bits) and
       not (0 in t.base^.ptr_attr.bits) then
      error1(297, line, sym);
    if check then
      if not check_types(t.base, typ.base, true) then
        error1(80, cexs_stack[top].line, cexs_stack[top].sym);
    ok := true;
  end;
end;

{ real_to_integer_or_enum - a floating operand to an integral type:
  operator 39 to t (the source's class in +6, t's signedness); to a
  type shorter than an int, first 39 to int (made here), then 18.

  0x04A3A0, 0x10A bytes, link #-4; coerce's frame from (A6).

  Not known from the original:
  - the names. }

procedure real_to_integer_or_enum;
begin
  if t.size < 4 then begin
    type_exp(int_type, addr(tt));
    init_aux(desc, tt);
    desc.w6 := get_rlen(cexs_stack[top].typ);
    desc.flags.b6 := t.base^.signed;
    add_tn(39, desc, top, top);
    op := 18;
    init_aux(desc, t);
    desc.w6 := 4;
  end
  else begin
    op := 39;
    desc.flags.b6 := t.base^.signed;
    desc.w6 := get_rlen(cexs_stack[top].typ);
  end;
  cexs_stack[top].typ := t;
  ok := true;
end;

{ real_to_real - between the floating types: a double constant (89)
  becomes a single one, converted under a clean-up handler (an
  overflow, a fault of subsystem 5 or 0, is diagnostic 19 with the
  fault's text, then the conversion is left to run time); a single
  constant (88) becomes a double one; anything else is operator 39.

  0x04A4AA, 0x1BE bytes, link #-24; coerce's frame from (A6) (the
  clean-up record at -72, status -160, the flag -172, the single -156,
  the double -8).  The conversions are `jsr fpp_$' (0x0074 0x00D4
  0xFF3E, a double to a single, through -16) and `jsr fpp_$eslv' (0x00D8
  0x0080, through -24); error_$print_format(status, 2, '?', 'compiler',
  8, '%$').  The subsystem is kept in a frame word (-10).

  Not known from the original:
  - the names. }

procedure real_to_real;
var
  subsys: integer;
begin
  with cexs_stack[top] do begin
    if node^.kind = 89 then begin
      overflow := false;
      status := pfm_$cleanup(crec);
      if status.all <> pfm_$cleanup_set then begin
        subsys := status.subsys;
        if (subsys = 5) or (subsys = 0) then begin
          pfm_$enable;
          cgerr(19, cexs_stack[top].line, cexs_stack[top].node);
          error_$print_format(status, 2, '?', 'compiler', 8, '%$');
          overflow := true;
        end
        else
          pfm_$signal(status);
      end;
      if overflow then begin
        op := 39;
        desc.w6 := get_rlen(typ);
        desc.flags.b6 := true;
      end
      else begin
        r := node^.real_value;
        pfm_$rls_cleanup(crec, status);
        d := r;
        node := rlcontk(d);
        ok := true;
      end;
    end
    else if node^.kind = 88 then
      node := dpcontk(node^.real_value)
    else begin
      op := 39;
      desc.w6 := get_rlen(typ);
      desc.flags.b6 := true;
    end;
    typ := t;
    ok := true;
  end;
end;

begin { coerce }
  cexs_23be := false;
  op := 0;
  init_aux(desc, t);
  with cexs_stack[top] do begin
    if (t.base = c_type_ptr_t(il_178)) or (typ.base = c_type_ptr_t(il_178)) then
      ok := true
    else begin
      ok := t.base = typ.base;
      if ok then
        case t.base^.kind of
          122: begin
            if typ.size <> t.size then
              common_integer_code;
            typ := t;
          end;
          129: begin
            if typ.size <> t.size then
              common_enum_code;
            typ := t;
          end;
          otherwise ;
        end
      else
        case t.base^.kind of
          122:
            case typ.base^.kind of
              122: begin
                sgn := typ.base^.signed;
                tsgn := t.base^.signed;
                if typ.size <> t.size then
                  common_integer_code
                else
                  ok := true;
                typ := t;
                if not sgn and tsgn and not cargs_$options.xansi then
                  if typ.base = int_type then
                    typ.base := uint_type
                  else if typ.base = short_type then
                    typ.base := ushort_type
                  else
                    typ.base := uchar_type;
              end;
              123: real_to_integer_or_enum;
              129: begin
                if typ.size <> t.size then
                  common_enum_code
                else
                  ok := true;
                typ := t;
              end;
              130: pointer_and_integer_or_enum;
              otherwise ;
            end;
          123:
            case typ.base^.kind of
              129: begin
                cexs_23be := true;
                float_operand(top, t.base);
                op := 0;
                typ := t;
                ok := true;
              end;
              122: begin
                float_operand(top, t.base);
                op := 0;
                typ := t;
                ok := true;
              end;
              123: real_to_real;
              otherwise ;
            end;
          129:
            case typ.base^.kind of
              122: begin
                if typ.size <> t.size then
                  common_enum_code
                else
                  ok := true;
                typ := t;
              end;
              123: begin
                cexs_23be := true;
                real_to_integer_or_enum;
              end;
              129: begin
                cexs_23be := true;
                if typ.size <> t.size then
                  common_enum_code
                else
                  ok := true;
                typ := t;
              end;
              130: begin
                cexs_23be := true;
                pointer_and_integer_or_enum;
              end;
              otherwise ;
            end;
          130:
            case typ.base^.kind of
              129: begin
                cexs_23be := true;
                pointer_and_integer_or_enum;
              end;
              122: pointer_and_integer_or_enum;
              130: pointer_to_pointer;
              otherwise ;
            end;
          otherwise ;
        end;
      if op <> 0 then begin
        add_tn(op, desc, top, top);
        typ.size := t.size;
      end;
    end;
  end;
  coerce := ok;
  if not ok then
    cexs_stack[top].typ.base := c_type_ptr_t(il_178);
end;

{ reference_operand - make the top entry's node reference its operand
  (mode 1: an address is wanted, 2: an indexed reference may be
  formed): a variable whose address is pending gets it from its
  allocation (get_addr_con, get_xdynm_ptr); a displacement beyond
  +-32700 or a pending index makes the node an address (a dynamic
  variable through the frame pointer nodes il_node_211, il_node_153
  and il_node_154, a 146's operand, an address operator 26); an
  indexed node (145) out of the short displacement range is unfolded
  into its address plus index (times its element size); a pending
  index becomes an indexed node (add_dindexn) or an addition; then,
  unless mode is 1, the displacement, the dereference (add_pn), the
  dynamic base (add_sdn) and the remaining displacement (add_dn, or
  folded into a 146's constant) are applied.

  0x04A9C0, 0x69E bytes, link #-84: attr_check_align(the top) first;
  the entry addressed once (A2 = A5 + 64k + 0x390); a jump table on the
  allocation - 1 (`cmpi.w #11; bcc'), vat_stat and vat_extdef with the
  same code twice; `btst D3,cpu' with D3 the cleared flag for `6 in
  cpu' (docs/rev889-patterns.md 24); the processors [2, 4, 8, 9, 10]
  as `andi.w #0x3FFC; lsr.w #2; andi.w #0x714' of the word at +0x284;
  the tree kinds of a node whose bit 8 (c_tree_t's post) is passed on
  are `btst' on a 26-byte set (docs/dpc-gaps.md 8); the element size
  (+40) zero-extended for push_con.

  Not known from the original:
  - the names; why vat_stat and vat_extdef were compiled twice. }

procedure reference_operand(
    mode: integer); options(val_param); internal;
var
  desc2: c_desc_t;                      { -24 }
  desc: c_desc_t;                       { -40 }
  off: integer32;                       { -48 }
  len: integer;                         { -62 }
  v: c_sym_ptr_t;
  n: il_$node_ptr_t;
  sub: il_$node_ptr_t;
  hit: boolean;
  fold: boolean;
begin
  attr_check_align(cexs_23bc);
  with cexs_stack[cexs_23bc] do begin
    if bits.var_pending and (node^.kind = 109) then begin
      bits.var_pending := false;
      v := c_sym_ptr_t(node);
      case v^.var_vat of
        vat_stat, vat_extdef:
          if c_blk_ptr_t(v^.block)^.data_sect <>
             c_blk_ptr_t(il_180)^.data_sect then begin
            bits.is_addr := true;
            offset := offset + v^.var_offset;
            node := get_addr_con(10, c_blk_ptr_t(v^.block)^.data_sect,
                                 offset, c_blk_ptr_t(il_180)^.data_sect,
                                 false);
          end;
        vat_param:
          bits.is_addr := true;
        vat_ext: begin
          bits.is_addr := true;
          off := offset;
          node := get_addr_con(2, il_$node_ptr_t(v), off,
                               c_blk_ptr_t(il_180)^.data_sect, false);
          offset := off;
        end;
        vat_sect: begin
          bits.is_addr := true;
          offset := offset + v^.var_offset;
          node := get_addr_con(3, v^.var_sect, offset,
                               c_blk_ptr_t(il_180)^.data_sect, false);
        end;
        vat_xstat, vat_xextdef: begin
          bits.is_addr := true;
          offset := offset + v^.var_offset;
          node := get_addr_con(1, c_blk_ptr_t(v^.block)^.data_sect,
                               offset, c_blk_ptr_t(il_180)^.data_sect,
                               false);
        end;
        vat_xdynm: begin
          bits.is_addr := true;
          offset := offset + v^.var_offset;
          node := get_xdynm_ptr(il_$node_ptr_t(cdef_50), offset);
        end;
        otherwise ;
      end;
    end;

    hit := false;
    if not bits.is_addr then begin
      fold := false;
      if (offset > 32700) or (index <> nil) or (offset < -32700) then begin
        n := node;
        v := c_sym_ptr_t(n);
        if (n^.kind = 109) and (v^.var_vat <> vat_abs) then begin
          if v^.var_vat = vat_dynm then begin
            if 6 in cargs_$options.cpu then begin
              base := n;
              if v^.var_offset > 0 then
                node := il_node_211
              else
                node := il_node_153;
            end
            else begin
              if (v^.var_offset > 0) and
                 (cargs_$options.cpu * [2, 4, 8, 9, 10] <> []) then
                base := n
              else
                offset := offset + v^.var_offset;
              node := il_node_153;
            end;
          end
          else begin
            offset := offset + v^.var_offset;
            node := il_node_154;
          end;
        end
        else if n^.kind = 146 then begin
          hit := c_tree_ptr_t(n)^.bits.post;
          node := n^.xp[6];
        end
        else if n^.kind = 145 then
          fold := true
        else begin
          init_aux(desc, typ);
          desc.size := 4;
          desc.rlen := 5;
          add_tn(26, desc, cexs_23bc, cexs_23bc);
        end;
        if not fold then
          bits.is_addr := true;
      end
      else begin
        n := node;
        if n^.kind = 145 then
          if not (3 in cargs_$options.cpu) then
            fold := (offset + n^.xl[8] <= -128) or
                    (offset + n^.xl[8] >= 96);
      end;
      if fold then begin
        n := node;
        offset := offset + n^.xl[8];
        init_aux(desc, typ);
        if bits.long_index or c_tree_ptr_t(n)^.bits.post then
          desc.w6 := 4
        else
          desc.w6 := 2;
        desc.size := 0;
        desc.rlen := 5;
        sub := n^.xp[8];
        node := n^.xp[6];
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc].node := sub;
        if n^.xw[20] <> 0 then begin
          if n^.xw[21] = 2 then
            type_exp(short_type, addr(cexs_stack[cexs_23bc].typ))
          else
            type_exp(int_type, addr(cexs_stack[cexs_23bc].typ));
          push_con(n^.xw[20]);
          init_aux(desc2, cexs_stack[cexs_23bc - 1].typ);
          add_tn(27, desc2, cexs_23bc - 1, cexs_23bc);
        end;
        add_tn(13, desc, cexs_23bc - 1, cexs_23bc);
        bits.is_addr := true;
      end;
    end;

    if index <> nil then begin
      n := index;
      if (n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) and
         c_tree_ptr_t(n)^.bits.post then
        hit := true;
      if (mode = 2) and
         ((3 in cargs_$options.cpu) or (6 in cargs_$options.cpu) or
          ((offset >= -128) and (offset < 96))) then begin
        if bits.long_index then
          len := 4
        else
          len := 2;
        node := add_dindexn(node, item, n, offset, len, typ.flags.align, 0);
        bits.is_addr := false;
        offset := 0;
      end
      else begin
        init_aux(desc, typ);
        if bits.long_index then
          desc.w6 := 4
        else
          desc.w6 := 2;
        desc.size := 0;
        desc.rlen := 5;
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc].node := index;
        add_tn(13, desc, cexs_23bc - 1, cexs_23bc);
      end;
      if hit and
         (node^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205])
      then
        c_tree_ptr_t(node)^.bits.post := true;
      index := nil;
      bits.long_index := false;
    end;

    if mode <> 1 then begin
      if (offset < -32700) or (offset > 32700) then begin
        init_aux(desc, typ);
        desc.rlen := 5;
        desc.w6 := 4;
        desc.size := 0;
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc].node := smcontk(81, offset);
        add_tn(13, desc, cexs_23bc - 1, cexs_23bc);
        c_tree_ptr_t(cexs_stack[cexs_23bc].node)^.bits.post := true;
        offset := 0;
      end;
      if bits.is_addr then begin
        node := add_pn(node, item, typ.flags.align, 0);
        bits.is_addr := false;
      end;
      if base <> nil then begin
        node := add_sdn(node, sym, base);
        base := nil;
      end;
      if (offset <> 0) or bits.force_disp then begin
        n := node;
        if (n^.kind = 146) and
           ((n^.xp[6]^.kind = 82) or (n^.xp[6]^.kind = 81)) then
          n^.xp[6] := smcontk(81, n^.xp[6]^.int_value + offset)
        else
          node := add_dn(n, sym, offset);
        offset := 0;
      end;
    end;
  end;
end;

{ body_opr - see c_externs.ins.pas.

  0x04B5E0, 0x534 bytes, link #-44: a jump table on mode (`cmpi.w #12;
  bcc'; 9 and 12 up do nothing); mode 10 runs into mode 5's
  reference_operand(2).  The error paths of the member case are
  compiled once for each way to them.

  Not known from the original:
  - the names; the meaning of the entries' bit 4 of +57 (cleared for
    mode 1 and strings, set for the other names). }

procedure body_opr;
var
  t: c_type_ptr_t;                      { -4 }
  o: integer32;                         { -8 }
  n: il_$node_ptr_t;                    { -12 }
  s: il_$node_ptr_t;
  f: c_field_ptr_t;
  p: c_type_ptr_t;
  r: c_sym_ptr_t;
  k2: integer;
  deref_int: boolean;
  fold: boolean;
  ok: boolean;

{ find_field - the field of the structure type t named name^.id, else
  il_178 (also when t or the name is il_178).

  0x04B078, 0x52 bytes, link #-12; body_opr's frame in A1; the loop
  ends by clearing its pointer (`suba.l A1,A1') when found; the result
  in A0.

  Not known from the original:
  - the names. }

function find_field(
    t: c_type_ptr_t): c_field_ptr_t; options(val_param);
var
  res: c_field_ptr_t;
  m: c_field_ptr_t;
begin
  res := c_field_ptr_t(il_178);
  if (t <> c_type_ptr_t(il_178)) and (name^.id <> il_178) then begin
    m := t^.su_fields;
    while m <> nil do
      if m^.name = name^.id then begin
        res := m;
        m := nil;
      end
      else
        m := m^.next;
  end;
  find_field := res;
end;

{ find_field_member - the field of t named name^.id, or one of an
  unnamed member structure's (to any depth; the shallowest of at most
  16 found, the number found beyond one diagnostic 90, one diagnostic
  89 under -STD), off the containing members' offsets.

  0x04B19A, 0x15C bytes, link #-240: the candidates are 12-byte
  records from -208 (field, offset, depth; element 0's depth set to
  32000 as the first best); the count at -232, the offset sum at
  -212, the depth at -228; body_opr's frame kept at -4; the result in
  A0.

  Not known from the original:
  - the names. }

function find_field_member(
    t: c_type_ptr_t;
    var off: integer32): c_field_ptr_t; options(val_param);
type
  cand_t = record
    field: c_field_ptr_t;               { +0 }
    offset: integer32;                  { +4 }
    depth: integer;                     { +8 }
  end;
var
  cands: array [0..16] of cand_t;       { -208 }
  sum: integer32;                       { -212 }
  depth: integer;                       { -228 }
  count: integer;                       { -232 }
  res: c_field_ptr_t;
  m: c_field_ptr_t;
  s: c_type_ptr_t;
  best: integer;
  i: integer;

{ find_field_partial - enter the fields of m's structure type s named
  name^.id as candidates (at most 16), recursing into its unnamed
  member structures.

  0x04B0CA, 0xD0 bytes, link #-16; find_field_member's frame in A1
  (body_opr's from its -4); the typedef names (118) looked through to
  their types (+28); `cmpi.w #16; bcc'.

  Not known from the original:
  - the names. }

procedure find_field_partial(
    m: c_field_ptr_t;
    s: c_type_ptr_t); options(val_param);
var
  g: c_field_ptr_t;
  u: c_type_ptr_t;
begin
  g := s^.su_fields;
  depth := depth + 1;
  sum := sum + m^.offset;
  while g <> nil do begin
    if (g^.name = name^.id) and (count < 16) then begin
      count := count + 1;
      cands[count].depth := depth;
      cands[count].field := g;
      cands[count].offset := sum;
    end;
    u := g^.ftype;
    while u^.kind = 118 do
      u := c_sym_ptr_t(u)^.td_type;
    if u^.kind = 132 then
      find_field_partial(g, u);
    g := g^.next;
  end;
  sum := sum - m^.offset;
  depth := depth - 1;
end;

begin { find_field_member }
  off := 0;
  res := find_field(t);
  if (res = c_field_ptr_t(il_178)) and (t <> c_type_ptr_t(il_178)) and
     (name^.id <> il_178) then begin
    count := 0;
    sum := 0;
    depth := 0;
    m := t^.su_fields;
    while m <> nil do begin
      s := m^.ftype;
      while s^.kind = 118 do
        s := c_sym_ptr_t(s)^.td_type;
      if s^.kind = 132 then
        find_field_partial(m, s);
      m := m^.next;
    end;
    if count = 0 then
      res := c_field_ptr_t(il_178)
    else begin
      if count <> 1 then
        error1(90, cexs_stack[cexs_23bc].line, name^.id)
      else if cargs_$options.std then
        error1(89, cexs_stack[cexs_23bc].line, name^.id);
      best := 0;
      cands[0].depth := 32000;
      for i := 1 to count do
        if cands[i].depth < cands[best].depth then
          best := i;
      res := cands[best].field;
      off := cands[best].offset;
    end;
  end;
  find_field_member := res;
end;

{ exposed_member - the field named name^.id of the structures exposed
  in the current block and those enclosing it (c_blk_t's exposed;
  entries of kind 6 skipped), off its offset; nil when there is none,
  il_178 when two are found of different types or offsets.

  0x04B2F6, 0xA6 bytes, link #-28; body_opr's frame from (A6)
  (docs/rev889-patterns.md 25), passed on in A1; the offset kept in D2
  and passed through -16; the test of two found is check_types' result
  and-ed with the offsets' equality (`seq; and.b; bmi'); the result in
  A0.

  Not known from the original:
  - the names; what the entries of kind 6 are. }

function exposed_member(
    var off: integer32): c_field_ptr_t; options(val_param);
type
  exp_ptr_t = ^exp_t;
  exp_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    next: exp_ptr_t;                    { +4 }
    stype: c_type_ptr_t;                { +8 }
  end;
var
  o: integer32;                         { -16 }
  res: c_field_ptr_t;
  g: c_field_ptr_t;
  e: exp_ptr_t;
  b: c_blk_ptr_t;
begin
  res := nil;
  off := 0;
  o := 0;
  b := c_blk_ptr_t(il_180);
  while b <> nil do begin
    e := exp_ptr_t(b^.tags);  { the block's tags (c_tag_t: +4 next, +8 the type) }
    while e <> nil do begin
      if e^.kind <> 6 then begin
        g := find_field_member(e^.stype, o);
        if g <> c_field_ptr_t(il_178) then
          if res = nil then begin
            res := g;
            off := o;
          end
          else if not (check_types(res^.ftype, g^.ftype, false) and
                       (off = o)) then begin
            exposed_member := c_field_ptr_t(il_178);
            return;
          end;
      end;
      e := e^.next;
    end;
    b := c_blk_ptr_t(il_$node_ptr_t(b)^.xp[2]);
  end;
  exposed_member := res;
end;

{ select_field - the top entry becomes its field f: f's type (keeping
  the structure's qualifiers b25_5 and b25_4), the offset f's added;
  a volatile or atomic field (flags 0, 1) or one whose type's phase
  has elements 0 or 1 (getphase) forces the displacement node
  (force_disp).

  0x04B39C, 0xC6 bytes, link #-12; body_opr's frame from (A6); the
  qualifiers or-ed in with `sne; or.b; lsr.b #7'.

  Not known from the original:
  - the names. }

procedure select_field(
    f: c_field_ptr_t); options(val_param);
var
  q5: boolean;
  q4: boolean;
begin
  with cexs_stack[cexs_23bc] do begin
    q5 := typ.flags.b25_5;
    q4 := typ.flags.b25_4;
    sym := il_$node_ptr_t(f);
    line := name^.line;
    type_exp(f^.ftype, addr(typ));
    offset := offset + f^.offset;
    bf_done := false;
    typ.flags.b25_5 := q5 or typ.flags.b25_5;
    typ.flags.b25_4 := q4 or typ.flags.b25_4;
    if (0 in f^.flags) or (1 in f^.flags) or
       (getphase(f^.ftype) * [0, 1] <> []) then
      bits.force_disp := true;
  end;
end;

{ stack_operand - push the operand n of type t (il_178 when n is):
  diagnostics name the identifier for a constant (the kinds 77..90,
  92, 93, 101, 156, 176, 198, 200), else n; the address parts cleared,
  var_pending set (the word at +56 stored as 1), disp -1.  A routine's
  type (107, 108) clears +56; with con, an integer constant of a
  signed type (or not integral) gets its value as its bounds and the
  shortest of char and short that holds it (an enumeration keeping its
  type); a variable's disp is its size.

  0x04B462, 0x164 bytes, link #-12; body_opr's frame from (A6); the
  constant kinds are `btst' on a 26-byte set (docs/dpc-gaps.md 8); the
  kind tested for 122 twice.

  Not known from the original:
  - the names. }

procedure stack_operand(
    n: il_$node_ptr_t;
    t: c_type_ptr_t;
    con: boolean); options(val_param);
var
  tt: c_type_ptr_t;                     { -8 }
  k: integer;
  v: integer32;
begin
  if n <> il_178 then
    tt := t
  else
    tt := c_type_ptr_t(il_178);
  cexs_23bc := cexs_23bc + 1;
  with cexs_stack[cexs_23bc] do begin
    node := n;
    item := n;
    if n^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
      sym := name^.id
    else
      sym := n;
    line := name^.line;
    offset := 0;
    index := nil;
    base := nil;
    bits.b56 := 0;
    bits.b57_7 := false;
    bits.b57_6 := false;
    bits.force_disp := false;
    bits.b57_4 := false;
    bits.b57_3 := false;
    bits.long_index := false;
    bits.is_addr := false;
    bits.var_pending := true;
    disp := -1;
    flag_61 := false;
    type_exp(tt, addr(typ));
    k := typ.base^.kind;
    if (k = 107) or (k = 108) then begin
      bits.b56 := 0;
      bits.var_pending := false;
    end
    else begin
      if con and typ.flags.ranged then
        if (k <> 122) or (typ.base^.signed and (k = 122)) then begin
          typ.low := n^.int_value;
          typ.high := typ.low;
          v := typ.low;
          if (v >= -128) and (v <= 127) then begin
            typ.size := 1;
            if typ.base^.kind <> 129 then
              typ.base := char_type;
          end
          else if (v >= -32768) and (v <= 32767) then begin
            typ.size := 2;
            if typ.base^.kind <> 129 then
              typ.base := short_type;
          end;
          typ.bytes := typ.size;
        end;
      if node^.kind = 109 then
        disp := typ.size;
    end;
  end;
end;

begin { body_opr }
  case mode of
    0, 1, 11:
      if (mode = 0) and (cdef_50^.kind = 108) and
         (cdef_50^.name.id = name^.id) then begin
        r := cdef_50^.ret_var;
        if r <> nil then
          t := c_type_ptr_t(r)
        else
          t := cdef_50^.result;
        stack_operand(il_$node_ptr_t(r), t, false);
      end
      else begin
        if mode = 11 then
          s := name^.id
        else
          s := fnd_name(name, false, true);
        if s^.kind = 116 then
          if mode = 0 then begin
            error1(52, name^.line, name^.id);
            stack_operand(il_178, c_type_ptr_t(il_178), false);
          end
          else
            stack_operand(c_sym_ptr_t(s)^.con_value,
                          c_sym_ptr_t(s)^.con_type, true)
        else if s^.kind = 109 then
          stack_operand(s, c_type_ptr_t(s), false)
        else begin
          if mode = 0 then
            error2(59, name^.line, name^.id, s)
          else
            error2(60, name^.line, name^.id, s);
          stack_operand(il_178, c_type_ptr_t(il_178), false);
        end;
        with cexs_stack[cexs_23bc] do
          if mode = 1 then
            bits.b57_4 := false
          else
            bits.b57_4 := true;
      end;
    2:
      with cexs_stack[cexs_23bc] do begin
        k2 := typ.base^.kind;
        if (k2 <> 122) and (k2 <> 131) and (k2 <> 127) then begin
          error2(61, line, sym, typ.base);
          typ.base := c_type_ptr_t(il_178);
        end;
      end;
    3:
      with cexs_stack[cexs_23bc] do begin
        deref_int := false;
        ok := true;
        if typ.base^.kind <> 130 then
          if (token_kind = ctk_arrow) and (typ.base^.kind = 122) and
             (typ.base^.len = 4) then
            deref_int := true
          else begin
            error2(62, line, sym, typ.base);
            typ.base := c_type_ptr_t(il_178);
            ok := false;
          end;
        if ok then begin
          reference_operand(0);
          bits.is_addr := true;
          if deref_int then begin
            item := il_$node_ptr_t(typ.base);
            type_exp(item, addr(typ));
            typ.flags.align := 1;
            typ.flags.align_attr := false;
            typ.flags.align_ok := true;
            typ.flags.b25_5 := false;
            typ.flags.b25_4 := false;
            typ.bytes := typ.size;
          end
          else begin
            item := il_$node_ptr_t(typ.base^.ptr_to);
            p := typ.base;
            type_exp(item, addr(typ));
            attr_set_align_dsc(il_$node_ptr_t(p), addr(typ));
            typ.bytes := (p^.ptr_attr.size_bits + 7) div 8;
            typ.flags.b25_5 := 19 in p^.ptr_attr.bits;
            typ.flags.b25_4 := 0 in p^.ptr_attr.bits;
          end;
        end;
      end;
    4:
      with cexs_stack[cexs_23bc] do begin
        fold := false;
        ok := false;
        if typ.base^.kind <> 132 then begin
          if cargs_$options.xansi then begin
            error2(64, name^.line, name^.id, sym);
            typ.base := c_type_ptr_t(il_178);
          end
          else begin
            f := exposed_member(o);
            if f = nil then begin
              error2(63, line, sym, typ.base);
              typ.base := c_type_ptr_t(il_178);
            end
            else if f = c_field_ptr_t(il_178) then begin
              error1(199, name^.line, name^.id);
              typ.base := c_type_ptr_t(il_178);
            end
            else begin
              error2(198, line, sym, name^.id);
              ok := true;
            end;
          end;
        end
        else begin
          f := find_field_member(typ.base, o);
          if f <> c_field_ptr_t(il_178) then
            ok := true
          else begin
            if not cargs_$options.xansi then
              f := exposed_member(o);
            if cargs_$options.xansi or (f = nil) then begin
              error2(64, name^.line, name^.id, sym);
              typ.base := c_type_ptr_t(il_178);
            end
            else if f = c_field_ptr_t(il_178) then begin
              error1(199, name^.line, name^.id);
              typ.base := c_type_ptr_t(il_178);
            end
            else begin
              error2(198, line, sym, name^.id);
              ok := true;
            end;
          end;
        end;
        if ok then begin
          offset := offset + o;
          select_field(f);
          n := node;
          if (n^.kind = 137) and (c_tree_ptr_t(n)^.op = 16) and
             (offset = 0) and not bits.is_addr then
            fold := true;
          if fold then
            node := add_disp_node(n, sym, 0, true);
        end;
      end;
    5:
      reference_operand(2);
    6: begin
      t := double_type;
      if name^.id <> nil then
        if name^.id^.kind = 88 then
          t := float_type;
      stack_operand(name^.id, t, true);
    end;
    7: begin
      n := name^.id;
      stack_operand(n, c_type_ptr_t(n), false);
      cexs_stack[cexs_23bc].bits.b57_4 := false;
    end;
    8:
      if name^.id^.kind = 85 then
        stack_operand(name^.id, uint_type, true)
      else
        stack_operand(name^.id, int_type, true);
    10: begin
      if name^.id <> il_178 then
        stack_operand(name^.id, c_sym_ptr_t(name^.id)^.var_type, false)
      else
        stack_operand(il_178, c_type_ptr_t(il_178), false);
      reference_operand(2);
    end;
    otherwise ;
  end;
end;

{ scl_cmp - d describes the comparison op (0 ==, 1 !=, 2 <=, 3 >=,
  4 <, 5 >) of entries a and b: the signed condition code first
  (cexs_cond[op]), the unsigned one (cexs_cond[op + 6]) when a pointer
  or an unsigned operand takes part (under -XANSI, when only one is
  unsigned, only if that one is 4 bytes); nothing more when both
  operands are the same node.

  0x04BB14, 0x17C bytes, link #-40: the operands' properties in D2..D5
  (`seq', `st', `clr.b', `not.b' of an enumeration's signedness); the
  exclusive or as `or.b; and.b; not.b; or.b; not.b'.

  Not known from the original:
  - the names. }

procedure scl_cmp(
    out d: c_desc_t;
    a: integer;
    b: integer;
    op: integer); options(val_param); internal;
var
  i: integer;                           { -40 }
  both4: boolean;                       { -12 }
  ta: c_type_ptr_t;
  tb: c_type_ptr_t;
  ua, la, pa: boolean;
  ub, lb, pb: boolean;
  uns: boolean;
begin
  i := op;
  d.w6 := cexs_cond[i];
  d.flags.b6 := true;
  ta := cexs_stack[a].typ.base;
  tb := cexs_stack[b].typ.base;
  if cexs_stack[a].node <> cexs_stack[b].node then begin
    if (ta^.kind = 122) and not ta^.signed then
      ua := true
    else if ta^.kind = 129 then
      ua := not ta^.enum_int^.signed
    else
      ua := false;
    if (ta^.kind = 122) and (ta^.len = 4) then
      la := true
    else if ta^.kind = 129 then
      la := ta^.enum_int^.len = 4
    else
      la := false;
    pa := ta^.kind = 130;
    if (tb^.kind = 122) and not tb^.signed then
      ub := true
    else if tb^.kind = 129 then
      ub := not tb^.enum_int^.signed
    else
      ub := false;
    if (tb^.kind = 122) and (tb^.len = 4) then
      lb := true
    else if tb^.kind = 129 then
      lb := tb^.enum_int^.len = 4
    else
      lb := false;
    pb := tb^.kind = 130;
    both4 := (ua and la) or (ub and lb);
    pa := pa or pb;
    if (ua <> ub) and cargs_$options.xansi then
      uns := both4 or pa
    else
      uns := pa or ua or ub;
    if uns then begin
      d.w6 := cexs_cond[i + 6];
      d.flags.b6 := false;
    end;
  end;
end;

{ push_con - push the integer constant v (body_opr 8, at lex_line).

  0x04BC90, 0x40 bytes, link #-8: the name record at -8.

  Not known from the original:
  - the names. }

procedure push_con;
var
  nm: c_name_t;                         { -8 }
begin
  nm.id := smcontk(81, v);
  nm.line := lex_line;
  body_opr(8, addr(nm));
end;

{ push_fcon - push the double constant value (body_opr 6, at
  lex_line); a constant of magnitude under 100 pushed over another
  operand takes that operand's size.

  0x04BCD0, 0xA4 bytes, link #-20: value copied to -16; the
  comparisons are `jsr fpp_$' with 0x0074 0x00B8 and the doubles -100.0
  and 100.0 inline, `sgt' and `slt' after them, and-ed (`and.b
  (-18,A6)'); the stack's top compared unsigned (`bls').

  Not known from the original:
  - the names. }

procedure push_fcon;
var
  r: double;                            { -16 }
  nm: c_name_t;                         { -8 }
begin
  r := value;
  nm.id := dpcontk(r);
  nm.line := lex_line;
  body_opr(6, addr(nm));
  if cexs_23bc > 1 then
    if (r > -100.0) and (r < 100.0) then
      cexs_stack[cexs_23bc].typ.size := cexs_stack[cexs_23bc - 1].typ.size;
end;

{ swap_top - exchange the stack's two top entries.

  0x04BD74, 0x62 bytes, link #-72: three copies of 62 bytes (`moveq
  #4; dbf' of three longwords, then a word) through -72
  (docs/rev889-patterns.md 48); c_expr_syn has its own copy.

  Not known from the original:
  - the local's name. }

procedure swap_top; internal;
var
  t: c_exp_t;
begin
  t := cexs_stack[cexs_23bc];
  cexs_stack[cexs_23bc] := cexs_stack[cexs_23bc - 1];
  cexs_stack[cexs_23bc - 1] := t;
end;

{ expr_op - see c_externs.ins.pas: reduce the top nargs entries of the
  stack by the operator op to one entry (at base, cexs_23bc - nargs +
  1).  First arrays (127, 131) decay to pointers (an address node 26 to
  a pointer to the element type) and functions (234, 108) to their
  addresses (expr_op 17), except in calling context 4 and for the
  first operand of the operators that take an object (expr_op's
  object_ops); bit-field operands (120) are extracted (14 with the
  width pushed); then the operands are checked against the operator's
  classes (op_tab, exp_class: diagnostics 68, 69), converted to a
  floating type when one is, ordered (the wider or constant operand
  second), converted to a common type (do_coerce for the assignments
  and shifts, else double_coerce), and the operator's case builds the
  tree; at the end the operator's tree node (op_tab's tnop, unless
  the case cleared it) is made (add_tn) over the operands, a boolean
  result is masked to its low bit, and a pending division (x196) is
  applied.  On an error the result is il_178 (label 99, which the
  nested routines reach by a non-local goto).

  0x04CDBA, 0x2B7A bytes, link #-492: A5 kept at -488 for the
  non-local goto (pas_$nlg2 from do_coerce, coerce_as_usual and
  value_preserve to 0x04F856, docs/rev889-patterns.md 35; dpc gap 14);
  the operator's case a jump table (`cmpi.w #66; bcc'); the operator
  sets are `btst' on 10-byte constants (0..79), the kinds' on 18 and
  26-byte ones (docs/dpc-gaps.md 8).  expr_op(22) does nothing.

  Not known from the original:
  - the names; the meaning of x196 (a divisor applied at the end), x260
    (the tree's +18), x310. }

procedure expr_op;
label
  96, 97, 98, 99;
var
  nm: c_name_t;                         { -8 }
  fd: c_decl_t;                         { -48 }
  at: type_exp_t;                       { -80 }
  it: type_exp_t;                       { -112 }
  cls: kind_set_t;                      { -144 }
  desc: c_desc_t;                       { -160 }
  x196: integer32;                      { -196 }
  tb: c_type_ptr_t;                     { -200 }
  neg: boolean;                         { -208 }
  shift: integer32;                     { -212 }
  rt: c_type_ptr_t;                     { -244 }
  ft: c_type_ptr_t;                     { -248 }
  conv: integer;                        { -254 }
  x260: integer;                        { -260 }
  tnop: integer;                        { -278 }
  ib: integer;                          { -284 }
  ia: integer;                          { -286 }
  bas: integer;                         { -288: the result's entry }
  isfn: boolean;                        { -296 }
  diff: boolean;                        { -298 }
  res_bool: boolean;                    { -308 }
  x310: boolean;                        { -310 }
  bad1, bad2: boolean;                  { -314 }
  off: integer32;                       { -252 }
  pl: c_parlist_ptr_t;                  { -370 }
  f: c_field_ptr_t;
  blk: c_blk_ptr_t;
  ta: c_type_ptr_t;
  p: c_type_ptr_t;
  n: il_$node_ptr_t;
  c: il_$node_ptr_t;
  d5n: il_$node_ptr_t;
  t: il_$node_ptr_t;
  oc: integer;
  i, j, k, m: integer;
  first, top, save: integer;
  minn, maxn: integer;
  w: integer32;
  v: integer32;
  esz: integer32;
  inset: boolean;
  swapped: boolean;
  unb: boolean;
  long: boolean;
  q5, q4: boolean;
  sa, sb: boolean;

{ boolean_result - the result (entry base) is a boolean: char, 0..1,
  1 byte, ranged; diagnostics name the operator; res_bool set.

  0x04BDD6, 0x4C bytes, link #-8; expr_op's frame from (A6); the
  bounds and size copied as three longwords (0, 1, 1) from after the
  routine.

  Not known from the original:
  - the names. }

procedure boolean_result;
begin
  with cexs_stack[bas] do begin
    typ.base := char_type;
    typ.low := 0;
    typ.high := 1;
    typ.size := 1;
    typ.flags.ranged := true;
    sym := name^.id;
  end;
  res_bool := true;
end;

{ do_coerce - convert entry ib to entry ia's type (assignments,
  shifts): a pointer mixed with an integer or enumeration other than
  the constant 0 is diagnostic 78; failing, diagnostic 70 and label 99;
  an enumeration converted, 205; a constant first operand keeps the
  wider of the two bounds.

  0x04BE2E, 0x1A2 bytes, link #-32; expr_op's frame from (A6); the
  second operand's constant test as `seq; or.b' of 82, 81, 80.

  Not known from the original:
  - the names. }

procedure do_coerce;
var
  lo, hi: integer32;
  z: il_$node_ptr_t;
begin
  with cexs_stack[ia] do begin
    if (typ.base^.kind = 130) or (cexs_stack[ib].typ.base^.kind = 130) then
      if (cexs_stack[ib].typ.base^.kind = 129) or (typ.base^.kind = 129) or
         (typ.base^.kind = 122) or
         (cexs_stack[ib].typ.base^.kind = 122) then begin
        if typ.base^.kind = 130 then
          z := cexs_stack[ib].node
        else
          z := node;
        if not (z^.kind in [80..86, 200]) or (z^.int_value <> 0) then
          error3(78, name^.line, sym, cexs_stack[ib].sym, name^.id);
      end;
    lo := cexs_stack[ib].typ.low;
    hi := cexs_stack[ib].typ.high;
    if not coerce(typ, ib, true) then begin
      error3(70, name^.line, sym, cexs_stack[ib].sym, name^.id);
      goto 99;  { non-local }
    end;
    if cexs_23be then begin
      error3(205, name^.line, sym, cexs_stack[ib].sym, name^.id);
      cexs_23be := false;
    end;
    if ((node^.kind = 80) or (node^.kind = 82) or (node^.kind = 81)) and
       not ((cexs_stack[ib].node^.kind = 82) or
            (cexs_stack[ib].node^.kind = 81) or
            (cexs_stack[ib].node^.kind = 80)) then begin
      if lo < typ.low then begin
        typ.low := lo;
        cexs_stack[ib].typ.low := lo;
      end;
      if hi > typ.high then
        typ.high := hi;
    end;
  end;
end;

{ double_coerce - the usual arithmetic conversions of entries ia and
  ib: integral and enumeration operands under -XANSI by value
  preservation (value_preserve), otherwise ib converted to ia's type
  (coerce_as_usual); a pointer mixed with an integer or enumeration
  other than the constant 0 is diagnostic 78.

  0x04C448, 0x1D2 bytes, link #-32; expr_op's frame from (A6); the
  kinds compared in turn (129, 122, 130), the -XANSI tests compiled
  once for each.

  Not known from the original:
  - the names. }

procedure double_coerce;
var
  lo, hi: integer32;                    { -12, -8 }
  ka, kb: integer;

{ fixup_bounds - after a conversion, a constant first operand and a
  second that is not keep the saved (wider) bounds.

  0x04BFD0, 0x9A bytes, link #-24; double_coerce's frame in A1,
  expr_op's from it; the high bound stored twice.

  Not known from the original:
  - the names. }

procedure fixup_bounds;
begin
  with cexs_stack[ia] do
    if (node^.kind in [80..86, 200]) and
       not (cexs_stack[ib].node^.kind in [80..86, 200]) then begin
      if lo < typ.low then begin
        typ.low := lo;
        cexs_stack[ib].typ.low := lo;
      end;
      if hi > typ.high then begin
        typ.high := hi;
        typ.high := hi;
      end;
    end;
end;

{ coerce_as_usual - convert entry ib to entry ia's type (diagnostics
  70 with label 99, 205), keeping ib's bounds for fixup_bounds.

  0x04C06A, 0xCC bytes, link #-24; double_coerce's frame in A1.

  Not known from the original:
  - the names. }

procedure coerce_as_usual;
begin
  lo := cexs_stack[ib].typ.low;
  hi := cexs_stack[ib].typ.high;
  if not coerce(cexs_stack[ia].typ, ib, true) then begin
    error3(70, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym, name^.id);
    goto 99;  { non-local }
  end;
  if cexs_23be then begin
    error3(205, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym,
           name^.id);
    cexs_23be := false;
  end;
  fixup_bounds;
end;

{ coerce_dominant - entry ia to the basic integral type of len bytes
  and signedness sgn, keeping its qualifiers and a constant's bounds.

  0x04C136, 0x10C bytes, link #-80; double_coerce's frame in A1; the
  type at -76, its type_exp_t at -72, the entry's old one at -40;
  coerce's result not read.

  Not known from the original:
  - the names. }

procedure coerce_dominant(
    len: integer;
    sgn: boolean); options(val_param);
var
  bt: c_type_ptr_t;                     { -76 }
  tt: type_exp_t;                       { -72 }
  saved: type_exp_t;                    { -40 }
begin
  with cexs_stack[ia] do begin
    if len = 1 then
      if sgn then bt := char_type else bt := uchar_type
    else if len = 2 then
      if sgn then bt := short_type else bt := ushort_type
    else
      if sgn then bt := int_type else bt := uint_type;
    type_exp(bt, addr(tt));
    saved := typ;
    discard(coerce(tt, ia, true));
    typ.flags.b25_5 := saved.flags.b25_5;
    typ.flags.b25_4 := saved.flags.b25_4;
    if node^.kind in [80..86, 200] then begin
      typ.low := saved.low;
      typ.high := saved.high;
    end;
  end;
end;

{ value_preserve - ANSI's value-preserving conversion of two integral
  operands of different signedness: the result is signed unless the
  unsigned one is 4 bytes; ia is first converted to that signedness
  and to 4 bytes (2 when both are chars and the unsigned... ) when it
  is shorter or of the other signedness, then ib to ia's type
  (diagnostics 70 with label 99, 205); operands of the same
  signedness are converted as usual.

  0x04C242, 0x206 bytes, link #-116; double_coerce's frame from (A6)
  (kept at -116), expr_op's at -4; the exclusive or as `and.b; or.b;
  not.b'.

  Not known from the original:
  - the names. }

procedure value_preserve;
var
  sa: boolean;                          { -94 }
  la, sb, lb: boolean;
  u4: boolean;
  pta, ptb: c_type_ptr_t;
  rs: boolean;
  len: integer;
begin
  with cexs_stack[ia] do begin
    pta := typ.base;
    ptb := cexs_stack[ib].typ.base;
    sa := ((pta^.kind = 122) and pta^.signed) or
          ((pta^.kind = 129) and pta^.enum_int^.signed);
    if (pta^.kind = 122) and (pta^.len = 4) then
      la := true
    else if pta^.kind = 129 then
      la := pta^.enum_int^.len = 4
    else
      la := false;
    sb := ((ptb^.kind = 122) and ptb^.signed) or
          ((ptb^.kind = 129) and ptb^.enum_int^.signed);
    if (ptb^.kind = 122) and (ptb^.len = 4) then
      lb := true
    else if ptb^.kind = 129 then
      lb := ptb^.enum_int^.len = 4
    else
      lb := false;
    u4 := (not sa and la) or (not sb and lb);
    if sa <> sb then begin
      rs := not u4;
      if sb then
        if typ.size > 1 then
          len := 4
        else if cexs_stack[ib].typ.size = 4 then
          len := 4
        else
          len := 2
      else
        if cexs_stack[ib].typ.size > 1 then
          len := 4
        else if typ.size = 4 then
          len := 4
        else
          len := 2;
      if (len > typ.size) or (rs <> sa) then
        coerce_dominant(len, rs);
      if not coerce(typ, ib, true) then begin
        error3(70, name^.line, sym, cexs_stack[ib].sym, name^.id);
        goto 99;  { non-local }
      end;
      if cexs_23be then begin
        error3(205, name^.line, sym, cexs_stack[ib].sym, name^.id);
        cexs_23be := false;
      end;
    end
    else
      coerce_as_usual;
  end;
end;

begin { double_coerce }
  ka := cexs_stack[ia].typ.base^.kind;
  kb := cexs_stack[ib].typ.base^.kind;
  if (ka = 129) or (ka = 122) then begin
    if (kb = 129) or (kb = 122) then begin
      if cargs_$options.xansi then begin
        value_preserve;
        return;
      end;
    end
    else if kb = 130 then
      if not (cexs_stack[ia].node^.kind in [80..86, 200]) or
         (cexs_stack[ia].node^.int_value <> 0) then
        error3(78, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym,
               name^.id);
  end
  else if ka = 130 then begin
    if (kb = 129) or (kb = 122) then
      if not (cexs_stack[ib].node^.kind in [80..86, 200]) or
         (cexs_stack[ib].node^.int_value <> 0) then
        error3(78, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym,
               name^.id);
  end;
  coerce_as_usual;
end;

{ mult_div_mod_prep - both operands of *, /, % to at least 2 bytes; a
  2-byte operand with a negative partner whose high bound passes 32767
  to 4 bytes.

  0x04C61A, 0xA0 bytes, link #-12; expr_op's frame from (A6); mode
  and length pushed together as one longword (`pea 0x2', `move.l
  #0x10004').

  Not known from the original:
  - the names. }

procedure mult_div_mod_prep;
begin
  adjust_length(bas, 0, 2);
  adjust_length(cexs_23bc, 0, 2);
  if (cexs_stack[bas + 1].typ.size = 2) and
     (cexs_stack[bas].typ.low < 0) and
     (cexs_stack[bas + 1].typ.high > 32767) then
    adjust_length(bas + 1, 1, 4)
  else if (cexs_stack[bas].typ.size = 2) and
          (cexs_stack[bas + 1].typ.low < 0) and
          (cexs_stack[bas].typ.high > 32767) then
    adjust_length(bas, 1, 4);
end;

{ mult_div_mod_sign - entry k takes the basic integral type of its
  size and signedness sgn.

  0x04C6BA, 0x72 bytes, link #-8 (uses none of expr_op's frame).

  Not known from the original:
  - the names. }

procedure mult_div_mod_sign(
    k: integer;
    sgn: boolean); options(val_param);
begin
  with cexs_stack[k] do
    if typ.size = 1 then
      if sgn then typ.base := char_type else typ.base := uchar_type
    else if typ.size = 2 then
      if sgn then typ.base := short_type else typ.base := ushort_type
    else
      if sgn then typ.base := int_type else typ.base := uint_type;
end;

{ power_of_two - whether the top entry is a constant whose magnitude
  is a power of two (shift its log2, neg its sign); under -XANSI the
  operand is folded first (cc_walk_it with call_kfold, its use counts
  raised around it); a one-character string becomes its character's
  constant.

  0x04C72C, 0x12E bytes, link #-28; expr_op's frame from (A6); the
  cleared result register passed as cc_walk_it's false and stored as
  neg (docs/rev889-patterns.md 24); the log2 by `lsr.l #1' until bit 0.

  Not known from the original:
  - the names. }

function power_of_two: boolean;
var
  r: boolean;
  v, w: integer32;
  k: integer;
  n: il_$node_ptr_t;
begin
  r := false;
  if cargs_$options.xansi then begin
    adjust_uc(cexs_stack[cexs_23bc].node, 1);
    cc_walk_it(cexs_stack[cexs_23bc].node, addr(call_kfold), r);
    adjust_uc(cexs_stack[cexs_23bc].node, -1);
  end;
  with cexs_stack[cexs_23bc] do
    if (node^.kind = 92) and (node^.str_len = 1) then
      node := smcontk(81, ord(node^.str_chars[1]));
  n := cexs_stack[cexs_23bc].node;
  if (n^.kind = 80) or (n^.kind = 82) or (n^.kind = 81) then begin
    v := n^.int_value;
    if v >= 0 then
      neg := r
    else begin
      v := -v;
      if v < 0 then begin
        power_of_two := r;
        return;
      end;
      neg := true;
    end;
    if (((v - 1) & v) = 0) and (v <> 0) then begin
      w := v;
      k := 0;
      while (w & 1) = 0 do begin
        w := rshft(w, 1);
        k := k + 1;
      end;
      r := true;
      shift := k;
    end;
  end;
  power_of_two := r;
end;

{ build_builtin_tree - the tree of a builtin's call (op 0x20..0x3D,
  c_expr_syn's codes) over the entries first + 1 .. last: the string
  copies and concatenations (55, 56, 59, 60) as an assignment (54) of
  the dereferenced operands (a strcpy from a string constant moves
  its length, class 11) followed by a comma (expr_op 44) with the
  destination; the others set the descriptor's classes (the case on op
  - 32) and the operator (42 pow, 68 strcmp, 69 strlen, 70 strncmp),
  dereference the string operands (57, 58, 61) and make the node; the
  result takes the function's type (entry first's).

  0x04C91E, 0x33C bytes, link #-52; expr_op's frame from (A6); first
  and last by address (expr_op's base and cexs_23bc).

  Not known from the original:
  - the names. }

procedure build_builtin_tree(
    op: integer;
    var first: integer;
    var last: integer); options(val_param);
var
  save: integer;                        { -36 }
  opc: integer;                         { -34 }
  nm2: c_name_t;                        { -32 }
  sz: integer32;                        { -24 }
  szc: integer;                         { -20 }
  k: integer;

{ de_ref - entry k, a pointer, becomes what it points to (add_pn with
  the pointer's alignment, its qualifiers 19 and 0); else diagnostic
  62.

  0x04C85A, 0xC4 bytes, link #-12.

  Not known from the original:
  - the names. }

procedure de_ref(
    k: integer); options(val_param);
begin
  with cexs_stack[k] do
    if typ.base^.kind = 130 then begin
      item := il_$node_ptr_t(typ.base^.ptr_to);
      node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
      attr_set_align_dsc(il_$node_ptr_t(typ.base), addr(typ));
      typ.flags.b25_5 := 19 in typ.base^.ptr_attr.bits;
      typ.flags.b25_4 := 0 in typ.base^.ptr_attr.bits;
      type_exp(item, addr(typ));
    end
    else
      error2(62, line, sym, typ.base);
end;

begin { build_builtin_tree }
  save := last;
  k := first + 1;
  if (op = 55) or (op = 56) or (op = 60) or (op = 59) then begin
    cexs_stack[first] := cexs_stack[k];
    opc := 28;
    if (op = 59) and (cexs_stack[k + 1].item^.kind = 92) then begin
      opc := 6;
      sz := cexs_stack[last].item^.str_len;
      szc := 11;
    end;
    de_ref(k);
    de_ref(k + 1);
    tnop := 54;
    init_aux(desc, cexs_stack[k].typ);
    if opc = 6 then begin
      desc.size := sz;
      desc.rlen := szc;
    end;
    add_tn(tnop, desc, k, save);
    last := k;
    if op = 60 then
      opc := 30
    else if op = 55 then
      opc := 27
    else if op = 56 then
      opc := 29;
    if cexs_stack[k].node^.kind = 137 then
      c_tree_ptr_t(cexs_stack[k].node)^.w18 := opc;
    swap_top;
    nm2.id := lex_tokens[ctk_comma];
    nm2.line := lex_line;
    expr_op(44, addr(nm2), 2);
  end
  else begin
    case op of
      32: desc.w6 := 0;
      37: desc.w6 := 7;
      38: desc.w6 := 2;
      39: desc.w6 := 6;
      40, 52: desc.w6 := 4;
      41: desc.w6 := 1;
      42: desc.w6 := 9;
      51: desc.w6 := 8;
      53: desc.w6 := 3;
      54: begin
        tnop := 42;
        desc.w8 := 7;
      end;
      57: begin
        tnop := 68;
        desc.rlen := 4;
        if cargs_$options.ansi or cargs_$options.xansi then
          desc.w6 := 0
        else
          desc.w6 := 1;
      end;
      58: begin
        tnop := 70;
        desc.rlen := 4;
        if cargs_$options.ansi or cargs_$options.xansi then
          desc.w6 := 0
        else
          desc.w6 := 1;
      end;
      61: begin
        tnop := 69;
        desc.rlen := 4;
      end;
      otherwise ;
    end;
    if (op = 61) or (op = 57) or (op = 58) then begin
      de_ref(k);
      if op <> 61 then
        de_ref(k + 1);
    end;
    add_tn(tnop, desc, k, save);
    last := k;
    swap_top;
    cexs_stack[first].typ := cexs_stack[last].typ;
    last := first;
  end;
end;

{ result_signedness - the signedness of an operation's result from
  its operands' (s1, len1, s2, len2): under ANSI (ansi) signed unless
  an unsigned operand is 4 bytes, else signed only when both are.

  0x04CC5A, 0x52 bytes, link #-12 (uses none of expr_op's frame); the
  result in D0.

  Not known from the original:
  - the names. }

function result_signedness(
    s1: boolean;
    len1: integer;
    s2: boolean;
    len2: integer;
    ansi: boolean): boolean; options(val_param);
var
  u4: boolean;
begin
  u4 := ((len2 = 4) and not s2) or (not s1 and (len1 = 4));
  if ansi then
    result_signedness := not u4
  else
    result_signedness := s1 and s2;
end;

{ check_for_out_of_bounds - a constant subscript v (of elements of
  size bytes) at or past the end of entry k's array variable sets the
  variable's flag 22.

  0x04CD6A, 0x50 bytes, link #-12: get_number_of_elements' results at
  -12 and -8; `bset #6' of the variable's +33.

  Not known from the original:
  - the names; what flag 22 is for (c_expr_syn sets it too). }

procedure check_for_out_of_bounds(
    k: integer;
    v: integer32;
    size: integer32); options(val_param);
var
  count: integer32;                     { -12 }
  s: il_$node_ptr_t;                    { -8 }

{ get_number_of_elements - the number of elements of size bytes in the
  array variable n names (through an address operator 26; a pointer
  counts only under an address), maxint when unknown; s the variable.

  0x04CCAC, 0xBE bytes, link #-40; check_for_out_of_bounds' frame in
  A1; the division M$DIS$LLL; the result's tests chained (`seq; not.b;
  and.b; bmi').

  Not known from the original:
  - the names. }

procedure get_number_of_elements(
    n: il_$node_ptr_t;
    var count: integer32;
    var s: il_$node_ptr_t;
    under_addr: boolean); options(val_param);
var
  tt: type_exp_t;                       { -40 }
begin
  s := nil;
  if n^.kind = 137 then begin
    if c_tree_ptr_t(n)^.op = 26 then
      get_number_of_elements(c_tree_ptr_t(n)^.opnd[1], count, s, true)
    else
      count := 2147483647;
  end
  else if n^.kind = 109 then begin
    type_exp(c_sym_ptr_t(n)^.var_type, addr(tt));
    if (size <= 0) or (tt.base^.kind = 127) or
       ((tt.base^.kind = 130) and not under_addr) or
       (tt.base^.kind = 131) then
      count := 2147483647
    else
      count := tt.bytes div size;
    s := n;
  end
  else
    count := 2147483647;
end;

begin { check_for_out_of_bounds }
  get_number_of_elements(cexs_stack[k].node, count, s, false);
  if v >= count then
    c_sym_ptr_t(s)^.var_flags := c_sym_ptr_t(s)^.var_flags + [22];
end;

begin { expr_op }
  res_bool := false;
  x196 := 0;
  x260 := -1;
  x310 := false;
  bas := cexs_23bc - nargs + 1;
  ia := bas;
  ib := bas + 1;
  inset := op in [18, 27, 28, 32, 37..42, 51..61, 65];

  { Arrays and functions to pointers. }
  if not ((op = 19) or (op = 17)) then
    if not (((cexs_stack[bas].typ.base^.kind = 131) or
             (cexs_stack[bas].typ.base^.kind = 127)) and (op = 65)) then
      for i := bas to cexs_23bc do begin
        if ((cexs_stack[i].typ.base^.kind = 131) or
            (cexs_stack[i].typ.base^.kind = 127)) and
           (csyn_60[csyn_202] <> 4) and not ((i = bas) and inset) then
          with cexs_stack[i] do begin
            p := def_ptr(typ.base^.arr_elem, nil);
            p^.ptr_attr.bits := p^.ptr_attr.bits + typ.base^.arr_attr.bits;
            if typ.flags.b25_5 then
              p^.ptr_attr.bits := p^.ptr_attr.bits + [19];
            if typ.flags.b25_4 then
              p^.ptr_attr.bits := p^.ptr_attr.bits + [0];
            type_exp(p, addr(typ));
            init_aux(desc, typ);
            add_tn(26, desc, i, i);
          end;
        if ((cexs_stack[i].typ.base^.kind = 234) or
            (cexs_stack[i].typ.base^.kind = 108)) and
           not ((i = bas) and inset) then begin
          save := cexs_23bc;
          cexs_23bc := i;
          nm.id := lex_tokens[ctk_amp];
          nm.line := cexs_stack[i].line;
          expr_op(17, addr(nm), 1);
          cexs_23bc := save;
        end;
      end;

  { Bit fields extracted. }
  first := bas;
  if (op = 27) or (op = 65) or (op = 28) then
    first := bas + 1;
  for i := first to cexs_23bc do
    with cexs_stack[i] do
      if sym <> nil then
        if (sym^.kind = 120) and not bf_done then begin
          bf_done := true;
          init_aux(desc, typ);
          f := c_field_ptr_t(sym);
          push_con(f^.bits.width);
          desc.w8 := f^.bits.at;
          w := f^.bits.width + f^.bits.at;
          if w <= 8 then
            desc.w6 := 1
          else if w <= 16 then
            desc.w6 := 2
          else
            desc.w6 := 4;
          desc.flags.b6 := f^.bits.signed;
          if i <> cexs_23bc - 1 then begin
            cexs_23bc := cexs_23bc + 1;
            cexs_stack[cexs_23bc] := cexs_stack[cexs_23bc - 1];
            cexs_stack[cexs_23bc - 1] := cexs_stack[i];
            add_tn(14, desc, cexs_23bc - 1, cexs_23bc);
            cexs_stack[i] := cexs_stack[cexs_23bc];
            cexs_23bc := cexs_23bc - 1;
          end
          else
            add_tn(14, desc, i, cexs_23bc);
        end;

  if op = 22 then
    return;
  if op = 24 then begin
    ib := cexs_23bc;
    ia := ib - 1;
  end;

  { The operands' classes. }
  bad1 := false;
  bad2 := false;
  tnop := op_tab[op].tnop;
  if op_tab[op].left <> 0 then begin
    cls := exp_class[op_tab[op].left];
    bad1 := not (cexs_stack[ia].typ.base^.kind in cls);
  end;
  if op_tab[op].right <> 0 then begin
    cls := exp_class[op_tab[op].right];
    bad2 := not (cexs_stack[ib].typ.base^.kind in cls);
  end;
  if bad1 or bad2 then begin
    if bad1 and bad2 then
      error3(68, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym, name^.id)
    else if bad1 then
      error2(69, name^.line, cexs_stack[ia].sym, name^.id)
    else
      error2(69, name^.line, cexs_stack[ib].sym, name^.id);
    goto 99;
  end;

  { A floating operand makes the other floating. }
  ta := cexs_stack[ia].typ.base;
  tb := cexs_stack[ib].typ.base;
  if (nargs > 1) and not (op in [18, 27, 28, 44, 65]) then
    if (((tb^.kind = 129) or (tb^.kind = 122)) and (ta^.kind = 123)) or
       ((tb^.kind = 123) and ((ta^.kind = 129) or (ta^.kind = 122))) then begin
      if ta^.kind = 123 then
        ft := ta
      else
        ft := tb;
      float_operand(ia, ft);
      float_operand(ib, ft);
      ta := cexs_stack[ia].typ.base;
      tb := cexs_stack[ib].typ.base;
    end;

  if not (((op = 50) or (op = 49) or (op = 8) or (op = 9)) and
          ((ta^.kind = 130) or (tb^.kind = 130)) and
          (get_oc(ia) = 0)) then begin
    { The wider or constant operand second. }
    swapped := false;
    if (nargs > 1) and not (op in [18, 27, 28, 44, 65]) then
      if cexs_stack[ia].typ.base^.kind in [122, 123, 129, 134, 136] then begin
        m := cexs_stack[ib].typ.size - cexs_stack[ia].typ.size;
        if m = 0 then begin
          sa := ((cexs_stack[ia].typ.base^.kind = 122) and
                 cexs_stack[ia].typ.base^.signed) or
                ((cexs_stack[ia].typ.base^.kind = 129) and
                 cexs_stack[ia].typ.base^.enum_int^.signed);
          sb := ((cexs_stack[ib].typ.base^.kind = 122) and
                 not cexs_stack[ib].typ.base^.signed) or
                ((cexs_stack[ib].typ.base^.kind = 129) and
                 not cexs_stack[ib].typ.base^.enum_int^.signed);
          if sa and sb and (op <> 30) then
            swapped := true;
        end;
        if (m > 0) and (cexs_stack[ib].node^.kind <> 89) then
          swapped := true
        else if (m < 0) and (cexs_stack[ia].node^.kind = 89) then
          swapped := true;
      end;
    if swapped then begin
      k := ia;
      ia := ib;
      ib := k;
    end;
    if op_tab[op].coerce and (nargs > 1) then
      if (op = 43) or (op = 31) or (op = 29) or (op = 30) then
        do_coerce
      else
        double_coerce;
    ta := cexs_stack[ia].typ.base;
    tb := cexs_stack[ib].typ.base;
  end;

  for i := cexs_23bc - nargs + 1 to cexs_23bc do
    if cexs_stack[i].typ.base = c_type_ptr_t(il_178) then
      goto 99;
  init_aux(desc, cexs_stack[ia].typ);
  oc := get_oc(ia);

  case op of

    { Comparisons. }
    0, 1, 2, 3, 4, 5: begin
      desc.w6 := cexs_cond[op];
      case oc of
        0: scl_cmp(desc, bas, bas + 1, op);
        1:
          if (op = 3) or (op = 2) then begin
            if op = 2 then
              k := cexs_23bc
            else
              k := bas;
            add_tn(8, desc, k, k);
            add_tn(9, desc, bas, cexs_23bc);
            push_con(0);
            desc.w6 := cexs_cond[0];
          end;
        2:
          if (op = 0) or (op = 1) then
            tnop := 24
          else
            tnop := 23;
        3: desc.rlen := desc.size;
        4: tnop := 24;
        5: tnop := 40;
        otherwise ;
      end;
      desc.w8 := desc.w6;
      desc.w6 := desc.rlen;
      desc.rlen := 1;
      boolean_result;
    end;

    7:
      desc.rlen := cexs_stack[cexs_23bc].typ.size;

    { Addition. }
    8, 49:
      case oc of
        0:
          if (ta^.kind = 130) or (tb^.kind = 130) then begin
            if (ta^.kind = 130) and (tb^.kind = 130) then begin
              error2(124, name^.line, cexs_stack[ia].sym, cexs_stack[ib].sym);
              goto 99;
            end;
            if ta^.kind <> 130 then begin
              swap_top;
              ta := cexs_stack[ia].typ.base;
              tb := cexs_stack[ib].typ.base;
              init_aux(desc, cexs_stack[ia].typ);
            end;
            if (tb^.kind <> 122) and (tb^.kind <> 129) then begin
              error1(125, name^.line, cexs_stack[ib].sym);
              goto 99;
            end;
            p := ta^.ptr_to;
            while p^.kind = 118 do
              p := c_sym_ptr_t(p)^.td_type;
            if p^.kind = 234 then begin
              error1(120, name^.line, cexs_stack[ia].sym);
              goto 99;
            end;
            if p^.kind = 210 then begin
              error1(250, name^.line, cexs_stack[ia].sym);
              goto 99;
            end;
            esz := (ta^.ptr_attr.size_bits + 7) div 8;
            if esz = 0 then
              error1(286, name^.line, cexs_stack[ia].sym)
            else if esz > 1 then
              if (cexs_stack[ib].node^.kind in [77..87, 101, 200]) and
                 (cexs_stack[ib].node^.int_value = 1) then begin
                cexs_23bc := cexs_23bc - 1;
                push_con(esz);
              end
              else begin
                push_con(esz);
                expr_op(11, name, 2);
              end;
            adjust_length(ib, 1, 4);
            if (cexs_stack[ib].node^.kind in [80..86, 200]) and (esz > 0) then
              check_for_out_of_bounds(ia,
                  cexs_stack[ib].node^.int_value div esz, esz);
          end
          else begin
            sa := result_signedness(cexs_stack[bas].typ.base^.signed,
                                    cexs_stack[bas].typ.size,
                                    cexs_stack[bas + 1].typ.base^.signed,
                                    cexs_stack[bas + 1].typ.size,
                                    cargs_$options.xansi);
            if op = 8 then begin
              adjust_length(bas, 1, 4);
              adjust_length(bas + 1, 1, 4);
            end;
            double_coerce;
            if op = 8 then begin
              w := arith(0, cexs_stack[bas].typ.high,
                         cexs_stack[bas + 1].typ.high);
              v := arith(0, cexs_stack[bas].typ.low,
                         cexs_stack[bas + 1].typ.low);
              if not sa then
                v := 0;
              cexs_stack[bas].typ.low := v;
              cexs_stack[bas].typ.high := w;
            end;
            init_aux(desc, cexs_stack[ia].typ);
            desc.flags.b6 := sa;
          end;
        1: begin
          do_coerce;
          tnop := 10;
        end;
        2: begin
          do_coerce;
          tnop := 20;
        end;
        5: begin
          do_coerce;
          tnop := 34;
        end;
        otherwise ;
      end;

    { Subtraction. }
    9, 50:
      case oc of
        0:
          if (ta^.kind = 130) or (tb^.kind = 130) then begin
            if ta^.kind = 130 then begin
              p := ta^.ptr_to;
              while p^.kind = 118 do
                p := c_sym_ptr_t(p)^.td_type;
              if p^.kind = 234 then begin
                error1(120, name^.line, cexs_stack[ia].sym);
                goto 99;
              end;
              if p^.kind = 210 then begin
                error1(250, name^.line, cexs_stack[ia].sym);
                goto 99;
              end;
            end;
            if (ta^.kind = 130) and (tb^.kind = 130) then begin
              discard(coerce(cexs_stack[ia].typ, ib, true));
              x196 := (ta^.ptr_attr.size_bits + 7) div 8;
              if x196 = 0 then
                error1(286, name^.line, cexs_stack[ia].sym)
              else if (tb^.ptr_attr.size_bits + 7) div 8 <> x196 then begin
                x196 := 0;
                error2(126, name^.line, cexs_stack[ia].sym,
                       cexs_stack[ib].sym);
                goto 99;
              end;
              type_exp(int_type, addr(cexs_stack[ia].typ));
              type_exp(int_type, addr(cexs_stack[ib].typ));
              init_aux(desc, cexs_stack[ia].typ);
            end
            else begin
              if not ((ta^.kind = 130) and (tb^.kind = 122)) then begin
                error2(127, name^.line, cexs_stack[ia].sym,
                       cexs_stack[ib].sym);
                goto 99;
              end;
              esz := (ta^.ptr_attr.size_bits + 7) div 8;
              if esz = 0 then
                error1(286, name^.line, cexs_stack[ia].sym)
              else if esz > 1 then begin
                push_con(esz);
                expr_op(11, name, 2);
              end;
              adjust_length(ib, 1, 4);
            end;
          end
          else begin
            if op = 9 then begin
              w := cexs_stack[bas].typ.high - cexs_stack[bas + 1].typ.low;
              v := cexs_stack[bas].typ.low - cexs_stack[bas + 1].typ.high;
            end;
            sa := result_signedness(cexs_stack[bas].typ.base^.signed,
                                    cexs_stack[bas].typ.size,
                                    cexs_stack[bas + 1].typ.base^.signed,
                                    cexs_stack[bas + 1].typ.size,
                                    cargs_$options.xansi);
            if not sa then
              v := 0;
            if op = 9 then begin
              if w < v then begin
                w := 2147483647;
                if sa then
                  v := -2147483647;
              end;
              if (cexs_stack[bas].typ.size = 1) or
                 (cexs_stack[bas].typ.size = 2) then begin
                adjust_length(bas, 1, 4);
                if cargs_$options.xansi then
                  cexs_stack[bas].typ.base := int_type;
              end;
              if (cexs_stack[bas + 1].typ.size = 1) or
                 (cexs_stack[bas + 1].typ.size = 2) then begin
                adjust_length(bas + 1, 1, 4);
                if cargs_$options.xansi then
                  cexs_stack[bas + 1].typ.base := int_type;
              end;
            end;
            double_coerce;
            if op = 9 then begin
              cexs_stack[bas].typ.high := w;
              cexs_stack[bas].typ.low := v;
            end;
            init_aux(desc, cexs_stack[bas].typ);
            desc.flags.b6 := sa;
          end;
        1: begin
          do_coerce;
          add_tn(8, desc, cexs_23bc, cexs_23bc);
          tnop := 9;
        end;
        2: begin
          do_coerce;
          tnop := 21;
        end;
        5: begin
          do_coerce;
          tnop := 35;
        end;
        otherwise ;
      end;

    { Multiplication (47: of a subscript by its element size). }
    11, 47: begin
      if op = 47 then begin
        x310 := true;
        oc := 0;
      end;
      case oc of
        0: begin
          if cexs_stack[bas].node^.kind in [80..86, 200] then
            swap_top;
          desc.flags.b6 := result_signedness(
              cexs_stack[bas].typ.base^.signed, cexs_stack[bas].typ.size,
              cexs_stack[bas + 1].typ.base^.signed,
              cexs_stack[bas + 1].typ.size, cargs_$options.xansi);
          mult_div_mod_prep;
          desc.rlen := 2;
          if cexs_stack[bas].typ.size = 2 then begin
            type_exp(cexs_stack[bas].typ.base, addr(it));
            it.size := 4;
            discard(coerce(it, bas, true));
          end;
          if cexs_stack[bas + 1].typ.size = 2 then begin
            type_exp(cexs_stack[bas + 1].typ.base, addr(it));
            it.size := 4;
            discard(coerce(it, bas + 1, true));
          end;
          w := cexs_stack[bas].typ.low;
          if w < 0 then
            w := -w;
          if w < 0 then
            w := 2147483647;
          if w < cexs_stack[bas].typ.high then
            w := cexs_stack[bas].typ.high;
          v := cexs_stack[bas + 1].typ.low;
          if v < 0 then
            v := -v;
          if v < 0 then
            v := 2147483647;
          if v < cexs_stack[bas + 1].typ.high then
            v := cexs_stack[bas + 1].typ.high;
          v := arith(2, w, v);
          if desc.flags.b6 then begin
            w := -v;
            if v > 32767 then
              desc.rlen := 4;
          end
          else begin
            w := 0;
            if v > 65535 then
              desc.rlen := 4
            else if x310 then
              if v > 32767 then
                desc.rlen := 4;
          end;
          if desc.rlen = 2 then begin
            adjust_length(bas, 1, 2);
            adjust_length(bas + 1, 1, 2);
          end;
          desc.w6 := cexs_stack[bas].typ.size;
          desc.w8 := cexs_stack[bas + 1].typ.size;
          if power_of_two then begin
            cexs_23bc := cexs_23bc - 1;
            desc.rlen := 4;
            adjust_length(bas, 1, desc.rlen);
            if neg then
              expr_op(21, name, 1);
            push_con(shift);
            tnop := 27;
            desc.w8 := 1;
          end;
          cexs_stack[bas].typ.size := desc.rlen;
          desc.size := desc.rlen;
          cexs_stack[bas].typ.low := w;
          cexs_stack[bas].typ.high := v;
          mult_div_mod_sign(bas, desc.flags.b6);
        end;
        1: begin
          do_coerce;
          tnop := 9;
        end;
        2: begin
          do_coerce;
          tnop := 19;
        end;
        5: begin
          do_coerce;
          tnop := 36;
        end;
        otherwise ;
      end;
    end;

    { Division. }
    12:
      if oc = 5 then begin
        tnop := 37;
        do_coerce;
      end
      else begin
        desc.flags.b6 := result_signedness(
            cexs_stack[bas].typ.base^.signed, cexs_stack[bas].typ.size,
            cexs_stack[bas + 1].typ.base^.signed,
            cexs_stack[bas + 1].typ.size, cargs_$options.xansi);
        mult_div_mod_prep;
        if not cexs_stack[bas].typ.base^.signed and power_of_two then begin
          cexs_23bc := cexs_23bc - 1;
          push_con(shift);
          expr_op(43, name, 2);
          if neg then
            expr_op(21, name, 1);
          tnop := 0;
        end
        else begin
          with cexs_stack[bas] do
            if cexs_stack[bas + 1].typ.low < 0 then
              if -typ.high < typ.low then
                typ.low := -typ.high
              else if -typ.low > typ.high then
                typ.high := -typ.low;
          desc.rlen := cexs_stack[bas].typ.size;
          desc.size := cexs_stack[bas].typ.size;
          desc.w6 := cexs_stack[bas].typ.size;
          desc.w8 := cexs_stack[bas + 1].typ.size;
          adjust_length(bas, 1, 4);
          adjust_length(bas + 1, 1, 4);
          desc.rlen := 4;
          desc.size := 4;
          desc.w6 := 4;
          desc.w8 := 4;
        end;
        mult_div_mod_sign(bas, desc.flags.b6);
      end;

    { Remainder: by a power of two, a mask. }
    14: begin
      n := cexs_stack[bas + 1].node;
      if (n^.kind = 80) or (n^.kind = 82) or (n^.kind = 81) then begin
        v := n^.int_value;
        if (cexs_stack[bas].typ.low >= 0) and (v > 0) and
           (((v - 1) & v) = 0) then begin
          w := v - 1;
          cexs_stack[bas + 1].node := smcontk(81, w);
          cexs_stack[bas + 1].typ.high := w;
          cexs_stack[bas + 1].typ.low := w;
          expr_op(33, name, 2);
          return;
        end;
      end;
      desc.flags.b6 := result_signedness(
          cexs_stack[bas + 1].typ.base^.signed,
          cexs_stack[bas + 1].typ.size,
          cexs_stack[bas].typ.base^.signed, cexs_stack[bas].typ.size,
          cargs_$options.xansi);
      adjust_length(bas, 1, 4);
      adjust_length(bas + 1, 1, 4);
      desc.rlen := cexs_stack[bas + 1].typ.size;
      desc.w6 := cexs_stack[bas].typ.size;
      desc.w8 := cexs_stack[bas + 1].typ.size;
      if desc.w6 = 2 then begin
        adjust_length(bas, 1, 4);
        desc.w6 := 4;
        desc.size := 2;
      end;
      cexs_stack[bas].typ.size := cexs_stack[bas + 1].typ.size;
      mult_div_mod_sign(bas, desc.flags.b6);
      type_exp(cexs_stack[bas].typ.base, addr(it));
      cexs_stack[bas].typ.low := it.low;
      cexs_stack[bas].typ.high := it.high;
    end;

    { Logical not, or, and. }
    16, 25, 26: begin
      if op <> 16 then begin
        test_ne_zero;
        swap_top;
      end;
      test_ne_zero;
      x260 := 0;
      type_exp(int_type, addr(cexs_stack[cexs_23bc].typ));
      init_aux(desc, cexs_stack[cexs_23bc].typ);
    end;

    { Address of. }
    17: begin
      tnop := 26;
      with cexs_stack[bas] do begin
        if node^.kind = 109 then begin
          c_sym_ptr_t(node)^.var_flags := c_sym_ptr_t(node)^.var_flags + [21];
          if typ.flags.ranged then
            flag_61 := true;
        end;
        p := typ.base;
        q5 := typ.flags.b25_5;
        q4 := typ.flags.b25_4;
        if (p^.kind = 131) or (p^.kind = 127) then begin
          ft := typ.base^.arr_elem;
          q5 := q5 or (19 in typ.base^.arr_attr.bits);
          q4 := q4 or (0 in typ.base^.arr_attr.bits);
          type_exp(ft, addr(typ));
        end
        else if p^.kind = 108 then begin
          blk := c_blk_ptr_t(p);
          sa := blk^.bits.db_adjusted;
          blk^.bits.b374_3 := true;
          blk^.bits.db_adjusted := true;
          if not sa and (blk^.bits.x376_0 = 0) then begin
            ft := p;
            adjust_blk_for_db(ft);
            p := ft;
          end;
          off := 0;
          node := get_addr_con(4, il_$node_ptr_t(p), off,
                               c_blk_ptr_t(il_180)^.data_sect, false);
          tnop := 0;
          fd.dtype := blk^.result;
          attr20_ptr_t(addr(fd.flags))^ := attr20_ptr_t(addr(blk^.attr))^;
          ft := def_func(fd, nil, blk^.bits.conv,
                         rshft(int32_ptr_t(addr(blk^.bits))^, 11),
                         blk^.params, integer32(blk^.old_parms), 0);
        end
        else
          ft := typ.node;
        p := def_ptr(ft, nil);
        p^.ptr_attr.size_bits := typ.bytes * 8;
        type_exp(p, addr(typ));
        if q5 then
          typ.base^.ptr_attr.bits := typ.base^.ptr_attr.bits + [19];
        if q4 then
          typ.base^.ptr_attr.bits := typ.base^.ptr_attr.bits + [0];
        init_aux(desc, typ);
      end;
    end;

    { Calls and builtins. }
    18, 32, 37, 38, 39, 40, 41, 42, 51, 52, 53, 54, 55, 56, 57, 58, 59,
    60, 61:
      with cexs_stack[bas] do begin
        if typ.base^.kind = 234 then begin
          isfn := true;
          pl := typ.base^.fn_params;
          conv := typ.base^.fn_conv;
          rt := typ.base^.fn_result;
          if conv = 4 then begin
            type_exp(rt, addr(typ));
            init_aux(desc, typ);
            goto 98;
          end;
        end
        else begin
          node := il_$node_ptr_t(typ.base);
          isfn := false;
          pl := c_blk_ptr_t(node)^.params;
          conv := c_blk_ptr_t(node)^.bits.conv;
          rt := c_blk_ptr_t(node)^.result;
        end;
        if cargs_$options.type_opt and (pl <> nil) then begin
          if pl^.types[pl^.count]^.kind = 31 then begin
            maxn := 32767;
            minn := pl^.count - 1;
          end
          else if pl^.types[pl^.count]^.kind = 210 then begin
            minn := 0;
            maxn := 0;
          end
          else begin
            minn := pl^.count;
            maxn := pl^.count;
          end;
          if nargs - 1 < minn then
            error1(82, line, sym)
          else if nargs - 1 > maxn then
            error1(81, line, sym)
          else begin
            k := bas + 1;
            j := 1;
            for m := 1 to pl^.count do begin
              p := pl^.types[j];
              if (p^.kind = 31) or (p^.kind = 210) then
                goto 97;
              type_exp(p, addr(it));
              type_exp(cexs_stack[k].typ.base, addr(at));
              diff := it.base^.kind <> at.base^.kind;
              if p^.kind = 123 then
                float_operand(k, p);
              if (((at.base^.kind = 122) or (at.base^.kind = 129)) and
                  (it.base^.kind = 130)) or
                 ((at.base^.kind = 130) and
                  ((it.base^.kind = 122) or (it.base^.kind = 129))) then
                if (it.base^.kind = 130) and (at.base^.kind = 122) and
                   ((cexs_stack[k].node^.kind = 80) or
                    (cexs_stack[k].node^.kind = 82) or
                    (cexs_stack[k].node^.kind = 81)) and
                   (cexs_stack[k].node^.int_value = 0) then
                  diff := false
                else
                  error1(221, line, smcontk(81, j));
              if coerce(it, k, true) then begin
                if diff then
                  error2(216, line, smcontk(81, j), sym);
              end
              else
                error2(83, line, smcontk(81, j), sym);
              k := k + 1;
              j := j + 1;
            end;
          end;
        end;
97:
        type_exp(rt, addr(typ));
        if not isfn then
          attr_set_align_dsc(node, addr(typ));
        if typ.size > 32768 then
          error1(121, line, sym);
        init_aux(desc, typ);
        if conv = 4 then
          goto 98;
        top := cexs_23bc;
        k := bas + 1;
        if op <> 18 then begin
          build_builtin_tree(op, bas, cexs_23bc);
          goto 96;
        end;
        add_tn(tnop, desc, bas, top);
        cexs_23bc := bas;
        t := cexs_stack[cexs_23bc].node;
        n := gspace((c_tree_ptr_t(t)^.count - 1) * 4 + 20);
        n^.kind := 171;
        n^.xw[2] := 0;
        n^.xw[3] := 0;
        n^.xp[4] := c_tree_ptr_t(t)^.opnd[1];
        c_tree_ptr_t(t)^.opnd[1] := n;
        j := 0;
        for i := k to top do begin
          n^.xw[10 + j] := cexs_stack[i].typ.size;
          n^.xw[11 + j] := get_rlen(cexs_stack[i].typ);
          j := j + 2;
        end;
        goto 96;
      end;

    { Subscript. }
    19:
      with cexs_stack[bas] do begin
        if (typ.base^.kind <> 130) and (typ.base^.kind <> 131) and
           (typ.base^.kind <> 127) then begin
          error1(65, name^.line, sym);
          typ.base := c_type_ptr_t(il_178);
          goto 98;
        end;
        if typ.base^.kind = 130 then begin
          type_exp(typ.base^.ptr_to, addr(it));
          if it.base^.kind = 234 then begin
            error1(120, name^.line, sym);
            goto 99;
          end;
          esz := (typ.base^.ptr_attr.size_bits + 7) div 8;
          type_exp(int_type, addr(it));
          it.low := 0;
          it.high := -1;
        end
        else begin
          type_exp(typ.base^.arr_index, addr(it));
          esz := typ.base^.arr_elsize;
        end;
        if esz = 0 then
          error1(286, name^.line, sym);
        unb := cargs_$options.indexl;
        if unb or (it.high < 1) or (typ.base^.kind = 130) then begin
          unb := true;
          it.high := 2147483647;
          it.size := 4;
        end;
        if (cexs_stack[bas + 1].typ.base^.kind <> 122) and
           (cexs_stack[bas + 1].typ.base^.kind <> 129) then
          error2(71, name^.line, cexs_stack[bas + 1].sym, sym);
        offset := offset - it.low * esz;
        n := cexs_stack[bas + 1].node;
        if n^.kind = 137 then
          if (c_tree_ptr_t(n)^.op = 2) or (c_tree_ptr_t(n)^.op = 1) then begin
            c := c_tree_ptr_t(n)^.opnd[2];
            if (c^.kind = 80) or (c^.kind = 82) or (c^.kind = 81) then begin
              v := c^.int_value;
              if c_tree_ptr_t(n)^.op = 2 then
                v := -v;
              it.low := it.low - v;
              it.high := it.high - v;
              offset := offset + v * esz;
              cexs_stack[bas + 1].node := c_tree_ptr_t(n)^.opnd[1];
            end;
          end;
        adjust_uc(cexs_stack[bas + 1].node, 1);
        cc_walk_it(cexs_stack[bas + 1].node, addr(call_kfold), false);
        adjust_uc(cexs_stack[bas + 1].node, -1);
        n := cexs_stack[bas + 1].node;
        if n^.kind in [77..87, 101, 200] then begin
          offset := offset + n^.int_value * esz;
          check_for_out_of_bounds(bas, n^.int_value, esz);
          if it.high <> 2147483647 then
            if (n^.int_value < it.low) or (n^.int_value > it.high) then
              if cargs_$options.subchk then
                error2(155, name^.line, cexs_stack[bas + 1].sym, sym);
        end
        else begin
          if esz > 1 then begin
            if cexs_stack[bas + 1].typ.base^.kind = 129 then
              cexs_stack[bas + 1].typ.base :=
                  cexs_stack[bas + 1].typ.base^.enum_int;
            push_con(esz);
            expr_op(47, name, 2);
          end;
          adjust_length(cexs_23bc, 0, 2);
          if (cexs_stack[bas + 1].typ.size = 2) and
             (unb or (cexs_stack[bas + 1].typ.high > 32767)) then
            adjust_length(cexs_23bc, 1, 4);
          d5n := cexs_stack[bas + 1].node;
          it := cexs_stack[bas + 1].typ;
          long := (cexs_stack[bas + 1].typ.size = 4) or unb;
          cexs_23bc := cexs_23bc - 1;
          reference_operand(1);
          w := (it.high - it.low) * esz;
          n := cexs_stack[cexs_23bc].node;
          if (w > 32767) or (w < 0) or unb then
            if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
              c_tree_ptr_t(n)^.bits.post := true
            else if d5n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
              c_tree_ptr_t(d5n)^.bits.post := true;
          index := d5n;
          if long then
            bits.long_index := true;
        end;
        tnop := 0;
        p := typ.base;
        if p^.kind = 130 then begin
          type_exp(p^.ptr_to, addr(typ));
          typ.bytes := (p^.ptr_attr.size_bits + 7) div 8;
          attr_set_align_dsc(il_$node_ptr_t(p), addr(typ));
          typ.flags.b25_5 := 19 in p^.ptr_attr.bits;
          typ.flags.b25_4 := 0 in p^.ptr_attr.bits;
        end
        else begin
          q5 := typ.flags.b25_5;
          q4 := typ.flags.b25_4;
          type_exp(p^.arr_elem, addr(typ));
          typ.bytes := (p^.arr_attr.size_bits + 7) div 8;
          attr_set_align_dsc(il_$node_ptr_t(p), addr(typ));
          typ.flags.b25_5 := q5 or (19 in p^.arr_attr.bits);
          typ.flags.b25_4 := q4 or (0 in p^.arr_attr.bits);
        end;
      end;

    { Unary plus. }
    20:
      with cexs_stack[cexs_23bc] do
        if typ.base^.kind = 122 then begin
          adjust_length(cexs_23bc, 1, 4);
          init_aux(desc, cexs_stack[cexs_23bc].typ);
        end;

    { Unary minus. }
    21:
      with cexs_stack[cexs_23bc] do
        if typ.base^.kind = 123 then
          tnop := 38
        else if typ.base^.kind = 122 then
          if typ.base^.signed then begin
            w := typ.high;
            v := typ.low;
            typ.high := -v;
            typ.low := -w;
          end
          else begin
            adjust_length(cexs_23bc, 1, 4);
            init_aux(desc, cexs_stack[cexs_23bc].typ);
            cexs_stack[cexs_23bc].typ.high := 2147483647;
            cexs_stack[cexs_23bc].typ.low := 0;
          end;

    { Conditional: the result the wider of the two values' types. }
    24: begin
      if tb^.kind = 130 then begin
        k := ia;
        ia := ib;
        ib := k;
      end;
      if (ta^.kind = 122) and (tb^.kind = 122) then
        if csyn_60[csyn_202] = 4 then begin
          n := cexs_stack[ia].node;
          if n^.kind = 82 then
            type_exp(int_type, addr(cexs_stack[ia].typ))
          else if (n^.kind = 81) or (n^.kind = 80) then
            type_exp(short_type, addr(cexs_stack[ia].typ));
        end
        else if (cexs_stack[ia].node^.kind = 81) or
                (cexs_stack[ib].node^.kind = 81) then begin
          adjust_length(ia, 1, 4);
          adjust_length(ib, 1, 4);
        end;
      do_coerce;
      init_aux(desc, cexs_stack[ia].typ);
      w := cexs_stack[ib].typ.high;
      if w < cexs_stack[ib + 1].typ.high then
        w := cexs_stack[ib + 1].typ.high;
      cexs_stack[ia].typ.high := w;
      v := cexs_stack[ib].typ.low;
      if v > cexs_stack[ib + 1].typ.low then
        v := cexs_stack[ib + 1].typ.low;
      cexs_stack[ia].typ.low := v;
      cexs_23bc := cexs_23bc + 1;
      cexs_stack[cexs_23bc] := cexs_stack[bas];
      test_ne_zero;
      cexs_stack[bas] := cexs_stack[cexs_23bc];
      cexs_23bc := cexs_23bc - 1;
      cexs_stack[bas].typ := cexs_stack[ia].typ;
      cexs_stack[bas].sym := name^.id;
      case get_oc(ia) of
        2, 4: x260 := 6;
        3: begin
          x260 := 0;
          desc.rlen := desc.size;
        end;
        5: x260 := 11;
        otherwise
          x260 := 0;
      end;
    end;

    { Assignments (65: an initialization), postfix increments. }
    27, 28, 65: begin
      if op = 28 then
        tnop := 55
      else
        tnop := 54;
      if (op <> 65) and cexs_stack[ia].typ.flags.b25_5 then
        error1(277, cexs_stack[ia].line, cexs_stack[ia].sym);
      if cexs_stack[ia].typ.base^.kind = 123 then
        float_operand(ib, cexs_stack[ia].typ.base);
      if name^.id^.idnt_name[1] <> '=' then begin
        case name^.id^.idnt_name[1] of
          '+': if op = 28 then k := 49 else k := 8;
          '-': if op = 28 then k := 50 else k := 9;
          '*': k := 11;
          '/': k := 12;
          '%': k := 14;
          '>': k := 30;
          '<': k := 29;
          '&': k := 33;
          '|': k := 34;
          '^': k := 45;
          otherwise ;
        end;
        cexs_23bc := cexs_23bc + 1;
        cexs_stack[cexs_23bc] := cexs_stack[cexs_23bc - 2];
        swap_top;
        expr_op(k, name, 2);
      end;
      sa := false;
      with cexs_stack[ib] do
        if typ.base^.kind = 210 then
          error1(37, il_d0, sym)
        else if (node^.kind = 137) and
                ((c_tree_ptr_t(node)^.op = 52) or
                 (c_tree_ptr_t(node)^.op = 57) or
                 (c_tree_ptr_t(node)^.op = 53)) then
          sa := false
        else begin
          if (typ.base^.kind = 122) and not typ.base^.signed and
             (typ.size <> cexs_stack[ia].typ.size) and
             (cexs_stack[ia].typ.size <= 4) then
            adjust_length(ib, 1, cexs_stack[ia].typ.size);
          sa := true;
        end;
      if sa then
        do_coerce;
      init_aux(desc, cexs_stack[ia].typ);
      case oc of
        2, 4: x260 := 6;
        3: begin
          x260 := 0;
          desc.rlen := desc.size;
        end;
        5: x260 := 11;
        otherwise begin
          x260 := 0;
          if cexs_stack[ia].sym <> nil then
            if cexs_stack[ia].sym^.kind = 120 then begin
              f := c_field_ptr_t(cexs_stack[ia].sym);
              if f^.bits.width + f^.bits.at > 16 then begin
                k := 32;
                desc.rlen := 4;
              end
              else begin
                k := 16;
                desc.rlen := 2;
              end;
              m := cexs_stack[ia].typ.size;
              cexs_stack[ia].typ.size := desc.rlen;
              discard(coerce(cexs_stack[ia].typ, ib, true));
              cexs_stack[ia].typ.size := m;
              n := cexs_stack[ib].node;
              x260 := 10;
              if (n^.kind = 80) or (n^.kind = 82) or (n^.kind = 81) then begin
                v := lshft(1, f^.bits.at) - 1;
                if (n^.int_value & v) = 0 then begin
                  x260 := 3;
                  if desc.rlen = 2 then
                    w := 65535
                  else
                    w := -1;
                  n := smcontk(81, ~lshft(v, k - f^.bits.width - f^.bits.at)
                                   & w);
                end
                else if (n^.int_value & v) = v then begin
                  x260 := 4;
                  n := smcontk(81, lshft(v, k - f^.bits.width - f^.bits.at));
                end;
              end;
              if x260 = 10 then begin
                desc.w6 := f^.bits.width;
                desc.w8 := f^.bits.at;
                desc.flags.b6 := true;
              end;
              cexs_stack[ib].node := n;
            end;
        end;
      end;
    end;

    { Shifts. }
    29, 30:
      with cexs_stack[bas] do begin
        if typ.size < 4 then
          adjust_length(bas, 1, 4);
        init_aux(desc, typ);
        desc.w6 := typ.size;
        if cexs_stack[bas + 1].node^.kind in [80..86, 200] then
          desc.w8 := desc.w6
        else
          desc.w8 := cexs_stack[bas + 1].typ.size;
        if typ.base^.signed then
          if tnop = 27 then
            tnop := 49
          else
            tnop := 50;
        typ.low := -2147483647;
        typ.high := 2147483647;
        n := cexs_stack[bas + 1].node;
        if n^.kind in [80..86, 200] then
          if n^.int_value < 0 then
            error1(94, cexs_stack[bas + 1].line, smcontk(81, n^.int_value));
      end;

    { Shift assignments. }
    31, 43:
      with cexs_stack[bas] do begin
        desc.w6 := typ.size;
        if cexs_stack[bas + 1].node^.kind in [80..86, 200] then
          desc.w8 := cexs_stack[bas + 1].typ.size
        else
          desc.w8 := desc.w6;
        if typ.base^.signed and (typ.low < 0) then
          if tnop = 27 then
            tnop := 49
          else
            tnop := 50;
      end;

    { The comma. }
    44: begin
      init_aux(desc, cexs_stack[ib].typ);
      tnop := 56;
      cexs_stack[bas].typ := cexs_stack[ib].typ;
    end;

    { Complement. }
    46:
      with cexs_stack[cexs_23bc] do
        if typ.base^.kind = 122 then begin
          if cargs_$options.xansi then
            if (typ.size = 1) or (typ.size = 2) then begin
              type_exp(int_type, addr(it));
              discard(coerce(it, cexs_23bc, true));
              init_aux(desc, it);
            end
            else if not typ.base^.signed then begin
              typ.high := 2147483647;
              typ.low := 0;
            end;
        end
        else if typ.base^.kind = 129 then
          if cargs_$options.xansi then begin
            type_exp(int_type, addr(it));
            discard(coerce(it, cexs_23bc, true));
            init_aux(desc, it);
          end;

    { The other operators: the common end (op_tab's tnop). }
    otherwise ;
  end;

98:
  if tnop <> 0 then
    add_tn(tnop, desc, bas, cexs_23bc);
  if (cexs_stack[bas].node^.kind = 137) and (tnop = 51) then
    cexs_stack[bas].node^.xl[1] := 0;
  cexs_23bc := bas;
  if x260 >= 0 then
    if cexs_stack[cexs_23bc].node^.kind = 137 then
      c_tree_ptr_t(cexs_stack[cexs_23bc].node)^.w18 := x260;
  goto 96;

99:
  cexs_stack[bas].typ.base := c_type_ptr_t(il_178);
  cexs_23bc := bas;

96:
  if res_bool then begin
    n := cexs_stack[cexs_23bc].node;
    if not ((n^.kind = 82) or (n^.kind = 81) or (n^.kind = 80)) then begin
      push_con(7);
      expr_op(43, name, 2);
      adjust_length(cexs_23bc, 1, 4);
    end
    else if n^.int_value <> 0 then
      cexs_stack[cexs_23bc].node := smcontk(n^.kind, 1);
  end;
  if x196 > 1 then begin
    push_con(x196);
    expr_op(12, name, 2);
  end;
end;

{ adjust_parm - the default argument promotions of the top entry when
  conv is set: an integer to 4 bytes, a float to double, an
  enumeration to 4 bytes (a constant only relabelled).

  0x04F974, 0xCC bytes, link #-36: the kinds compared in turn (122,
  123, 129); coerce's result not read.

  Not known from the original:
  - the names. }

procedure adjust_parm;
var
  tt: type_exp_t;                       { -32 }
begin
  with cexs_stack[cexs_23bc] do
    if typ.base^.kind = 122 then begin
      if conv then
        adjust_length(cexs_23bc, 1, 4);
    end
    else if typ.base^.kind = 123 then begin
      if conv and (typ.size <> 8) then begin
        type_exp(double_type, addr(tt));
        discard(coerce(tt, cexs_23bc, true));
      end;
    end
    else if typ.base^.kind = 129 then
      if conv and (typ.size <> 4) then
        if (node^.kind = 80) or (node^.kind = 82) or (node^.kind = 81) then
          typ.size := 4
        else
          adjust_length(cexs_23bc, 1, 4);
end;

{ test_ne_zero - the top entry becomes the boolean `operand != 0':
  a conversion (18) of a masked comparison result (`x & 7' or `x %
  7'-like trees of operators 50 or 28 with the constant 7, x a
  comparison 12, 23, 40 or 24) is replaced by the comparison itself;
  otherwise the operand is made an rvalue (expr_op 22), compared with 0
  or 0.0 (operator 12 or 40), a structure is diagnostic 70 and a void
  value 251, and the result is char 0..1.

  0x04FA40, 0x21A bytes, link #-64: the constant 0.0 is a double after
  the routine (`pea (0x04FC5A,PC)'); the result's bounds from
  boolean_result's constant (`lea (0x04BE22,PC)').

  Not known from the original:
  - the names. }

procedure test_ne_zero;
var
  nm: c_name_t;                         { -8 }
  desc: c_desc_t;                       { -24 }
  op: integer;                          { -38 }
  n, m, x, y, c, r: il_$node_ptr_t;
  pt: c_type_ptr_t;
begin
  r := nil;
  n := cexs_stack[cexs_23bc].node;
  if (n^.kind = 137) and (c_tree_ptr_t(n)^.op = 18) then begin
    m := c_tree_ptr_t(n)^.opnd[1];
    if m^.kind = 137 then
      if (c_tree_ptr_t(m)^.op = 50) or (c_tree_ptr_t(m)^.op = 28) then begin
        x := c_tree_ptr_t(m)^.opnd[1];
        y := c_tree_ptr_t(m)^.opnd[2];
        if x^.kind = 81 then
          c := x
        else if y^.kind = 81 then
          c := y
        else
          c := nil;
        if c <> nil then
          if c^.int_value = 7 then begin
            if c = x then
              x := y;
            if x^.kind = 137 then
              if (c_tree_ptr_t(x)^.op = 12) or (c_tree_ptr_t(x)^.op = 23) or
                 (c_tree_ptr_t(x)^.op = 40) or (c_tree_ptr_t(x)^.op = 24) then
                r := x;
          end;
      end;
  end;
  if r <> nil then
    cexs_stack[cexs_23bc].node := r
  else begin
    nm.id := il_178;
    expr_op(22, addr(nm), 1);
    init_aux(desc, cexs_stack[cexs_23bc].typ);
    if cexs_stack[cexs_23bc].typ.base^.kind = 123 then begin
      push_fcon(0.0);
      op := 40;
    end
    else begin
      push_con(0);
      op := 12;
    end;
    with cexs_stack[cexs_23bc - 1] do begin
      pt := typ.base;
      if pt^.kind = 132 then
        error3(70, line, sym, cexs_stack[cexs_23bc].sym, lex_tokens[ctk_ne])
      else if ((pt^.kind = 108) and (c_blk_ptr_t(pt)^.result^.kind = 210)) or
              (pt^.kind = 210) then
        error0(251, lex_line);
    end;
    desc.w6 := desc.rlen;
    desc.w8 := 6;
    desc.rlen := 1;
    add_tn(op, desc, cexs_23bc - 1, cexs_23bc);
    with cexs_stack[cexs_23bc] do begin
      typ.base := char_type;
      typ.low := 0;
      typ.high := 1;
      typ.size := 1;
      typ.flags.ranged := true;
    end;
  end;
end;

{ adjust_blk_for_db - enter the routine blk's parameters' names in it
  (blk_fnd_name; the count the byte at +293, the chain at +12, each
  entry's name at +8) and look at its result's class (a result of a
  class above 6 has its variable, +96, fetched and not used).

  0x04FC62, 0x8C bytes, link #-52: the loop a `dbf' of the count; the
  test `shi; tst.b; bpl'; the fetched variable left in A0.

  Not known from the original:
  - the names; what the fetched result variable was for. }

procedure adjust_blk_for_db;
type
  parm_ptr_t = ^parm_t;
  parm_t = record
    unused_0: integer32;                { +0 }
    next: parm_ptr_t;                   { +4 }
    name: c_name_t;                     { +8 }
  end;
var
  tt: type_exp_t;                       { -32 }
  b: c_blk_ptr_t;
  q: parm_ptr_t;
  r: c_sym_ptr_t;
  i: integer;
  big: boolean;
begin
  b := c_blk_ptr_t(blk);
  q := parm_ptr_t(il_$node_ptr_t(b)^.xp[3]);
  for i := 1 to ord(il_$node_ptr_t(b)^.xc[293]) do begin
    discard(blk_fnd_name(q^.name, true, false, b));
    q := q^.next;
  end;
  if b^.result^.kind <> 210 then begin
    type_exp(b^.result, addr(tt));
    big := get_rlen(tt) > 6;
    if big then
      r := b^.ret_var;
  end;
end;
