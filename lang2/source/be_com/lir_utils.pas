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
    --------  0x24C312  lir_utils_$trans_insert_move (TODO)
    --------  0x24CFC4  assign_spill_id (internal)
    --------  0x24D024  lir_utils_$get_new_memory_home
    --------  0x24D0F2  lir_utils_$add_memory_home
    --------  0x24D2C4  add_new_operand (internal)
    --------  0x24D34C  lir_utils_$flesh_out_new_load_or_store (TODO)
    --------  0x24D5DC  nolonger_exposed (internal)
    --------  0x24D65A  lir_utils_$get_next_async_exposed_lr
    --------  0x24D808  lir_utils_$fix_store_through_lrs (TODO)
    --------  0x24D7CC    new_db_lts (TODO; nested in it)
    --------  0x24E5F8  lir_utils_$find_mate_operand
    A5 0x48C164: move_opcode (+0, move_opcode.init), the squash
    suffixes ('.SN ', '.ST ', '.SF ', '.SA ' at +0x40) and the rest of
    the module's data, read by the routines not translated yet.

  The segments come from lir's fixed heap (lir.pvt.pas lir_3c00).
  lir_utils_$get_new_memory_home loads A5 and is global though only
  this unit calls it; assign_spill_id's message names RA_UTILS.

  Not known from the original: every local and parameter name. }

{ TODO(pascal) lir_utils.pas: not translated yet (translator PA3
  stopped here; the image's routines stay extern through
  backend.ins.pas): lir_utils_$trans_insert_move (0x24C312, 0x912
  bytes), lir_utils_$flesh_out_new_load_or_store (0x24D34C, 0x288: it
  fills lir_$build_operand's solution cells, post +0x6CC..+0x738,
  lir_main +0x250 .. +0x790, the section spill_instr_forms and
  isc_user_routines +0x330/+0x340, and sets at_backend_4fc's +226 bit
  1), lir_utils_$fix_store_through_lrs (0x24D808, 0xC8E) with its
  nested new_db_lts (0x24D7CC, 0x3C). }
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
  (docs/questions.md 250).  The messages' arguments: the line, LTS
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

{ lir_utils_$find_mate_operand - utils_$find_mate_operand's.
  0x24E5F8, 0x26 bytes: op (8) in A2; A0 as utils' left it. }

function lir_utils_$find_mate_operand(
    op: opnd_ptr_t): opnd_ptr_t;
begin
  lir_utils_$find_mate_operand := utils_$find_mate_operand(op);
end;
