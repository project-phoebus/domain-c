{ sanity - the LIR's consistency checks (cc.a88k only): the segments'
  and live ranges' properties recomputed from their references, and
  the whole routine checked (lir_utils_$sanity_check, which most
  phases call first).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x271D30  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x271D52  sanity_$repair_lts_properties
    --------  0x271EC4  check_lts (internal)
    --------  0x2721B4  sanity_$check_entire_routine
    --------  0x273C46  lir_utils_$repair_lts_properties
    --------  0x273C6A  lir_utils_$sanity_check
    A5 0x48FD08: no data the routines use (sched's block follows).

  sanity_$repair_lts_properties and sanity_$check_entire_routine load
  A5 and are global though only this unit calls them.

  The messages go through at_backend's phase_bug_check and
  phase_instr_bug_check ("[%M12A]\" puts the phase's name first).  A
  segment's final flag (+3 bit 4) is what the messages call
  active_on_exit; +3 bit 3 marks a segment checked (check_lts).

  Not known from the original: every local and parameter name. }

{ TODO(pascal) sanity.pas: sanity_$check_entire_routine (0x2721B4, 0xD76
  bytes) is not translated yet (translator PA2 stopped at it); it is
  declared extern below so that lir_utils_$sanity_check compiles.  Its
  start: for each block in the +72 order (through next114) each
  instruction's +0 bit 0 := its +2 bit 6, the instructions of the
  block without +0 bit 0 excised (utils_$excise_instruction_cleanly,
  false), the block's +19 bit 1 cleared; then every block's
  instructions and operands are checked (check_lts is its helper). }
module sanity;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

{ SANITY_$CHECK_ENTIRE_ROUTINE - 0x2721B4, 0xD76 bytes: rtn (8).  Not
  translated yet (above). }
procedure sanity_$check_entire_routine(
    rtn: rtn_ptr_t); options(val_param); extern;

{ sanity_$repair_lts_properties - each segment's rrp modify, write,
  read and intend_to_modify recomputed as the union of its references'
  (bits 5..2: `and.w #0xFFC3', `and.w #60'), the live range's as the
  union of its segments'; the live range's +3 bit 1 set when exactly
  one segment's first reference writes or modifies (bits 3..2); the
  live ranges' and segments' +3 bit 2 cleared.  A segment on a live
  range's list must belong to it (phase_bug_check).

  0x271D52, 0xF4 bytes: rtn (8); the live range in D4, the count in
  D2, the live range's bits in D3.  The message's arguments by
  address: the segment's live range's number, the segment's number (a
  byte widened into a frame longword), its block's number, the live
  range's number. }

procedure sanity_$repair_lts_properties(
    rtn: rtn_ptr_t); options(val_param);
var
  lr: lr_ptr_t;
  count: integer32;
  acc: integer;
  lts: lts_ptr_t;
  n: integer32;
  op: opnd_ptr_t;
  bits: integer;
begin
  lr := rtn^.lrs;
  while lr <> nil do begin
    count := 0;
    acc := 0;
    lr^.f2.b3_2 := false;
    lts := lr^.ltss;
    while lts <> nil do begin
      if lts^.lr <> lr then begin
        n := lts^.f2.num;
        phase_bug_check('[%M12A]\SANITY_$REPAIR_LTS_PROPERTIES: LTS %3ZWD.%2ZLD (apparently in BB %3ZWD) found on LR %3ZWD''s lifetime_segments list%$',
                        lts^.lr^.num, n, lts^.bb^.num, lr^.num);
      end;
      lts^.f2.b3_2 := false;
      op := lts^.refs;
      bits := 0;
      if op <> nil then begin
        bits := opnd_bytes_ptr_t(op)^.rrp;
        if (bits & 12) <> 0 then
          count := count + 1;
        op := op^.link;
        while op <> nil do begin
          bits := bits ! opnd_bytes_ptr_t(op)^.rrp;
          op := op^.link;
        end;
      end;
      lts^.rrp := lts^.rrp - [rrp$modify..rrp$intend_to_modify]
                  + (rrp$set_t(bits) * [rrp$modify..rrp$intend_to_modify]);
      acc := acc ! bits;
      lts := lts^.next;
    end;
    lr^.rrp := lr^.rrp - [rrp$modify..rrp$intend_to_modify]
               + (rrp$set_t(acc) * [rrp$modify..rrp$intend_to_modify]);
    lr^.f2.b3_1 := count = 1;
    lr := lr^.next;
  end;
end;

{ check_lts - lts checked (not marked twice, not final in a live range
  that is not complex, not both even and odd only) and marked (+3 bit
  3, mark cleared); then its references from op on: each must be in
  lts's block and read lts (phase_instr_bug_check otherwise); those
  whose instruction the last walk did not mark (+2 bit 6) are
  unlinked (after prev, or from refs).

  0x271EC4, 0x16A bytes: lts (8), op (12) in D2, prev (16) in A3; the
  instruction in D3. }

procedure check_lts(
    lts: lts_ptr_t;
    op: opnd_ptr_t;
    prev: opnd_ptr_t); options(val_param); internal;
var
  n: integer32;
  instr: instr_ptr_t;
  nx: opnd_ptr_t;
begin
  if lts^.f2.b3_3 then begin
    n := lts^.f2.num;
    phase_bug_check('[%M12A]\CHECK_LTS: Doubly marked LTS %3ZWD.%2ZLD%$',
                    lts^.lr^.num, n);
  end;
  if lts^.f2.final and (lts^.lr^.id = 0) then begin
    n := lts^.f2.num;
    phase_bug_check('[%M12A]\CHECK_LTS: LTS %3ZWD.%2ZLD is active_on_exit but LR is simple%$',
                    lts^.lr^.num, n);
  end;
  if (lts^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only])
     = [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] then begin
    n := lts^.f2.num;
    phase_bug_check('[%M12A]\CHECK_LTS: Both even and odd parity set in LTS %3ZWD.%2ZLD%$',
                    lts^.lr^.num, n);
  end;
  lts^.mark := 0;
  lts^.f2.b3_3 := true;
  while op <> nil do begin
    instr := utils_ins_$operands_instruction(op);
    if instr^.bb <> lts^.bb then begin
      n := lts^.f2.num;
      phase_instr_bug_check('[%M12A]\CHECK_LTS: Reference to LTS in wrong block, near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                            instr^, lts^.lr^.num, n, instr^.bb^.num,
                            instr^.num);
    end;
    if (op^.lts <> lts) or not op^.h.read then begin
      n := lts^.f2.num;
      phase_instr_bug_check('[%M12A]\CHECK_LTS: Anomalous exposed LTS ref near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                            instr^, lts^.lr^.num, n, instr^.bb^.num,
                            instr^.num);
    end;
    if instr^.h.b2_6 then
      prev := op;
    nx := op^.link;
    if prev <> nil then
      prev^.link := nx
    else
      lts^.refs := nx;
    op := nx;
  end;
end;

{ lir_utils_$repair_lts_properties - sanity_$repair_lts_properties.
  0x273C46, 0x24 bytes. }

procedure lir_utils_$repair_lts_properties(
    rtn: rtn_ptr_t);
begin
  sanity_$repair_lts_properties(rtn);
end;

{ lir_utils_$sanity_check - sanity_$check_entire_routine.  0x273C6A,
  0x24 bytes. }

procedure lir_utils_$sanity_check(
    rtn: rtn_ptr_t);
begin
  sanity_$check_entire_routine(rtn);
end;
