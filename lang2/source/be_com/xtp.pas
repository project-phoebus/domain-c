{ xtp - the XTP phase of the PRISM back end (at_backend's phase table
  entry 11, 'x', "XTP"): after register allocation, the spill of the
  live ranges that pass through, the flow graph cleaned (empty blocks
  forwarded, senseless loops ended, the hammocks found again), the
  IPCCNOPs the instructions that need one get, and the snuggle moves.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x287ABC  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x287ADE  cc_mentioned (internal)
    --------  0x287B22  insert_ipccnop (internal)
    --------  0x287DA8  xtp_$begin_compilation
    --------  0x287DAA  xtp_$end_compilation
    --------  0x287DAC  xtp_$process_routine
    --------  0x287F7E  xtp_$end_routine
    A5 0x492FEC (zzzzz's): the module has no data.

  insert_ipccnop's messages name SCHED_$insert_ipccnop: the routine was
  sched's once, most likely.

  Not known from the original: the parameters' and locals' names. }
module xtp;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  { What a live range holds (its sym: an IL node) as xtp reads it: the
    kind (+2), and a longword of flags at +24, at +32 for a VAR_NAME
    (kind 109). }
  xtp_sym_ptr_t = ^xtp_sym_t;
  xtp_sym_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [4..23] of char;    { +4 }
    flags24: integer32;                 { +24 }
    unused_28: integer32;               { +28 }
    flags32: integer32;                 { +32 }
  end;

{ cc_mentioned - whether one of instr's operands is the condition codes
  (operand$ip_condition_codes).

  0x287ADE, 0x44 bytes, internal: instr by value; the operands from the
  first (+44, the kind at +47: `moveq #31; and.b (35,A0)' with A0 the
  instruction plus 12k) by `dbf' over nopnds (+1); `st' or `clr.b'. }

function cc_mentioned(
    instr: instr_ptr_t): boolean; options(val_param); internal;
var
  k: integer32;
begin
  cc_mentioned := false;
  for k := 1 to instr^.h.nopnds do
    if instr^.opnds[k].h.kind = operand$ip_condition_codes then begin
      cc_mentioned := true;
      return;
    end;
end;

{ insert_ipccnop - an IPCCNOP after instr (which marks itself as needing
  one: it sets the condition codes), unless its condition code
  segment needs none or the instruction
  that defines it is an MFNEXTCC: the IPCCNOP reads instr's condition
  codes (operand 2, tied to their definition) and defines a new segment
  of them (operand 1, after instr's in the block), which instr's
  condition code operand is tied to from then on.

  0x287B22, 0x20E bytes, internal: instr by value (A3).  The last
  condition code operand (from operand nopnds down: `lea (32,A3,D0.l)'
  with D0 12k) in D4; bug_check without one.  When the operand is tied
  to nothing (+4 nil) and its segment's +3 bit 4 is clear, nothing.
  When tied, the defining instruction (utils_ins_$operands_instruction):
  bug_check if it is an IPCCNOP (194), nothing if an MFNEXTCC (111).
  The IPCCNOP's anchor: instr, or, when instr's block's +17 bit 5 is
  set, the last of instr's group (+0 bit 2, along next) and, unless
  that one mentions the condition codes, the instruction after it,
  with `after' then false when that one's class is 3, 8 or 17
  (`btst' in 0x20108).  lir_$optimizer_new_instruction(anchor, 194,
  after); in such a block the new one's group bit (+0 bit 2) is the
  anchor's (when after) or set.  Operand 2: the condition code
  operand's segment (+64) and tie (+60), kind 7 (+59 bits 4..0), num 2,
  +57 bit 2 set; its segment's rrp loses write and gets modify (`and.w
  #-9; or.w #4'), its def the operand.  Operand 1: a new segment
  (lir_utils_$add_lts_after_lts(the old segment, 0, instr's block)) at
  +52, kind 7, num 1, +45 bits 5..4 set; the new segment's rrp gets
  the old operand's +1 bits 3..2 and 0x30, its def the old operand;
  the old operand's segment becomes the new one and its tie the new
  operand 1; the new segment's live range (+48) rrp gets 0x34. }

procedure insert_ipccnop(
    instr: instr_ptr_t); options(val_param); internal;
var
  k: integer32;
  cc: opnd_ptr_t;
  def: instr_ptr_t;
  anchor: instr_ptr_t;
  after: boolean;
  nop: instr_ptr_t;
  lts: lts_ptr_t;
begin
  cc := nil;
  for k := instr^.h.nopnds downto 1 do
    if instr^.opnds[k].h.kind = operand$ip_condition_codes then begin
      cc := addr(instr^.opnds[k]);
      exit;
    end;
  if cc = nil then
    bug_check('SCHED_$insert_ipccnop: no IP CC operand (%3ZWD:%3ZWD)%$',
              instr^.bb^.num, instr^.num);
  if cc^.link = nil then begin
    if not cc^.lts^.f2.final then
      return;
  end
  else begin
    def := utils_ins_$operands_instruction(cc^.link);
    if def^.opc = 194 then
      bug_check('SCHED_$insert_ipccnop: IPCCNOP already present (%3ZWD:%3ZWD)%$',
                instr^.bb^.num, instr^.num);
    if def^.opc = 111 then
      return;
  end;
  anchor := instr;
  after := true;
  if instr^.bb^.f.b17_5 then begin
    while anchor^.h.grouped do
      anchor := anchor^.next;
    if anchor^.next <> nil then
      if not cc_mentioned(anchor) then begin
        anchor := anchor^.next;
        after := not (instruction_attributes[anchor^.opc].class
                      in [3, 8, 17]);
      end;
  end;
  nop := lir_$optimizer_new_instruction(anchor, 194, after);
  if instr^.bb^.f.b17_5 then begin
    if after then
      nop^.h.grouped := anchor^.h.grouped
    else
      nop^.h.grouped := true;
  end;
  nop^.opnds[2].lts := cc^.lts;
  with nop^.opnds[2] do begin
    link := cc^.link;
    h.kind := operand$ip_condition_codes;
    h.num := 2;
    h.modify := true;
  end;
  with nop^.opnds[2].lts^ do
    rrp := rrp - [rrp$write] + [rrp$modify];
  nop^.opnds[2].lts^.refs := addr(nop^.opnds[2]);
  lts := lir_utils_$add_lts_after_lts(cc^.lts, 0, instr^.bb);
  nop^.opnds[1].lts := lts;
  with nop^.opnds[1] do begin
    h.kind := operand$ip_condition_codes;
    h.num := 1;
    h.intend_to_modify := true;
    h.read := true;
  end;
  lts^.rrp := lts^.rrp + [rrp$read, rrp$intend_to_modify];
  if cc^.h.write then
    lts^.rrp := lts^.rrp + [rrp$write];
  if cc^.h.modify then
    lts^.rrp := lts^.rrp + [rrp$modify];
  lts^.refs := cc;
  cc^.lts := lts;
  cc^.link := addr(nop^.opnds[1]);
  lts^.lr^.rrp := lts^.lr^.rrp + [rrp$modify, rrp$read, rrp$intend_to_modify];
end;

{ xtp_$begin_compilation - nothing.  0x287DA8, 2 bytes. }

procedure xtp_$begin_compilation;
begin
end;

{ xtp_$end_compilation - nothing.  0x287DAA, 2 bytes. }

procedure xtp_$end_compilation;
begin
end;

{ xtp_$process_routine - the phase.

  0x287DAC, 0x1D2 bytes: the routine in D3.  Sanity check; the old join
  birthpoints dropped; every live range whose sym's flags (+32 for a
  VAR_NAME, 109; else +24) have bit 13 loses its sym.  Unless switch 10
  (`btst #2,0x485D30'): when ra_utils_$spill_pass_through_lrs(the
  switches' level) spills, lir_main_c86 := 1, the dominators and dfs
  lists again (2, 0), sanity check, the hammocks, life, the join
  birthpoints dropped.  Unless lir_main_da4 or switch 9: the global
  walk (the routine's +192, 0, 0) and a sanity check when lir_main_c84
  is 0; empty blocks forwarded (changed in D2: then the dominators again,
  1, 0); when senseless loops were ended, a sanity check if D2, the
  empty blocks forwarded again (the result dropped), the dominators
  again, and D2 set; when D2, a sanity check and the hammocks.  Then
  the bit vectors released, an IPCCNOP for each instruction that needs
  one (+0 bit 4; the next one taken first), block by block in code
  order (+76, chained at +118; the instructions from +34 along +4);
  last the snuggle moves unless the 's' debug word's bit 15 (cargs
  +0x264: `tst.b; bmi'). }

procedure xtp_$process_routine(
    rtn: rtn_ptr_t);
var
  lr: lr_ptr_t;
  sym: xtp_sym_ptr_t;
  flags: integer32;
  changed: boolean;
  bb: bb_ptr_t;
  instr, next: instr_ptr_t;
begin
  lir_utils_$sanity_check(rtn);
  fg_utils_$drop_old_join_birthpoints(rtn);
  lr := rtn^.lrs;
  while lr <> nil do begin
    if lr^.memory_home <> nil then begin
      sym := lr^.memory_home;
      if sym^.kind = 109 then
        flags := sym^.flags32
      else
        flags := sym^.flags24;
      if (flags & 16#2000) <> 0 then
        lr^.memory_home := nil;
    end;
    lr := lr^.next;
  end;
  if not at_backend_switches.sw10 then
    if ra_utils_$spill_pass_through_lrs(rtn, at_backend_switches.level)
    then begin
      lir_main_c86 := 1;
      fg_utils_$recompute_dominators_and_dfs_lists(rtn, 2, 0);
      lir_utils_$sanity_check(rtn);
      hal_$find_hammocks(rtn);
      life_$process_routine(rtn);
      fg_utils_$drop_old_join_birthpoints(rtn);
    end;
  if not lir_main_da4 and not at_backend_switches.sw9 then begin
    if lir_main_c84 = 0 then begin
      df_utils_$global_walk(rtn, rtn^.l192, 0, 0);
      lir_utils_$sanity_check(rtn);
    end;
    changed := fg_utils_$forward_empty_blocks(rtn);
    if changed then
      fg_utils_$recompute_dominators_and_dfs_lists(rtn, 1, 0);
    if fg_utils_$end_senseless_loops(rtn) then begin
      if changed then
        lir_utils_$sanity_check(rtn);
      discard(fg_utils_$forward_empty_blocks(rtn));
      fg_utils_$recompute_dominators_and_dfs_lists(rtn, 1, 0);
      changed := true;
    end;
    if changed then begin
      lir_utils_$sanity_check(rtn);
      hal_$find_hammocks(rtn);
    end;
  end;
  bv_$release_bit_vectors(rtn);
  bb := rtn^.bbs;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      next := instr^.next;
      if instr^.h.sets_cc then
        insert_ipccnop(instr);
      instr := next;
    end;
    bb := bb^.next;
  end;
  if cargs_$debug_switches['s'] >= 0 then
    sched_utils_$insert_snuggle_moves(rtn);
end;

{ xtp_$end_routine - nothing.  0x287F7E, 2 bytes. }

procedure xtp_$end_routine(
    rtn: rtn_ptr_t);
begin
end;
