{ opt_strength - strength reduction (cc.m68k): the induction variables
  of each loop (recognize_induction_variables), the products of them by
  loop constants replaced by temporaries stepped with the variable
  (reduce, create_sr_temp_var, add_assign), the temporaries combined and
  sized, uses rewritten (substitute, walkuses, ...) and, where the
  target allows, auto-increment addressing (autoinc); the products it
  forms (opt_str_$product_of: constants folded, multiplication by 1 or
  a shift by 0 a conversion, constants moved into an operand that is
  already a product) and the substitution points a strength reduction
  temporary records (opt_str_$set_substitution_point,
  opt_str_$add_substitution_point) serve opt_main and il_utils too.
  cc.a88k keeps only those helpers, deluse, delparent and walkuses;
  its strengthreduce is empty.

  Image addresses (DOMAIN C 6.9):
    cc.m68k   cc.a88k
    0x0E5E8C  --------  opt_str_$is_loop_constant_integer
    0x0E5F74  0x2B307C  opt_str_$product_of_consts
    0x0E6036  0x2B3158  sizeof_dataclass (in opt_str_$opmod_of_operand)
    0x0E606C  0x2B318E  opt_str_$opmod_of_operand
    0x0E61D6  --------  opt_str_$opmod1_of_multiplier
    0x0E61FA  0x2B32F8  identity_mul (in opt_str_$product_of)
    0x0E6290  0x2B338E  smuggle_constants (in opt_str_$product_of)
    0x0E63D2  0x2B34D0  opt_str_$product_of
    0x0E6656  0x2B3754  opt_str_$set_substitution_point
    0x0E66B6  0x2B37B4  opt_str_$add_substitution_point
    0x0E676A  --------  transformtemps
    0x0E6840  --------  is_invariant_srtemp
    0x0E689C  --------  multidim
    0x0E69A0  --------  unlinkstmts
    0x0E6AA4  --------  substitute
    0x0E6C6E  --------  stmtfound
    0x0E6D7E  --------  verify_increments
    0x0E6F30  --------  opt_str_$trees_equivalent
    0x0E70A6  --------  combine_temps
    0x0E729C  --------  usewalk (in used_outside_loop)
    0x0E73BE  --------  used_outside_loop
    0x0E7564  --------  substitute_ptr_for_target
    0x0E7668  --------  subwalk
    0x0E776A  --------  ptrsub
    0x0E7864  0x2B3976  deluse
    0x0E78B8  0x2B39CA  delparent
    0x0E790A  --------  match_rlens_srtemp_and_assign
    0x0E79FC  --------  doinsert
    0x0E7BFE  --------  check_tree_node
    0x0E7CEA  --------  opt_str_$is_loop_invariant
    0x0E7DB4  --------  check_dindex
    0x0E7EA8  --------  find_assigns
    0x0E7F74  --------  checkauto
    0x0E8176  --------  autoinc
    0x0E852A  0x2B3A1C  walkuses
    0x0E8798  --------  elimuses
    0x0E8912  --------  add_assign
    0x0E8E18  --------  getval
    0x0E8FFC  --------  not_on_ud_chain (in findvalues)
    0x0E9062  --------  noincfound (in findvalues)
    0x0E90F6  --------  findvalues
    0x0E9C50  --------  opt_str_$make_name
    0x0E9CBA  --------  create_sr_temp_var
    0x0E9E34  --------  setflag
    0x0E9E74  --------  removeflag
    0x0E9EB4  --------  newexpr
    0x0E9F58  --------  removeexpr
    0x0E9FAA  --------  walkexpr
    0x0EA0D8  --------  disqualify
    0x0EA248  --------  fetch_uc (in testexits)
    0x0EA292  --------  exitwalk (in testexits)
    0x0EA3A0  --------  testexits
    0x0EA562  --------  cand_exprs
    0x0EA674  --------  newindvar
    0x0EA71E  --------  recognize_induction_variables
    0x0EA96E  --------  dump_induction_variables
    0x0EAC16  --------  minimally_size_sr_temp
    0x0EACC8  --------  reduce
    0x0EBAF0  0x2B3ED4  strengthreduce
    A5 0x3530D8 (cc.m68k): the module's data, read by the routines not
    written yet (+32 .. +160); cc.a88k's unit (A5 0x513A84) has none.
    cc.a88k also holds, at 0x2B3868 (0x10E bytes, right after
    opt_str_$add_substitution_point), usewalk's code taking its
    parent's frame from the dynamic link, with no .blocks entry and no
    caller.

  The routines that load A5 are global (opt_str_$product_of,
  opt_str_$opmod_of_operand, walkuses, strengthreduce and delparent in
  g_opt.ins.pas; the substitution points in globals_from_general.ins.pas;
  opt_str_$product_of_consts and deluse only this unit calls);
  opt_str_$is_loop_constant_integer and opt_str_$opmod1_of_multiplier
  do not and are internal.  Trees are read through g_opt.ins.pas's
  g_opt_tree_t, the cse nodes through g_opt_cse_t, other nodes by
  offset.  delay.pas's class_size (its +888: the bytes of each register
  class) is read absolutely and declared here.

  dpc gaps (docs/dpc-gaps.md): 8 (`in' on the kind and operator sets).
  identity_mul, smuggle_constants and opt_str_$product_of set their
  pointer results from a local (dpc refuses a parameter or a cast
  there, gaps 11 and 15).
}

{ TODO(pascal) opt_strength.pas: the cc.m68k-only routines

  Written: the routines cc.a88k shares (the products, the substitution
  points, deluse, delparent, walkuses; cc.a88k's empty strengthreduce),
  opt_str_$is_loop_constant_integer and opt_str_$opmod1_of_multiplier.
  Not written yet: transformtemps .. ptrsub, match_rlens_srtemp_and_
  assign .. autoinc, elimuses .. minimally_size_sr_temp, reduce and
  cc.m68k's strengthreduce (0x0EBAF0, 0x35C bytes), and the module's
  data they use (A5 +32 .. +160). }

module opt_strength;

%var cc_a88k;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { A strength reduction temporary's substitution points (8 bytes from
    gspace): the nodes it stands for. }
  sr_point_ptr_t = ^sr_point_t;
  sr_point_t = record
    point: il_$node_ptr_t;              { +0 }
    next: sr_point_ptr_t;               { +4 }
  end;
  { What a temporary's node leads to (+46 of a kind 110 with +24 bit
    17, +52 of a kind 109 with +32 bit 17; il_utils.pas's sr_info_t
    from its +4). }
  sr_temp_ptr_t = ^sr_temp_t;
  sr_temp_t = record
    unused_0: integer32;                { +0 }
    points: sr_point_ptr_t;             { +4 }
  end;

var
  { delay.pas's +888 (cc.m68k 0x169968, cc.a88k 0x2E99D8): the bytes of
    each register class (delay.pas's class_size). }
  class_size: extern array [0..12] of integer;

%if cc_a88k %then
define
  opt_str_$product_of, opt_str_$opmod_of_operand,
  opt_str_$set_substitution_point, opt_str_$add_substitution_point,
  delparent, walkuses, strengthreduce;
%else
define
  opt_str_$product_of, opt_str_$opmod_of_operand,
  opt_str_$set_substitution_point, opt_str_$add_substitution_point,
  delparent, walkuses;
%endif

%if cc_a88k %then
%else
{ opt_str_$is_loop_constant_integer - tree t is an integer constant, a
  variable marked constant in the loop (bit 11 of a 109's word at +34,
  of a 110's at +26), an operator 17, or one of the operators in the
  set below whose operands all are.  l is passed on unchanged.

  0x0E5E8C, 0xC2 bytes (cc.m68k): the kinds by a set of 0..207 (`sgt'
  to the result), the operators by a set of 0..95 without a range
  check; the operands counted with `dbf' and a borrow
  (docs/rev889-patterns.md 17). }

function opt_str_$is_loop_constant_integer(
    t: il_$node_ptr_t;
    l: univ_ptr): boolean; options(val_param); internal;
var
  k: integer32;
begin
  if t^.kind in [77..87, 101, 200] then
    opt_str_$is_loop_constant_integer := true
  else
    case t^.kind of
      109:
        opt_str_$is_loop_constant_integer := (t^.xw[17] & 16#800) <> 0;
      110:
        opt_str_$is_loop_constant_integer := (t^.xw[13] & 16#800) <> 0;
      137:
        if g_opt_tree_ptr_t(t)^.op in [0..10, 13, 14, 17, 18, 27..29, 33,
                                       43..46, 49..53, 57, 59..62, 74..77,
                                       86] then begin
          for k := 1 to g_opt_tree_ptr_t(t)^.count do
            if not opt_str_$is_loop_constant_integer(
                     g_opt_tree_ptr_t(t)^.opnd[k], l) then begin
              opt_str_$is_loop_constant_integer := false;
              return;
            end;
          opt_str_$is_loop_constant_integer := true;
        end
        else if g_opt_tree_ptr_t(t)^.op = 17 then
          opt_str_$is_loop_constant_integer := true
        else
          opt_str_$is_loop_constant_integer := false;
      otherwise
        opt_str_$is_loop_constant_integer := false;
    end;
end;
%endif

{ opt_str_$product_of_consts - the constant a op b (3 the product, 27
  a shifted left by b) of two integer constants, else nil.

  0x0E5F74, 0xC2 bytes (cc.a88k 0x2B307C): the product by M$MIS$LLL;
  the result in A0. }

function opt_str_$product_of_consts(
    op: integer;
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
begin
  opt_str_$product_of_consts := nil;
  if op = 3 then begin
    if a^.kind in [77..87, 101, 200] then
      if b^.kind in [77..87, 101, 200] then
        opt_str_$product_of_consts :=
          smcontk(81, a^.int_value * b^.int_value);
  end
  else if op = 27 then
    if a^.kind in [77..87, 101, 200] then
      if b^.kind in [77..87, 101, 200] then
        opt_str_$product_of_consts :=
          smcontk(81, lshft(a^.int_value, b^.int_value));
end;

{ opt_str_$opmod_of_operand - see g_opt.ins.pas: an integer constant 2
  when it fits a (signed or unsigned) word, else 4; a 110 the size of
  its data class (+10 low nibble: 1, 2, 3 is 4 bytes; else size); a
  109 2 when its type is at most 2 bytes (opt_var_types by its number
  at +74, else type_exp), else 4; a tree its register class's bytes;
  an index, contents or displacement size.

  0x0E606C, 0x132 bytes (cc.a88k 0x2B318E): the kinds compared in turn;
  bug_check given the kind by address. }

function opt_str_$opmod_of_operand(
    t: il_$node_ptr_t;
    size: integer;
    sgn: boolean): integer32;
var
  te: g_opt_vtype_t;

  { sizeof_dataclass - the bytes of data class c (1, 2, 3 is 4), dflt
    for the others.

    0x0E6036, 0x36 bytes: nested, the parent's frame not used. }

  function sizeof_dataclass(
      c: integer;
      dflt: integer): integer; options(val_param);
  begin
    if c = 1 then
      sizeof_dataclass := 1
    else if c = 2 then
      sizeof_dataclass := 2
    else if c = 3 then
      sizeof_dataclass := 4
    else
      sizeof_dataclass := dflt;
  end;

begin
  if t^.kind in [77..87, 101, 200] then begin
    if sgn then begin
      if (t^.int_value >= -32768) and (t^.int_value <= 32767) then
        opt_str_$opmod_of_operand := 2
      else
        opt_str_$opmod_of_operand := 4;
    end
    else if (t^.int_value >= 0) and (t^.int_value <= 65535) then
      opt_str_$opmod_of_operand := 2
    else
      opt_str_$opmod_of_operand := 4;
  end
  else
    case t^.kind of
      110:
        opt_str_$opmod_of_operand :=
          sizeof_dataclass(ord(t^.xc[10]) & 15, size);
      109:
        if (t^.xw[37] > 0) and (opt_var_types <> nil) then begin
          if opt_var_types^[t^.xw[37]].size > 2 then
            opt_str_$opmod_of_operand := 4
          else
            opt_str_$opmod_of_operand := 2;
        end
        else begin
          type_exp(t, addr(te));
          if te.size <= 2 then
            opt_str_$opmod_of_operand := 2
          else
            opt_str_$opmod_of_operand := 4;
        end;
      137:
        opt_str_$opmod_of_operand :=
          class_size[g_opt_tree_ptr_t(t)^.rlen];
      145, 146, 147, 205:
        opt_str_$opmod_of_operand := size;
      otherwise
        bug_check('opt_str_$opmod_of_operand -- unexpected object kind %d%.',
                  t^.kind);
    end;
end;

%if cc_a88k %then
%else
{ opt_str_$opmod1_of_multiplier - the size of a multiplication's
  second operand (+28), else of t's register class.

  0x0E61D6, 0x24 bytes (cc.m68k), no frame: the result in D0. }

function opt_str_$opmod1_of_multiplier(
    t: g_opt_tree_ptr_t): integer; options(val_param); internal;
begin
  if t^.op = 3 then
    opt_str_$opmod1_of_multiplier := t^.w28
  else
    opt_str_$opmod1_of_multiplier := class_size[t^.rlen];
end;
%endif

{ opt_str_$product_of - see g_opt.ins.pas: a op b (3 a product, 27 a
  left shift) as a tree of register class rlen (the operands' classes
  rlen_a, rlen_b; sgn signed), reusing the tree reuse when not nil:
  constants folded; a product with 1 or a shift by 0 the other operand
  converted (identity_mul); a constant multiplied into an operand that
  is a product or shift by a constant (smuggle_constants, either way
  round for the commutative operators); else a product node (18-byte
  operand modes: words when the result is a word or the product of a
  word variable and a word constant).

  0x0E63D2, 0x25E bytes (cc.a88k 0x2B34D0): the descriptor, the type
  and the operands in the frame (-304, -288, -256), which the nested
  routines reach through the dynamic link; smuggle_constants reads the
  descriptor's operand mode and sign before they are set (the
  image's); `Don't know how to form product!' for another operator
  (the result left as it is). }

function opt_str_$product_of(
    op: integer;
    a: il_$node_ptr_t;
    b: il_$node_ptr_t;
    rlen: integer;
    rlen_a: integer;
    rlen_b: integer;
    sgn: boolean;
    reuse: g_opt_tree_ptr_t): il_$node_ptr_t;
var
  ops: add_node_$opnds_t;               { -256 }
  te: g_opt_vtype_t;                    { -288 }
  d: add_node_$desc_t;                  { -304 }
  r: il_$node_ptr_t;

  { identity_mul - t converted from class from_rlen to class to_rlen
    (operator 18, uses 0), or t itself when they are the same.

    0x0E61FA, 0x96 bytes: nested, the parent's operands through the
    dynamic link (`movea.l (A6),A3'); the result in A0. }

  function identity_mul(
      t: il_$node_ptr_t;
      to_rlen: integer;
      from_rlen: integer;
      sgn: boolean): il_$node_ptr_t; options(val_param);
  var
    d: add_node_$desc_t;
    r: il_$node_ptr_t;
  begin
    if to_rlen = from_rlen then
      r := t
    else begin
      d.rlen := to_rlen;
      d.w6 := opt_str_$opmod_of_operand(t, class_size[from_rlen], sgn);
      d.w8 := 0;
      d.size := class_size[from_rlen];
      d.flags.signed := sgn;
      ops[1] := t;
      r := buildtreenode(18, d, ops, 1);
      g_opt_tree_ptr_t(r)^.uses := 0;
      g_opt_tree_ptr_t(r)^.opnd[1] := t;
    end;
    identity_mul := r;
  end;

  { smuggle_constants - a op b with b an integer constant and a a
    product (or for op 27 a shift) used once whose second (or first)
    operand is a constant: the constants combined into a, which is the
    result; nil otherwise.

    0x0E6290, 0x142 bytes: nested, the parent's descriptor through the
    dynamic link (`move.l (A6),D3': its +6, +8 and sign). }

  function smuggle_constants(
      op: integer;
      a: il_$node_ptr_t;
      b: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    t: g_opt_tree_ptr_t;
    res: il_$node_ptr_t;
  begin
    res := nil;
    t := g_opt_tree_ptr_t(a);
    if a^.kind = 137 then
      if t^.uses = 1 then
        if b^.kind in [77..87, 101, 200] then
          if (t^.op = 3) and (t^.opnd[2]^.kind in [77..87, 101, 200]) then begin
            t^.opnd[2] := opt_str_$product_of_consts(op, t^.opnd[2], b);
            t^.w28 := opt_str_$opmod_of_operand(t^.opnd[2], d.w8, d.flags.signed);
            res := a;
          end
          else if (t^.op = 3) and (t^.opnd[1]^.kind in [77..87, 101, 200]) then begin
            t^.opnd[1] := opt_str_$product_of_consts(op, t^.opnd[1], b);
            t^.w26 := opt_str_$opmod_of_operand(t^.opnd[1], d.w6, t^.dflags.signed);
            res := a;
          end
          else if (t^.op = 27) and (op = 27) and
                  (t^.opnd[2]^.kind in [77..87, 101, 200]) then begin
            t^.opnd[2] := smcontk(81, t^.opnd[2]^.int_value + b^.int_value);
            res := a;
          end;
    smuggle_constants := res;
  end;

begin
  r := opt_str_$product_of_consts(op, a, b);
  if r <> nil then begin
    opt_str_$product_of := r;
    return;
  end;
  if (op = 3) and (a^.kind in [77..87, 101, 200]) and (a^.int_value = 1) then begin
    opt_str_$product_of := identity_mul(b, rlen, rlen_b, sgn);
    return;
  end;
  if ((op = 3) and (b^.kind in [77..87, 101, 200]) and (b^.int_value = 1)) or
     ((op = 27) and (b^.kind in [77..87, 101, 200]) and (b^.int_value = 0)) then begin
    opt_str_$product_of := identity_mul(a, rlen, rlen_a, sgn);
    return;
  end;
  r := smuggle_constants(op, a, b);
  if r <> nil then begin
    opt_str_$product_of := r;
    return;
  end;
  if op in [1, 3, 9, 10, 19, 20, 34, 36, 44..46] then begin
    r := smuggle_constants(op, b, a);
    if r <> nil then begin
      opt_str_$product_of := r;
      return;
    end;
  end;
  if op = 3 then begin
    d.rlen := rlen;
    d.w6 := class_size[rlen_a];
    d.w8 := class_size[rlen_b];
    d.size := class_size[rlen];
    d.flags.signed := sgn;
    if rlen = 4 then
      if not ((b^.kind = 80) or (b^.kind = 200) or (b^.kind = 81)) or
         (a^.kind <> 109) or (a^.xw[37] <> 0) or (d.w6 <> 2) or
         (d.w8 <> 2) or (d.rlen <> 4) then begin
        d.w6 := 4;
        d.w8 := 4;
      end
      else begin
        type_exp(a, addr(te));
        if te.size <> 2 then begin
          d.w6 := 4;
          d.w8 := 4;
        end;
      end;
    if d.rlen = 2 then begin
      d.w6 := 2;
      d.w8 := 2;
    end;
    d.w6 := opt_str_$opmod_of_operand(a, d.w6, d.flags.signed);
    d.w8 := opt_str_$opmod_of_operand(b, d.w8, d.flags.signed);
    if reuse <> nil then begin
      reuse^.w26 := d.w6;
      reuse^.w28 := d.w8;
      reuse^.opnd[1] := a;
      reuse^.opnd[2] := b;
      r := il_$node_ptr_t(reuse);
      opt_str_$product_of := r;
    end
    else begin
      ops[1] := a;
      ops[2] := b;
      r := buildtreenode(op, d, ops, 2);
      g_opt_tree_ptr_t(r)^.uses := 0;
      opt_str_$product_of := r;
    end;
  end
  else
    bug_check('Don''t know how to form product!');
end;

{ opt_str_$set_substitution_point - old becomes the first substitution
  point of strength reduction temporary new (a 110 or 109 marked bit
  17).

  0x0E6656, 0x60 bytes (cc.a88k 0x2B3754). }

procedure opt_str_$set_substitution_point(
    var new: il_$node_ptr_t;
    var old: il_$node_ptr_t);
var
  t: sr_temp_ptr_t;
begin
  if new^.kind = 110 then begin
    if (new^.xl[6] & 16#20000) = 0 then
      return;
    t := sr_temp_ptr_t(new^.xp2[11]);
  end
  else if new^.kind = 109 then begin
    if (new^.xl[8] & 16#20000) = 0 then
      return;
    t := sr_temp_ptr_t(new^.xp[13]);
  end
  else
    return;
  t^.points^.point := old;
end;

{ opt_str_$add_substitution_point - old added in front of temporary
  new's substitution points (8 bytes from gspace; cgerr_no_source 9
  when there is none); a conversion (137, operator 18) passes it to its
  operand.

  0x0E66B6, 0xB4 bytes (cc.a88k 0x2B37B4): old copied to a frame
  temporary for the recursive call. }

procedure opt_str_$add_substitution_point(
    var new: il_$node_ptr_t;
    var old: il_$node_ptr_t);
var
  n, o, x: il_$node_ptr_t;
  t: sr_temp_ptr_t;
  p: sr_point_ptr_t;
begin
  o := old;
  n := new;
  if (n = nil) or (o = nil) then
    return;
  if n^.kind = 110 then begin
    if (n^.xl[6] & 16#20000) = 0 then
      return;
    t := sr_temp_ptr_t(n^.xp2[11]);
  end
  else if n^.kind = 109 then begin
    if (n^.xl[8] & 16#20000) = 0 then
      return;
    t := sr_temp_ptr_t(n^.xp[13]);
  end
  else begin
    if n^.kind = 137 then
      if g_opt_tree_ptr_t(n)^.op = 18 then begin
        x := o;
        opt_str_$add_substitution_point(g_opt_tree_ptr_t(n)^.opnd[1], x);
      end;
    return;
  end;
  p := gspace(8);
  if p = nil then
    cgerr_no_source(9, 0);
  p^.point := o;
  p^.next := t^.points;
  t^.points := p;
end;

{ deluse - use u (189) taken off cse parent p's (190) list of uses.

  0x0E7864, 0x54 bytes (cc.a88k 0x2B3976): both by address; no caller
  in either binary. }

procedure deluse(
    in p: g_opt_cse_ptr_t;
    in u: g_opt_cse_ptr_t);
var
  q, r: g_opt_cse_ptr_t;
begin
  q := p^.p_uses;
  if q <> nil then
    if q = u then
      p^.p_uses := q^.u_next
    else
      while q <> nil do begin
        r := q^.u_next;
        if r = u then begin
          q^.u_next := r^.u_next;
          exit;
        end;
        q := r;
      end;
end;

{ delparent - see g_opt.ins.pas: cse parent p (190) taken off its
  statement's list of parents (cses, through p_next).

  0x0E78B8, 0x52 bytes (cc.a88k 0x2B39CA): p by address, only read
  (opt_livevar's check_cse_uses passes a frame copy): `in'. }

procedure delparent(
    in p: g_opt_cse_ptr_t);
var
  s: g_opt_stmt_ptr_t;
  q, r: g_opt_cse_ptr_t;
begin
  s := p^.p_stmt;
  q := g_opt_cse_ptr_t(s^.cses);
  if q <> nil then
    if q = p then
      s^.cses := il_$node_ptr_t(p^.p_next)
    else
      while q <> nil do begin
        r := q^.p_next;
        if r = p then begin
          q^.p_next := r^.p_next;
          exit;
        end;
        q := r;
      end;
end;

{ walkuses - see g_opt.ins.pas: whether variable r occurs in t (a
  statement or a tree, through a cse parent to its tree; the operands
  of an evaluation from the last; a cse use of an operator 26 tree
  walked into).

  0x0E852A, 0x26E bytes (cc.a88k 0x2B3A1C): r by address, copied to a
  frame temporary for each call; the kinds compared in turn; an
  assignment's two sides and an index's two operands walked both
  before the test (`or.b'), a 164's second only when the first fails. }

function walkuses(
    var t: il_$node_ptr_t;
    in r: il_$node_ptr_t): boolean;
var
  found: boolean;
  n: il_$node_ptr_t;
  u: g_opt_cse_ptr_t;
  k: integer;
begin
  found := false;
  n := t;
  if n^.kind = 190 then
    n := g_opt_cse_ptr_t(n)^.p_tree;
  case n^.kind of
    139:
      for k := g_opt_stmt_ptr_t(n)^.eval_count downto 1 do
        if walkuses(g_opt_stmt_ptr_t(n)^.eval_opnd[k], r) then
          found := true;
    142:
      if walkuses(g_opt_stmt_ptr_t(n)^.br_cond, r) then
        found := true;
    140: begin
      if walkuses(g_opt_stmt_ptr_t(n)^.asg_lhs, r) or
         walkuses(g_opt_stmt_ptr_t(n)^.asg_rhs, r) then
        found := true;
      if g_opt_stmt_ptr_t(n)^.asg_x <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.asg_x, r) then
          found := true;
    end;
    151:
      if g_opt_stmt_ptr_t(n)^.x48 <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.x48, r) then
          found := true;
    188:
      if g_opt_stmt_ptr_t(n)^.x48 <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.x48, r) then
          found := true;
    143, 137:
      for k := 1 to g_opt_tree_ptr_t(n)^.count do begin
        if walkuses(g_opt_tree_ptr_t(n)^.opnd[k], r) then
          found := true;
        u := g_opt_cse_ptr_t(g_opt_tree_ptr_t(n)^.opnd[k]);
        if u^.kind = 189 then
          if g_opt_tree_ptr_t(u^.u_tree)^.op = 26 then
            if walkuses(u^.u_tree, r) then
              found := true;
      end;
    147, 146, 205:
      if walkuses(n^.xp[6], r) then
        found := true;
    145:
      if walkuses(n^.xp[6], r) or walkuses(n^.xp[9], r) then
        found := true;
    164:
      if walkuses(n^.xp[5], r) then
        found := true
      else if walkuses(n^.xp[6], r) then
        found := true;
    175, 171:
      if walkuses(n^.xp[4], r) then
        found := true;
    109, 110:
      if n = r then
        found := true;
    otherwise
  end;
  walkuses := found;
end;

%if cc_a88k %then
{ strengthreduce - see g_opt.ins.pas; cc.a88k's does nothing.

  cc.a88k 0x2B3ED4, 2 bytes: a lone `rts' (docs/rev889-patterns.md 13). }

procedure strengthreduce;
begin
end;
%endif
