{ df_utils - the global data flow walk of the PRISM back end (cc.a88k
  only): the live ranges' segment lists made canonical (references
  from instructions the last walk did not reach dropped, the live
  ranges that need it made complex, the segments chained by block and
  back by live range), then a backward walk from the instructions that
  must stay (branches, labels, returns, the blocks that must keep their
  code, and with async protection the writes of the live ranges an
  exception handler may see) through the segments they read, block by
  block over the flow graph's predecessors, which marks every
  instruction whose result is used (instruction +2 bit 6) and sets
  each block's live_in / live_out / live_gen bits; last the exposed and
  final lists rebuilt by block (lir_main_c86 0) or by live range (1).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x22E564  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x22E586  df_utils_$begin_compilation
    --------  0x22E588  df_utils_$init_for_routine
    --------  0x22E5A2  df_utils_$end_routine
    --------  0x22E5A4  df_utils_$end_compilation
    --------  0x22E5A6  enqueue_instruction (internal)
    --------  0x22E5D6  mark_tail (internal)
    --------  0x22E630  mark_lts (internal)
    --------  0x22E778  special_p (internal)
    --------  0x22E7BE  memory_home_is_initialized_fsym (internal)
    --------  0x22E7EE  df_utils_$canonicalize_lr_lts_lists (internal)
    --------  0x22EBB4  rebuild_bb_exposed_and_final_lists (internal)
    --------  0x22EC28  process_marked_instructions (internal)
    --------  0x22ED06  need_all_writes (internal)
    --------  0x22ED46  do_global_walk (internal)
    --------  0x22F03A  df_utils_$global_walk
    --------  0x22F070  df_utils_$global_walk_with_async_protection
    A5 0x486058: the module's data (20 bytes): the work queue's tail
    (+0) and head (+4), the walk's level (+8, stored and not read),
    the walk's mark (+12), and whether the routine has not been walked
    yet (+16, set by df_utils_$init_for_routine).

  df_utils_$canonicalize_lr_lts_lists does not load A5 and nothing
  outside calls it: internal despite its name.

  The work queue: instructions chained at their +24, the last one
  pointing to itself; an instruction is queued once per walk (its +16
  the walk's mark, from the routine's marks).

  Not known from the original: every local and parameter name; the
  module variables' names. }
module df_utils;

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
  tail: instr_ptr_t;                    { +0: the queue's last }
  head: instr_ptr_t;                    { +4: the queue's first }
  walk_level: integer32;                { +8: the walk's level }
  mark: integer32;                      { +12: the walk's mark }
  first_walk: boolean;                  { +16 }

{ df_utils_$begin_compilation - nothing.  0x22E586, 2 bytes. }

procedure df_utils_$begin_compilation;
begin
end;

{ df_utils_$init_for_routine - the next walk is the routine's first
  (`move.b #-1,(16,A5)').  0x22E588, 0x1A bytes. }

procedure df_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
  first_walk := true;
end;

{ df_utils_$end_routine - nothing.  0x22E5A2, 2 bytes. }

procedure df_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ df_utils_$end_compilation - nothing.  0x22E5A4, 2 bytes. }

procedure df_utils_$end_compilation;
begin
end;

{ enqueue_instruction - instr put at the queue's tail unless this walk
  has queued it (its +16 not below the mark: `cmp.l (16,A0),D0; ble').

  0x22E5A6, 0x30 bytes, no frame (the instruction at (4,SP)).  The head
  set when empty, the tail when empty, then the old tail's +24 and the
  tail set, and the instruction's +24 pointing to itself. }

procedure enqueue_instruction(
    instr: instr_ptr_t); options(val_param); internal;
begin
  if mark > instr^.l16 then begin
    instr^.l16 := mark;
    if head = nil then
      head := instr;
    if tail = nil then
      tail := instr;
    tail^.l24 := integer32(instr);
    tail := instr;
    instr^.l24 := integer32(instr);
  end;
end;

procedure mark_lts(
    lts: lts_ptr_t;
    bb: bb_ptr_t;
    lr: lr_ptr_t); options(val_param); internal; forward;

{ mark_tail - lr live out of bb: the first time (bv_$test_and_set of
  bb's live_out, +86), its final segment in bb marked final (+3 bit 4)
  and walked, or with none the live range walked into bb's head.

  0x22E5D6, 0x5A bytes: lr (8), bb (12).  utils_$find_final_lts(lr,
  bb); the two calls of mark_lts share one `bsr' (the arguments pushed
  on each path). }

procedure mark_tail(
    lr: lr_ptr_t;
    bb: bb_ptr_t); options(val_param); internal;
var
  lts: lts_ptr_t;
begin
  if not bv_$test_and_set(bb^.live_out, lr) then begin
    lts := utils_$find_final_lts(lr, bb);
    if lts = nil then
      mark_lts(nil, bb, lr)
    else begin
      lts^.f2.final := true;
      mark_lts(lts, bb, nil);
    end;
  end;
end;

{ mark_lts - the value lts (or lr's, with lts nil, entering bb from its
  head) needs: a segment whose first reference writes it queues the
  defining instruction (a segment so defined must not be flagged
  exposed); otherwise the value is live into bb (live_in, +94) and, the
  first time, live out of each predecessor.

  0x22E630, 0xC4 bytes: lts (8), bb (12), lr (16).  The definition is
  the segment's refs (+4) when that operand does not read (+1 bit 4);
  its instruction (utils_ins_$operands_instruction inline, kept in a
  frame slot) given to instr_bug_check when the segment's +3 bit 7 is
  set.  A segment read first must be exposed (bug_check otherwise).
  Only a complex live range (id, +4, nonzero) is followed: bb's edges
  in (+26) chained at +12, each source (+0) given to mark_tail. }

procedure mark_lts(
    lts: lts_ptr_t;
    bb: bb_ptr_t;
    lr: lr_ptr_t);
var
  op: opnd_ptr_t;
  instr: instr_ptr_t;
  l: lr_ptr_t;
  e: fg_edge_ptr_t;
begin
  if lts <> nil then begin
    op := lts^.refs;
    if not op^.h.read then begin
      instr := instr_ptr_t(integer32(op) - 32 - op^.h.num * 12);
      if lts^.f2.exposed then
        instr_bug_check('DF_UTILS_$MARK_LTS: "exposed use" flag on, should be off, near line %LD%$',
                        instr^);
      enqueue_instruction(instr);
      return;
    end;
  end;
  if lts = nil then
    l := lr
  else begin
    l := lts^.lr;
    if not lts^.f2.exposed then
      bug_check('DF_UTILS_$MARK_LTS: "exposed use" flag off, should be on%$');
  end;
  if l^.id <> 0 then
    if not bv_$test_and_set(bb^.live_in, l) then begin
      e := bb^.preds;
      while e <> nil do begin
        mark_tail(l, e^.source);
        e := e^.next_pred;
      end;
    end;
end;

{ special_p - whether instr must stay whatever its result: its opcode's
  class a branch, a floating branch, a jump, a label or a return (the
  mask 0x01080062 over instruction_attributes' +7), or its block's +17
  bit 6 set.

  0x22E778, 0x46 bytes: instr (8), bb (12); `st'/`clr.b' D0. }

function special_p(
    instr: instr_ptr_t;
    bb: bb_ptr_t): boolean; options(val_param); internal;
begin
  special_p := (instruction_attributes[instr^.opc].class in
                [class$branch, class$fp_branch, class$jump, class$label,
                 class$return])
               or bb^.f.atomic;
end;

{ memory_home_is_initialized_fsym - whether sym (a live range's +24) is
  a variable (kind 110) whose +44 has 3 in bits 7..4 and bit 3 set.

  0x22E7BE, 0x30 bytes, no frame (sym at (4,SP)); `sne'/`clr.b' D0. }

function memory_home_is_initialized_fsym(
    sym: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (sym <> nil) and then (sym^.kind = fortran_symbol)
     and then (rshft(ord(sym^.xc[44]) & 16#F0, 4) = 3) then
    memory_home_is_initialized_fsym := (ord(sym^.xc[44]) & 8) <> 0
  else
    memory_home_is_initialized_fsym := false;
end;

{ df_utils_$canonicalize_lr_lts_lists - the routine's segment lists
  made canonical.

  0x22E7EE, 0x3C6 bytes: the routine (8) in D3.
  1. Every block's exposed (+62), finals (+66) and +134 lists cleared.
  2. Unless the routine has not been walked (first_walk, `tst.b
     (16,A5); bmi'), each live range's segments: the references from
     instructions the last walk did not mark (+2 bit 6 clear) unlinked
     from refs; a read before any kept write sets the segment's exposed
     (+3 bit 7) and the live range's +3 bit 4; the writes are counted
     (+3 bit 1: exactly one); a segment left without references taken
     off the live range's list and out of the chain from its +44's +28
     (the exposed segments the final one reaches); the others lose rrp
     modify, write, read and intend_to_modify (`and.w #0xFFC3') and
     first_in_bb and final (`andi.w #0xFFAF' of +2).  The live range
     loses the same rrp bits, its id (+4) and its hints and lists
     (+64 .. +84).
  3. zero_init: the routine's node's +379 bit 4 or lir_main_c8c, and
     cargs' -ZERO (+0x288 bit 5).  A live range that is not complex
     yet becomes complex when its +3 bit 7 is set, it is one of the
     routine's live ranges at +140, +144 or +108, or it has segments
     and (an exposed use (+3 bit 4) with zero_init or more than one
     segment, or its symbol, or its mate's, a memory home
     memory_home_is_initialized_fsym says is initialized): its
     segments then go on their blocks' lists (the first in each block
     on finals with first_in_bb set, the exposed ones on exposed, every
     one on +134); a segment in a block of order 0 is dropped (its
     exposed flag cleared).  The segments of a live range not made
     complex but with several go on their blocks' +134 lists only.
  4. Each block's +134 segments back on their live ranges' lists (so in
     block order), its finals on their live ranges' finals (first_in_bb
     set); unless first_walk, the block's instructions lose their marks
     (+2 bit 6, +24, +16).
  5. In the order of the routine's +72 (chained at +114), each block's
     exposed segments on their live ranges' exposed lists.
  6. lir_main_c86 := 1 (the lists by live range).

  The or-chain of step 3 is written as tests in the image's order (dpc
  gap 24 avoided). }

procedure df_utils_$canonicalize_lr_lts_lists(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  lr: lr_ptr_t;
  prev: lts_ptr_t;
  lts: lts_ptr_t;
  nx: lts_ptr_t;
  l: lts_ptr_t;
  last: opnd_ptr_t;
  op: opnd_ptr_t;
  instr: instr_ptr_t;
  writes: integer32;
  exposed_use: boolean;
  zero_init: boolean;
  complex: boolean;
  keep: boolean;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.exposed := nil;
    bb^.finals := nil;
    bb^.l134 := nil;
    bb := bb^.next;
  end;

  if not first_walk then begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      writes := 0;
      exposed_use := false;
      prev := nil;
      lts := lr^.ltss;
      while lts <> nil do begin
        last := nil;
        op := lts^.refs;
        while op <> nil do begin
          instr := instr_ptr_t(integer32(op) - 32 - op^.h.num * 12);
          if not instr^.h.b2_6 then begin
            if last = nil then
              lts^.refs := op^.link
            else
              last^.link := op^.link;
          end
          else begin
            if not op^.h.read then
              writes := writes + 1
            else if last = nil then begin
              exposed_use := true;
              lts^.f2.exposed := true;
            end;
            last := op;
          end;
          op := op^.link;
        end;
        if last = nil then
          lts^.refs := nil;
        if lts^.refs = nil then begin
          if prev = nil then
            lr^.ltss := lts^.next
          else
            prev^.next := lts^.next;
          l := lts_ptr_t(lts^.l44);
          if l <> nil then begin
            if l^.l28 = lts then
              l^.l28 := lts^.l28
            else begin
              l := l^.l28;
              while (l <> nil) and then (l^.l28 <> lts) do
                l := l^.l28;
              if l <> nil then
                l^.l28 := lts^.l28;
            end;
          end;
        end
        else begin
          lts^.rrp := lts^.rrp - [rrp$modify, rrp$write, rrp$read,
                                  rrp$intend_to_modify];
          lts^.f2.first_in_bb := false;
          lts^.f2.final := false;
          prev := lts;
        end;
        lts := lts^.next;
      end;
      lr^.rrp := lr^.rrp - [rrp$modify, rrp$write, rrp$read,
                            rrp$intend_to_modify];
      lr^.f2.b3_4 := exposed_use;
      lr^.f2.b3_1 := writes = 1;
      lr^.id := 0;
      lr^.exposed := nil;
      lr^.exposed_hint := nil;
      lr^.exposed_prev := nil;
      lr^.finals := nil;
      lr^.final_hint := nil;
      lr^.final_prev := nil;
      lr := lr^.next;
    end;
  end;

  zero_init := (il_180^.blk_atts.never_entered_recursively or lir_main_c8c)
               and (2 in cargs_$options.flags_286);
  lr := rtn^.lrs;
  while lr <> nil do begin
    lts := lr^.ltss;
    if lr^.f2.physical_register or (lr = rtn^.lr140) or (lr = rtn^.memory_lr)
       or (lr = rtn^.db_lr) then
      complex := true
    else if lts = nil then
      complex := false
    else if lr^.f2.b3_4 and (zero_init or (lts^.next <> nil)) then
      complex := true
    else if memory_home_is_initialized_fsym(il_$node_ptr_t(lr^.memory_home)) then
      complex := true
    else if lr^.mate = nil then
      complex := false
    else
      complex := memory_home_is_initialized_fsym(
                     il_$node_ptr_t(lr^.mate^.memory_home));
    if complex then begin
      lr^.ltss := nil;
      bv_$make_live_range_complex(rtn, lr);
      bb := nil;
      while lts <> nil do begin
        nx := lts^.next;
        keep := true;
        if lts^.bb <> bb then begin
          if lts^.bb^.order = 0 then begin
            lts^.f2.exposed := false;
            keep := false;
          end
          else begin
            bb := lts^.bb;
            lts^.next_final := bb^.finals;
            bb^.finals := lts;
            lts^.f2.first_in_bb := true;
          end;
        end;
        if keep then begin
          if lts^.f2.exposed then begin
            lts^.next_exposed := bb^.exposed;
            bb^.exposed := lts;
          end;
          lts^.next := lts_ptr_t(bb^.l134);
          bb^.l134 := lts;
        end;
        lts := nx;
      end;
    end
    else if (lts <> nil) and then (lts^.next <> nil) then begin
      lr^.ltss := nil;
      repeat
        nx := lts^.next;
        bb := lts^.bb;
        lts^.next := lts_ptr_t(bb^.l134);
        bb^.l134 := lts;
        lts := nx;
      until lts = nil;
    end;
    lr := lr^.next;
  end;

  bb := rtn^.bbs;
  while bb <> nil do begin
    lts := lts_ptr_t(bb^.l134);
    bb^.l134 := nil;
    while lts <> nil do begin
      lr := lts^.lr;
      nx := lts^.next;
      lts^.next := lr^.ltss;
      lr^.ltss := lts;
      lts := nx;
    end;
    lts := bb^.finals;
    bb^.finals := nil;
    while lts <> nil do begin
      lr := lts^.lr;
      lts^.f2.first_in_bb := true;
      nx := lts^.next_final;
      lts^.next_final := lr^.finals;
      lr^.finals := lts;
      lts := nx;
    end;
    if not first_walk then begin
      instr := bb^.first;
      while instr <> nil do begin
        instr^.h.b2_6 := false;
        instr^.l24 := 0;
        instr^.l16 := 0;
        instr := instr^.next;
      end;
    end;
    bb := bb^.next;
  end;

  bb := rtn^.bbs72;
  while bb <> nil do begin
    lts := bb^.exposed;
    bb^.exposed := nil;
    while lts <> nil do begin
      lr := lts^.lr;
      nx := lts^.next_exposed;
      lts^.next_exposed := lr^.exposed;
      lr^.exposed := lts;
      lts := nx;
    end;
    bb := bb^.next114;
  end;
  lir_main_c86 := 1;
end;

{ rebuild_bb_exposed_and_final_lists - lr's segments on their blocks'
  exposed and final lists by their flags (lr's own lists cleared), the
  segments without references dropped from lr's list; whether one was
  exposed.

  0x22EBB4, 0x74 bytes: lr (8) in D1; `st D0' at an exposed one. }

function rebuild_bb_exposed_and_final_lists(
    lr: lr_ptr_t): boolean; options(val_param); internal;
var
  exposed: boolean;
  prev: lts_ptr_t;
  lts: lts_ptr_t;
  bb: bb_ptr_t;
begin
  lr^.exposed := nil;
  lr^.finals := nil;
  exposed := false;
  prev := nil;
  lts := lr^.ltss;
  while lts <> nil do begin
    if lts^.refs <> nil then begin
      bb := lts^.bb;
      if lts^.f2.exposed then begin
        exposed := true;
        lts^.next_exposed := bb^.exposed;
        bb^.exposed := lts;
      end;
      if lts^.f2.final then begin
        lts^.next_final := bb^.finals;
        bb^.finals := lts;
      end;
      prev := lts;
    end;
    lts := lts^.next;
    if prev <> nil then
      prev^.next := lts
    else
      lr^.ltss := lts;
  end;
  rebuild_bb_exposed_and_final_lists := exposed;
end;

{ process_marked_instructions - until the queue is empty: its head
  taken off and marked (+2 bit 6), and each register or memory operand
  (kinds 1..11: the mask 0xFFE) merges its rrp byte (+1) into its
  segment's and live range's rrp; for a complex live range a read whose
  segment's definition also reads sets the live range's bit in the
  block's live_gen (+90), a write in its +110; then the segment is
  walked (mark_lts(lts, bb, nil)).

  0x22EC28, 0xDE bytes.  The head taken (`move.l #0,(4,A5)' when it is
  the tail, else its +24); the operands by `dbf' over the count (+1
  less one, a borrow from the high word: rev889-patterns 17) with the
  operand's offset in D3 from 12. }

procedure process_marked_instructions; internal;
var
  instr: instr_ptr_t;
  k: integer32;
  op: opnd_ptr_t;
  lts: lts_ptr_t;
  lr: lr_ptr_t;
  bb: bb_ptr_t;
begin
  while head <> nil do begin
    instr := head;
    if head = tail then
      head := nil
    else
      head := instr_ptr_t(head^.l24);
    instr^.h.b2_6 := true;
    for k := 1 to instr^.h.nopnds do begin
      op := addr(instr^.opnds[k]);
      if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
        lts := op^.lts;
        lr := lts^.lr;
        bb := lts^.bb;
        lts^.rrp := rrp$set_t(integer(lts^.rrp)
                              ! opnd_bytes_ptr_t(op)^.rrp);
        lr^.rrp := rrp$set_t(integer(lr^.rrp)
                             ! opnd_bytes_ptr_t(op)^.rrp);
        if lr^.id <> 0 then begin
          if op^.h.read then begin
            if lts^.refs^.h.read then
              bv_$set(bb^.live_gen, lr);
          end
          else
            bv_$set(bb^.transparent, lr);
        end;
        mark_lts(lts, bb, nil);
      end;
    end;
  end;
end;

{ need_all_writes - every instruction that writes or modifies lr (a
  segment's rrp bits 3..2: `and.w (A2),D0' with 12) queued: the
  definition is the segment's refs.

  0x22ED06, 0x40 bytes: lr (8); the instruction kept in a frame slot. }

procedure need_all_writes(
    lr: lr_ptr_t); options(val_param); internal;
var
  lts: lts_ptr_t;
  instr: instr_ptr_t;
begin
  lts := lr^.ltss;
  while lts <> nil do begin
    if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then begin
      instr := utils_ins_$operands_instruction(lts^.refs);
      enqueue_instruction(instr);
    end;
    lts := lts^.next;
  end;
end;

{ do_global_walk - the walk.

  0x22ED46, 0x2C0 bytes: rtn (8) in D5, nlrs (12), how (16, a word, in
  D4: lir_main_c86's next value), async (18, a byte, in D3).  The
  routine's +192 := nlrs; the dfa bit vectors made; the lists made
  canonical; lir_main_c8d saved in D2 and set (`st'); the live ranges
  at +100 and +112 made complex; first_walk cleared (`move.b #0'); the
  mark the routine's marks (+180) counted up; the queue emptied
  (`move.l #0' each).  The memory live range (+144) must be complex
  (bug_check), is live out of the block at +80 and gets +3 bit 4.  Each
  block in the +72 order (chained at +114) queues its special
  instructions, a label getting +3 bit 6.  With async: the live ranges
  lir_utils_$get_next_async_exposed_lr gives (from the routine's map,
  +60) that are registers (rrp bits 15..14), not the +112 one and
  without +3 bit 7 have their writes (and their mates') queued; then
  the instructions chained from lir_main_c44 (at their +32, cleared),
  and lir_main_c44 cleared.  Last the exposed and final lists: by live
  range (how 1: each live range's finals filtered to the segments still
  final) or by block (rebuild_bb_exposed_and_final_lists; a pair's two
  live ranges handled when the second is met, its mate's rrp life_mark
  (bit 8, `bset #0,(A2)') telling): a register live range left with no
  exposed segment, without +3 bit 7 and other than the routine's +108
  loses +3 bit 4 and its id (of a pair, only if the mate has none
  either).  lir_main_c8d restored.

  Not known from the original: what +80, +100, +108, +112, +140 and
  +144 of the routine hold beyond what is used here (the +112 field is
  backend.ins.pas's l112, which zzzzz compares with a segment). }

procedure do_global_walk(
    rtn: rtn_ptr_t;
    nlrs: integer32;
    how: integer;
    async: boolean); options(val_param); internal;
var
  saved_c8d: boolean;
  bb: bb_ptr_t;
  instr: instr_ptr_t;
  nxt: instr_ptr_t;
  lr: lr_ptr_t;
  mate: lr_ptr_t;
  cursor: univ_ptr;
  k: integer32;
  lts: lts_ptr_t;
  l: lts_ptr_t;
  lnext: lts_ptr_t;
  r1: boolean;
  r2: boolean;
begin
  rtn^.l192 := nlrs;
  bv_$create_dfa_bit_vectors(rtn);
  df_utils_$canonicalize_lr_lts_lists(rtn);
  saved_c8d := lir_main_c8d;
  lir_main_c8d := true;
  bv_$make_live_range_complex(rtn, rtn^.ap_lr);
  bv_$make_live_range_complex(rtn, lr_ptr_t(rtn^.l112));
  first_walk := false;
  rtn^.marks := rtn^.marks + 1;
  mark := rtn^.marks;
  head := nil;
  tail := nil;
  if rtn^.memory_lr^.id = 0 then
    bug_check('DF_UTILS_$DO_GLOBAL_WALK: Memory LR is not complex%$');
  mark_tail(rtn^.memory_lr, rtn^.bb80);
  rtn^.memory_lr^.f2.b3_4 := true;
  bb := rtn^.bbs72;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      if special_p(instr, bb) then begin
        if instruction_attributes[instr^.opc].class = class$label then
          instr^.h.width := instr^.h.width ! 16#40;
        enqueue_instruction(instr);
      end;
      instr := instr^.next;
    end;
    bb := bb^.next114;
  end;
  process_marked_instructions;

  if async then begin
    lr := nil;
    cursor := nil;
    repeat
      k := lir_utils_$get_next_async_exposed_lr(rtn, lr, cursor);
      if k <> 0 then begin
        lr := rtn^.lr_map^[k];
        if ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> [])
           and (lr <> lr_ptr_t(rtn^.l112)) and not lr^.f2.physical_register then begin
          need_all_writes(lr);
          if lr^.mate <> nil then
            need_all_writes(lr^.mate);
        end;
      end;
    until k = 0;
    instr := instr_ptr_t(lir_main_c44);
    while instr <> nil do begin
      enqueue_instruction(instr);
      nxt := instr_ptr_t(instr^.l32);
      instr^.l32 := 0;
      instr := nxt;
    end;
    lir_main_c44 := nil;
    process_marked_instructions;
  end;

  lir_main_c86 := how;
  if how = 1 then begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      l := nil;
      lts := lr^.finals;
      lr^.finals := nil;
      lr^.final_hint := nil;
      lr^.final_prev := nil;
      while lts <> nil do begin
        lnext := lts^.next_final;
        lts^.next_final := nil;
        if lts^.f2.final then begin
          if l = nil then
            lr^.finals := lts
          else
            l^.next_final := lts;
          l := lts;
        end;
        lts := lnext;
      end;
      lr := lr^.next;
    end;
  end
  else begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      mate := lr^.mate;
      if mate = nil then begin
        if not rebuild_bb_exposed_and_final_lists(lr) then begin
          lr^.f2.b3_4 := false;
          if ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> [])
             and not lr^.f2.physical_register and (lr <> rtn^.db_lr) then
            lr^.id := 0;
        end;
      end
      else if not (rrp$life_mark in mate^.rrp) then
        lr^.rrp := lr^.rrp + [rrp$life_mark]
      else begin
        mate^.rrp := mate^.rrp - [rrp$life_mark];
        r1 := rebuild_bb_exposed_and_final_lists(lr);
        r2 := rebuild_bb_exposed_and_final_lists(mate);
        if not r1 then begin
          lr^.f2.b3_4 := false;
          if ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> [])
             and not lr^.f2.physical_register and not r2 then
            lr^.id := 0;
        end;
        if not r2 then begin
          mate^.f2.b3_4 := false;
          if ((mate^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> [])
             and not mate^.f2.physical_register and not r1 then
            mate^.id := 0;
        end;
      end;
      lr := lr^.next;
    end;
  end;
  lir_main_c8d := saved_c8d;
end;

{ df_utils_$global_walk - the walk without async protection.
  0x22F03A, 0x36 bytes: level (18) stored at (8,A5); how passed on as
  a word, false as a cleared word. }

procedure df_utils_$global_walk(
    rtn: rtn_ptr_t;
    nlrs: integer32;
    how: integer;
    level: integer32);
begin
  walk_level := level;
  do_global_walk(rtn, nlrs, how, false);
end;

{ df_utils_$global_walk_with_async_protection - the walk with the
  writes an exception handler may see kept.  0x22F070, 0x36 bytes
  (`st -(SP)'). }

procedure df_utils_$global_walk_with_async_protection(
    rtn: rtn_ptr_t;
    nlrs: integer32;
    how: integer;
    level: integer32);
begin
  walk_level := level;
  do_global_walk(rtn, nlrs, how, true);
end;
