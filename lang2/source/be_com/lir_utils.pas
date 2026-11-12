{ lir_utils - the LIR's utilities (cc.a88k only): instructions excised
  and preference moves made, segments added to live ranges, memory
  homes and spill ids, operands of new loads and stores, the live
  ranges exposed on asynchronous paths, the store-through live ranges.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x24C0FC  lir_utils_$excise_inst
    --------  0x24C14E  lir_utils_$create_preference_move
    --------  0x24C24A  lir_utils_$add_lts_to_lr
    --------  0x24C2A8  lir_utils_$add_lts_after_lts
    --------  0x24C312  lir_utils_$trans_insert_move
    --------  0x24CFC4  assign_spill_id (internal)
    --------  0x24D024  lir_utils_$get_new_memory_home
    --------  0x24D0F2  lir_utils_$add_memory_home
    --------  0x24D2C4  add_new_operand (internal)
    --------  0x24D34C  lir_utils_$flesh_out_new_load_or_store
    --------  0x24D5DC  nolonger_exposed (internal)
    --------  0x24D65A  lir_utils_$get_next_async_exposed_lr
    --------  0x24D808  lir_utils_$fix_store_through_lrs
    --------  0x24D7CC    new_db_lts (nested in it)
    --------  0x24E5F8  lir_utils_$find_mate_operand
    A5 0x48C164: move_opcode (+0, move_opcode.init), the squash
    suffixes ('.SN ', '.ST ', '.SF ', '.SA ' at +0x40) and the rest of
    the module's data, read by the routines not translated yet.

  The segments come from lir's fixed heap (lir.pvt.pas lir_3c00).
  lir_utils_$get_new_memory_home loads A5 and is global though only
  this unit calls it; assign_spill_id's message names RA_UTILS.

  Not known from the original: every local and parameter name. }

module lir_utils;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang2/source/isc/isc_var_externs.ins.pas';
%include 'lang2/source/be_com/lir.pvt.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/move_opcode.init';
%include 'lang2/source/be_com/utils.ins.pas';


{ The section spill_instr_forms (lir.pvt.pas; cc.a88k 0x513E30, 264
  bytes from .rwdi): its initial value.  Not known from the original:
  which unit held it (lir_utils and ra_utils both use it; here with the
  first of them). }

define spill_instr_forms := [
    [[0, 0, 0, 0], [ord(of$ip_reg), 0, 0, 0], [0, 0, 192, 0],
     [ord(of$ip_reg_scaled_or_s_immed16), 0, 0, 0]],
    [[[ord(of$fp_reg), 3, 196, 0], [0, 0, 0, 0], 8, ord(opc$loads), 16#4408, 16#0000],
     [[ord(of$fp_reg), 3, 196, 0], [0, 0, 0, 0], 2, ord(opc$loads), 16#4409, 16#0000],
     [[ord(of$fp_reg), 3, 196, 0], [0, 0, 0, 0], 3, ord(opc$loads), 16#440A, 16#0000],
     [[ord(of$fp_reg_pair), 3, 196, 0], [ord(of$fp_reg_pair), 4, 196, 0], 9, ord(opc$loadd), 16#4409, 16#440A],
     [[ord(of$ip_reg), 3, 196, 0], [0, 0, 0, 0], 11, ord(opc$loadbu), 16#8408, 16#0000],
     [[ord(of$ip_reg), 3, 196, 0], [0, 0, 0, 0], 11, ord(opc$loadwu), 16#8408, 16#0000],
     [[ord(of$ip_reg), 3, 196, 0], [0, 0, 0, 0], 11, ord(opc$loadl), 16#8408, 16#0000]],
    [addr(spill_instr_forms.loads[3]),
     addr(spill_instr_forms.loads[1]),
     addr(spill_instr_forms.loads[2]),
     addr(spill_instr_forms.loads[0]),
     addr(spill_instr_forms.loads[6]),
     addr(spill_instr_forms.loads[5]),
     addr(spill_instr_forms.loads[4])],
    [[[ord(of$fp_reg), 1, 4, 0], [0, 0, 0, 0], 8, ord(opc$stores), 16#4010, 16#0000],
     [[ord(of$fp_reg), 1, 4, 0], [0, 0, 0, 0], 2, ord(opc$stores), 16#4011, 16#0000],
     [[ord(of$fp_reg), 1, 4, 0], [0, 0, 0, 0], 3, ord(opc$stores), 16#4012, 16#0000],
     [[ord(of$fp_reg_pair), 1, 4, 0], [ord(of$fp_reg_pair), 4, 4, 0], 9, ord(opc$stored), 16#4011, 16#4012],
     [[ord(of$ip_reg), 1, 4, 0], [0, 0, 0, 0], 11, ord(opc$storel), 16#8010, 16#0000]],
    [addr(spill_instr_forms.stores[3]),
     addr(spill_instr_forms.stores[1]),
     addr(spill_instr_forms.stores[2]),
     addr(spill_instr_forms.stores[0]),
     addr(spill_instr_forms.stores[4])],
    0, 0];

{ lir_utils_$excise_inst - instr unlinked from its block (first and
  last kept), its +2 bit 6 (marked) cleared.

  0x24C0FC, 0x52 bytes: instr (8) in A0; the second test is the flags
  of the store of next (`move.l (4,A0),(4,A1)'; bne), pattern 111. }

procedure lir_utils_$excise_inst(
    instr: instr_ptr_t);
begin
  if instr^.prev = nil then
    instr^.bb^.first := instr^.next
  else
    instr^.prev^.next := instr^.next;
  if instr^.next = nil then
    instr^.bb^.last := instr^.prev
  else
    instr^.next^.prev := instr^.prev;
  instr^.h.b2_6 := false;
end;

{ lir_utils_$create_preference_move - a move of kind's registers
  (move_opcode) put by anchor (after it when after): operand 1 read
  (16) and 2 written (8), kind and kind's non-_like form (12..14 as
  1..3); the instruction's +0 bit 6 set for the registers and their
  physical forms (1..6); for a pair (3, 6, 14) operands 3 and 4 too,
  the odd halves (18, 10), the first two then the even halves (17, 9).

  0x24C14E, 0xFC bytes: kind (8) a word in D2, anchor (10), after
  (14) a byte; the instruction in A0, the second kind in D0. }

function lir_utils_$create_preference_move(
    kind: operand$t;
    anchor: instr_ptr_t;
    after: boolean): instr_ptr_t;
var
  instr: instr_ptr_t;
  kind2: operand$t;
begin
  instr := lir_$optimizer_new_instruction(anchor, move_opcode[kind], after);
  if kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
    instr^.h.preference := true;
    kind2 := kind;
  end
  else begin
    instr^.h.preference := false;
    kind2 := kind;
    case kind of
      operand$ip_reg_like: kind2 := operand$ip_reg;
      operand$fp_reg_like: kind2 := operand$fp_reg;
      operand$fp_reg_pair_like: kind2 := operand$fp_reg_pair;
      otherwise
        ;
    end;
  end;
  instr^.opnds[1].h.kind := kind;
  opnd_bytes_ptr_t(addr(instr^.opnds[1]))^.rrp := 16;
  instr^.opnds[1].h.num := 1;
  instr^.opnds[2].h.kind := kind2;
  opnd_bytes_ptr_t(addr(instr^.opnds[2]))^.rrp := 8;
  instr^.opnds[2].h.num := 2;
  if kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
              operand$fp_reg_pair_like] then begin
    instr^.opnds[3].h.kind := kind;
    opnd_bytes_ptr_t(addr(instr^.opnds[3]))^.rrp := 18;
    instr^.opnds[3].h.num := 3;
    instr^.opnds[4].h.kind := kind2;
    opnd_bytes_ptr_t(addr(instr^.opnds[4]))^.rrp := 10;
    instr^.opnds[4].h.num := 4;
    opnd_bytes_ptr_t(addr(instr^.opnds[1]))^.rrp := 17;
    opnd_bytes_ptr_t(addr(instr^.opnds[2]))^.rrp := 9;
  end;
  lir_utils_$create_preference_move := instr;
end;

{ lir_utils_$add_lts_to_lr - a new segment of lr in bb, first on its
  list, lr's count up and the segment numbered by it; its rrp the bits
  given and lr's register class and parity (16#C003), lr's rrp gets the
  bits.

  0x24C24A, 0x5E bytes: rrp (8) a word in D2, lr (10) in A2, bb (14)
  in D3, lts (18) by address. }

procedure lir_utils_$add_lts_to_lr(
    rrp: integer;
    lr: lr_ptr_t;
    bb: bb_ptr_t;
    out lts: lts_ptr_t);
var
  l: lts_ptr_t;
begin
  l := mrh_$alloc_fixed(lir_3c00);
  l^.next := lr^.ltss;
  lr^.ltss := l;
  lr^.w56 := lr^.w56 + 1;
  l^.f2.num := lr^.w56 & 255;
  l^.lr := lr;
  l^.bb := bb;
  rrp := rrp ! (integer(lr^.rrp) & 16#C003);
  l^.rrp := rrp$set_t(rrp);
  lr^.rrp := lr^.rrp + rrp$set_t(rrp);
  lts := l;
end;

{ lir_utils_$add_lts_after_lts - a new segment of lts's live range in
  bb, after lts on its list (as add_lts_to_lr otherwise).

  0x24C2A8, 0x6A bytes: lts (8) in A2, rrp (12) a word in D2, bb (14)
  in D3; the segment in A0. }

function lir_utils_$add_lts_after_lts(
    lts: lts_ptr_t;
    rrp: integer;
    bb: bb_ptr_t): lts_ptr_t;
var
  l: lts_ptr_t;
begin
  l := mrh_$alloc_fixed(lir_3c00);
  l^.next := lts^.next;
  lts^.next := l;
  lts^.lr^.w56 := lts^.lr^.w56 + 1;
  l^.f2.num := lts^.lr^.w56 & 255;
  l^.lr := lts^.lr;
  l^.bb := bb;
  rrp := rrp ! (integer(lts^.lr^.rrp) & 16#C003);
  l^.rrp := rrp$set_t(rrp);
  lts^.lr^.rrp := lts^.lr^.rrp + rrp$set_t(rrp);
  lir_utils_$add_lts_after_lts := l;
end;

{ lir_utils_$trans_insert_move - a move put next to op's instruction so
  that op's segment, a physical register's, is separated from it by a
  new live range of op's class (a pair for a pair operand of a mated
  live range): for a read (op's +1 bit 4) the move goes before the
  instruction, reading op's old segment and writing a new one that op
  then reads (op must be the segment's only reader); for a write the
  move goes after it, op writing a new segment that the move reads, the
  move writing op's old one for its reader (op must have one reader at
  most; none, nothing is done).  The new segments' rrp are the old
  one's without parity, modify, intend_to_modify, unconsumed, spare_1
  and true_write (`andi.w #-1256'), with read and write (24); a pair's
  halves get even_only and odd_only and the move's four operands
  (move_opcode[fp_reg_pair]: 1 and 2 the even halves, 3 and 4 the odd)
  are filled here, k (1 even, 3 odd) the half op is, the mate's
  operands (utils_$find_mate_operand of op for a fp_reg_pair, else of
  the segment's definition or reader) moved the same way.

  0x24C312, 0x912 bytes: op (8) in D6 (the write path D7); the
  instruction computed inline (`move.b (A1),D0; lsl.w #2; ...;
  subi.l #32; sub.l D1,D2': utils_ins_$operands_instruction's body,
  docs/rev889-patterns.md 121) in A4 (A3); lr -20, def -36, the pair's
  move -48, new_lts -16, other_lts -12, rrp D4 (D2), the other half's
  rrp D3 (D5), pair D5 (D3, `sne'), k D2 (D4).  The kinds' sets:
  16#4048 (`btst D5,D7': fp_reg_pair, _physical, _like), 16#2024
  (fp_reg's), 16#21012 (ip_reg's and case_jump_base).  lr's mate is
  tested first, then the operand's kind again (`btst D0,D7', not the
  boolean), and the boolean once more before the other half's
  add_lts_to_lr.  In the non-pair read the move's operand 2 gets def's
  parity when the instruction is a DIVI (`cmpi.w #179,(20,A4)') or the
  new live range has a mate, else op loses its own (`andi.b #-4').
  The write path's "Multiple physical outputs" check passes -48 (the
  pair's move, never set on that path) as the instruction (`move.l
  (-48,A6),-(SP)', its +42 and its block's +10): kept
  (docs/questions.md 197).  The messages' arguments: the line, LTS
  lr.num.lts.num (the segment's number zero-extended to a longword at
  -116), inst bb.num:instr.num.

  Not known from the original: the names of the locals; whether the
  pair's move was built by a routine of its own (it is inline here). }

procedure lir_utils_$trans_insert_move(
    op: opnd_ptr_t);
var
  instr: instr_ptr_t;
  mi: instr_ptr_t;
  pm: instr_ptr_t;
  lr: lr_ptr_t;
  nlr: lr_ptr_t;
  olr: lr_ptr_t;
  def: opnd_ptr_t;
  rd: opnd_ptr_t;
  mop: opnd_ptr_t;
  mdef: opnd_ptr_t;
  d: opnd_ptr_t;
  s: opnd_ptr_t;
  new_lts: lts_ptr_t;
  other_lts: lts_ptr_t;
  rrp: integer;
  orrp: integer;
  pair: boolean;
  k: integer32;
  n: integer32;
begin
  if op^.h.read then begin
    lr := op^.lts^.lr;
    instr := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
    if at_backend_switches.level >= 4 then
      vfmt_$write('Enter LIR_UTILS_$TRANS_INSERT_MOVE (read) for instruction %3ZWD%.',
                  instr^.num);
    def := op^.lts^.refs;
    if (def^.h.read and (def <> op))
       or (not def^.h.read and (def^.link <> op))
       or (op^.link <> nil) then begin
      n := op^.lts^.f2.num;
      instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE: physical LTS has multiple consumers: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                      instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
    end;
    rrp := (integer(op^.lts^.rrp) & 16#FB18) ! 24;
    pair := op^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                           operand$fp_reg_pair_like];
    if (lr^.mate <> nil)
       and (op^.h.kind in [operand$fp_reg_pair,
                           operand$fp_reg_pair_physical,
                           operand$fp_reg_pair_like]) then begin
      if rrp$fp_reg_even_only in op^.lts^.rrp then begin
        k := 1;
        nlr := lir_$new_live_range_fp_reg_pair;
        olr := nlr^.mate;
        orrp := rrp ! 2;
        rrp := rrp ! 1;
      end
      else begin
        k := 3;
        olr := lir_$new_live_range_fp_reg_pair;
        nlr := olr^.mate;
        orrp := rrp ! 1;
        rrp := rrp ! 2;
      end;
      olr^.rrp := rrp$set_t(orrp);
      if pair then
        lir_utils_$add_lts_to_lr(orrp, olr, op^.lts^.bb, other_lts);
    end
    else if op^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                           operand$fp_reg_like] then
      nlr := lir_$new_live_range_fp_reg
    else if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                           operand$ip_reg_like,
                           operand$case_jump_base] then
      nlr := lir_$new_live_range_ip_reg
    else
      nlr := lir_$new_live_range;
    nlr^.rrp := rrp$set_t(rrp);
    lir_utils_$add_lts_to_lr(rrp, nlr, op^.lts^.bb, new_lts);
    if pair then begin
      mi := lir_$optimizer_new_instruction(instr,
              move_opcode[operand$fp_reg_pair], false);
      d := addr(mi^.opnds[k + 1]);
      d^.h.kind := op^.h.kind;
      opnd_bytes_ptr_t(d)^.rrp := 8 ! (rrp & 3);
      d^.lts := new_lts;
      d^.link := op;
      new_lts^.refs := d;
      d^.h.num := k + 1;
      s := addr(mi^.opnds[k]);
      s^.h.kind := def^.h.kind;
      opnd_bytes_ptr_t(s)^.rrp := 16 ! (rrp & 3);
      s^.lts := op^.lts;
      s^.link := nil;
      s^.h.num := k;
      if def = op then
        op^.lts^.refs := s
      else
        def^.link := s;
      op^.lts := new_lts;
      if op^.h.kind = operand$fp_reg_pair then begin
        mop := utils_$find_mate_operand(op);
        mdef := mop^.lts^.refs;
        if mop^.lts^.lr^.mate <> lr then begin
          n := op^.lts^.f2.num;
          instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE 1 -- found operand but LRs are not mated: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
        end;
      end
      else begin
        mdef := utils_$find_mate_operand(def);
        mop := mdef^.link;
        if mdef^.lts^.lr^.mate <> lr then begin
          n := op^.lts^.f2.num;
          instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE 2 -- found operand but LRs are not mated: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
        end;
      end;
      d := addr(mi^.opnds[5 - k]);
      if mop = nil then
        d^.h.kind := operand$fp_reg
      else
        d^.h.kind := mop^.h.kind;
      opnd_bytes_ptr_t(d)^.rrp := 8 ! (orrp & 3);
      d^.lts := other_lts;
      d^.link := mop;
      other_lts^.refs := d;
      d^.h.num := 5 - k;
      s := addr(mi^.opnds[4 - k]);
      s^.h.kind := mdef^.h.kind;
      opnd_bytes_ptr_t(s)^.rrp := 16 ! (orrp & 3);
      s^.lts := mdef^.lts;
      s^.link := nil;
      s^.h.num := 4 - k;
      if mdef = mop then
        mop^.lts^.refs := s
      else
        mdef^.link := s;
      if mop <> nil then
        mop^.lts := other_lts;
    end
    else begin
      pm := lir_utils_$create_preference_move(op^.h.kind, instr, false);
      opnd_bytes_ptr_t(addr(pm^.opnds[2]))^.rrp :=
        (opnd_bytes_ptr_t(def)^.rrp & 64) ! 8;
      if (instr^.opc = ord(opc$divi)) or (new_lts^.lr^.mate <> nil) then
        opnd_bytes_ptr_t(addr(pm^.opnds[2]))^.rrp :=
          opnd_bytes_ptr_t(addr(pm^.opnds[2]))^.rrp
          ! (opnd_bytes_ptr_t(def)^.rrp & 3)
      else
        opnd_bytes_ptr_t(op)^.rrp := opnd_bytes_ptr_t(op)^.rrp & 16#FC;
      pm^.opnds[2].lts := new_lts;
      pm^.opnds[2].link := op;
      new_lts^.refs := addr(pm^.opnds[2]);
      pm^.opnds[1].lts := op^.lts;
      pm^.opnds[1].link := nil;
      if def = op then
        op^.lts^.refs := addr(pm^.opnds[1])
      else
        def^.link := addr(pm^.opnds[1]);
      op^.lts := new_lts;
    end;
  end
  else begin
    rd := op^.link;
    if rd = nil then
      return;
    if rd^.link <> nil then begin
      n := op^.lts^.f2.num;
      instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE: Multiple physical outputs: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                      mi^, op^.lts^.lr^.num, n, mi^.bb^.num, mi^.num);
    end;
    lr := op^.lts^.lr;
    instr := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
    if at_backend_switches.level >= 4 then
      vfmt_$write('Enter lir_utils_$trans_insert_move (write) for instruction %3ZWD%.',
                  instr^.num);
    rrp := (integer(op^.lts^.rrp) & 16#FB18) ! 24;
    pair := op^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                           operand$fp_reg_pair_like];
    if (lr^.mate <> nil)
       and (op^.h.kind in [operand$fp_reg_pair,
                           operand$fp_reg_pair_physical,
                           operand$fp_reg_pair_like]) then begin
      if rrp$fp_reg_even_only in op^.lts^.rrp then begin
        k := 1;
        nlr := lir_$new_live_range_fp_reg_pair;
        olr := nlr^.mate;
        orrp := rrp ! 2;
        rrp := rrp ! 1;
      end
      else begin
        k := 3;
        olr := lir_$new_live_range_fp_reg_pair;
        nlr := olr^.mate;
        orrp := rrp ! 1;
        rrp := rrp ! 2;
      end;
      olr^.rrp := rrp$set_t(orrp);
      if pair then
        lir_utils_$add_lts_to_lr(orrp, olr, op^.lts^.bb, other_lts);
    end
    else if op^.h.kind in [operand$fp_reg, operand$fp_reg_physical,
                           operand$fp_reg_like] then
      nlr := lir_$new_live_range_fp_reg
    else if op^.h.kind in [operand$ip_reg, operand$ip_reg_physical,
                           operand$ip_reg_like,
                           operand$case_jump_base] then
      nlr := lir_$new_live_range_ip_reg
    else
      nlr := lir_$new_live_range;
    nlr^.rrp := rrp$set_t(rrp);
    lir_utils_$add_lts_to_lr(rrp, nlr, op^.lts^.bb, new_lts);
    if pair then begin
      mi := lir_$optimizer_new_instruction(instr,
              move_opcode[operand$fp_reg_pair], true);
      d := addr(mi^.opnds[k + 1]);
      d^.h := op^.h;
      d^.h.kind := rd^.h.kind;
      d^.lts := op^.lts;
      d^.link := op^.link;
      d^.lts^.refs := d;
      opnd_bytes_ptr_t(d)^.rrp := (opnd_bytes_ptr_t(d)^.rrp & 123) ! 8;
      d^.h.num := k + 1;
      d^.h.b2_3_0 := 0;
      s := addr(mi^.opnds[k]);
      s^.h := rd^.h;
      s^.h.kind := op^.h.kind;
      opnd_bytes_ptr_t(s)^.rrp := (opnd_bytes_ptr_t(s)^.rrp & 3) ! 16;
      s^.h.count := 0;
      s^.h.num := k;
      s^.lts := new_lts;
      s^.link := nil;
      op^.link := s;
      new_lts^.refs := op;
      op^.lts := new_lts;
      if op^.h.kind = operand$fp_reg_pair then begin
        mdef := utils_$find_mate_operand(op);
        mop := mdef^.link;
        if mdef^.lts^.lr^.mate <> lr then begin
          n := op^.lts^.f2.num;
          instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE 3 -- found operand but LRs are not mated: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
        end;
      end
      else begin
        mop := utils_$find_mate_operand(rd);
        mdef := mop^.lts^.refs;
        if mop^.lts^.lr^.mate <> lr then begin
          n := op^.lts^.f2.num;
          instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE 4 -- found operand but LRs are not mated: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                          instr^, op^.lts^.lr^.num, n, instr^.bb^.num, instr^.num);
        end;
      end;
      if mop <> nil then begin
        if (mdef^.link <> mop) or (mop^.link <> nil) then
          instr_bug_check('LIR_UTILS_$TRANS_INSERT_MOVE: badly formed LTS on register pair near line %LD%$',
                          mi^);
        d := addr(mi^.opnds[5 - k]);
        d^.h := mdef^.h;
        d^.h.kind := mop^.h.kind;
        d^.lts := mdef^.lts;
        d^.link := mdef^.link;
        d^.lts^.refs := d;
        opnd_bytes_ptr_t(d)^.rrp := (opnd_bytes_ptr_t(d)^.rrp & 123) ! 8;
        d^.h.num := 5 - k;
        d^.h.b2_3_0 := 0;
        s := addr(mi^.opnds[4 - k]);
        s^.h := mop^.h;
        s^.h.kind := mdef^.h.kind;
        opnd_bytes_ptr_t(s)^.rrp := (opnd_bytes_ptr_t(s)^.rrp & 3) ! 16;
        s^.h.count := 0;
        s^.h.num := 4 - k;
        s^.lts := other_lts;
        s^.link := nil;
        mdef^.link := s;
        other_lts^.refs := mdef;
        mdef^.lts := other_lts;
        mi^.opnds[1].h.fp_reg_even_only := true;
        mi^.opnds[2].h.fp_reg_even_only := true;
        mi^.opnds[3].h.fp_reg_odd_only := true;
        mi^.opnds[4].h.fp_reg_odd_only := true;
      end;
    end
    else begin
      pm := lir_utils_$create_preference_move(op^.h.kind, instr, true);
      pm^.opnds[2].lts := op^.lts;
      pm^.opnds[2].link := op^.link;
      pm^.opnds[2].lts^.refs := addr(pm^.opnds[2]);
      opnd_bytes_ptr_t(addr(pm^.opnds[2]))^.rrp :=
        opnd_bytes_ptr_t(addr(pm^.opnds[2]))^.rrp
        ! (opnd_bytes_ptr_t(op)^.rrp & 67);
      pm^.opnds[1].lts := new_lts;
      pm^.opnds[1].link := nil;
      op^.link := addr(pm^.opnds[1]);
      new_lts^.refs := op;
      op^.lts := new_lts;
      opnd_bytes_ptr_t(op)^.rrp := opnd_bytes_ptr_t(op)^.rrp & 16#FC;
    end;
  end;
end;

{ assign_spill_id - the routine's next spill id (its +196 counted up;
  bug_check when it overflows) to id (the counter's low word).

  0x24CFC4, 0x30 bytes, no A5: rtn (8) in A3, id (12) a word by
  address. }

procedure assign_spill_id(
    rtn: rtn_ptr_t;
    out id: integer); options(val_param); internal;
begin
  rtn^.spills := rtn^.spills + 1;
  if rtn^.spills < 0 then
    bug_check('RA_UTILS: ASSIGN_SPILL_ID -- counter overflow.%$');
  id := rtn^.spills & 16#FFFF;
end;

{ lir_utils_$get_new_memory_home - a new temporary for lr's home:
  integral (kind 122) of 32 bits for an integer register, floating
  (123) of 32 bits for a single, 64 for a pair (lr has a mate); its +44
  2 or 3 and size 4 or 8; in il_180's block, its +28 lr's old home and
  its name (+4) name, or (when name is nil) the old home's: a
  variable's name, a common member's identifier (idntk 76 of its +72
  name), else nil.

  0x24D024, 0xCE bytes: lr (8) in A4, name (12) by address in D2,
  size (16) by address in A2; the node in A3, then A0. }

function lir_utils_$get_new_memory_home(
    lr: lr_ptr_t;
    var name: univ_ptr;
    out size: integer32): il_$node_ptr_t;
var
  t: il_$node_ptr_t;
  m: il_$node_ptr_t;
begin
  if rrp$ip_reg in lr^.rrp then begin
    t := make_expression_temporary(122, 32);
    t^.xw[22] := 2;
    size := 4;
  end
  else if lr^.mate = nil then begin
    t := make_expression_temporary(123, 32);
    t^.xw[22] := 2;
    size := 4;
  end
  else begin
    t := make_expression_temporary(123, 64);
    t^.xw[22] := 3;
    size := 8;
  end;
  t^.xp[5] := il_180;
  m := lr^.memory_home;
  if m <> nil then begin
    t^.xp[7] := m;
    if name = nil then
      case m^.kind of
        109: name := m^.xp[1];
        110: name := idntk(76, m^.xc[72], m^.xw[35]);
        otherwise
          name := nil;
      end;
  end;
  t^.xp[1] := name;
  lir_utils_$get_new_memory_home := t;
end;

{ lir_utils_$add_memory_home - lr's memory home (an odd half's: its
  mate's; its +32 live range's first, whose home it shares): the home
  it has when it is big enough (8 bytes for a pair, 4 else), marked
  spilled (flag 29 set, 18 and 27 cleared; a spill id the first time;
  a variable's +44 at least 2), else a new temporary
  (get_new_memory_home, a common member's identifier as its name),
  allocated static when static, with a spill id; the mate shares it.

  0x24D0F2, 0x18C bytes: rtn (8) in D3, lr (12) in A3, static (16) a
  byte in D2; the home in A2, its size in D0, the name in -8, the new
  home's size in -20; recursive.  The flags: a variable's (109)
  longword at +32 (c_sym_t's var_flags), a common member's (110) at
  +24; the id a word at +74 or +16. }

procedure lir_utils_$add_memory_home(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t;
    static: boolean);
label
  10;
var
  m: il_$node_ptr_t;
  name: univ_ptr;
  sz: integer32;
  newsz: integer32;
  f: integer32;
begin
  if rrp$fp_reg_odd_only in lr^.rrp then
    lr := lr^.mate;
  if lr^.home_lr <> nil then begin
    lir_utils_$add_memory_home(rtn, lr^.home_lr, static);
    lr^.memory_home := lr^.home_lr^.memory_home;
  end;
  name := nil;
  m := lr^.memory_home;
  if m = nil then
    goto 10;
  sz := sym_$allocation_size_in_bytes(m);
  if m^.kind = 109 then begin
    if lr^.mate <> nil then
      if sz < 8 then
        goto 10;
    if sz < 4 then
      goto 10;
    m^.xp[5] := il_180;
    f := m^.xl[8];
    if (f & 16#20000000) = 0 then
      assign_spill_id(rtn, m^.xw[37]);
    f := (f & 16#F7FBFFFF) ! 16#20000000;
    m^.xl[8] := f;
    if m^.xw[22] < 2 then
      m^.xw[22] := 2;
  end
  else if m^.kind = 110 then begin
    if ((lr^.mate <> nil) and (sz < 8)) or (sz < 4) then begin
      name := idntk(76, m^.xc[72], m^.xw[35]);
      goto 10;
    end;
    f := m^.xl[6];
    if (f & 16#20000000) = 0 then
      assign_spill_id(rtn, m^.xw[8]);
    f := (f & 16#F7FBFFFF) ! 16#20000000;
    m^.xl[6] := f;
  end
  else
    bug_check('LIR_UTILS_$ADD_MEMORY_HOME -- unexpected object in LR^.memory_home%$');
  if lr^.mate <> nil then
    lr^.mate^.memory_home := m;
  return;

10:
  m := lir_utils_$get_new_memory_home(lr, name, newsz);
  lr^.memory_home := m;
  if lr^.mate <> nil then
    lr^.mate^.memory_home := m;
  m^.xc[32] := chr(ord(m^.xc[32]) ! 16#20);
  if static then
    sym_$allocate_static_variable(m, newsz);
  assign_spill_id(rtn, m^.xw[37]);
end;

{ add_new_operand - instr's operand k made: cleared, numbered, its rrp
  byte rrp, kind, unlinked, of segment lts (whose rrp gets rrp; the
  first reference becomes lts's refs), chained after last (which then
  points to it).

  0x24D2C4, 0x88 bytes, no A5: instr (8), k (12), kind (16) and rrp
  (18) words, lts (20), last (24) by address. }

procedure add_new_operand(
    instr: instr_ptr_t;
    k: integer32;
    kind: operand$t;
    rrp: integer;
    lts: lts_ptr_t;
    var last: opnd_ptr_t); options(val_param); internal;
var
  op: opnd_ptr_t;
begin
  op := addr(instr^.opnds[k]);
  opnd_bytes_ptr_t(op)^.num := 0;
  opnd_bytes_ptr_t(op)^.rrp := 0;
  opnd_bytes_ptr_t(op)^.b2 := 0;
  opnd_bytes_ptr_t(op)^.b3 := 0;
  op^.link := nil;
  op^.value := 0;
  op^.h.num := k;
  opnd_bytes_ptr_t(op)^.rrp := rrp & 255;
  op^.h.b2_3_0 := 0;
  op^.h.kind := kind;
  op^.link := nil;
  op^.lts := lts;
  lts^.rrp := lts^.rrp + rrp$set_t(rrp);
  if lts^.refs = nil then
    lts^.refs := op;
  if last <> nil then
    last^.link := op;
  last := op;
end;

{ lir_utils_$flesh_out_new_load_or_store - the operands of a new load or
  store instr, as desc describes it: reg the register (segment lts,
  solution ra_utils_10 with lts's live range, its physical register and
  flags, desc's kind, form desc^.form), for a pair (kind 9) reg2 the
  odd half (lts2, form2) and reg even, reg2 odd; the address: with no
  home, a frame temporary (base from isc_user_routines_330, the home a
  constant 0.0 for a pair, else smcontk(81, 0) with lir_main_250's bytes
  4); a static home through the DB register (the routine needs it: at
  _backend_4fc's needs_db; db_lts, made by new_db_lts the first time,
  read by a new ip_reg operand, its displacement sym_$displacement in
  lir_main_760); else base from isc_user_routines_340; addr_op from
  the solution with home as its node and the form forms[3] (4 more for
  a pair's low half, kind 3); instr marked kept (+2 bit 6) and given
  pos's source position.

  0x24D34C, 0x288 bytes: reg (8), reg2 (12), addr_op (16), base (20),
  home (24), lts (28) in A2, lts2 (32), desc (36) in D6, instr (40) in
  D5, pos (44) in D4, db_lts (48) by address in D3, db_last (52) in
  D2, new_db_lts (56) called `jsr (A1)' (a nested routine of
  fix_store_through_lrs, through its trampoline).  The rrp ORed as
  words (`or.w D0,(A2)'); post's flags byte (+0x70B) stored bit by bit
  (`smi; lsr.b #7; lsl.b #3; andi.b #-9; or.b'); the 0.0 is the 8 zero
  bytes at 0x24D5D4 passed to dpcontk; the operand number of the DB
  register's operand is forms[1]'s (`move.b 0x513E35,D1'), its kind
  and rrp one longword (`move.l #65552', ip_reg and read).  After the
  address lir_main_760's node is cleared (`move.l #0,0x48BB0C').

  Not known from the original: the names of the parameters. }

procedure lir_utils_$flesh_out_new_load_or_store(
    reg: opnd_ptr_t;
    reg2: opnd_ptr_t;
    addr_op: opnd_ptr_t;
    base: opnd_ptr_t;
    home: univ_ptr;
    lts: lts_ptr_t;
    lts2: lts_ptr_t;
    desc: spill_desc_ptr_t;
    instr: instr_ptr_t;
    pos: instr_ptr_t;
    var db_lts: lts_ptr_t;
    var db_last: opnd_ptr_t;
    function new_db_lts: lts_ptr_t);
var
  lr: lr_ptr_t;
  sol: solution_ptr_t;
begin
  lr := lts^.lr;
  lts^.rrp := rrp$set_t(integer(lts^.rrp) ! integer(desc^.rrp));
  lr^.rrp := rrp$set_t(integer(lr^.rrp) ! integer(desc^.rrp));
  ra_utils_10.kind := desc^.kind;
  ra_utils_10.live_range := lr;
  ra_utils_10.f78.physical_register := lr^.f2.physical;
  ra_utils_10.f78.physical_register_is_no_modify := lr^.f2.no_modify;
  ra_utils_10.f78.physical_register_user_declared := lr^.f2.serialize;
  ra_utils_10.f78.physical_register_number := lr^.f2.reg;
  lir_$build_operand(reg, addr(ra_utils_10), desc^.form);
  reg^.lts := lts;
  if desc^.kind = 9 then begin
    lr := lts2^.lr;
    lts2^.rrp := rrp$set_t(integer(lts2^.rrp) ! integer(desc^.rrp2));
    lr^.rrp := rrp$set_t(integer(lr^.rrp) ! integer(desc^.rrp2));
    ra_utils_10.live_range := lr;
    ra_utils_10.f78.physical_register_number := lr^.f2.reg;
    lir_$build_operand(reg2, addr(ra_utils_10), desc^.form2);
    reg2^.lts := lts2;
    reg^.h.fp_reg_even_only := true;
    reg2^.h.fp_reg_even_only := false;
    reg2^.h.fp_reg_odd_only := true;
  end;
  if home = nil then begin
    lir_$build_operand(base, isc_user_routines_330, spill_instr_forms.forms[1]);
    if lts2 <> nil then
      home := dpcontk(0.0)
    else begin
      home := smcontk(81, 0);
      lir_main_250.bytes := 4;
    end;
    lir_main_250.literal_32_bits_value := 0;
    sol := addr(lir_main_250);
  end
  else if sym_$is_static_vat(home) then begin
    rtn_ptr_t(at_backend_4fc)^.f226.needs_db := true;
    if db_lts = nil then
      db_lts := new_db_lts;
    add_new_operand(instr, spill_instr_forms.forms[1].num, operand$ip_reg,
                    16, db_lts, db_last);
    lir_main_760.literal_32_bits_value := sym_$displacement(home);
    sol := addr(lir_main_760);
  end
  else begin
    lir_$build_operand(base, isc_user_routines_340, spill_instr_forms.forms[1]);
    lir_main_250.literal_32_bits_value := 0;
    sol := addr(lir_main_250);
  end;
  sol^.object_with_name := home;
  lir_$build_operand(addr_op, sol, spill_instr_forms.forms[3]);
  lir_main_760.object_with_name := nil;
  if desc^.kind = 3 then
    addr_op^.value := addr_op^.value + 4;
  instr^.h.b2_6 := true;
  if pos <> nil then begin
    instr^.h.b0_1 := pos^.h.b0_1;
    instr^.l32 := pos^.l32;
  end;
end;

{ nolonger_exposed - lr no longer exposed in bb: its exposed segment
  there (utils_$find_exposed_lts) off the list (the hint and the one
  before it kept), and lr's bits in bb's live_in and live_gen cleared,
  in transparent set.

  0x24D5DC, 0x7E bytes, no A5: lr (8) in A2, bb (12) in D2. }

procedure nolonger_exposed(
    lr: lr_ptr_t;
    bb: bb_ptr_t); options(val_param); internal;
var
  lts: lts_ptr_t;
  nx: lts_ptr_t;
begin
  lts := utils_$find_exposed_lts(lr, bb);
  if lts <> nil then begin
    lts^.f2.exposed := false;
    nx := lts^.next_exposed;
    if lr^.exposed_prev = nil then
      lr^.exposed := nx
    else
      lr^.exposed_prev^.next_exposed := nx;
    lr^.exposed_hint := nx;
  end;
  bv_$clear(bb^.live_in, lr);
  bv_$clear(bb^.live_gen, lr);
  bv_$set(bb^.transparent, lr);
end;

{ lir_utils_$get_next_async_exposed_lr - the next complex id after
  lr's (from the start when lr is nil) in the live_in of an
  asynchronous path's first block: the start block's edges (edge nil
  to begin: the routine's first block's succs, whose source must be
  the start block, block$start) whose target is on an asynchronous
  path (+17 bit 4); the path's block the target itself when it has +17
  bit 2, else its successor that has (the target when both have);
  0 when none is left.

  0x24D65A, 0xF4 bytes: rtn (8) in D3, lr (12), edge (16) by address
  in A3; the block in A2. }

function lir_utils_$get_next_async_exposed_lr(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t;
    var edge: univ fg_edge_ptr_t): integer32;
label
  10, 20;
var
  b: bb_ptr_t;
  t: bb_ptr_t;
  e: fg_edge_ptr_t;
  k: integer32;
begin
  if edge = nil then begin
    edge := rtn^.bbs^.succs;
    if edge = nil then
      goto 20;
    if edge^.source^.f14.kind <> 1 then
      bug_check('LIR_UTILS_$GET_NEXT_ASYNC_EXPOSED_LR:  can''t find start block%$');
    goto 10;
  end;
  repeat
    b := edge^.target;
    if b^.f.asynchronous_return then begin
      if not b^.f.asynchronous_path then begin
        e := b^.succs;
        t := e^.target;
        if t^.f.asynchronous_path then begin
          if not e^.next_succ^.target^.f.asynchronous_path then
            b := t;
        end
        else begin
          b := b^.succs^.next_succ^.target;
          if not b^.f.asynchronous_path then
            bug_check('LIR_UTILS_$GET_NEXT_ASYNC_EXPOSED_LR:  not asynchronous path%$');
        end;
      end;
      if lr = nil then
        k := 0
      else
        k := lr^.id;
      k := bv_$find_next_val(rtn, b^.live_in, k);
      if k <> 0 then begin
        lir_utils_$get_next_async_exposed_lr := k;
        return;
      end;
    end;
    lr := nil;
    edge := edge^.next_succ;
  10:
  until edge = nil;
20:
  lir_utils_$get_next_async_exposed_lr := 0;
end;

{ lir_utils_$fix_store_through_lrs - the store-through live ranges: those
  whose value must be in memory when an asynchronous path or a handler
  may resume.
  1. With handlers (il_180's +379 bit 4, or lir_main_c8c): each live
     range of a register (rrp ip_reg or fp_reg) live into an entry
     block, not physical, holding a common member (kind 110 other than
     il_180's +96, its +26 bit 14 clear) not yet store-through, whose
     home is none or of vat 1, made store-through with its mate; given
     a static memory home when either is written (else none);
     cgerr 48 on the member.
  2. Every live range's segments forgotten (count, list); the routine's
     save_rpc set when it has an asynchronous return.
  3. Each live range live into an asynchronous path
     (lir_utils_$get_next_async_exposed_lr) of a register, not the
     routine's l112, not physical, not yet store-through: made
     store-through with its mate, given a memory home.
  4. Each block's instructions relinked and renumbered: at a dynamic
     entry (an asynchronous path that is also an asynchronous return,
     or one whose only predecessor is an asynchronous return off the
     path) or, with handlers, at an entry block, before its first
     instruction that is not opcode 199 (and, at an entry block, once
     the DB register's segment is known), a load of each store-through
     live range live in (loads[3] for a pair's even half, loads[0] for
     a floating register, loads[6] for an integer one: their exposed
     segments become the loads' operands and are no longer exposed;
     each load also reads lir_3ba8, the memory); after each kept
     instruction (+2 bit 6, numbered) that writes a store-through
     register (not the AP's, not a pair's odd half: store_ptrs by
     kind and parity) a store after it (and after the group it begins),
     reading the register and the memory segment and writing a new
     memory segment; the memory's and the DB register's segments
     tracked through the block (xlts, db_lts) and their readers
     chained; at the end each is final when its live range is live
     out.
  5. With handlers, a home of a vat other than 2 not flagged (bit 28) is
     dropped; when none is left, il_180's +379 bit 4 and lir_main_c8c
     are cleared.
  The four forms' operand numbers are set for loads (1, 3 at +9, base
  2 at +13 and address 3 at +5 for the stores; 1 and 2 at the loads).

  0x24D808, 0xC8E bytes: rtn (8); new_db_lts's trampoline built at -156
  (`move.w #16889; move.l A5; move.w #17401; move.l A6; move.w #20217;
  move.l #0x24D7CC' and cache_$clear: lea A5's value,A0; lea the frame,
  A1; jmp, for the nested routine passed to
  lir_utils_$flesh_out_new_load_or_store); trace D5 (the switches'
  level nonzero), handlers -134, bb -124, the block's live_in -120,
  db_lr -116, db_lts -112, db_last -108, the instruction counter D4,
  prev -72, xlts -44, xlast -40, at_entry -132, dynamic -138; the
  instruction -76.  The kinds' sets: 4094 (`btst D3,D6': 1..11), 126
  (1..6).  The trace's mnemonic length is the longword 12 at
  0x24E5F0 passed by address (docs/rev889-patterns.md 116), the 'STATIC'
  line's name the member's +72 with its +70 word; the first '%.' is
  the head of the 'STATIC' line's constant (pattern 119).  The relinking
  of a found exposed segment to the head of its live range's list
  (`cmpa.l 0x48AD4C,A0') neither unlinks it from where it is: kept.
  The memory segment's flags first_in_bb and final cleared and set as
  one word (`andi.w #-81', `or.w #80').  get_exposed_lts is called for
  the mate even when there is none (`move.l (16,A1),-(SP)'): kept.

  Not known from the original: the names of the locals; the order of
  the tests in the conditions (taken from the branches). }

procedure lir_utils_$fix_store_through_lrs(
    rtn: rtn_ptr_t);
var
  trace: boolean;
  handlers: boolean;
  at_entry: boolean;
  dynamic: boolean;
  created: boolean;
  any: boolean;
  bb: bb_ptr_t;
  v: bv_ptr_t;
  lr: lr_ptr_t;
  lr2: lr_ptr_t;
  db_lr: lr_ptr_t;
  node: il_$node_ptr_t;
  db_lts: lts_ptr_t;
  db_last: opnd_ptr_t;
  xlts: lts_ptr_t;
  xlast: opnd_ptr_t;
  e1: lts_ptr_t;
  e2: lts_ptr_t;
  l: lts_ptr_t;
  head: lts_ptr_t;
  instr: instr_ptr_t;
  prev: instr_ptr_t;
  ni: instr_ptr_t;
  at: instr_ptr_t;
  op: opnd_ptr_t;
  def: opnd_ptr_t;
  desc: spill_desc_ptr_t;
  edge: fg_edge_ptr_t;
  wr: integer;
  vat: integer;
  n: integer32;
  j: integer32;
  k: integer32;
  count: integer32;
  f: integer32;
  kind: operand$t;

  { new_db_lts - the DB register's exposed segment in the parent's bb,
    read and without references.  0x24D7CC, 0x3C bytes: the parent's
    frame in A1 (rtn its 8, bb its -124); created -14; the segment
    left in A0. }

  function new_db_lts: lts_ptr_t;
  var
    created: boolean;
    l: lts_ptr_t;
  begin
    l := utils_$get_exposed_lts(rtn^.db_lr, bb, created);
    l^.rrp := l^.rrp + [rrp$read];
    l^.refs := nil;
    new_db_lts := l;
  end;

begin
  trace := at_backend_switches.level <> 0;
  if trace then
    vfmt_$write('%/%/TRACE OF LIR_UTILS_$FIX_STORE_THROUGH_LRS%/%.');
  handlers := ((ord(il_180^.xc[379]) & 16#10) <> 0) or lir_main_c8c;
  if handlers then begin
    if trace then
      vfmt_$write('%.');
    bb := rtn^.bbs;
    while bb <> nil do begin
      if bb^.f.entry then begin
        v := bb^.live_in;
        lr := nil;
        repeat
          lr := bv_$find_next(rtn, v, lr);
          if lr = nil then
            exit;
          if (integer(lr^.rrp) & 16#C000) = 0 then
            next;
          if lr^.f2.physical then
            next;
          if lr^.f2.no_modify then
            bug_check('LIR_UTILS_$FIX_STORE_THROUGH_LRS -- static store through is no_modify register.%$');
          node := lr^.node20;
          if node = nil then
            next;
          if node^.kind <> 110 then
            next;
          if node = il_180^.xp[24] then
            next;
          if (node^.xw[13] & 16#4000) <> 0 then
            next;
          if rrp$store_through in lr^.rrp then
            next;
          if lr^.memory_home <> nil then
            if (ord(il_$node_ptr_t(lr^.memory_home)^.xc[11]) & 16#F0) div 16 <> 1 then
              next;
          wr := integer(lr^.rrp) & 12;
          lr^.rrp := lr^.rrp + [rrp$store_through];
          lr2 := lr^.mate;
          if lr2 <> nil then begin
            wr := wr ! (integer(lr2^.rrp) & 12);
            lr2^.rrp := lr2^.rrp + [rrp$store_through];
          end;
          if wr <> 0 then
            lir_utils_$add_memory_home(rtn, lr, true)
          else begin
            lr^.memory_home := nil;
            if lr2 <> nil then
              lr2^.memory_home := nil;
          end;
          cgerr(48, 0, node);
          if trace then begin
            n := node^.xw[35] & 16#FFFF;
            vfmt_$write('  STORE_THROUGH (STATIC):  LR %3ZWD  "%A"%.',
                        lr^.num, node^.xc[72], n);
          end;
        until false;
      end;
      bb := bb^.next;
    end;
    if trace then
      vfmt_$write('%.');
  end;

  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.w56 := 0;
    lr^.ltss := nil;
    lr := lr^.next;
  end;
  if rtn^.f226.asynchronous_return then
    rtn^.f226.save_rpc := true;
  if trace then
    vfmt_$write('  %.');

  lr := nil;
  edge := nil;
  repeat
    k := lir_utils_$get_next_async_exposed_lr(rtn, lr, edge);
    if k = 0 then
      exit;
    lr := rtn^.lr_map^[k];
    if (integer(lr^.rrp) & 16#C000) = 0 then
      next;
    if lr = lr_ptr_t(rtn^.l112) then
      next;
    if lr^.f2.physical then
      next;
    if rrp$store_through in lr^.rrp then
      next;
    if lr^.f2.no_modify then
      bug_check('LIR_UTILS_$FIX_STORE_THROUGH_LRS -- store through is no_modify register.%$');
    lr^.rrp := lr^.rrp + [rrp$store_through];
    if lr^.mate <> nil then
      lr^.mate^.rrp := lr^.mate^.rrp + [rrp$store_through];
    lir_utils_$add_memory_home(rtn, lr, false);
    if trace then
      vfmt_$write('  STORE_THROUGH (DYNAMIC): LR %3ZWD%.', lr^.num);
  until false;
  if trace then
    vfmt_$write('%.');

  spill_instr_forms.forms[0].num := 1;
  spill_instr_forms.forms[2].num := 3;
  spill_instr_forms.forms[3].num := 2;
  spill_instr_forms.forms[1].num := 3;
  count := 0;
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.exposed := nil;
    bb^.finals := nil;
    db_lr := rtn^.db_lr;
    db_lts := nil;
    db_last := nil;
    xlts := nil;
    xlast := nil;
    prev := nil;
    if (bb^.f.asynchronous_return and bb^.f.asynchronous_path)
       or (bb^.f.asynchronous_path and (bb^.preds <> nil)
           and (bb^.preds^.next_pred = nil)
           and bb^.preds^.source^.f.asynchronous_return
           and not bb^.preds^.source^.f.asynchronous_path) then begin
      at_entry := true;
      dynamic := true;
    end
    else if handlers and bb^.f.entry then begin
      at_entry := true;
      dynamic := false;
    end
    else
      at_entry := false;
    instr := bb^.first;
    bb^.first := nil;
    while instr <> nil do begin
      if at_entry and (instr^.opc <> 199) and (dynamic or (db_lts <> nil)) then begin
        at_entry := false;
        spill_instr_forms.forms[3].num := 1;
        spill_instr_forms.forms[1].num := 2;
        v := bb^.live_in;
        lr := nil;
        repeat
          lr := bv_$find_next(rtn, v, lr);
          if lr = nil then
            exit;
          if not (rrp$store_through in lr^.rrp) then
            next;
          if lr^.mate <> nil then begin
            if not (rrp$fp_reg_even_only in lr^.rrp) then
              next;
          end;
          if lr^.mate <> nil then
            desc := addr(spill_instr_forms.loads[3])
          else if rrp$fp_reg in lr^.rrp then
            desc := addr(spill_instr_forms.loads[0])
          else
            desc := addr(spill_instr_forms.loads[6]);
          if lr^.memory_home = nil then
            ni := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
                    desc^.opc, 0, nil, 0)
          else
            ni := lir_$get_new_instruction_no_exceptions(addr(lir_3b80),
                    desc^.opc, 16#2000, lr^.memory_home, 0);
          ni^.bb := bb;
          e1 := utils_$get_exposed_lts(lr, bb, created);
          e2 := utils_$get_exposed_lts(lr^.mate, bb, created);
          lir_utils_$flesh_out_new_load_or_store(addr(ni^.opnds[3]),
            addr(ni^.opnds[4]), addr(ni^.opnds[1]), addr(ni^.opnds[2]),
            lr^.memory_home, e1, e2, desc, ni, bb^.first, db_lts, db_last,
            new_db_lts);
          ni^.opnds[3].link := e1^.refs;
          e1^.refs := addr(ni^.opnds[3]);
          if ni^.opnds[3].lts^.lr = db_lr then begin
            db_last := addr(ni^.opnds[3]);
            db_lts := ni^.opnds[3].lts;
          end;
          e1^.f2.exposed := false;
          nolonger_exposed(e1^.lr, bb);
          if e2 <> nil then begin
            ni^.opnds[4].link := e2^.refs;
            e2^.refs := addr(ni^.opnds[4]);
            e2^.f2.exposed := false;
            nolonger_exposed(e2^.lr, bb);
          end;
          if xlts = nil then begin
            xlts := utils_$get_exposed_lts(addr(lir_3ba8), bb, created);
            xlts^.rrp := xlts^.rrp + [rrp$read];
            xlts^.refs := nil;
          end;
          j := ni^.h.nopnds - ord(instruction_attributes[ni^.opc].b14_0);
          add_new_operand(ni, j, operand$inscrutable_memory, 16, xlts, xlast);
          count := count + 1;
          ni^.num := count;
          if prev = nil then
            bb^.first := ni
          else
            prev^.next := ni;
          ni^.prev := prev;
          prev := ni;
        until false;
        spill_instr_forms.forms[3].num := 2;
        spill_instr_forms.forms[1].num := 3;
      end;
      if trace then begin
        n := ord(instr^.h.grouped);
        vfmt_$write('BB#%3ZWD%4WD: %ZA   (continued = %D)%.', bb^.num,
                    instr^.num, instruction_mnemonic[instr^.opc], 12, n);
      end;
      if instr^.h.b2_6 and (instr^.num <> 0) then begin
        if xlts = nil then begin
          xlts := utils_$find_exposed_lts(addr(lir_3ba8), bb);
          if (xlts <> nil) and (xlts <> lir_3ba8.ltss) then begin
            head := lir_3ba8.ltss;
            if head <> nil then
              if head^.bb = bb then begin
                head^.f2.first_in_bb := false;
                head^.f2.final := false;
              end;
            xlts^.next := head;
            lir_3ba8.ltss := xlts;
            lir_3ba8.w56 := lir_3ba8.w56 + 1;
            xlts^.f2.num := lir_3ba8.w56 & 255;
            xlts^.refs := nil;
          end;
        end;
        if db_lts = nil then begin
          db_lts := utils_$find_exposed_lts(db_lr, bb);
          if (db_lts <> nil) and (db_lts <> db_lr^.ltss) then begin
            head := db_lr^.ltss;
            if head <> nil then
              if head^.bb = bb then begin
                head^.f2.first_in_bb := false;
                head^.f2.final := false;
              end;
            db_lts^.next := head;
            db_lr^.ltss := db_lts;
            db_lr^.w56 := db_lr^.w56 + 1;
            db_lts^.f2.num := db_lr^.w56 & 255;
            db_lts^.refs := nil;
          end;
        end;
        for j := 1 to instr^.h.nopnds do begin
          op := addr(instr^.opnds[j]);
          l := op^.lts;
          if (op^.h.kind = operand$inscrutable_memory)
             and (l^.lr = addr(lir_3ba8)) then begin
            if (opnd_bytes_ptr_t(op)^.rrp & 12) <> 0 then
              xlts := l
            else begin
              op^.lts := xlts;
              if xlast = nil then
                xlts^.refs := op
              else
                xlast^.link := op;
            end;
            xlast := op;
            op^.link := nil;
            xlts^.rrp := rrp$set_t(integer(xlts^.rrp) ! opnd_bytes_ptr_t(op)^.rrp);
          end;
          if (op^.h.kind = operand$ip_reg) and (op^.lts^.lr = db_lr) then begin
            if (opnd_bytes_ptr_t(op)^.rrp & 12) <> 0 then
              db_lts := l
            else begin
              op^.lts := db_lts;
              if db_last = nil then
                db_lts^.refs := op
              else
                db_last^.link := op;
            end;
            db_last := op;
            op^.link := nil;
            db_lts^.rrp := rrp$set_t(integer(db_lts^.rrp) ! opnd_bytes_ptr_t(op)^.rrp);
          end;
          if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
            lr := l^.lr;
            head := lr^.ltss;
            if l <> head then begin
              l^.next := head;
              lr^.ltss := l;
              lr^.w56 := lr^.w56 + 1;
              l^.f2.num := lr^.w56 & 255;
            end;
          end;
        end;
        { The stores after the instruction. }
        for j := 1 to instr^.h.nopnds do begin
          op := addr(instr^.opnds[j]);
          kind := op^.h.kind;
          if (opnd_bytes_ptr_t(op)^.rrp & 12) = 0 then
            next;
          if not (kind in [operand$ip_reg..operand$fp_reg_pair_physical]) then
            next;
          e1 := op^.lts;
          lr := e1^.lr;
          if not (rrp$store_through in lr^.rrp) then
            next;
          if lr = rtn^.ap_lr then
            next;
          if kind = operand$fp_reg_pair then
            if op^.h.fp_reg_odd_only then
              next;
          bv_$set(bb^.transparent, addr(lir_3ba8));
          if op^.h.kind = operand$fp_reg_pair then
            desc := spill_instr_forms.store_ptrs[0]
          else if op^.h.kind = operand$ip_reg then
            desc := spill_instr_forms.store_ptrs[4]
          else if rrp$fp_reg_even_only in e1^.rrp then
            desc := spill_instr_forms.store_ptrs[1]
          else if rrp$fp_reg_odd_only in e1^.rrp then
            desc := spill_instr_forms.store_ptrs[2]
          else
            desc := spill_instr_forms.store_ptrs[3];
          ni := lir_$get_new_instruction_no_exceptions(nil, desc^.opc,
                  16#2000, lr^.memory_home, 0);
          ni^.bb := bb;
          if op^.h.kind <> operand$fp_reg_pair then
            e2 := nil
          else
            e2 := utils_$find_mate_operand(op)^.lts;
          lir_utils_$flesh_out_new_load_or_store(addr(ni^.opnds[1]),
            addr(ni^.opnds[4]), addr(ni^.opnds[2]), addr(ni^.opnds[3]),
            lr^.memory_home, e1, e2, desc, ni, instr, db_lts, db_last,
            new_db_lts);
          ni^.opnds[1].link := op^.link;
          op^.link := addr(ni^.opnds[1]);
          if db_lts = ni^.opnds[1].lts then
            db_last := addr(ni^.opnds[1]);
          if e2 <> nil then begin
            def := e2^.refs;
            ni^.opnds[4].link := def^.link;
            def^.link := addr(ni^.opnds[4]);
          end;
          if xlts = nil then
            xlts := utils_$get_exposed_lts(addr(lir_3ba8), bb, created);
          xlts^.f2.first_in_bb := false;
          xlts^.f2.final := false;
          add_new_operand(ni, ni^.h.nopnds - 1, operand$inscrutable_memory,
                          16, xlts, xlast);
          if xlts <> lir_3ba8.ltss then begin
            xlts^.next := lir_3ba8.ltss;
            lir_3ba8.ltss := xlts;
            lir_3ba8.w56 := lir_3ba8.w56 + 1;
            xlts^.f2.num := lir_3ba8.w56 & 255;
          end;
          lir_utils_$add_lts_to_lr(0, addr(lir_3ba8), bb, xlts);
          xlts^.rrp := [];
          xlast := nil;
          add_new_operand(ni, ni^.h.nopnds, operand$inscrutable_memory, 8,
                          xlts, xlast);
          at := instr;
          while at^.h.grouped
                or (at^.h.atomic_update and (at^.next <> nil)
                    and at^.next^.h.atomic_update) do
            at := at^.next;
          if trace then
            vfmt_$write('   Inserting %ZA%.', instruction_mnemonic[ni^.opc], 12);
          ni^.next := at^.next;
          if ni^.next <> nil then
            ni^.next^.prev := ni;
          at^.next := ni;
          ni^.prev := at;
        end;
        { The stores done. }
      end;
      if prev = nil then
        bb^.first := instr
      else
        prev^.next := instr;
      instr^.prev := prev;
      prev := instr;
      count := count + 1;
      instr^.num := count;
      instr := instr^.next;
    end;
    if prev <> nil then
      prev^.next := nil;
    if db_lts <> nil then
      if bv_$test(bb^.live_out, db_lr) then begin
        db_lts^.f2.first_in_bb := true;
        db_lts^.f2.final := true;
      end;
    if xlts <> nil then
      if bv_$test(bb^.live_out, xlts^.lr) then begin
        xlts^.f2.first_in_bb := true;
        xlts^.f2.final := true;
      end;
    bb := bb^.next;
  end;

  if handlers then begin
    any := false;
    lr := rtn^.lrs;
    while lr <> nil do begin
      node := lr^.memory_home;
      if node <> nil then begin
        if node^.kind = 109 then begin
          vat := node^.xw[36];
          f := node^.xl[8];
        end
        else if node^.kind = 110 then begin
          vat := (ord(node^.xc[11]) & 16#F0) div 16;
          f := node^.xl[6];
        end
        else begin
          vat := 2;
          f := 0;
        end;
        if vat <> 2 then
          if (f & 16#10000000) <> 0 then
            any := true
          else
            lr^.memory_home := nil;
      end;
      lr := lr^.next;
    end;
    if not any then begin
      il_180^.xc[379] := chr(ord(il_180^.xc[379]) & 16#EF);
      lir_main_c8c := false;
    end;
  end;
end;

{ lir_utils_$find_mate_operand - utils_$find_mate_operand's.
  0x24E5F8, 0x26 bytes: op (8) in A2; A0 as utils' left it. }

function lir_utils_$find_mate_operand(
    op: opnd_ptr_t): opnd_ptr_t;
begin
  lir_utils_$find_mate_operand := utils_$find_mate_operand(op);
end;
