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

{ REG_SAVE_$REGISTERS_PRESERVED_BY_STATEMENT - reg_save.pas 0x0ED458
  (cc.a88k target_at_dummies): the registers top-level statement s
  preserves (no insert has the heading). }
function reg_save_$registers_preserved_by_statement(
    s: il_$node_ptr_t): reg_save_$regs_t; options(val_param); extern;

define
  om_succ_pool, om_blocks_pool, om_hoist_pool, om_nodes_pool,
  om_varset_pool;
  om_complex_size := [8, 12];
  om_class_bytes := [0, 2, 4, 4, 8, 8, 1, 4, 4, 0];
  opt_main_$ensure_var_set;

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
