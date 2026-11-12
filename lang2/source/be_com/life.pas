{ life - the LIFE phase of the PRISM back end (lifetimes): a write of
  memory right after a read of the same memory made a modify, every
  live range's segments split into equivalence classes (segments tied
  by a modify, an exposed segment and the final segment that reaches
  it, a join birthpoint and its inputs, the segments that enter the
  routine; the two halves of a register pair tied across their
  classes), each class given a live range of its own (a new pair for
  paired classes), the live ranges' lists rebuilt by block, and the
  reads that a later write in the same instruction modifies marked
  intend_to_modify.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x241BE4  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x241C06  life_$begin_compilation
    --------  0x241C08  life_$end_compilation
    --------  0x241C0A  insert_modifies_for_memory (internal)
    --------  0x241CD6  create_instrs_intend_modifies (internal)
    --------  0x241F88  create_intend_modifies (internal)
    --------  0x241FC8  life_$equivalence_class_parent (internal)
    --------  0x242002  life_$union_lifetimes (internal)
    --------  0x242080  life_$initial_equivalence_classes (internal)
    --------  0x242188  life_$union_reg_pair_operands (internal)
    --------  0x2423A4  life_$get_equivalence_class_lr (internal)
    --------  0x242540  life_$distribute_ltss_to_new_lrs (internal)
    --------  0x24260A  life_$process_routine
    --------  0x24281C  life_$end_routine
    A5 0x486D94: no data the routines use.

  The life_$ routines other than the phase's entries do not load A5
  and nothing outside calls them: internal.

  While the classes are made a segment's fields serve the union-find:
  its lr (+48) is its parent segment (the root's own; nil before it
  is classed), and once its class has a live range, the class root's
  +48 is that live range and its rrp ra_marked (bit 9, set on every
  segment first) is cleared; a class root's mark (+36) is the root of
  the paired class (register pairs); an exposed segment's next_exposed
  (+16) chains the exposed ones.  A live range's l52 is the last of
  the segments distributed to it.

  Not known from the original: every local and parameter name. }
module life;

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
  { A join birthpoint's input (utils.pas's ut_jbi_t): chained from the
    join's operand 3 (its link) at +4. }
  life_jbi_ptr_t = ^life_jbi_t;
  life_jbi_t = record
    next: life_jbi_ptr_t;               { +0 }
    next_op: life_jbi_ptr_t;            { +4 }
    lts: lts_ptr_t;                     { +8 }
    instr: instr_ptr_t;                 { +12 }
  end;

{ life_$begin_compilation - nothing.  0x241C06, 2 bytes. }

procedure life_$begin_compilation;
begin
end;

{ life_$end_compilation - nothing.  0x241C08, 2 bytes. }

procedure life_$end_compilation;
begin
end;

{ insert_modifies_for_memory - for each memory live range (not +3 bit
  7, neither register bit): a segment defined by a write (not operand
  1) whose operand before it reads the same kind of operand of the same
  live range becomes a modify: the read gets intend_to_modify (operand
  and segment), the write's operand and segment lose write for modify,
  and the live range gets modify and intend_to_modify (`or.w #36').

  0x241C0A, 0xCC bytes: rtn (8). }

procedure insert_modifies_for_memory(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  lr: lr_ptr_t;
  lts: lts_ptr_t;
  op: opnd_ptr_t;
  prev: opnd_ptr_t;
begin
  lr := rtn^.lrs;
  while lr <> nil do begin
    if not lr^.f2.b3_7 and ((lr^.rrp * [rrp$fp_reg, rrp$ip_reg]) = []) then begin
      lts := lr^.ltss;
      while lts <> nil do begin
        op := lts^.refs;
        if op <> nil then
          if op^.h.write and (op^.h.num <> 1) then begin
            prev := opnd_ptr_t(integer32(op) - 12);
            if prev^.h.kind = op^.h.kind then
              if prev^.h.read and (prev^.lts^.lr = lr) then begin
                lr^.rrp := lr^.rrp + [rrp$modify, rrp$intend_to_modify];
                prev^.h.intend_to_modify := true;
                prev^.lts^.rrp := prev^.lts^.rrp + [rrp$intend_to_modify];
                opnd_bytes_ptr_t(op)^.rrp :=
                  (opnd_bytes_ptr_t(op)^.rrp & 16#F7) ! 4;
                op^.lts^.rrp := op^.lts^.rrp - [rrp$write] + [rrp$modify];
              end;
          end;
        lts := lts^.next;
      end;
    end;
    lr := lr^.next;
  end;
end;

{ create_instrs_intend_modifies - in instr, a read (not yet
  intend_to_modify) of a live range the instruction also writes, from
  the last operand back, is moved to the end of its segment's
  references (it must come after the other readers' instructions:
  instr_bug_check otherwise) and marked intend_to_modify (operand,
  segment, live range); a write of a live range so read becomes a
  modify.  The live ranges' +3 bit 2 marks "written here" meanwhile.

  0x241CD6, 0x226 bytes: instr (8) in D4.  Three loops over the
  operands by `dbf' (rev889-patterns 17), the second from the last.
  The message's arguments by address: the live range's number, the
  segment's number (a byte widened into a frame longword), the block's
  and the instruction's numbers. }

procedure create_instrs_intend_modifies(
    instr: instr_ptr_t); options(val_param); internal;
var
  k: integer32;
  op: opnd_ptr_t;
  last: opnd_ptr_t;
  p: opnd_ptr_t;
  lts: lts_ptr_t;
  n: integer32;
begin
  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if op^.h.write then
        op^.lts^.lr^.f2.b3_2 := true;
  end;

  for k := instr^.h.nopnds downto 1 do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if (opnd_bytes_ptr_t(op)^.rrp & 16#30) = 16#10 then
        if op^.lts^.lr^.f2.b3_2 then begin
          if op^.link <> nil then begin
            last := op^.link;
            while last^.link <> nil do
              last := last^.link;
            if tr_utils_$relative_instr_position(
                   instr, utils_ins_$operands_instruction(last)) > 0 then begin
              n := op^.lts^.f2.num;
              instr_bug_check('LIFE_$create_instrs_intend_modifies: Reference being made into intend/modify is not last: near line %LD, LTS %3ZWD.%2ZLD, inst %3ZWD:%3ZWD%$',
                              instr^, op^.lts^.lr^.num, n,
                              instr^.bb^.num, instr^.num);
            end;
            last^.link := op;
            lts := op^.lts;
            if lts^.refs = op then
              lts^.refs := op^.link
            else begin
              p := lts^.refs;
              while p^.link <> op do
                p := p^.link;
              p^.link := op^.link;
            end;
            op^.link := nil;
          end;
          op^.h.intend_to_modify := true;
          op^.lts^.rrp := op^.lts^.rrp + [rrp$intend_to_modify];
          op^.lts^.lr^.rrp := op^.lts^.lr^.rrp + [rrp$intend_to_modify];
          op^.lts^.lr^.f2.b3_2 := false;
        end;
  end;

  for k := 1 to instr^.h.nopnds do begin
    op := addr(instr^.opnds[k]);
    if op^.h.kind in [operand$ip_reg..operand$well_behaved_memory] then
      if op^.h.write then begin
        if not op^.lts^.lr^.f2.b3_2 then begin
          opnd_bytes_ptr_t(op)^.rrp :=
            (opnd_bytes_ptr_t(op)^.rrp & 16#F7) ! 4;
          op^.lts^.rrp := op^.lts^.rrp + [rrp$modify];
          op^.lts^.lr^.rrp := op^.lts^.lr^.rrp + [rrp$modify];
        end;
        op^.lts^.lr^.f2.b3_2 := false;
      end;
  end;
end;

{ create_intend_modifies - create_instrs_intend_modifies for every
  instruction of every block.  0x241F88, 0x40 bytes: rtn (8). }

procedure create_intend_modifies(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  bb: bb_ptr_t;
  instr: instr_ptr_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    instr := bb^.first;
    while instr <> nil do begin
      create_instrs_intend_modifies(instr);
      instr := instr^.next;
    end;
    bb := bb^.next;
  end;
end;

{ life_$equivalence_class_parent - the root of lts's class (lts itself
  when it has no parent yet), the path to it compressed.

  0x241FC8, 0x3A bytes: lts (8); A0. }

function life_$equivalence_class_parent(
    lts: lts_ptr_t): lts_ptr_t; options(val_param); internal;
var
  root: lts_ptr_t;
  l: lts_ptr_t;
  up: lts_ptr_t;
begin
  l := lts;
  root := lts_ptr_t(lts^.lr);
  if root <> nil then begin
    while lts_ptr_t(root^.lr) <> root do
      root := lts_ptr_t(root^.lr);
    while l <> root do begin
      up := lts_ptr_t(l^.lr);
      l^.lr := lr_ptr_t(root);
      l := up;
    end;
  end;
  life_$equivalence_class_parent := l;
end;

{ life_$union_lifetimes - a's and b's classes joined: b's root under
  a's (a's root made a root first when neither had a parent), or a's
  under b's when only a's root is new; the root kept takes the other's
  paired class when it has none.

  0x242002, 0x7E bytes: a (8), b (12). }

procedure life_$union_lifetimes(
    a: lts_ptr_t;
    b: lts_ptr_t); options(val_param); internal;
var
  pa: lts_ptr_t;
  pb: lts_ptr_t;
begin
  if a = b then
    return;
  a := life_$equivalence_class_parent(a);
  b := life_$equivalence_class_parent(b);
  if a = b then
    return;
  pa := lts_ptr_t(a^.lr);
  pb := lts_ptr_t(b^.lr);
  if (integer32(pa) ! integer32(pb)) = 0 then
    a^.lr := lr_ptr_t(a)
  else if pa = nil then begin
    a^.lr := lr_ptr_t(b);
    if b^.mark = 0 then
      b^.mark := a^.mark;
    return;
  end
  else if pb <> nil then
    a^.lr := lr_ptr_t(a);
  b^.lr := lr_ptr_t(a);
  if a^.mark = 0 then
    a^.mark := b^.mark;
end;

{ life_$initial_equivalence_classes - lr's segments made singletons
  (ra_marked, no parent; the exposed ones chained at next_exposed, the
  others' mark cleared), a segment that intends to modify joined with
  the one before it; then each exposed segment (mark cleared) joined
  with the final segment that reaches it (l44), or with a join
  birthpoint's inputs (its definition opcode JOIN_BP: operand 3's
  link), or else with the first such exposed segment.  lr is emptied
  (rrp bits 11..2 cleared: `andi.w #0xF003', +3 bit 4, id, segments,
  l52, count, exposed and final lists); its old segments' list.

  0x242080, 0x108 bytes: lr (8) in D3; the previous segment at (-12),
  the first unjoined exposed one in D2.  The old list is read back
  from lr's +36 just before it is cleared. }

function life_$initial_equivalence_classes(
    lr: lr_ptr_t): lts_ptr_t; options(val_param); internal;
var
  exposed: lts_ptr_t;
  prev: lts_ptr_t;
  first: lts_ptr_t;
  lts: lts_ptr_t;
  nx: lts_ptr_t;
  instr: instr_ptr_t;
  j: life_jbi_ptr_t;
  joined: boolean;
begin
  exposed := nil;
  prev := nil;
  first := nil;
  lts := lr^.ltss;
  while lts <> nil do begin
    if lts^.f2.exposed then begin
      lts^.next_exposed := exposed;
      exposed := lts;
    end
    else
      lts^.mark := 0;
    lts^.rrp := lts^.rrp + [rrp$ra_marked];
    lts^.lr := nil;
    if rrp$intend_to_modify in lts^.rrp then
      life_$union_lifetimes(lts, prev);
    prev := lts;
    lts := lts^.next;
  end;
  while exposed <> nil do begin
    exposed^.mark := 0;
    nx := exposed^.next_exposed;
    if exposed^.l44 <> nil then begin
      life_$union_lifetimes(exposed, lts_ptr_t(exposed^.l44));
      joined := true;
    end
    else if exposed^.refs <> nil then begin
      instr := utils_ins_$operands_instruction(exposed^.refs);
      if instr^.opc = ord(opc$join_bp) then begin
        j := life_jbi_ptr_t(instr^.opnds[3].link);
        while j <> nil do begin
          life_$union_lifetimes(exposed, j^.lts);
          j := j^.next_op;
        end;
        joined := true;
      end
      else
        joined := false;
    end
    else
      joined := false;
    if not joined then begin
      if first = nil then
        first := exposed
      else
        life_$union_lifetimes(exposed, first);
    end;
    exposed := nx;
  end;
  life_$initial_equivalence_classes := lr^.ltss;
  lr^.rrp := lr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only,
                        rrp$unique_value, rrp$safe_base_address, rrp$fp_reg,
                        rrp$ip_reg];
  lr^.f2.b3_4 := false;
  lr^.id := 0;
  lr^.ltss := nil;
  lr^.l52 := nil;
  lr^.w56 := 0;
  lr^.exposed := nil;
  lr^.finals := nil;
end;

{ life_$union_reg_pair_operands - for the halves' classes (c1 the even
  half's list, c2 the odd's: swapped when c1's first segment is odd
  only), each fp_reg_pair reference of the even half's segments: in
  its instruction, the even fp_reg_pair operand that is the reference
  is matched with the next odd fp_reg_pair operand after the results
  (the scan continues where the last match left it), and the two
  classes' roots become each other's paired class (mark), or are
  joined with the class already paired.

  0x242188, 0x188 bytes: c1 (8, reused for the list walked), c2 (12);
  the reference at (-8).  bug_check when no odd operand is left or no
  operand is the reference (each followed by the next operand or
  reference). }

procedure life_$union_reg_pair_operands(
    c1: lts_ptr_t;
    c2: lts_ptr_t); options(val_param); internal;
label
  10, 20;
var
  p: lts_ptr_t;
  ref: opnd_ptr_t;
  instr: instr_ptr_t;
  k: integer32;
  j: integer32;
  ra: lts_ptr_t;
  rb: lts_ptr_t;
begin
  if (c1 = nil) or (c2 = nil) then
    return;
  p := c1;
  if rrp$fp_reg_odd_only in c1^.rrp then
    p := c2;
  while p <> nil do begin
    ref := p^.refs;
    while ref <> nil do begin
      if ref^.h.kind = operand$fp_reg_pair then begin
        instr := utils_ins_$operands_instruction(ref);
        j := instruction_attributes[instr^.opc].nresults;
        k := 1;
        while k <= instr^.h.nopnds do begin
          if (instr^.opnds[k].h.kind = operand$fp_reg_pair)
             and instr^.opnds[k].h.fp_reg_even_only then begin
            while j < instr^.h.nopnds do begin
              j := j + 1;
              if (instr^.opnds[j].h.kind = operand$fp_reg_pair)
                 and instr^.opnds[j].h.fp_reg_odd_only then begin
                if addr(instr^.opnds[k]) <> ref then
                  goto 10;
                ra := life_$equivalence_class_parent(p);
                rb := life_$equivalence_class_parent(instr^.opnds[j].lts);
                if rb^.mark <> 0 then
                  life_$union_lifetimes(ra, lts_ptr_t(rb^.mark))
                else
                  rb^.mark := integer32(ra);
                if ra^.mark <> 0 then
                  life_$union_lifetimes(rb, lts_ptr_t(ra^.mark))
                else
                  ra^.mark := integer32(rb);
                goto 20;
              end;
            end;
            bug_check('LIFE_$UNION_REG_PAIR_OPERANDS -- fp_reg_pair odd_only operand not found%$');
          end;
10:
          k := k + 1;
        end;
        bug_check('LIFE_$UNION_REG_PAIR_OPERANDS -- no operand corresponds to LTS argument%$');
      end;
20:
      ref := ref^.link;
    end;
    p := p^.next;
  end;
end;

{ life_$get_equivalence_class_lr - the live range for lts's class
  (lts of lr, whose register pair mate is mate): a class member
  already given one (ra_marked clear) answers its +48; else, for a
  class with a paired class: lr and mate themselves when both are
  still empty (made mates), the paired class's live range's mate when
  it has one (bug_check unless), or a new fp_reg_pair live range (its
  odd half when lr is odd only) taking lr's and mate's +20 and sym
  (sym kept only when both are unique_value), the paired class's root
  getting the other half; for an unpaired class: lr itself when still
  empty, else a new live range of lr's kind (ip_reg bit 15, fp_reg bit
  14, else memory) with lr's +20 and sym (sym only when unique_value)
  and lr's rrp unique_value and safe_base_address.  The class root
  takes the live range.

  0x2423A4, 0x166 bytes: lr (8) in D3, mate (12) in D2, lts (16); A0.
  The answer of a marked member is returned from inside the walk to
  the root (`bra' to the epilogue). }

function life_$get_equivalence_class_lr(
    lr: lr_ptr_t;
    mate: lr_ptr_t;
    lts: lts_ptr_t): lr_ptr_t; options(val_param); internal;
var
  root: lts_ptr_t;
  other: lts_ptr_t;
  r: lts_ptr_t;
  nlr: lr_ptr_t;
begin
  root := lts;
  if root^.lr <> nil then
    while lts_ptr_t(root^.lr) <> root do begin
      if not (rrp$ra_marked in root^.rrp) then begin
        life_$get_equivalence_class_lr := root^.lr;
        return;
      end;
      root := lts_ptr_t(root^.lr);
    end;
  other := lts_ptr_t(root^.mark);
  if other <> nil then begin
    if (lr^.ltss = nil) and (mate^.ltss = nil) then begin
      lr^.mate := mate;
      mate^.mate := lr;
      nlr := lr;
    end
    else begin
      r := other;
      if r^.lr <> nil then
        while lts_ptr_t(r^.lr) <> r do begin
          if not (rrp$ra_marked in r^.rrp) then begin
            nlr := r^.lr^.mate;
            if nlr = nil then
              bug_check('LIFE_$GET_EQUIVALENCE_CLASS_LR: mismatched reg pair%$');
            life_$get_equivalence_class_lr := nlr;
            return;
          end;
          r := lts_ptr_t(r^.lr);
        end;
      if not (rrp$unique_value in lr^.rrp)
         or not (rrp$unique_value in mate^.rrp) then begin
        lr^.sym := nil;
        mate^.sym := nil;
      end;
      nlr := lir_$new_live_range_fp_reg_pair;
      if rrp$fp_reg_odd_only in lr^.rrp then
        nlr := nlr^.mate;
      nlr^.node20 := lr^.node20;
      nlr^.mate^.node20 := mate^.node20;
      nlr^.sym := lr^.sym;
      nlr^.mate^.sym := mate^.sym;
    end;
    other^.rrp := other^.rrp - [rrp$ra_marked];
    other^.lr := nlr^.mate;
  end
  else if lr^.ltss = nil then
    nlr := lr
  else begin
    if not (rrp$unique_value in lr^.rrp) then
      lr^.sym := nil;
    if rrp$ip_reg in lr^.rrp then
      nlr := lir_$new_live_range_ip_reg
    else if rrp$fp_reg in lr^.rrp then
      nlr := lir_$new_live_range_fp_reg
    else
      nlr := lir_$new_live_range;
    nlr^.node20 := lr^.node20;
    nlr^.sym := lr^.sym;
    nlr^.rrp := nlr^.rrp
                + (lr^.rrp * [rrp$unique_value, rrp$safe_base_address]);
  end;
  root^.rrp := root^.rrp - [rrp$ra_marked];
  root^.lr := nlr;
  life_$get_equivalence_class_lr := nlr;
end;

{ life_$distribute_ltss_to_new_lrs - each segment of the list lts
  given its class's live range: appended to its segments (l52 the
  last), numbered (the count's low byte), unpaired segments of a pair
  losing even_only / odd_only (their references too), the live range
  taking its rrp; an exposed one makes the live range (and its mate)
  complex with +3 bit 4.

  0x242540, 0xCA bytes: rtn (8) in D4, lts (12) in D3, lr (16), mate
  (20) in D2. }

procedure life_$distribute_ltss_to_new_lrs(
    rtn: rtn_ptr_t;
    lts: lts_ptr_t;
    lr: lr_ptr_t;
    mate: lr_ptr_t); options(val_param); internal;
var
  nx: lts_ptr_t;
  nlr: lr_ptr_t;
  op: opnd_ptr_t;
begin
  while lts <> nil do begin
    nx := lts^.next;
    nlr := life_$get_equivalence_class_lr(lr, mate, lts);
    lts^.lr := nlr;
    lts^.rrp := lts^.rrp - [rrp$ra_marked];
    if nlr^.l52 = nil then
      nlr^.ltss := lts
    else
      lts_ptr_t(nlr^.l52)^.next := lts;
    nlr^.l52 := lr_ptr_t(lts);
    lts^.next := nil;
    nlr^.w56 := nlr^.w56 + 1;
    lts^.f2.num := nlr^.w56 & 255;
    if (mate <> nil) and (nlr^.mate = nil) then begin
      op := lts^.refs;
      while op <> nil do begin
        opnd_bytes_ptr_t(op)^.rrp := opnd_bytes_ptr_t(op)^.rrp & 16#FC;
        op := op^.link;
      end;
      lts^.rrp := lts^.rrp - [rrp$fp_reg_even_only, rrp$fp_reg_odd_only];
    end;
    nlr^.rrp := nlr^.rrp + lts^.rrp;
    if lts^.f2.exposed then begin
      nlr^.f2.b3_4 := true;
      bv_$make_live_range_complex(rtn, nlr);
      if nlr^.mate <> nil then
        bv_$make_live_range_complex(rtn, nlr^.mate);
    end;
    lts := nx;
  end;
end;

{ life_$process_routine - the phase.

  0x24260A, 0x212 bytes: rtn (8) in D3.  The sanity check, the bit
  vectors released, extraneous modifies stripped, memory modifies
  inserted; the routine's +192 cleared.  Each live range up to the
  routine's +200 (its number, unsigned, above it ends the walk), its
  id cleared: the second of a pair (life_mark) just loses the mark;
  others but +3 bit 7 and the routine's +108, +112 and +144 are split
  into classes (a pair together, the mate marked).  Then each live
  range's exposed and final lists cleared (a live range without a mate
  loses even_only / odd_only); its segments either lose final (no
  exposed use, +3 bit 4) or go on their blocks' exposed and final
  lists, the live range taking their even_only / odd_only; a live range
  of +3 bit 7 or bit 4 made complex, and those at the routine's +144,
  +100, +108 and +112.  The intend_to_modify marks; lir_main_c86 := 0
  (the lists by block). }

procedure life_$process_routine(
    rtn: rtn_ptr_t);
var
  last: integer32;
  lr: lr_ptr_t;
  m: lr_ptr_t;
  c1: lts_ptr_t;
  c2: lts_ptr_t;
  lts: lts_ptr_t;
  bb: bb_ptr_t;
begin
  lir_utils_$sanity_check(rtn);
  bv_$release_bit_vectors(rtn);
  utils_$strip_extraneous_modifies(rtn);
  insert_modifies_for_memory(rtn);
  rtn^.l192 := 0;
  last := rtn^.l200;
  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.id := 0;
    if lr^.num > last then
      exit;
    if rrp$life_mark in lr^.rrp then
      lr^.rrp := lr^.rrp - [rrp$life_mark]
    else if not lr^.f2.b3_7 and (lr <> rtn^.lr108)
            and (lr <> lr_ptr_t(rtn^.l112)) and (lr <> rtn^.memory_lr) then begin
      m := lr^.mate;
      if m <> nil then begin
        lr^.mate := nil;
        m^.mate := nil;
        c1 := life_$initial_equivalence_classes(lr);
        c2 := life_$initial_equivalence_classes(m);
        life_$union_reg_pair_operands(c1, c2);
        life_$distribute_ltss_to_new_lrs(rtn, c1, lr, m);
        life_$distribute_ltss_to_new_lrs(rtn, c2, m, lr);
        m^.rrp := m^.rrp + [rrp$life_mark];
      end
      else begin
        c1 := life_$initial_equivalence_classes(lr);
        life_$distribute_ltss_to_new_lrs(rtn, c1, lr, nil);
      end;
    end;
    lr := lr^.next;
  end;

  lr := rtn^.lrs;
  while lr <> nil do begin
    lr^.exposed := nil;
    lr^.finals := nil;
    if lr^.mate = nil then
      lr^.rrp := lr^.rrp - [rrp$fp_reg_even_only, rrp$fp_reg_odd_only];
    lts := lr^.ltss;
    if not lr^.f2.b3_4 then
      while lts <> nil do begin
        lts^.f2.final := false;
        lr^.rrp := lr^.rrp
                   + (lts^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only]);
        lts := lts^.next;
      end
    else
      while lts <> nil do begin
        bb := lts^.bb;
        if lts^.f2.exposed then begin
          lts^.next_exposed := bb^.exposed;
          bb^.exposed := lts;
        end;
        if lts^.f2.final then begin
          lts^.next_final := bb^.finals;
          bb^.finals := lts;
        end;
        lr^.rrp := lr^.rrp
                   + (lts^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only]);
        lts := lts^.next;
      end;
    if lr^.f2.b3_7 or lr^.f2.b3_4 then
      bv_$make_live_range_complex(rtn, lr);
    lr := lr^.next;
  end;
  bv_$make_live_range_complex(rtn, rtn^.memory_lr);
  bv_$make_live_range_complex(rtn, rtn^.ap_lr);
  bv_$make_live_range_complex(rtn, rtn^.lr108);
  bv_$make_live_range_complex(rtn, lr_ptr_t(rtn^.l112));
  create_intend_modifies(rtn);
  lir_main_c86 := 0;
end;

{ life_$end_routine - nothing.  0x24281C, 2 bytes. }

procedure life_$end_routine(
    rtn: rtn_ptr_t);
begin
end;
