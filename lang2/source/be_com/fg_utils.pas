{ fg_utils - the flow graph's utilities (cc.a88k only): blocks dropped
  and forwarded, the successor lists ordered, depth-first numbering,
  intervals and loop headers, empty blocks and senseless loops, the
  dominators, join birthpoints (the SSA form of a live range) put in
  and dropped.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x234980  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x2349A2  fg_utils_$begin_compilation
    --------  0x234A46  fg_utils_$init_for_routine
    --------  0x234A74  fg_utils_$end_routine
    --------  0x234A92  fg_utils_$end_compilation
    --------  0x234A94  n_edges (internal)
    --------  0x234AB8  fg_utils_$drop_this_block
    --------  0x234C3C  fg_utils_$forward_this_block
    A5 0x48646C: the module's data: three heaps (+0 the join
    birthpoint instructions', +24 their inputs', +48 the dominator
    buckets'), then the cells the routines below use.

  TODO(pascal) fg_utils: 8 of 53 routines (the first ones in address
  order); from order_successor_lists (0x2350BE) on not translated yet:
  order_successor_lists, add_final_edges, depth_first_search,
  final_edge_fixup, reorder_start_bb_successor_list,
  fg_utils_$compute_dfs_lists, in_interval, loop_entry_is_conditional,
  visit_interval_contents, fg_utils_$intervals,
  fg_utils_$separate_loop_header_edges, an_exit_has_multiple_successors,
  build_exit, copy_bb_contents, build_loop_header, n_instrs,
  every_interval_block_exits, make_loops_unconditional,
  fg_utils_$make_loops_unconditional, fg_utils_$forward_empty_blocks,
  fg_utils_$end_senseless_loops, reverse_depth_first_search, compress,
  eval, evaldef, compute_rel, replace_exposed_lts,
  fg_utils_$generate_join_birthpoint, fg_utils_$insert_join_birthpoint,
  traverse, fg_utils_$add_jbi, add_join_birthpoint_inputs,
  fg_utils_$dominators, drop_jbis_on_exposed_list,
  drop_unconsumed_exposed_segments, drop_unconsumed_final_segments,
  fg_utils_$drop_old_join_birthpoints, fg_utils_$recompute_postnum,
  fg_utils_$recompute_dominators_and_dfs_lists, mark_live_on_entry_blocks,
  mark_active_on_exit_blocks, init_and_compute_exposure,
  fg_utils_$compute_lr_lifetime, compute_reach_of_definition,
  fg_utils_$recompute_ssa_form_for_lr (they stay extern through
  backend.ins.pas meanwhile).

  Not known from the original: every local and parameter name, the
  module variables' names. }

module fg_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

var
  jbi_heap: mrh_$heap_t;                { +0: the join birthpoint
                                          instructions }
  jbi_input_heap: mrh_$heap_t;          { +24: their inputs (ut_jbi_t) }
  bucket_heap: mrh_$heap_t;             { +48: the dominator buckets }
  fg_72: integer32;                     { +72 }
  fg_76: integer32;                     { +76 }
  fg_80: integer;                       { +80 }
  fg_82: integer;                       { +82 }
  fg_84: integer32;                     { +84 }
  fg_88: integer32;                     { +88 }
  fg_92: integer;                       { +92 }
  fg_94: boolean;                       { +94: set for each routine }
  fg_95: char;                          { +95 }
  fg_96: boolean;                       { +96: set for each routine }

{ fg_utils_$begin_compilation - the three heaps made.

  0x2349A2, 0x52 bytes: flags and default size pushed as one longword
  (pattern 105). }

procedure fg_utils_$begin_compilation;
begin
  mrh_$initialize(bucket_heap, 0, 16, 'dominator bucket heap%');
  mrh_$initialize(jbi_input_heap, 0, 16, 'join_birthpoin_input heap%');
  mrh_$initialize(jbi_heap, 1, 0, 'join birthpoint instruction heap%');
end;

{ fg_utils_$init_for_routine - the join birthpoint instructions' heap
  emptied, +94 and +96 set, lir_main_c8e (definitions may be located)
  cleared.

  0x234A46, 0x2E bytes. }

procedure fg_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(jbi_heap);
  fg_96 := true;
  fg_94 := true;
  lir_main_c8e := false;
end;

{ fg_utils_$end_routine - the join birthpoint inputs' heap emptied.

  0x234A74, 0x1E bytes. }

procedure fg_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(jbi_input_heap);
end;

{ fg_utils_$end_compilation - nothing.

  0x234A92, 0x2 bytes, no A5. }

procedure fg_utils_$end_compilation;
begin
end;

{ n_edges - the edges on the list from e, chained at next_succ when succ
  else at next_pred.

  0x234A94, 0x24 bytes, no frame: e (4), succ (8) a byte. }

function n_edges(
    e: fg_edge_ptr_t;
    succ: boolean): integer32; options(val_param, internal);
var
  n: integer32;
begin
  n := 0;
  while e <> nil do begin
    n := n + 1;
    if succ then
      e := e^.next_succ
    else
      e := e^.next_pred;
  end;
  n_edges := n;
end;

{ fg_utils_$drop_this_block - bb taken out of the flow graph: its edges
  in off their sources' lists of edges out, its edges out off their
  targets' lists of edges in; after phase 1 out of the code order
  (next, next114: the routine's +76 and +72 the ends) and the chains at
  l54/l58 relinked round it; out of its interval head's list of members
  (the head's l74, or the routine's l84 without a head, chained at
  l78); the routine's block count down; bb marked forwarded.

  0x234AB8, 0x184 bytes: rtn (8) in D1, bb (12) in D0; the code order's
  second test on the flags of the store of bb's next (pattern 111). }

procedure fg_utils_$drop_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t);
var
  e: fg_edge_ptr_t;
  next: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  src: bb_ptr_t;
  p: bb_ptr_t;
  h: bb_ptr_t;
begin
  e := bb^.preds;
  while e <> nil do begin
    next := e^.next_pred;
    src := e^.source;
    prev := nil;
    f := src^.succs;
    while (f <> nil) and (f <> e) do begin
      prev := f;
      f := f^.next_succ;
    end;
    if f <> nil then
      if prev = nil then
        src^.succs := f^.next_succ
      else
        prev^.next_succ := f^.next_succ;
    e := next;
  end;
  e := bb^.succs;
  while e <> nil do begin
    next := e^.next_succ;
    src := e^.target;
    prev := nil;
    f := src^.preds;
    while (f <> nil) and (f <> e) do begin
      prev := f;
      f := f^.next_pred;
    end;
    if f <> nil then
      if prev = nil then
        src^.preds := f^.next_pred
      else
        prev^.next_pred := f^.next_pred;
    e := next;
  end;
  if at_backend_phase > phase$fga then begin
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
    if bb^.l54 <> nil then
      if bb^.l54^.l58 = bb then
        bb^.l54^.l58 := bb^.l58;
    if bb^.l58 <> nil then
      if bb^.l58^.l54 = bb then
        bb^.l58^.l54 := bb^.l54;
  end;
  p := nil;
  if bb^.l70 = nil then begin
    if rtn^.l84 = bb then
      rtn^.l84 := bb^.l78
    else
      p := rtn^.l84;
  end
  else begin
    h := bb^.l70;
    if h^.l74 = bb then
      h^.l74 := bb^.l78
    else
      p := h^.l74;
  end;
  if p <> nil then begin
    while p^.l78 <> bb do
      p := p^.l78;
    p^.l78 := bb^.l78;
  end;
  rtn^.nbbs := rtn^.nbbs - 1;
  bb^.f.forwarded := true;
end;

{ fg_utils_$forward_this_block - bb, a block whose one instruction is
  the jump (or a label and the jump), forwarded: each edge into bb made
  an edge into the jump's target (or the existing edge from the same
  source used, its operands retargeted); for a jump through a register
  (ip_reg, ip_reg_physical, ip_reg_like or case_jump_base), each
  source's branch operand that takes a register replaced by the jump's
  register operand (a reader of a final segment of its live range in the
  source, made and put on the exposed list when new, before RA), the
  source given bb's edges out (hidden); a source whose operand cannot
  take it keeps its edge into bb.  When no edge stays, bb's labels move
  to the target's head, the jump's register segment is excised (before
  RA) and bb dropped.  Traced at debug level 3.

  0x234C3C, 0x3C8 bytes: rtn (8), bb (12), jump (16); the target (-4),
  the edges in (-52), the next (-28), the source (-20), the edge kept
  (-48); kept a source's +18 bit 7 in D5, changed D6; the operands
  walked with D2 = 12k, D3 = 4k (the opcode's operand forms). }

procedure fg_utils_$forward_this_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    jump: instr_ptr_t);
label
  9;
var
  kind: integer;
  tgt: bb_ptr_t;
  changed: boolean;
  keep: boolean;
  e: fg_edge_ptr_t;
  next: fg_edge_ptr_t;
  src: bb_ptr_t;
  dup: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  ins: instr_ptr_t;
  k: integer32;
  form: integer;
  created: boolean;
  lts: lts_ptr_t;
  op: opnd_ptr_t;
  a: opnd_ptr_t;
  i: instr_ptr_t;
begin
  kind := ord(jump^.opnds[1].h.kind);
  if kind = ord(operand$flow_graph_edge) then begin
    tgt := fg_edge_ptr_t(jump^.opnds[1].ptr)^.target;
    if at_backend_switches.level >= 3 then
      vfmt_$write('Enter fg_utils_$forward_this_block: BB#%3ZWD to BB#%3ZWD%.',
                  bb^.num, tgt^.num);
    if tgt = bb then
      goto 9;
  end
  else begin
    if not (kind in [ord(operand$ip_reg), ord(operand$ip_reg_physical),
                     ord(operand$ip_reg_like), ord(operand$case_jump_base)]) then
      bug_check('FG_UTILS_$FORWARD_THIS_BLOCK:  branch target not understood%$');
    if at_backend_switches.level >= 3 then
      vfmt_$write('Enter fg_utils_$forward_this_block: BB#%3ZWD to <some register>%.',
                  bb^.num);
    tgt := nil;
  end;
  changed := false;
  e := bb^.preds;
  bb^.preds := nil;
  while e <> nil do begin
    next := e^.next_pred;
    src := e^.source;
    dup := nil;
    f := src^.succs;
    while f <> nil do begin
      if f <> e then
        if f^.target = tgt then
          dup := f;
      f := f^.next_succ;
    end;
    if (dup = nil) and (tgt <> nil) then begin
      e^.target := tgt;
      e^.next_pred := tgt^.preds;
      tgt^.preds := e;
    end
    else begin
      keep := src^.f.hidden_successor_edges;
      ins := src^.first;
      while ins <> nil do begin
        for k := 1 to ins^.h.nopnds do
          if ins^.opnds[k].h.kind = operand$flow_graph_edge then
            if fg_edge_ptr_t(ins^.opnds[k].ptr) = e then
              if tgt <> nil then
                ins^.opnds[k].ptr := dup
              else begin
                form := instr_attr_view_ptr_t(addr(instruction_attributes[ins^.opc]))^.opnds[k].form;
                if not ((form = ord(of$ip_reg_or_basic_block))
                        or (form = ord(of$ip_reg_or_long_pc_disp))) then
                  keep := true
                else begin
                  f := bb^.succs;
                  while f <> nil do begin
                    src^.f.hidden_successor_edges := true;
                    discard(lir_$add_flow_graph_edge(src, f^.target));
                    f := f^.next_succ;
                  end;
                  ins^.opnds[k] := jump^.opnds[1];
                  if at_backend_phase <= phase$ra then begin
                    lts := utils_$get_final_lts(jump^.opnds[1].lts^.lr, src, created);
                    if created then begin
                      utils_$put_lts_on_exposed_list(lts);
                      if lir_main_c8e then begin
                        lts^.l44 := jump^.opnds[1].lts^.l44;
                        lts^.l28 := lts_ptr_t(lts^.l44)^.l28;
                        lts_ptr_t(lts^.l44)^.l28 := lts;
                      end;
                    end;
                    ins^.opnds[k].lts := lts;
                    ins^.opnds[k].link := nil;
                    lts^.rrp := lts^.rrp + [rrp$read];
                    op := addr(ins^.opnds[k]);
                    if lts^.refs = nil then
                      lts^.refs := op
                    else begin
                      a := lts^.refs;
                      while a^.link <> nil do
                        a := a^.link;
                      a^.link := op;
                    end;
                  end;
                end;
              end;
        ins := ins^.next;
      end;
      if keep then begin
        e^.next_pred := bb^.preds;
        bb^.preds := e;
        changed := true;
      end
      else if src^.succs = e then
        src^.succs := e^.next_succ
      else begin
        f := src^.succs;
        while f^.next_succ <> e do
          f := f^.next_succ;
        f^.next_succ := e^.next_succ;
      end;
    end;
    e := next;
  end;
  if not changed then begin
    if bb^.first <> nil then
      if instruction_attributes[bb^.first^.opc].class = class$label then begin
        if tgt = nil then
          goto 9;
        i := bb^.first;
        repeat
          i^.bb := tgt;
          if i^.next = nil then
            exit;
          if instruction_attributes[i^.next^.opc].class <> class$label then
            exit;
          i := i^.next;
        until false;
        i^.next := tgt^.first;
        if tgt^.first <> nil then
          tgt^.first^.prev := i
        else
          tgt^.last := i;
        tgt^.first := bb^.first;
      end;
    if jump^.opnds[1].h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if at_backend_phase <= phase$ra then
        utils_$excise_lts_cleanly(jump^.opnds[1].lts, true);
    fg_utils_$drop_this_block(rtn, bb);
  end;
9:
end;
