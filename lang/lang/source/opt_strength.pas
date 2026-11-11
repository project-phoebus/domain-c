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
  opt_str_$is_loop_constant_integer, opt_str_$opmod1_of_multiplier,
  transformtemps .. ptrsub and the module's data.
  Not written yet: match_rlens_srtemp_and_assign .. autoinc, elimuses
  .. minimally_size_sr_temp, reduce and cc.m68k's strengthreduce
  (0x0EBAF0, 0x35C bytes). }

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
    from its +4; 18 bytes from gspace, create_sr_temp_var): tree the
    expression it stands for (reduce), points its substitution points,
    incs the statements that step it (add_assign), asg the statement in
    the loop's preheader giving its first value, header the number of
    the loop's header block. }
  sr_inc_ptr_t = ^sr_inc_t;
  sr_temp_ptr_t = ^sr_temp_t;
  sr_temp_t = record
    tree: g_opt_tree_ptr_t;             { +0 }
    points: sr_point_ptr_t;             { +4 }
    incs: sr_inc_ptr_t;                 { +8 }
    asg: g_opt_stmt_ptr_t;              { +12 }
    header: integer;                    { +16 }
  end;
  { A statement stepping a temporary (8 bytes). }
  sr_inc_t = record
    stmt: g_opt_stmt_ptr_t;             { +0 }
    next: sr_inc_ptr_t;                 { +4 }
  end;
  { The module's lists (8 bytes from new): the induction variables
    (newindvar) and the candidate expressions (newexpr). }
  sr_list_ptr_t = ^sr_list_t;
  sr_list_t = record
    node: il_$node_ptr_t;               { +0 }
    next: sr_list_ptr_t;                { +4 }
  end;
  { A tree's header (+4..+15) and descriptor (+20..+35) as wholes
    (stmtfound and verify_increments compare them with `cmpm.l' loops). }
  sr_tree_view_ptr_t = ^sr_tree_view_t;
  sr_tree_view_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    hdr: array [1..3] of integer32;     { +4 }
    uses: integer;                      { +16 }
    unused_18: integer;                 { +18 }
    desc: add_node_$desc_t;             { +20 }
  end;

var
  { delay.pas's +888 (cc.m68k 0x169968, cc.a88k 0x2E99D8): the bytes of
    each register class (delay.pas's class_size). }
  class_size: extern array [0..12] of integer;

%if cc_a88k %then
%else
var
  { The module's data (cc.m68k A5 0x3530D8), by variable number of
    opt_region's table: invariant the variables no statement of the
    loop assigns, excluded those strengthreduce rules out for the
    routine (a 109 of storage class 5, without a type number at +74 or
    with a bit of 16#201101 at +32; a 110 without +16 or with such a bit
    at +24), others those excluded or assigned in the loop other than
    as an induction variable, ivset the induction variables
    (recognize_induction_variables). }
  invariant: g_opt_varset_t;            { +0 }
  excluded: g_opt_varset_t;             { +32 }
  others: g_opt_varset_t;               { +64 }
  ivset: g_opt_varset_t;                { +96 }
  auto_desc: add_node_$desc_t;          { +128: autoinc's descriptor of
                                          the addresses it forms }
  cur_loop: g_opt_block_ptr_t;          { +144: the loop's blocks
                                          (select_loop) }
  ivs: sr_list_ptr_t;                   { +148: the induction variables }
  exprs: sr_list_ptr_t;                 { +152: the candidate expressions }
  ntemps: integer;                      { +156: the temporaries made }
  preheader_num: g_opt_num_t;           { +158: the loop's preheader }
  header_num: g_opt_num_t;              { +160: the loop's header }

{ FIXUPCHILDREN - opt_loop.pas 0x0D93E4 (only opt_loop's insert-less
  heading): tree t now evaluated at statement r (opt_loop.pas). }
procedure fixupchildren(
    var t: il_$node_ptr_t;
    in r: integer;
    in f: boolean); extern;

{ FIXUP_BLOCKS - opt_main.pas 0x0DF2B6: the basic blocks' first and
  last statements after statements were added (no parameters). }
procedure fixup_blocks; extern;

{ OPT_MAIN_$SYMIDX_OF_VARN_OR_FSYM - opt_main.pas 0x0DE630: the number
  in opt_region's table of the variable a reference t stands for (D0, a
  word compared with a statement's vnum). }
function opt_main_$symidx_of_varn_or_fsym(
    t: il_$node_ptr_t): integer; options(val_param); extern;

{ KFOLD - kfold.pas 0x0AF444: fold the constants of tree t, a tree of
  statement stmt (opt_general's heading). }
procedure kfold(
    in stmt: il_$node_ptr_t;
    var t: il_$node_ptr_t); extern;
%endif

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

%if cc_a88k %then
%else
{ transformtemps - t's operand temp (a strength reduction temporary,
  operand 2 of a 137, the index of a 145) and the invariant temporary
  inv added there: temp's first value (its preheader assignment) gets
  inv added (operator 1), both recorded as substitution points of the
  sum, and t's operand becomes temp alone.

  0x0E676A, 0xD6 bytes: the operands in the frame (-264); temp and t
  passed on by address (`pea (12,A6)', `pea (16,A6)'). }

procedure transformtemps(
    inv: il_$node_ptr_t;
    temp: il_$node_ptr_t;
    t: il_$node_ptr_t); options(val_param); internal;
var
  ops: add_node_$opnds_t;
  s: g_opt_stmt_ptr_t;
begin
  if temp = nil then
    return;
  case temp^.kind of
    109: begin
      if (temp^.xl[8] & 16#20000) = 0 then
        return;
      s := sr_temp_ptr_t(temp^.xp[13])^.asg;
    end;
    110: begin
      if (temp^.xl[6] & 16#20000) = 0 then
        return;
      s := sr_temp_ptr_t(temp^.xp2[11])^.asg;
    end;
    otherwise
      return;
  end;
  ops[1] := s^.asg_rhs;
  ops[2] := inv;
  s^.asg_rhs := buildtreenode(1, s^.asg_desc, ops, 2);
  opt_str_$add_substitution_point(ops[1], s^.asg_rhs);
  opt_str_$add_substitution_point(ops[2], s^.asg_rhs);
  if t^.kind = 137 then
    g_opt_tree_ptr_t(t)^.opnd[2] := temp
  else if t^.kind = 145 then
    t^.xp[9] := temp
  else
    return;
  opt_str_$add_substitution_point(temp, t);
end;

{ is_invariant_srtemp - temporary t was not made for a loop whose header
  is a block of the loop headed by block h.

  0x0E6840, 0x5C bytes: the header's number in a frame word; the result
  in D2 (`st' first). }

function is_invariant_srtemp(
    t: il_$node_ptr_t;
    h: integer): boolean; options(val_param); internal;
var
  hn: integer;
  b: g_opt_block_ptr_t;
  r: boolean;
begin
  if t^.kind = 110 then
    hn := sr_temp_ptr_t(t^.xp2[11])^.header
  else
    hn := sr_temp_ptr_t(t^.xp[13])^.header;
  r := true;
  b := select_loop(h);
  while b <> nil do begin
    if hn = b^.num then begin
      r := false;
      exit;
    end;
    b := b^.link;
  end;
  is_invariant_srtemp := r;
end;

{ multidim - the address t (a 145, or a 137 of operator 13) whose
  operand (index or operand 2) is a sum, used once, of two strength
  reduction temporaries of which one is invariant in the loop headed by
  block h: the invariant one folded into the other's first value
  (transformtemps).

  0x0E689C, 0x104 bytes: the two kinds tested whole (`seq', `or.b'). }

procedure multidim(
    t: il_$node_ptr_t;
    h: integer); options(val_param); internal;
var
  x: g_opt_tree_ptr_t;
begin
  if t = nil then
    return;
  if not ((t^.kind = 145) or (t^.kind = 137)) then
    return;
  if t^.kind = 137 then
    if g_opt_tree_ptr_t(t)^.op <> 13 then
      return;
  if t^.kind = 137 then
    x := g_opt_tree_ptr_t(g_opt_tree_ptr_t(t)^.opnd[2])
  else
    x := g_opt_tree_ptr_t(t^.xp[9]);
  if x^.kind <> 137 then
    return;
  if x^.uses > 1 then
    return;
  if x^.op <> 1 then
    return;
  if not il_utils_$is_strength_reduction_temp(x^.opnd[1]) then
    return;
  if not il_utils_$is_strength_reduction_temp(x^.opnd[2]) then
    return;
  if is_invariant_srtemp(x^.opnd[1], h) and
     not is_invariant_srtemp(x^.opnd[2], h) then
    transformtemps(x^.opnd[1], x^.opnd[2], t)
  else if is_invariant_srtemp(x^.opnd[2], h) and
          not is_invariant_srtemp(x^.opnd[1], h) then
    transformtemps(x^.opnd[2], x^.opnd[1], t);
end;

{ unlinkstmts - the assignments to temporary t taken out of the
  preheader (from its first statement to the next block's first) and
  t's stepping statements out of the loop: use counts given back, a
  region statement marked deleted.

  0x0E69A0, 0x104 bytes: the region tested as `(+42 & 0xFFFF00) >> 8'
  (g_opt.ins.pas's hdr). }

procedure unlinkstmts(
    t: il_$node_ptr_t); options(val_param); internal;
var
  p: sr_inc_ptr_t;
  b: g_opt_block_ptr_t;
  s, n: g_opt_stmt_ptr_t;
begin
  if t^.kind = 110 then
    p := sr_temp_ptr_t(t^.xp2[11])^.incs
  else if t^.kind = 109 then
    p := sr_temp_ptr_t(t^.xp[13])^.incs
  else
    return;
  b := g_opt_blocks_ptr_t(il_11c)^[preheader_num];
  s := b^.first_stmt;
  while s <> g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt do begin
    n := s^.next;
    if n^.kind = 140 then
      if n^.asg_lhs = t then begin
        il_utils_$adjust_uc(il_$node_ptr_t(n), -1);
        s^.next := n^.next;
        n^.next^.prev := s;
        if n^.hdr.region <> 0 then
          n^.hdr.deleted := true;
      end;
    s := s^.next;
  end;
  while p <> nil do begin
    il_utils_$adjust_uc(il_$node_ptr_t(p^.stmt), -1);
    n := p^.stmt;
    n^.prev^.next := n^.next;
    n^.next^.prev := n^.prev;
    if n^.hdr.region <> 0 then
      n^.hdr.deleted := true;
    p := p^.next;
  end;
end;

{ substitute - temporary new put for temporary old at each of old's
  substitution points, whose list is then put in front of new's.

  0x0E6AA4, 0x1CA bytes: the kinds compared in turn; 164's second
  operand shares 146's code; another kind cgerr_no_source(28, 0).  Of
  a 109 the list is joined to old's own (+52 of old, then new's: the
  image's), and the last point is not set when old has none. }

procedure substitute(
    new: il_$node_ptr_t;
    old: il_$node_ptr_t); options(val_param); internal;
var
  p, q, last: sr_point_ptr_t;
  n: il_$node_ptr_t;
  k: integer;
begin
  if old^.kind = 110 then
    p := sr_temp_ptr_t(old^.xp2[11])^.points
  else
    p := sr_temp_ptr_t(old^.xp[13])^.points;
  q := p;
  while q <> nil do begin
    last := q;
    n := q^.point;
    if n <> nil then
      case n^.kind of
        143, 137:
          for k := 1 to g_opt_tree_ptr_t(n)^.count do
            if g_opt_tree_ptr_t(n)^.opnd[k] = old then
              g_opt_tree_ptr_t(n)^.opnd[k] := new;
        205, 147, 146:
          if n^.xp[6] = old then
            n^.xp[6] := new;
        145: begin
          if n^.xp[6] = old then
            n^.xp[6] := new;
          if n^.xp[9] = old then
            n^.xp[9] := new;
        end;
        164: begin
          if n^.xp[5] = old then
            n^.xp[5] := new;
          if n^.xp[6] = old then
            n^.xp[6] := new;
        end;
        175, 171:
          if n^.xp[4] = old then
            n^.xp[4] := new;
        140: begin
          if g_opt_stmt_ptr_t(n)^.asg_rhs = old then
            g_opt_stmt_ptr_t(n)^.asg_rhs := new;
          if g_opt_stmt_ptr_t(n)^.asg_x <> nil then
            if g_opt_stmt_ptr_t(n)^.asg_x = old then
              g_opt_stmt_ptr_t(n)^.asg_x := new;
        end;
        139:
          for k := 1 to g_opt_stmt_ptr_t(n)^.eval_count do
            if g_opt_stmt_ptr_t(n)^.eval_opnd[k] = old then
              g_opt_stmt_ptr_t(n)^.eval_opnd[k] := new;
        142:
          if g_opt_stmt_ptr_t(n)^.br_cond = old then
            g_opt_stmt_ptr_t(n)^.br_cond := new;
        151:
          if g_opt_stmt_ptr_t(n)^.x48 <> nil then
            if g_opt_stmt_ptr_t(n)^.x48 = old then
              g_opt_stmt_ptr_t(n)^.x48 := new;
        otherwise
          cgerr_no_source(28, 0);
      end;
    q := q^.next;
  end;
  if new^.kind = 110 then begin
    last^.next := sr_temp_ptr_t(new^.xp2[11])^.points;
    sr_temp_ptr_t(new^.xp2[11])^.points := p;
  end
  else begin
    last^.next := sr_temp_ptr_t(old^.xp[13])^.points;
    sr_temp_ptr_t(new^.xp[13])^.points := p;
  end;
end;

{ stmtfound - assignment b lies before a (or at it) or after it in the
  run of assignments around a, and assigns the same as a (same
  operator, width and value: the same tree, or before a an equal tree
  of operator 137 with the same operands).

  0x0E6C6E, 0x110 bytes: the trees' header (+4..+15, three longwords)
  and descriptor (+20..+35) compared with `cmpm.l' loops, then count,
  operator, uses and the two operands. }

function stmtfound(
    a: g_opt_stmt_ptr_t;
    b: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  s: g_opt_stmt_ptr_t;
  x, y: g_opt_tree_ptr_t;
begin
  stmtfound := false;
  s := a;
  while s^.kind = 140 do begin
    if s = b then begin
      if (s^.asg_op = a^.asg_op) and (s^.asg_rlen = a^.asg_rlen) then
        if s^.asg_rhs = a^.asg_rhs then
          stmtfound := true
        else if (s^.asg_rhs^.kind = 137) and (a^.asg_rhs^.kind = 137) then begin
          x := g_opt_tree_ptr_t(a^.asg_rhs);
          y := g_opt_tree_ptr_t(s^.asg_rhs);
          if (sr_tree_view_ptr_t(x)^.hdr = sr_tree_view_ptr_t(y)^.hdr) and
             (sr_tree_view_ptr_t(x)^.desc = sr_tree_view_ptr_t(y)^.desc) and
             (x^.count = y^.count) and (x^.op = y^.op) and
             (x^.uses = y^.uses) and (x^.opnd[1] = y^.opnd[1]) and
             (x^.opnd[2] = y^.opnd[2]) then
            stmtfound := true;
        end;
      return;
    end;
    s := s^.prev;
  end;
  s := a;
  while s^.kind = 140 do begin
    if s = b then begin
      if (s^.asg_rhs = a^.asg_rhs) and (s^.asg_op = a^.asg_op) and
         (s^.asg_rlen = a^.asg_rlen) then
        stmtfound := true;
      return;
    end;
    s := s^.next;
  end;
end;

{ verify_increments - temporaries a and b are stepped alike: one
  stepping statement each, assigning the same (stmtfound), or every
  stepping statement of a matched by one of b's.  No stepping
  statement for either is cgerr 3 at opt_region's statement.

  0x0E6D7E, 0x1B2 bytes: the result in D2 (`st' first); the trees
  compared as in stmtfound. }

function verify_increments(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): boolean; options(val_param); internal;
var
  p, q, r: sr_inc_ptr_t;
  x, y: g_opt_tree_ptr_t;
  ok, found: boolean;
begin
  ok := true;
  if a^.kind = 110 then begin
    p := sr_temp_ptr_t(a^.xp2[11])^.incs;
    q := sr_temp_ptr_t(b^.xp2[11])^.incs;
  end
  else begin
    p := sr_temp_ptr_t(a^.xp[13])^.incs;
    q := sr_temp_ptr_t(b^.xp[13])^.incs;
  end;
  if (p = nil) or (q = nil) then
    cgerr(3, opt_4009c[opt_region]^.line, opt_4009c[opt_region]);
  if (p^.next = nil) and (q^.next = nil) and
     (p^.stmt^.asg_rhs = q^.stmt^.asg_rhs) and
     (p^.stmt^.asg_op = q^.stmt^.asg_op) then begin
    if not stmtfound(p^.stmt, q^.stmt) then
      ok := false;
  end
  else begin
    if (p^.next = nil) and (q^.next = nil) then begin
      if p^.stmt^.asg_op <> q^.stmt^.asg_op then begin
        verify_increments := false;
        return;
      end;
      if (p^.stmt^.asg_rhs^.kind <> 137) or
         (q^.stmt^.asg_rhs^.kind <> 137) then begin
        verify_increments := false;
        return;
      end;
      x := g_opt_tree_ptr_t(p^.stmt^.asg_rhs);
      y := g_opt_tree_ptr_t(q^.stmt^.asg_rhs);
      if not ((sr_tree_view_ptr_t(x)^.hdr = sr_tree_view_ptr_t(y)^.hdr) and
              (sr_tree_view_ptr_t(x)^.desc = sr_tree_view_ptr_t(y)^.desc) and
              (x^.count = y^.count) and (x^.op = y^.op) and
              (x^.uses = y^.uses) and (x^.opnd[1] = y^.opnd[1]) and
              (x^.opnd[2] = y^.opnd[2])) then begin
        verify_increments := false;
        return;
      end;
      if not stmtfound(p^.stmt, q^.stmt) then begin
        verify_increments := false;
        return;
      end;
    end;
    while p <> nil do begin
      found := false;
      r := q;
      while r <> nil do begin
        if stmtfound(p^.stmt, r^.stmt) then begin
          found := true;
          exit;
        end;
        r := r^.next;
      end;
      if not found then begin
        ok := false;
        exit;
      end;
      p := p^.next;
    end;
  end;
  verify_increments := ok;
end;

{ opt_str_$trees_equivalent - trees a and b compute the same: the same
  node, or of one kind: a 137 of the same operator, descriptor, flags,
  uses and count, not a load (15, 16), with none of flags 0..4, 12, 16,
  19 unless an operator 26, and equivalent operands (in_index passed
  down for an operator 26); a 145 with equivalent indexes, the same base
  (+24) and +32, +4, +40, +42, in_index set, and the same +28 unless
  the base is of kind 153, 154, 163 or 195.

  0x0E6F30, 0x176 bytes: the flags as a longword (`andi.l #0x9101F');
  145's conditions evaluated whole (`seq', `and.b'), the call first. }

function opt_str_$trees_equivalent(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t;
    in_index: boolean): boolean; options(val_param); internal;
var
  x, y: g_opt_tree_ptr_t;
  k: integer;
begin
  if a = b then begin
    opt_str_$trees_equivalent := true;
    return;
  end;
  if a^.kind <> b^.kind then begin
    opt_str_$trees_equivalent := false;
    return;
  end;
  x := g_opt_tree_ptr_t(a);
  y := g_opt_tree_ptr_t(b);
  case a^.kind of
    137: begin
      if (x^.op <> y^.op) or
         (sr_tree_view_ptr_t(x)^.desc <> sr_tree_view_ptr_t(y)^.desc) or
         (x^.flags <> y^.flags) or (x^.uses <> y^.uses) or
         (x^.count <> y^.count) then begin
        opt_str_$trees_equivalent := false;
        return;
      end;
      if (x^.op = 16) or (x^.op = 15) then begin
        opt_str_$trees_equivalent := false;
        return;
      end;
      if x^.op <> 26 then
        if x^.flags * [0..4, 12, 16, 19] <> [] then begin
          opt_str_$trees_equivalent := false;
          return;
        end;
      for k := 1 to x^.count do
        if not opt_str_$trees_equivalent(x^.opnd[k], y^.opnd[k],
                                         x^.op = 26) then begin
          opt_str_$trees_equivalent := false;
          return;
        end;
      opt_str_$trees_equivalent := true;
    end;
    145:
      opt_str_$trees_equivalent :=
        opt_str_$trees_equivalent(a^.xp[9], b^.xp[9], false) and
        (a^.xp[6] = b^.xp[6]) and in_index and (a^.xl[8] = b^.xl[8]) and
        (a^.xl[1] = b^.xl[1]) and (a^.xw[21] = b^.xw[21]) and
        (a^.xw[20] = b^.xw[20]) and
        ((a^.xp[6]^.kind = 195) or (a^.xp[6]^.kind = 163) or
         (a^.xp[6]^.kind = 154) or (a^.xp[6]^.kind = 153) or
         (a^.xp[7] = b^.xp[7]));
    otherwise
      opt_str_$trees_equivalent := false;
  end;
end;

{ combine_temps - in each loop's preheader, two temporaries assigned
  alike (op 0, the same width, size and operator, equivalent values)
  and stepped alike (verify_increments), the second made for this loop
  (its tree's statement's block in the loop: serial), are made one:
  the second's points get the first (substitute) and its statements go
  (unlinkstmts).

  0x0E70A6, 0x1F6 bytes: the blocks in depth-first order
  (opt_dfs_block); the loop in cur_loop, the preheader's number in
  preheader_num; both walks end at the first statement of the block
  numbered after the preheader, and stop at nil after a statement. }

procedure combine_temps; internal;
var
  i: integer;
  bn: g_opt_num_t;
  b: g_opt_block_ptr_t;
  s, s2: g_opt_stmt_ptr_t;
  n: il_$node_ptr_t;
  t: sr_temp_ptr_t;
begin
  for i := opt_first_block to opt_last_block do begin
    bn := opt_dfs_block^[i];
    b := g_opt_blocks_ptr_t(il_11c)^[bn];
    if b^.flags.header and (b^.preheader <> nil) then begin
      cur_loop := select_loop(bn);
      preheader_num := b^.preheader^.num;
      s := b^.preheader^.first_stmt;
      while s <> g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt do begin
        if s^.kind = 140 then
          if il_utils_$is_strength_reduction_temp(s^.asg_lhs) then
            if s^.asg_op = 0 then begin
              s2 := s^.next;
              while s2 <> g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt do begin
                if s2^.kind = 140 then begin
                  n := s2^.asg_lhs;
                  t := nil;
                  if n^.kind = 109 then begin
                    if (n^.xl[8] & 16#20000) <> 0 then
                      t := sr_temp_ptr_t(n^.xp[13]);
                  end
                  else if n^.kind = 110 then
                    if (n^.xl[6] & 16#20000) <> 0 then
                      t := sr_temp_ptr_t(n^.xp2[11]);
                  if t <> nil then
                    if (t^.tree^.owner^.block^.serial = cur_loop^.serial) and
                       (s2^.asg_op = 0) and (s^.asg_rlen = s2^.asg_rlen) and
                       (s^.asg_size = s2^.asg_size) and
                       (s^.asg_op = s2^.asg_op) then
                      if opt_str_$trees_equivalent(s^.asg_rhs, s2^.asg_rhs,
                                                   false) then
                        if verify_increments(s^.asg_lhs, s2^.asg_lhs) then begin
                          substitute(s^.asg_lhs, s2^.asg_lhs);
                          unlinkstmts(s2^.asg_lhs);
                        end;
                end;
                if s2 = nil then
                  exit;
                if s2 = g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt then
                  exit;
                s2 := s2^.next;
              end;
            end;
        if s = nil then
          exit;
        if s = g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt then
          exit;
        s := s^.next;
      end;
    end;
  end;
end;

{ used_outside_loop - tree t (a 137 or 143) is an operand of a
  statement of a block outside cur_loop (serial), or of a tree there.

  0x0E73BE, 0x1A6 bytes: the blocks by number (il_11c), each from its
  first statement to its last's next; found in the frame (-20), set by
  usewalk through its static link (A1) and tested after each walk; the
  result in D0. }

function used_outside_loop(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  found: boolean;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  i, k: integer;

  { usewalk - found set when t is an operand of tree n or of a tree
    below it.

    0x0E729C, 0x122 bytes: nested, the static link in A1 (passed on to
    itself); the kinds compared in turn; 171 and 175 separate copies. }

  procedure usewalk(
      n: il_$node_ptr_t;
      t: il_$node_ptr_t); options(val_param);
  var
    k: integer;
  begin
    case n^.kind of
      137, 143:
        for k := 1 to g_opt_tree_ptr_t(n)^.count do
          if g_opt_tree_ptr_t(n)^.opnd[k] = t then begin
            found := true;
            return;
          end
          else
            usewalk(g_opt_tree_ptr_t(n)^.opnd[k], t);
      147, 205, 146:
        if n^.xp[6] = t then
          found := true
        else
          usewalk(n^.xp[6], t);
      145:
        if n^.xp[6] = t then
          found := true
        else begin
          usewalk(n^.xp[6], t);
          if n^.xp[9] = t then
            found := true
          else
            usewalk(n^.xp[9], t);
        end;
      175:
        if n^.xp[4] = t then
          found := true
        else
          usewalk(n^.xp[4], t);
      171:
        if n^.xp[4] = t then
          found := true
        else
          usewalk(n^.xp[4], t);
      164:
        if n^.xp[5] = t then
          found := true
        else begin
          usewalk(n^.xp[5], t);
          if n^.xp[6] = t then
            found := true
          else
            usewalk(n^.xp[6], t);
        end;
      otherwise
    end;
  end;

begin
  used_outside_loop := false;
  found := false;
  if not ((t^.kind = 143) or (t^.kind = 137)) then
    return;
  for i := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    if b^.serial <> cur_loop^.serial then begin
      s := b^.first_stmt;
      while s <> b^.last_stmt^.next do begin
        case s^.kind of
          139:
            for k := 1 to s^.eval_count do
              if s^.eval_opnd[k] = t then begin
                used_outside_loop := true;
                return;
              end
              else
                usewalk(s^.eval_opnd[k], t);
          140: begin
            if s^.asg_rhs = t then begin
              used_outside_loop := true;
              return;
            end;
            usewalk(s^.asg_rhs, t);
            used_outside_loop := found;
            if found then
              return;
            if s^.asg_x <> nil then begin
              if s^.asg_x = t then begin
                used_outside_loop := true;
                return;
              end;
              usewalk(s^.asg_x, t);
            end;
            used_outside_loop := found;
            if found then
              return;
            if s^.asg_lhs = t then begin
              used_outside_loop := true;
              return;
            end;
            usewalk(s^.asg_lhs, t);
          end;
          142: begin
            if s^.br_cond = t then begin
              used_outside_loop := true;
              return;
            end;
            usewalk(s^.br_cond, t);
          end;
          151:
            if s^.x48 <> nil then begin
              if s^.x48 = t then begin
                used_outside_loop := true;
                return;
              end;
              usewalk(s^.x48, t);
            end;
          188: begin
            if s^.x48 = t then begin
              used_outside_loop := true;
              return;
            end;
            usewalk(s^.x48, t);
          end;
          otherwise
        end;
        used_outside_loop := found;
        if found then
          return;
        s := s^.next;
      end;
    end;
  end;
end;

procedure subwalk(
    n: il_$node_ptr_t;
    ptr: il_$node_ptr_t;
    target: il_$node_ptr_t); options(val_param); internal; forward;

{ substitute_ptr_for_target - slot (an operand of parent) holding
  target gets ptr (target a 145: ptr itself, its uses up by n; else
  ptr's base, recorded as a substitution point of parent), and a 137
  target used more than once gives its use back (from an address
  parent: its operand's when n > 1, the uses down by n but kept at 1
  at least); another slot is walked into (subwalk).  A slot then of
  kind 137, 164 or 143 is folded (kfold) and recorded as a
  substitution point of parent.

  0x0E7564, 0x104 bytes: parent passed on by address (`pea (8,A6)');
  the kinds compared in turn. }

procedure substitute_ptr_for_target(
    parent: il_$node_ptr_t;
    ptr: il_$node_ptr_t;
    target: il_$node_ptr_t;
    var slot: il_$node_ptr_t;
    n: integer32); options(val_param); internal;
var
  k: integer;
begin
  if slot = target then begin
    if target^.kind = 145 then begin
      slot := ptr;
      g_opt_tree_ptr_t(ptr)^.uses := g_opt_tree_ptr_t(ptr)^.uses + n;
    end
    else begin
      slot := ptr^.xp[6];
      opt_str_$add_substitution_point(ptr^.xp[6], parent);
    end;
    if target^.kind = 137 then
      if g_opt_tree_ptr_t(target)^.uses > 1 then begin
        k := parent^.kind;
        if (k = 145) or (k = 147) or (k = 146) or (k = 205) then begin
          if n > 1 then begin
            g_opt_tree_ptr_t(target)^.uses :=
              g_opt_tree_ptr_t(target)^.uses - n;
            il_utils_$adjust_uc(g_opt_tree_ptr_t(target)^.opnd[1], -1);
          end
          else
            il_utils_$adjust_uc(target, -1);
          if g_opt_tree_ptr_t(target)^.uses < 1 then
            g_opt_tree_ptr_t(target)^.uses := 1;
        end
        else
          il_utils_$adjust_uc(target, -1);
      end;
  end
  else
    subwalk(slot, ptr, target);
  k := slot^.kind;
  if (k = 137) or (k = 164) or (k = 143) then begin
    kfold(parent, slot);
    opt_str_$add_substitution_point(slot, parent);
  end;
end;

{ subwalk - substitute_ptr_for_target over the operands of n (the uses
  of an address node passed for its base and index).

  0x0E7668, 0x102 bytes: the kinds compared in turn; 145's index and
  164's second operand share the base's call. }

procedure subwalk;
var
  k: integer;
begin
  case n^.kind of
    137, 143:
      for k := 1 to g_opt_tree_ptr_t(n)^.count do
        substitute_ptr_for_target(n, ptr, target,
                                  g_opt_tree_ptr_t(n)^.opnd[k], 1);
    147, 146, 205:
      substitute_ptr_for_target(n, ptr, target, n^.xp[6],
                                g_opt_tree_ptr_t(n)^.uses);
    145: begin
      substitute_ptr_for_target(n, ptr, target, n^.xp[6],
                                g_opt_tree_ptr_t(n)^.uses);
      substitute_ptr_for_target(n, ptr, target, n^.xp[9],
                                g_opt_tree_ptr_t(n)^.uses);
    end;
    171, 175:
      substitute_ptr_for_target(n, ptr, target, n^.xp[4], 1);
    164: begin
      substitute_ptr_for_target(n, ptr, target, n^.xp[5], 1);
      substitute_ptr_for_target(n, ptr, target, n^.xp[6], 1);
    end;
    otherwise
  end;
end;

{ ptrsub - substitute_ptr_for_target over the operands of every
  statement of the loop's blocks (loop, linked through link).

  0x0E776A, 0xFA bytes: each block from its first statement's
  predecessor's next to its last statement. }

procedure ptrsub(
    loop: g_opt_block_ptr_t;
    ptr: il_$node_ptr_t;
    target: il_$node_ptr_t); options(val_param); internal;
var
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  k: integer;
begin
  b := loop;
  while b <> nil do begin
    s := b^.first_stmt^.prev;
    repeat
      s := s^.next;
      case s^.kind of
        140: begin
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.asg_rhs, 1);
          if s^.asg_x <> nil then
            substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                      s^.asg_x, 1);
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.asg_lhs, 1);
        end;
        139:
          for k := 1 to s^.eval_count do
            substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                      s^.eval_opnd[k], 1);
        142:
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.br_cond, 1);
        151:
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.x48, 1);
        otherwise
      end;
    until s = b^.last_stmt;
    b := b^.link;
  end;
end;
%endif

{ deluse -use u (189) taken off cse parent p's (190) list of uses.

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
