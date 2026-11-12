{ fga - the FGA phase of the PRISM back end (flow graph analysis): the
  blocks that only jump forwarded, the depth-first lists, the argument
  pointer's read taken out of the routine's RETURN when the routine
  does not need it there, the blocks reached asynchronously (from a
  block that may be resumed: after a setjmp, the path its zero result
  takes), with exception handling edges from the final block to the
  blocks a handler may enter, the global walk with async protection,
  and last the plain global walk.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x237A60  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x237A82  fga_$begin_compilation
    --------  0x237A84  fga_$end_routine
    --------  0x237A86  fga_$end_compilation
    --------  0x237A88  fga_$optimize_ap_read_in_return (internal)
    --------  0x237BDC  analyze_source (internal)
    --------  0x237CC6  conditionally_asynchronous (internal)
    --------  0x23808A  mark_asynchronous_path (internal)
    --------  0x2380C2  fga_$compute_asynchronous_paths (internal)
    --------  0x238112  fga_$strip_final_to_entry_fges (internal)
    --------  0x23817A  fga_$process_routine
    A5 0x4864D0: the module's data, 4 bytes (the switches' level).

  The fga_$ routines other than the phase's entries do not load A5 and
  nothing outside calls them: internal.  fga opens the prelude (its
  .blocks list has globals.ins.pas and its members after
  bug_check.ins.pas): idntk, il_180 and cargs_$options are the
  prelude's (docs/questions.md 174, answered by translator PA3).

  Opcodes by their names (the opcode enumeration): a block ending in
  BEQ or BNE on condition codes a TST or MOVE (one source) or an ADD,
  SUB or RSUB (two) wrote, after a CALL whose operand 1 a LOADL of an
  immediate loaded.

  Not known from the original: every local and parameter name; level's
  name. }
module fga;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { What an immediate's or an XSB displacement's operand +4 (its link
    field) points to,
    as fga reads it: kind (+2: 163 and 195 the constants analyzed), a
    word at +4 (an XSB base's kind), the value at +8, and a constant's
    count and symbol (163: a byte count at +20 and the symbol at +8;
    195: a word count at +20 and the symbol at +12). }
  fga_node_ptr_t = ^fga_node_t;
  fga_node_t = record
    w0: integer;                        { +0 }
    kind: integer;                      { +2 }
    w4: integer;                        { +4 }
    w6: integer;                        { +6 }
    case integer of
      1: (value: integer32;             { +8 }
          l12: integer32;               { +12 }
          l16: integer32;               { +16 }
          b20: char);                   { +20 }
      2: (sym8: fga_node_ptr_t;         { +8 }
          sym12: fga_node_ptr_t;        { +12 }
          l16_2: integer32;             { +16 }
          w20: integer);                { +20 }
      3: (xp: array [2..74] of univ_ptr);    { +8: xp[74] at +296, a
                                          routine symbol's name }
      4: (xc: array [8..379] of char);  { +8: a routine node's flags at
                                          +379 }
  end;

  { batch A (PA3): fga_cargs_t, idntk's heading and the il_180 and
    cargs_$options views went with the prelude (docs/questions.md 174). }

var
  level: integer32;                     { +0 }

{ fga_$begin_compilation - nothing.  0x237A82, 2 bytes. }

procedure fga_$begin_compilation;
begin
end;

{ fga_$end_routine - nothing.  0x237A84, 2 bytes. }

procedure fga_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ fga_$end_compilation - nothing.  0x237A86, 2 bytes. }

procedure fga_$end_compilation;
begin
end;

{ fga_$optimize_ap_read_in_return - when the routine's +226 bit 0 is set
  and its argument pointer's live range (+100) is read, the RETURN's
  (+96) third operand, which must be a segment of that live range
  (bug_check), becomes operand$none (`andi.w #0xFFE0' of its +2 word)
  and is unlinked from the segment's references; a segment whose first
  reference it was is dropped from the live range's list.

  0x237A88, 0xB2 bytes: the routine (8); the live range in D2, the
  previous segment in D3, the previous operand in D4.  The search's
  end without the operand falls into the unlinking after bug_check (a
  flag here). }

procedure fga_$optimize_ap_read_in_return(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  ret: instr_ptr_t;
  target: opnd_ptr_t;
  prev_lts: lts_ptr_t;
  lts: lts_ptr_t;
  prev_op: opnd_ptr_t;
  op: opnd_ptr_t;
  found: boolean;
begin
  if rtn^.f226.b226_0 then begin
    lr := rtn^.ap_lr;
    if rrp$read in lr^.rrp then begin
      ret := rtn^.return_instr;
      if ret^.opnds[3].lts^.lr <> lr then
        bug_check('FGA_$OPTIMIZE_AP_READ_IN_RETURN -- AP operand in RETURN not in expected position%$');
      ret^.opnds[3].h.kind := operand$none;
      target := addr(ret^.opnds[3]);
      prev_lts := nil;
      lts := lr^.ltss;
      found := false;
      while (lts <> nil) and not found do begin
        prev_op := nil;
        op := lts^.refs;
        while (op <> nil) and not found do
          if op = target then
            found := true
          else begin
            prev_op := op;
            op := op^.link;
          end;
        if not found then begin
          prev_lts := lts;
          lts := lts^.next;
        end;
      end;
      if not found then
        bug_check('FGA_$OPTIMIZE_AP_READ_IN_RETURN -- no AP operand in RETURN when searching LTSs%$');
      if prev_op <> nil then
        prev_op^.link := op^.link
      else if prev_lts <> nil then
        prev_lts^.next := lts^.next
      else
        lr^.ltss := lts^.next;
    end;
  end;
end;

{ analyze_source - whether op is a known value: an immediate (when
  allow_imm: its value), a live range of +3 bit 7 with +2 zero that
  is never written or modified (not a constant), or a register defined
  by a MOVE (its source analyzed in turn) or, when allow_imm, by a
  LOADL of an XSB displacement (operand 1 of
  kind displacement_XSB_base whose node (the operand's +4, link) has
  0, 3, 4, 7 or 10 at its +4: the mask 0x499) whose value is the
  node's +8; each defining instruction
  used is marked (+2 bit 6).

  0x237BDC, 0xEA bytes: op (8), allow_imm (12, a byte), is_const (14)
  and value (18) by address; `st'/`clr.b' D0. }

function analyze_source(
    op: opnd_ptr_t;
    allow_imm: boolean;
    var is_const: boolean;
    var value: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  lts: lts_ptr_t;
  instr: instr_ptr_t;
  n: fga_node_ptr_t;
begin
  result := false;
  if allow_imm and (op^.h.kind = operand$immediate) then begin
    is_const := true;
    value := op^.value;
    result := true;
  end
  else if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
    lts := op^.lts;
    if lts^.lr^.f2.b3_7 then begin
      is_const := result;
      result := (lts^.lr^.f2.reg = 0)
                and ((lts^.rrp * [rrp$modify, rrp$write]) = []);
    end
    else if lts^.refs^.h.write then begin
      instr := utils_ins_$operands_instruction(lts^.refs);
      if instr^.opc = ord(opc$move) then begin
        instr^.h.b2_6 := true;
        result := analyze_source(addr(instr^.opnds[1]), allow_imm,
                                 is_const, value);
      end
      else if allow_imm and (instr^.opc = ord(opc$loadl))
              and (instr^.opnds[1].h.kind = operand$displacement_XSB_base) then begin
        n := fga_node_ptr_t(instr^.opnds[1].link);
        if n^.w4 in [0, 3, 4, 7, 10] then begin
          instr^.h.b2_6 := true;
          value := n^.value;
          is_const := true;
          result := true;
        end;
      end;
    end;
  end;
  analyze_source := result;
end;

{ conditionally_asynchronous - whether only one way out of bb is
  asynchronous: bb (whose instructions are labels, its one branch,
  jumps and the instructions that compute the branch's condition,
  each marked +2 bit 6, every other one unmarked) branches (BEQ or
  BNE) on condition codes written by a TST or MOVE (one source) or an
  ADD, RSUB or SUB (two) of known values; its one predecessor of kind
  other than 1 (+14) ends in a CALL (the instruction before its last)
  with an integer register result (a live range of +3 bit 7, +2
  zero); and either that predecessor's +17 bit 3 is set and the value
  is 0x03040003, or the call's operand 1 is defined by a LOADL of an
  immediate whose node (163 or 195) has
  2 for its count and names a routine (kind 108) called setjmp (or,
  unless cargs +0x288 bit 3, SETJMP), the value being 0; bb has two
  successors.  Then target is the successor the zero result takes (by
  the branch's sense: for BEQ the edge other than its operand 1's),
  which must have
  one predecessor.  Whatever the answer, the instructions of bb not
  examined yet are marked.

  0x237CC6, 0x3B8 bytes: the routine (8, not read), bb (12) in D6,
  target (16) by address, set to bb first; the answer in D3.  Every
  failure branches to the marking loop at the end (0x23806C: `goto
  99').  The
  compare's operands: the first analyzed with allow_imm unless it is
  a one-operand compare (D4 `st'), the second (79, 83, 81) with
  allow_imm unless the first was constant; the value negated for 79.
  The predecessor's call: the first register operand (by `dbf' over
  its count) writing an integer register (kind 1) of a live range
  with +3 bit 7 and +2 zero.  idntk(76, 'setjmp', 6) (`move.w #6'
  pushed first) compared with the routine symbol's +296.

  Not known from the original: why the routine is passed. }

function conditionally_asynchronous(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t;
    var target: bb_ptr_t): boolean; options(val_param); internal;
label
  99;
var
  result: boolean;
  instr: instr_ptr_t;
  br: instr_ptr_t;
  cls: integer;
  lts: lts_ptr_t;
  cmp: instr_ptr_t;
  src1: opnd_ptr_t;
  src2: opnd_ptr_t;
  known: boolean;
  is_const: boolean;
  value: integer32;
  e: fg_edge_ptr_t;
  pred: bb_ptr_t;
  call: instr_ptr_t;
  res: opnd_ptr_t;
  k: integer32;
  op: opnd_ptr_t;
  ld: instr_ptr_t;
  n: fga_node_ptr_t;
  count: integer;
  sym: fga_node_ptr_t;
  taken: fg_edge_ptr_t;
  other: fg_edge_ptr_t;
begin
  result := false;
  target := bb;
  instr := bb^.first;
  br := nil;
  while instr <> nil do begin
    cls := ord(instruction_attributes[instr^.opc].class);
    if cls = class$label then
      instr^.h.b2_6 := true
    else if cls = class$branch then begin
      if br <> nil then
        goto 99;
      br := instr;
      instr^.h.b2_6 := true;
    end
    else if cls = class$jump then
      instr^.h.b2_6 := true
    else
      instr^.h.b2_6 := false;
    instr := instr^.next;
  end;
  if br = nil then
    goto 99;
  if (br^.opc <> ord(opc$beq)) and (br^.opc <> ord(opc$bne)) then
    goto 99;
  if br^.opnds[2].h.kind <> operand$ip_condition_codes then
    goto 99;
  lts := br^.opnds[2].lts;
  if not (rrp$write in lts^.rrp) then
    goto 99;
  cmp := utils_ins_$operands_instruction(lts^.refs);
  if (cmp^.opc = ord(opc$move)) or (cmp^.opc = ord(opc$tst)) then begin
    src1 := addr(cmp^.opnds[1]);
    src2 := nil;
    value := 0;
    known := true;
  end
  else if (cmp^.opc = ord(opc$add)) or (cmp^.opc = ord(opc$rsub))
          or (cmp^.opc = ord(opc$sub)) then begin
    src1 := addr(cmp^.opnds[1]);
    src2 := addr(cmp^.opnds[2]);
    known := false;
  end
  else
    goto 99;
  cmp^.h.b2_6 := true;
  if not analyze_source(src1, not known, is_const, value) then
    goto 99;
  known := known or is_const;
  if src2 <> nil then
    if not analyze_source(src2, not known, is_const, value) then
      goto 99;
  known := known or is_const;
  if not known then
    goto 99;
  if cmp^.opc = ord(opc$add) then
    value := -value;

  instr := bb^.first;
  while instr <> nil do begin
    if not instr^.h.b2_6 then
      goto 99;
    instr := instr^.next;
  end;

  pred := nil;
  e := bb^.preds;
  while e <> nil do begin
    if ord(e^.source^.f14.b14) <> 1 then begin
      if pred <> nil then
        goto 99;
      pred := e^.source;
    end;
    e := e^.next_pred;
  end;
  if pred^.last^.prev = nil then
    goto 99;
  call := pred^.last^.prev;
  if call^.opc <> ord(opc$call) then
    goto 99;
  res := nil;
  for k := 1 to call^.h.nopnds do begin
    op := addr(call^.opnds[k]);
    if (op^.lts^.lr^.f2.reg = 0) and op^.lts^.lr^.f2.b3_7
       and op^.h.write and (op^.h.kind = operand$ip_reg) then begin
      res := op;
      exit;
    end;
  end;
  if res = nil then
    goto 99;
  if pred^.f.b17_3 then begin
    if value <> 16#03040003 then
      goto 99;
  end
  else begin
    if not (rrp$write in call^.opnds[1].lts^.rrp) then
      goto 99;
    ld := utils_ins_$operands_instruction(call^.opnds[1].lts^.refs);
    if ld^.opc <> ord(opc$loadl) then
      goto 99;
    if not (ld^.opnds[1].h.kind in [operand$immediate,
                                    operand$bind_time_immediate]) then
      goto 99;
    n := fga_node_ptr_t(ld^.opnds[1].link);
    if n^.kind = 163 then begin
      count := ord(n^.b20);
      sym := n^.sym8;
    end
    else if n^.kind = 195 then begin
      count := n^.w20;
      sym := n^.sym12;
    end
    else
      goto 99;
    if count <> 2 then
      goto 99;
    if sym = nil then
      goto 99;
    if sym^.kind <> 108 then
      goto 99;
    if bb^.succs = nil then
      goto 99;
    if bb^.succs^.next_succ = nil then
      goto 99;
    if bb^.succs^.next_succ^.next_succ <> nil then
      goto 99;
    if idntk(76, 'setjmp', 6) <> sym^.xp[74] then begin
      if 0 in cargs_$options.flags_286 then
        goto 99;
      if idntk(76, 'SETJMP', 6) <> sym^.xp[74] then
        goto 99;
    end;
    if value <> 0 then
      goto 99;
  end;

  taken := br^.opnds[1].ptr;
  if taken = bb^.succs then
    other := taken^.next_succ
  else
    other := bb^.succs;
  if br^.opc = ord(opc$beq) then
    target := other^.target
  else
    target := taken^.target;
  if target^.preds = nil then
    goto 99;
  if target^.preds^.next_pred <> nil then
    goto 99;
  result := true;
99:
  while instr <> nil do begin
    instr^.h.b2_6 := true;
    instr := instr^.next;
  end;
  conditionally_asynchronous := result;
end;

{ mark_asynchronous_path - bb and every block reachable from it marked
  (+17 bit 2), depth first over the edges out.

  0x23808A, 0x38 bytes: bb (8). }

procedure mark_asynchronous_path(
    bb: bb_ptr_t); options(val_param); internal;
var
  e: fg_edge_ptr_t;
begin
  if not bb^.f.b17_2 then begin
    bb^.f.b17_2 := true;
    e := bb^.succs;
    while e <> nil do begin
      mark_asynchronous_path(e^.target);
      e := e^.next_succ;
    end;
  end;
end;

{ fga_$compute_asynchronous_paths - from each block that may be resumed
  (+17 bit 4), the paths marked: from its asynchronous successor when
  conditionally_asynchronous finds one, else from the block.

  0x2380C2, 0x50 bytes: the routine (8); target in a frame slot. }

procedure fga_$compute_asynchronous_paths(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  target: bb_ptr_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    if bb^.f.b17_4 then begin
      if not conditionally_asynchronous(rtn, bb, target) then
        target := bb;
      mark_asynchronous_path(target);
    end;
    bb := bb^.next;
  end;
end;

{ fga_$strip_final_to_entry_fges - the edges out of the final block
  (the routine's +80) taken off their targets' lists of edges in, and
  its list of edges out cleared.

  0x238112, 0x68 bytes: the routine (8); the final block in D0, the
  edge in D1, the previous edge in in D2 (set to each edge in, removed
  or not). }

procedure fga_$strip_final_to_entry_fges(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  fin: bb_ptr_t;
  e: fg_edge_ptr_t;
  prev: fg_edge_ptr_t;
  tgt: bb_ptr_t;
  p: fg_edge_ptr_t;
  nx: fg_edge_ptr_t;
begin
  fin := rtn^.bb80;
  e := fin^.succs;
  while e <> nil do begin
    prev := nil;
    tgt := e^.target;
    p := tgt^.preds;
    while p <> nil do begin
      nx := p^.next_pred;
      if p^.source = fin then begin
        if prev = nil then
          tgt^.preds := nx
        else
          prev^.next_pred := nx;
      end;
      prev := p;
      p := nx;
    end;
    e := e^.next_succ;
  end;
  fin^.succs := nil;
end;

{ fga_$process_routine - the phase.

  0x23817A, 0x1B8 bytes: the routine (8) in D4.  level := the switches'
  bits 2..0.  Unless switch 9: each block (followed through its +134,
  read before the block may be forwarded) of kind other than 1 (+14)
  whose one instruction is a jump (class 6) along its first edge out
  (the jump's operand 1) is forwarded (fg_utils_$forward_this_block).
  The dfs lists (level, switch 3).  The routine's +226 bit 0 set when
  its +226 bit 2 or +227 bit 6 is; the AP read; with +227 bit 6 the
  asynchronous paths.  With the routine node's +379 bit 4 or
  lir_main_c8c, an edge from the final block (+80) to each block of +17
  bit 7 (lir_$add_flow_graph_edge, its result dropped).  The routine's
  +192 grows by 96.  With those edges or +227 bit 6, unless switch 9:
  the walk with async protection (how 1), the sanity check and
  lir_utils_$fix_store_through_lrs.  The instructions chained from
  lir_main_c44 at their +32 unchained (lir_main_c44 kept).  The edges
  added are stripped again; lir_main_c8d set, lir_main_c86 1, and the
  plain walk (how 1). }

procedure fga_$process_routine(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
  nx: bb_ptr_t;
  first: instr_ptr_t;
  instr: instr_ptr_t;
  inext: instr_ptr_t;
  handlers: boolean;
  added: boolean;
begin
  level := at_backend_switches.level;
  if not at_backend_switches.sw9 then begin
    bb := rtn^.bbs;
    while bb <> nil do begin
      nx := bb_ptr_t(bb^.l134);
      if ord(bb^.f14.b14) <> 1 then begin
        first := bb^.first;
        if (first = bb^.last) and (first <> nil) then
          if instruction_attributes[first^.opc].class = class$jump then
            if (bb^.succs <> nil)
               and (univ_ptr(bb^.succs) = first^.opnds[1].ptr) then
              fg_utils_$forward_this_block(rtn, bb, first);
      end;
      bb := nx;
    end;
  end;
  fg_utils_$compute_dfs_lists(rtn, level, at_backend_switches.sw3);
  if rtn^.f226.b226_2 or rtn^.f226.b227_6 then
    rtn^.f226.b226_0 := true;
  fga_$optimize_ap_read_in_return(rtn);
  if rtn^.f226.b227_6 then
    fga_$compute_asynchronous_paths(rtn);
  handlers := ((ord(il_180^.xc[379]) & 16#10) <> 0) or lir_main_c8c;
  added := false;
  if handlers then begin
    bb := rtn^.bbs;
    while bb <> nil do begin
      if bb^.f.b17_7 then begin
        added := true;
        discard(lir_$add_flow_graph_edge(rtn^.bb80, bb));
      end;
      bb := bb^.next;
    end;
  end;
  rtn^.l192 := rtn^.l192 + 96;
  if (handlers or rtn^.f226.b227_6) and not at_backend_switches.sw9 then begin
    df_utils_$global_walk_with_async_protection(rtn, rtn^.l192, 1, level);
    lir_utils_$sanity_check(rtn);
    lir_utils_$fix_store_through_lrs(rtn);
  end;
  instr := instr_ptr_t(lir_main_c44);
  while instr <> nil do begin
    inext := instr_ptr_t(instr^.l32);
    instr^.l32 := 0;
    instr := inext;
  end;
  if added then
    fga_$strip_final_to_entry_fges(rtn);
  lir_main_c8d := true;
  lir_main_c86 := 1;
  df_utils_$global_walk(rtn, rtn^.l192, 1, level);
end;
