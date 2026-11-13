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
    A5 0x3530D8 (cc.m68k): the module's data (+0 .. +161: four
    variable sets, autoinc's descriptor, the loop, the induction
    variables' and candidates' lists, the temporaries' count, the
    preheader's and header's numbers); cc.a88k's unit (A5 0x513A84)
    has none.  cc.a88k also holds, at 0x2B3868 (0x10E bytes, right
    after opt_str_$add_substitution_point), usewalk's code taking its
    parent's frame from the dynamic link, with no .blocks entry and no
    caller.

  The routines that load A5 are global (opt_str_$product_of,
  opt_str_$opmod_of_operand, walkuses, strengthreduce and delparent in
  g_opt.ins.pas; the substitution points in globals_from_general.ins.pas;
  opt_str_$product_of_consts and deluse only this unit calls); the
  others do not and are internal (they run on strengthreduce's A5).
  Trees are read through g_opt.ins.pas's g_opt_tree_t, statements
  through g_opt_stmt_t, the cse nodes through g_opt_cse_t, other nodes
  by offset.  delay.pas's class_size (its +888: the bytes of each
  register class) is read absolutely and declared here, as are the
  routines of other units without an insert heading (opt_loop's
  fixupchildren, kfold; opt_main's fixup_blocks and
  opt_main_$symidx_of_varn_or_fsym are in g_opt.ins.pas since opt_main
  was translated, docs/questions.md 126).

  dpc gaps (docs/dpc-gaps.md): 2 (ptrsub's case), 3 (new and dispose of
  the lists' cells), 8 (`in' on the kind and operator sets), 24 (calls
  as right operands of `and').  identity_mul, smuggle_constants and
  opt_str_$product_of set their pointer results from a local (dpc
  refuses a parameter or a cast there, gaps 11 and 15).
}

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
    kind: il_$kind_t;                   { +2 }
    hdr: array [1..3] of integer32;     { +4 }
    uses: integer;                      { +16 }
    unused_18: integer;                 { +18 }
    desc: add_node_$desc_t;             { +20 }
  end;
  { An indexed reference (145) as doinsert reads it for add_pn: +22 a
    signed byte (`ext.w'), +23 an unsigned one. }
  sr_index_ptr_t = ^sr_index_t;
  sr_index_t = packed record
    unused_0: array [0..21] of char;    { +0 }
    align: -128..127;                   { +22 }
    b23: 0..255;                        { +23 }
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
  auto_desc: add_node_$desc_t := [size := 4, rlen := rlen_addr];
                                        { +128: autoinc's descriptor of
                                          the addresses it forms (.rwdi:
                                          size 4, rlen 5) }
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
  delparent, walkuses, strengthreduce;
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
  if t^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
    opt_str_$is_loop_constant_integer := true
  else
    case t^.kind of
      var_name:
        opt_str_$is_loop_constant_integer := (t^.xw[17] & 16#800) <> 0;
      fortran_symbol:
        opt_str_$is_loop_constant_integer := (t^.xw[13] & 16#800) <> 0;
      tree_node:
        if g_opt_tree_ptr_t(t)^.op in [nop_top..or_top, index_top, unpack_top, value_top, extend_top, lshf_top..abs_top, isc_mul_top,
                                       expon_top..min_top, alshf_top..cc_logand_ptop, cc_lognot_ptop, signed_div_top..unsigned_mod_top, isc_signed_rem_top..isc_unsigned_mod_top,
                                       ada_expon_top] then begin
          for k := 1 to g_opt_tree_ptr_t(t)^.count do
            if not opt_str_$is_loop_constant_integer(
                     g_opt_tree_ptr_t(t)^.opnd[k], l) then begin
              opt_str_$is_loop_constant_integer := false;
              return;
            end;
          opt_str_$is_loop_constant_integer := true;
        end
        else if g_opt_tree_ptr_t(t)^.op = value_top then
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
    op: il_$top_t;
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
begin
  opt_str_$product_of_consts := nil;
  if op = mul_top then begin
    if a^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
      if b^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
        opt_str_$product_of_consts :=
          smcontk(integer_ob, a^.int_value * b^.int_value);
  end
  else if op = lshf_top then
    if a^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
      if b^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
        opt_str_$product_of_consts :=
          smcontk(integer_ob, lshft(a^.int_value, b^.int_value));
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
  if t^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then begin
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
      fortran_symbol:
        opt_str_$opmod_of_operand :=
          sizeof_dataclass(ord(t^.xc[10]) & 15, size);
      var_name:
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
      tree_node:
        opt_str_$opmod_of_operand :=
          class_size[g_opt_tree_ptr_t(t)^.rlen];
      dindex_node, ptr_node, disp_node, sym_disp_node:
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
  if t^.op = mul_top then
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
    op: il_$top_t;
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
      r := buildtreenode(extend_top, d, ops, 1);
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
      op: il_$top_t;
      a: il_$node_ptr_t;
      b: il_$node_ptr_t): il_$node_ptr_t; options(val_param);
  var
    t: g_opt_tree_ptr_t;
    res: il_$node_ptr_t;
  begin
    res := nil;
    t := g_opt_tree_ptr_t(a);
    if a^.kind = tree_node then
      if t^.uses = 1 then
        if b^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob] then
          if (t^.op = mul_top) and (t^.opnd[2]^.kind in [blogical_ob..char_ob,
              char16_ob, binteger_ob]) then begin
            t^.opnd[2] := opt_str_$product_of_consts(op, t^.opnd[2], b);
            t^.w28 := opt_str_$opmod_of_operand(t^.opnd[2], d.w8, d.flags.signed);
            res := a;
          end
          else if (t^.op = mul_top) and (t^.opnd[1]^.kind in [blogical_ob..char_ob,
              char16_ob, binteger_ob]) then begin
            t^.opnd[1] := opt_str_$product_of_consts(op, t^.opnd[1], b);
            t^.w26 := opt_str_$opmod_of_operand(t^.opnd[1], d.w6, t^.dflags.signed);
            res := a;
          end
          else if (t^.op = lshf_top) and (op = lshf_top) and
                  (t^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                        binteger_ob]) then begin
            t^.opnd[2] := smcontk(integer_ob,
                                  t^.opnd[2]^.int_value + b^.int_value);
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
  if (op = mul_top) and (a^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob])
      and (a^.int_value = 1) then begin
    opt_str_$product_of := identity_mul(b, rlen, rlen_b, sgn);
    return;
  end;
  if ((op = mul_top) and (b^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob])
      and (b^.int_value = 1)) or
     ((op = lshf_top) and (b^.kind in [blogical_ob..char_ob, char16_ob, binteger_ob])
      and (b^.int_value = 0)) then begin
    opt_str_$product_of := identity_mul(a, rlen, rlen_a, sgn);
    return;
  end;
  r := smuggle_constants(op, a, b);
  if r <> nil then begin
    opt_str_$product_of := r;
    return;
  end;
  if op in [add_top, mul_top, and_top, or_top, set_and_top, set_or_top, f_add_top, f_mul_top, eor_top..min_top] then begin
    r := smuggle_constants(op, b, a);
    if r <> nil then begin
      opt_str_$product_of := r;
      return;
    end;
  end;
  if op = mul_top then begin
    d.rlen := rlen;
    d.w6 := class_size[rlen_a];
    d.w8 := class_size[rlen_b];
    d.size := class_size[rlen];
    d.flags.signed := sgn;
    if rlen = rlen_long then
      if not ((b^.kind = sinteger_ob) or (b^.kind = binteger_ob)
              or (b^.kind = integer_ob)) or
         (a^.kind <> var_name) or (a^.xw[37] <> 0) or (d.w6 <> 2) or
         (d.w8 <> 2) or (d.rlen <> rlen_long) then begin
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
    if d.rlen = rlen_word then begin
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
  if new^.kind = fortran_symbol then begin
    if not (var_$strength_reduction in new^.fs_attr) then
      return;
    t := sr_temp_ptr_t(new^.xp2[11]);
  end
  else if new^.kind = var_name then begin
    if not (var_$strength_reduction in new^.vr_attr) then
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
  if n^.kind = fortran_symbol then begin
    if not (var_$strength_reduction in n^.fs_attr) then
      return;
    t := sr_temp_ptr_t(n^.xp2[11]);
  end
  else if n^.kind = var_name then begin
    if not (var_$strength_reduction in n^.vr_attr) then
      return;
    t := sr_temp_ptr_t(n^.xp[13]);
  end
  else begin
    if n^.kind = tree_node then
      if g_opt_tree_ptr_t(n)^.op = extend_top then begin
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
    var_name: begin
      if not (var_$strength_reduction in temp^.vr_attr) then
        return;
      s := sr_temp_ptr_t(temp^.xp[13])^.asg;
    end;
    fortran_symbol: begin
      if not (var_$strength_reduction in temp^.fs_attr) then
        return;
      s := sr_temp_ptr_t(temp^.xp2[11])^.asg;
    end;
    otherwise
      return;
  end;
  ops[1] := s^.asg_rhs;
  ops[2] := inv;
  s^.asg_rhs := buildtreenode(add_top, s^.asg_desc, ops, 2);
  opt_str_$add_substitution_point(ops[1], s^.asg_rhs);
  opt_str_$add_substitution_point(ops[2], s^.asg_rhs);
  if t^.kind = tree_node then
    g_opt_tree_ptr_t(t)^.opnd[2] := temp
  else if t^.kind = dindex_node then
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
  if t^.kind = fortran_symbol then
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
  if not ((t^.kind = dindex_node) or (t^.kind = tree_node)) then
    return;
  if t^.kind = tree_node then
    if g_opt_tree_ptr_t(t)^.op <> index_top then
      return;
  if t^.kind = tree_node then
    x := g_opt_tree_ptr_t(g_opt_tree_ptr_t(t)^.opnd[2])
  else
    x := g_opt_tree_ptr_t(t^.xp[9]);
  if x^.kind <> tree_node then
    return;
  if x^.uses > 1 then
    return;
  if x^.op <> add_top then
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
  if t^.kind = fortran_symbol then
    p := sr_temp_ptr_t(t^.xp2[11])^.incs
  else if t^.kind = var_name then
    p := sr_temp_ptr_t(t^.xp[13])^.incs
  else
    return;
  b := g_opt_blocks_ptr_t(il_11c)^[preheader_num];
  s := b^.first_stmt;
  while s <> g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt do begin
    n := s^.next;
    if n^.kind = assign_node then
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
  if old^.kind = fortran_symbol then
    p := sr_temp_ptr_t(old^.xp2[11])^.points
  else
    p := sr_temp_ptr_t(old^.xp[13])^.points;
  q := p;
  while q <> nil do begin
    last := q;
    n := q^.point;
    if n <> nil then
      case n^.kind of
        cmp_tree_node, tree_node:
          for k := 1 to g_opt_tree_ptr_t(n)^.count do
            if g_opt_tree_ptr_t(n)^.opnd[k] = old then
              g_opt_tree_ptr_t(n)^.opnd[k] := new;
        sym_disp_node, disp_node, ptr_node:
          if n^.xp[6] = old then
            n^.xp[6] := new;
        dindex_node: begin
          if n^.xp[6] = old then
            n^.xp[6] := new;
          if n^.xp[9] = old then
            n^.xp[9] := new;
        end;
        cs_node: begin
          if n^.xp[5] = old then
            n^.xp[5] := new;
          if n^.xp[6] = old then
            n^.xp[6] := new;
        end;
        pf_call, cc_call:
          if n^.xp[4] = old then
            n^.xp[4] := new;
        assign_node: begin
          if g_opt_stmt_ptr_t(n)^.asg_rhs = old then
            g_opt_stmt_ptr_t(n)^.asg_rhs := new;
          if g_opt_stmt_ptr_t(n)^.asg_x <> nil then
            if g_opt_stmt_ptr_t(n)^.asg_x = old then
              g_opt_stmt_ptr_t(n)^.asg_x := new;
        end;
        eval_node:
          for k := 1 to g_opt_stmt_ptr_t(n)^.eval_count do
            if g_opt_stmt_ptr_t(n)^.eval_opnd[k] = old then
              g_opt_stmt_ptr_t(n)^.eval_opnd[k] := new;
        cbranch_node:
          if g_opt_stmt_ptr_t(n)^.br_cond = old then
            g_opt_stmt_ptr_t(n)^.br_cond := new;
        return_node:
          if g_opt_stmt_ptr_t(n)^.x48 <> nil then
            if g_opt_stmt_ptr_t(n)^.x48 = old then
              g_opt_stmt_ptr_t(n)^.x48 := new;
        otherwise
          cgerr_no_source(28, 0);
      end;
    q := q^.next;
  end;
  if new^.kind = fortran_symbol then begin
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
  while s^.kind = assign_node do begin
    if s = b then begin
      if (s^.asg_op = a^.asg_op) and (s^.asg_rlen = a^.asg_rlen) then
        if s^.asg_rhs = a^.asg_rhs then
          stmtfound := true
        else if (s^.asg_rhs^.kind = tree_node)
            and (a^.asg_rhs^.kind = tree_node) then begin
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
  while s^.kind = assign_node do begin
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
  if a^.kind = fortran_symbol then begin
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
      if (p^.stmt^.asg_rhs^.kind <> tree_node) or
         (q^.stmt^.asg_rhs^.kind <> tree_node) then begin
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
    tree_node: begin
      if (x^.op <> y^.op) or
         (sr_tree_view_ptr_t(x)^.desc <> sr_tree_view_ptr_t(y)^.desc) or
         (x^.flags <> y^.flags) or (x^.uses <> y^.uses) or
         (x^.count <> y^.count) then begin
        opt_str_$trees_equivalent := false;
        return;
      end;
      if (x^.op = func_call_top) or (x^.op = call_top) then begin
        opt_str_$trees_equivalent := false;
        return;
      end;
      if x^.op <> addr_top then
        if x^.flags * [phase_atm..phase_devwt, phase_sd_eff, phase_voldecl, phase_phys] <> [] then begin
          opt_str_$trees_equivalent := false;
          return;
        end;
      for k := 1 to x^.count do
        if not opt_str_$trees_equivalent(x^.opnd[k], y^.opnd[k],
                                         x^.op = addr_top) then begin
          opt_str_$trees_equivalent := false;
          return;
        end;
      opt_str_$trees_equivalent := true;
    end;
    dindex_node:
      opt_str_$trees_equivalent :=
        opt_str_$trees_equivalent(a^.xp[9], b^.xp[9], false) and
        (a^.xp[6] = b^.xp[6]) and in_index and (a^.xl[8] = b^.xl[8]) and
        (a^.xl[1] = b^.xl[1]) and (a^.xw[21] = b^.xw[21]) and
        (a^.xw[20] = b^.xw[20]) and
        ((a^.xp[6]^.kind = reloc_absolute_addr_con)
         or (a^.xp[6]^.kind = addr_con) or
         (a^.xp[6]^.kind = db_register) or (a^.xp[6]^.kind = sb_register) or
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
        if s^.kind = assign_node then
          if il_utils_$is_strength_reduction_temp(s^.asg_lhs) then
            if s^.asg_op = scalar_aop then begin
              s2 := s^.next;
              while s2 <> g_opt_blocks_ptr_t(il_11c)^[preheader_num + 1]^.first_stmt do begin
                if s2^.kind = assign_node then begin
                  n := s2^.asg_lhs;
                  t := nil;
                  if n^.kind = var_name then begin
                    if var_$strength_reduction in n^.vr_attr then
                      t := sr_temp_ptr_t(n^.xp[13]);
                  end
                  else if n^.kind = fortran_symbol then
                    if var_$strength_reduction in n^.fs_attr then
                      t := sr_temp_ptr_t(n^.xp2[11]);
                  if t <> nil then
                    if (t^.tree^.owner^.block^.serial = cur_loop^.serial) and
                       (s2^.asg_op = scalar_aop) and (s^.asg_rlen = s2^.asg_rlen) and
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
      tree_node, cmp_tree_node:
        for k := 1 to g_opt_tree_ptr_t(n)^.count do
          if g_opt_tree_ptr_t(n)^.opnd[k] = t then begin
            found := true;
            return;
          end
          else
            usewalk(g_opt_tree_ptr_t(n)^.opnd[k], t);
      disp_node, sym_disp_node, ptr_node:
        if n^.xp[6] = t then
          found := true
        else
          usewalk(n^.xp[6], t);
      dindex_node:
        if n^.xp[6] = t then
          found := true
        else begin
          usewalk(n^.xp[6], t);
          if n^.xp[9] = t then
            found := true
          else
            usewalk(n^.xp[9], t);
        end;
      pf_call:
        if n^.xp[4] = t then
          found := true
        else
          usewalk(n^.xp[4], t);
      cc_call:
        if n^.xp[4] = t then
          found := true
        else
          usewalk(n^.xp[4], t);
      cs_node:
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
  if not ((t^.kind = cmp_tree_node) or (t^.kind = tree_node)) then
    return;
  for i := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    if b^.serial <> cur_loop^.serial then begin
      s := b^.first_stmt;
      while s <> b^.last_stmt^.next do begin
        case s^.kind of
          eval_node:
            for k := 1 to s^.eval_count do
              if s^.eval_opnd[k] = t then begin
                used_outside_loop := true;
                return;
              end
              else
                usewalk(s^.eval_opnd[k], t);
          assign_node: begin
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
          cbranch_node: begin
            if s^.br_cond = t then begin
              used_outside_loop := true;
              return;
            end;
            usewalk(s^.br_cond, t);
          end;
          return_node:
            if s^.x48 <> nil then begin
              if s^.x48 = t then begin
                used_outside_loop := true;
                return;
              end;
              usewalk(s^.x48, t);
            end;
          use_def_ob: begin
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
  k: il_$kind_t;
begin
  if slot = target then begin
    if target^.kind = dindex_node then begin
      slot := ptr;
      g_opt_tree_ptr_t(ptr)^.uses := g_opt_tree_ptr_t(ptr)^.uses + n;
    end
    else begin
      slot := ptr^.xp[6];
      opt_str_$add_substitution_point(ptr^.xp[6], parent);
    end;
    if target^.kind = tree_node then
      if g_opt_tree_ptr_t(target)^.uses > 1 then begin
        k := parent^.kind;
        if (k = dindex_node) or (k = disp_node) or (k = ptr_node)
            or (k = sym_disp_node) then begin
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
  if (k = tree_node) or (k = cs_node) or (k = cmp_tree_node) then begin
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
    tree_node, cmp_tree_node:
      for k := 1 to g_opt_tree_ptr_t(n)^.count do
        substitute_ptr_for_target(n, ptr, target,
                                  g_opt_tree_ptr_t(n)^.opnd[k], 1);
    disp_node, ptr_node, sym_disp_node:
      substitute_ptr_for_target(n, ptr, target, n^.xp[6],
                                g_opt_tree_ptr_t(n)^.uses);
    dindex_node: begin
      substitute_ptr_for_target(n, ptr, target, n^.xp[6],
                                g_opt_tree_ptr_t(n)^.uses);
      substitute_ptr_for_target(n, ptr, target, n^.xp[9],
                                g_opt_tree_ptr_t(n)^.uses);
    end;
    cc_call, pf_call:
      substitute_ptr_for_target(n, ptr, target, n^.xp[4], 1);
    cs_node: begin
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
        assign_node: begin
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.asg_rhs, 1);
          if s^.asg_x <> nil then
            substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                      s^.asg_x, 1);
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.asg_lhs, 1);
        end;
        eval_node:
          for k := 1 to s^.eval_count do
            substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                      s^.eval_opnd[k], 1);
        cbranch_node:
          substitute_ptr_for_target(il_$node_ptr_t(s), ptr, target,
                                    s^.br_cond, 1);
        return_node:
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

%if cc_a88k %then
%else
{ match_rlens_srtemp_and_assign - assignment s of an auto-increment
  address for t: an index t scaled (+40 a shift count) has s's value
  multiplied by 1 shifted left that many (opt_str_$product_of, the old
  value a substitution point of the new); a word product stored at
  width class 4 or 5 made a longword one; a variable (109) of +36 16
  stored at class 5 given 32.

  0x0E790A, 0xF2 bytes: the product's operand classes s's width and
  the constant's operand size (opt_str_$opmod_of_operand of it, 2,
  signed: the image's), rlen pushed twice (`move.w (SP),-(SP)'). }

procedure match_rlens_srtemp_and_assign(
    t: il_$node_ptr_t;
    s: g_opt_stmt_ptr_t); options(val_param); internal;
var
  old, c: il_$node_ptr_t;
  r: g_opt_tree_ptr_t;
begin
  if t^.kind = dindex_node then
    if t^.xw[20] <> 0 then begin
      old := s^.asg_rhs;
      c := smcontk(integer_ob, lshft(1, t^.xw[20]));
      il_utils_$do_substitution(il_$node_ptr_t(s), s^.asg_rhs,
        opt_str_$product_of(mul_top, s^.asg_rhs, c, s^.asg_rlen, s^.asg_rlen,
                            opt_str_$opmod_of_operand(c, 2, true), true,
                            nil));
      opt_str_$add_substitution_point(old, s^.asg_rhs);
    end;
  if (s^.asg_rlen = rlen_addr) or (s^.asg_rlen = rlen_long) then begin
    r := g_opt_tree_ptr_t(s^.asg_rhs);
    if r^.kind = tree_node then
      if r^.rlen = rlen_word then
        if r^.op = mul_top then
          r^.rlen := rlen_long;
  end;
  if s^.asg_rlen = rlen_addr then
    if s^.asg_lhs^.kind = var_name then
      if s^.asg_lhs^.xl[9] = 16 then
        s^.asg_lhs^.xl[9] := 32;
end;

{ doinsert - the address t (a 137 sum, or a 145 made a 26 of it with
  auto_desc) becomes an auto-increment of temporary s1's (asg the
  preheader's assignment, s2 the loop's stepping one): t's operand
  takes s1's first value, s1 assigns t (or the 26) as an address
  (auto_desc), r the dereference of s1's temporary (add_pn: of t's
  item, align and +23 for a 145), used once; s2 and every assignment
  of the temporary in the region with another descriptor get auto_desc
  (match_rlens_srtemp_and_assign); the new value's tree then evaluated
  at the region statement before s1 (fixupchildren).

  0x0E79FC, 0x200 bytes: all four by address; a 110 temporary's +10
  low nibble set to 11; the region walk a repeat from opt_region's
  statement to runbackend_16's; fixupchildren's flag the byte at
  0x0E7BFC (the next routine's first, 0x4E: false to its `bpl'). }

procedure doinsert(
    var s1: g_opt_stmt_ptr_t;
    var s2: g_opt_stmt_ptr_t;
    var t: il_$node_ptr_t;
    var r: il_$node_ptr_t); internal;
var
  ops: add_node_$opnds_t;
  x, lhs: il_$node_ptr_t;
  q, s: g_opt_stmt_ptr_t;
  reg: integer;
begin
  if t^.kind = dindex_node then begin
    ops[1] := t;
    x := buildtreenode(addr_top, auto_desc, ops, 1);
    opt_str_$add_substitution_point(t, x);
  end;
  lhs := s1^.asg_lhs;
  if lhs^.kind = fortran_symbol then
    lhs^.xc[10] := chr(ord(lhs^.xc[10]) & 16#F0 ! 11);
  if t^.kind = tree_node then
    g_opt_tree_ptr_t(t)^.opnd[2] := s1^.asg_rhs;
  if t^.kind = dindex_node then
    t^.xp[9] := s1^.asg_rhs;
  if t^.kind = dindex_node then
    s1^.asg_rhs := x
  else
    s1^.asg_rhs := t;
  s1^.asg_desc := auto_desc;
  if t^.kind = dindex_node then
    r := add_pn(s1^.asg_lhs, t^.xp[7], sr_index_ptr_t(t)^.align,
                sr_index_ptr_t(t)^.b23)
  else
    r := add_pn(s1^.asg_lhs, s1^.asg_lhs, 0, 0);
  opt_str_$add_substitution_point(r^.xp[6], r);
  g_opt_tree_ptr_t(r)^.uses := 1;
  s2^.asg_desc := auto_desc;
  match_rlens_srtemp_and_assign(t, s2);
  q := opt_4009c[opt_region];
  repeat
    if q <> s2 then
      if q^.kind = assign_node then
        if q^.asg_lhs = s2^.asg_lhs then
          if q^.asg_desc <> auto_desc then begin
            q^.asg_desc := auto_desc;
            match_rlens_srtemp_and_assign(t, q);
          end;
    q := q^.next;
  until q = opt_4009c[runbackend_16];
  reg := 0;
  s := s1;
  while reg = 0 do begin
    reg := s^.hdr.region;
    s := s^.prev;
  end;
  fixupchildren(s1^.asg_rhs, reg, false);
end;

{ check_tree_node - t is a 137 of operator 13 (an address sum) of a
  strength reduction temporary (operand 2) and a constant or variable
  base that is not one (operand 1), not used outside the loop, the
  base not a variable whose type (opt_var_types, else type_exp) is of
  kind 130.

  0x0E7BFE, 0xD2 bytes: the base's kind by a set of 0..207; find_var
  called before the base's kind is tested; the result in D2. }

function check_tree_node(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  te: g_opt_vtype_t;
  x: g_opt_tree_ptr_t;
  v: integer;
  r: boolean;
begin
  r := false;
  x := g_opt_tree_ptr_t(t);
  if x^.kind = tree_node then
    if x^.op = index_top then
      if il_utils_$is_strength_reduction_temp(x^.opnd[2]) then
        if x^.opnd[1]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, var_name,
                                fortran_symbol, sb_register, db_register,
                                set_con_ob,
                                addr_con, rec_const_ob,
                                    reloc_absolute_addr_con, dpcomplex_ob,
                                    binteger_ob] then
          if not il_utils_$is_strength_reduction_temp(x^.opnd[1]) then
            if not used_outside_loop(t) then begin
              v := find_var(x^.opnd[1]);
              if x^.opnd[1]^.kind = var_name then begin
                if v > 0 then begin
                  if opt_var_types^[v].base^.kind <> ptr_type then
                    r := true;
                end
                else begin
                  type_exp(x^.opnd[1], addr(te));
                  if te.base^.kind <> ptr_type then
                    r := true;
                end;
              end
              else
                r := true;
            end;
  check_tree_node := r;
end;

{ opt_str_$is_loop_invariant - t is a constant, a variable marked
  constant (bit 11 of a 109's +32, a 110's +24) or a variable no
  statement of loop assigns (vnum), not a strength reduction temporary
  (bit 17).  f and x are not read.

  0x0E7CEA, 0xB0 bytes: the constants by a set of 0..207; loop at
  (18,A6) (f a word at 12, x a longword at 14); each block from its
  first statement to its last's next, stopping at nil. }

function opt_str_$is_loop_invariant(
    t: il_$node_ptr_t;
    f: boolean;
    x: il_$node_ptr_t;
    loop: g_opt_block_ptr_t): boolean; options(val_param); internal;
var
  fl: integer32;
  v: integer;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
begin
  if t^.kind in [blogical_ob..complex_ob, char_string_ob, char32_string_ob,
                 char16_ob, sb_register, db_register, set_con_ob, addr_con,
                 rec_const_ob, reloc_absolute_addr_con, dpcomplex_ob,
                 binteger_ob] then begin
    opt_str_$is_loop_invariant := true;
    return;
  end;
  case t^.kind of
    var_name:
      fl := t^.xl[8];
    fortran_symbol:
      fl := t^.xl[6];
    otherwise begin
      opt_str_$is_loop_invariant := false;
      return;
    end;
  end;
  if (fl & 16#800) <> 0 then begin
    opt_str_$is_loop_invariant := true;
    return;
  end;
  if (fl & 16#20000) <> 0 then begin
    opt_str_$is_loop_invariant := false;
    return;
  end;
  v := find_var(t);
  if v > 0 then begin
    b := loop;
    while b <> nil do begin
      s := b^.first_stmt;
      while s <> nil do begin
        if s = b^.last_stmt^.next then
          exit;
        if s^.hdr.vnum = v then begin
          opt_str_$is_loop_invariant := false;
          return;
        end;
        s := s^.next;
      end;
      b := b^.link;
    end;
  end;
  opt_str_$is_loop_invariant := true;
end;

{ check_dindex - the indexed reference t (145) has a strength reduction
  temporary for index and a loop invariant base that is not a
  variable whose type is of kind 130 assigned in the loop (a use-def
  chain of the base at t's statement's region reaching from a block of
  cur_loop: serial), nor, without a number, of such a type.

  0x0E7DB4, 0xF4 bytes: the result in D2, passed (false) for
  opt_str_$is_loop_invariant's f. }

function check_dindex(
    t: il_$node_ptr_t): boolean; options(val_param); internal;
var
  te: g_opt_vtype_t;
  c: g_opt_chain_ptr_t;
  v: integer;
  r: boolean;
begin
  r := false;
  if il_utils_$is_strength_reduction_temp(t^.xp[9]) then
    if opt_str_$is_loop_invariant(t^.xp[6], r, nil, cur_loop) then begin
      if t^.xp[6]^.kind = var_name then begin
        v := find_var(t^.xp[6]);
        if v > 0 then begin
          if opt_var_types^[v].base^.kind = ptr_type then begin
            c := opt_4009c[g_opt_tree_ptr_t(t)^.owner^.hdr.region]^.vars^[v]^.ud;
            while c <> nil do begin
              if c^.stmt^.block^.serial = cur_loop^.serial then begin
                check_dindex := false;
                return;
              end;
              c := c^.next;
            end;
          end;
          r := true;
        end
        else begin
          type_exp(t^.xp[6], addr(te));
          if te.base^.kind <> ptr_type then
            r := true;
        end;
      end
      else
        r := true;
    end;
  check_dindex := r;
end;

{ find_assigns - s1 the preheader assignment of temporary t (nil when
  t is none, when the run of assignments before it starts no region
  statement, or when that statement is not in the preheader), s2 the
  first assignment of t in cur_loop's blocks (nil when none).

  0x0E7EA8, 0xCC bytes: s1 and s2 by address; the blocks' walk stops
  at a block without statements. }

procedure find_assigns(
    var s1: g_opt_stmt_ptr_t;
    var s2: g_opt_stmt_ptr_t;
    t: il_$node_ptr_t); internal;
var
  p, s: g_opt_stmt_ptr_t;
  b: g_opt_block_ptr_t;
begin
  if t^.kind = fortran_symbol then
    s1 := sr_temp_ptr_t(t^.xp2[11])^.asg
  else if t^.kind = var_name then
    s1 := sr_temp_ptr_t(t^.xp[13])^.asg
  else
    s1 := nil;
  s2 := nil;
  if s1 = nil then
    return;
  p := s1;
  while p^.kind = assign_node do
    p := p^.prev;
  if p^.hdr.region = 0 then
    return;
  if p^.block^.num <> preheader_num then begin
    s1 := nil;
    return;
  end;
  b := cur_loop;
  while b <> nil do begin
    s := b^.first_stmt;
    if s = nil then
      return;
    while s <> b^.last_stmt^.next do begin
      if s^.kind = assign_node then
        if s^.asg_lhs = t then begin
          s2 := s;
          return;
        end;
      s := s^.next;
      if s = nil then
        exit;
    end;
    b := b^.link;
  end;
end;

{ checkauto - the operand slot of parent, an address sum of a
  temporary (check_tree_node) or an indexed reference by one
  (check_dindex) whose temporary has its assignments (find_assigns),
  made an auto-increment (doinsert): the base variable marked (bit 12
  of a 110's +24, a 109's +32), slot given the new dereference (its
  uses parent's for an address parent), recorded as a substitution
  point of parent; other uses of t rewritten (ptrsub) when t was
  shared, and t's use given back as in substitute_ptr_for_target.

  0x0E7F74, 0x202 bytes: parent passed on by address (`pea (8,A6)');
  t copied to a frame word for doinsert. }

procedure checkauto(
    parent: il_$node_ptr_t;
    var slot: il_$node_ptr_t); options(val_param); internal;
var
  s1, s2: g_opt_stmt_ptr_t;
  t, v, ptr: il_$node_ptr_t;
  k: il_$kind_t;
begin
  t := slot;
  if (t^.kind = tree_node) and check_tree_node(t) then begin
    find_assigns(s1, s2, g_opt_tree_ptr_t(t)^.opnd[2]);
    if (s1 = nil) or (s2 = nil) then
      return;
    v := g_opt_tree_ptr_t(t)^.opnd[1];
  end
  else begin
    if t^.kind <> dindex_node then
      return;
    if not check_dindex(t) then
      return;
    find_assigns(s1, s2, t^.xp[9]);
    if (s1 = nil) or (s2 = nil) then
      return;
    v := t^.xp[7];
  end;
  if v^.kind = fortran_symbol then
    v^.xc[26] := chr(ord(v^.xc[26]) ! 16#10)
  else if v^.kind = var_name then
    v^.xc[34] := chr(ord(v^.xc[34]) ! 16#10)
  else
    return;
  doinsert(s1, s2, t, ptr);
  k := parent^.kind;
  if (k = dindex_node) or (k = ptr_node) or (k = sym_disp_node)
      or (k = disp_node) then
    if t^.kind = dindex_node then
      g_opt_tree_ptr_t(ptr)^.uses := g_opt_tree_ptr_t(parent)^.uses;
  if t^.kind = dindex_node then
    slot := ptr
  else
    slot := ptr^.xp[6];
  opt_str_$add_substitution_point(slot, parent);
  k := parent^.kind;
  if (k = dindex_node) or (k = ptr_node) or (k = sym_disp_node)
      or (k = disp_node) then
    if g_opt_tree_ptr_t(parent)^.uses > 1 then
      g_opt_tree_ptr_t(ptr)^.uses := g_opt_tree_ptr_t(parent)^.uses;
  if (g_opt_tree_ptr_t(t)^.uses > 1) or
     ((g_opt_tree_ptr_t(slot)^.uses > 1) and (slot^.kind = tree_node) and
      (g_opt_tree_ptr_t(slot)^.op = addr_top)) then
    ptrsub(cur_loop, ptr, t);
  if t^.kind = tree_node then
    if g_opt_tree_ptr_t(t)^.uses > 1 then begin
      k := parent^.kind;
      if (k = dindex_node) or (k = ptr_node) or (k = sym_disp_node)
          or (k = disp_node) then begin
        if g_opt_tree_ptr_t(parent)^.uses > 1 then begin
          g_opt_tree_ptr_t(t)^.uses :=
            g_opt_tree_ptr_t(t)^.uses - g_opt_tree_ptr_t(parent)^.uses;
          il_utils_$adjust_uc(g_opt_tree_ptr_t(t)^.opnd[1], -1);
        end
        else
          il_utils_$adjust_uc(t, -1);
        if g_opt_tree_ptr_t(t)^.uses < 1 then
          g_opt_tree_ptr_t(t)^.uses := 1;
      end
      else
        il_utils_$adjust_uc(t, -1);
    end;
end;

{ autoinc - auto-increment addressing: in each loop (the blocks in
  reverse depth-first order; a header with a latch preheader that
  dominates it) every address operand of every node of the loop's
  blocks offered to checkauto, after multidim for the address sums of
  two temporaries; a node standing for its statement (flag 6) followed
  to it, a tree of no uses skipped.

  0x0E8176, 0x39A bytes: auto_desc set first (size 4, class 5, 0, 0);
  the tree kinds by a set of 0..207; a 139's operands from the last;
  146, 147, 205 and 145's index share 164's last call. }

procedure autoinc; internal;
var
  i: integer;
  bn: g_opt_num_t;
  b, l: g_opt_block_ptr_t;
  n: integer32;
  t: il_$node_ptr_t;
  x: g_opt_tree_ptr_t;
  k: integer;
begin
  auto_desc.rlen := rlen_addr;
  auto_desc.w6 := 0;
  auto_desc.w8 := 0;
  auto_desc.size := 4;
  for i := opt_last_block downto opt_first_block do begin
    bn := opt_dfs_block^[i];
    b := g_opt_blocks_ptr_t(il_11c)^[bn];
    if b^.flags.header and (b^.preheader <> nil) then
      if b^.preheader^.num <> bn then
        if b^.preheader^.flags.latch then
          if dom(b^.preheader, b) then begin
            l := select_loop(bn);
            preheader_num := b^.preheader^.num;
            cur_loop := l;
            while l <> nil do begin
              for n := l^.first to l^.last do begin
                t := g_opt_nodes_ptr_t(il_120)^[n];
                if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                               dindex_node..disp_node, cs_node, cc_call,
                               pf_call, cse_use_ob,
                               sym_disp_node] then
                  if phase_cse in g_opt_tree_ptr_t(t)^.flags then
                    while phase_cse in g_opt_tree_ptr_t(t)^.flags do
                      t := g_opt_nodes_ptr_t(il_120)^[g_opt_tree_ptr_t(t)^.stmt];
                if not ((t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                                     dindex_node..disp_node, cs_node, cc_call,
                                     pf_call,
                                     cse_use_ob, sym_disp_node]) and
                        (g_opt_tree_ptr_t(t)^.uses = 0)) then
                  case t^.kind of
                    assign_node: begin
                      if (g_opt_stmt_ptr_t(t)^.asg_lhs^.kind = dindex_node) or
                         (g_opt_stmt_ptr_t(t)^.asg_lhs^.kind = tree_node) then
                        checkauto(t, g_opt_stmt_ptr_t(t)^.asg_lhs);
                      if (g_opt_stmt_ptr_t(t)^.asg_rhs^.kind = dindex_node) or
                         (g_opt_stmt_ptr_t(t)^.asg_rhs^.kind = tree_node) then
                        checkauto(t, g_opt_stmt_ptr_t(t)^.asg_rhs);
                      if g_opt_stmt_ptr_t(t)^.asg_x <> nil then
                        if (g_opt_stmt_ptr_t(t)^.asg_x^.kind = dindex_node) or
                           (g_opt_stmt_ptr_t(t)^.asg_x^.kind = tree_node) then
                          checkauto(t, g_opt_stmt_ptr_t(t)^.asg_x);
                    end;
                    eval_node:
                      for k := g_opt_stmt_ptr_t(t)^.eval_count downto 1 do
                        if (g_opt_stmt_ptr_t(t)^.eval_opnd[k]^.kind = dindex_node) or
                           (g_opt_stmt_ptr_t(t)^.eval_opnd[k]^.kind = tree_node) then
                          checkauto(t, g_opt_stmt_ptr_t(t)^.eval_opnd[k]);
                    tree_node, cmp_tree_node: begin
                      x := g_opt_tree_ptr_t(g_opt_tree_ptr_t(t)^.opnd[2]);
                      if g_opt_tree_ptr_t(t)^.op = index_top then
                        if x^.kind = tree_node then
                          if x^.op = add_top then
                            if (x^.opnd[1]^.kind = fortran_symbol) or
                               (x^.opnd[1]^.kind = var_name) then
                              if (x^.opnd[2]^.kind = fortran_symbol) or
                                 (x^.opnd[2]^.kind = var_name) then
                                multidim(t, bn);
                      for k := 1 to g_opt_tree_ptr_t(t)^.count do
                        if (g_opt_tree_ptr_t(t)^.opnd[k]^.kind = dindex_node)
                            or
                           (g_opt_tree_ptr_t(t)^.opnd[k]^.kind = tree_node) then
                          checkauto(t, g_opt_tree_ptr_t(t)^.opnd[k]);
                    end;
                    return_node:
                      if g_opt_stmt_ptr_t(t)^.x48 <> nil then
                        if (g_opt_stmt_ptr_t(t)^.x48^.kind = dindex_node) or
                           (g_opt_stmt_ptr_t(t)^.x48^.kind = tree_node) then
                          checkauto(t, g_opt_stmt_ptr_t(t)^.x48);
                    disp_node, ptr_node, sym_disp_node:
                      checkauto(t, t^.xp[6]);
                    dindex_node: begin
                      x := g_opt_tree_ptr_t(t^.xp[9]);
                      if x^.kind = tree_node then
                        if x^.op = add_top then
                          if (x^.opnd[1]^.kind = fortran_symbol) or
                             (x^.opnd[1]^.kind = var_name) then
                            if (x^.opnd[2]^.kind = fortran_symbol) or
                               (x^.opnd[2]^.kind = var_name) then
                              multidim(t, bn);
                      checkauto(t, t^.xp[6]);
                      checkauto(t, t^.xp[9]);
                    end;
                    cs_node: begin
                      checkauto(t, t^.xp[5]);
                      checkauto(t, t^.xp[6]);
                    end;
                    otherwise
                  end;
              end;
              l := l^.link;
            end;
          end;
  end;
end;
%endif

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
  if n^.kind = cse_parent_ob then
    n := g_opt_cse_ptr_t(n)^.p_tree;
  case n^.kind of
    eval_node:
      for k := g_opt_stmt_ptr_t(n)^.eval_count downto 1 do
        if walkuses(g_opt_stmt_ptr_t(n)^.eval_opnd[k], r) then
          found := true;
    cbranch_node:
      if walkuses(g_opt_stmt_ptr_t(n)^.br_cond, r) then
        found := true;
    assign_node: begin
      if walkuses(g_opt_stmt_ptr_t(n)^.asg_lhs, r) or
         walkuses(g_opt_stmt_ptr_t(n)^.asg_rhs, r) then
        found := true;
      if g_opt_stmt_ptr_t(n)^.asg_x <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.asg_x, r) then
          found := true;
    end;
    return_node:
      if g_opt_stmt_ptr_t(n)^.x48 <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.x48, r) then
          found := true;
    use_def_ob:
      if g_opt_stmt_ptr_t(n)^.x48 <> nil then
        if walkuses(g_opt_stmt_ptr_t(n)^.x48, r) then
          found := true;
    cmp_tree_node, tree_node:
      for k := 1 to g_opt_tree_ptr_t(n)^.count do begin
        if walkuses(g_opt_tree_ptr_t(n)^.opnd[k], r) then
          found := true;
        u := g_opt_cse_ptr_t(g_opt_tree_ptr_t(n)^.opnd[k]);
        if u^.kind = cse_use_ob then
          if g_opt_tree_ptr_t(u^.u_tree)^.op = addr_top then
            if walkuses(u^.u_tree, r) then
              found := true;
      end;
    disp_node, ptr_node, sym_disp_node:
      if walkuses(n^.xp[6], r) then
        found := true;
    dindex_node:
      if walkuses(n^.xp[6], r) or walkuses(n^.xp[9], r) then
        found := true;
    cs_node:
      if walkuses(n^.xp[5], r) then
        found := true
      else if walkuses(n^.xp[6], r) then
        found := true;
    pf_call, cc_call:
      if walkuses(n^.xp[4], r) then
        found := true;
    var_name, fortran_symbol:
      if n = r then
        found := true;
    otherwise
  end;
  walkuses := found;
end;

%if cc_a88k %then
%else
{ elimuses - induction variable v (its number: a 109's +74, a 110's
  +16) no longer used at the loop's region statements that had it in
  their sets but do not use it (walkuses) nor take its address (flag
  bit 9): its use-def chains there cut (each defining statement's
  entry flagged 16#100), its set bit cleared.

  0x0E8798, 0x17A bytes: the block and the statement in frame words
  (-16, -12; the statement passed to walkuses by address, v by its
  parameter's); the variable as a one-element frame set (-96). }

procedure elimuses(
    loop: g_opt_block_ptr_t;
    v: il_$node_ptr_t); options(val_param); internal;
var
  one: g_opt_varset_t;
  e: g_opt_stmt_ptr_t;
  b: g_opt_block_ptr_t;
  s: il_$node_ptr_t;
  c: g_opt_chain_ptr_t;
  n, r: integer;
  vr: g_opt_var_ptr_t;
begin
  if v^.kind = var_name then
    n := v^.xw[37]
  else
    n := v^.xw[8];
  if n <= 0 then
    return;
  b := loop;
  while b <> nil do begin
    s := il_$node_ptr_t(b^.first_stmt);
    repeat
      r := g_opt_stmt_ptr_t(s)^.hdr.region;
      if r <> 0 then begin
        e := opt_4009c[r];
        if e^.vset <> nil then
          if n in e^.vset^ then
            if (e^.vars^[n]^.flags & 16#200) = 0 then
              if not walkuses(s, v) then begin
                c := e^.vars^[n]^.ud;
                while c <> nil do begin
                  vr := opt_4009c[c^.stmt^.hdr.region]^.vars^[n];
                  vr^.flags := vr^.flags ! 16#100;
                  c := c^.next;
                end;
                e^.vars^[n]^.ud := nil;
                one := [n];
                e^.vset^ := e^.vset^ - one;
              end;
      end;
      s := il_$node_ptr_t(g_opt_stmt_ptr_t(s)^.next);
    until g_opt_stmt_ptr_t(s) = b^.last_stmt^.next;
    b := b^.link;
  end;
end;

{ add_assign - a new assignment (140, 80 bytes from gspace) to
  temporary temp before statement s: with op 0 its first value init *
  factor (opt_str_$product_of, of d's classes and sign), recorded as
  temp's asg; else temp op= step * factor (recorded among temp's
  incs) or temp op= factor without a step; d its descriptor (a word
  class's size 2, a longword's 4; a word typed temporary of class 4
  made a longword).  A region statement for it: s's, for op 0 the one
  before s in a latch block, else the nearest before (op 0) or after
  (op <> 0; s moved on) that has one, for op 0 backed out of cur_loop
  and past deleted ones; the new value's tree evaluated there
  (fixupchildren).  Of a region, the assignment is linked before s
  (s's region, no flags, null position), and takes the place of s
  when s is that region's empty evaluation (one constant operand) in a
  latch block: s's header copied, the region's entry, the block's
  first or last statement and il_120's node replaced.

  0x0E8912, 0x506 bytes: d by address; vnum and num cleared with
  `andi.l #0xFF' of +38, the flags of +41, +42 with `andi.l
  #0xFF0000FF' of +40 (docs/rev889-patterns.md 10); the registers
  16#7FFF1FFF; the variables' table from mem_$alloc of opt_main_18;
  fixupchildren's flag the byte at 0x0E7BFC (false, as in doinsert);
  the header copy ten longwords and a word (+4..+45). }

procedure add_assign(
    s: g_opt_stmt_ptr_t;
    temp: il_$node_ptr_t;
    init: il_$node_ptr_t;
    step: il_$node_ptr_t;
    factor: il_$node_ptr_t;
    op: il_$aop_t;
    in d: add_node_$desc_t); options(val_param); internal;
type
  head_t = record
    w: array [1..10] of integer32;      { +4..+43 }
    h: integer;                         { +44 }
  end;
  head_ptr_t = ^head_t;
var
  p, n: g_opt_stmt_ptr_t;
  x: il_$node_ptr_t;
  blk: g_opt_block_ptr_t;
  q: sr_inc_ptr_t;
  reg, rr, k: integer;
begin
  if op = scalar_aop then begin
    if temp^.kind = var_name then
      if sr_temp_ptr_t(temp^.xp[13])^.asg <> nil then
        return;
    if temp^.kind = fortran_symbol then
      if sr_temp_ptr_t(temp^.xp2[11])^.asg <> nil then
        return;
  end;
  p := s;
  reg := s^.hdr.region;
  if reg <> 0 then begin
    blk := opt_4009c[reg]^.block;
    if blk^.flags.latch and (op = scalar_aop) and (s <> blk^.first_stmt) then begin
      p := s^.prev;
      reg := p^.hdr.region;
    end;
  end;
  if reg = 0 then begin
    if op = scalar_aop then
      while p^.hdr.region = 0 do begin
        p := p^.prev;
        reg := p^.hdr.region;
      end
    else
      while s^.hdr.region = 0 do begin
        s := s^.next;
        reg := s^.hdr.region;
      end;
  end
  else if op = scalar_aop then
    if opt_4009c[reg]^.block^.serial = cur_loop^.serial then
      while (opt_4009c[reg]^.block^.serial = cur_loop^.serial) or
            opt_4009c[reg]^.hdr.deleted do
        reg := reg - 1;
  n := gspace(80);
  if n = nil then
    cgerr_no_source(9, 0);
  n^.kind := assign_node;
  n^.hdr.vnum := 0;
  n^.hdr.num := 0;
  if n^.vset <> nil then
    n^.vset^ := [];
  n^.block := nil;
  n^.vars := mem_$alloc(opt_main_18, il_180^.xw[145] * 4);
  if n^.vars = nil then
    cgerr_no_source(9, 0);
  for k := 1 to il_180^.xw[145] do
    n^.vars^[k] := nil;
  n^.cses := nil;
  n^.regs := [0..12, 16..30];
  n^.hdr.b7 := false;
  n^.hdr.b6 := false;
  n^.hdr.b5 := false;
  n^.hdr.b4 := false;
  n^.hdr.b3 := false;
  n^.hdr.counted := false;
  n^.hdr.no_prune := false;
  n^.hdr.deleted := false;
  n^.hdr.b42_7 := false;
  n^.hdr.b42_6 := false;
  n^.hdr.kills := false;
  n^.hdr.b42_4 := false;
  n^.hdr.last := false;
  n^.hdr.b42_2 := false;
  n^.hdr.first := false;
  n^.hdr.entry := false;
  n^.asg_x := nil;
  n^.asg_op := op;
  if op = scalar_aop then begin
    if temp^.kind = var_name then
      sr_temp_ptr_t(temp^.xp[13])^.asg := n;
    if temp^.kind = fortran_symbol then
      sr_temp_ptr_t(temp^.xp2[11])^.asg := n;
    il_utils_$do_substitution(il_$node_ptr_t(n), n^.asg_rhs,
      opt_str_$product_of(mul_top, init, factor, d.rlen, d.w6, d.w8,
                          d.flags.signed, nil));
    x := il_$node_ptr_t(n);
    opt_str_$add_substitution_point(init, x);
    x := il_$node_ptr_t(n);
    opt_str_$add_substitution_point(factor, x);
  end
  else if step <> nil then begin
    if temp^.kind = var_name then begin
      q := gspace(8);
      q^.stmt := n;
      q^.next := sr_temp_ptr_t(temp^.xp[13])^.incs;
      sr_temp_ptr_t(temp^.xp[13])^.incs := q;
    end;
    if temp^.kind = fortran_symbol then begin
      q := gspace(8);
      q^.stmt := n;
      q^.next := sr_temp_ptr_t(temp^.xp2[11])^.incs;
      sr_temp_ptr_t(temp^.xp2[11])^.incs := q;
    end;
    il_utils_$do_substitution(il_$node_ptr_t(n), n^.asg_rhs,
      opt_str_$product_of(mul_top, step, factor, d.rlen, d.w6, d.w8,
                          d.flags.signed, nil));
    opt_str_$add_substitution_point(factor, n^.asg_rhs);
    opt_str_$add_substitution_point(step, n^.asg_rhs);
  end
  else
    il_utils_$do_substitution(il_$node_ptr_t(n), n^.asg_rhs, factor);
  rr := reg;
  fixupchildren(n^.asg_rhs, rr, false);
  n^.asg_lhs := temp;
  if reg <> 0 then begin
    n^.hdr.region := 0;
    n^.next := s;
    n^.prev := s^.prev;
    n^.hdr.b45 := 0;
    n^.line := spos_$null_position;
  end;
  n^.asg_desc := d;
  if n^.asg_rlen = rlen_word then
    n^.asg_size := 2
  else if n^.asg_rlen = rlen_long then
    n^.asg_size := 4;
  if temp^.kind = var_name then
    if temp^.xp[7] = il_$node_ptr_t(runbackend_10) then
      if (d.w6 = 2) and (d.rlen = rlen_long) then
        temp^.xp[7] := il_$node_ptr_t(runbackend_0c);
  n^.asg_w54 := 0;
  n^.asg_w56 := 0;
  if reg <> 0 then
    if s^.hdr.region = reg then
      if s^.kind = eval_node then
        if s^.eval_count = 1 then
          if s^.eval_opnd[1]^.kind = integer_ob then
            if opt_4009c[reg]^.block^.flags.latch then begin
              head_ptr_t(addr(n^.prev))^ := head_ptr_t(addr(s^.prev))^;
              if n^.hdr.first then
                opt_4009c[reg]^.block^.first_stmt := n;
              opt_4009c[reg] := n;
              if opt_4009c[reg]^.next^.hdr.first then
                opt_4009c[reg]^.block^.last_stmt := n;
              n^.prev^.next := n;
              n^.next^.prev := n;
              g_opt_nodes_ptr_t(il_120)^[opt_4009c[reg]^.hdr.num] :=
                il_$node_ptr_t(n);
              return;
            end;
  s^.prev^.next := n;
  s^.prev := n;
end;

{ getval - the step an assignment s (140) gives induction variable v
  (number v of opt_region's table) through tree t: in a statement of
  another loop's region (serial) s's variable; for v := v + c or v - c
  (v or a 147 of v first, c a constant) c, negated for a subtraction;
  for v := a + b or a - b where s's region uses v the other operand;
  else t itself (a constant stored directly too).

  0x0E8E18, 0x1CA bytes: the constants by a set of 0..207; the result
  in D2, then A0. }

function getval(
    t: il_$node_ptr_t;
    v: integer;
    s: g_opt_stmt_ptr_t): il_$node_ptr_t; options(val_param); internal;
var
  r, vn: il_$node_ptr_t;
  e: g_opt_stmt_ptr_t;
  x: g_opt_tree_ptr_t;
begin
  r := t;
  x := g_opt_tree_ptr_t(t);
  if s^.kind = assign_node then
    if not ((t^.kind in [blogical_ob..complex_ob, char_string_ob,
                         char32_string_ob, char16_ob, set_con_ob, rec_const_ob,
                         dpcomplex_ob, binteger_ob]) and
            (s^.asg_op = scalar_aop)) then begin
      e := opt_4009c[s^.hdr.region];
      if e^.block^.serial <> cur_loop^.serial then
        r := s^.asg_lhs
      else if not (t^.kind in [blogical_ob..complex_ob, char_string_ob,
                               char32_string_ob, char16_ob, set_con_ob,
                               rec_const_ob, dpcomplex_ob, binteger_ob]) then
        if (t^.kind = tree_node) and ((x^.op = sub_top) or (x^.op = add_top)) and
           (x^.opnd[2]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                 char32_string_ob, char16_ob, set_con_ob,
                                 rec_const_ob, dpcomplex_ob,
                                 binteger_ob]) then begin
          vn := opt_4009c[opt_region]^.vars^[v]^.node;
          if (x^.opnd[1] = vn) or
             ((x^.opnd[1]^.kind = disp_node)
              and (x^.opnd[1]^.xp[6] = vn)) then begin
            r := x^.opnd[2];
            if x^.op = sub_top then
              r := smcontk(integer_ob, -r^.int_value);
          end;
        end
        else if t^.kind = tree_node then
          if s^.kind = assign_node then
            if e^.vset <> nil then
              if v in e^.vset^ then
                if (x^.op = sub_top) or (x^.op = add_top) then begin
                  vn := opt_4009c[opt_region]^.vars^[v]^.node;
                  if x^.opnd[2] = vn then
                    r := x^.opnd[1]
                  else if x^.opnd[1] = vn then
                    r := x^.opnd[2];
                end;
    end;
  getval := r;
end;

{ findvalues - the assignments giving temporary temp (= iv * factor,
  of descriptor d) its values, for induction variable iv (number v)
  used at region statement r in the loop headed by block h: along the
  use-def chain of v at r, a definition in the loop steps temp after
  it (add_assign of getval's step, unless a neighbouring statement
  already assigns temp); for the only definition, when it does not
  reach itself, temp is first assigned in the preheader and assigned
  the definition's value again at the loop's back edge; a definition
  outside the loop gives the first value in the preheader (at the
  preheader's last region statement, or after it unless it branches),
  given a use-def entry there when all of r's other definitions are
  in the loop; a 188 likewise; another kind is cgerr 3.  An only
  definition in the loop whose region uses v has its own chain
  followed instead when one of those definitions is outside.  Then
  every assignment of v in the loop not reached otherwise
  (not_on_ud_chain) or without a step of temp near it (noincfound)
  steps temp too; without a first value one is put in the preheader.

  0x0E90F6, 0xB5A bytes: d by address, passed on; the chain, the
  region numbers, the operator and the flags in frame words (-16 ..
  -64); the walk of the chains a loop entered again by branches
  (written with labels); a dead call with operator 0 for a step (the
  image's: its operator is 1 or 2 there); the loop's predecessor
  search leaves k past the predecessors when none is in the loop. }

procedure findvalues(
    r: integer;
    v: integer;
    h: g_opt_block_ptr_t;
    temp: il_$node_ptr_t;
    factor: il_$node_ptr_t;
    in d: add_node_$desc_t;
    iv: il_$node_ptr_t); options(val_param); internal;
label
  10, 20, 30, 40;
var
  c, q, cell: g_opt_chain_ptr_t;
  e, x, y, p, lt: g_opt_stmt_ptr_t;
  l: g_opt_block_ptr_t;
  rhs: g_opt_tree_ptr_t;
  val, nv: il_$node_ptr_t;
  reg, lastreg, cr: integer;
  op, op2: il_$aop_t;
  k, j: integer;
  single, done, ok, found, f, a: boolean;

  { not_on_ud_chain - no definition on v's use-def chain at region
    statement r is region statement k.

    0x0E8FFC, 0x66 bytes: nested, the parent's frame not used. }

  function not_on_ud_chain(
      k: integer;
      r: integer;
      v: integer): boolean; options(val_param);
  var
    c: g_opt_chain_ptr_t;
    res: boolean;
  begin
    res := true;
    c := opt_4009c[r]^.vars^[v]^.ud;
    while c <> nil do begin
      if c^.stmt^.hdr.region = k then begin
        res := false;
        exit;
      end;
      c := c^.next;
    end;
    not_on_ud_chain := res;
  end;

  { noincfound - no assignment to temp among the statements of no
    region before and after region statement k.

    0x0E9062, 0x94 bytes: nested, the parent's frame not used. }

  function noincfound(
      k: integer;
      temp: il_$node_ptr_t): boolean; options(val_param);
  var
    p: g_opt_stmt_ptr_t;
  begin
    noincfound := true;
    p := opt_4009c[k]^.prev;
    while p^.hdr.region = 0 do begin
      if p^.kind = assign_node then
        if p^.asg_lhs = temp then begin
          noincfound := false;
          return;
        end;
      p := p^.prev;
    end;
    p := opt_4009c[k]^.next;
    while p^.hdr.region = 0 do begin
      if p^.kind = assign_node then
        if p^.asg_lhs = temp then begin
          noincfound := false;
          return;
        end;
      p := p^.next;
    end;
  end;

begin
  lastreg := g_opt_blocks_ptr_t(il_11c)^[preheader_num]^.last_stmt^.hdr.region;
  reg := r;
  if v = 0 then
    return;
  if opt_4009c[reg]^.vars^[v] = nil then
    return;
  if opt_4009c[reg]^.vars^[v]^.ud = nil then
    return;
  c := opt_4009c[reg]^.vars^[v]^.ud;
  if c <> nil then
    single := c^.next = nil
  else
    single := false;
  done := false;
  goto 30;
10:
  cr := c^.stmt^.hdr.region;
  e := opt_4009c[cr];
  if e^.kind = assign_node then begin
    if e^.hdr.vnum <> v then
      goto 20;
    val := getval(e^.asg_rhs, v, opt_4009c[cr]);
    if e^.block^.serial = h^.serial then begin
      op2 := add_to_aop;
      if e^.asg_op = sub_from_aop then
        op2 := sub_from_aop;
      if e^.prev^.kind = assign_node then
        if (e^.prev^.asg_op = sub_from_aop) or (e^.prev^.asg_op = add_to_aop) then
          if e^.prev^.asg_lhs = temp then
            goto 20;
      if e^.next^.kind = assign_node then
        if (e^.next^.asg_op = sub_from_aop) or (e^.next^.asg_op = add_to_aop) then
          if e^.next^.hdr.region = 0 then begin
            if e^.next^.asg_lhs = temp then
              goto 20;
            p := e^.next;
            found := false;
            repeat
              if p^.kind = assign_node then
                if p^.asg_lhs = temp then
                  found := true;
              p := p^.next;
            until p^.hdr.region <> 0;
            if found then
              goto 20;
          end;
      if single and not done and (c^.next = nil) and
         not ((e^.vset <> nil) and (v in e^.vset^)) then begin
        op := scalar_aop;
        x := opt_4009c[lastreg];
        if (x^.kind = branch_node) or (x^.kind = nlbranch_node)
            or (x^.kind = cbranch_node) then
          add_assign(opt_4009c[lastreg], temp, iv, nil, factor, op, d)
        else
          add_assign(opt_4009c[lastreg]^.next, temp, iv, nil, factor, op, d);
        op := add_to_aop;
        e^.hdr.no_prune := true;
        for k := 1 to h^.npreds do
          if h^.pred[k]^.serial = h^.serial then
            exit;
        lt := h^.pred[k]^.last_stmt;
        rhs := g_opt_tree_ptr_t(e^.asg_rhs);
        nv := e^.asg_rhs;
        if rhs^.kind = tree_node then begin
          nv := buildtreenode(rhs^.op, sr_tree_view_ptr_t(rhs)^.desc,
                              rhs^.opnd, rhs^.count);
          for j := 1 to rhs^.count do
            opt_str_$add_substitution_point(rhs^.opnd[j], nv);
        end;
        add_assign(lt, temp, nil, nv, factor, op, d);
        lt^.prev^.asg_op := scalar_aop;
        done := true;
        goto 20;
      end;
      if op2 = scalar_aop then
        add_assign(opt_4009c[cr], temp, iv, nil, factor, op2, d)
      else if (op2 = sub_from_aop) or (op2 = add_to_aop) then
        add_assign(e^.next, temp, nil, val, factor, op2, d);
      goto 20;
    end;
    op := scalar_aop;
    if not done then begin
      ok := true;
      q := opt_4009c[reg]^.vars^[v]^.ud;
      while q <> nil do begin
        if q <> c then
          if h^.serial <> q^.stmt^.block^.serial then begin
            ok := false;
            exit;
          end;
        q := q^.next;
      end;
      x := opt_4009c[lastreg];
      if (x^.kind = branch_node) or (x^.kind = nlbranch_node)
          or (x^.kind = cbranch_node) then
        add_assign(opt_4009c[lastreg], temp, iv, nil, factor, op, d)
      else
        add_assign(opt_4009c[lastreg]^.next, temp, iv, nil, factor, op, d);
      if ok then begin
        y := opt_4009c[lastreg]^.next;
        if y^.vars <> nil then
          if y^.vars^[v] = nil then begin
            y^.vars^[v] := mem_$alloc(opt_main_18, 18);
            if y^.vars^[v] = nil then
              cgerr_no_source(9, 0);
            y^.vars^[v]^ := opt_4009c[reg]^.vars^[v]^;
            q := y^.vars^[v]^.ud;
            if q <> nil then begin
              y^.vars^[v]^.ud := mem_$alloc(opt_main_18, 8);
              if y^.vars^[v]^.ud = nil then
                cgerr_no_source(9, 0);
              y^.vars^[v]^.ud^.next := nil;
              while q <> nil do begin
                if q^.stmt^.block^.serial <> h^.serial then begin
                  y^.vars^[v]^.ud^.stmt := q^.stmt;
                  exit;
                end;
                q := q^.next;
              end;
            end;
          end;
      end;
    end;
    done := true;
    goto 20;
  end;
  if e^.kind = use_def_ob then
    if e^.block^.serial <> h^.serial then begin
      if not done then begin
        op := scalar_aop;
        x := opt_4009c[lastreg];
        if (x^.kind = branch_node) or (x^.kind = nlbranch_node)
            or (x^.kind = cbranch_node) then
          add_assign(opt_4009c[lastreg], temp, iv, nil, factor, op, d)
        else
          add_assign(opt_4009c[lastreg]^.next, temp, iv, nil, factor, op, d);
        done := true;
      end;
      goto 20;
    end;
  cgerr(3, opt_4009c[runbackend_16]^.line, opt_4009c[runbackend_16]);
20:
  c := c^.next;
  if c <> nil then
    goto 10;
  if single and not done then begin
    e := opt_4009c[cr];
    if e^.vset <> nil then
      if v in e^.vset^ then
        if e^.block^.serial = h^.serial then
          if (opt_4009c[r]^.vars^[v]^.flags & 16#400) = 0 then
            if (e^.vars^[v]^.flags & 16#400) = 0 then begin
              c := e^.vars^[v]^.ud;
              reg := cr;
              f := false;
              q := c;
              while q <> nil do begin
                if q^.stmt^.block^.serial <> h^.serial then begin
                  f := true;
                  exit;
                end;
                q := q^.next;
                if q = nil then
                  c := nil;
              end;
              if c = nil then
                goto 40;
              cell := c;
              while cell <> nil do begin
                if f then
                  goto 30;
                reg := cell^.stmt^.hdr.region;
                q := opt_4009c[reg]^.vars^[v]^.ud;
                while q <> nil do begin
                  if q^.stmt^.block^.serial <> h^.serial then begin
                    f := true;
                    exit;
                  end;
                  q := q^.next;
                end;
                if f then begin
                  c := opt_4009c[reg]^.vars^[v]^.ud;
                  goto 30;
                end;
                cell := cell^.next;
              end;
            end;
  end;
30:
  if c <> nil then
    goto 10;
40:
  l := select_loop(h^.num);
  while l <> nil do begin
    p := l^.first_stmt;
    while p^.hdr.region = 0 do
      p := p^.next;
    k := p^.hdr.region;
    repeat
      x := opt_4009c[k];
      if not x^.hdr.deleted then
        if x^.hdr.vnum = v then
          if x^.kind = assign_node then begin
            if x^.vset <> nil then
              a := noincfound(k, temp) and (v in x^.vset^)
            else
              a := false;
            if not_on_ud_chain(k, r, v) or a then begin
              val := getval(x^.asg_rhs, v, opt_4009c[k]);
              op := add_to_aop;
              if x^.asg_op = sub_from_aop then
                op := sub_from_aop;
              if not ((x^.prev^.kind = assign_node) and
                      ((x^.prev^.asg_op = sub_from_aop) or (x^.prev^.asg_op = add_to_aop)) and
                      (x^.prev^.asg_lhs = temp)) then
                if (x^.next^.kind = assign_node) and
                   ((x^.next^.asg_op = sub_from_aop) or (x^.next^.asg_op = add_to_aop)) and
                   (x^.next^.hdr.region = 0) then begin
                  if x^.next^.asg_lhs <> temp then begin
                    p := x^.next;
                    found := false;
                    repeat
                      if p^.kind = assign_node then
                        if p^.asg_lhs = temp then
                          found := true;
                      p := p^.next;
                    until p^.hdr.region <> 0;
                    if not found then
                      add_assign(x^.next, temp, nil, val, factor, op, d);
                  end;
                end
                else
                  add_assign(x^.next, temp, nil, val, factor, op, d);
            end;
          end;
      k := k + 1;
    until opt_4009c[k]^.block <> l;
    l := l^.link;
  end;
  if not done then begin
    op := scalar_aop;
    x := g_opt_blocks_ptr_t(il_11c)^[preheader_num]^.last_stmt;
    if (x^.kind = branch_node) or (x^.kind = nlbranch_node)
        or (x^.kind = cbranch_node) then
      add_assign(g_opt_blocks_ptr_t(il_11c)^[preheader_num]^.last_stmt,
                 temp, iv, nil, factor, op, d)
    else
      add_assign(g_opt_blocks_ptr_t(il_11c)^[preheader_num]^.last_stmt^.next,
                 temp, iv, nil, factor, op, d);
  end;
end;

{ opt_str_$make_name - s the name of temporary n: `<OSR$n>' (n five
  digits, zero filled).

  0x0E9C50, 0x66 bytes: s by address. }

procedure opt_str_$make_name(
    out s: prtsub_$line_t;
    n: integer); options(val_param); internal;
begin
  s.length := 0;
  prtcatc(s, '<');
  prtcats(s, 'OSR$', 4);
  prtint(s, n, 5, true);
  prtcatc(s, '>');
end;

{ create_sr_temp_var - a new strength reduction temporary of type typ
  for the loop headed by block h: its sr_temp_t (18 bytes, its first
  point 8 bytes, from gspace; cgerr_no_source(9, 0) for nil); in a C
  routine (il_180's +377 bits 6..4 = 2) a 110 (83 bytes: +44 high
  nibble 3, data class 2, +11 high nibble 2, +68 -1, the routine at
  +40, the name in its own +70, +72), else a 109 (84 bytes: the
  routine at +20, typ at +28, storage class 2, +78 -1, its name an
  identifier, kind 76); both flagged 14 and 17 (16#24000).

  0x0E9CBA, 0x17A bytes: ntemps counted first; the name built in the
  frame (-264). }

function create_sr_temp_var(
    typ: il_$node_ptr_t;
    h: integer): il_$node_ptr_t; options(val_param); internal;
var
  name: prtsub_$line_t;
  p: sr_point_ptr_t;
  t: sr_temp_ptr_t;
  n: il_$node_ptr_t;
begin
  ntemps := ntemps + 1;
  p := gspace(8);
  t := gspace(18);
  if (p = nil) or (t = nil) then
    cgerr_no_source(9, 0);
  t^.tree := nil;
  t^.points := p;
  t^.incs := nil;
  t^.asg := nil;
  t^.header := h;
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then begin
    n := gspace(84);
    n^.kind := var_name;
    n^.xp[5] := il_180;
    n^.xp[7] := typ;
    n^.xw[36] := 2;
    n^.vr_attr := [var_$temporary, var_$strength_reduction];
    n^.xp[13] := il_$node_ptr_t(t);
    n^.xw[39] := -1;
    n^.xl[15] := 0;
    opt_str_$make_name(name, ntemps);
    n^.xp[1] := idntk(id_ob, name.body, name.length);
  end
  else begin
    n := gspace(83);
    n^.kind := fortran_symbol;
    n^.xc[44] := chr(ord(n^.xc[44]) & 16#0F ! 16#30);
    n^.xp[1] := nil;
    n^.xc[10] := chr(ord(n^.xc[10]) & 16#F0 ! 2);
    n^.xc[11] := chr(ord(n^.xc[11]) & 16#0F ! 16#20);
    n^.xw[34] := -1;
    n^.xp[10] := il_180;
    n^.xp2[11] := il_$node_ptr_t(t);
    n^.fs_attr := [var_$temporary, var_$strength_reduction];
    opt_str_$make_name(name, ntemps);
    strings_$memmove(n^.xc[72], name.body, name.length);
    n^.xw[35] := name.length;
  end;
  create_sr_temp_var := n;
end;

{ setflag - mark variable n an induction variable (bit 20 of a 109's
  +32, a 110's +24).

  0x0E9E34, 0x40 bytes: the two kinds tested whole; `bset #4' of the
  flags' second byte. }

procedure setflag(
    n: il_$node_ptr_t); options(val_param); internal;
begin
  if n <> nil then
    if (n^.kind = fortran_symbol) or (n^.kind = var_name) then
      if n^.kind = var_name then
        n^.xc[33] := chr(ord(n^.xc[33]) ! 16#10)
      else
        n^.xc[25] := chr(ord(n^.xc[25]) ! 16#10);
end;

{ removeflag - the mark of setflag cleared.

  0x0E9E74, 0x40 bytes: `bclr #4'. }

procedure removeflag(
    n: il_$node_ptr_t); options(val_param); internal;
begin
  if n <> nil then
    if (n^.kind = fortran_symbol) or (n^.kind = var_name) then
      if n^.kind = var_name then
        n^.xc[33] := chr(ord(n^.xc[33]) & 16#EF)
      else
        n^.xc[25] := chr(ord(n^.xc[25]) & 16#EF);
end;

{ newexpr - tree t added at the end of the candidate expressions
  (exprs) unless there; cgerr_no_source(9, 0) when new gives nil.

  0x0E9EB4, 0xA4 bytes: new (PAS_$NEW, 8 bytes). }

procedure newexpr(
    t: il_$node_ptr_t); options(val_param); internal;
var
  p, q: sr_list_ptr_t;
begin
  if exprs = nil then begin
    new(exprs);
    if exprs = nil then
      cgerr_no_source(9, 0);
    exprs^.node := t;
    exprs^.next := nil;
  end
  else begin
    p := exprs;
    while p^.node <> t do begin
      if p^.next = nil then begin
        new(q);
        if q = nil then
          cgerr_no_source(9, 0);
        p^.next := q;
        q^.node := t;
        q^.next := nil;
        return;
      end;
      p := p^.next;
    end;
  end;
end;

{ removeexpr - tree t taken off the candidate expressions (its cell
  not disposed).

  0x0E9F58, 0x52 bytes. }

procedure removeexpr(
    t: il_$node_ptr_t); options(val_param); internal;
var
  p, prev, nxt: sr_list_ptr_t;
begin
  if exprs <> nil then
    if exprs^.node = t then
      exprs := exprs^.next
    else begin
      prev := exprs;
      p := exprs^.next;
      while p <> nil do begin
        nxt := p^.next;
        if p^.node = t then begin
          prev^.next := nxt;
          exit;
        end;
        prev := p;
        p := nxt;
      end;
    end;
end;

{ walkexpr - found set when tree t uses an induction variable (setflag)
  other than through a load (15, 16), a shared product or shift used
  outside the loop, or a 171 or 175.

  0x0E9FAA, 0x12E bytes: found by address, cleared first; the kinds
  compared in turn. }

procedure walkexpr(
    t: il_$node_ptr_t;
    var found: boolean); options(val_param); internal;
var
  x: g_opt_tree_ptr_t;
  k: integer;
begin
  found := false;
  x := g_opt_tree_ptr_t(t);
  case t^.kind of
    cmp_tree_node, tree_node: begin
      if (x^.op = func_call_top) or (x^.op = call_top) then
        return;
      if (x^.op = lshf_top) or (x^.op = mul_top) then
        if x^.uses > 1 then
          if used_outside_loop(t) then
            return;
      for k := 1 to x^.count do begin
        walkexpr(x^.opnd[k], found);
        if found then
          return;
      end;
    end;
    disp_node, ptr_node, sym_disp_node:
      walkexpr(t^.xp[6], found);
    dindex_node: begin
      walkexpr(t^.xp[6], found);
      if found then
        return;
      walkexpr(t^.xp[9], found);
    end;
    cs_node: begin
      walkexpr(t^.xp[5], found);
      if found then
        return;
      walkexpr(t^.xp[6], found);
    end;
    pf_call:
      found := false;
    cc_call:
      found := false;
    var_name:
      if var_$induction in t^.vr_attr then
        found := true;
    fortran_symbol:
      if var_$induction in t^.fs_attr then
        found := true;
    otherwise
  end;
end;

{ disqualify - the candidate expressions kept are those using an
  induction variable (walkexpr), not a tree flagged 20, and, for a
  137, with a product, multiplication (36) or shift operand whose
  operand is a constant or variable or a conversion (18) of a
  variable; the others removed (removeexpr).

  0x0EA0D8, 0x156 bytes: the tree kinds and the operands' by sets of
  0..207; walkexpr's flag a frame copy of D2. }

procedure disqualify; internal;
var
  e: sr_list_ptr_t;
  t: g_opt_tree_ptr_t;
  x, y: g_opt_tree_ptr_t;
  ok: boolean;
  k: integer;
begin
  e := exprs;
  while e <> nil do begin
    walkexpr(e^.node, ok);
    t := g_opt_tree_ptr_t(e^.node);
    if t^.kind in [tree_node, gen_tree_node, cmp_tree_node,
                   dindex_node..disp_node, cs_node, cc_call, pf_call,
                   cse_use_ob, sym_disp_node] then
      if phase_proc_reg in t^.flags then
        ok := false;
    if ok then
      if t^.kind = tree_node then begin
        ok := false;
        for k := 1 to t^.count do begin
          x := g_opt_tree_ptr_t(t^.opnd[k]);
          if x^.kind = tree_node then
            if (x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top) then begin
              if x^.opnd[1]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                      char32_string_ob, char16_ob, var_name,
                                      fortran_symbol, disp_node, set_con_ob,
                                      rec_const_ob, dpcomplex_ob,
                                      binteger_ob] then begin
                ok := true;
                exit;
              end;
              if x^.opnd[2]^.kind in [blogical_ob..complex_ob, char_string_ob,
                                      char32_string_ob, char16_ob, var_name,
                                      fortran_symbol, disp_node, set_con_ob,
                                      rec_const_ob, dpcomplex_ob,
                                      binteger_ob] then begin
                ok := true;
                exit;
              end;
              y := g_opt_tree_ptr_t(x^.opnd[1]);
              if y^.kind = tree_node then
                if y^.op = extend_top then
                  if (y^.opnd[1]^.kind = fortran_symbol)
                      or (y^.opnd[1]^.kind = var_name) then begin
                    ok := true;
                    exit;
                  end;
              y := g_opt_tree_ptr_t(x^.opnd[2]);
              if y^.kind = tree_node then
                if y^.op = extend_top then
                  if (y^.opnd[1]^.kind = fortran_symbol)
                      or (y^.opnd[1]^.kind = var_name) then begin
                    ok := true;
                    exit;
                  end;
            end;
        end;
      end;
    if not ok then
      removeexpr(e^.node);
    e := e^.next;
  end;
end;

{ testexits - a candidate indexed reference (145) used more than once
  is removed unless all its uses are in the loop: the times it is an
  operand of the loop's statements and trees (exitwalk) equal to its
  use count (fetch_uc).

  0x0EA3A0, 0x1C2 bytes: the candidate and the count in registers,
  copied to frame words (-12, -22) for each exitwalk; a 139's operands
  from the last. }

procedure testexits(
    loop: g_opt_block_ptr_t); options(val_param); internal;
var
  e: sr_list_ptr_t;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  cnt, uc, k: integer;

  { fetch_uc - the use count of t (145, 137, 143, 147, 205, 146), else 0.

    0x0EA248, 0x4A bytes: no frame (docs/rev889-patterns.md 16), t at
    (4,SP); four copies of the load. }

  function fetch_uc(
      t: il_$node_ptr_t): integer; options(val_param);
  begin
    case t^.kind of
      dindex_node:
        fetch_uc := g_opt_tree_ptr_t(t)^.uses;
      tree_node, cmp_tree_node:
        fetch_uc := g_opt_tree_ptr_t(t)^.uses;
      disp_node, sym_disp_node:
        fetch_uc := g_opt_tree_ptr_t(t)^.uses;
      ptr_node:
        fetch_uc := g_opt_tree_ptr_t(t)^.uses;
      otherwise
        fetch_uc := 0;
    end;
  end;

  { exitwalk - count the times e's tree is an operand of t or of the
    trees below it (a 171's operand only counted, not walked).

    0x0EA292, 0x10E bytes: e and count by address, passed on; 175 and
    the base of 146, 147 and 205 share the last test. }

  procedure exitwalk(
      t: il_$node_ptr_t;
      var e: sr_list_ptr_t;
      var count: integer); options(val_param);
  var
    k: integer;
  begin
    case t^.kind of
      tree_node, cmp_tree_node:
        for k := 1 to g_opt_tree_ptr_t(t)^.count do
          if g_opt_tree_ptr_t(t)^.opnd[k] = e^.node then
            count := count + 1
          else
            exitwalk(g_opt_tree_ptr_t(t)^.opnd[k], e, count);
      disp_node, sym_disp_node, ptr_node:
        if t^.xp[6] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[6], e, count);
      dindex_node: begin
        if t^.xp[6] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[6], e, count);
        if t^.xp[9] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[9], e, count);
      end;
      pf_call:
        if t^.xp[4] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[4], e, count);
      cc_call:
        if t^.xp[4] = e^.node then
          count := count + 1;
      cs_node: begin
        if t^.xp[5] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[5], e, count);
        if t^.xp[6] = e^.node then
          count := count + 1
        else
          exitwalk(t^.xp[6], e, count);
      end;
      otherwise
    end;
  end;

begin
  e := exprs;
  while e <> nil do begin
    if e^.node^.kind = dindex_node then
      if fetch_uc(e^.node) > 1 then begin
        cnt := 0;
        uc := fetch_uc(e^.node);
        b := loop;
        while b <> nil do begin
          s := b^.first_stmt;
          while s <> b^.last_stmt^.next do begin
            case s^.kind of
              eval_node:
                for k := s^.eval_count downto 1 do
                  exitwalk(s^.eval_opnd[k], e, cnt);
              assign_node: begin
                exitwalk(s^.asg_lhs, e, cnt);
                exitwalk(s^.asg_rhs, e, cnt);
                if s^.asg_x <> nil then
                  exitwalk(s^.asg_x, e, cnt);
              end;
              cbranch_node:
                exitwalk(s^.br_cond, e, cnt);
              return_node:
                if s^.x48 <> nil then
                  exitwalk(s^.x48, e, cnt);
              use_def_ob:
                exitwalk(s^.x48, e, cnt);
              otherwise
            end;
            s := s^.next;
          end;
          b := b^.link;
        end;
        if cnt <> uc then
          removeexpr(e^.node);
      end;
    if e <> nil then
      e := e^.next;
  end;
end;

{ cand_exprs - the candidate expressions of loop's nodes: a 137 with a
  product, multiplication (36) or shift operand, a 145 whose index is
  one; a node standing for its statement (flag 6) followed to it (a
  137 only once an operand qualifies, the operands then looked at
  again).

  0x0EA562, 0x112 bytes: loop the parameter itself, stepped; il_120
  reached as il_c0's +0x60 (docs/rev889-patterns.md 70); the 137's
  restart a branch back to the kind's test. }

procedure cand_exprs(
    loop: g_opt_block_ptr_t); options(val_param); internal;
label
  10;
var
  n: integer32;
  t: g_opt_tree_ptr_t;
  x: g_opt_tree_ptr_t;
  k: integer;
begin
  while loop <> nil do begin
    for n := loop^.first to loop^.last do begin
      t := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[n]);
  10:
      case t^.kind of
        tree_node:
          for k := 1 to t^.count do begin
            x := g_opt_tree_ptr_t(t^.opnd[k]);
            if x^.kind = tree_node then
              if (x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top) then
                if phase_cse in t^.flags then begin
                  t := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[t^.stmt]);
                  goto 10;
                end
                else
                  newexpr(il_$node_ptr_t(t));
          end;
        dindex_node: begin
          while phase_cse in t^.flags do
            t := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[t^.stmt]);
          x := g_opt_tree_ptr_t(il_$node_ptr_t(t)^.xp[9]);
          if x^.kind = tree_node then
            if (x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top) then
              newexpr(il_$node_ptr_t(t));
        end;
        otherwise
      end;
    end;
    loop := loop^.link;
  end;
end;

{ newindvar - variable v put in front of the induction variables (ivs)
  unless there, and marked (setflag); cgerr_no_source(9, 0) when new
  gives nil.

  0x0EA674, 0xAA bytes: new (PAS_$NEW, 8 bytes) of ivs itself, the old
  head kept in A3. }

procedure newindvar(
    v: il_$node_ptr_t); options(val_param); internal;
var
  p, old: sr_list_ptr_t;
begin
  if ivs = nil then begin
    new(ivs);
    if ivs = nil then
      cgerr_no_source(9, 0);
    ivs^.node := v;
    ivs^.next := nil;
  end
  else begin
    p := ivs;
    while p <> nil do begin
      if p^.node = v then
        return;
      p := p^.next;
    end;
    old := ivs;
    new(ivs);
    if ivs = nil then
      cgerr_no_source(9, 0);
    ivs^.node := v;
    ivs^.next := old;
  end;
  setflag(v);
end;

{ recognize_induction_variables - the induction variables of loop:
  variables (of opt_region's table) not excluded whose every
  assignment in the loop is v := v + c, c + v, v - c (operator 0 with
  a 137 of operator 1 or 2) or v op= c (operators 1, 2), c a loop
  constant integer (opt_str_$is_loop_constant_integer); each becomes
  a newindvar, marked; true when there is one.  invariant ends as the
  variables no statement of the loop assigns.

  0x0EA71E, 0x250 bytes: the sets in the module's data; a statement's
  variable as a one-element frame set; each block's statements from
  its first while they are of no block or of this one; ivset and
  others or-ed in from separate copies of the code; the mark again
  inline after newindvar. }

function recognize_induction_variables(
    loop: g_opt_block_ptr_t): boolean; options(val_param); internal;
var
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  r: g_opt_tree_ptr_t;
  v: integer;
  one: g_opt_varset_t;
  a1, a2, found: boolean;
  n: il_$node_ptr_t;
begin
  ivset := [];
  others := excluded;
  invariant := [0..255];
  b := loop;
  while b <> nil do begin
    s := b^.first_stmt;
    repeat
      v := s^.hdr.vnum;
      one := [v];
      invariant := invariant - one;
      if s^.kind <> assign_node then
        others := others + one
      else if v <> 0 then
        if opt_main_$symidx_of_varn_or_fsym(s^.asg_lhs) = v then
          case s^.asg_op of
            scalar_aop: begin
              r := g_opt_tree_ptr_t(s^.asg_rhs);
              if r^.kind <> tree_node then
                others := others + one
              else
                case r^.op of
                  add_top: begin
                    if r^.opnd[2] = s^.asg_lhs then
                      a1 := opt_str_$is_loop_constant_integer(r^.opnd[1], loop)
                    else
                      a1 := false;
                    if r^.opnd[1] = s^.asg_lhs then
                      a2 := opt_str_$is_loop_constant_integer(r^.opnd[2], loop)
                    else
                      a2 := false;
                    if a1 or a2 then
                      ivset := ivset + one
                    else
                      others := others + one;
                  end;
                  sub_top:
                    if (r^.opnd[1] = s^.asg_lhs) and
                       opt_str_$is_loop_constant_integer(r^.opnd[2], loop) then
                      ivset := ivset + one
                    else
                      others := others + one;
                  otherwise
                    others := others + one;
                end;
            end;
            sub_from_aop, add_to_aop:
              if opt_str_$is_loop_constant_integer(s^.asg_rhs, loop) then
                ivset := ivset + one
              else
                others := others + one;
            otherwise
              others := others + one;
          end;
      s := s^.next;
    until (s = nil) or ((s^.block <> nil) and (s^.block <> b));
    b := b^.link;
  end;
  ivset := ivset - others;
  found := false;
  for v := 1 to il_180^.xw[145] do
    if v in ivset then begin
      n := opt_4009c[opt_region]^.vars^[v]^.node;
      newindvar(n);
      if n^.kind = var_name then
        n^.xc[33] := chr(ord(n^.xc[33]) ! 16#10)
      else
        n^.xc[25] := chr(ord(n^.xc[25]) ! 16#10);
      found := true;
    end;
  recognize_induction_variables := found;
end;

{ dump_induction_variables - under -DUMP68 SRI: the routine's name, the
  loop's blocks and the induction variables (address, number, name),
  two to a line, on the listing.

  0x0EA96E, 0x23E bytes: the line in the frame (-264); the blank
  literals share one run of 30 blanks (docs/rev889-patterns.md 27);
  the first listln pops 2 bytes of 4 (docs/rev889-patterns.md 51). }

procedure dump_induction_variables(
    loop: g_opt_block_ptr_t); options(val_param); internal;
var
  s: prtsub_$line_t;
  b: g_opt_block_ptr_t;
  p: sr_list_ptr_t;
  v, nm: il_$node_ptr_t;
  pad: integer;
  odd: boolean;
begin
  s.length := 0;
  listln(s);
  prtcats(s, 'Strength reduction( ', 20);
  nm := il_d4^.xp[2]^.xp[12]^.xp[74];
  prtcats(s, nm^.idnt_name, nm^.idnt_len);
  prtcats(s, ' ):  loop selected comprises blocks:', 36);
  listln(s);
  s.length := 0;
  b := loop;
  while b <> nil do begin
    prtcatc(s, ' ');
    prtint(s, b^.num, 3, true);
    b := b^.link;
  end;
  listln(s);
  s.length := 0;
  prtcats(s, 'Induction variables:', 20);
  listln(s);
  s.length := 0;
  odd := false;
  p := ivs;
  while p <> nil do begin
    v := p^.node;
    prtcats(s, '      ', 6);
    prthex(s, integer32(v), 8);
    prtcats(s, '  ', 2);
    if v^.kind = fortran_symbol then begin
      prtint(s, v^.xw[8], 3, true);
      prtcats(s, '  ', 2);
      prtcats(s, v^.xc[72], v^.xw[35]);
      pad := 18 - v^.xw[35];
    end
    else begin
      prtint(s, v^.xw[37], 3, true);
      prtcats(s, '  ', 2);
      prtcats(s, v^.xp[1]^.idnt_name, v^.xp[1]^.idnt_len);
      pad := 18 - v^.xp[1]^.idnt_len;
    end;
    prtcats(s, '                        ', pad);
    odd := not odd;
    if not odd then begin
      listln(s);
      s.length := 0;
    end;
    p := p^.next;
  end;
  if odd then begin
    listln(s);
    s.length := 0;
  end;
end;

{ minimally_size_sr_temp - temporary v retyped for its register class
  rlen: 4 a longword (runbackend_0c), 2 a word (runbackend_10), when
  its type or its type's +28 is the other; its +36 then 16 for a word,
  else 32.

  0x0EAC16, 0xB2 bytes. }

procedure minimally_size_sr_temp(
    rlen: integer;
    v: il_$node_ptr_t); options(val_param); internal;
begin
  if (rlen = rlen_long) and (v^.xp[7] = il_$node_ptr_t(runbackend_10)) then
    v^.xp[7] := il_$node_ptr_t(runbackend_0c)
  else if (rlen = rlen_word) and (v^.xp[7] = il_$node_ptr_t(runbackend_0c)) then
    v^.xp[7] := il_$node_ptr_t(runbackend_10)
  else if (rlen = rlen_long) and
          (v^.xp[7]^.xp[7] = il_$node_ptr_t(runbackend_10)) then
    v^.xp[7] := il_$node_ptr_t(runbackend_0c)
  else if (rlen = rlen_word) and
          (v^.xp[7]^.xp[7] = il_$node_ptr_t(runbackend_0c)) then
    v^.xp[7] := il_$node_ptr_t(runbackend_10);
  if (v^.xp[7] = il_$node_ptr_t(runbackend_10)) or
     (v^.xp[7]^.xp[7] = il_$node_ptr_t(runbackend_10)) then
    v^.xl[9] := 16
  else
    v^.xl[9] := 32;
end;

{ reduce - each candidate expression reduced, for the loop headed by
  block h: a product or shift (3, 36, 27) of an induction variable (a
  109 or 110 marked by setflag, through a 147 or a word conversion
  used once) by a constant becomes a new temporary (create_sr_temp_var,
  retyped by the variable's size and minimally_size_sr_temp; a 110's
  data class 3 for a longword) whose values findvalues assigns (iv
  times the product of 1 by the constant), substituted for the
  product: the index of an address sum (13), an operand of another
  137 (a constant other operand of a commutative operator swapped to
  the second place first, the operand sizes of a product with it), an
  index (145) not standing for its statement.  A product of a sum
  (operator 1) of a temporary and an induction variable gives the sum
  of a new temporary and the old one times the constant: the old
  temporary's first and stepping assignments after and before the
  statement multiplied too (a large constant widening them to class
  4), and word 110 operands converted (18) for a longword sum.  A
  shift by other than 4 or 2 bytes of operand is left.

  0x0EACC8, 0xE28 bytes: the candidate, the header block, the
  temporary and the region in frame words (-316, -312, -292, -334);
  the commutative operators by a set of 0..47 (opt_str_$product_of's);
  the swap and the address case's test branch into the address sum's
  code (written with a label); for a 145, the variable a word
  constant's other operand stands for when the first is a constant is
  the first again (the image's). }

procedure reduce(
    h: integer); options(val_param); internal;
label
  50, 60, 90;
var
  ops: add_node_$opnds_t;
  dd: add_node_$desc_t;
  e: sr_list_ptr_t;
  hb: g_opt_block_ptr_t;
  t, x, y, z: g_opt_tree_ptr_t;
  iv, temp, w: il_$node_ptr_t;
  s: g_opt_stmt_ptr_t;
  n, rg, k, sw: integer;
begin
  e := exprs;
  hb := g_opt_blocks_ptr_t(il_11c)^[h];
  while e <> nil do begin
    t := g_opt_tree_ptr_t(e^.node);
    case t^.kind of
      tree_node: begin
        if t^.op <> index_top then begin
          for k := 1 to t^.count do begin
            x := g_opt_tree_ptr_t(t^.opnd[k]);
            if x^.kind = tree_node then
              if (x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top) then begin
                y := g_opt_tree_ptr_t(x^.opnd[1]);
                if (y^.kind = tree_node) and (y^.op = add_top) and
                   (x^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                         binteger_ob]) and
                   (y^.opnd[1]^.kind in [var_name, fortran_symbol,
                                         sym_disp_node, disp_node]) and
                   il_utils_$is_strength_reduction_temp(y^.opnd[2]) then begin
                  iv := y^.opnd[1];
                  if iv^.kind = disp_node then
                    iv := iv^.xp[6];
                  if not il_utils_$is_strength_reduction_temp(iv) then
                    goto 90;
                  if x^.kind = tree_node then
                    if x^.op = lshf_top then
                      if not ((x^.w28 = 4) or (x^.w28 = 2)) then
                        goto 90;
                  if iv^.kind = fortran_symbol then begin
                    n := iv^.xw[8];
                    if n <= 0 then
                      goto 90;
                    temp := create_sr_temp_var(nil, h);
                    if x^.rlen = rlen_long then
                      temp^.xc[10] := chr(ord(temp^.xc[10]) & 16#F0 ! 3);
                    rg := x^.owner^.hdr.region;
                    sr_temp_ptr_t(temp^.xp2[11])^.tree := x;
                    findvalues(rg, n, hb, temp,
                      opt_str_$product_of(x^.op, smcontk(integer_ob, 1),
                                          x^.opnd[2],
                        x^.rlen, class_size[x^.rlen],
                        opt_str_$opmod1_of_multiplier(x), x^.dflags.signed,
                        nil),
                      sr_tree_view_ptr_t(x)^.desc, iv);
                    s := opt_4009c[x^.owner^.hdr.region];
                    while s <> nil do begin
                      if s^.kind = assign_node then
                        if s^.asg_lhs = g_opt_tree_ptr_t(x^.opnd[1])^.opnd[2] then
                          if s^.asg_op = add_to_aop then begin
                            il_utils_$do_substitution(il_$node_ptr_t(s), s^.asg_rhs,
                              opt_str_$product_of(x^.op, s^.asg_rhs, x^.opnd[2],
                                s^.asg_rlen, s^.asg_rlen, x^.w28,
                                x^.dflags.signed, nil));
                            if var_$strength_reduction in
                                s^.asg_lhs^.fs_attr then
                              if ((s^.asg_rhs^.kind in [blogical_ob..char_ob,
                                  char16_ob, binteger_ob]) and
                                  ((s^.asg_rhs^.int_value > 32767) or
                                   (s^.asg_rhs^.int_value < -32768))) or
                                 (x^.rlen = rlen_long) then begin
                                s^.asg_rlen := rlen_long;
                                s^.asg_lhs^.xc[10] :=
                                  chr(ord(s^.asg_lhs^.xc[10]) & 16#F0 ! 3);
                              end;
                            exit;
                          end;
                      s := s^.next;
                    end;
                    s := x^.owner;
                    while s <> nil do begin
                      if s^.kind = assign_node then
                        if s^.asg_lhs = g_opt_tree_ptr_t(x^.opnd[1])^.opnd[2] then
                          if s^.asg_op = scalar_aop then begin
                            il_utils_$do_substitution(il_$node_ptr_t(s), s^.asg_rhs,
                              opt_str_$product_of(x^.op, s^.asg_rhs, x^.opnd[2],
                                s^.asg_rlen, s^.asg_rlen, x^.w28,
                                x^.dflags.signed, nil));
                            if var_$strength_reduction in
                                s^.asg_lhs^.fs_attr then
                              if ((s^.asg_rhs^.kind in [blogical_ob..char_ob,
                                  char16_ob, binteger_ob]) and
                                  ((s^.asg_rhs^.int_value > 32767) or
                                   (s^.asg_rhs^.int_value < -32768))) or
                                 (x^.rlen = rlen_long) then begin
                                s^.asg_rlen := rlen_long;
                                s^.asg_lhs^.xc[10] :=
                                  chr(ord(s^.asg_lhs^.xc[10]) & 16#F0 ! 3);
                              end;
                            exit;
                          end;
                      s := s^.prev;
                    end;
                    il_utils_$do_substitution(il_$node_ptr_t(x), x^.opnd[2], temp);
                    il_utils_$do_substitution(il_$node_ptr_t(x), x^.opnd[1],
                      g_opt_tree_ptr_t(x^.opnd[1])^.opnd[2]);
                    x^.op := add_top;
                    if x^.rlen = rlen_long then begin
                      w := x^.opnd[1];
                      if w^.kind = fortran_symbol then
                        if ((ord(w^.xc[10]) & 15) = 2) or
                           ((ord(w^.xc[10]) & 15) = 1) then begin
                          ops[1] := w;
                          dd.rlen := rlen_long;
                          if (ord(w^.xc[10]) & 15) = 1 then
                            dd.w6 := 1
                          else
                            dd.w6 := 2;
                          dd.w8 := 0;
                          dd.size := 4;
                          x^.opnd[1] := buildtreenode(extend_top, dd, ops, 1);
                          opt_str_$add_substitution_point(ops[1], x^.opnd[1]);
                        end;
                    end;
                    if x^.rlen = rlen_long then begin
                      w := x^.opnd[2];
                      if w^.kind = fortran_symbol then
                        if ((ord(w^.xc[10]) & 15) = 2) or
                           ((ord(w^.xc[10]) & 15) = 1) then begin
                          ops[1] := w;
                          dd.rlen := rlen_long;
                          if (ord(w^.xc[10]) & 15) = 1 then
                            dd.w6 := 1
                          else
                            dd.w6 := 2;
                          dd.w8 := 0;
                          dd.size := 4;
                          x^.opnd[2] := buildtreenode(extend_top, dd, ops, 1);
                          opt_str_$add_substitution_point(ops[1], x^.opnd[2]);
                        end;
                    end;
                  end;
                end
                else begin
                  if k = 1 then
                    if t^.op in [add_top, mul_top, and_top, or_top, set_and_top, set_or_top, f_add_top, f_mul_top, eor_top..min_top] then
                      if t^.opnd[1]^.kind = tree_node then begin
                        z := g_opt_tree_ptr_t(t^.opnd[1]);
                        if (z^.op = mul_top) or (z^.op = f_mul_top) or (z^.op = lshf_top) then
                          if t^.opnd[2]^.kind in [blogical_ob..complex_ob,
                                                  char_string_ob,
                                                  char32_string_ob, char16_ob,
                                                  var_name, fortran_symbol,
                                                  disp_node, set_con_ob,
                                                  rec_const_ob, dpcomplex_ob,
                                                  binteger_ob] then begin
                            t^.opnd[1] := t^.opnd[2];
                            t^.opnd[2] := il_$node_ptr_t(x);
                            if t^.op = mul_top then begin
                              sw := t^.w26;
                              t^.w26 := t^.w28;
                              t^.w28 := sw;
                            end;
                            goto 50;
                          end;
                      end;
                  if t^.opnd[1]^.kind in [blogical_ob..complex_ob,
                                          char_string_ob, char32_string_ob,
                                          char16_ob, var_name, fortran_symbol,
                                          disp_node, set_con_ob, rec_const_ob,
                                          dpcomplex_ob, binteger_ob] then
                    if t^.opnd[2]^.kind = tree_node then begin
                      z := g_opt_tree_ptr_t(t^.opnd[2]);
                      if (z^.op = mul_top) or (z^.op = f_mul_top) or (z^.op = lshf_top) then
                        goto 50;
                    end;
                  iv := x^.opnd[1];
                  if (iv^.kind = var_name) or (iv^.kind = disp_node)
                      or (iv^.kind = fortran_symbol) then
                    if x^.opnd[2]^.kind in [blogical_ob..complex_ob,
                                            char_string_ob, char32_string_ob,
                                            char16_ob, set_con_ob,
                                            rec_const_ob, dpcomplex_ob,
                                            binteger_ob] then begin
                      if iv^.kind = disp_node then
                        iv := iv^.xp[6];
                      if (iv^.kind = fortran_symbol)
                          or (iv^.kind = var_name) then begin
                        if iv^.kind = fortran_symbol then begin
                          if not (var_$induction in iv^.fs_attr) then
                            goto 60;
                          if iv^.xw[8] = 0 then
                            goto 60;
                        end;
                        if iv^.kind = var_name then begin
                          if not (var_$induction in iv^.vr_attr) then
                            goto 60;
                          if iv^.xw[37] = 0 then
                            goto 60;
                        end;
                        if x^.op = lshf_top then
                          if not ((x^.w28 = 4) or (x^.w28 = 2)) then
                            goto 60;
                        if iv^.kind = fortran_symbol then begin
                          n := iv^.xw[8];
                          temp := create_sr_temp_var(nil, h);
                          if x^.rlen = rlen_long then
                            temp^.xc[10] := chr(ord(temp^.xc[10]) & 16#F0 ! 3);
                          sr_temp_ptr_t(temp^.xp2[11])^.tree := x;
                        end
                        else if iv^.kind = var_name then begin
                          n := iv^.xw[37];
                          if x^.opnd[1]^.kind = var_name then
                            temp := create_sr_temp_var(x^.opnd[1]^.xp[7], h)
                          else if x^.opnd[1]^.kind = disp_node then
                            if x^.opnd[1]^.xp[6]^.kind = var_name then
                              temp := create_sr_temp_var(x^.opnd[1]^.xp[6]^.xp[7], h);
                          sr_temp_ptr_t(temp^.xp[13])^.tree := x;
                          if x^.opnd[1]^.kind = disp_node then begin
                            w := x^.opnd[1]^.xp[6]^.xp[7];
                            if (w <> il_$node_ptr_t(runbackend_10)) and
                               (w <> il_$node_ptr_t(runbackend_0c)) and (n > 0) then
                              if opt_var_types^[n].size = 2 then
                                temp^.xp[7] := il_$node_ptr_t(runbackend_10)
                              else if opt_var_types^[n].size = 4 then
                                temp^.xp[7] := il_$node_ptr_t(runbackend_0c);
                          end;
                          if x^.opnd[1]^.kind = var_name then begin
                            w := x^.opnd[1]^.xp[7];
                            if (w <> il_$node_ptr_t(runbackend_10)) and
                               (w <> il_$node_ptr_t(runbackend_0c)) and (n > 0) then
                              if opt_var_types^[n].size = 2 then
                                temp^.xp[7] := il_$node_ptr_t(runbackend_10)
                              else if opt_var_types^[n].size = 4 then
                                temp^.xp[7] := il_$node_ptr_t(runbackend_0c);
                          end;
                          minimally_size_sr_temp(x^.rlen, temp);
                        end;
                        rg := x^.owner^.hdr.region;
                        findvalues(rg, n, hb, temp,
                          opt_str_$product_of(x^.op, smcontk(integer_ob, 1),
                                              x^.opnd[2],
                            x^.rlen, class_size[x^.rlen],
                            opt_str_$opmod1_of_multiplier(x), x^.dflags.signed,
                            nil),
                          sr_tree_view_ptr_t(x)^.desc, iv);
                        il_utils_$do_substitution(il_$node_ptr_t(t), t^.opnd[k], temp);
                      end;
                    end;
                end;
              end;
  60:
          end;
          goto 90;
        end;
  50:
        x := g_opt_tree_ptr_t(t^.opnd[2]);
        if x^.kind <> tree_node then
          goto 90;
        if not ((x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top)) then
          goto 90;
        if not (x^.opnd[1]^.kind in [var_name, fortran_symbol, disp_node,
                                     tree_node]) then
          goto 90;
        if not (x^.opnd[2]^.kind in [blogical_ob..char_ob, char16_ob,
                                     binteger_ob]) then
          goto 90;
        iv := x^.opnd[1];
        if iv^.kind = disp_node then
          iv := iv^.xp[6];
        if iv^.kind = tree_node then
          if g_opt_tree_ptr_t(iv)^.op = extend_top then begin
            if g_opt_tree_ptr_t(iv)^.w26 = 1 then
              goto 90;
            if g_opt_tree_ptr_t(iv)^.uses > 1 then
              goto 90;
            w := g_opt_tree_ptr_t(iv)^.opnd[1];
            if (w^.kind = fortran_symbol)
                and (var_$induction in w^.fs_attr) then
              iv := w
            else if (w^.kind = var_name) and
                    (var_$induction in w^.vr_attr) then
              iv := w;
          end;
        if not ((iv^.kind = fortran_symbol) or (iv^.kind = var_name)) then
          goto 90;
        if x^.kind = tree_node then
          if x^.op = lshf_top then
            if not ((x^.w28 = 4) or (x^.w28 = 2)) then
              goto 90;
        if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then begin
          n := iv^.xw[37];
          if n = 0 then
            goto 90;
          if not (var_$induction in iv^.vr_attr) then
            goto 90;
          temp := create_sr_temp_var(iv^.xp[7], h);
          sr_temp_ptr_t(temp^.xp[13])^.tree := x;
          if (iv^.xp[7] <> il_$node_ptr_t(runbackend_10)) and
             (iv^.xp[7] <> il_$node_ptr_t(runbackend_0c)) and (n > 0) then
            if opt_var_types^[n].size = 2 then
              temp^.xp[7] := il_$node_ptr_t(runbackend_10)
            else if opt_var_types^[n].size = 4 then
              temp^.xp[7] := il_$node_ptr_t(runbackend_0c);
          minimally_size_sr_temp(x^.rlen, temp);
        end
        else begin
          if iv^.kind <> fortran_symbol then
            goto 90;
          n := iv^.xw[8];
          if n = 0 then
            goto 90;
          if not (var_$induction in iv^.fs_attr) then
            goto 90;
          temp := create_sr_temp_var(nil, h);
          if x^.rlen = rlen_long then
            temp^.xc[10] := chr(ord(temp^.xc[10]) & 16#F0 ! 3);
          sr_temp_ptr_t(temp^.xp2[11])^.tree := x;
        end;
        rg := x^.owner^.hdr.region;
        findvalues(rg, n, hb, temp,
          opt_str_$product_of(x^.op, smcontk(integer_ob, 1), x^.opnd[2],
                              x^.rlen,
            class_size[x^.rlen], opt_str_$opmod1_of_multiplier(x),
            x^.dflags.signed, nil),
          sr_tree_view_ptr_t(x)^.desc, iv);
        il_utils_$do_substitution(il_$node_ptr_t(t), t^.opnd[2], temp);
      end;
      dindex_node: begin
        iv := nil;
        if phase_cse in t^.flags then
          goto 90;
        x := g_opt_tree_ptr_t(il_$node_ptr_t(t)^.xp[9]);
        if x^.kind <> tree_node then
          goto 90;
        if not ((x^.op = mul_top) or (x^.op = f_mul_top) or (x^.op = lshf_top)) then
          goto 90;
        if (x^.kind = tree_node) and (x^.count >= 2) then begin
          y := g_opt_tree_ptr_t(x^.opnd[1]);
          if (y^.kind = tree_node) and (y^.op = extend_top) and (y^.w26 = 1) then
            goto 90;
          if (y^.kind = tree_node) and (y^.op = extend_top)
              and (y^.opnd[1]^.kind = var_name) and
             (var_$induction in y^.opnd[1]^.vr_attr) then
            iv := y^.opnd[1]
          else if (y^.kind = tree_node) and (y^.op = extend_top) and
                  (y^.opnd[1]^.kind = fortran_symbol) and
                  (var_$induction in y^.opnd[1]^.fs_attr) then
            iv := y^.opnd[1]
          else begin
            if not (y^.kind in [blogical_ob..complex_ob, char_string_ob,
                                char32_string_ob, char16_ob, var_name,
                                fortran_symbol, disp_node, set_con_ob,
                                rec_const_ob, dpcomplex_ob, binteger_ob]) then
              if not (x^.opnd[2]^.kind in [blogical_ob..complex_ob,
                                           char_string_ob, char32_string_ob,
                                           char16_ob, var_name, fortran_symbol,
                                           disp_node, set_con_ob, rec_const_ob,
                                           dpcomplex_ob, binteger_ob]) then
                goto 90;
            if (y^.kind = var_name) or (y^.kind = disp_node)
                or (y^.kind = fortran_symbol) then
              iv := il_$node_ptr_t(y)
            else if (x^.opnd[2]^.kind = var_name)
                or (x^.opnd[2]^.kind = disp_node) or
                    (x^.opnd[2]^.kind = fortran_symbol) then
              iv := il_$node_ptr_t(y);
          end;
        end;
        if iv = nil then
          goto 90;
        if iv^.kind = disp_node then
          iv := iv^.xp[6];
        if x^.kind = tree_node then
          if x^.op = lshf_top then
            if not ((x^.w28 = 4) or (x^.w28 = 2)) then
              goto 90;
        if x^.opnd[1]^.kind = tree_node then
          if g_opt_tree_ptr_t(x^.opnd[1])^.uses > 1 then
            goto 90;
        if not ((iv^.kind = fortran_symbol) or (iv^.kind = var_name)) then
          goto 90;
        if iv^.kind = var_name then begin
          if iv^.xw[37] <= 0 then
            goto 90;
          if not (var_$induction in iv^.vr_attr) then
            goto 90;
          temp := create_sr_temp_var(iv^.xp[7], h);
          sr_temp_ptr_t(temp^.xp[13])^.tree := x;
          n := iv^.xw[37];
          if (iv^.xp[7] <> il_$node_ptr_t(runbackend_10)) and
             (iv^.xp[7] <> il_$node_ptr_t(runbackend_0c)) and (n > 0) then
            if opt_var_types^[n].size = 2 then
              temp^.xp[7] := il_$node_ptr_t(runbackend_10)
            else if opt_var_types^[n].size = 4 then
              temp^.xp[7] := il_$node_ptr_t(runbackend_0c);
          minimally_size_sr_temp(x^.rlen, temp);
        end
        else begin
          n := iv^.xw[8];
          if n <= 0 then
            goto 90;
          if not (var_$induction in iv^.fs_attr) then
            goto 90;
          temp := create_sr_temp_var(nil, h);
          if x^.rlen = rlen_long then
            temp^.xc[10] := chr(ord(temp^.xc[10]) & 16#F0 ! 3);
          sr_temp_ptr_t(temp^.xp2[11])^.tree := x;
        end;
        rg := x^.owner^.hdr.region;
        findvalues(rg, n, hb, temp,
          opt_str_$product_of(x^.op, smcontk(integer_ob, 1), x^.opnd[2],
                              x^.rlen,
            class_size[x^.rlen], opt_str_$opmod1_of_multiplier(x),
            x^.dflags.signed, nil),
          sr_tree_view_ptr_t(x)^.desc, iv);
        il_utils_$do_substitution(il_$node_ptr_t(t), il_$node_ptr_t(t)^.xp[9],
                                  temp);
      end;
      otherwise
    end;
  90:
    e := e^.next;
  end;
end;

{ strengthreduce - see g_opt.ins.pas: the variables excluded (or-ed
  into excluded, never cleared); in each loop (the blocks in
  depth-first order; a header with a latch preheader that dominates it
  and at most one forward predecessor) with induction variables, the
  candidate expressions found, disqualified and tested at the exits,
  then reduced and the induction variables' uses eliminated; the marks
  and the candidates' cells dropped.  The statements added before a
  block's first get its block (a first statement that no longer starts
  one gives it up), then fixup_blocks, autoinc, markuses and
  combine_temps.  -TREE 21, 22, 23 print the IL and stop at their
  points, -TREE 30 after combine_temps.

  0x0EBAF0, 0x35C bytes: a variable as a one-element frame set (-216);
  the candidates' cells disposed through a frame copy (-24). }

procedure strengthreduce;
var
  one: g_opt_varset_t;
  i, v: integer;
  bn: g_opt_num_t;
  b, ph, blk: g_opt_block_ptr_t;
  n: il_$node_ptr_t;
  p, q: sr_list_ptr_t;
  s, s2: g_opt_stmt_ptr_t;
begin
  if cargs_$options.tree = 21 then begin
    list_tree_$print_whole_il;
    return;
  end;
  ntemps := 0;
  for v := 1 to il_180^.xw[145] do begin
    n := opt_4009c[opt_region]^.vars^[v]^.node;
    if n <> nil then
      if n^.kind = var_name then begin
        if (n^.xw[36] = 5) or (n^.xw[37] = 0) or
           (n^.vr_attr * [var_$volatile, var_$uplevel, var_$address_exposed,
                          var_$nooptimize] <> []) then begin
          one := [v];
          excluded := excluded + one;
        end;
      end
      else if n^.kind = fortran_symbol then
        if (n^.xw[8] = 0) or (n^.fs_attr * [var_$volatile, var_$uplevel,
                                            var_$address_exposed,
                                            var_$nooptimize] <> []) then begin
          one := [v];
          excluded := excluded + one;
        end;
  end;
  for i := opt_first_block to opt_last_block do begin
    bn := opt_dfs_block^[i];
    b := g_opt_blocks_ptr_t(il_11c)^[bn];
    if b^.flags.header and (b^.preheader <> nil) then begin
      ph := b^.preheader;
      if ph^.num <> bn then
        if ph^.flags.latch then
          if dom(ph, b) then begin
            ivs := nil;
            preheader_num := b^.preheader^.num;
            header_num := bn;
            if b^.nfwd <= 1 then begin
              cur_loop := select_loop(bn);
              if recognize_induction_variables(cur_loop) then begin
                if cargs_$options.sri then
                  dump_induction_variables(cur_loop);
                exprs := nil;
                cand_exprs(cur_loop);
                if exprs <> nil then begin
                  disqualify;
                  if exprs <> nil then begin
                    testexits(cur_loop);
                    if exprs <> nil then begin
                      reduce(bn);
                      p := ivs;
                      while p <> nil do begin
                        elimuses(cur_loop, p^.node);
                        p := p^.next;
                      end;
                    end;
                  end;
                end;
                p := ivs;
                while p <> nil do begin
                  q := p^.next;
                  removeflag(p^.node);
                  p := q;
                end;
                p := exprs;
                while p <> nil do begin
                  q := p^.next;
                  dispose(p);
                  p := q;
                end;
              end;
            end;
          end;
    end;
  end;
  s := g_opt_stmt_ptr_t(il_d4);
  blk := nil;
  while s <> nil do begin
    if s^.hdr.first then
      if s^.block <> nil then
        blk := s^.block;
    if s^.kind = assign_node then
      if s^.block = nil then
        if not s^.hdr.first then
          if new_block(s) then begin
            s^.hdr.first := true;
            s2 := s^.next;
            while s2^.block = nil do
              s2 := s2^.next;
            if s2^.hdr.first then
              if not new_block(s2) then begin
                s^.block := s2^.block;
                s2^.hdr.first := false;
                blk := s^.block;
                blk^.first_stmt := s;
              end;
          end;
    if blk <> nil then
      s^.block := blk;
    s := s^.next;
  end;
  fixup_blocks;
  if cargs_$options.tree = 22 then begin
    list_tree_$print_whole_il;
    return;
  end;
  autoinc;
  markuses;
  if cargs_$options.tree = 23 then begin
    list_tree_$print_whole_il;
    return;
  end;
  combine_temps;
  if cargs_$options.tree = 30 then
    list_tree_$print_whole_il;
end;
%endif

%if cc_a88k %then
{ strengthreduce - see g_opt.ins.pas; cc.a88k's does nothing.

  cc.a88k 0x2B3ED4, 2 bytes: a lone `rts' (docs/rev889-patterns.md 13). }

procedure strengthreduce;
begin
end;
%endif
