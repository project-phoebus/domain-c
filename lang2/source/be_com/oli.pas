{ oli - the PRISM back end's loop optimizer (OLI): software pipelining
  of innermost single-block loops.  A loop whose block branches back to
  itself on a counter decremented by one (size_and_shape_ok,
  find_loop_instrs), whose memory references and recurrences allow it
  (analyze_dependencies), is scheduled modulo an iteration interval
  (iteration_interval, schedule: four functional units a cycle), the
  induction variables adjusted to the overlapped iterations, and the
  loop rebuilt as a prologue, a pipelined body and an epilogue
  (build_pipelined_loop).

  TODO(oli): translator PC6 did not reach every routine; those below
  marked TODO are not in this file yet (the table lists all of the
  image's).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x257D60  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x257D82  zero (internal)
    --------  0x257D98  gcd (internal)
    --------  0x257DC8  is_exposed_or_produced_by_jbi (internal)
    --------  0x257E0E  fu_of (internal)
    --------  0x257E7E  new_seq_num (internal)
    --------  0x257ED8  build_sched_array (internal)
    --------  0x258030  reverse_iteration_numbers (internal)
    --------  0x258058  init_software_pipelining (internal)
    --------  0x2580BA  add_instr_end_of_prolog_inits (internal)
    --------  0x258184  get_dp_zero (internal)
    --------  0x258362  get_sp_zero (internal)
    --------  0x2584D0  get_ip_zero (internal)
    --------  0x258622  init_sched (internal)
    --------  0x2586E4  enqueue_enabled_instruction (internal)
    --------  0x25876A  dequeue_enabled_instruction (internal)
    --------  0x25878E  oli_$begin_compilation
    --------  0x2587C6  oli_$end_compilation
    --------  0x2587C8  first_innermost_loop (internal)
    --------  0x2587EA  next_inner_loop (internal)
    --------  0x25883E  assign_sequence_numbers (internal)
    --------  0x25885C  size_and_shape_ok (internal)
    --------  0x258940  mem_ref_via_non_const_induction_variable (internal)
    --------  0x258A1E  reduction_class_of (internal)
    --------  0x258C26  create_reduction_variable (internal)
    --------  0x258CC0  is_exposed_reduction (internal)
    --------  0x258D86  induction_increment_of (internal)
    --------  0x258E90  induction_initial_value_of (internal)
    --------  0x258FEC  iv_expressions_differ_by_const (internal)
    --------  0x259058  record_recurrence (internal)
    --------  0x2590BE  delay_along_data_flow_path (internal) TODO
    --------  0x259156  data_flow_paths (internal) TODO
    --------  0x2592A6  find_data_flow_paths (internal) TODO
    --------  0x2592D4  simple_test (internal) TODO
    --------  0x2593BC  gcd_test (internal) TODO
    --------  0x259446  slope_test (internal) TODO
    --------  0x2594F8  constant_trip_count (internal) TODO
    --------  0x25954E  banarjees_test (internal) TODO
    --------  0x25963C  recurrence_test (internal) TODO
    --------  0x259736  oli_$compare_memory_references TODO
    --------  0x259A48  analyze_memory_references (internal) TODO
    --------  0x259A64  analyze_dependencies (internal) TODO
    --------  0x259AFE  modified (internal) TODO
    --------  0x259B22  parity_matches (internal) TODO
    --------  0x259B7A  can_join (internal) TODO
    --------  0x259BDC  is_5op_candidate (internal) TODO
    --------  0x259F56  max_recurrence_slope (internal) TODO
    --------  0x259FB8  iteration_interval (internal) TODO
    --------  0x25A18A  assign_enable_counts (internal) TODO
    --------  0x25A300  decrement_ienable_count (internal) TODO
    --------  0x25A31E  decrement_lenable_count TODO
    --------  0x25A35E  swap_inputs (internal) TODO
    --------  0x25A44A  find_open_slot (internal) TODO
    --------  0x25ACB8  schedule_instr (internal) TODO
    --------  0x25AEDC  find_data_flow_constraints (internal) TODO
    --------  0x25B12C  ticks_to_most_remote_consumer (internal) TODO
    --------  0x25B3FA  schedule (internal) TODO
    --------  0x25B6B0  excess_register_pressure (internal) TODO
    --------  0x25BA5C  int_const_in_fp_reg (internal) TODO
    --------  0x25BC08  operand_gets_materialized_value (internal) TODO
    --------  0x25BDC0  exposed_at TODO
    --------  0x25BE02  consumed_in_downstream_bb TODO
    --------  0x25BE68  get_materialized_in_re_duction_lr (internal) TODO
    --------  0x25C108  build_bookkeeping_structures (internal) TODO
    --------  0x25C22A  build_fan_in_seq_instr TODO
    --------  0x25C3F2  build_fan_out_seq_instrs TODO
    --------  0x25C5CE  enlist_sorted (internal) TODO
    --------  0x25C6BA  add_instruction_in_sequence (internal) TODO
    --------  0x25C79C  five_oppify (internal) TODO
    --------  0x25C91E  un_five_oppify (internal) TODO
    --------  0x25C994  record_live_exposed_lr (internal) TODO
    --------  0x25CA4E  get_live_exposed_lr (internal) TODO
    --------  0x25CB2A  find_final_lr_in_column (internal) TODO
    --------  0x25CB70  record_final_lr_in_column (internal) TODO
    --------  0x25CC16  build_final_lr_in_col_list (internal) TODO
    --------  0x25CCCC  link_lrs (internal) TODO
    --------  0x25CECA  link_final_induction_vars (internal) TODO
    --------  0x25CFE2  get_induction_variable_adjustment TODO
    --------  0x25D496  copys_in_prolog (internal) TODO
    --------  0x25D50C  get_exposed_operand (internal) TODO
    --------  0x25D90E  precedes_in_schedule (internal) TODO
    --------  0x25D954  get_new_lr_pair (internal) TODO
    --------  0x25D978  find_new_intend_to_modify_operand (internal) TODO
    --------  0x25DAB8  get_write_lr (internal) TODO
    --------  0x25E046  fill_in_live_ranges (internal) TODO
    --------  0x25E4EA  generate_jump (internal) TODO
    --------  0x25E57A  generate_jumps (internal) TODO
    --------  0x25E654  generate_control_flow_instructions (internal) TODO
    --------  0x25ECC6  generate_ltss (internal) TODO
    --------  0x25EDB6  generate_birthpoints (internal) TODO
    --------  0x25F258  modify_operand (internal) TODO
    --------  0x25F3F4  post_adds_a_loop_invariant_to (internal) TODO
    --------  0x25F4D4  adds_unscaled_loop_invariant (internal) TODO
    --------  0x25F5BA  find_other_addend (internal) TODO
    --------  0x25F64A  adjust_induction_vars (internal) TODO
    --------  0x25FB04  restore_induction_vars (internal) TODO
    --------  0x25FE74  materialize_induction_variable_increments (internal) TODO
    --------  0x2600DE  reduce_partial_sums (internal) TODO
    --------  0x2603CE  add_reduction_partial_sums (internal) TODO
    --------  0x26061E  copy_to_end_of (internal) TODO
    --------  0x260850  build_bbs_and_fges (internal) TODO
    --------  0x260A52  mark_buckets (internal) TODO
    --------  0x260AC4  move_from_body_to_tail (internal) TODO
    --------  0x260B4A  fill_in_tail (internal) TODO
    --------  0x260C3A  adjust_final_induction_vars (internal) TODO
    --------  0x260C3C  build_pipelined_loop (internal) TODO
    --------  0x260CF4  find_loop_instrs (internal) TODO
    --------  0x260DE0  recurrence_constraints_ok (internal) TODO
    --------  0x260E6E  clear_walk_marks (internal) TODO
    --------  0x260EE0  increase_precedence (internal) TODO
    --------  0x260F5E  increase_recurrence_precedence (internal) TODO
    --------  0x260F9C  decrease_precedence (internal) TODO
    --------  0x261020  restore_precedence (internal) TODO
    --------  0x261054  software_pipeline (internal) TODO
    --------  0x26111E  init_depend (internal) TODO
    --------  0x261128  overlap_loop_iterations (internal) TODO
    --------  0x26116C  mem_refs_good_for_align_unroll (internal) TODO
    --------  0x261170  unroll_for_alignment (internal) TODO
    --------  0x26118E  oli_$process_routine TODO
    --------  0x2612A0  oli_$end_routine TODO
    A5 0x48C5C4: the module's data: oli_red_kind (+0, by opcode),
    oli_add_opc (+0x300), the bookkeeping heap (+0x340), the queue's
    nodes (+0x998), the tables by instruction number (+0xFD4 ..
    +0x1938, each [1..200]), the schedule (+0x1C58, a row of four
    functional units a cycle), the flags by number
    (+0x2BF8, +0x2CC0), the routine's and the loop's state (+0x2D9C
    .. +0x2E72).

  A module-level routine that does not load A5 is internal; nearly
  every routine of the unit is (they run on oli_$process_routine's A5).

  Fields of batch A's records read through views or casts (offsets for
  batch A to name): a block's l74 (+74, an interval head's first member)
  and l78 (+78, the next member of the interval), l70 (+70, the head);
  a segment's l24 (+24: an induction lts of iv, kind 1..4, or oli's
  reduction record, kind 5); an instruction's num (+42) oli renumbers
  1..n in the loop (assign_sequence_numbers) and indexes its tables by;
  an instruction's +28 word, the precedence height sched_utils
  computes (the queue's order).

  Not known from the original: every local, parameter, cell and type
  name. }

module oli;

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
%include 'lang2/source/be_com/utils.ins.pas';

type
  { A node of the queue of enabled instructions (8 bytes, from the
    pool oli_qnodes): chained at next, by the instructions' +28 word
    (the precedence height), highest first. }
  oli_qnode_ptr_t = ^oli_qnode_t;
  oli_qnode_t = record
    next: oli_qnode_ptr_t;              { +0 }
    instr: instr_ptr_t;                 { +4 }
  end;

  { A reduction (16 bytes from the bookkeeping heap): a live range
    whose segments in the loop accumulate one value; kind (+0) 5, so
    that a segment's l24 (an induction lts of iv otherwise, kinds 1..4)
    tells the two apart; cls (+2) its class's bit number (0 integer,
    1 single, 2 double); chained from oli_reductions at next. }
  oli_red_ptr_t = ^oli_red_t;
  oli_red_t = record
    h: packed record                    { +0 }
      kind: 0..255;
      b1: 0..255;
      end;
    cls: integer;                       { +2 }
    lr: lr_ptr_t;                       { +4 }
    next: oli_red_ptr_t;                { +8 }
    l12: integer32;                     { +12 }
  end;

  { A recurrence (28 bytes from the bookkeeping heap): from an
    instruction (+4) to one (+8) a distance (+12) of iterations later;
    chained from oli_recurrences at next. }
  oli_rec_ptr_t = ^oli_rec_t;
  oli_rec_t = record
    next: oli_rec_ptr_t;                { +0 }
    from: univ_ptr;                     { +4 }
    upto: univ_ptr;                     { +8 }
    dist: integer32;                    { +12 }
    l16: integer32;                     { +16 }
    l20: integer32;                     { +20 }
    l24: integer32;                     { +24 }
  end;

  { An instruction's +28 as the scheduler uses it (batch A's instr_t
    l28; sched_utils' su_instr_t): the precedence height, compared
    unsigned. }
  oli_instr_v_ptr_t = ^oli_instr_v_t;
  oli_instr_v_t = record
    space0: array [0..27] of char;
    height: 0..65535;                   { +28 }
  end;

var
  { +0: the class of value an instruction of each opcode can reduce
    (a set as bits: 1 integer, 2 single, 4 double; 0 none): add, sub,
    mffp, mtfp integer; copys, adds, subs single; copyd, addd, subd
    double.  384 words (.rwdi). }
  oli_red_kind: array [0..383] of integer := [
    79 of 0, 1, 0, 1, 34 of 0, 1, 9 of 0, 1, 17 of 0,  { 0 .. 143 }
    2, 9 of 0, 2, 2, 5 of 0, 4, 9 of 0, 4, 4,   { 144 .. 172 }
    211 of 0];                                  { 173 .. 383 }

  { +0x300: the opcode that adds partial sums of each class (1 add, 2
    and 3 addi). }
  oli_add_opc: array [0..3] of integer := [0, 79, 137, 137];

  { +0x340: the bookkeeping heap (reductions, recurrences, ...). }
  oli_heap: mrh_$heap_t;

  { +0x998: the queue's nodes, chained on oli_qfree. }
  oli_qnodes: array [0..199] of oli_qnode_t;

  { +0xFD4 .. +0x1934: by instruction number (1..200; each table's
    element k at its base + 4k). }
  oli_order: array [1..200] of integer32;      { +0xFD8: an instruction's
                                          place in oli_sched_list }
  oli_sched_list: array [1..200] of instr_ptr_t;   { +0x12F8: the
                                          scheduled instructions, by
                                          iteration (last first), cycle
                                          and unit; nil after the last }
  oli_iter: array [1..200] of integer32;       { +0x1618: the iteration
                                          (stage) an instruction is
                                          scheduled in (0 none) }
  oli_slot: array [1..200] of integer32;       { +0x1938: its cycle in
                                          the iteration interval }

  { +0x1C58: the schedule: by cycle of the interval (1..200) the
    instruction of each functional unit (fu_of: 0..3). }
  oli_sched: array [1..200, 0..3] of instr_ptr_t;

  oli_2bf8: array [1..200] of boolean;  { +0x2BF8 (init_sched clears) }
  oli_2cc0: array [1..200] of boolean;  { +0x2CC0
                                          (init_software_pipelining
                                          clears) }

  { +0x2DA4 .. +0x2E72: the routine's and the loop's state. }
  oli_recurrences: oli_rec_ptr_t;       { +0x2DA8 (record_recurrence) }
  oli_2dac: univ_ptr;                   { +0x2DAC }
  oli_2db0: integer32;                  { +0x2DB0 }
  oli_red_lts: lts_ptr_t;               { +0x2DB4: the segment
                                          is_exposed_reduction examines }
  oli_reductions: oli_red_ptr_t;        { +0x2DB8 }
  oli_dp_zero: lr_ptr_t;                { +0x2DBC: a floating pair
                                          register holding 0.0 (loadd
                                          of a literal in the prologue) }
  oli_sp_zero: lr_ptr_t;                { +0x2DC0: a floating register
                                          holding 0.0 (get_dp_zero's
                                          copy goes here too) }
  oli_ip_zero: lr_ptr_t;                { +0x2DC4: an integer register
                                          holding 0 }
  oli_2dc8: univ_ptr;                   { +0x2DC8 }
  oli_prolog_bb: bb_ptr_t;              { +0x2DE4: the block the
                                          prologue's instructions go in }
  oli_prolog_last: instr_ptr_t;         { +0x2DEC: the last instruction
                                          added at the prologue's end }
  oli_branch: instr_ptr_t;              { +0x2DF0: the loop's branch
                                          back }
  oli_decr: instr_ptr_t;                { +0x2DF4: the loop counter's
                                          decrement (a sub of 1) }
  oli_counter: lr_ptr_t;                { +0x2DF8: the loop counter }
  oli_rtn: rtn_ptr_t;                   { +0x2DFC }
  oli_2e00: integer32;                  { +0x2E00 }
  oli_2e04: integer32;                  { +0x2E04 }
  oli_2e08: integer32;                  { +0x2E08 }
  oli_2e0c: integer32;                  { +0x2E0C }
  oli_2e10: integer32;                  { +0x2E10 }
  oli_2e14: integer32;                  { +0x2E14 }
  oli_2e18: integer32;                  { +0x2E18 }
  oli_2e1c: integer32;                  { +0x2E1C }
  oli_2e20: integer32;                  { +0x2E20 }
  oli_2e24: integer32;                  { +0x2E24 }
  oli_2e28: integer32;                  { +0x2E28 }
  oli_2e2c: integer32;                  { +0x2E2C }
  oli_2e30: integer32;                  { +0x2E30 }
  oli_2e34: integer32;                  { +0x2E34 }
  oli_iters: integer32;                 { +0x2E3C: the iterations
                                          (stages) the schedule spans }
  oli_ii: integer32;                    { +0x2E40: the iteration
                                          interval (cycles) }
  oli_2e44: integer32;                  { +0x2E44 }
  oli_2e48: integer32;                  { +0x2E48 }
  oli_2e4c: integer32;                  { +0x2E4C }
  oli_2e50: integer32;                  { +0x2E50 }
  oli_2e54: integer32;                  { +0x2E54 }
  oli_nsched: integer32;                { +0x2E58: oli_sched_list's
                                          length }
  oli_qfree: oli_qnode_ptr_t;           { +0x2E5C: the free nodes }
  oli_queue: oli_qnode_ptr_t;           { +0x2E60: the enabled
                                          instructions }
  oli_bb: bb_ptr_t;                     { +0x2E64: the loop (its one
                                          block) }
  oli_red_cls: integer;                 { +0x2E6C: the class of the
                                          reduction being examined }
  oli_mem_dep: integer;                 { +0x2E6E: what the memory
                                          references' analysis found }
  oli_dep: integer;                     { +0x2E70: analyze_dependencies'
                                          answer }
  oli_cfg_changed: boolean;             { +0x2E72: a loop was rebuilt
                                          (the bit vectors released) }

{ zero - (n + 3) div 4 longwords from p cleared (nothing for 0).
  0x257D82, 0x16 bytes, no frame (pattern 100's helper). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := 0;
  end;
end;

{ gcd - the greatest common divisor of |a| and |b| by subtraction.
  0x257D98, 0x30 bytes. }

function gcd(
    a: integer32;
    b: integer32): integer32; options(val_param); internal;
var
  t: integer32;
begin
  if a < 0 then
    a := -a;
  if b < 0 then
    b := -b;
  repeat
    if a < b then begin
      t := a;
      a := b;
      b := t;
    end;
    a := a - b;
  until a = 0;
  gcd := b;
end;

{ is_exposed_or_produced_by_jbi - s is exposed in its block or defined
  by a join birthpoint.  0x257DC8, 0x46 bytes. }

function is_exposed_or_produced_by_jbi(
    s: lts_ptr_t): boolean; options(val_param); internal;
begin
  if s^.f2.exposed then
    is_exposed_or_produced_by_jbi := true
  else
    is_exposed_or_produced_by_jbi :=
        instruction_attributes[utils_ins_$operands_instruction(s^.refs)^.opc].class
        = class$join_bp;
end;

{ fu_of - the functional unit an instruction of opcode opc runs on, by
  its interaction class: 0, 2, 1 or 3.  0x257E0E, 0x70 bytes: the
  classes tested as sets of 0..31 in registers (`btst Dn,Dn'). }

function fu_of(
    opc: integer): integer; options(val_param); internal;
var
  k: integer;
begin
  k := instruction_attributes[opc].interaction;
  if k in [1, 4..16] then
    fu_of := 0
  else if k in [2, 11, 13] then
    fu_of := 2
  else if k in [3, 11, 13] then
    fu_of := 1
  else
    fu_of := 3;
end;

{ new_seq_num - the sequence number of a slot: iteration it of the
  instruction numbered num, run on opc's unit: ((it + its iteration) *
  the interval + its cycle) * 4 + the unit.  0x257E7E, 0x5A bytes. }

function new_seq_num(
    it: integer32;
    num: integer32;
    opc: integer): integer32; options(val_param); internal;
var
  fu: integer;
begin
  fu := fu_of(opc);
  new_seq_num := ((it + oli_iter[num]) * oli_ii + oli_slot[num]) * 4 + fu;
end;

{ build_sched_array - oli_sched_list: the scheduled instructions,
  iteration by iteration from the last, cycle by cycle, unit by unit
  (an instruction in more than one unit of a cycle once; the branch and
  the counter's decrement left out), each one's place in oli_order.
  0x257ED8, 0x158 bytes. }

procedure build_sched_array; internal;
label
  10;
var
  n, it, row: integer32;
  fu, m: integer;
  i: instr_ptr_t;
begin
  n := 1;
  for it := oli_iters downto 1 do
    for row := 1 to oli_ii do
      for fu := 0 to 3 do begin
        i := oli_sched[row, fu];
        if (i <> nil) and (oli_iter[i^.num] = it) and (i <> oli_decr)
            and (i <> oli_branch) then begin
          for m := 0 to fu - 1 do
            if oli_sched[row, m] <> nil then
              if oli_sched[row, m] = i then
                goto 10;
          oli_sched_list[n] := i;
          oli_order[i^.num] := n;
          n := n + 1;
        end;
    10:
      end;
  oli_nsched := n - 1;
  oli_sched_list[n] := nil;
end;

{ reverse_iteration_numbers - each scheduled instruction's iteration
  counted from the other end.  0x258030, 0x28 bytes, no frame. }

procedure reverse_iteration_numbers; internal;
var
  k: integer;
begin
  for k := 1 to 200 do
    if oli_iter[k] <> 0 then
      oli_iter[k] := oli_iters + 1 - oli_iter[k];
end;

{ init_software_pipelining - the loop's state cleared.  0x258058, 0x62
  bytes. }

procedure init_software_pipelining; internal;
var
  k: integer32;
begin
  for k := 1 to 200 do
    oli_2cc0[k] := false;
  oli_ip_zero := nil;
  oli_sp_zero := nil;
  oli_dp_zero := nil;
  oli_2dc8 := nil;
  oli_2dac := nil;
  oli_2e00 := -1;
  oli_prolog_last := nil;
  oli_2db0 := 0;
end;

{ add_instr_end_of_prolog_inits - a new instruction of opcode opc at
  the end of the prologue's initializations: after the last one added,
  else before the prologue block's first instruction that is numbered
  or transfers control (a new block's only instruction when there is
  none); numbered 0.  0x2580BA, 0xCA bytes. }

function add_instr_end_of_prolog_inits(
    opc: integer): instr_ptr_t; options(val_param); internal;
var
  i: instr_ptr_t;
begin
  if oli_prolog_last = nil then begin
    i := oli_prolog_bb^.first;
    while i <> nil do begin
      if i^.num <> 0 then
        exit;
      if instruction_attributes[i^.opc].class in
          [class$branch, class$fp_branch, class$jump] then
        exit;
      i := i^.next;
    end;
    if i = nil then begin
      oli_prolog_last := lir_$new_instruction(opc);
      oli_prolog_last^.bb := oli_prolog_bb;
      oli_prolog_last^.h.b2_6 := true;
      oli_prolog_bb^.first := oli_prolog_last;
      oli_prolog_bb^.last := oli_prolog_last;
      oli_prolog_last^.next := nil;
      oli_prolog_last^.prev := nil;
    end
    else
      oli_prolog_last := lir_$optimizer_new_instruction(i, opc, false);
  end
  else
    oli_prolog_last := lir_$optimizer_new_instruction(oli_prolog_last, opc,
        true);
  oli_prolog_last^.num := 0;
  add_instr_end_of_prolog_inits := oli_prolog_last;
end;

{ get_dp_zero - a floating pair register holding 0.0, made in the
  prologue: when oli_dp_zero is set, a copyd of it into a new pair
  (kept in oli_sp_zero: the image's), else a loadd of the literal 0.0
  into a new pair kept in oli_dp_zero; the new pair returned.
  0x258184, 0x1D6 bytes: the pair's halves are operands 3 and 4 (the
  second half the live range's mate); the operands' rrp bytes stored
  whole (`move.b #17,(45,A0)'), their kinds by `andi.b #-32; or.b'. }

function get_dp_zero: lr_ptr_t; internal;
var
  i: instr_ptr_t;
  lr: lr_ptr_t;
begin
  if oli_dp_zero <> nil then begin
    i := add_instr_end_of_prolog_inits(161);    { copyd }
    i^.h.preference := true;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 17;
    i^.opnds[1].h.kind := operand$fp_reg_pair;
    i^.opnds[1].h.num := 1;
    i^.opnds[1].ptr := oli_dp_zero;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 9;
    i^.opnds[2].h.kind := operand$fp_reg_pair;
    lr := lir_$new_live_range_for_kind(3);
    i^.opnds[2].ptr := lr;
    bv_$make_live_range_complex(oli_rtn, lr);
    i^.opnds[2].h.num := 2;
    oli_sp_zero := i^.opnds[2].ptr;
    opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 18;
    i^.opnds[3].h.kind := operand$fp_reg_pair;
    i^.opnds[3].h.num := 3;
    i^.opnds[3].ptr := oli_dp_zero^.mate;
    opnd_bytes_ptr_t(addr(i^.opnds[4]))^.rrp := 10;
    i^.opnds[4].h.kind := operand$fp_reg_pair;
    i^.opnds[4].ptr := lr_ptr_t(i^.opnds[2].ptr)^.mate;
  end
  else begin
    i := add_instr_end_of_prolog_inits(109);    { loadd }
    discard(sym_$reformat_literal_operand(dpcontk(0.0), 4, 0,
        addr(i^.opnds[1])));
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$displacement_literal_pool;
    i^.opnds[1].h.bytes := 4;
    i^.opnds[1].h.num := 1;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
    i^.opnds[2].h.kind := operand$ip_reg_like;
    i^.opnds[2].value := lir_main_c48;
    i^.opnds[2].h.num := 2;
    opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 9;
    i^.opnds[3].h.kind := operand$fp_reg_pair;
    i^.opnds[3].ptr := lir_$new_live_range_fp_reg_pair;
    bv_$make_live_range_complex(oli_rtn, i^.opnds[3].ptr);
    i^.opnds[3].h.num := 3;
    oli_dp_zero := i^.opnds[3].ptr;
    lr := oli_dp_zero;
    opnd_bytes_ptr_t(addr(i^.opnds[4]))^.rrp := 10;
    i^.opnds[4].h.kind := operand$fp_reg_pair;
    i^.opnds[4].ptr := lr_ptr_t(i^.opnds[3].ptr)^.mate;
  end;
  i^.opnds[4].h.num := 4;
  i^.h.may_generate_an_exception := false;
  get_dp_zero := lr;
end;

{ get_sp_zero - a floating register holding 0.0: a moves of
  oli_sp_zero into a new one, or a loads of the literal into the
  register kept there.  0x258362, 0x16E bytes. }

function get_sp_zero: lr_ptr_t; internal;
var
  i: instr_ptr_t;
  lr: lr_ptr_t;
begin
  if oli_sp_zero <> nil then begin
    i := add_instr_end_of_prolog_inits(146);    { moves }
    i^.h.preference := true;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$fp_reg;
    i^.opnds[1].h.num := 1;
    i^.opnds[1].ptr := oli_sp_zero;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 8;
    i^.opnds[2].h.kind := operand$fp_reg;
    i^.opnds[2].ptr := lir_$new_live_range_for_kind(2);
    lr := i^.opnds[2].ptr;
    bv_$make_live_range_complex(oli_rtn, lr);
    i^.opnds[2].h.num := 2;
  end
  else begin
    i := add_instr_end_of_prolog_inits(106);    { loads }
    discard(sym_$reformat_literal_operand(rlcontk(0.0), 4, 0,
        addr(i^.opnds[1])));
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$displacement_literal_pool;
    i^.opnds[1].h.bytes := 4;
    i^.opnds[1].h.num := 1;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
    i^.opnds[2].h.kind := operand$ip_reg_like;
    i^.opnds[2].value := lir_main_c48;
    i^.opnds[2].h.num := 2;
    opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
    i^.opnds[3].h.kind := operand$fp_reg;
    i^.opnds[3].ptr := lir_$new_live_range_for_kind(2);
    lr := i^.opnds[3].ptr;
    bv_$make_live_range_complex(oli_rtn, lr);
    i^.opnds[3].h.num := 3;
    oli_sp_zero := i^.opnds[3].ptr;
  end;
  i^.h.may_generate_an_exception := false;
  get_sp_zero := lr;
end;

{ get_ip_zero - an integer register holding 0: a move of oli_ip_zero
  into a new one, or an add of the zero register to itself (lir_main_
  c4c's segment) at the head of the prologue block into the register
  kept there.  0x2584D0, 0x152 bytes: the add's opcode and `after'
  pushed as one longword (pattern 105). }

function get_ip_zero: lr_ptr_t; internal;
var
  i: instr_ptr_t;
  lr: lr_ptr_t;
begin
  if oli_ip_zero <> nil then begin
    i := add_instr_end_of_prolog_inits(75);     { move }
    i^.h.preference := true;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$ip_reg;
    i^.opnds[1].h.num := 1;
    i^.opnds[1].ptr := oli_ip_zero;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 8;
    i^.opnds[2].h.kind := operand$ip_reg;
    i^.opnds[2].ptr := lir_$new_live_range_for_kind(1);
    lr := i^.opnds[2].ptr;
    bv_$make_live_range_complex(oli_rtn, lr);
    i^.opnds[2].h.num := 2;
  end
  else begin
    i := lir_$optimizer_new_instruction(oli_prolog_bb^.first, 79, false);
    i^.num := 0;                                { add }
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$ip_reg_like;
    i^.opnds[1].value := lir_main_c4c;
    i^.opnds[1].h.num := 1;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
    i^.opnds[2].h.kind := operand$ip_reg_like;
    i^.opnds[2].value := lir_main_c4c;
    i^.opnds[2].h.num := 2;
    opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
    i^.opnds[3].h.kind := operand$ip_reg;
    i^.opnds[3].ptr := lir_$new_live_range_for_kind(1);
    lr := i^.opnds[3].ptr;
    bv_$make_live_range_complex(oli_rtn, lr);
    i^.opnds[3].h.num := 3;
    oli_ip_zero := i^.opnds[3].ptr;
  end;
  i^.h.may_generate_an_exception := false;
  get_ip_zero := lr;
end;

{ init_sched - the schedule emptied: the flags, the queue (its nodes
  chained free), the cycles' units; the counters reset.  0x258622, 0xC2
  bytes. }

procedure init_sched; internal;
var
  k, fu: integer32;
begin
  for k := 1 to 200 do
    oli_2bf8[k] := false;
  oli_2e54 := 1;
  oli_qfree := addr(oli_qnodes[0]);
  oli_queue := nil;
  for k := 1 to 200 do
    for fu := 0 to 3 do
      oli_sched[k, fu] := nil;
  for k := 0 to 198 do
    oli_qnodes[k].next := addr(oli_qnodes[k + 1]);
  oli_qnodes[199].next := nil;
  oli_2e20 := 0;
  oli_2e1c := 0;
  oli_2e18 := 0;
  oli_2e14 := 0;
  oli_2e44 := oli_2e48;
  oli_2e2c := oli_ii;
  oli_2e30 := oli_2e34;
  oli_iters := 0;
end;

{ enqueue_enabled_instruction - i put on the queue after the
  instructions of a height not below its (unsigned words).  0x2586E4,
  0x86 bytes. }

procedure enqueue_enabled_instruction(
    i: instr_ptr_t); options(val_param); internal;
var
  n, p, q: oli_qnode_ptr_t;
begin
  n := oli_qfree;
  oli_qfree := oli_qfree^.next;
  n^.instr := i;
  if oli_queue = nil then begin
    oli_queue := n;
    n^.next := nil;
  end
  else if oli_instr_v_ptr_t(oli_queue^.instr)^.height
      < oli_instr_v_ptr_t(i)^.height then begin
    n^.next := oli_queue;
    oli_queue := n;
  end
  else begin
    p := oli_queue;
    q := oli_queue^.next;
    while q <> nil do begin
      if oli_instr_v_ptr_t(q^.instr)^.height
          < oli_instr_v_ptr_t(i)^.height then
        exit;
      p := q;
      q := q^.next;
    end;
    n^.next := q;
    p^.next := n;
  end;
end;

{ dequeue_enabled_instruction - the queue's first instruction taken
  off (its node freed); nil when empty.  0x25876A, 0x24 bytes, no
  frame. }

function dequeue_enabled_instruction: instr_ptr_t; internal;
var
  n: oli_qnode_ptr_t;
begin
  if oli_queue = nil then
    dequeue_enabled_instruction := nil
  else begin
    n := oli_queue;
    dequeue_enabled_instruction := n^.instr;
    oli_queue := n^.next;
    n^.next := oli_qfree;
    oli_qfree := n;
  end;
end;

{ oli_$begin_compilation - the bookkeeping heap made (flags 0, size 0:
  one longword, pattern 105).  0x25878E, 0x24 bytes: the name is the
  routine's 20 characters, no terminator (pattern 113). }

procedure oli_$begin_compilation;
begin
  mrh_$initialize(oli_heap, 0, 0, 'oli bookkeeping heap');
end;

{ oli_$end_compilation - nothing.  0x2587C6, 2 bytes. }

procedure oli_$end_compilation;
begin
end;

{ first_innermost_loop - the innermost interval head reached from bb
  down through the heads' first members (l74), along the members (l78)
  past those that are not heads.  0x2587C8, 0x22 bytes, no frame: A0
  (the last head reached; not set when bb is nil). }

function first_innermost_loop(
    bb: bb_ptr_t): bb_ptr_t; options(val_param); internal;
var
  h: bb_ptr_t;
begin
  while bb <> nil do
    if bb^.f.distinguished_entry then begin
      h := bb;
      bb := bb_ptr_t(bb^.l74);
    end
    else
      bb := bb^.l78;
  first_innermost_loop := h;
end;

{ next_inner_loop - cur advanced to the next innermost loop inside
  head (the first one when cur is nil): true when there is one.
  0x2587EA, 0x54 bytes. }

function next_inner_loop(
    head: bb_ptr_t;
    var cur: bb_ptr_t): boolean; options(val_param); internal;
begin
  next_inner_loop := false;
  if head = cur then
    return;
  if cur = nil then begin
    cur := first_innermost_loop(head);
    next_inner_loop := true;
    return;
  end;
  repeat
    while cur^.l78 = nil do begin
      cur := cur^.l70;
      if head = cur then
        return;
    end;
    cur := cur^.l78;
  until cur^.f.distinguished_entry;
  cur := first_innermost_loop(cur);
  next_inner_loop := true;
end;

{ assign_sequence_numbers - bb's instructions numbered 1, 2, ...
  (+42).  0x25883E, 0x1E bytes, no frame. }

procedure assign_sequence_numbers(
    bb: bb_ptr_t); options(val_param); internal;
var
  i: instr_ptr_t;
  n: integer32;
begin
  n := 1;
  i := bb^.first;
  while i <> nil do begin
    i^.num := n;
    n := n + 1;
    i := i^.next;
  end;
end;

{ size_and_shape_ok - bb is a loop oli takes: neither an irreducible
  loop's nor an entry block, one edge out to a second edge whose own
  successor list ends there, the loop closed on bb (bb the first edge's
  target's head, or the second's target bb), no call, at most 100
  instructions not of the classes entry, fp_branch, jump, enable,
  pmove, label and join_bp (the set 16#40C00F0), and no operand of kinds 4..6
  (physical registers).  0x25885C, 0xE4 bytes. }

function size_and_shape_ok(
    bb: bb_ptr_t): boolean; options(val_param); internal;
label
  99;
var
  e, e2: fg_edge_ptr_t;
  i: instr_ptr_t;
  n, k: integer32;
  cls: integer;
begin
  size_and_shape_ok := false;
  if bb^.f.irreducible then
    goto 99;
  if bb^.f.hidden_successor_edges then
    goto 99;
  e := bb^.succs;
  if e = nil then
    goto 99;
  if e^.next_succ = nil then
    goto 99;
  e2 := e^.next_succ;
  if e2^.next_succ <> nil then
    goto 99;
  if (e^.target <> bb) or (e2^.target^.l70 = bb) then begin
    if e^.target^.l70 = bb then
      goto 99;
    if e2^.target <> bb then
      goto 99;
  end;
  i := bb^.first;
  n := 0;
  while i <> nil do begin
    cls := ord(instruction_attributes[i^.opc].class);
    if cls = class$call then
      goto 99;
    if not (cls in [4..7, 18, 19, 26]) then
      n := n + 1;
    for k := 1 to i^.h.nopnds do
      if i^.opnds[k].h.kind in [operand$ip_reg_physical..
          operand$fp_reg_pair_physical] then
        goto 99;
    i := i^.next;
  end;
  if n <= 100 then
    size_and_shape_ok := true;
99:
end;
