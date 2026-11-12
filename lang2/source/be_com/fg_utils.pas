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

  TODO(pascal) fg_utils: 22 of 53 routines (the first ones in address
  order, through an_exit_has_multiple_successors, 0x2358B0); not
  translated yet: build_exit, copy_bb_contents, build_loop_header, n_instrs,
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
  dfs_level: integer32;                 { +76: compute_dfs_lists' debug
                                          level }
  order_count: integer32;               { +80: the blocks
                                          order_successor_lists has
                                          numbered (their order its low
                                          word) }
  fg_84: integer32;                     { +84 }
  final_bb: bb_ptr_t;                   { +88: the block add_final_edges
                                          gives an edge to }
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

{ order_successor_lists - bb's successor lists ordered, depth first
  (order 65535 while in progress, then order_count's low word): the
  edges to successors whose path_to is 2 moved to the end, those of
  path_to 3 to the front (unless bb's own path_to is 3); bb's path_to
  the largest of its successors'.

  0x2350BE, 0xE0 bytes, no A5 load (the A5 of its caller): bb (8) in
  A3; the moved edges' head D2, tail D4, the previous edge D3. }

function order_successor_lists(
    bb: bb_ptr_t): integer; options(val_param, internal);
var
  first: fg_edge_ptr_t;
  last: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
  k: integer;
begin
  bb^.order := 65535;
  if bb^.f14.path_to = 0 then begin
    first := nil;
    prev := nil;
    e := bb^.succs;
    while e <> nil do begin
      t := e^.target;
      if t^.order = 0 then
        k := order_successor_lists(t)
      else
        k := t^.f14.path_to;
      case k of
        0:
          prev := e;
        2: begin
          if prev = nil then
            bb^.succs := e^.next_succ
          else
            prev^.next_succ := e^.next_succ;
          if first = nil then
            first := e
          else
            last^.next_succ := e;
          last := e;
        end;
        3: begin
          if e <> bb^.succs then
            if bb^.f14.path_to <> 3 then begin
              prev^.next_succ := e^.next_succ;
              e^.next_succ := bb^.succs;
              bb^.succs := e;
            end;
          prev := e;
        end;
        otherwise
          ;
      end;
      if bb^.f14.path_to < k then
        bb^.f14.path_to := k;
      e := e^.next_succ;
    end;
    if first <> nil then begin
      last^.next_succ := bb^.succs;
      bb^.succs := first;
    end;
  end;
  order_count := order_count + 1;
  bb^.order := order_count & 16#FFFF;
  order_successor_lists := bb^.f14.path_to;
end;

{ add_final_edges - every block reachable from bb marked (+19 bit 3),
  depth first; a normal block with an edge in from a block not before
  it in the order (a loop's latch) given a hidden edge to final_bb.

  0x23519E, 0x78 bytes, no A5 load: bb (8) in A2. }

procedure add_final_edges(
    bb: bb_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
begin
  bb^.f.b19_3 := true;
  e := bb^.succs;
  while e <> nil do begin
    if not e^.target^.f.b19_3 then
      add_final_edges(e^.target);
    e := e^.next_succ;
  end;
  if bb^.f14.kind = 0 then begin
    e := bb^.preds;
    while e <> nil do begin
      if bb^.order >= e^.source^.order then begin
        bb^.f.hidden_successor_edges := true;
        discard(lir_$add_flow_graph_edge(bb, final_bb));
        return;
      end;
      e := e^.next_pred;
    end;
  end;
end;

{ depth_first_search - bb visited: its interval members (+138) itself,
  on the stack (+19 bit 1), a loop head (+19 bit 2) cleared, +150
  itself, +46, +142, +146 cleared; numbered in preorder (w8, the
  routine's dfs_first .. dfs_last, chained at l98 and back at l102);
  each successor not visited visited with bb its parent (l106), one on
  the stack marked a loop head; then off the stack and put in postorder
  (order; the routine's bbs72 the first, bbs the last, chained at
  next114 and back at next).

  0x235216, 0xE4 bytes, no A5: rtn (8) in A3, bb (12) in A2. }

procedure depth_first_search(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
begin
  bb^.members := bb;
  bb^.f.b19_1 := true;
  bb^.f.b19_2 := false;
  bb^.l150 := bb;
  bb^.l46 := nil;
  bb^.next142 := nil;
  bb^.mark146 := 0;
  if rtn^.dfs_first = nil then begin
    rtn^.dfs_first := bb;
    bb^.w8 := 1;
  end
  else begin
    rtn^.dfs_last^.l98 := fg_edge_ptr_t(bb);
    bb^.w8 := rtn^.dfs_last^.w8 + 1;
  end;
  bb^.l102 := rtn^.dfs_last;
  rtn^.dfs_last := bb;
  e := bb^.succs;
  while e <> nil do begin
    t := e^.target;
    if t^.members = nil then begin
      t^.l106 := bb;
      depth_first_search(rtn, e^.target);
    end
    else if t^.f.b19_1 then
      t^.f.b19_2 := true;
    e := e^.next_succ;
  end;
  bb^.f.b19_1 := false;
  if rtn^.bbs72 = nil then begin
    rtn^.bbs72 := bb;
    bb^.order := 1;
  end
  else begin
    rtn^.bbs^.next114 := bb;
    bb^.order := rtn^.bbs^.order + 1;
  end;
  bb^.next := rtn^.bbs;
  rtn^.bbs := bb;
end;

{ final_edge_fixup - the blocks numbered again by a depth-first search
  from the first block (the routine's +64..+79 cleared first; nbbs the
  last postorder number); the edges in from blocks the search did not
  reach dropped (each block in postorder), then those from forwarded
  blocks (each block in preorder from the last).

  0x2352FA, 0xD8 bytes, no A5: rtn (8) in D2; the first block (-24). }

procedure final_edge_fixup(
    rtn: rtn_ptr_t); options(val_param, internal);
var
  b: bb_ptr_t;
  x: bb_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
begin
  b := rtn^.bbs;
  rtn^.dfs_first := nil;
  rtn^.dfs_last := nil;
  rtn^.bbs72 := nil;
  rtn^.bbs := nil;
  depth_first_search(rtn, b);
  rtn^.nbbs := rtn^.bbs^.order;
  x := rtn^.bbs72;
  while x <> nil do begin
    prev := nil;
    e := x^.preds;
    while e <> nil do begin
      if e^.source^.members <> nil then
        prev := e
      else if prev = nil then
        x^.preds := e^.next_pred
      else
        prev^.next_pred := e^.next_pred;
      e := e^.next_pred;
    end;
    x := x^.next114;
  end;
  x := rtn^.dfs_last;
  while x <> nil do begin
    prev := nil;
    e := x^.preds;
    while e <> nil do begin
      if e^.source^.f.forwarded then begin
        if prev = nil then
          x^.preds := e^.next_pred
        else
          prev^.next_pred := e^.next_pred;
      end
      else
        prev := e;
      e := e^.next_pred;
    end;
    x := x^.l102;
  end;
end;

{ reorder_start_bb_successor_list - of the start block bb's edges out,
  the first to an entry block whose ENTRY's block is not an ENTRY
  statement's (kind 167) moved to the end (the ENTRY must be its
  block's first instruction).  Without one the image appends whatever
  its register last held (kept out: nothing is moved).

  0x2353D2, 0xA6 bytes, no A5: bb (8) in D2; the previous edge D3. }

procedure reorder_start_bb_successor_list(
    bb: bb_ptr_t); options(val_param, internal);
var
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  f: fg_edge_ptr_t;
  ins: instr_ptr_t;
  found: fg_edge_ptr_t;
begin
  prev := nil;
  found := nil;
  e := bb^.succs;
  while (e <> nil) and (found = nil) do begin
    if e^.target^.f.entry then begin
      ins := e^.target^.first;
      if ins^.opnds[1].h.kind <> operand$symbol_definition then
        bug_check('FG_UTILS_$reorder_start_bb_successor_list --- ENTRY instruction is no longer first within basic block%$');
      if il_$node_ptr_t(ins^.opnds[1].link)^.kind <> 167 then begin
        if prev = nil then
          bb^.succs := e^.next_succ
        else
          prev^.next_succ := e^.next_succ;
        e^.next_succ := nil;
        found := e;
      end;
    end;
    if found = nil then begin
      prev := e;
      e := e^.next_succ;
    end;
  end;
  if found <> nil then
    if bb^.succs = nil then
      bb^.succs := found
    else begin
      f := bb^.succs;
      while f^.next_succ <> nil do
        f := f^.next_succ;
      f^.next_succ := found;
    end;
end;

{ fg_utils_$compute_dfs_lists - the flow graph's depth-first lists made
  again: (after the first time for the routine) the blocks' members,
  +19 bits 2..1, l98 and next114 cleared; the successor lists ordered
  from the first block (the routine's no_return_block set unless the
  first block reaches a return, path_to 3), the start block's
  successors reordered, the final edges added (to the routine's bb80),
  the depth-first search made.

  0x2354E0, 0xA2 bytes: rtn (8) in A2, level (12) in D0 (p3 not read). }

procedure fg_utils_$compute_dfs_lists(
    rtn: rtn_ptr_t;
    level: integer32;
    p3: boolean);
var
  b: bb_ptr_t;
  start: bb_ptr_t;
begin
  if not fg_96 then begin
    b := rtn^.bbs;
    while b <> nil do begin
      b^.members := nil;
      b^.f.b19_2 := false;
      b^.f.b19_1 := false;
      b^.l98 := nil;
      b^.next114 := nil;
      b := b^.next;
    end;
  end;
  fg_96 := false;
  dfs_level := level;
  final_bb := rtn^.bb80;
  final_bb^.order := 65535;
  order_count := 0;
  start := rtn^.bbs;
  if order_successor_lists(start) <> 3 then
    rtn^.f226.no_return_block := true;
  reorder_start_bb_successor_list(start);
  add_final_edges(start);
  final_edge_fixup(rtn);
end;

{ in_interval - whether h is b or one of the interval heads above it
  (l70).

  0x235582, 0x20 bytes, no frame: b (4), h (8). }

function in_interval(
    b: bb_ptr_t;
    h: bb_ptr_t): boolean; options(val_param, internal);
begin
  in_interval := false;
  while b <> nil do begin
    if b = h then begin
      in_interval := true;
      return;
    end;
    b := b^.l70;
  end;
end;

{ loop_entry_is_conditional - whether the interval head h has both an
  edge out to a member of its interval and one leaving it (edges to
  itself not counted).

  0x2355A2, 0x3E bytes, no A5. }

function loop_entry_is_conditional(
    h: bb_ptr_t): boolean; options(val_param, internal);
var
  e: fg_edge_ptr_t;
  outside: boolean;
  inside: boolean;
begin
  outside := false;
  e := h^.succs;
  inside := outside;
  while e <> nil do begin
    if e^.target <> h then
      if e^.target^.l70 = h then
        inside := true
      else
        outside := true;
    e := e^.next_succ;
  end;
  loop_entry_is_conditional := outside and inside;
end;

{ visit_interval_contents - the interval headed by h given loop depth
  depth (inner loops depth + 1); its entry marked conditional when it
  is; each member with an edge leaving the interval marked a loop exit
  (and a conditional entry when it is an additional entry).

  0x2355E0, 0x96 bytes, no A5: h (8) in A2, depth (12) in D2. }

procedure visit_interval_contents(
    h: bb_ptr_t;
    depth: integer32); options(val_param, internal);
var
  m: bb_ptr_t;
  e: fg_edge_ptr_t;
begin
  h^.f.depth := depth & 255;
  if loop_entry_is_conditional(h) then
    h^.f.conditional_entry := true;
  m := h^.l74;
  while m <> nil do begin
    m^.f.depth := depth & 255;
    if m^.f.distinguished_entry then
      visit_interval_contents(m, depth + 1);
    e := m^.succs;
    while e <> nil do
      if not in_interval(e^.target^.l70, h) and (e^.target <> h) then begin
        m^.f.loop_exit := true;
        if m^.f.additional_entry then
          m^.f.conditional_entry := true;
        e := nil;
      end
      else
        e := e^.next_succ;
    m := m^.l78;
  end;
end;

{ fg_utils_$intervals - the routine's intervals (loops) found: for each
  block h in postorder (bbs72, next114), the outermost heads of its
  predecessors (only those not after it for h itself) gathered on a
  work list through l78, each in turn giving its own; a block reached
  from one after h marks h (and the block it was reached from, when
  before h) an additional entry.  When the list closes on h with some
  predecessor and h no additional entry, h heads an interval of the
  blocks gathered (distinguished_entry; their l70 h, its l74 the list;
  an additional entry among them makes h irreducible).  Then each block
  without a head is put on the routine's l84 (an additional entry sets
  rtn +228 bit 2) and its interval visited from depth 1; mark146
  cleared.  The first time for a routine nothing is cleared first.

  0x235676, 0x1AC bytes: rtn (8) in D2; the head D3, the list's tail
  D4, its first unvisited D5, the block whose edges in are walked D6,
  any D0, the first pass D1. }

procedure fg_utils_$intervals(
    rtn: rtn_ptr_t);
label
  1;
var
  b: bb_ptr_t;
  h: bb_ptr_t;
  last: bb_ptr_t;
  next: bb_ptr_t;
  cur: bb_ptr_t;
  p: bb_ptr_t;
  m: bb_ptr_t;
  e: fg_edge_ptr_t;
  any: boolean;
  first: boolean;
begin
  if not fg_94 then begin
    b := rtn^.bbs72;
    while b <> nil do begin
      b^.l70 := nil;
      b^.l74 := nil;
      b^.l78 := nil;
      b^.f.distinguished_entry := false;
      b^.f.irreducible := false;
      b^.f.additional_entry := false;
      b^.f.conditional_entry := false;
      b^.f.depth := 0;
      b := b^.next114;
    end;
  end
  else
    fg_94 := false;
  h := rtn^.bbs72;
  while h <> nil do begin
    last := h;
    next := nil;
    h^.l78 := h;
    any := false;
    cur := h;
    first := true;
  1:
    e := cur^.preds;
    while e <> nil do begin
      p := e^.source;
      while p^.l70 <> nil do
        p := p^.l70;
      if not (first and (p^.order > cur^.order)) then begin
        any := true;
        if p^.l78 = nil then begin
          if next = nil then
            next := p;
          last^.l78 := p;
          last := p;
          p^.l78 := p;
        end;
      end;
      e := e^.next_pred;
    end;
    if next <> nil then begin
      p := next;
      if p = last then
        next := nil
      else
        next := p^.l78;
      if p^.order > h^.order then begin
        h^.f.additional_entry := true;
        if cur^.order < h^.order then
          cur^.f.additional_entry := true;
      end;
      cur := p;
      first := false;
      goto 1;
    end;
    if any and not h^.f.additional_entry then begin
      h^.f.distinguished_entry := true;
      m := h^.l78;
      if m = h then
        m := nil;
      last^.l78 := nil;
      h^.l74 := m;
      h^.l78 := nil;
      while m <> nil do begin
        m^.l70 := h;
        if m^.f.additional_entry then
          h^.f.irreducible := true;
        m := m^.l78;
      end;
    end;
    m := h;
    while m <> nil do begin
      p := m;
      m := m^.l78;
      p^.l78 := nil;
    end;
    h := h^.next114;
  end;
  b := rtn^.bbs;
  while b <> nil do begin
    if b^.l70 = nil then begin
      b^.l78 := rtn^.l84;
      rtn^.l84 := b;
      if b^.f.additional_entry then
        rtn^.f228.b228_2 := true;
      if b^.f.distinguished_entry then
        visit_interval_contents(b, 1);
    end;
    b^.mark146 := 0;
    b := b^.next;
  end;
end;

{ fg_utils_$separate_loop_header_edges - bb's edges in from blocks
  outside the loop headed by head (inside when p3 is false: a source
  is outside when its depth is less than head's or head is not among
  its interval heads) taken off bb's list (when outside <> p3) and
  chained, newest first, at next_pred; the chain.

  0x235822, 0x8E bytes: bb (8) in D3, head (12) in D2, p3 (16) in D1;
  the chain in D4 (returned in A0), the previous edge D5. }

function fg_utils_$separate_loop_header_edges(
    bb: bb_ptr_t;
    head: bb_ptr_t;
    p3: boolean): fg_edge_ptr_t;
var
  moved: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  e: fg_edge_ptr_t;
  n: fg_edge_ptr_t;
  a: bb_ptr_t;
  outside: boolean;
begin
  moved := nil;
  prev := moved;
  e := bb^.preds;
  while e <> nil do begin
    a := e^.source;
    if a^.f.depth < head^.f.depth then
      outside := true
    else begin
      outside := true;
      while a <> nil do
        if a = head then begin
          outside := false;
          a := nil;
        end
        else
          a := a^.l70;
    end;
    if outside = p3 then begin
      prev := e;
      e := e^.next_pred;
    end
    else begin
      n := e^.next_pred;
      if prev = nil then
        bb^.preds := n
      else
        prev^.next_pred := n;
      e^.next_pred := moved;
      moved := e;
      e := n;
    end;
  end;
  fg_utils_$separate_loop_header_edges := moved;
end;

{ an_exit_has_multiple_successors - whether a source of the edges on
  the chain list (at next_pred) does not end in a jump with one
  visible successor, or has a branch or jump before that jump.

  0x2358B0, 0x7E bytes, no A5: list (8) in A0. }

function an_exit_has_multiple_successors(
    list: fg_edge_ptr_t): boolean; options(val_param, internal);
var
  src: bb_ptr_t;
  last: instr_ptr_t;
  p: instr_ptr_t;
begin
  an_exit_has_multiple_successors := true;
  while list <> nil do begin
    src := list^.source;
    last := src^.last;
    if (last^.opc <> ord(opc$jump)) or (src^.succs^.next_succ <> nil)
       or src^.f.hidden_successor_edges then
      return;
    p := last^.prev;
    if p <> nil then
      if instruction_attributes[p^.opc].class in [class$branch, class$fp_branch, class$jump] then
        return;
    list := list^.next_pred;
  end;
  an_exit_has_multiple_successors := false;
end;
