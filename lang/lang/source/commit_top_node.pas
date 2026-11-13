{ commit_top_node - COMMIT_TOP_, assignment operators (kind 140, the
  operator at +76) turned into operators on memory when their right
  side computes from their own left side: `x := x op y' becomes `x op=
  y' (aop_to_mem), a bit-field store of an or/and of a constant into
  one (pack_aop_to_mem); an assignment the user marked atomic that
  cannot be done atomically reported.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07561C  0x076FFC  pack_aop_to_mem
    0x07593A  0x07731A  aop_pattern_search
    0x075AAC  0x07748C  aop_to_mem
    0x075D8E  0x07776E  contains_same_lvalue
    0x075E7A  0x07785A  user_atomicness
    0x075F18  0x0778F8  implicit_atomicness
    0x075FB8  0x077998  commit_top_$convert_aops_to__aop_to_mem
    A5 0x1695EC (cc.m68k), 0x2E965C (cc.a88k): 4 bytes nothing reads
    (to const_op.ftn's A5).

  commit_top_$convert_aops_to__aop_to_mem is the only global routine;
  the others do not load A5 (internal).

  The nodes are read by offset (il.ins.pas's views): an assignment's
  left side +64, right side +68, operator +76, sizes +48..+56; a tree
  node's (137) operator +36, operands +40, +44.

  Not known from the original: every name but the routines' and the
  messages'; the operators' and the assignment operators' names (by
  number here).
}
module commit_top_node;

%include 'us/us/ins/ubase.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/commit_top_node.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { The address of an operand slot (aop_pattern_search's last
    parameter). }
  commit_top_slot_ptr_t = ^il_$node_ptr_t;

var
  unused_0: integer32;                  { +0x0: not read }

{ pack_aop_to_mem - n, a bit-field assignment (operator 10) not yet
  marked (+58 bit 6) whose right side (through kinds 189 and an
  operator 18) is an or (9, 10) or and (1, 2) of an integer constant
  with the field's own extraction (operator 14 of the same lvalue, its
  shift +28 and width the field's +56 and +54): the operator becomes
  1, 2, 3 or 4 and the right side the constant placed in the field's
  bits (for 9 the bits around the field set), the old right side's use
  counts dropped.

  0x07561C, 0x280 bytes: the integer constant kinds a set of 0..207
  (77..87, 101, 200; docs/dpc-gaps.md 8); the container's bits +52 * 8,
  the mask `lsr.l' of -1; trees_equivalent compared unsigned (`bhi');
  the widths zero-extended words; a `case' on the operator (a table of
  10 from 1).

  Not known from the original: the field and operator names; the
  unsigned forms of the comparisons. }

procedure pack_aop_to_mem(
    n: il_$node_ptr_t); options(val_param); internal;
var
  r: il_$node_ptr_t;
  inner: il_$node_ptr_t;
  lhs: il_$node_ptr_t;
  operand: il_$node_ptr_t;
  width: integer32;
  bits: integer32;
  mask: integer32;
  val: integer32;
  shift: integer32;
begin
  if (n = nil) or else (n^.kind <> assign_node) then
    bug_check('IL_UTILS_$\PACK_AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if n^.asg_op <> pack_aop then
    bug_check('IL_UTILS_$\PACK_AOP_TO_MEM --- node^.assign_node.op <> pack_aop.%.');
  if (ord(n^.xc[58]) & 16#40) <> 0 then
    return;
  r := n^.xp[17];
  if r^.kind = cse_parent_ob then
    return;
  if r^.kind = cse_use_ob then
    r := r^.xp[5];
  if (r^.kind = tree_node) and (r^.tr_op = extend_top) then
    r := r^.xp[10];
  if r^.kind <> tree_node then
    return;
  if not ((r^.tr_op = or_top) or (r^.tr_op = and_top) or
          (r^.tr_op = sub_top) or (r^.tr_op = add_top)) then
    return;
  operand := r^.xp[11];
  if not (operand^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob]) then
    return;
  inner := r^.xp[10];
  if inner^.kind = cse_parent_ob then
    inner := inner^.xp[1];
  if inner^.kind = cse_use_ob then
    inner := inner^.xp[5];
  lhs := n^.xp[16];
  if lhs^.kind = cse_use_ob then
    lhs := lhs^.xp[5];
  if lhs^.kind = cse_parent_ob then
    lhs := lhs^.xp[1];
  if inner^.kind = tree_node then begin
    operand := inner^.xp[10];
    if operand^.kind = cse_use_ob then
      operand := operand^.xp[5];
    if operand^.kind = cse_parent_ob then
      operand := operand^.xp[1];
  end;
  if inner^.kind <> tree_node then
    return;
  if il_utils_$trees_equivalent(lhs, operand) > 1 then
    return;
  if inner^.tr_op <> unpack_top then
    return;
  if not (inner^.xp[11]^.kind in [blogical_ob..char_ob, char16_ob,
                                  binteger_ob]) then
    return;
  width := n^.xw[27];
  if inner^.xp[11]^.xl[2] <> width then
    return;
  if inner^.xw[14] <> n^.xw[28] then
    return;
  bits := n^.xw[26] * 8;
  mask := rshft(-1, 32 - bits);
  val := 0;
  if r^.tr_op = and_top then begin
    shift := bits - width;
    if shift <= 31 then
      val := lshft(mask, shift) & mask;
    shift := n^.xw[28] + width;
    if shift < bits then
      val := val ! rshft(mask, shift);
  end;
  val := val ! lshft(r^.xp[11]^.xl[2], bits - (n^.xw[28] + width));
  case r^.tr_op of
    add_top: n^.asg_op := add_to_aop;
    sub_top: n^.asg_op := sub_from_aop;
    and_top: n^.asg_op := and_to_aop;
    or_top: n^.asg_op := or_to_aop;
    otherwise
      ;
  end;
  il_utils_$adjust_uc(r, -1);
  n^.xp[17] := smcontk(integer_ob, val);
end;

{ aop_pattern_search - the operand of the tree in slot (and below it,
  through operators that may be reordered) equivalent to n's left
  side, for a tree of lhs's operator: the result that operand, a the
  other operand, b the slot holding the tree; nil (a and b nil) when
  there is none.

  0x07593A, 0x158 bytes: the first operand tried first, the second for
  the commutative operators (a set of 0..47: 1, 3, 9, 10, 19, 20, 34,
  36, 44..46); the search goes down the operands of the associative
  ones (1, 3, 9, 10, 34, 36) when they are also in a set of 0..95
  (no range check) or with fpra (`btst #0,0x2C366A'); trees_equivalent
  compared unsigned; the result in A0 (`suba.l A0,A0' for nil). }

function aop_pattern_search(
    n: il_$node_ptr_t;
    lhs: il_$node_ptr_t;
    var slot: il_$node_ptr_t;
    var a: il_$node_ptr_t;
    var b: commit_top_slot_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r: il_$node_ptr_t;
begin
  if slot^.kind = tree_node then
    if slot^.tr_op = lhs^.tr_op then begin
      if il_utils_$trees_equivalent(n^.xp[16], slot^.xp[10]) <= 1 then begin
        r := slot^.xp[10];
        a := slot^.xp[11];
        b := addr(slot);
        aop_pattern_search := r;
        return;
      end;
      if slot^.tr_op in [add_top, mul_top, and_top, or_top, set_and_top,
                         set_or_top, f_add_top, f_mul_top, eor_top,
                         max_top, min_top] then
        if il_utils_$trees_equivalent(n^.xp[16], slot^.xp[11]) <= 1 then begin
          r := slot^.xp[11];
          a := slot^.xp[10];
          b := addr(slot);
          aop_pattern_search := r;
          return;
        end;
      if slot^.tr_op in [add_top, mul_top, and_top, or_top, f_add_top,
                         f_mul_top] then
        if (slot^.tr_op in [nop_top..or_top, index_top, unpack_top, value_top,
                              extend_top, lshf_top..abs_top, isc_mul_top,
                              expon_top..min_top, alshf_top..cc_logand_ptop,
                              cc_lognot_ptop,
                              signed_div_top..unsigned_mod_top,
                              isc_signed_rem_top..isc_unsigned_mod_top,
                              ada_expon_top]) or
           cargs_$options.fpra then begin
          r := aop_pattern_search(n, lhs, slot^.xp[10], a, b);
          if r <> nil then begin
            aop_pattern_search := r;
            return;
          end;
          r := aop_pattern_search(n, lhs, slot^.xp[11], a, b);
          if r <> nil then begin
            aop_pattern_search := r;
            return;
          end;
        end;
    end;
  a := nil;
  b := nil;
  aop_pattern_search := nil;
end;

{ aop_to_mem - n, an assignment of a tree whose operand (below
  operators 18) is n's left side, turned into the assignment operator
  of the tree's operator (1, 2, 9, 10, 19..21, 27, 28, 34..37, 44; 7
  and 8 with a 0 constant, 21 through a new kind 8 tree of the size),
  the operand replaced (il_utils_$do_substitution).  Operator 11 only
  with cpu 2, 4, 8, 9 or 10 and a size (+52) of 6 or 7; for operator 6
  (and the tree's 1, 2, 8, 9, 10, 44: a set of 0..47) at most 4 bytes
  (+48), +52 from +50.

  0x075AAC, 0x29E bytes: a `case' on the tree's operator (a table of
  44 from 1); the sizes compared unsigned (`bhi'); the frame
  temporary (-264) passed by address to buildtreenode.

  Not known from the original: the operators' names. }

procedure aop_to_mem(
    n: il_$node_ptr_t); options(val_param); internal;
var
  e: il_$node_ptr_t;
  slot: commit_top_slot_ptr_t;
  x: il_$node_ptr_t;
  y: commit_top_slot_ptr_t;
  r: il_$node_ptr_t;
  tmp: il_$node_ptr_t;
begin
  if (n = nil) or else (n^.kind <> assign_node) then
    bug_check('IL_UTILS_$\AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if n^.xp[17]^.kind <> tree_node then
    return;
  if n^.asg_op = fp_aop then begin
    if cargs_$options.cpu * [2, 4, 8, 9, 10] = [] then
      return;
    if not ((n^.xw[26] = 7) or (n^.xw[26] = 6)) then
      return;
  end;
  e := n^.xp[17];
  slot := addr(n^.xp[17]);
  while (e^.kind = tree_node) and (e^.tr_op = extend_top) do begin
    slot := addr(e^.xp[10]);
    e := e^.xp[10];
  end;
  r := aop_pattern_search(n, e, slot^, x, y);
  if r = nil then
    return;
  if n^.asg_op = agg_aop then
    if e^.tr_op in [add_top, sub_top, not_top, and_top, or_top,
                    eor_top] then begin
      if n^.xl[12] > 4 then
        return;
      n^.xw[26] := n^.xw[25];
    end;
  case e^.tr_op of
    add_top: n^.asg_op := add_to_aop;
    sub_top: n^.asg_op := sub_from_aop;
    neg_top: begin
      x := smcontk(integer_ob, 0);
      n^.asg_op := neg_to_aop;
    end;
    not_top: begin
      x := smcontk(integer_ob, 0);
      n^.asg_op := not_to_aop;
    end;
    and_top: n^.asg_op := and_to_aop;
    or_top: n^.asg_op := or_to_aop;
    set_and_top:
      if n^.xl[12] > 4 then
        n^.asg_op := set_and_to_aop
      else begin
        n^.xw[26] := n^.xw[25];
        n^.asg_op := and_to_aop;
      end;
    set_or_top:
      if n^.xl[12] > 4 then
        n^.asg_op := set_or_to_aop
      else begin
        n^.xw[26] := n^.xw[25];
        n^.asg_op := or_to_aop;
      end;
    set_diff_top:
      if n^.xl[12] > 4 then
        n^.asg_op := set_diff_from_aop
      else begin
        n^.asg_op := and_to_aop;
        n^.xw[26] := n^.xw[25];
        tmp := x;
        x := buildtreenode(not_top, n^.xl[12], tmp, 1);
        x^.xw[8] := 0;
      end;
    lshf_top: begin
      n^.asg_op := lshft_to_aop;
      n^.xw[27] := y^^.xw[13];
      n^.xw[28] := y^^.xw[14];
    end;
    rshf_top: begin
      n^.asg_op := rshft_to_aop;
      n^.xw[27] := y^^.xw[13];
      n^.xw[28] := y^^.xw[14];
    end;
    f_add_top: n^.asg_op := f_add_to_aop;
    f_sub_top: n^.asg_op := f_sub_from_aop;
    f_mul_top: n^.asg_op := f_mul_to_aop;
    f_div_top: n^.asg_op := f_div_by_aop;
    eor_top: n^.asg_op := eor_to_aop;
    otherwise
      return;
  end;
  il_utils_$do_substitution(n, y^, x);
end;

{ contains_same_lvalue - whether b (through kinds 189 and 190), or an
  operand of it as a tree, is the lvalue a: a variable or a tree of
  the kinds in a set of 0..207 (109, 145..147, 205; docs/dpc-gaps.md
  8) or a Fortran symbol of class 3 equivalent to a.

  0x075D8E, 0xD2 bytes: the result or-ed in D3 (`or.b D0,D3'); the
  operands from 2 for calls (16, 15), a word counter (`dbf' alone). }

function contains_same_lvalue(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); internal;
var
  r: boolean;
  first: integer;
  i: integer;
begin
  r := false;
  if a^.kind = cse_use_ob then
    a := a^.xp[5];
  if a^.kind = cse_parent_ob then
    a := a^.xp[1];
  if b^.kind = cse_use_ob then
    b := b^.xp[5];
  if b^.kind = cse_parent_ob then
    b := b^.xp[1];
  if (b^.kind in [var_name, dindex_node, ptr_node, disp_node, sym_disp_node])
      or
     ((b^.kind = fortran_symbol) and (rshft(ord(b^.xc[44]) & 16#F0,
                                            4) = 3)) then begin
    if il_utils_$trees_equivalent(a, b) = 0 then
      r := true;
  end
  else if b^.kind = tree_node then begin
    if (b^.tr_op = func_call_top) or (b^.tr_op = call_top) then
      first := 2
    else
      first := 1;
    for i := first to b^.xw[19] do
      r := r or contains_same_lvalue(a, b^.xp[9 + i]);
  end;
  contains_same_lvalue := r;
end;

{ user_atomicness - n's left side (+64) is atomic (getphase element
  0) and its right side a tree containing it.

  0x075E7A, 0x5C bytes. }

function user_atomicness(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  l: il_$node_ptr_t;
  r: il_$node_ptr_t;
begin
  if (n = nil) or else (n^.kind <> assign_node) then
    bug_check('IL_UTILS_$\USER_ATOMICNESS --- node^.kind is not an assign_node.%.');
  l := n^.xp[16];
  r := n^.xp[17];
  if (phase_atm in getphase(l)) and (r^.kind = tree_node) then
    user_atomicness := contains_same_lvalue(l, r)
  else
    user_atomicness := false;
end;

{ implicit_atomicness - n's left side is atomic and its operator 12 or
  10.

  0x075F18, 0x58 bytes. }

function implicit_atomicness(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  l: il_$node_ptr_t;
begin
  if (n = nil) or else (n^.kind <> assign_node) then
    bug_check('IL_UTILS_$\IMPLICIT_ATOMICNESS  --- node^.kind is not an assign_node.%.');
  l := n^.xp[16];
  if (phase_atm in getphase(l)) and ((n^.asg_op = field_aop) or
                                     (n^.asg_op = pack_aop)) then
    implicit_atomicness := true
  else
    implicit_atomicness := false;
end;

{ commit_top_$convert_aops_to__aop_to_mem - n, an assignment not
  marked (+41 bit 0): an assignment operator already (a set of 0..47
  without the range check: 26, 31..34) is an internal error; unless
  its left side's phase has element 20, operators 0, 6, 10 and 11 not
  in [1..5, 7..9, 13..24] are converted (10 by pack_aop_to_mem, the
  others by aop_to_mem; for 10 and 6 the variable's (109: +33, 110:
  +25) bit 5 set first); then cgerr 30 at n's line when the
  assignment is implicitly atomic, or atomic by the user and its
  operator not in that set.

  0x075FB8, 0xAC bytes past the A5 load: the operator in D2; the two
  sets of 0..31 as `move.l #'s (`btst D2,D1' after `cmp.w; bcs'); the
  message a varying string constant (a word 43, then the text; dpc
  passes the characters alone, docs/dpc-gaps.md 18). }

procedure commit_top_$convert_aops_to__aop_to_mem;
var
  op: il_$aop_t;
  user: boolean;
  l: il_$node_ptr_t;
begin
  if (t = nil) or else (t^.kind <> assign_node) then
    bug_check('IL_UTILS_$CONVERT_AOPS_TO__AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if t^.st_flags.stmt_eliminated then
    return;
  op := t^.asg_op;
  if op in [isc_mul_to_aop, isc_agg_aop..isc_fill_aop] then
    bug_check('IL_UTILS_$CONVERT_AOPS_TO__AOP_TO_MEM --- isc_aop???%.');
  if not (phase_proc_reg in getphase(t^.xp[16])) then
    if op in [scalar_aop, agg_aop, pack_aop, fp_aop] then
      if not (op in [add_to_aop..eor_to_aop, set_and_to_aop..set_diff_from_aop,
                     not_to_aop..div_by_aop]) then begin
        if (op = pack_aop) or (op = agg_aop) then begin
          l := t^.xp[17];
          case l^.kind of
            var_name: l^.xc[33] := chr(ord(l^.xc[33]) ! 16#20);
            fortran_symbol: l^.xc[25] := chr(ord(l^.xc[25]) ! 16#20);
            otherwise
              ;
          end;
        end;
        if op = pack_aop then
          pack_aop_to_mem(t)
        else
          aop_to_mem(t);
      end;
  user := user_atomicness(t);
  if implicit_atomicness(t) or
     (user and not (t^.asg_op in [add_to_aop..eor_to_aop,
                                  set_and_to_aop..set_diff_from_aop,
                                  not_to_aop..div_by_aop])) then
    cgerr(30, il_utils_$src_line(t),
        token_$make_string_token('Compiler may not guarantee atomic behavior.'));
end;
