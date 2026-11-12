{ opt_main - HEADER TODO }
module opt_main;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/cg.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/pfm.ins.pas';
%include 'lang/lang/source/list_tree.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { Raw memory (zero_longwords, zero_bytes). }
  om_longs_ptr_t = ^integer32;
  om_bytes_ptr_t = ^char;
  { A longword's bits (convert_exponentiation's exponent). }
  om_bits_t = set of 0..31;
  { A routine's parameter list (its +12; var_is_param_of_routine): the
    count at +10, 12-byte entries from +12, the variable first. }
  om_parm_t = record
    v: il_$node_ptr_t;                  { +0 }
    unused_4: array [1..4] of integer;  { +4 }
  end;
  om_params_ptr_t = ^om_params_t;
  om_params_t = record
    unused_0: array [0..4] of integer;  { +0 }
    count: integer;                     { +10 }
    parm: array [1..1000] of om_parm_t; { +12 }
  end;
  { A routine block's +384 (init_opt_info_for_vars): a chain (+8) of
    nodes whose +4 is a variable that gets flags 4 in its entry. }
  om_blk_ptr_t = ^om_blk_t;
  om_blk_t = record
    unused_0: array [0..95] of integer32;  { +0..+383 }
    vlist: il_$node_ptr_t;              { +384 }
  end;
  { The argument classes (paramclass) a later argument passing the
    same variable may not have (om_param_conflicts). }
  om_classes_t = set of 0..15;

var
  { The module's data (A5 0x2D2EF0 in cc.m68k, 0x49389C in cc.a88k),
    the cells g_opt.ins.pas does not declare, defined below in the
    image's order. }
  om_succ_pool: extern mem_$pool_t;     { +0x0: blk_succ }
  om_blocks_pool: extern mem_$pool_t;   { +0x4: bindxp }
  om_hoist_pool: extern mem_$pool_t;    { +0xC: hoist }
  om_nodes_pool: extern mem_$pool_t;    { +0x10: nindxp }
  om_varset_pool: extern mem_$pool_t;   { +0x1C: variable_use_set }
  om_complex_size: extern array [6..7] of integer;  { +0x28 }
  om_class_bytes: extern array [0..9] of integer;   { +0x70 }
  om_stmt_num: extern integer;          { +0x58 }
  om_nvars: extern integer;             { +0x64 }
  om_param_conflicts: extern array [0..4] of om_classes_t;  { +0x90 }

var
  { delay.pas's +888 (cc.m68k 0x169968, cc.a88k 0x2E99D8): the bytes of
    each register class (delay.pas's class_size; opt_strength.pas
    declares it the same way). }
  class_size: extern array [0..12] of integer;

{ REG_SAVE_$REGISTERS_PRESERVED_BY_STATEMENT - reg_save.pas 0x0ED458
  (cc.a88k target_at_dummies): the registers top-level statement s
  preserves (no insert has the heading). }
function reg_save_$registers_preserved_by_statement(
    s: il_$node_ptr_t): reg_save_$regs_t; options(val_param); extern;

{ OPT_MAIN_$IS_FORTRAN_ASF - (defined below, after its caller
  add_def_for_params_at_routine_entry) whether s is the entry of a
  Fortran statement function. }
function opt_main_$is_fortran_asf(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); extern;

define
  om_succ_pool, om_blocks_pool, om_hoist_pool, om_nodes_pool,
  om_varset_pool;
  om_complex_size := [8, 12];
  om_class_bytes := [0, 2, 4, 4, 8, 8, 1, 4, 4, 0];
  om_stmt_num, om_nvars;
  om_param_conflicts := [[0, 2], [1, 4], [0, 2], [3], [1, 4]];
  opt_main_$ensure_var_set, check_dominators, reviseuses,
  opt_main_$symidx_of_varn_or_fsym, opt_main_$var_is_param_of_routine,
  opt_main_$is_fortran_asf, fixup_blocks;

{ assert_optimizer_is_enabled - the optimizer runs: target_properties'
  +0x7F, else not -DBA (cargs db 3) and -OPT's level above 2.

  0x0DAC88, 0x38 bytes, no frame: `tst.b 0x2CE5A7; bmi' to `st';
  `andi.l #0x18000' of cargs +0x282, `lsr.l #8; lsr.l #7; cmpi.w #3'
  (db); `andi.b #0x3C' of +0x27F, `lsr.w #2; cmpi.w #2; shi' (opt).
  cg_addr.pas has a routine of the same name without the first test. }

function assert_optimizer_is_enabled: boolean; internal;
begin
  if target_properties.p_7f then
    assert_optimizer_is_enabled := true
  else if cargs_$options.db = 3 then
    assert_optimizer_is_enabled := false
  else
    assert_optimizer_is_enabled := cargs_$options.opt > 2;
end;

{ assert_common_subexpression_phase_is_enabled - opt_on 9 or 15.

  0x0DACC0, 0x18 bytes, no frame: `andi.l #0x7FFFFFFE' of cargs +0x280,
  `lsr.l #1; andi.l #0x8200; sne'. }

function assert_common_subexpression_phase_is_enabled: boolean; internal;
begin
  assert_common_subexpression_phase_is_enabled :=
    cargs_$options.opt_on * [9, 15] <> [];
end;

{ assert_language_on_il_spine_is_ada - the first top-level node is a
  label (144) followed by a routine's entry (148) whose routine's
  language (+377 bits 6..4) is 5.

  0x0DACD8, 0x46 bytes: `btst d0, #32' (a one-element set). }

function assert_language_on_il_spine_is_ada: boolean; internal;
var
  e: il_$node_ptr_t;
  k: integer;
begin
  assert_language_on_il_spine_is_ada := false;
  if il_d4 <> nil then
    if il_d4^.kind = 144 then begin
      e := il_d4^.xp[2];
      if e^.kind = 148 then begin
        k := rshft(ord(g_opt_stmt_ptr_t(e)^.x48^.xc[377]) & 16#70, 4);
        assert_language_on_il_spine_is_ada := k in [5];
      end;
    end;
end;

{ limit_of_cse_backwards_reach - how far cse looks back: 200 under
  opt_on 9, 500 under 15, else 0.

  0x0DAD1E, 0x24 bytes, no frame: `btst #2' of cargs +0x282 (element
  9), `btst #0' of +0x281 (element 15); the result a word. }

function limit_of_cse_backwards_reach: integer; internal;
begin
  if 9 in cargs_$options.opt_on then
    limit_of_cse_backwards_reach := 200
  else if 15 in cargs_$options.opt_on then
    limit_of_cse_backwards_reach := 500
  else
    limit_of_cse_backwards_reach := 0;
end;

{ estimate_register_consumption_of_all_statements - unless
  target_properties' +0x7F, each top-level statement's free registers
  (+30) and the routine block's (+216) narrowed to those the statement
  preserves (reg_save_$registers_preserved_by_statement).

  0x0DAD42, 0x4C bytes: il_180's address kept in A3 (`movea.l
  #0x169DF0'), the routine block reloaded for each statement. }

procedure estimate_register_consumption_of_all_statements; internal;
var
  s: g_opt_stmt_ptr_t;
  r: reg_save_$regs_t;
begin
  if not target_properties.p_7f then begin
    s := g_opt_stmt_ptr_t(il_d4);
    while s <> nil do begin
      r := reg_save_$registers_preserved_by_statement(il_$node_ptr_t(s));
      s^.regs := s^.regs * r;
      il_180^.xl[54] := il_180^.xl[54] & integer32(r);
      s := s^.next;
    end;
  end;
end;

{ zero_longwords - n longwords from p cleared (opt_reachdef has the
  same routine).

  0x0DAD8E, 0x14 bytes, no frame: `clr.l (A0)+' while n > 0. }

procedure zero_longwords(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
var
  q: om_longs_ptr_t;
begin
  q := p;
  while n > 0 do begin
    q^ := 0;
    q := om_longs_ptr_t(integer32(q) + 4);
    n := n - 1;
  end;
end;

{ zero_bytes - n bytes from p cleared: the longwords, then the rest.

  0x0DADA2, 0x56 bytes: n div 4 and n mod 4 signed (M$OIS$WLW). }

procedure zero_bytes(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
var
  q: om_bytes_ptr_t;
  k: integer32;
begin
  zero_longwords(p, n div 4);
  q := om_bytes_ptr_t(integer32(p) + (n & (-4)));
  k := n mod 4;
  while k > 0 do begin
    q^ := chr(0);
    q := om_bytes_ptr_t(integer32(q) + 1);
    k := k - 1;
  end;
end;

{ alloc_block_list - il_11c: room for il_124 + 1 block pointers from
  the bindxp pool.

  0x0DADF8, 0x26 bytes: il_124 zero-extended. }

procedure alloc_block_list; internal;
begin
  il_11c := mem_$alloc(om_blocks_pool, (il_124 & 16#FFFF) * 4 + 4);
end;

{ alloc_hoist - opt_loop's hoist table, n bytes from the hoist pool.

  0x0DAE1E, 0x1C bytes. }

procedure alloc_hoist(
    n: integer32); options(val_param); internal;
begin
  opt_loop_hoist := mem_$alloc(om_hoist_pool, n);
end;

{ dispose_hoist - the hoist pool emptied when the table was allocated.

  0x0DAE3A, 0x1A bytes. }

procedure dispose_hoist; internal;
begin
  if opt_loop_hoist <> nil then
    mem_$empty_pool(om_hoist_pool);
end;

{ alloc_postorder_node_list - il_120: room for il_126 + 1 node pointers
  from the nindxp pool.

  0x0DAE54, 0x26 bytes. }

procedure alloc_postorder_node_list; internal;
begin
  il_120 := mem_$alloc(om_nodes_pool, (il_126 & 16#FFFF) * 4 + 4);
end;

{ dispose_postorder_node_list - the nindxp pool emptied.

  0x0DAE7A, 0x12 bytes. }

procedure dispose_postorder_node_list; internal;
begin
  mem_$empty_pool(om_nodes_pool);
end;

{ assert_is_defined_spos - p is not spos's null position (the word at
  0x14E770).

  0x0DAE8C, 0x10 bytes, no frame: p a word at (4,SP). }

function assert_is_defined_spos(
    p: integer): boolean; options(val_param); internal;
begin
  assert_is_defined_spos := p <> spos_$null_position;
end;

{ assert_is_top_level_statement - n is a top-level statement (its kind
  in the set of 0..239 after the routine, as reg_save's).

  0x0DAE9C, 0x26 bytes, no frame: `move.w #239; sub.w; lsr.w #3; btst'
  without a range check (docs/dpc-gaps.md 8). }

function assert_is_top_level_statement(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_top_level_statement := false
  else
    assert_is_top_level_statement :=
      n^.kind in [139..142, 144, 148..151, 188, 191, 214..215, 223..225,
                  227..228, 231, 233];
end;

{ assert_is_conditional_branch - n is a conditional branch (142).

  0x0DAEE0, 0x18 bytes, no frame. }

function assert_is_conditional_branch(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_conditional_branch := false
  else
    assert_is_conditional_branch := n^.kind = 142;
end;

{ assert_is_unconditional_branch - n is a branch (141) or a non-local
  one (150).

  0x0DAEF8, 0x22 bytes, no frame: `seq; seq; or.b'. }

function assert_is_unconditional_branch(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_unconditional_branch := false
  else
    assert_is_unconditional_branch := (n^.kind = 150) or (n^.kind = 141);
end;

{ assert_is_branch - n is a branch of either kind.

  0x0DAF1A, 0x1E bytes: the second call only when the first is false. }

function assert_is_branch(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_unconditional_branch(n) then
    assert_is_branch := true
  else
    assert_is_branch := assert_is_conditional_branch(n);
end;

{ assert_is_label - n is a label (144).

  0x0DAF38, 0x18 bytes, no frame. }

function assert_is_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_label := false
  else
    assert_is_label := n^.kind = 144;
end;

{ assert_is_childless_eval - n is an evaluation (139) of no operands.

  0x0DAF50, 0x18 bytes, no frame: n not tested for nil. }

function assert_is_childless_eval(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n^.kind = 139 then
    assert_is_childless_eval := g_opt_stmt_ptr_t(n)^.eval_count = 0
  else
    assert_is_childless_eval := false;
end;

{ assert_is_artificial_label - n is a label the compiler made: its kind
  (+72 bits 5..1) one of 1..10 or 16.

  0x0DAF68, 0x32 bytes: `btst' in the longword 0x107FE. }

function assert_is_artificial_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_label(n) then
    assert_is_artificial_label :=
      rshft(ord(n^.xc[72]) & 16#3E, 1) in [1..10, 16]
  else
    assert_is_artificial_label := false;
end;

{ assert_is_unconditional_branch_to_artificial_label - n is a branch
  (141) to a label of kind 1..10, 12 or 16.

  0x0DAF9A, 0x40 bytes: `btst' in the longword 0x117FE. }

function assert_is_unconditional_branch_to_artificial_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  l: il_$node_ptr_t;
begin
  assert_is_unconditional_branch_to_artificial_label := false;
  if n^.kind = 141 then begin
    l := g_opt_stmt_ptr_t(n)^.br_target;
    if assert_is_label(l) then
      assert_is_unconditional_branch_to_artificial_label :=
        rshft(ord(l^.xc[72]) & 16#3E, 1) in [1..10, 12, 16];
  end;
end;

{ assert_is_conditional_branch_to_artificial_label - n is a conditional
  branch (142) to a label of kind 2..10, 12 or 16.

  0x0DAFDA, 0x42 bytes: `btst' in the longword 0x117FC. }

function assert_is_conditional_branch_to_artificial_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  l: il_$node_ptr_t;
begin
  assert_is_conditional_branch_to_artificial_label := false;
  if n^.kind = 142 then begin
    l := g_opt_stmt_ptr_t(n)^.br_target;
    if assert_is_label(l) then
      assert_is_conditional_branch_to_artificial_label :=
        rshft(ord(l^.xc[72]) & 16#3E, 1) in [2..10, 12, 16];
  end;
end;

{ assert_is_branch_to_artificial_label - either kind of branch to such
  a label.

  0x0DB01C, 0x20 bytes. }

function assert_is_branch_to_artificial_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_unconditional_branch_to_artificial_label(n) then
    assert_is_branch_to_artificial_label := true
  else
    assert_is_branch_to_artificial_label :=
      assert_is_conditional_branch_to_artificial_label(n);
end;

{ assert_is_artificial_statement - n is a top-level statement the
  compiler made: an empty evaluation, an artificial label or a branch
  to one.

  0x0DB03C, 0x40 bytes. }

function assert_is_artificial_statement(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if not assert_is_top_level_statement(n) then
    assert_is_artificial_statement := false
  else if assert_is_childless_eval(n) then
    assert_is_artificial_statement := true
  else if assert_is_artificial_label(n) then
    assert_is_artificial_statement := true
  else
    assert_is_artificial_statement := assert_is_branch_to_artificial_label(n);
end;

{ realloc_postorder_node_list - il_120 grown by a twentieth (an error 17
  past 65000 entries) with a warning on standard output, the entries
  copied.

  0x0DB07C, 0xA2 bytes: `jsr fpp_$' with 0x00C4 (the size, a longword),
  0x00A0 and the double 1.05 (multiply), 0x00D0 (to a longword in D0:
  trunc); PAS_$WRITE and PAS_$WRITELN on the file at (-4,A5)
  (docs/dpc-gaps.md 4, 7); the old entries copied with a `dbf' loop
  from the table kept in A2. }

procedure realloc_postorder_node_list; internal;
var
  old: g_opt_num_t;
  n: integer32;
  p: g_opt_nodes_ptr_t;
  k: integer;
begin
  old := il_126;
  p := il_120;
  n := trunc(old * 1.05);
  if n >= 65000 then
    cgerr_no_source(17, 0);
  writeln('Internal warning: OPT_MAIN_\REALLOC_POSTORDER_NODE_LIST -- postordered node list size was calculated wrongly, growing to compensate...');
  il_126 := n;
  alloc_postorder_node_list;
  for k := 1 to old do
    g_opt_nodes_ptr_t(il_120)^[k] := p^[k];
end;

{ new_postorder_node_list_entry - n put at the next entry k of il_120
  (k by address), the table grown when full.

  0x0DB1A4, 0x3C bytes: `cmp.w il_126; bcs' (unsigned). }

procedure new_postorder_node_list_entry(
    var k: g_opt_num_t;
    n: il_$node_ptr_t); options(val_param); internal;
begin
  if k >= il_126 then
    realloc_postorder_node_list;
  k := k + 1;
  g_opt_nodes_ptr_t(il_120)^[k] := n;
end;

{ assert_statement_is_interesting_in_postorder_node_list - n is not a
  188, 150, 144 or 141.

  0x0DB1E0, 0x38 bytes, no frame: the four `seq' or-ed, `not.b'. }

function assert_statement_is_interesting_in_postorder_node_list(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_statement_is_interesting_in_postorder_node_list := false
  else
    assert_statement_is_interesting_in_postorder_node_list :=
      not ((n^.kind = 188) or (n^.kind = 150) or (n^.kind = 144) or
           (n^.kind = 141));
end;

{ assert_is_a_variable - n is a variable (110, 109).

  0x0DB218, 0x22 bytes, no frame (opt_general has the same routine). }

function assert_is_a_variable(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_a_variable := false
  else
    assert_is_a_variable := (n^.kind = 110) or (n^.kind = 109);
end;

{ assert_is_var_name - n is a variable's name (109).

  0x0DB23A, 0x18 bytes, no frame. }

function assert_is_var_name(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_var_name := false
  else
    assert_is_var_name := n^.kind = 109;
end;

{ assert_is_fortran_symbol - n is a Fortran symbol (110).

  0x0DB252, 0x18 bytes, no frame. }

function assert_is_fortran_symbol(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_fortran_symbol := false
  else
    assert_is_fortran_symbol := n^.kind = 110;
end;

{ assert_is_fortran_temp - n is a Fortran symbol marked a temporary
  (+26 bit 14).

  0x0DB26A, 0x2A bytes: the word loaded, `btst #14'. }

function assert_is_fortran_temp(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_fortran_symbol(n) then
    assert_is_fortran_temp := (n^.xw[13] & 16#4000) <> 0
  else
    assert_is_fortran_temp := false;
end;

{ assert_is_call_tree - n is a tree (143, 137) of operator 16 or 15 (a
  call).

  0x0DB294, 0x32 bytes, no frame. }

function assert_is_call_tree(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_call_tree := false
  else if (n^.kind = 143) or (n^.kind = 137) then
    assert_is_call_tree := (g_opt_tree_ptr_t(n)^.op = 16) or
                           (g_opt_tree_ptr_t(n)^.op = 15)
  else
    assert_is_call_tree := false;
end;

{ opt_main_$ensure_var_set - see g_opt.ins.pas: 32 bytes from the
  variable_use_set pool when s is nil.

  0x0DB2C6, 0x32 bytes: A5 loaded; s by address. }

procedure opt_main_$ensure_var_set(
    var s: g_opt_varset_ptr_t);
begin
  if s = nil then
    s := mem_$alloc(om_varset_pool, 32);
end;

{ opt_main_$complex_decomposition - Fortran's store of a complex value
  (s, an assignment of op 6 of size bytes, half each part) made of the
  four assignments before it: a and b store the parts (op 11, a complex
  part's register class 6 or 7 whose size om_complex_size gives) into
  the temporary s copies (a to its second half, a displacement node
  147 of half bytes), c and d compute them into Fortran temporaries
  a and b read, and neither c's nor d's value reads s's destination.

  0x0DB2F8, 0x1AC bytes: the parameters in registers; each test `bne'
  to the end; il_utils_$search_tree_for_node with same_only false (the
  result's register, D2, pushed). }

function opt_main_$complex_decomposition(
    s: g_opt_stmt_ptr_t;
    size: integer;
    half: integer32;
    a: g_opt_stmt_ptr_t;
    b: g_opt_stmt_ptr_t;
    c: g_opt_stmt_ptr_t;
    d: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  ok: boolean;
  l: il_$node_ptr_t;
begin
  ok := false;
  if (a^.kind = 140) and (a^.asg_op = 11) and
     ((a^.asg_rlen = 7) or (a^.asg_rlen = 6)) and
     (om_complex_size[a^.asg_rlen] = size) then begin
    l := a^.asg_lhs;
    if (l^.kind = 147) and (l^.xl[8] = half) and (l^.xp[6] = s^.asg_rhs) then
      if (b^.kind = 140) and (b^.asg_op = 11) and
         ((b^.asg_rlen = 7) or (b^.asg_rlen = 6)) and
         (om_complex_size[b^.asg_rlen] = size) and
         (b^.asg_lhs = s^.asg_rhs) then
        if (c^.kind = 140) and (c^.asg_op = 11) and
           ((c^.asg_rlen = 7) or (c^.asg_rlen = 6)) and
           (om_complex_size[c^.asg_rlen] = size) and
           (c^.asg_lhs = a^.asg_rhs) then
          if assert_is_fortran_temp(c^.asg_lhs) then
            if (d^.kind = 140) and (d^.asg_op = 11) and
               ((d^.asg_rlen = 7) or (d^.asg_rlen = 6)) and
               (om_complex_size[d^.asg_rlen] = size) and
               (d^.asg_lhs = b^.asg_rhs) then
              if assert_is_fortran_temp(d^.asg_lhs) then
                if il_utils_$search_tree_for_node(c^.asg_rhs, s^.asg_lhs,
                                                  ok) = nil then
                  if il_utils_$search_tree_for_node(d^.asg_rhs, s^.asg_lhs,
                                                    ok) = nil then
                    ok := true;
  end;
  opt_main_$complex_decomposition := ok;
end;

{ opt_main_$complex_intrinsic_decomposition - the same store made of
  the two assignments a and b before it (an intrinsic's parts): a
  stores into s's temporary's second half, b into its first.

  0x0DB4A4, 0xB4 bytes. }

function opt_main_$complex_intrinsic_decomposition(
    s: g_opt_stmt_ptr_t;
    size: integer;
    half: integer32;
    a: g_opt_stmt_ptr_t;
    b: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  l: il_$node_ptr_t;
begin
  opt_main_$complex_intrinsic_decomposition := false;
  if (a^.kind = 140) and (a^.asg_op = 11) and
     ((a^.asg_rlen = 7) or (a^.asg_rlen = 6)) and
     (om_complex_size[a^.asg_rlen] = size) then begin
    l := a^.asg_lhs;
    if (l^.kind = 147) and (l^.xl[8] = half) and (l^.xp[6] = s^.asg_rhs) then
      if (b^.kind = 140) and (b^.asg_op = 11) and
         ((b^.asg_rlen = 7) or (b^.asg_rlen = 6)) and
         (om_complex_size[b^.asg_rlen] = size) and
         (b^.asg_lhs = s^.asg_rhs) then
        opt_main_$complex_intrinsic_decomposition := true;
  end;
end;

{ opt_main_$collapse_fortran_complex_assigns - s (by address), a
  block move (op 6) of a Fortran complex temporary (its data class,
  +10 low nibble, 6 a complex, 13 a double complex): when the
  statements before it decompose it (opt_main_$complex_decomposition,
  else opt_main_$complex_intrinsic_decomposition), the two part
  stores are pointed at s's destination (a copy of it, and the copy
  displaced half bytes) and s is unlinked; s becomes the first of the
  remaining statements.

  0x0DB558, 0x134 bytes: the four statements before s in A3, D3, A2,
  D2; copy_tree's argument by address (s's +64). }

procedure opt_main_$collapse_fortran_complex_assigns(
    var s: g_opt_stmt_ptr_t); internal;
var
  size: integer;
  half: integer32;
  a: g_opt_stmt_ptr_t;
  b: g_opt_stmt_ptr_t;
  c: g_opt_stmt_ptr_t;
  d: g_opt_stmt_ptr_t;
  t: il_$node_ptr_t;
  u: il_$node_ptr_t;
  k: integer;
begin
  if (s^.kind = 140) and (s^.asg_op = 6) then
    if assert_is_fortran_temp(s^.asg_rhs) then begin
      k := ord(s^.asg_rhs^.xc[10]) & 15;
      if k = 6 then begin
        size := 8;
        half := 4;
      end
      else if k = 13 then begin
        size := 12;
        half := 8;
      end
      else
        return;
      a := s^.prev;
      b := a^.prev;
      c := b^.prev;
      d := c^.prev;
      if opt_main_$complex_decomposition(s, size, half, a, b, c, d) then
        a := c
      else if opt_main_$complex_intrinsic_decomposition(s, size, half, a,
                                                        b) then
        d := b
      else
        return;
      t := copy_tree(s^.asg_lhs);
      d^.asg_lhs := t;
      adjust_uc(t, 1);
      u := copy_tree(s^.asg_lhs);
      t := add_dn(u, u, half);
      adjust_uc(t, 1);
      a^.asg_lhs := t;
      a^.next := s^.next;
      s^.next^.prev := a;
      s := d;
    end;
end;

{ assert_is_predecessor - block a (a number, 0 none) reaches block b
  over successor edges: a's visited mark is taken off as it is looked
  at, so each block is followed once.

  0x0DB68C, 0xA6 bytes: both words; recursive; the successors' loop
  left at the first that reaches b. }

function assert_is_predecessor(
    a: g_opt_num_t;
    b: g_opt_num_t): boolean; options(val_param); internal;
var
  p: g_opt_block_ptr_t;
  k: integer;
  r: boolean;
begin
  r := false;
  if a <> 0 then
    if a = b then
      r := true
    else begin
      p := g_opt_blocks_ptr_t(il_11c)^[a];
      if p^.flags.visited then begin
        p^.flags.visited := false;
        for k := 1 to g_opt_blocks_ptr_t(il_11c)^[a]^.nsucc do
          if assert_is_predecessor(
               g_opt_blocks_ptr_t(il_11c)^[a]^.succ^[k]^.num, b) then begin
            r := true;
            exit;
          end;
      end;
    end;
  assert_is_predecessor := r;
end;

{ assert_is_entry_block - n is a routine's block (167).

  0x0DB712, 0x18 bytes, no frame. }

function assert_is_entry_block(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_entry_block := false
  else
    assert_is_entry_block := n^.kind = 167;
end;

{ assert_is_entry_block_entry - n is a routine's entry (148) of such a
  block.

  0x0DB72A, 0x2A bytes. }

function assert_is_entry_block_entry(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_entry_block_entry := false
  else if n^.kind = 148 then
    assert_is_entry_block_entry :=
      assert_is_entry_block(g_opt_stmt_ptr_t(n)^.x48)
  else
    assert_is_entry_block_entry := false;
end;

{ assert_is_entry_label - n is a label of kind 13 followed by an entry.

  0x0DB754, 0x36 bytes. }

function assert_is_entry_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if not assert_is_label(n) then
    assert_is_entry_label := false
  else if rshft(ord(n^.xc[72]) & 16#3E, 1) = 13 then
    assert_is_entry_label := assert_is_entry_block_entry(n^.xp[2])
  else
    assert_is_entry_label := false;
end;

{ assert_is_abnormal_label - n is a label reached abnormally (+74).

  0x0DB78A, 0x26 bytes. }

function assert_is_abnormal_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_label(n) then
    assert_is_abnormal_label := n^.xc[74] <> chr(0)
  else
    assert_is_abnormal_label := false;
end;

{ assert_is_assigned_goto_label - n is a Fortran symbol of class 6
  (+44 bits 7..4) with +45 bit 6 and not bit 4: a label an assigned goto
  may reach.

  0x0DB7B0, 0x42 bytes. }

function assert_is_assigned_goto_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  assert_is_assigned_goto_label := false;
  if assert_is_fortran_symbol(n) then
    if rshft(ord(n^.xc[44]) & 16#F0, 4) = 6 then
      if (ord(n^.xc[45]) & 16#40) <> 0 then
        assert_is_assigned_goto_label := (ord(n^.xc[45]) & 16#10) = 0;
end;

{ assert_is_unsafe_abnormal_label - an abnormal label not marked safe
  (+77).

  0x0DB7F2, 0x26 bytes: `not.b' of the byte. }

function assert_is_unsafe_abnormal_label(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if assert_is_abnormal_label(n) then
    assert_is_unsafe_abnormal_label := n^.xc[77] = chr(0)
  else
    assert_is_unsafe_abnormal_label := false;
end;

{ assert_reached_by_linear_flow_from_previous_basic_block - s starts a
  block (hdr.first) and the statement before it does not leave by an
  unconditional branch or the end of a routine (149, not of a 172).

  0x0DB818, 0x5A bytes. }

function assert_reached_by_linear_flow_from_previous_basic_block(
    s: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
var
  p: g_opt_stmt_ptr_t;
begin
  assert_reached_by_linear_flow_from_previous_basic_block := false;
  if assert_is_top_level_statement(il_$node_ptr_t(s)) then
    if s^.hdr.first then
      if not assert_is_unconditional_branch(il_$node_ptr_t(s^.prev)) then
        if s^.prev <> nil then begin
          p := s^.prev;
          if p^.kind = 149 then
            assert_reached_by_linear_flow_from_previous_basic_block :=
              p^.x48^.kind = 172
          else
            assert_reached_by_linear_flow_from_previous_basic_block := true;
        end;
end;

{ mark_if_begins_basic_block - s starts a basic block (hdr.first) when
  it is a label, or follows a branch, or is an empty evaluation (after
  any statement).

  0x0DB872, 0x5C bytes: `bset #1,(42,A2)'. }

procedure mark_if_begins_basic_block(
    s: g_opt_stmt_ptr_t); options(val_param); internal;
begin
  if not assert_is_top_level_statement(il_$node_ptr_t(s)) then
    bug_check('OPT_MAIN_\MARK_IF_BEGINS_BASIC_BLOCK -- statement not a top level object%.');
  if assert_is_label(il_$node_ptr_t(s)) then
    s^.hdr.first := true
  else if s^.prev <> nil then
    if assert_is_branch(il_$node_ptr_t(s^.prev)) then
      s^.hdr.first := true
    else if assert_is_childless_eval(il_$node_ptr_t(s)) then
      s^.hdr.first := true;
end;

{ mark_begins_basic_block - s starts a basic block.

  0x0DB918, 0x2E bytes. }

procedure mark_begins_basic_block(
    s: g_opt_stmt_ptr_t); options(val_param); internal;
begin
  if not assert_is_top_level_statement(il_$node_ptr_t(s)) then
    bug_check('OPT_MAIN_\MARK_BEGINS_BASIC_BLOCK -- statement not a top level object%.');
  s^.hdr.first := true;
end;

{ new_basic_block - a basic block numbered num (116 bytes and npreds
  predecessors, cleared) starting at statement first_stmt (its first
  node first, loop the +12 field), skipped when first_stmt is an
  abnormal label; every register but 13..15 free over it.

  0x0DB98E, 0xA2 bytes: PAS_$NEW of npreds * 4 + 116 (an error 9 when
  there is no room); the boolean's high bit moved to bit 0 (`lsr.b #7;
  andi.b #0xFE; or.b'); +100 the longword 0xFFFF1FFF; the result in
  A0. }

function new_basic_block(
    num: g_opt_num_t;
    npreds: integer;
    first_stmt: g_opt_stmt_ptr_t;
    first: g_opt_num_t;
    loop: g_opt_block_ptr_t): g_opt_block_ptr_t; options(val_param); internal;
var
  b: g_opt_block_ptr_t;
begin
  if npreds < 0 then
    bug_check('OPT_MAIN_\NEW_BASIC_BLOCK -- negative pred_count%.');
  pas_$new(b, npreds * 4 + 116);
  if b = nil then
    cgerr_no_source(9, 0);
  zero_bytes(b, 116);
  b^.num := num;
  b^.flags.skip := assert_is_abnormal_label(il_$node_ptr_t(first_stmt));
  b^.first_stmt := first_stmt;
  b^.first := first;
  b^.loop := loop;
  b^.regs := [0..12, 16..31];
  new_basic_block := b;
end;

{ new_successor_list - room for n successors of block b (n * 4 bytes
  from the blk_succ pool; nil for none), b's capacity n.

  0x0DBA62, 0x60 bytes: the second test of n made again after the
  bug_check (`tst.w D2' twice). }

procedure new_successor_list(
    b: g_opt_block_ptr_t;
    n: integer); options(val_param); internal;
begin
  if b = nil then
    bug_check('OPT_MAIN_\NEW_SUCCESSOR_LIST -- NIL basic_block%.');
  if n < 0 then
    bug_check('OPT_MAIN_\NEW_SUCCESSOR_BLOCK -- negative succ_count%.');
  if n > 0 then
    b^.succ := mem_$alloc(om_succ_pool, n * 4)
  else
    b^.succ := nil;
  b^.unused_104 := n;
end;

{ add_predecessor - p among b's predecessors, unless it is already.

  0x0DBB2A, 0x4E bytes: the search a `dbf' loop. }

procedure add_predecessor(
    b: g_opt_block_ptr_t;
    p: g_opt_block_ptr_t); options(val_param); internal;
var
  k: integer;
begin
  for k := 1 to b^.npreds do
    if b^.pred[k] = p then
      return;
  b^.npreds := b^.npreds + 1;
  b^.pred[b^.npreds] := p;
end;

{ add_successor - s among b's successors, unless it is already; an
  error 28 at s's line when b's list is full (the successor is put in
  even so).

  0x0DBB78, 0x8A bytes: cgerr's argument strtk of the 40 characters;
  s's line the word +20 of its first statement. }

procedure add_successor(
    b: g_opt_block_ptr_t;
    s: g_opt_block_ptr_t); options(val_param); internal;
var
  k: integer;
begin
  for k := 1 to b^.nsucc do
    if b^.succ^[k] = s then
      return;
  if b^.nsucc = b^.unused_104 then
    cgerr(28, s^.first_stmt^.line,
          strtk('Insufficient space for block successors', 40));
  b^.nsucc := b^.nsucc + 1;
  b^.succ^[b^.nsucc] := s;
end;

{ assert_is_nonlocal_branch - n is a non-local branch (150).

  0x0DBC2A, 0x18 bytes, no frame. }

function assert_is_nonlocal_branch(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_nonlocal_branch := false
  else
    assert_is_nonlocal_branch := n^.kind = 150;
end;

{ assert_is_fortran_assigned_goto - n is a non-local branch through a
  Fortran symbol (its +44 bit 0): an assigned goto.

  0x0DBC42, 0x3A bytes. }

function assert_is_fortran_assigned_goto(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  v: il_$node_ptr_t;
begin
  assert_is_fortran_assigned_goto := false;
  if assert_is_nonlocal_branch(n) then begin
    v := g_opt_stmt_ptr_t(n)^.x48;
    if assert_is_fortran_symbol(v) then
      assert_is_fortran_assigned_goto := odd(ord(v^.xc[44]));
  end;
end;

{ assert_is_lexically_earlier_statement - a and b are top-level
  statements and a's region number is below b's.

  0x0DBC7C, 0x50 bytes: `andi.l #0xFFFF00' of the longwords at +42,
  `lsr.l #8', `cmp.w; scs'. }

function assert_is_lexically_earlier_statement(
    a: g_opt_stmt_ptr_t;
    b: g_opt_stmt_ptr_t): boolean; options(val_param); internal;
begin
  assert_is_lexically_earlier_statement := false;
  if assert_is_top_level_statement(il_$node_ptr_t(a)) then
    if assert_is_top_level_statement(il_$node_ptr_t(b)) then
      assert_is_lexically_earlier_statement := a^.hdr.region < b^.hdr.region;
end;

{ compute_label_backward_refs_due_to_assigned_goto - for each block
  ending in an assigned goto, the labels it may reach that come before
  it lose their +72 bit 6.

  0x0DBCCC, 0x8C bytes: `bclr #6,(72,A4)'. }

procedure compute_label_backward_refs_due_to_assigned_goto; internal;
var
  i: integer;
  k: integer;
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  l: g_opt_stmt_ptr_t;
begin
  for i := 1 to il_124 do begin
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    if assert_is_fortran_assigned_goto(il_$node_ptr_t(b^.last_stmt)) then begin
      s := b^.last_stmt;
      for k := 1 to b^.nsucc do begin
        l := b^.succ^[k]^.first_stmt;
        if assert_is_label(il_$node_ptr_t(l)) then
          if assert_is_lexically_earlier_statement(l, s) then
            il_$node_ptr_t(l)^.xc[72] := chr(ord(il_$node_ptr_t(l)^.xc[72]) & 16#BF);
      end;
    end;
  end;
end;

{ compute_variable_type_descriptors - types (by address: opt_var_types)
  allocated for the routine's variables (il_180's +290, from 0) and,
  for each variable of the routine whose entry heads opt_region (a
  148: il_180 set to its routine), its type: a Fortran variable's
  (language 2) without a base type, unranged (low and high -1), the
  size its data class (+10 low nibble) gives in om_class_bytes; the
  others type_exp's.

  0x0DBD58, 0x11C bytes: PAS_$NEW of 28 * n + 28 (`lsl #2; neg; lsl
  #3; add'; an error 9 when there is no room); the loop over the
  variables tests the entry's kind each time; +24 written as a word's
  bits (`andi.b #7', `bclr #10', `bclr #9', `ori.w #64'). }

procedure compute_variable_type_descriptors(
    var types: g_opt_vtypes_ptr_t); internal;
var
  v: integer;
  e: g_opt_stmt_ptr_t;
  n: il_$node_ptr_t;
begin
  pas_$new(types, il_180^.xw[145] * 28 + 28);
  if types = nil then
    cgerr_no_source(9, 0);
  for v := 1 to il_180^.xw[145] do begin
    e := opt_4009c[opt_region];
    if e^.kind = 148 then begin
      il_180 := e^.x48;
      n := e^.vars^[v]^.node;
      if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then begin
        types^[v].low := -1;
        types^[v].high := -1;
        types^[v].base := nil;
        types^[v].flags.b24 := 0;
        types^[v].flags.b24_2 := false;
        types^[v].flags.b24_1 := false;
        types^[v].flags.ranged := true;
        types^[v].size := om_class_bytes[ord(n^.xc[10]) & 15];
      end
      else
        type_exp(n, addr(types^[v]));
    end;
  end;
end;

{ check_dominators - for each block from an entry label or an unsafe
  abnormal label on, a later block reached from an earlier block (by a
  predecessor numbered below the entry's block) that the entry's block
  reaches (assert_is_predecessor) loses its dominators (idom and dom).

  0x0DBE74, 0x12E bytes: A5 loaded; the entry's number in (-12,A6),
  cleared after its blocks are looked at; the predecessors' loop left
  at the first that qualifies. }

procedure check_dominators;
var
  entry: g_opt_num_t;
  i: g_opt_num_t;
  j: g_opt_num_t;
  k: integer;
  b: g_opt_block_ptr_t;
begin
  if il_11c <> nil then begin
    entry := 0;
    for i := 1 to opt_last_block do begin
      if assert_is_entry_label(
           il_$node_ptr_t(g_opt_blocks_ptr_t(il_11c)^[i]^.first_stmt)) or
         assert_is_unsafe_abnormal_label(
           il_$node_ptr_t(g_opt_blocks_ptr_t(il_11c)^[i]^.first_stmt)) then
        entry := i;
      if entry <> 0 then begin
        for j := entry + 1 to opt_last_block do begin
          b := g_opt_blocks_ptr_t(il_11c)^[j];
          for k := 1 to b^.npreds do
            if b^.pred[k]^.num < entry then
              if assert_is_label(il_$node_ptr_t(b^.first_stmt)) then
                if assert_is_predecessor(entry, j) then begin
                  g_opt_blocks_ptr_t(il_11c)^[j]^.idom := nil;
                  g_opt_blocks_ptr_t(il_11c)^[j]^.dom := nil;
                  exit;
                end;
        end;
        entry := 0;
      end;
    end;
  end;
end;

{ initialize_stmt_nodes - the top-level statements numbered from 0 as
  opt_4009c's entries (each its region number; vnum and num cleared,
  its variable set emptied, no block, vars, cses, its free registers
  all but 13..15), an error 17 at the 65000th; n (by address) one more
  than the count.

  0x0DBFA2, 0xA6 bytes: `andi.l #0xFF0000FF; or.l' of the longword at
  +42 (region), `andi.l #0xFF' of +38; +22..+33 copied from a 12-byte
  constant (0, 0, 0xFFFF1FFF); `cmpi.w #-536' (65000 unsigned). }

procedure initialize_stmt_nodes(
    var n: g_opt_num_t); internal;
var
  k: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
begin
  k := 0;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    opt_4009c[k] := s;
    s^.hdr.region := k;
    s^.hdr.vnum := 0;
    s^.hdr.num := 0;
    if s^.vset <> nil then
      s^.vset^ := [];
    s^.block := nil;
    s^.vars := nil;
    s^.cses := nil;
    s^.regs := [0..12, 16..31];
    k := k + 1;
    if k >= 65000 then
      cgerr_no_source(17, 0);
    s := s^.next;
  end;
  n := k + 1;
end;

{ recompute_stmt_nodes - the top-level statements numbered again as
  opt_4009c's entries; runbackend_16 the last routine's end (149, not
  of a 172).

  0x0DC054, 0x6E bytes. }

procedure recompute_stmt_nodes; internal;
var
  k: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
begin
  k := 0;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    opt_4009c[k] := s;
    s^.hdr.region := k;
    if s^.kind = 149 then
      if s^.x48^.kind <> 172 then
        runbackend_16 := k;
    k := k + 1;
    s := s^.next;
  end;
end;

{ killvisited - the nodes of il_120 of the kinds in the set (trees and
  references) lose flag 5 (visited).

  0x0DC0C2, 0x6A bytes: the set of 0..207 at 0x0DC12C, range-checked
  (`bcs'), `bclr #5,(7,A1)'. }

procedure killvisited; internal;
var
  k: integer;
  n: g_opt_tree_ptr_t;
begin
  for k := 1 to il_126 do begin
    n := g_opt_tree_ptr_t(g_opt_nodes_ptr_t(il_120)^[k]);
    if n <> nil then
      if n^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205] then
        n^.flags := n^.flags - [5];
  end;
end;

{ resolve_nlbranch_targets - in a Fortran routine (language 2), each
  label an assigned goto may reach (the routine's symbols from il_180's
  +16, chained by +4) whose statement has a block makes that block a
  successor of b (and b its predecessor): the block is no longer
  skipped, the symbol loses +44 bit 1 and the statement is no longer
  abnormal (+74).

  0x0DC146, 0x9A bytes. }

procedure resolve_nlbranch_targets(
    b: g_opt_block_ptr_t); options(val_param); internal;
var
  l: il_$node_ptr_t;
  t: g_opt_block_ptr_t;
begin
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then begin
    if b = nil then
      bug_check('OPT_MAIN_\RESOLVE_NLBRANCH_TARGETS -- NIL block%.');
    l := il_180^.xp[4];
    while l <> nil do begin
      if assert_is_assigned_goto_label(l) then begin
        t := g_opt_stmt_ptr_t(l^.xp[12])^.block;
        if t <> nil then begin
          add_successor(b, t);
          add_predecessor(t, b);
          t^.flags.skip := false;
          l^.xc[44] := chr(ord(l^.xc[44]) & 16#FD);
          l^.xp[12]^.xc[74] := chr(0);
        end;
      end;
      l := l^.xp[1];
    end;
  end;
end;

{ compute_successors - block b's successors by its last statement: a
  branch's target block (the label's +52), a conditional branch's and
  the next block, a non-local branch's in Fortran
  (resolve_nlbranch_targets), the next block after the end of a 172 or
  any other statement.

  0x0DC212, 0xDC bytes: a jump table on the kind (141..150), the next
  block in (-8,A6); il_11c^[num + 1] read before the case. }

procedure compute_successors(
    b: g_opt_block_ptr_t); options(val_param); internal;
var
  next: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
begin
  if b = nil then
    bug_check('OPT_MAIN_\COMPUTE_SUCCESSORS -- NIL block%.');
  if b^.last_stmt = nil then
    bug_check('OPT_MAIN_\COMPUTE_SUCCESSORS -- NIL block^.last_tree_ptr%.');
  next := g_opt_blocks_ptr_t(il_11c)^[b^.num + 1];
  s := b^.last_stmt;
  case s^.kind of
    141:
      add_successor(b, g_opt_block_ptr_t(s^.br_target^.xp[13]));
    142: begin
      add_successor(b, next);
      add_successor(b, g_opt_block_ptr_t(s^.br_target^.xp[13]));
    end;
    149:
      if s^.x48^.kind = 172 then
        add_successor(b, next);
    150:
      if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
        resolve_nlbranch_targets(b);
    otherwise
      add_successor(b, next);
  end;
end;

{ assert_cleanup_body - block b is a cleanup handler's body: skipped and
  its flags' bit 7 set.

  0x0DC354, 0x26 bytes: `ori.b #0x81' (docs/rev889-patterns.md 10). }

procedure assert_cleanup_body(
    b: g_opt_block_ptr_t); options(val_param); internal;
begin
  if b = nil then
    bug_check('OPT_MAIN_\ASSERT_CLEANUP_BODY -- NIL block%.');
  b^.flags.b7 := true;
  b^.flags.skip := true;
end;

{ assert_is_pointer_deref_of_volatile_object - n is a dereference (146)
  without flags 1..4.

  0x0DC3A6, 0x20 bytes, no frame: `moveq #30; and.l (4,A0); seq'. }

function assert_is_pointer_deref_of_volatile_object(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    assert_is_pointer_deref_of_volatile_object := false
  else if n^.kind = 146 then
    assert_is_pointer_deref_of_volatile_object := (n^.xl[1] & 30) = 0
  else
    assert_is_pointer_deref_of_volatile_object := false;
end;

{ assert_is_call_to_abnormal_routine - n is a call tree (operator 16 or
  15 of a 143 or 137) of a routine that may return abnormally: a
  routine (108, 107) or a routine variable's (171: a volatile
  dereference, or its +16's) attribute +376 bit 5, a 175's +20's +79
  bit 5, or the Fortran symbol opt_abnormal_routine (opt_livevar's +0,
  docs/questions.md 122).

  0x0DC3C6, 0xB6 bytes: the call test kept in D2 and and-ed with the
  result (`and.b D2,D0'). }

function assert_is_call_to_abnormal_routine(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
var
  call: boolean;
  r: boolean;
  p: il_$node_ptr_t;
begin
  r := false;
  call := false;
  if n <> nil then
    if (n^.kind = 143) or (n^.kind = 137) then
      call := (g_opt_tree_ptr_t(n)^.op = 16) or (g_opt_tree_ptr_t(n)^.op = 15);
  if call then begin
    p := g_opt_tree_ptr_t(n)^.opnd[1];
    case p^.kind of
      108, 107:
        r := (ord(p^.xc[376]) & 16#20) <> 0;
      171:
        if assert_is_pointer_deref_of_volatile_object(p) then
          r := true
        else
          r := (ord(p^.xp[4]^.xc[376]) & 16#20) <> 0;
      175:
        r := (ord(p^.xp[5]^.xc[79]) & 16#20) <> 0;
      110:
        r := p = opt_abnormal_routine;
      otherwise
        r := false;
    end;
  end;
  assert_is_call_to_abnormal_routine := r and call;
end;

{ compute_abnormality_due_to_proc_calls - for each node of block b
  that calls a routine that may return abnormally, b's successors are
  skipped (and their successors computed); in a routine of language 1,
  2 or 6, a successor ending in a conditional branch on a comparison
  (operator 12) with the integer constant 16#03040003 (a cleanup
  handler's status) marks the arm taken on it as a cleanup handler's
  body, else every successor of it; language 3 likewise without
  looking at the constant.

  0x0DC47C, 0x234 bytes: `btst' of the language in the longword 70
  ([1, 2, 6]); the comparison's sense from the branch's br_sense and
  the comparison's register class (+28: 7, 6); the constant's kind by
  the set of 0..207 at 0x0DC6EE. }

procedure compute_abnormality_due_to_proc_calls(
    b: g_opt_block_ptr_t); options(val_param); internal;
var
  i: g_opt_num_t;
  k: integer;
  m: integer;
  lang: integer;
  t: il_$node_ptr_t;
  s: g_opt_block_ptr_t;
  e: g_opt_stmt_ptr_t;
  c: g_opt_tree_ptr_t;
  x: il_$node_ptr_t;
  neg: boolean;
  done: boolean;
begin
  if b = nil then
    bug_check('OPT_MAIN_\COMPUTE_ABNORMALITY_DUE_TO_PROC_CALLS -- NIL block%.');
  for i := b^.first to b^.last do begin
    t := g_opt_nodes_ptr_t(il_120)^[i];
    if assert_is_call_to_abnormal_routine(t) then
      for k := 1 to b^.nsucc do begin
        s := b^.succ^[k];
        s^.flags.skip := true;
        compute_successors(b^.succ^[k]);
        lang := rshft(ord(il_180^.xc[377]) & 16#70, 4);
        done := false;
        if lang in [1, 2, 6] then begin
          e := s^.last_stmt;
          if e^.kind = 142 then begin
            c := g_opt_tree_ptr_t(e^.br_cond);
            if (c^.kind = 143) and (c^.op = 12) then begin
              neg := not e^.br_sense;
              if ((c^.w28 = 7) and neg) or (e^.br_sense and (c^.w28 = 6)) then
                if s^.nsucc = 2 then begin
                  x := c^.opnd[2];
                  if x^.kind in [77..87, 101, 200] then
                    if x^.int_value = 16#03040003 then begin
                      assert_cleanup_body(s^.succ^[2]);
                      done := true;
                    end;
                end;
              if not done then
                if ((c^.w28 = 6) and neg) or (e^.br_sense and (c^.w28 = 7)) then
                  if s^.nsucc = 1 then begin
                    x := c^.opnd[2];
                    if x^.kind in [77..87, 101, 200] then
                      if x^.int_value = 16#03040003 then begin
                        assert_cleanup_body(s^.succ^[1]);
                        done := true;
                      end;
                  end;
            end;
          end;
          if not done then
            for m := 1 to s^.nsucc do
              assert_cleanup_body(s^.succ^[m]);
        end
        else if lang = 3 then begin
          e := s^.last_stmt;
          if e^.kind = 142 then begin
            c := g_opt_tree_ptr_t(e^.br_cond);
            if (c^.kind = 143) and (c^.op = 12) then begin
              neg := not e^.br_sense;
              if ((c^.w28 = 7) and neg) or (e^.br_sense and (c^.w28 = 6)) then
                if s^.nsucc = 2 then begin
                  assert_cleanup_body(s^.succ^[2]);
                  done := true;
                end;
              if not done then
                if ((c^.w28 = 6) and neg) or (e^.br_sense and (c^.w28 = 7)) then
                  if s^.succ^[1] <> nil then begin
                    assert_cleanup_body(s^.succ^[1]);
                    done := true;
                  end;
            end;
          end;
          if not done then
            for m := 1 to s^.nsucc do
              assert_cleanup_body(s^.succ^[m]);
        end;
      end;
  end;
end;

{ compute_basic_block_relationships - for each top-level statement
  (om_stmt_num counting them): a routine's entry sets opt_region and
  il_180; a statement starting a block gives the block its predecessor
  (the block before, when reached by linear flow), its successors and
  their abnormality; a branch makes its target's block a successor of
  the current one.

  0x0DC708, 0xEE bytes: the block's number in D2. }

procedure compute_basic_block_relationships; internal;
var
  n: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
  b: g_opt_block_ptr_t;
  t: g_opt_block_ptr_t;
begin
  n := 0;
  om_stmt_num := n;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    if opt_4009c[om_stmt_num]^.hdr.entry then begin
      opt_region := om_stmt_num;
      il_180 := opt_4009c[om_stmt_num]^.x48;
    end;
    if s^.hdr.first then begin
      n := n + 1;
      b := g_opt_blocks_ptr_t(il_11c)^[n];
      if assert_reached_by_linear_flow_from_previous_basic_block(s) then
        add_predecessor(b, g_opt_blocks_ptr_t(il_11c)^[n - 1]);
      compute_successors(b);
      compute_abnormality_due_to_proc_calls(b);
    end;
    if (s^.kind = 142) or (s^.kind = 141) then begin
      t := g_opt_block_ptr_t(s^.br_target^.xp[13]);
      if t <> nil then
        add_predecessor(t, g_opt_blocks_ptr_t(il_11c)^[n]);
    end;
    om_stmt_num := om_stmt_num + 1;
    s := s^.next;
  end;
end;

{ compute_depth_first_order_of_basic_blocks - the blocks numbered in
  depth-first order (opt_select's dfs, n counting down from
  opt_last_block): first from the blocks without predecessors, then
  from any block not reached yet, until every block has its number.

  0x0DC7F6, 0xD0 bytes: the count compared with opt_first_block - 1 as
  longwords before each block; dfs's n through a frame copy. }

procedure compute_depth_first_order_of_basic_blocks; internal;
var
  n: g_opt_num_t;
  i: g_opt_num_t;
  b: g_opt_block_ptr_t;
begin
  n := opt_last_block;
  for i := opt_first_block to opt_last_block do begin
    if n = opt_first_block - 1 then
      exit;
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    if not b^.flags.visited and (b^.npreds = 0) then
      dfs(b, n);
  end;
  if n <> opt_first_block - 1 then
    for i := opt_first_block to opt_last_block do begin
      b := g_opt_blocks_ptr_t(il_11c)^[i];
      if not b^.flags.visited then
        dfs(b, n);
    end;
end;

{ compute_dominator_matrix - opt_dom's rows (il_124 + 1 booleans each,
  from the dom_matrix pool) for blocks 0..opt_last_block; each block's
  row marks its dominators (the dom chain).

  0x0DC8C6, 0xCE bytes: the size by M$MIU$LLL; both loops counted with
  `dbf' and a borrow (docs/rev889-patterns.md 17); the second from
  opt_last_block down to 1. }

procedure compute_dominator_matrix; internal;
var
  size: integer32;
  m: univ_ptr;
  i: integer32;
  d: g_opt_block_ptr_t;
  row: g_opt_dom_row_ptr_t;
begin
  size := ((il_124 & 16#FFFF) + 1) * (opt_last_block + 1);
  m := mem_$alloc(opt_main_8, size);
  for i := 0 to opt_last_block do begin
    opt_dom[i] := m;
    m := univ_ptr(integer32(m) + (il_124 & 16#FFFF) + 1);
  end;
  for i := opt_last_block downto 1 do begin
    d := g_opt_blocks_ptr_t(il_11c)^[i]^.dom;
    row := opt_dom[i];
    while d <> nil do begin
      row^[d^.num] := true;
      d := d^.dom;
    end;
  end;
end;

{ compute_preds_and_succs_for_dominance - each block's flow edges for
  dominators: a list of its successors (succs, an edge from the block
  to each; one empty edge when it has none) and of its predecessors
  (preds_list, likewise), each edge 16 bytes from gspace.

  0x0DC994, 0x13E bytes: il_11c's address kept in D6; the first edge
  of each list filled in place, the others pushed in front. }

procedure compute_preds_and_succs_for_dominance; internal;
var
  i: g_opt_num_t;
  k: integer;
  b: g_opt_block_ptr_t;
  x: g_opt_block_ptr_t;
  e: g_opt_edge_ptr_t;
begin
  for i := opt_first_block to opt_last_block do begin
    b := g_opt_blocks_ptr_t(il_11c)^[i];
    b^.succs := gspace(16);
    b^.preds_list := gspace(16);
    e := b^.succs;
    e^.src := g_opt_blocks_ptr_t(il_11c)^[i];
    e^.dest := nil;
    e^.next_succ := nil;
    e^.next_pred := nil;
    for k := 1 to b^.nsucc do begin
      x := b^.succ^[k];
      e := b^.succs;
      if e^.dest = nil then
        e^.dest := x
      else begin
        e := gspace(16);
        e^.dest := x;
        e^.next_succ := b^.succs;
        e^.src := g_opt_blocks_ptr_t(il_11c)^[i];
        e^.next_pred := nil;
        b^.succs := e;
      end;
    end;
    e := b^.preds_list;
    e^.dest := g_opt_blocks_ptr_t(il_11c)^[i];
    e^.src := nil;
    e^.next_succ := nil;
    e^.next_pred := nil;
    for k := 1 to b^.npreds do begin
      x := b^.pred[k];
      e := b^.preds_list;
      if e^.src = nil then
        e^.src := x
      else begin
        e := gspace(16);
        e^.src := x;
        e^.next_pred := b^.preds_list;
        e^.dest := g_opt_blocks_ptr_t(il_11c)^[i];
        e^.next_succ := nil;
        b^.preds_list := e;
      end;
    end;
  end;
end;

{ compute_basic_block_dominance_relationships - the flow edges, the
  depth-first lists from the first block and from each block not
  reached from it, the immediate dominators, check_dominators in
  Fortran when either flag is set (g_opt's), the dominance matrix.

  0x0DCAD2, 0xCA bytes: depth_first_dom's arguments il_180 and the
  block by address (`move.l #0x169DF0'); a block not reached has no
  semi (+72). }

procedure compute_basic_block_dominance_relationships(
    a: boolean;
    b: boolean); options(val_param); internal;
var
  i: g_opt_num_t;
begin
  compute_preds_and_succs_for_dominance;
  depth_first_dom(il_180, g_opt_blocks_ptr_t(il_11c)^[opt_first_block]);
  for i := opt_first_block to opt_last_block do
    if g_opt_blocks_ptr_t(il_11c)^[i]^.semi = nil then
      depth_first_dom(il_180, g_opt_blocks_ptr_t(il_11c)^[i]);
  dominators(il_180, g_opt_blocks_ptr_t(il_11c)^[opt_first_block]);
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 2 then
    if a or b then
      check_dominators;
  compute_dominator_matrix;
end;

{ recompute_usedef_for_strength_reduction - after strength reduction,
  each statement using variables (vset) gets, for each variable it
  uses, an entry in its table (a copy of opt_region's entry's, 18 bytes
  from the var_chain pool, uses cleared) and its use-def chain
  (make_motioned_ud_chain with the region at hand, om_stmt_num); an
  entry without a chain gets one.

  0x0DCB9C, 0x128 bytes: an empty set found with `tst.l (A0)+; dbne';
  the variables' loop over il_180's +290; make_motioned_ud_chain's
  arguments by address (the variable and the statement through frame
  copies). }

procedure recompute_usedef_for_strength_reduction; internal;
var
  s: g_opt_stmt_ptr_t;
  v: 0..255;
begin
  om_stmt_num := 0;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    if s^.hdr.region <> 0 then
      om_stmt_num := s^.hdr.region;
    if s^.vset = nil then
      s := s^.next
    else if s^.vset^ = [] then
      s := s^.next
    else begin
      for v := 1 to il_180^.xw[145] do
        if v in s^.vset^ then
          if s^.vars^[v] = nil then begin
            s^.vars^[v] := mem_$alloc(opt_main_18, 18);
            s^.vars^[v]^ := opt_4009c[opt_region]^.vars^[v]^;
            s^.vars^[v]^.count := 0;
            make_motioned_ud_chain(v, om_stmt_num, s);
          end
          else if s^.vars^[v]^.ud = nil then
            make_motioned_ud_chain(v, om_stmt_num, s);
      s := s^.next;
    end;
  end;
end;

{ recompute_usedef_for_uplevel_addressing - outside Fortran, each call
  (in each block's nodes) of a routine (107, 167, 108) marked to reach
  its callers' variables (+378 bit 6) nested no deeper than the
  current routine (+294, signed bytes) uses the variable that routine
  addresses its enclosing frames through (the current routine's +240
  chain, +12 down as many levels as the nesting differs): when it is a
  variable of opt_region's table not yet in the call's statement's set,
  it is added there with an entry (a copy of opt_region's, one use,
  flags 16#200).

  0x0DCCC4, 0x1DE bytes: the variable's number in D3, set only when
  the chain ends at a variable's name (otherwise the previous call's,
  or whatever D3 held, is used: kept); the set's element added through
  a 32-byte frame set (`bset', then `or.l' of the eight longwords). }

procedure recompute_usedef_for_uplevel_addressing; internal;
var
  i: g_opt_num_t;
  j: g_opt_num_t;
  k: integer;
  n: g_opt_num_t;
  t: il_$node_ptr_t;
  r: il_$node_ptr_t;
  v: il_$node_ptr_t;
  s: g_opt_stmt_ptr_t;
  one: g_opt_varset_t;
begin
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
    for i := opt_first_block to opt_last_block do
      for j := g_opt_blocks_ptr_t(il_11c)^[i]^.first to
               g_opt_blocks_ptr_t(il_11c)^[i]^.last do begin
        t := g_opt_nodes_ptr_t(il_120)^[j];
        if assert_is_call_tree(t) then begin
          r := g_opt_tree_ptr_t(t)^.opnd[1];
          if (r^.kind = 107) or (r^.kind = 167) or (r^.kind = 108) then
            if (ord(r^.xc[378]) & 16#40) <> 0 then
              if ord(r^.xc[294]) <= ord(il_180^.xc[294]) then begin
                v := il_180^.xp[60];
                for k := 1 to ord(il_180^.xc[294]) - ord(r^.xc[294]) do
                  v := v^.xp[3];
                if assert_is_var_name(v) then
                  n := find_var(v);
                if n <> 0 then begin
                  s := g_opt_tree_ptr_t(t)^.owner;
                  if s^.vset <> nil then
                    if n in s^.vset^ then
                      next;
                  opt_main_$ensure_var_set(s^.vset);
                  one := [];
                  one := one + [n];
                  s^.vset^ := s^.vset^ + one;
                  s^.vars^[n] := mem_$alloc(opt_main_18, 18);
                  s^.vars^[n]^ := opt_4009c[opt_region]^.vars^[n]^;
                  s^.vars^[n]^.count := 1;
                  s^.vars^[n]^.flags := s^.vars^[n]^.flags ! 16#200;
                end;
              end;
        end;
      end;
end;

{ eliminate_dead_code_and_count_basic_blocks - il_124 counts the
  statements starting basic blocks (marked first unless
  opt_track_lines); after an unconditional branch, the statements up
  to a label still reached (not of kind 11, or abnormal, or referenced:
  +50) are unlinked (the label relinked after the branch; at a
  routine's start or end, 148 or 149, nothing is relinked); when one
  of them was code (not 148, 149) and none was quiet (+41 bits 7, 5) or
  a store to a variable marked +34 bit 14, warning 33 (unreachable
  code) at the first line found: theirs, else the branch's next
  source-generated statement's (when the branch has a line), else the
  first line from the stopping statement on.

  0x0DCEA2, 0x1CE bytes: the flags in D2 (code), D3 (quiet), D4
  (marked store); the line in (-18,A6); the quiet bits by `andi.w
  #0xA000' of the word at +41. }

procedure eliminate_dead_code_and_count_basic_blocks; internal;
var
  s: g_opt_stmt_ptr_t;
  t: g_opt_stmt_ptr_t;
  line: integer;
  code: boolean;
  quiet: boolean;
  marked: boolean;
  stop: boolean;
begin
  il_124 := 0;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    if not opt_track_lines then
      mark_if_begins_basic_block(s);
    if s^.hdr.first then
      il_124 := il_124 + 1;
    code := false;
    quiet := true;
    marked := code;
    if assert_is_unconditional_branch(il_$node_ptr_t(s)) then begin
      t := s;
      line := spos_$null_position;
      stop := false;
      repeat
        t := t^.next;
        if t = nil then begin
          s^.next := t;
          stop := true;
        end
        else if (t^.kind = 144) and
                ((rshft(ord(il_$node_ptr_t(t)^.xc[72]) & 16#3E, 1) <> 11) or
                 (il_$node_ptr_t(t)^.xc[74] <> chr(0)) or
                 (il_$node_ptr_t(t)^.xw[25] <> 0)) then begin
          s^.next := t;
          t^.prev := s;
          stop := true;
        end
        else if (t^.kind = 149) or (t^.kind = 148) then
          stop := true
        else begin
          code := true;
          if not (t^.hdr.b7 or t^.hdr.b5) then
            quiet := false;
          if t^.kind = 140 then
            if t^.asg_lhs^.kind = 109 then
              marked := (t^.asg_lhs^.xw[17] & 16#4000) <> 0;
          if not assert_is_defined_spos(line) then
            if assert_is_defined_spos(t^.line) then
              line := t^.line;
        end;
      until stop;
      if not (quiet or marked) then
        if assert_is_defined_spos(line) then
          cgerr(33, line, nil)
        else if code then
          if assert_is_defined_spos(s^.line) then begin
            t := g_opt_stmt_ptr_t(il_utils_$source_generated_top_level_node(
                                    il_$node_ptr_t(s^.next)));
            cgerr(33, t^.line, nil);
          end
          else if t <> nil then
            if not assert_is_defined_spos(t^.line) then begin
              while t <> nil do begin
                line := t^.line;
                if assert_is_defined_spos(t^.line) then
                  exit;
                if (t^.kind = 149) or (t^.kind = 148) then
                  exit;
                t := t^.next;
              end;
              if assert_is_defined_spos(line) then
                cgerr(33, line, nil);
            end;
    end;
    s := s^.next;
  end;
end;

{ coalesce_adjacent_and_eliminate_dead_assignments - for each top-level
  statement: Fortran's complex stores collapsed
  (opt_main_$collapse_fortran_complex_assigns, which may move s back); a
  routine's entry clears its routine's depth-first lists (+132..+147);
  an artificial statement is marked quiet (+41 bit 5); an assignment
  not followed by one, or followed by one of operator 27..30, is
  merged with the run after it (opt_assign's assign_opt).

  0x0DD070, 0xA8 bytes: s through a frame copy; the operators by
  `btst' in the longword 0x78000000 after `cmp.w #31; bcs'. }

procedure coalesce_adjacent_and_eliminate_dead_assignments; internal;
var
  s: g_opt_stmt_ptr_t;
  t: g_opt_stmt_ptr_t;
  r: g_opt_rtn_ptr_t;
begin
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    t := s;
    opt_main_$collapse_fortran_complex_assigns(t);
    s := t;
    if s^.kind = 148 then begin
      r := g_opt_rtn_ptr_t(s^.x48);
      r^.pre_first := nil;
      r^.pre_last := nil;
      r^.post_first := nil;
      r^.post_last := nil;
    end;
    if assert_is_artificial_statement(il_$node_ptr_t(s)) then
      s^.hdr.b5 := true;
    if (s^.kind = 140) and (s^.next^.kind <> 140) then
      assign_opt(s)
    else if (s^.kind = 140) and (s^.next^.kind = 140) then
      if (s^.next^.asg_op <= 31) and (s^.next^.asg_op in [27..30]) then
        assign_opt(s);
    s := s^.next;
  end;
end;

{ makedindex - outside Fortran, a dereference t (146, no flags 1..4)
  of a sum (137, operator 1, register class 5) of a variable (109) and
  a reference (109, 145, 147, 146) becomes an indexed reference of the
  reference by the variable (add_dindexn, 4 bytes an element, t's
  alignment +22 signed and +23), unused, substituted for t in p.

  0x0DD118, 0x118 bytes: t by address; the two orders written out. }

procedure makedindex(
    var t: il_$node_ptr_t;
    p: il_$node_ptr_t); options(val_param); internal;
var
  n: il_$node_ptr_t;
  a: g_opt_tree_ptr_t;
  x: il_$node_ptr_t;
  y: il_$node_ptr_t;
  r: il_$node_ptr_t;
  al: integer;
begin
  if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
    if t <> nil then begin
      n := t;
      if (n^.kind = 146) and ((n^.xl[1] & 30) = 0) then begin
        a := g_opt_tree_ptr_t(n^.xp[6]);
        if (a^.kind = 137) and (a^.op = 1) and (a^.rlen = 5) then begin
          x := a^.opnd[1];
          al := ord(n^.xc[22]);
          if al > 127 then
            al := al - 256;
          if (x^.kind = 109) and
             ((a^.opnd[2]^.kind = 109) or (a^.opnd[2]^.kind = 145) or
              (a^.opnd[2]^.kind = 147) or (a^.opnd[2]^.kind = 146)) then
            r := add_dindexn(a^.opnd[2], n^.xp[7], x, 0, 4, al, ord(n^.xc[23]))
          else begin
            y := a^.opnd[2];
            if y^.kind <> 109 then
              return;
            if not ((x^.kind = 109) or (x^.kind = 145) or (x^.kind = 147) or
                    (x^.kind = 146)) then
              return;
            r := add_dindexn(x, n^.xp[7], y, 0, 4, al, ord(n^.xc[23]));
          end;
          r^.xw[8] := 0;
          il_utils_$do_substitution(p, t, r);
        end;
      end;
    end;
end;

{ recover - the indexed references of tree t and below remade
  (makedindex) where the original's dereferences of sums were kept: a
  tree used once and not marked to be kept (flags 3, 4) is walked by
  kind; an indexed reference (145) whose index is a left shift by a
  constant 0..3, or a product by 2, 4 or 8, of the index's class gets
  that scale (+40) and the shift's or product's operand as its index (a
  product of a word by 2 not of the index's class: the operand
  displaced 2 bytes, add_dn).

  0x0DD230, 0x38A bytes: recursive; the kinds by the set of 0..207 at
  0x0DC12C (killvisited's), `andi.l #24' of +4; the constants' kinds by
  the set at 0x0DC6EE. }

procedure recover(
    t: il_$node_ptr_t); options(val_param); internal;
var
  k: integer;
  a: g_opt_tree_ptr_t;
  c: il_$node_ptr_t;
begin
  if t = nil then
    return;
  if t^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205] then
    if ((t^.xl[1] & 24) <> 0) or (t^.xw[8] > 1) then
      return;
  case t^.kind of
    190:
      recover(t^.xp[1]);
    143, 137:
      for k := 1 to g_opt_tree_ptr_t(t)^.count do begin
        makedindex(g_opt_tree_ptr_t(t)^.opnd[k], t);
        recover(g_opt_tree_ptr_t(t)^.opnd[k]);
      end;
    205, 147, 146: begin
      makedindex(t^.xp[6], t);
      recover(t^.xp[6]);
    end;
    175: begin
      makedindex(t^.xp[4], t);
      recover(t^.xp[4]);
    end;
    171: begin
      makedindex(t^.xp[4], t);
      recover(t^.xp[4]);
    end;
    164: begin
      makedindex(t^.xp[5], t);
      makedindex(t^.xp[6], t);
      recover(t^.xp[5]);
      recover(t^.xp[6]);
    end;
    145: begin
      makedindex(t^.xp[6], t);
      makedindex(t^.xp[9], t);
      a := g_opt_tree_ptr_t(t^.xp[9]);
      if (a^.kind = 137) and (a^.op = 27) then begin
        c := a^.opnd[2];
        if c^.kind in [77..87, 101, 200] then
          if c^.int_value <= 3 then
            if (t^.xw[21] = a^.rlen) and (t^.xw[8] = 1) then begin
              t^.xw[20] := c^.xw[5];
              adjust_uc(t^.xp[9], -1);
              t^.xp[9] := g_opt_tree_ptr_t(t^.xp[9])^.opnd[1];
              adjust_uc(t^.xp[9], 1);
            end;
      end;
      a := g_opt_tree_ptr_t(t^.xp[9]);
      if (a^.kind = 137) and (a^.op = 3) then begin
        c := a^.opnd[2];
        if c^.kind in [77..87, 101, 200] then
          if (c^.int_value = 2) or (c^.int_value = 8) or
             (c^.int_value = 4) then
            if (t^.xw[21] = a^.rlen) and (t^.xw[21] = a^.w26) and
               (t^.xw[21] = a^.w28) and (t^.xw[8] = 1) then begin
              if c^.int_value = 8 then
                t^.xw[20] := 3
              else if c^.int_value = 4 then
                t^.xw[20] := 2
              else
                t^.xw[20] := 1;
              adjust_uc(t^.xp[9], -1);
              t^.xp[9] := g_opt_tree_ptr_t(t^.xp[9])^.opnd[1];
              adjust_uc(t^.xp[9], 1);
            end;
      end;
      a := g_opt_tree_ptr_t(t^.xp[9]);
      if (a^.kind = 137) and (a^.op = 3) then begin
        c := a^.opnd[2];
        if c^.kind in [77..87, 101, 200] then
          if (c^.int_value = 2) or (c^.int_value = 8) or
             (c^.int_value = 4) then
            if (t^.xw[21] = a^.rlen) and (t^.xw[21] <> a^.w26) and
               (t^.xw[21] = a^.w28) and (t^.xw[21] = 2) and
               (t^.xw[8] = 1) then begin
              if c^.int_value = 8 then
                t^.xw[20] := 3
              else if c^.int_value = 4 then
                t^.xw[20] := 2
              else
                t^.xw[20] := 1;
              adjust_uc(t^.xp[9], -1);
              t^.xp[9] := add_dn(g_opt_tree_ptr_t(t^.xp[9])^.opnd[1],
                                 g_opt_tree_ptr_t(t^.xp[9])^.opnd[1], 2);
              adjust_uc(t^.xp[9], 1);
            end;
      end;
      recover(t^.xp[6]);
      recover(t^.xp[9]);
    end;
    otherwise
      ;
  end;
end;

{ recover_scaled - when target_properties' +0x58 is positive, each
  statement's trees from the first block's on, up to the end of the
  outermost routine (149, not of a 172), get their indexed references
  back (makedindex, recover): an assignment's three, an evaluation's
  operands, a conditional branch's condition, a 151's operand.

  0x0DD5BA, 0x114 bytes: the loop entered at the first statement
  without a test. }

procedure recover_scaled; internal;
var
  s: g_opt_stmt_ptr_t;
  k: integer;
begin
  if target_properties.p_58 > 0 then begin
    s := g_opt_blocks_ptr_t(il_11c)^[opt_first_block]^.first_stmt;
    if s <> nil then
      repeat
        case s^.kind of
          140: begin
            makedindex(s^.asg_rhs, il_$node_ptr_t(s));
            makedindex(s^.asg_x, il_$node_ptr_t(s));
            makedindex(s^.asg_lhs, il_$node_ptr_t(s));
            recover(s^.asg_rhs);
            recover(s^.asg_lhs);
            recover(s^.asg_x);
          end;
          139:
            for k := 1 to s^.eval_count do begin
              makedindex(s^.eval_opnd[k], il_$node_ptr_t(s));
              recover(s^.eval_opnd[k]);
            end;
          142: begin
            makedindex(s^.br_cond, il_$node_ptr_t(s));
            recover(s^.br_cond);
          end;
          151:
            if s^.x48 <> nil then begin
              makedindex(s^.x48, il_$node_ptr_t(s));
              recover(s^.x48);
            end;
          otherwise
            ;
        end;
        s := s^.next;
      until (s^.kind = 149) and (s^.x48^.kind <> 172);
  end;
end;

{ distrib_mul - t, a multiplication (3) or left shift (27) of
  something by an integer constant, distributed over an addition (1)
  below it (through a conversion, 18): (b * c' + v) * c becomes b * (c'
  * c) + v * c (opt_str_$product_of forms the product; both products'
  register classes fixed up); ((x << k1 + y) + z << k2) << k3 has k3
  added to the inner shifts and y shifted; under opt_on 20, (v1 + v2)
  << c becomes v1 + (v2 << c) for two variables or references.  The
  result is the tree that stands for t (the addition when t was
  distributed).

  0x0DDA32, 0x56C bytes: the result in D2, A0 at the end; the
  constants by the set at 0x0DC6EE, the shifted operands by the set of
  0..159 at 0x0DDF9E ([109..110, 145..147]); the second form's test of
  no_enforce_parens_and_ucs_eq_1 returns t unchanged when it is true
  (`bmi'), the first's when it is false (`bpl'): kept. }

function distrib_mul(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); internal;
type
  rlens_t = set of 0..15;
var
  r: il_$node_ptr_t;
  m: g_opt_tree_ptr_t;
  a: g_opt_tree_ptr_t;
  b: g_opt_tree_ptr_t;
  c: g_opt_tree_ptr_t;
  p: g_opt_tree_ptr_t;
  x: il_$node_ptr_t;
  ops: array [1..2] of il_$node_ptr_t;
  done: boolean;

  { no_enforce_parens_and_ucs_eq_1 - neither the product a nor the sum
    b below it is parenthesized (flag 21), when f neither displacement
    operand (a's second, b's first's first) is a displacement (147) of
    other than a Fortran symbol, and a, a's first operand, b and b's
    first operand are each used once.

    0x0DD6CE, 0x8C bytes: nested, the parent's frame not used. }

  function no_enforce_parens_and_ucs_eq_1(
      a: g_opt_tree_ptr_t;
      b: g_opt_tree_ptr_t;
      f: boolean): boolean; options(val_param);
  var
    c: g_opt_tree_ptr_t;
    x: il_$node_ptr_t;
  begin
    no_enforce_parens_and_ucs_eq_1 := false;
    c := g_opt_tree_ptr_t(b^.opnd[1]);
    if not (21 in b^.flags) and not (21 in c^.flags) then begin
      if f then begin
        x := b^.opnd[2];
        if x^.kind = 147 then
          if x^.xp[6]^.kind <> 110 then
            return;
        x := c^.opnd[1];
        if x^.kind = 147 then
          if x^.xp[6]^.kind <> 110 then
            return;
      end;
      if (a^.uses = 1) and (a^.opnd[1]^.xw[8] = 1) and (b^.uses = 1) and
         (c^.uses = 1) then
        no_enforce_parens_and_ucs_eq_1 := true;
    end;
  end;

  { convert_lshf_to_mul - a left shift t by a constant k made the
    product by 2 ** k, its operands of t's register class's size.

    0x0DD75A, 0x56 bytes: nested; `lsl.l' of 1. }

  procedure convert_lshf_to_mul(
      t: g_opt_tree_ptr_t); options(val_param);
  begin
    if t^.op = 27 then begin
      t^.opnd[2] := smcontk(81, lshft(1, t^.opnd[2]^.int_value));
      t^.w26 := class_size[t^.rlen];
      t^.w28 := t^.w26;
      t^.op := 3;
    end;
  end;

  { possible_rlens_of_operand - the sizes t may be used at as an
    operand: a constant [2, 4] when it fits a word, else [4]; a
    displacement of 2 bytes into a 4-byte variable used once [2, 4];
    else the one opt_str_$opmod_of_operand gives (size, sgn).

    0x0DD7B0, 0xB8 bytes: nested; the set a word (20, 16; `bset' into a
    cleared frame word, range-checked). }

  function possible_rlens_of_operand(
      t: il_$node_ptr_t;
      size: integer;
      sgn: boolean): rlens_t; options(val_param);
  var
    k: integer32;
  begin
    if t^.kind in [77..87, 101, 200] then begin
      if (t^.int_value >= -32768) and (t^.int_value <= 32767) then
        possible_rlens_of_operand := [2, 4]
      else
        possible_rlens_of_operand := [4];
    end
    else if (t^.kind = 147) and (t^.xl[8] = 2) and (t^.xw[8] = 1) and
            ((t^.xp[6]^.kind = 110) or (t^.xp[6]^.kind = 109)) and
            (opt_str_$opmod_of_operand(t^.xp[6], 2, true) = 4) then
      possible_rlens_of_operand := [2, 4]
    else begin
      k := opt_str_$opmod_of_operand(t, size, sgn);
      possible_rlens_of_operand := [k];
    end;
  end;

  { crush_disp_2 - operand t (by address) used at 4 bytes: a constant
    as it is, a displacement of 2 bytes into a 4-byte variable used
    once replaced by the variable; size (by address) 4 then.

    0x0DD868, 0x8A bytes: nested. }

  procedure crush_disp_2(
      var t: il_$node_ptr_t;
      var size: integer);
  begin
    if t^.kind in [77..87, 101, 200] then
      size := 4
    else if (t^.kind = 147) and (t^.xl[8] = 2) and (t^.xw[8] = 1) and
            ((t^.xp[6]^.kind = 110) or (t^.xp[6]^.kind = 109)) and
            (opt_str_$opmod_of_operand(t^.xp[6], 2, true) = 4) then begin
      t := t^.xp[6];
      size := 4;
    end;
  end;

  { fixup_rlen_of_mul - product (or left shift) t given register class
    rlen: unless it already is a product of that class whose operands
    may be used at their sizes, the operands are widened to 4 bytes
    (crush_disp_2) and a shift made a product, except for a word
    product of words; the class, the operands' sizes and the size set.

    0x0DD8F2, 0x116 bytes: nested; a shift's operand sizes from its
    classes (class_size); the sets tested range-checked (`cmp.w #15;
    bcs; btst'); the sizes through frame copies. }

  procedure fixup_rlen_of_mul(
      t: g_opt_tree_ptr_t;
      rlen: integer); options(val_param);
  var
    a: integer;
    b: integer;
    pa: rlens_t;
    pb: rlens_t;
  begin
    if t^.op = 27 then begin
      a := class_size[t^.w26];
      b := class_size[t^.w28];
    end
    else if t^.op = 3 then begin
      a := t^.w26;
      b := t^.w28;
    end
    else
      bug_check('opt_main:  bad call to fixup_rlen_of_mul%.');
    pa := possible_rlens_of_operand(t^.opnd[1], a, t^.dflags.signed);
    pb := possible_rlens_of_operand(t^.opnd[2], b, t^.dflags.signed);
    if (t^.rlen = rlen) and (a in pa) and (b in pb) and (t^.op = 3) then
      return;
    if not ((rlen = 2) and (a = 2) and (b = 2)) then begin
      crush_disp_2(t^.opnd[1], a);
      crush_disp_2(t^.opnd[2], b);
      convert_lshf_to_mul(t);
    end;
    t^.rlen := rlen;
    t^.w26 := a;
    t^.w28 := b;
    t^.size := class_size[rlen] & 16#FFFF;
  end;

begin
  r := t;
  if t = nil then
    begin
      distrib_mul := r;
      return;
    end;
  m := g_opt_tree_ptr_t(t);
  if m^.kind <> 137 then
    begin
      distrib_mul := r;
      return;
    end;
  if not ((m^.op = 27) or (m^.op = 3)) then
    begin
      distrib_mul := r;
      return;
    end;
  if m^.flags * [1..4, 21] <> [] then
    begin
      distrib_mul := r;
      return;
    end;
  a := g_opt_tree_ptr_t(m^.opnd[1]);
  if (a^.kind = 137) and (a^.op = 18) then
    a := g_opt_tree_ptr_t(a^.opnd[1]);
  { a sum's variable operand put second }
  if (m^.op = 27) or (m^.op = 3) then
    if m^.opnd[2]^.kind in [77..87, 101, 200] then
      if (a^.kind = 137) and (a^.op = 1) then begin
        x := a^.opnd[1];
        if (x^.kind = 109) or (x^.kind = 110) or (x^.kind = 205) or
           (x^.kind = 147) then
          if a^.opnd[2]^.kind = 137 then begin
            a^.opnd[1] := a^.opnd[2];
            a^.opnd[2] := x;
          end;
      end;
  done := false;
  { (b * c' + v) * c }
  if (m^.op = 27) or (m^.op = 3) then
    if m^.opnd[2]^.kind in [77..87, 101, 200] then
      if (a^.kind = 137) and (a^.op = 1) then begin
        x := a^.opnd[2];
        b := g_opt_tree_ptr_t(a^.opnd[1]);
        if (x^.kind = 109) or (x^.kind = 110) or (x^.kind = 205) or
           (x^.kind = 147) then
          if b^.kind = 137 then
            if (b^.op = 27) or (b^.op = 3) then
              if b^.opnd[2]^.kind in [77..87, 101, 200] then begin
                x := b^.opnd[1];
                if (x^.kind = 109) or (x^.kind = 110) or (x^.kind = 205) or
                   (x^.kind = 147) then begin
                  if not no_enforce_parens_and_ucs_eq_1(m, a, true) then
                    begin
                      distrib_mul := r;
                      return;
                    end;
                  b := g_opt_tree_ptr_t(a^.opnd[1]);
                  if (m^.op = 3) and (b^.op = 27) then
                    convert_lshf_to_mul(b);
                  p := g_opt_tree_ptr_t(opt_str_$product_of(
                         m^.op, il_$node_ptr_t(b), m^.opnd[2], b^.rlen,
                         b^.w26, b^.w28,
                         b^.dflags.signed or m^.dflags.signed, b));
                  m^.opnd[1] := a^.opnd[2];
                  a^.opnd[1] := il_$node_ptr_t(p);
                  a^.opnd[2] := t;
                  m^.w26 := class_size[a^.rlen];
                  a^.rlen := m^.rlen;
                  a^.size := class_size[m^.rlen] & 16#FFFF;
                  fixup_rlen_of_mul(p, m^.rlen);
                  fixup_rlen_of_mul(m, m^.rlen);
                  r := il_$node_ptr_t(a);
                  done := true;
                end;
              end;
      end;
  { ((x << k1 + y) + z << k2) << k3 }
  if not done then
    if m^.op = 27 then
      if m^.opnd[2]^.kind in [77..87, 101, 200] then
        if (a^.kind = 137) and (a^.op = 1) then begin
          c := g_opt_tree_ptr_t(a^.opnd[2]);
          if (c^.kind = 137) and (c^.op = 27) then
            if c^.opnd[2]^.kind in [77..87, 101, 200] then
              if c^.opnd[1]^.kind in [109..110, 145..147] then begin
                b := g_opt_tree_ptr_t(a^.opnd[1]);
                if (b^.kind = 137) and (b^.op = 1) then begin
                  p := g_opt_tree_ptr_t(b^.opnd[1]);
                  if (p^.kind = 137) and (p^.op = 27) then
                    if p^.opnd[2]^.kind in [77..87, 101, 200] then
                      if p^.opnd[1]^.kind in [109..110, 145..147] then
                        if b^.opnd[2]^.kind in [109..110, 145..147] then begin
                          if no_enforce_parens_and_ucs_eq_1(m, a, false) then
                            begin
                              distrib_mul := r;
                              return;
                            end;
                          p^.opnd[2] := smcontk(81, p^.opnd[2]^.int_value +
                                                    m^.opnd[2]^.int_value);
                          c^.opnd[2] := smcontk(81, c^.opnd[2]^.int_value +
                                                    m^.opnd[2]^.int_value);
                          ops[1] := b^.opnd[2];
                          ops[2] := m^.opnd[2];
                          b^.opnd[2] := buildtreenode(27, m^.size, ops, 2);
                          x := b^.opnd[2];
                          if (g_opt_tree_ptr_t(x)^.rlen = 4) and
                             (a^.rlen = 2) then begin
                            a^.rlen := 4;
                            if b^.rlen = 2 then
                              b^.rlen := 4;
                          end;
                          r := il_$node_ptr_t(a);
                          done := true;
                        end;
                end;
              end;
        end;
  { (v1 + v2) << c under opt_on 20 }
  if not done then
    if 20 in cargs_$options.opt_on then begin
      a := g_opt_tree_ptr_t(m^.opnd[1]);
      if m^.op = 27 then
        if m^.opnd[2]^.kind in [77..87, 101, 200] then
          if (a^.kind = 137) and (a^.op = 1) then begin
            b := g_opt_tree_ptr_t(a^.opnd[1]);
            c := g_opt_tree_ptr_t(a^.opnd[2]);
            if ((b^.kind = 109) or (b^.kind = 110) or (b^.kind = 205) or
                (b^.kind = 147)) and
               ((c^.kind = 109) or (c^.kind = 110) or (c^.kind = 205) or
                (c^.kind = 147)) and
               not (21 in m^.flags) and not (21 in a^.flags) and
               (m^.uses = 1) and (a^.uses = 1) then
              if (b^.kind <> 147) or
                 (il_$node_ptr_t(b)^.xp[6]^.kind = 110) then
                if (c^.kind <> 147) or
                   (il_$node_ptr_t(c)^.xp[6]^.kind = 110) then begin
                  ops[1] := il_$node_ptr_t(c);
                  ops[2] := m^.opnd[2];
                  a^.opnd[2] := buildtreenode(27, m^.size, ops, 2);
                  m^.opnd[1] := a^.opnd[1];
                  a^.opnd[1] := t;
                  r := il_$node_ptr_t(a);
                end;
          end;
    end;
  distrib_mul := r;
end;

{ convert_exponentiation - t, a power (used once, not kept) of an
  operand used once by an integer constant or an integral real n of
  at most 6 multiplications (the highest bit's index - 1 + the bits
  set), becomes a chain of products of operator op (36 real, 3
  integer): the operand squared once for each bit, the squares of the
  bits set multiplied together, the last product made in t itself
  (its operand classes t's class).

  0x0DDFB2, 0x1F4 bytes: the exponent's kinds by the set of 0..207 at
  0x0DE1A6 ([77..89, 101, 200]); a real's `jsr fpp_$' 0x0074 0x00D0
  (trunc) and 0x00C4 0x00B4 (compared back, `bne' out;
  docs/dpc-gaps.md 7); the bits counted with a `dbf' loop of 32; the
  operands through frame copies for copy_tree. }

procedure convert_exponentiation(
    t: g_opt_tree_ptr_t;
    op: integer); options(val_param); internal;
var
  a: il_$node_ptr_t;
  e: il_$node_ptr_t;
  n: integer32;
  ns: om_bits_t;
  hi: integer32;
  bits: integer32;
  k: integer32;
  p: il_$node_ptr_t;
  acc: il_$node_ptr_t;
  tmp: il_$node_ptr_t;
  ops: array [1..2] of il_$node_ptr_t;
begin
  a := t^.opnd[1];
  if a^.kind in [137..138, 143, 145..147, 164, 171, 175, 189, 205] then
    if a^.xw[8] <> 1 then
      return;
  if t^.uses <> 1 then
    return;
  if 12 in t^.flags then
    return;
  e := t^.opnd[2];
  if not (e^.kind in [77..89, 101, 200]) then
    return;
  if e^.kind in [77..87, 101, 200] then
    n := e^.int_value
  else if (e^.kind = 89) or (e^.kind = 88) then begin
    n := trunc(e^.real_value);
    if n <> e^.real_value then
      return;
  end
  else
    return;
  hi := 0;
  bits := hi;
  ns := om_bits_t(n);
  for k := 0 to 31 do
    if k in ns then begin
        bits := bits + 1;
        hi := k;
      end;
  if hi - 1 < 0 then
    return;
  if hi - 1 + bits > 6 then
    return;
  t^.w26 := t^.rlen;
  t^.w28 := t^.rlen;
  p := t^.opnd[1];
  ops[1] := p;
  if 0 in ns then
    acc := p
  else
    acc := nil;
  k := 1;
  while k <= hi do begin
    if (k = hi) and (bits = 1) then
      acc := p
    else begin
      tmp := p;
      ops[2] := copy_tree(tmp);
      adjust_uc(ops[2], 1);
      p := buildtreenode(op, t^.size, ops, 2);
    end;
    ops[1] := p;
    if k in ns then
      if acc = nil then
        acc := p
      else begin
        tmp := acc;
        ops[2] := copy_tree(tmp);
        acc := tmp;
        adjust_uc(ops[2], 1);
        if k < hi then
          acc := buildtreenode(op, t^.size, ops, 2)
        else begin
          t^.op := op;
          t^.opnd[1] := ops[1];
          t^.opnd[2] := ops[2];
        end;
      end;
    k := k + 1;
  end;
end;

{ dwalk - the trees below t (by address) walked bottom up: a tree's
  operands, then the tree distributed (distrib_mul) when not marked
  (flags 1..4); a division's (13) dividend class taken from its
  divisor tree's; a power (42 real, 43 integer) turned into products;
  an indexed reference's index at least as used as the reference and
  its class the index tree's.

  0x0DE1C0, 0x16E bytes: recursive; the kinds compared in turn. }

procedure dwalk(
    var t: il_$node_ptr_t); internal;
var
  k: integer;
  m: g_opt_tree_ptr_t;
  x: g_opt_tree_ptr_t;
begin
  if t <> nil then
    case t^.kind of
      143, 137: begin
        for k := 1 to g_opt_tree_ptr_t(t)^.count do
          dwalk(g_opt_tree_ptr_t(t)^.opnd[k]);
        if (t^.xl[1] & 30) = 0 then
          t := distrib_mul(t);
        m := g_opt_tree_ptr_t(t);
        if m^.op = 13 then begin
          x := g_opt_tree_ptr_t(m^.opnd[2]);
          if x^.kind = 137 then
            if x^.rlen <> m^.w26 then
              m^.w26 := x^.rlen;
        end;
        m := g_opt_tree_ptr_t(t);
        if (t^.xl[1] & 30) = 0 then
          if m^.op = 42 then
            convert_exponentiation(m, 36)
          else if m^.op = 43 then
            convert_exponentiation(m, 3);
      end;
      205, 147, 146:
        dwalk(t^.xp[6]);
      145: begin
        dwalk(t^.xp[6]);
        dwalk(t^.xp[9]);
        x := g_opt_tree_ptr_t(t^.xp[9]);
        if x^.kind = 137 then
          if t^.xw[8] > x^.uses then
            x^.uses := t^.xw[8];
        x := g_opt_tree_ptr_t(t^.xp[9]);
        if x^.kind = 137 then
          if x^.rlen <> t^.xw[21] then
            t^.xw[21] := x^.rlen;
      end;
      164: begin
        dwalk(t^.xp[5]);
        dwalk(t^.xp[6]);
      end;
      175:
        dwalk(t^.xp[4]);
      171:
        dwalk(t^.xp[4]);
      otherwise
        ;
    end;
end;

{ distribute - the trees of each top-level statement walked (dwalk): an
  evaluation's operands, an assignment's three, a conditional branch's
  condition, a 151's operand; a routine's entry (148) of other than a
  167 or 172 sets il_180.

  0x0DE32E, 0xD4 bytes: a jump table on the kind (139..151). }

procedure distribute; internal;
var
  s: g_opt_stmt_ptr_t;
  k: integer;
begin
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    case s^.kind of
      139:
        for k := 1 to s^.eval_count do
          dwalk(s^.eval_opnd[k]);
      140: begin
        dwalk(s^.asg_rhs);
        dwalk(s^.asg_lhs);
        dwalk(s^.asg_x);
      end;
      142:
        dwalk(s^.br_cond);
      148:
        if (s^.x48^.kind <> 167) and (s^.x48^.kind <> 172) then
          il_180 := s^.x48;
      151:
        if s^.x48 <> nil then
          dwalk(s^.x48);
      otherwise
        ;
    end;
    s := s^.next;
  end;
end;

{ reviseuses - after strength reduction, each region statement from
  opt_region to runbackend_16 (not a branch, label, non-local branch
  or deleted statement) that still has variable v in its set but no
  longer uses it (no chain cut, flags 16#200, and walkuses does not
  find opt_region's node of v in it) loses v: its use-def chain is cut
  (each defining statement's entry of v flagged 16#100) and v taken
  out of its set.

  0x0DE402, 0x196 bytes: A5 loaded; the entry's address kept in
  (-96,A6) and passed to walkuses by address; the set's element
  removed through a 32-byte frame set (`not.l; and.l'); the test of
  v in the set range-checked (docs/dpc-gaps.md 29). }

procedure reviseuses;
var
  i: g_opt_num_t;
  v: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
  node: il_$node_ptr_t;
  used: boolean;
  c: g_opt_chain_ptr_t;
  one: g_opt_varset_t;
begin
  if il_180^.xw[145] <> 0 then
    for i := opt_region to runbackend_16 do begin
      s := opt_4009c[i];
      if (s^.kind <> 141) and (s^.kind <> 144) and not s^.hdr.deleted and
         (s^.kind <> 150) then
        for v := 1 to il_180^.xw[145] do begin
          s := opt_4009c[i];
          if s^.vset <> nil then
            if v in s^.vset^ then begin
              node := opt_4009c[opt_region]^.vars^[v]^.node;
              if (opt_4009c[i]^.vars^[v]^.flags & 16#200) <> 0 then
                used := true
              else
                used := walkuses(opt_4009c[i], node);
              if not used then begin
                c := opt_4009c[i]^.vars^[v]^.ud;
                while c <> nil do begin
                  c^.stmt^.vars^[v]^.flags := c^.stmt^.vars^[v]^.flags ! 16#100;
                  c := c^.next;
                end;
                opt_4009c[i]^.vars^[v]^.ud := nil;
                one := [];
                one := one + [v];
                opt_4009c[i]^.vset^ := opt_4009c[i]^.vset^ - one;
              end;
            end;
        end;
    end;
end;

{ opt_main_$strip_all_use_def_obs - the use and definition statements
  (188) of the routine from opt_region's entry to the end of the
  outermost routine (149, not of a 172) unlinked and marked deleted;
  the next statement takes over a line and a block start of one.

  0x0DE598, 0x98 bytes: no A5 load (internal). }

procedure opt_main_$strip_all_use_def_obs; internal;
var
  s: g_opt_stmt_ptr_t;
  p: g_opt_stmt_ptr_t;
  n: g_opt_stmt_ptr_t;
begin
  s := opt_4009c[opt_region];
  while s <> nil do begin
    if s^.kind = 188 then begin
      s^.hdr.deleted := true;
      if s^.line <> spos_$null_position then
        if s^.next^.line = spos_$null_position then
          s^.next^.line := s^.line;
      p := s^.prev;
      n := s^.next;
      p^.next := n;
      n^.prev := p;
      if s^.hdr.first then
        n^.hdr.first := true;
      s := n;
    end
    else
      s := s^.next;
    if s <> nil then
      if s^.kind = 149 then
        if s^.x48^.kind <> 172 then
          return;
  end;
end;

{ opt_main_$symidx_of_varn_or_fsym - see g_opt.ins.pas: a variable's
  number (+74 of a 109, +16 of a 110), 0 for other nodes.

  0x0DE630, 0x5C bytes: A5 loaded; the result a word. }

function opt_main_$symidx_of_varn_or_fsym(
    t: il_$node_ptr_t): integer;
var
  k: integer;
begin
  k := 0;
  if assert_is_a_variable(t) then
    case t^.kind of
      109:
        k := t^.xw[37];
      110:
        k := t^.xw[8];
      otherwise
        bug_check('OPT_MAIN_$SYMIDX_OF_VAR_OR_FSYM -- p not a var_name or fortran_symbol%.');
    end;
  opt_main_$symidx_of_varn_or_fsym := k;
end;

{ create_use_def_ob - a use or definition statement (188, 4 bytes more
  than its kind's) of variable v for statement s: mode 0 and 1 put it
  before s (taking over s's line and block start; mode 0 its +45 from
  the statement before s), 2 after s, 3 after the 188s of positive
  argument number that follow s; its arg_stmt, arg_call and arg_num
  (num) set, marked quiet (+41 bit 5), its vnum v's number when that is
  not negative.

  0x0DE6D4, 0x174 bytes: an error 9 when the node cannot be made; the
  statement placed after in A1 (left as it was for another mode); the
  block start moved as one 16-bit field (`andi.w #-3', `andi.w #2'). }

procedure create_use_def_ob(
    s: g_opt_stmt_ptr_t;
    call: il_$node_ptr_t;
    at: il_$node_ptr_t;
    v: il_$node_ptr_t;
    num: integer;
    mode: integer); options(val_param); internal;
var
  n: g_opt_stmt_ptr_t;
  p: g_opt_stmt_ptr_t;
  k: integer;
begin
  n := g_opt_stmt_ptr_t(add_node_$new_top_level(188, 4));
  if n = nil then
    cgerr_no_source(9, 0);
  case mode of
    2, 1, 0:
      p := s;
    3: begin
      p := s^.next;
      while (p^.kind = 188) and (p^.arg_num > 0) do
        p := p^.next;
      p := p^.prev;
    end;
    otherwise
      ;
  end;
  n^.x48 := v;
  n^.arg_stmt := at;
  n^.hdr.b5 := true;
  n^.hdr.b45 := p^.hdr.b45;
  n^.arg_call := call;
  n^.arg_num := num;
  case mode of
    0, 1: begin
      if mode = 0 then
        n^.hdr.b45 := s^.prev^.hdr.b45;
      n^.line := p^.line;
      p^.line := spos_$null_position;
      n^.hdr.first := p^.hdr.first;
      p^.hdr.first := false;
      n^.prev := p^.prev;
      n^.next := p;
      p^.prev^.next := n;
      p^.prev := n;
    end;
    3, 2: begin
      n^.line := spos_$null_position;
      n^.hdr.first := false;
      n^.prev := p;
      n^.next := p^.next;
      p^.next^.prev := n;
      p^.next := n;
    end;
    otherwise
      ;
  end;
  k := opt_main_$symidx_of_varn_or_fsym(v);
  if k >= 0 then
    n^.hdr.vnum := k;
end;

{ add_use_defs_for_call_site - unless opt_track_lines, variable v
  passed as argument num (from 1; 0 for a call's effect on statics) of
  call (in statement s) gets its use (unless passed by value, class 3:
  mode 1; mode 0 for a parameter, +72 = 5) and, when the argument may
  be changed (classes 1, 3, 4) and s does not store it or an alias of
  it, its definition after s (mode 3, -num); not when a later argument
  passes it too in a conflicting class (om_param_conflicts) or the call
  is through a 159.

  0x0DE848, 0x192 bytes: the argument's class in D5 (left as it was
  when num is 0); the later arguments' variables compared directly, a
  147's +24, a 164's +20; num 0 pushed with the mode as one longword
  (`clr.l -(SP)'); `btst' of the class in 26. }

procedure add_use_defs_for_call_site(
    s: g_opt_stmt_ptr_t;
    call: g_opt_tree_ptr_t;
    at: il_$node_ptr_t;
    v: il_$node_ptr_t;
    num: integer); options(val_param); internal;
var
  cls: integer;
  cnt: integer;
  k: integer;
  x: il_$node_ptr_t;
  match: boolean;
  da: alias_$desc_t;
  db: alias_$desc_t;
begin
  if opt_track_lines then
    return;
  if num > 0 then
    cls := paramclass(il_$node_ptr_t(call), num - 1);
  if call = nil then
    cnt := 0
  else
    cnt := call^.count;
  for k := num + 1 to cnt do begin
    x := call^.opnd[k];
    case x^.kind of
      110, 109:
        match := x = v;
      147:
        match := x^.xp[6] = v;
      164:
        match := x^.xp[5] = v;
      otherwise
        match := false;
    end;
    if match then begin
      if call^.opnd[1]^.kind = 159 then
        return;
      if paramclass(il_$node_ptr_t(call), k - 1) in om_param_conflicts[cls] then
        return;
    end;
  end;
  if num = 0 then
    create_use_def_ob(s, il_$node_ptr_t(call), at, v, 0, 0)
  else begin
    if v <> nil then begin
      if (v^.kind = 109) and (v^.xw[36] = 5) then
        create_use_def_ob(s, il_$node_ptr_t(call), at, v, num, 0)
      else if cls <> 3 then
        create_use_def_ob(s, il_$node_ptr_t(call), at, v, num, 1);
    end
    else if cls <> 3 then
      create_use_def_ob(s, il_$node_ptr_t(call), at, v, num, 1);
    if s^.kind = 140 then begin
      if s^.asg_lhs = v then
        return;
      alias_$alias_desc_with_size(s^.asg_lhs, s^.asg_size, da);
      alias_$alias_desc_with_size(v, s^.asg_size, db);
      if alias_$related(da, db) then
        return;
    end;
    if cls in [1, 3, 4] then
      create_use_def_ob(s, il_$node_ptr_t(call), at, v, -num, 3);
  end;
end;

{ opt_main_$var_is_param_of_routine - the number (from 1) of v among
  routine r's parameters (+12: a count at +10, 12-byte entries from
  +12), -1 when it is not one.

  0x0DE9DA, 0x5A bytes: A5 loaded; the result a word. }

function opt_main_$var_is_param_of_routine(
    v: il_$node_ptr_t;
    r: il_$node_ptr_t): integer; options(val_param);
var
  p: om_params_ptr_t;
  k: integer;
begin
  opt_main_$var_is_param_of_routine := -1;
  if r^.xp[3] <> nil then begin
    p := om_params_ptr_t(r^.xp[3]);
    for k := 1 to p^.count do
      if p^.parm[k].v = v then begin
        opt_main_$var_is_param_of_routine := k;
        return;
      end;
  end;
end;

{ assert_defined_on_entry - variable v of block blk (its type te) may
  hold a value on entry to the routine rtn (so a definition of it is
  made there): in Fortran (blk's language 2) a parameter (storage class
  5 at +11 bits 7..4 and among rtn's parameters), a symbol of +44 bit
  3, of a static class (3482: 1, 3, 4, 7, 8, 10, 11) outside a main
  program (105) or under flags_286 element 2, or of class 3, 4, 8, 10
  or 11 (3352); elsewhere a variable (109) not of a routine's type
  (107): a parameter (+72 = 5) not an array (121), an array not of
  3 dimensions' kind (+44) or whose type is ranged or a 135, 134 or
  130, an address-taken one (+32 bits 6, 8), a static outside a main
  program, or of type 135.

  0x0DEA34, 0x13E bytes: the classes by `btst' in the words 3482 and
  3352. }

function assert_defined_on_entry(
    v: il_$node_ptr_t;
    in te: il_utils_$type_info_t;
    blk: il_$node_ptr_t;
    rtn: il_$node_ptr_t): boolean; options(val_param); internal;
var
  cls: integer;
  t: il_$node_ptr_t;
  k: integer;
begin
  if rshft(ord(blk^.xc[377]) & 16#70, 4) = 2 then begin
    cls := rshft(ord(v^.xc[11]) & 16#F0, 4);
    if cls = 5 then
      if opt_main_$var_is_param_of_routine(v, rtn) >= 0 then begin
        assert_defined_on_entry := true;
        return;
      end;
    if (ord(v^.xc[44]) & 8) <> 0 then begin
      assert_defined_on_entry := true;
      return;
    end;
    if cls in [1, 3, 4, 7, 8, 10, 11] then
      if (blk^.kind <> 105) or (2 in cargs_$options.flags_286) then begin
        assert_defined_on_entry := true;
        return;
      end;
    assert_defined_on_entry := cls in [3, 4, 8, 10, 11];
  end
  else if v^.kind = 109 then begin
    t := v^.xp[7];
    assert_defined_on_entry := true;
    if t^.kind = 107 then begin
      assert_defined_on_entry := false;
      return;
    end;
    if (v^.xw[36] = 5) and (t^.kind <> 121) then
      return;
    if t^.kind = 121 then begin
      if t^.xw[22] <> 3 then
        return;
      if (ord(te.c[25]) & 16#40) = 0 then
        if not ((te.tp^.kind = 135) or (te.tp^.kind = 134) or
                (te.tp^.kind = 130)) then
          return;
    end;
    if (v^.xw[36] = 5) and (t^.kind = 121) then
      if (ord(te.c[25]) & 16#40) <> 0 then
        return;
    if (v^.xl[8] & 320) <> 0 then
      return;
    k := v^.xw[36];
    if k in [1, 3, 4, 7, 8, 10, 11] then
      if blk^.kind <> 105 then
        return;
    assert_defined_on_entry := t^.kind = 135;
  end
  else
    assert_defined_on_entry := false;
end;

{ add_use_defs_for_statics_and_params - for routine rtn and the blocks
  (172) nested in it (a 167's +148 next): each variable that may hold a
  value on entry gets a definition (create_use_def_ob, mode 0) before
  the routine's first statement after its entry (from +100, past
  labels and evaluations; at the routine's entry statement); in
  Fortran a symbol of class 3 (+44 bits 7..4) without +58 and +32 in a
  routine (not a 172), elsewhere a variable (109, not of a routine's
  type) that is a parameter array, ranged, of type 123, 134, 130 or of
  storage class 1 (+72).  Nothing under opt_track_lines.

  0x0DEB72, 0x19A bytes: the type in a 32-byte frame record (passed
  to assert_defined_on_entry even when type_exp was not called). }

procedure add_use_defs_for_statics_and_params(
    rtn: il_$node_ptr_t); options(val_param); internal;
var
  s: g_opt_stmt_ptr_t;
  first: g_opt_stmt_ptr_t;
  b: il_$node_ptr_t;
  v: il_$node_ptr_t;
  te: il_utils_$type_info_t;
begin
  s := g_opt_stmt_ptr_t(rtn^.xp[25]);
  while (s^.kind = 144) or (s^.kind = 139) do
    s := s^.next;
  if s^.kind = 148 then
    first := s^.next
  else
    first := s;
  b := rtn;
  while b <> nil do begin
    v := b^.xp[4];
    while v <> nil do
      if rshft(ord(rtn^.xc[377]) & 16#70, 4) = 2 then begin
        if not opt_track_lines then
          if rshft(ord(v^.xc[44]) & 16#F0, 4) = 3 then
            if assert_defined_on_entry(v, te, rtn, rtn) then
              if (v^.xl2[14] = 0) and (v^.xp[8] = nil) and
                 (rtn^.kind <> 172) then
                create_use_def_ob(first, nil, il_$node_ptr_t(s), v, 0, 0);
        v := v^.xp[1];
      end
      else begin
        if not opt_track_lines and (v^.kind = 109) then
          if v^.xp[7]^.kind <> 107 then begin
            type_exp(v, addr(te));
            if ((v^.xw[36] = 5) and (v^.xp[7]^.kind = 121)) or
               ((ord(te.c[25]) & 16#40) <> 0) or
               (te.tp^.kind = 123) or (te.tp^.kind = 134) or
               (te.tp^.kind = 130) or (v^.xw[36] = 1) then
              if assert_defined_on_entry(v, te, rtn, nil) then
                create_use_def_ob(first, nil, il_$node_ptr_t(s), v, 0, 0);
          end;
        v := v^.xp[4];
      end;
    if b^.kind = 167 then
      b := b^.xp[37]
    else if b^.xp[1] = nil then
      b := nil
    else if rtn^.kind = 172 then
      b := nil
    else if b^.xp[1]^.kind = 172 then
      b := b^.xp[1]
    else
      b := nil;
  end;
end;

{ add_def_for_params_at_routine_entry - at a routine's entry s (148, not
  of a 172, not a Fortran statement function), the definitions of its
  statics and parameters and of its nested blocks' (172).  Nothing
  under opt_track_lines.

  0x0DED0C, 0x56 bytes. }

procedure add_def_for_params_at_routine_entry(
    s: g_opt_stmt_ptr_t); options(val_param); internal;
var
  r: il_$node_ptr_t;
begin
  if not opt_track_lines then
    if s^.kind = 148 then
      if s^.x48^.kind <> 172 then
        if not opt_main_$is_fortran_asf(s) then begin
          r := s^.x48;
          repeat
            add_use_defs_for_statics_and_params(r);
            r := r^.xp[1];
          until (r = nil) or (r^.kind <> 172);
        end;
end;

{ use_def_proc - a use or definition statement s (188) of a variable of
  opt_region's table (number v) applied to the statement at hand
  (om_stmt_num's entry e): a definition without a call (a static's or
  parameter's) makes e assign v; a use (argument number positive) adds
  v to e's set; for a definition after a call (not of a reference: 146,
  145, 147), e assigns v when the argument may be changed (classes 1,
  3, 4), or for a call through a 159, when the call may change v's
  storage (alias_$related_call) or the number is negative.  Nothing
  under opt_track_lines.

  0x0DED62, 0x184 bytes: the set's element added through a 32-byte
  frame set; a 159's case tests the number twice (`tst.w; bne' then
  `bge'). }

procedure use_def_proc(
    s: g_opt_stmt_ptr_t); options(val_param); internal;
var
  v: integer;
  e: g_opt_stmt_ptr_t;
  x: il_$node_ptr_t;
  one: g_opt_varset_t;
  d: alias_$desc_t;
begin
  if opt_track_lines then
    return;
  if s^.kind <> 188 then
    return;
  v := find_var(s^.x48);
  if v = 0 then
    return;
  if (s^.arg_call = nil) and (s^.arg_num = 0) and (s^.x48 <> nil) then begin
    opt_4009c[om_stmt_num]^.hdr.vnum := v;
    return;
  end;
  e := opt_4009c[om_stmt_num];
  if s^.arg_stmt = nil then
    return;
  if s^.arg_num > 0 then begin
    opt_main_$ensure_var_set(e^.vset);
    one := [];
    one := one + [v];
    e^.vset^ := e^.vset^ + one;
    if s^.arg_num > 0 then
      return;
  end;
  x := s^.x48;
  if (x^.kind = 146) or (x^.kind = 145) or (x^.kind = 147) then
    return;
  if g_opt_tree_ptr_t(s^.arg_call)^.opnd[1]^.kind <> 159 then begin
    if paramclass(s^.arg_call, -s^.arg_num - 1) in [1, 3, 4] then
      e^.hdr.vnum := v;
  end
  else if s^.arg_num = 0 then begin
    if e^.hdr.vnum <> v then begin
      alias_$basic_alias_desc(opt_4009c[opt_region]^.vars^[v]^.node, d);
      if alias_$related_call(d, s^.arg_call) then
        e^.hdr.vnum := v;
    end;
  end
  else if s^.arg_num < 0 then
    e^.hdr.vnum := v;
end;

{ opt_main_$is_fortran_asf - s is the entry (148) of a Fortran
  statement function: language 2, +376 bit 3, not a 172.

  0x0DEEE6, 0x4C bytes: A5 loaded. }

function opt_main_$is_fortran_asf(
    s: g_opt_stmt_ptr_t): boolean; options(val_param);
var
  r: il_$node_ptr_t;
begin
  opt_main_$is_fortran_asf := false;
  if s <> nil then
    if s^.kind = 148 then begin
      r := s^.x48;
      if rshft(ord(r^.xc[377]) & 16#70, 4) = 2 then
        if (ord(r^.xc[376]) & 8) <> 0 then
          opt_main_$is_fortran_asf := r^.kind <> 172;
    end;
end;

{ init_opt_info_for_vars - at a routine's entry s (unless
  opt_track_lines): the entry heads the region (opt_region, its entry
  mark; il_180 its routine); the first time (first, by address) lo (by
  address) takes n; the variables' numbers cleared (a 110's +16, a
  109's +74 outside Fortran), counted (il_utl_$count_vars: om_nvars,
  the routine's +290; opt_max_vars the largest), and numbered from 1
  by class (il_utl_$classify_variable: 4..6 a variable's +74, 13..15 a
  Fortran symbol's +16 when not yet numbered, with +25 bit 5 when it
  has +32) with an entry in the region's table (18 bytes from the
  var_chain pool: node, flags 4 when on the routine's +384 chain, 16#80
  when defined on entry); the numbers left negative cleared after.

  0x0DEF32, 0x384 bytes: a jump table on the class (0..15); the walks
  over a Fortran routine's 109s do not advance (the image's loops test
  the language before stepping): kept. }

procedure init_opt_info_for_vars(
    var first: boolean;
    var lo: g_opt_num_t;
    s: g_opt_stmt_ptr_t;
    n: g_opt_num_t); options(val_param); internal;
var
  r: il_$node_ptr_t;
  v: il_$node_ptr_t;
  next: il_$node_ptr_t;
  p: il_$node_ptr_t;
  e: g_opt_stmt_ptr_t;
  x: g_opt_var_ptr_t;
  k: integer;
  nv: integer;
  ok: boolean;
  te: il_utils_$type_info_t;
begin
  if opt_track_lines then
    return;
  if first then begin
    lo := n;
    first := false;
  end;
  opt_region := om_stmt_num;
  opt_4009c[om_stmt_num]^.hdr.entry := true;
  il_180 := s^.x48;
  r := il_180;
  while r <> nil do begin
    v := r^.xp[4];
    while v <> nil do
      if v^.kind = 110 then begin
        v^.xw[8] := 0;
        v := v^.xp[1];
      end
      else if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then begin
        if v^.kind = 109 then
          v^.xw[37] := 0;
        v := v^.xp[4];
      end;
    if r^.xp[1] = nil then
      r := nil
    else if r^.xp[1]^.kind = 172 then
      r := r^.xp[1]
    else
      r := nil;
  end;
  nv := il_utl_$count_vars(s^.x48);
  om_nvars := nv;
  s^.x48^.xw[145] := nv;
  e := opt_4009c[om_stmt_num];
  if nv > 0 then
    e^.vars := mem_$alloc(opt_main_18, nv * 4)
  else
    e^.vars := nil;
  e^.hdr.vnum := 0;
  if e^.vset <> nil then
    e^.vset^ := [];
  il_180^.xw[145] := om_nvars;
  if om_nvars = 0 then
    return;
  nv := om_nvars;
  if nv < opt_max_vars then
    nv := opt_max_vars;
  opt_max_vars := nv;
  k := 1;
  r := il_180;
  while r <> nil do begin
    v := r^.xp[4];
    while (k <= om_nvars) and (v <> nil) and (om_nvars > 0) do begin
      ok := false;
      if v^.kind = 109 then
        if (v^.xl[8] & 16#201101) = 0 then
          type_exp(v, addr(te));
      case il_utl_$classify_variable(v, te, r, next) of
        4, 5, 6: begin
          v^.xw[37] := k;
          opt_4009c[om_stmt_num]^.vars^[k] := mem_$alloc(opt_main_18, 18);
          ok := true;
        end;
        13, 14, 15:
          if v^.xw[8] <= 0 then begin
            v^.xw[8] := k;
            opt_4009c[om_stmt_num]^.vars^[k] := mem_$alloc(opt_main_18, 18);
            ok := true;
            if v^.xl[8] <> 0 then
              v^.xc[25] := chr(ord(v^.xc[25]) ! 16#20);
          end;
        otherwise
          ;
      end;
      if ok then begin
        x := opt_4009c[om_stmt_num]^.vars^[k];
        x^.node := v;
        x^.unused_4 := 0;
        x^.count := 0;
        x^.ud := nil;
        x^.du := nil;
        x^.flags := 0;
        p := om_blk_ptr_t(r)^.vlist;
        while p <> nil do begin
          if p^.xp[1] = v then
            x^.flags := 4;
          p := p^.xp[2];
        end;
        if assert_defined_on_entry(v, te, il_180, il_180) then
          x^.flags := x^.flags ! 16#80;
        k := k + 1;
      end;
      v := next;
    end;
    if v <> nil then
      r := nil
    else if r^.xp[1] = nil then
      r := nil
    else if r^.xp[1]^.kind = 172 then
      r := r^.xp[1]
    else
      r := nil;
    if k > om_nvars then
      exit;
  end;
  r := il_180;
  while r <> nil do begin
    v := r^.xp[4];
    while v <> nil do
      if v^.kind = 110 then begin
        if v^.xw[8] < 0 then
          v^.xw[8] := 0;
        v := v^.xp[1];
      end
      else if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then begin
        if v^.kind = 109 then
          if v^.xw[37] < 0 then
            v^.xw[37] := 0;
        v := v^.xp[4];
      end;
    r := r^.xp[1];
  end;
end;

{ fixup_blocks - see g_opt.ins.pas: the region statements from
  opt_region's on (skipping deleted entries, and marking deleted those
  passed over: entries left by statements that are gone, up to a
  strength reduction temporary's assignment) matched again with the
  routine's statements: each block start's block gets its first
  statement and every statement's block its last; error 3 when the
  entries run past runbackend_16; it stops at a routine's entry label
  (kind 13) followed by an entry of other than a 167 or 172.

  0x0DF2B6, 0x1A2 bytes: A5 loaded; runbackend_16's address kept in
  D4; a register's (191) and a strength reduction temporary's
  assignment have no entry of their own. }

procedure fixup_blocks;
var
  r: g_opt_num_t;
  s: g_opt_stmt_ptr_t;
  b: g_opt_block_ptr_t;
  x: il_$node_ptr_t;
begin
  r := opt_region;
  s := opt_4009c[r];
  b := s^.block;
  while s <> nil do begin
    while opt_4009c[r]^.hdr.deleted do
      r := r + 1;
    if s^.kind <> 191 then
      while (r < runbackend_16) and (opt_4009c[r] <> s) do begin
        if s^.kind = 140 then
          if il_utils_$is_strength_reduction_temp(s^.asg_lhs) then
            exit;
        if r > opt_region then
          opt_4009c[r]^.hdr.deleted := true;
        r := r + 1;
      end;
    if r > runbackend_16 then
      cgerr(3, opt_4009c[runbackend_16]^.line, opt_4009c[runbackend_16]);
    if s^.hdr.first then begin
      b := opt_4009c[r]^.block;
      b^.first_stmt := s;
    end;
    if s^.kind <> 191 then
      if s^.kind <> 140 then
        r := r + 1
      else if s^.hdr.region <> 0 then
        r := r + 1
      else begin
        x := s^.asg_lhs;
        if not ((x^.kind = 110) or (x^.kind = 109)) then
          r := r + 1
        else if not il_utils_$is_strength_reduction_temp(x) then
          r := r + 1;
      end;
    b^.last_stmt := s;
    s := s^.next;
    if assert_is_label(il_$node_ptr_t(s)) then
      if rshft(ord(il_$node_ptr_t(s)^.xc[72]) & 16#3E, 1) = 13 then
        if s^.next^.kind = 148 then
          if (s^.next^.x48^.kind <> 167) and
             (s^.next^.x48^.kind <> 172) then
            return;
  end;
end;
