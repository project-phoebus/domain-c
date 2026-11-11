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
  if (n = nil) or else (n^.kind <> 140) then
    bug_check('IL_UTILS_$\PACK_AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if n^.xw[38] <> 10 then
    bug_check('IL_UTILS_$\PACK_AOP_TO_MEM --- node^.assign_node.op <> pack_aop.%.');
  if (ord(n^.xc[58]) & 16#40) <> 0 then
    return;
  r := n^.xp[17];
  if r^.kind = 190 then
    return;
  if r^.kind = 189 then
    r := r^.xp[5];
  if (r^.kind = 137) and (r^.xw[18] = 18) then
    r := r^.xp[10];
  if r^.kind <> 137 then
    return;
  if not ((r^.xw[18] = 10) or (r^.xw[18] = 9) or (r^.xw[18] = 2) or
          (r^.xw[18] = 1)) then
    return;
  operand := r^.xp[11];
  if not (operand^.kind in [77..87, 101, 200]) then
    return;
  inner := r^.xp[10];
  if inner^.kind = 190 then
    inner := inner^.xp[1];
  if inner^.kind = 189 then
    inner := inner^.xp[5];
  lhs := n^.xp[16];
  if lhs^.kind = 189 then
    lhs := lhs^.xp[5];
  if lhs^.kind = 190 then
    lhs := lhs^.xp[1];
  if inner^.kind = 137 then begin
    operand := inner^.xp[10];
    if operand^.kind = 189 then
      operand := operand^.xp[5];
    if operand^.kind = 190 then
      operand := operand^.xp[1];
  end;
  if inner^.kind <> 137 then
    return;
  if il_utils_$trees_equivalent(lhs, operand) > 1 then
    return;
  if inner^.xw[18] <> 14 then
    return;
  if not (inner^.xp[11]^.kind in [77..87, 101, 200]) then
    return;
  width := n^.xw[27];
  if inner^.xp[11]^.xl[2] <> width then
    return;
  if inner^.xw[14] <> n^.xw[28] then
    return;
  bits := n^.xw[26] * 8;
  mask := rshft(-1, 32 - bits);
  val := 0;
  if r^.xw[18] = 9 then begin
    shift := bits - width;
    if shift <= 31 then
      val := lshft(mask, shift) & mask;
    shift := n^.xw[28] + width;
    if shift < bits then
      val := val ! rshft(mask, shift);
  end;
  val := val ! lshft(r^.xp[11]^.xl[2], bits - (n^.xw[28] + width));
  case r^.xw[18] of
    1: n^.xw[38] := 1;
    2: n^.xw[38] := 2;
    9: n^.xw[38] := 3;
    10: n^.xw[38] := 4;
    otherwise
      ;
  end;
  il_utils_$adjust_uc(r, -1);
  n^.xp[17] := smcontk(81, val);
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
  if slot^.kind = 137 then
    if slot^.xw[18] = lhs^.xw[18] then begin
      if il_utils_$trees_equivalent(n^.xp[16], slot^.xp[10]) <= 1 then begin
        r := slot^.xp[10];
        a := slot^.xp[11];
        b := addr(slot);
        aop_pattern_search := r;
        return;
      end;
      if slot^.xw[18] in [1, 3, 9, 10, 19, 20, 34, 36, 44, 45, 46] then
        if il_utils_$trees_equivalent(n^.xp[16], slot^.xp[11]) <= 1 then begin
          r := slot^.xp[11];
          a := slot^.xp[10];
          b := addr(slot);
          aop_pattern_search := r;
          return;
        end;
      if slot^.xw[18] in [1, 3, 9, 10, 34, 36] then
        if (slot^.xw[18] in [0..10, 13, 14, 17, 18, 27..29, 33, 43..46,
                              49..53, 57, 59..62, 74..77, 86]) or
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
  if (n = nil) or else (n^.kind <> 140) then
    bug_check('IL_UTILS_$\AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if n^.xp[17]^.kind <> 137 then
    return;
  if n^.xw[38] = 11 then begin
    if cargs_$options.cpu * [2, 4, 8, 9, 10] = [] then
      return;
    if not ((n^.xw[26] = 7) or (n^.xw[26] = 6)) then
      return;
  end;
  e := n^.xp[17];
  slot := addr(n^.xp[17]);
  while (e^.kind = 137) and (e^.xw[18] = 18) do begin
    slot := addr(e^.xp[10]);
    e := e^.xp[10];
  end;
  r := aop_pattern_search(n, e, slot^, x, y);
  if r = nil then
    return;
  if n^.xw[38] = 6 then
    if e^.xw[18] in [1, 2, 8, 9, 10, 44] then begin
      if n^.xl[12] > 4 then
        return;
      n^.xw[26] := n^.xw[25];
    end;
  case e^.xw[18] of
    1: n^.xw[38] := 1;
    2: n^.xw[38] := 2;
    7: begin
      x := smcontk(81, 0);
      n^.xw[38] := 14;
    end;
    8: begin
      x := smcontk(81, 0);
      n^.xw[38] := 13;
    end;
    9: n^.xw[38] := 3;
    10: n^.xw[38] := 4;
    19:
      if n^.xl[12] > 4 then
        n^.xw[38] := 7
      else begin
        n^.xw[26] := n^.xw[25];
        n^.xw[38] := 3;
      end;
    20:
      if n^.xl[12] > 4 then
        n^.xw[38] := 8
      else begin
        n^.xw[26] := n^.xw[25];
        n^.xw[38] := 4;
      end;
    21:
      if n^.xl[12] > 4 then
        n^.xw[38] := 9
      else begin
        n^.xw[38] := 3;
        n^.xw[26] := n^.xw[25];
        tmp := x;
        x := buildtreenode(8, n^.xl[12], tmp, 1);
        x^.xw[8] := 0;
      end;
    27: begin
      n^.xw[38] := 15;
      n^.xw[27] := y^^.xw[13];
      n^.xw[28] := y^^.xw[14];
    end;
    28: begin
      n^.xw[38] := 16;
      n^.xw[27] := y^^.xw[13];
      n^.xw[28] := y^^.xw[14];
    end;
    34: n^.xw[38] := 19;
    35: n^.xw[38] := 20;
    36: n^.xw[38] := 21;
    37: n^.xw[38] := 22;
    44: n^.xw[38] := 5;
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
  if a^.kind = 189 then
    a := a^.xp[5];
  if a^.kind = 190 then
    a := a^.xp[1];
  if b^.kind = 189 then
    b := b^.xp[5];
  if b^.kind = 190 then
    b := b^.xp[1];
  if (b^.kind in [109, 145, 146, 147, 205]) or
     ((b^.kind = 110) and (rshft(ord(b^.xc[44]) & 16#F0, 4) = 3)) then begin
    if il_utils_$trees_equivalent(a, b) = 0 then
      r := true;
  end
  else if b^.kind = 137 then begin
    if (b^.xw[18] = 16) or (b^.xw[18] = 15) then
      first := 2
    else
      first := 1;
    for i := first to b^.xw[19] do
      r := r or contains_same_lvalue(a, b^.xp[6 + i]);
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
  if (n = nil) or else (n^.kind <> 140) then
    bug_check('IL_UTILS_$\USER_ATOMICNESS --- node^.kind is not an assign_node.%.');
  l := n^.xp[16];
  r := n^.xp[17];
  if (0 in getphase(l)) and (r^.kind = 137) then
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
  if (n = nil) or else (n^.kind <> 140) then
    bug_check('IL_UTILS_$\IMPLICIT_ATOMICNESS  --- node^.kind is not an assign_node.%.');
  l := n^.xp[16];
  if (0 in getphase(l)) and ((n^.xw[38] = 12) or (n^.xw[38] = 10)) then
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
  op: integer;
  user: boolean;
  l: il_$node_ptr_t;
begin
  if (t = nil) or else (t^.kind <> 140) then
    bug_check('IL_UTILS_$CONVERT_AOPS_TO__AOP_TO_MEM --- node^.kind is not an assign_node.%.');
  if (ord(t^.xc[41]) & 1) <> 0 then
    return;
  op := t^.xw[38];
  if op in [26, 31, 32, 33, 34] then
    bug_check('IL_UTILS_$CONVERT_AOPS_TO__AOP_TO_MEM --- isc_aop???%.');
  if not (20 in getphase(t^.xp[16])) then
    if op in [0, 6, 10, 11] then
      if not (op in [1..5, 7..9, 13..24]) then begin
        if (op = 10) or (op = 6) then begin
          l := t^.xp[17];
          case l^.kind of
            109: l^.xc[33] := chr(ord(l^.xc[33]) ! 16#20);
            110: l^.xc[25] := chr(ord(l^.xc[25]) ! 16#20);
            otherwise
              ;
          end;
        end;
        if op = 10 then
          pack_aop_to_mem(t)
        else
          aop_to_mem(t);
      end;
  user := user_atomicness(t);
  if implicit_atomicness(t) or
     (user and not (t^.xw[38] in [1..5, 7..9, 13..24])) then
    cgerr(30, il_utils_$src_line(t),
        token_$make_string_token('Compiler may not guarantee atomic behavior.'));
end;
