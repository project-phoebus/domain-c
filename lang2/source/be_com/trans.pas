{ trans - the PRISM back end's transformations phase (TRANS): branches
  on a compare with 1 or -1 turned into branches on a test, compares
  made tests, instructions moved into the blocks they reach (the alpha
  and omega motions), silly extracts and XORs removed, copies
  eliminated (tr_utils).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x281908  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x28192A  split_lts_for_merge (internal)
    --------  0x2819C2  reattach_split_lts (internal)
    --------  0x2819D6  drop_operand_from_lts (internal)
    --------  0x281A4E  copy_operand (internal)
    --------  0x281B2A  make_immediate_operand (internal)
    --------  0x281B82  immedify (internal)
    --------  0x281CE6  convert_compare_to_test (internal)
    --------  0x281D38  trans_branches (internal)
    --------  0x281FF6  oprs_high_bits_known (internal)
    --------  0x2821FC  n_zero_high_bits
    --------  0x282252  update_attributes (in make_lr_complex)
    --------  0x2822A0  make_lr_complex (internal)
    --------  0x2822DA  validate_instr (internal)
    --------  0x2824F6  other_consumers_same_lr (internal)
    --------  0x282562  instrs_ok_for_motion (internal)
    --------  0x282AB6  merge_mate_lr (internal)
    --------  0x282B8C  move_base_instr_to_head_of_new_bb (internal)
    --------  0x283048  combine_instr_with_omega_base (internal)
    --------  0x283294  add_successors_to_work_list (internal)
    --------  0x2832DC  add_predecessors_to_work_list (internal)
    --------  0x28332A  get_omega_candidate (internal)
    --------  0x2833AE  trans_$omega_motions
    --------  0x283526  move_base_instr_to_tail_of_new_bb (internal)
    --------  0x283964  combine_instr_with_alpha_base (internal)
    --------  0x283C12  collect_unprecedented_instrs (internal)
    --------  0x283CA6  drop_unprecedented_instr (internal)
    --------  0x283CE0  get_alpha_candidate (internal)
    --------  0x283D6C  trans_$alpha_motions
    --------  0x284148  attempt_special_zero_branches (internal)
    --------  0x2843AE  massage_xor_to_tst (internal)
    --------  0x28446C  trans_$kill_silly_extract
    --------  0x284560  trans_$copy_elimination
    --------  0x2845D0  trans_$begin_compilation
    --------  0x2845D2  trans_$end_compilation
    --------  0x2845D4  trans_$end_routine
    --------  0x2845D6  trans_$process_routine
    A5 0x492FA4: the module's data: +0 the routine (trans_0).

  Not known from the original: every local and parameter name, the
  module cell's name. }

module trans;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

type
  opnd_ptr_ptr_t = ^opnd_ptr_t;

  { The motions' view of a block (fields batch A has not named;
    backend.ins.pas bb_t): l42 (+42) a longword get_omega_candidate and
    get_alpha_candidate require equal in the block an instruction moves
    from and the one it moves to; unprec (+122, batch A's avail_in) the
    alpha motion's list of the block's unprecedented instructions
    (chained through their +24); work (+150) the motions' work list
    link (nil off the list, -1 the end of the list). }
  trans_bb_v_ptr_t = ^trans_bb_v_t;
  trans_bb_v_t = record
    space0: array [0..41] of char;
    l42: integer32;                     { +42 }
    space46: array [46..121] of char;
    unprec: instr_ptr_t;                { +122 }
    space126: array [126..149] of char;
    work: bb_ptr_t;                     { +150 }
  end;

var
  trans_0: rtn_ptr_t;                   { +0: the routine (set by
                                          copy_elimination and
                                          process_routine; the internal
                                          routines that call
                                          tr_utils_$attempt_test_
                                          elimination read it through
                                          their caller's A5) }

{ split_lts_for_merge - l's live range's list cut so that it holds only
  the run of segments around l (from the write l's intend-to-modify
  reads go back to, through the modifies after it); rest the segments
  that followed (or, when the run did not start the list, the list's
  old head, the run taken out of it).  0x28192A, 0x98 bytes, no A5. }

procedure split_lts_for_merge(
    l: lts_ptr_t;
    out rest: lts_ptr_t); options(val_param); internal;
var
  a, p, first: lts_ptr_t;
begin
  a := l;
  while rrp$intend_to_modify in a^.rrp do begin
    p := a^.lr^.ltss;
    while p^.next <> a do
      p := p^.next;
    a := p;
  end;
  if a^.lr^.ltss = a then
    p := nil
  else begin
    p := a^.lr^.ltss;
    while p^.next <> a do
      p := p^.next;
  end;
  first := a;
  while rrp$modify in a^.rrp do
    a := a^.next;
  if p = nil then
    rest := a^.next
  else begin
    rest := a^.lr^.ltss;
    p^.next := a^.next;
  end;
  a^.lr^.ltss := first;
  a^.next := nil;
end;

{ reattach_split_lts - the list split_lts_for_merge cut off made its
  live range's again.  0x2819C2, 0x14 bytes, no frame. }

procedure reattach_split_lts(
    l: lts_ptr_t); options(val_param); internal;
begin
  if l <> nil then
    l^.lr^.ltss := l;
end;

{ drop_operand_from_lts - o taken off l's operands (+4, chained through
  their links) and l's rrp made again from the others' rrp bytes and
  the register kind (16#8000 an integer register, 16#4000 a floating
  one).  0x2819D6, 0x78 bytes, no A5: the link's address carried in A1
  (the segment's +4 and an operand's +4 alike). }

procedure drop_operand_from_lts(
    o: opnd_ptr_t;
    l: lts_ptr_t); options(val_param); internal;
var
  r: integer;
  p: opnd_ptr_ptr_t;
  q: opnd_ptr_t;
begin
  if o^.h.kind = operand$ip_reg then
    r := -32768                         { 16#8000 }
  else if o^.h.kind in [operand$fp_reg, operand$fp_reg_pair] then
    r := 16#4000
  else
    r := 0;
  p := addr(l^.refs);
  q := l^.refs;
  while q <> nil do
    if q = o then begin
      q := q^.link;
      p^ := q;
    end
    else begin
      r := r ! opnd_bytes_ptr_t(q)^.rrp;
      p := addr(q^.link);
      q := q^.link;
    end;
  l^.rrp := rrp$set_t(r);
end;

{ copy_operand - dst (a register or memory operand dropped from its
  segment first) made a copy of src but for its number (0:
  bug_check); unless src is an immediate, dst put in src's place among
  its segment's operands, or (link) made src's link.  0x281A4E, 0xB2
  bytes, no A5. }

procedure copy_operand(
    dst: opnd_ptr_t;
    src: opnd_ptr_t;
    link: boolean); options(val_param); internal;
var
  n: integer;
  p: opnd_ptr_ptr_t;
  q: opnd_ptr_t;
begin
  if dst^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
    drop_operand_from_lts(dst, dst^.lts);
  n := dst^.h.num;
  if n = 0 then
    bug_check('TRANS_$ copy_operand: bad operand number%.');
  dst^ := src^;
  dst^.h.num := n;
  if src^.h.kind <> operand$immediate then
    if link then
      src^.link := dst
    else begin
      q := src^.lts^.refs;
      p := addr(src^.lts^.refs);
      while q <> nil do
        if q = src then begin
          p^ := dst;
          q := nil;
        end
        else begin
          p := addr(q^.link);
          q := q^.link;
        end;
    end;
end;

{ make_immediate_operand - o made the immediate v (its reader taken off
  its segment first), unlinked, its count cleared.  0x281B2A, 0x58
  bytes, no A5: utils_$remove_reader_from_lts's arguments left on the
  stack (the `unlk' pops them). }

procedure make_immediate_operand(
    o: opnd_ptr_t;
    v: integer32); options(val_param); internal;
begin
  if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
    utils_$remove_reader_from_lts(o, true);
  o^.h.kind := operand$immediate;
  o^.value := v;
  o^.link := nil;
  o^.h.count := 0;
end;

{ immedify - whether operand o is (or can be made) an immediate: an
  integer register whose canonical birthpoint (following 3) is a known
  value, or is an EXTEND0/7/15 of a known value that a MOVE can load
  (the extend made a MOVE); the value must be encodable in o's
  instruction, or in an ADD for a SUB of the negated value (the
  instruction made an ADD).

  0x281B82, 0x164 bytes, no A5: lir_$can_encode_as_immediate_operand's
  third argument the constant 1 (`pea 0x1'). }

function immedify(
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  r, ok: boolean;
  i, d: instr_ptr_t;
  bp: utils_$birthpoint_t;
  v: integer32;
begin
  r := false;
  if o^.h.kind = operand$immediate then
    r := true
  else if o^.h.kind = operand$ip_reg then begin
    i := utils_ins_$operands_instruction(o);
    utils_$get_canonical_birthpoint(o^.lts, 3, bp);
    if bp.has_base then begin
      ok := true;
      v := bp.base;
    end
    else if (bp.lts = nil) or (bp.lts^.refs = nil) then
      ok := r
    else begin
      d := utils_ins_$operands_instruction(bp.lts^.refs);
      ok := r;
      if (d^.opc = ord(opc$extend0)) or (d^.opc = ord(opc$extend15))
          or (d^.opc = ord(opc$extend7)) then begin
        utils_$get_canonical_birthpoint(d^.opnds[1].lts, 1, bp);
        if bp.has_base and (d^.opnds[2].h.count = 0) then
          if lir_$can_encode_as_immediate_operand(bp.base, ord(opc$move),
                                                  univ_ptr(1)) then begin
            ok := true;
            utils_$set_instruction_opcode(d, ord(opc$move));
            v := bp.base;
          end;
      end;
    end;
    if ok then
      if lir_$can_encode_as_immediate_operand(v, i^.opc, univ_ptr(1)) then begin
        make_immediate_operand(o, v);
        r := true;
      end
      else if i^.opc = ord(opc$sub) then
        if lir_$can_encode_as_immediate_operand(-v, ord(opc$add),
                                                univ_ptr(1)) then begin
          utils_$set_instruction_opcode(i, ord(opc$add));
          make_immediate_operand(o, -v);
          r := true;
        end;
  end;
  immedify := r;
end;

{ convert_compare_to_test - a CMP made a TST of its first operand's
  value: two operands, operand 1 a copy of operand 2, operand 2 of o
  (the condition codes).  0x281CE6, 0x52 bytes, no A5: the first
  copy_operand's pop leaves 2 bytes for the second (pattern 51). }

procedure convert_compare_to_test(
    i: instr_ptr_t;
    o: opnd_ptr_t); options(val_param); internal;
begin
  utils_$set_instruction_opcode(i, ord(opc$tst));
  i^.h.nopnds := 2;
  copy_operand(addr(i^.opnds[1]), addr(i^.opnds[2]), false);
  copy_operand(addr(i^.opnds[2]), o, false);
end;

{ trans_branches - bb's branch (the first instruction of the branch
  class; none past another control transfer or, for one marked +3 bit
  3, a call, trap or immediate-class instruction) on condition codes set
  by a CMP, an XOR (for BNE and BEQ) or an ADD or SUB whose result is an
  integer register used only there: with the compared value (made)
  immediate, BGT/BLE -1 become BGE/BLT, BGE/BLT 1 become BGT/BLE, BHS 1
  becomes BNE, and the CMP a TST; BNE/BEQ -1 of a value decremented
  just before (SUB 1 or ADD -1 that does not set the codes) let the
  decrement set the codes (BHS/BLO) and the CMP go.

  0x281D38, 0x2BE bytes, no A5: the branch opcodes less 8 by a 12-entry
  jump table; the classes `btst' in 16#1000062 and 16#1104166, the
  register kinds in 16#21012. }

procedure trans_branches(
    bb: bb_ptr_t); options(val_param); internal;
var
  i, d, e: instr_ptr_t;
  cls: integer;
  cc, ccop: opnd_ptr_t;
  l, l3, l1: lts_ptr_t;
  k: operand$t;
  lr3: lr_ptr_t;
  v: integer32;
  found: boolean;
begin
  i := bb^.first;
  found := false;
  while not found do begin
    if i = nil then
      return;
    cls := instruction_attributes[i^.opc].class;
    if cls = class$branch then
      found := true
    else begin
      if cls in [class$branch, class$fp_branch, class$jump, class$return] then
        return;
      if (i^.h.width & 8) <> 0 then
        if cls in [1, 2, 5, 6, 8, 14, 20, 24] then
          return;
      i := i^.next;
    end;
  end;
  cc := addr(i^.opnds[i^.h.nopnds]);
  if cc^.h.kind <> operand$ip_condition_codes then
    return;
  l := cc^.lts;
  if l^.f2.exposed then
    return;
  d := utils_ins_$operands_instruction(l^.refs);
  if d^.opc <> ord(opc$cmp) then begin
    if d^.opc = ord(opc$xor) then begin
      if (i^.opc <> ord(opc$bne)) and (i^.opc <> ord(opc$beq)) then
        return;
    end
    else if (d^.opc <> ord(opc$sub)) and (d^.opc <> ord(opc$add)) then
      return;
    k := d^.opnds[3].h.kind;
    if not (k in [operand$ip_reg, operand$ip_reg_physical,
                  operand$ip_reg_like, operand$case_jump_base]) then
      return;
    l3 := d^.opnds[3].lts;
    lr3 := l3^.lr;
    if not ((k = operand$ip_reg_like) and (lr3^.f2.b2 = 31)) then begin
      if rrp$read in l3^.rrp then
        return;
      if l3^.next <> nil then
        return;
      if k <> operand$ip_reg then
        return;
      if lr3^.ltss <> l3 then
        return;
    end;
  end;
  if not immedify(addr(d^.opnds[1])) then
    return;
  v := d^.opnds[1].value;
  if d^.opc = ord(opc$add) then
    v := -v;
  ccop := addr(d^.opnds[d^.h.nopnds]);
  case i^.opc of
    8: begin                            { bgt }
      if v <> -1 then
        return;
      utils_$set_instruction_opcode(i, ord(opc$bge));
    end;
    9: begin                            { ble }
      if v <> -1 then
        return;
      utils_$set_instruction_opcode(i, ord(opc$blt));
    end;
    10: begin                           { bge }
      if v <> 1 then
        return;
      utils_$set_instruction_opcode(i, ord(opc$bgt));
    end;
    11: begin                           { blt }
      if v <> 1 then
        return;
      utils_$set_instruction_opcode(i, ord(opc$ble));
    end;
    15: begin                           { bhs }
      if v <> 1 then
        return;
      utils_$set_instruction_opcode(i, ord(opc$bne));
    end;
    18, 19: begin                       { bne, beq }
      if v <> -1 then
        return;
      l1 := d^.opnds[2].lts;
      if l1^.f2.exposed then
        return;
      e := utils_ins_$operands_instruction(l1^.refs);
      if e^.opnds[1].h.kind <> operand$immediate then
        return;
      if e^.h.sets_cc then
        return;
      if not (((e^.opc = ord(opc$sub)) and (e^.opnds[1].value = 1))
              or ((e^.opc = ord(opc$add)) and (e^.opnds[1].value = -1))) then
        return;
      e^.h.sets_cc := true;
      e^.h.nopnds := 4;
      e^.opnds[4].h.num := 4;
      copy_operand(addr(e^.opnds[4]), ccop, false);
      utils_$excise_instruction_cleanly(d, true);
      if i^.opc = ord(opc$bne) then
        utils_$set_instruction_opcode(i, ord(opc$bhs))
      else
        utils_$set_instruction_opcode(i, ord(opc$blo));
      return;
    end;
    otherwise
      return;
  end;
  convert_compare_to_test(d, ccop);
end;

{ oprs_high_bits_known - how many of operand o's high bits are known,
  bits their values: an immediate's 32; a register's by its canonical
  birthpoint's definition: LOADBU 24 and LOADWU 16 zeros, a MOVE's
  source's, an OR's (the ones of either operand beyond the shorter
  known run), an XOR's (the shorter run), an AND's (the zeros of either
  beyond it), an EXTRACTU's 32 less its width; else 0.

  0x281FF6, 0x206 bytes, no A5: recursive; the runs walked with a mask
  shifted right (`lsr.l #1') counted by `dbf'. }

function oprs_high_bits_known(
    o: opnd_ptr_t;
    out bits: integer32): integer32; options(val_param); internal;
var
  bp: utils_$birthpoint_t;
  d: instr_ptr_t;
  n1, n2, lo, hi: integer32;
  b1, b2, hb, mask: integer32;
begin
  if o^.h.kind = operand$immediate then begin
    bits := o^.value;
    oprs_high_bits_known := 32;
    return;
  end;
  if not (o^.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then begin
    oprs_high_bits_known := 0;
    return;
  end;
  utils_$get_canonical_birthpoint(o^.lts, 0, bp);
  if bp.lts = nil then begin
    oprs_high_bits_known := 0;
    return;
  end;
  d := utils_ins_$operands_instruction(bp.lts^.refs);
  if d^.opc = ord(opc$loadbu) then begin
    bits := 0;
    oprs_high_bits_known := 24;
  end
  else if d^.opc = ord(opc$loadwu) then begin
    bits := 0;
    oprs_high_bits_known := 16;
  end
  else if d^.opc = ord(opc$move) then
    oprs_high_bits_known := oprs_high_bits_known(addr(d^.opnds[1]), bits)
  else if d^.opc = ord(opc$or) then begin
    n1 := oprs_high_bits_known(addr(d^.opnds[1]), b1);
    n2 := oprs_high_bits_known(addr(d^.opnds[2]), b2);
    bits := b1 ! b2;
    lo := n1;
    if lo > n2 then
      lo := n2;
    hi := n1;
    hb := b1;
    if n2 > n1 then begin
      hi := n2;
      hb := b2;
    end;
    mask := lshft(1, 31 - lo);
    while (lo < hi) and ((mask & hb) <> 0) do begin
      bits := bits ! mask;
      lo := lo + 1;
      mask := rshft(mask, 1);
    end;
    oprs_high_bits_known := lo;
  end
  else if d^.opc = ord(opc$xor) then begin
    n1 := oprs_high_bits_known(addr(d^.opnds[1]), b1);
    n2 := oprs_high_bits_known(addr(d^.opnds[2]), b2);
    if n2 > n1 then
      n2 := n1;
    bits := xor(b1, b2);
    oprs_high_bits_known := n2;
  end
  else if d^.opc = ord(opc$and) then begin
    n1 := oprs_high_bits_known(addr(d^.opnds[1]), b1);
    n2 := oprs_high_bits_known(addr(d^.opnds[2]), b2);
    bits := b1 & b2;
    lo := n1;
    if lo > n2 then
      lo := n2;
    hi := n1;
    hb := b1;
    if n2 > n1 then begin
      hi := n2;
      hb := b2;
    end;
    mask := lshft(1, 31 - lo);
    while (lo < hi) and ((mask & hb) = 0) do begin
      bits := bits & ~mask;
      lo := lo + 1;
      mask := rshft(mask, 1);
    end;
    oprs_high_bits_known := lo;
  end
  else if d^.opc = ord(opc$extractu) then begin
    bits := 0;
    oprs_high_bits_known := 32 - d^.h.width;
  end
  else
    oprs_high_bits_known := 0;
end;

{ n_zero_high_bits - how many of o's high bits are known to be zero.
  0x2821FC, 0x56 bytes (loads A5: global, though no other unit calls
  it). }

function n_zero_high_bits(
    o: opnd_ptr_t): integer32; options(val_param);
var
  n, k, bits, mask: integer32;
begin
  n := oprs_high_bits_known(o, bits);
  mask := lshft(1, 31);
  for k := 0 to n - 1 do begin
    if (bits & mask) <> 0 then begin
      n := k;
      exit;
    end;
    mask := rshft(mask, 1);
  end;
  n_zero_high_bits := n;
end;

{ make_lr_complex - lr given a complex id (bv_$make_live_range_complex)
  and its attributes updated, and its mate's.  0x2822A0, 0x3A bytes, no
  A5. }

procedure make_lr_complex(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t); options(val_param); internal;

  { update_attributes - each segment of lr that writes kills lr in its
    block (transparent); the first segment of each block marked.
    0x282252, 0x4E bytes. }

  procedure update_attributes(
      lr: lr_ptr_t); options(val_param);
  var
    l: lts_ptr_t;
    b, prev: bb_ptr_t;
  begin
    prev := nil;
    l := lr^.ltss;
    while l <> nil do begin
      b := l^.bb;
      if (integer(l^.rrp) & 12) <> 0 then
        bv_$set(b^.transparent, lr);
      if b <> prev then
        l^.f2.first_in_bb := true;
      prev := b;
      l := l^.next;
    end;
  end;

begin
  bv_$make_live_range_complex(rtn, lr);
  update_attributes(lr);
  if lr^.mate <> nil then
    update_attributes(lr^.mate);
end;

{ validate_instr - instr, when its operands allow it to be moved (into
  the block to_bb of the edge from from_bb with motion 0, or out of it with
  motion 1); else nil.  Every operand must be of a kind the motions
  know; a register or memory operand: with motion 0 one followed in its
  block by another segment must modify it, an intend-to-modify must be
  its segment's first reader, a read must be of a complex live range
  and exposed, a write of a complex live range (or modifying) must not
  be live out of to; with motion 1 a complex live range must be the
  first of its block or written by a later operand, a simple one's
  segment must be in another block than the one before, a write must
  be the segment's only reader-free operand, complex, and not live into
  from's other successors.  A paired live range's write must be of a
  pair kind.

  0x2822DA, 0x21C bytes, no A5: the kinds `btst' in 16#FC7E8F, 16#FFE
  and 16#4048. }

function validate_instr(
    from_bb: bb_ptr_t;
    to_bb: bb_ptr_t;
    instr: instr_ptr_t;
    motion: integer): instr_ptr_t; options(val_param); internal;
var
  j, m: integer32;
  o, q: opnd_ptr_t;
  k: operand$t;
  l: lts_ptr_t;
  lr: lr_ptr_t;
  pb: bb_ptr_t;
  e: fg_edge_ptr_t;
  found: boolean;
begin
  validate_instr := nil;
  for j := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[j]);
    k := o^.h.kind;
    if not (k in [operand$none..operand$fp_reg_pair,
                  operand$ip_condition_codes,
                  operand$argument_block_memory..operand$fp_reg_pair_like,
                  operand$displacement_routine..operand$immediate]) then
      return;
    if k in [operand$ip_reg..operand$well_behaved_memory] then begin
      l := o^.lts;
      lr := l^.lr;
      if motion = 0 then begin
        if l^.next <> nil then
          if l^.bb = l^.next^.bb then
            if not o^.h.modify then
              return;
        if o^.h.intend_to_modify then
          if o <> l^.refs then
            return;
      end
      else if lr^.id <> 0 then begin
        if not l^.f2.first_in_bb then begin
          found := false;
          for m := j + 1 to instr^.h.nopnds do begin
            q := addr(instr^.opnds[m]);
            if q^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
              if (opnd_bytes_ptr_t(q)^.rrp & 12) <> 0 then
                if q^.lts^.lr = lr then begin
                  found := true;
                  exit;
                end;
          end;
          if not found then
            return;
        end;
      end
      else begin
        pb := nil;
        l := lr^.ltss;
        while l <> o^.lts do begin
          pb := l^.bb;
          l := l^.next;
        end;
        if o^.lts^.bb = pb then
          return;
      end;
      if o^.h.read then
        if motion = 0 then begin
          if lr^.id = 0 then
            return;
          if not o^.lts^.f2.exposed then
            return;
        end;
      if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        if lr^.mate <> nil then
          if not (k in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                        operand$fp_reg_pair_like]) then
            return;
        if motion = 0 then begin
          if lr^.id <> 0 then
            if not o^.h.modify then
              if bv_$test(to_bb^.live_out, lr) then
                return;
        end
        else begin
          if o^.link <> nil then
            return;
          if lr^.id = 0 then
            return;
          e := from_bb^.succs;
          while e <> nil do begin
            if e^.target <> to_bb then
              if bv_$test(e^.target^.live_in, o^.lts^.lr) then
                return;
            e := e^.next_succ;
          end;
        end;
      end;
    end;
  end;
  validate_instr := instr;
end;

{ other_consumers_same_lr - whether every operand from o on (through the
  links) that is in i1 has, at the same number in i2, an operand of the
  same kind whose segment is of lr.  0x2824F6, 0x6C bytes, no A5. }

function other_consumers_same_lr(
    i1: instr_ptr_t;
    i2: instr_ptr_t;
    lr: lr_ptr_t;
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  p, q: opnd_ptr_t;
  pi: instr_ptr_t;
begin
  p := o;
  while p <> nil do begin
    pi := utils_ins_$operands_instruction(p);
    if pi = i1 then begin
      q := addr(i2^.opnds[p^.h.num]);
      if (q^.h.kind <> p^.h.kind) or (q^.lts^.lr <> lr) then begin
        other_consumers_same_lr := false;
        return;
      end;
    end;
    p := p^.link;
  end;
  other_consumers_same_lr := true;
end;

{ instrs_ok_for_motion - whether i1 (not a branch or jump) and i2 do the
  same thing, so that one may stand for both when an instruction is
  moved into (motion 0) or out of (motion 1) the block bb: the same
  width, operands and opcode; operand by operand the same rrp byte,
  kind and count; registers, condition codes and memory of live ranges
  with the same complex id and pairing, a different live range only
  when it has no segment in i2's block and the other readers agree
  (other_consumers_same_lr); a physical register's live range (+3 bit
  7, not unique_value) taken out of a call's registers, and (with the
  phase's switch 10) not live across the move; the like kinds the same
  segment; displacements and immediates the same link and value; a
  memory reference's alias descriptors (24 bytes before the
  instruction, +2 bit 7) identical; and for a call, none of the
  registers it uses (three masks after its operands: integer
  registers, floating registers 0..31 and 32..63, whose live ranges
  are lir's tables at +0x4090 and +0x3F90) live across the move.

  0x282562, 0x520 bytes, no A5: the kinds by a 24-entry jump table; the
  classes `btst' in 98, 16#100004 and 16#9F1CE94; the three masks by a
  `case' of 1..3 as a compare chain; the integer registers' table
  0x48B210 and the floating registers' 0x48B110 loaded as immediates;
  the two bv_$tests of each `or' both made (pattern 29). }

function instrs_ok_for_motion(
    i1: instr_ptr_t;
    i2: instr_ptr_t;
    bb: bb_ptr_t;
    motion: integer): boolean; options(val_param); internal;
type
  { The registers a call uses: three masks after its operands (at
    +44 + 12 nopnds). }
  call_regs_ptr_t = ^call_regs_t;
  call_regs_t = record
    fp_hi: bv_word_t;                   { +0: floating registers 32..63 }
    fp_lo: bv_word_t;                   { +4: floating registers 0..31 }
    ip: bv_word_t;                      { +8: integer registers }
  end;
  { lir's tables of the physical registers' live ranges. }
  reg_lrs_ptr_t = ^reg_lrs_t;
  reg_lrs_t = array [0..63] of lr_ptr_t;
  { An operand's +3 as a literal pool displacement's: bits 7..5 compared
    as one field. }
  opnd_v_ptr_t = ^opnd_v_t;
  opnd_v_t = packed record
    num: 0..255;                        { +0 }
    rrp: 0..255;                        { +1 }
    b2: 0..255;                         { +2 }
    b3_hi: 0..7;                        { +3 .7..5 }
    kind: 0..31;                        { .4..0 }
  end;
  univ_ptr_ptr_t = ^univ_ptr;
var
  mask: bv_word_t;
  prev: lts_ptr_t;
  lr: lr_ptr_t;
  regs: reg_lrs_ptr_t;
  fp_lo, fp_hi, ip: bv_word_t;
  base: integer;
  is_call: boolean;
  o1, o2: opnd_ptr_t;
  lr1, lr2: lr_ptr_t;
  cr: call_regs_ptr_t;
  j, k: integer32;
  r: integer;
begin
  instrs_ok_for_motion := false;
  if ord(i1^.class) in [class$branch, class$fp_branch, class$jump] then
    return;
  if i1^.h.width <> i2^.h.width then
    return;
  if i1^.h.nopnds <> i2^.h.nopnds then
    return;
  if i1^.opc <> i2^.opc then
    return;
  if instruction_attributes[i2^.opc].class in [class$call, class$svc] then begin
    is_call := true;
    cr := call_regs_ptr_t(addr(i2^.opnds[i2^.h.nopnds + 1]));
    ip := cr^.ip;
    fp_hi := cr^.fp_hi;
    fp_lo := cr^.fp_lo;
  end
  else
    is_call := false;
  for j := 1 to i1^.h.nopnds do begin
    o1 := addr(i1^.opnds[j]);
    o2 := addr(i2^.opnds[j]);
    if opnd_bytes_ptr_t(o1)^.rrp <> opnd_bytes_ptr_t(o2)^.rrp then
      return;
    if o1^.h.kind <> o2^.h.kind then
      return;
    if o1^.h.count <> o2^.h.count then
      return;
    case o1^.h.kind of
      operand$none:
        ;
      operand$ip_reg_like, operand$fp_reg_like, operand$fp_reg_pair_like:
        if o1^.lts <> o2^.lts then
          return;
      operand$ip_reg, operand$fp_reg, operand$fp_reg_pair,
      operand$ip_condition_codes, operand$fp_condition_codes,
      operand$inscrutable_memory, operand$well_behaved_memory: begin
        lr2 := o2^.lts^.lr;
        lr1 := o1^.lts^.lr;
        if lr1^.id <> lr2^.id then
          return;
        if (lr2^.mate = nil) <> (lr1^.mate = nil) then
          return;
        if lr1 <> lr2 then begin
          if utils_$find_last_lts_in_bb(lr1, i2^.bb, prev) <> nil then
            return;
          if o2^.link <> nil then
            if not other_consumers_same_lr(i2, i1, lr1, o2^.link) then
              return;
          if o1^.link <> nil then
            if not other_consumers_same_lr(i1, i2, lr2, o1^.link) then
              return;
        end;
        if lr2^.f2.b3_7 then
          if not (rrp$unique_value in lr2^.rrp) then begin
            if o1^.h.kind in [operand$fp_reg, operand$fp_reg_pair] then begin
              if lr2^.f2.b2 > 31 then
                fp_hi := fp_hi - [lr2^.f2.b2 + 31]
              else
                fp_lo := fp_lo - [lr2^.f2.b2];
            end
            else
              ip := ip - [lr2^.f2.b2];
            if not at_backend_switches.sw10 then
              return;
            if lr2^.id = 0 then
              return;
            if motion = 0 then begin
              if o2^.h.write then
                if bv_$test(i2^.bb^.live_in, lr2)
                    or bv_$test(bb^.live_out, lr2) then
                  return;
            end
            else if (opnd_bytes_ptr_t(o2)^.rrp & 16#30) = 16#10 then
              if bv_$test(i2^.bb^.live_out, lr2)
                  or bv_$test(bb^.live_in, lr2) then
                return;
          end;
      end;
      operand$displacement_routine, operand$displacement_arg_block,
      operand$displacement_stack_frame, operand$displacement_XSB_base,
      operand$immediate: begin
        if o1^.link <> o2^.link then
          return;
        if o1^.value <> o2^.value then
          return;
      end;
      operand$displacement_literal_pool: begin
        if o1^.value <> o2^.value then
          return;
        if opnd_v_ptr_t(o1)^.b3_hi <> opnd_v_ptr_t(o2)^.b3_hi then
          return;
        if univ_ptr_ptr_t(o1^.link)^ <> univ_ptr_ptr_t(o2^.link)^ then
          return;
      end;
      otherwise
        bug_check('TRANS_$instrs_ok_for_motion:  illegal operand kind%$');
    end;
  end;
  if instruction_attributes[i2^.opc].class
      in [class$call, class$entry, class$enable, class$seq, class$synch,
          class$limit, class$trap, class$load_pair, class$load, class$svc,
          class$store, class$mfpr, class$mtpr, class$return,
          class$trap_cond] then begin
    if i1^.h.b2_7 <> i2^.h.b2_7 then
      return;
    if i1^.h.b2_7 then
      if not alias_$descriptors_are_identical(
          alias_$desc_ptr_t(integer32(i1) - 24)^,
          alias_$desc_ptr_t(integer32(i2) - 24)^) then
        return;
  end;
  if is_call then
    for k := 1 to 3 do begin
      case k of
        1: begin
          mask := ip;
          regs := addr(lir_4090);
          base := 0;
        end;
        2: begin
          mask := fp_lo;
          regs := addr(lir_3f90);
          base := 0;
        end;
        3: begin
          mask := fp_hi;
          regs := addr(lir_3f90);
          base := 32;
        end;
      end;
      for r := 0 to 31 do
        if r in mask then begin
          lr := regs^[r + base];
          if motion = 0 then begin
            if bv_$test(i2^.bb^.live_in, lr)
                or bv_$test(bb^.live_out, lr) then
              return;
          end
          else if bv_$test(i2^.bb^.live_out, lr)
              or bv_$test(bb^.live_in, lr) then
            return;
        end;
    end;
  instrs_ok_for_motion := true;
end;

{ merge_mate_lr - for the first operand of l of a register pair kind,
  its mate's live range (cut down to the mate's run of segments while
  merging) merged into lr (tr_utils_$merge_lrs: no block, no mates, the
  bits set); lr killed in l's block when the mate writes.  0x282AB6,
  0xAE bytes, no A5. }

procedure merge_mate_lr(
    l: lts_ptr_t;
    lr: lr_ptr_t); options(val_param); internal;
var
  o, m: opnd_ptr_t;
  rest: lts_ptr_t;
begin
  o := l^.refs;
  while o <> nil do begin
    if o^.h.kind in [operand$fp_reg_pair, operand$fp_reg_pair_physical,
                     operand$fp_reg_pair_like] then begin
      m := lir_utils_$find_mate_operand(o);
      if m = nil then
        bug_check('TRANS_$merge_mate_lr: can''t find mate%$');
      split_lts_for_merge(m^.lts, rest);
      tr_utils_$merge_lrs(lr, m^.lts^.lr, nil, false, true);
      reattach_split_lts(rest);
      if (opnd_bytes_ptr_t(m)^.rrp & 12) <> 0 then
        bv_$set(l^.bb^.transparent, lr);
      return;
    end;
    o := o^.link;
  end;
end;

{ move_base_instr_to_head_of_new_bb - instr taken out of its block and
  put at the head of new_bb (after its labels and join birthpoints),
  its register and memory operands moved with it, last to first: a
  reader taken off its segment's readers and given new_bb's exposed
  segment of its live range (made complex first when simple; the
  segment in the old block made final, its live range live out of
  it; a new exposed segment chained to the final segment that reaches
  it and made final when the live range is live out of new_bb; an
  existing one's join birthpoint's operand 2 segment taken instead),
  the live range live into new_bb and read there unless the segment
  writes; a writer's segment excised from the old block (its live range
  killed and not live out there) and new_bb's exposed segment (or the
  segment of its join birthpoint, the join excised) made the write's,
  or a new first segment, the live range killed in new_bb and not live
  into it.

  0x282B8C, 0x3F2 bytes, no A5: the operands walked down by 12 from
  the last; the kinds `btst' in 4094; the empty walk of the live
  range's exposed list at the end kept. }

procedure move_base_instr_to_head_of_new_bb(
    rtn: rtn_ptr_t;
    instr: instr_ptr_t;
    new_bb: bb_ptr_t); options(val_param); internal;
var
  old_bb: bb_ptr_t;
  i, jb: instr_ptr_t;
  j: integer32;
  o, p: opnd_ptr_t;
  l, f, x: lts_ptr_t;
  lr: lr_ptr_t;
  created: boolean;
begin
  old_bb := instr^.bb;
  if instr^.prev = nil then
    old_bb^.first := instr^.next
  else
    instr^.prev^.next := instr^.next;
  if instr^.next = nil then
    old_bb^.last := instr^.prev
  else
    instr^.next^.prev := instr^.prev;
  i := new_bb^.first;
  while (i^.opc = ord(opc$join_bp)) or (i^.opc = ord(opc$label)) do
    i := i^.next;
  instr^.bb := new_bb;
  if i^.prev = nil then begin
    new_bb^.first := instr;
    instr^.prev := nil;
  end
  else begin
    i^.prev^.next := instr;
    instr^.prev := i^.prev;
  end;
  instr^.next := i;
  i^.prev := instr;
  for j := instr^.h.nopnds downto 1 do begin
    o := addr(instr^.opnds[j]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      l := o^.lts;
      lr := l^.lr;
      if o^.h.read then begin
        if l^.refs = o then
          l^.refs := o^.link
        else begin
          p := l^.refs;
          while p^.link <> o do
            p := p^.link;
          p^.link := o^.link;
        end;
        if lr^.id = 0 then begin
          make_lr_complex(rtn, lr);
          f := o^.lts;
        end
        else begin
          if not o^.lts^.f2.first_in_bb then
            bug_check('TRANS_$move_base_instr_to_head_of_new_bb: new complex LR not final%$');
          f := o^.lts;
          if f^.f2.exposed then
            f := f^.l44;
        end;
        bv_$set(old_bb^.live_out, lr);
        x := o^.lts;
        if not x^.f2.final then
          utils_$put_lts_on_final_list(x);
        l := utils_$get_exposed_lts(lr, new_bb, created);
        if created then begin
          l^.l44 := f;
          if f <> nil then begin
            l^.l28 := f^.l28;
            f^.l28 := l;
          end;
          if bv_$test(new_bb^.live_out, lr) then
            if utils_$find_final_lts(lr, new_bb) = nil then
              utils_$put_lts_on_final_list(l);
        end
        else begin
          jb := utils_$find_join_bp(l);
          if jb <> nil then
            l := jb^.opnds[2].lts;
        end;
        l^.rrp := rrp$set_t(integer(l^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
        o^.lts := l;
        if (integer(l^.rrp) & 12) = 0 then begin
          o^.link := l^.refs;
          l^.refs := o;
          bv_$set(new_bb^.live_in, lr);
          bv_$set(new_bb^.live_gen, lr);
        end
        else begin
          o^.link := l^.refs^.link;
          l^.refs^.link := o;
        end;
      end
      else if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        if lr^.id = 0 then
          bug_check('TRANS_$move_base_instr_to_head_of_new_bb: written LR not complex%$');
        utils_$excise_lts_cleanly(o^.lts, false);
        bv_$clear(old_bb^.transparent, lr);
        bv_$clear(old_bb^.live_out, lr);
        l := utils_$find_exposed_lts(lr, new_bb);
        if l <> nil then begin
          jb := utils_$find_join_bp(l);
          if jb <> nil then begin
            l := jb^.opnds[2].lts;
            if (l = nil) or (l^.lr <> lr) then
              bug_check('TRANS_$move_base_instr_to_head_of_new_bb: JOIN_BP has illegal form%$');
            l^.rrp := l^.rrp - [rrp$modify, rrp$write];
            l^.refs := l^.refs^.link;
            jb^.opnds[3].h.kind := operand$none;
            utils_$excise_instruction_cleanly(jb, false);
          end
          else
            utils_$remove_lts_from_exposed_list(l);
        end
        else begin
          l := utils_$get_new_lts(lr, new_bb, true);
          if l^.f2.first_in_bb then
            if bv_$test(new_bb^.live_out, lr) then
              utils_$put_lts_on_final_list(l);
        end;
        o^.lts := l;
        o^.link := l^.refs;
        l^.refs := o;
        l^.rrp := rrp$set_t(integer(l^.rrp) ! (opnd_bytes_ptr_t(o)^.rrp & 12));
        bv_$clear(new_bb^.live_in, lr);
        bv_$clear(new_bb^.live_gen, lr);
        bv_$set(new_bb^.transparent, lr);
        x := lr^.exposed;
        while x <> nil do
          x := x^.next_exposed;
      end;
    end;
  end;
end;

{ combine_instr_with_omega_base - instr (in a predecessor of the block
  base was moved to) made one with base and excised: each register or
  memory operand, last to first, that reads joins base's live range (a
  simple live range merged into it with its mate's, its segment made
  final and killing it, the live range live out of instr's block; a
  complex one's segment made final there and the first of its block)
  and is a birthpoint of base's block for it; one that writes has its
  segment excised, the live range not killed nor live out there.
  base's live range takes instr's IL node when it has none; the source
  statements merged.

  0x283048, 0x210 bytes, no A5: the kinds `btst' in 4094 and 16#4048;
  the bv_$sets of the two paths share a tail (pattern 23). }

procedure combine_instr_with_omega_base(
    instr: instr_ptr_t;
    base: instr_ptr_t); options(val_param); internal;
var
  j: integer32;
  o: opnd_ptr_t;
  lr, blr: lr_ptr_t;
  f, l, rest: lts_ptr_t;
  bb: bb_ptr_t;
begin
  for j := instr^.h.nopnds downto 1 do begin
    o := addr(instr^.opnds[j]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      lr := o^.lts^.lr;
      bb := instr^.bb;
      if o^.h.read then begin
        blr := base^.opnds[j].lts^.lr;
        if lr^.id = 0 then begin
          if blr^.id = 0 then
            bug_check('TRANS_$combine_instr_with_omega_base: expected complex LR%$');
          if blr^.mate <> nil then
            if not (o^.h.kind in [operand$fp_reg_pair,
                                  operand$fp_reg_pair_physical,
                                  operand$fp_reg_pair_like]) then
              if lr^.mate <> nil then
                merge_mate_lr(o^.lts, blr);
          o^.lts^.f2.final := true;
          split_lts_for_merge(o^.lts, rest);
          tr_utils_$merge_lrs(blr, o^.lts^.lr, nil, false, true);
          reattach_split_lts(rest);
          f := o^.lts;
          bv_$set(bb^.transparent, blr);
          bv_$set(bb^.live_out, blr);
        end
        else begin
          l := o^.lts;
          if l^.f2.exposed then
            f := l^.l44
          else
            f := l;
          l^.f2.first_in_bb := true;
          l := o^.lts;
          if not l^.f2.final then
            utils_$put_lts_on_final_list(l);
          bv_$set(bb^.live_out, o^.lts^.lr);
          if (integer(o^.lts^.rrp) & 12) <> 0 then
            bv_$set(bb^.transparent, o^.lts^.lr);
        end;
        utils_$add_birthpoint(f, base^.bb, true);
        if blr^.node20 = nil then
          blr^.node20 := lr^.node20;
      end
      else if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        utils_$excise_lts_cleanly(o^.lts, false);
        bv_$clear(bb^.transparent, lr);
        bv_$clear(bb^.live_out, lr);
      end;
    end;
  end;
  utils_$maybe_merge_source_statements(base, instr);
  utils_$excise_instruction_cleanly(instr, false);
end;

{ add_successors_to_work_list - bb's successors not on the work list
  (head, chained through the blocks' work links) put on it, then bb.
  0x283294, 0x48 bytes, no A5. }

procedure add_successors_to_work_list(
    var head: bb_ptr_t;
    bb: bb_ptr_t); options(val_param); internal;
var
  e: fg_edge_ptr_t;
  t: bb_ptr_t;
begin
  e := bb^.succs;
  while e <> nil do begin
    t := e^.target;
    if trans_bb_v_ptr_t(t)^.work = nil then begin
      trans_bb_v_ptr_t(t)^.work := head;
      head := e^.target;
    end;
    e := e^.next_succ;
  end;
  if trans_bb_v_ptr_t(bb)^.work = nil then begin
    trans_bb_v_ptr_t(bb)^.work := head;
    head := bb;
  end;
end;

{ add_predecessors_to_work_list - bb's predecessors marked with mark
  and not on the work list put on it, then bb.  0x2832DC, 0x4E bytes, no
  A5. }

procedure add_predecessors_to_work_list(
    var head: bb_ptr_t;
    bb: bb_ptr_t;
    mark: integer32); options(val_param); internal;
var
  e: fg_edge_ptr_t;
  s: bb_ptr_t;
begin
  e := bb^.preds;
  while e <> nil do begin
    s := e^.source;
    if trans_bb_v_ptr_t(s)^.work = nil then
      if s^.mark146 = mark then begin
        trans_bb_v_ptr_t(s)^.work := head;
        head := e^.source;
      end;
    e := e^.next_pred;
  end;
  if trans_bb_v_ptr_t(bb)^.work = nil then begin
    trans_bb_v_ptr_t(bb)^.work := head;
    head := bb;
  end;
end;

{ get_omega_candidate - the instruction that defines lr's final segment
  in from_bb, when it writes, from_bb has the same +42 as to_bb, is not
  marked +17 bit 6 and its +16 is not below to_bb's, and it may be moved
  into to_bb (validate_instr, motion 1); else nil.  0x28332A, 0x84
  bytes, no A5: validate_instr's result left in A0 (pattern 32). }

function get_omega_candidate(
    from_bb: bb_ptr_t;
    to_bb: bb_ptr_t;
    lr: lr_ptr_t): instr_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
  i: instr_ptr_t;
begin
  l := utils_$find_final_lts(lr, from_bb);
  if (l = nil) or (l^.refs = nil) then
    get_omega_candidate := nil
  else if ((opnd_bytes_ptr_t(l^.refs)^.rrp & 12) = 0)
      or (trans_bb_v_ptr_t(to_bb)^.l42 <> trans_bb_v_ptr_t(from_bb)^.l42)
      or from_bb^.f.b17_6
      or (to_bb^.f.b16 > from_bb^.f.b16) then
    get_omega_candidate := nil
  else begin
    i := utils_ins_$operands_instruction(l^.refs);
    get_omega_candidate := validate_instr(from_bb, to_bb, i, 1);
  end;
end;

{ trans_$omega_motions - the omega motions: for each block (from a work
  list of all the blocks in code order, ended by -1) with two
  predecessors or more, not marked +17 bit 6 and of kind other than 2,
  and each live range live into it (a physical register's only with
  the phase's switch 10), when every predecessor's final definition of
  it is a candidate (get_omega_candidate) and does what the first one
  does (instrs_ok_for_motion), the first moved to the head of the block
  and the others combined with it; the block's successors and the
  block then go back on the work list.

  0x2833AE, 0x178 bytes: A5 loaded; at_backend_switches' address loaded
  into D4 and not used (pattern 53); bv_$find_next's first nil pushed
  before the loop is entered at its test; the first instrs_ok_for_motion
  compares the first candidate with itself; head kept in a register
  and passed to add_successors_to_work_list through a frame slot
  (pattern 72). }

procedure trans_$omega_motions(
    rtn: rtn_ptr_t);
var
  head, bb, b: bb_ptr_t;
  lr: lr_ptr_t;
  e: fg_edge_ptr_t;
  base, c: instr_ptr_t;
  ok: boolean;
begin
  b := rtn^.bbs;
  if b = nil then
    return;
  head := b;
  while b^.next <> nil do begin
    trans_bb_v_ptr_t(b)^.work := b^.next;
    b := b^.next;
  end;
  trans_bb_v_ptr_t(b)^.work := bb_ptr_t(-1);
  repeat
    bb := head;
    head := trans_bb_v_ptr_t(bb)^.work;
    trans_bb_v_ptr_t(bb)^.work := nil;
    if bb^.preds <> nil then
      if not bb^.f.b17_6 then
        if bb^.f14.b14 <> 2 then
          if bb^.preds^.next_pred <> nil then begin
            lr := bv_$find_next(rtn, bb^.live_in, nil);
            while lr <> nil do begin
              if (rrp$unique_value in lr^.rrp) or not lr^.f2.b3_7
                  or at_backend_switches.sw10 then begin
                e := bb^.preds;
                base := get_omega_candidate(e^.source, bb, lr);
                if base <> nil then begin
                  ok := instrs_ok_for_motion(base, base, bb, 1);
                  e := e^.next_pred;
                  while ok and (e <> nil) do begin
                    c := get_omega_candidate(e^.source, bb, lr);
                    if c = nil then
                      ok := false
                    else begin
                      ok := instrs_ok_for_motion(base, c, bb, 1);
                      e := e^.next_pred;
                    end;
                  end;
                  if ok then begin
                    move_base_instr_to_head_of_new_bb(rtn, base, bb);
                    e := bb^.preds^.next_pred;
                    while e <> nil do begin
                      c := get_omega_candidate(e^.source, bb, lr);
                      combine_instr_with_omega_base(c, base);
                      e := e^.next_pred;
                    end;
                    add_successors_to_work_list(head, bb);
                  end;
                end;
              end;
              lr := bv_$find_next(rtn, bb^.live_in, lr);
            end;
          end;
  until (head = nil) or (head = bb_ptr_t(-1));
end;

{ move_base_instr_to_tail_of_new_bb - instr taken out of its block and
  put at the tail of new_bb (before its closing branches and jumps),
  its register and memory operands, first to last, taken off their
  segments' operands and moved with it: a reader's exposed segment
  (excised when left without operands, the live range then not read in
  the old block, nor live into it unless live out) replaced by new_bb's
  final segment of the live range, or its exposed one made final
  (chained to the final segment that reached the old one), the reader
  put last among its operands; a writer's live range made complex, its
  old segment made an exposed reader in the old block (the live range
  read there and killed unless the segment was the first of its
  block), and new_bb's final segment (a new one, when one existed only
  through a modify) made the definition, the live range killed in
  new_bb and live out of it.

  0x283526, 0x38C bytes, no A5: the block's tail found from its last
  instruction by the classes `btst' in 98, without a nil test of the
  last instruction or of the next one where instr is linked in; the
  kinds `btst' in 4094.  The messages name the routine
  move_instr_to_tail_of_new_bb. }

procedure move_base_instr_to_tail_of_new_bb(
    rtn: rtn_ptr_t;
    instr: instr_ptr_t;
    new_bb: bb_ptr_t); options(val_param); internal;
var
  old_bb: bb_ptr_t;
  i: instr_ptr_t;
  j: integer32;
  o, p: opnd_ptr_t;
  l, f: lts_ptr_t;
  lr: lr_ptr_t;
  created: boolean;
begin
  old_bb := instr^.bb;
  if instr^.prev = nil then
    old_bb^.first := instr^.next
  else
    instr^.prev^.next := instr^.next;
  if instr^.next = nil then
    old_bb^.last := instr^.prev
  else
    instr^.next^.prev := instr^.prev;
  i := new_bb^.last;
  while instruction_attributes[i^.opc].class
      in [class$branch, class$fp_branch, class$jump] do begin
    i := i^.prev;
    if i = nil then
      exit;
  end;
  instr^.bb := new_bb;
  if i = nil then begin
    instr^.next := new_bb^.first;
    new_bb^.first^.prev := instr;
    new_bb^.first := instr;
    instr^.prev := nil;
  end
  else begin
    instr^.next := i^.next;
    instr^.next^.prev := instr;
    i^.next := instr;
    instr^.prev := i;
  end;
  for j := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[j]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
      l := o^.lts;
      lr := l^.lr;
      if l^.refs = o then
        l^.refs := o^.link
      else begin
        p := l^.refs;
        while p^.link <> o do
          p := p^.link;
        p^.link := o^.link;
      end;
      if o^.h.read then begin
        if not o^.lts^.f2.exposed then
          bug_check('TRANS_$move_instr_to_tail_of_new_bb: expected exposed LTS%$');
        l := o^.lts;
        f := l^.l44;
        if l^.refs = nil then begin
          utils_$excise_lts_cleanly(l, false);
          bv_$clear(old_bb^.live_gen, lr);
          if not bv_$test(old_bb^.live_out, lr) then
            bv_$clear(old_bb^.live_in, lr);
        end;
        l := utils_$find_final_lts(lr, new_bb);
        if l = nil then begin
          l := utils_$get_exposed_lts(lr, new_bb, created);
          if not l^.f2.first_in_bb then
            bug_check('TRANS_$move_instr_to_tail_of_new_bb: expected final LTS%$');
          l^.rrp := l^.rrp + [rrp$read];
          utils_$put_lts_on_final_list(l);
          if f <> nil then begin
            l^.l28 := f^.l28;
            f^.l28 := l;
          end
          else
            l^.l28 := nil;
          l^.l44 := f;
        end;
        o^.lts := l;
        o^.link := nil;
        l^.rrp := rrp$set_t(integer(l^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
        if l^.refs = nil then
          l^.refs := o
        else begin
          p := l^.refs;
          while p^.link <> nil do
            p := p^.link;
          p^.link := o;
        end;
      end
      else if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        if lr^.id = 0 then
          make_lr_complex(rtn, lr);
        l := o^.lts;
        l^.rrp := l^.rrp - [rrp$modify, rrp$write];
        utils_$put_lts_on_exposed_list(o^.lts);
        bv_$set(old_bb^.live_in, lr);
        bv_$set(old_bb^.live_gen, lr);
        if o^.lts^.f2.first_in_bb then
          bv_$clear(old_bb^.transparent, lr)
        else
          bv_$set(old_bb^.transparent, lr);
        l := utils_$get_final_lts(lr, new_bb, created);
        if not created then begin
          if not o^.h.modify then
            bug_check('TRANS_$move_instr_to_tail_of_new_bb: expected modify cycle%$');
          utils_$remove_lts_from_final_list(l);
          l := utils_$get_final_lts(lr, new_bb, created);
        end;
        utils_$move_definition(o^.lts, l, true);
        o^.link := nil;
        o^.lts := l;
        l^.refs := o;
        l^.rrp := rrp$set_t(integer(l^.rrp) ! opnd_bytes_ptr_t(o)^.rrp);
        bv_$set(new_bb^.transparent, lr);
        bv_$set(new_bb^.live_out, lr);
      end;
    end;
  end;
end;

{ combine_instr_with_alpha_base - instr (in a successor of the block
  base was moved to) made one with base and excised: each register or
  memory operand, first to last, that is its segment's only reader has
  the segment excised (the live range not read in instr's block, nor
  live into it unless live out) and is cleared; one that writes (its
  segment's definition) gives the definition to base's segment (a
  simple live range merged into base's first, with its mate's), the
  old segment becoming an exposed reader (the live range read in
  instr's block, killed there unless the segment was the first of its
  block).  The source statements merged.

  0x283964, 0x236 bytes, no A5: the kinds `btst' in 4094 and 16#4048;
  the cleared operand's first word stored with `clr.w' and its kind
  with `andi.w #-32' of the word at +2. }

procedure combine_instr_with_alpha_base(
    instr: instr_ptr_t;
    base: instr_ptr_t); options(val_param); internal;
var
  j: integer32;
  o: opnd_ptr_t;
  lr, blr: lr_ptr_t;
  bl, rest, l: lts_ptr_t;
  bb: bb_ptr_t;
begin
  for j := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[j]);
    if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if o^.h.read then begin
        if o^.lts^.refs = o then
          if o^.link = nil then begin
            bb := instr^.bb;
            lr := o^.lts^.lr;
            bv_$clear(bb^.live_gen, lr);
            if not bv_$test(bb^.live_out, lr) then
              bv_$clear(bb^.live_in, lr);
            utils_$excise_lts_cleanly(o^.lts, false);
            opnd_bytes_ptr_t(o)^.num := 0;
            opnd_bytes_ptr_t(o)^.rrp := 0;
            o^.lts := nil;
            o^.h.kind := operand$none;
          end;
      end
      else if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
        if o^.lts^.refs <> o then
          bug_check('TRANS_$combine_instr_with_alpha_base:  write operand not first%$');
        o^.lts^.refs := o^.link;
        lr := o^.lts^.lr;
        bl := base^.opnds[j].lts;
        if lr^.id = 0 then begin
          blr := bl^.lr;
          if blr^.mate <> nil then
            if not (o^.h.kind in [operand$fp_reg_pair,
                                  operand$fp_reg_pair_physical,
                                  operand$fp_reg_pair_like]) then
              if lr^.mate <> nil then
                merge_mate_lr(o^.lts, blr);
          split_lts_for_merge(o^.lts, rest);
          tr_utils_$merge_lrs(blr, lr, base^.bb, false, true);
          reattach_split_lts(rest);
          lr := blr;
        end
        else if lr <> bl^.lr then
          bug_check('TRANS_$combine_instr_with_alpha_base:  LRs don''t match%$');
        utils_$move_definition(o^.lts, bl, true);
        l := o^.lts;
        l^.rrp := l^.rrp - [rrp$modify, rrp$write];
        utils_$put_lts_on_exposed_list(o^.lts);
        bv_$set(instr^.bb^.live_in, lr);
        bv_$set(instr^.bb^.live_gen, lr);
        if o^.lts^.f2.first_in_bb then
          bv_$clear(instr^.bb^.transparent, lr)
        else
          bv_$set(instr^.bb^.transparent, lr);
      end;
  end;
  utils_$maybe_merge_source_statements(base, instr);
  utils_$excise_instruction_cleanly(instr, false);
end;

{ collect_unprecedented_instrs - unless from_bb's list of them is made
  already, the instructions of from_bb that read no register or memory
  and may move out of it into to_bb (validate_instr, motion 0), chained
  from the block's +122 through the instructions' +24.  0x283C12, 0x94
  bytes, no A5. }

procedure collect_unprecedented_instrs(
    from_bb: bb_ptr_t;
    to_bb: bb_ptr_t); options(val_param); internal;
var
  i: instr_ptr_t;
  j: integer32;
  o: opnd_ptr_t;
  reads: boolean;
begin
  if trans_bb_v_ptr_t(from_bb)^.unprec = nil then begin
    i := from_bb^.first;
    while i <> nil do begin
      reads := false;
      for j := 1 to i^.h.nopnds do begin
        o := addr(i^.opnds[j]);
        if o^.h.read then
          if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
            reads := true;
            exit;
          end;
      end;
      if not reads then
        if validate_instr(from_bb, to_bb, i, 0) <> nil then begin
          i^.l24 := integer32(trans_bb_v_ptr_t(from_bb)^.unprec);
          trans_bb_v_ptr_t(from_bb)^.unprec := i;
        end;
      i := i^.next;
    end;
  end;
end;

{ drop_unprecedented_instr - i taken off its block's list of
  unprecedented instructions.  0x283CA6, 0x3A bytes, no frame. }

procedure drop_unprecedented_instr(
    i: instr_ptr_t); options(val_param); internal;
var
  b: bb_ptr_t;
  p: instr_ptr_t;
begin
  b := i^.bb;
  if trans_bb_v_ptr_t(b)^.unprec = i then
    trans_bb_v_ptr_t(b)^.unprec := instr_ptr_t(i^.l24)
  else begin
    p := trans_bb_v_ptr_t(b)^.unprec;
    while p <> nil do begin
      if instr_ptr_t(p^.l24) = i then
        exit;
      p := instr_ptr_t(p^.l24);
    end;
    if p <> nil then
      p^.l24 := i^.l24;
  end;
end;

{ get_alpha_candidate - the next reader (after cur, or the first of lr's
  exposed segment in from_bb when cur is nil: the segment must exist,
  have operands and not be written there, and from_bb must not be
  marked +17 bit 6) whose instruction may be moved out of from_bb into
  to_bb (validate_instr, motion 0); cur left at the reader; nil when
  there is none.  0x283CE0, 0x8C bytes, no A5: validate_instr's result
  left in A0 (pattern 32); the test of cur the flags of its store
  (pattern 111). }

function get_alpha_candidate(
    from_bb: bb_ptr_t;
    to_bb: bb_ptr_t;
    lr: lr_ptr_t;
    var cur: opnd_ptr_t): instr_ptr_t; options(val_param); internal;
var
  l: lts_ptr_t;
  o: opnd_ptr_t;
  i: instr_ptr_t;
  ok: boolean;
begin
  ok := true;
  if cur = nil then begin
    l := utils_$find_exposed_lts(lr, from_bb);
    if (l = nil) or (l^.refs = nil) then
      ok := false
    else if ((opnd_bytes_ptr_t(l^.refs)^.rrp & 12) <> 0)
        or from_bb^.f.b17_6 then
      ok := false
    else
      o := l^.refs;
  end
  else
    o := cur^.link;
  if not ok then
    get_alpha_candidate := nil
  else begin
    cur := o;
    if o = nil then
      get_alpha_candidate := nil
    else begin
      i := utils_ins_$operands_instruction(o);
      get_alpha_candidate := validate_instr(from_bb, to_bb, i, 0);
    end;
  end;
end;

{ trans_$alpha_motions - the alpha motions: the blocks (in the order
  from the routine's +72) with two successors or more, of kind other
  than 1 and not marked +17 bit 6 or +18 bit 7, whose successors each
  have it as their only predecessor, the same +42 and a +16 not below
  its own, are marked (a new mark) and put on a work list.  First, for
  each such block, an unprecedented instruction of its first successor
  (collect_unprecedented_instrs) that each other successor has one
  doing the same as (instrs_ok_for_motion, motion 0; at most 256) is
  moved to the tail of the block and the others combined with it (the
  moved one becoming unprecedented in the block when it may move on
  into the block's first predecessor); then, from a work list of the
  marked blocks in code order, for each live range read first in its
  first successor (a physical register's only with the phase's switch
  10) and in every other, a reader in the first successor (trying each
  in turn) that each other successor has one doing the same as is
  moved, and the others combined with it.  A block that gained an
  instruction puts its marked predecessors and itself back on the work
  list.

  0x283D6C, 0x3DC bytes: A5 loaded; at_backend_switches' address loaded
  into D5 and not used (pattern 53); the candidates in a 256-entry frame
  array, the count tested after it is counted up (`cmpi.l #256; bgt');
  a successor without a matching reader sends the search back to the
  first successor's next reader; the work lists' heads kept in
  registers and passed to add_predecessors_to_work_list through a frame
  slot (pattern 72). }

procedure trans_$alpha_motions(
    rtn: rtn_ptr_t);
var
  next: instr_ptr_t;
  cands: array [1..256] of instr_ptr_t;
  head, tail, b, bb, t: bb_ptr_t;
  first, e: fg_edge_ptr_t;
  base, c: instr_ptr_t;
  lr: lr_ptr_t;
  cur, cur2: opnd_ptr_t;
  mark, n, k: integer32;
  ok, moved, retry, found: boolean;
begin
  b := rtn^.bbs72;
  if b = nil then
    return;
  rtn^.marks := rtn^.marks + 1;
  head := nil;
  mark := rtn^.marks;
  tail := head;
  repeat
    trans_bb_v_ptr_t(b)^.unprec := nil;
    if b^.succs <> nil then
      if b^.f14.b14 <> 1 then
        if not b^.f.b17_6 then
          if not b^.f.b18_7 then
            if b^.succs^.next_succ <> nil then begin
              ok := true;
              e := b^.succs;
              while ok and (e <> nil) do begin
                t := e^.target;
                if t^.preds = nil then
                  ok := false
                else if t^.preds^.next_pred <> nil then
                  ok := false
                else if b^.f.b16 > t^.f.b16 then
                  ok := false
                else if trans_bb_v_ptr_t(b)^.l42 <> trans_bb_v_ptr_t(t)^.l42 then
                  ok := false
                else
                  e := e^.next_succ;
              end;
              if ok then begin
                if head = nil then
                  head := b
                else
                  trans_bb_v_ptr_t(tail)^.work := b;
                b^.mark146 := mark;
                tail := b;
              end;
            end;
    b := b^.next114;
  until b = nil;
  if tail = nil then
    return;
  trans_bb_v_ptr_t(tail)^.work := bb_ptr_t(-1);
  b := head;
  repeat
    e := b^.succs;
    while e <> nil do begin
      collect_unprecedented_instrs(e^.target, b);
      e := e^.next_succ;
    end;
    b := trans_bb_v_ptr_t(b)^.work;
  until b = bb_ptr_t(-1);

  repeat
    bb := head;
    head := trans_bb_v_ptr_t(bb)^.work;
    trans_bb_v_ptr_t(bb)^.work := nil;
    first := bb^.succs;
    base := trans_bb_v_ptr_t(first^.target)^.unprec;
    moved := false;
    while (base <> nil) and not moved do begin
      next := instr_ptr_t(base^.l24);
      if instrs_ok_for_motion(base, base, bb, 0) then begin
        n := 0;
        e := first^.next_succ;
        ok := true;
        while ok and (e <> nil) do begin
          c := trans_bb_v_ptr_t(e^.target)^.unprec;
          while c <> nil do begin
            if instrs_ok_for_motion(base, c, bb, 0) then
              exit;
            c := instr_ptr_t(c^.l24);
          end;
          if c = nil then
            ok := false
          else begin
            n := n + 1;
            if n > 256 then
              ok := false
            else begin
              cands[n] := c;
              e := e^.next_succ;
            end;
          end;
        end;
        if ok then begin
          drop_unprecedented_instr(base);
          move_base_instr_to_tail_of_new_bb(rtn, base, bb);
          if bb^.preds <> nil then
            if bb^.preds^.source <> nil then
              if validate_instr(bb, bb^.preds^.source, base, 0) <> nil then begin
                base^.l24 := integer32(trans_bb_v_ptr_t(bb)^.unprec);
                trans_bb_v_ptr_t(bb)^.unprec := base;
              end;
          for k := 1 to n do begin
            c := cands[k];
            drop_unprecedented_instr(c);
            combine_instr_with_alpha_base(c, base);
          end;
          add_predecessors_to_work_list(head, bb, mark);
          moved := true;
        end;
      end;
      base := next;
    end;
  until (head = nil) or (head = bb_ptr_t(-1));

  head := bb_ptr_t(-1);
  b := rtn^.bbs;
  repeat
    if b^.mark146 = mark then begin
      trans_bb_v_ptr_t(b)^.work := head;
      head := b;
    end;
    b := b^.next;
  until b = nil;
  repeat
    bb := head;
    head := trans_bb_v_ptr_t(bb)^.work;
    trans_bb_v_ptr_t(bb)^.work := nil;
    first := bb^.succs;
    moved := false;
    lr := bv_$find_next(rtn, first^.target^.live_gen, nil);
    while (lr <> nil) and not moved do begin
      if (rrp$unique_value in lr^.rrp) or not lr^.f2.b3_7
          or at_backend_switches.sw10 then begin
        cur := nil;
        repeat
          retry := false;
          base := get_alpha_candidate(first^.target, bb, lr, cur);
          if base <> nil then
            if instrs_ok_for_motion(base, base, bb, 0) then begin
              n := 0;
              e := first^.next_succ;
              ok := true;
              while ok and (e <> nil) do
                if not bv_$test(e^.target^.live_gen, lr) then
                  ok := false
                else begin
                  cur2 := nil;
                  repeat
                    c := get_alpha_candidate(e^.target, bb, lr, cur2);
                    if c = nil then
                      exit;
                    found := instrs_ok_for_motion(base, c, bb, 0);
                  until found;
                  if c = nil then begin
                    retry := true;
                    ok := false;
                  end
                  else begin
                    n := n + 1;
                    if n > 256 then
                      ok := false
                    else begin
                      cands[n] := c;
                      e := e^.next_succ;
                    end;
                  end;
                end;
              if ok then begin
                move_base_instr_to_tail_of_new_bb(rtn, base, bb);
                for k := 1 to n do
                  combine_instr_with_alpha_base(cands[k], base);
                add_predecessors_to_work_list(head, bb, mark);
                moved := true;
              end;
            end;
        until not retry;
      end;
      if not moved then
        lr := bv_$find_next(rtn, first^.target^.live_gen, lr);
    end;
  until (head = nil) or (head = bb_ptr_t(-1));
end;

{ attempt_special_zero_branches - br (a BNE or BEQ) on condition codes
  whose canonical birthpoint is an AND of 7 or 3, or an EXTRACTU at 0
  of width 3 or 2, of a value whose result is a simple live range used
  only there (for 2 bits the value made by an OR that is not a reader):
  br made a branch on the low bits (BNE: BL2 or BNZ3, BEQ: BNL2 or BZ3)
  and the AND or EXTRACTU a TST of the value, then test elimination
  tried on it.  0x284148, 0x21C bytes, no A5: trans_0 read through the
  caller's A5. }

procedure attempt_special_zero_branches(
    br: instr_ptr_t); options(val_param); internal;
var
  l, src: lts_ptr_t;
  bp: utils_$birthpoint_t;
  d: instr_ptr_t;
  o3, r: opnd_ptr_t;
  n, v: integer32;
begin
  if not (br^.opnds[br^.h.nopnds].h.kind
          in [operand$ip_reg..operand$well_behaved_memory]) then
    return;
  l := br^.opnds[br^.h.nopnds].lts;
  utils_$get_canonical_birthpoint(l, 0, bp);
  if bp.lts = nil then
    return;
  d := utils_ins_$operands_instruction(bp.lts^.refs);
  if (d^.opc = ord(opc$and))
      and (d^.opnds[1].h.kind = operand$immediate) then begin
    v := d^.opnds[1].value;
    if v = 7 then
      n := 3
    else if v = 3 then
      n := 2
    else
      return;
    src := d^.opnds[2].lts;
  end
  else if (d^.opc = ord(opc$extractu))
      and (d^.opnds[2].h.kind = operand$immediate)
      and (d^.opnds[2].value = 0) then begin
    n := d^.h.width;
    src := d^.opnds[1].lts;
  end
  else
    return;
  o3 := addr(d^.opnds[3]);
  if (n <> 2) and (n <> 3) then
    return;
  if not (o3^.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    return;
  if o3^.link <> nil then
    return;
  if o3^.lts^.lr^.id <> 0 then
    return;
  if n = 2 then begin
    utils_$get_canonical_birthpoint(src, 0, bp);
    if bp.lts = nil then
      return;
    r := bp.lts^.refs;
    if r^.h.read then
      return;
    if utils_ins_$operands_instruction(r)^.opc <> ord(opc$or) then
      return;
  end;
  if br^.opc = ord(opc$bne) then begin
    if n = 2 then
      utils_$set_instruction_opcode(br, ord(opc$bl2))
    else
      utils_$set_instruction_opcode(br, ord(opc$bnz3));
  end
  else if br^.opc = ord(opc$beq) then begin
    if n = 2 then
      utils_$set_instruction_opcode(br, ord(opc$bnl2))
    else
      utils_$set_instruction_opcode(br, ord(opc$bz3));
  end
  else
    bug_check('TRANS_$attempt_special_zero_branches:  input branch was not BEQ or BNE.%$');
  if d^.opc = ord(opc$extractu) then
    d^.h.width := 0
  else
    copy_operand(addr(d^.opnds[1]), addr(d^.opnds[2]), false);
  copy_operand(addr(d^.opnds[2]), addr(d^.opnds[d^.h.nopnds]), false);
  d^.h.nopnds := 2;
  utils_$set_instruction_opcode(d, ord(opc$tst));
  tr_utils_$attempt_test_elimination(trans_0, d);
end;

{ massage_xor_to_tst - an XOR of 0 that sets the condition codes (four
  operands) and whose result, a simple live range, is not read: made a
  TST of its value (three operands), then test elimination tried on it.
  0x2843AE, 0xBE bytes, no A5: trans_0 read through the caller's A5;
  the copy_operand pads left for the next call (pattern 51). }

procedure massage_xor_to_tst(
    x: instr_ptr_t); options(val_param); internal;
var
  l: lts_ptr_t;
begin
  if not (x^.opnds[3].h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    return;
  if x^.opnds[1].value <> 0 then
    return;
  if x^.opnds[1].h.kind <> operand$immediate then
    return;
  if not x^.h.sets_cc then
    return;
  if x^.h.nopnds <> 4 then
    return;
  l := x^.opnds[3].lts;
  if l^.refs^.link <> nil then
    return;
  if l^.lr^.id <> 0 then
    return;
  utils_$set_instruction_opcode(x, ord(opc$tst));
  copy_operand(addr(x^.opnds[1]), addr(x^.opnds[2]), false);
  copy_operand(addr(x^.opnds[2]), addr(x^.opnds[3]), false);
  copy_operand(addr(x^.opnds[3]), addr(x^.opnds[4]), false);
  x^.opnds[4].h.num := 0;
  x^.h.nopnds := 3;
  tr_utils_$attempt_test_elimination(trans_0, x);
end;

{ trans_$kill_silly_extract - an EXTRACTU at 0 (four operands) of a
  register or memory value whose high bits beyond the field's width are
  known to be zero (n_zero_high_bits): made a MOVE (three operands, the
  fourth moved down or, when of kind none, copied whole), then test
  elimination tried on it when it sets the condition codes, else it is
  marked +0 bit 6.  0x28446C, 0xF4 bytes; called from com and
  process_routine. }

procedure trans_$kill_silly_extract(
    x: instr_ptr_t);
begin
  if not (x^.opnds[3].h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    return;
  if x^.opnds[2].value <> 0 then
    return;
  if x^.opnds[2].h.kind <> operand$immediate then
    return;
  if x^.h.nopnds <> 4 then
    return;
  if not (x^.opnds[1].h.kind in [operand$ip_reg..operand$well_behaved_memory]) then
    return;
  if n_zero_high_bits(addr(x^.opnds[1])) < 32 - x^.h.width then
    return;
  utils_$set_instruction_opcode(x, ord(opc$move));
  copy_operand(addr(x^.opnds[2]), addr(x^.opnds[3]), false);
  if x^.opnds[4].h.kind <> operand$none then begin
    copy_operand(addr(x^.opnds[3]), addr(x^.opnds[4]), false);
    x^.opnds[4].h.kind := operand$none;
    x^.opnds[4].h.num := 0;
  end
  else
    x^.opnds[3] := x^.opnds[4];
  x^.h.nopnds := 3;
  if x^.h.sets_cc then
    tr_utils_$attempt_test_elimination(trans_0, x)
  else
    x^.h.b0_6 := true;
end;

{ trans_$copy_elimination - copy elimination tried on every
  instruction whose opcode's b6_0 is set, block by block in the order
  from the routine's +72.  0x284560, 0x70 bytes; called from com and
  process_routine: sets trans_0. }

procedure trans_$copy_elimination(
    rtn: rtn_ptr_t);
var
  b: bb_ptr_t;
  i: instr_ptr_t;
begin
  trans_0 := rtn;
  b := rtn^.bbs72;
  while b <> nil do begin
    i := b^.first;
    while i <> nil do begin
      if instruction_attributes[i^.opc].b6_0 then
        tr_utils_$attempt_copy_elimination(rtn, i);
      i := i^.next;
    end;
    b := b^.next114;
  end;
end;

{ trans_$begin_compilation - nothing.  0x2845D0, 2 bytes. }

procedure trans_$begin_compilation;
begin
end;

{ trans_$end_compilation - nothing.  0x2845D2, 2 bytes. }

procedure trans_$end_compilation;
begin
end;

{ trans_$end_routine - nothing.  0x2845D4, 2 bytes. }

procedure trans_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ trans_$process_routine - the phase: rtn checked (lir_utils_$
  sanity_check), the live ranges' hints made invalid; unless the phase's
  switch 15 or 14 is set, with 4 bit vectors to each block: the
  branches transformed in each block not marked +17 bit 6 (in the order
  from the routine's +72), the alpha and omega motions, the bit vectors
  released and the instructions resequenced; then twice: for each
  segment's defining instruction (not in a block marked +17 bit 6, its
  +2 bit 6 set) a silly EXTRACTU killed, an XOR of 0 made a TST, test
  elimination tried on a MOVE, COPYS or COPYD (that sets the condition
  codes, or is marked +0 bit 3) or a TST or WIDEN that writes condition
  codes, autoincrement tried on an ADD or SUB (when it succeeds the live
  range's segments walked again from the first, else the displacement
  twiddled), and copy elimination; last the special zero branches of
  the readers of the condition code live ranges (+2 30 or 31), and the
  global walk unless switch 13 is set.  The level's messages around it.

  0x2845D6, 0x2F0 bytes: lir_main_c8d cleared with `clr.b', lir_main_c84
  set to 4; the opcodes by a compare chain (97, 86, 75, 161, 144, 99,
  98, 175, 158, 72, 71, 73, 81, 79); the passes counted down from 1 by
  `dbf'; the loops' tests the flags of their pointers' moves; the
  register kinds `btst' in 384; try_twiddling_disp's result dropped. }

procedure trans_$process_routine(
    rtn: rtn_ptr_t);
var
  b: bb_ptr_t;
  pass: integer;
  lr: lr_ptr_t;
  l: lts_ptr_t;
  o: opnd_ptr_t;
  i: instr_ptr_t;
  again: boolean;
begin
  trans_0 := rtn;
  lir_utils_$sanity_check(rtn);
  lir_main_c8d := false;
  if at_backend_switches.sw15 then
    return;
  if at_backend_switches.sw14 then
    return;
  if at_backend_switches.level <> 0 then
    vfmt_$write('Enter graph transformation phase!!!!!!!!%.');
  lir_main_c84 := 4;
  b := rtn^.bbs72;
  while b <> nil do begin
    if not b^.f.b17_6 then
      trans_branches(b);
    b := b^.next114;
  end;
  trans_$alpha_motions(rtn);
  trans_$omega_motions(rtn);
  bv_$release_bit_vectors(rtn);
  utils_$guarantee_instr_sequence(rtn);
  for pass := 1 downto 0 do begin
    lr := rtn^.lrs;
    while lr <> nil do begin
      l := lr^.ltss;
      while l <> nil do begin
        again := false;
        o := l^.refs;
        if o <> nil then
          if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
            i := utils_ins_$operands_instruction(o);
            if not i^.bb^.f.b17_6 then
              if i^.h.b2_6 then
                case i^.opc of
                  97:                   { extractu }
                    trans_$kill_silly_extract(i);
                  86:                   { xor }
                    massage_xor_to_tst(i);
                  75:                   { move }
                    if i^.h.sets_cc then
                      if o^.h.kind in [operand$ip_condition_codes,
                                       operand$fp_condition_codes] then
                        tr_utils_$attempt_test_elimination(rtn, i);
                  161, 144:             { copyd, copys }
                    if i^.h.b0_3 then
                      if o^.h.kind in [operand$ip_condition_codes,
                                       operand$fp_condition_codes] then
                        tr_utils_$attempt_test_elimination(rtn, i);
                  99, 98, 175, 158, 72, 71, 73:   { widenw, widenb, tstd,
                                          tsts, tstw, tstb, tst }
                    if o^.h.kind in [operand$ip_condition_codes,
                                     operand$fp_condition_codes] then
                      tr_utils_$attempt_test_elimination(rtn, i);
                  81, 79:               { sub, add }
                    if tr_utils_$attempt_autoincrement(rtn, i) then
                      again := true
                    else
                      discard(tr_utils_$try_twiddling_disp(i, 0, true, true));
                  otherwise
                    ;
                end;
          end;
        if again then
          l := lr^.ltss
        else
          l := l^.next;
      end;
      lr := lr^.next;
    end;
    trans_$copy_elimination(rtn);
  end;
  lr := rtn^.lrs;
  while lr <> nil do begin
    if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then
      if (lr^.f2.b2 = 30) or (lr^.f2.b2 = 31) then begin
        l := lr^.ltss;
        while l <> nil do begin
          o := l^.refs;
          if o <> nil then
            if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
              o := o^.link;
              while o <> nil do begin
                i := utils_ins_$operands_instruction(o);
                if i^.bb^.f.b17_6 then
                  exit;
                if (i^.opc = ord(opc$beq)) or (i^.opc = ord(opc$bne)) then
                  attempt_special_zero_branches(i);
                o := o^.link;
              end;
            end;
          l := l^.next;
        end;
      end;
    lr := lr^.next;
  end;
  if not at_backend_switches.sw13 then
    df_utils_$global_walk(rtn, rtn^.l192, 1, 0);
  if at_backend_switches.level <> 0 then
    vfmt_$write('End of graph transformation phase!!!!!!!!%.');
end;
