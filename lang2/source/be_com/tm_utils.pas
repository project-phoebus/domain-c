{ tm_utils - the target machine's utilities (cc.a88k only): whether a
  value can be an immediate operand of an opcode (its operand forms,
  the access sizes' displacement ranges in the amse_ sections, the forms'
  alignment masks in operand_forms_mask), whether a base register can be
  pre- or postmodified by a displacement, whether an operand's scale can
  grow, and the pipeline's interaction distances between instructions.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x27B714  tm_utils_$begin_compilation
    --------  0x27B716  tm_utils_$init_for_routine
    --------  0x27B718  tm_utils_$end_routine
    --------  0x27B71A  tm_utils_$end_compilation
    --------  0x27B71C  tm_utils_$can_convert_to_immediate_operand
    --------  0x27B838  tm_utils_$can_convert_to_ip_reg_operand
    --------  0x27B8F2  tm_utils_$can_encode_as_immediate_operand
    --------  0x27BA8E  tm_utils_$can_increase_scale_by
    --------  0x27BBA2  tm_utils_$can_postmodify_base_register_by
    --------  0x27BCB6  tm_utils_$can_premodify_base_register_by
    --------  0x27BDC8  tm_utils_$interaction_distance_backward
    --------  0x27BE72  tm_utils_$interaction_distance_forward
    --------  0x27BED0  tm_utils_$minimum_distance
    --------  0x27C164  lir_$can_encode_as_immediate_operand
    A5 0x492F80 (loaded by every routine but the four empty ones); the
    module has no data of its own.  It holds the named sections'
    initial values (operand_forms_mask.init, the amse_*.init: the
    sections' bytes, docs/questions.md 161's scheme).

  An opcode's operand k is described by instruction_attributes'
  longword at +4k (backend.ins.pas instr_attr_view_t: its form); the
  operands an opcode's forms cover are its attributes' nresults (+11
  bits 2..0).  tm_utils_$can_increase_scale_by is global but nothing
  calls it (no heading in backend.ins.pas: declared here).

  Not known from the original: every local and parameter name. }

module tm_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_forms_mask.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_postmod_immed_high.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_postmod_immed_low.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_premod_immed_high.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_premod_immed_low.init';
%include 'lang2/source/be_com/utils.ins.pas';

{ The empty phase entries.  0x27B714, 0x27B716, 0x27B718, 0x27B71A, 0x2
  bytes each (a lone `rts', docs/rev889-patterns.md 13). }

procedure tm_utils_$begin_compilation;
begin
end;

procedure tm_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
end;

procedure tm_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

procedure tm_utils_$end_compilation;
begin
end;

{ tm_utils_$can_encode_as_immediate_operand - whether value can be
  operand k of an opcode: k one of the opcode's operands (nresults),
  value in its form's range (below) and clear in its form's mask
  (operand_forms_mask).  The ranges by form: 6 and 35 -3072..1023; 7
  and 9 -128..127; 8, 10, 11 -32768..32767; 12 a high or low halfword
  only; 13 no bits above 12; 15, 16 none above 4; 20 none above 3; 21,
  31, 36, 39, 40, 42 -57344..8191; 23, 33, 34 -240..15; 26 outside
  -32768..32767, or a high or low halfword only; 37 a multiple of 2048,
  or -57344..8191; the others (and 0, 43) never.  The lower bounds are
  the image's (`cmpi.l #-240', #-3072, #-57344: not the forms' signed
  ranges; kept).

  0x27B8F2, 0x19C bytes: value (8) in D1, opc (12) a word, k (14) in
  D2; the form a jump table of 42 words (`subq.w #1; cmpi.w #42; bcc';
  0x27B94A), each range's tail shared (`bra 0x27BA68', the mask test);
  13's `andi.w #-8192' of the longword's copy (the high word kept). }

function tm_utils_$can_encode_as_immediate_operand(
    value: integer32;
    opc: integer;
    k: integer32): boolean;
var
  form: integer;
  ok: boolean;
begin
  tm_utils_$can_encode_as_immediate_operand := false;
  if instruction_attributes[opc].nresults < k then
    return;
  form := instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[k].form;
  case form of
    23, 33, 34:
      ok := (value >= -240) and (value <= 15);
    7, 9:
      ok := (value >= -128) and (value <= 127);
    6, 35:
      ok := (value >= -3072) and (value <= 1023);
    21, 31, 36, 39, 40, 42:
      ok := (value >= -57344) and (value <= 8191);
    37:
      ok := ((value & 2047) = 0) or ((value >= -57344) and (value <= 8191));
    8, 10, 11:
      ok := (value >= -32768) and (value <= 32767);
    13:
      ok := (value & 16#FFFFE000) = 0;
    15, 16:
      ok := (value & 16#FFFFFFE0) = 0;
    20:
      ok := (value & 16#FFFFFFF0) = 0;
    26:
      ok := (value < -32768) or (value > 32767)
            or ((value & 16#FFFF0000) = 0) or ((value & 16#FFFF) = 0);
    12:
      ok := ((value & 16#FFFF0000) = 0) or ((value & 16#FFFF) = 0);
    otherwise
      ok := false;
  end;
  if ok then
    if (ord(operand_forms_mask[form]) & value) = 0 then
      tm_utils_$can_encode_as_immediate_operand := true;
end;

{ tm_utils_$can_convert_to_immediate_operand - whether value can replace
  operand k of instr as an immediate: for a load's or store's address
  displacement (k 1 for loads and MFPR, else 2) of an access that
  modifies its base or is qualified, within the amse_ ranges of its
  access size (amse 3 or 6 qualified as 1): postmodify's, premodify's,
  or for neither both; else as tm_utils_$can_encode_as_immediate_operand.

  0x27B71C, 0x11C bytes: value (8) in D2, instr (12), k (16) in D5;
  class sets 16#410000 (load, mfpr) and 16#210000 (load, store); amse
  set 72 (3, 6); the ranges' tests share their tails (`bra 0x27B822'). }

function tm_utils_$can_convert_to_immediate_operand(
    value: integer32;
    instr: instr_ptr_t;
    k: integer32): boolean;
var
  opc: integer;
  n: integer32;
  m: integer;
  a: integer;
begin
  opc := instr^.opc;
  if instruction_attributes[opc].class in [class$load, class$mfpr] then
    n := 1
  else
    n := 2;
  m := instr^.h.modify;
  if not ((instruction_attributes[opc].class in [class$load, class$store])
          and (k = n) and ((m <> 0) or (instr^.h.lsq <> 0))) then begin
    tm_utils_$can_convert_to_immediate_operand :=
      tm_utils_$can_encode_as_immediate_operand(value, opc, k);
    return;
  end;
  a := instruction_attributes[opc].amse;
  if (a in [3, 6]) and (instr^.h.lsq <> 0) then
    a := 1;
  if m = 1 then
    tm_utils_$can_convert_to_immediate_operand :=
      (value <= amse_postmod_immed_high[a])
      and (value >= amse_postmod_immed_low[a])
  else if m = 2 then
    tm_utils_$can_convert_to_immediate_operand :=
      (value <= amse_premod_immed_high[a])
      and (value >= amse_premod_immed_low[a])
  else
    tm_utils_$can_convert_to_immediate_operand :=
      (value <= amse_postmod_immed_high[a])
      and (value >= amse_postmod_immed_low[a])
      and (value <= amse_premod_immed_high[a])
      and (value >= amse_premod_immed_low[a]);
end;

{ tm_utils_$can_convert_to_ip_reg_operand - whether operand k of an
  opcode can be an integer register scaled by count (0..3): k one of
  its operands and its form a register form of that scale.

  0x27B838, 0xA2 bytes: opc (8) a word, k (10), count (14) in D2; a jump
  table of 4 (0x27B88E); the four sets 6 bytes each, overlapping in the
  code after the routine (0x27B8DA, 0x27B8E0, 0x27B8E6, 0x27B8EC:
  `moveq #47; sub.w; lsr.w #3; btst', docs/rev889-patterns.md 102). }

function tm_utils_$can_convert_to_ip_reg_operand(
    opc: integer;
    k: integer32;
    count: integer32): boolean;
var
  form: of$t;
begin
  tm_utils_$can_convert_to_ip_reg_operand := false;
  form := of$t(integer(instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[k].form));
  if instruction_attributes[opc].nresults < k then
    return;
  case count of
    0:
      tm_utils_$can_convert_to_ip_reg_operand := form in
        [of$ip_reg_or_long_pc_disp, of$ip_reg_or_basic_block,
         of$ip_compare_a_operand, of$ip_reg_or_s_immed11,
         of$ip_reg_scaled_or_s_immed8, of$ip_reg_or_s_immed8,
         of$ip_reg_scaled_or_s_immed16, of$ip_reg_or_s_immed16,
         of$ip_reg_or_u_i16_or_hi_i16, of$ip_reg_or_and_or_bic_u_immed16,
         of$ip_reg_or_u_immed5, of$ip_reg, of$ip_reg_scaled_or_pa_add_immed,
         of$trap_serialize_register, of$ip_reg_or_s_immed5,
         of$ip_reg_or_s_u_hi_immed16, of$ip_reg_or_0_mod_2_s_immed16,
         of$ip_reg_or_0_mod_4_s_immed16, of$ip_reg_or_0_mod_8_s_immed16,
         of$ip_reg_or_0_mod_16_s_immed16, of$ip_reg_or_s_immed14,
         of$ip_reg_scaled_3_or_s_immed5, of$ip_reg_scaled_2_or_s_immed5,
         of$ip_reg_scaled_2_or_s_immed14, of$ip_reg_scaled_or_pa_move_immed,
         of$ip_reg_scaled_3_or_s_immed14, of$ip_reg_scaled_1_or_s_immed14];
    1:
      tm_utils_$can_convert_to_ip_reg_operand := form in
        [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
         of$ip_reg_scaled_or_s_immed16, of$ip_reg_scaled_or_pa_add_immed,
         of$ip_reg_scaled_or_pa_move_immed, of$ip_reg_scaled_1_or_s_immed14];
    2:
      tm_utils_$can_convert_to_ip_reg_operand := form in
        [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
         of$ip_reg_scaled_or_s_immed16, of$ip_reg_scaled_or_pa_add_immed,
         of$ip_reg_scaled_2_or_s_immed5, of$ip_reg_scaled_2_or_s_immed14,
         of$ip_reg_scaled_or_pa_move_immed];
    3:
      tm_utils_$can_convert_to_ip_reg_operand := form in
        [of$ip_compare_a_operand, of$ip_reg_scaled_or_s_immed8,
         of$ip_reg_scaled_or_s_immed16, of$ip_reg_scaled_or_pa_add_immed,
         of$ip_reg_scaled_3_or_s_immed5, of$ip_reg_scaled_or_pa_move_immed,
         of$ip_reg_scaled_3_or_s_immed14];
    otherwise
      ;
  end;
end;

{ tm_utils_$can_increase_scale_by - whether op's scale (its +2 bits
  5..4, count) can grow by by: by 0 always; else by at most 3, op one of
  its opcode's operands, and the scale then the one its form takes
  (forms 42: 1; 36, 34: 2; 39, 33: 3) or at most 3 (forms 21, 10, 7, 3).

  0x27BA8E, 0x114 bytes: by (8) in D2, op (12); op's instruction inline
  (`subi.l #32; sub.l', docs/rev889-patterns.md 131); the forms tested
  as a chain of compares (`cmpi.w #42' ...); `cmpi.l #3,D2; bhi' (by
  unsigned). }

function tm_utils_$can_increase_scale_by(
    by: integer32;
    op: opnd_ptr_t): boolean;
var
  instr: instr_ptr_t;
  k: integer32;
  form: integer;
begin
  k := op^.h.num;
  instr := instr_ptr_t(integer32(op) - 32 - 12 * k);
  tm_utils_$can_increase_scale_by := true;
  if by = 0 then
    return;
  tm_utils_$can_increase_scale_by := false;
  if instruction_attributes[instr^.opc].nresults < k then
    return;
  if (by < 0) or (by > 3) then
    return;
  form := instr_attr_view_ptr_t(addr(instruction_attributes[instr^.opc]))^.opnds[k].form;
  if form = 42 then
    tm_utils_$can_increase_scale_by := op^.h.count + by = 1
  else if (form = 36) or (form = 34) then
    tm_utils_$can_increase_scale_by := op^.h.count + by = 2
  else if (form = 39) or (form = 33) then
    tm_utils_$can_increase_scale_by := op^.h.count + by = 3
  else if (form = 21) or (form = 10) or (form = 7) or (form = 3) then
    tm_utils_$can_increase_scale_by := op^.h.count + by <= 3;
end;

{ tm_utils_$can_postmodify_base_register_by - whether a load or store of
  opcode opc can postmodify its base register by disp: its access size
  (amse) one of 1, 3..6, disp within the postmodify range of that size
  and clear in the mask of its address operand's form (operand 1 for
  loads and MFPR, 2 for stores and MTPR; bug_check for other classes).

  0x27BBA2, 0xC2 bytes: disp (8) in D2, opc (12) a word; amse set 122;
  class sets 16#410000 and 16#A00000. }

function tm_utils_$can_postmodify_base_register_by(
    disp: integer32;
    opc: integer): boolean;
var
  k: integer32;
  a: integer;
begin
  tm_utils_$can_postmodify_base_register_by := false;
  a := instruction_attributes[opc].amse;
  if not (a in [1, 3, 4, 5, 6]) then
    return;
  if instruction_attributes[opc].class in [class$load, class$mfpr] then
    k := 1
  else if instruction_attributes[opc].class in [class$store, class$mtpr] then
    k := 2
  else
    bug_check('TM_UTILS_$CAN_POSTMODIFY_BASE_REGISTER_BY -- ia.class is neither load nor store%$');
  if disp > amse_postmod_immed_high[a] then
    return;
  if disp < amse_postmod_immed_low[a] then
    return;
  if (ord(operand_forms_mask[instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[k].form])
      & disp) <> 0 then
    return;
  tm_utils_$can_postmodify_base_register_by := true;
end;

{ tm_utils_$can_premodify_base_register_by - as postmodify's, for
  premodification: access sizes 1..6, the premodify range.

  0x27BCB6, 0xC2 bytes: amse set 126. }

function tm_utils_$can_premodify_base_register_by(
    disp: integer32;
    opc: integer): boolean;
var
  k: integer32;
  a: integer;
begin
  tm_utils_$can_premodify_base_register_by := false;
  a := instruction_attributes[opc].amse;
  if not (a in [1, 2, 3, 4, 5, 6]) then
    return;
  if instruction_attributes[opc].class in [class$load, class$mfpr] then
    k := 1
  else if instruction_attributes[opc].class in [class$store, class$mtpr] then
    k := 2
  else
    bug_check('TM_UTILS_$CAN_PREMODIFY_BASE_REGISTER_BY -- ia.class is neither load nor store%$');
  if disp > amse_premod_immed_high[a] then
    return;
  if disp < amse_premod_immed_low[a] then
    return;
  if (ord(operand_forms_mask[instr_attr_view_ptr_t(addr(instruction_attributes[opc]))^.opnds[k].form])
      & disp) <> 0 then
    return;
  tm_utils_$can_premodify_base_register_by := true;
end;

{ tm_utils_$interaction_distance_backward - the cycles instr needs from
  the instruction before it, by its opcode's interaction class: 15 one;
  5, 13 three; 11, 12 one; 1, 15 one; 4, 5, 7, 8 one when it modifies
  its base (+3 bits 7..6); else 0.

  0x27BDC8, 0xAA bytes: instr (8); the class `andi.w #3968,(A0)' and
  `lsr.w #7' each time; the sets 8224, 6144, 32770, 432 (15 tested again
  in 32770, 5 in 432: kept). }

function tm_utils_$interaction_distance_backward(
    instr: instr_ptr_t): integer32;
var
  c: integer;
begin
  tm_utils_$interaction_distance_backward := 0;
  c := instruction_attributes[instr^.opc].interaction;
  if c = 15 then
    tm_utils_$interaction_distance_backward := 1
  else if c in [5, 13] then
    tm_utils_$interaction_distance_backward := 3
  else if c in [11, 12] then
    tm_utils_$interaction_distance_backward := 1
  else if c in [1, 15] then
    tm_utils_$interaction_distance_backward := 1
  else if c in [4, 5, 7, 8] then
    if instr^.h.modify <> 0 then
      tm_utils_$interaction_distance_backward := 1;
end;

{ tm_utils_$interaction_distance_forward - the cycles the instruction
  after instr needs from it: classes 7, 13, 14 one; 2, 3 three; else 0.

  0x27BE72, 0x5E bytes: the sets 24704 and 12. }

function tm_utils_$interaction_distance_forward(
    instr: instr_ptr_t): integer32;
var
  c: integer;
begin
  tm_utils_$interaction_distance_forward := 0;
  c := instruction_attributes[instr^.opc].interaction;
  if c in [7, 13, 14] then
    tm_utils_$interaction_distance_forward := 1
  else if c in [2, 3] then
    tm_utils_$interaction_distance_forward := 3;
end;

{ tm_utils_$minimum_distance - the cycles b must follow a by: when a is
  of class 7, 13 or 14, 1 if b is of class 15, or of class 1 and writes
  (+1 bits 5, 3, 2) an integer register (kinds 16#21012) of a's
  operand 1's live range (from the RA phase on: its register); when a
  is of class 2 or 3 and b of 5 or 13, 3 if a reads (bit 4) a floating
  register (kinds 16#606C) of b's operand 2's live range (class 13) or
  operand 3's (or, for a LOADD, opcode 109, its mate operand's; from the
  RA phase on their registers); else 0.

  0x27BED0, 0x294 bytes: a (8), b (12) in D3/A2; the result D4; the
  phase `cmpi.w #13,0x485D32' (at_backend_phase, phase$ra); the second
  live range -1 when there is none (`movea.l #-1,A1', its register -1
  at -16); the loops `dbf' over the operands from 1. }

function tm_utils_$minimum_distance(
    a: instr_ptr_t;
    b: instr_ptr_t): integer32;
var
  ca: integer;
  cb: integer;
  j: integer32;
  op: opnd_ptr_t;
  lr: lr_ptr_t;
  lr2: lr_ptr_t;
  reg: integer32;
  reg2: integer32;
  d: integer32;
begin
  d := 0;
  ca := instruction_attributes[a^.opc].interaction;
  cb := instruction_attributes[b^.opc].interaction;
  if ca in [7, 13, 14] then begin
    if cb = 15 then
      d := 1
    else if cb = 1 then begin
      lr := a^.opnds[1].lts^.lr;
      if at_backend_phase < phase$ra then begin
        for j := 1 to b^.h.nopnds do begin
          op := addr(b^.opnds[j]);
          if (opnd_bytes_ptr_t(op)^.rrp & 44) <> 0 then
            if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                              operand$ip_reg_like,
                              operand$case_jump_base] then
              if op^.lts^.lr = lr then begin
                d := 1;
                exit;
              end;
        end;
      end
      else begin
        reg := lr^.f2.reg;
        for j := 1 to b^.h.nopnds do begin
          op := addr(b^.opnds[j]);
          if (opnd_bytes_ptr_t(op)^.rrp & 44) <> 0 then
            if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                              operand$ip_reg_like,
                              operand$case_jump_base] then
              if op^.lts^.lr^.f2.reg = reg then begin
                d := 1;
                exit;
              end;
        end;
      end;
    end;
  end
  else if ca in [2, 3] then
    if cb in [5, 13] then begin
      if cb = 13 then begin
        lr := b^.opnds[2].lts^.lr;
        lr2 := lr_ptr_t(-1);
        reg2 := -1;
      end
      else begin
        lr := b^.opnds[3].lts^.lr;
        if b^.opc = ord(opc$loadd) then begin
          lr2 := utils_$find_mate_operand(addr(b^.opnds[3]))^.lts^.lr;
          reg2 := lr2^.f2.reg;
        end
        else begin
          lr2 := lr_ptr_t(-1);
          reg2 := -1;
        end;
      end;
      reg := lr^.f2.reg;
      if at_backend_phase < phase$ra then begin
        for j := 1 to a^.h.nopnds do begin
          op := addr(a^.opnds[j]);
          if op^.h.read then
            if op^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
                              operand$fp_reg_physical,
                              operand$fp_reg_pair_physical,
                              operand$fp_reg_like,
                              operand$fp_reg_pair_like] then
              if (op^.lts^.lr = lr) or (op^.lts^.lr = lr2) then begin
                d := 3;
                exit;
              end;
        end;
      end
      else begin
        for j := 1 to a^.h.nopnds do begin
          op := addr(a^.opnds[j]);
          if op^.h.read then
            if op^.h.kind in [operand$fp_reg, operand$fp_reg_pair,
                              operand$fp_reg_physical,
                              operand$fp_reg_pair_physical,
                              operand$fp_reg_like,
                              operand$fp_reg_pair_like] then
              if (op^.lts^.lr^.f2.reg = reg)
                 or (op^.lts^.lr^.f2.reg = reg2) then begin
                d := 3;
                exit;
              end;
        end;
      end;
    end;
  tm_utils_$minimum_distance := d;
end;

{ lir_$can_encode_as_immediate_operand - tm_utils_$can_encode_as_
  immediate_operand's answer (its arguments pushed again; D0 left as it
  returned).  0x27C164, 0x26 bytes. }

function lir_$can_encode_as_immediate_operand(
    value: integer32;
    opc: integer;
    k: integer32): boolean;
begin
  lir_$can_encode_as_immediate_operand :=
    tm_utils_$can_encode_as_immediate_operand(value, opc, k);
end;
