{ isc_main - the ISC's driver (a DSEE derived object of the iscg_input
  description; cc.a88k only): the solutions and inherited attributes
  allocated, duplicated and preserved, the solution lists, the
  statements selected (pass 1, the choice, pass 2 between
  begin_statement and end_statement), and the phase's entry points
  (isc_$begin_compilation, isc_$begin_routine, isc_$end_routine,
  isc_$end_compilation: at_backend's phase table) with their metering
  under sw3.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x0D92C8  new_inherited_attributes
    --------  0x0D9318  new_solution
    --------  0x0D93FC  duplicate_solution
    --------  0x0D945E  duplicate_inherited_attributes
    --------  0x0D94A6  preserve_solution
    --------  0x0D97E6  solution_list$new
    --------  0x0D980C  solution_list$append
    --------  0x0D989A  solution_list$delete
    --------  0x0D9938  solution_list$empty
    --------  0x0D9992  solution_list$preserve
    --------  0x0D9A52  isc_$begin_compilation
    --------  0x0D9B92  isc_$initialize_routine
    --------  0x0D9C6C  isc_$process_statement
    --------  0x0D9DDC  apply_pass_1_and_choose_to_list
    --------  0x0DA0BE  apply_pass_2_to_list
    --------  0x0DA1E4  isc_$begin_routine
    --------  0x0DA27E  isc_$end_routine
    --------  0x0DB25A  isc_$end_compilation
  A5 0x44E9B0: the module's data, im_rule_has_fields (+0x0, by rule
  1..563: whether preserve_solution copies the rule's own fields; the
  generator's table) and a longword at +0x234 no instruction reads.
  (-4,A5) is the run time's input (isc_$initialize_routine reads the
  debug line from it), (-8,A5) its output.  The cells the module
  counts and meters in are isc_user_routines' (isc_var_externs.ins.pas:
  +0x2DC .. +0x308, +0x350; the names in the comments are the metering
  printout's).

  The span after isc_$end_routine (0x0DA5B4 .. 0x0DB25A) holds its
  strings and il$t's name table (0x0DA74A); no code.

  The writes and the read are dpc gap 4 (docs/dpc-gaps.md 4).

  Not known from the original: the parameters' and locals' names, the
  module data's names. }
module isc_main;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas';
%include 'lang2/source/isc/isc_consts.ins.pas';
%include 'lang2/source/isc/isc_types.ins.pas';
%include 'lang2/source/isc/isc_routine_externs.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';

type
  { A heap's first five longwords, as new_solution and
    duplicate_solution compare a heap with the ISC heap (`cmpm.l' five
    times). }
  im_heap_view_ptr_t = ^im_heap_view_t;
  im_heap_view_t = array [1..5] of integer32;

  { A solution's pointer at +358 (rules 114 and 115: not a longword
    boundary of isc_solution_t's fields). }
  im_sol358_ptr_t = ^im_sol358_t;
  im_sol358_t = record
    x0: array [0..357] of char;         { +0 }
    f358: isc_solution_ptr_t;           { +358 }
  end;

  { A routine record's first statement (rtn_t's +20). }
  im_rtn_view_ptr_t = ^im_rtn_view_t;
  im_rtn_view_t = record
    x0: array [0..19] of char;          { +0 }
    first: isc_node_ptr_t;              { +20 }
  end;

var
  im_rule_has_fields: array [1..563] of boolean := [
      11 of false, true, 101 of false, true, true, 61 of false, true,
      1 of false, true, 1 of false, true, 4 of false, true, 75 of false,
      true, 11 of false, true, true, 14 of false, true, 1 of false, true,
      8 of false, true, 2 of false, true, 39 of false, true, 30 of false,
      true, 1 of false, true, true, true, 38 of false, true, 3 of false,
      true, true, 21 of false, true, 2 of false, true, 25 of false, true,
      4 of false, true, 62 of false, true, 5 of false, true, true, true,
      13 of false];
  im_unused_234: integer32 := 0;

{ same_heap - whether heap's first five longwords are the ISC heap's
  (new_solution's and duplicate_solution's test, inline in the image:
  `moveq #4,D0; cmpm.l (A3)+,(A1)+; dbne D0').  The reconstruction's
  helper. }

function same_heap(
    in heap: mrh_$heap_t): boolean; internal;
var
  a: im_heap_view_ptr_t;
  b: im_heap_view_ptr_t;
  i: integer;
  same: boolean;
begin
  a := im_heap_view_ptr_t(addr(heap));
  b := im_heap_view_ptr_t(addr(isc_heap));
  same := true;
  i := 1;
  while same and (i <= 5) do begin
    same := a^[i] = b^[i];
    i := i + 1;
  end;
  same_heap := same;
end;

{ new_inherited_attributes - 40 bytes from heap for node: node and
  stmt node, precision and available 32, +36 cleared, arith 1
  (arith_integer); the rest as the heap gives it.

  0x0D92C8, 0x50 bytes: heap 8 (by address), node 12; A0. }

function new_inherited_attributes;
var
  a: inherited_attributes_ptr_t;
begin
  a := mrh_$alloc(heap, 40);
  a^.il := node;
  a^.original_il := node;
  a^.fetch_precision := 32;
  a^.parent_il_kind := chr(0);
  a^.f38.required_arithmetic := 1;
  a^.required_precision := 32;
  new_inherited_attributes := a;
end;

{ new_solution - 432 bytes from heap: kind, number_of_children
  (nchildren: bug_check above 5, with inh's source line),
  inherited_attributes (inh), il (sym), il_kind; field_precision 32,
  is_destroyable and is_entire_object set, evaluation_order 1 (+96
  and +98 as one longword 16#10000; il_kind after), base_register and
  index_register isc_user_routines_31c; counted (+0x2EC) when from the
  ISC heap.

  0x0D9318, 0xAA bytes: heap 8, kind a word at 12, nchildren a word at
  14, inh 16, sym 20, il_kind a word at 24; +108 cleared before the
  kind is stored; A0. }

function new_solution;
var
  s: isc_solution_ptr_t;
begin
  if nchildren > 5 then
    bug_check('ISC: source line %wd: new_solution: too many children.%$', inh^.pos);
  s := mrh_$alloc(heap, 432);
  if same_heap(heap) then
    isc_user_routines_2ec := isc_user_routines_2ec + 1;
  s^.f76.field_precision := 32;
  s^.f76.is_destroyable := true;
  s^.f76.is_entire_object := true;
  s^.evaluation_order := 1;
  s^.il_kind := il_none;
  s^.kind := solution$none;
  s^.base_register := isc_solution_ptr_t(isc_user_routines_31c);
  s^.index_register := isc_solution_ptr_t(isc_user_routines_31c);
  s^.kind := solution$t(kind);
  s^.inherited_attributes := inh;
  s^.il := sym;
  s^.il_kind := il$t(il_kind);
  s^.f114.number_of_children := nchildren;
  new_solution := s;
end;

{ duplicate_solution - a copy of sol from heap (counted as new_solution
  counts); nil for nil.

  0x0D93FC, 0x62 bytes: heap 8, sol 12; the 432 bytes by a `dbf' loop
  of 27 times four longwords; A0. }

function duplicate_solution;
var
  d: isc_solution_ptr_t;
begin
  if sol = nil then
    d := nil
  else begin
    d := mrh_$alloc(heap, 432);
    if same_heap(heap) then
      isc_user_routines_2ec := isc_user_routines_2ec + 1;
    d^ := sol^;
  end;
  duplicate_solution := d;
end;

{ duplicate_inherited_attributes - a copy of inh from heap; nil for
  nil.

  0x0D945E, 0x48 bytes: heap 8, inh 12; A0. }

function duplicate_inherited_attributes;
var
  d: inherited_attributes_ptr_t;
begin
  if inh = nil then
    d := nil
  else begin
    d := mrh_$alloc(heap, 40);
    d^ := inh^;
  end;
  duplicate_inherited_attributes := d;
end;

{ preserve_solution - sol copied into the preserved heap
  (isc_user_routines +0x224) with its attributes: once (a copy, +115
  bit 7, is its own; a solution with +115 bits 5 and 4 has its copy at
  its symbol's +12).  A solution passing pass 2 on (chain, +88) has
  the chain preserved and then, when its rule has fields
  (im_rule_has_fields), the rule's solution pointers (the offsets by
  rule, docs/isc-notes.md); otherwise its children (+116, nchildren of
  them).  A solution with +115 bit 5 then records the copy at its
  symbol's +12 and the copy is marked preserved (bit 4).

  0x0D94A6, 0x340 bytes: sol 8; the table `tst.b (-1,A5,D0.w)' by the
  copy's rule; the case by sol's rule a chain of comparisons; the
  children by the unsigned count (`cmpi.b #2; bcs'); A0. }

function preserve_solution;
var
  p: isc_solution_ptr_t;
begin
  if sol = nil then
    p := nil
  else if sol^.f114.builtin_is_local_cse and sol^.f114.builtin_local_cse_has_been_preserved then
    p := isc_solution_ptr_t(isc_node_ptr_t(sol^.il)^.xp[3])
  else if sol^.f114.already_preserved then
    p := sol
  else begin
    p := duplicate_solution(isc_preserve_heap, sol);
    p^.f114.already_preserved := true;
    p^.inherited_attributes := duplicate_inherited_attributes(isc_preserve_heap, sol^.inherited_attributes);
    if sol^.before_transform <> nil then begin
      p^.before_transform := preserve_solution(sol^.before_transform);
      if im_rule_has_fields[p^.which_transform] then
        case sol^.which_transform of
          12, 179, 181, 274, 275, 290, 292, 301, 304, 344, 375, 377, 378,
          379, 418, 445, 448, 474, 542, 548, 549:
            p^.fields[0] := preserve_solution(sol^.fields[0]);
          114, 115:
            im_sol358_ptr_t(p)^.f358 := preserve_solution(im_sol358_ptr_t(sol)^.f358);
          177: begin
            p^.fields[1] := preserve_solution(sol^.fields[1]);
            p^.fields[2] := preserve_solution(sol^.fields[2]);
            p^.fields[3] := preserve_solution(sol^.fields[3]);
            p^.fields[4] := preserve_solution(sol^.fields[4]);
          end;
          186:
            p^.fields[2] := preserve_solution(sol^.fields[2]);
          422: begin
            p^.fields[0] := preserve_solution(sol^.fields[0]);
            p^.fields[1] := preserve_solution(sol^.fields[1]);
            p^.fields[2] := preserve_solution(sol^.fields[2]);
            p^.fields[3] := preserve_solution(sol^.fields[3]);
          end;
          423: begin
            p^.fields[0] := preserve_solution(sol^.fields[0]);
            p^.fields[1] := preserve_solution(sol^.fields[1]);
            p^.fields[2] := preserve_solution(sol^.fields[2]);
            p^.fields[3] := preserve_solution(sol^.fields[3]);
            p^.fields[4] := preserve_solution(sol^.fields[4]);
            p^.fields[5] := preserve_solution(sol^.fields[5]);
            p^.fields[6] := preserve_solution(sol^.fields[6]);
          end;
          262, 479, 550:
            p^.fields[1] := preserve_solution(sol^.fields[1]);
          otherwise ;
        end;
    end
    else begin
      if sol^.f114.number_of_children > 0 then
        p^.children[1] := preserve_solution(sol^.children[1]);
      if sol^.f114.number_of_children >= 2 then
        p^.children[2] := preserve_solution(sol^.children[2]);
      if sol^.f114.number_of_children >= 3 then
        p^.children[3] := preserve_solution(sol^.children[3]);
      if sol^.f114.number_of_children >= 4 then
        p^.children[4] := preserve_solution(sol^.children[4]);
      if sol^.f114.number_of_children >= 5 then
        p^.children[5] := preserve_solution(sol^.children[5]);
    end;
    if sol^.f114.builtin_is_local_cse then begin
      isc_node_ptr_t(sol^.il)^.xp[3] := isc_node_ptr_t(p);
      p^.f114.builtin_local_cse_has_been_preserved := true;
    end;
  end;
  preserve_solution := p;
end;

{ solution_list$new - an 8-byte list head from the ISC heap (not
  cleared).

  0x0D97E6, 0x26 bytes: A0. }

function solution_list$new;
begin
  solution_list$new := mrh_$alloc(isc_heap, 8);
end;

{ solution_list$append - sol put at list's end in a new cell (its next
  not set; bug_check for a nil list).

  0x0D980C, 0x64 bytes: list 8, sol 12. }

procedure solution_list$append;
var
  c: solution_cell_ptr_t;
begin
  if list = nil then
    bug_check('ISC: solution_list$append: list was nil.%$')
  else begin
    c := mrh_$alloc(isc_heap, 8);
    c^.sol := sol;
    if list^.first = nil then
      list^.first := c
    else
      list^.last^.next := c;
    list^.last := c;
  end;
end;

{ solution_list$delete - sol's first cell taken out of list (the head's
  last kept when it is the first cell; bug_check for a nil list).

  0x0D989A, 0x74 bytes: list 8, sol 12. }

procedure solution_list$delete;
var
  prev: solution_cell_ptr_t;
  c: solution_cell_ptr_t;
  done: boolean;
begin
  if list = nil then
    bug_check('ISC: solution_list$delete: list was nil.%$')
  else if list^.first <> nil then
    if list^.first^.sol = sol then
      list^.first := list^.first^.next
    else begin
      prev := list^.first;
      done := false;
      repeat
        c := prev^.next;
        if c = nil then
          done := true
        else if c^.sol = sol then begin
          prev^.next := c^.next;
          if list^.last = c then
            list^.last := prev;
          done := true;
        end
        else
          prev := c;
      until done;
    end;
end;

{ solution_list$empty - whether list has no solutions (true, after
  bug_check, for a nil list).

  0x0D9938, 0x30 bytes: list 8; D0. }

function solution_list$empty;
begin
  if list = nil then begin
    bug_check('ISC: solution_list$empty: list was nil.%$');
    solution_list$empty := true;
  end
  else
    solution_list$empty := list^.first = nil;
end;

{ solution_list$preserve - a copy of list in the preserved heap, each
  solution preserved (the head and cells not cleared; bug_check and nil
  for a nil list).

  0x0D9992, 0x94 bytes: list 8; the new head's last through D2 (its
  address); A0. }

function solution_list$preserve;
var
  l: solution_list_ptr_t;
  p: solution_cell_ptr_t;
  c: solution_cell_ptr_t;
  sol: isc_solution_ptr_t;
begin
  if list = nil then begin
    bug_check('ISC: solution_list$preserve: list was nil.%$');
    l := nil;
  end
  else begin
    l := mrh_$alloc(isc_preserve_heap, 8);
    p := list^.first;
    while p <> nil do begin
      sol := p^.sol;
      c := mrh_$alloc(isc_preserve_heap, 8);
      c^.sol := preserve_solution(sol);
      if l^.first = nil then
        l^.first := c
      else
        l^.last^.next := c;
      l^.last := c;
      p := p^.next;
    end;
  end;
  solution_list$preserve := l;
end;

{ isc_$begin_compilation - the three heaps set up (per compilation,
  +0x20C; per routine, the preserved heap; per statement, the ISC heap),
  isc_to_lir's begin_compilation, the well-known literals -1..32 made,
  the per-compilation counts cleared, the reference kinds' table
  (+0x9C: kinds 137, 138, 143, 145..147, 164, 171, 175, 189, 205, the
  set after the code at 0x0D9B4A, by 207 - kind) filled for kinds
  0..236, the pass-1 tables (isc_pass_1_begin_compilation), the literal
  model 1.

  0x0D9A52, 0xDE bytes: mrh_$initialize's flags and size pushed as one
  longword (16#10000); the literals' loop `dbf' from 33. }

procedure isc_$begin_compilation;
var
  k: integer;
begin
  mrh_$initialize(isc_user_routines_20c, 1, 0, 'isc per_compilation heap%');
  mrh_$initialize(isc_preserve_heap, 1, 0, 'isc per_routine heap%');
  mrh_$initialize(isc_heap, 1, 0, 'isc per_statement heap%');
  begin_compilation;
  for k := -1 to 32 do
    isc_literal_solutions[k] := solution_ptr_t(well_known_literal(k));
  isc_user_routines_2e4 := 0;
  isc_user_routines_2e0 := 0;
  isc_user_routines_2dc := 0;
  for k := 0 to 236 do
    isc_user_routines_9c[k] :=
        k in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205];
  isc_pass_1_begin_compilation;
  isc_user_routines_352 := 1;
end;

{ isc_$initialize_routine - the traces set from at_backend's switches
  (sw13: isc_user_routines_356, sw12: _354), the last line cleared;
  under sw13 the source line to trace asked for on the terminal
  (vfmt_$ws to stream 2; read into +0x304); the per-routine counts
  cleared.

  0x0D9B92, 0xAA bytes: the switches `btst #5' and `btst #4' of
  0x485D30; the stream a constant 2 after the code (0x0D9C6A); PAS_$READ
  code 2609, a longword. }

procedure isc_$initialize_routine;
begin
  isc_user_routines_356 := false;
  isc_user_routines_354 := false;
  isc_user_routines_308 := 0;
  if at_backend_switches.sw13 then
    isc_user_routines_356 := true;
  if at_backend_switches.sw12 then
    isc_user_routines_354 := true;
  if isc_user_routines_356 then begin
    vfmt_$ws(2, 'Debug "no solutions" at which source line? %$');
    read(isc_user_routines_304);
    readln;
  end;
  isc_user_routines_300 := 0;
  isc_user_routines_2fc := 0;
  isc_user_routines_2f8 := 0;
  isc_user_routines_2f4 := 0;
  isc_user_routines_350 := il_none;
  isc_user_routines_2f0 := 0;
  isc_user_routines_2e8 := 0;
end;

{ isc_$process_statement - the statement node under inh selected: the
  ISC heap marked, begin_statement, the statement's solutions counted
  from 0; the traces off unless the statement is on the line to trace
  (+0x304, -1 every line); pass 1 for every solution kind but none
  (16#FFFFFE), the cheapest chosen and passed through pass 2 (traced:
  dump_solution); the traces restored, end_statement, the heap released
  to the mark; the statement with the most solutions so far recorded
  (+0x2E8, its index +0x2F0).

  0x0D9C6C, 0x152 bytes: node 8, inh 12; the mark in (-4,A6). }

procedure isc_$process_statement;
var
  mark: mrh_$mark_t;
  list: solution_list_ptr_t;
  sol: isc_solution_ptr_t;
  save_356: boolean;
  save_354: boolean;
begin
  mark := mrh_$mark(isc_heap);
  begin_statement;
  isc_user_routines_2ec := 0;
  save_356 := isc_user_routines_356;
  save_354 := isc_user_routines_354;
  if (isc_user_routines_304 <> -1) and (inh^.pos.source_line_number <> isc_user_routines_304) then begin
    isc_user_routines_356 := false;
    isc_user_routines_354 := false;
  end;
  list := pass_1(node, inh, 0, [solution$case_jump_base..solution$void]);
  if not solution_list$empty(list) then begin
    sol := choose_one_solution(list);
    pass_2(sol, 0);
    if isc_user_routines_356 or isc_user_routines_354 then begin
      write('Chosen solution after pass 2:');
      writeln;
      writeln;
      dump_solution(sol, 0, true);
      writeln;
    end;
  end;
  isc_user_routines_356 := save_356;
  isc_user_routines_354 := save_354;
  end_statement;
  mrh_$release_to_mark(isc_heap, mark);
  if isc_user_routines_2ec > isc_user_routines_2e8 then begin
    isc_user_routines_2e8 := isc_user_routines_2ec;
    isc_user_routines_2f0 := inh^.pos.stmt_number;
  end;
end;

{ apply_pass_1_and_choose_to_list - one chosen solution (pass 1 for
  every kind but none, then choose_one_solution) for each node of the
  chain from node (through +8: the statement kinds, an assignment of
  any operator but 12, 17 and 18; another node bug_check'ed); an
  irrelevant solution (21) when the list stays empty.

  0x0D9DDC, 0x276 bytes: node 8, inh 12; the kinds a chain of
  comparisons, the assignment operators a jump table over 0..36; A0. }

function apply_pass_1_and_choose_to_list;
var
  n: isc_node_ptr_t;
  list: solution_list_ptr_t;
  l: solution_list_ptr_t;
  sol: isc_solution_ptr_t;
begin
  n := node;
  list := solution_list$new;
  while n <> nil do begin
    l := pass_1(n, inh, 0, [solution$case_jump_base..solution$void]);
    sol := choose_one_solution(l);
    solution_list$append(list, sol);
    case n^.kind of
      assign_node:
        case n^.as_op of
          scalar_aop, add_to_aop, sub_from_aop, and_to_aop, or_to_aop, eor_to_aop, agg_aop, set_and_to_aop, set_or_to_aop, set_diff_from_aop, pack_aop, fp_aop, not_to_aop, neg_to_aop, lshft_to_aop, rshft_to_aop, f_add_to_aop, f_sub_from_aop, f_mul_to_aop,
          f_div_by_aop, mul_to_aop, div_by_aop, agg_len_aop, isc_mul_to_aop, strcat_aop, strcpy_aop, strncat_aop, strncpy_aop, isc_agg_aop, isc_slice_aop, isc_agg_zero_aop, isc_fill_aop, range_check_to_aop, f_range_check_to_aop:
            n := n^.xp[2];
          otherwise
            bug_check('ISC: source line %wd: apply_pass_1_and_choose_to_list: An object inside a visit list did not have a next.%$',
                      inh^.pos);
        end;
      bit_field_assign, blk_end_node, block_entry_node, branch_node,
          case_node_range_check, case_node_no_range_check, cbranch_node,
          eval_node, insert_bit_field, label_node, nlbranch_node,
          raise_exception, release_dynamic_space, return_node:
        n := n^.xp[2];
      otherwise
        bug_check('ISC: source line %wd: apply_pass_1_and_choose_to_list: An object inside a visit list did not have a next.%$',
                  inh^.pos);
    end;
  end;
  if solution_list$empty(list) then begin
    sol := new_solution(isc_heap, 21, 0, nil, nil, 0);
    solution_list$append(list, sol);
  end;
  apply_pass_1_and_choose_to_list := list;
end;

{ apply_pass_2_to_list - pass 2 over each solution of list (traced:
  dump_solution); bug_check for a nil list.

  0x0DA0BE, 0xE6 bytes: list 8. }

procedure apply_pass_2_to_list;
var
  c: solution_cell_ptr_t;
begin
  if list = nil then
    bug_check('ISC: apply_pass_2_to_list: list was nil.%$')
  else begin
    c := list^.first;
    while c <> nil do begin
      pass_2(c^.sol, 0);
      if isc_user_routines_356 or isc_user_routines_354 then begin
        write('apply_pass_2_to_list:');
        writeln;
        writeln;
        write('Chosen solution after pass 2:');
        writeln;
        writeln;
        dump_solution(c^.sol, 0, true);
        writeln;
      end;
      c := c^.next;
    end;
  end;
end;

{ isc_$begin_routine - the routine rtn selected statement by statement
  (from its +20, through +8, to its BLK_END_NODE, 149): a statement
  without a line given the last one (+0x30A, the low halfword of
  +0x308), else its line recorded there; each under new attributes
  with its line and index (+43..+44), the ISC heap released after
  each.

  0x0DA1E4, 0x9A bytes: rtn 8. }

procedure isc_$begin_routine;
var
  s: isc_node_ptr_t;
  inh: inherited_attributes_ptr_t;
  done: boolean;
begin
  isc_$initialize_routine;
  begin_routine;
  s := im_rtn_view_ptr_t(rtn)^.first;
  repeat
    if s^.st_line = 0 then
      s^.st_line := isc_user_routines_308
    else
      isc_user_routines_308 := s^.st_line;
    inh := new_inherited_attributes(isc_heap, s);
    inh^.pos.source_line_number := s^.st_line;
    inh^.pos.stmt_number := rshft(s^.st_l42 & 16#FFFF00, 8);
    isc_$process_statement(s, inh);
    mrh_$release_all(isc_heap);
    done := s^.kind = blk_end_node;
    if not done then
      s := s^.xp[2];
  until done;
end;

{ isc_$end_routine - isc_to_lir's end_routine; under sw3 the routine's
  metering printed; the routine's counts added to the compilation's;
  the preserved heap released.

  0x0DA27E, 0x336 bytes: rtn 8 (not read); the counts written by
  address (`move.l #0x481100,-(SP)'). }

procedure isc_$end_routine;
begin
  end_routine;
  if at_backend_switches.sw3 then begin
    write('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
    writeln;
    write('isc_$end_routine:                     metering results:');
    writeln;
    write('calls_to_pass_1:                      ');
    write(isc_user_routines_300:1);
    write('.');
    writeln;
    write('calls_to_pass_2:                      ');
    write(isc_user_routines_2fc:1);
    write('.');
    writeln;
    write('calls_to_pattern_matcher:             ');
    write(isc_user_routines_2f8:1);
    write('.');
    writeln;
    write('max_solutions_for_one_il_node:        ');
    write(isc_user_routines_2f4:1);
    write('.');
    writeln;
    write('which_il_kind_had_max_solutions:      ');
    write(isc_user_routines_350:1);
    write('.');
    writeln;
    write('which_stmt_number_had_max_solutions:  ');
    write(isc_user_routines_2f0:1);
    write('.');
    writeln;
    write('max_solutions_during_a_statement:     ');
    write(isc_user_routines_2e8:1);
    write('.');
    writeln;
    write('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
    writeln;
  end;
  isc_user_routines_2e4 := isc_user_routines_2e4 + isc_user_routines_300;
  isc_user_routines_2e0 := isc_user_routines_2e0 + isc_user_routines_2fc;
  isc_user_routines_2dc := isc_user_routines_2dc + isc_user_routines_2f8;
  mrh_$release_all(isc_preserve_heap);
end;

{ isc_$end_compilation - under sw3 the compilation's metering printed;
  isc_to_lir's end_compilation.

  0x0DB25A, 0x1A0 bytes. }

procedure isc_$end_compilation;
begin
  if at_backend_switches.sw3 then begin
    write('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
    writeln;
    write('isc_$end_compilation:                     metering results:');
    writeln;
    write('calls_to_pass_1_per_compilation:          ');
    write(isc_user_routines_2e4:1);
    write('.');
    writeln;
    write('calls_to_pass_2_per_compilation:          ');
    write(isc_user_routines_2e0:1);
    write('.');
    writeln;
    write('calls_to_pattern_matcher_per_compilation: ');
    write(isc_user_routines_2dc:1);
    write('.');
    writeln;
    write('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&');
    writeln;
  end;
  end_compilation;
end;
