{ sched - the instruction scheduler (cc.a88k only): the SCHED phase
  (12, after XTP and before register allocation, on virtual
  registers).  A list scheduler run block by block.  Pass 1 takes the
  block's instructions off it and walks back from its end (the closing
  branches, the final segments) placing each instruction once all its
  readers are placed, so computing its precedence height: the longest
  chain of operand delays to the block's end, in quarter cycles, with
  a register pressure bonus in the low two bits.  Lock bits on the
  segments and live ranges (+3 bit 2) keep what may not move in place:
  values still read, physical argument and result registers next to
  their calls (test_p1_call_lock), condition code chains, a final
  call, conditional traps' drivers.  Pass 2 then issues the
  instructions cycle by cycle from a ready queue ordered by height:
  each cycle has an integer slot and a floating slot (a call, ENTRY,
  LIMIT, SVC or floating control instruction takes both); a floating
  add may be fused with the multiply in the floating slot into a
  five-operand instruction (ADDS5, SUBS5, TRUNCSI5, ADDD5, SUBD5,
  TRUNCDI5), two single-word loads or stores of adjacent words may
  share the integer slot (made LOADSE/LOADSO, STORESE/STORESO), and a
  cycle's floating register reads and writes (fp_registers_busy.init)
  are limited by sched_3158.  The values an issued instruction
  produces enter a 16-cycle ring by their delay; an instruction reading
  a value still in the ring stalls (stall cycles are counted in each
  instruction's +2 bits 3..0).  The instructions go back into the
  block in issue order, a cycle's instructions after the first marked
  grouped.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x273C90  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x273CB2  fix_instr_prev_ptrs (internal)
    --------  0x273CE0  sched_$collect_memory_and_cc_properties (internal)
    --------  0x273F66  get_phys_lr_num (internal)
    --------  0x273FA0  walker_initialize (internal)
    --------  0x273FAE  walker_excise_current_item (internal)
    --------  0x274004  walker_advance_to_next_item (internal)
    --------  0x274024  enqueue_instruction (internal)
    --------  0x274152  check_clobbered_registers (internal)
    --------  0x274234  exit_active (internal)
    --------  0x27425C  promote_p2_temp_actives (internal)
    --------  0x2742F0  p2_temp_act_instr (internal)
    --------  0x274308  p1_activate (internal)
    --------  0x274376  p1_setup_lts (internal)
    --------  0x274412  p1_initial_touch_instruction (internal)
    --------  0x2745B4  p1_touch_segment (internal)
    --------  0x274758  instr_ok_as_trapcc_driver (internal)
    --------  0x274824  test_p1_trapcc_lock (internal)
    --------  0x274936  undo_p1_lock_test (internal)
    --------  0x2749A4  test_p1_call_lock (internal)
    --------  0x274FA4  test_p1_lock (internal)
    --------  0x275382  register_pressure (internal)
    --------  0x27545A  remove_lts_from_final_list (internal)
    --------  0x27549C  pass1 (internal)
    --------  0x275E0A  p2_process_lts (internal)
    --------  0x2761CA  init_p2_instr_update (internal)
    --------  0x2762DA  undo_p2_lock_test (internal)
    --------  0x2763A0  all_inputs_available (internal)
    --------  0x276474  test_p2_call_lock (internal)
    --------  0x276B3E  test_p2_lock (internal)
    --------  0x276F90  instr_would_stall (internal)
    --------  0x27704E  can_make_into_rmw_and_combine_lts (internal)
    --------  0x277132  get_operand_p_p (internal)
    --------  0x277262  can_be_5opified (internal)
    --------  0x2774F4  instr_would_fit (internal)
    --------  0x27781C  fix_even_odd_property (internal)
    --------  0x27784E  swap_operands (in canonicalize_existing_rmw)
    --------  0x27792E  canonicalize_existing_rmw (internal)
    --------  0x277A42  make_into_rmw_and_combine_lts (internal)
    --------  0x277C46  fit_instr (internal)
    --------  0x2783D8  generate_stall_cycle (internal)
    --------  0x2783F2  final_p2_instr_update (internal)
    --------  0x2785BE  only_final_call_and_seq (in pass2)
    --------  0x278606  select_first_instruction (in pass2)
    --------  0x278900  pass2 (internal)
    --------  0x278F9C  drop_unneeded_instructions (internal)
    --------  0x27900A  sched_$begin_compilation
    --------  0x27900C  sched_$end_compilation
    --------  0x27900E  sched_$end_routine
    --------  0x279010  sched_$process_routine
    A5 0x48FD08 (0x3164 bytes): the 16 lists of the ring (+0, 130
    segments each) and their counts (+0x2080), 4096 bytes no
    instruction reaches (+0x20C0), the three queues (+0x30C0, +0x30D0,
    +0x30E0), the cycle's slots and counters (+0x30EC .. +0x3162;
    sched_3158, set by lir_main, among them).  The section
    sched_readonly_tables (0x2BE108, 768 bytes): fp_registers_busy
    (fp_registers_busy.init, included after exs.ins.pas as the .blocks
    list has it).

  Every routine but the four entry points is internal and reaches the
  unit's data through sched_$process_routine's A5; the two nested
  routines of pass2 and swap_operands use nothing of their parents and
  are called without a static link (rev889-patterns 128).

  Batch A's records are read through views (sc_instr_t, sc_opnd_t,
  sc_lts_t, sc_lr_t, sc_bb_t, sc_rtn_v_t; the offsets and meanings are
  reported in docs/backend-plan.md): during SCHED an instruction's +16
  is its mark (low bits its state), +28 its height and +30 its enable
  count, +2 bits 3..0 its stall cycles; a segment's +3 bit 3 set up,
  bit 2 its lock bit, +28 the touched chain, +32 its height and +34
  its enable count; a live range's +3 bit 2 its lock bit.

  Not known from the original: every local, parameter, type and module
  variable name but the routines' (the .blocks names) and those the
  messages give (last_ip_cc_start, last_fp_cc_start, Fitter.fivop,
  last_seg, last_seg_mate, cc_clobbering_call_count, the lock bits, EC
  for the enable counts). }
module sched;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang/common/source/exs.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/fp_registers_busy.init';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { Instruction classes as the image's masks group them. }
  sc_unscheduled = [class$entry, class$enable, class$seq, class$limit,
      class$trap, class$svc, class$return,
      class$trap_cond];                 { 0x09104A90 }
  sc_calls = [class$call, class$svc];   { 0x100004 }
  sc_call_like = [class$call, class$entry, class$svc, class$return,
      class$join_bp];                   { 0x05100014 }
  sc_no_slot = [class$entry, class$seq, class$limit, class$pmove,
      class$label, class$join_bp];      { 0x040C0A10: take no slot }

  { Operand kinds as the image's masks group them. }
  sc_regs_and_memory = [operand$ip_reg .. operand$well_behaved_memory];
                                        { 0xFFE }
  sc_memory = [operand$argument_block_memory .. operand$well_behaved_memory];
                                        { 0xE00 }
  sc_ccs = [operand$ip_condition_codes, operand$fp_condition_codes];
                                        { 0x180 }
  sc_pairs = [operand$fp_reg_pair, operand$fp_reg_pair_physical,
      operand$fp_reg_pair_like];        { 0x4048 }

type
  sc_instr_ptr_t = ^sc_instr_t;
  sc_opnd_ptr_t = ^sc_opnd_t;
  sc_lts_ptr_t = ^sc_lts_t;
  sc_lr_ptr_t = ^sc_lr_t;
  sc_bb_ptr_t = ^sc_bb_t;

  { opnd_t (batch A's) with the links typed as SCHED follows them. }
  sc_opnd_t = record
    h: opnd_hdr_t;                      { +0 }
    link: sc_opnd_ptr_t;                { +4 }
    case integer of                     { +8 }
      1: (value: integer32);
      2: (lts: sc_lts_ptr_t);
  end;

  { instr_hdr_t (batch A's) with +2 bits 3..0 as SCHED writes them: the
    stall cycles before the instruction issued (lst's cycle column, ra's
    clock; batch A's do_not_delete, b2_2 .. b2_0 there).  b2_6 marks a
    live instruction (a deleted one has it clear: "Reference to deleted
    instruction"); grouped (+0 bit 2) one followed by another in its
    cycle; width (+3) of a branch its squash mode (bits 7..6), of a
    call bits 3 and 5 a final call. }
  sc_instr_hdr_t = packed record
    atomic_update: boolean;             { +0 .7: bus-locking }
    preference: boolean;                { .6 }
    quad_aligned: boolean;              { .5 }
    sets_cc: boolean;                   { .4 }
    fp_ccs: boolean;                    { .3 }
    grouped: boolean;                   { .2 }
    b0_1, b0_0: boolean;
    nopnds: 0..255;                     { +1 }
    b2_7: boolean;                      { +2 .7 }
    b2_6: boolean;                      { .6 }
    b2_5, b2_4: boolean;
    stalls: 0..15;                      { .3..0 }
    case integer of                     { +3 }
      1: (width: 0..255);
      2: (modify: 0..3;                 { .7..6 }
          lsq: 0..3;
          b3_3, b3_2, b3_1, b3_0: boolean);
  end;

  { instr_t (batch A's) as SCHED uses it: mark (+16) the routine's marks
    (sc_marks) when the instruction was first touched in the block, its
    low two bits its state (both set when pass 1 places it; bit 0
    cleared when pass 2 issues it, bit 1 when it is put back in the
    block); l24 (+24) cleared on the first touch; height (+28) its
    precedence height (in quarter cycles: each delay counts four, plus
    four; the low two bits pass 1's register pressure bonus); enable
    (+30) the readers (pass 1) or inputs (pass 2) not yet handled: it is
    enabled at 0; num (+42) its serial number, compared unsigned. }
  sc_instr_t = record
    h: sc_instr_hdr_t;                  { +0 }
    next: sc_instr_ptr_t;               { +4: in its block, or on one of
                                          SCHED's queues (the last
                                          pointing to itself) }
    prev: sc_instr_ptr_t;               { +8 }
    bb: bb_ptr_t;                       { +12 }
    mark: integer32;                    { +16 }
    opc: opc$w_t;                       { +20 }
    w22: integer;                       { +22 }
    l24: integer32;                     { +24 }
    height: 0..65535;                   { +28 }
    enable: integer;                    { +30 }
    l32: integer32;                     { +32 }
    l36: integer32;                     { +36 }
    class: char;                        { +40 }
    b41: char;                          { +41 }
    num: 0..65535;                      { +42 }
    opnds: array [1..255] of sc_opnd_t; { +44 }
  end;

  { lts_t (batch A's) as SCHED uses it: setup (+3 bit 3) set up for
    the block by pass 1, locked (+3 bit 2) its lock bit; touched (+28)
    the exposed segments pass 1 met, chained; w32 (+32) the height its
    readers reached; ec (+34) its enable count, the readers not yet
    scheduled. }
  sc_lts_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      num: 0..255;
      exposed: boolean;                 { +3 .7 }
      first_in_bb: boolean;             { .6 }
      b3_5: boolean;                    { .5 }
      final: boolean;                   { .4 }
      setup: boolean;                   { .3 }
      locked: boolean;                  { .2 }
      b3_1, b3_0: boolean;
      end;
    refs: sc_opnd_ptr_t;                { +4 }
    next: sc_lts_ptr_t;                 { +8 }
    bb: bb_ptr_t;                       { +12 }
    next_exposed: sc_lts_ptr_t;         { +16 }
    next_final: sc_lts_ptr_t;           { +20 }
    l24: integer32;                     { +24 }
    touched: sc_lts_ptr_t;              { +28 }
    w32: 0..65535;                      { +32 }
    ec: integer;                        { +34 }
    mark: integer32;                    { +36 }
    l40: integer32;                     { +40 }
    l44: univ_ptr;                      { +44 }
    lr: sc_lr_ptr_t;                    { +48 }
  end;

  { lr_t (batch A's) as SCHED uses it: locked (+3 bit 2) its lock
    bit. }
  sc_lr_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      reg: 0..255;
      physical: boolean;                { +3 .7 }
      no_modify: boolean;               { .6 }
      serialize: boolean;               { .5 }
      b3_4, b3_3: boolean;
      locked: boolean;                  { .2 }
      b3_1, b3_0: boolean;
      end;
    id: 0..65535;                       { +4 }
    num: integer;                       { +6 }
    l8: integer32;                      { +8 }
    next: sc_lr_ptr_t;                  { +12 }
    mate: sc_lr_ptr_t;                  { +16 }
    space20: array [20..35] of char;    { +20 }
    ltss: sc_lts_ptr_t;                 { +36 }
    l40: integer32;                     { +40 }
    l44: integer32;                     { +44 }
    l48: integer32;                     { +48 }
    l52: integer32;                     { +52 }
    w56: integer;                       { +56: its segments' count }
  end;

  { bb_t (batch A's) with the lists typed as SCHED follows them. }
  sc_bb_t = record
    space0: array [0..9] of char;       { +0 }
    num: integer;                       { +10 }
    space12: array [12..15] of char;    { +12 }
    f: bb_flags_t;                      { +16 }
    space20: array [20..33] of char;    { +20 }
    first: sc_instr_ptr_t;              { +34 }
    last: sc_instr_ptr_t;               { +38 }
    space42: array [42..61] of char;    { +42 }
    exposed: sc_lts_ptr_t;              { +62 }
    finals: sc_lts_ptr_t;               { +66 }
    space70: array [70..113] of char;   { +70 }
    next114: sc_bb_ptr_t;               { +114 }
  end;

  { rtn_t (batch A's) +132, +136: the floating and integer condition
    codes' live ranges (oli's oli_rtn_v_t). }
  sc_rtn_v_ptr_t = ^sc_rtn_v_t;
  sc_rtn_v_t = record
    space0: array [0..131] of char;
    fp_cc: sc_lr_ptr_t;                 { +132 }
    ip_cc: sc_lr_ptr_t;                 { +136 }
  end;

  { What a call or SVC carries after its n operands: the registers it
    clobbers (bit 30 of ip: the integer condition codes, bit 31 the
    floating ones) and its conventions (a call's). }
  sc_clob_ptr_t = ^sc_clob_t;
  sc_clob_t = record
    fp_hi: bv_word_t;                   { +44 + 12n: F32..F63 }
    fp_lo: bv_word_t;                   { +48 + 12n: F0..F31 }
    ip: bv_word_t;                      { +52 + 12n }
    conv: call_conv_$ptr_t;             { +56 + 12n }
  end;

  { lir's physical live ranges by register (lir_3f90 the floating,
    lir_4090 the integer). }
  sc_phys_ptr_t = ^sc_phys_t;
  sc_phys_t = array [0..63] of sc_lr_ptr_t;

  { A queue of instructions chained at their next, the last pointing to
    itself, with a cursor (walker_initialize, _advance_to_next_item,
    _excise_current_item): cur the item the walk is at, prev the one
    before it. }
  sc_walker_ptr_t = ^sc_walker_t;
  sc_walker_t = record
    head: sc_instr_ptr_t;               { +0 }
    cur: sc_instr_ptr_t;                { +4 }
    prev: sc_instr_ptr_t;               { +8 }
  end;

  { The physical registers as one set: 0..31 the integer registers,
    32..95 the floating ones. }
  sc_regs_t = set of 0..95;

  { A chain of operands' head: a segment (its refs) or an operand (its
    link), both at +4 (get_operand_p_p), and a link in such a chain. }
  sc_chain_ptr_t = ^sc_chain_t;
  sc_chain_t = record
    space0: integer32;                  { +0 }
    first: sc_opnd_ptr_t;               { +4 }
  end;
  sc_link_ptr_t = ^sc_opnd_ptr_t;

  { The fitter's record (pass 2's frame, three of them): a floating add
    to be fused with a multiply (can_be_5opified, fit_instr: the
    "Fitter.fivop" of the messages) and the order of a load or store
    pair.  which (+0) the add's input that the multiply feeds (1 or
    2), opnd_pp and mate_pp (+4, +8) the links to it (and to its odd
    half's operand, k + 3, for a double) in its segment's readers,
    save_pp and save_mate_pp (+12, +16) those of a try that failed,
    tail_pp and mate_tail_pp (+20, +24) the chains' last links,
    last_seg and last_seg_mate (+28, +32) the input's segments, rmw_kind
    (+36) can_make_into_rmw_and_combine_lts's kind, existing_rmw (+38)
    the add already modifies its result in place, swapped (+40) the
    pair's second instruction is the lower word.  42 bytes (pass 2
    copies five longword pairs and a word). }
  sc_fit_t = record
    which: integer32;                   { +0 }
    opnd_pp: sc_link_ptr_t;             { +4 }
    mate_pp: sc_link_ptr_t;             { +8 }
    save_pp: sc_link_ptr_t;             { +12 }
    save_mate_pp: sc_link_ptr_t;        { +16 }
    tail_pp: sc_link_ptr_t;             { +20 }
    mate_tail_pp: sc_link_ptr_t;        { +24 }
    last_seg: sc_lts_ptr_t;             { +28 }
    last_seg_mate: sc_lts_ptr_t;        { +32 }
    rmw_kind: integer;                  { +36 }
    existing_rmw: boolean;              { +38 }
    pad39: char;                        { +39 }
    swapped: boolean;                   { +40 }
    pad41: char;                        { +41 }
  end;

  { A literal-pool operand's literal as SCHED reads and makes it (asm's
    lit_t's first 16 bytes: kind 12 a single real held as a double,
    the double at +8). }
  sc_lit_ptr_t = ^sc_lit_t;
  sc_lit_t = record
    l0: integer32;                      { +0 }
    kind: integer;                      { +4 }
    w6: integer;                        { +6 }
    l8: integer32;                      { +8 }
    l12: integer32;                     { +12 }
  end;

  { The pipeline's ring: for each of 16 cycles (the clock modulo 16),
    the segments whose values become available then. }
  sc_ring_list_t = array [1..130] of sc_lts_ptr_t;

  { A live range's or segment's rrp as the word fix_even_odd_property
    ors into. }
  sc_rrp_ptr_t = ^sc_rrp_t;
  sc_rrp_t = record
    case integer of
      1: (s: rrp$set_t);
      2: (w: integer);
  end;

  { A double from a literal's two longwords (token_$make_real_lit_pair
    takes doubles by address). }
  sc_dbl_t = record
    case integer of
      1: (d: double);
      2: (l: array [1..2] of integer32);
  end;

{ The module's data (A5 0x48FD08, 0x3164 bytes): every cell extern and
  defined in address order (dpc lays defined cells out in define-list
  order after any own variables: lir_main.pas's scheme), so that
  sched_3158 (backend.ins.pas's, set by lir_main) is at its address.
  The four booleans at the end are a word apart in the image too. }
var
  sc_ring: extern array [0..15] of sc_ring_list_t;     { +0x0000 }
  sc_ring_count: extern array [0..15] of integer32;    { +0x2080 }
  sc_unused_20c0: extern array [0..1023] of integer32; { +0x20C0: not
                                          referenced }
  sc_temp: extern sc_walker_t;          { +0x30C0: pass 2's temporarily
                                          active instructions }
  sc_unused_30cc: extern integer32;     { +0x30CC }
  sc_ready: extern sc_walker_t;         { +0x30D0: the ready queue, by
                                          height }
  sc_unused_30dc: extern integer32;     { +0x30DC }
  sc_active: extern sc_walker_t;        { +0x30E0: pass 1's active
                                          instructions }
  sc_touched_last: extern sc_lts_ptr_t; { +0x30EC: the exposed segments
                                          pass 1 touched (chained at
                                          their +28), the last }
  sc_touched: extern sc_lts_ptr_t;      { +0x30F0: ... the first }
  sc_marks: extern integer32;           { +0x30F4: the routine's marks for
                                          this run (rtn +180) }
  sc_last_cycle: extern integer32;      { +0x30F8: the clock when the last
                                          cycle closed }
  sc_clock: extern integer32;           { +0x30FC: pass 2's cycle count }
  sc_fp_cc_clobbers: extern integer32;  { +0x3100: instructions placed
                                          by pass 1 while the floating
                                          condition code chain is broken,
                                          less those pass 2 has issued
                                          (the cc_clobbering_call_count) }
  sc_ip_cc_clobbers: extern integer32;  { +0x3104: the same for the
                                          integer condition codes }
  sc_last_issued: extern sc_instr_ptr_t;     { +0x3108: the cycle's last
                                          instruction put back in the
                                          block (marked grouped when
                                          another follows) }
  sc_seq_slot: extern sc_instr_ptr_t;   { +0x310C: the cycle's SEQ or join
                                          birthpoint }
  sc_ipccnop_slot: extern sc_instr_ptr_t;    { +0x3110: its IPCCNOP }
  sc_int_pair: extern sc_instr_ptr_t;   { +0x3114: the second of a load
                                          or store pair }
  sc_int_slot: extern sc_instr_ptr_t;   { +0x3118: the integer slot }
  sc_fp_reads: extern integer32;        { +0x311C: the floating registers
                                          the cycle reads (singles) }
  sc_fp_writes: extern integer32;       { +0x3120: ... writes }
  sc_fp_add: extern sc_instr_ptr_t;     { +0x3124: the add fused with the
                                          multiply in the floating slot }
  sc_fp_slot: extern sc_instr_ptr_t;    { +0x3128: the floating slot }
  sc_p2_final_call: extern sc_instr_ptr_t;   { +0x312C: the final call,
                                          which pass 2 issues last }
  sc_final_call: extern sc_instr_ptr_t; { +0x3130: the final call while
                                          pass 1 has not placed it }
  sc_branch_cc: extern sc_lts_ptr_t;    { +0x3134: the closing
                                          conditional branch's condition
                                          code segment }
  sc_fp_cc_start: extern sc_lts_ptr_t;  { +0x3138: last_fp_cc_start }
  sc_ip_cc_start: extern sc_lts_ptr_t;  { +0x313C: last_ip_cc_start }
  sc_out_last: extern sc_instr_ptr_t;   { +0x3140: the block's new
                                          instruction list (its labels,
                                          then the instructions as pass 2
                                          issues them), the last }
  sc_out: extern sc_instr_ptr_t;        { +0x3144: ... the first }
  sc_branches_last: extern sc_instr_ptr_t;   { +0x3148: the closing
                                          branches and RETURN, the last }
  sc_branches: extern sc_instr_ptr_t;   { +0x314C: ... the first }
  sc_bb: extern sc_bb_ptr_t;            { +0x3150: the block }
  sc_rtn: extern rtn_ptr_t;             { +0x3154: the routine }
  { sched_3158 (backend.ins.pas): +0x3158, the floating register
    traffic a cycle may have (lir_main sets it). }
  sc_entry_pending: extern boolean;     { +0x315C: the block is an entry
                                          block whose ENTRY or LIMIT has
                                          not issued }
  sc_fp_cc_live: extern boolean;        { +0x315E: the floating condition
                                          code chain is broken (clobbered
                                          or rewritten while live) }
  sc_ip_cc_live: extern boolean;        { +0x3160: ... the integer one }
  sc_cycle_used: extern boolean;        { +0x3162: an instruction that
                                          takes a cycle was issued in it }

define
  sc_ring, sc_ring_count, sc_unused_20c0, sc_temp, sc_unused_30cc,
  sc_ready, sc_unused_30dc, sc_active, sc_touched_last, sc_touched,
  sc_marks, sc_last_cycle, sc_clock, sc_fp_cc_clobbers,
  sc_ip_cc_clobbers, sc_last_issued, sc_seq_slot, sc_ipccnop_slot,
  sc_int_pair, sc_int_slot, sc_fp_reads, sc_fp_writes, sc_fp_add,
  sc_fp_slot, sc_p2_final_call, sc_final_call, sc_branch_cc,
  sc_fp_cc_start, sc_ip_cc_start, sc_out_last, sc_out,
  sc_branches_last, sc_branches, sc_bb, sc_rtn, sched_3158,
  sc_entry_pending, sc_fp_cc_live, sc_ip_cc_live, sc_cycle_used;

{ utils_ins_$operands_instruction (utils.ins.pas) is the unit's first
  routine (0x273C90, 0x22 bytes); the unit also computes it inline
  (rev889-patterns 131). }

{ FIX_INSTR_PREV_PTRS - bb's instructions' prev links rebuilt from
  their next links, and its last instruction.

  0x273CB2, 0x2E bytes, internal (no A5): bb by value. }

procedure fix_instr_prev_ptrs(
    bb: sc_bb_ptr_t); options(val_param, internal);
var
  i: sc_instr_ptr_t;
  prev: sc_instr_ptr_t;
begin
  prev := nil;
  i := bb^.first;
  while i <> nil do begin
    i^.prev := prev;
    prev := i;
    i := i^.next;
  end;
  bb^.last := prev;
end;

{ SCHED_$COLLECT_MEMORY_AND_CC_PROPERTIES - the routine's memory model
  properties as its callers' conventions will see them (rtn_t's +227,
  +228 bits, which call_conv copies to a later call's conventions): it
  writes no condition codes whose live range is not written (the
  floating ones +132, the integer ones +136), reads and writes no
  memory unless it may raise an exception explicitly or a memory
  operand's instruction is not of an unscheduled class (a read clears
  no_memory_read, a write or modify no_memory_write), and touches the
  argument block only through its argument pointer's loads (operand 2)
  and stores (operand 3); a call that may touch uplevel dynamic
  storage (its conventions' +40 clear) or has no conventions, or any
  call when the routine's node +377 bits 6..4 are 5, counts as
  touching the argument block both ways.

  0x273CE0, 0x242 bytes, internal (no A5): rtn by value; the
  conventions at the call's +56 + 12n (`movea.l (0x38,A0,D1.w)').  The
  flags are stored bit by bit from `seq'/`not' (`lsr.b #7; lsl.b #4;
  andi.b #-17; or.b'); `ori.w #6,(226,A1)' sets +227 bits 2 and 1 at
  once and `andi.w #-7' clears them. }

procedure sched_$collect_memory_and_cc_properties(
    rtn: rtn_ptr_t); options(val_param, internal);
var
  rv: sc_rtn_v_ptr_t;
  may_raise: boolean;
  lr: sc_lr_ptr_t;
  lts: sc_lts_ptr_t;
  op: sc_opnd_ptr_t;
  i: sc_instr_ptr_t;
  cv: call_conv_$ptr_t;
begin
  rv := sc_rtn_v_ptr_t(rtn);
  rtn^.f228.no_fp_cc_write := (rv^.fp_cc^.rrp * [rrp$modify, rrp$write]) = [];
  rtn^.f228.no_ip_cc_write := (rv^.ip_cc^.rrp * [rrp$modify, rrp$write]) = [];
  may_raise := exs_$subprogram_may_propogate_exceptions_by_explicit_raise(il_180);
  rtn^.f226.no_memory_read := not may_raise;
  rtn^.f226.no_memory_write := not may_raise;
  rtn^.f226.no_arg_block_read := true;
  rtn^.f226.no_arg_block_write := true;

  lr := sc_lr_ptr_t(rtn^.lrs);
  while lr <> nil do begin
    if not lr^.f2.physical and
       ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) = []) then begin
      lts := lr^.ltss;
      while lts <> nil do begin
        op := lts^.refs;
        while op <> nil do begin
          if not (op^.h.kind in sc_memory) then
            bug_check('SCHED_$COLLECT_MEMORY_AND_CC_PROPERTIES -- unexpected operand kind%$');
          i := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(op)));
          if not (instruction_attributes[i^.opc].class in sc_unscheduled) then begin
            rtn^.f226.no_memory_read := false;
            if op^.h.write or op^.h.modify then
              rtn^.f226.no_memory_write := false;
          end;
          if instruction_attributes[i^.opc].class = class$call then begin
            cv := sc_clob_ptr_t(integer32(i) + 44 + 12 * i^.h.nopnds)^.conv;
            if (cv = nil) or
               (rshft(ord(il_180^.xc[377]) & 16#70, 4) = 5) or
               not cv^.uplevel_dynamic_storage_untouched then begin
              rtn^.f226.no_arg_block_read := false;
              rtn^.f226.no_arg_block_write := false;
            end;
          end;
          op := op^.link;
        end;
        lts := lts^.next;
      end;
    end;
    lr := lr^.next;
  end;

  { The argument pointer's references. }
  lts := sc_lr_ptr_t(rtn^.ap_lr)^.ltss;
  while lts <> nil do begin
    if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then
      op := lts^.refs^.link
    else
      op := lts^.refs;
    while op <> nil do begin
      i := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(op)));
      if not (instruction_attributes[i^.opc].class in sc_unscheduled) then
        if (instruction_attributes[i^.opc].class = class$load) and
           (op^.h.num = 2) then
          rtn^.f226.no_arg_block_read := false
        else if (instruction_attributes[i^.opc].class = class$store) and
                (op^.h.num = 3) then
          rtn^.f226.no_arg_block_write := false
        else begin
          rtn^.f226.no_arg_block_read := false;
          rtn^.f226.no_arg_block_write := false;
        end;
      op := op^.link;
    end;
    lts := lts^.next;
  end;
end;

{ get_phys_lr_num - whether lr is a physical register's live range (not
  a user-declared one: serialize clear), its register in n (32 up for
  a floating one).

  0x273F66, 0x3A bytes, internal, no frame: lr, n by address (`movea.l
  (8,SP),A1; move.l D0,(A1)'); `tst.w (A0)' tests rrp$ip_reg. }

function get_phys_lr_num(
    lr: sc_lr_ptr_t;
    out n: integer32): boolean; options(val_param, internal);
begin
  if not lr^.f2.physical or lr^.f2.serialize then
    get_phys_lr_num := false
  else begin
    if rrp$ip_reg in lr^.rrp then
      n := lr^.f2.reg
    else
      n := lr^.f2.reg + 32;
    get_phys_lr_num := true;
  end;
end;

{ walker_initialize - the walk of w starts at its head.

  0x273FA0, 0xE bytes, internal, no frame. }

procedure walker_initialize(
    w: sc_walker_ptr_t); options(val_param, internal);
begin
  w^.cur := w^.head;
  w^.prev := nil;
end;

{ walker_excise_current_item - the item w is at, taken off its queue;
  the walk moves to the next one (nil after the last).

  0x273FAE, 0x56 bytes, internal: A0.  The queue's last item points to
  itself: prev becomes the last when the last is taken. }

function walker_excise_current_item(
    w: sc_walker_ptr_t): sc_instr_ptr_t; options(val_param, internal);
var
  cur: sc_instr_ptr_t;
  next: sc_instr_ptr_t;
begin
  cur := w^.cur;
  if cur = cur^.next then
    next := nil
  else
    next := cur^.next;
  if w^.prev = nil then
    w^.head := next
  else if next = nil then
    w^.prev^.next := w^.prev
  else
    w^.prev^.next := next;
  w^.cur := next;
  cur^.next := nil;
  walker_excise_current_item := cur;
end;

{ walker_advance_to_next_item - the walk of w moves on one item.

  0x274004, 0x20 bytes, internal, no frame. }

procedure walker_advance_to_next_item(
    w: sc_walker_ptr_t); options(val_param, internal);
var
  cur: sc_instr_ptr_t;
begin
  cur := w^.cur;
  w^.prev := cur;
  if cur^.next = cur then
    w^.cur := nil
  else
    w^.cur := cur^.next;
end;

{ enqueue_instruction - instr put on queue q.  By height: in descending
  height, after those of its height with a lower or equal serial
  number; otherwise in ascending height, after those of its height
  with a higher or equal number.  The head is compared by height
  alone.

  0x274024, 0xCE bytes, internal: q, instr by value, by_height a byte
  (frame 16).  Heights and numbers compared unsigned (`bcs', `bls'). }

procedure enqueue_instruction(
    q: sc_walker_ptr_t;
    instr: sc_instr_ptr_t;
    by_height: boolean); options(val_param, internal);
label
  10, 99;
var
  p: sc_instr_ptr_t;
  n: sc_instr_ptr_t;
begin
  if instr^.next <> nil then
    instr_bug_check('SCHED_$ENQUEUE_INSTRUCTION: Enqueueing an instruction with non-nil next pointer: near line %LD%$',
                    instr^);
  p := q^.head;
  if p = nil then begin
    instr^.next := instr;
    q^.head := instr;
    goto 99;
  end;
  if by_height then begin
    if p^.height < instr^.height then
      goto 10;
    repeat
      n := p^.next;
      if n = p then begin
        instr^.next := instr;
        p^.next := instr;
        goto 99;
      end;
      if (n^.height < instr^.height) or
         ((n^.height = instr^.height) and (n^.num > instr^.num)) then begin
        instr^.next := n;
        p^.next := instr;
        goto 99;
      end;
      p := n;
    until false;
  end
  else begin
    if p^.height > instr^.height then
      goto 10;
    repeat
      n := p^.next;
      if n = p then begin
        instr^.next := instr;
        p^.next := instr;
        goto 99;
      end;
      if (n^.height > instr^.height) or
         ((n^.height = instr^.height) and (n^.num < instr^.num)) then begin
        instr^.next := n;
        p^.next := instr;
        goto 99;
      end;
      p := n;
    until false;
  end;
10:
  instr^.next := p;
  q^.head := instr;
99:
end;

{ check_clobbered_registers - whether instr is a call or SVC that
  clobbers a register whose live range is locked.  The condition codes
  it clobbers (its integer set's bits 30 and 31) are noted in
  sc_ip_cc_live and sc_fp_cc_live.

  0x274152, 0xE2 bytes, internal: instr by value; D0 (`st' first, kept
  for a hit).  The loop counts 32 with `dbf' and tests each register in
  the three sets (the integer ones below 30). }

function check_clobbered_registers(
    instr: sc_instr_ptr_t): boolean; options(val_param, internal);
label
  99;
var
  clob: sc_clob_ptr_t;
  r: integer32;
  ip_phys: sc_phys_ptr_t;
  fp_phys: sc_phys_ptr_t;
begin
  check_clobbered_registers := true;
  if instruction_attributes[instr^.opc].class in sc_calls then begin
    clob := sc_clob_ptr_t(integer32(instr) + 44 + 12 * instr^.h.nopnds);
    if 30 in clob^.ip then
      sc_ip_cc_live := true;
    if 31 in clob^.ip then
      sc_fp_cc_live := true;
    fp_phys := sc_phys_ptr_t(addr(lir_3f90));
    ip_phys := sc_phys_ptr_t(addr(lir_4090));
    for r := 0 to 31 do begin
      if (r in clob^.ip) and (r < 30) then
        if ip_phys^[r]^.f2.locked then
          goto 99;
      if r in clob^.fp_lo then
        if fp_phys^[r]^.f2.locked then
          goto 99;
      if r in clob^.fp_hi then
        if fp_phys^[r + 32]^.f2.locked then
          goto 99;
    end;
  end;
  check_clobbered_registers := false;
99:
end;

{ exit_active - whether lts is live out of the block: sc_branch_cc, or a
  final segment of a complex live range.

  0x274234, 0x28 bytes, internal, no frame: D0. }

function exit_active(
    lts: sc_lts_ptr_t): boolean; options(val_param, internal);
begin
  if lts = sc_branch_cc then
    exit_active := true
  else if lts^.f2.final and (lts^.lr^.id <> 0) then
    exit_active := true
  else
    exit_active := false;
end;

{ promote_p2_temp_actives - pass 2's temporarily active instructions
  moved to the ready queue (by height).

  0x27425C, 0x54 bytes, internal. }

procedure promote_p2_temp_actives; options(internal);
var
  i: sc_instr_ptr_t;
begin
  walker_initialize(addr(sc_temp));
  while sc_temp.cur <> nil do begin
    i := walker_excise_current_item(addr(sc_temp));
    if (i^.mark & 3) = 0 then
      instr_bug_check('SCHED_$PROMOTE_P2_TEMP_ACTIVES: State bits off: near line %LD%$',
                      i^);
    enqueue_instruction(addr(sc_ready), i, true);
  end;
end;

{ p2_temp_act_instr - i made temporarily active in pass 2.

  0x2742F0, 0x18 bytes, internal: i by value (frame 8:l). }

procedure p2_temp_act_instr(
    i: sc_instr_ptr_t); options(val_param, internal);
begin
  enqueue_instruction(addr(sc_temp), i, false);
end;

{ p1_activate - i made active in pass 1 (all its readers handled).

  0x274308, 0x34 bytes, internal. }

procedure p1_activate(
    i: sc_instr_ptr_t); options(val_param, internal);
begin
  if i^.next <> nil then
    instr_bug_check('SCHED_$P1_ACTIVATE: Losing in p1_activate: near line %LD%$',
                    i^);
  enqueue_instruction(addr(sc_active), i, false);
end;

{ p1_setup_lts - lts set up for pass 1: marked, final cleared, its
  height cleared and its enable count the readers whose instructions
  are live (+2 bit 6).

  0x274376, 0x6C bytes, internal.  A defined segment's first reference
  is its definition (skipped); every later one must read. }

procedure p1_setup_lts(
    lts: sc_lts_ptr_t); options(val_param, internal);
var
  op: sc_opnd_ptr_t;
begin
  lts^.f2.setup := true;
  op := lts^.refs;
  lts^.f2.final := false;
  lts^.w32 := 0;
  lts^.ec := 0;
  if not op^.h.read then
    op := op^.link;
  while op <> nil do begin
    if not op^.h.read then
      bug_check('SCHED_$P1_SETUP_LTS: Anomalous write reference%$');
    if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(op)))^.h.b2_6 then
      lts^.ec := lts^.ec + 1;
    op := op^.link;
  end;
end;

{ p1_initial_touch_instruction - i prepared for pass 1 the first time
  it is touched in the block (its mark below sc_marks): off any queue,
  l24 and its height cleared, its enable count the written register or
  memory operands whose segments are live out of the block or read by
  a live instruction (one that is read by none is marked unconsumed);
  an ENTRY's height 30000.  A bus-locking or deleted instruction is a
  bug check.

  0x274412, 0x102 bytes, internal.  `bset #6,(0x21,A3,D4.l)' marks the
  operand unconsumed; the operands counted `dbf' from 1 (D3). }

procedure p1_initial_touch_instruction(
    i: sc_instr_ptr_t); options(val_param, internal);
label
  10;
var
  k: integer32;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
  r: sc_opnd_ptr_t;
begin
  if i^.h.atomic_update then
    bug_check('SCHED_$P1_INITIAL_TOUCH_INSTRUCTION: Reference to bus-locking instruction: %3ZWD%$',
              i^.num);
  if not i^.h.b2_6 then
    bug_check('SCHED_$P1_INITIAL_TOUCH_INSTRUCTION: Reference to deleted instruction: %3ZWD%$',
              i^.num);
  if sc_marks > i^.mark then begin
    i^.mark := sc_marks;
    i^.next := nil;
    i^.l24 := 0;
    i^.enable := 0;
    for k := 1 to i^.h.nopnds do begin
      op := addr(i^.opnds[k]);
      if (op^.h.kind in sc_regs_and_memory) and not op^.h.read then begin
        lts := op^.lts;
        if not exit_active(lts) then begin
          r := op^.link;
          while r <> nil do begin
            if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(r)))^.h.b2_6 then
              goto 10;
            r := r^.link;
          end;
          op^.h.unconsumed := true;
          next;
        end;
10:
        i^.enable := i^.enable + 1;
      end;
    end;
    i^.height := 0;
    if instruction_attributes[i^.opc].class = class$entry then
      i^.height := 30000;
  end;
end;

{ p1_touch_segment - lts reached in pass 1's walk back from the block's
  end, its readers all handled (its enable count 0).  An exposed
  segment (its first reference a read) is put on the touched list.
  Otherwise its definition's instruction is touched: its height raised
  to the segment's height plus four times (the definition's delay plus
  one), a value read by a call or SVC alone, not as operand 1, given
  delay 0; and its enable count lowered: at 0 it becomes active.

  0x2745B4, 0x138 bytes, internal: lts by value.  The definition's
  instruction computed inline (`subi.l #32; sub.l'), and the reader's
  too; the reader's read bit tested with `btst D1,(1,A0)', D1 holding
  the class mask 0x100004 (bit 4 on memory: rev889-patterns 148).
  Heights compared unsigned (`bhi'). }

procedure p1_touch_segment(
    lts: sc_lts_ptr_t); options(val_param, internal);
var
  op: sc_opnd_ptr_t;
  i: sc_instr_ptr_t;
  r: sc_opnd_ptr_t;
  h: integer32;
begin
  if lts^.ec <> 0 then
    return;
  op := lts^.refs;
  if op^.h.read then begin
    if sc_touched_last = nil then
      sc_touched := lts
    else
      sc_touched_last^.touched := lts;
    lts^.touched := nil;
    sc_touched_last := lts;
    return;
  end;
  i := sc_instr_ptr_t(integer32(op) - 32 - op^.h.num * 12);
  p1_initial_touch_instruction(i);
  if not (op^.h.kind in sc_regs_and_memory) then
    bug_check('SCHED_$P1_TOUCH_SEGMENT: Anomalous output operand kind%$');
  r := op^.link;
  if r <> nil then
    if r^.link = nil then
      if instruction_attributes[sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12)^.opc].class
         in sc_calls then
        if r^.h.read and (r^.h.num > 1) then
          op^.h.b2_3_0 := 0;
  h := lts^.w32 + (op^.h.b2_3_0 + 1) * 4;
  if h <= i^.height then
    h := i^.height;
  i^.height := h;
  i^.enable := i^.enable - 1;
  if i^.enable = 0 then
    p1_activate(i)
  else if i^.enable < 0 then
    bug_check('SCHED_$P1_TOUCH_SEGMENT: Enable count is negative%$');
end;

{ instr_ok_as_trapcc_driver - whether i, the instruction that sets a
  conditional trap's condition codes, may move with the trap: each of
  its register and memory operands (but those of the trap's own live
  ranges lr_a, lr_b) is free: a plain read of an unlocked live range
  whose segment is not marked to be modified, or a write of a segment
  read by nothing else and not live out of the block.

  0x274758, 0xCC bytes, internal: i, lr_a, lr_b by value; D0.  The
  kinds 0xE7E (registers, physical registers and memory, not the
  condition codes); `andi.w #48' with 16 for a plain read. }

function instr_ok_as_trapcc_driver(
    i: sc_instr_ptr_t;
    lr_a: sc_lr_ptr_t;
    lr_b: sc_lr_ptr_t): boolean; options(val_param, internal);
label
  99;
var
  k: integer32;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
begin
  instr_ok_as_trapcc_driver := false;
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in [operand$ip_reg .. operand$fp_reg_pair_physical,
                      operand$argument_block_memory ..
                      operand$well_behaved_memory] then begin
      lts := op^.lts;
      lr := lts^.lr;
      if (lr <> lr_a) and (lr <> lr_b) then begin
        if (opnd_bytes_ptr_t(op)^.rrp & 16#30) = 16#10 then begin
          if not lts^.f2.locked then
            if lr^.f2.locked or (rrp$intend_to_modify in lts^.rrp) then
              goto 99;
        end
        else if (opnd_bytes_ptr_t(op)^.rrp & 16#0C) <> 0 then begin
          if not lts^.f2.locked then begin
            if lr^.f2.locked or (rrp$intend_to_modify in lts^.rrp) then
              goto 99;
            if (op^.link <> nil) or lts^.f2.final then
              goto 99;
          end;
        end;
      end;
    end;
  end;
  instr_ok_as_trapcc_driver := true;
99:
end;

{ test_p1_trapcc_lock - whether the conditional trap i must stay where
  it is in pass 1: false when the instruction that sets its condition
  codes (op, a condition code operand; through an IPCCNOP to the
  instruction that sets that one's operand 1) may move with it
  (instr_ok_as_trapcc_driver, with the live range of the trap's
  register operand 1 and, for a pair, its mate).

  0x274824, 0xD8 bytes, internal: i, op by address (frame 8:a,
  12:a); D0. }

function test_p1_trapcc_lock(
    i: sc_instr_ptr_t;
    op: sc_opnd_ptr_t): boolean; options(val_param, internal);
var
  lr_a: sc_lr_ptr_t;
  lr_b: sc_lr_ptr_t;
  lts: sc_lts_ptr_t;
  d: sc_instr_ptr_t;
begin
  if instruction_attributes[i^.opc].class <> class$trap_cond then
    bug_check('SCHED_$test_p1_trapcc_lock -- expected TRAP instruction%$');
  if (i^.opnds[1].h.kind in sc_regs_and_memory) and i^.opnds[1].h.read then begin
    lr_a := i^.opnds[1].lts^.lr;
    if i^.opnds[1].h.kind in sc_pairs then
      lr_b := lr_a^.mate
    else
      lr_b := nil;
  end
  else begin
    lr_a := nil;
    lr_b := nil;
  end;
  test_p1_trapcc_lock := false;
  lts := op^.lts;
  if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then begin
    d := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(lts^.refs)));
    if d^.opc = ord(opc$ipccnop) then begin
      lts := d^.opnds[1].lts;
      if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then
        d := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(lts^.refs)))
      else
        d := nil;
    end;
    if d <> nil then
      if instr_ok_as_trapcc_driver(d, lr_a, lr_b) then
        test_p1_trapcc_lock := true;
  end;
end;

{ undo_p1_lock_test - what test_p1_lock unlocked put back: the segments
  and live ranges i writes (not read, not unconsumed) locked again.

  0x274936, 0x6E bytes, internal.  The operands from the last
  (`subq.l #1' and `dbf'). }

procedure undo_p1_lock_test(
    i: sc_instr_ptr_t); options(val_param, internal);
var
  k: integer32;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
begin
  for k := i^.h.nopnds downto 1 do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0 then begin
        lts := op^.lts;
        lts^.f2.locked := true;
        lts^.lr^.f2.locked := true;
      end;
  end;
end;

{ test_p1_call_lock - whether the physical register that op (the first
  reference of a segment i reads) holds keeps its producer locked in
  pass 1.  An exposed segment (op has no reader after it): locked
  unless every exposed physical segment of the block is free (unlocked
  with a live consumer).  Otherwise op is a call's (call-like
  instruction's) physical result or argument: the call is touched and
  stays locked while one of its written physical registers' segments
  or live ranges is locked or read by an instruction already handled,
  while one of its read registers is locked but neither written by it
  nor a register it writes, or while a register it clobbers is locked
  and not one it writes.

  0x2749A4, 0x468 bytes, internal: op by address; D0 (the frame byte
  -58, `st' first).  The registers it writes are a set of 0..95 (the
  frame's -16, three longwords; an element added through a cleared
  temporary at -120 ored in, bounded by `cmpi 95' as a constructor:
  rev889-patterns 156; docs/dpc-gaps.md 29 and 38 for the test and the
  addition);
  the operands counted down from the last. }

function test_p1_call_lock(
    op: sc_opnd_ptr_t): boolean; options(val_param, internal);
label
  20, 30, 99;
var
  locked: boolean;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  n: integer32;
  r: sc_opnd_ptr_t;
  i: sc_instr_ptr_t;
  regs: sc_regs_t;
  k: integer32;
  j: integer32;
  o: sc_opnd_ptr_t;
  clob: sc_clob_ptr_t;
  ip_phys: sc_phys_ptr_t;
  fp_phys: sc_phys_ptr_t;
begin
  locked := true;
  if op^.link = nil then begin
    { An exposed physical input. }
    if not op^.h.read then
      bug_check('SCHED_$TEST_P1_CALL_LOCK: Anomalous exposed physical input%$');
    lts := sc_bb^.exposed;
    while lts <> nil do begin
      lr := lts^.lr;
      if lts^.f2.locked then begin
        if lts^.ec <> 0 then
          goto 99;
      end
      else begin
        if lr^.f2.locked then
          goto 99;
        if not get_phys_lr_num(lr, n) then
          goto 99;
        r := lts^.refs;
        if r^.link <> nil then
          bug_check('SCHED_$TEST_P1_CALL_LOCK: Exposed physical LTS has multiple consumers%$');
        if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(r)))^.next = nil then
          goto 99;
      end;
      lts := lts^.next_exposed;
    end;
    locked := false;
    goto 99;
  end;

  i := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(op)));
  if op^.link^.link <> nil then
    instr_bug_check('SCHED_$TEST_P1_CALL_LOCK: Physical input does not go to exactly one destination: near line %LD%$',
                    i^);
  if not (instruction_attributes[i^.opc].class in sc_call_like) then
    instr_bug_check('SCHED_$TEST_P1_CALL_LOCK: Physical input does not come from a call-type instruction: near line %LD%$',
                    i^);
  p1_initial_touch_instruction(i);

  { The physical registers it writes. }
  regs := [];
  for k := i^.h.nopnds downto 1 do begin
    o := addr(i^.opnds[k]);
    if o^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(o)^.rrp & 16#50) = 0 then begin
        lr := o^.lts^.lr;
        if get_phys_lr_num(lr, n) then
          regs := regs + [n];
        if o^.lts^.f2.locked then begin
          if o^.lts^.ec <> 0 then
            goto 99;
        end
        else begin
          if lr^.f2.locked then
            goto 99;
          if not get_phys_lr_num(lr, n) then
            goto 99;
          r := o^.link;
          if r <> nil then begin
            if r^.link <> nil then
              bug_check('SCHED_$TEST_P1_CALL_LOCK: Physical destination of call has multiple consumers%$');
            if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(r)))^.next = nil then
              goto 99;
          end;
        end;
      end;
  end;

  { The registers it reads. }
  for k := i^.h.nopnds downto 1 do begin
    o := addr(i^.opnds[k]);
    if o^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(o)^.rrp & 16#50) <> 0 then begin
        lts := o^.lts;
        lr := lts^.lr;
        if lr^.f2.locked and (o^.h.unconsumed or not lts^.f2.locked) then begin
          if get_phys_lr_num(lr, n) then begin
            if n in regs then
              goto 30;
            goto 99;
          end;
          for j := k + 1 to i^.h.nopnds do begin
            r := addr(i^.opnds[j]);
            if r^.h.kind in sc_regs_and_memory then
              if (opnd_bytes_ptr_t(r)^.rrp & 16#50) = 0 then
                if r^.lts^.lr = lr then
                  goto 30;
          end;
          goto 99;
        end;
        if lr^.f2.locked or lts^.f2.locked then
          goto 30;
        if not (rrp$intend_to_modify in lts^.rrp) then
          goto 30;
        if o^.h.intend_to_modify then
          goto 30;
        r := o^.link;
        while r^.link <> nil do
          r := r^.link;
        if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(r))) <> i then
          goto 99;
      end;
30:
  end;

  { The registers it clobbers. }
  if instruction_attributes[i^.opc].class in sc_calls then begin
    clob := sc_clob_ptr_t(integer32(i) + 44 + 12 * i^.h.nopnds);
    fp_phys := sc_phys_ptr_t(addr(lir_3f90));
    ip_phys := sc_phys_ptr_t(addr(lir_4090));
    for k := 0 to 31 do begin
      if (k in clob^.ip) and (k < 30) then
        if ip_phys^[k]^.f2.locked then
          if not (k in regs) then
            goto 99;
      if k in clob^.fp_lo then
        if fp_phys^[k]^.f2.locked then
          if not (k + 32 in regs) then
            goto 99;
      if k in clob^.fp_hi then
        if fp_phys^[k + 32]^.f2.locked then
          if not (k + 64 in regs) then
            goto 99;
    end;
  end;
  locked := false;
99:
  test_p1_call_lock := locked;
end;

{ test_p1_lock - whether i must stay locked in pass 1 (cannot yet be
  placed, walking back from the block's end).  Its written segments
  and live ranges are unlocked first (each must have been locked: the
  readers placed after it), and put back (undo_p1_lock_test) when it
  stays locked.  It is locked when another instruction holds the block
  (sc_final_call, for anything but a SEQ), when a segment it reads is
  unlocked but its live range is locked (or the segment is to be
  modified by a later reader), when a physical register it reads keeps
  its producer (test_p1_call_lock), when a conditional trap's
  condition codes' driver cannot move with it (test_p1_trapcc_lock),
  when it leaves an unconsumed result in a locked live range, or when
  it clobbers a locked register.  The condition code chains: the
  segments it writes and reads are compared with last_ip_cc_start and
  last_fp_cc_start, sc_ip_cc_live and sc_fp_cc_live noting that a
  chain is broken.

  0x274FA4, 0x33C bytes, internal: i by value; D0 (D3).  Two passes
  over the operands from the last; the physical inputs test unless the
  operand is a condition code (0x180) or i is call-like (0x5100014). }

function test_p1_lock(
    i: sc_instr_ptr_t): boolean; options(val_param, internal);
var
  locked: boolean;
  k: integer32;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  r: sc_opnd_ptr_t;
  n: integer32;
  ip_read: sc_lts_ptr_t;
  fp_read: sc_lts_ptr_t;
  ip_written: sc_lts_ptr_t;
  fp_written: sc_lts_ptr_t;
begin
  ip_read := nil;
  fp_read := nil;
  ip_written := nil;
  fp_written := nil;
  sc_ip_cc_live := false;
  sc_fp_cc_live := false;
  locked := false;
  if instruction_attributes[i^.opc].class <> class$seq then
    if (sc_final_call <> nil) and (sc_final_call <> i) then
      locked := true;

  { Its results unlocked. }
  for k := i^.h.nopnds downto 1 do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0 then begin
        lts := op^.lts;
        lr := lts^.lr;
        if op^.h.kind = operand$ip_condition_codes then begin
          if ip_written <> nil then
            bug_check('SCHED_$TEST_P1_LOCK: Instruction sets condition code twice%$');
          ip_written := op^.lts;
        end
        else if op^.h.kind = operand$fp_condition_codes then begin
          if fp_written <> nil then
            bug_check('SCHED_$TEST_P1_LOCK: Instruction sets condition code twice%$');
          fp_written := op^.lts;
        end;
        if not op^.lts^.f2.locked then
          bug_check('SCHED_$TEST_P1_LOCK: LTS lock bit was already off%$');
        op^.lts^.f2.locked := false;
        if not lr^.f2.locked then
          bug_check('SCHED_$TEST_P1_LOCK: LR lock bit was already off%$');
        lr^.f2.locked := false;
      end;
  end;

  { Its inputs. }
  for k := i^.h.nopnds downto 1 do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in sc_regs_and_memory then begin
      lts := op^.lts;
      lr := lts^.lr;
      if op^.h.read then begin
        if op^.h.kind = operand$ip_condition_codes then
          ip_read := lts
        else if op^.h.kind = operand$fp_condition_codes then
          fp_read := lts;
        if not lts^.f2.locked then begin
          if lr^.f2.locked then
            locked := true
          else if (rrp$intend_to_modify in lts^.rrp) and
                  not op^.h.intend_to_modify then begin
            r := op^.link;
            while r^.link <> nil do
              r := r^.link;
            if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(r))) <> i then
              locked := true;
          end;
        end;
        if not locked then begin
          if get_phys_lr_num(lr, n) and not (op^.h.kind in sc_ccs) and
             not (instruction_attributes[i^.opc].class in sc_call_like) then
            locked := test_p1_call_lock(op^.lts^.refs)
          else if (op^.h.kind in sc_ccs) and
                  (instruction_attributes[i^.opc].class = class$trap_cond) then
            locked := test_p1_trapcc_lock(i, op);
        end;
      end
      else if op^.h.unconsumed then begin
        if op^.h.kind = operand$ip_condition_codes then
          sc_ip_cc_live := true;
        if op^.h.kind = operand$fp_condition_codes then
          sc_fp_cc_live := true;
        if lr^.f2.locked then
          locked := true;
      end;
    end;
  end;

  if check_clobbered_registers(i) then
    locked := true;
  if not locked then begin
    if (ip_written <> nil) and (ip_written <> sc_ip_cc_start) then
      sc_ip_cc_live := true
    else if (ip_read <> nil) and (ip_written <> nil) then
      sc_ip_cc_start := ip_read;
    if (fp_written <> nil) and (fp_written <> sc_fp_cc_start) then
      sc_fp_cc_live := true
    else if (fp_read <> nil) and (fp_written <> nil) then
      sc_fp_cc_start := fp_read;
  end;
  if ip_read <> nil then
    sc_ip_cc_live := false;
  if fp_read <> nil then
    sc_fp_cc_live := false;
  if locked then
    undo_p1_lock_test(i);
  test_p1_lock := locked;
end;

{ register_pressure - what placing i does to the registers live, as a
  height bonus 0..4 (3 above 4): from 2, each register operand (kinds
  ip_reg .. fp_reg_pair_physical) it reads adds one and each it writes
  takes one off, for the classes that compute (alu, call, the floating
  classes, immediate, fp_control, svc); a load or MFPR 0, a store or
  MTPR 1; the other classes 2.

  0x275382, 0xD8 bytes, internal: i by value; D0.  A jump table of 24
  classes (`cmpi.w #24; bcc' to the end); the 2 is the shifts' count
  register (`moveq #2,D1; lsl.w D1,D0', where the unit's other
  products use `lsl.w #2'), so the base is a constant the compiler
  reused (rev889-patterns 75, 155; docs/questions.md 244).  A load's
  -1 jumps straight to the clamp's 0. }

function register_pressure(
    i: sc_instr_ptr_t): integer32; options(val_param, internal);
var
  p: integer32;
  k: integer32;
begin
  p := 2;
  case ord(instruction_attributes[i^.opc].class) of
    class$alu, class$call, class$fp_double, class$immediate,
    class$fp_control, class$fp_single, class$svc:
      for k := 1 to i^.h.nopnds do
        if i^.opnds[k].h.kind in [operand$ip_reg ..
                                  operand$fp_reg_pair_physical] then
          if i^.opnds[k].h.read then
            p := p + 1
          else
            p := p - 1;
    class$load, class$mfpr:
      p := -1;
    class$store, class$mtpr:
      p := 1;
    otherwise
      ;
  end;
  if p < 0 then
    p := 0
  else if p > 4 then
    p := 3;
  register_pressure := p;
end;

{ remove_lts_from_final_list - lts taken off the block's list of final
  segments.

  0x27545A, 0x42 bytes, internal. }

procedure remove_lts_from_final_list(
    lts: sc_lts_ptr_t); options(val_param, internal);
label
  99;
var
  l: sc_lts_ptr_t;
begin
  l := sc_bb^.finals;
  if l = lts then
    sc_bb^.finals := lts^.next_final
  else
    while l <> nil do begin
      if l^.next_final = lts then begin
        l^.next_final := lts^.next_final;
        goto 99;
      end;
      l := l^.next_final;
    end;
99:
end;

{ PASS1 - the block's instructions taken off it and their precedence
  heights computed, walking back from its end (a list schedule in
  reverse, in quarter cycles).  The labels go on one list
  (sc_out), the closing branches and RETURN on another (sc_branches,
  each pointing to itself at the end), a call marked to end the block
  (its +3 bit 3 or 5: a final call) becomes sc_final_call, which holds
  every other instruction but SEQs locked; the conditional branch's
  condition code segment (sc_branch_cc) is cut from its chain and the
  branch's operand made kind none, its squash mode set to 2 (.SF).
  The branches' inputs and the block's final segments are the roots
  (the branch's condition codes 8 high); every segment gets its lock
  bit while its readers are unscheduled and its definition locked.
  Then, while instructions are active (sc_active: all their readers
  placed), the first one test_p1_lock frees is placed: its height
  gets register_pressure's bonus, the ones found locked before it go
  back with a height just above it, its inputs' segments are raised to
  its height plus their delays (four a cycle) and touched; pass 2's
  enable count is its inputs, those with none made temporarily active,
  then ready (promote_p2_temp_actives).

  0x27549C, 0x642 bytes, internal.  The operand delays first
  (sched_utils_$fill_in_operand_delays(bb, [1], sw9): `move.w
  #2,-(SP)').  The locked instructions wait on a queue in the frame
  (-16, a walker).  The cc-clobbering counts (+0x3104, +0x3100) count
  the instructions placed while a condition code chain is broken. }

procedure pass1; options(internal);
label
  50;
var
  i: sc_instr_ptr_t;
  nxt: sc_instr_ptr_t;
  cls: integer;
  branch: sc_instr_ptr_t;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  k: integer32;
  n: integer32;
  q: sc_walker_t;
  j: sc_instr_ptr_t;
  h: integer32;
begin
  branch := nil;
  sc_touched := nil;
  sc_touched_last := nil;
  sc_temp.head := nil;
  sched_utils_$fill_in_operand_delays(bb_ptr_t(sc_bb), [1],
                                      at_backend_switches.sw9);

  { The block's instructions taken off it. }
  i := sc_bb^.first;
  while i <> nil do begin
    nxt := i^.next;
    cls := ord(instruction_attributes[i^.opc].class);
    if cls = class$label then begin
      if sc_out = nil then
        sc_out := i
      else
        sc_out_last^.next := i;
      sc_out_last := i;
      i := nxt;
      next;
    end;
    if not (cls in [class$branch, class$fp_branch, class$jump,
                    class$return]) then begin
      if cls in [class$branch, class$call, class$fp_branch, class$jump,
                 class$trap, class$svc, class$return] then
        if ((i^.h.width & 16#08) <> 0) or ((i^.h.width & 16#20) <> 0) then begin
          if sc_final_call <> nil then
            bug_check('SCHED_$PASS1: Too many final calls.%$');
          sc_final_call := i;
          sc_p2_final_call := i;
        end;
      i^.next := nil;
      i := nxt;
      next;
    end;

    { A closing branch or RETURN. }
    if cls in [class$jump, class$trap, class$return] then
      if nxt <> nil then
        bug_check('SCHED_$PASS1: Unconditional branch is not last%$');
    if branch <> nil then begin
      if cls = class$return then
        bug_check('SCHED_$PASS1: RETURN instruction after a conditional branch%$');
    end
    else begin
      if cls in [class$branch, class$fp_branch] then begin
        op := addr(i^.opnds[i^.h.nopnds]);
        sc_branch_cc := op^.lts;
        if op^.h.kind = operand$ip_condition_codes then
          sc_ip_cc_start := sc_branch_cc
        else
          sc_fp_cc_start := sc_branch_cc;
        lts := sc_branch_cc;
        if lts^.refs^.h.write or lts^.refs^.h.modify then begin
          if lts^.refs^.link <> op then
            bug_check('SCHED_$PASS1: Improperly formed CC chain%$');
          sc_branch_cc^.refs^.link := nil;
        end
        else begin
          if not lts^.f2.exposed or (lts^.refs <> op) then
            bug_check('SCHED_$PASS1: Improperly formed CC chain%$');
          sc_branch_cc^.refs := nil;
        end;
        lts := sc_branch_cc;
        if lts^.f2.final then
          if sc_bb^.finals = lts then
            sc_bb^.finals := lts^.next_final
          else
            remove_lts_from_final_list(lts);
        op^.link := nil;
      end;
      branch := i;
    end;
    i^.h.modify := 2;
    if cls in [class$branch, class$fp_branch] then
      i^.opnds[i^.h.nopnds].h.kind := operand$none;
    if cls <> class$return then begin
      for k := 1 to i^.h.nopnds do begin
        op := addr(i^.opnds[k]);
        if (op^.h.kind in [operand$ip_reg .. operand$fp_reg_pair_physical]) and
           op^.h.read then begin
          lr := op^.lts^.lr;
          if op^.lts^.f2.final then
            remove_lts_from_final_list(op^.lts);
          if not op^.lts^.f2.setup then begin
            p1_setup_lts(op^.lts);
            if op^.lts^.f2.locked then
              instr_bug_check('SCHED_$PASS1: LTS lock bit was already on - initial jump scan near line %LD%$',
                              i^);
            if lr^.f2.locked then
              instr_bug_check('SCHED_$PASS1: LR lock bit was already on - initial jump scan near line %LD%$',
                              i^);
            op^.lts^.f2.locked := true;
            lr^.f2.locked := true;
          end;
          if op^.lts^.ec = 0 then
            bug_check('SCHED_$PASS1: segment EC about to go negative%$');
          op^.lts^.ec := op^.lts^.ec - 1;
          p1_touch_segment(op^.lts);
        end;
      end;
      if sc_branches = nil then
        sc_branches := i
      else
        sc_branches_last^.next := i;
      sc_branches_last := i;
      i^.next := i;
    end;
    i := nxt;
  end;

  { The roots: the branch's condition codes and the final segments. }
  if sc_branch_cc <> nil then
    if sc_branch_cc^.refs <> nil then begin
      p1_setup_lts(sc_branch_cc);
      sc_branch_cc^.f2.locked := true;
      sc_branch_cc^.lr^.f2.locked := true;
      sc_branch_cc^.w32 := 8;
      sc_branch_cc^.f2.final := true;
      p1_touch_segment(sc_branch_cc);
    end;
  lts := sc_bb^.finals;
  while lts <> nil do begin
    lr := lts^.lr;
    if not lts^.f2.setup then begin
      p1_setup_lts(lts);
      if lts^.f2.locked then begin
        n := lts^.f2.num;
        bug_check('SCHED_$PASS1: LTS lock bit was already on, LTS %3ZWD.%2ZLD, BB %3ZWD - initial scan!!!%.',
                  lr^.num, n, sc_bb_ptr_t(lts^.bb)^.num);
      end;
      if lr^.f2.locked then begin
        n := lts^.f2.num;
        bug_check('SCHED_$PASS1: LR lock bit was already on, LTS %3ZWD.%2ZLD, BB %3ZWD - initial scan!!!%.',
                  lr^.num, n, sc_bb_ptr_t(lts^.bb)^.num);
      end;
      lts^.f2.locked := true;
      lr^.f2.locked := true;
    end;
    lts^.f2.final := true;
    lts^.w32 := 0;
    if lr^.f2.physical and ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) = []) then
      if lr^.f2.reg = 30 then begin
        if sc_ip_cc_start <> nil then
          bug_check('SCHED_$PASS1: last_ip_cc_start already set%$');
        sc_ip_cc_start := lts;
      end
      else if lr^.f2.reg = 31 then begin
        if sc_fp_cc_start <> nil then
          bug_check('SCHED_$PASS1: last_fp_cc_start already set%$');
        sc_fp_cc_start := lts;
      end;
    p1_touch_segment(lts);
    lts := lts^.next_final;
  end;

  { The list schedule, backwards. }
  while sc_active.head <> nil do begin
    walker_initialize(addr(sc_active));
    q.head := nil;
    while sc_active.cur <> nil do begin
      if not test_p1_lock(sc_active.cur) then
        goto 50;
      j := walker_excise_current_item(addr(sc_active));
      enqueue_instruction(addr(q), j, false);
    end;
50:
    if sc_active.cur = nil then
      instr_bug_check('SCHED_$PASS1: Deadlocked: near line %LD%$', q.head^);
    i := walker_excise_current_item(addr(sc_active));
    sc_final_call := nil;
    i^.height := i^.height + register_pressure(i);
    if sc_ip_cc_live then
      sc_ip_cc_clobbers := sc_ip_cc_clobbers + 1;
    if sc_fp_cc_live then
      sc_fp_cc_clobbers := sc_fp_cc_clobbers + 1;
    if q.head <> nil then begin
      walker_initialize(addr(q));
      while q.cur <> nil do begin
        j := walker_excise_current_item(addr(q));
        j^.height := (i^.height & 16#FFFC) + 4;
        enqueue_instruction(addr(sc_active), j, false);
      end;
    end;
    i^.mark := i^.mark ! 3;
    for k := i^.h.nopnds downto 1 do begin
      op := addr(i^.opnds[k]);
      if (op^.h.kind in sc_regs_and_memory) and op^.h.read then begin
        lts := op^.lts;
        if not lts^.f2.setup then begin
          lr := lts^.lr;
          if op^.lts^.f2.locked then
            instr_bug_check('SCHED_$PASS1: LTS lock bit was already on near line %LD%$',
                            i^);
          if lr^.f2.locked then
            instr_bug_check('SCHED_$PASS1: LR lock bit was already on near line %LD%$',
                            i^);
          op^.lts^.f2.locked := true;
          lr^.f2.locked := true;
        end;
        i^.enable := i^.enable + 1;
        if not op^.lts^.f2.setup then
          p1_setup_lts(op^.lts);
        h := (i^.height & 16#FFFC) + op^.h.b2_3_0 * 4;
        if h <= op^.lts^.w32 then
          h := op^.lts^.w32;
        op^.lts^.w32 := h;
        if op^.lts^.ec = 0 then
          bug_check('SCHED_$PASS1: segment EC about to go negative%$');
        op^.lts^.ec := op^.lts^.ec - 1;
        p1_touch_segment(op^.lts);
      end;
    end;
    if i^.enable = 0 then
      p2_temp_act_instr(i);
  end;
  promote_p2_temp_actives;
end;

{ p2_process_lts - lts's value becomes available in pass 2 (its
  definition issued, or an exposed segment at the start): its enable
  count is set to the readers still to issue (one more when it is live
  out of the block), each live reader's own enable count lowered (a
  reader at 0 is made temporarily active); a reader that means to
  modify the value (intend_to_modify, necessarily the last) is enabled
  only when it is the only reader left.  Branches (classes branch,
  fp_branch, jump) are not counted; when nothing but branches reads
  it, its lock bits are released at once.

  0x275E0A, 0x1F6 bytes, internal: lts by value.  The readers'
  instructions computed inline; the last reader's found by walking the
  links.  "LTS doesn't go anywhere" names the last reader examined
  (nothing when there is none: rev889-patterns 142). }

procedure p2_process_lts(
    lts: sc_lts_ptr_t); options(val_param, internal);
var
  nbranches: integer32;
  live_out: boolean;
  op: sc_opnd_ptr_t;
  r: sc_opnd_ptr_t;
  rmw: sc_instr_ptr_t;
  i: sc_instr_ptr_t;
  n: integer32;
begin
  nbranches := 0;
  if lts^.ec <> 0 then
    bug_check('SCHED_$P2_PROCESS_LTS: Segment EC <> 0%.');
  live_out := exit_active(lts);
  op := lts^.refs;
  if not op^.h.read then
    op := op^.link;
  rmw := nil;
  if op <> nil then begin
    r := op;
    while r^.link <> nil do
      r := r^.link;
    if r^.h.intend_to_modify then
      rmw := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
  end;
  while op <> nil do begin
    i := sc_instr_ptr_t(integer32(op) - 32 - op^.h.num * 12);
    if i^.h.b2_6 then begin
      if not op^.h.read then
        instr_bug_check('SCHED_$P2_PROCESS_LTS: Write access is not first: near line %LD%$',
                        i^);
      if op^.h.intend_to_modify then begin
        if (op^.link <> nil) or live_out then
          instr_bug_check('SCHED_$P2_PROCESS_LTS: RI access is not last: near line %LD%$',
                          i^);
        if lts^.ec = 0 then begin
          i^.enable := i^.enable - 1;
          if i^.enable = 0 then
            p2_temp_act_instr(i);
        end;
        lts^.ec := lts^.ec + 1;
      end
      else if instruction_attributes[i^.opc].class in [class$branch,
              class$fp_branch, class$jump] then
        nbranches := nbranches + 1
      else begin
        i^.enable := i^.enable - 1;
        if i^.enable = 0 then
          p2_temp_act_instr(i);
        if i <> rmw then
          lts^.ec := lts^.ec + 1;
      end;
    end;
    op := op^.link;
  end;
  if live_out then
    lts^.ec := lts^.ec + 1;
  if lts^.ec + nbranches = 0 then
    instr_bug_check('SCHED_$P2_PROCESS_LTS: LTS doesn''t go anywhere: near line %LD%$',
                    i^);
  if lts^.ec = 0 then begin
    if not lts^.f2.locked then begin
      n := lts^.f2.num;
      instr_bug_check('SCHED_$P2_PROCESS_LTS: LTS lock bit was already off on branch: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                      i^, lts^.lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
    end;
    if not lts^.lr^.f2.locked then begin
      n := lts^.f2.num;
      instr_bug_check('SCHED_$P2_PROCESS_LTS: LR lock bit was already off on branch: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                      i^, lts^.lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
    end;
    lts^.f2.locked := false;
    lts^.lr^.f2.locked := false;
  end;
end;

{ init_p2_instr_update - i issued in pass 2: each segment it writes
  becomes available (p2_process_lts); for each it reads with one
  reader left, a last reader meaning to modify it is enabled.  The
  enable counts of the segments it reads are raised for the walk and
  lowered again after it.

  0x2761CA, 0x110 bytes, internal: i by value.  Unconsumed operands
  are skipped. }

procedure init_p2_instr_update(
    i: sc_instr_ptr_t); options(val_param, internal);
var
  k: integer32;
  op: sc_opnd_ptr_t;
  r: sc_opnd_ptr_t;
  ri: sc_instr_ptr_t;
begin
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and not op^.h.unconsumed then
      if op^.h.read then begin
        if op^.lts^.ec = 1 then begin
          r := op;
          while r^.link <> nil do
            r := r^.link;
          if r^.h.intend_to_modify then begin
            ri := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
            ri^.enable := ri^.enable - 1;
            if ri^.enable = 0 then
              p2_temp_act_instr(ri);
          end;
        end;
        op^.lts^.ec := op^.lts^.ec + 1;
      end
      else
        p2_process_lts(op^.lts);
  end;
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and not op^.h.unconsumed and
       op^.h.read then
      op^.lts^.ec := op^.lts^.ec - 1;
  end;
end;

{ undo_p2_lock_test - what test_p2_lock did to i's inputs put back: a
  segment whose count it brought to 0 locked again, the count raised
  (not for the reader that modifies it last, which test_p2_lock did not
  count).

  0x2762DA, 0xC6 bytes, internal: i by value. }

procedure undo_p2_lock_test(
    i: sc_instr_ptr_t); options(val_param, internal);
var
  k: integer32;
  op: sc_opnd_ptr_t;
  r: sc_opnd_ptr_t;
  rmw: sc_instr_ptr_t;
begin
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and op^.h.read then begin
      if op^.lts^.ec = 0 then begin
        op^.lts^.f2.locked := true;
        op^.lts^.lr^.f2.locked := true;
      end;
      rmw := nil;
      if not op^.h.intend_to_modify then begin
        r := op;
        while r^.link <> nil do
          r := r^.link;
        if r^.h.intend_to_modify then
          rmw := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
      end;
      if i <> rmw then
        op^.lts^.ec := op^.lts^.ec + 1;
    end;
  end;
end;

{ all_inputs_available - whether the instruction of op (a reader of a
  condition code segment that instr writes; through an IPCCNOP, the
  reader of its operand 2) can follow instr: anything but a
  conditional trap can; a trap only when each register or memory input
  is still locked (its value not yet given up) and not to be modified
  by it unless it is the input's last reader, or is written by instr.

  0x2763A0, 0xD4 bytes, internal: op, instr by value; D0.  The kinds
  0xE7E. }

function all_inputs_available(
    op: sc_opnd_ptr_t;
    instr: sc_instr_ptr_t): boolean; options(val_param, internal);
label
  99;
var
  t: sc_instr_ptr_t;
  k: integer32;
  o: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
begin
  t := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(op)));
  if t^.opc = ord(opc$ipccnop) then
    if t^.opnds[2].link <> nil then
      t := sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(t^.opnds[2].link)));
  all_inputs_available := true;
  if instruction_attributes[t^.opc].class <> class$trap_cond then
    goto 99;
  for k := 1 to t^.h.nopnds do begin
    o := addr(t^.opnds[k]);
    if o^.h.read and
       (o^.h.kind in [operand$ip_reg .. operand$fp_reg_pair_physical,
                      operand$argument_block_memory ..
                      operand$well_behaved_memory]) then begin
      lts := o^.lts;
      if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then
        if sc_instr_ptr_t(utils_ins_$operands_instruction(opnd_ptr_t(lts^.refs))) = instr then
          next;
      if not lts^.f2.locked or
         (o^.h.intend_to_modify and (lts^.ec <> 1)) then begin
        all_inputs_available := false;
        goto 99;
      end;
    end;
  end;
99:
end;

{ test_p2_call_lock - whether the call-like instruction that reads op
  (the one reader of a physical result instr would write) keeps instr
  from issuing in pass 2: when the call has an unavailable input that
  is not a free physical register, when one of its physical inputs is
  still defined by an instruction not issued (other than instr), when
  it reads a value it also means to modify before its last reader,
  when a register it writes is locked and neither one it reads (a
  physical one) nor the live range of an input before it, or when a
  register it clobbers is locked and not one it reads.  The enable
  counts of its inputs, and of the inputs of their unissued
  definitions, are lowered for the test and put back.

  0x276474, 0x5D8 bytes, internal: op, instr by address (frame 8:a,
  12:a); D0 (the frame byte -46).  The physical registers it reads are
  a set of 0..95 (-16, built as test_p1_call_lock's; docs/dpc-gaps.md 29, 38).  The first test
  returns at once (`st D0; bra' to the epilogue). }

function test_p2_call_lock(
    op: sc_opnd_ptr_t;
    instr: sc_instr_ptr_t): boolean; options(val_param, internal);
label
  20, 99;
var
  locked: boolean;
  c: sc_instr_ptr_t;
  regs: sc_regs_t;
  k: integer32;
  j: integer32;
  o: sc_opnd_ptr_t;
  r: sc_opnd_ptr_t;
  d: sc_instr_ptr_t;
  lr: sc_lr_ptr_t;
  n: integer32;
  clob: sc_clob_ptr_t;
  ip_phys: sc_phys_ptr_t;
  fp_phys: sc_phys_ptr_t;
begin
  locked := false;
  if (op = nil) or (op^.link <> nil) then
    bug_check('SCHED_$TEST_P2_CALL_LOCK: Physical output does not go to exactly one destination%$');
  c := sc_instr_ptr_t(integer32(op) - 32 - op^.h.num * 12);
  if not (instruction_attributes[c^.opc].class in sc_call_like) then
    bug_check('SCHED_$TEST_P2_CALL_LOCK: Physical output does not go to a call-type instruction%$');
  regs := [];

  { An unavailable input that is not a free physical register. }
  for k := c^.h.nopnds downto 1 do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then
      if not o^.lts^.f2.locked then begin
        lr := o^.lts^.lr;
        if not get_phys_lr_num(lr, n) or lr^.f2.locked then begin
          test_p2_call_lock := true;
          return;
        end;
      end;
  end;

  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then
      o^.lts^.ec := o^.lts^.ec - 1;
  end;

  { Its physical inputs' definitions. }
  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then begin
      lr := o^.lts^.lr;
      if get_phys_lr_num(lr, n) then begin
        regs := regs + [n];
        if not o^.lts^.f2.locked and not lr^.f2.locked then begin
          r := o^.lts^.refs;
          if r^.h.read then
            bug_check('SCHED_$TEST_P2_CALL_LOCK: Ran off top of basic block with physical register%$');
          d := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
          if d^.next = nil then
            locked := true
          else if d <> instr then
            for j := 1 to d^.h.nopnds do
              if (d^.opnds[j].h.kind in sc_regs_and_memory) and
                 d^.opnds[j].h.read then
                d^.opnds[j].lts^.ec := d^.opnds[j].lts^.ec - 1;
        end;
      end;
    end;
  end;

  { A value it reads and means to modify before its last reader. }
  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then
      if o^.lts^.f2.locked and o^.h.intend_to_modify and (o^.lts^.ec <> 0) then
        locked := true;
  end;

  { The registers it writes. }
  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and not o^.h.read then begin
      lr := o^.lts^.lr;
      if lr^.f2.locked then begin
        if get_phys_lr_num(lr, n) then begin
          if not (n in regs) then
            locked := true;
        end
        else begin
          for j := 1 to k - 1 do begin
            r := addr(c^.opnds[j]);
            if (r^.h.kind in sc_regs_and_memory) and r^.h.read then
              if r^.lts^.lr = lr then
                goto 20;
          end;
          locked := true;
        end;
      end;
20:
    end;
  end;

  { The counts put back. }
  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then
      o^.lts^.ec := o^.lts^.ec + 1;
  end;
  for k := 1 to c^.h.nopnds do begin
    o := addr(c^.opnds[k]);
    if (o^.h.kind in sc_regs_and_memory) and o^.h.read then begin
      lr := o^.lts^.lr;
      if get_phys_lr_num(lr, n) then
        if not o^.lts^.f2.locked and not lr^.f2.locked then begin
          r := o^.lts^.refs;
          d := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
          if d^.next <> nil then
            if d <> instr then
              for j := 1 to d^.h.nopnds do
                if (d^.opnds[j].h.kind in sc_regs_and_memory) and
                   d^.opnds[j].h.read then
                  d^.opnds[j].lts^.ec := d^.opnds[j].lts^.ec + 1;
        end;
    end;
  end;

  { The registers it clobbers. }
  if instruction_attributes[c^.opc].class in sc_calls then begin
    clob := sc_clob_ptr_t(integer32(c) + 44 + 12 * c^.h.nopnds);
    fp_phys := sc_phys_ptr_t(addr(lir_3f90));
    ip_phys := sc_phys_ptr_t(addr(lir_4090));
    for k := 0 to 31 do begin
      if (k in clob^.ip) and (k < 30) then
        if ip_phys^[k]^.f2.locked then
          if not (k in regs) then
            goto 99;
      if k in clob^.fp_lo then
        if fp_phys^[k]^.f2.locked then
          if not (k + 32 in regs) then
            goto 99;
      if k in clob^.fp_hi then
        if fp_phys^[k + 32]^.f2.locked then
          if not (k + 64 in regs) then
            goto 99;
    end;
  end;
  test_p2_call_lock := locked;
  return;
99:
  test_p2_call_lock := true;
end;

{ test_p2_lock - whether i must wait in pass 2.  The segments it reads
  have their enable counts lowered (the last reader that modifies a
  value is not counted), each reaching 0 releasing its lock bits; they
  are put back (undo_p2_lock_test) when it must wait.  It waits when
  it is the final call (sc_p2_final_call), when it writes a
  condition code segment while a chain is broken or before a
  conditional trap reading it can follow (all_inputs_available), when
  it writes a locked live range (one still read by instructions not
  issued), when a physical result's call cannot take it yet
  (test_p2_call_lock), or when it clobbers a locked register.

  0x276B3E, 0x346 bytes, internal: i by value; D0 (D5). }

function test_p2_lock(
    i: sc_instr_ptr_t): boolean; options(val_param, internal);
var
  locked: boolean;
  ip_read: boolean;
  fp_read: boolean;
  k: integer32;
  op: sc_opnd_ptr_t;
  r: sc_opnd_ptr_t;
  rmw: sc_instr_ptr_t;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  n: integer32;
begin
  ip_read := false;
  fp_read := false;
  sc_ip_cc_live := false;
  sc_fp_cc_live := false;
  locked := false;
  if i = sc_p2_final_call then
    locked := true;

  { Its inputs. }
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and op^.h.read then begin
      lts := op^.lts;
      lr := lts^.lr;
      if op^.h.kind = operand$ip_condition_codes then
        ip_read := true
      else if op^.h.kind = operand$fp_condition_codes then
        fp_read := true;
      rmw := nil;
      if not op^.h.intend_to_modify then begin
        r := op^.link;
        if r <> nil then begin
          while r^.link <> nil do
            r := r^.link;
          if r^.h.intend_to_modify then
            rmw := sc_instr_ptr_t(integer32(r) - 32 - r^.h.num * 12);
        end;
      end;
      if rmw <> i then
        op^.lts^.ec := op^.lts^.ec - 1;
      if op^.lts^.ec < 0 then
        bug_check('SCHED_$TEST_P2_LOCK: Segment EC has gone negative - %WD, op %LD%.',
                  i^.num, k);
      lts := op^.lts;
      if lts^.ec = 0 then begin
        if not lts^.f2.locked then begin
          n := lts^.f2.num;
          instr_bug_check('SCHED_$TEST_P2_LOCK: LTS lock bit was already off: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          i^, lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
        end;
        if not lr^.f2.locked then begin
          n := op^.lts^.f2.num;
          instr_bug_check('SCHED_$TEST_P2_LOCK: LR lock bit was already off: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          i^, lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
        end;
        op^.lts^.f2.locked := false;
        lr^.f2.locked := false;
      end;
    end;
  end;

  { Its results. }
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and not op^.h.read then begin
      lts := op^.lts;
      lr := lts^.lr;
      if op^.h.kind = operand$ip_condition_codes then
        if lts = sc_ip_cc_start then begin
          if sc_ip_cc_clobbers <> 0 then
            locked := true;
        end
        else begin
          sc_ip_cc_live := true;
          r := op^.link;
          while r <> nil do begin
            if not all_inputs_available(r, i) then
              locked := true;
            r := r^.link;
          end;
        end;
      if op^.h.kind = operand$fp_condition_codes then
        if op^.lts = sc_fp_cc_start then begin
          if sc_fp_cc_clobbers <> 0 then
            locked := true;
        end
        else begin
          sc_fp_cc_live := true;
          r := op^.link;
          while r <> nil do begin
            if not all_inputs_available(r, i) then
              locked := true;
            r := r^.link;
          end;
        end;
      if lr^.f2.locked then
        locked := true
      else if not op^.h.unconsumed then
        if get_phys_lr_num(lr, n) and not (op^.h.kind in sc_ccs) and
           not (instruction_attributes[i^.opc].class in sc_call_like) then
          if test_p2_call_lock(op^.lts^.refs^.link, i) then
            locked := true;
    end;
  end;

  if check_clobbered_registers(i) then
    locked := true;
  if ip_read then
    sc_ip_cc_live := false;
  if fp_read then
    sc_fp_cc_live := false;
  if locked then
    undo_p2_lock_test(i);
  test_p2_lock := locked;
end;

{ instr_would_stall - whether a register or memory value i reads is
  still in the pipeline: on one of the 16 cycles' lists of values that
  become available (sc_ring).  ENTRYs, SEQs, LIMITs, PMOVEs, labels and
  join birthpoints never stall.

  0x276F90, 0xBE bytes, internal: D0 (the frame byte -18, `st' first).
  The lists are 130 segments each (520 bytes), their counts longwords
  at +0x2080. }

function instr_would_stall(
    i: sc_instr_ptr_t): boolean; options(val_param, internal);
label
  99;
var
  k: integer32;
  op: sc_opnd_ptr_t;
  slot: integer32;
  j: integer32;
begin
  instr_would_stall := true;
  if not (instruction_attributes[i^.opc].class in sc_no_slot) then
    for k := 1 to i^.h.nopnds do begin
      op := addr(i^.opnds[k]);
      if (op^.h.kind in sc_regs_and_memory) and op^.h.read then
        for slot := 0 to 15 do
          for j := 1 to sc_ring_count[slot] do
            if sc_ring[slot][j] = op^.lts then
              goto 99;
    end;
  instr_would_stall := false;
99:
end;

{ can_make_into_rmw_and_combine_lts - whether the live ranges of a (an
  input of an add) and b (its result) can be made one, the add then
  modifying its input in place: both pairs or both not, not even-only
  and odd-only between them (nor their mates); when b's live range is
  complex, a's must be simple and b must not have a later segment in
  its block (kind 1: a's segments join b's live range); when a's is
  complex, a must not be final, to be modified, or have a final
  segment in its block (kind 0: b's join a's).

  0x27704E, 0xE4 bytes, internal: a, b by value, kind by address (a
  word); D0. }

function can_make_into_rmw_and_combine_lts(
    a: sc_lts_ptr_t;
    b: sc_lts_ptr_t;
    out kind: integer): boolean; options(val_param, internal);
var
  lra: sc_lr_ptr_t;
  lrb: sc_lr_ptr_t;
begin
  lra := a^.lr;
  lrb := b^.lr;
  can_make_into_rmw_and_combine_lts := false;
  if (lra^.mate = nil) <> (lrb^.mate = nil) then
    return;
  if ((lra^.rrp + lrb^.rrp) * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only]) =
     [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] then
    return;
  if lra^.mate <> nil then
    if ((lra^.mate^.rrp + lrb^.mate^.rrp) *
        [rrp$fp_reg_even_only, rrp$fp_reg_odd_only]) =
       [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] then
      return;
  if lrb^.id <> 0 then begin
    if lra^.id <> 0 then
      return;
    if b^.next <> nil then
      if b^.bb = b^.next^.bb then
        return;
    kind := 1;
  end
  else begin
    if lra^.id <> 0 then begin
      if a^.f2.final or (lrb^.id <> 0) or
         (rrp$intend_to_modify in a^.rrp) then
        return;
      if utils_$find_final_lts(lr_ptr_t(lra), a^.bb) <> nil then
        return;
    end;
    kind := 0;
  end;
  can_make_into_rmw_and_combine_lts := true;
end;

{ get_operand_p_p - the link (a pointer to the pointer) that leads to
  target in the chain of operands after head (a segment, whose refs,
  or an operand, whose link, is at +4; a definition first is skipped),
  nil when it is not there; tail the last link (nil), ok false when
  another reader in the chain is not yet put back in the block (its
  state bit 1) or means to modify the value.  Each reader must be a
  floating register read.

  0x277132, 0xB8 bytes, internal: head, target by value, tail, ok by
  address; A0. }

function get_operand_p_p(
    head: sc_chain_ptr_t;
    target: sc_opnd_ptr_t;
    out tail: sc_link_ptr_t;
    out ok: boolean): sc_link_ptr_t; options(val_param, internal);
var
  p: sc_link_ptr_t;
  found: sc_link_ptr_t;
begin
  p := addr(head^.first);
  if not p^^.h.read then
    p := addr(p^^.link);
  if p^ = nil then
    bug_check('SCHED_$CAN_BE_5OPIFIED: Anomalous LTS for 5opification%$');
  found := nil;
  ok := true;
  while p^ <> nil do begin
    if not (p^^.h.kind in [operand$fp_reg, operand$fp_reg_pair]) or
       not p^^.h.read then
      bug_check('SCHED_$CAN_BE_5OPIFIED: Anomalous operand for 5opification - 2%$');
    if p^ = target then
      found := p
    else begin
      if (sc_instr_ptr_t(integer32(p^) - 32 - p^^.h.num * 12)^.mark & 2) <> 0 then
        ok := false;
      if p^^.h.intend_to_modify then
        ok := false;
    end;
    p := addr(p^^.link);
  end;
  tail := p;
  get_operand_p_p := found;
end;

{ can_be_5opified - whether a, a floating add, subtract or truncate,
  can be fused with a multiply of opcode mul (MULS with ADDS, SUBS,
  TRUNCSI; MULD with ADDD, SUBD, TRUNCDI) into one five-operand
  instruction (adds5 ...: the multiply's result fed to the add inside
  the floating unit).  An add already modifying its result in place
  (operand 3, and 6 for a double; for a subtract its operand 2 marked
  to be modified, for SUBD 2 and 5) fuses as it is (f.existing_rmw).
  Otherwise one of its inputs (2 then 1; for a double with its other
  half, k + 3) must be a non-final, non-physical value whose other
  readers are not issued and do not modify it and whose live range can
  be made one with the result's (can_make_into_rmw_and_combine_lts):
  f records the input (which), the links to it and its tail (from
  get_operand_p_p), its segments and the combining kind.  A subtract
  tries operand 2 only; a truncate always fuses.

  0x277262, 0x252 bytes, internal: a by address, mul a word (frame 12),
  f by address (14); D0.  The inputs counted down from 2 (`dbf' twice);
  a failed try saves f's links at +12 and +16. }

function can_be_5opified(
    a: sc_instr_ptr_t;
    mul: integer;
    var f: sc_fit_t): boolean; options(val_param, internal);
label
  50, 98, 99;
var
  dbl: boolean;
  bad: boolean;
  k: integer32;
  lts: sc_lts_ptr_t;
  lts2: sc_lts_ptr_t;
  tail: sc_link_ptr_t;
  tail2: sc_link_ptr_t;
  ok: boolean;
  pp: sc_link_ptr_t;
begin
  f.existing_rmw := false;
  case mul of
    181: begin                          { muls }
      dbl := false;
      case a^.opc of
        154:                            { adds }
          if a^.opnds[3].h.modify then begin
            f.existing_rmw := true;
            goto 98;
          end;
        155:                            { subs }
          if a^.opnds[3].h.modify and a^.opnds[2].h.intend_to_modify then begin
            f.existing_rmw := true;
            goto 98;
          end;
        152:                            { truncsi }
          goto 98;
        otherwise
          goto 99;
      end;
    end;
    184: begin                          { muld }
      dbl := true;
      case a^.opc of
        171:                            { addd }
          ;
        172:                            { subd }
          if not a^.opnds[5].h.intend_to_modify or
             not a^.opnds[2].h.intend_to_modify then
            goto 50;
        169:                            { truncdi }
          goto 98;
        otherwise
          goto 99;
      end;
      if a^.opnds[3].h.modify and a^.opnds[6].h.modify then begin
        f.existing_rmw := dbl;
        goto 98;
      end;
    end;
    otherwise
      goto 99;
  end;
50:
  if dbl then
    if a^.opnds[6].lts^.lr^.f2.physical then
      goto 99;
  if a^.opnds[3].lts^.lr^.f2.physical then
    goto 99;
  if not dbl then
    if a^.opnds[3].lts^.lr^.mate <> nil then
      goto 99;
  for k := 2 downto 1 do begin
    bad := false;
    if not (a^.opnds[k].h.kind in [operand$fp_reg, operand$fp_reg_pair]) or
       not a^.opnds[k].h.read then
      bug_check('SCHED_$CAN_BE_5OPIFIED: Anomalous operand for 5opification - 1%$');
    if dbl then
      if not (a^.opnds[k + 3].h.kind in [operand$fp_reg, operand$fp_reg_pair]) or
         not a^.opnds[k + 3].h.read then
        bug_check('SCHED_$CAN_BE_5OPIFIED: Anomalous operand for 5opification - 1%$');
    lts := a^.opnds[k].lts;
    if lts^.f2.final or lts^.lr^.f2.physical then
      bad := true;
    if not dbl then
      lts2 := nil
    else begin
      lts2 := a^.opnds[k + 3].lts;
      if lts2^.f2.final then
        bad := true;
    end;
    if a^.opnds[3].h.unconsumed then
      bad := true;
    if dbl then
      if a^.opnds[6].h.unconsumed then
        bad := true;
    f.opnd_pp := get_operand_p_p(sc_chain_ptr_t(lts),
                                 addr(a^.opnds[k]), tail, ok);
    if not ok then
      bad := true;
    if not dbl then begin
      tail2 := nil;
      f.mate_pp := nil;
    end
    else begin
      f.mate_pp := get_operand_p_p(sc_chain_ptr_t(lts2),
                                   addr(a^.opnds[k + 3]), tail2, ok);
      if not ok then
        bad := true;
    end;
    if not can_make_into_rmw_and_combine_lts(a^.opnds[k].lts,
                                             a^.opnds[3].lts,
                                             f.rmw_kind) then
      bad := true;
    if not bad then begin
      f.tail_pp := tail;
      f.mate_tail_pp := tail2;
      f.which := k;
      f.last_seg := lts;
      f.last_seg_mate := lts2;
      goto 98;
    end;
    if (a^.opc = 172) or (a^.opc = 155) then
      goto 99;
    f.save_pp := f.opnd_pp;
    f.save_mate_pp := f.mate_pp;
  end;
99:
  can_be_5opified := false;
  return;
98:
  can_be_5opified := true;
end;

{ instr_would_fit - whether i fits in the cycle being built (the
  integer slot sc_int_slot and its pair, the floating slot sc_fp_slot
  and its fused add, the IPCCNOP and SEQ slots), with the floating
  registers it reads and writes (fp_registers_busy, its own +41 more
  written) within sched_3158.  A floating operation goes with anything
  but a call in the integer slot, into an empty floating slot or one
  holding a multiply it fuses with (can_be_5opified, either way round;
  not when either sets the floating condition codes); a preference
  move of floating registers that sets no condition codes needs the
  whole cycle, as do calls and floating control instructions; ENTRY,
  LIMIT and SVC need it with no IPCCNOP; an IPCCNOP goes beside
  anything but an unscheduled-class instruction; SEQs and join
  birthpoints always fit.  An integer instruction goes into an empty
  integer slot, or beside a single LOADS or STORES of the same kind of
  memory and the same base: two loads of single literals, or of
  adjacent words of one variable in the stack frame (f.swapped when
  the new one is the lower), with debug switch sw11 set.  With sw14
  nothing shares a cycle.

  0x2774F4, 0x328 bytes, internal: i, f by address; D2.  A jump table
  of 25 classes from 2 (`subq.w #2; cmpi.w #25; bcc'); the literal's
  kind (12, a single) at its +4, a VAR_NAME's (109) at its +2. }

function instr_would_fit(
    i: sc_instr_ptr_t;
    var f: sc_fit_t): boolean; options(val_param, internal);
label
  10, 20, 98, 99;
var
  k: integer32;
  kind: integer;
  d: integer32;
begin
  if (fp_registers_busy[i^.opc * 2] + sc_fp_reads > sched_3158) or
     (fp_registers_busy[i^.opc * 2 + 1] + sc_fp_writes + ord(i^.b41) >
      sched_3158) then
    goto 99;
  if sc_seq_slot <> nil then
    goto 99;
  case ord(instruction_attributes[i^.opc].class) of
    class$fp_double, class$fp_single: begin
      if not i^.h.fp_ccs and i^.h.preference and not i^.h.sets_cc then
        goto 20;
      if sc_int_slot <> nil then
        if instruction_attributes[sc_int_slot^.opc].class = class$call then
          goto 99;
      if at_backend_switches.sw14 then
        if (sc_int_slot <> nil) or (sc_fp_slot <> nil) then
          goto 99;
      if sc_fp_slot = nil then
        goto 98;
      if sc_fp_add <> nil then
        goto 99;
      if sc_fp_slot^.h.fp_ccs or i^.h.fp_ccs then
        goto 99;
      if can_be_5opified(i, sc_fp_slot^.opc, f) then
        goto 98;
      if can_be_5opified(sc_fp_slot, i^.opc, f) then
        goto 98;
      goto 99;
    end;
    class$immediate: begin
      if i^.h.fp_ccs and (sc_int_slot <> nil) then
        if instruction_attributes[sc_int_slot^.opc].class = class$call then
          goto 99;
      if at_backend_switches.sw14 then
        if (sc_int_slot <> nil) or (sc_fp_slot <> nil) then
          goto 99;
      if sc_fp_slot = nil then
        goto 98;
      goto 99;
    end;
    class$entry, class$limit, class$svc: begin
      if (sc_int_slot <> nil) or (sc_fp_slot <> nil) or
         (sc_ipccnop_slot <> nil) then
        goto 99;
      goto 98;
    end;
    class$ipccnop: begin
      if sc_ipccnop_slot <> nil then
        goto 99;
      if sc_int_slot = nil then
        goto 98;
      if instruction_attributes[sc_int_slot^.opc].class in sc_no_slot then
        goto 99;
      goto 98;
    end;
    class$call, class$fp_control:
      goto 20;
    class$seq, class$join_bp:
      goto 98;
    otherwise
      goto 10;
  end;

20:                                     { the whole cycle }
  if (sc_int_slot <> nil) or (sc_fp_slot <> nil) then
    goto 99;
  goto 98;

10:                                     { an integer instruction }
  if at_backend_switches.sw14 then
    if sc_fp_slot <> nil then
      goto 99;
  if sc_int_slot = nil then
    goto 98;
  if sc_int_pair <> nil then
    goto 99;
  if sc_int_slot^.opc <> i^.opc then
    goto 99;
  if (sc_int_slot^.opc <> ord(opc$loads)) and
     (sc_int_slot^.opc <> ord(opc$stores)) then
    goto 99;
  k := 1;
  if sc_int_slot^.opc = ord(opc$stores) then
    k := 2;
  kind := ord(sc_int_slot^.opnds[k].h.kind);
  if ord(i^.opnds[k].h.kind) <> kind then
    goto 99;
  if i^.opnds[k + 1].value <> sc_int_slot^.opnds[k + 1].value then
    goto 99;
  if not at_backend_switches.sw11 then
    goto 99;
  case kind of
    21: begin                           { displacement_literal_pool }
      if (sc_lit_ptr_t(sc_int_slot^.opnds[k].link)^.kind <> 12) or
         (sc_lit_ptr_t(i^.opnds[k].link)^.kind <> 12) then
        goto 99;
      goto 98;
    end;
    20: begin                           { displacement_stack_frame }
      if (il_$node_ptr_t(sc_int_slot^.opnds[k].link)^.kind <> 109) or
         (il_$node_ptr_t(i^.opnds[k].link)^.kind <> 109) or
         (i^.opnds[k].link <> sc_int_slot^.opnds[k].link) then
        goto 99;
      d := i^.opnds[k].value - sc_int_slot^.opnds[k].value;
      if d = 4 then begin
        f.swapped := false;
        goto 98;
      end;
      if d = -4 then begin
        f.swapped := true;
        goto 98;
      end;
      goto 99;
    end;
    otherwise
      goto 99;
  end;
99:
  instr_would_fit := false;
  return;
98:
  instr_would_fit := true;
end;

{ fix_even_odd_property - bits (the even-only and odd-only properties)
  added to lr, its segments and every operand that refers to them.

  0x27781C, 0x32 bytes, internal, no frame: lr, bits a word (`or.w'
  into the live range's and segments' rrp, `or.b' its low byte into
  each operand's +1). }

procedure fix_even_odd_property(
    lr: sc_lr_ptr_t;
    bits: integer); options(val_param, internal);
var
  lts: sc_lts_ptr_t;
  op: sc_opnd_ptr_t;
begin
  sc_rrp_ptr_t(lr)^.w := sc_rrp_ptr_t(lr)^.w ! bits;
  lts := lr^.ltss;
  while lts <> nil do begin
    op := lts^.refs;
    while op <> nil do begin
      opnd_bytes_ptr_t(op)^.rrp := opnd_bytes_ptr_t(op)^.rrp ! bits;
      op := op^.link;
    end;
    sc_rrp_ptr_t(lts)^.w := sc_rrp_ptr_t(lts)^.w ! bits;
    lts := lts^.next;
  end;
end;

{ CANONICALIZE_EXISTING_RMW - an add that already modifies its result
  in place (operand 3; 6 for a double's other half) put in the form the
  five-operand instruction wants: the input it modifies (marked
  intend_to_modify) second (4 and 5 likewise).

  0x27792E, 0x9E bytes, internal. }

procedure canonicalize_existing_rmw(
    i: sc_instr_ptr_t); options(val_param, internal);

  { swap_operands - the contents of operands a and b exchanged, their
    numbers kept, and the segments' reference chains pointed at their
    new places.

    0x27784E, 0xE0 bytes, nested (uses nothing of its parent: called
    without a static link, rev889-patterns 128): a, b by value. }

  procedure swap_operands(
      a: sc_opnd_ptr_t;
      b: sc_opnd_ptr_t); options(val_param);
  var
    t: sc_opnd_t;
    p: sc_opnd_ptr_t;
  begin
    t := a^;
    a^ := b^;
    a^.h.num := t.h.num;
    t.h.num := b^.h.num;
    b^ := t;
    if a^.h.kind in sc_regs_and_memory then
      if a^.lts^.refs = b then
        a^.lts^.refs := a
      else begin
        p := a^.lts^.refs;
        while p^.link <> b do
          p := p^.link;
        p^.link := a;
      end;
    if b^.h.kind in sc_regs_and_memory then
      if b^.lts^.refs = a then
        b^.lts^.refs := b
      else begin
        p := b^.lts^.refs;
        while p^.link <> a do
          p := p^.link;
        p^.link := b;
      end;
  end;

begin
  if not i^.opnds[3].h.modify then
    bug_check('SCHED_$canonicalize_existing_rmw: not a modify access.%.');
  if i^.opnds[1].h.intend_to_modify then
    swap_operands(addr(i^.opnds[1]), addr(i^.opnds[2]))
  else if not i^.opnds[2].h.intend_to_modify then
    bug_check('SCHED_$canonicalize_existing_rmw: can''t find intend access.%.');
  if i^.opnds[1].h.kind in sc_pairs then begin
    if not i^.opnds[6].h.modify then
      bug_check('SCHED_$canonicalize_existing_rmw: not a modify access.%.');
    if i^.opnds[4].h.intend_to_modify then
      swap_operands(addr(i^.opnds[4]), addr(i^.opnds[5]))
    else if not i^.opnds[5].h.intend_to_modify then
      bug_check('SCHED_$canonicalize_existing_rmw: can''t find intend access.%.');
  end;
end;

{ make_into_rmw_and_combine_lts - operand k of i (an input) and k + 1
  (its result) made one read-modify-write: the input marked
  intend_to_modify, the result modify (no longer write), their live
  ranges' even/odd properties merged, and the two live ranges made one
  (kind 0: the result's segments join the input's live range, before
  the input's segment; kind 1: the input's join the result's, after
  its segment), the emptied live range unlocked.  Both must be locked.

  0x277A42, 0x18A bytes, internal: i, k by value, kind a word (frame
  16).  The segments renumbered from the live range's +56 count
  (`addq.w #1,(56,A2); move.b (57,A2),(2,A0)'); rrp$unique_value
  cleared (`andi.w #-4097') and the live range's +3 bit 1. }

procedure make_into_rmw_and_combine_lts(
    i: sc_instr_ptr_t;
    k: integer32;
    kind: integer); options(val_param, internal);
var
  lts_a: sc_lts_ptr_t;
  lts_b: sc_lts_ptr_t;
  lra: sc_lr_ptr_t;
  lrb: sc_lr_ptr_t;
  bits: integer;
  s: sc_lts_ptr_t;
  last: sc_lts_ptr_t;
  p: sc_lts_ptr_t;
begin
  lts_a := i^.opnds[k].lts;
  lts_b := i^.opnds[k + 1].lts;
  lra := lts_a^.lr;
  lrb := lts_b^.lr;
  bits := (sc_rrp_ptr_t(lra)^.w ! sc_rrp_ptr_t(lrb)^.w) & 3;
  if bits <> 0 then begin
    fix_even_odd_property(lra, bits);
    fix_even_odd_property(lrb, bits);
  end;
  i^.opnds[k].h.intend_to_modify := true;
  lts_a^.rrp := lts_a^.rrp + [rrp$intend_to_modify];
  lra^.rrp := lra^.rrp + [rrp$intend_to_modify];
  i^.opnds[k + 1].h.write := false;
  i^.opnds[k + 1].h.modify := true;
  lts_b^.rrp := lts_b^.rrp + [rrp$modify];
  lrb^.rrp := lrb^.rrp + [rrp$modify];
  if not lra^.f2.locked or not lts_a^.f2.locked then
    instr_bug_check('SCHED_$MAKE_RMW: Input LR/LTS is not locked: near line %LD%$',
                    i^);
  if not lrb^.f2.locked or not lts_b^.f2.locked then
    instr_bug_check('SCHED_$MAKE_RMW: Output LR/LTS is not locked: near line %LD%$',
                    i^);
  if kind = 0 then begin
    lra^.rrp := (lra^.rrp + lrb^.rrp) - [rrp$unique_value];
    lra^.f2.b3_1 := false;
    s := lrb^.ltss;
    while s <> nil do begin
      s^.lr := lra;
      lra^.w56 := lra^.w56 + 1;
      s^.f2.num := lra^.w56 & 16#FF;
      last := s;
      s := s^.next;
    end;
    if lra^.ltss = lts_a then begin
      last^.next := lra^.ltss;
      lra^.ltss := lrb^.ltss;
    end
    else begin
      p := lra^.ltss;
      while p^.next <> lts_a do
        p := p^.next;
      last^.next := lts_a;
      p^.next := lrb^.ltss;
    end;
    lrb^.ltss := nil;
    lrb^.f2.locked := false;
  end
  else begin
    lrb^.rrp := (lrb^.rrp + lra^.rrp) - [rrp$unique_value];
    lrb^.f2.b3_1 := false;
    s := lra^.ltss;
    while s <> nil do begin
      s^.lr := lrb;
      lrb^.w56 := lrb^.w56 + 1;
      s^.f2.num := lrb^.w56 & 16#FF;
      last := s;
      s := s^.next;
    end;
    last^.next := lts_b^.next;
    lts_b^.next := lra^.ltss;
    lra^.ltss := nil;
    lra^.f2.locked := false;
  end;
end;

{ fit_instr - i issued into the cycle being built: its results'
  segments and live ranges locked (each must have been unlocked) and
  its inputs' too, the condition code clobber counts brought down,
  pass 2's bookkeeping (init_p2_instr_update) and the cycle's floating
  register traffic counted; then i takes its slot: a call, an ENTRY,
  LIMIT, SVC or floating control instruction both slots (a call adds
  its +41 to the writes), a SEQ or join birthpoint the SEQ slot, an
  IPCCNOP its own; a floating operation the floating slot, or, when
  the slot is taken, it is fused with the multiply there (the multiply
  stays in the slot, the add becomes sc_fp_add and its five-operand
  opcode: ADDS5, SUBS5, TRUNCSI5, ADDD5, SUBD5, TRUNCDI5) and made
  read-modify-write as f says (the multiply's reader moved last in its
  segment's chain, the inputs swapped when it is operand 1, the
  segments combined: make_into_rmw_and_combine_lts); a floating
  preference move that sets no condition codes both slots.  Any other
  instruction takes the integer slot, or pairs with the LOADS or
  STORES there: the two become LOADSE and LOADSO (STORESE, STORESO),
  the lower word's first; two single literals are made one pair
  literal (token_$make_real_lit_pair), whose order decides which is
  lower.

  0x277C46, 0x5A6 bytes, internal: i, f by address (frame 8:l, 12:l).
  `bclr #0,(19,A0)' clears the state bit 0 of i's mark.  A jump table
  of 25 classes from 2.  The opcodes written as numbers (the five
  operand forms 186..191, LOADSE 107, LOADSO 108, STORESE 122,
  STORESO 123).  The pair literal is a 16-byte record from pas_$new
  (`pea 0x10'): kind 12 and the node's +12, +16. }

procedure fit_instr(
    i: sc_instr_ptr_t;
    var f: sc_fit_t); options(val_param, internal);
label
  20, 99;
var
  k: integer32;
  op: sc_opnd_ptr_t;
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  n: integer32;
  a: sc_instr_ptr_t;
  pp: sc_link_ptr_t;
  mpp: sc_link_ptr_t;
  o: sc_opnd_ptr_t;
  t: sc_opnd_t;
  swapped: boolean;
  da: sc_dbl_t;
  db: sc_dbl_t;
  node: il_$node_ptr_t;
  lit: sc_lit_ptr_t;
  s: sc_lit_ptr_t;
begin
  i^.mark := i^.mark & 16#FFFFFFFE;

  { Its results locked. }
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0 then begin
        lts := op^.lts;
        lr := lts^.lr;
        if lts^.f2.locked then begin
          n := lts^.f2.num;
          instr_bug_check('SCHED_$FIT_INSTR: LTS lock bit was already on: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          i^, lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
        end;
        if lr^.f2.locked then begin
          n := op^.lts^.f2.num;
          instr_bug_check('SCHED_$FIT_INSTR: LR lock bit was already on: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          i^, lr^.num, n, sc_bb_ptr_t(i^.bb)^.num, i^.num);
        end;
        op^.lts^.f2.locked := true;
        lr^.f2.locked := true;
      end;
  end;

  { Its inputs locked. }
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and op^.h.read then begin
      op^.lts^.f2.locked := true;
      op^.lts^.lr^.f2.locked := true;
    end;
  end;

  if sc_ip_cc_live then
    sc_ip_cc_clobbers := sc_ip_cc_clobbers - 1;
  if sc_fp_cc_live then
    sc_fp_cc_clobbers := sc_fp_cc_clobbers - 1;
  init_p2_instr_update(i);
  sc_fp_writes := sc_fp_writes + fp_registers_busy[i^.opc * 2 + 1];
  sc_fp_reads := sc_fp_reads + fp_registers_busy[i^.opc * 2];

  case ord(instruction_attributes[i^.opc].class) of
    class$call: begin
      sc_fp_writes := sc_fp_writes + ord(i^.b41);
      goto 20;
    end;
    class$entry, class$limit, class$fp_control, class$svc:
      goto 20;
    class$seq, class$join_bp: begin
      sc_seq_slot := i;
      goto 99;
    end;
    class$ipccnop: begin
      sc_ipccnop_slot := i;
      goto 99;
    end;
    class$fp_double, class$immediate, class$fp_single: begin
      if instruction_attributes[i^.opc].class in [class$fp_double,
                                                  class$fp_single] then
        if not i^.h.fp_ccs and i^.h.preference and not i^.h.sets_cc then
          goto 20;
      if sc_fp_slot = nil then begin
        sc_fp_slot := i;
        goto 99;
      end;

      { The multiply and add fused. }
      if (i^.opc = 181) or (i^.opc = 184) then begin
        sc_fp_add := sc_fp_slot;
        sc_fp_slot := i;
      end
      else
        sc_fp_add := i;
      a := sc_fp_add;
      case a^.opc of
        154: a^.opc := 186;             { adds -> adds5 }
        155: a^.opc := 187;             { subs -> subs5 }
        152: begin                      { truncsi -> truncsi5 }
          a^.opc := 188;
          goto 99;
        end;
        171: a^.opc := 189;             { addd -> addd5 }
        172: a^.opc := 190;             { subd -> subd5 }
        169: begin                      { truncdi -> truncdi5 }
          a^.opc := 191;
          goto 99;
        end;
        otherwise
          instr_bug_check('SCHED_$FIT_INSTR: Losing MUL_ADD conversion: near line %LD%$',
                          i^);
      end;
      if f.existing_rmw then begin
        canonicalize_existing_rmw(sc_fp_add);
        goto 99;
      end;
      pp := f.opnd_pp;
      if pp^ <> addr(sc_fp_add^.opnds[f.which]) then
        instr_bug_check('SCHED_$FIT_INSTR: MUL_ADD conversion failing, seem to have wrong instr: near line %LD%$',
                        i^);
      mpp := f.mate_pp;
      o := pp^;
      if o^.link <> nil then begin
        f.tail_pp^ := o;
        pp^ := o^.link;
        f.tail_pp^^.link := nil;
      end;
      if mpp <> nil then begin
        o := mpp^;
        if o^.link <> nil then begin
          f.mate_tail_pp^ := o;
          mpp^ := o^.link;
          f.mate_tail_pp^^.link := nil;
        end;
      end;
      if f.which = 1 then begin
        o := pp^;
        pp^ := f.save_pp^;
        f.save_pp^ := o;
        t := sc_fp_add^.opnds[2];
        sc_fp_add^.opnds[2] := sc_fp_add^.opnds[1];
        sc_fp_add^.opnds[1] := t;
        sc_fp_add^.opnds[1].h.num := 1;
        sc_fp_add^.opnds[2].h.num := 2;
        if mpp <> nil then begin
          o := mpp^;
          mpp^ := f.save_mate_pp^;
          f.save_mate_pp^ := o;
          t := sc_fp_add^.opnds[5];
          sc_fp_add^.opnds[5] := sc_fp_add^.opnds[4];
          sc_fp_add^.opnds[4] := t;
          sc_fp_add^.opnds[4].h.num := 4;
          sc_fp_add^.opnds[5].h.num := 5;
        end;
      end;
      if f.last_seg <> sc_fp_add^.opnds[2].lts then
        instr_bug_check('SCHED_$FIT_INSTR: Fitter.fivop.last_seg has wrong stuff: near line %LD%$',
                        i^);
      if f.last_seg_mate <> nil then
        if f.last_seg_mate <> sc_fp_add^.opnds[5].lts then
          instr_bug_check('SCHED_$FIT_INSTR: Fitter.fivop.last_seg_mate has wrong stuff: near line %LD%$',
                          i^);
      make_into_rmw_and_combine_lts(sc_fp_add, 2, f.rmw_kind);
      if mpp <> nil then
        make_into_rmw_and_combine_lts(sc_fp_add, 5, f.rmw_kind);
      goto 99;
    end;
    otherwise
      ;
  end;

  { An integer instruction. }
  if sc_int_slot = nil then begin
    sc_int_slot := i;
    goto 99;
  end;
  k := 1;
  if i^.opc = ord(opc$stores) then
    k := 2;
  swapped := f.swapped;
  if i^.opnds[k].h.kind = operand$displacement_literal_pool then begin
    s := sc_lit_ptr_t(i^.opnds[k].link);
    if s^.kind = 12 then begin
      da.l[1] := sc_lit_ptr_t(sc_int_slot^.opnds[k].link)^.l8;
      da.l[2] := sc_lit_ptr_t(sc_int_slot^.opnds[k].link)^.l12;
      db.l[1] := s^.l8;
      db.l[2] := s^.l12;
      node := token_$make_real_lit_pair(da.d, db.d, false, swapped);
      new(lit);
      lit^.kind := 12;
      lit^.l8 := node^.xl[3];
      lit^.l12 := node^.xl[4];
      i^.opnds[k].link := sc_opnd_ptr_t(lit);
      sc_int_slot^.opnds[k].link := sc_opnd_ptr_t(lit);
    end;
  end;
  if swapped then begin
    sc_int_pair := sc_int_slot;
    sc_int_slot := i;
  end
  else
    sc_int_pair := i;
  if sc_int_slot^.opc = ord(opc$loads) then begin
    sc_int_slot^.opc := ord(opc$loadse);
    sc_int_pair^.opc := ord(opc$loadso);
  end
  else if sc_int_slot^.opc = ord(opc$stores) then begin
    sc_int_slot^.opc := ord(opc$storese);
    sc_int_pair^.opc := ord(opc$storeso);
  end;
  goto 99;

20:                                     { the whole cycle }
  sc_int_slot := i;
  sc_fp_slot := i;
99:
end;

{ generate_stall_cycle - a cycle with nothing issued: the clock
  advances and the values due at the new cycle are available (its list
  emptied).

  0x2783D8, 0x1A bytes, internal, no frame (the clock's low word, +0x30FE,
  modulo 16). }

procedure generate_stall_cycle; options(internal);
begin
  sc_clock := sc_clock + 1;
  sc_ring_count[sc_clock & 15] := 0;
end;

{ final_p2_instr_update - i, issued in the cycle just closed, put back
  in the block: the inputs it was the last reader of unlocked, its
  results locked; unless a SEQ or join birthpoint, it is appended to
  the block's new list (the cycle's previous one marked grouped), its
  state cleared, and, unless of a class that takes no slot, the cycle
  counted as used, its stall cycles (the clock less the last cycle's)
  noted in its +2 bits 3..0, and each register result that is read
  entered on the list of the cycle its delay makes it available.

  0x2783F2, 0x1CC bytes, internal.  The ring's slot (delay + clock + 1)
  modulo 16, the list 520 bytes (`lsl.l #3' plus `lsl.l #6' of it). }

procedure final_p2_instr_update(
    i: sc_instr_ptr_t); options(val_param, internal);
var
  k: integer32;
  op: sc_opnd_ptr_t;
  cls: integer;
  slot: integer32;
begin
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and op^.h.read then
      if op^.lts^.ec = 0 then begin
        op^.lts^.f2.locked := false;
        op^.lts^.lr^.f2.locked := false;
      end;
  end;
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if op^.h.kind in sc_regs_and_memory then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#50) = 0 then begin
        op^.lts^.f2.locked := true;
        op^.lts^.lr^.f2.locked := true;
      end;
  end;
  cls := ord(instruction_attributes[i^.opc].class);
  if cls in [class$seq, class$join_bp] then
    return;
  if sc_last_issued <> nil then
    sc_last_issued^.h.grouped := true;
  sc_last_issued := i;
  if sc_out = nil then
    sc_out := i
  else
    sc_out_last^.next := i;
  sc_out_last := i;
  i^.next := i;
  i^.mark := i^.mark & 16#FFFFFFFC;
  if cls in sc_no_slot then
    return;
  sc_cycle_used := true;
  i^.h.stalls := (sc_clock - sc_last_cycle) & 15;
  for k := 1 to i^.h.nopnds do begin
    op := addr(i^.opnds[k]);
    if (op^.h.kind in sc_regs_and_memory) and not op^.h.read and
       (op^.link <> nil) and not (op^.h.kind in sc_memory) then begin
      slot := (op^.h.b2_3_0 + sc_clock + 1) & 15;
      sc_ring[slot][sc_ring_count[slot] + 1] := op^.link^.lts;
      sc_ring_count[slot] := sc_ring_count[slot] + 1;
    end;
  end;
end;

{ PASS2 - the block's instructions issued cycle by cycle from the
  ready queue (by height) and put back in the block in that order.
  The exposed segments pass 1 touched become available first.  Each
  cycle starts with the first instruction select_first_instruction
  gives (stall cycles while it gives none), then takes the floating
  operations that fit, the other instructions that fit, and, when an
  instruction as high as those placed must wait a few cycles while
  nothing else could go, waits for it (stall cycles) and fills the
  cycle around it; the cycle's instructions are then put back
  (final_p2_instr_update, in the order integer slot, pair, IPCCNOP,
  floating slot, fused add, SEQ) and the clock advances when the cycle
  was used.  The closing branches go last, each in a cycle of its own;
  then the block's final segments and the branch's condition codes are
  unlocked.

  0x278900, 0x5A6 bytes, internal.  Three fitter records in the frame
  (-160 for the cycle, -48 for a waiting candidate's test, -96 its
  copy); the candidate's queue position a walker (-112).  A stalled
  start loops back to clearing the slots without testing the queue
  (`bra' to 0x278980: rev889-patterns 158); the fitter records copied
  whole (pattern 157).  The floating pass stops at a fused add or at a
  multiply-class instruction in the floating slot whose attributes' +6
  bit 1 is clear. }

procedure pass2; options(internal);
label
  20, 30, 40, 50;
var
  lts: sc_lts_ptr_t;
  lr: sc_lr_ptr_t;
  k: integer32;
  n: integer32;
  i: sc_instr_ptr_t;
  j: sc_instr_ptr_t;
  h: integer32;
  stall: boolean;
  fit: sc_fit_t;
  fit2: sc_fit_t;
  fitcopy: sc_fit_t;
  cand: sc_walker_t;
  b: sc_instr_ptr_t;
  nb: sc_instr_ptr_t;

  { only_final_call_and_seq - whether nothing but SEQs follows the item
    w is at (the queue's last item is not looked at).

    0x2785BE, 0x48 bytes, nested (called without a static link). }

  function only_final_call_and_seq(
      w: sc_walker_ptr_t): boolean; options(val_param);
  label
    99;
  var
    cur: sc_instr_ptr_t;
    p: sc_instr_ptr_t;
  begin
    cur := w^.cur;
    p := cur^.next;
    if p <> cur then
      repeat
        if instruction_attributes[p^.opc].class <> class$seq then begin
          only_final_call_and_seq := false;
          goto 99;
        end;
        p := p^.next;
      until p^.next = p;
    only_final_call_and_seq := true;
  99:
  end;

  { select_first_instruction - the cycle's first instruction, taken off
    the ready queue into chosen (false), or true when a stall cycle is
    needed.  The final call first when nothing but SEQs follows it; in
    an entry block the ENTRY or LIMIT first (a LIMIT ends that); else a
    call, SEQ, SVC or join birthpoint that can issue (if it would
    stall, a stall cycle).  Otherwise the highest instruction that can
    issue without stalling, preferring a later one of the same quarter
    cycle with a higher fraction (the heights' low two bits, pass 1's
    register pressure bonus), and giving up the search 100 below the
    best height.  Nothing able to issue and nothing even tried is a
    deadlock.

    0x278606, 0x290 bytes, nested (called without a static link):
    chosen by address; D0.  The best and second-best queue positions are
    walkers in the frame (-24, -40); the test `(h & -4) = 3' can never
    hold (`moveq #-4; and.l; cmpi.l #3'), kept (docs/questions.md 245). }

  function select_first_instruction(
      out chosen: sc_instr_ptr_t): boolean; options(val_param);
  label
    10, 20, 30, 90;
  var
    best: sc_walker_t;
    second: sc_walker_t;
    h: integer32;
    hq: integer32;
    tried: boolean;
    locked: boolean;
    opc: integer;
  begin
    walker_initialize(addr(sc_ready));
    best.cur := nil;
    second.cur := nil;
    h := 0;
    tried := false;
    if sc_ready.cur = sc_p2_final_call then
      if only_final_call_and_seq(addr(sc_ready)) then begin
        sc_p2_final_call := nil;
        locked := test_p2_lock(sc_ready.cur);
        sc_p2_final_call := sc_ready.cur;
        if not locked then begin
          if not instr_would_stall(sc_ready.cur) then
            goto 10;
          undo_p2_lock_test(sc_ready.cur);
          tried := true;
        end;
      end;
    if sc_entry_pending then
      while sc_ready.cur <> nil do begin
        opc := sc_ready.cur^.opc;
        if (opc = ord(opc$entry)) or (opc = ord(opc$limit)) then
          if not test_p2_lock(sc_ready.cur) then begin
            if opc = ord(opc$limit) then
              sc_entry_pending := false;
            goto 10;
          end;
        walker_advance_to_next_item(addr(sc_ready));
      end
    else
      while sc_ready.cur <> nil do begin
        if instruction_attributes[sc_ready.cur^.opc].class in
           [class$call, class$seq, class$svc, class$join_bp] then
          if not test_p2_lock(sc_ready.cur) then begin
            if not instr_would_stall(sc_ready.cur) then
              goto 10;
            undo_p2_lock_test(sc_ready.cur);
            goto 90;
          end;
        walker_advance_to_next_item(addr(sc_ready));
      end;

    walker_initialize(addr(sc_ready));
    while sc_ready.cur <> nil do begin
      if ((h & 16#FFFFFFFC) = 3) and (second.cur = nil) then
        goto 20;
      if best.cur <> nil then begin
        if sc_ready.cur^.height + 100 < h then
          goto 20;
        if best.cur <> nil then
          if (sc_ready.cur^.height & 3) <= (h & 3) then
            goto 30;
      end;
      if not test_p2_lock(sc_ready.cur) then begin
        undo_p2_lock_test(sc_ready.cur);
        tried := true;
        if not instr_would_stall(sc_ready.cur) then begin
          if best.cur = nil then begin
            best := sc_ready;
            hq := sc_ready.cur^.height & 16#FFFC;
          end
          else
            second := sc_ready;
          h := sc_ready.cur^.height;
        end;
      end;
  30:
      if best.cur <> nil then
        if (sc_ready.cur^.height & 16#FFFC) >= hq then
          if second.cur <> nil then begin
            best := second;
            second.cur := nil;
            hq := best.cur^.height & 16#FFFC;
          end;
      walker_advance_to_next_item(addr(sc_ready));
    end;
  20:
    if best.cur <> nil then begin
      sc_ready := best;
      if test_p2_lock(sc_ready.cur) then
        bug_check('SCHED_$SELECT_FIRST_INSTRUCTION: Inconsistent instruction lock%$');
      goto 10;
    end;
    if not tried then
      instr_bug_check('SCHED_$PASS2: Deadlocked: near line %LD%$',
                      sc_ready.head^);
  90:
    select_first_instruction := true;
    return;
  10:
    chosen := walker_excise_current_item(addr(sc_ready));
    select_first_instruction := false;
  end;

begin
  sc_entry_pending := sc_bb^.f.entry;
  lts := sc_touched;
  while lts <> nil do begin
    if not lts^.f2.locked then
      bug_check('SCHED_$PASS2: LTS lock bit was already off%$');
    if not lts^.lr^.f2.locked then
      bug_check('SCHED_$PASS2: LR lock bit was already off%$');
    p2_process_lts(lts);
    lts := lts^.touched;
  end;
  promote_p2_temp_actives;
  sc_clock := 1;
  sc_last_cycle := 1;
  for k := 0 to 15 do
    sc_ring_count[k] := 0;

  while sc_ready.head <> nil do begin
    repeat
      sc_int_slot := nil;
      sc_int_pair := nil;
      sc_fp_slot := nil;
      sc_fp_add := nil;
      sc_ipccnop_slot := nil;
      sc_seq_slot := nil;
      sc_fp_writes := 0;
      sc_fp_reads := 0;
      sc_temp.head := nil;
      stall := select_first_instruction(i);
      if stall then
        generate_stall_cycle;
    until not stall;
    fit_instr(i, fit);
    h := i^.height & 16#FFFC;

    { The floating operations that fit. }
    walker_initialize(addr(sc_ready));
    while sc_ready.cur <> nil do begin
      if sc_fp_slot <> nil then begin
        if sc_fp_add <> nil then
          goto 20;
        if not odd(instruction_attributes[sc_fp_slot^.opc].b6_7_1) then
          goto 20;
      end;
      if (instruction_attributes[sc_ready.cur^.opc].class in
          [class$fp_double, class$immediate, class$fp_single]) and
         instr_would_fit(sc_ready.cur, fit) and
         not instr_would_stall(sc_ready.cur) and
         not test_p2_lock(sc_ready.cur) then begin
        j := walker_excise_current_item(addr(sc_ready));
        fit_instr(j, fit);
        if h < (j^.height & 16#FFFC) then
          h := j^.height & 16#FFFC;
      end
      else
        walker_advance_to_next_item(addr(sc_ready));
    end;
20:
    { The other instructions that fit. }
    walker_initialize(addr(sc_ready));
    while sc_ready.cur <> nil do begin
      if (sc_int_slot <> nil) and (sc_ipccnop_slot <> nil) then begin
        if sc_int_pair <> nil then
          goto 30;
        if (sc_int_slot^.opc <> ord(opc$loads)) and
           (sc_int_slot^.opc <> ord(opc$stores)) then
          goto 30;
      end;
      if not (instruction_attributes[sc_ready.cur^.opc].class in
              [class$immediate, class$fp_double, class$fp_single]) and
         instr_would_fit(sc_ready.cur, fit) and
         not instr_would_stall(sc_ready.cur) and
         not test_p2_lock(sc_ready.cur) then begin
        j := walker_excise_current_item(addr(sc_ready));
        fit_instr(j, fit);
        if h < (j^.height & 16#FFFC) then
          h := j^.height & 16#FFFC;
      end
      else
        walker_advance_to_next_item(addr(sc_ready));
    end;
30:
    { An instruction as high that must wait while nothing else can go. }
    walker_initialize(addr(sc_ready));
    cand.cur := nil;
    while sc_ready.cur <> nil do begin
      if (sc_ready.cur^.height & 16#FFFC) < h then
        goto 40;
      if not instr_would_stall(sc_ready.cur) then begin
        if cand.cur <> nil then
          undo_p2_lock_test(cand.cur);
        cand.cur := nil;
        goto 50;
      end;
      if cand.cur = nil then
        if instr_would_fit(sc_ready.cur, fit2) then
          if not test_p2_lock(sc_ready.cur) then begin
            cand := sc_ready;
            fitcopy := fit2;
            h := sc_ready.cur^.height & 16#FFFC;
          end;
      walker_advance_to_next_item(addr(sc_ready));
    end;
40:
    if cand.cur <> nil then begin
      sc_ready := cand;
      while instr_would_stall(sc_ready.cur) do
        generate_stall_cycle;
      i := walker_excise_current_item(addr(sc_ready));
      fit_instr(i, fitcopy);
      while sc_ready.cur <> nil do begin
        if (sc_ready.cur^.height & 16#FFFC) < h then
          goto 50;
        if instr_would_fit(sc_ready.cur, fit2) and
           not instr_would_stall(sc_ready.cur) and
           not test_p2_lock(sc_ready.cur) then begin
          i := walker_excise_current_item(addr(sc_ready));
          fit_instr(i, fit2);
        end
        else
          walker_advance_to_next_item(addr(sc_ready));
      end;
    end;
50:
    { The cycle closed. }
    sc_last_issued := nil;
    sc_cycle_used := false;
    if sc_int_slot <> nil then
      final_p2_instr_update(sc_int_slot);
    if sc_int_pair <> nil then
      final_p2_instr_update(sc_int_pair);
    if sc_ipccnop_slot <> nil then
      final_p2_instr_update(sc_ipccnop_slot);
    if (sc_fp_slot <> nil) and (sc_fp_slot <> sc_int_slot) then
      final_p2_instr_update(sc_fp_slot);
    if sc_fp_add <> nil then
      final_p2_instr_update(sc_fp_add);
    if sc_seq_slot <> nil then
      final_p2_instr_update(sc_seq_slot);
    promote_p2_temp_actives;
    if sc_cycle_used then begin
      sc_clock := sc_clock + 1;
      sc_last_cycle := sc_clock;
      sc_ring_count[sc_clock & 15] := 0;
    end;
  end;

  { The closing branches. }
  b := sc_branches;
  if b <> nil then
    sc_branches_last^.next := nil;
  while b <> nil do begin
    nb := b^.next;
    b^.next := nil;
    sc_last_issued := nil;
    sc_cycle_used := false;
    final_p2_instr_update(b);
    b := nb;
  end;
  sc_bb^.first := sc_out;
  sc_bb^.last := sc_out_last;
  if sc_out <> nil then
    sc_out_last^.next := nil;
  lts := sc_bb^.finals;
  while lts <> nil do begin
    lr := lts^.lr;
    if not lts^.f2.locked then begin
      n := lts^.f2.num;
      instr_bug_check('SCHED_$PASS2: P2 LTS lock bit was already off: near line %LD, LTS %3ZWD.%2ZLD%$',
                      sc_out^, lr^.num, n);
    end;
    lts^.f2.locked := false;
    if not lr^.f2.locked then begin
      n := lts^.f2.num;
      instr_bug_check('SCHED_$PASS2: P2 LR lock bit was already off: near line %LD, LTS %3ZWD.%2ZLD%$',
                      sc_out^, lr^.num, n);
    end;
    lr^.f2.locked := false;
    lts := lts^.next_final;
  end;
  if sc_branch_cc <> nil then begin
    sc_branch_cc^.f2.locked := false;
    sc_branch_cc^.lr^.f2.locked := false;
  end;
end;

{ drop_unneeded_instructions - an atomic block (or one of +17 bit 5)
  is not scheduled: its SEQs and join birthpoints are taken out and
  the prev links and last instruction rebuilt.

  0x278F9C, 0x6E bytes, internal. }

procedure drop_unneeded_instructions; options(internal);
var
  prev: sc_instr_ptr_t;
  i: sc_instr_ptr_t;
begin
  prev := nil;
  i := sc_bb^.first;
  while i <> nil do begin
    if instruction_attributes[i^.opc].class in [class$seq, class$join_bp] then
      if prev = nil then
        sc_bb^.first := i^.next
      else
        prev^.next := i^.next
    else
      prev := i;
    i^.prev := prev;
    i := i^.next;
  end;
  sc_bb^.last := prev;
end;

{ SCHED_$BEGIN_COMPILATION, _END_COMPILATION, _END_ROUTINE - nothing.
  0x27900A, 0x27900C, 0x27900E, 2 bytes each (no A5). }

procedure sched_$begin_compilation;
begin
end;

procedure sched_$end_compilation;
begin
end;

procedure sched_$end_routine;
begin
end;

{ SCHED_$PROCESS_ROUTINE - the SCHED phase (12, before RA): the
  routine checked (lir_utils_$sanity_check), its memory and condition
  code properties collected, every instruction's +28..+31 cleared (the
  blocks in rtn +72's order); unless debug switch sw15 turns the
  phase off, each block in that order is scheduled (pass1, pass2; an
  atomic block or one of +17 bit 5 only loses its SEQs and join
  birthpoints) and its prev links rebuilt.  The routine's marks are
  advanced (to the next multiple of 4, and by 3 after) so that each
  block's first touch of an instruction is told by its mark.

  0x279010, 0x152 bytes: the unit's one routine that loads A5; rtn by
  value (frame 8).  `clr.l (28,A1)' clears the height and enable count
  at once.  The cc-clobbering counts must be 0 after pass 2. }

procedure sched_$process_routine;
var
  bb: sc_bb_ptr_t;
  i: sc_instr_ptr_t;
begin
  sc_rtn := rtn;
  lir_utils_$sanity_check(sc_rtn);
  sched_$collect_memory_and_cc_properties(sc_rtn);
  bb := sc_bb_ptr_t(sc_rtn^.bbs72);
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      i^.height := 0;
      i^.enable := 0;
      i := i^.next;
    end;
    bb := bb^.next114;
  end;
  if at_backend_switches.sw15 then
    return;
  rtn^.marks := (rtn^.marks + 4) & 16#FFFFFFFC;
  sc_marks := rtn^.marks;
  sc_bb := sc_bb_ptr_t(rtn^.bbs72);
  while sc_bb <> nil do begin
    if sc_bb^.f.atomic or sc_bb^.f.b17_5 then
      drop_unneeded_instructions
    else begin
      sc_branches := nil;
      sc_branches_last := nil;
      sc_active.head := nil;
      sc_ready.head := nil;
      sc_out := nil;
      sc_out_last := nil;
      sc_final_call := nil;
      sc_p2_final_call := nil;
      sc_branch_cc := nil;
      sc_ip_cc_start := nil;
      sc_fp_cc_start := nil;
      sc_ip_cc_clobbers := 0;
      sc_fp_cc_clobbers := 0;
      pass1;
      pass2;
      if (sc_ip_cc_clobbers <> 0) or (sc_fp_cc_clobbers <> 0) then
        bug_check('SCHED: cc_clobbering_call_count out of phase%$');
    end;
    fix_instr_prev_ptrs(sc_bb);
    sc_bb := sc_bb^.next114;
  end;
  rtn^.marks := rtn^.marks + 3;
end;
