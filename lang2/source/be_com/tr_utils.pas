{ tr_utils - the PRISM back end's transformation utilities: the
  optimizer's (com, trans, iv) copy elimination, test elimination and
  autoincrement (autoindex) transformations over the LIR, and the live
  range merging and operand ordering they share.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x27C18C  utils_ins_$operands_instruction (utils.ins.pas)
    A5 0x492F80: the module's data (0x24 bytes): the complex lifetime
    segments' heap (20 bytes at +0, "TR_UTILS find complex heap"), the
    routine being transformed (+20, set by the attempt_ entries), +24,
    +28 and +32 (below).

  Not known from the original: every local and parameter name, the
  module cells' names. }
module tr_utils;

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

type
  { What a validator gives back with a solution (two longwords). }
  tr_pair_t = record
    a: univ_ptr;
    b: univ_ptr;
  end;

  { A block of solutions (248 bytes, the heap's default size): chained
    from the newest, 20 entries of a pair and the block it was found
    in. }
  tr_sol_ptr_t = ^tr_sol_t;
  tr_sol_t = record
    next: tr_sol_ptr_t;                 { +0 }
    count: integer32;                   { +4 }
    entries: array [1..20] of record    { +8 }
      a: univ_ptr;
      b: univ_ptr;
      bb: bb_ptr_t;
      end;
  end;

  { A validator find_complex_driving_ltss calls (`jsr (A0)'): 0 no, 1
    yes (and a pair). }
  tr_valid_t = ^function(
      lts: lts_ptr_t;
      bb: bb_ptr_t;
      arg: univ_ptr;
      out pair: tr_pair_t): integer; options(val_param);

var
  tr_heap: mrh_$heap_t;                 { +0 }
  tr_rtn: rtn_ptr_t;                    { +20 }
  tr_24: bb_ptr_t;                      { +24: the start block's
                                          interval head }
  tr_28: bb_ptr_t;                      { +28: the start block }
  tr_32: boolean;                       { +32: a solution found }

{ tr_utils_$begin_compilation - the complex segments' heap set up (flags
  0, default size 248: `pea 0xF8', the two words in one longword).
  0x27C1AE, 0x24 bytes. }

procedure tr_utils_$begin_compilation;
begin
  mrh_$initialize(tr_heap, 0, 248, 'TR_UTILS find complex heap%');
end;

{ tr_utils_$init_for_routine - nothing.  0x27C1F0, 2 bytes. }

procedure tr_utils_$init_for_routine(
    rtn: rtn_ptr_t);
begin
end;

{ tr_utils_$end_routine - the heap released.  0x27C1F2, 0x1C bytes. }

procedure tr_utils_$end_routine(
    rtn: rtn_ptr_t);
begin
  mrh_$release_all(tr_heap);
end;

{ tr_utils_$end_compilation - nothing.  0x27C20E, 2 bytes. }

procedure tr_utils_$end_compilation;
begin
end;

{ index_operand - a load's or store's index operand: a load's (class
  16) operand 1, a store's (class 21) operand 2, else nil.

  0x27C210, 0x3A bytes, no frame: instr at (4,SP); the class at +7 of
  instruction_attributes (0x2B8C3C) by 20 times the opcode; A0. }

function index_operand(
    instr: instr_ptr_t): opnd_ptr_t; options(val_param); internal;
begin
  if instruction_attributes[instr^.opc].class = class$load then
    index_operand := addr(instr^.opnds[1])
  else if instruction_attributes[instr^.opc].class = class$store then
    index_operand := addr(instr^.opnds[2])
  else
    index_operand := nil;
end;

{ base_operand - a load's or store's base operand: a load's operand 2,
  a store's operand 3, else nil.  0x27C24A, 0x3A bytes, no frame. }

function base_operand(
    instr: instr_ptr_t): opnd_ptr_t; options(val_param); internal;
begin
  if instruction_attributes[instr^.opc].class = class$load then
    base_operand := addr(instr^.opnds[2])
  else if instruction_attributes[instr^.opc].class = class$store then
    base_operand := addr(instr^.opnds[3])
  else
    base_operand := nil;
end;

{ is_base_operand - whether o is instr's base operand (its number 2 in
  a load, 3 in a store).  0x27C284, 0x52 bytes: `seq'. }

function is_base_operand(
    instr: instr_ptr_t;
    o: opnd_ptr_t): boolean; options(val_param); internal;
begin
  if instruction_attributes[instr^.opc].class = class$load then
    is_base_operand := o^.h.num = 2
  else if instruction_attributes[instr^.opc].class = class$store then
    is_base_operand := o^.h.num = 3
  else
    is_base_operand := false;
end;

{ move_operand - src copied into dst (dst keeps its number); when src is
  a register or memory operand (kinds 1..11: `btst' in 4094), dst takes
  src's place in its segment's chain (the segment's def, +4, or the
  operand linked to src, +4); src then has no kind and no value.

  0x27C2D6, 0x80 bytes: the 12 bytes by three `move.l'; `andi.w #-32'
  of +2 (the kind, +3 bits 4..0); `move.l #0' of +8. }

procedure move_operand(
    src: opnd_ptr_t;
    dst: opnd_ptr_t); options(val_param); internal;
var
  num: integer32;
  o: opnd_ptr_t;
begin
  num := dst^.h.num;
  dst^ := src^;
  dst^.h.num := num;
  if src^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
    if src^.lts^.def = src then
      src^.lts^.def := dst
    else begin
      o := src^.lts^.def;
      while o^.link <> src do
        o := o^.link;
      o^.link := dst;
    end;
  end;
  src^.h.kind := operand$none;
  src^.value := 0;
end;

{ make_copy - dst made a copy of src: when src is a register or memory
  operand, a MOVE after src's instruction takes src over (its operand
  1, the instruction's +0 bit 6 set) and reads a new segment of a new
  integer register live range (lir_utils_$add_lts_to_lr with rrp
  24, write and read: its operand 2, rrp byte 8, kind 1), whose reader
  dst becomes (rrp byte 16, read; kind 1; tied to nothing; src's count,
  +2 bits 5..4, which src loses); then the copy eliminated
  (tr_utils_$attempt_copy_elimination); otherwise dst is src
  (move_operand).

  0x27C356, 0x112 bytes, internal (on its caller's A5: +20): src's
  instruction stored to a frame slot not read again; the MOVE's
  instruction from lir_$optimizer_new_instruction(instr, 75, true);
  lir_$new_live_range_ip_reg's call pops 6 of its 8 bytes and
  lir_utils_$add_lts_to_lr finds its bb and segment address among them
  (docs/rev889-patterns.md 63). }

procedure make_copy(
    src: opnd_ptr_t;
    dst: opnd_ptr_t); options(val_param); internal;
var
  instr: instr_ptr_t;
  mv: instr_ptr_t;
  count: integer32;
  lts: lts_ptr_t;
begin
  if src^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
    instr := utils_ins_$operands_instruction(src);
    mv := lir_$optimizer_new_instruction(instr, ord(opc$move), true);
    mv^.h.b0_6 := true;
    mv^.opnds[1].h.num := 1;
    count := src^.h.count;
    src^.h.count := 0;
    move_operand(src, addr(mv^.opnds[1]));
    lir_utils_$add_lts_to_lr(24, lir_$new_live_range_ip_reg, mv^.bb, lts);
    lts^.def := addr(mv^.opnds[2]);
    mv^.opnds[2].h.num := 2;
    opnd_bytes_ptr_t(addr(mv^.opnds[2]))^.rrp := 8;
    mv^.opnds[2].h.kind := operand$ip_reg;
    mv^.opnds[2].lts := lts;
    mv^.opnds[2].link := dst;
    opnd_bytes_ptr_t(dst)^.rrp := 16;
    dst^.h.kind := operand$ip_reg;
    dst^.lts := lts;
    dst^.link := nil;
    dst^.h.count := count;
    tr_utils_$attempt_copy_elimination(tr_rtn, mv);
  end
  else
    move_operand(src, dst);
end;

{ drop_operand_from_lts - o taken out of its segment's chain (the
  segment's def or the operand linked to o gets o's link), when o is a
  register or memory operand.  0x27C468, 0x4A bytes, no frame. }

procedure drop_operand_from_lts(
    o: opnd_ptr_t); options(val_param); internal;
var
  p: opnd_ptr_t;
begin
  if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
    if o^.lts^.def = o then
      o^.lts^.def := o^.link
    else begin
      p := o^.lts^.def;
      while p^.link <> o do
        p := p^.link;
      p^.link := o^.link;
    end;
  end;
end;

{ find_operand_of_kind - instr's first operand of the kind: for kind 0
  (none, a free slot) the first, given its number; for another kind the
  first whose rrp byte (+1) has a bit of mask; nil when none.

  0x27C4B2, 0x6C bytes: kind and mask words by value; `dbf' over
  nopnds with the number in D3. }

function find_operand_of_kind(
    instr: instr_ptr_t;
    kind: integer;
    mask: integer): opnd_ptr_t; options(val_param); internal;
var
  k: integer32;
  o: opnd_ptr_t;
begin
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if ord(o^.h.kind) = kind then begin
      if kind = 0 then begin
        o^.h.num := k;
        find_operand_of_kind := o;
        return;
      end;
      if (opnd_bytes_ptr_t(o)^.rrp & mask) <> 0 then begin
        find_operand_of_kind := o;
        return;
      end;
    end;
  end;
  find_operand_of_kind := nil;
end;

{ tr_utils_$relative_instr_position - how many instructions b is after
  a in their block (negative when before, 0 when the same): searched
  first along next (when a's number, +42, is below b's) or prev, then
  the other way; bug_check when b is found neither way.

  0x27C51E, 0x1BC bytes: the direction a word (`bcc' of the numbers),
  the two passes by `dbf'; the message's text is the image's (its
  "position: i" is missing). }

function tr_utils_$relative_instr_position(
    a: instr_ptr_t;
    b: instr_ptr_t): integer32;
var
  backward: boolean;
  pass: integer32;
  p: instr_ptr_t;
  n: integer32;
begin
  if a = b then begin
    tr_utils_$relative_instr_position := 0;
    return;
  end;
  backward := a^.num >= b^.num;
  for pass := 1 to 2 do begin
    if not backward then begin
      p := a^.next;
      if p = nil then
        n := 0
      else begin
        n := 1;
        while p <> b do begin
          p := p^.next;
          n := n + 1;
          if p = nil then begin
            n := 0;
            exit;
          end;
        end;
      end;
    end
    else begin
      p := a^.prev;
      if p = nil then
        n := 0
      else begin
        n := -1;
        while p <> b do begin
          p := p^.prev;
          n := n - 1;
          if p = nil then begin
            n := 0;
            exit;
          end;
        end;
      end;
    end;
    if n <> 0 then
      exit;
    backward := not backward;
  end;
  if n = 0 then
    bug_check('TR_UTILS_$relative_instr_positnstrs not in same bb%$');
  tr_utils_$relative_instr_position := n;
end;

{ tr_utils_$guarantee_operand_order - a segment's readers (its def's
  chain along link, after the def when the def writes or modifies:
  rrp byte bits 3..2) put in the order of their instructions (an
  insertion sort by tr_utils_$relative_instr_position).

  0x27C614, 0xDC bytes, no A5: the first reader in D3, the operand
  before it (nil for the def) in D4. }

procedure tr_utils_$guarantee_operand_order(
    lts: lts_ptr_t); options(val_param); internal;
var
  o, first, before, m, p, prev: opnd_ptr_t;
  i1, i2: instr_ptr_t;
begin
  if lts^.def = nil then
    return;
  o := lts^.def;
  if (opnd_bytes_ptr_t(o)^.rrp & 12) = 0 then begin
    first := o;
    before := nil;
  end
  else begin
    before := o;
    o := o^.link;
    first := o;
    if o = nil then
      return;
  end;
  while o^.link <> nil do begin
    p := o^.link;
    i1 := utils_ins_$operands_instruction(o);
    i2 := utils_ins_$operands_instruction(o^.link);
    if tr_utils_$relative_instr_position(i1, i2) < 0 then begin
      m := o^.link;
      o^.link := m^.link;
      p := first;
      prev := before;
      i1 := utils_ins_$operands_instruction(m);
      while tr_utils_$relative_instr_position(
                utils_ins_$operands_instruction(p), i1) > 0 do begin
        prev := p;
        p := p^.link;
      end;
      m^.link := p;
      if p = first then
        first := m;
      if prev = nil then
        lts^.def := m
      else
        prev^.link := m;
      p := o;
    end;
    o := p;
  end;
end;

{ tr_utils_$mark_dependents - the instructions from instr to last (to
  the block's end when last is nil) that depend on instr marked with
  mark (+16): all of them when instr has a physical register operand
  (kinds 4..6) or a register whose live range's +3 bit 7 is set;
  otherwise each branch, jump or return (classes 1, 5, 6, 24), each
  already marked, each with its +3 bit 5 set, each call or svc (classes
  2, 20) with +3 bit 3 set, and each instruction that reads a live range
  marked so far (+3 bit 2 of a marked instruction's written live
  ranges) or writes one it wrote (the live ranges' +40 set to a serial
  number, the routine's +180 counted up): the condition codes an
  instruction writes mark their readers' instructions instead.  The
  live ranges' marks (+3 bit 2, chained at +52) cleared at the end.

  0x27C6F0, 0x240 bytes, no A5 (its callers': +20): instr's +16 set
  first; the sets 112, 126, 0x1000062, 0x100004, 4094, 384 by `btst';
  the marked live range stored to a frame slot not read again. }

procedure tr_utils_$mark_dependents(
    instr: instr_ptr_t;
    last: instr_ptr_t;
    mark: integer32); options(val_param); internal;
var
  serial: integer32;
  marked: lr_ptr_t;
  p, stop: instr_ptr_t;
  k: integer32;
  o: opnd_ptr_t;
  cls: integer;
  found: boolean;
  lr, unused: lr_ptr_t;
  r: opnd_ptr_t;
begin
  instr^.l16 := mark;
  tr_rtn^.l180 := tr_rtn^.l180 + 1;
  serial := tr_rtn^.l180;
  marked := nil;
  p := instr;
  if last = nil then
    stop := nil
  else
    stop := last^.next;
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if (o^.h.kind in [operand$ip_reg_physical..operand$fp_reg_pair_physical])
       or ((o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
           and o^.lts^.lr^.f2.b3_7) then begin
      while p <> stop do begin
        p^.l16 := mark;
        p := p^.next;
      end;
      return;
    end;
  end;
  while p <> stop do begin
    cls := instruction_attributes[p^.opc].class;
    if (cls in [class$branch, class$fp_branch, class$jump, class$return])
       or ((p^.h.width & 16#20) <> 0) or (p^.l16 = mark)
       or ((cls in [class$call, class$svc]) and ((p^.h.width & 8) <> 0)) then
      found := true
    else begin
      found := false;
      for k := 1 to p^.h.nopnds do begin
        o := addr(p^.opnds[k]);
        if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
          if o^.h.read and o^.lts^.lr^.f2.b3_2 then begin
            found := true;
            exit;
          end;
          if ((opnd_bytes_ptr_t(o)^.rrp & 12) <> 0)
             and (o^.lts^.lr^.l40 = serial) then begin
            found := true;
            exit;
          end;
        end;
      end;
    end;
    if found then begin
      p^.l16 := mark;
      for k := 1 to p^.h.nopnds do begin
        o := addr(p^.opnds[k]);
        if o^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then begin
          if not (o^.h.kind in [operand$ip_condition_codes,
                                operand$fp_condition_codes]) then
            o^.lts^.lr^.l40 := serial;
          if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
            if o^.h.kind in [operand$ip_condition_codes,
                             operand$fp_condition_codes] then begin
              r := o^.link;
              if r <> nil then
                repeat
                  utils_ins_$operands_instruction(r)^.l16 := mark;
                  r := r^.link;
                until r = nil;
            end
            else begin
              lr := o^.lts^.lr;
              if not lr^.f2.b3_2 then begin
                unused := lr;
                lr^.f2.b3_2 := true;
                lr^.l52 := marked;
                marked := lr;
              end;
            end;
          end;
        end;
      end;
    end;
    p := p^.next;
  end;
  lr := marked;
  while lr <> nil do begin
    lr^.f2.b3_2 := false;
    lr := lr^.l52;
  end;
end;

{ tr_utils_$separate_partitions - the instructions after instr up to
  last (to the block's end when last is nil) that instr's mark (+16)
  does not mark moved before instr, the ones it marks left after it:
  a moved instruction's written segments of a live range that a marked
  instruction writes (the live range's +3 bit 2) are moved in their
  live range's list to after the segments the marked instructions
  write (the segments' +3 bit 2), and the block's last segment of the
  live range (utils_$find_last_lts_in_bb) takes over +3 bit 6; a moved
  segment that is on its block's final list (+3 bit 4) is a bug.  The
  marks cleared at the end.

  0x27C930, 0x230 bytes, no A5: the marked live ranges chained at +52
  from D6; the message's text is the image's. }

procedure tr_utils_$separate_partitions(
    instr: instr_ptr_t;
    last: instr_ptr_t); options(val_param); internal;
var
  marked: lr_ptr_t;
  mark: integer32;
  p, stop, nxt: instr_ptr_t;
  k: integer32;
  o: opnd_ptr_t;
  prev: lts_ptr_t;
  l: lts_ptr_t;
  q: lts_ptr_t;
  lr: lr_ptr_t;
begin
  marked := nil;
  mark := instr^.l16;
  p := instr^.next;
  if last = nil then
    stop := nil
  else
    stop := last^.next;
  while p <> stop do begin
    nxt := p^.next;
    if p^.l16 <> mark then begin
      p^.prev^.next := p^.next;
      if p^.next <> nil then
        p^.next^.prev := p^.prev
      else
        p^.bb^.last := p^.prev;
      p^.prev := instr^.prev;
      if p^.prev <> nil then
        p^.prev^.next := p
      else
        p^.bb^.first := p;
      p^.next := instr;
      instr^.prev := p;
      for k := 1 to p^.h.nopnds do begin
        o := addr(p^.opnds[k]);
        if (o^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
           and ((opnd_bytes_ptr_t(o)^.rrp & 12) <> 0)
           and o^.lts^.lr^.f2.b3_2 then begin
          if o^.lts^.f2.b3_4 then
            bug_check('TR_UTILS_$separate_partis: LTS was aon exit%$');
          l := utils_$find_last_lts_in_bb(o^.lts^.lr, p^.bb, prev);
          o^.lts^.f2.b3_6 := false;
          l^.f2.b3_6 := true;
          while l <> o^.lts do begin
            prev := l;
            l := l^.next;
          end;
          if prev = nil then
            l^.lr^.ltss := l^.next
          else
            prev^.next := l^.next;
          l := l^.next;
          while l^.next <> nil do begin
            if not l^.next^.f2.b3_2 then
              exit;
            l := l^.next;
          end;
          o^.lts^.next := l^.next;
          l^.next := o^.lts;
        end;
      end;
    end
    else
      for k := 1 to p^.h.nopnds do begin
        o := addr(p^.opnds[k]);
        if (o^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
           and ((opnd_bytes_ptr_t(o)^.rrp & 12) <> 0) then begin
          o^.lts^.f2.b3_2 := true;
          lr := o^.lts^.lr;
          if not lr^.f2.b3_2 then begin
            lr^.f2.b3_2 := true;
            lr^.l52 := marked;
            marked := lr;
          end;
        end;
      end;
    p := nxt;
  end;
  lr := marked;
  while lr <> nil do begin
    lr^.f2.b3_2 := false;
    q := lr^.ltss;
    while q <> nil do begin
      q^.f2.b3_2 := false;
      q := q^.next;
    end;
    lr := lr^.l52;
  end;
end;

{ maintain_complex_props - a segment merged into lr: when it writes or
  modifies (rrp bits 3..2) and set_bits, lr's bit (its number, +4, when
  not 0) set in its block's +110; when on the exposed list (+3 bit 7),
  put on it again (the bit cleared first) and, when set_bits, lr's bit
  set in the block's +94 and +90; chained after final (+44, +28) when
  there is one; when on the final list (+3 bit 4), put on it again and,
  when set_bits, lr's bit set in +86.

  0x27CB98, 0xC6 bytes, no A5: the first test `sne; and.b' (both
  evaluated); `move.l A3,(44,A2)' tested again (`beq'). }

procedure maintain_complex_props(
    lts: lts_ptr_t;
    lr: lr_ptr_t;
    final: lts_ptr_t;
    set_bits: boolean); options(val_param); internal;
begin
  if ((lts^.rrp * [rrp$modify, rrp$write]) <> []) and set_bits then
    if lr^.w4 <> 0 then
      bv_$set(lts^.bb^.l110, lr);
  if lts^.f2.b3_7 then begin
    lts^.f2.b3_7 := false;
    utils_$put_lts_on_exposed_list(lts);
    if set_bits then begin
      bv_$set(lts^.bb^.l94, lr);
      bv_$set(lts^.bb^.l90, lr);
    end;
  end;
  if final <> nil then begin
    lts^.l44 := final;
    lts^.l28 := final^.l28;
    final^.l28 := lts;
  end;
  if lts^.f2.b3_4 then begin
    lts^.f2.b3_4 := false;
    utils_$put_lts_on_final_list(lts);
    if set_bits then
      bv_$set(lts^.bb^.l86, lr);
  end;
end;

{ tr_utils_$merge_lrs - src's segments merged into lr's list, which
  both keep in their blocks' order (the blocks' +12): a segment of the
  block lr's current segment is in, when that one was not passed, gives
  its operands to lr's segment (each operand's segment; its readers,
  after the def when it writes or modifies, chained after lr's
  segment's readers) and is dropped (its block's +86 gets lr's bit when
  set_bits, lr has a number and the segment was final); one of an
  earlier block is linked in before lr's (maintain_complex_props) and
  the rest appended.  Then lr's segments numbered (+2) and counted
  (+56), the first of each block marked (+3 bit 6) when lr has a
  number; src left without segments (+36, +72, +76 cleared); when
  with_mates and src has a mate (+16), the mates merged too (lr must
  have one: bug_check), unless src's mate has no segments.  bb, when
  not nil, is where the final segment (utils_$find_final_lts) must be
  found.

  0x27CC5E, 0x23A bytes: the link to lr's current segment kept by
  address (-16; first lr's +36, then a segment's +8); the blocks'
  numbers compared as longwords from `clr.l; move.w'. }

procedure tr_utils_$merge_lrs(
    lr: lr_ptr_t;
    src: lr_ptr_t;
    bb: bb_ptr_t;
    with_mates: boolean;
    set_bits: boolean);
type
  lts_ptr_ptr_t = ^lts_ptr_t;
var
  tail: lts_ptr_ptr_t;
  final: lts_ptr_t;
  passed: boolean;
  l, nxt: lts_ptr_t;
  o: opnd_ptr_t;
  readers: opnd_ptr_t;
  n0, n1: integer32;
  numbered: boolean;
  prev_bb: bb_ptr_t;
  count: integer32;
begin
  tail := addr(lr^.ltss);
  if bb = nil then
    final := nil
  else begin
    final := utils_$find_final_lts(lr, bb);
    if final = nil then
      bug_check('TR_UTILS_$merge_lrs:  can''t find birthpoint LTS%$');
  end;
  passed := false;
  l := src^.ltss;
  while (tail^ <> nil) and (l <> nil) do begin
    l^.lr := lr;
    n0 := tail^^.bb^.w12;
    if not passed and (l^.bb^.w12 = n0) then begin
      o := l^.def;
      if o <> nil then begin
        if set_bits and (lr^.w4 <> 0) and l^.f2.b3_4 then
          bv_$set(l^.bb^.l86, lr);
        repeat
          o^.lts := tail^;
          if o^.link = nil then
            exit;
          o := o^.link;
        until o = nil;
        if (l^.rrp * [rrp$modify, rrp$write]) <> [] then
          readers := l^.def^.link
        else
          readers := l^.def;
        if readers <> nil then begin
          if (tail^^.rrp * [rrp$modify, rrp$write]) <> [] then begin
            o^.link := tail^^.def^.link;
            tail^^.def^.link := readers;
          end
          else begin
            o^.link := tail^^.def;
            tail^^.def := readers;
          end;
        end;
      end;
      nxt := l^.next;
    end
    else begin
      n1 := l^.bb^.w12;
      if n1 >= n0 then begin
        tail := addr(tail^^.next);
        nxt := l;
        passed := n1 = n0;
      end
      else begin
        nxt := l^.next;
        l^.next := tail^;
        tail^ := l;
        maintain_complex_props(l, lr, final, set_bits);
        passed := true;
      end;
    end;
    l := nxt;
  end;
  if (l <> nil) and (tail <> nil) then begin
    tail^ := l;
    while l <> nil do begin
      l^.lr := lr;
      maintain_complex_props(l, lr, final, set_bits);
      l := l^.next;
    end;
  end;
  numbered := lr^.w4 <> 0;
  prev_bb := nil;
  l := lr^.ltss;
  count := 0;
  while l <> nil do begin
    count := count + 1;
    l^.f2.b2 := count;
    if numbered and (prev_bb <> l^.bb) then
      l^.f2.b3_6 := true;
    prev_bb := l^.bb;
    l := l^.next;
  end;
  lr^.w56 := count;
  src^.ltss := nil;
  src^.l72 := 0;
  src^.l76 := 0;
  if with_mates and (src^.l16 <> nil) then begin
    if lr^.l16 = nil then
      bug_check('TR_UTILS_$merge_lrs:  incompatible mates%$');
    if src^.l16^.ltss <> nil then
      tr_utils_$merge_lrs(lr^.l16, src^.l16, bb, false, false);
  end;
end;

{ write_cc_or_delete_instr - a copy whose result was taken over: when
  it sets the condition codes (+0 bit 4 or bit 3), its operand 2 gets a
  new segment (rrp 8) of a new live range of its kind (and operand 4
  one of the new live range's mate, when it has one); otherwise the
  instruction excised.

  0x27CEF4, 0xA8 bytes, no A5: the kind a word (+59 bits 4..0) pushed
  after a pad; utils_$excise_instruction_cleanly's result dropped. }

procedure write_cc_or_delete_instr(
    instr: instr_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  lts: lts_ptr_t;
begin
  if instr^.h.sets_cc or instr^.h.b0_3 then begin
    lr := lir_$new_live_range_for_kind(ord(instr^.opnds[2].h.kind));
    lir_utils_$add_lts_to_lr(8, lr, instr^.bb, lts);
    instr^.opnds[2].lts := lts;
    lts^.def := addr(instr^.opnds[2]);
    instr^.opnds[2].link := nil;
    if lr^.l16 <> nil then begin
      lir_utils_$add_lts_to_lr(8, lr^.l16, instr^.bb, lts);
      instr^.opnds[4].lts := lts;
      lts^.def := addr(instr^.opnds[4]);
      instr^.opnds[4].link := nil;
    end;
  end
  else
    discard(utils_$excise_instruction_cleanly(instr, true));
end;

{ simple_ends_before_next_complex - whether the last reader of simple
  (after its readers are put in order) is not before the def of the
  segment before complex in complex's live range (from the last of
  complex's live range in its block, utils_$find_last_lts_in_bb); true
  when complex is that last one (it gets +3 bit 6).

  0x27CF9C, 0x90 bytes, no A5: the predecessor searched from the last
  segment along +8; `bpl' of the position. }

function simple_ends_before_next_complex(
    simple: lts_ptr_t;
    complex: lts_ptr_t): boolean; options(val_param); internal;
var
  prev: lts_ptr_t;
  l: lts_ptr_t;
  o: opnd_ptr_t;
begin
  l := utils_$find_last_lts_in_bb(complex^.lr, complex^.bb, prev);
  if l = complex then begin
    complex^.f2.b3_6 := true;
    simple_ends_before_next_complex := true;
    return;
  end;
  while l^.next <> complex do
    l := l^.next;
  tr_utils_$guarantee_operand_order(simple);
  o := simple^.def;
  while o^.link <> nil do
    o := o^.link;
  if tr_utils_$relative_instr_position(utils_ins_$operands_instruction(o),
       utils_ins_$operands_instruction(l^.def)) < 0 then
    simple_ends_before_next_complex := false
  else
    simple_ends_before_next_complex := true;
end;

{ copy$simple_dest - a copy eliminated whose destination's live range
  is simple: nothing when a register operand's live range is pinned (+3
  bit 7), when a segment that is not its live range's first in the
  block (+3 bit 6 clear) is not the live range's segment in the
  instruction's block (a live range without a number) or does not end
  before the next (simple_ends_before_next_complex, with the operand
  after it), or when the written operand has no reader, or its one
  reader is a copy's (+0 bit 6) and the operand before is a register or
  memory operand whose segment means to modify (rrp element 5) or whose
  live range has a number, and the reader's live range is pinned.
  Otherwise each written register operand's readers move to the
  segment of the operand before it (their rrp bits or-ed into the
  segment's, the chain appended to its readers, the live range's rrp
  or-ed, its +20 copied when unset and both live ranges have a mate or
  neither has), its segment excised, the readers put in order; when the
  last reader's instruction has a later operand writing the same live
  range, the reader means to modify (+1 bit 5, and its segment's), the
  later operand modifies instead of writing (its rrp and its segment's)
  and the live range gets modify and intend_to_modify (36).  Last
  write_cc_or_delete_instr.

  0x27D02C, 0x29E bytes, no A5: the operands before and after operand k
  reached as (0x17,A0,D3.l), (0x1C,..), (0x34,..) with D3 12k (k - 1
  and k + 1); the set 126 (kinds 1..6) and 4094 by `btst'. }

procedure copy$simple_dest(
    instr: instr_ptr_t); options(val_param); internal;
var
  k, j: integer32;
  o, r, o3: opnd_ptr_t;
  lts, src: lts_ptr_t;
  lr: lr_ptr_t;
  l: lts_ptr_t;
  i: instr_ptr_t;
begin
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
      lts := o^.lts;
      lr := lts^.lr;
      if lr^.f2.b3_7 then
        return;
      if not lts^.f2.b3_6 and (lr^.ltss <> lts) then begin
        if lr^.w4 = 0 then begin
          l := lr^.ltss;
          while l^.bb <> instr^.bb do
            l := l^.next;
          if l <> o^.lts then
            return;
        end
        else if not simple_ends_before_next_complex(instr^.opnds[k + 1].lts,
                                                    lts) then
          return;
      end;
      if o^.h.write then begin
        if o^.link = nil then
          return;
        i := utils_ins_$operands_instruction(o^.link);
        if (o^.link^.link = nil) and i^.h.b0_6
           and (instr^.opnds[k - 1].h.kind
                in [operand$ip_reg..operand$well_behaved_memory])
           and ((rrp$intend_to_modify in instr^.opnds[k - 1].lts^.rrp)
                or (instr^.opnds[k - 1].lts^.lr^.w4 <> 0)) then begin
          o3 := addr(i^.opnds[o^.link^.h.num]);
          if o3^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
            if o3^.lts^.lr^.f2.b3_7 then
              return;
        end;
      end;
    end;
  end;
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if (o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
       and o^.h.write then begin
      src := instr^.opnds[k - 1].lts;
      r := o;
      repeat
        r := r^.link;
        r^.lts := src;
        src^.rrp := rrp$set_t(integer(src^.rrp) ! opnd_bytes_ptr_t(r)^.rrp);
      until r^.link = nil;
      r^.link := instr^.opnds[k - 1].link;
      instr^.opnds[k - 1].link := o^.link;
      lr := src^.lr;
      lr^.rrp := lr^.rrp + src^.rrp;
      if lr^.l20 = 0 then
        if (lr^.l16 = nil) = (o^.lts^.lr^.l16 = nil) then
          lr^.l20 := o^.lts^.lr^.l20;
      utils_$excise_lts_cleanly(o^.lts, true);
      tr_utils_$guarantee_operand_order(src);
      r := src^.def;
      while r^.link <> nil do
        r := r^.link;
      i := utils_ins_$operands_instruction(r);
      for j := r^.h.num + 1 to i^.h.nopnds do begin
        o3 := addr(i^.opnds[j]);
        if (o3^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
           and ((opnd_bytes_ptr_t(o3)^.rrp & 12) <> 0)
           and (o3^.lts^.lr = lr) then begin
          r^.h.intend_to_modify := true;
          r^.lts^.rrp := r^.lts^.rrp + [rrp$intend_to_modify];
          o3^.h.write := false;
          o3^.h.modify := true;
          o3^.lts^.rrp := o3^.lts^.rrp - [rrp$write] + [rrp$modify];
          lr^.rrp := lr^.rrp + [rrp$modify, rrp$intend_to_modify];
          exit;
        end;
      end;
    end;
  end;
  write_cc_or_delete_instr(instr);
end;

{ copy$simple_complex - a copy eliminated whose source's live range is
  simple and destination's complex: nothing when a read register
  operand's live range or the next operand's is pinned (+3 bit 7), its
  segment modifies or means to (rrp 36) or does not write (rrp element
  3), the next operand's segment's successor in the same block has a
  last reader that writes or modifies or comes before the read
  segment's def, or the read segment does not end before the next
  (simple_ends_before_next_complex).  Otherwise each written register
  operand's segment takes over the operand before it's def and readers
  (its rrp bits or-ed in, the chain ended with the operand's own
  readers), the live range's rrp or-ed; when an earlier operand of the
  def's instruction reads the same live range, it means to modify (and
  its segment), and the def modifies instead of writing (and the
  segment); the old segment, its def cleared, excised.  Last
  write_cc_or_delete_instr.

  0x27D2CA, 0x276 bytes, no A5: the earlier operands from the def's
  number - 1 down (`subi.l #12'). }

procedure copy$simple_complex(
    instr: instr_ptr_t); options(val_param); internal;
var
  k, j: integer32;
  o, o2, r, o3: opnd_ptr_t;
  lts, nxt, src: lts_ptr_t;
  i: instr_ptr_t;
  lr: lr_ptr_t;
begin
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if (o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
       and o^.h.read then begin
      lts := o^.lts;
      if lts^.lr^.f2.b3_7 then
        return;
      nxt := instr^.opnds[k + 1].lts;
      if nxt^.lr^.f2.b3_7 then
        return;
      if (lts^.rrp * [rrp$modify, rrp$intend_to_modify]) <> [] then
        return;
      if not (rrp$write in lts^.rrp) then
        return;
      if nxt^.next <> nil then
        if nxt^.next^.bb = instr^.bb then begin
          tr_utils_$guarantee_operand_order(nxt^.next);
          r := instr^.opnds[k + 1].lts^.next^.def;
          if r <> nil then begin
            while r^.link <> nil do
              r := r^.link;
            tr_utils_$guarantee_operand_order(o^.lts);
            if (opnd_bytes_ptr_t(r)^.rrp & 12) <> 0 then
              return;
            if tr_utils_$relative_instr_position(
                   utils_ins_$operands_instruction(r),
                   utils_ins_$operands_instruction(o^.lts^.def)) < 0 then
              return;
          end;
        end;
      if not simple_ends_before_next_complex(o^.lts,
                                             instr^.opnds[k + 1].lts) then
        return;
    end;
  end;
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if (o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
       and o^.h.write then begin
      src := instr^.opnds[k - 1].lts;
      r := src^.def;
      o^.lts^.def := r;
      i := utils_ins_$operands_instruction(r);
      lr := o^.lts^.lr;
      for j := r^.h.num - 1 downto 1 do begin
        o3 := addr(i^.opnds[j]);
        if (o3^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical])
           and o3^.h.read and (o3^.lts^.lr = lr) then begin
          o3^.h.intend_to_modify := true;
          o3^.lts^.rrp := o3^.lts^.rrp + [rrp$intend_to_modify];
          r^.h.write := false;
          r^.h.modify := true;
          o^.lts^.rrp := o^.lts^.rrp - [rrp$write] + [rrp$modify];
          lr^.rrp := lr^.rrp + [rrp$modify, rrp$intend_to_modify];
          exit;
        end;
      end;
      repeat
        r^.lts := o^.lts;
        o^.lts^.rrp := rrp$set_t(integer(o^.lts^.rrp)
                                 ! opnd_bytes_ptr_t(r)^.rrp);
        if r^.link = nil then
          exit;
        r := r^.link;
      until false;
      r^.link := o^.link;
      lr^.rrp := lr^.rrp + o^.lts^.rrp;
      src^.def := nil;
      utils_$excise_lts_cleanly(src, true);
    end;
  end;
  write_cc_or_delete_instr(instr);
end;

{ copy$complex_complex - a copy between two complex live ranges: the
  image jumps from the entry straight to the epilogue (`bra.w' over the
  rest), so it does nothing; the code it keeps checks each register
  operand's live range (not pinned, +3 bit 1 set) and segment (+3 bit
  6), then merges the source's live range into the destination's
  (tr_utils_$merge_lrs with the mates, without the bits; at the block
  of the final segment the destination's segment follows, +44, when it
  does not write or modify) and calls write_cc_or_delete_instr.

  0x27D540, 0xAE bytes, no A5: `bra.w 0x27D5DE' first; the loop's
  counter is never set up. }

procedure copy$complex_complex(
    instr: instr_ptr_t); options(val_param); internal;
var
  k: integer32;
  o: opnd_ptr_t;
  lts: lts_ptr_t;
  lr: lr_ptr_t;
  bb: bb_ptr_t;
begin
  return;
  for k := 1 to instr^.h.nopnds do begin
    o := addr(instr^.opnds[k]);
    if o^.h.kind in [operand$ip_reg..operand$fp_reg_pair_physical] then begin
      lts := o^.lts;
      lr := lts^.lr;
      if lr^.f2.b3_7 then
        return;
      if not lr^.f2.b3_1 then
        return;
      if not lts^.f2.b3_6 then
        return;
    end;
  end;
  lts := instr^.opnds[1].lts;
  if ((lts^.rrp * [rrp$modify, rrp$write]) = []) and (lts^.l44 <> nil) then
    bb := lts^.l44^.bb
  else
    bb := nil;
  tr_utils_$merge_lrs(lts^.lr, instr^.opnds[2].lts^.lr, bb, true, false);
  write_cc_or_delete_instr(instr);
end;

{ tr_utils_$attempt_copy_elimination - instr, a copy (its opcode's
  b6_0) that does not set the condition codes (+0 bits 4, 3) between
  two register operands (kinds 1..6), eliminated: unless the opcode's
  +19 bits 2..0 are 3, neither live range may have a mate (+16); by
  whether the live ranges are simple (no number, +4): both or the
  source (operand 2) simple, copy$simple_dest; the destination simple,
  copy$simple_complex; neither, copy$complex_complex.

  0x27D5EE, 0xD0 bytes: rtn stored at +20 first; the opcode's
  attributes at 0x2B8C3C + 20 opc (+6 bit 0, +19). }

procedure tr_utils_$attempt_copy_elimination(
    rtn: rtn_ptr_t;
    instr: instr_ptr_t);
begin
  tr_rtn := rtn;
  if instruction_attributes[instr^.opc].b6_0 and not instr^.h.sets_cc
     and not instr^.h.b0_3
     and (instr^.opnds[1].h.kind
          in [operand$ip_reg..operand$fp_reg_pair_physical])
     and (instr^.opnds[2].h.kind
          in [operand$ip_reg..operand$fp_reg_pair_physical]) then begin
    if (instruction_attributes[instr^.opc].w18 & 7) <> 3 then begin
      if instr^.opnds[1].lts^.lr^.l16 <> nil then
        return;
      if instr^.opnds[2].lts^.lr^.l16 <> nil then
        return;
    end;
    if instr^.opnds[1].lts^.lr^.w4 = 0 then begin
      if instr^.opnds[2].lts^.lr^.w4 = 0 then
        copy$simple_dest(instr)
      else
        copy$simple_complex(instr);
    end
    else if instr^.opnds[2].lts^.lr^.w4 = 0 then
      copy$simple_dest(instr)
    else
      copy$complex_complex(instr);
  end;
end;

{ add_solution - a solution (a, b, bb) appended to the list: a new
  block of 20 (248 bytes, the heap's default size) put first when the
  first is full or there is none.

  0x27D6BE, 0x7E bytes, no A5 (its caller's: the heap at +0): the
  entries 12 bytes from +8, indexed by the count's low word. }

procedure add_solution(
    var sols: tr_sol_ptr_t;
    a: univ_ptr;
    b: univ_ptr;
    bb: bb_ptr_t); options(val_param); internal;
var
  s: tr_sol_ptr_t;
begin
  if (sols = nil) or (sols^.count = 20) then begin
    s := mrh_$alloc_fixed(tr_heap);
    s^.next := sols;
    s^.count := 0;
    sols := s;
  end;
  sols^.count := sols^.count + 1;
  sols^.entries[sols^.count].a := a;
  sols^.entries[sols^.count].b := b;
  sols^.entries[sols^.count].bb := bb;
end;

{ just_join_bp - whether lts is defined by a join birthpoint only: its
  def (+4) has no reader linked, modifies (+1 bit 2) and is a
  JOIN_BP's (203).  0x27D73C, 0x3C bytes, no A5: `seq'. }

function just_join_bp(
    lts: lts_ptr_t): boolean; options(val_param); internal;
begin
  if lts^.def <> nil then
    if (lts^.def^.link = nil) and lts^.def^.h.modify then begin
      just_join_bp :=
        utils_ins_$operands_instruction(lts^.def)^.opc = ord(opc$join_bp);
      return;
    end;
  just_join_bp := false;
end;

{ bb_interval - the head of bb's interval: bb itself when it is one (+18
  bit 6), else its +70.  0x27D778, 0x12 bytes, no frame. }

function bb_interval(
    bb: bb_ptr_t): bb_ptr_t; options(val_param); internal;
begin
  if bb^.f.b18_6 then
    bb_interval := bb
  else
    bb_interval := bb^.l70;
end;

{ find_complex_driving_ltss - whether every path into bb (backward over
  the edges in, +26) reaches a segment of lr1 that valid accepts (each
  one a solution: add_solution, and +32 set), or one of lr2 defined by
  a join birthpoint only, from which ok accepts the edge's source.
  Called first with start (lr2's segment; then the search starts at its
  block: +28 the start block, +24 its interval, the visit marks two up
  from the routine's +180 into serial, lr1's lifetime computed), then
  for each block reached (start nil).  A block's mark (+146): serial
  when done (true), serial - 1 while being searched (a loop: true
  unless the interval's head, or the routine when there is none, says
  otherwise: +18 bit 5, +228 bit 2); the start block reached again, or
  one that is not +20 bit 3, fails.  Both live ranges must have
  numbers.

  0x27D78A, 0x25E bytes, no A5 (its callers'): valid and ok are
  routines passed by address and called with `jsr (A0)' (a word
  result: 0 no, 1 yes, else bug_check); a start whose def is nil
  returns with D0 unset; `sne; not.b; and.b' for the last test. }

function find_complex_driving_ltss(
    start: lts_ptr_t;
    lr1: lr_ptr_t;
    lr2: lr_ptr_t;
    bb: bb_ptr_t;
    valid: tr_valid_t;
    ok: tr_valid_t;
    var serial: integer32;
    arg: univ_ptr;
    var sols: tr_sol_ptr_t): boolean; options(val_param); internal;
var
  m: integer32;
  l: lts_ptr_t;
  r: integer;
  pair: tr_pair_t;
  e: bb_edge_ptr_t;
  prev: lts_ptr_t;
  yes: boolean;
begin
  if (lr1^.w4 = 0) or (lr2^.w4 = 0) then begin
    find_complex_driving_ltss := false;
    return;
  end;
  if start <> nil then begin
    if start^.def = nil then
      return;
    if not start^.f2.b3_7 then
      if utils_ins_$operands_instruction(start^.def)^.opc
         <> ord(opc$join_bp) then begin
        find_complex_driving_ltss := false;
        return;
      end;
    tr_28 := bb;
    tr_24 := bb_interval(bb);
    tr_rtn^.l180 := tr_rtn^.l180 + 2;
    serial := tr_rtn^.l180;
    fg_utils_$compute_lr_lifetime(lr1);
  end
  else begin
    if bb^.l146 = serial then begin
      find_complex_driving_ltss := true;
      return;
    end;
    m := serial - 1;
    if m = bb^.l146 then begin
      if bb_interval(bb) = nil then
        find_complex_driving_ltss := not tr_rtn^.f228.b228_2
      else
        find_complex_driving_ltss := not bb_interval(bb)^.f.b18_5;
      return;
    end;
    bb^.l146 := m;
    if (bb = tr_28) or not bb^.f20.b20_3 then begin
      find_complex_driving_ltss := false;
      return;
    end;
    l := utils_$find_final_lts(lr1, bb);
    if l <> nil then
      if l^.def <> nil then
        if not just_join_bp(l) then begin
          if lr1 = lr2 then
            if bb_interval(bb) <> tr_24 then begin
              find_complex_driving_ltss := false;
              return;
            end;
          r := valid^(l, bb, arg, pair);
          if r = 0 then begin
            find_complex_driving_ltss := false;
            return;
          end;
          if r = 1 then begin
            add_solution(sols, pair.a, pair.b, bb);
            tr_32 := true;
            bb^.l146 := serial;
            find_complex_driving_ltss := true;
            return;
          end;
          bug_check('TR_UTILS_$find_complex_driving_ltss:  Huh?!?%$');
        end;
    start := utils_$find_last_lts_in_bb(lr2, bb, prev);
    if start <> nil then
      if (start^.def = nil) or (start^.def^.link <> nil)
         or (utils_ins_$operands_instruction(start^.def)^.opc
             <> ord(opc$join_bp)) then begin
        find_complex_driving_ltss := false;
        return;
      end;
  end;
  e := bb^.l26;
  if e = nil then begin
    find_complex_driving_ltss := false;
    return;
  end;
  repeat
    if start <> nil then
      tr_32 := false;
    if not find_complex_driving_ltss(nil, lr1, lr2, e^.source, valid, ok,
                                     serial, arg, sols) then begin
      if e^.source^.f.b16 >= bb^.f.b16 then begin
        find_complex_driving_ltss := false;
        return;
      end;
      if not ((start <> nil) and not tr_32) or not bb^.f20.b20_6 then begin
        find_complex_driving_ltss := false;
        return;
      end;
      yes := ok^(nil, e^.source, arg, pair) = 1;
      if not yes then begin
        find_complex_driving_ltss := false;
        return;
      end;
      add_solution(sols, nil, nil, e^.source);
      e^.source^.l146 := serial;
    end;
    e := e^.next_in;
  until e = nil;
  bb^.l146 := serial;
  find_complex_driving_ltss := true;
end;

{ solutions_dont_interfere - whether lr is not live (validate) from any
  block of the solutions (third fields) on: lr's lifetime computed, a
  new mark (the routine's +180 up one) put on bb; each solution's
  block is validated (unless already marked, when not all, and then the
  answer is no); then every solution's block marked and the mark
  stored in serial.  bb, the solutions and lr's number are checked
  (bug_check).

  0x27DA9C, 0xF8 bytes, no A5 (its callers'). }

function solutions_dont_interfere(
    sols: tr_sol_ptr_t;
    bb: bb_ptr_t;
    lr: lr_ptr_t;
    var serial: integer32;
    all: boolean): boolean; options(val_param); internal;
var
  m: integer32;
  s: tr_sol_ptr_t;
  k: integer32;
  b: bb_ptr_t;

  { validate - whether bb, unless it carries mark (then yes) or the old
    one (then no unless bb's +20 bit 6 is clear), and every block
    after it along the edges out (+22, the targets at +4 chained at
    +8) is free of lr: bb gets mark, or old - 1 when not all.

    0x27DA16, 0x86 bytes, nested (level 3), recursive; lr is passed on
    unread. }

  function validate(
      bb: bb_ptr_t;
      lr: lr_ptr_t;
      old: integer32;
      mark: integer32;
      all: boolean): boolean; options(val_param);
  var
    e: bb_edge_ptr_t;
  begin
    if bb^.l146 = mark then begin
      validate := true;
      return;
    end;
    if bb^.l146 <> old then begin
      validate := not bb^.f20.b20_6;
      return;
    end;
    if all then
      bb^.l146 := mark
    else
      bb^.l146 := old - 1;
    e := bb^.l22;
    while e <> nil do begin
      if not validate(e^.target, lr, old, mark, true) then begin
        validate := false;
        return;
      end;
      e := e^.next_out;
    end;
    validate := true;
  end;

begin
  if (bb = nil) or (sols = nil) or (lr^.w4 = 0) then
    bug_check('TR_UTILS_$solutions_dont_interfere:  invalid input.%$');
  fg_utils_$compute_lr_lifetime(lr);
  tr_rtn^.l180 := tr_rtn^.l180 + 1;
  m := tr_rtn^.l180;
  bb^.l146 := m;
  s := sols;
  while s <> nil do begin
    for k := 1 to s^.count do begin
      b := s^.entries[k].bb;
      if not all and (b^.l146 = m) then begin
        solutions_dont_interfere := false;
        return;
      end;
      if not validate(b, lr, serial, m, all) then begin
        solutions_dont_interfere := false;
        return;
      end;
    end;
    s := s^.next;
  end;
  s := sols;
  while s <> nil do begin
    for k := 1 to s^.count do
      s^.entries[k].bb^.l146 := m;
    s := s^.next;
  end;
  serial := m;
  solutions_dont_interfere := true;
end;

{ print_solutions_for_debugging - nothing (2 bytes).  0x27DBCA. }

procedure print_solutions_for_debugging(
    lts: lts_ptr_t;
    sols: tr_sol_ptr_t); options(val_param); internal;
begin
end;

{ convert_add_to_move - an ADD or SUB of an immediate made a MOVE: its
  operand 1 (the immediate, dropped from its segment when a register)
  replaced by operand 2, operand 2 by operand 3; with three operands the
  third emptied (num 0, no kind) and nopnds 2, with four the fourth
  (the condition codes) moved to the third (emptied when it has no
  kind) and nopnds 3; the instruction's +0 bit 6 set when operand 1 is
  a register (kinds 1..6: `sne; lsr.b #7; lsl.b #6').  The opcode MOVE
  (75).

  0x27DBCC, 0xD0 bytes, no A5. }

procedure convert_add_to_move(
    instr: instr_ptr_t); options(val_param); internal;
begin
  if instr^.opnds[1].h.kind
     in [operand$ip_reg..operand$well_behaved_memory] then
    drop_operand_from_lts(addr(instr^.opnds[1]));
  move_operand(addr(instr^.opnds[2]), addr(instr^.opnds[1]));
  move_operand(addr(instr^.opnds[3]), addr(instr^.opnds[2]));
  if instr^.h.nopnds = 3 then begin
    instr^.opnds[3].h.kind := operand$none;
    instr^.opnds[3].h.num := 0;
    instr^.h.b0_6 := instr^.opnds[1].h.kind
                     in [operand$ip_reg..operand$fp_reg_pair_physical];
    instr^.h.nopnds := 2;
  end
  else begin
    move_operand(addr(instr^.opnds[4]), addr(instr^.opnds[3]));
    if instr^.opnds[3].h.kind = operand$none then begin
      instr^.opnds[3].h.num := 0;
      instr^.h.b0_6 := instr^.opnds[1].h.kind
                       in [operand$ip_reg..operand$fp_reg_pair_physical];
    end;
    instr^.h.nopnds := 3;
  end;
  utils_$set_instruction_opcode(instr, ord(opc$move));
end;

{ convert_move_to_add - a MOVE made an ADD (79) after it: the move's
  operands 1 and 2 become the add's 2 and 3, its operand 1 an
  immediate (kind 23, rrp byte 16, value left to the caller); a move
  that sets the condition codes gives its last operand to the add's
  last (the add then sets them, +0 bit 4); the add takes the move's
  number (+42) and the move is excised (the result dropped).  The add.

  0x27DC9C, 0xCC bytes, no A5: A0 the new instruction kept in A3 for
  the return. }

function convert_move_to_add(
    instr: instr_ptr_t): instr_ptr_t; options(val_param); internal;
var
  add: instr_ptr_t;
  o: opnd_ptr_t;
begin
  add := lir_$optimizer_new_instruction(instr, ord(opc$add), true);
  add^.opnds[1].h.num := 1;
  add^.opnds[2].h.num := 2;
  add^.opnds[3].h.num := 3;
  move_operand(addr(instr^.opnds[1]), addr(add^.opnds[2]));
  move_operand(addr(instr^.opnds[2]), addr(add^.opnds[3]));
  add^.opnds[1].h.kind := operand$immediate;
  opnd_bytes_ptr_t(addr(add^.opnds[1]))^.rrp := 16;
  if instr^.h.sets_cc then begin
    o := addr(add^.opnds[add^.h.nopnds]);
    o^.h.num := add^.h.nopnds;
    move_operand(addr(instr^.opnds[instr^.h.nopnds]), o);
    add^.h.sets_cc := true;
  end;
  add^.num := instr^.num;
  discard(lir_utils_$excise_inst(instr));
  convert_move_to_add := add;
end;

{ adjustable_creation_point - whether the instruction that creates o's
  value can absorb disp (o's value then disp less), and, when apply,
  it made to: a postmodifying load or store (+3 bits 7..6 = 1) whose
  base is o's live range and o writes, when simple or its immediate
  index less disp still postmodifies (tm_utils_$can_postmodify_base_
  register_by); a JOIN_BP; an ADD or SUB whose operand 2 is o's live
  range (when simple) or whose result is o: with an immediate operand
  1 the new constant (an ADD's less disp, a SUB's plus disp or, as an
  ADD, its negation) encodable (the opcode set, or a MOVE when 0);
  otherwise, when the creator is in a block of a lower +16 than the
  instruction's and -disp is encodable, an ADD of -disp after it into a
  new segment of a new register live range that the result moves to; a
  MOVE of an immediate (its value less disp) or of o's live range
  (simple), or, unless no_add, made an ADD of -disp
  (convert_move_to_add).  An instruction that sets condition codes
  that are final (+3 bit 4) or read cannot.

  0x27DD68, 0x3C8 bytes, no A5: the result a frame byte (-42); the
  opcodes by a compare chain (203, 81, 79, 75); the classes 16 and 21
  by `btst' in 0x210000; tm_utils_$can_encode_as_immediate_operand's
  operand number 1 by `pea 0x1' after a pad. }

function adjustable_creation_point(
    o: opnd_ptr_t;
    disp: integer32;
    creator: instr_ptr_t;
    simple: boolean;
    no_add: boolean;
    apply: boolean): boolean; options(val_param); internal;
var
  result: boolean;
  i, add: instr_ptr_t;
  x, last, res: opnd_ptr_t;
  value: integer32;
  newop: integer;
  ok: boolean;
  lr: lr_ptr_t;
  lts: lts_ptr_t;
  kind: integer;
  neg: integer32;
begin
  result := false;
  i := utils_ins_$operands_instruction(o);
  if instruction_attributes[i^.opc].class in [class$load, class$store] then
    if rshft(i^.h.width & 16#C0, 6) = 1 then
      if base_operand(i)^.lts^.lr = o^.lts^.lr then
        if (opnd_bytes_ptr_t(o)^.rrp & 12) <> 0 then begin
          if simple then
            result := true
          else begin
            x := index_operand(i);
            if x^.h.kind = operand$immediate then
              if tm_utils_$can_postmodify_base_register_by(x^.value - disp,
                                                           i^.opc) then begin
                result := true;
                if apply then
                  x^.value := x^.value - disp;
              end;
          end;
        end;
  if i^.h.sets_cc then begin
    last := addr(i^.opnds[i^.h.nopnds]);
    if last^.lts^.f2.b3_4 or (last^.link <> nil) then begin
      adjustable_creation_point := result;
      return;
    end;
  end;
  if i^.opc = ord(opc$join_bp) then
    result := true
  else if (i^.opc = ord(opc$sub)) or (i^.opc = ord(opc$add)) then begin
    if simple
       and (i^.opnds[2].h.kind
            in [operand$ip_reg..operand$well_behaved_memory])
       and (i^.opnds[2].lts^.lr = o^.lts^.lr) then
      result := true
    else if addr(i^.opnds[3]) = o then begin
      res := addr(i^.opnds[3]);
      ok := false;
      if i^.opnds[1].h.kind = operand$immediate then begin
        if i^.opc = ord(opc$add) then begin
          value := i^.opnds[1].value - disp;
          if tm_utils_$can_encode_as_immediate_operand(value, ord(opc$add),
                                                       1) then
            ok := true;
          newop := ord(opc$add);
        end
        else begin
          value := disp + i^.opnds[1].value;
          if tm_utils_$can_encode_as_immediate_operand(value, ord(opc$sub),
                                                       1) then begin
            newop := ord(opc$sub);
            ok := true;
          end
          else begin
            neg := -value;
            if tm_utils_$can_encode_as_immediate_operand(neg, ord(opc$add),
                                                         1) then begin
              newop := ord(opc$add);
              value := neg;
              ok := true;
            end;
          end;
        end;
      end;
      if ok then begin
        result := true;
        if apply then
          if value <> 0 then begin
            utils_$set_instruction_opcode(i, newop);
            i^.opnds[1].value := value;
          end
          else
            convert_add_to_move(i);
      end
      else if creator <> nil then
        if i^.bb^.f.b16 < creator^.bb^.f.b16 then begin
          neg := -disp;
          if tm_utils_$can_encode_as_immediate_operand(neg, ord(opc$add),
                                                       1) then begin
            result := true;
            if apply then begin
              add := lir_$optimizer_new_instruction(i, ord(opc$add), true);
              add^.opnds[1].h.num := 1;
              add^.opnds[2].h.num := 2;
              add^.opnds[3].h.num := 3;
              move_operand(res, addr(add^.opnds[3]));
              add^.opnds[1].h.kind := operand$immediate;
              add^.opnds[1].value := neg;
              opnd_bytes_ptr_t(addr(add^.opnds[1]))^.rrp := 16;
              lr := lir_$new_live_range_ip_reg;
              lir_utils_$add_lts_to_lr(24, lr, i^.bb, lts);
              lts^.def := res;
              i^.opnds[3].h.kind := operand$ip_reg;
              i^.opnds[3].lts := lts;
              i^.opnds[3].link := addr(add^.opnds[2]);
              opnd_bytes_ptr_t(addr(i^.opnds[3]))^.rrp := 8;
              i^.opnds[2].h.intend_to_modify := false;
              i^.opnds[1].h.intend_to_modify := false;
              add^.opnds[2].h.kind := operand$ip_reg;
              add^.opnds[2].lts := lts;
              opnd_bytes_ptr_t(addr(add^.opnds[2]))^.rrp := 16;
            end;
          end;
        end;
    end;
  end
  else if i^.opc = ord(opc$move) then begin
    kind := ord(i^.opnds[1].h.kind);
    if kind = ord(operand$immediate) then begin
      value := i^.opnds[1].value - disp;
      if tm_utils_$can_encode_as_immediate_operand(value, ord(opc$move),
                                                   1) then begin
        result := true;
        if apply then
          i^.opnds[1].value := value;
      end;
    end
    else if simple
            and (kind in [1..11])
            and (i^.opnds[1].lts^.lr = o^.lts^.lr) then
      result := true
    else if not no_add then begin
      result := true;
      if apply then
        convert_move_to_add(i)^.opnds[1].value := -disp;
    end;
  end;
  adjustable_creation_point := result;
end;

{ can_preserve_operation - whether o's instruction can keep its effect
  when o's value changes from old to new: o must be read; condition
  codes it sets must be neither final nor read; a load's or store's
  base (not postmodifying or premodifying, +3 bits 7..6 = 0) with its
  index, an ADD's operand 2 with its operand 1, a SUB's operand 2 with
  an immediate operand 1 (yes at once when the SUB's constant
  adjusted, value - new + old, encodes; else as an ADD), a MOVE
  (yes at once when new - old encodes as an ADD's, unless operand 1 is
  a register) with its operand 1: that operand must be an immediate
  whose adjusted value (+ new - old) can be converted
  (tm_utils_$can_convert_to_immediate_operand) or, for the changed
  opcode, encoded.

  0x27E130, 0x1A2 bytes, no A5. }

function can_preserve_operation(
    o: opnd_ptr_t;
    old: integer32;
    new: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  i: instr_ptr_t;
  last: opnd_ptr_t;
  opc: integer;
  x: opnd_ptr_t;
begin
  result := false;
  if not o^.h.read then begin
    can_preserve_operation := false;
    return;
  end;
  i := utils_ins_$operands_instruction(o);
  if i^.h.sets_cc then begin
    last := addr(i^.opnds[i^.h.nopnds]);
    if last^.lts^.f2.b3_4 or (last^.link <> nil) then begin
      can_preserve_operation := false;
      return;
    end;
  end;
  opc := i^.opc;
  if instruction_attributes[opc].class in [class$load, class$store] then begin
    if not is_base_operand(i, o) then begin
      can_preserve_operation := false;
      return;
    end;
    if rshft(i^.h.width & 16#C0, 6) <> 0 then begin
      can_preserve_operation := false;
      return;
    end;
    x := index_operand(i);
  end
  else if opc = ord(opc$add) then begin
    if o^.h.num <> 2 then begin
      can_preserve_operation := false;
      return;
    end;
    x := addr(i^.opnds[1]);
  end
  else if opc = ord(opc$sub) then begin
    if (o^.h.num <> 2) or (i^.opnds[1].h.kind <> operand$immediate) then begin
      can_preserve_operation := false;
      return;
    end;
    if tm_utils_$can_encode_as_immediate_operand(
           i^.opnds[1].value - new + old, ord(opc$sub), 1) then begin
      can_preserve_operation := true;
      return;
    end;
    opc := ord(opc$add);
    x := addr(i^.opnds[1]);
  end
  else if opc = ord(opc$move) then begin
    if not (i^.opnds[1].h.kind
            in [operand$ip_reg..operand$well_behaved_memory]) then
      if tm_utils_$can_encode_as_immediate_operand(new - old, ord(opc$add),
                                                   1) then begin
        can_preserve_operation := true;
        return;
      end;
    x := addr(i^.opnds[1]);
  end
  else begin
    can_preserve_operation := false;
    return;
  end;
  if x^.h.kind = operand$immediate then
    if opc = i^.opc then
      result := tm_utils_$can_convert_to_immediate_operand(
                    new + x^.value - old, i, x^.h.num)
    else
      result := tm_utils_$can_encode_as_immediate_operand(
                    new + x^.value - old, opc, x^.h.num);
  can_preserve_operation := result;
end;

{ preserve_operation - o's instruction made to keep its effect when o's
  value changes by delta: the immediate (a load's or store's index, an
  ADD's or SUB's operand 1; a MOVE first made an ADD, o then its
  operand 2) less delta; a SUB whose constant plus delta does not
  encode becomes an ADD of the negation, else delta is negated; an ADD
  or SUB left adding 0 becomes a MOVE (o then its operand 1).  The
  operand must be an immediate (bug_check).

  0x27E2D2, 0x11C bytes, no A5: o by address; the subtraction's flags
  (`sub.l D2,(8,A3); bne') test the new value. }

procedure preserve_operation(
    var o: opnd_ptr_t;
    delta: integer32); options(val_param); internal;
var
  i: instr_ptr_t;
  x: opnd_ptr_t;
begin
  i := utils_ins_$operands_instruction(o);
  if instruction_attributes[i^.opc].class in [class$load, class$store] then
    x := index_operand(i)
  else if i^.opc = ord(opc$add) then
    x := addr(i^.opnds[1])
  else if i^.opc = ord(opc$sub) then begin
    if i^.opnds[1].h.kind <> operand$immediate then
      bug_check('TR_UTILS_$preserve_operation: operand not immediate%$');
    if tm_utils_$can_encode_as_immediate_operand(delta + i^.opnds[1].value,
                                                 ord(opc$sub), 1) then
      delta := -delta
    else begin
      utils_$set_instruction_opcode(i, ord(opc$add));
      i^.opnds[1].value := -i^.opnds[1].value;
    end;
    x := addr(i^.opnds[1]);
  end
  else if i^.opc = ord(opc$move) then begin
    i := convert_move_to_add(i);
    o := addr(i^.opnds[2]);
    x := addr(i^.opnds[1]);
  end;
  if x^.h.kind <> operand$immediate then
    bug_check('TR_UTILS_$preserve_operation: operand not immediate%$');
  x^.value := x^.value - delta;
  if x^.value = 0 then
    if (i^.opc = ord(opc$sub)) or (i^.opc = ord(opc$add)) then begin
      convert_add_to_move(i);
      o := addr(i^.opnds[1]);
    end;
end;

{ is_well_understood_intend_input_to_modify - whether o, a register or
  memory operand read by a MOVE, ADD, JOIN_BP or SUB, means to modify
  (+1 bit 5) or a later operand of its instruction writes or modifies
  o's live range.  0x27E424, 0xCC bytes, no A5. }

function is_well_understood_intend_input_to_modify(
    o: opnd_ptr_t): boolean; options(val_param); internal;
var
  i: instr_ptr_t;
  k: integer32;
  opc: integer;
begin
  i := utils_ins_$operands_instruction(o);
  if not o^.h.read
     or not (o^.h.kind in [operand$ip_reg..operand$well_behaved_memory]) then begin
    is_well_understood_intend_input_to_modify := false;
    return;
  end;
  opc := i^.opc;
  if (opc = ord(opc$move)) or (opc = ord(opc$add))
     or (opc = ord(opc$join_bp)) or (opc = ord(opc$sub)) then begin
    if o^.h.intend_to_modify then begin
      is_well_understood_intend_input_to_modify := true;
      return;
    end;
    for k := o^.h.num + 1 to i^.h.nopnds do
      if (i^.opnds[k].h.kind
          in [operand$ip_reg..operand$well_behaved_memory])
         and ((opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0)
         and (i^.opnds[k].lts^.lr = o^.lts^.lr) then begin
        is_well_understood_intend_input_to_modify := true;
        return;
      end;
    is_well_understood_intend_input_to_modify := false;
  end
  else
    is_well_understood_intend_input_to_modify := false;
end;

{ tr_utils_$try_twiddling_disp - instr's displacement folded into the
  definitions and uses of the live range it adds to: for an ADD or SUB
  (not setting the condition codes, disp 0) of a register result (its
  operand 3), an immediate operand 1 (delta, negated for a SUB; not
  when operand 2 is the result's live range) or a register operand 1
  of an ADD (then the uses are rewritten instead: the copy mode); for a
  load or store with an immediate index, disp less the index (delta)
  and the base's live range.  Each segment of the live range: its
  writing def must absorb delta (adjustable_creation_point; in the
  copy mode be instr's result), its readers keep their effect
  (is_well_understood_intend_input_to_modify, can_preserve_operation;
  in the copy mode each must be the base of a load or store in instr's
  block with an immediate index cancelling delta, convertible to a
  register index, not modifying, after instr's operand 1's last
  segment's def unless that live range is simple with one segment).
  When some def or reader was found, everything rewritten so (in the
  copy mode the defs, ADDs, become MOVEs and the index operands become
  operand 1's segment, its rrp less 0x2C plus read, its count); then,
  unless no_copy_elim, the last such MOVE's copy eliminated.  True when
  done (also when nothing was found).

  0x27E4F0, 0x42C bytes: delta at -52, the mode at -64 (true: adjust),
  operand 1's live range simple at -60; tr_utils_$attempt_copy_elimination
  with the cell +20 as it is. }

function tr_utils_$try_twiddling_disp(
    instr: instr_ptr_t;
    disp: integer32;
    no_add: boolean;
    no_copy_elim: boolean): boolean;
var
  result: boolean;
  adjust: boolean;
  simple1: boolean;
  delta: integer32;
  base: opnd_ptr_t;
  src: lts_ptr_t;
  count: integer32;
  kind: integer;
  lr: lr_ptr_t;
  l: lts_ptr_t;
  found: boolean;
  r, nr, x, t: opnd_ptr_t;
  i: instr_ptr_t;
  v: integer32;
  last, prev: lts_ptr_t;
  mv: instr_ptr_t;
begin
  result := false;
  adjust := true;
  simple1 := false;
  if (instr^.opc = ord(opc$sub)) or (instr^.opc = ord(opc$add)) then begin
    if instr^.h.sets_cc or (disp <> 0) then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
    base := addr(instr^.opnds[3]);
    if not (base^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
    then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
    if instr^.opnds[1].h.kind = operand$immediate then begin
      if instr^.opnds[2].h.kind
         in [operand$ip_reg..operand$well_behaved_memory] then
        if instr^.opnds[2].lts^.lr = base^.lts^.lr then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
      delta := instr^.opnds[1].value;
      if instr^.opc = ord(opc$sub) then
        delta := -delta;
    end
    else begin
      if (instr^.opc = ord(opc$sub))
         or not (instr^.opnds[1].h.kind
                 in [operand$ip_reg..operand$well_behaved_memory]) then begin
        tr_utils_$try_twiddling_disp := false;
        return;
      end;
      src := instr^.opnds[1].lts;
      simple1 := (src^.lr^.w4 = 0) and (src^.lr^.ltss^.next = nil);
      count := instr^.opnds[1].h.count;
      kind := ord(instr^.opnds[1].h.kind);
      adjust := false;
      delta := 0;
    end;
  end
  else begin
    x := index_operand(instr);
    if x = nil then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
    if x^.h.kind <> operand$immediate then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
    delta := disp - x^.value;
    base := base_operand(instr);
    if not (base^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
    then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
  end;
  lr := base^.lts^.lr;
  l := lr^.ltss;
  found := false;
  while l <> nil do begin
    r := l^.def;
    if (r <> nil) and ((opnd_bytes_ptr_t(r)^.rrp & 12) <> 0) then begin
      if adjust then begin
        if not adjustable_creation_point(r, delta, instr, true, no_add,
                                         false) then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
      end
      else if r <> addr(instr^.opnds[3]) then begin
        tr_utils_$try_twiddling_disp := false;
        return;
      end;
      r := r^.link;
    end
    else if not adjust then begin
      tr_utils_$try_twiddling_disp := false;
      return;
    end;
    while r <> nil do begin
      if adjust then begin
        if not is_well_understood_intend_input_to_modify(r) then
          if not can_preserve_operation(r, 0, delta) then begin
            tr_utils_$try_twiddling_disp := false;
            return;
          end;
      end
      else begin
        i := utils_ins_$operands_instruction(r);
        x := index_operand(i);
        if x = nil then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
        if x^.h.kind <> operand$immediate then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
        if not tm_utils_$can_convert_to_ip_reg_operand(i^.opc, x^.h.num,
                                                       count) then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
        v := x^.value + delta;
        if (rshft(i^.h.width & 16#C0, 6) <> 0) or (base_operand(i) <> r)
           or (v <> 0) or (i^.bb <> instr^.bb) then begin
          tr_utils_$try_twiddling_disp := false;
          return;
        end;
        if not simple1 then begin
          last := utils_$find_last_lts_in_bb(src^.lr, i^.bb, prev);
          if last <> src then begin
            while last^.next <> src do
              last := last^.next;
            if tr_utils_$relative_instr_position(i,
                 utils_ins_$operands_instruction(last^.def)) < 0 then begin
              tr_utils_$try_twiddling_disp := false;
              return;
            end;
          end;
        end;
      end;
      found := true;
      r := r^.link;
    end;
    l := l^.next;
  end;
  if found then begin
    mv := nil;
    l := lr^.ltss;
    while l <> nil do begin
      r := l^.def;
      if (r <> nil) and ((opnd_bytes_ptr_t(r)^.rrp & 12) <> 0) then begin
        nr := r^.link;
        if adjust then
          discard(adjustable_creation_point(r, delta, instr, true, no_add,
                                            true))
        else begin
          i := utils_ins_$operands_instruction(r);
          convert_add_to_move(i);
          mv := i;
        end;
        r := nr;
      end;
      while r <> nil do begin
        nr := r^.link;
        x := index_operand(utils_ins_$operands_instruction(r));
        if adjust then begin
          if not is_well_understood_intend_input_to_modify(r) then begin
            t := r;
            preserve_operation(t, -delta);
          end;
        end
        else if x <> nil then begin
          x^.h.kind := operand$t(kind);
          opnd_bytes_ptr_t(x)^.rrp :=
            (integer(src^.rrp) & 16#D3) ! 16;
          x^.lts := src;
          x^.h.count := count;
          if (src^.def <> nil)
             and ((opnd_bytes_ptr_t(src^.def)^.rrp & 12) <> 0) then begin
            x^.link := src^.def^.link;
            src^.def^.link := x;
          end
          else begin
            x^.link := src^.def;
            src^.def := x;
          end;
        end;
        r := nr;
      end;
      l := l^.next;
    end;
    if not no_copy_elim and (mv <> nil) then
      tr_utils_$attempt_copy_elimination(tr_rtn, mv);
  end;
  tr_utils_$try_twiddling_disp := true;
end;

{ transform_to_autoindex - add (an ADD or SUB of the base register and
  an immediate) folded into mem as its pre- or postmodification: o (the
  operand of mem that reads the base) takes the add's operand 2, x (the
  index) a copy of the add's operand 1 (negated for a SUB); unless mem
  is a load whose result is the base's live range (only allowed when
  allow_same: then a mode 1 index is 0), the add's result moves to a
  free operand slot of mem (modify instead of write), o means to
  modify, and mem's +3 bits 7..6 get mode.  The add excised.

  0x27E91C, 0x11A bytes, no A5. }

procedure transform_to_autoindex(
    mem: instr_ptr_t;
    o: opnd_ptr_t;
    x: opnd_ptr_t;
    add: instr_ptr_t;
    mode: integer;
    allow_same: boolean); options(val_param); internal;
var
  n: opnd_ptr_t;
begin
  drop_operand_from_lts(o);
  move_operand(addr(add^.opnds[2]), o);
  drop_operand_from_lts(x);
  make_copy(addr(add^.opnds[1]), x);
  utils_$maybe_merge_source_statements(mem, add);
  if add^.opc = ord(opc$sub) then
    x^.value := -x^.value;
  if (instruction_attributes[mem^.opc].class = class$load)
     and (mem^.opnds[2].lts^.lr = mem^.opnds[3].lts^.lr) then begin
    if not allow_same then
      bug_check('TR_UTILS_$transform_to_autoindex: load LR same as base addr!%$');
    if mode = 1 then
      x^.value := 0;
  end
  else begin
    n := find_operand_of_kind(mem, 0, 0);
    move_operand(addr(add^.opnds[3]), n);
    n^.h.write := false;
    n^.h.modify := true;
    n^.lts^.rrp := n^.lts^.rrp - [rrp$write] + [rrp$modify];
    o^.h.intend_to_modify := true;
    o^.lts^.rrp := o^.lts^.rrp + [rrp$intend_to_modify];
    mem^.h.width := (mem^.h.width & 16#3F) ! lshft(mode, 6);
  end;
  discard(lir_utils_$excise_inst(add));
end;

{ mem_ref_positioned_for_postincrement - whether mem (not yet pre- or
  postmodifying, with a register base and an immediate index) can
  postmodify its base by disp (add the instruction that adds it, or
  nil): with try_pre, a postmodification when the index plus offset is
  0, or a premodification when it equals disp; otherwise the index
  plus offset must be 0 and, when add's result is written before mem,
  mem and its dependents are separated from what lies between them.
  Then the base's readers are ordered; the last one (before add's, when
  that is add's) must not mean to modify, and the readers mem's
  dependents include must keep their effect (can_preserve_operation,
  with try_pre only; else no); mem's dependents are separated from the
  rest up to that reader.  Without try_pre, add's result's readers must
  not depend on mem.

  0x27EA74, 0x280 bytes, no A5 (its callers'): the result in D5, the
  disp parameter's register reused for the answer (D2). }

function mem_ref_positioned_for_postincrement(
    mem: instr_ptr_t;
    add: instr_ptr_t;
    try_pre: boolean;
    disp: integer32;
    offset: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  ok: boolean;
  base, x, prev, last, r: opnd_ptr_t;
  sum: integer32;
  def: instr_ptr_t;
  mark: integer32;
  target: instr_ptr_t;
begin
  result := false;
  base := base_operand(mem);
  if rshft(mem^.h.width & 16#C0, 6) <> 0 then begin
    mem_ref_positioned_for_postincrement := false;
    return;
  end;
  if base = nil then begin
    mem_ref_positioned_for_postincrement := false;
    return;
  end;
  if not (base^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
  then begin
    mem_ref_positioned_for_postincrement := false;
    return;
  end;
  x := index_operand(mem);
  if x = nil then begin
    mem_ref_positioned_for_postincrement := false;
    return;
  end;
  if x^.h.kind <> operand$immediate then begin
    mem_ref_positioned_for_postincrement := false;
    return;
  end;
  sum := offset + x^.value;
  if try_pre then begin
    if not (tm_utils_$can_postmodify_base_register_by(disp, mem^.opc)
            and (sum = 0)) then
      if not tm_utils_$can_premodify_base_register_by(disp, mem^.opc)
         or (disp <> sum) then begin
        mem_ref_positioned_for_postincrement := false;
        return;
      end;
  end
  else begin
    if (sum <> 0) or (add = nil) then begin
      mem_ref_positioned_for_postincrement := false;
      return;
    end;
    if (add^.opnds[1].lts^.rrp * [rrp$modify, rrp$write]) <> [] then begin
      def := utils_ins_$operands_instruction(add^.opnds[1].lts^.def);
      if tr_utils_$relative_instr_position(mem, def) > 0 then begin
        tr_rtn^.l180 := tr_rtn^.l180 + 1;
        mark := tr_rtn^.l180;
        tr_utils_$mark_dependents(mem, def, mark);
        if mem^.l16 = def^.l16 then begin
          mem_ref_positioned_for_postincrement := false;
          return;
        end;
        tr_utils_$separate_partitions(mem, def);
        tr_utils_$guarantee_operand_order(add^.opnds[1].lts);
      end;
    end;
  end;
  tr_utils_$guarantee_operand_order(base^.lts);
  if base^.link = nil then
    ok := true
  else begin
    prev := nil;
    last := base^.link;
    while last^.link <> nil do begin
      prev := last;
      last := last^.link;
    end;
    if utils_ins_$operands_instruction(last) = add then
      last := prev;
    if last = nil then
      ok := true
    else begin
      if last^.h.intend_to_modify then begin
        mem_ref_positioned_for_postincrement := false;
        return;
      end;
      tr_rtn^.l180 := tr_rtn^.l180 + 1;
      mark := tr_rtn^.l180;
      target := utils_ins_$operands_instruction(last);
      tr_utils_$mark_dependents(mem, target, mark);
      r := base^.link;
      repeat
        if utils_ins_$operands_instruction(r)^.l16 = mark then begin
          if not try_pre then begin
            mem_ref_positioned_for_postincrement := false;
            return;
          end;
          if not can_preserve_operation(r, disp, offset) then begin
            mem_ref_positioned_for_postincrement := false;
            return;
          end;
        end;
        if r = last then
          exit;
        r := r^.link;
      until false;
      tr_utils_$separate_partitions(mem, target);
      tr_utils_$guarantee_operand_order(base^.lts);
      ok := true;
    end;
  end;
  if ok and not try_pre then
    if (add^.opnds[1].h.kind
        in [operand$ip_reg..operand$well_behaved_memory])
       and ((add^.opnds[1].lts^.rrp * [rrp$modify, rrp$write]) <> []) then begin
      tr_rtn^.l180 := tr_rtn^.l180 + 1;
      mark := tr_rtn^.l180;
      tr_utils_$mark_dependents(mem, add, mark);
      if utils_ins_$operands_instruction(add^.opnds[1].lts^.def)^.l16
         = mark then begin
        mem_ref_positioned_for_postincrement := false;
        return;
      end;
    end;
  mem_ref_positioned_for_postincrement := ok;
end;

{ mem_ref_positioned_for_preincrement - whether mem (not yet pre- or
  postmodifying, with a register base, written by add's result when
  written at all, and an immediate index) can premodify its base by
  disp: with try_post, a premodification when the index plus offset is
  0 or a postmodification when it is -disp; otherwise it must be 0.
  Then, the base's readers ordered, the reader before mem's base and
  what depends on it must not include mem: else mem is separated from
  it and the test repeated; when they do (only with try_post), each
  reader before mem's base must keep its effect (can_preserve_operation
  with -disp).

  0x27ECF4, 0x1AC bytes, no A5 (its callers'): add's register reused
  for the sum. }

function mem_ref_positioned_for_preincrement(
    mem: instr_ptr_t;
    add: instr_ptr_t;
    try_post: boolean;
    disp: integer32;
    offset: integer32): boolean; options(val_param); internal;
var
  base, x, r: opnd_ptr_t;
  written: boolean;
  sum: integer32;
  mark: integer32;
  i: instr_ptr_t;
begin
  base := base_operand(mem);
  if (rshft(mem^.h.width & 16#C0, 6) <> 0) or (base = nil) then begin
    mem_ref_positioned_for_preincrement := false;
    return;
  end;
  if not (base^.h.kind in [operand$ip_reg..operand$well_behaved_memory])
  then begin
    mem_ref_positioned_for_preincrement := false;
    return;
  end;
  written := (base^.lts^.rrp * [rrp$modify, rrp$write]) <> [];
  if written then
    if base^.lts^.def <> addr(add^.opnds[3]) then begin
      mem_ref_positioned_for_preincrement := false;
      return;
    end;
  x := index_operand(mem);
  if x = nil then begin
    mem_ref_positioned_for_preincrement := false;
    return;
  end;
  if x^.h.kind <> operand$immediate then begin
    mem_ref_positioned_for_preincrement := false;
    return;
  end;
  sum := offset + x^.value;
  if try_post then begin
    if not (tm_utils_$can_premodify_base_register_by(disp, mem^.opc)
            and (sum = 0)) then
      if not tm_utils_$can_postmodify_base_register_by(disp, mem^.opc)
         or (-disp <> sum) then begin
        mem_ref_positioned_for_preincrement := false;
        return;
      end;
  end
  else if sum <> 0 then begin
    mem_ref_positioned_for_preincrement := false;
    return;
  end;
  repeat
    tr_utils_$guarantee_operand_order(base^.lts);
    if written then
      r := base^.lts^.def^.link
    else
      r := base^.lts^.def;
    if r = base then begin
      mem_ref_positioned_for_preincrement := true;
      return;
    end;
    while r^.link <> base do
      r := r^.link;
    tr_rtn^.l180 := tr_rtn^.l180 + 1;
    mark := tr_rtn^.l180;
    i := utils_ins_$operands_instruction(r);
    tr_utils_$mark_dependents(i, mem, mark);
    if i^.l16 = mem^.l16 then begin
      if not try_post then begin
        mem_ref_positioned_for_preincrement := false;
        return;
      end;
      if written then
        r := base^.lts^.def^.link
      else
        r := base^.lts^.def;
      while r <> base do begin
        if not can_preserve_operation(r, -disp, offset) then begin
          mem_ref_positioned_for_preincrement := false;
          return;
        end;
        r := r^.link;
      end;
      mem_ref_positioned_for_preincrement := true;
      return;
    end;
    tr_utils_$separate_partitions(i, mem);
  until false;
end;

{ can_adjust_creation_point - whether the creation of lts (written or
  modified), by a MOVE (its operand 2), ADD or SUB (operand 3) or a
  postmodifying load or store of lts's live range (lts's def), can
  absorb new - old (adjustable_creation_point, without applying), and
  the def's readers keep their effect (can_preserve_operation).

  0x27EEA0, 0x122 bytes, no A5. }

function can_adjust_creation_point(
    instr: instr_ptr_t;
    lts: lts_ptr_t;
    creator: instr_ptr_t;
    old: integer32;
    new: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  o: opnd_ptr_t;
begin
  if (lts^.rrp * [rrp$modify, rrp$write]) = [] then begin
    can_adjust_creation_point := false;
    return;
  end;
  if (instr^.opc = ord(opc$move)) or (instr^.opc = ord(opc$sub))
     or (instr^.opc = ord(opc$add)) then begin
    if instr^.opc = ord(opc$move) then
      o := addr(instr^.opnds[2])
    else
      o := addr(instr^.opnds[3]);
    if o^.lts <> lts then begin
      can_adjust_creation_point := false;
      return;
    end;
    if adjustable_creation_point(o, new - old, creator, false, false,
                                 false) then
      result := true
    else begin
      can_adjust_creation_point := false;
      return;
    end;
  end
  else if instruction_attributes[instr^.opc].class
          in [class$load, class$store] then begin
    if (rshft(instr^.h.width & 16#C0, 6) <> 1)
       or (base_operand(instr)^.lts^.lr <> lts^.lr) then begin
      can_adjust_creation_point := false;
      return;
    end;
    o := lts^.def;
    result := adjustable_creation_point(o, new - old, creator, false, false,
                                        false);
  end
  else
    result := false;
  if result then begin
    o := o^.link;
    while o <> nil do begin
      if not can_preserve_operation(o, old, new) then begin
        can_adjust_creation_point := false;
        return;
      end;
      o := o^.link;
    end;
  end;
  can_adjust_creation_point := result;
end;

{ autoindex_within_bb - add (an ADD of an immediate to the base register,
  operand 2, into operand 3; with try_both any of the opcodes, else
  only ADD, disp then the smallest integer) folded into a load or store
  of its block as a pre- or postmodification.  First the instructions
  reading add's result (chained through +24, each once), in two
  passes: one whose base is the result and that is positioned for a
  preincrement (mem_ref_positioned_for_preincrement: offset 0 in the
  first pass; in the second, with an immediate index, offset -index, or
  with try_both as a postincrement with -(disp + index) and its
  displacement then twiddled by -disp: tr_utils_$try_twiddling_disp)
  takes add over: the result's readers before it adjusted by -disp
  (preserve_operation) and moved to add's operand 2's segment, then
  transform_to_autoindex (mode 2 for a zero index, else 1; the load's
  result may be the base).  Otherwise operand 2's readers (operand 2
  itself taken off their chain, where it must be last: bug_check)
  chained in reverse, in two passes likewise: an instruction whose
  creation of operand 2 can absorb disp (can_adjust_creation_point,
  with try_both) or a load or store based on operand 2 positioned for a
  postincrement (offset 0; then -index, or with try_both disp - index
  and a twiddle by disp) takes add over: the readers after it, but add,
  adjusted by disp and moved to add's result; when the operand writes
  (a creation absorbed), the creation adjusted by -disp
  (adjustable_creation_point applied; bug_check when it fails), the
  result's readers given to operand 2's segment, the result's segment
  excised (its definition moved to operand 2's segment first when it is
  final) and add excised; else transform_to_autoindex (mode 1 for a
  zero index, else 2).  Operand 2 put back on its chain when nothing
  was done.  True when add was folded.

  0x27EFC2, 0x598 bytes, no A5 (its callers'): the instruction lists
  through +24; both passes counted by `dbf' with the pass in a word. }

function autoindex_within_bb(
    add: instr_ptr_t;
    try_both: boolean;
    disp: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  r, b, x, o, a2, t: opnd_ptr_t;
  head, p, i: instr_ptr_t;
  pass: integer;
  k: integer32;
  ok: boolean;
  delta: integer32;
  mode: integer;
  lts, l3: lts_ptr_t;
  op2: opnd_ptr_t;
  last: opnd_ptr_t;
begin
  result := false;
  if not try_both then begin
    if add^.opc <> ord(opc$add) then begin
      autoindex_within_bb := false;
      return;
    end;
    disp := 16#80000000;
  end;
  tr_utils_$guarantee_operand_order(add^.opnds[3].lts);
  r := add^.opnds[3].link;
  if r = nil then
    head := nil
  else begin
    head := utils_ins_$operands_instruction(r);
    head^.l24 := 0;
    p := head;
    r := r^.link;
    while r <> nil do begin
      i := utils_ins_$operands_instruction(r);
      p^.l24 := integer32(i);
      if i <> p then
        p := i;
      p^.l24 := 0;
      r := r^.link;
    end;
  end;
  pass := 0;
  for k := 1 to 2 do begin
    p := head;
    while p <> nil do begin
      b := base_operand(p);
      x := index_operand(p);
      if (x <> nil) and (b <> nil) then
        if b^.lts = add^.opnds[3].lts then begin
          if pass <> 1 then
            ok := mem_ref_positioned_for_preincrement(p, add, try_both, disp, 0)
          else if x^.h.kind = operand$immediate then begin
            ok := mem_ref_positioned_for_preincrement(p, add, try_both, disp,
                                                      -x^.value);
            if ok then
              delta := 0
            else if try_both then begin
              ok := mem_ref_positioned_for_postincrement(p, add, try_both,
                      disp, -(disp + x^.value));
              delta := -disp;
            end
            else
              ok := false;
            if ok then
              ok := tr_utils_$try_twiddling_disp(p, delta, false, false);
          end
          else
            ok := false;
          if ok then begin
            if x^.value = 0 then
              mode := 2
            else
              mode := 1;
            a2 := add^.opnds[3].link;
            if a2 <> b then begin
              delta := -disp;
              lts := add^.opnds[2].lts;
              repeat
                t := a2;
                preserve_operation(t, delta);
                a2 := t;
                a2^.lts := lts;
                last := a2;
                a2 := a2^.link;
              until a2 = b;
              op2 := addr(add^.opnds[2]);
              last^.link := op2;
              if lts^.def = op2 then
                lts^.def := add^.opnds[3].link
              else begin
                o := lts^.def;
                while o^.link <> op2 do
                  o := o^.link;
                o^.link := add^.opnds[3].link;
              end;
              add^.opnds[3].link := b;
            end;
            transform_to_autoindex(p, b, x, add, mode, true);
            autoindex_within_bb := true;
            return;
          end;
        end;
      p := instr_ptr_t(p^.l24);
    end;
    pass := pass + 1;
  end;
  tr_utils_$guarantee_operand_order(add^.opnds[2].lts);
  a2 := add^.opnds[2].lts^.def;
  if add^.opnds[2].link <> nil then
    bug_check('TR_UTILS_$autoindex_within_bb: intend to modify opr should be last%$');
  op2 := addr(add^.opnds[2]);
  if a2 = op2 then begin
    autoindex_within_bb := result;
    return;
  end;
  while a2^.link <> op2 do
    a2 := a2^.link;
  a2^.link := nil;
  a2 := add^.opnds[2].lts^.def;
  if a2 = nil then
    head := nil
  else begin
    head := utils_ins_$operands_instruction(a2);
    head^.l24 := 0;
    a2 := a2^.link;
    while a2 <> nil do begin
      i := utils_ins_$operands_instruction(a2);
      if head <> i then begin
        i^.l24 := integer32(head);
        head := i;
      end;
      a2 := a2^.link;
    end;
  end;
  pass := 0;
  for k := 1 to 2 do begin
    p := head;
    while p <> nil do begin
      ok := false;
      if try_both
         and can_adjust_creation_point(p, add^.opnds[2].lts, add, disp, 0)
      then begin
        ok := true;
        b := add^.opnds[2].lts^.def;
      end
      else begin
        b := base_operand(p);
        x := index_operand(p);
        if (x <> nil) and (b <> nil) then
          if b^.lts = add^.opnds[2].lts then begin
            if pass <> 1 then
              ok := mem_ref_positioned_for_postincrement(p, add, try_both,
                                                         disp, 0)
            else if x^.h.kind = operand$immediate then begin
              if mem_ref_positioned_for_postincrement(p, add, try_both, disp,
                                                      -x^.value) then begin
                ok := true;
                delta := 0;
              end
              else if try_both then begin
                ok := mem_ref_positioned_for_postincrement(p, add, try_both,
                        disp, disp - x^.value);
                delta := disp;
              end;
              if ok then
                ok := tr_utils_$try_twiddling_disp(p, delta, false, false);
            end;
          end;
      end;
      if ok then begin
        a2 := b^.link;
        if a2 <> nil then begin
          last := nil;
          repeat
            i := utils_ins_$operands_instruction(a2);
            if i <> add then begin
              t := a2;
              preserve_operation(t, disp);
              a2 := t;
              last := a2;
            end;
            a2 := a2^.link;
          until a2 = nil;
          if last <> nil then begin
            last^.link := add^.opnds[3].link;
            add^.opnds[3].link := b^.link;
            r := add^.opnds[3].link;
            while r <> nil do begin
              r^.lts := add^.opnds[3].lts;
              r := r^.link;
            end;
          end;
        end;
        if (add^.opnds[1].h.kind = operand$ip_reg)
           and (add^.opnds[1].lts = b^.lts) then
          b^.link := addr(add^.opnds[1])
        else
          b^.link := op2;
        lts := add^.opnds[2].lts;
        if (opnd_bytes_ptr_t(b)^.rrp & 12) <> 0 then begin
          if not adjustable_creation_point(lts^.def, -disp, add, false, false,
                                           true) then
            bug_check('TR_UTILS_$autoindex_within_bb: adjustable_creation_point failed%$');
          add^.opnds[2].link := add^.opnds[3].link;
          add^.opnds[3].link := nil;
          r := add^.opnds[2].link;
          while r <> nil do begin
            r^.lts := lts;
            r := r^.link;
          end;
          l3 := add^.opnds[3].lts;
          if l3^.f2.b3_4 then begin
            utils_$move_definition(l3, lts, false);
            utils_$excise_lts_cleanly(add^.opnds[3].lts, false);
            utils_$put_lts_on_final_list(lts);
          end
          else
            utils_$excise_lts_cleanly(l3, false);
          discard(utils_$excise_instruction_cleanly(add, true));
          autoindex_within_bb := true;
          return;
        end;
        if x^.value = 0 then
          mode := 1
        else
          mode := 2;
        transform_to_autoindex(p, b, x, add, mode, false);
        autoindex_within_bb := true;
        return;
      end;
      p := instr_ptr_t(p^.l24);
    end;
    pass := pass + 1;
  end;
  o := add^.opnds[2].lts^.def;
  while o^.link <> nil do
    o := o^.link;
  o^.link := op2;
  autoindex_within_bb := result;
end;

{ autoincrement_solutions_acceptable - whether the solutions' last entry
  (taken off; its segment in b) can take add's increment by disp: one
  of the instructions reading the segment (chained through +24, each
  once) whose creation can absorb disp (can_adjust_creation_point) or
  that is a load or store based on the segment with an immediate index
  positioned for a postincrement (with -index; else, or on a second
  try of the same instruction, disp - index and a displacement twiddle
  by disp when they differ); every other solution's segment then must
  have such an instruction too (its entry's a set to it, or nil for a
  creation), and the twiddle must succeed (tr_utils_$try_twiddling_disp).
  The entry is put back with the instruction found (nil for a creation)
  and the answer is yes.

  0x27F5E0, 0x2C4 bytes, no A5 (its callers'): the frame bytes -58 (a
  second try pending), -60 (twiddle) and -52 (the twiddle's disp). }

function autoincrement_solutions_acceptable(
    sols: tr_sol_ptr_t;
    add: instr_ptr_t;
    disp: integer32): boolean; options(val_param); internal;
var
  result: boolean;
  lts, l2: lts_ptr_t;
  r: opnd_ptr_t;
  head, cur, found, p, i: instr_ptr_t;
  retry: boolean;
  ok: boolean;
  twiddle: boolean;
  tdisp: integer32;
  offset: integer32;
  b, x: opnd_ptr_t;
  s: tr_sol_ptr_t;
  k: integer32;
label
  next_entry, fail;
begin
  result := false;
  lts := sols^.entries[sols^.count].b;
  sols^.count := sols^.count - 1;
  r := lts^.def;
  if r = nil then begin
    autoincrement_solutions_acceptable := false;
    return;
  end;
  head := utils_ins_$operands_instruction(r);
  head^.l24 := 0;
  r := r^.link;
  while r <> nil do begin
    i := utils_ins_$operands_instruction(r);
    if i <> head then begin
      i^.l24 := integer32(head);
      head := i;
    end;
    r := r^.link;
  end;
  retry := false;
  cur := head;
  while cur <> nil do begin
    ok := false;
    twiddle := false;
    tdisp := 0;
    offset := 0;
    found := cur;
    if can_adjust_creation_point(cur, lts, add, disp, offset) then begin
      ok := true;
      found := nil;
    end
    else begin
      b := base_operand(cur);
      x := index_operand(cur);
      if (b <> nil) and (x <> nil) then
        if (b^.lts = lts) and (x^.h.kind = operand$immediate) then begin
          offset := -x^.value;
          if not retry and mem_ref_positioned_for_postincrement(
                               cur, nil, true, disp, offset) then begin
            ok := true;
            twiddle := offset <> 0;
            retry := true;
          end
          else begin
            offset := disp - x^.value;
            tdisp := disp;
            twiddle := tdisp <> x^.value;
            ok := mem_ref_positioned_for_postincrement(cur, nil, true, disp,
                                                       offset);
            retry := false;
          end;
        end;
    end;
    if ok then begin
      s := sols;
      while s <> nil do begin
        for k := 1 to s^.count do begin
          l2 := s^.entries[k].b;
          if l2^.def = nil then begin
            autoincrement_solutions_acceptable := false;
            return;
          end;
          p := utils_ins_$operands_instruction(l2^.def);
          p^.l24 := 0;
          r := l2^.def^.link;
          while r <> nil do begin
            i := utils_ins_$operands_instruction(r);
            if i <> p then begin
              i^.l24 := integer32(p);
              p := i;
            end;
            r := r^.link;
          end;
          while p <> nil do begin
            if can_adjust_creation_point(p, l2, add, disp, offset) then begin
              s^.entries[k].a := nil;
              goto next_entry;
            end;
            b := base_operand(p);
            x := index_operand(p);
            if (b <> nil) and (x <> nil) then
              if (b^.lts = l2) and (x^.h.kind = operand$immediate) then
                if mem_ref_positioned_for_postincrement(p, nil, true, disp,
                                                        offset) then begin
                  s^.entries[k].a := p;
                  goto next_entry;
                end;
            p := instr_ptr_t(p^.l24);
          end;
          goto fail;
        next_entry:
        end;
        s := s^.next;
      end;
      if twiddle then
        if not tr_utils_$try_twiddling_disp(cur, tdisp, false, false) then
          goto fail;
      sols^.count := sols^.count + 1;
      sols^.entries[sols^.count].a := found;
      autoincrement_solutions_acceptable := true;
      return;
    end;
  fail:
    if not retry then
      cur := instr_ptr_t(cur^.l24);
  end;
  autoincrement_solutions_acceptable := result;
end;

{ apply_autoincrement_solutions - each solution's segment takes add's
  increment by disp: an entry without an instruction has its creation
  adjusted by -disp (adjustable_creation_point applied; bug_check when
  it fails), its readers kept; otherwise the entry's load or store (a
  bug when not one) gets a free operand slot modifying lr's final
  segment in the solution's block (utils_$get_final_lts; the base's
  segment, which must be final, taken off the final list, means to
  modify, and gives its definition to the new one when it writes), and
  postmodifies (a zero index becomes disp, mode 1) or premodifies (mode
  2).  The readers of the old base (or creation) follow the new
  segment, each adjusted by disp (preserve_operation); the source
  statements merged with add's.

  0x27F8A4, 0x20E bytes, no A5: an entry's instruction tested by the
  flags of its `move.l' (the next `movea.l' sets none). }

procedure apply_autoincrement_solutions(
    sols: tr_sol_ptr_t;
    lr: lr_ptr_t;
    disp: integer32;
    add: instr_ptr_t); options(val_param); internal;
var
  s: tr_sol_ptr_t;
  k: integer32;
  mem: instr_ptr_t;
  lts, nl: lts_ptr_t;
  readers, n, b, x: opnd_ptr_t;
  created: boolean;
begin
  s := sols;
  while s <> nil do begin
    for k := 1 to s^.count do begin
      mem := s^.entries[k].a;
      lts := s^.entries[k].b;
      if mem = nil then begin
        readers := lts^.def^.link;
        lts^.def^.link := nil;
        if not adjustable_creation_point(lts^.def, -disp, add, false, false,
                                         true) then
          bug_check('TR_UTILS_$apply_autoincrement_solutions: adjustable_creation_point failed%$');
        mem := utils_ins_$operands_instruction(lts^.def);
        nl := lts;
        n := lts^.def;
      end
      else begin
        if not (instruction_attributes[mem^.opc].class
                in [class$load, class$store]) then
          bug_check('TR_UTILS_$apply_autoincrement:  illegal opcode%$');
        b := base_operand(mem);
        lts := b^.lts;
        readers := b^.link;
        b^.link := nil;
        if not lts^.f2.b3_4 then
          bug_check('TR_UTILS_$apply_autoincrement:  can''t find final LTS%$');
        utils_$remove_lts_from_final_list(lts);
        nl := utils_$get_final_lts(lr, s^.entries[k].bb, created);
        n := find_operand_of_kind(mem, 0, 0);
        n^.h.kind := operand$ip_reg;
        n^.link := nil;
        opnd_bytes_ptr_t(n)^.rrp := 4;
        n^.lts := nl;
        nl^.rrp := nl^.rrp + [rrp$modify];
        nl^.def := n;
        lts^.rrp := lts^.rrp + [rrp$intend_to_modify];
        b^.h.intend_to_modify := true;
        if (lts^.rrp * [rrp$modify, rrp$write]) <> [] then
          utils_$move_definition(lts, nl, false);
        x := index_operand(mem);
        if x^.value = 0 then begin
          x^.value := disp;
          mem^.h.width := (mem^.h.width & 16#3F) ! 16#40;
        end
        else
          mem^.h.width := (mem^.h.width & 16#3F) ! 16#80;
      end;
      if readers <> nil then begin
        n^.link := readers;
        nl^.rrp := nl^.rrp + [rrp$read];
        repeat
          readers^.lts := nl;
          preserve_operation(readers, disp);
          readers := readers^.link;
        until readers = nil;
      end;
      utils_$maybe_merge_source_statements(mem, add);
    end;
    s := s^.next;
  end;
end;

{ ok_to_add_auto - no (0): an autoincrement is never added on an edge.
  0x27FB64, 0x16 bytes (loads A5). }

function ok_to_add_auto(
    lts: lts_ptr_t;
    bb: bb_ptr_t;
    arg: univ_ptr;
    out pair: tr_pair_t): integer; options(val_param);
begin
  ok_to_add_auto := 0;
end;

{ validate_lts_for_auto - a segment found for an autoincrement: no (0)
  when it has no def or its block's +17 bit 6 is set; else yes (1)
  with the segment as the pair's b (its a nil).  0x27FB7A, 0x40 bytes. }

function validate_lts_for_auto(
    lts: lts_ptr_t;
    bb: bb_ptr_t;
    arg: univ_ptr;
    out pair: tr_pair_t): integer; options(val_param);
begin
  pair.a := nil;
  if (lts^.def = nil) or bb^.f.b17_6 then
    validate_lts_for_auto := 0
  else begin
    pair.b := lts;
    validate_lts_for_auto := 1;
  end;
end;

{ try_autoincrement - add folded into the loads and stores of its block
  (autoindex_within_bb), or, with try_both, across blocks: operand 2's
  segment (of a live range with a number, exposed or defined by a
  modifying JOIN_BP) has its readers before add adjusted by disp and
  moved to add's result, and add moved before its first reader; then
  every path into the block must reach an acceptable segment
  (find_complex_driving_ltss with validate_lts_for_auto and
  ok_to_add_auto, from the routine's heap mark), the solutions must not
  interfere and take the increment
  (solutions_dont_interfere, autoincrement_solutions_acceptable,
  apply_autoincrement_solutions); add's result's segment (which must
  follow operand 2's: bug_check) is excised, its readers given to
  operand 2's segment (and its place on the final list), and add
  excised; the live range's SSA form recomputed.

  0x27FBBA, 0x2B8 bytes: validate_lts_for_auto and ok_to_add_auto by
  their addresses (`move.l #0x27FB7A', `#0x27FB64'); the routine's
  heap mark (mrh_$mark) kept and not used; print_solutions_for_debugging
  pops 6 of its 8 bytes. }

function try_autoincrement(
    add: instr_ptr_t;
    try_both: boolean;
    disp: integer32): boolean;
var
  lts, l3: lts_ptr_t;
  r, first, op2, last, t: opnd_ptr_t;
  i: instr_ptr_t;
  mark: mrh_$mark_t;
  sols: tr_sol_ptr_t;
  lr: lr_ptr_t;
  lrv: lr_ptr_t;
  serial: integer32;
begin
  if autoindex_within_bb(add, try_both, disp) then begin
    try_autoincrement := true;
    return;
  end;
  if not try_both then begin
    try_autoincrement := false;
    return;
  end;
  lts := add^.opnds[2].lts;
  if lts^.lr^.w4 = 0 then begin
    try_autoincrement := false;
    return;
  end;
  if not lts^.f2.b3_7 then begin
    r := lts^.def;
    if not r^.h.modify then begin
      try_autoincrement := false;
      return;
    end;
    i := utils_ins_$operands_instruction(r);
    if i^.opc <> ord(opc$join_bp) then begin
      try_autoincrement := false;
      return;
    end;
  end;
  tr_utils_$guarantee_operand_order(lts);
  r := lts^.def;
  if r^.h.read then
    first := r
  else
    first := r^.link;
  op2 := addr(add^.opnds[2]);
  if first <> op2 then begin
    r := first;
    repeat
      if not can_preserve_operation(r, disp, 0) then begin
        try_autoincrement := false;
        return;
      end;
      r := r^.link;
    until r = op2;
    l3 := add^.opnds[3].lts;
    r := first;
    repeat
      t := r;
      preserve_operation(t, disp);
      r := t;
      r^.lts := l3;
      last := r;
      r := r^.link;
    until r = op2;
    r := lts^.def;
    if not r^.h.read then
      r := r^.link;
    if r = lts^.def then
      lts^.def := op2
    else
      lts^.def^.link := op2;
    last^.link := add^.opnds[3].link;
    add^.opnds[3].link := r;
    add^.prev^.next := add^.next;
    if add^.next <> nil then
      add^.next^.prev := add^.prev
    else
      add^.bb^.last := add^.prev;
    i := utils_ins_$operands_instruction(r);
    add^.prev := i^.prev;
    if i^.prev <> nil then
      i^.prev^.next := add
    else
      i^.bb^.first := add;
    add^.next := i;
    i^.prev := add;
  end;
  mark := mrh_$mark(tr_heap);
  sols := nil;
  lr := lts^.lr;
  lrv := lr;
  if not find_complex_driving_ltss(lts, lr, lr, lts^.bb,
                                   addr(validate_lts_for_auto),
                                   addr(ok_to_add_auto), serial, addr(lrv),
                                   sols) then begin
    try_autoincrement := false;
    return;
  end;
  print_solutions_for_debugging(lts, sols);
  if not solutions_dont_interfere(sols, add^.bb, lr, serial, false) then begin
    try_autoincrement := false;
    return;
  end;
  if not autoincrement_solutions_acceptable(sols, add, disp) then begin
    try_autoincrement := false;
    return;
  end;
  apply_autoincrement_solutions(sols, lr, disp, add);
  l3 := add^.opnds[3].lts;
  if l3^.next <> lts then
    bug_check('TR_UTILS_$try_autoincrement:  LTS list out of order%$');
  if l3^.f2.b3_4 then begin
    utils_$remove_lts_from_final_list(l3);
    utils_$put_lts_on_final_list(lts);
  end;
  last := nil;
  r := l3^.def^.link;
  while r <> nil do begin
    r^.lts := lts;
    last := r;
    r := r^.link;
  end;
  if last <> nil then begin
    last^.link := add^.opnds[2].link;
    add^.opnds[2].link := l3^.def^.link;
  end;
  l3^.def^.link := nil;
  utils_$excise_lts_cleanly(l3, false);
  lts^.l44 := nil;
  discard(utils_$excise_instruction_cleanly(add, false));
  fg_utils_$recompute_ssa_form_for_lr(lr);
  try_autoincrement := true;
end;

{ could_adjust_hammock_contents - whether lr's final segments in the
  blocks of a hammock (from bb along +106, and the inner hammocks of
  the blocks that have one, +19 bit 7, from their +102) are all
  exposed (any set when there is one) and their readers keep their
  effect when the value changes by disp.

  0x27FEA8, 0x8E bytes, no A5, recursive. }

function could_adjust_hammock_contents(
    bb: bb_ptr_t;
    lr: lr_ptr_t;
    disp: integer32;
    var any: boolean): boolean; options(val_param); internal;
var
  b: bb_ptr_t;
  l: lts_ptr_t;
  r: opnd_ptr_t;
begin
  any := false;
  b := bb;
  while b <> nil do begin
    l := utils_$find_final_lts(lr, b);
    if l <> nil then begin
      if not l^.f2.b3_7 then begin
        could_adjust_hammock_contents := false;
        return;
      end;
      any := true;
      r := l^.def;
      while r <> nil do begin
        if not can_preserve_operation(r, disp, 0) then begin
          could_adjust_hammock_contents := false;
          return;
        end;
        r := r^.link;
      end;
    end;
    if b^.f.b19_7 then
      if not could_adjust_hammock_contents(b^.l102, lr, disp, any) then begin
        could_adjust_hammock_contents := false;
        return;
      end;
    b := b^.l106;
  end;
  could_adjust_hammock_contents := true;
end;

{ adjust_hammock_contents - final's live range's final segments in the
  hammock's blocks (and inner hammocks) chained after final instead of
  their old final segment (+44, +28), their readers adjusted by disp
  (preserve_operation).  0x27FF36, 0xC8 bytes, no A5, recursive. }

procedure adjust_hammock_contents(
    bb: bb_ptr_t;
    final: lts_ptr_t;
    disp: integer32); options(val_param); internal;
var
  b: bb_ptr_t;
  l, f: lts_ptr_t;
  r, t: opnd_ptr_t;
begin
  b := bb;
  while b <> nil do begin
    l := utils_$find_final_lts(final^.lr, b);
    if l <> nil then begin
      if l^.l44 <> nil then begin
        f := l^.l44;
        if f^.l28 = l then
          f^.l28 := l^.l28
        else begin
          f := f^.l28;
          while f^.l28 <> l do
            f := f^.l28;
          f^.l28 := l^.l28;
        end;
      end;
      l^.l44 := final;
      if final <> nil then begin
        l^.l28 := final^.l28;
        final^.l28 := l;
      end;
      r := l^.def;
      while r <> nil do begin
        t := r;
        preserve_operation(t, disp);
        r := t;
        r := r^.link;
      end;
    end;
    if b^.f.b19_7 then
      adjust_hammock_contents(b^.l102, final, disp);
    b := b^.l106;
  end;
end;

{ move_add_to_new_bb - add moved to bb: after anchor (which must be in
  bb: bug_check), else at the tail (before the closing branches,
  classes 1, 5, 6, 24) or at the head (after the JOIN_BPs and labels);
  at the tail, operand 2 reads lr's final segment in bb (a new one
  exposed and chained after the old final) and the result defines a new
  final segment there (the old one, its def moved to it, made exposed
  and excised when nothing defines it); at the head, the result
  defines lr's exposed segment in bb (taken off the exposed list, its
  chains cleared, the old segment's definition moved to it and the old
  segment excised; put on the final list when chained) and operand 2
  reads a new exposed segment chained after operand 2's old final (its
  old segment put on the final list).

  0x27FFFE, 0x3AE bytes, no A5: utils_$remove_reader_from_lts's result
  dropped; the head's segment's def overwritten without its chain. }

procedure move_add_to_new_bb(
    add: instr_ptr_t;
    bb: bb_ptr_t;
    anchor: instr_ptr_t;
    at_tail: boolean); options(val_param); internal;
var
  old: bb_ptr_t;
  p: instr_ptr_t;
  l2, l3, f: lts_ptr_t;
  created: boolean;
  op2: opnd_ptr_t;
  r: opnd_ptr_t;
  was_final: boolean;
begin
  if anchor <> nil then
    if anchor^.bb <> bb then
      bug_check('TR_UTILS_$move_add_to_nebb: prev_instr not in new_bb%$');
  old := add^.bb;
  if add^.prev <> nil then
    add^.prev^.next := add^.next
  else
    old^.first := add^.next;
  if add^.next <> nil then
    add^.next^.prev := add^.prev
  else
    old^.last := add^.prev;
  if anchor <> nil then
    p := anchor^.next
  else if at_tail then begin
    p := bb^.last;
    while p <> nil do begin
      if not (instruction_attributes[p^.opc].class
              in [class$branch, class$fp_branch, class$jump, class$return])
      then
        exit;
      p := p^.prev;
    end;
    if p = nil then
      p := bb^.first
    else
      p := p^.next;
  end
  else begin
    p := bb^.first;
    while p <> nil do begin
      if (p^.opc <> ord(opc$join_bp)) and (p^.opc <> ord(opc$label)) then
        exit;
      p := p^.next;
    end;
  end;
  if p <> nil then begin
    if p^.prev <> nil then
      p^.prev^.next := add
    else
      bb^.first := add;
    add^.prev := p^.prev;
    add^.next := p;
    p^.prev := add;
  end
  else begin
    bb^.last^.next := add;
    add^.prev := bb^.last;
    bb^.last := add;
    add^.next := nil;
  end;
  add^.bb := bb;
  if at_tail then begin
    l2 := utils_$get_final_lts(add^.opnds[2].lts^.lr, bb, created);
    if created then begin
      utils_$put_lts_on_exposed_list(l2);
      l2^.l44 := add^.opnds[2].lts^.l44;
      if l2^.l44 <> nil then begin
        l2^.l28 := l2^.l44^.l28;
        l2^.l44^.l28 := l2;
      end;
    end;
    op2 := addr(add^.opnds[2]);
    discard(utils_$remove_reader_from_lts(op2, false));
    add^.opnds[2].lts := l2;
    if l2^.def = nil then
      l2^.def := op2
    else begin
      r := l2^.def;
      while r^.link <> nil do
        r := r^.link;
      r^.link := op2;
    end;
    add^.opnds[2].link := nil;
    if l2^.f2.b3_4 then begin
      was_final := true;
      utils_$remove_lts_from_final_list(l2);
    end
    else
      was_final := false;
    f := utils_$get_final_lts(add^.opnds[3].lts^.lr, bb, created);
    if was_final and ((l2^.rrp * [rrp$modify, rrp$write]) <> []) then
      utils_$move_definition(l2, f, false);
    l3 := add^.opnds[3].lts;
    utils_$move_definition(l3, f, true);
    l3^.def := l3^.def^.link;
    l3^.rrp := l3^.rrp - [rrp$modify, rrp$write];
    utils_$put_lts_on_exposed_list(l3);
    if l3^.def = nil then
      utils_$excise_lts_cleanly(l3, false);
    f^.def := addr(add^.opnds[3]);
    add^.opnds[3].lts := f;
    add^.opnds[3].link := nil;
    f^.rrp := rrp$set_t(integer(f^.rrp)
                        ! (opnd_bytes_ptr_t(addr(add^.opnds[3]))^.rrp & 12));
  end
  else begin
    l3 := utils_$get_exposed_lts(add^.opnds[3].lts^.lr, bb, created);
    if not created then
      if l3^.l44 <> nil then begin
        f := l3^.l44;
        if f^.l28 = l3 then
          f^.l28 := l3^.l28
        else begin
          while f^.l28 <> l3 do
            f := f^.l28;
          f^.l28 := l3^.l28;
        end;
      end;
    utils_$remove_lts_from_exposed_list(l3);
    l3^.l28 := nil;
    l3^.l44 := nil;
    f := add^.opnds[3].lts;
    utils_$move_definition(f, l3, false);
    if not l3^.f2.b3_4 then
      if (l3^.l28 <> nil) or (l3^.l44 <> nil) then
        utils_$put_lts_on_final_list(l3);
    f^.def := nil;
    utils_$excise_lts_cleanly(f, false);
    add^.opnds[3].lts := l3;
    add^.opnds[3].link := l3^.def;
    l3^.def := addr(add^.opnds[3]);
    l3^.rrp := rrp$set_t(integer(l3^.rrp)
                         ! (opnd_bytes_ptr_t(addr(add^.opnds[3]))^.rrp & 12));
    l2 := utils_$get_exposed_lts(add^.opnds[2].lts^.lr, bb, created);
    f := add^.opnds[2].lts;
    if (f^.rrp * [rrp$modify, rrp$write]) = [] then
      f := f^.l44;
    if f <> nil then begin
      l2^.l44 := f;
      l2^.l28 := f^.l28;
      f^.l28 := l2;
    end;
    utils_$put_lts_on_final_list(add^.opnds[2].lts);
    op2 := addr(add^.opnds[2]);
    discard(utils_$remove_reader_from_lts(op2, false));
    l2^.def := op2;
    add^.opnds[2].lts := l2;
    add^.opnds[2].link := nil;
    if add^.opnds[2].h.intend_to_modify then
      l2^.rrp := l2^.rrp + [rrp$intend_to_modify];
  end;
end;

{ move_add_to_hammock_head - add (in a hammock's join block, +19 bit 6,
  reading an exposed segment of a register defined once) moved to the
  end of the hammock's head (the source of the block's first edge in,
  or that block's +82 when it heads none), unless the head's +14 is 1,
  when the hammock's contents can take the change
  (could_adjust_hammock_contents) and some was found or force; the
  contents adjusted (adjust_hammock_contents).

  0x2803E4, 0xB4 bytes, no A5: adjust_hammock_contents pops 10 of its
  12 bytes. }

function move_add_to_hammock_head(
    add: instr_ptr_t;
    disp: integer32;
    force: boolean): boolean; options(val_param); internal;
var
  bb, head: bb_ptr_t;
  l: lts_ptr_t;
  any: boolean;
  ok: boolean;
begin
  bb := add^.bb;
  if not bb^.f.b19_6 then begin
    move_add_to_hammock_head := false;
    return;
  end;
  if not (add^.opnds[2].h.kind
          in [operand$ip_reg..operand$well_behaved_memory]) then begin
    move_add_to_hammock_head := false;
    return;
  end;
  l := add^.opnds[2].lts;
  if not l^.f2.b3_7 or (l^.def^.link <> nil) then begin
    move_add_to_hammock_head := false;
    return;
  end;
  head := bb^.l26^.source;
  if not head^.f.b19_7 then
    head := head^.l82;
  if head^.f14.b14 = 1 then begin
    move_add_to_hammock_head := false;
    return;
  end;
  any := false;
  ok := could_adjust_hammock_contents(head^.l102, l^.lr, disp, any);
  if not ok or not (force or any) then begin
    move_add_to_hammock_head := false;
    return;
  end;
  adjust_hammock_contents(head^.l102, add^.opnds[3].lts, disp);
  move_add_to_new_bb(add, head, nil, true);
  move_add_to_hammock_head := true;
end;

{ move_add_to_hammock_tail - add (in a hammock's head, +19 bit 7, with a
  final register result) moved to the head of the block after the
  hammock (the target of the block's edge +98, unless its +14 is 2),
  after anchor when given: the hammock's contents must take the change
  by -disp (could_adjust_hammock_contents; when none was found, the
  result's live range must be exposed in that block), and the result's
  readers keep their effect; they are adjusted and moved to operand
  2's segment, the contents adjusted after operand 2's final segment.

  0x280498, 0x178 bytes, no A5. }

function move_add_to_hammock_tail(
    add: instr_ptr_t;
    disp: integer32;
    anchor: instr_ptr_t): boolean; options(val_param); internal;
var
  bb, target: bb_ptr_t;
  l, l2, fin: lts_ptr_t;
  any: boolean;
  ok: boolean;
  neg: integer32;
  r, t, last, op2, o: opnd_ptr_t;
begin
  bb := add^.bb;
  if not bb^.f.b19_7 then begin
    move_add_to_hammock_tail := false;
    return;
  end;
  if not (add^.opnds[3].h.kind
          in [operand$ip_reg..operand$well_behaved_memory]) then begin
    move_add_to_hammock_tail := false;
    return;
  end;
  l := add^.opnds[3].lts;
  if not l^.f2.b3_4 then begin
    move_add_to_hammock_tail := false;
    return;
  end;
  target := bb^.l98^.target;
  if target^.f14.b14 = 2 then begin
    move_add_to_hammock_tail := false;
    return;
  end;
  any := false;
  neg := -disp;
  ok := could_adjust_hammock_contents(bb^.l102, l^.lr, neg, any);
  if not ok then begin
    move_add_to_hammock_tail := false;
    return;
  end;
  if not any then
    if utils_$find_exposed_lts(l^.lr, target) = nil then begin
      move_add_to_hammock_tail := false;
      return;
    end;
  r := add^.opnds[3].link;
  if r <> nil then begin
    repeat
      if not can_preserve_operation(r, neg, 0) then begin
        move_add_to_hammock_tail := false;
        return;
      end;
      r := r^.link;
    until r = nil;
    l2 := add^.opnds[2].lts;
    r := add^.opnds[3].link;
    repeat
      t := r;
      preserve_operation(t, neg);
      r := t;
      r^.lts := l2;
      last := r;
      r := r^.link;
    until r = nil;
    op2 := addr(add^.opnds[2]);
    last^.link := op2;
    if l2^.def = op2 then
      l2^.def := add^.opnds[3].link
    else begin
      o := l2^.def;
      while o^.link <> op2 do
        o := o^.link;
      o^.link := add^.opnds[3].link;
    end;
    add^.opnds[3].link := nil;
  end;
  fin := add^.opnds[2].lts;
  if (fin^.rrp * [rrp$modify, rrp$write]) = [] then
    fin := fin^.l44;
  adjust_hammock_contents(bb^.l102, fin, neg);
  move_add_to_new_bb(add, target, anchor, false);
  move_add_to_hammock_tail := true;
end;

{ tr_utils_$attempt_autoincrement - add (an ADD or SUB whose operands 2
  and 3 are one live range, not setting the condition codes) folded
  into a pre- or postmodification (try_autoincrement: across blocks
  when operand 1 is an immediate, disp its value, negated for a SUB;
  bug_check for another opcode); failing that, moved to the head of
  its hammock and tried again (moved back after its old predecessor
  when that fails), then to the tail and tried again (moved back to
  the head when that fails).

  0x280610, 0x130 bytes: rtn stored at +20 first; disp unset for a
  register operand 1. }

function tr_utils_$attempt_autoincrement(
    rtn: rtn_ptr_t;
    add: instr_ptr_t): boolean;
var
  disp: integer32;
  try_both: boolean;
  prev: instr_ptr_t;
begin
  tr_rtn := rtn;
  if add^.opnds[2].lts^.lr <> add^.opnds[3].lts^.lr then begin
    tr_utils_$attempt_autoincrement := false;
    return;
  end;
  if add^.h.sets_cc then begin
    tr_utils_$attempt_autoincrement := false;
    return;
  end;
  if add^.opnds[1].h.kind = operand$immediate then begin
    if add^.opc = ord(opc$add) then
      disp := add^.opnds[1].value
    else if add^.opc = ord(opc$sub) then
      disp := -add^.opnds[1].value
    else
      bug_check('TR_UTILS_$try_autoincrement:  expected ADD or SUB%$');
    try_both := true;
  end
  else
    try_both := false;
  if try_autoincrement(add, try_both, disp) then begin
    tr_utils_$attempt_autoincrement := true;
    return;
  end;
  if not try_both then begin
    tr_utils_$attempt_autoincrement := false;
    return;
  end;
  prev := add^.prev;
  if move_add_to_hammock_head(add, disp, false) then begin
    if try_autoincrement(add, try_both, disp) then begin
      tr_utils_$attempt_autoincrement := true;
      return;
    end;
    if not move_add_to_hammock_tail(add, disp, prev) then begin
      tr_utils_$attempt_autoincrement := false;
      return;
    end;
  end;
  if move_add_to_hammock_tail(add, disp, nil) then begin
    if try_autoincrement(add, try_both, disp) then begin
      tr_utils_$attempt_autoincrement := true;
      return;
    end;
    discard(move_add_to_hammock_head(add, disp, true));
  end;
  tr_utils_$attempt_autoincrement := false;
end;
