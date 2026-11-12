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

{ sanity_$check_entire_routine - the whole routine checked, in five
  walks over the blocks in the +72 order (chained at next114):

  1. each instruction's +0 bit 0 := its +2 bit 6 (the last walk's
     mark); the unmarked ones excised (utils_$excise_instruction_cleanly,
     not cascading), from the block's last back; the block's +19 bit 1
     cleared.
  2. each instruction: +0 bit 6 kept only with a register or memory
     operand 1; past phase 3 a control transfer's +3 bit 3 cleared; its
     block; a JOIN_BP's input (operand 1) and inputs (operand 3's link);
     a load's or store's address mode against the opcode's access size
     (amse, the amse_ sections' immediate ranges); then each operand:
     present when explicit (the opcode's +11 bits 2..0 count them),
     numbered, its form (the opcode's operand forms; the of$t sets
     after the routine), parity, its properties (an intend-to-modify
     read paired with a later modify of the same live range; a write or
     modify heading its segment's references, the segment checked by
     check_lts), an odd fp_reg_pair's earlier even mate, its scale
     factor, an immediate's encoding
     (tm_utils_$can_encode_as_immediate_operand), a symbolic
     displacement's form and a literal pool integer's size.
  3. each block's exposed segments (each live range's with
     lir_main_c86): a simple live range's segment that writes is an
     error for the list's first; unreferenced ones excised, the others
     checked (check_lts from their refs).
  4. each block's final segments likewise: the first's live range must
     be complex; unreferenced ones excised; past phase 3 each must be
     marked, and a physical register's (lr +3 bit 7, not bit 5, not
     register 30 or 31 without a register class) must be the result of
     a CALL that ends the block (only SEQs, then a jump, trap or return
     after it) with no readers: the CALL's +3 bit 3 set.
  5. the segments that the register and memory operands read marked;
     then each live range: parity, hints cleared, its unmarked
     segments excised (the marked unmarked), its mate equally complex;
     sanity_$repair_lts_properties last.

  0x2721B4, 0xD76 bytes: rtn (8); the block in -68, the instruction in
  -56, the opcode's attributes in A3 (then the operand), k in D4, the
  modify operand's search index in D5, the even mate's in D6 (with D7
  12 times it), the explicit operands' count in -64, the operand form
  pointer in -108, the access size index in -74 (a word).  The
  messages' arguments by address, a mnemonic with its length 12 (the
  longword 12 at 0x273B8E, before the last two messages); most read
  "[%M12A]_$CHECK_ENTIRE_ROUTINE" (no "\SANITY", unlike the four
  fp_reg_pair messages), as the image has them.  Walk 3's and 4's
  checks of a list's head are made once, outside its loop; the
  literal pool size check prints the size as a signed 3-bit field
  (`asr.b #5') though it tests it unsigned (dpc prints it unsigned).
  The of$t sets are 6 bytes each (bound 47) at 0x27312A (disp_forms),
  0x273182 (scaled_3), 0x273188 (scaled_2), 0x27318E (scaled_1) and
  0x2734B0 (ip_forms).  Walks 3 and 4 load lir_main_c86's address into
  D3 (and lir_main_c40's into D4, unused).

  Not known from the original: the locals' names; how walks 3 and 4
  left their loops (`repeat ... until false' with `exit' here). }

procedure sanity_$check_entire_routine(
    rtn: rtn_ptr_t); options(val_param);
const
  ip_forms = [of$ip_reg_or_long_pc_disp, of$ip_reg_or_basic_block,
              of$ip_compare_a_operand, of$ip_reg_or_s_immed11,
              of$ip_reg_scaled_or_s_immed8, of$ip_reg_or_s_immed8,
              of$ip_reg_scaled_or_s_immed16, of$ip_reg_or_s_immed16,
              of$ip_reg_or_u_i16_or_hi_i16,
              of$ip_reg_or_and_or_bic_u_immed16, of$ip_reg_or_u_immed5,
              of$ip_reg, of$ip_reg_scaled_or_pa_add_immed,
              of$trap_serialize_register, of$ip_reg_or_s_immed5,
              of$ip_reg_or_s_u_hi_immed16, of$ip_reg_or_0_mod_2_s_immed16,
              of$ip_reg_or_0_mod_4_s_immed16,
              of$ip_reg_or_0_mod_8_s_immed16,
              of$ip_reg_or_0_mod_16_s_immed16, of$ip_reg_or_s_immed14,
              of$ip_reg_scaled_3_or_s_immed5,
              of$ip_reg_scaled_2_or_s_immed5,
              of$ip_reg_scaled_2_or_s_immed14,
              of$ip_reg_scaled_or_pa_move_immed,
              of$ip_reg_scaled_3_or_s_immed14,
              of$ip_reg_scaled_1_or_s_immed14];
  scaled_1 = [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
              of$ip_reg_scaled_or_s_immed16,
              of$ip_reg_scaled_or_pa_add_immed,
              of$ip_reg_scaled_or_pa_move_immed,
              of$ip_reg_scaled_1_or_s_immed14];
  scaled_2 = [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
              of$ip_reg_scaled_or_s_immed16,
              of$ip_reg_scaled_or_pa_add_immed,
              of$ip_reg_scaled_2_or_s_immed5,
              of$ip_reg_scaled_2_or_s_immed14,
              of$ip_reg_scaled_or_pa_move_immed];
  scaled_3 = [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
              of$ip_reg_scaled_or_s_immed16,
              of$ip_reg_scaled_or_pa_add_immed,
              of$ip_reg_scaled_3_or_s_immed5,
              of$ip_reg_scaled_or_pa_move_immed,
              of$ip_reg_scaled_3_or_s_immed14];
  disp_forms = [of$s_immed16, of$ip_reg_scaled_or_s_immed16,
                of$ip_reg_or_s_immed16, of$ip_reg_scaled_or_pa_add_immed,
                of$0_mod_2_s_immed16, of$0_mod_4_s_immed16,
                of$ip_reg_or_s_u_hi_immed16,
                of$ip_reg_or_0_mod_2_s_immed16,
                of$ip_reg_or_0_mod_4_s_immed16,
                of$ip_reg_or_0_mod_8_s_immed16,
                of$ip_reg_or_0_mod_16_s_immed16, of$ip_reg_or_s_immed14,
                of$ip_reg_scaled_2_or_s_immed14,
                of$ip_reg_scaled_or_pa_move_immed,
                of$ip_reg_scaled_3_or_s_immed14, of$signed_immed14,
                of$ip_reg_scaled_1_or_s_immed14];
var
  bb: bb_ptr_t;
  instr: instr_ptr_t;
  ins: instr_ptr_t;
  attr: instr_attr_ptr_t;
  op: opnd_ptr_t;
  def: opnd_ptr_t;
  lts: lts_ptr_t;
  nx: lts_ptr_t;
  lr: lr_ptr_t;
  lr2: lr_ptr_t;
  k: integer32;
  j: integer32;
  i: integer32;
  nexp: integer32;
  n: integer32;
  sc: integer32;
  v: integer32;
  m: integer;
  ix: integer;
  kind: operand$t;
  form: integer;
  zero: boolean;
  physical: boolean;
  at_end: boolean;
begin
  { 1. The instructions the last walk did not mark excised. }
  bb := rtn^.bbs72;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      instr^.h.b0_0 := instr^.h.b2_6;
      instr := instr^.next;
    end;
    instr := bb^.last;
    while instr <> nil do begin
      if not instr^.h.b0_0 then
        utils_$excise_instruction_cleanly(instr, false);
      instr := instr^.prev;
    end;
    bb^.f.b19_1 := false;
    bb := bb^.next114;
  end;

  { 2. Each instruction and its operands. }
  bb := rtn^.bbs72;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      if instr^.h.b0_6 then
        if not (instr^.opnds[1].h.kind
                in [operand$ip_reg..operand$well_behaved_memory]) then
          instr^.h.b0_6 := false;
      attr := addr(instruction_attributes[instr^.opc]);
      if at_backend_phase > 3 then
        if attr^.class in [class$branch, class$call, class$fp_branch,
                           class$jump, class$trap, class$svc,
                           class$return] then
          instr^.h.b3_3 := false;
      if instr^.bb <> bb then
        phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: instruction appears in wrong basic block: near line %LD, BB %3ZWD, inst %3ZWD%$',
                              instr^, bb^.num, instr^.num);
      if instr^.opc = ord(opc$join_bp) then begin
        lts := instr^.opnds[1].lts;
        if lts^.refs^.link <> nil then begin
          n := lts^.f2.num;
          phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LTS %3ZWD.%2ZLD input to JOIN_BP has multiple consumers%$',
                          lts^.lr^.num, n);
        end;
        if instr^.opnds[3].link = nil then begin
          n := lts^.f2.num;
          phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LTS %3ZWD.%2ZLD is consumed by JOIN_BP with no JBIs%$',
                          lts^.lr^.num, n);
        end
        else if lts^.l44 <> nil then begin
          n := lts^.f2.num;
          phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LTS %3ZWD.%2ZLD is consumed by JOIN_BP & has non-NIL definition%$',
                          lts^.lr^.num, n);
        end;
      end;

      { A load's or store's address mode. }
      if attr^.class in [class$load, class$store] then begin
        m := instr^.h.modify;
        if m <> 0 then begin
          if m = 1 then begin
            if not (attr^.amse in [1, 3..6]) then
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: illegal postmodify address mode: %A%$',
                              instruction_mnemonic[instr^.opc], 12);
          end
          else if m = 2 then begin
            if not (attr^.amse in [1..6]) then
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: illegal premodify address mode: %A%$',
                              instruction_mnemonic[instr^.opc], 12);
          end;
        end;
        if (instr^.h.modify <> 0) or (instr^.h.lsq <> 0) then begin
          ix := attr^.amse;
          if (ix in [3, 6]) and (instr^.h.lsq <> 0) then
            ix := 1;
          if attr^.class in [class$load, class$mfpr] then
            k := 1
          else
            k := 2;
          kind := instr^.opnds[k].h.kind;
          if kind = operand$immediate then begin
            v := instr^.opnds[k].value;
            m := instr^.h.modify;
            if m = 1 then begin
              if (v > amse_postmod_immed_high[ix])
                 or (v < amse_postmod_immed_low[ix]) then
                phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: immediate %8ZH out of range for postmodify AM: %A%$',
                                v, instruction_mnemonic[instr^.opc], 12);
            end
            else if m = 2 then begin
              if (v > amse_premod_immed_high[ix])
                 or (v < amse_premod_immed_low[ix]) then
                phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: immediate %8ZH out of range for premodify AM: %A%$',
                                v, instruction_mnemonic[instr^.opc], 12);
            end
            else if (v > amse_postmod_immed_high[ix])
                    or (v < amse_postmod_immed_low[ix])
                    or (v > amse_premod_immed_high[ix])
                    or (v < amse_premod_immed_low[ix]) then
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: immediate %8ZH out of range for qualified AM: %A%$',
                              v, instruction_mnemonic[instr^.opc], 12);
          end
          else if kind in [operand$displacement_arg_block
                           ..operand$displacement_XSB_base] then
            phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE:  -- illegal use of symbolic displacement with modifying or qualified AM%$');
        end;
      end;

      { Its operands. }
      nexp := attr^.nresults;
      j := 1;
      i := 1;
      for k := 1 to instr^.h.nopnds do begin
        op := addr(instr^.opnds[k]);
        if op^.h.kind = operand$none then begin
          if k <= nexp then
            phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: required (explicit) operand is missing: near line %LD, operand #%LD, inst %3ZWD:%3ZWD%$',
                                  instr^, k, bb^.num, instr^.num);
        end
        else begin
          n := op^.h.num;
          if n <> k then
            phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: bad operand number: near line %LD, is %LD instead of %LD, inst %3ZWD:%3ZWD%$',
                                  instr^, n, k, bb^.num, instr^.num);
          kind := op^.h.kind;
          form := instr_attr_view_ptr_t(attr)^.opnds[k].form;
          if kind in [operand$ip_reg..operand$well_behaved_memory] then begin
            if (k <= nexp)
               and (kind in [operand$ip_reg, operand$ip_reg_physical,
                             operand$ip_reg_like, operand$case_jump_base])
               and not (of$t(form) in ip_forms) then begin
              n := op^.h.num;
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: operand %LD, inst %3ZWD:%3ZWD cannot be IP_REG specifier%$',
                              n, bb^.num, instr^.num);
            end;
            if (opnd_bytes_ptr_t(op)^.rrp & 3) = 3 then begin
              n := op^.h.num;
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Both even and odd parity set in operand %LD, inst %3ZWD:%3ZWD%$',
                              n, bb^.num, instr^.num);
            end;

            { Its properties: read, write or modify. }
            m := opnd_bytes_ptr_t(op)^.rrp & 16#1C;
            if m = 16#10 then begin
              if op^.h.intend_to_modify then begin
                while not instr^.opnds[j].h.modify do begin
                  j := j + 1;
                  if j > instr^.h.nopnds then
                    phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: intend-to-modify operand not paired with modify: near line %LD%$',
                                          instr^);
                end;
                if j <= k then
                  phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: intend-to-modify operand and modify out of order: near line %LD%$',
                                        instr^);
                if op^.lts^.lr <> instr^.opnds[j].lts^.lr then
                  phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: intend-to-modify operand and modify have different LR: near line %LD%$',
                                        instr^);
                j := j + 1;
              end;
            end
            else if (m = 8) or (m = 4) then begin
              if op^.lts^.refs <> op then
                phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Anomalous LTS head: near line %LD%$',
                                      instr^);
              if lir_main_c8e then begin
                lts := op^.lts;
                if lts^.f2.final then begin
                  if (lts^.l44 = nil) and (lts^.l28 = nil)
                     and (lts^.lr <> rtn^.memory_lr) then begin
                    n := lts^.f2.num;
                    phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Active-on-exit LTS has no down-stream consumers: %3ZWD.%2ZLD%$',
                                    lts^.lr^.num, n);
                  end;
                end
                else if (lts^.l44 <> nil) or (lts^.l28 <> nil) then begin
                  n := lts^.f2.num;
                  phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Anomalous simple LTS: %3ZWD.%2ZLD%$',
                                  lts^.lr^.num, n);
                end;
              end;
              check_lts(op^.lts, op^.link, op);
            end
            else
              phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Anomalous operand properties (no read nor wrtie nor modify): near line %LD%$',
                                    instr^);

            { An odd fp_reg_pair's even mate, earlier. }
            if (op^.h.kind = operand$fp_reg_pair)
               and op^.h.fp_reg_odd_only then begin
              while (i < k)
                    and not ((instr^.opnds[i].h.kind = operand$fp_reg_pair)
                             and instr^.opnds[i].h.fp_reg_even_only) do
                i := i + 1;
              if i < k then begin
                lr2 := instr^.opnds[i].lts^.lr;
                lr := op^.lts^.lr;
                if (lr2^.mate = nil) or (lr^.mate = nil)
                   or (lr2^.mate <> lr) or (lr^.mate <> lr2) then
                  phase_instr_bug_check('[%M12A]\SANITY_$CHECK_ENTIRE_ROUTINE: (near line %LD, instr %3ZWD:%3ZWD), fp_reg_pair operands #%LD and #%LD are not well-mated LRs%$',
                                        instr^, bb^.num, instr^.num, i, k);
                if (opnd_bytes_ptr_t(addr(instr^.opnds[i]))^.rrp & 60)
                   <> (opnd_bytes_ptr_t(op)^.rrp & 60) then
                  phase_instr_bug_check('[%M12A]\SANITY_$CHECK_ENTIRE_ROUTINE: (near line %LD, instr %3ZWD:%3ZWD), fp_reg_pair operands #%LD and #%LD have different access properties%$',
                                        instr^, bb^.num, instr^.num, i, k);
              end
              else
                phase_instr_bug_check('[%M12A]\SANITY_$CHECK_ENTIRE_ROUTINE: (near line %LD, instr %3ZWD:%3ZWD), no earlier even fp_reg_pair mate operand for odd fp_reg_pair operand #%LD%$',
                                      instr^, bb^.num, instr^.num, k);
              i := i + 1;
            end;

            { Its scale factor. }
            sc := op^.h.count;
            if sc <> 0 then
              if (k > nexp)
                 or ((sc = 1) and not (of$t(form) in scaled_1))
                 or ((sc = 2) and not (of$t(form) in scaled_2))
                 or ((sc = 3) and not (of$t(form) in scaled_3)) then
                phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: illegal scale factor of %LD on operand #%LD of %A%$',
                                sc, k, instruction_mnemonic[instr^.opc], 12);
          end
          else if kind = operand$immediate then begin
            if k <= nexp then
              if not tm_utils_$can_encode_as_immediate_operand(
                       op^.value, instr^.opc, k) then
                phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: cannot encode immediate %8ZLH as operand #%LD of %A%$',
                                op^.value, k, instruction_mnemonic[instr^.opc], 12);
          end
          else if kind in [operand$displacement_arg_block
                           ..operand$displacement_XSB_base] then begin
            if (k > nexp) or not (of$t(form) in disp_forms) then
              phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: operand #%LD of %A is a symbolic displacement%$',
                              k, instruction_mnemonic[instr^.opc], 12);
            if (op^.h.kind = operand$displacement_literal_pool)
               and (lit_ptr_t(op^.link)^.kind in [0..11]) then begin
              n := op^.h.bytes;
              if not ((n = 4) or (n = 2) or (n = 1)) then
                phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: operand #%LD of %A with .bytes = %LD is displacement_literal_pool to an int_ob%$',
                                k, instruction_mnemonic[instr^.opc], 12, n);
            end;
          end;
        end;
      end;
      while j <= instr^.h.nopnds do begin
        if instr^.opnds[j].h.modify then
          phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: modify operand not paired with intend-to-modify: near line %LD%$',
                                instr^);
        j := j + 1;
      end;
      instr := instr^.next;
    end;
    bb := bb^.next114;
  end;

  { 3. The exposed segments, by block or by live range. }
  bb := rtn^.bbs72;
  lr := rtn^.lrs;
  repeat
    if lir_main_c86 = 0 then begin
      if bb = nil then
        exit;
      lts := bb^.exposed;
    end
    else begin
      if lr = nil then
        exit;
      lts := lr^.exposed;
    end;
    if lts <> nil then
      if (lts^.lr^.id = 0)
         and ((lts^.lr^.rrp * [rrp$modify, rrp$write]) <> []) then begin
        n := lts^.f2.num;
        phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LTS is on exposed list but LR is simple, LTS %3ZWD.%2ZLD%$',
                        lts^.lr^.num, n);
      end;
    while lts <> nil do begin
      nx := lts^.next_exposed;
      if lts^.refs = nil then
        utils_$excise_lts_cleanly(lts, false)
      else
        check_lts(lts, lts^.refs, nil);
      lts := nx;
    end;
    if lir_main_c86 = 0 then
      bb := bb^.next114
    else
      lr := lr^.next;
  until false;

  { 4. The final segments, by block or by live range. }
  bb := rtn^.bbs72;
  lr := rtn^.lrs;
  repeat
    if lir_main_c86 = 0 then begin
      if bb = nil then
        exit;
      lts := bb^.finals;
    end
    else begin
      if lr = nil then
        exit;
      lts := lr^.finals;
    end;
    if lts <> nil then begin
      if lts^.lr^.id = 0 then begin
        n := lts^.f2.num;
        phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LTS is on final list but LR is simple, LTS %3ZWD.%2ZLD%$',
                        lts^.lr^.num, n);
      end;
      lr2 := lts^.lr;
      if (lr2^.rrp * [rrp$fp_reg, rrp$ip_reg]) = [] then
        zero := (lr2^.f2.reg = 31) or (lr2^.f2.reg = 30)
      else
        zero := false;
      if lr2^.f2.b3_7 and not lr2^.f2.b3_5 then
        physical := not zero
      else
        physical := false;
      repeat
        nx := lts^.next_final;
        if lts^.refs = nil then
          utils_$excise_lts_cleanly(lts, false)
        else if at_backend_phase > 3 then begin
          if not lts^.f2.b3_3 then begin
            n := lts^.f2.num;
            phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: final LTS source not marked, LTS %3ZWD.%2ZLD%$',
                            lts^.lr^.num, n);
          end;
          if physical then begin
            def := lts^.refs;
            ins := utils_ins_$operands_instruction(def);
            instr := ins^.next;
            while instr <> nil do begin
              if instruction_attributes[instr^.opc].class <> class$seq then
                exit;
              instr := instr^.next;
            end;
            if instr = nil then
              at_end := true
            else
              at_end := instruction_attributes[instr^.opc].class
                        in [class$jump, class$trap, class$return];
            if not (at_end and (ins^.opc = ord(opc$call))
                    and not def^.h.read and (def^.link = nil)) then begin
              n := lts^.f2.num;
              phase_instr_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Anomalous physical LTS at end of basic block: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                                    ins^, lts^.lr^.num, n, ins^.bb^.num,
                                    ins^.num);
            end;
            ins^.h.b3_3 := true;
          end;
        end;
        lts := nx;
      until lts = nil;
    end;
    if lir_main_c86 = 0 then
      bb := bb^.next114
    else
      lr := lr^.next;
  until false;

  { 5. The segments the register and memory operands read marked; the
    live ranges' segments not marked excised. }
  bb := rtn^.bbs72;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      for k := 1 to instr^.h.nopnds do
        if (instr^.opnds[k].h.kind
            in [operand$ip_reg..operand$well_behaved_memory])
           and instr^.opnds[k].h.read then
          instr^.opnds[k].lts^.f2.b3_3 := true;
      instr := instr^.next;
    end;
    bb := bb^.next114;
  end;
  lr := rtn^.lrs;
  while lr <> nil do begin
    if (lr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only])
       = [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] then
      phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: Both even and odd parity set on LR %3ZWD%$',
                      lr^.num);
    lr^.exposed_hint := nil;
    lr^.exposed_prev := nil;
    lr^.final_hint := nil;
    lr^.final_prev := nil;
    lts := lr^.ltss;
    while lts <> nil do begin
      nx := lts^.next;
      if lts^.f2.b3_3 then
        lts^.f2.b3_3 := false
      else
        utils_$excise_lts_cleanly(lts, false);
      lts := nx;
    end;
    if lr^.mate <> nil then
      if (lr^.id = 0) <> (lr^.mate^.id = 0) then
        phase_bug_check('[%M12A]_$CHECK_ENTIRE_ROUTINE: LR %3ZWD and mate %3ZWD have differing complexity%$',
                        lr^.num, lr^.mate^.num);
    lr := lr^.next;
  end;
  sanity_$repair_lts_properties(rtn);
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
