{ post - the POST phase (cc.a88k only): after register allocation, the
  physical registers written into the operands, then the PRISM's
  pipeline rules met: the IPCCNOP slots after condition code setters
  and the shadows of calls and branches filled with independent
  instructions (stolen from neighbouring blocks, with copies where
  their other predecessors need them), loads that would stall moved
  earlier, LOADSE/LOADSO and STORESE/STORESO pairs combined, conditional
  moves of 0 and 1 made with MFNEXTCC, FPQUIESCEs for FORTRAN's
  floating exceptions, NOPs and SHIFTNOPs against three hardware bugs
  (shift after load, LDCC after a memory access of another size, call
  through a register just used for memory), and the flow graph tidied
  (empty blocks forwarded, loop heads rotated, back edge targets split,
  jumps to the next block dropped, branches reversed).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x2612A4  trace_pass_start (internal)
    --------  0x2612A6  trace_block_entry (internal)
    --------  0x2612A8  trace_instruction (internal)
    --------  0x2612AA  trace_message (internal)
    --------  0x2612AC  trace_block_exit (internal)
    --------  0x2612AE  trace_pass_finish (internal)
    --------  0x2612B0  trace_bit_vectors (internal)
    --------  0x2612B2  bit_vector_test (internal)
    --------  0x2612E8  bit_vector_set (internal)
    --------  0x26132A  bit_vector_clear (internal)
    --------  0x26136E  get_needed_inst (internal)
    --------  0x26138A  get_prev_needed_inst (internal)
    --------  0x2613A6  flush_labels (internal)
    --------  0x2613DE  check_conflicts_for_interaction (internal)
    --------  0x261452  clear_conflicts (internal)
    --------  0x261476  check_register_conflicts (internal)
    --------  0x26170C  pass_bundle (internal)
    --------  0x2617AA  next_bundle (internal)
    --------  0x2617E8  swap_bundles (internal)
    --------  0x26185A  delete_successor_list (internal)
    --------  0x2618BA  rebuild_successor_list (internal)
    --------  0x2618EA  flush_this_block (internal)
    --------  0x261990  droppable_jump_addr (internal)
    --------  0x261A20  interval_of_basic_block (internal)
    --------  0x261A32  interval_of_target_operand (internal)
    --------  0x261A5E  delete_instruction (internal)
    --------  0x261ADE  insert_instruction (internal)
    --------  0x261B6A  instrs_are_identical (internal)
    --------  0x261CAE  post_$initialize (internal)
    --------  0x262554  post_$sprinkle_fpquiesce (internal)
    --------  0x26273A  get_full_conflicts (internal)
    --------  0x26279E  can_steal_bundle_from_bb (internal)
    --------  0x26291E  move_bundle_to_new_bb (internal)
    --------  0x2629D4  copy_instr_to_new_bb (internal)
    --------  0x262AA2  add_exit_active_conflicts (internal)
    --------  0x262B14  get_insertion_point_and_conflicts (internal)
    --------  0x262D0C  need_copy_in_this_bb (internal)
    --------  0x262D96  instr_can_be_moved_along_all_edges (internal)
    --------  0x262E90  ipccnop_with_branches (internal)
    --------  0x2633E6  ipccnop_shuffle_trapcc (internal)
    --------  0x263668  post_$fill_ipccnop (internal)
    --------  0x26385C  block_is_only_const_ip_move (internal)
    --------  0x26392C  fill_er_up (internal)
    --------  0x263994  find_ip_slot_and_insert_instr (internal)
    --------  0x263A7A  post_$sprinkle_mfnextcc (internal)
    --------  0x264114  post_$reschedule_spill_loads (internal)
    --------  0x264684  post_$call_shadows (internal)
    --------  0x264806  post_$branch_shadow_always (internal)
    --------  0x26499E  safe_to_forward_jump_through_ip_reg (internal)
    --------  0x264A3E  post_$forward_empty_block (internal)
    --------  0x264C58  post_$rotate_loop_header (internal)
    --------  0x264D84  post_$split_back_edge_target (internal)
    --------  0x2650CE  post_$branch_shadow_true (internal)
    --------  0x2656B4  post_$sequential_flow (internal)
    --------  0x265D18  post_$new_bb_for_shadow_true (internal)
    --------  0x2660A0  post_$isolate_unneeded (internal)
    --------  0x2661B0  emergency_nop (internal)
    --------  0x266222  get_safe_instr (internal)
    --------  0x26628C  post_$fix_pos_bug (internal)
    --------  0x266508  post_$fix_ldcc_bug (internal)
    --------  0x2667A4  mem_ref_then_call_infected_on_exit (internal)
    --------  0x266862  post_$fix_mem_ref_then_call_bug (internal)
    --------  0x266AE8  post_$begin_compilation
    --------  0x266B34  post_$process_routine
    --------  0x266C3A  post_$end_routine
    --------  0x266C56  post_$end_compilation
    A5 0x48F438: the module's data, 80 bytes (post_heap .. post_minimal
    below, in address order; post_cc_bits initialized from .rwdi).  No
    other unit reaches it (backend.ins.pas's ra_utils_10, once named
    post_6b8, is ra_utils' +0x10).

  The registers as post numbers them (post_$initialize writes the
  number into each register operand's num): integer 0..31, floating
  32..95, the integer and floating condition codes 96 and 97, memory
  98, a pending floating exception 99.  The conflict sets (post_conf_t)
  and the blocks' bit vectors (100 bits: live_gen, transparent,
  live_in/out, avail_*) are of these numbers.  An instruction's +3 bits
  7..6 (h.modify) are a transfer's shadow mode: 0 none (.SN), 1 taken
  only (.ST), 2 still to be filled, 3 always (.SA); an instruction's
  +2 bit 6 (h.b2_6) says it is still in its block (delete_instruction
  clears it), +0 bit 2 (h.grouped) that it is bundled with the next.
  A block's +138 is its first control transfer (post_bb_v_t).

  The trace routines are empty in the image (`rts'); post's calls to
  them are kept.  utils.ins.pas's utils_ins_$operands_instruction is
  not called: the image has no copy (pattern 98); dpc compiles one.

  Not known from the original: every local and parameter name, the
  type and cell names (post_...). }

module post;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/common/source/exs.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { The register numbers post_$initialize writes into the operands (an
    operand's num) and the conflict sets and bit vectors use beyond the
    integer (0..31) and floating (32..95) registers. }
  post_ip_cc = 96;                      { the integer condition codes }
  post_fp_cc = 97;                      { the floating condition codes }
  post_memory = 98;                     { memory }
  post_fp_exc = 99;                     { a floating exception pending
                                          (FORTRAN: an FPQUIESCE needed) }
  post_nregs = 100;

  { Instruction classes as the image's masks group them. }
  post_calls = [class$call, class$svc];                 { 0x100004 }
  post_fp_ops = [class$fp_double, class$immediate,
      class$fp_single];                                 { 0x20108 }
  post_slow = [class$fp_control, class$load_pair, class$load,
      class$mfpr];                                      { 0x419000 }
  post_transfers = [class$branch, class$fp_branch, class$jump,
      class$return];                                    { 0x1000062 }
  post_branches = [class$branch, class$fp_branch, class$jump];  { 98 }
  post_not_stealable = [class$entry, class$seq, class$limit,
      class$pmove, class$label, class$join_bp];         { 0x40C0A10 }
  post_fixed = [class$branch, class$call, class$entry, class$fp_branch,
      class$jump, class$enable, class$seq, class$synch, class$limit,
      class$trap, class$svc, class$store, class$mtpr,
      class$return];                                    { 0x1B04EF6 }
  post_fp_users = [class$fp_double, class$immediate, class$fp_control,
      class$fp_single, class$mfpr];                     { 0x421108 }
  post_no_shuffle = [class$branch, class$call, class$fp_branch,
      class$jump, class$trap, class$svc, class$return]; { 0x1104066 }
  post_mem_ops = [class$load, class$store];             { 0x210000 }
  post_jumps = [class$jump, class$trap, class$return];  { 0x1004040 }
  post_shadow_ok = [class$alu, class$load_pair, class$load,
      class$store];                                     { 0x218001 }
  post_ends = [class$branch, class$call, class$fp_branch, class$jump,
      class$limit, class$trap, class$svc, class$return]; { 0x1104866 }

type
  { A string handed to the trace routines. }
  post_name_t = array [1..80] of char;

  { The registers an instruction (or a bundle) reads and writes, by the
    numbers above: four longwords of 32 each. }
  post_conf_ptr_t = ^post_conf_t;
  post_conf_t = record
    case integer of
      1: (reads: array [0..3] of bv_word_t;     { +0 }
          writes: array [0..3] of bv_word_t);   { +16 }
      2: (all: array [0..7] of bv_word_t);
  end;

  { What a call or svc instruction carries after its operands (at its
    +44 + 12 nopnds): the floating registers 32..63 and 0..31 and the
    integer registers it clobbers. }
  post_clob_ptr_t = ^post_clob_t;
  post_clob_t = record
    fp_hi: bv_word_t;                   { +0 }
    fp_lo: bv_word_t;                   { +4 }
    ip: integer32;                      { +8 }
  end;

  { A block as post uses it: ctl (+138) its first control transfer
    (post_$initialize; bb_t's members in other phases). }
  post_bb_v_ptr_t = ^post_bb_v_t;
  post_bb_v_t = record
    space0: array [0..137] of char;     { +0 }
    ctl: instr_ptr_t;                   { +138 }
  end;

  post_node_ptr_t = ^univ_ptr;

  post_last_def_t = array [0..99] of instr_ptr_t;

var
  { post.pas's data (A5 0x48F438, 80 bytes), in address order. }
  post_heap: mrh_$heap_t;               { +0: the instructions post
                                          copies }
  post_unused_14: integer32;            { +20 }
  post_cc_bits: array [0..6] of integer32 := [-1, 25, 24, 23, 22, 20, 21];
                                        { +24: by a branch opcode's b15
                                          bits 2..0, the condition code
                                          bit an EXTRACTU of MFNEXTCC's
                                          result takes }
  post_ldcc_count: integer32;           { +52: post_$fix_ldcc_bug's fixes }
  post_pos_count: integer32;            { +56: post_$fix_pos_bug's fixes }
  post_level: integer32;                { +60: the debug switches' level }
  post_unused_40: integer32;            { +64 }
  post_rtn: rtn_ptr_t;                  { +68: the routine }
  post_unused_48: integer32;            { +72 }
  post_minimal: boolean;                { +76: the phase's switch sw15:
                                          only the corrections, no
                                          scheduling into shadows }

{ The trace routines (0x2612A4 .. 0x2612B0): each a bare `rts'; the
  calls pass a name and its length, a block, an instruction or a
  message. }

{ trace_pass_start - 0x2612A4, 0x2 bytes. }

procedure trace_pass_start(
    in name: univ post_name_t;
    len: integer); options(val_param, internal);
begin
end;

{ trace_block_entry - 0x2612A6, 0x2 bytes. }

procedure trace_block_entry(
    bb: bb_ptr_t); options(val_param, internal);
begin
end;

{ trace_instruction - 0x2612A8, 0x2 bytes. }

procedure trace_instruction(
    instr: instr_ptr_t); options(val_param, internal);
begin
end;

{ trace_message - 0x2612AA, 0x2 bytes. }

procedure trace_message(
    in msg: univ post_name_t); options(val_param, internal);
begin
end;

{ trace_block_exit - 0x2612AC, 0x2 bytes. }

procedure trace_block_exit; options(internal);
begin
end;

{ trace_pass_finish - 0x2612AE, 0x2 bytes. }

procedure trace_pass_finish; options(internal);
begin
end;

{ trace_bit_vectors - 0x2612B0, 0x2 bytes. }

procedure trace_bit_vectors; options(internal);
begin
end;

{ bit_vector_test - whether bit n of v is set.

  0x2612B2, 0x36 bytes: `lsr.l #5', the word index `lsl.w #2'; the
  range check's carry and `btst' together (`shi'). }

function bit_vector_test(
    v: bv_ptr_t;
    n: integer32): boolean; options(val_param, internal);
begin
  bit_vector_test := (n & 31) in v^[rshft(n, 5)];
end;

{ bit_vector_set - bit n of v set.

  0x2612E8, 0x42 bytes. }

procedure bit_vector_set(
    v: bv_ptr_t;
    n: integer32); options(val_param, internal);
var
  w: integer32;
begin
  w := rshft(n, 5);
  v^[w] := v^[w] + [n & 31];
end;

{ bit_vector_clear - bit n of v cleared.

  0x26132A, 0x44 bytes. }

procedure bit_vector_clear(
    v: bv_ptr_t;
    n: integer32); options(val_param, internal);
var
  w: integer32;
begin
  w := rshft(n, 5);
  v^[w] := v^[w] - [n & 31];
end;

{ get_needed_inst - instr or the first instruction after it still in
  its block (+2 bit 6; delete_instruction clears it).

  0x26136E, 0x1C bytes, no frame. }

function get_needed_inst(
    instr: instr_ptr_t): instr_ptr_t; options(val_param, internal);
label 9;
begin
  while instr <> nil do begin
    if instr^.h.b2_6 then
      goto 9;
    instr := instr^.next;
  end;
9:
  get_needed_inst := instr;
end;

{ get_prev_needed_inst - likewise backward.

  0x26138A, 0x1C bytes, no frame. }

function get_prev_needed_inst(
    instr: instr_ptr_t): instr_ptr_t; options(val_param, internal);
label 9;
begin
  while instr <> nil do begin
    if instr^.h.b2_6 then
      goto 9;
    instr := instr^.prev;
  end;
9:
  get_prev_needed_inst := instr;
end;

{ flush_labels - bb's first instruction still in it that is not a
  label.

  0x2613A6, 0x38 bytes, no frame. }

function flush_labels(
    bb: bb_ptr_t): instr_ptr_t; options(val_param, internal);
label 9;
var
  i: instr_ptr_t;
begin
  i := bb^.first;
  while i <> nil do begin
    if i^.h.b2_6 then
      if instruction_attributes[i^.opc].class <> class$label then
        goto 9;
    i := i^.next;
  end;
9:
  flush_labels := i;
end;

{ check_conflicts_for_interaction - whether what a writes is read or
  written by b, or what b writes is read by a.

  0x2613DE, 0x74 bytes: the two halves each `sne', or-ed. }

function check_conflicts_for_interaction(
    a: post_conf_ptr_t;
    b: post_conf_ptr_t): boolean; options(val_param, internal);
begin
  check_conflicts_for_interaction :=
      (((b^.reads[0] + b^.writes[0]) * a^.writes[0]
        + (b^.reads[1] + b^.writes[1]) * a^.writes[1]
        + (b^.reads[2] + b^.writes[2]) * a^.writes[2]
        + (b^.reads[3] + b^.writes[3]) * a^.writes[3]) <> [])
      or ((b^.writes[0] * a^.reads[0] + b^.writes[1] * a^.reads[1]
           + b^.writes[2] * a^.reads[2]
           + b^.writes[3] * a^.reads[3]) <> []);
end;

{ clear_conflicts - c emptied.

  0x261452, 0x24 bytes: eight longwords (`dbf'). }

procedure clear_conflicts(
    c: post_conf_ptr_t); options(val_param, internal);
var
  k: integer32;
begin
  for k := 0 to 7 do
    c^.all[k] := [];
end;

{ check_register_conflicts - the registers instr reads and writes
  added to a set (mode 2 conf cleared first, 3 added to it as it is),
  or (mode 1) gathered in a set of its own and the answer whether they
  interact with conf's; mode 0 nothing.  A call is taken in two steps:
  first its operands 1..2 (flag set), then (flag set on entry) its
  clobbers and its other operands; an svc the same in one step.  The
  integer registers 30 and 31 a call clobbers are the condition codes
  (96, 97), and a branch reads one of them.

  0x261476, 0x250 bytes: the operands by `dbf' with the high word
  extended (a longword for loop); the interaction inline (one `sne'
  for the whole expression, where check_conflicts_for_interaction has
  two). }

function check_register_conflicts(
    instr: instr_ptr_t;
    mode: integer;
    conf: post_conf_ptr_t;
    var flag: boolean): boolean; options(val_param, internal);
label 9;
var
  res: boolean;
  c: post_conf_ptr_t;
  local: post_conf_t;
  first, last, k: integer32;
  op: opnd_ptr_t;
  clob: post_clob_ptr_t;
  reg, w: integer32;
  cls: integer;
begin
  res := false;
  if mode = 0 then
    goto 9;
  if mode = 1 then
    c := addr(local)
  else
    c := conf;
  if mode <> 3 then
    clear_conflicts(c);
  first := 1;
  last := instr^.h.nopnds;
  if instruction_attributes[instr^.opc].class = class$return then
    last := 2;
  if instruction_attributes[instr^.opc].class <> class$call then
    flag := false;
  cls := instruction_attributes[instr^.opc].class;
  if cls in post_calls then begin
    if flag or (instruction_attributes[instr^.opc].class <> class$call)
    then begin
      clob := post_clob_ptr_t(addr(instr^.opnds[instr^.h.nopnds + 1]));
      c^.writes[0] := c^.writes[0] + bv_word_t(clob^.ip);
      c^.writes[1] := c^.writes[1] + clob^.fp_lo;
      c^.writes[2] := c^.writes[2] + clob^.fp_hi;
      c^.writes[3] := c^.writes[3] + bv_word_t(rshft(clob^.ip, 30));
      if instruction_attributes[instr^.opc].class = class$call then
        first := 3;
      flag := false;
    end
    else begin
      last := 2;
      flag := true;
    end;
  end;
  c^.writes[0] := c^.writes[0] * bv_word_t(16#3FFFFFFF);
  if instruction_attributes[instr^.opc].class = class$branch then
    c^.reads[3] := c^.reads[3] + [0]
  else if instruction_attributes[instr^.opc].class = class$fp_branch then
    c^.reads[3] := c^.reads[3] + [1];
  for k := first to last do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_like,
                      operand$case_jump_base] then begin
      reg := op^.h.num;
      if (reg & 16#80) <> 0 then
        bug_check('POST_$CHECK_REGISTER_CONFLICTS -- illegal physical register number%$');
      w := rshft(reg, 5);
      reg := reg & 31;
      if op^.h.read then
        c^.reads[w] := c^.reads[w] + [reg]
      else if op^.h.write or op^.h.modify then
        c^.writes[w] := c^.writes[w] + [reg];
    end;
  end;
  if mode = 1 then
    res := (local.reads[0] * conf^.writes[0] + local.reads[1] * conf^.writes[1]
            + local.reads[2] * conf^.writes[2]
            + local.reads[3] * conf^.writes[3]
            + (conf^.reads[0] + conf^.writes[0]) * local.writes[0]
            + (conf^.reads[1] + conf^.writes[1]) * local.writes[1]
            + (conf^.reads[2] + conf^.writes[2]) * local.writes[2]
            + (conf^.reads[3] + conf^.writes[3]) * local.writes[3]) <> [];
9:
  check_register_conflicts := res;
end;

{ pass_bundle - the registers of the bundle starting at bundle (an
  instruction and the ones grouped after it) checked against conf
  (check_register_conflicts' modes; a call's second step taken too);
  last its last instruction, bundle the next one still in the block.
  The answer whether any interacted.

  0x26170C, 0x9E bytes. }

function pass_bundle(
    var bundle: instr_ptr_t;
    var last: instr_ptr_t;
    mode: integer;
    conf: post_conf_ptr_t): boolean; options(val_param, internal);
label 1;
var
  res: boolean;
  i: instr_ptr_t;
  m: integer;
  flag, again: boolean;
begin
  res := false;
  i := bundle;
  m := mode;
1:
  if m <> 0 then begin
    flag := false;
    if check_register_conflicts(i, m, conf, flag) then
      res := true;
    again := flag;
    if m = 2 then
      m := 3;
    if again then
      if m <> 1 then
        if check_register_conflicts(i, m, conf, flag) then
          res := true;
  end;
  if i^.h.grouped then begin
    i := get_needed_inst(i^.next);
    goto 1;
  end;
  last := i;
  bundle := get_needed_inst(i^.next);
  pass_bundle := res;
end;

{ next_bundle - pass_bundle without the registers.

  0x2617AA, 0x3E bytes. }

procedure next_bundle(
    var bundle: instr_ptr_t;
    var last: instr_ptr_t); options(val_param, internal);
var
  i: instr_ptr_t;
begin
  i := bundle;
  while i^.h.grouped do
    i := get_needed_inst(i^.next);
  last := i;
  bundle := get_needed_inst(i^.next);
end;

{ swap_bundles - the bundle first..last moved after the bundle that
  follows it (ending at last2) in bb.

  0x2617E8, 0x72 bytes. }

procedure swap_bundles(
    first: instr_ptr_t;
    last: instr_ptr_t;
    last2: instr_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  first2: instr_ptr_t;
begin
  first2 := last^.next;
  if last2^.next = nil then
    bb^.last := last
  else
    last2^.next^.prev := last;
  last^.next := last2^.next;
  if first^.prev = nil then
    bb^.first := first2
  else
    first^.prev^.next := first2;
  first2^.prev := first^.prev;
  last2^.next := first;
  first^.prev := last2;
end;

{ delete_successor_list - bb's edges out taken off their targets' lists
  of edges in (each relinked as the walk goes) and dropped.

  0x26185A, 0x60 bytes: the relinking store's flags tested for the
  loop (pattern 111). }

procedure delete_successor_list(
    bb: bb_ptr_t); options(val_param, internal);
var
  e, p, prev: fg_edge_ptr_t;
  t: bb_ptr_t;
begin
  e := bb^.succs;
  while e <> nil do begin
    t := e^.target;
    prev := nil;
    p := t^.preds;
    while p <> nil do begin
      if p <> e then
        prev := p;
      p := p^.next_pred;
      if prev = nil then
        t^.preds := p
      else
        prev^.next_pred := p;
    end;
    e^.source := nil;
    e := e^.next_succ;
  end;
  bb^.succs := nil;
end;

{ rebuild_successor_list - an edge from bb to each target of the list
  edges.

  0x2618BA, 0x30 bytes. }

procedure rebuild_successor_list(
    bb: bb_ptr_t;
    edges: fg_edge_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
begin
  e := edges;
  while e <> nil do begin
    discard(lir_$add_flow_graph_edge(bb, e^.target));
    e := e^.next_succ;
  end;
end;

{ flush_this_block - bb (which nothing reaches) taken out of rtn's
  blocks and marked forwarded; its edges out dropped.

  0x2618EA, 0x6E bytes: the test of bb's next after the first update is
  that store's flags. }

procedure flush_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
begin
  if bb^.preds <> nil then
    bug_check('FLUSH_THIS_BLOCK -- block has superfluous predecessors%$');
  bb^.f.forwarded := true;
  if bb^.next114 = nil then
    rtn^.bbs := bb^.next
  else
    bb^.next114^.next := bb^.next;
  if bb^.next = nil then
    rtn^.bbs72 := bb^.next114
  else
    bb^.next^.next114 := bb^.next114;
  bb^.next114 := nil;
  bb^.next := nil;
  delete_successor_list(bb);
end;

{ droppable_jump_addr - whether instr (a jump) goes to the block after
  bb.

  0x261990, 0x58 bytes: after the bug check the result is what D0
  holds (pattern 142). }

function droppable_jump_addr(
    instr: instr_ptr_t;
    bb: bb_ptr_t): boolean; options(val_param, internal);
var
  e: fg_edge_ptr_t;
  next, t: bb_ptr_t;
begin
  if instr^.opnds[1].h.kind <> operand$flow_graph_edge then
    droppable_jump_addr := false
  else begin
    e := instr^.opnds[1].ptr;
    next := bb^.next;
    t := e^.target;
    if t^.f.forwarded then
      bug_check('POST: DROPPABLE_JUMP_ADDR -- block is marked forwarded%$')
    else if (next <> nil) and next^.f.forwarded then
      bug_check('POST: DROPPABLE_JUMP_ADDR -- block is marked forwarded%$')
    else
      droppable_jump_addr := next = t;
  end;
end;

{ interval_of_basic_block - the head of bb's interval.

  0x261A20, 0x12 bytes, no frame. }

function interval_of_basic_block(
    bb: bb_ptr_t): bb_ptr_t; options(val_param, internal);
begin
  if not bb^.f.distinguished_entry then
    bb := bb^.l70;
  interval_of_basic_block := bb;
end;

{ interval_of_target_operand - the head of the interval of the block op
  (a flow graph edge) goes to; nil for another operand.

  0x261A32, 0x2C bytes. }

function interval_of_target_operand(
    op: opnd_ptr_t): bb_ptr_t; options(val_param, internal);
begin
  if op^.h.kind <> operand$flow_graph_edge then
    interval_of_target_operand := nil
  else
    interval_of_target_operand :=
        interval_of_basic_block(fg_edge_ptr_t(op^.ptr)^.target);
end;

{ delete_instruction - instr unlinked from bb (the bundle it ended keeps
  instr's grouping) and marked deleted.

  0x261A5E, 0x80 bytes. }

procedure delete_instruction(
    instr: instr_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  p: instr_ptr_t;
begin
  if instr^.prev = nil then
    bb^.first := instr^.next
  else begin
    instr^.prev^.next := instr^.next;
    p := get_prev_needed_inst(instr^.prev);
    if p <> nil then
      if p^.h.grouped then
        p^.h.grouped := instr^.h.grouped;
  end;
  if instr^.next = nil then
    bb^.last := instr^.prev
  else
    instr^.next^.prev := instr^.prev;
  instr^.h.b2_6 := false;
end;

{ insert_instruction - a new instruction of opcode opc in bb, after
  anchor (after) or before it.

  0x261ADE, 0x8C bytes: the result in A0. }

function insert_instruction(
    opc: integer;
    bb: bb_ptr_t;
    anchor: instr_ptr_t;
    after: boolean): instr_ptr_t; options(val_param, internal);
var
  i: instr_ptr_t;
begin
  i := lir_$new_instruction(opc);
  i^.h.b2_6 := true;
  i^.bb := bb;
  if after then begin
    i^.prev := anchor;
    i^.next := anchor^.next;
    anchor^.next := i;
    if i^.next <> nil then
      i^.next^.prev := i
    else
      bb^.last := i;
  end
  else begin
    i^.next := anchor;
    i^.prev := anchor^.prev;
    anchor^.prev := i;
    if i^.prev <> nil then
      i^.prev^.next := i
    else
      bb^.first := i;
  end;
  insert_instruction := i;
end;

{ instrs_are_identical - whether a and b are the same instruction:
  width, operands and opcode, and each operand's rrp, kind, count and
  register, displacement or immediate.

  0x261B6A, 0x144 bytes: the kinds by a jump table of 24 (a literal
  pool displacement compares the first longwords its link points to);
  the width compared signed (`ext.w'). }

function instrs_are_identical(
    a: instr_ptr_t;
    b: instr_ptr_t): boolean; options(val_param, internal);
label 9;
var
  res: boolean;
  k: integer32;
  oa, ob: opnd_ptr_t;
begin
  res := false;
  if a^.h.width <> b^.h.width then
    goto 9;
  if a^.h.nopnds <> b^.h.nopnds then
    goto 9;
  if a^.opc <> b^.opc then
    goto 9;
  for k := 1 to a^.h.nopnds do begin
    oa := addr(a^.opnds[k]);
    ob := addr(b^.opnds[k]);
    if opnd_bytes_ptr_t(oa)^.rrp <> opnd_bytes_ptr_t(ob)^.rrp then
      goto 9;
    if oa^.h.kind <> ob^.h.kind then
      goto 9;
    if oa^.h.count <> ob^.h.count then
      goto 9;
    if oa^.h.kind in [operand$ip_reg..operand$fp_reg_pair_like,
                      operand$case_jump_base] then begin
      if oa^.h.num <> ob^.h.num then
        goto 9;
    end
    else
      case oa^.h.kind of
        operand$none, operand$ip_condition_codes,
        operand$fp_condition_codes:
          ;
        operand$displacement_routine, operand$displacement_arg_block,
        operand$displacement_stack_frame, operand$displacement_XSB_base,
        operand$immediate: begin
          if oa^.link <> ob^.link then
            goto 9;
          if oa^.value <> ob^.value then
            goto 9;
        end;
        operand$displacement_literal_pool: begin
          if post_node_ptr_t(oa^.link)^ <> post_node_ptr_t(ob^.link)^ then
            goto 9;
          if oa^.value <> ob^.value then
            goto 9;
        end;
        otherwise
          goto 9;
      end;
  end;
  res := true;
9:
  instrs_are_identical := res;
end;

{ post_$initialize - the physical registers written into the operands
  (num: integer 0..31, floating 32..95, the condition codes 96 and 97,
  memory 98) and each block's registers read before written
  (live_gen) and not written (transparent) gathered from its end
  backward, then propagated (bv_$propagate_lifetimes with 100 bits);
  a block's first control transfer kept at its +138.  A move from a
  register to itself becomes the opcode after it (opc + 1, its no-op
  form) and is moved after the instruction that last set the register
  (or to the block's head); a LOADSE/LOADSO or STORESE/STORESO pair is
  combined into one LOADD or STORED (not under post_minimal).  With
  avail (FORTRAN), a floating instruction that may raise an exception
  makes register 99 generated in its block, and found is set.

  0x261CAE, 0x6D0 bytes, no A5 (internal): avail a byte at 8, found by
  address at 10; the blocks walked from the routine's last (+72)
  through +114; the last definitions (-408, 100 longwords) set to the
  block's last leading label; the two pairs' messages printed with
  vfmt_$write. }

procedure post_$initialize(
    avail: boolean;
    var found: boolean); options(val_param, internal);
label 2, 4;
var
  bb: bb_ptr_t;
  d1, a0, instr, next, prev, n2: instr_ptr_t;
  last_def: post_last_def_t;
  k, reg: integer32;
  op: opnd_ptr_t;
  lr1, lr2: lr_ptr_t;
  clob: post_clob_ptr_t;
  combined: boolean;
begin
  trace_pass_start('POST_$INITIALIZE', 16);
  found := false;
  bb := post_rtn^.bbs72;
  while bb <> nil do begin
    trace_block_entry(bb);
    post_bb_v_ptr_t(bb)^.ctl := nil;
    d1 := bb^.first;
    if d1 <> nil then
      if instruction_attributes[d1^.opc].class <> class$label then
        d1 := nil
      else begin
4:
        a0 := d1^.next;
        if a0 <> nil then
          if instruction_attributes[a0^.opc].class = class$label then begin
            d1 := a0;
            goto 4;
          end;
      end;
    for k := 0 to 99 do
      last_def[k] := d1;
    instr := bb^.first;
    prev := nil;
    while instr <> nil do begin
      trace_instruction(instr);
      next := instr^.next;
      if not instr^.h.b2_6 then
        bug_check('POST_$INITIALIZE -- deleted instruction found%$');
      instr^.prev := prev;
      if instruction_attributes[instr^.opc].b6_0 then
        if instr^.opnds[1].h.kind in [operand$ip_reg..
                                      operand$fp_reg_pair_physical] then
          if instr^.opnds[1].h.count = 0 then
            if not instr^.h.sets_cc then
              if not instr^.h.fp_ccs then
                if instr^.opnds[1].lts^.lr^.f2.reg
                   = instr^.opnds[2].lts^.lr^.f2.reg then begin
                  instr^.opc := instr^.opc + 1;
                  if instr^.opnds[1].h.kind = instr^.opnds[2].h.kind then
                    if instr^.opnds[1].h.kind in [operand$ip_reg..
                                                  operand$well_behaved_memory]
                    then begin
                      lr1 := instr^.opnds[1].lts^.lr;
                      lr2 := instr^.opnds[2].lts^.lr;
                      if lr1^.node20 = nil then
                        lr1^.node20 := lr2^.node20;
                      if lr2^.node20 = nil then
                        lr2^.node20 := lr1^.node20;
                    end;
                  if prev <> nil then
                    if prev^.h.grouped then
                      prev^.h.grouped := instr^.h.grouped;
                  instr^.h.grouped := false;
                  instr^.h.b2_6 := false;
                  if prev <> nil then
                    prev^.next := next
                  else
                    bb^.first := next;
                  reg := instr^.opnds[1].lts^.lr^.f2.reg;
                  if (reg & 16#C0) <> 0 then
                    bug_check('POST_$INITIALIZE -- illegal physical register number%$');
                  if instr^.opnds[1].h.kind in [operand$fp_reg,
                      operand$fp_reg_pair, operand$fp_reg_like,
                      operand$fp_reg_pair_like] then
                    reg := reg + 32;
                  a0 := last_def[reg];
                  if a0 = nil then begin
                    n2 := bb^.first;
                    instr^.next := n2;
                    if n2 <> nil then
                      n2^.prev := instr;
                    instr^.prev := nil;
                    bb^.first := instr;
                  end
                  else begin
                    while a0^.h.grouped do
                      a0 := a0^.next;
                    n2 := a0^.next;
                    instr^.next := n2;
                    if n2 <> nil then
                      n2^.prev := instr;
                    instr^.prev := a0;
                    a0^.next := instr;
                  end;
                  if a0 = prev then
                    prev := instr;
                end;
      for k := 1 to instr^.h.nopnds do begin
        op := addr(instr^.opnds[k]);
        if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical,
                          operand$ip_reg_like..operand$fp_reg_pair_like,
                          operand$case_jump_base] then begin
          reg := op^.lts^.lr^.f2.reg;
          if (reg & 16#C0) <> 0 then
            bug_check('POST_$INITIALIZE -- illegal physical register number%$');
          if op^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
                            operand$fp_reg_like, operand$fp_reg_pair_like] then
            reg := reg + 32;
          op^.h.num := reg;
          last_def[reg] := instr;
        end
        else if op^.h.kind = operand$ip_condition_codes then
          op^.h.num := post_ip_cc
        else if op^.h.kind = operand$fp_condition_codes then
          op^.h.num := post_fp_cc
        else if op^.h.kind in [operand$argument_block_memory..
                               operand$well_behaved_memory] then
          op^.h.num := post_memory;
        if op^.h.kind in [operand$ip_reg..operand$fp_reg_pair_like,
                          operand$case_jump_base] then
          if not ((op^.h.num = 31) or (op^.h.num = 30)) then
            if op^.h.read or op^.h.intend_to_modify then begin
              if bit_vector_test(bb^.transparent, op^.h.num) then
                bit_vector_set(bb^.live_gen, op^.h.num);
            end
            else if op^.h.write or op^.h.modify then
              bit_vector_clear(bb^.transparent, op^.h.num);
      end;
      if instruction_attributes[instr^.opc].class = class$branch then
        if bit_vector_test(bb^.transparent, post_ip_cc) then
          bit_vector_set(bb^.live_gen, post_ip_cc);
      if instruction_attributes[instr^.opc].class = class$fp_branch then
        if bit_vector_test(bb^.transparent, post_fp_cc) then
          bit_vector_set(bb^.live_gen, post_fp_cc);
      if instruction_attributes[instr^.opc].class in post_calls then begin
        clob := post_clob_ptr_t(addr(instr^.opnds[instr^.h.nopnds + 1]));
        bb^.transparent^[0] := bb^.transparent^[0] - bv_word_t(clob^.ip);
        bb^.transparent^[1] := bb^.transparent^[1] - clob^.fp_lo;
        bb^.transparent^[2] := bb^.transparent^[2] - clob^.fp_hi;
      end;
      if post_bb_v_ptr_t(bb)^.ctl = nil then
        if instruction_attributes[instr^.opc].class in post_transfers then
          post_bb_v_ptr_t(bb)^.ctl := instr;
      if not instr^.h.b2_6 then begin
        instr := next;
        goto 2;
      end;
      combined := false;
      if not post_minimal then
        case instr^.opc of
          ord(opc$loadse): begin
            trace_message('Combining LOADSE/O pair into LOADD');
            if not (instr^.h.grouped and (instr^.next <> nil)) then
              bug_check('POST_$INITIALIZE -- loadse not part of pair%$')
            else if instr^.next^.opc <> ord(opc$loadso) then
              bug_check('POST_$INITIALIZE -- loadse not part of pair%$');
            if instr^.opnds[3].h.kind <> operand$fp_reg then
              bug_check('POST_$INITIALIZE -- bad operand kind in loadse/so%$');
            if instr^.opnds[3].h.num + 1 <> instr^.next^.opnds[3].h.num then
              vfmt_$write('**** Bad register pairing in loadse/so%.');
            instr^.opc := ord(opc$loadd);
            combined := true;
          end;
          ord(opc$storese): begin
            trace_message('Combining STORESE/O pair into STORED');
            if not (instr^.h.grouped and (instr^.next <> nil)) then
              bug_check('POST_$INITIALIZE -- storese not part of pair%$')
            else if instr^.next^.opc <> ord(opc$storeso) then
              bug_check('POST_$INITIALIZE -- storese not part of pair%$');
            if instr^.opnds[1].h.kind <> operand$fp_reg then
              bug_check('POST_$INITIALIZE -- bad operand kind in storese/so%$');
            if instr^.opnds[1].h.num + 1 <> instr^.next^.opnds[1].h.num then
              vfmt_$write('**** Bad register pairing in storese/so%.');
            instr^.opc := ord(opc$stored);
            combined := true;
          end;
          otherwise
            ;
        end;
      if combined then begin
        instr^.h.grouped := instr^.next^.h.grouped;
        instr^.next^.h.grouped := false;
        instr^.next^.h.b2_6 := false;
      end;
      if avail then
        if instr^.h.may_generate_an_exception then
          if instruction_attributes[instr^.opc].class in post_fp_ops then
          begin
            bit_vector_set(bb^.avail_gen, post_fp_exc);
            bit_vector_set(bb^.live_gen, post_fp_exc);
            found := true;
          end;
      prev := instr;
      instr := next;
2:
    end;
    bb^.last := prev;
    if prev <> nil then
      prev^.next := nil;
    trace_block_exit;
    bb := bb^.next114;
  end;
  bv_$propagate_lifetimes(post_nregs, post_rtn);
  trace_bit_vectors;
  trace_pass_finish;
end;

{ post_$sprinkle_fpquiesce - (FORTRAN) an FPQUIESCE put at the end of
  each block (before its first control transfer) where a floating
  exception may still be pending and the block does not settle it: the
  exception is settled by a RETURN block and on a flow to another
  exception frame that handles predefined exceptions (or that is not
  nested in the block's frame); availability then propagated with 100
  bits.

  0x262554, 0x18E bytes, no A5 (internal): the block's number by
  address to the bug check; the FPQUIESCE's anchor not set on that
  path. }

procedure post_$sprinkle_fpquiesce; options(internal);
label 1;
var
  bb: bb_ptr_t;
  e: fg_edge_ptr_t;
  t: boolean;
  anchor: instr_ptr_t;
  after: boolean;
begin
  trace_pass_start('POST_$SPRINKLE_FPQUIESCE', 24);
  bb := post_rtn^.bbs72;
  while bb <> nil do begin
    if bb^.f14.kind = ord(block$return) then
      bit_vector_clear(bb^.transparent, post_fp_exc)
    else begin
      e := bb^.succs;
      while e <> nil do begin
        if bb^.l42 <> e^.target^.l42 then
          if exs_$frame_has_handler_for_predefined_exception(
                 univ_ptr(bb^.l42), 1)
             or (exs_$frame_has_handler_for_predefined_exception(
                     univ_ptr(e^.target^.l42), 1)
                 and not exs_$frame_is_lexically_nested(
                     univ_ptr(e^.target^.l42), univ_ptr(bb^.l42))) then
          begin
            bit_vector_clear(bb^.transparent, post_fp_exc);
            bit_vector_clear(bb^.avail_gen, post_fp_exc);
            goto 1;
          end;
        e := e^.next_succ;
      end;
    end;
1:
    bb := bb^.next114;
  end;
  bv_$propagate_availability(post_nregs, post_rtn, true);
  bb := post_rtn^.bbs72;
  while bb <> nil do begin
    t := bit_vector_test(bb^.live_gen, post_fp_exc);
    t := t or bit_vector_test(bb^.avail_in, post_fp_exc);
    if t and not bit_vector_test(bb^.transparent, post_fp_exc) then begin
      if post_bb_v_ptr_t(bb)^.ctl <> nil then begin
        anchor := post_bb_v_ptr_t(bb)^.ctl;
        after := false;
      end
      else if bb^.last <> nil then begin
        anchor := bb^.last;
        after := true;
      end
      else
        bug_check('POST_$SPRINKLE_FPQUIESCE -- can''t find last instr in BB#%3ZWD%$',
                  bb^.num);
      discard(insert_instruction(ord(opc$fpquiesce), bb, anchor, after));
    end;
    bb := bb^.next114;
  end;
  trace_pass_finish;
end;

{ get_full_conflicts - check_register_conflicts of instr, a call's
  second step too.

  0x26273A, 0x64 bytes. }

function get_full_conflicts(
    instr: instr_ptr_t;
    mode: integer;
    conf: post_conf_ptr_t): boolean; options(val_param, internal);
var
  res, flag: boolean;
begin
  flag := false;
  res := check_register_conflicts(instr, mode, conf, flag);
  if flag then
    if not (res and (mode = 1)) then begin
      if mode = 2 then
        mode := 3;
      res := res or check_register_conflicts(instr, mode, conf, flag);
    end;
  get_full_conflicts := res;
end;

{ can_steal_bundle_from_bb - the first bundle of bb (past its labels,
  entries, pmoves and join birthpoints) when it may be moved out of the
  block: bb not atomic, with at most maxpreds edges in (0 any), an
  instruction that is not fixed (a transfer, call, store, ...), that
  may raise an exception only with may_trap, of the kind mode asks
  (1, 2: not a floating or slow instruction, a grouped one only before
  an IPCCNOP, for 2 one that sets the condition codes; 3: a floating
  one, or an IPCCNOP before one), not a load setting the condition
  codes, and whose registers do not interact with conf.  nil when
  not.

  0x26279E, 0x180 bytes: mode by a jump table of 4. }

function can_steal_bundle_from_bb(
    bb: bb_ptr_t;
    mode: integer;
    conf: post_conf_ptr_t;
    maxpreds: integer32;
    may_trap: boolean): instr_ptr_t; options(val_param, internal);
label 1, 3, 9;
var
  res, i, a0: instr_ptr_t;
  n: integer32;
  e: fg_edge_ptr_t;
begin
  res := nil;
  if bb^.f.atomic then
    goto 9;
  n := 0;
  e := bb^.preds;
  while e <> nil do begin
    n := n + 1;
    e := e^.next_pred;
  end;
  if maxpreds <> 0 then
    if n > maxpreds then
      goto 9;
  i := flush_labels(bb);
  while i <> nil do begin
    if not (instruction_attributes[i^.opc].class in post_not_stealable) then
      goto 1;
    i := get_needed_inst(i^.next);
  end;
1:
  if i = nil then
    goto 9;
  if instruction_attributes[i^.opc].class in post_fixed then
    goto 9;
  if not may_trap then
    if i^.h.may_generate_an_exception then
      goto 9;
  case mode of
    1, 2: begin
      if instruction_attributes[i^.opc].class in post_fp_users then
        goto 9;
      if i^.h.grouped then begin
        a0 := i^.next;
        if a0^.h.grouped then
          goto 9;
        if a0^.opc <> ord(opc$ipccnop) then
          goto 9;
      end;
      if mode = 2 then
        if not i^.h.sets_cc then
          goto 9;
    end;
    3: begin
      if (i^.opc = ord(opc$ipccnop)) and i^.h.grouped then
        a0 := i^.next
      else
        a0 := i;
      if not (instruction_attributes[a0^.opc].class in post_fp_ops) then
        goto 9;
    end;
    otherwise
      ;
  end;
  if i^.h.sets_cc then
    if instruction_attributes[i^.opc].class = class$load then
      goto 9;
  if not get_full_conflicts(i, 1, conf) then
    res := i;
9:
  can_steal_bundle_from_bb := res;
end;

{ move_bundle_to_new_bb - the bundle starting at first unlinked from bb
  and put after anchor (after) or before it in newbb (the bundle's
  instructions keep their block).

  0x26291E, 0xB6 bytes: the test after the first update is that
  store's flags. }

procedure move_bundle_to_new_bb(
    bb: bb_ptr_t;
    first: instr_ptr_t;
    newbb: bb_ptr_t;
    anchor: instr_ptr_t;
    after: boolean); options(val_param, internal);
var
  last: instr_ptr_t;
begin
  last := first;
  while last^.h.grouped do
    last := last^.next;
  if first^.prev = nil then
    bb^.first := last^.next
  else
    first^.prev^.next := last^.next;
  if last^.next = nil then
    bb^.last := first^.prev
  else
    last^.next^.prev := first^.prev;
  if after then begin
    last^.next := anchor^.next;
    anchor^.next := first;
    first^.prev := anchor;
    if last^.next = nil then
      newbb^.last := last
    else
      last^.next^.prev := last;
  end
  else begin
    first^.prev := anchor^.prev;
    anchor^.prev := last;
    last^.next := anchor;
    if first^.prev = nil then
      newbb^.first := first
    else
      first^.prev^.next := first;
  end;
end;

{ copy_instr_to_new_bb - a copy of instr (from post's heap) put after
  anchor (after) or before it in bb; a load's or store's copy loses
  its +2 bit 7.

  0x2629D4, 0xCE bytes: the size (nopnds + 1) * 12 in word arithmetic
  plus 32; the copy a longword at a time. }

function copy_instr_to_new_bb(
    instr: instr_ptr_t;
    bb: bb_ptr_t;
    anchor: instr_ptr_t;
    after: boolean): instr_ptr_t; options(val_param, internal);
type
  longs_t = array [1..1024] of integer32;
var
  size: integer32;
  k: integer32;
  new: instr_ptr_t;
  src, dst: ^longs_t;
begin
  size := ((instr^.h.nopnds + 1) * 12) + 32;
  new := mrh_$alloc(post_heap, size);
  dst := univ_ptr(new);
  src := univ_ptr(instr);
  for k := 1 to size div 4 do
    dst^[k] := src^[k];
  if instruction_attributes[new^.opc].class in post_mem_ops then
    new^.h.b2_7 := false;
  if after then begin
    new^.next := anchor^.next;
    if new^.next = nil then
      bb^.last := new
    else
      new^.next^.prev := new;
    anchor^.next := new;
    new^.prev := anchor;
  end
  else begin
    new^.prev := anchor^.prev;
    if new^.prev = nil then
      bb^.first := new
    else
      new^.prev^.next := new;
    new^.next := anchor;
    anchor^.prev := new;
  end;
  copy_instr_to_new_bb := new;
end;

{ add_exit_active_conflicts - dst made src (when they differ) with the
  registers live into bb's successors but skip added to its reads.

  0x262AA2, 0x72 bytes: the copy eight `move.l'. }

procedure add_exit_active_conflicts(
    skip: bb_ptr_t;
    bb: bb_ptr_t;
    dst: post_conf_ptr_t;
    src: post_conf_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
  v: bv_ptr_t;
begin
  if dst <> src then
    dst^ := src^;
  e := bb^.succs;
  while e <> nil do begin
    if e^.target <> skip then begin
      v := e^.target^.live_in;
      dst^.reads[0] := dst^.reads[0] + v^[0];
      dst^.reads[1] := dst^.reads[1] + v^[1];
      dst^.reads[2] := dst^.reads[2] + v^[2];
      dst^.reads[3] := dst^.reads[3] + v^[3];
    end;
    e := e^.next_succ;
  end;
end;

{ get_insertion_point_and_conflicts - where an instruction may be put
  at the end of bb (before its control transfers, and before the
  floating instruction or IPCCNOP bundle that precedes them; nil when
  the instruction before is itself a branch) in ins; conf the
  registers of the transfers (and of that bundle; the condition codes:
  96 when more than one branch, 97 with a floating branch), with the
  registers live into bb's successors but skip, and the writes of the
  slow instruction before; count the branches.

  0x262B14, 0x1F8 bytes. }

procedure get_insertion_point_and_conflicts(
    skip: bb_ptr_t;
    bb: bb_ptr_t;
    var ins: instr_ptr_t;
    conf: post_conf_ptr_t;
    var count: integer32); options(val_param, internal);
label 1, 2;
var
  nfp, nip: integer32;
  flag: boolean;
  i, p, a0, last: instr_ptr_t;
  local: post_conf_t;
begin
  clear_conflicts(conf);
  nfp := 0;
  nip := 0;
  flag := false;
  i := post_bb_v_ptr_t(bb)^.ctl;
  while i <> nil do begin
    if instruction_attributes[i^.opc].class = class$branch then
      nip := nip + 1
    else if instruction_attributes[i^.opc].class = class$fp_branch then
      nfp := nfp + 1;
    discard(check_register_conflicts(i, 3, conf, flag));
    i := i^.next;
  end;
  count := nfp + nip;
  if nfp <> 0 then
    conf^.reads[3] := conf^.reads[3] + [1];
  if nip > 1 then
    conf^.reads[3] := conf^.reads[3] + [0]
  else
    conf^.reads[3] := conf^.reads[3] - [0];
  p := post_bb_v_ptr_t(bb)^.ctl;
  if p <> nil then begin
    i := p^.prev;
    if i <> nil then begin
      while i^.prev <> nil do begin
        if not i^.prev^.h.grouped then
          goto 1;
        i := i^.prev;
      end;
1:
      if (i^.opc = ord(opc$ipccnop))
         or (instruction_attributes[i^.opc].class in post_fp_ops) then begin
        p := i;
        a0 := i;
        discard(pass_bundle(a0, last, 3, conf));
        conf^.reads[3] := conf^.reads[3] - [0];
        conf^.writes[3] := conf^.writes[3] - [0];
      end;
    end;
  end;
  if p <> nil then
    ins := p
  else
    ins := bb^.first;
  if skip <> nil then
    add_exit_active_conflicts(skip, bb, conf, conf);
  if p <> nil then begin
    p := get_prev_needed_inst(p^.prev);
    if p <> nil then begin
2:
      a0 := get_prev_needed_inst(p^.prev);
      if a0 <> nil then
        if a0^.h.grouped then begin
          p := a0;
          goto 2;
        end;
      if p <> nil then
        if instruction_attributes[p^.opc].class in post_slow then begin
          discard(get_full_conflicts(p, 2, addr(local)));
          conf^.writes[0] := conf^.writes[0] + local.writes[0];
          conf^.writes[1] := conf^.writes[1] + local.writes[1];
          conf^.writes[2] := conf^.writes[2] + local.writes[2];
          conf^.writes[3] := conf^.writes[3] + local.writes[3];
        end
        else if instruction_attributes[p^.opc].class in post_branches then
          ins := nil;
    end;
  end;
end;

{ need_copy_in_this_bb - whether an instruction with the registers conf
  moved out of from needs a copy in bb: not when from is bb's only
  predecessor and nothing bb writes, or that is live past it (but into
  skip), interacts with conf.

  0x262D0C, 0x8A bytes: the local set's reads cleared, its writes the
  complement of bb's transparent registers; add_exit_active_conflicts'
  two set arguments one push (`move.l (SP),-(SP)'). }

function need_copy_in_this_bb(
    skip: bb_ptr_t;
    bb: bb_ptr_t;
    from: bb_ptr_t;
    conf: post_conf_ptr_t): boolean; options(val_param, internal);
var
  res: boolean;
  local: post_conf_t;
  e: fg_edge_ptr_t;
begin
  res := true;
  e := bb^.preds;
  if e <> nil then
    if e^.next_pred = nil then
      if e^.source = from then begin
        local.reads[0] := [];
        local.reads[1] := [];
        local.reads[2] := [];
        local.reads[3] := [];
        local.writes[0] := [0..31] - bb^.transparent^[0];
        local.writes[1] := [0..31] - bb^.transparent^[1];
        local.writes[2] := [0..31] - bb^.transparent^[2];
        local.writes[3] := [0..31] - bb^.transparent^[3];
        add_exit_active_conflicts(skip, bb, addr(local), addr(local));
        res := check_conflicts_for_interaction(addr(local), conf);
      end;
  need_copy_in_this_bb := res;
end;

{ instr_can_be_moved_along_all_edges - whether the bundle at instr may
  be moved out of bb into from: each other predecessor that would need
  a copy has room for it (an insertion point, no interaction) and is
  not shallower in loops than bb unless the copy goes before a
  floating instruction or IPCCNOP, nor (copied before an IPCCNOP) deeper
  than from.

  0x262D96, 0xFA bytes: the depths compared unsigned. }

function instr_can_be_moved_along_all_edges(
    instr: instr_ptr_t;
    bb: bb_ptr_t;
    from: bb_ptr_t): boolean; options(val_param, internal);
label 8, 9;
var
  res: boolean;
  b, last, ins: instr_ptr_t;
  conf, conf2: post_conf_t;
  e: fg_edge_ptr_t;
  count: integer32;
  src: bb_ptr_t;
begin
  b := instr;
  discard(pass_bundle(b, last, 2, addr(conf)));
  e := bb^.preds;
  while e <> nil do begin
    if e^.source <> from then
      if need_copy_in_this_bb(bb, e^.source, from, addr(conf)) then begin
        get_insertion_point_and_conflicts(bb, e^.source, ins, addr(conf2),
                                          count);
        if ins = nil then
          goto 8;
        if check_conflicts_for_interaction(addr(conf), addr(conf2)) then
          goto 8;
        src := e^.source;
        if not (src^.f.depth < bb^.f.depth) then
          if ins^.opc <> ord(opc$ipccnop) then
            if not (instruction_attributes[ins^.opc].class in post_fp_ops)
            then
              goto 8;
        if src^.f.depth > from^.f.depth then
          if ins^.opc = ord(opc$ipccnop) then
            goto 8;
      end;
    e := e^.next_pred;
  end;
  res := true;
  goto 9;
8:
  res := false;
9:
  instr_can_be_moved_along_all_edges := res;
end;

{ ipccnop_with_branches - the IPCCNOP ipcc (or, nil, the slot) at the
  end of bb, before its branches, filled with a bundle that sets the
  condition codes or a harmless one stolen from the head of a
  successor (from pred_bb when given, the deepest successor that
  allows it otherwise), with copies put at the ends of that block's
  other predecessors where needed and identical bundles at their other
  successors' heads deleted; the stolen bundle and an IPCCNOP after it
  then deleted.

  0x262E90, 0x53C bytes: `btst D3,(-57,A6)' with D3 0 tests the
  integer condition codes in the conflicts' reads (pattern 123); D2
  holds pred_bb, then the stolen instruction, then whether it sets the
  condition codes; the live sets of the blocks updated longword by
  longword. }

procedure ipccnop_with_branches(
    bb: bb_ptr_t;
    pred_bb: bb_ptr_t;
    ipcc: instr_ptr_t); options(val_param, internal);
label 9;
var
  ins, cand, steal, b, last, t, t2, d0i, p, a2: instr_ptr_t;
  conf, conf2: post_conf_t;
  count, d4: integer32;
  src_bb, s: bb_ptr_t;
  sets_cc, all_copied: boolean;
  e, e2: fg_edge_ptr_t;
  mode: integer;
begin
  if ipcc <> nil then
    if (ipcc^.opc <> ord(opc$ipccnop)) or ipcc^.h.grouped then
      goto 9;
  get_insertion_point_and_conflicts(nil, bb, ins, addr(conf), count);
  if ins = nil then
    goto 9;
  if ipcc <> nil then
    if ins <> ipcc then
      goto 9;
  src_bb := nil;
  steal := nil;
  cand := nil;
  if pred_bb <> nil then begin
    if not (0 in conf.reads[3]) then begin
      add_exit_active_conflicts(pred_bb, bb, addr(conf2), addr(conf));
      a2 := can_steal_bundle_from_bb(pred_bb, 2, addr(conf2), 0, false);
      if a2 <> nil then
        if instr_can_be_moved_along_all_edges(a2, pred_bb, bb) then begin
          src_bb := pred_bb;
          steal := a2;
          sets_cc := true;
        end;
    end;
  end
  else begin
    if not (0 in conf.reads[3]) then begin
      e := bb^.succs;
      while e <> nil do begin
        add_exit_active_conflicts(e^.target, bb, addr(conf2), addr(conf));
        a2 := can_steal_bundle_from_bb(e^.target, 2, addr(conf2), 0, false);
        if a2 <> nil then
          if (src_bb = nil) or (src_bb^.f.depth < e^.target^.f.depth) then
            if instr_can_be_moved_along_all_edges(a2, e^.target, bb) then
            begin
              src_bb := e^.target;
              cand := a2;
            end;
        e := e^.next_succ;
      end;
    end;
    if cand <> nil then begin
      steal := cand;
      sets_cc := true;
    end
    else begin
      e := bb^.succs;
      while e <> nil do begin
        add_exit_active_conflicts(e^.target, bb, addr(conf2), addr(conf));
        a2 := can_steal_bundle_from_bb(e^.target, 1, addr(conf2), 0, false);
        if a2 <> nil then
          if (src_bb = nil) or (src_bb^.f.depth < e^.target^.f.depth) then
            if instr_can_be_moved_along_all_edges(a2, e^.target, bb) then
            begin
              src_bb := e^.target;
              cand := a2;
            end;
        e := e^.next_succ;
      end;
      steal := cand;
      sets_cc := false;
    end;
  end;
  if steal = nil then
    goto 9;
  trace_message('Filling end of BB IPCCNOP');
  b := steal;
  discard(pass_bundle(b, last, 2, addr(conf)));
  src_bb^.live_in^[0] := src_bb^.live_in^[0] + conf.writes[0];
  src_bb^.live_in^[1] := src_bb^.live_in^[1] + conf.writes[1];
  src_bb^.live_in^[2] := src_bb^.live_in^[2] + conf.writes[2];
  src_bb^.live_in^[3] := src_bb^.live_in^[3] + conf.writes[3];
  all_copied := true;
  e := src_bb^.preds;
  while e <> nil do begin
    if need_copy_in_this_bb(src_bb, e^.source, bb, addr(conf)) then begin
      t := get_needed_inst(steal^.next);
      get_insertion_point_and_conflicts(src_bb, e^.source, ins, addr(conf2),
                                        count);
      d4 := count;
      d0i := copy_instr_to_new_bb(steal, e^.source, ins, false);
      if (ins^.opc = ord(opc$ipccnop))
         or (instruction_attributes[ins^.opc].class in post_fp_ops) then
        d0i^.h.grouped := true;
      s := e^.source;
      s^.live_out^[0] := s^.live_out^[0] + conf.writes[0];
      s^.live_out^[1] := s^.live_out^[1] + conf.writes[1];
      s^.live_out^[2] := s^.live_out^[2] + conf.writes[2];
      s^.live_out^[3] := s^.live_out^[3] + conf.writes[3];
      s^.transparent^[0] := s^.transparent^[0] - conf.writes[0];
      s^.transparent^[1] := s^.transparent^[1] - conf.writes[1];
      s^.transparent^[2] := s^.transparent^[2] - conf.writes[2];
      s^.transparent^[3] := s^.transparent^[3] - conf.writes[3];
      if sets_cc then begin
        e^.source^.live_out^[3] := e^.source^.live_out^[3] + [0];
        src_bb^.live_in^[3] := src_bb^.live_in^[3] + [0];
        if (d4 <> 0) and (t <> nil) then
          if (t^.opc = ord(opc$ipccnop)) and not t^.h.grouped then begin
            p := get_prev_needed_inst(ins^.prev);
            t2 := ins;
            if p^.h.grouped then
              discard(pass_bundle(t2, last, 0, addr(conf2)));
            if not (instruction_attributes[t2^.opc].class in post_fp_ops)
            then begin
              t := copy_instr_to_new_bb(t, e^.source, t2, true);
              t^.h.grouped := t2^.h.grouped;
              t2^.h.grouped := true;
            end
            else begin
              t := copy_instr_to_new_bb(t, e^.source, t2, false);
              t^.h.grouped := true;
            end;
          end
          else
            all_copied := false
        else
          all_copied := false;
      end;
      e2 := e^.source^.succs;
      if sets_cc then
        mode := 2
      else
        mode := 1;
      while e2 <> nil do begin
        if e2^.target <> src_bb then begin
          a2 := can_steal_bundle_from_bb(e2^.target, mode, addr(conf2), 1,
                                         false);
          if a2 <> nil then
            if instrs_are_identical(steal, a2) then begin
              delete_instruction(a2, e2^.target);
              if all_copied and sets_cc then
                if a2^.next <> nil then
                  if a2^.next^.opc = ord(opc$ipccnop) then
                    if not a2^.h.grouped then
                      delete_instruction(a2^.next, e2^.target);
            end;
        end;
        e2 := e2^.next_succ;
      end;
    end
    else begin
      s := e^.source;
      s^.live_out^[0] := s^.live_out^[0] + conf.writes[0];
      s^.live_out^[1] := s^.live_out^[1] + conf.writes[1];
      s^.live_out^[2] := s^.live_out^[2] + conf.writes[2];
      s^.live_out^[3] := s^.live_out^[3] + conf.writes[3];
      s^.live_in^[0] := s^.live_in^[0] + conf.writes[0];
      s^.live_in^[1] := s^.live_in^[1] + conf.writes[1];
      s^.live_in^[2] := s^.live_in^[2] + conf.writes[2];
      s^.live_in^[3] := s^.live_in^[3] + conf.writes[3];
    end;
    e := e^.next_pred;
  end;
  if all_copied then
    if steal^.next <> nil then
      if steal^.next^.opc = ord(opc$ipccnop) then
        delete_instruction(steal^.next, src_bb);
  delete_instruction(steal, src_bb);
9:
end;

{ ipccnop_shuffle_trapcc - the IPCCNOP ipcc before a conditional trap's
  bundle filled with an instruction of that bundle that sets the
  condition codes and does not interact with the trap's registers
  (moved before the IPCCNOP, grouped; an IPCCNOP after the trap then
  moved after it); for a trap that may not raise an exception, its
  result (and a pair's matching operand) left out of the conflicts.
  The instruction to go on from: the trap's or the next bundle.

  0x2633E6, 0x26C bytes: the result undefined when ipcc is not an
  ungrouped IPCCNOP (D5 not set: pattern 142); the trap's result kinds
  cleared for the bundle's second pass and put back
  (`andi.w #-32; or.b'). }

function ipccnop_shuffle_trapcc(
    ipcc: instr_ptr_t;
    bb: bb_ptr_t): instr_ptr_t; options(val_param, internal);
label 1, 8, 9;
var
  res, trap, a2, b, last, a0: instr_ptr_t;
  conf: post_conf_t;
  kind: operand$t;
  k, kk: integer32;
  flag: boolean;
begin
  if ipcc^.opc <> ord(opc$ipccnop) then
    goto 9;
  if ipcc^.h.grouped then
    goto 9;
  trap := get_needed_inst(ipcc^.next);
  res := trap;
  if trap = nil then
    goto 8;
  if instruction_attributes[trap^.opc].class <> class$trap_cond then
    goto 8;
  b := trap;
  discard(pass_bundle(b, last, 2, addr(conf)));
  a2 := b;
  if not a2^.h.may_generate_an_exception then begin
    kind := operand$none;
    kk := 0;
    if trap^.opnds[2].h.kind in [operand$ip_reg..
                                 operand$fp_reg_pair_physical] then
      if trap^.opnds[2].h.write or trap^.opnds[2].h.modify then begin
        kind := trap^.opnds[2].h.kind;
        trap^.opnds[2].h.kind := operand$none;
        if kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                    operand$fp_reg_pair_like] then
          for k := 3 to trap^.h.nopnds do
            if trap^.opnds[k].h.kind = kind then
              if trap^.opnds[k].h.write or trap^.opnds[k].h.modify then
              begin
                kk := k;
                trap^.opnds[k].h.kind := operand$none;
                goto 1;
              end;
      end;
1:
    b := trap;
    discard(pass_bundle(b, last, 2, addr(conf)));
    a2 := b;
    if kind <> operand$none then begin
      trap^.opnds[2].h.kind := kind;
      if kk <> 0 then
        trap^.opnds[kk].h.kind := kind;
    end;
  end;
  conf.reads[3] := conf.reads[3] - [0];
  if a2^.h.sets_cc then
    if not a2^.h.grouped then
      if not (instruction_attributes[a2^.opc].class in post_no_shuffle) then
        if not (instruction_attributes[a2^.opc].class in post_slow) then
        begin
          flag := false;
          if not check_register_conflicts(a2, 1, addr(conf), flag) then begin
            trace_message('Filling trap IPCCNOP');
            a2^.prev^.next := a2^.next;
            a2^.next^.prev := a2^.prev;
            if ipcc^.prev = nil then
              bb^.first := a2
            else
              ipcc^.prev^.next := a2;
            a2^.prev := ipcc^.prev;
            a2^.next := ipcc;
            ipcc^.prev := a2;
            a2^.h.grouped := true;
            a2 := get_needed_inst(trap^.next);
            if a2 <> nil then
              if a2^.opc = ord(opc$ipccnop) then
                if not a2^.h.grouped then begin
                  a2^.prev^.next := a2^.next;
                  a2^.next^.prev := a2^.prev;
                  trap^.next^.prev := a2;
                  a2^.next := trap^.next;
                  trap^.next := a2;
                  a2^.prev := trap;
                  if trap^.h.grouped then
                    a2^.h.grouped := true
                  else
                    trap^.h.grouped := true;
                  res := get_needed_inst(a2^.next);
                end;
          end;
        end;
8:
  ipccnop_shuffle_trapcc := res;
9:
end;

{ post_$fill_ipccnop - the IPCCNOPs filled: each block's (code order)
  ungrouped IPCCNOPs before a branch from the block's successors
  (ipccnop_with_branches), before a conditional trap from its bundle;
  then, taking desperate measures, a block starting with a harmless
  instruction and an IPCCNOP after it lends that instruction to its
  +54 block (when that is a predecessor no deeper in loops) for the
  IPCCNOP at its end.

  0x263668, 0x1C8 bytes, no A5 (internal). }

procedure post_$fill_ipccnop; options(internal);
label 1, 2;
var
  bb, l54: bb_ptr_t;
  i, a0, b, last: instr_ptr_t;
  conf: post_conf_t;
  cls: integer;
  found: boolean;
  e: fg_edge_ptr_t;
begin
  trace_pass_start('POST_$FILL_IPCCNOP', 18);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := get_needed_inst(bb^.first);
    while i <> nil do begin
      if (i^.opc <> ord(opc$ipccnop)) or i^.h.grouped then begin
        b := i;
        discard(pass_bundle(b, last, 0, addr(conf)));
        i := b;
      end
      else begin
        a0 := get_needed_inst(i^.next);
        if a0 = nil then
          goto 1;
        cls := instruction_attributes[a0^.opc].class;
        if cls = class$branch then begin
          ipccnop_with_branches(bb, nil, i);
          i := nil;
        end
        else if cls in post_no_shuffle then begin
          b := a0;
          discard(pass_bundle(b, last, 0, addr(conf)));
          i := b;
        end
        else
          i := ipccnop_shuffle_trapcc(i, bb);
      end;
    end;
1:
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_message('Taking desperate measures');
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := get_needed_inst(bb^.first);
    if i <> nil then
      if not i^.h.grouped then
        if i^.opc <> ord(opc$ipccnop) then
          if not (instruction_attributes[i^.opc].class in post_fp_ops) then
          begin
            a0 := get_needed_inst(i^.next);
            if a0 <> nil then
              if a0^.opc = ord(opc$ipccnop) then
                if not a0^.h.grouped then begin
                  e := bb^.preds;
                  found := false;
                  while e <> nil do begin
                    if e^.source = bb^.l54 then begin
                      found := true;
                      goto 2;
                    end;
                    e := e^.next_pred;
                  end;
2:
                  if found then begin
                    l54 := bb^.l54;
                    if not (bb^.f.depth < l54^.f.depth) then
                      ipccnop_with_branches(l54, bb, nil);
                  end;
                end;
          end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ block_is_only_const_ip_move - whether bb (one edge in, one out) is a
  MOVE of the immediate -1, 0 or 1 followed by a jump, trap or return
  that ends it: value the immediate, instr the MOVE.

  0x26385C, 0xD0 bytes: the instruction after the MOVE is not tested
  for nil. }

function block_is_only_const_ip_move(
    bb: bb_ptr_t;
    var value: integer32;
    var instr: instr_ptr_t): boolean; options(val_param, internal);
var
  res: boolean;
  i: instr_ptr_t;
begin
  res := false;
  if bb^.preds <> nil then
    if bb^.preds^.next_pred = nil then
      if bb^.succs <> nil then
        if bb^.succs^.next_succ = nil then begin
          i := flush_labels(bb);
          if i <> nil then
            if not i^.h.grouped then
              if i^.opc = ord(opc$move) then
                if i^.opnds[1].h.kind = operand$immediate then
                  if (i^.opnds[1].value = -1) or (i^.opnds[1].value = 1)
                     or (i^.opnds[1].value = 0) then begin
                    value := i^.opnds[1].value;
                    instr := i;
                    i := get_needed_inst(i^.next);
                    if instruction_attributes[i^.opc].class in post_jumps
                    then
                      if i^.next = nil then
                        res := true;
                  end;
        end;
  block_is_only_const_ip_move := res;
end;

{ fill_er_up - a bundle of mode mode stolen from from_bb's head (when it
  has at most two predecessors; may trap) and put before ins in bb;
  ins the bundle.

  0x26392C, 0x68 bytes: move_bundle_to_new_bb's arguments left on the
  stack (pattern 135). }

function fill_er_up(
    bb: bb_ptr_t;
    from_bb: bb_ptr_t;
    mode: integer;
    var ins: instr_ptr_t;
    conf: post_conf_ptr_t): boolean; options(val_param, internal);
var
  i: instr_ptr_t;
begin
  if from_bb = nil then
    fill_er_up := false
  else begin
    i := can_steal_bundle_from_bb(from_bb, mode, conf, 2, true);
    if i = nil then
      fill_er_up := false
    else begin
      move_bundle_to_new_bb(from_bb, i, bb, ins, false);
      ins := i;
      fill_er_up := true;
    end;
  end;
end;

{ find_ip_slot_and_insert_instr - a new instruction of opcode opc in bb
  before the first IPCCNOP or floating instruction from first on
  (before last when none; then a floating bundle stolen from from_bb
  first when one may be), grouped with what it goes before when that
  is an IPCCNOP or floating instruction.

  0x263994, 0xE6 bytes. }

function find_ip_slot_and_insert_instr(
    opc: integer;
    bb: bb_ptr_t;
    first: instr_ptr_t;
    from_bb: bb_ptr_t;
    conf: post_conf_ptr_t;
    last: instr_ptr_t): instr_ptr_t; options(val_param, internal);
label 1;
var
  a2, b, l, ins, new: instr_ptr_t;
  conf2: post_conf_t;
begin
  a2 := first;
  while a2 <> last do begin
    if a2^.opc = ord(opc$ipccnop) then
      goto 1;
    if instruction_attributes[a2^.opc].class in post_fp_ops then
      goto 1;
    b := a2;
    discard(pass_bundle(b, l, 0, addr(conf2)));
    a2 := b;
  end;
1:
  ins := a2;
  if a2 = last then
    if from_bb <> nil then
      if fill_er_up(bb, from_bb, 3, ins, conf) then
        a2 := ins;
  new := insert_instruction(opc, bb, a2, false);
  if (a2^.opc = ord(opc$ipccnop))
     or (instruction_attributes[a2^.opc].class in post_fp_ops) then
    new^.h.grouped := true;
  find_ip_slot_and_insert_instr := new;
end;

{ post_$sprinkle_mfnextcc - a conditional move made branch-free: a block
  whose two successors are each a MOVE of 0 and of -1 or 1 to the same
  register and a jump to a common block, and that ends with a
  conditional branch, the branch (and its IPCCNOP) replaced by MFNEXTCC
  (the condition codes into the register), an EXTRACTU of the branch's
  condition bit (post_cc_bits), and a NEG (for -1) or a SUB or XOR with
  1 when the sense is reversed; done when an instruction before the
  IPCCNOP leaves room or the join block lends one, otherwise "would be
  slower".  The two MOVE blocks' MOVEs are deleted.

  0x263A7A, 0x602 bytes, no A5 (internal): the blocks from the last
  (+72) through +114; the branch's condition from its opcode's b15
  (bits 2..0 the bit's index, bit 3 the sense; `move.w (14,A1,D0.w);
  btst #3'); fill_er_up's block argument the MOVE block (D6), as the
  image has it. }

procedure post_$sprinkle_mfnextcc; options(internal);
label 1, 2, 3, 4, 5;
var
  bb, prevbb, head, other, join: bb_ptr_t;
  value: integer32;
  mv, mv2, br, a2, first_conf, ipcc, last, b, x, t2, a3: instr_ptr_t;
  conf, conf2: post_conf_t;
  e1, e2, e: fg_edge_ptr_t;
  ahead: integer32;
  sense, rev: boolean;
  val2: integer32;
  bropc: integer;
  newopc: integer;
  cls: integer;
begin
  trace_pass_start('POST_$SPRINKLE_MFCCNOP', 22);
  bb := post_rtn^.bbs72;
  while bb <> nil do begin
    trace_block_entry(bb);
    prevbb := bb^.next114;
    if not block_is_only_const_ip_move(bb, value, mv) then
      goto 1;
    if value <> 0 then
      goto 1;
    head := bb^.preds^.source;
    e1 := head^.succs;
    if e1 = nil then
      goto 1;
    e2 := e1^.next_succ;
    if e2 = nil then
      goto 1;
    if e2^.next_succ <> nil then
      goto 1;
    if head^.f.hidden_successor_edges then
      goto 1;
    if e1^.target <> bb then
      other := e1^.target
    else
      other := e2^.target;
    if not block_is_only_const_ip_move(other, value, mv2) then
      goto 1;
    val2 := value;
    if val2 = 0 then
      goto 1;
    if mv^.opnds[2].h.num <> mv2^.opnds[2].h.num then
      goto 1;
    br := head^.last;
    while br <> nil do begin
      if instruction_attributes[br^.opc].class in [class$branch,
                                                   class$fp_branch] then
        goto 2;
      br := get_prev_needed_inst(br^.prev);
    end;
2:
    if br = nil then
      goto 1;
    if instruction_attributes[br^.opc].class <> class$branch then
      goto 1;
    if (instruction_attributes[br^.opc].b15 & 7) = 0 then
      goto 1;
    if br^.opnds[1].h.kind <> operand$flow_graph_edge then
      goto 1;
    discard(get_full_conflicts(mv, 2, addr(conf)));
    first_conf := nil;
    a2 := get_prev_needed_inst(br^.prev);
    ahead := 0;
    while a2 <> nil do begin
      if instruction_attributes[a2^.opc].class in post_transfers then
        goto 1;
      if a2^.opc = ord(opc$ipccnop) then
        goto 3;
      if first_conf = nil then begin
        if not a2^.h.grouped then
          ahead := ahead + 1;
        if get_full_conflicts(a2, 1, addr(conf)) then
          first_conf := a2;
      end;
      a2 := get_prev_needed_inst(a2^.prev);
    end;
3:
    if a2 = nil then
      goto 1;
    ipcc := a2;
    a2 := get_prev_needed_inst(ipcc^.prev);
    while a2 <> nil do begin
      if first_conf = nil then
        if get_full_conflicts(a2, 1, addr(conf)) then
          first_conf := a2;
      discard(get_full_conflicts(a2, 2, addr(conf2)));
      if 0 in conf2.writes[3] then begin
        if a2^.h.grouped then
          ahead := ahead - 1;
        goto 4;
      end;
      if not a2^.h.grouped then
        if first_conf = nil then
          ahead := ahead + 1;
      a2 := get_prev_needed_inst(a2^.prev);
    end;
4:
    if a2 = nil then
      goto 1;
    if instruction_attributes[a2^.opc].class in post_slow then
      goto 1;
    if not a2^.h.sets_cc then
      goto 1;
    e := br^.opnds[1].ptr;
    if e^.target = bb then
      sense := false
    else if e^.target = other then
      sense := true
    else
      bug_check('POST_$sprinkle_mfnextcc:  branch target not in target list.%$');
    if bb^.succs^.target = other^.succs^.target then
      join := bb^.succs^.target
    else
      join := nil;
    rev := (instruction_attributes[br^.opc].b15 & 8) <> 0;
    if not ((ahead > 0) or ((val2 = 1) and (rev = sense))) then begin
      if join = nil then
        goto 5;
      if can_steal_bundle_from_bb(join, 0, addr(conf), 2, true) = nil then
        goto 5;
    end;
    trace_message('Transforming to MFNEXTCC');
    if first_conf = nil then
      first_conf := a2;
    delete_instruction(ipcc, head);
    last := head^.last;
    bropc := br^.opc;
    delete_instruction(br, head);
    b := first_conf;
    discard(pass_bundle(b, x, 0, addr(conf2)));
    a2 := insert_instruction(ord(opc$mfnextcc), head, b, false);
    a2^.opnds[1] := mv^.opnds[2];
    a2^.opnds[a2^.h.nopnds].h.kind := operand$ip_condition_codes;
    opnd_bytes_ptr_t(addr(a2^.opnds[a2^.h.nopnds]))^.rrp := 16;
    a2^.opnds[a2^.h.nopnds].h.num := post_ip_cc;
    b := a2;
    discard(pass_bundle(b, x, 0, addr(conf2)));
    a3 := b;
    if a3 <> last then begin
      b := a3;
      discard(pass_bundle(b, x, 0, addr(conf2)));
      a3 := b;
    end
    else if join <> nil then begin
      t2 := a3;
      if fill_er_up(bb, join, 0, t2, addr(conf)) then begin
        b := t2;
        discard(pass_bundle(b, x, 0, addr(conf2)));
        a3 := b;
      end;
    end;
    a3 := find_ip_slot_and_insert_instr(ord(opc$extractu), head, a3, join,
                                        addr(conf), last);
    a3^.opnds[1] := mv^.opnds[2];
    a3^.opnds[3] := mv^.opnds[2];
    a3^.h.width := 1;
    a3^.opnds[2].h.kind := operand$immediate;
    opnd_bytes_ptr_t(addr(a3^.opnds[2]))^.rrp := 16;
    a3^.opnds[2].value :=
        post_cc_bits[instruction_attributes[bropc].b15 & 7];
    b := a3;
    discard(pass_bundle(b, x, 0, addr(conf2)));
    a2 := b;
    if ((instruction_attributes[bropc].b15 & 8) <> 0) = sense then begin
      if val2 = -1 then begin
        a2 := find_ip_slot_and_insert_instr(ord(opc$neg), head, a2, join,
                                            addr(conf), last);
        a2^.opnds[1] := mv^.opnds[2];
        a2^.opnds[2] := mv^.opnds[2];
      end;
    end
    else begin
      if val2 = 1 then
        newopc := ord(opc$xor)
      else
        newopc := ord(opc$sub);
      a2 := find_ip_slot_and_insert_instr(newopc, head, a2, join,
                                          addr(conf), last);
      a2^.opnds[2] := mv^.opnds[2];
      a2^.opnds[3] := mv^.opnds[2];
      a2^.opnds[1].h.kind := operand$immediate;
      opnd_bytes_ptr_t(addr(a2^.opnds[1]))^.rrp := 16;
      a2^.opnds[1].value := 1;
    end;
    delete_instruction(mv, bb);
    delete_instruction(mv2, other);
    goto 1;
5:
    trace_message('Could do MFNEXTCC but it would be slower');
1:
    trace_block_exit;
    bb := prevbb;
  end;
  trace_pass_finish;
end;

{ post_$reschedule_spill_loads - a load whose result the next bundle
  reads (a stall) moved before the bundle before it, when their
  registers do not interact; memory counts as a register (98) for a
  load from the frame or through the DB register and a store before it,
  unless their alias descriptors (from the instruction's +2 bit 7
  record in front of it, or alias_$get_alias_desc) show them unrelated.
  An ungrouped IPCCNOP is moved next to a neighbouring bundle that
  neither reads nor writes the condition codes (after a floating
  instruction, grouped; before another, taking its grouping).

  0x264114, 0x53A bytes, no A5 (internal): the blocks in code order;
  the bundles' conflicts at -40 (the one before), -128 (the load's),
  -96 (the next); the alias descriptors (20 bytes) at -152 and -64,
  the store's inexact flag set in the load's descriptor (`bset
  #7,(-133,A6)') as the image has it; the moved flag D2 (false) used as
  a bit number (`bclr D2,(-81,A6)': the condition codes, pattern 123);
  the relation D5: 0 unrelated, 1 related, 2 to be decided. }

procedure post_$reschedule_spill_loads; options(internal);
label 1;
var
  bb: bb_ptr_t;
  prevb, cur, nxt, last, t: instr_ptr_t;
  prevconf, curconf, nextconf: post_conf_t;
  desc, desc2: alias_$desc_t;
  node: univ_ptr;
  rel: integer;
  moved: boolean;
  kind: operand$t;
  a2: instr_ptr_t;
begin
  trace_pass_start('RESCHEDULE_SPILL_LOADS', 22);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    prevb := flush_labels(bb);
    if prevb = nil then
      cur := nil
    else begin
      cur := prevb;
      discard(pass_bundle(cur, last, 2, addr(prevconf)));
    end;
    while cur <> nil do begin
      trace_instruction(cur);
      moved := false;
      nxt := cur;
      discard(pass_bundle(nxt, last, 2, addr(curconf)));
      if (instruction_attributes[cur^.opc].class = class$load)
         and (nxt <> nil) and not cur^.h.grouped
         and (cur^.opnds[1].h.kind in [operand$none, operand$ip_reg_like..
                  operand$fp_reg_pair_like, operand$flow_graph_edge..
                  operand$immediate, operand$exception_information]) then
      begin
        if cur^.opnds[2].h.kind in [operand$none, operand$ip_reg_like..
               operand$fp_reg_pair_like, operand$flow_graph_edge..
               operand$immediate, operand$exception_information] then
          case cur^.opnds[1].h.kind of
            operand$displacement_literal_pool:
              rel := 0;
            operand$displacement_stack_frame: begin
              node := cur^.opnds[1].link;
              rel := 2;
            end;
            otherwise
              rel := 1;
          end
        else begin
          if not (cur^.opnds[2].h.kind in [operand$ip_reg..
                                           operand$well_behaved_memory]) then
            goto 1;
          if cur^.opnds[2].lts^.lr <> post_rtn^.db_lr then
            goto 1;
          if cur^.opnds[1].h.kind = operand$immediate then begin
            node := cur^.opnds[1].link;
            rel := 2;
          end
          else
            rel := 1;
        end;
        if rel = 2 then
          if cur^.h.b2_7 then
            desc := alias_$desc_ptr_t(integer32(cur) - 24)^
          else if alias_$get_alias_desc(node, 4, desc) then
            desc.inexact := true
          else
            rel := 1;
        if rel = 2 then
          if desc.class = 0 then
            rel := 0;
        if rel <> 0 then
          curconf.reads[3] := curconf.reads[3] + [2];
        t := nxt;
        discard(pass_bundle(t, last, 2, addr(nextconf)));
        if (nxt^.opc <> ord(opc$ipccnop)) or nxt^.h.grouped then
          nextconf.reads[3] := nextconf.reads[3] - [0];
        if (curconf.writes[3] * nextconf.reads[3] = [])
           and (curconf.writes[2] * nextconf.reads[2] = [])
           and (nextconf.reads[0] * curconf.writes[0] = [])
           and (curconf.writes[1] * nextconf.reads[1] = []) then
          goto 1;
        t := prevb;
        discard(pass_bundle(t, last, 2, addr(prevconf)));
        if instruction_attributes[prevb^.opc].class = class$store then
          if rel <> 0 then begin
            if prevb^.h.b2_7 then
              desc2 := alias_$desc_ptr_t(integer32(prevb) - 24)^
            else begin
              kind := prevb^.opnds[2].h.kind;
              if kind = operand$displacement_stack_frame then begin
                if alias_$get_alias_desc(univ_ptr(prevb^.opnds[1].link),
                       lshft(1, instruction_attributes[prevb^.opc].w18 & 7),
                       desc2) then
                  desc.inexact := true
                else
                  rel := 1;
              end
              else if kind = operand$immediate then begin
                if alias_$get_alias_desc(univ_ptr(prevb^.opnds[1].link),
                       lshft(1, instruction_attributes[prevb^.opc].w18 & 7),
                       desc2) then
                  desc.inexact := true
                else
                  rel := 1;
              end
              else
                rel := 1;
            end;
            if rel = 2 then
              if alias_$related(desc, desc2) then
                rel := 1
              else
                rel := 0;
            if rel = 1 then
              prevconf.writes[3] := prevconf.writes[3] + [2]
            else if rel = 0 then
              prevconf.writes[3] := prevconf.writes[3] - [2];
          end;
        if check_conflicts_for_interaction(addr(curconf), addr(prevconf)) then
          goto 1;
        trace_message('Moving LOAD to prevent a stall');
        moved := true;
        cur^.prev^.next := cur^.next;
        cur^.next^.prev := cur^.prev;
        cur^.prev := prevb^.prev;
        if cur^.prev = nil then
          bb^.first := cur
        else
          cur^.prev^.next := cur;
        cur^.next := prevb;
        prevb^.prev := cur;
      end
      else if (cur^.opc = ord(opc$ipccnop)) and not cur^.h.grouped then begin
        a2 := nil;
        if nxt <> nil then
          if not (instruction_attributes[nxt^.opc].class in post_transfers)
          then begin
            t := nxt;
            discard(pass_bundle(t, last, 2, addr(nextconf)));
            if (t = nil)
               or (instruction_attributes[t^.opc].class <> class$branch) then
              if not (0 in (nextconf.reads[3] + nextconf.writes[3])) then
                a2 := nxt;
          end;
        if a2 = nil then
          if not (instruction_attributes[prevb^.opc].class in post_transfers)
          then begin
            t := prevb;
            discard(pass_bundle(t, last, 2, addr(prevconf)));
            if not (0 in (prevconf.reads[3] + prevconf.writes[3])) then
              a2 := prevb;
          end;
        if a2 <> nil then begin
          cur^.prev^.next := cur^.next;
          cur^.next^.prev := cur^.prev;
          if instruction_attributes[a2^.opc].class in post_fp_ops then begin
            cur^.next := a2^.next;
            cur^.next^.prev := cur;
            cur^.prev := a2;
            a2^.next := cur;
            cur^.h.grouped := true;
            t := cur;
          end
          else begin
            cur^.prev := a2^.prev;
            cur^.prev^.next := cur;
            cur^.next := a2;
            a2^.prev := cur;
            cur^.h.grouped := a2^.h.grouped;
            a2^.h.grouped := true;
            t := a2;
          end;
          cur := t;
          nxt := cur;
          discard(pass_bundle(nxt, last, 0, addr(curconf)));
        end;
      end;
1:
      if not moved then
        prevb := cur;
      cur := nxt;
    end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ post_$call_shadows - each call's shadow (the instruction after it)
  filled with the single integer, load or store instruction before it
  (not a NOP; not with the switch sw12) when its registers do not
  interact with the call's: the call's +3 bits 7..6 set (3) and the two
  swapped.

  0x264684, 0x158 bytes, no A5 (internal): the blocks from the last
  (+72) through +114; the switches by address (`movea.l #0x485D30'). }

procedure post_$call_shadows; options(internal);
var
  bb: bb_ptr_t;
  sw: ^at_switches_t;
  cand, i, cand_last, b, last, call: instr_ptr_t;
  conf: post_conf_t;
begin
  trace_pass_start('POST_$CALL_SHADOWS', 18);
  bb := post_rtn^.bbs72;
  sw := addr(at_backend_switches);
  while bb <> nil do begin
    trace_block_entry(bb);
    cand := nil;
    i := flush_labels(bb);
    while i <> nil do begin
      trace_instruction(i);
      if instruction_attributes[i^.opc].class <> class$call then begin
        cand := i;
        b := i;
        discard(pass_bundle(b, cand_last, 2, addr(conf)));
        i := b;
        if not (instruction_attributes[cand^.opc].class in post_shadow_ok) then
          cand := nil
        else if sw^.sw12 then
          cand := nil
        else if cand <> cand_last then
          cand := nil
        else if cand^.opc = ord(opc$nop) then
          cand := nil;
      end
      else begin
        if cand = nil then begin
          b := i;
          next_bundle(b, last);
          i := b;
        end
        else begin
          call := i;
          b := i;
          if pass_bundle(b, last, 1, addr(conf)) then
            i := b
          else begin
            i := b;
            trace_message('Inserting call shadow.');
            call^.h.modify := 3;
            swap_bundles(cand, cand_last, last, bb);
          end;
        end;
        cand := nil;
      end;
    end;
    trace_block_exit;
    bb := bb^.next114;
  end;
  trace_pass_finish;
end;

{ post_$branch_shadow_always - a block's transfer whose shadow mode is 2
  given the bundle before it (a single instruction that is not itself
  a transfer, call, limit, trap or svc; not with sw12) for its shadow
  when their registers do not interact: mode 3 and the two swapped.
  The transfer is kept at the block's +138.

  0x264806, 0x17E bytes, no A5 (internal): the blocks in code order. }

procedure post_$branch_shadow_always; options(internal);
label 1;
var
  bb: bb_ptr_t;
  sw: ^at_switches_t;
  i, cand, b, last, x, x2, br: instr_ptr_t;
  conf: post_conf_t;
begin
  trace_pass_start('POST_$BRANCH_SHADOW_ALWAYS', 26);
  bb := post_rtn^.bbs;
  sw := addr(at_backend_switches);
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    cand := nil;
    while i <> nil do begin
      trace_instruction(i);
      if instruction_attributes[i^.opc].class in post_transfers then
        goto 1;
      cand := i;
      b := i;
      next_bundle(b, last);
      i := b;
      if instruction_attributes[cand^.opc].class in post_ends then begin
        if instruction_attributes[cand^.opc].class = class$call then
          if cand^.h.modify <> 0 then begin
            b := i;
            next_bundle(b, last);
            i := b;
          end;
        cand := nil;
      end;
    end;
1:
    if sw^.sw12 then
      cand := nil;
    post_bb_v_ptr_t(bb)^.ctl := i;
    if i <> nil then
      if cand <> nil then
        if i^.h.modify = 2 then begin
          br := i;
          b := i;
          discard(pass_bundle(b, x, 2, addr(conf)));
          b := cand;
          if not pass_bundle(b, x2, 1, addr(conf)) then begin
            br^.h.modify := 3;
            swap_bundles(cand, last, x, bb);
          end;
        end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ safe_to_forward_jump_through_ip_reg - whether a jump through an
  integer register (instr) at the head of bb may be copied to bb's
  predecessors: none hides edges out, and the registers of each
  predecessor's transfers do not interact with the jump's.

  0x26499E, 0xA0 bytes. }

function safe_to_forward_jump_through_ip_reg(
    bb: bb_ptr_t;
    instr: instr_ptr_t): boolean; options(val_param, internal);
label 9;
var
  res: boolean;
  b, last, i: instr_ptr_t;
  conf: post_conf_t;
  e: fg_edge_ptr_t;
begin
  res := false;
  if instr^.opnds[1].h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                operand$ip_reg_like,
                                operand$case_jump_base] then begin
    b := instr;
    discard(pass_bundle(b, last, 2, addr(conf)));
    e := bb^.preds;
    while e <> nil do begin
      if e^.source^.f.hidden_successor_edges then
        goto 9;
      i := post_bb_v_ptr_t(e^.source)^.ctl;
      while i <> nil do begin
        b := i;
        if pass_bundle(b, last, 1, addr(conf)) then
          goto 9;
        i := b;
      end;
      e := e^.next_pred;
    end;
    res := true;
  end;
9:
  safe_to_forward_jump_through_ip_reg := res;
end;

{ post_$forward_empty_block - a block holding only labels, the bundles
  before an unconditional jump and the jump (its shadow mode not 1 or 3)
  forwarded (fg_utils_$forward_this_block): its bundles moved to the
  jump's target, after the target's leading labels.

  0x264A3E, 0x1BC bytes, no A5 (internal). }

procedure post_$forward_empty_block; options(internal);
label 1;
var
  bb, nxtbb, target: bb_ptr_t;
  i, jump, b, last, anchor, nx: instr_ptr_t;
  after: boolean;
begin
  trace_pass_start('POST_$FORWARD_EMPTY_BLOCK', 25);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    nxtbb := bb^.next;
    if i <> nil then
      if instruction_attributes[i^.opc].class in post_jumps then
        if (i^.opnds[1].h.kind = operand$flow_graph_edge)
           or safe_to_forward_jump_through_ip_reg(bb, i) then begin
          jump := i;
          b := i;
          next_bundle(b, last);
          if b = nil then
            if last = jump then begin
              if odd(jump^.h.modify) then
                bug_check('POST_$FORWARD_EMPTY_BLOCK -- unconditional jump shadow is not .sf%$');
              if jump^.opnds[1].h.kind = operand$flow_graph_edge then begin
                target := fg_edge_ptr_t(jump^.opnds[1].ptr)^.target;
                anchor := target^.first;
                if anchor <> nil then begin
                  after := instruction_attributes[anchor^.opc].class
                           = class$label;
                  if after then
                    while anchor^.next <> nil do begin
                      if instruction_attributes[anchor^.next^.opc].class
                         <> class$label then
                        goto 1;
                      anchor := anchor^.next;
                    end;
1:
                  i := bb^.first;
                  while i <> jump do begin
                    b := i;
                    next_bundle(b, last);
                    nx := b;
                    if instruction_attributes[i^.opc].class <> class$label
                    then begin
                      move_bundle_to_new_bb(bb, i, target, anchor, after);
                      anchor := last;
                      after := true;
                    end;
                    i := nx;
                  end;
                end;
              end;
              fg_utils_$forward_this_block(post_rtn, bb, jump);
            end;
        end;
    trace_block_exit;
    bb := nxtbb;
  end;
  trace_pass_finish;
end;

{ post_$rotate_loop_header - a loop head (a distinguished, conditional,
  reducible entry not hiding edges) with two successors moved in code
  order between a predecessor and the loop's exit when the predecessor
  falls through to the exit and does not start with a branch.

  0x264C58, 0x114 bytes, no A5 (internal): bb unlinked without nil
  tests. }

procedure post_$rotate_loop_header; options(internal);
label 1;
var
  bb, t1, t2, exitb, p: bb_ptr_t;
  e1, e2, e: fg_edge_ptr_t;
  i: instr_ptr_t;
  n, pv: bb_ptr_t;
begin
  trace_pass_start('POST_$ROTATE_LOOP_HEADER', 24);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    if bb^.f.distinguished_entry then
      if bb^.f.conditional_entry then
        if not bb^.f.irreducible then
          if not bb^.f.hidden_successor_edges then begin
            e1 := bb^.succs;
            e2 := e1^.next_succ;
            if e2 <> nil then
              if e2^.next_succ = nil then begin
                t1 := e1^.target;
                t2 := e2^.target;
                if (t1 <> bb) and (t2 <> bb) then begin
                  if t1^.l70 = bb then
                    exitb := t2
                  else
                    exitb := t1;
                  e := bb^.preds;
                  while e <> nil do begin
                    p := e^.source;
                    if p^.next = exitb then begin
                      i := flush_labels(p);
                      if i <> nil then
                        if instruction_attributes[i^.opc].class
                           in [class$branch, class$fp_branch] then
                          goto 1;
                      n := bb^.next;
                      pv := bb^.next114;
                      n^.next114 := pv;
                      pv^.next := n;
                      p^.next := bb;
                      exitb^.next114 := bb;
                      bb^.next := exitb;
                      bb^.next114 := p;
                      goto 1;
                    end;
                    e := e^.next_pred;
                  end;
                end;
              end;
          end;
1:
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ post_$split_back_edge_target - a block ending with a branch whose
  shadow mode is 2 (still needing a shadow) and branching to a block of
  its own interval that does not follow it: that target split after
  its first bundle, which becomes the shadow of a new JUMP (mode 3) to
  the new block holding the rest.

  0x264D84, 0x2D4 bytes, no A5 (internal): the JUMP from post's heap
  (56 bytes) with its first longword built in a local (`move.l
  #0x40C0', the operand count from instruction_attributes' +11 bits
  6..3 for opc$jump). }

procedure post_$split_back_edge_target; options(internal);
label 1, 2;
type
  hdr_t = record
    case integer of
      1: (h: instr_hdr_t);
      2: (l: integer32);
  end;
var
  bb, head, ih1, ih2, target, nb, after: bb_ptr_t;
  i, b, last, first, flast, rest, jump: instr_ptr_t;
  e1, e2, e, a0e: fg_edge_ptr_t;
  hdr: hdr_t;
begin
  trace_pass_start('POST_$SPLIT_BACK_EDGE_TARGET', 28);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    while i <> nil do begin
      if instruction_attributes[i^.opc].class in post_branches then
        if i^.h.modify = 2 then
          goto 2
        else
          goto 1;
      b := i;
      next_bundle(b, last);
      i := b;
    end;
    goto 1;
2:
    trace_message('This block still needs a shadow');
    head := interval_of_basic_block(bb);
    if head = nil then
      goto 1;
    e1 := bb^.succs;
    ih1 := interval_of_basic_block(e1^.target);
    e2 := e1^.next_succ;
    if e2 = nil then
      ih2 := nil
    else begin
      if e2^.next_succ <> nil then
        goto 1;
      ih2 := interval_of_basic_block(e2^.target);
    end;
    if ih2 = ih1 then
      goto 1;
    if ih1 = head then
      a0e := e1
    else if ih2 = head then
      a0e := e2
    else
      goto 1;
    target := a0e^.target;
    if target = bb^.next then
      goto 1;
    if target^.f.atomic then
      goto 1;
    trace_message('Found non-sequential target in same loop');
    i := flush_labels(target);
    if i = nil then
      goto 1;
    if instruction_attributes[i^.opc].class in post_ends then
      goto 1;
    first := i;
    b := i;
    next_bundle(b, last);
    flast := last;
    rest := b;
    if rest = nil then
      goto 1;
    trace_message('Splitting block');
    nb := lir_$new_basic_block;
    nb^.next114 := target;
    after := target^.next;
    target^.next := nb;
    nb^.next := after;
    if after = nil then
      post_rtn^.bbs72 := nb
    else
      after^.next114 := nb;
    nb^.f.depth := target^.f.depth;
    nb^.f.hidden_successor_edges := target^.f.hidden_successor_edges;
    target^.f.hidden_successor_edges := false;
    nb^.f.loop_exit := target^.f.loop_exit;
    target^.f.loop_exit := false;
    if target^.f.distinguished_entry then
      nb^.l70 := target
    else
      nb^.l70 := target^.l70;
    nb^.l78 := nb^.l70^.l74;
    nb^.l70^.l74 := nb;
    nb^.last := target^.last;
    e := target^.succs;
    nb^.succs := e;
    target^.succs := nil;
    while e <> nil do begin
      e^.source := nb;
      e := e^.next_succ;
    end;
    jump := mrh_$alloc(post_heap, 56);
    jump^.opc := ord(opc$jump);
    hdr.l := 16#40C0;
    hdr.h.nopnds := instruction_attributes[ord(opc$jump)].nopnds;
    jump^.h := hdr.h;
    jump^.opnds[1].h.kind := operand$flow_graph_edge;
    jump^.opnds[1].ptr := lir_$add_flow_graph_edge(target, nb);
    post_bb_v_ptr_t(nb)^.ctl := post_bb_v_ptr_t(target)^.ctl;
    post_bb_v_ptr_t(target)^.ctl := jump;
    jump^.prev := first^.prev;
    if jump^.prev = nil then
      target^.first := jump
    else
      jump^.prev^.next := jump;
    jump^.next := first;
    first^.prev := jump;
    target^.last := flast;
    flast^.next := nil;
    nb^.first := rest;
    rest^.prev := nil;
1:
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ post_$branch_shadow_true - a block that is only an unconditional jump
  and its shadow (grouped with it, or the bundle after a jump of mode
  1) taken out of its predecessors' paths: each predecessor's branch to
  it (mode 2, not with sw10) becomes a branch of mode 1 (.ST) to the
  jump's target with a copy of the shadow after it, unless the jump
  goes to the block after the predecessor or to bb, or the
  predecessor's following jump or fall-through goes deeper in loops
  ("not really creating .ST"); a predecessor whose calls do not name
  the edge then loses it ("removing the edge").  A block left with no
  predecessors and only labels that need none is flushed.  Not with
  sw12.

  0x2650CE, 0x53C bytes, no A5 (internal): the shadow copied a longword
  at a time (tested at the top: `tst.l D3; bgt'); the predecessor's
  start-block and hidden-edges flags or-ed (`smi; seq; or.b'); the
  jump's edge target compared with bb whatever the jump's operand. }

procedure post_$branch_shadow_true; options(internal);
label 1, 3, 4, 5, 6, 7, 8;
type
  longs_t = array [1..1024] of integer32;
var
  bb, nxtbb, src, tb: bb_ptr_t;
  i, first, last, shadow, shlast, d6, d7, a2, c, new, a3: instr_ptr_t;
  e, enext, prevedge, ed, se: fg_edge_ptr_t;
  keep: boolean;
  dpth: integer;
  size, k: integer32;
  dst, srcp: ^longs_t;
begin
  trace_pass_start('POST_$BRANCH_SHADOW_TRUE', 24);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    nxtbb := bb^.next;
    i := flush_labels(bb);
    if i = nil then
      goto 1;
    if not (instruction_attributes[i^.opc].class in post_jumps) then
      goto 1;
    first := i;
    i := first;
    next_bundle(i, last);
    if (i = nil) and (last <> first) then begin
      if odd(first^.h.modify) then
        bug_check('POST_$BRANCH_SHADOW_TRUE -- unconditional jump shadow is not .sf%$');
      shadow := get_needed_inst(first^.next);
      shlast := last;
    end
    else begin
      if i = nil then
        goto 1;
      if last <> first then
        goto 1;
      if not odd(first^.h.modify) then
        goto 1;
      shadow := i;
      next_bundle(i, shlast);
      if i <> nil then
        goto 1;
    end;
    if at_backend_switches.sw12 then
      goto 1;
    trace_message('This block is nearly empty');
    prevedge := nil;
    e := bb^.preds;
    while e <> nil do begin
      enext := e^.next_pred;
      src := e^.source;
      keep := src^.f.hidden_successor_edges
              or (src^.f14.kind = ord(block$start));
      d6 := get_needed_inst(post_bb_v_ptr_t(src)^.ctl);
      a2 := nil;
      while d6 <> nil do begin
        d7 := d6;
        next_bundle(d6, last);
        if (d7^.opnds[1].h.kind = operand$flow_graph_edge)
           and (d7^.opnds[1].ptr = e) then begin
          if (d7^.h.modify <> 2) or at_backend_switches.sw10 then
            goto 3;
          if first^.opnds[1].h.kind = operand$flow_graph_edge then
            if fg_edge_ptr_t(first^.opnds[1].ptr)^.target = src^.next then
              goto 3;
          if fg_edge_ptr_t(first^.opnds[1].ptr)^.target = bb then
            goto 3;
          if d6 <> nil then begin
            if d6^.opc = ord(opc$jump) then begin
              if d6^.opnds[1].h.kind = operand$flow_graph_edge then
                if fg_edge_ptr_t(d6^.opnds[1].ptr)^.target^.f.depth
                   > bb^.f.depth then
                  goto 3;
            end
            else if src^.f.depth > bb^.f.depth then
              goto 3;
          end
          else if a2 <> nil then
            if instruction_attributes[a2^.opc].class in [class$branch,
                                                         class$fp_branch] then
              if a2^.h.modify = 2 then
                if a2^.opnds[1].h.kind = operand$flow_graph_edge then
                  if fg_edge_ptr_t(a2^.opnds[1].ptr)^.target = src^.next then
                    if src^.next^.f.depth > bb^.f.depth then
                      goto 3;
          d7^.h.modify := 1;
          d7^.opnds[1] := first^.opnds[1];
          if d7^.opnds[1].h.kind = operand$flow_graph_edge then
            d7^.opnds[1].ptr := lir_$add_flow_graph_edge(src,
                fg_edge_ptr_t(first^.opnds[1].ptr)^.target)
          else begin
            tb := first^.bb;
            if tb^.f.hidden_successor_edges then begin
              se := tb^.succs;
              while se <> nil do begin
                src^.f.hidden_successor_edges := true;
                discard(lir_$add_flow_graph_edge(src, se^.target));
                se := se^.next_succ;
              end;
            end;
          end;
          c := shadow;
4:
          size := ((c^.h.nopnds + 1) * 12) + 32;
          new := mrh_$alloc(post_heap, size);
          dst := univ_ptr(new);
          srcp := univ_ptr(c);
          k := 1;
          while size > 0 do begin
            dst^[k] := srcp^[k];
            k := k + 1;
            size := size - 4;
          end;
          if instruction_attributes[new^.opc].class
             in [class$call, class$entry, class$enable, class$seq,
                 class$synch, class$limit, class$trap, class$load_pair,
                 class$load, class$svc, class$store, class$mfpr,
                 class$mtpr, class$return, class$trap_cond] then
            new^.h.b2_7 := false;
          a3 := last;
          new^.next := a3^.next;
          a3^.next := new;
          if new^.next = nil then
            src^.last := new
          else
            new^.next^.prev := new;
          new^.prev := a3;
          last := new;
          if shlast <> c then begin
            c := get_needed_inst(c^.next);
            goto 4;
          end;
          goto 5;
3:
          keep := true;
          trace_message('Not really creating ".ST" branch');
        end;
5:
        a2 := d7;
      end;
      if not keep then begin
        i := flush_labels(src);
        while i <> nil do begin
          a2 := i;
          next_bundle(i, last);
          if instruction_attributes[a2^.opc].class = class$call then
            for k := 3 to a2^.h.nopnds do
              if a2^.opnds[k].h.kind = operand$flow_graph_edge then
                if a2^.opnds[k].ptr = e then
                  keep := true;
        end;
        if not keep then begin
          trace_message('Removing the edge');
          se := nil;
          ed := src^.succs;
          while ed <> nil do begin
            if ed = e then
              goto 6;
            se := ed;
            ed := ed^.next_succ;
          end;
6:
          if se = nil then
            src^.succs := e^.next_succ
          else
            se^.next_succ := e^.next_succ;
          if prevedge = nil then
            bb^.preds := enext
          else
            prevedge^.next_pred := enext;
          goto 7;
        end;
      end;
      prevedge := e;
7:
      e := enext;
    end;
    if bb^.preds = nil then begin
      i := get_needed_inst(bb^.first);
      while i <> nil do begin
        if instruction_attributes[i^.opc].class <> class$label then
          goto 8;
        if i^.h.modify >= 2 then
          goto 1;
        i := get_needed_inst(i^.next);
      end;
8:
      flush_this_block(post_rtn, bb);
    end;
1:
    trace_block_exit;
    bb := nxtbb;
  end;
  trace_pass_finish;
end;

{ post_$sequential_flow - a block's transfers simplified where its code
  falls through to the next block: an unconditional jump to the next
  block dropped (its shadow, of mode 1 or 3, kept in the block), an
  IPCCNOP after a jump of mode 3 grouped with it (mode 0); a conditional
  branch to the next block followed by a jump reversed to go where the
  jump went and the jump dropped ("Bcc goes to next block"); a
  conditional branch (mode 0) followed by a jump that leaves the
  branch's interval (or through an integer register) while the branch
  stays in it: the two exchanged ("Swapping Bcc with JUMP"; a jump of
  mode 1 makes the branch mode 1 and the jump's shadow follows).  A
  block whose last transfer was removed is marked sequential_flow_out.

  0x2656B4, 0x536 bytes, no A5 (internal): the blocks from the last
  (+72) through +114; the branch reversed by its opcode's low bit
  (`bchg #0,(21,A4)'); the shadow mode's two bits exchanged field by
  field (`smi', `sne'); the labels as the image's branch targets. }

procedure post_$sequential_flow; options(internal);
label 1, 2, 3, 4, 5, 6, 7;
var
  bb, prevbb, head: bb_ptr_t;
  i, br, last, b, nx, jmp, jlast, x, x3: instr_ptr_t;
  drop: boolean;
  tmp: opnd_t;
  m: integer;
begin
  trace_pass_start('POST_$SEQUENTIAL_FLOW', 21);
  bb := post_rtn^.bbs72;
  while bb <> nil do begin
    trace_block_entry(bb);
    prevbb := bb^.next114;
    i := flush_labels(bb);
    br := nil;
    while i <> nil do begin
      if instruction_attributes[i^.opc].class in post_transfers then begin
        br := i;
        b := i;
        next_bundle(b, last);
        goto 2;
      end;
      b := i;
      next_bundle(b, x);
      i := b;
    end;
2:
    if br = nil then
      goto 1;
    nx := get_needed_inst(last^.next);
3:
    drop := droppable_jump_addr(br, bb);
    if instruction_attributes[br^.opc].class in post_jumps then begin
      if drop then begin
        if odd(br^.h.modify) then begin
          if nx = nil then
            bug_check('POST_$SEQUENTIAL_FLOW -- JUMP.SA has no shadow%$');
        end
        else if nx <> nil then
          goto 1;
        trace_message('Goes to next block, dropping it');
        if br^.next <> nil then
          br^.next^.prev := br^.prev
        else
          bb^.last := br^.prev;
        if br^.prev <> nil then
          br^.prev^.next := br^.next
        else
          bb^.first := br^.next;
        goto 4;
      end;
      if br^.h.modify = 3 then
        if br^.next^.opc = ord(opc$ipccnop) then
          if not br^.next^.h.grouped then begin
            br^.h.modify := 0;
            br^.h.grouped := true;
          end;
      goto 5;
    end;
    if nx = nil then begin
      if odd(br^.h.modify) then
        bug_check('POST_$SEQUENTIAL_FLOW -- Bcc.ST has no shadow%$');
      goto 5;
    end;
    if odd(br^.h.modify) then begin
      if instruction_attributes[nx^.opc].class in post_transfers then
        goto 1;
      b := nx;
      next_bundle(b, x);
      nx := b;
    end
    else if br^.h.modify < 2 then
      bug_check('POST_$SEQUENTIAL_FLOW -- Bcc.SN%$');
    if drop then begin
      if nx = nil then
        goto 1;
      if not (instruction_attributes[nx^.opc].class in post_jumps) then
        goto 1;
      jmp := nx;
      b := nx;
      next_bundle(b, jlast);
      nx := b;
      if odd(jmp^.h.modify) then begin
        if nx = nil then
          bug_check('POST_$SEQUENTIAL_FLOW -- JUMP.ST has no shadow%$');
        if odd(br^.h.modify) then begin
          nx := jmp;
          goto 6;
        end;
        if jlast <> jmp then
          goto 1;
        b := nx;
        next_bundle(b, x);
        nx := b;
      end
      else if odd(br^.h.modify) and (jlast <> jmp) then
        goto 1;
      if nx <> nil then
        goto 1;
      trace_message('Bcc goes to next block, swapping it with JUMP');
      br^.opnds[1] := jmp^.opnds[1];
      br^.opc := xor(br^.opc, 1);
      if odd(jmp^.h.modify) or odd(br^.h.modify) or (jlast <> jmp) then begin
        m := br^.h.modify;
        br^.h.modify := (m div 2) + (m & 1) * 2;
      end;
      if jmp^.next <> nil then
        jmp^.next^.prev := jmp^.prev
      else
        bb^.last := jmp^.prev;
      if jmp^.prev <> nil then
        jmp^.prev^.next := jmp^.next
      else
        bb^.first := jmp^.next;
      goto 4;
    end;
    if nx = nil then
      goto 6;
    if not (instruction_attributes[nx^.opc].class in post_jumps) then
      goto 6;
    if odd(br^.h.modify) then
      goto 6;
    if droppable_jump_addr(nx, bb) then
      goto 6;
    head := interval_of_basic_block(bb);
    if head = nil then begin
      if nx^.opnds[1].h.kind = operand$ip_reg then
        goto 7;
      goto 6;
    end;
    if interval_of_target_operand(addr(br^.opnds[1])) = head then
      goto 6;
    if interval_of_target_operand(addr(nx^.opnds[1])) = head then
      goto 7;
    goto 6;
4:
    bb^.f.sequential_flow_out := true;
    goto 1;
5:
    if nx = nil then
      goto 1;
    if odd(br^.h.modify) then begin
      if instruction_attributes[nx^.opc].class in post_transfers then
        goto 1;
      b := nx;
      next_bundle(b, x);
      nx := b;
    end;
6:
    if nx = nil then
      goto 1;
    if not (instruction_attributes[nx^.opc].class in post_transfers) then
      goto 1;
    br := nx;
    b := nx;
    next_bundle(b, last);
    nx := b;
    goto 3;
7:
    jmp := nx;
    b := nx;
    next_bundle(b, jlast);
    nx := b;
    if jlast <> jmp then
      goto 1;
    if odd(jmp^.h.modify) then begin
      if nx = nil then
        bug_check('POST_$SEQUENTIAL_FLOW -- JUMP.ST has no shadow%$');
      b := nx;
      next_bundle(b, x3);
      nx := b;
    end
    else if odd(br^.h.modify) and (jlast <> jmp) then
      goto 1;
    if nx <> nil then
      goto 1;
    trace_message('Swapping Bcc with JUMP');
    tmp := br^.opnds[1];
    br^.opnds[1] := jmp^.opnds[1];
    jmp^.opnds[1] := tmp;
    br^.opc := xor(br^.opc, 1);
    if odd(jmp^.h.modify) then begin
      br^.h.modify := 1;
      jmp^.h.modify := 2;
      swap_bundles(jmp, jlast, x3, bb);
    end;
1:
    trace_block_exit;
    bb := prevbb;
  end;
  trace_pass_finish;
end;

{ post_$new_bb_for_shadow_true - a block with a conditional branch of
  mode 1 (.ST) split after it: the branch's shadow bundle starts a new
  block (falling through, sequential_flow_out), and what follows the
  shadow another; the edges rebuilt (the branch's from the shadow's
  block, the transfers' from theirs), the hidden edges copied, both
  first blocks marked as hiding edges.

  0x265D18, 0x334 bytes, no A5 (internal). }

procedure post_$new_bb_for_shadow_true; options(internal);
label 1, 2, 3;
var
  bb, nb, rb: bb_ptr_t;
  i, a2, br, x, shlast, rest: instr_ptr_t;
  old: fg_edge_ptr_t;
begin
  trace_pass_start('POST_$NEW_BB_FOR_SHADOW_TRUE', 28);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    br := nil;
    while i <> nil do begin
      trace_instruction(i);
      a2 := i;
      next_bundle(i, x);
      if instruction_attributes[a2^.opc].class in [class$branch,
                                                   class$fp_branch] then
        if a2^.h.modify = 1 then begin
          br := a2;
          goto 2;
        end;
    end;
2:
    if br = nil then
      goto 1;
    if i = nil then
      bug_check('POST_$NEW_BB_FOR_SHADOW_TRUE -- JUMP.ST has no shadow%$');
    a2 := i;
    next_bundle(i, shlast);
    rest := i;
    nb := lir_$new_basic_block;
    nb^.next114 := bb;
    if bb^.next = nil then
      post_rtn^.bbs72 := nb
    else
      bb^.next^.next114 := nb;
    nb^.f.sequential_flow_out := true;
    nb^.next := bb^.next;
    bb^.next := nb;
    nb^.last := bb^.last;
    bb^.last := a2^.prev;
    nb^.first := a2;
    a2^.prev^.next := nil;
    a2^.prev := nil;
    rb := nil;
    if rest <> nil then begin
      rb := lir_$new_basic_block;
      rb^.next114 := nb;
      if nb^.next = nil then
        post_rtn^.bbs72 := rb
      else
        nb^.next^.next114 := rb;
      rb^.f.sequential_flow_out := bb^.f.sequential_flow_out;
      rb^.next := nb^.next;
      nb^.next := rb;
      rb^.last := nb^.last;
      nb^.last := rest^.prev;
      rb^.first := rest;
      rest^.prev^.next := nil;
      rest^.prev := nil;
      if bb^.f.sequential_flow_out then
        discard(lir_$add_flow_graph_edge(rb, rb^.next));
    end;
    bb^.f.sequential_flow_out := true;
    old := bb^.succs;
    delete_successor_list(bb);
    discard(lir_$add_flow_graph_edge(bb, nb));
    if rb <> nil then
      discard(lir_$add_flow_graph_edge(bb, rb))
    else
      discard(lir_$add_flow_graph_edge(bb, nb^.next));
    if br^.opnds[1].h.kind = operand$flow_graph_edge then
      br^.opnds[1].ptr := lir_$add_flow_graph_edge(nb,
          fg_edge_ptr_t(br^.opnds[1].ptr)^.target);
    a2 := flush_labels(bb);
    while a2 <> nil do begin
      if a2 = br then
        goto 3;
      if instruction_attributes[a2^.opc].class in post_transfers then
        if a2^.opnds[1].h.kind = operand$flow_graph_edge then
          a2^.opnds[1].ptr := lir_$add_flow_graph_edge(bb,
              fg_edge_ptr_t(a2^.opnds[1].ptr)^.target);
      next_bundle(a2, x);
    end;
3:
    if bb^.f.hidden_successor_edges then
      rebuild_successor_list(bb, old);
    if rb <> nil then begin
      a2 := get_needed_inst(rb^.first);
      while a2 <> nil do begin
        if instruction_attributes[a2^.opc].class in post_transfers then
          if a2^.opnds[1].h.kind = operand$flow_graph_edge then
            a2^.opnds[1].ptr := lir_$add_flow_graph_edge(rb,
                fg_edge_ptr_t(a2^.opnds[1].ptr)^.target);
        next_bundle(a2, x);
      end;
      if rb^.f.hidden_successor_edges then
        rebuild_successor_list(rb, old);
    end;
    bb^.f.hidden_successor_edges := true;
    nb^.f.hidden_successor_edges := true;
1:
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ post_$isolate_unneeded - each block's list rebuilt from its first
  instruction: the odd halves of combined pairs (LOADSO, STORESO)
  dropped, the physical moves (PMOVE, PMOVEI, PCOPYS, PCOPYD) held back
  until the bundle they are in ends.

  0x2660A0, 0xFA bytes, no A5 (internal): the previous links not
  rebuilt. }

procedure post_$isolate_unneeded; options(internal);
var
  bb: bb_ptr_t;
  head, tail, phead, ptail, i, nx: instr_ptr_t;
  ended: boolean;
begin
  trace_pass_start('POST_$ISOLATE_UNNEEDED', 22);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    head := nil;
    phead := nil;
    tail := head;
    ended := true;
    i := bb^.first;
    while i <> nil do begin
      trace_instruction(i);
      nx := i^.next;
      case i^.opc of
        ord(opc$storeso), ord(opc$loadso):
          ;
        ord(opc$pcopyd), ord(opc$pcopys), ord(opc$pmovei), ord(opc$pmove):
          begin
            if phead = nil then
              phead := i
            else
              ptail^.next := i;
            ptail := i;
          end;
        otherwise begin
          if head = nil then
            head := i
          else
            tail^.next := i;
          tail := i;
          ended := not i^.h.grouped;
        end;
      end;
      if phead <> nil then
        if ended then begin
          if head = nil then
            head := phead
          else
            tail^.next := phead;
          tail := ptail;
          phead := nil;
        end;
      i := nx;
    end;
    bb^.first := head;
    bb^.last := tail;
    if tail <> nil then
      tail^.next := nil;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ emergency_nop - a NOP (reg negative) or a SHIFTNOP reading and writing
  integer register reg put before or after anchor in bb.

  0x2661B0, 0x72 bytes. }

procedure emergency_nop(
    bb: bb_ptr_t;
    anchor: instr_ptr_t;
    reg: integer32;
    after: boolean); options(val_param, internal);
var
  opc: integer;
  i: instr_ptr_t;
begin
  if reg < 0 then
    opc := ord(opc$nop)
  else
    opc := ord(opc$shiftnop);
  i := insert_instruction(opc, bb, anchor, after);
  if reg >= 0 then begin
    i^.opnds[1].h.kind := operand$ip_reg;
    opnd_bytes_ptr_t(addr(i^.opnds[1]))^.rrp := 16;
    i^.opnds[1].h.num := reg;
    i^.opnds[2].h.kind := operand$ip_reg;
    opnd_bytes_ptr_t(addr(i^.opnds[2]))^.rrp := 8;
    i^.opnds[2].h.num := reg;
  end;
end;

{ get_safe_instr - i moved past the bundles of entries, labels, branches,
  pmoves and the like.

  0x266222, 0x6A bytes. }

procedure get_safe_instr(
    var i: instr_ptr_t); options(val_param, internal);
label 9;
var
  x: instr_ptr_t;
begin
  if i <> nil then
    while instruction_attributes[i^.opc].class
          in [class$branch, class$entry, class$fp_branch, class$jump,
              class$seq, class$limit, class$pmove, class$label,
              class$join_bp] do begin
      next_bundle(i, x);
      if i = nil then
        goto 9;
    end;
9:
end;

{ post_$fix_pos_bug - a SHIFTNOP of the register put before a shift or
  field instruction (ASR .. EXTRACTU) whose second operand is the
  integer register the instruction before loaded (any register at a
  block's start, unless it follows its only predecessor in code order,
  and after a call); the fixes counted (post_pos_count).

  0x26628C, 0x224 bytes, no A5 (internal): the opcodes a constant set
  after the routine (`btst' of 0x2664C2, the elements 111..0: pattern
  102); the registers a 30-bit set (integer registers 0..29); the
  results' loop counter in D4, the saved set's register, as the image
  has it. }

procedure post_$fix_pos_bug; options(internal);
var
  bb: bb_ptr_t;
  i, x: instr_ptr_t;
  restart, in_shadow: boolean;
  loaded, saved: bv_word_t;
  k, n: integer32;
  reg: integer;
begin
  trace_pass_start('POST_$FIX_POS_BUG', 17);
  restart := true;
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    get_safe_instr(i);
    if bb^.preds = nil then
      restart := true
    else if bb^.preds^.next_pred <> nil then
      restart := true
    else if bb^.preds^.source <> bb^.next114 then
      restart := true;
    while i <> nil do begin
      trace_instruction(i);
      if restart then begin
        loaded := bv_word_t(16#3FFFFFFF);
        restart := false;
        saved := loaded;
      end;
      in_shadow := false;
      if instruction_attributes[i^.opc].class = class$call then begin
        restart := true;
        if i^.h.modify >= 2 then begin
          next_bundle(i, x);
          in_shadow := restart;
        end;
      end;
      if i^.opc in [ord(opc$asr)..ord(opc$extractu)] then
        if i^.opnds[2].h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                  operand$ip_reg_like,
                                  operand$case_jump_base] then
          if i^.opnds[2].h.num <= 31 then
            if i^.opnds[2].h.num in loaded then begin
              if in_shadow then
                bug_check('POST_$FIX_POS_BUG -- SHIFTNOP inserted in CALL shadow%$');
              post_pos_count := post_pos_count + 1;
              emergency_nop(bb, i, i^.opnds[2].h.num, false);
            end;
      loaded := saved;
      n := instruction_attributes[i^.opc].nresults;
      for k := 1 to n do
        if i^.opnds[k].h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                  operand$ip_reg_like,
                                  operand$case_jump_base] then
          loaded := loaded - [i^.opnds[k].h.num];
      if (instruction_attributes[i^.opc].class = class$load)
         and (i^.opnds[3].h.kind in [operand$ip_reg, operand$ip_reg_physical,
                                     operand$ip_reg_like,
                                     operand$case_jump_base]) then begin
        saved := [i^.opnds[3].h.num];
        loaded := loaded + saved;
      end
      else
        saved := [];
      next_bundle(i, x);
      get_safe_instr(i);
    end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ post_$fix_ldcc_bug - a NOP put before a load that sets the condition
  codes after a memory access of another size (a load pair counts as
  size 4), unless the access before was a SYNCH, which then becomes the
  SYNCHB, SYNCHW or SYNCH of the load's size; the state forgotten after
  a call (or its shadow) and at a block reached from a block that ends
  with a call, svc, synch or memory access ("tainted", +19 bit 1); the
  fixes counted (post_ldcc_count).

  0x266508, 0x2A0 bytes, no A5 (internal): the size -1 for none, -2 for
  unknown; the access size instruction_attributes' +19 bits 2..0. }

procedure post_$fix_ldcc_bug; options(internal);
label 0, 1, 2;
var
  bb: bb_ptr_t;
  i, x, prev_mem: instr_ptr_t;
  tainted, nop, after_call: boolean;
  size: integer32;
  e: fg_edge_ptr_t;
  cls: integer;
begin
  trace_pass_start('POST_$FIX_LDCC_BUG', 18);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    tainted := true;
    i := flush_labels(bb);
    while i <> nil do begin
      cls := instruction_attributes[i^.opc].class;
      if cls in [class$call, class$synch, class$load_pair, class$load,
                 class$svc, class$store] then
        tainted := true
      else if cls in [class$alu, class$fp_double, class$enable,
                      class$immediate, class$synch, class$fp_control,
                      class$ipccnop, class$trap, class$fp_single,
                      class$mfpr, class$mtpr, class$trap_cond] then
        tainted := false;
      next_bundle(i, x);
    end;
    if tainted then begin
      e := bb^.succs;
      while e <> nil do begin
        e^.target^.f.b19_1 := true;
        e := e^.next_succ;
      end;
    end;
    trace_block_exit;
    bb := bb^.next;
  end;
  size := -2;
  after_call := false;
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    if bb^.f.b19_1 then begin
      trace_message('This block is tainted!');
      size := -2;
    end;
    bb^.f.b19_1 := false;
    i := flush_labels(bb);
    prev_mem := nil;
    while i <> nil do begin
      trace_instruction(i);
      cls := instruction_attributes[i^.opc].class;
      if not (cls in post_not_stealable) then begin
        if cls in [class$load_pair, class$load] then
          if size <> -1 then
            if i^.h.sets_cc then begin
              nop := false;
              if cls = class$load_pair then begin
                if size <> 4 then
                  nop := true;
              end
              else if (instruction_attributes[i^.opc].w18 & 7) <> size then
                if prev_mem <> nil then
                  if instruction_attributes[prev_mem^.opc].class
                     = class$synch then
                    case instruction_attributes[i^.opc].w18 & 7 of
                      0: prev_mem^.opc := ord(opc$synchb);
                      1: prev_mem^.opc := ord(opc$synchw);
                      2: prev_mem^.opc := ord(opc$synch);
                      otherwise
                        nop := true;
                    end
                  else
                    nop := true
                else
                  nop := true;
              if nop then begin
                post_ldcc_count := post_ldcc_count + 1;
                emergency_nop(bb, i, -1, false);
              end;
            end;
        size := -1;
        prev_mem := nil;
        if cls in [class$synch, class$load_pair, class$load,
                   class$store] then begin
          if cls = class$load_pair then
            size := 4
          else
            size := instruction_attributes[i^.opc].w18 & 7;
          prev_mem := i;
        end;
        if after_call then begin
          size := -2;
          after_call := false;
        end;
        if cls = class$call then
          if i^.h.modify <> 0 then
            after_call := true
          else
            size := -2;
      end;
      next_bundle(i, x);
    end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ mem_ref_then_call_infected_on_exit - the integer register a block's
  last significant instruction (past grouped instructions, branches,
  jumps, limits, pmoves, returns) reaches memory through as a store's
  first or a load's third operand: a set of it, empty for another
  instruction, the integer registers 0..29 for an empty block.

  0x2667A4, 0xBE bytes: the set in D0. }

function mem_ref_then_call_infected_on_exit(
    bb: bb_ptr_t): bv_word_t; options(val_param, internal);
label 9;
var
  res: bv_word_t;
  i: instr_ptr_t;
  op: opnd_ptr_t;
begin
  res := bv_word_t(16#3FFFFFFF);
  i := bb^.last;
  while i <> nil do begin
    if ((i^.prev <> nil) and i^.prev^.h.grouped)
       or (instruction_attributes[i^.opc].class
           in [class$branch, class$fp_branch, class$jump, class$limit,
               class$pmove, class$return]) then
      i := get_prev_needed_inst(i^.prev)
    else begin
      if instruction_attributes[i^.opc].class = class$store then
        op := addr(i^.opnds[1])
      else if instruction_attributes[i^.opc].class = class$load then
        op := addr(i^.opnds[3])
      else
        op := nil;
      if op <> nil then
        if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                          operand$ip_reg_like, operand$case_jump_base] then
          res := [op^.h.num]
        else
          res := []
      else
        res := [];
      goto 9;
    end;
  end;
9:
  mem_ref_then_call_infected_on_exit := res;
end;

{ post_$fix_mem_ref_then_call_bug - a call through an integer register
  (its second operand) that the instruction before used to reach memory
  (a store's first, a load's third operand; at a block's head, any
  predecessor's last such instruction): the call's shadow of mode 3
  moved before it (mode 0), otherwise a NOP put before the call.

  0x266862, 0x262 bytes, no A5 (internal): the set after a call the
  registers 0..29 less its own (a code constant 0x3FFFFFFF, `not.l;
  and.l'). }

procedure post_$fix_mem_ref_then_call_bug; options(internal);
var
  bb: bb_ptr_t;
  i, b, x, sh, sl, p, n: instr_ptr_t;
  regs: bv_word_t;
  conf: post_conf_t;
  shadowed: boolean;
  e: fg_edge_ptr_t;
  cls: integer;
begin
  trace_pass_start('POST_$FIX_MEM_REF_THEN_CALL_BUG', 31);
  bb := post_rtn^.bbs;
  while bb <> nil do begin
    trace_block_entry(bb);
    i := flush_labels(bb);
    if (i <> nil) and (instruction_attributes[i^.opc].class = class$call)
    then begin
      regs := [];
      e := bb^.preds;
      while e <> nil do begin
        regs := regs + mem_ref_then_call_infected_on_exit(e^.source);
        e := e^.next_pred;
      end;
    end
    else
      regs := bv_word_t(16#3FFFFFFF);
    shadowed := false;
    while i <> nil do begin
      trace_instruction(i);
      cls := instruction_attributes[i^.opc].class;
      if cls = class$call then begin
        if i^.opnds[2].h.num <= 31 then
          if i^.opnds[2].h.num in regs then
            if i^.h.modify = 3 then begin
              b := i;
              discard(pass_bundle(b, x, 0, addr(conf)));
              sh := b;
              x := sh;
              discard(pass_bundle(x, sl, 0, addr(conf)));
              p := sh^.prev;
              n := sl^.next;
              p^.next := n;
              if n = nil then
                bb^.last := sh^.prev
              else
                n^.prev := sh^.prev;
              sh^.prev := i^.prev;
              if sh^.prev = nil then
                bb^.first := sh
              else
                sh^.prev^.next := sh;
              sl^.next := i;
              i^.prev := sl;
              i^.h.modify := 0;
            end
            else
              emergency_nop(bb, i, -1, false);
        regs := bv_word_t(16#3FFFFFFF) - [i^.opnds[2].h.num];
        shadowed := i^.h.modify = 3;
      end
      else if (cls = class$store)
              and (i^.opnds[1].h.kind in [operand$ip_reg,
                       operand$ip_reg_physical, operand$ip_reg_like,
                       operand$case_jump_base])
              and not shadowed then begin
        regs := [i^.opnds[1].h.num];
        shadowed := false;
      end
      else if (cls = class$load)
              and (i^.opnds[3].h.kind in [operand$ip_reg,
                       operand$ip_reg_physical, operand$ip_reg_like,
                       operand$case_jump_base])
              and not shadowed then begin
        regs := [i^.opnds[3].h.num];
        shadowed := false;
      end
      else if not (cls in [class$branch, class$entry, class$fp_branch,
                           class$jump, class$seq, class$limit,
                           class$pmove, class$label,
                           class$join_bp]) then begin
        regs := [];
        shadowed := false;
      end;
      b := i;
      discard(pass_bundle(b, x, 0, addr(conf)));
      i := b;
    end;
    trace_block_exit;
    bb := bb^.next;
  end;
  trace_pass_finish;
end;

{ POST_$BEGIN_COMPILATION - post's heap made, the counts cleared.

  0x266AE8, 0x36 bytes: mrh_$initialize's flags and default size one
  longword (pattern 105). }

procedure post_$begin_compilation;
begin
  mrh_$initialize(post_heap, 1, 0, 'post instruction heap%');
  post_pos_count := 0;
  post_ldcc_count := 0;
end;

{ POST_$PROCESS_ROUTINE - the POST phase: bit vectors of the registers
  (100 bits; seven vectors a block for FORTRAN, whose floating
  exceptions need availability too, four otherwise), post_$initialize,
  FPQUIESCEs where needed, then the scheduling into the IPCCNOPs and
  shadows (not with sw15), the hardware corrections (the POS, LDCC and
  memory-reference-then-call bugs), and the flow graph's tidying.

  0x266B34, 0x106 bytes: the language from runbackend_14 (5 FORTRAN:
  `btst' in the constant 32); the switches' level stored, never read. }

procedure post_$process_routine(
    rtn: rtn_ptr_t);
var
  avail, found: boolean;
begin
  post_rtn := rtn;
  post_minimal := at_backend_switches.sw15;
  post_level := at_backend_switches.level;
  if runbackend_14 in [5] then begin
    bv_$initialize_bit_vectors(rtn, post_nregs, 7, true);
    avail := true;
  end
  else begin
    bv_$initialize_bit_vectors(rtn, post_nregs, 4, true);
    avail := false;
  end;
  post_$initialize(avail, found);
  if found then
    post_$sprinkle_fpquiesce;
  if avail then
    bv_$release_availability_bit_vectors(rtn);
  if not post_minimal then begin
    post_$reschedule_spill_loads;
    post_$sprinkle_mfnextcc;
    post_$fill_ipccnop;
  end;
  post_$fix_pos_bug;
  post_$fix_ldcc_bug;
  if not post_minimal then begin
    post_$call_shadows;
    post_$branch_shadow_always;
  end;
  post_$fix_mem_ref_then_call_bug;
  bv_$release_bit_vectors(rtn);
  post_$forward_empty_block;
  if not post_minimal then begin
    post_$rotate_loop_header;
    post_$split_back_edge_target;
    post_$branch_shadow_true;
  end;
  post_$sequential_flow;
  if not post_minimal then
    post_$new_bb_for_shadow_true;
  post_$isolate_unneeded;
end;

{ POST_$END_ROUTINE - post's heap released.

  0x266C3A, 0x1C bytes. }

procedure post_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(post_heap);
end;

{ POST_$END_COMPILATION - nothing.

  0x266C56, 0x2 bytes (no A5). }

procedure post_$end_compilation;
begin
end;
