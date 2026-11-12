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
    --------  0x282AB6  merge_mate_lr (internal)
    --------  0x2845D0  trans_$begin_compilation
    --------  0x2845D2  trans_$end_compilation
    --------  0x2845D4  trans_$end_routine
    A5 0x492FA4: the module's data: +0 (pushed for its calls by
    massage_xor_to_tst, kill_silly_extract and copy_elimination; not
    yet translated).

  Not known from the original: every local and parameter name, the
  module cell's name. }

{ TODO(pascal) trans: 18 of the image's 37 routines.  Remaining:
  instrs_ok_for_motion (0x282562, 0x520 bytes: operands compared by
  kind through a 24-entry jump table, physical registers' live ranges
  from the tables at 0x48B010 and 0x48B110), move_base_instr_to_head_of_
  new_bb (0x282B8C), combine_instr_with_omega_base (0x283048),
  add_successors_to_work_list (0x283294), add_predecessors_to_work_list
  (0x2832DC), get_omega_candidate (0x28332A), trans_$omega_motions
  (0x2833AE), move_base_instr_to_tail_of_new_bb (0x283526),
  combine_instr_with_alpha_base (0x283964), collect_unprecedented_instrs
  (0x283C12), drop_unprecedented_instr (0x283CA6), get_alpha_candidate
  (0x283CE0), trans_$alpha_motions (0x283D6C),
  attempt_special_zero_branches (0x284148), massage_xor_to_tst
  (0x2843AE), trans_$kill_silly_extract (0x28446C),
  trans_$copy_elimination (0x284560), trans_$process_routine (0x2845D6:
  clears lir_main_c8d, sets lir_main_c86 to 4, the level from
  at_backend_switches). }
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

var
  trans_0: univ_ptr;                    { +0 }

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
