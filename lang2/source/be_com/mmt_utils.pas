{ mmt_utils - the memory model (MMT) phase's utilities: memory live
  ranges kept for reuse, the MMT_SEQ instructions (kept by operand
  count for reuse) and their tokens, the address comparisons and the
  analysis of the blocks' memory references (com, oli, mmt).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x2551D8  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x2551FA  zero (internal)
    --------  0x255210  mmt_utils_$begin_compilation
    --------  0x255212  mmt_utils_$init_for_routine
    --------  0x25524E  mmt_utils_$end_routine
    --------  0x255250  mmt_utils_$end_compilation
    --------  0x255252  mmt_utils_$save_mem_lr (internal)
    --------  0x25526C  mmt_utils_$save_unneeded_lrs (internal)
    --------  0x2552E0  mmt_utils_$mark_lr_for_removal (internal)
    --------  0x2552F6  mmt_utils_$get_mem_lr
    --------  0x255364  mmt_utils_$lr_is_for_memory
    --------  0x2553BA  mmt_utils_$save_mmt_seq_instruction (internal)
    --------  0x2553E4  mmt_utils_$get_mmt_seq_instruction (internal)
    --------  0x2554A8  add_operand (internal)
    --------  0x255534  build_mmt_seq_instr (internal)
    A5 0x48C544: the module's data (0x80 bytes): the MMT_SEQ
    instructions kept for reuse by operand count (+0, 21 chains, 0 for
    more than 20), the memory live ranges kept for reuse (+100), +120
    (a live range was marked for removal), +122; mmt's cells +0xC8 and
    +0xCC (mmt.pvt.pas) reached absolutely.

  Not known from the original: every local and parameter name, the
  module cells' names. }

{ TODO(pascal) mmt_utils: 15 of the image's 37 routines.  Remaining:
  mmt_utils_$mmt_seq_emit (0x255576), mmt_seq_add_token (0x255942),
  mmt_seq_add_tokens_from_instr (0x255A0C), mmt_seq_add_tokens_from_bv
  (0x255A90), can_combine_mmt_seqs (0x255B04), get_base_and_index
  (0x255C04), disp_known (0x255C68), addr_compare (0x255DA8),
  set_address_comparison_function (0x25601A), allocate_descriptor
  (0x256054), compared_already (0x256300), ids_related (0x2563A0),
  inform_about_relationships (0x25642A), mark_related_references
  (0x256516), discover_relationships (0x256636),
  free_mmt_seqs_and_ltss (0x256AB8), bind_new_tokens_to_operands
  (0x256D10), insert_mmt_seqs (0x256F6A), fill_in_ltss (0x2572C6),
  count_and_bind_complex_lrs (0x257824), analyze_one_bb (0x25789E),
  analyze_blocks (0x257CEC); with them mmt's cells +0xC0..+0x1A8 in
  mmt.pvt.pas. }
module mmt_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/mmt.pvt.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  mu_heap_ptr_t = ^mrh_$heap_t;

var
  mu_seqs: array [0..20] of instr_ptr_t;  { +0 }
  mu_54: array [21..24] of integer32;     { +0x54 }
  mu_free_lrs: lr_ptr_t;                  { +100 }
  mu_68: array [0..4] of integer32;       { +0x68 }
  mu_removal: boolean;                    { +120 }
  mu_122: boolean;                        { +122 }

{ zero - n bytes from p cleared ((n + 3) div 4 longwords; nothing for
  0).  0x2551FA, 0x16 bytes, no frame (zzzzz's and at_backend's have
  the same code). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
  longs_ptr_t = ^longs_t;
var
  k: integer32;
  q: longs_ptr_t;
begin
  q := p;
  for k := 1 to (n + 3) div 4 do
    q^[k] := 0;
end;

{ mmt_utils_$begin_compilation - nothing.  0x255210, 2 bytes. }

procedure mmt_utils_$begin_compilation;
begin
end;

{ mmt_utils_$init_for_routine - no live ranges kept, none marked, +122
  cleared, no address comparison function (nil, 0), the instruction
  chains cleared (84 bytes from +0).

  0x255212, 0x3C bytes: `move.l #0' and `move.b #0' of the cells. }

procedure mmt_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
  mu_free_lrs := nil;
  mu_122 := false;
  mu_removal := false;
  mmt_utils_$set_address_comparison_function(nil, 0);
  zero(addr(mu_seqs), 84);
end;

{ mmt_utils_$end_routine - nothing.  0x25524E, 2 bytes. }

procedure mmt_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ mmt_utils_$end_compilation - nothing.  0x255250, 2 bytes. }

procedure mmt_utils_$end_compilation;
begin
end;

{ mmt_utils_$save_mem_lr - lr kept for reuse (first on +100, chained at
  its +12), no longer in use (+3 bit 3) and without segments.

  0x255252, 0x1A bytes, no frame, no A5 (its callers'). }

procedure mmt_utils_$save_mem_lr(
    lr: lr_ptr_t); options(val_param); internal;
begin
  lr^.next := mu_free_lrs;
  mu_free_lrs := lr;
  lr^.f2.b3_3 := false;
  lr^.ltss := nil;
end;

{ mmt_utils_$save_unneeded_lrs - when a live range was marked for
  removal, the routine's live ranges not in use (+3 bit 3 clear) taken
  off its list (+52, the last at +56) and kept for reuse.

  0x25526C, 0x74 bytes, no A5 (its callers'): the removed one's
  successor stored and tested (`bne' after the `move.l'). }

procedure mmt_utils_$save_unneeded_lrs; internal;
var
  lr, nxt, prev: lr_ptr_t;
begin
  if mu_removal then begin
    mu_removal := false;
    lr := mmt_rtn^.lrs;
    prev := nil;
    while lr <> nil do begin
      nxt := lr^.next;
      if lr^.f2.b3_3 then
        prev := lr
      else begin
        if prev = nil then
          mmt_rtn^.lrs := nxt
        else
          prev^.next := nxt;
        if nxt = nil then
          mmt_rtn^.lrs_last := prev;
        mmt_utils_$save_mem_lr(lr);
      end;
      lr := nxt;
    end;
  end;
end;

{ mmt_utils_$mark_lr_for_removal - lr no longer in use (+3 bit 3),
  without segments; +120 set.  0x2552E0, 0x16 bytes, no frame, no A5. }

procedure mmt_utils_$mark_lr_for_removal(
    lr: lr_ptr_t); options(val_param); internal;
begin
  lr^.f2.b3_3 := false;
  lr^.ltss := nil;
  mu_removal := true;
end;

{ mmt_utils_$get_mem_lr - a live range for memory: a kept one (cleared,
  88 bytes, but its +6, in use, appended to the routine's list) or a
  new one (lir_$new_live_range).

  0x2552F6, 0x6E bytes. }

function mmt_utils_$get_mem_lr: lr_ptr_t;
var
  lr: lr_ptr_t;
  w: integer32;
begin
  if mu_free_lrs <> nil then begin
    lr := mu_free_lrs;
    mu_free_lrs := lr^.next;
    w := lr^.w6;
    zero(lr, 88);
    lr^.w6 := w;
    lr^.f2.b3_3 := true;
    mmt_rtn^.lrs_last^.next := lr;
    mmt_rtn^.lrs_last := lr;
    mmt_utils_$get_mem_lr := lr;
  end
  else
    mmt_utils_$get_mem_lr := lir_$new_live_range;
end;

{ mmt_utils_$lr_is_for_memory - whether lr holds memory: not pinned (+3
  bit 7), neither an integer nor a floating register (rrp 16#C000), and
  its first segment's def (if any) not of the argument block (kind 9).

  0x255364, 0x56 bytes. }

function mmt_utils_$lr_is_for_memory(
    lr: lr_ptr_t): boolean;
begin
  if lr^.f2.b3_7 or ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) <> []) then
    mmt_utils_$lr_is_for_memory := false
  else if lr^.ltss = nil then
    mmt_utils_$lr_is_for_memory := true
  else if lr^.ltss^.def = nil then
    mmt_utils_$lr_is_for_memory := true
  else if lr^.ltss^.def^.h.kind = operand$argument_block_memory then
    mmt_utils_$lr_is_for_memory := false
  else
    mmt_utils_$lr_is_for_memory := true;
end;

{ mmt_utils_$save_mmt_seq_instruction - an MMT_SEQ instruction kept for
  reuse on the chain of its operand count (+4; chain 0 for more than
  20).  0x2553BA, 0x2A bytes, no frame, no A5. }

procedure mmt_utils_$save_mmt_seq_instruction(
    instr: instr_ptr_t); options(val_param); internal;
var
  k: integer32;
begin
  if instr^.h.nopnds > 20 then
    k := 0
  else
    k := instr^.h.nopnds;
  instr^.next := mu_seqs[k];
  mu_seqs[k] := instr;
end;

{ mmt_utils_$get_mmt_seq_instruction - an MMT_SEQ instruction of n
  operands: a kept one of n (n at most 20), else from chain 0 the one
  of exactly n or the smallest above (its predecessor noted at +8 while
  searching, then unlinked), else a new one from lir_main_heap (44 + 12n
  bytes).

  0x2553E4, 0xC4 bytes, no A5 (its callers'): the counts compared
  unsigned (`bls'). }

function mmt_utils_$get_mmt_seq_instruction(
    n: integer32): instr_ptr_t; options(val_param); internal;
var
  i, prev, best: instr_ptr_t;
  c: integer32;
begin
  if n <= 20 then begin
    i := mu_seqs[n];
    if i <> nil then
      mu_seqs[n] := i^.next;
  end
  else begin
    i := mu_seqs[0];
    prev := nil;
    best := nil;
    while i <> nil do begin
      c := i^.h.nopnds;
      if c = n then begin
        i^.prev := prev;
        best := i;
        exit;
      end;
      if c > n then
        if (best = nil) or (best^.h.nopnds > i^.h.nopnds) then begin
          i^.prev := prev;
          best := i;
        end;
      prev := i;
      i := i^.next;
    end;
    if best <> nil then
      if best^.prev = nil then
        mu_seqs[0] := best^.next
      else
        best^.prev^.next := best^.next;
    i := best;
  end;
  if i = nil then
    i := mrh_$alloc(mu_heap_ptr_t(lir_main_heap)^, n * 12 + 44);
  mmt_utils_$get_mmt_seq_instruction := i;
end;

{ add_operand - the next operand (count up, at most instr's nopnds:
  bug_check) of an MMT_SEQ: number the count, rrp byte rrp, segment
  lts, kind 10 (inscrutable memory).

  0x2554A8, 0x66 bytes, no A5: the count a longword by address, its low
  word the index and its low byte the number. }

procedure add_operand(
    instr: instr_ptr_t;
    var count: integer32;
    lts: lts_ptr_t;
    rrp: integer); options(val_param); internal;
begin
  count := count + 1;
  if instr^.h.nopnds < count then
    bug_check('MMT_$add_operand: too many operands%$');
  instr^.opnds[count].h.num := count & 255;
  opnd_bytes_ptr_t(addr(instr^.opnds[count]))^.rrp := rrp & 255;
  instr^.opnds[count].lts := lts;
  instr^.opnds[count].h.kind := operand$inscrutable_memory;
end;

{ build_mmt_seq_instr - an MMT_SEQ (202) of n operands next to anchor,
  from mmt's heap (+0xCC, made lir_main_heap for the call), +2 bit 5
  set.  0x255534, 0x42 bytes, no A5. }

function build_mmt_seq_instr(
    anchor: instr_ptr_t;
    after: boolean;
    n: integer32): instr_ptr_t; options(val_param); internal;
var
  save: univ_ptr;
  i: instr_ptr_t;
begin
  save := lir_main_heap;
  lir_main_heap := addr(mmt_seq_heap);
  i := lir_$optimizer_new_n_opr_instr(anchor, ord(opc$mmt_seq), after, n);
  lir_main_heap := save;
  i^.h.b2_5 := true;
  build_mmt_seq_instr := i;
end;
