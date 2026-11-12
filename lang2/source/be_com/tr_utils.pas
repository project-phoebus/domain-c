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
      arg: integer32;
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
    arg: integer32;
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
    sols: tr_sol_ptr_t); options(val_param); internal;
begin
end;
