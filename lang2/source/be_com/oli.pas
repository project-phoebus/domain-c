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
%include 'lang/lang/source/alias.ins.pas';
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

  { A table of longwords from the bookkeeping heap. }
  oli_longs_ptr_t = ^oli_longs_t;
  oli_longs_t = array [0..65535] of integer32;
  oli_instrs_ptr_t = ^array [0..65535] of instr_ptr_t;
  oli_bbs_ptr_t = ^array [0..65535] of bb_ptr_t;
  oli_heap_ptr_t = ^mrh_$heap_t;
  integer32_ptr_t = ^integer32;

  { A cycle's live registers (excess_register_pressure). }
  oli_live_t = record
    ip: integer32;                      { +0 }
    fp: integer32;                      { +4 }
  end;
  oli_live_ptr_t = ^array [0..65535] of oli_live_t;

  { An integer constant in a floating register (12 bytes), on
    oli_fp_consts by value. }
  oli_fpconst_ptr_t = ^oli_fpconst_t;
  oli_fpconst_t = record
    next: oli_fpconst_ptr_t;            { +0 }
    value: integer32;                   { +4 }
    lr: lr_ptr_t;                       { +8 }
  end;

  { A value to materialize in an operand (operand_gets_materialized_
    value): kind (+2) 1 a live range, 2 an operand (ptr), 3 a
    constant. }
  oli_mval_ptr_t = ^oli_mval_t;
  oli_mval_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    case integer of                     { +4 }
      1: (ptr: univ_ptr);
      2: (value: integer32);
  end;

  { An induction variable's adjustment (get_induction_variable_
    adjustment): its exposed segment (+8), the iteration (+16) whose
    value lr (+20) holds, the increment (+24); on oli_ivadjs at
    next (+4). }
  oli_ivadj_ptr_t = ^oli_ivadj_t;
  oli_ivadj_t = record
    l0: integer32;                      { +0 }
    next: oli_ivadj_ptr_t;              { +4 }
    lts: lts_ptr_t;                     { +8 }
    ilts: lts_ptr_t;                    { +12: a segment of its live
                                          range (the columns' order) }
    it: integer32;                      { +16 }
    lr: lr_ptr_t;                       { +20 }
    mv: oli_mval_t;                     { +24 }
    final: oli_mval_t;                  { +32: the adjustment after the
                                          loop }
  end;

  { A live range's replacement in a column (12 bytes). }
  oli_lrmap_ptr_t = ^oli_lrmap_t;
  oli_lrmap_t = record
    next: oli_lrmap_ptr_t;              { +0 }
    lr: lr_ptr_t;                       { +4 }
    new: lr_ptr_t;                      { +8 }
  end;
  oli_lrmaps_ptr_t = ^array [0..65535] of oli_lrmap_ptr_t;

  { A final live range's copies by column (16 bytes): its operand kind
    (+12), its segment's induction or reduction kind (+14), the copies
    (+8, columns 0 .. niters). }
  oli_col_ptr_t = ^oli_col_t;
  oli_col_t = record
    next: oli_col_ptr_t;                { +0 }
    lr: lr_ptr_t;                       { +4 }
    cols: ^array [0..65535] of lr_ptr_t;    { +8 }
    kind: integer;                      { +12 }
    ikind: integer;                     { +14 }
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
    sums: oli_longs_ptr_t;              { +12: the partial sums, by
                                          iteration and iteration }
  end;

  { A step of a data flow path (16 bytes from the bookkeeping heap): an
    instruction (+4), the operand by which it reads the previous step's
    value (+8) and the one by which it writes the next's (+12). }
  oli_step_ptr_t = ^oli_step_t;
  oli_step_t = record
    next: oli_step_ptr_t;               { +0 }
    instr: instr_ptr_t;                 { +4 }
    in_k: integer32;                    { +8 }
    out_k: integer32;                   { +12 }
  end;

  { A data flow path (8 bytes): its steps, the first the writer;
    chained at next. }
  oli_path_ptr_t = ^oli_path_t;
  oli_path_t = record
    next: oli_path_ptr_t;               { +0 }
    steps: oli_step_ptr_t;              { +4 }
  end;

  { A recurrence (28 bytes from the bookkeeping heap): from an
    instruction (+4) to one (+8) a distance (+12) of iterations later,
    the data flow paths from the second back to the first (+16);
    chained from oli_recurrences at next. }
  oli_rec_ptr_t = ^oli_rec_t;
  oli_rec_t = record
    next: oli_rec_ptr_t;                { +0 }
    from: instr_ptr_t;                  { +4 }
    upto: instr_ptr_t;                  { +8 }
    dist: integer32;                    { +12 }
    paths: oli_path_ptr_t;              { +16 }
    l20: integer32;                     { +20 }
    l24: integer32;                     { +24 }
  end;

  { An instruction's +28 as the scheduler uses it (batch A's instr_t
    l28; sched_utils' su_instr_t): the precedence height, compared
    unsigned, and its enable count (+30). }
  oli_instr_v_ptr_t = ^oli_instr_v_t;
  oli_instr_v_t = record
    space0: array [0..27] of char;
    height: 0..65535;                   { +28 }
    enable: integer;                    { +30: the count of what must be
                                          scheduled before it }
    space32: array [32..41] of char;
    unum: 0..65535;                     { +42: its number, unsigned (the
                                          sequence numbers reach 16#8000) }
  end;

  { A segment's +34 word as the scheduler uses it (batch A's lts_t
    l32's low half): the readers not yet scheduled. }
  oli_lts_v_ptr_t = ^oli_lts_v_t;
  oli_lts_v_t = record
    space0: array [0..33] of char;
    enable: integer;                    { +34 }
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

  { +0x358: the nodes of the cycles' lists of uncounted instructions
    (oli_sched's column 3), taken in order from 1. }
  oli_unodes: array [1..200] of oli_qnode_t;

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
    instruction of each functional unit (fu_of: 0 integer, 1 and 2
    floating), and (3) the list of the cycle's instructions of the
    uncounted classes (an oli_qnode_ptr_t, cast). }
  oli_sched: array [1..200, 0..3] of instr_ptr_t;

  oli_5op_k: array [1..200] of integer32;  { +0x28D8: the input of a
                                          five-operand candidate its
                                          result can share (is_5op_
                                          candidate) }
  oli_paired: array [1..200] of boolean;   { +0x2BF8: a floating
                                          instruction paired with a
                                          multiply in its cycle }
  oli_5op: array [1..200] of boolean;   { +0x2CC0: a five-operand
                                          candidate }

  { +0x2DA4 .. +0x2E72: the routine's and the loop's state. }
  oli_recurrences: oli_rec_ptr_t;       { +0x2DA8 (record_recurrence) }
  oli_ivadjs: oli_ivadj_ptr_t;          { +0x2DA4: the induction
                                          variables' adjustments }
  oli_fp_consts: oli_fpconst_ptr_t;     { +0x2DAC: the integer constants
                                          in floating registers }
  oli_cols: oli_col_ptr_t;              { +0x2DB0: the final live
                                          ranges' columns }
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
  oli_mem_lr: lr_ptr_t;                 { +0x2DC8: the memory live range
                                          the prologue's fan in writes }
  oli_copies: oli_instrs_ptr_t;         { +0x2DCC: the latest copy of
                                          each loop instruction, by its
                                          number less one (800 bytes) }
  oli_exposed: oli_lrmaps_ptr_t;        { +0x2DD0: by column (two by
                                          iteration), the exposed live
                                          ranges' replacements }
  oli_2dd4: oli_longs_ptr_t;            { +0x2DD4: by iteration }
  oli_tails: oli_bbs_ptr_t;             { +0x2DD8: the tail blocks, by
                                          iteration less one }
  oli_body: bb_ptr_t;                   { +0x2DE0: the pipelined body }
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
  oli_nmuld: integer32;                 { +0x2E04: muld's (no fp_ccs) }
  oli_nmuls: integer32;                 { +0x2E08: muls's }
  oli_n5d: integer32;                   { +0x2E0C: the double
                                          five-operand candidates }
  oli_n5s: integer32;                   { +0x2E10: the single ones }
  oli_2e14: integer32;                  { +0x2E14 }
  oli_2e18: integer32;                  { +0x2E18 }
  oli_2e1c: integer32;                  { +0x2E1C }
  oli_2e20: integer32;                  { +0x2E20 }
  oli_2e24: integer32;                  { +0x2E24 }
  oli_span: integer32;                  { +0x2E28: the span of the
                                          sequence numbers }
  oli_2e2c: integer32;                  { +0x2E2C }
  oli_2e30: integer32;                  { +0x2E30 }
  oli_nfpctl: integer32;                { +0x2E34: the fp_control
                                          instructions }
  oli_niters: integer32;                { +0x2E38: oli_iters when the
                                          schedule was made }
  oli_iters: integer32;                 { +0x2E3C: the iterations
                                          (stages) the schedule spans }
  oli_ii: integer32;                    { +0x2E40: the iteration
                                          interval (cycles) }
  oli_fp_budget: integer32;             { +0x2E44: the floating pairs
                                          the schedule may still make
                                          (oli_fp_spare at its start) }
  oli_fp_spare: integer32;              { +0x2E48: the floating
                                          instructions that pair (nfp
                                          less the interval) }
  oli_nint: integer32;                  { +0x2E4C: the integer unit's
                                          instructions }
  oli_nfp: integer32;                   { +0x2E50: the floating unit's }
  oli_nunodes: integer32;               { +0x2E54: oli_unodes used, plus
                                          one }
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
  the counter's decrement and the uncounted lists left out), each
  one's place in oli_order.
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
        if fu = 3 then
          goto 10;
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
    oli_5op[k] := false;
  oli_ip_zero := nil;
  oli_sp_zero := nil;
  oli_dp_zero := nil;
  oli_mem_lr := nil;
  oli_fp_consts := nil;
  oli_2e00 := -1;
  oli_prolog_last := nil;
  oli_cols := nil;
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
    oli_paired[k] := false;
  oli_nunodes := 1;
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
  oli_fp_budget := oli_fp_spare;
  oli_2e2c := oli_ii;
  oli_2e30 := oli_nfpctl;
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

{ mem_ref_via_non_const_induction_variable - i is a load or store
  whose base (base: a load's operand 2, a store's 3) and displacement
  (disp: operand 1, 2) are not both constant, each one either a
  constant or a register whose segment is a confirmed induction
  variable's (iv's induction lts of kind 2 at its l24).  0x258940, 0xDE
  bytes: the constant kinds the set 16#10FF0001 (none, flow_graph_edge
  .. immediate, spare_2), the registers 16#FFE (ip_reg ..
  well_behaved_memory). }

function mem_ref_via_non_const_induction_variable(
    i: instr_ptr_t;
    var base: opnd_ptr_t;
    var disp: opnd_ptr_t): boolean; options(val_param); internal;
label
  99;
var
  cls: integer;
  o: opnd_ptr_t;
  l: iv_lts_ptr_t;
begin
  mem_ref_via_non_const_induction_variable := false;
  cls := instruction_attributes[i^.opc].class;
  if cls = class$load then begin
    base := addr(i^.opnds[2]);
    o := addr(i^.opnds[1]);
  end
  else if cls = class$store then begin
    base := addr(i^.opnds[3]);
    o := addr(i^.opnds[2]);
  end
  else
    goto 99;
  disp := o;
  if base^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2] then
    if disp^.h.kind in [operand$none, operand$flow_graph_edge..
        operand$immediate, operand$spare_2] then
      goto 99;
  if not (base^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2]) then begin
    if not (base^.h.kind in [operand$ip_reg..
        operand$well_behaved_memory]) then
      goto 99;
    l := iv_lts_ptr_t(base^.lts^.l24);
    if l = nil then
      goto 99;
    if l^.h.kind <> 2 then
      goto 99;
  end;
  if not (disp^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2]) then begin
    if not (disp^.h.kind in [operand$ip_reg..
        operand$well_behaved_memory]) then
      goto 99;
    l := iv_lts_ptr_t(disp^.lts^.l24);
    if l = nil then
      goto 99;
    if l^.h.kind <> 2 then
      goto 99;
  end;
  mem_ref_via_non_const_induction_variable := true;
99:
end;

{ reduction_class_of - the classes of value (oli_red_kind's bits) s
  can be a reduction in: for the first segment of its live range in
  the block, oli_red_cls when the segment exposed at the loop's head
  (followed along the live range within the loop) is the one
  is_exposed_reduction examines; else, when s has one reader, an
  instruction that does not set the condition codes and can reduce,
  through the segment it writes, back to an exposed or join-defined
  segment (the pair's other half for a register pair half), the
  classes of that one and its opcode's.  0x258A1E, 0x208 bytes: each
  search's `for' left at its last operand when nothing matched, by a
  test of the index after the operand's (`cmp.l D4,D1; beq'). }

function reduction_class_of(
    s: lts_ptr_t): integer; options(val_param); internal;
label
  10, 20, 30, 99;
var
  r: integer;
  t: lts_ptr_t;
  i: instr_ptr_t;
  n, k, c: integer32;
begin
  r := 0;
  if s^.f2.first_in_bb then begin
    if s^.refs^.link <> nil then
      goto 99;
    t := s;
    while (t^.next <> nil) and (t^.next^.bb = oli_bb) and
        not t^.f2.exposed do
      t := t^.next;
    if not t^.f2.exposed then
      goto 99;
    if t <> oli_red_lts then
      goto 99;
    r := oli_red_cls;
    goto 99;
  end;
  t := s;
  if s^.refs^.link^.link <> nil then
    goto 99;
  i := utils_ins_$operands_instruction(s^.refs^.link);
  if i^.h.sets_cc then
    goto 99;
  if oli_red_kind[i^.opc] = 0 then
    goto 99;
  if i^.h.fp_ccs then
    goto 99;
  n := i^.h.nopnds;
  if (opnd_bytes_ptr_t(s^.refs^.link)^.rrp & 3) <> 0 then begin
    for k := 1 to n do begin
      if i^.opnds[k].h.kind in [operand$ip_reg..
          operand$well_behaved_memory] then
        if i^.opnds[k].lts^.lr = s^.refs^.link^.lts^.lr^.mate then begin
          t := i^.opnds[k].lts;
          goto 10;
        end;
      if k = n then
        goto 99;
    end;
10:
    if not is_exposed_or_produced_by_jbi(t) then
      goto 99;
    if t^.refs^.link^.link <> nil then
      goto 99;
    for k := 1 to n do begin
      if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then begin
        t := i^.opnds[k].lts;
        goto 20;
      end;
      if k = n then
        goto 99;
    end;
20:
    if t^.lr^.mate = nil then
      goto 99;
    goto 30;
  end
  else begin
    c := 0;
    for k := 1 to n do
      if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then begin
        c := c + 1;
        if c > 1 then
          goto 99;
      end;
    if n - 1 < 0 then
      goto 99;
    for k := 1 to n do
      if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then begin
        t := i^.opnds[k].lts;
        goto 30;
      end;
    goto 99;
  end;
30:
  r := reduction_class_of(t) & oli_red_kind[i^.opc];
99:
  reduction_class_of := r;
end;

{ create_reduction_variable - a reduction of class cls for s's live
  range, put on oli_reductions and at the l24 of s, the live range's
  final segment in the loop, and, for a pair, its mate's exposed and
  final segments there.  0x258C26, 0x9A bytes. }

procedure create_reduction_variable(
    s: lts_ptr_t;
    cls: integer); options(val_param); internal;
var
  r: oli_red_ptr_t;
begin
  r := mrh_$alloc(oli_heap, 16);
  r^.lr := s^.lr;
  r^.next := oli_reductions;
  r^.h.kind := 5;
  r^.cls := cls;
  oli_reductions := r;
  s^.l24 := integer32(r);
  utils_$find_final_lts(s^.lr, oli_bb)^.l24 := integer32(r);
  if s^.lr^.mate <> nil then begin
    utils_$find_exposed_lts(s^.lr^.mate, oli_bb)^.l24 := integer32(r);
    utils_$find_final_lts(s^.lr^.mate, oli_bb)^.l24 := integer32(r);
  end;
end;

{ is_exposed_reduction - s (exposed at the loop's head) is a reduction
  in exactly one class, made one: unless cargs_$options.fpra, not for a
  floating register (rrp's fp_reg_even_only, fp_reg_odd_only, fp_reg).
  The segment examined is s, or for a join birthpoint's the join's
  result.  0x258CC0, 0xC6 bytes: fpra tested with `btst D2,...', D2
  holding false (bit 0; pattern 123); the join's result is left unset
  when the join writes nothing (kept). }

function is_exposed_reduction(
    s: lts_ptr_t): boolean; options(val_param); internal;
label
  99;
var
  i: instr_ptr_t;
  t: lts_ptr_t;
  c, k: integer;
  n: integer32;
begin
  is_exposed_reduction := false;
  if not cargs_$options.fpra then
    if (integer(s^.rrp) & 16#4003) <> 0 then
      goto 99;
  oli_red_lts := s;
  i := utils_ins_$operands_instruction(s^.refs);
  if instruction_attributes[i^.opc].class = class$join_bp then begin
    for n := 1 to i^.h.nopnds do
      if (opnd_bytes_ptr_t(addr(i^.opnds[n]))^.rrp & 12) <> 0 then begin
        t := i^.opnds[n].lts;
        exit;
      end;
  end
  else
    t := s;
  c := reduction_class_of(t);
  for k := 0 to 2 do
    if c = lshft(1, k) then begin
      create_reduction_variable(s, k);
      is_exposed_reduction := true;
      exit;
    end;
99:
end;

{ induction_increment_of - the increment per iteration of the address
  a load or store's operands a and b compute: each operand's variable's
  increment (0 for a constant), scaled by its shift (+2 bits 5..4);
  b's left out of a postmodify (+3 bits 7..6 = 1).  0x258D86, 0x10A
  bytes. }

function induction_increment_of(
    a: opnd_ptr_t;
    b: opnd_ptr_t;
    i: instr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  ea, eb: iv_expr_ptr_t;
  sh: integer;
begin
  if a^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2] then
    ea := iv_utils_$create_value_expression(0)
  else begin
    ea := iv_lts_ptr_t(a^.lts^.l24)^.ivar^.incr;
    sh := a^.h.count;
    if sh <> 0 then
      ea := iv_utils_$create_mul_expression(
          iv_utils_$create_value_expression(lshft(1, sh)), ea);
  end;
  if (i^.h.modify = 1) or (b^.h.kind in [operand$none,
      operand$flow_graph_edge..operand$immediate, operand$spare_2]) then
    eb := iv_utils_$create_value_expression(0)
  else begin
    eb := iv_lts_ptr_t(b^.lts^.l24)^.ivar^.incr;
    sh := b^.h.count;
    if sh <> 0 then
      eb := iv_utils_$create_mul_expression(
          iv_utils_$create_value_expression(lshft(1, sh)), eb);
  end;
  induction_increment_of := iv_utils_$canonicalize_expression(
      iv_utils_$duplicate_expression(
      iv_utils_$create_add_expression(ea, eb)));
end;

{ induction_initial_value_of - the address a load or store's operands
  a and b compute in the first iteration: each operand's variable's
  initial value plus its segment's increment from it (the operand
  itself for a constant, b's value for an immediate), scaled by its
  shift; b's left out of a postmodify.  0x258E90, 0x15C bytes. }

function induction_initial_value_of(
    a: opnd_ptr_t;
    b: opnd_ptr_t;
    i: instr_ptr_t): iv_expr_ptr_t; options(val_param); internal;
var
  ea, eb: iv_expr_ptr_t;
  l: iv_lts_ptr_t;
  sh: integer;
begin
  if a^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2] then
    ea := iv_utils_$create_operand_expression(a^)
  else begin
    l := iv_lts_ptr_t(a^.lts^.l24);
    ea := l^.ivar^.init;
    if l^.incr <> nil then
      ea := iv_utils_$create_add_expression(ea, l^.incr);
    sh := a^.h.count;
    if sh <> 0 then
      ea := iv_utils_$create_mul_expression(
          iv_utils_$create_value_expression(lshft(1, sh)), ea);
  end;
  if i^.h.modify = 1 then
    eb := iv_utils_$create_value_expression(0)
  else if b^.h.kind in [operand$none, operand$flow_graph_edge..
      operand$immediate, operand$spare_2] then begin
    if b^.h.kind = operand$immediate then
      eb := iv_utils_$create_value_expression(b^.value)
    else
      eb := iv_utils_$create_operand_expression(b^);
  end
  else begin
    l := iv_lts_ptr_t(b^.lts^.l24);
    eb := l^.ivar^.init;
    if l^.incr <> nil then
      eb := iv_utils_$create_add_expression(eb, l^.incr);
    sh := b^.h.count;
    if sh <> 0 then
      eb := iv_utils_$create_mul_expression(
          iv_utils_$create_value_expression(lshft(1, sh)), eb);
  end;
  induction_initial_value_of := iv_utils_$canonicalize_expression(
      iv_utils_$duplicate_expression(
      iv_utils_$create_add_expression(ea, eb)));
end;

{ iv_expressions_differ_by_const - a and b are the same address but
  for a constant, d (a - b).  0x258FEC, 0x6C bytes. }

function iv_expressions_differ_by_const(
    a: iv_expr_ptr_t;
    b: iv_expr_ptr_t;
    out d: integer32): boolean; options(val_param); internal;
var
  e: iv_expr_ptr_t;
begin
  iv_expressions_differ_by_const := false;
  if iv_utils_$compare_address_expressions(a, b) then begin
    e := iv_utils_$canonicalize_expression(
        iv_utils_$create_sub_expression(iv_utils_$duplicate_expression(a),
        iv_utils_$duplicate_expression(b)));
    if e^.kind = iv_value then begin
      d := e^.value;
      iv_expressions_differ_by_const := true;
    end;
  end;
end;

{ record_recurrence - a recurrence from a to b d iterations later (from
  b to a, -d, for d <= 0) put on oli_recurrences.  0x259058, 0x66
  bytes. }

procedure record_recurrence(
    a: instr_ptr_t;
    b: instr_ptr_t;
    d: integer32); options(val_param); internal;
var
  r: oli_rec_ptr_t;
begin
  r := mrh_$alloc(oli_heap, 28);
  if d > 0 then begin
    r^.from := a;
    r^.upto := b;
    r^.dist := d;
  end
  else begin
    r^.from := b;
    r^.upto := a;
    r^.dist := -d;
  end;
  r^.l20 := 0;
  r^.next := oli_recurrences;
  oli_recurrences := r;
end;

{ delay_along_data_flow_path - the cycles a data flow path takes: for
  each step the delays of the writer's operand and of the reader's,
  and one more unless either instruction is of the classes
  size_and_shape_ok does not count.  0x2590BE, 0x98 bytes. }

function delay_along_data_flow_path(
    p: oli_step_ptr_t): integer32; options(val_param); internal;
var
  d: integer32;
  q: oli_step_ptr_t;
begin
  d := 0;
  while (p <> nil) and (p^.next <> nil) do begin
    q := p^.next;
    d := d + (p^.instr^.opnds[p^.out_k].h.b2_3_0
        + q^.instr^.opnds[q^.in_k].h.b2_3_0);
    if not (instruction_attributes[p^.instr^.opc].class in
        [4..7, 18, 19, 26]) then
      if not (instruction_attributes[q^.instr^.opc].class in
          [4..7, 18, 19, 26]) then
        d := d + 1;
    p := q;
  end;
  delay_along_data_flow_path := d;
end;

{ data_flow_paths - the paths of data flow from i to target: for each
  register i writes, each reader, the reader itself when it is target
  (a path of two steps), else the paths from the reader, each given i
  as its first step.  0x259156, 0x150 bytes: the list from the reader
  is put in front of those found so far by its first cell (its link
  set to them), and the walk that adds i's step then goes on through
  them too (kept). }

function data_flow_paths(
    i: instr_ptr_t;
    target: instr_ptr_t): oli_path_ptr_t; options(val_param); internal;
var
  res, c: oli_path_ptr_t;
  n, s: oli_step_ptr_t;
  k: integer32;
  o, r: opnd_ptr_t;
  ri: instr_ptr_t;
begin
  res := nil;
  for k := 1 to i^.h.nopnds do begin
    o := addr(i^.opnds[k]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        r := o^.link;
        while r <> nil do begin
          ri := utils_ins_$operands_instruction(r);
          if ri = target then begin
            n := mrh_$alloc(oli_heap, 16);
            n^.next := nil;
            n^.instr := target;
            n^.in_k := r^.h.num;
            c := mrh_$alloc(oli_heap, 8);
            c^.steps := n;
            s := mrh_$alloc(oli_heap, 16);
            s^.next := c^.steps;
            c^.steps := s;
            s^.instr := i;
            s^.out_k := o^.h.num;
            c^.next := res;
            res := c;
          end
          else begin
            c := data_flow_paths(ri, target);
            if c <> nil then begin
              c^.next := res;
              res := c;
              repeat
                s := mrh_$alloc(oli_heap, 16);
                s^.next := c^.steps;
                c^.steps := s;
                s^.instr := i;
                s^.out_k := o^.h.num;
                s^.next^.in_k := r^.h.num;
                c := c^.next;
              until c = nil;
            end;
          end;
          r := r^.link;
        end;
      end;
  end;
  data_flow_paths := res;
end;

{ find_data_flow_paths - each recurrence's paths, from its later
  instruction back to its earlier.  0x2592A6, 0x2E bytes. }

procedure find_data_flow_paths; internal;
var
  r: oli_rec_ptr_t;
begin
  r := oli_recurrences;
  while r <> nil do begin
    r^.paths := data_flow_paths(r^.upto, r^.from);
    r := r^.next;
  end;
end;

{ simple_test - for two references with constant increments a and b
  whose initial addresses e1, e2 differ by a constant d, of sizes x and
  y (true: oli_$compare_memory_references takes them as disjoint): d
  at least the larger size with equal nonzero
  increments; else, unequal increments, d mod (b - a) nonzero and equal
  sizes, or a remainder (d mod (b - a), or (b - a) mod d when b - a is
  not below d) beyond the larger size; or a zero remainder with d and
  b - a of opposite signs.  0x2592D4, 0xE8 bytes: m$ois$lll the
  remainder. }

function simple_test(
    a: integer32;
    b: integer32;
    e1: iv_expr_ptr_t;
    e2: iv_expr_ptr_t;
    x: integer32;
    y: integer32): boolean; options(val_param); internal;
label
  99;
var
  dep: boolean;
  d, m, diff, r: integer32;
begin
  dep := false;
  if iv_expressions_differ_by_const(e1, e2, d) then begin
    m := x;
    if m < y then
      m := y;
    if abs(d) >= m then
      if a = b then
        if d <> 0 then begin
          dep := true;
          goto 99;
        end;
    if a = b then
      goto 99;
    diff := b - a;
    r := d mod diff;
    if r <> 0 then begin
      if x = y then begin
        dep := true;
        goto 99;
      end;
      if diff < d then
        if abs(r) > m then begin
          dep := true;
          goto 99;
        end;
      if abs(diff mod d) > m then
        dep := true;
    end
    else if ((d > 0) and (diff < 0)) or ((d < 0) and (diff > 0)) then
      dep := true;
  end;
99:
  simple_test := dep;
end;

{ gcd_test - references with increments a and b and initial addresses
  differing by a constant d: a remainder of d by gcd(a, b) with equal
  sizes, or one not below the larger size.  0x2593BC, 0x8A bytes. }

function gcd_test(
    a: integer32;
    b: integer32;
    e1: iv_expr_ptr_t;
    e2: iv_expr_ptr_t;
    x: integer32;
    y: integer32): boolean; options(val_param); internal;
var
  dep: boolean;
  d, m: integer32;
begin
  dep := false;
  if iv_expressions_differ_by_const(e1, e2, d) then
    if ((d mod gcd(a, b)) <> 0) and (x = y) then
      dep := true
    else begin
      m := x;
      if m < y then
        m := y;
      if d mod gcd(a, b) >= m then
        dep := true;
    end;
  gcd_test := dep;
end;

{ slope_test - references with increments a and b and initial addresses
  differing by a constant d: |d| at least the larger size with the
  increments of opposite signs moving apart, or d zero and both
  increments of one sign at least that large.  0x259446, 0xB2 bytes. }

function slope_test(
    a: integer32;
    b: integer32;
    e1: iv_expr_ptr_t;
    e2: iv_expr_ptr_t;
    x: integer32;
    y: integer32): boolean; options(val_param); internal;
var
  dep: boolean;
  d, m: integer32;
begin
  dep := false;
  if iv_expressions_differ_by_const(e1, e2, d) then begin
    m := x;
    if m < y then
      m := y;
    if (abs(d) >= m) and (((a < 0) and (b > 0) and (d < 0)) or
        ((d > 0) and (a > 0) and (b < 0))) then
      dep := true
    else if (d = 0) and (abs(a) >= m) and (abs(b) >= m) then
      if ((a > 0) and (b > 0)) or ((a < 0) and (b < 0)) then
        dep := true;
  end;
  slope_test := dep;
end;

{ constant_trip_count - n the loop's trip count when the counter's
  initial value is a constant (that plus one): the counter's exposed
  segment in the loop, its induction variable's initial value.
  0x2594F8, 0x56 bytes. }

function constant_trip_count(
    out n: integer32): boolean; internal;
var
  s: lts_ptr_t;
  e: iv_expr_ptr_t;
begin
  constant_trip_count := false;
  s := oli_bb^.exposed;
  while s <> nil do begin
    if s^.lr = oli_counter then
      exit;
    s := s^.next_exposed;
  end;
  e := iv_lts_ptr_t(s^.l24)^.ivar^.init;
  if e^.kind = iv_value then begin
    constant_trip_count := true;
    n := e^.value + 1;
  end;
end;

{ banarjees_test - with a constant trip count n and equal sizes,
  references with increments a and b and initial addresses differing by
  d: the bounds of d's change over the loop (Banerjee's) both of one
  sign.  0x25954E, 0xEE bytes: m$mis$lll the products. }

function banarjees_test(
    a: integer32;
    b: integer32;
    e1: iv_expr_ptr_t;
    e2: iv_expr_ptr_t;
    x: integer32;
    y: integer32): boolean; options(val_param); internal;
var
  dep: boolean;
  n, d, hi, lo: integer32;
begin
  dep := false;
  if constant_trip_count(n) then
    if iv_expressions_differ_by_const(e1, e2, d) then
      if x = y then begin
        if a >= 0 then
          if b >= 0 then begin
            lo := d - b * n;
            hi := a * n + d;
          end
          else begin
            lo := d;
            hi := (a - b) * n + d;
          end
        else if b >= 0 then begin
          lo := (a - b) * n + d;
          hi := d;
        end
        else begin
          lo := a * n + d;
          hi := d - b * n;
        end;
        if ((hi < 0) and (lo < 0)) or ((hi > 0) and (lo > 0)) then
          dep := true;
      end;
  banarjees_test := dep;
end;

{ recurrence_test - references i1, i2 with equal increments a and
  initial addresses differing by d make a recurrence, recorded: for a
  zero increment, the same address when one is a store (distance 1),
  or d below either size; else d a multiple of a when one is a store
  (distance d div a).  0x25963C, 0xFA bytes: m$dis$lll the quotient. }

function recurrence_test(
    a: integer32;
    b: integer32;
    e1: iv_expr_ptr_t;
    e2: iv_expr_ptr_t;
    i1: instr_ptr_t;
    i2: instr_ptr_t;
    x: integer32;
    y: integer32): boolean; options(val_param); internal;
label
  99;
var
  dep: boolean;
  d: integer32;
begin
  dep := false;
  if iv_expressions_differ_by_const(e1, e2, d) then
    if a = b then
      if a = 0 then begin
        if d = 0 then begin
          if (instruction_attributes[i1^.opc].class <> class$store) and
              (instruction_attributes[i2^.opc].class <> class$store) then
            goto 99;
        end
        else if (d >= x) and (d >= y) then
          goto 99;
        record_recurrence(i1, i2, 1);
        dep := true;
      end
      else if d mod a = 0 then
        if (instruction_attributes[i1^.opc].class = class$store) or
            (instruction_attributes[i2^.opc].class = class$store) then begin
          record_recurrence(i1, i2, d div a);
          dep := true;
        end;
99:
  recurrence_test := dep;
end;

{ OLI_$COMPARE_MEMORY_REFERENCES - the address comparison mmt_utils
  uses while oli runs (oli_$process_routine sets it): mmt_utils_$addr_
  compare's answer, refined for a store and another load or store whose
  addresses are induction expressions: 3 (disjoint) when the increments
  are constants and simple_test answers true, or when increments and
  initial values differ by constants not dividing; oli_mem_dep 2 for
  references not so addressed, and 1 when one of the dependence tests
  finds a dependence (unless the alias descriptors say they are
  unrelated).  0x259736, 0x312 bytes: the sizes 1 shl (the opcode's
  +19 bits 2..0); simple_test given init_b in A0 (the same value). }

function oli_$compare_memory_references(
    a: instr_ptr_t;
    b: instr_ptr_t;
    report: boolean;
    out disp: integer32): integer;
label
  99;
var
  r: integer;
  ca, cb: integer;
  va: boolean;
  base_a, disp_a, base_b, disp_b: opnd_ptr_t;
  inc_a, inc_b, init_a, init_b: iv_expr_ptr_t;
  sa, sb, d1, d2: integer32;
begin
  if a = b then begin
    r := 1;
    goto 99;
  end;
  r := mmt_utils_$addr_compare(a, b, report, disp);
  ca := instruction_attributes[a^.opc].class;
  cb := instruction_attributes[b^.opc].class;
  if (ca <> class$store) and (cb <> class$store) then
    goto 99;
  if oli_mem_dep = 2 then
    goto 99;
  if not ((ca in [class$load, class$store]) and
      (cb in [class$load, class$store])) then
    goto 99;
  va := mem_ref_via_non_const_induction_variable(a, base_a, disp_a);
  if not (mem_ref_via_non_const_induction_variable(b, base_b, disp_b)
      and va) then begin
    oli_mem_dep := 2;
    goto 99;
  end;
  inc_a := induction_increment_of(base_a, disp_a, a);
  inc_b := induction_increment_of(base_b, disp_b, b);
  init_a := induction_initial_value_of(base_a, disp_a, a);
  init_b := induction_initial_value_of(base_b, disp_b, b);
  sa := lshft(1, instruction_attributes[a^.opc].w18 & 7);
  sb := lshft(1, instruction_attributes[b^.opc].w18 & 7);
  if (r <> 1) and (r <> 3) then
    if (inc_a^.kind = iv_value) and (inc_b^.kind = iv_value) then begin
      if simple_test(inc_a^.value, inc_b^.value, init_a, init_b, sa,
          sb) then
        r := 3;
    end
    else begin
      va := iv_expressions_differ_by_const(inc_a, inc_b, d1);
      if iv_expressions_differ_by_const(init_a, init_b, d2) and va then
        if sa = sb then
          if d2 mod d1 <> 0 then
            r := 3;
    end;
  if a^.h.b2_7 and b^.h.b2_7 then
    if not alias_$related(alias_$desc_ptr_t(integer32(a) - 24)^,
        alias_$desc_ptr_t(integer32(b) - 24)^) then
      goto 99;
  oli_mem_dep := 2;
  if (inc_a^.kind = iv_value) and (inc_b^.kind = iv_value) then
    if gcd_test(inc_a^.value, inc_b^.value, init_a, init_b, sa, sb)
        or slope_test(inc_a^.value, inc_b^.value, init_a, init_b, sa, sb)
        or banarjees_test(inc_a^.value, inc_b^.value, init_a, init_b, sa,
        sb)
        or recurrence_test(inc_a^.value, inc_b^.value, init_a, init_b, a,
        b, sa, sb) then
      oli_mem_dep := 1;
99:
  oli_$compare_memory_references := r;
end;

{ analyze_memory_references - bb's memory references put into MMT_SEQs
  (comparing them through oli_$compare_memory_references, which sets
  oli_mem_dep); oli_mem_dep returned.  0x259A48, 0x1C bytes. }

function analyze_memory_references(
    bb: bb_ptr_t): integer; options(val_param); internal;
begin
  mmt_utils_$analyze_one_bb(oli_rtn, bb, 0);
  analyze_memory_references := oli_mem_dep;
end;

{ analyze_dependencies - what keeps bb's iterations apart: 2 (they
  cannot overlap) when a register live around the loop (its final
  segment reaching the head's exposed one, not memory) is neither an
  induction variable nor a reduction; else the memory references'
  answer (0 none, 1 recurrences, 2 not analysable).  0x259A64, 0x9A
  bytes. }

function analyze_dependencies(
    bb: bb_ptr_t): integer; options(val_param); internal;
label
  99;
var
  s, t: lts_ptr_t;
begin
  oli_mem_dep := 0;
  oli_recurrences := nil;
  oli_bb := bb;
  s := bb^.finals;
  while s <> nil do begin
    t := s;
    while (t^.next <> nil) and (t^.next^.bb = bb) and
        not t^.f2.exposed do
      t := t^.next;
    if t^.f2.exposed and (t <> s) then
      if not (t^.refs^.h.kind in [operand$argument_block_memory..
          operand$well_behaved_memory]) then
        if t^.l24 = 0 then
          if not is_exposed_reduction(t) then begin
            analyze_dependencies := 2;
            goto 99;
          end;
    s := s^.next_final;
  end;
  analyze_dependencies := analyze_memory_references(bb);
99:
end;

{ modified - the last operand referring to s modifies it.  0x259AFE,
  0x24 bytes, no frame. }

function modified(
    s: lts_ptr_t): boolean; options(val_param); internal;
var
  o: opnd_ptr_t;
begin
  o := s^.refs;
  while o^.link <> nil do
    o := o^.link;
  modified := o^.h.modify;
end;

{ parity_matches - i's operands j and k ask for the same register
  halves (rrp's fp_reg_even_only and fp_reg_odd_only).  0x259B22, 0x58
  bytes. }

function parity_matches(
    i: instr_ptr_t;
    j: integer32;
    k: integer32): boolean; options(val_param); internal;
begin
  parity_matches := (opnd_bytes_ptr_t(addr(i^.opnds[j]))^.rrp & 3)
      = (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 3);
end;

{ can_join - segments a and b, of simple live ranges (no complex id),
  can share a register: a exposed and not read, or not exposed and
  read once.  0x259B7A, 0x62 bytes. }

function can_join(
    a: lts_ptr_t;
    b: lts_ptr_t): boolean; options(val_param); internal;
begin
  can_join := false;
  if (a^.lr^.id = 0) and (b^.lr^.id = 0) then
    if a^.f2.exposed and (a^.refs^.link = nil) then
      can_join := true
    else if not a^.f2.exposed then
      if a^.refs^.link^.link = nil then
        can_join := true;
end;

{ is_5op_candidate - a floating add or subtract that can become a
  five-operand instruction (the result written into one of its inputs,
  oli_5op_k the input): already so (its result modifies, or a subtract's
  operand 2 intends to), or an input register not modified later that
  can share the result's register with matching halves (oli_5op set);
  truncsi and truncdi always.  0x259BDC, 0x33C bytes: addd's search
  goes on after a match and tests can_join twice with the same
  operands (kept). }

function is_5op_candidate(
    i: instr_ptr_t): boolean; options(val_param); internal;
label
  10, 20, 99;
var
  res: boolean;
  k: integer32;
  s: lts_ptr_t;
begin
  res := false;
  case i^.opc of
    154: begin                          { adds }
      if i^.opnds[3].h.modify then begin
        res := true;
        oli_5op_k[i^.num] := 2;
        goto 99;
      end;
      for k := 2 downto 1 do begin
        s := i^.opnds[k].lts;
        if i^.opnds[k].h.kind in [operand$ip_reg..
            operand$well_behaved_memory] then
          if not modified(s) then
            if can_join(s, i^.opnds[3].lts) and parity_matches(i, k, 3)
                then begin
              res := true;
              oli_5op[i^.num] := res;
              oli_5op_k[i^.num] := k;
              goto 99;
            end;
      end;
    end;
    171: begin                          { addd }
      if i^.opnds[3].h.modify and i^.opnds[6].h.modify then begin
        res := true;
        goto 10;
      end;
      for k := 2 downto 1 do
        if i^.opnds[k].h.kind in [operand$ip_reg..
            operand$well_behaved_memory] then
          if i^.opnds[k + 3].h.kind in [operand$ip_reg..
              operand$well_behaved_memory] then
            if not (modified(i^.opnds[k].lts) or
                modified(i^.opnds[k + 3].lts)) then
              if can_join(i^.opnds[k].lts, i^.opnds[3].lts)
                  and can_join(i^.opnds[k].lts, i^.opnds[3].lts)
                  and parity_matches(i, k, 3)
                  and parity_matches(i, k + 1, 6) then begin
                res := true;
                oli_5op[i^.num] := res;
                oli_5op_k[i^.num] := k;
              end;
    end;
    155: begin                          { subs }
      if i^.opnds[3].h.modify and i^.opnds[2].h.intend_to_modify then begin
        res := true;
        goto 10;
      end;
      s := i^.opnds[2].lts;
      if i^.opnds[2].h.kind in [operand$ip_reg..
          operand$well_behaved_memory] then
        if not modified(s) then
          if can_join(s, i^.opnds[3].lts) and parity_matches(i, 2, 3) then
              begin
            res := true;
            goto 20;
          end;
    end;
    172: begin                          { subd }
      if i^.opnds[5].h.intend_to_modify and i^.opnds[2].h.intend_to_modify
          and i^.opnds[3].h.modify and i^.opnds[6].h.modify then begin
        res := true;
        goto 10;
      end;
      if i^.opnds[2].h.kind in [operand$ip_reg..
          operand$well_behaved_memory] then
        if i^.opnds[5].h.kind in [operand$ip_reg..
            operand$well_behaved_memory] then
          if not (modified(i^.opnds[2].lts) or modified(i^.opnds[5].lts))
              then
            if can_join(i^.opnds[2].lts, i^.opnds[3].lts)
                and can_join(i^.opnds[5].lts, i^.opnds[6].lts)
                and parity_matches(i, 2, 3)
                and parity_matches(i, 5, 6) then begin
              res := true;
              goto 20;
            end;
    end;
    169, 152:                           { truncdi, truncsi }
      res := true;
    otherwise
      bug_check('OLI_$is_5op_candidate: input instruction not add or subtract%$');
  end;
  goto 99;
10:
  oli_5op_k[i^.num] := 2;
  goto 99;
20:
  oli_5op[i^.num] := res;
  oli_5op_k[i^.num] := 2;
99:
  is_5op_candidate := res;
end;

{ max_recurrence_slope - the largest, over the recurrences, of the
  longest path's delay spread over the recurrence's distance (rounded
  up).  0x259F56, 0x62 bytes. }

function max_recurrence_slope: integer32; internal;
var
  best, m, d: integer32;
  r: oli_rec_ptr_t;
  p: oli_path_ptr_t;
begin
  best := 0;
  r := oli_recurrences;
  while r <> nil do begin
    m := 0;
    p := r^.paths;
    while p <> nil do begin
      d := delay_along_data_flow_path(p^.steps);
      if m < d then
        m := d;
      p := p^.next;
    end;
    d := (m + r^.dist - 1) div r^.dist;
    if best < d then
      best := d;
    r := r^.next;
  end;
  max_recurrence_slope := best;
end;

{ iteration_interval - the cycles an iteration needs: the instructions
  counted by unit (floating: fp_double, immediate, fp_single; integer:
  the others but the uncounted classes and jumps; fp_control both),
  the floating multiplies and five-operand candidates that can pair
  (oli_n5s, oli_n5d) taken off the floating count; at least the
  recurrences' slope when there are recurrences.  0x259FB8, 0x1D2
  bytes. }

function iteration_interval: integer32; internal;
var
  i: instr_ptr_t;
  cls: integer;
  a, b, ii, r: integer32;
begin
  oli_nfp := 0;
  oli_nint := 0;
  oli_nmuls := 0;
  oli_nmuld := 0;
  oli_n5d := 0;
  oli_n5s := 0;
  oli_nfpctl := 0;
  i := oli_bb^.first;
  while i <> nil do begin
    cls := instruction_attributes[i^.opc].class;
    if cls in [class$fp_double, class$immediate, class$fp_single] then begin
      oli_nfp := oli_nfp + 1;
      case i^.opc of
        181:                            { muls }
          if not i^.h.fp_ccs then
            oli_nmuls := oli_nmuls + 1;
        184:                            { muld }
          if not i^.h.fp_ccs then
            oli_nmuld := oli_nmuld + 1;
        155, 154:                       { subs, adds }
          if is_5op_candidate(i) then
            oli_n5s := oli_n5s + 1;
        152: begin                      { truncsi }
          oli_5op[i^.num] := true;
          oli_n5s := oli_n5s + 1;
        end;
        172, 171:                       { subd, addd }
          if is_5op_candidate(i) then
            oli_n5d := oli_n5d + 1;
        169: begin                      { truncdi }
          oli_5op[i^.num] := true;
          oli_n5d := oli_n5d + 1;
        end;
        otherwise
      end;
    end
    else if cls = class$fp_control then begin
      oli_nfp := oli_nfp + 1;
      oli_nint := oli_nint + 1;
      oli_nfpctl := oli_nfpctl + 1;
    end
    else if not (cls in [4..7, 18, 19, 26]) then
      if i^.opc <> 69 then              { jump }
        oli_nint := oli_nint + 1;
    i := i^.next;
  end;
  if oli_nint >= oli_nfp then begin
    ii := oli_nint;
    oli_fp_spare := 0;
  end
  else begin
    a := oli_nmuls;
    if a > oli_n5s then
      a := oli_n5s;
    b := oli_nmuld;
    if b > oli_n5d then
      b := oli_n5d;
    ii := oli_nfp - a - b;
    if ii < oli_nint then
      ii := oli_nint;
    oli_fp_spare := oli_nfp - ii;
  end;
  find_data_flow_paths;
  if oli_dep = 1 then begin
    r := max_recurrence_slope;
    if r < ii then
      r := ii;
  end
  else
    r := ii;
  iteration_interval := r;
end;

{ assign_enable_counts - the counts the scheduler releases by: an
  instruction's (+30 word) the segments it defines that have readers
  or are first in the block, and one for each intend-to-modify write
  after it whose segment it reads; a segment's (+34 word) its
  readers, one more for a first segment in the block (not condition
  codes) or an exposed one first in it.  0x25A18A, 0x176 bytes. }

procedure assign_enable_counts(
    bb: bb_ptr_t); options(val_param); internal;
var
  i, j: instr_ptr_t;
  s, t: lts_ptr_t;
  o, r: opnd_ptr_t;
  k: integer32;
begin
  i := bb^.first;
  while i <> nil do begin
    oli_instr_v_ptr_t(i)^.enable := 0;
    i := i^.next;
  end;
  s := bb^.exposed;
  while s <> nil do begin
    if s^.f2.first_in_bb then
      oli_lts_v_ptr_t(s)^.enable := 1
    else
      oli_lts_v_ptr_t(s)^.enable := 0;
    r := s^.refs;
    while r <> nil do begin
      if r^.h.read then
        oli_lts_v_ptr_t(s)^.enable := oli_lts_v_ptr_t(s)^.enable + 1;
      r := r^.link;
    end;
    s := s^.next_exposed;
  end;
  i := bb^.first;
  while i <> nil do begin
    for k := 1 to i^.h.nopnds do begin
      o := addr(i^.opnds[k]);
      if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
          begin
        if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then
          if (o^.link <> nil) or o^.lts^.f2.first_in_bb then begin
            oli_instr_v_ptr_t(i)^.enable := oli_instr_v_ptr_t(i)^.enable + 1;
            t := o^.lts;
            oli_lts_v_ptr_t(t)^.enable := 0;
            r := t^.refs^.link;
            while r <> nil do begin
              if r^.h.read then
                oli_lts_v_ptr_t(t)^.enable := oli_lts_v_ptr_t(t)^.enable + 1;
              r := r^.link;
            end;
            if t^.f2.first_in_bb then
              if o^.h.kind <> operand$ip_condition_codes then
                oli_lts_v_ptr_t(t)^.enable := oli_lts_v_ptr_t(t)^.enable + 1;
          end;
        if (opnd_bytes_ptr_t(o)^.rrp & 48) = 48 then begin
          t := o^.lts;
          r := t^.refs;
          if not t^.f2.exposed then
            r := r^.link;
          while r <> nil do begin
            if r^.h.read and not r^.h.intend_to_modify then begin
              j := utils_ins_$operands_instruction(r);
              oli_instr_v_ptr_t(j)^.enable := oli_instr_v_ptr_t(j)^.enable + 1;
            end;
            r := r^.link;
          end;
        end;
      end;
    end;
    i := i^.next;
  end;
end;

{ decrement_ienable_count - i's count taken down; at 0 it is enabled
  (queued).  0x25A300, 0x1E bytes. }

procedure decrement_ienable_count(
    i: instr_ptr_t); options(val_param); internal;
begin
  oli_instr_v_ptr_t(i)^.enable := oli_instr_v_ptr_t(i)^.enable - 1;
  if oli_instr_v_ptr_t(i)^.enable = 0 then
    enqueue_enabled_instruction(i);
end;

{ decrement_lenable_count - s's count taken down; at 0, for a segment
  not exposed, its definition's count.  0x25A31E, 0x40 bytes: loads A5
  (a global routine nothing outside calls; s by address). }

procedure decrement_lenable_count(
    var s: lts_ptr_t);
begin
  oli_lts_v_ptr_t(s)^.enable := oli_lts_v_ptr_t(s)^.enable - 1;
  if oli_lts_v_ptr_t(s)^.enable = 0 then
    if not s^.f2.exposed then
      decrement_ienable_count(utils_ins_$operands_instruction(s^.refs));
end;

{ swap_inputs - i's operands 1 and 2 exchanged (renumbered); for an
  addd also its operands 4 and 5, whose segments' operand chains are
  relinked first.  0x25A35E, 0xEC bytes: operands 1 and 2 are not
  relinked (kept). }

procedure swap_inputs(
    i: instr_ptr_t); options(val_param); internal;
var
  t: opnd_t;
  o: opnd_ptr_t;
begin
  t := i^.opnds[2];
  i^.opnds[2] := i^.opnds[1];
  i^.opnds[1] := t;
  i^.opnds[1].h.num := 1;
  i^.opnds[2].h.num := 2;
  if i^.opc = 171 then begin            { addd }
    o := i^.opnds[4].lts^.refs;
    if o = addr(i^.opnds[4]) then
      i^.opnds[4].lts^.refs := addr(i^.opnds[5])
    else begin
      while o^.link <> addr(i^.opnds[4]) do
        o := o^.link;
      o^.link := addr(i^.opnds[5]);
    end;
    o := i^.opnds[5].lts^.refs;
    if o = addr(i^.opnds[5]) then
      i^.opnds[5].lts^.refs := addr(i^.opnds[4])
    else begin
      while o^.link <> addr(i^.opnds[5]) do
        o := o^.link;
      o^.link := addr(i^.opnds[4]);
    end;
    t := i^.opnds[5];
    i^.opnds[5] := i^.opnds[4];
    i^.opnds[4] := t;
    i^.opnds[4].h.num := 4;
    i^.opnds[5].h.num := 5;
  end;
end;

{ find_open_slot - a cycle for i at or before slot (counted down,
  wrapping to the interval's end into the next iteration, it), with its
  unit free: the integer unit (0) for most, the floating units (1, 2)
  for floating ones; fp_control all three; the uncounted classes
  anywhere.  A floating multiply (or add, subtract, truncate) not
  setting the condition codes first looks, within the pairing budget,
  back over the cycles its share of the interval allows for a
  five-operand candidate (a multiply) to pair with in the other unit;
  the counts of paired and unpaired ones (oli_2e14 .. oli_2e20) kept.
  0x25A44A, 0x86E bytes: truncdi's last search does not step (kept). }

function find_open_slot(
    i: instr_ptr_t;
    var slot: integer32;
    var iter: integer32): boolean; options(val_param); internal;
label
  10, 90, 99;
var
  s, it, lim: integer32;
  cls: integer;
  j: instr_ptr_t;
begin
  s := slot;
  it := iter;
  cls := instruction_attributes[i^.opc].class;
  if cls = class$fp_control then begin
    repeat
      if oli_sched[s, 1] = nil then
        if oli_sched[s, 0] = nil then
          if oli_sched[s, 2] = nil then
            goto 10;
      s := s - 1;
      if s <= 0 then begin
        s := s + oli_ii;
        it := it + 1;
      end;
    until s = slot;
    goto 90;
  end;
  if cls in [4..7, 18, 19, 26] then
    goto 10;
  case i^.opc of
    181, 184: begin                     { muls, muld }
      if not i^.h.fp_ccs then
        if oli_fp_budget > 0 then
          if ((i^.opc = 181) and (oli_2e20 > 0)) or
              ((i^.opc = 184) and (oli_2e1c > 0)) then begin
            if i^.opc = 181 then
              lim := s - (oli_ii * oli_2e20) div oli_n5s
            else
              lim := s - (oli_ii * oli_2e1c) div oli_n5d;
            if lim <= 0 then
              lim := lim + oli_ii;
            repeat
              if oli_sched[s, 1] = nil then begin
                j := oli_sched[s, 2];
                if j <> nil then
                  if oli_5op[j^.num] then
                    if instruction_attributes[j^.opc].class = class$fp_single
                        then
                      if is_5op_candidate(j) then
                        goto 10;
              end;
              s := s - 1;
              if s <= 0 then begin
                s := s + oli_ii;
                it := it + 1;
              end;
            until s = lim;
            s := slot;
            it := iter;
          end;
      repeat
        if oli_sched[s, 1] = nil then
          if oli_sched[s, 2] = nil then begin
            if not i^.h.fp_ccs then
              if i^.opc = 181 then
                oli_2e18 := oli_2e18 + 1
              else
                oli_2e14 := oli_2e14 + 1;
            goto 10;
          end;
        s := s - 1;
        if s <= 0 then begin
          s := s + oli_ii;
          it := it + 1;
        end;
      until s = slot;
      goto 90;
    end;
    154, 155, 171, 172: begin           { adds, subs, addd, subd }
      if oli_5op[i^.num] then
        if oli_fp_budget > 0 then
          if (((i^.opc = 154) or (i^.opc = 155)) and (oli_2e18 > 0)) or
              (((i^.opc = 171) or (i^.opc = 172)) and (oli_2e14 > 0)) then
            if is_5op_candidate(i) then begin
              if (i^.opc = 154) or (i^.opc = 155) then
                lim := slot - (oli_ii * oli_2e18) div oli_nmuls
              else
                lim := slot - (oli_ii * oli_2e14) div oli_nmuld;
              if lim <= 0 then
                lim := lim + oli_ii;
              repeat
                if oli_sched[s, 2] = nil then begin
                  j := oli_sched[s, 1];
                  if j <> nil then
                    if ((j^.opc = 181) and ((i^.opc = 154) or (i^.opc = 155)))
                        or ((j^.opc = 184) and ((i^.opc = 171) or
                        (i^.opc = 172))) then
                      if not j^.h.fp_ccs then
                        goto 10;
                end;
                s := s - 1;
                if s <= 0 then begin
                  s := s + oli_ii;
                  it := it + 1;
                end;
              until s = lim;
              s := slot;
              it := iter;
            end;
      repeat
        if oli_sched[s, 1] = nil then
          if oli_sched[s, 2] = nil then begin
            if oli_5op[i^.num] then
              if is_5op_candidate(i) then
                if (i^.opc = 154) or (i^.opc = 155) then
                  oli_2e20 := oli_2e20 + 1
                else
                  oli_2e1c := oli_2e1c + 1;
            goto 10;
          end;
        s := s - 1;
        if s <= 0 then begin
          s := s + oli_ii;
          it := it + 1;
        end;
      until s = slot;
      goto 90;
    end;
    152: begin                          { truncsi }
      if oli_fp_budget > 0 then
        if oli_2e18 > 0 then begin
          lim := s - (oli_ii * oli_2e18) div oli_nmuls;
          if lim <= 0 then
            lim := lim + oli_ii;
          repeat
            if oli_sched[s, 2] = nil then begin
              j := oli_sched[s, 1];
              if j <> nil then
                if j^.opc = 181 then
                  if not j^.h.fp_ccs then
                    goto 10;
            end;
            s := s - 1;
            if s <= 0 then begin
              s := s + oli_ii;
              it := it + 1;
            end;
          until s = lim;
          s := slot;
          it := iter;
        end;
      repeat
        if oli_sched[s, 1] = nil then
          if oli_sched[s, 2] = nil then begin
            oli_2e20 := oli_2e20 + 1;
            goto 10;
          end;
        s := s - 1;
        if s <= 0 then begin
          s := s + oli_ii;
          it := it + 1;
        end;
      until s = slot;
      goto 90;
    end;
    169: begin                          { truncdi }
      if oli_fp_budget > 0 then
        if oli_2e14 > 0 then begin
          lim := s - (oli_ii * oli_2e14) div oli_nmuld;
          if lim <= 0 then
            lim := lim + oli_ii;
          repeat
            if oli_sched[s, 2] = nil then begin
              j := oli_sched[s, 1];
              if j <> nil then
                if j^.opc = 184 then
                  if not j^.h.fp_ccs then
                    goto 10;
            end;
            s := s - 1;
            if s <= 0 then begin
              s := s + oli_ii;
              it := it + 1;
            end;
          until s = lim;
          s := slot;
          it := iter;
        end;
      repeat
        if oli_sched[s, 1] = nil then
          if oli_sched[s, 2] = nil then begin
            oli_2e1c := oli_2e1c + 1;
            goto 10;
          end;
        if s <= 0 then begin
          s := s + oli_ii;
          it := it + 1;
        end;
      until s = slot;
      goto 90;
    end;
    otherwise
      if cls in [class$fp_double, class$immediate, class$fp_single] then begin
        repeat
          if oli_sched[s, 2] = nil then
            if oli_sched[s, 1] = nil then
              goto 10;
          s := s - 1;
          if s <= 0 then begin
            s := s + oli_ii;
            it := it + 1;
          end;
        until s = slot;
      end
      else
        repeat
          if oli_sched[s, 0] = nil then
            goto 10;
          s := s - 1;
          if s <= 0 then begin
            s := s + oli_ii;
            it := it + 1;
          end;
        until s = slot;
  end;
90:
  find_open_slot := false;
  goto 99;
10:
  slot := s;
  iter := it;
  find_open_slot := true;
99:
end;

{ schedule_instr - i put in cycle slot of iteration iter: in the units
  its interaction class uses (an uncounted one on the cycle's list,
  column 3, from oli_unodes); a floating pair completed counts against
  the budget (oli_paired the partner); its cycle and iteration noted;
  the segments it reads and the readers its intend-to-modify writes
  wait for released.  0x25ACB8, 0x224 bytes. }

procedure schedule_instr(
    i: instr_ptr_t;
    slot: integer32;
    iter: integer32); options(val_param); internal;
var
  two: boolean;
  k: integer;
  n: integer32;
  j: instr_ptr_t;
  o, r: opnd_ptr_t;
  t: lts_ptr_t;
begin
  two := false;
  k := instruction_attributes[i^.opc].interaction;
  if k in [1, 4..16] then
    oli_sched[slot, 0] := i;
  if k in [2, 11, 13] then begin
    oli_sched[slot, 2] := i;
    two := true;
  end;
  if k in [3, 11, 13] then begin
    oli_sched[slot, 1] := i;
    two := true;
  end;
  if instruction_attributes[i^.opc].class in [4..7, 18, 19, 26] then begin
    n := oli_nunodes;
    oli_nunodes := oli_nunodes + 1;
    oli_unodes[n].next := oli_qnode_ptr_t(oli_sched[slot, 3]);
    oli_sched[slot, 3] := instr_ptr_t(addr(oli_unodes[n]));
    oli_unodes[n].instr := i;
  end;
  if two then
    if oli_sched[slot, 1] <> oli_sched[slot, 2] then
      if oli_sched[slot, 2] <> nil then
        if oli_sched[slot, 1] <> nil then begin
          j := oli_sched[slot, 2];
          oli_paired[j^.num] := true;
          oli_fp_budget := oli_fp_budget - 1;
          if j = i then
            if j^.opc = 154 then
              oli_2e18 := oli_2e18 - 1
            else
              oli_2e14 := oli_2e14 - 1
          else if j^.opc = 154 then
            oli_2e20 := oli_2e20 - 1
          else
            oli_2e1c := oli_2e1c - 1;
        end;
  oli_slot[i^.num] := slot;
  oli_iter[i^.num] := iter;
  for n := 1 to i^.h.nopnds do begin
    o := addr(i^.opnds[n]);
    if o^.h.read then
      if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
        decrement_lenable_count(o^.lts);
    if o^.h.intend_to_modify then begin
      t := o^.lts;
      r := t^.refs;
      if not t^.f2.exposed then
        r := r^.link;
      while r <> nil do begin
        if r^.h.read and not r^.h.intend_to_modify then
          decrement_ienable_count(utils_ins_$operands_instruction(r));
        r := r^.link;
      end;
    end;
  end;
end;

{ find_data_flow_constraints - the latest cycle (slot, iteration iter)
  i can be put in, counting back from the readers already scheduled:
  for a value it writes, each reader's cycle less the delays (one less
  again unless either is of an uncounted class); for a register it
  reads that a later instruction intends to modify, that instruction's
  cycle (less one, likewise).  0x25AEDC, 0x250 bytes. }

procedure find_data_flow_constraints(
    i: instr_ptr_t;
    var slot: integer32;
    var iter: integer32); options(val_param); internal;
var
  k: integer32;
  r: opnd_ptr_t;
  j: instr_ptr_t;
  d, it: integer32;
  unc, upd: boolean;
begin
  slot := oli_ii;
  iter := 1;
  for k := 1 to i^.h.nopnds do
    if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then begin
      r := i^.opnds[k].lts^.refs^.link;
      while r <> nil do begin
        j := utils_ins_$operands_instruction(r);
        d := i^.opnds[k].h.b2_3_0 + r^.h.b2_3_0;
        it := oli_iter[j^.num];
        if (instruction_attributes[j^.opc].class in [4..7, 18, 19, 26]) or
            (instruction_attributes[i^.opc].class in [4..7, 18, 19, 26]) then
          d := oli_slot[j^.num] - d
        else
          d := oli_slot[j^.num] - 1 - d;
        while d <= 0 do begin
          d := d + oli_ii;
          it := it + 1;
        end;
        if it > iter then begin
          iter := it;
          slot := d;
        end
        else if d < slot then
          slot := d;
        r := r^.link;
      end;
    end
    else if i^.opnds[k].h.kind in [operand$ip_reg..
        operand$well_behaved_memory] then
      if i^.opnds[k].h.read and not i^.opnds[k].h.intend_to_modify then begin
        r := i^.opnds[k].lts^.refs^.link;
        while r <> nil do begin
          if r^.h.intend_to_modify then begin
            j := utils_ins_$operands_instruction(r);
            unc := (instruction_attributes[j^.opc].class in
                [4..7, 18, 19, 26]) or
                (instruction_attributes[i^.opc].class in [4..7, 18, 19, 26]);
            if unc then begin
              if oli_iter[j^.num] > iter then begin
                iter := oli_iter[j^.num];
                slot := oli_slot[j^.num];
              end
              else if oli_slot[j^.num] < slot then
                slot := oli_slot[j^.num];
            end
            else begin
              upd := false;
              if oli_iter[j^.num] > iter then begin
                iter := oli_iter[j^.num];
                upd := true;
              end
              else if oli_slot[j^.num] < slot then
                upd := true;
              if upd then begin
                slot := oli_slot[j^.num] - 1;
                if slot <= 0 then begin
                  slot := slot + oli_ii;
                  iter := iter + 1;
                end;
              end;
            end;
          end;
          r := r^.link;
        end;
      end;
end;

{ ticks_to_most_remote_consumer - the cycles from where the value of
  segment s (defined by operand o, nil for a value live into the loop)
  is made to its last use in the schedule: for a first segment in the
  block whose live range is exposed at the head through a join (not
  when all) the time to the join plus, for an intend-to-modify chain,
  from there on; else the furthest reader, following chains of
  intend-to-modify readers and the five-operand pairs' results.
  0x25B12C, 0x2CE bytes: m$mis$lll the products. }

function ticks_to_most_remote_consumer(
    i: instr_ptr_t;
    o: opnd_ptr_t;
    s: lts_ptr_t;
    all: boolean): integer32; options(val_param); internal;
label
  20, 30, 99;
var
  sl, it, d, best, t: integer32;
  j: instr_ptr_t;
  u: lts_ptr_t;
  r: opnd_ptr_t;
  k: integer32;
begin
  if o = nil then begin
    sl := 0;
    it := 1;
  end
  else begin
    j := utils_ins_$operands_instruction(o);
    sl := oli_slot[j^.num];
    it := oli_iter[j^.num];
  end;
  if s^.f2.first_in_bb then begin
    u := s;
    while (u^.next <> nil) and (u^.next^.bb = s^.bb) and
        not u^.f2.exposed do
      u := u^.next;
    if all or not u^.f2.exposed then begin
      ticks_to_most_remote_consumer := oli_ii - sl + (oli_iters - it) * oli_ii;
      goto 99;
    end;
    r := u^.refs;
    j := utils_ins_$operands_instruction(r);
    if instruction_attributes[j^.opc].class <> class$join_bp then begin
      ticks_to_most_remote_consumer := oli_ii * oli_iters;
      goto 99;
    end;
    d := oli_ii - sl + (oli_iters - it) * oli_ii + oli_slot[j^.num]
        + (oli_iter[j^.num] - 1) * oli_ii;
    if r^.h.intend_to_modify and (j <> i) then
      d := ticks_to_most_remote_consumer(i, addr(j^.opnds[2]),
          j^.opnds[2].lts, all) + d;
    ticks_to_most_remote_consumer := d;
    goto 99;
  end;
  if o = nil then
    r := s^.refs
  else
    r := o^.link;
  best := 0;
  while r <> nil do begin
    j := utils_ins_$operands_instruction(r);
    d := oli_slot[j^.num] - sl + (oli_iter[j^.num] - it) * oli_ii;
    if r^.h.intend_to_modify and (j <> i) then begin
      for k := j^.h.nopnds downto 1 do
        if j^.opnds[k].h.kind in [operand$ip_reg..
            operand$well_behaved_memory] then
          if j^.opnds[k].lts^.lr = r^.lts^.lr then begin
            t := ticks_to_most_remote_consumer(i, addr(j^.opnds[k]),
                j^.opnds[k].lts, all) + d;
            goto 20;
          end;
    end
    else if oli_paired[j^.num] then
      case j^.opc of
        155, 154: begin                 { subs, adds }
          t := ticks_to_most_remote_consumer(i, addr(j^.opnds[3]),
              j^.opnds[3].lts, all) + d;
          goto 20;
        end;
        172, 171: begin                 { subd, addd }
          if r^.h.num = 2 then
            t := ticks_to_most_remote_consumer(i, addr(j^.opnds[3]),
                j^.opnds[3].lts, all) + d
          else
            t := ticks_to_most_remote_consumer(i, addr(j^.opnds[6]),
                j^.opnds[6].lts, all) + d;
          goto 20;
        end;
        152, 169:                       { truncsi, truncdi }
          if best < d then
            best := d;
        otherwise
      end
    else if best < d then
      best := d;
    goto 30;
20:
    if best < t then
      best := t;
30:
    r := r^.link;
  end;
  ticks_to_most_remote_consumer := best;
99:
end;

{ schedule - the loop's modulo schedule at the current interval:
  the branch put in the interval's last cycle of iteration 1, the
  final segments released, then each enabled instruction (highest
  first) put in the latest open cycle its consumers allow, moved back
  further while an instruction already in a cycle its interaction
  distances reach (tm_utils_$minimum_distance; forward distances first,
  then backward) needs more room, unless that moved it before its
  constraints' cycle in an earlier iteration; the list built and the
  iterations renumbered.  False when an instruction finds no cycle.
  0x25B3FA, 0x2B6 bytes. }

function schedule: boolean; internal;
label
  50, 60, 70, 99;
var
  i: instr_ptr_t;
  s, t: lts_ptr_t;
  ds, di, sl, it, bk, fw, c, cyc, m, d: integer32;
  u: integer;
  done, ok: boolean;
begin
  init_sched;
  assign_enable_counts(oli_bb);
  schedule_instr(oli_branch, oli_ii - 1, 1);
  s := oli_bb^.finals;
  while s <> nil do begin
    t := s;
    decrement_lenable_count(t);
    s := s^.next_final;
  end;
  i := dequeue_enabled_instruction;
  while i <> nil do begin
    find_data_flow_constraints(i, ds, di);
    sl := ds;
    it := di;
    if not find_open_slot(i, sl, it) then begin
      schedule := false;
      goto 99;
    end;
    bk := tm_utils_$interaction_distance_backward(i);
    fw := tm_utils_$interaction_distance_forward(i);
    done := false;
    repeat
      if fw > 0 then
        for c := fw downto 1 do begin
          cyc := sl + c;
          if cyc > oli_ii then
            cyc := cyc - oli_ii;
          m := 0;
          for u := 0 to 3 do
            if oli_sched[cyc, u] <> nil then
              if u <> 3 then begin
                d := tm_utils_$minimum_distance(i, oli_sched[cyc, u]);
                if m < d then
                  m := d;
              end;
          if m >= oli_ii then
            goto 70;
          if m > c then begin
            d := cyc - m;
            if d <= 0 then begin
              d := d + oli_ii;
              it := it + 1;
            end;
            sl := d;
            ok := find_open_slot(i, sl, it);
            goto 50;
          end;
        end;
      if bk > 0 then begin
        for c := 1 to bk do begin
          cyc := sl - c;
          if cyc <= 0 then
            cyc := cyc + oli_ii;
          m := 0;
          for u := 0 to 3 do
            if oli_sched[cyc, u] <> nil then
              if u <> 3 then begin
                d := tm_utils_$minimum_distance(i, oli_sched[cyc, u]);
                if m < d then
                  m := d;
              end;
          if m >= oli_ii then
            goto 70;
          if m > c then begin
            d := cyc - m;
            if d <= 0 then begin
              d := d + oli_ii;
              it := it + 1;
            end;
            sl := d;
            ok := find_open_slot(i, sl, it);
            goto 50;
          end;
        end;
        done := true;
      end
      else
        done := true;
      goto 60;
50:
      if not ok then begin
        schedule := false;
        goto 99;
      end;
      if it < di then
        if ds >= sl then begin
          sl := ds;
          it := di;
          goto 70;
        end;
60:
    until done;
70:
    schedule_instr(i, sl, it);
    if oli_iters < it then
      oli_iters := it;
    i := dequeue_enabled_instruction;
  end;
  schedule := true;
  build_sched_array;
  reverse_iteration_numbers;
  oli_niters := oli_iters;
99:
end;

{ excess_register_pressure - the schedule needs more registers than
  there are: the values live in each cycle of the overlapped iterations
  (integer and floating: registers exposed at the head, then each
  scheduled write adds one and the last read of a segment, unless it
  is read later in the schedule, takes one off), folded onto the
  interval's cycles, the largest of each with the values live around
  the loop beyond 24 integer or 64 floating.  0x25B6B0, 0x3AC bytes:
  the table's size is a word product of the interval's and the
  iterations' low words (pattern 129); the last loop repeats its search
  once for each cycle (kept). }

function excess_register_pressure: boolean; internal;
label
  99;
var
  tab: oli_live_ptr_t;
  ip_in, fp_in, c, n, k, row, m, ip, fp, x: integer32;
  i, j: instr_ptr_t;
  s: lts_ptr_t;
  o, r: opnd_ptr_t;
begin
  tab := mrh_$alloc(oli_heap, oli_ii * oli_niters * 8);
  tab^[0].ip := 0;
  tab^[0].fp := 0;
  ip_in := 0;
  fp_in := 0;
  s := oli_bb^.exposed;
  while s <> nil do begin
    if s^.refs^.h.kind in [operand$ip_reg, operand$ip_reg_physical] then
      if s^.f2.first_in_bb then
        ip_in := ip_in + 1
      else
        tab^[0].ip := tab^[0].ip + 1
    else if s^.refs^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
        operand$fp_reg_physical, operand$fp_reg_pair_physical,
        operand$fp_reg_like, operand$fp_reg_pair_like] then
      if s^.f2.first_in_bb then
        fp_in := fp_in + 1
      else
        tab^[0].fp := tab^[0].fp + 1;
    s := s^.next_exposed;
  end;
  n := 1;
  for c := 1 to oli_ii * oli_niters - 1 do begin
    tab^[c] := tab^[c - 1];
    while n <= oli_nsched do begin
      i := oli_sched_list[n];
      if (oli_iter[i^.num] - 1) * oli_ii + oli_slot[i^.num] <> c then
        exit;
      for k := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[k]);
        if o^.h.write then begin
          if o^.h.kind in [operand$ip_reg, operand$ip_reg_physical] then
            tab^[c].ip := tab^[c].ip + 1
          else if o^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
              operand$fp_reg_physical, operand$fp_reg_pair_physical,
              operand$fp_reg_like, operand$fp_reg_pair_like] then
            tab^[c].fp := tab^[c].fp + 1;
        end
        else if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory]
            then
          if o^.h.read and not o^.h.intend_to_modify then begin
            s := o^.lts;
            if not s^.f2.first_in_bb then
              if not (rrp$modify in s^.rrp) then begin
                if s^.f2.exposed then
                  r := s^.refs
                else
                  r := s^.refs^.link;
                while r <> nil do begin
                  j := utils_ins_$operands_instruction(r);
                  if oli_iter[j^.num] > oli_iter[i^.num] then
                    goto 99;
                  if oli_iter[j^.num] = oli_iter[i^.num] then
                    if oli_slot[j^.num] > oli_slot[i^.num] then
                      goto 99;
                  r := r^.link;
                end;
                if o^.h.kind in [operand$ip_reg, operand$ip_reg_physical]
                    then
                  tab^[c].ip := tab^[c].ip - 1
                else if o^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
                    operand$fp_reg_physical, operand$fp_reg_pair_physical,
                    operand$fp_reg_like, operand$fp_reg_pair_like] then
                  tab^[c].fp := tab^[c].fp - 1;
              end;
          end;
    99:
      end;
      n := n + 1;
    end;
  end;
  for row := 0 to oli_ii - 1 do
    for m := 1 to oli_niters - 1 do begin
      tab^[row].ip := tab^[row].ip + tab^[m * oli_ii + row].ip;
      tab^[row].fp := tab^[row].fp + tab^[m * oli_ii + row].fp;
    end;
  excess_register_pressure := false;
  for row := 0 to oli_ii - 1 do begin
    ip := 0;
    fp := 0;
    for x := 0 to oli_ii - 1 do begin
      if ip < tab^[x].ip then
        ip := tab^[x].ip;
      if fp < tab^[x].fp then
        fp := tab^[x].fp;
    end;
    fp := fp + fp_in;
    ip := ip + ip_in;
    if (fp > 64) or (ip > 24) then begin
      excess_register_pressure := true;
      exit;
    end;
  end;
end;

{ int_const_in_fp_reg - a floating register holding the integer v: one
  made earlier (oli_fp_consts, by value) or a new one, an add of v to
  the zero register and an mtfp of it at the prologue's end.  0x25BA5C,
  0x1AC bytes. }

function int_const_in_fp_reg(
    v: integer32): lr_ptr_t; options(val_param); internal;
label
  99;
var
  p, n: oli_fpconst_ptr_t;
  i: instr_ptr_t;
  lr: lr_ptr_t;
  k: integer32;
begin
  p := oli_fp_consts;
  if p = nil then
    p := nil
  else if v < p^.value then
    p := nil
  else begin
    if v = p^.value then begin
      int_const_in_fp_reg := p^.lr;
      goto 99;
    end;
    while p^.next <> nil do begin
      if v <= p^.next^.value then
        exit;
      p := p^.next;
    end;
    if p^.next <> nil then
      if p^.next^.value = v then begin
        int_const_in_fp_reg := p^.next^.lr;
        goto 99;
      end;
  end;
  n := mrh_$alloc(oli_heap, 12);
  if p = nil then begin
    n^.next := oli_fp_consts;
    oli_fp_consts := n;
  end
  else begin
    n^.next := p^.next;
    p^.next := n;
  end;
  n^.value := v;
  i := add_instr_end_of_prolog_inits(79);       { add }
  for k := 1 to i^.h.nopnds do
    i^.opnds[k].h.num := k;
  i^.opnds[1].value := v;
  opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
  i^.opnds[1].h.kind := operand$immediate;
  i^.opnds[1].link := nil;
  i^.opnds[1].h.bytes := 4;
  i^.opnds[1].h.count := 0;
  i^.opnds[2].value := lir_main_c4c;
  opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
  i^.opnds[2].h.kind := operand$ip_reg_like;
  lr := lir_$new_live_range_for_kind(1);
  i^.opnds[3].ptr := lr;
  opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
  i^.opnds[3].h.kind := operand$ip_reg;
  i := add_instr_end_of_prolog_inits(126);      { mtfp }
  i^.opnds[1].h.num := 1;
  i^.opnds[1].ptr := lr;
  opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
  i^.opnds[1].h.kind := operand$ip_reg;
  i^.opnds[2].h.num := 2;
  lr := lir_$new_live_range_for_kind(2);
  i^.opnds[2].ptr := lr;
  opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 8;
  i^.opnds[2].h.kind := operand$fp_reg;
  n^.lr := lr;
  int_const_in_fp_reg := lr;
99:
end;

{ operand_gets_materialized_value - operand o (cleared) made the value
  v describes, for register file rclass: a live range (kind 1), a
  constant (3: an immediate if encodable as operand pos of an opc
  instruction, else a register made at the head of bb; in a floating
  register, int_const_in_fp_reg's), or a copy of an operand (2, its
  number kept).  0x25BC08, 0x16E bytes: pos is a longword passed on as
  its low word. }

procedure operand_gets_materialized_value(
    o: opnd_ptr_t;
    v: oli_mval_ptr_t;
    rclass: integer;
    opc: integer;
    pos: integer32;
    bb: bb_ptr_t); options(val_param); internal;
var
  e: iv_expr_ptr_t;
  lr: lr_ptr_t;
  value: integer32;
  op: opnd_ptr_t;
  kind: integer;
  n: integer;
begin
  zero(o, 12);
  case v^.kind of
    1: begin
      o^.ptr := v^.ptr;
      opnd_bytes_ptr_t(o)^.rrp := 16;
      opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! rclass;
    end;
    3:
      if rclass = 1 then begin
        e := iv_utils_$create_value_expression(v^.value);
        e := iv_utils_$canonicalize_expression(e);
        e := iv_utils_$elaborate_expression(e, rclass, opc, pos);
        iv_utils_$live_range_from_elaborated_expression(e, bb, lr, value,
            op, kind);
        iv_utils_$delete_expression(e);
        if kind = 3 then begin
          opnd_bytes_ptr_t(o)^.rrp := 16;
          o^.h.kind := operand$immediate;
          o^.value := value;
          o^.link := nil;
          o^.h.bytes := 4;
          o^.h.count := 0;
        end
        else if kind = 1 then begin
          opnd_bytes_ptr_t(o)^.rrp := 16;
          o^.ptr := lr;
          opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! rclass;
        end
        else
          bug_check('\\OLI\OPERAND_GETS_MATERIALIZED_VALUE --- Can''t handle this return kind.%$');
      end
      else if rclass = 2 then begin
        opnd_bytes_ptr_t(o)^.rrp := 16;
        o^.ptr := int_const_in_fp_reg(v^.value);
        opnd_bytes_ptr_t(o)^.b3 := (opnd_bytes_ptr_t(o)^.b3 & 16#E0) ! rclass;
      end;
    2: begin
      n := o^.h.num;
      o^ := opnd_ptr_t(v^.ptr)^;
      o^.h.num := n;
    end;
    otherwise
  end;
end;

{ exposed_at - lr has an exposed segment in bb.  0x25BDC0, 0x42 bytes:
  global (A5), its parameters by address; nothing calls it. }

function exposed_at(
    var bb: bb_ptr_t;
    var lr: lr_ptr_t): boolean;
var
  s: lts_ptr_t;
begin
  exposed_at := false;
  s := bb^.exposed;
  while s <> nil do begin
    if s^.lr = lr then begin
      exposed_at := true;
      exit;
    end;
    s := s^.next_exposed;
  end;
end;

{ consumed_in_downstream_bb - lr's final segment in bb reaches an
  exposed segment in another block.  0x25BE02, 0x66 bytes: global,
  nothing calls it; when the final segment reaches none outside bb the
  result is not set (D0 holds bb's address; kept). }

function consumed_in_downstream_bb(
    var lr: lr_ptr_t;
    var bb: bb_ptr_t): boolean;
label
  99;
var
  s: lts_ptr_t;
begin
  s := bb^.finals;
  while s <> nil do begin
    if s^.lr = lr then
      exit;
    s := s^.next_final;
  end;
  if s = nil then begin
    consumed_in_downstream_bb := false;
    goto 99;
  end;
  s := s^.l28;
  while s <> nil do begin
    if s^.bb <> bb then begin
      consumed_in_downstream_bb := true;
      goto 99;
    end;
    s := s^.l28;
  end;
99:
end;

{ get_materialized_in_re_duction_lr - the live range that holds, in
  iteration it of the prologue, the value an operand o reads from a
  previous iteration (o's segment, or the join's input it comes from):
  for a reduction, its live range in iteration 0, else the zero of its
  register file (the pair's other half from new's operands); for an
  induction variable, its record's live range for it, else a new one
  computed by an add of the adjustment to the previous one at the
  prologue's end.  0x25BE68, 0x258 bytes: the paths that find nothing
  return what A0 holds (kept unset). }

function get_materialized_in_re_duction_lr(
    o: opnd_ptr_t;
    it: integer32;
    new: instr_ptr_t): lr_ptr_t; options(val_param); internal;
label
  99;
var
  s, e: lts_ptr_t;
  l: oli_red_ptr_t;
  r: oli_red_ptr_t;
  p: oli_ivadj_ptr_t;
  j, i: instr_ptr_t;
  k: integer32;
  kind, opc: integer;
  tmp: opnd_t;
  lr: lr_ptr_t;
begin
  s := o^.lts;
  if s^.f2.exposed then
    e := s
  else
    e := utils_ins_$operands_instruction(s^.refs)^.opnds[1].lts;
  l := oli_red_ptr_t(e^.l24);
  if l = nil then begin
    get_materialized_in_re_duction_lr := e^.lr;
    goto 99;
  end;
  if l^.h.kind = 5 then begin
    if it = 0 then begin
      r := oli_reductions;
      while r <> nil do begin
        if r^.lr = s^.lr then
          exit;
        r := r^.next;
      end;
      get_materialized_in_re_duction_lr := r^.lr;
    end
    else if rrp$ip_reg in e^.rrp then begin
      if rrp$intend_to_modify in s^.rrp then
        get_materialized_in_re_duction_lr := get_ip_zero
      else
        get_materialized_in_re_duction_lr := nil;
    end
    else if rrp$fp_reg_even_only in e^.rrp then
      get_materialized_in_re_duction_lr := get_dp_zero
    else if rrp$fp_reg_odd_only in e^.rrp then begin
      j := utils_ins_$operands_instruction(o);
      for k := 1 to o^.h.num do
        if j^.opnds[k].lts^.lr = o^.lts^.lr^.mate then begin
          get_materialized_in_re_duction_lr :=
              lr_ptr_t(new^.opnds[k].ptr)^.mate;
          goto 99;
        end;
    end
    else if rrp$fp_reg in e^.rrp then
      get_materialized_in_re_duction_lr := get_sp_zero;
    goto 99;
  end;
  p := oli_ivadjs;
  while p <> nil do begin
    if p^.lts = e then
      exit;
    p := p^.next;
  end;
  if p = nil then
    bug_check('oli.get_incremented_induction_lr: couldn''t find exposed induction lts.%$');
  if p^.it = it then begin
    get_materialized_in_re_duction_lr := p^.lr;
    goto 99;
  end;
  kind := ord(e^.refs^.h.kind);
  if kind = 1 then
    opc := 79                           { add }
  else
    opc := 137;                         { addi }
  operand_gets_materialized_value(addr(tmp), addr(p^.mv), kind, opc, 1,
      oli_prolog_bb);
  i := add_instr_end_of_prolog_inits(opc);
  i^.num := 0;
  for k := 1 to i^.h.nopnds do
    i^.opnds[k].h.num := k;
  i^.opnds[1] := tmp;
  i^.opnds[1].h.num := 1;
  i^.opnds[2].ptr := p^.lr;
  opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
  i^.opnds[2].h.kind := e^.refs^.h.kind;
  i^.opnds[3].h.kind := e^.refs^.h.kind;
  lr := lir_$new_live_range_for_kind(ord(i^.opnds[3].h.kind));
  i^.opnds[3].ptr := lr;
  bv_$make_live_range_complex(oli_rtn, lr);
  opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
  p^.lr := lr;
  p^.it := it;
  get_materialized_in_re_duction_lr := lr;
99:
end;

{ build_bookkeeping_structures - the tables the pipelined loop is built
  with, from the bookkeeping heap: two of a longword by iteration
  (oli_tails, oli_2dd4), one by instruction number (oli_copies, cleared),
  each reduction's partial sums (iterations by iterations), one of two
  longwords by iteration (oli_exposed, cleared); oli_span the
  instructions' sequence numbers' span.  0x25C108, 0x122 bytes: the
  sizes word products of the counts' low words (pattern 129). }

procedure build_bookkeeping_structures; internal;
var
  k: integer32;
  r: oli_red_ptr_t;
begin
  oli_tails := mrh_$alloc(oli_heap, oli_niters * 4);
  oli_2dd4 := mrh_$alloc(oli_heap, oli_niters * 4);
  oli_copies := mrh_$alloc(oli_heap, 800);
  for k := 1 to 200 do
    oli_copies^[k - 1] := nil;
  r := oli_reductions;
  oli_span := ((oli_niters - 1) * (oli_niters - 2)) div 2 + oli_iters
      + oli_niters - 1;
  while r <> nil do begin
    r^.sums := mrh_$alloc(oli_heap, oli_iters * oli_niters * 4);
    r := r^.next;
  end;
  oli_exposed := mrh_$alloc(oli_heap, oli_niters * 2 * 4);
  for k := 0 to oli_niters * 2 - 1 do
    oli_exposed^[k] := nil;
end;

{ build_fan_in_seq_instr - with more than one memory live range exposed
  at the loop's head (not first in the block), an mmt_seq as the
  prologue block's only instruction that reads them all and writes a
  new memory live range (oli_mem_lr); it becomes the prologue's last
  initialization when there is none.  0x25C22A, 0x1C8 bytes: global
  (A5) though only build_pipelined_loop calls it; the instruction from
  lir_main_heap (44 + 12n bytes), its flags from the opcode's
  attributes as lir does. }

procedure build_fan_in_seq_instr;
var
  n, k: integer32;
  s: lts_ptr_t;
  i: instr_ptr_t;
begin
  n := 1;
  s := oli_bb^.exposed;
  while s <> nil do begin
    if not s^.f2.first_in_bb then
      if s^.refs^.h.kind in [operand$argument_block_memory..
          operand$well_behaved_memory] then
        n := n + 1;
    s := s^.next_exposed;
  end;
  if n <= 1 then
    return;
  i := mrh_$alloc(oli_heap_ptr_t(lir_main_heap)^, n * 12 + 44);
  i^.opc := 202;                        { mmt_seq }
  integer32_ptr_t(i)^ := 16#4000;
  i^.h.nopnds := n;
  i^.h.preference := instruction_attributes[202].b6_0;
  i^.h.may_generate_an_exception := instruction_attributes[202].b11_7;
  i^.h.b0_1 := oli_bb^.first^.h.b0_1;
  i^.l32 := oli_bb^.first^.l32;
  i^.bb := oli_prolog_bb;
  k := 1;
  s := oli_bb^.exposed;
  while s <> nil do begin
    if not s^.f2.first_in_bb then
      if s^.refs^.h.kind in [operand$argument_block_memory..
          operand$well_behaved_memory] then begin
        i^.opnds[k].ptr := s^.lr;
        opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp := 16;
        i^.opnds[k].h.kind := operand$inscrutable_memory;
        i^.opnds[k].h.num := k;
        k := k + 1;
      end;
    s := s^.next_exposed;
  end;
  oli_mem_lr := lir_$new_live_range;
  bv_$make_live_range_complex(oli_rtn, oli_mem_lr);
  i^.opnds[k].ptr := oli_mem_lr;
  opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp := 8;
  i^.opnds[k].h.kind := operand$inscrutable_memory;
  i^.opnds[k].h.num := k;
  oli_mem_lr^.rrp := oli_mem_lr^.rrp + [rrp$write];
  oli_prolog_bb^.first := i;
  oli_prolog_bb^.last := i;
  i^.next := nil;
  i^.prev := nil;
  if oli_prolog_last = nil then
    oli_prolog_last := i;
end;

{ build_fan_out_seq_instrs - with oli_mem_lr and more than one memory
  live range final in the loop (not exposed), an mmt_seq as each tail
  block's only instruction (numbered -32768), reading oli_mem_lr and
  writing them all.  0x25C3F2, 0x1DC bytes: global, as the fan in. }

procedure build_fan_out_seq_instrs;
var
  n, k, m, size: integer32;
  s: lts_ptr_t;
  i: instr_ptr_t;
begin
  if oli_mem_lr = nil then
    return;
  n := 1;
  s := oli_bb^.finals;
  while s <> nil do begin
    if not s^.f2.exposed then
      if s^.refs^.h.kind in [operand$argument_block_memory..
          operand$well_behaved_memory] then
        n := n + 1;
    s := s^.next_final;
  end;
  if n <= 1 then
    return;
  size := n * 12 + 44;
  for k := 1 to oli_niters do begin
    i := mrh_$alloc(oli_heap_ptr_t(lir_main_heap)^, size);
    utils_$set_instruction_opcode(i, 202);      { mmt_seq }
    i^.num := -32768;
    integer32_ptr_t(i)^ := 16#4000;
    i^.h.nopnds := n;
    i^.h.preference := instruction_attributes[202].b6_0;
    i^.h.may_generate_an_exception := instruction_attributes[202].b11_7;
    i^.h.b0_1 := oli_bb^.last^.h.b0_1;
    i^.l32 := oli_bb^.last^.l32;
    i^.bb := oli_tails^[k - 1];
    i^.opnds[1].ptr := oli_mem_lr;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.kind := operand$inscrutable_memory;
    i^.opnds[1].h.num := 1;
    m := 2;
    s := oli_bb^.finals;
    while s <> nil do begin
      if not s^.f2.exposed then
        if s^.refs^.h.kind in [operand$argument_block_memory..
            operand$well_behaved_memory] then begin
          i^.opnds[m].ptr := s^.lr;
          opnd_bytes_ptr_t(addr(i^.opnds[m]))^.rrp := 8;
          i^.opnds[m].h.kind := operand$inscrutable_memory;
          i^.opnds[m].h.num := m;
          m := m + 1;
        end;
      s := s^.next_final;
    end;
    oli_tails^[k - 1]^.first := i;
    oli_tails^[k - 1]^.last := i;
    i^.next := nil;
    i^.prev := nil;
  end;
end;

{ enlist_sorted - i put in bb's list by its number (unsigned), from
  after (bb's first when nil): before the first with a higher number,
  else before bb's last instruction and the control transfers before
  it.  0x25C5CE, 0xEC bytes. }

procedure enlist_sorted(
    i: instr_ptr_t;
    after: instr_ptr_t;
    bb: bb_ptr_t); options(val_param); internal;
var
  p: instr_ptr_t;
begin
  if after = nil then begin
    if bb^.first = nil then begin
      bb^.first := i;
      bb^.last := i;
      i^.next := nil;
      i^.prev := nil;
      return;
    end;
    after := bb^.first;
  end;
  p := after;
  while p <> nil do begin
    if oli_instr_v_ptr_t(p)^.unum > oli_instr_v_ptr_t(i)^.unum then begin
      i^.next := p;
      i^.prev := p^.prev;
      if i^.prev <> nil then
        i^.prev^.next := i
      else
        bb^.first := i;
      p^.prev := i;
      return;
    end;
    p := p^.next;
  end;
  p := bb^.last;
  while p^.prev <> nil do begin
    if not (instruction_attributes[p^.prev^.opc].class in
        [class$branch, class$fp_branch, class$jump]) then
      exit;
    p := p^.prev;
  end;
  if p^.prev = nil then begin
    p^.prev := i;
    i^.next := p;
    bb^.first := i;
    i^.prev := nil;
  end
  else begin
    p^.prev^.next := i;
    i^.next := p;
    i^.prev := p^.prev;
    p^.prev := i;
  end;
end;

{ add_instruction_in_sequence - a copy of the loop's instruction t for
  iteration it, put in bb by its new sequence number (after the copy of
  the instruction scheduled before it, the n-1st, when that is in bb);
  oli_copies keeps it by t's number.  0x25C6BA, 0xE2 bytes: the copy
  is unlinked from bb's end, where utils put it. }

function add_instruction_in_sequence(
    it: integer32;
    t: instr_ptr_t;
    n: integer32;
    bb: bb_ptr_t): instr_ptr_t; options(val_param); internal;
var
  c, after: instr_ptr_t;
begin
  c := utils_$copy_instr_template_to_bb_end(t, bb);
  oli_copies^[oli_instr_v_ptr_t(t)^.unum - 1] := c;
  if c^.prev <> nil then
    c^.prev^.next := c^.next
  else
    bb^.first := c^.next;
  if c^.next <> nil then
    c^.next^.prev := c^.prev
  else
    bb^.last := c^.prev;
  c^.num := new_seq_num(it, oli_instr_v_ptr_t(t)^.unum, t^.opc);
  if n > 1 then
    if oli_copies^[oli_instr_v_ptr_t(oli_sched_list[n - 1])^.unum - 1]^.bb
        = bb then
      after := oli_copies^[oli_instr_v_ptr_t(oli_sched_list[n - 1])^.unum - 1]
    else
      after := nil
  else
    after := nil;
  enlist_sorted(c, after, bb);
  add_instruction_in_sequence := c;
end;

{ five_oppify - floating add, subtract and truncate i made a
  five-operand instruction when in the pipelined body (adds5 .. truncdi5),
  an add's inputs exchanged unless operand 2 is the one its result
  shares (oli_5op_k, by num), its shared input marked intend to modify
  and the result's write turned into a modify.  0x25C79C, 0x182 bytes. }

procedure five_oppify(
    i: instr_ptr_t;
    num: integer32); options(val_param); internal;
begin
  case i^.opc of
    155, 154: begin                     { subs, adds }
      if i^.opc = 154 then begin
        if i^.bb = oli_body then
          utils_$set_instruction_opcode(i, 186);    { adds5 }
        if oli_5op_k[num] <> 2 then
          swap_inputs(i);
      end
      else if i^.bb = oli_body then
        utils_$set_instruction_opcode(i, 187);      { subs5 }
      i^.opnds[2].h.intend_to_modify := true;
      if i^.opnds[3].h.write then
        opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp :=
            (opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp & 16#F7) ! 4;
    end;
    152:                                { truncsi }
      if i^.bb = oli_body then
        utils_$set_instruction_opcode(i, 188);      { truncsi5 }
    172, 171: begin                     { subd, addd }
      if i^.opc = 171 then begin
        if i^.bb = oli_body then
          utils_$set_instruction_opcode(i, 189);    { addd5 }
        if oli_5op_k[num] <> 2 then
          swap_inputs(i);
      end
      else if i^.bb = oli_body then
        utils_$set_instruction_opcode(i, 190);      { subd5 }
      i^.opnds[2].h.intend_to_modify := true;
      i^.opnds[5].h.intend_to_modify := true;
      if i^.opnds[3].h.write then begin
        opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp :=
            (opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp & 16#F7) ! 4;
        opnd_bytes_ptr_t(addr(i^.opnds[6]))^.rrp :=
            (opnd_bytes_ptr_t(addr(i^.opnds[6]))^.rrp & 16#F7) ! 4;
      end;
    end;
    169:                                { truncdi }
      if i^.bb = oli_body then
        utils_$set_instruction_opcode(i, 191);      { truncdi5 }
    otherwise
  end;
end;

{ un_five_oppify - a five-operand instruction back to its opcode.
  0x25C91E, 0x76 bytes: a jump table. }

procedure un_five_oppify(
    i: instr_ptr_t); options(val_param); internal;
begin
  case i^.opc of
    186: utils_$set_instruction_opcode(i, 154);
    187: utils_$set_instruction_opcode(i, 155);
    188: utils_$set_instruction_opcode(i, 152);
    189: utils_$set_instruction_opcode(i, 171);
    190: utils_$set_instruction_opcode(i, 172);
    191: utils_$set_instruction_opcode(i, 169);
    otherwise
  end;
end;

{ record_live_exposed_lr - in column k (oli_exposed's list), lr is
  replaced by v; a different replacement recorded earlier is a
  conflict.  0x25C994, 0x82 bytes. }

procedure record_live_exposed_lr(
    k: integer32;
    v: lr_ptr_t;
    lr: lr_ptr_t); options(val_param); internal;
var
  p: oli_lrmap_ptr_t;
begin
  p := oli_exposed^[k];
  while p <> nil do begin
    if p^.lr = lr then begin
      if p^.new <> v then
        bug_check('oli:record_live_exposed_lr -- live-exposed lr conflict%$');
      return;
    end;
    p := p^.next;
  end;
  p := mrh_$alloc(oli_heap, 12);
  p^.next := oli_exposed^[k];
  oli_exposed^[k] := p;
  p^.lr := lr;
  p^.new := v;
end;

{ get_live_exposed_lr - lr's replacement in column k (a pair half's
  through its mate's), else a new live range of its register file and
  properties, made complex and recorded.  0x25CA4E, 0xDC bytes. }

function get_live_exposed_lr(
    k: integer32;
    lr: lr_ptr_t): lr_ptr_t; options(val_param); internal;
label
  99;
var
  p: oli_lrmap_ptr_t;
  x, nl: lr_ptr_t;
begin
  p := oli_exposed^[k];
  while p <> nil do begin
    if p^.lr = lr then begin
      get_live_exposed_lr := p^.new;
      goto 99;
    end;
    if (integer(p^.lr^.rrp) & 3) <> 0 then
      if p^.lr^.mate = lr then begin
        get_live_exposed_lr := p^.new^.mate;
        goto 99;
      end;
    p := p^.next;
  end;
  p := mrh_$alloc(oli_heap, 12);
  p^.next := oli_exposed^[k];
  oli_exposed^[k] := p;
  p^.lr := lr;
  if (integer(lr^.rrp) & 3) <> 0 then begin
    x := lir_$new_live_range_fp_reg_pair;
    if rrp$fp_reg_even_only in lr^.rrp then
      nl := x
    else
      nl := x^.mate;
  end
  else if rrp$fp_reg in lr^.rrp then
    nl := lir_$new_live_range_fp_reg
  else
    nl := lir_$new_live_range_ip_reg;
  p^.new := nl;
  p^.new^.rrp := lr^.rrp;
  bv_$make_live_range_complex(oli_rtn, nl);
  get_live_exposed_lr := nl;
99:
end;

{ find_final_lr_in_column - lr's live range in column k (column 0 when
  the schedule's iterations together exceed oli_2e24).  0x25CB2A, 0x46
  bytes. }

function find_final_lr_in_column(
    lr: lr_ptr_t;
    k: integer32): lr_ptr_t; options(val_param); internal;
var
  p: oli_col_ptr_t;
begin
  p := oli_cols;
  while p^.lr <> lr do
    p := p^.next;
  if oli_iters + oli_niters > oli_2e24 then
    find_final_lr_in_column := p^.cols^[0]
  else
    find_final_lr_in_column := p^.cols^[k];
end;

{ record_final_lr_in_column - v is lr's live range in column k: column
  0 recorded in column 0 (or all columns from 1 when oli_2e24 is not
  below the iterations); another only when oli_2e24 is that column's
  place (2 niters + k - 3) or not beyond 2 niters - 3.  0x25CB70, 0xA6
  bytes. }

procedure record_final_lr_in_column(
    v: lr_ptr_t;
    lr: lr_ptr_t;
    k: integer32); options(val_param); internal;
var
  p: oli_col_ptr_t;
  m: integer32;
begin
  p := oli_cols;
  while p^.lr <> lr do
    p := p^.next;
  if k = 0 then begin
    if oli_2e24 < oli_niters then
      p^.cols^[0] := v
    else
      for m := 1 to oli_niters do
        p^.cols^[m] := v;
  end
  else if (oli_2e24 = oli_niters * 2 + k - 3) or
      (oli_niters * 2 - 3 >= oli_2e24) then
    p^.cols^[k] := v;
end;

{ build_final_lr_in_col_list - a column record for each register live
  range final in the loop but the counter (not exposed): its kind, its
  segment's induction or reduction kind (+14), columns 0 .. niters.
  0x25CC16, 0xB6 bytes. }

procedure build_final_lr_in_col_list; internal;
var
  s: lts_ptr_t;
  p: oli_col_ptr_t;
  l: iv_lts_ptr_t;
begin
  s := oli_bb^.finals;
  while s <> nil do begin
    if s^.refs^.h.kind in [operand$ip_reg..operand$fp_reg_pair] then
      if s^.lr <> oli_counter then
        if not s^.f2.exposed then begin
          l := iv_lts_ptr_t(s^.l24);
          p := mrh_$alloc(oli_heap, 16);
          if l = nil then
            p^.ikind := 0
          else
            p^.ikind := l^.h.kind;
          p^.next := oli_cols;
          oli_cols := p;
          p^.lr := s^.lr;
          p^.cols := mrh_$alloc(oli_heap, (oli_niters + 1) * 4);
          p^.kind := ord(s^.refs^.h.kind);
        end;
    s := s^.next_final;
  end;
end;

{ link_lrs - in bb (after its last instruction before the control
  transfers, or before its first), live range b made a's value less v:
  a move (move, movei, copyd by register file kind) when v is the
  constant 0 and a and b differ, else a sub (subi) of v's operand, a
  modify when a is b.  0x25CCCC, 0x1FE bytes: for another kind the
  move's instruction is not set (kept). }

procedure link_lrs(
    v: oli_mval_ptr_t;
    a: lr_ptr_t;
    b: lr_ptr_t;
    bb: bb_ptr_t;
    after: boolean;
    kind: integer); options(val_param); internal;
var
  p, i: instr_ptr_t;
  opc: integer;
  tmp: opnd_t;
begin
  if after then begin
    p := bb^.last;
    while instruction_attributes[p^.opc].class in
        [class$branch, class$fp_branch, class$jump] do
      p := p^.prev;
  end
  else
    p := bb^.first;
  if (v^.kind = 3) and (v^.value = 0) then begin
    if a = b then
      return;
    if kind = 1 then
      i := lir_$optimizer_new_instruction(p, 75, after)     { move }
    else if kind = 2 then
      i := lir_$optimizer_new_instruction(p, 133, after)    { movei }
    else if kind = 3 then
      i := lir_$optimizer_new_instruction(p, 161, after);   { copyd }
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.b3 :=
        (opnd_bytes_ptr_t(addr(i^.opnds[1]))^.b3 & 16#E0) ! kind;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.num := 1;
    i^.opnds[1].ptr := a;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.b3 :=
        (opnd_bytes_ptr_t(addr(i^.opnds[2]))^.b3 & 16#E0) ! kind;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 8;
    i^.opnds[2].h.num := 2;
    i^.opnds[2].ptr := b;
    if kind = 3 then begin
      opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 17;
      opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 9;
      opnd_bytes_ptr_t(addr(i^.opnds[3]))^.b3 :=
          (opnd_bytes_ptr_t(addr(i^.opnds[3]))^.b3 & 16#E0) ! kind;
      opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 18;
      i^.opnds[3].h.num := 3;
      i^.opnds[3].ptr := a^.mate;
      opnd_bytes_ptr_t(addr(i^.opnds[4]))^.b3 :=
          (opnd_bytes_ptr_t(addr(i^.opnds[4]))^.b3 & 16#E0) ! kind;
      opnd_bytes_ptr_t(addr(i^.opnds[4]))^.rrp := 10;
      i^.opnds[4].h.num := 4;
      i^.opnds[4].ptr := b^.mate;
    end;
  end
  else begin
    if kind = 1 then
      opc := 81                         { sub }
    else
      opc := 138;                       { subi }
    operand_gets_materialized_value(addr(tmp), v, kind, opc, 1, bb);
    i := lir_$optimizer_new_instruction(p, opc, after);
    i^.opnds[1] := tmp;
    i^.opnds[1].h.num := 1;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.b3 :=
        (opnd_bytes_ptr_t(addr(i^.opnds[2]))^.b3 & 16#E0) ! kind;
    i^.opnds[2].h.num := 2;
    i^.opnds[2].ptr := a;
    if a = b then begin
      opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 48;
      opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 4;
    end
    else begin
      opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 16;
      opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
    end;
    opnd_bytes_ptr_t(addr(i^.opnds[3]))^.b3 :=
        (opnd_bytes_ptr_t(addr(i^.opnds[3]))^.b3 & 16#E0) ! kind;
    i^.opnds[3].h.num := 3;
    i^.opnds[3].ptr := b;
  end;
end;

{ link_final_induction_vars - in each tail block, each final live
  range's column copy linked back to it, less its induction variable's
  final adjustment (oli_ivadjs, in the columns' order) or 0; not for a
  pair's odd half or a reduction.  0x25CECA, 0xD2 bytes. }

procedure link_final_induction_vars; internal;
var
  zero_mv, mv: oli_mval_t;
  p: oli_col_ptr_t;
  a: oli_ivadj_ptr_t;
  k: integer32;
begin
  zero_mv.kind := 3;
  zero_mv.value := 0;
  p := oli_cols;
  a := oli_ivadjs;
  while p <> nil do begin
    if (a <> nil) and (p^.lr = a^.ilts^.lr) then begin
      mv := a^.final;
      a := a^.next;
    end
    else
      mv := zero_mv;
    if not (rrp$fp_reg_odd_only in p^.lr^.rrp) then
      if p^.ikind <> 5 then
        for k := 1 to oli_niters do
          link_lrs(addr(mv), p^.cols^[k], p^.lr, oli_tails^[k - 1], true,
              p^.kind);
    p := p^.next;
  end;
  if a <> nil then
    bug_check('OLI-link_final_induction_vars: induction increment unaccounted for.%$');
end;
