{ jmp_br_resolve - branch shortening for the m68k back end (cc.m68k
  only).  jmp_br_setup walks a section's code cells, giving each its
  location twice (+12 as assembled, +16 at the worst case), and chains
  the labels and the branches (+20 from the section's +28) and the
  inline constants (from +32).  jmp_br_resolve then, for each section:
  pads the end to 4 (-ALIGN); moves inline constants nearer to the code
  that reaches them PC-relatively when the section passes 32K
  (ensure_inline_consts_are_reachable: a copy after an rts or a bra
  within 30000 bytes); then passes over the chain until nothing changes:
  each branch whose target is within a byte keeps its short form, a
  branch within a word gets the word form, a farther one the long form
  (bra.l and Bcc.l with -CPU M020, else a jmp, a reversed Bcc around a
  jmp, a dbcc to a jmp, a case jump through a jmp), the changes in size
  carried to the cells after (drop_update); an alignment is dropped or
  becomes a nop.  Last the labels are numbered or their temporary label
  nodes given their addresses, the inline constants placed, and the
  section's size and offset set (emit's +0x108, the code's size so far,
  rounded to 4).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0BA830  --------  observe_that_offset_is_negative (internal)
    0x0BA842  --------  observe_that_offset_is_positive (internal)
    0x0BA852  --------  assert_byte_reach_is_possible (internal)
    0x0BA86E  --------  assert_word_reach_is_possible (internal)
    0x0BA88A  --------  assert_is_forward_of (internal)
    0x0BA8A6  --------  jmp_br_setup
    0x0BAAB4  --------  drop_update (in jmp_br_resolve)
    0x0BAB10  --------  make_long_jmp (in jmp_br_resolve)
    0x0BAC28  --------  make_long_cbr (in jmp_br_resolve)
    0x0BAD38  --------  make_long_dbcc (in jmp_br_resolve)
    0x0BAE66  --------  make_long_casejmp (in jmp_br_resolve)
    0x0BAF40  --------  add_size_of_inst_to_pc (in jmp_br_resolve)
    0x0BAFD0  --------  update_const_approximate_pcs (in jmp_br_resolve)
    0x0BB03E  --------  calc_const_approximate_pcs (in jmp_br_resolve)
    0x0BB054  --------  check_for_deferred_ref (in jmp_br_resolve)
    0x0BB0F4  --------  update_refs_from_here_forward (in jmp_br_resolve)
    0x0BB18A  --------  assert_available_hole (in ensure_inline_consts_are_reachable)
    0x0BB1C0  --------  ensure_inline_consts_are_reachable (in jmp_br_resolve)
    0x0BB470  --------  resolve_inline_const_addrs (in jmp_br_resolve)
    0x0BB4E8  --------  calc_psect_size (in jmp_br_resolve)
    0x0BB57A  --------  jmp_br_resolve
    A5 0x2CE8BC (instr_reorder.pas has the same): +0 the branch's
    reference cell, +4 its target label, +8 the cell at hand, +12 the
    passes, +20 the label being numbered, +24 the section.  Absolute:
    emit's +0x108 (0x2CE7B0, the code's size so far), celpkg's empty
    address descriptor (+24, 0x2CE68C), il_10c (the sections), cargs's
    options.

  The five small routines load no A5 (internal); the observe_ and
  assert_byte/word ones have no frame (docs/rev889-patterns.md 16).
  The routines nested in jmp_br_resolve run on its frame (the shifts at
  -36 and -32, the last cell kept at -56, the change flag at -60).

  The code cells are read through a view of their own (jb_cell_t: the
  two locations, the chain, the descriptors' words as pointers), the
  sections through jb_sect_t.

  Not known from the original: every name but the routines'; what +16
  of the module's data held; the op values (37 the jump fnl_slct makes,
  5 the nop, 119 and 123 the absolute and PC-relative jmp/jsr, 208 an
  alignment's).
}
module jmp_br_resolve;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';

type
  { A reference cell (celpkg's getrefcell, 16 bytes): on its label's
    list; from the cell that refers, owner the label cell. }
  jb_ref_ptr_t = ^jb_ref_t;
  jb_cell_ptr_t = ^jb_cell_t;
  jb_ref_t = record
    next: jb_ref_ptr_t;                 { +0 }
    prev: jb_ref_ptr_t;                 { +4 }
    from: jb_cell_ptr_t;                { +8 }
    owner: jb_cell_ptr_t;               { +12 }
  end;

  { A code cell as branch shortening reads it (codegen_$cell_t): the
    instruction's size, its location as assembled (+12) and at the
    worst case (+16), the chain of labels and branches (or of inline
    constants), the descriptors (their x and y words are a branch's
    temporary label node and reference cell, a PC-relative reference's
    reference cell and displacement), the instruction. }
  jb_cell_t = record
    next: jb_cell_ptr_t;                { +0 }
    prev: jb_cell_ptr_t;                { +4 }
    kind: integer;                      { +8 }
    size: 0..65535;                     { +10 }
    pc: integer32;                      { +12 }
    pc2: integer32;                     { +16 }
    link: jb_cell_ptr_t;                { +20 }
    case integer of
      0: (ads1: codegen_$ads_t;         { +24 }
          ads2: codegen_$ads_t;         { +36 }
          op: integer;                  { +48 }
          w50: integer);                { +50 }
      1: (f24: integer32;               { +24 }
          ref1: jb_ref_ptr_t;           { +28 }
          ref1y: jb_ref_ptr_t;          { +32: a case jump's table }
          f36: integer32;               { +36 }
          lab2: il_$node_ptr_t;         { +40 }
          ref2: jb_ref_ptr_t);          { +44 }
      2: (g24: integer32;               { +24 }
          lab1: il_$node_ptr_t;         { +28 }
          disp1: integer32;             { +32 }
          g36: integer32;               { +36 }
          g40: integer32;               { +40 }
          num2: integer32);             { +44 }
      3: (h24: integer32;               { +24 }
          h28: integer32;               { +28 }
          h32: integer32;               { +32 }
          h36: integer32;               { +36 }
          ref2x: jb_ref_ptr_t);         { +40: a PC-relative reference }
  end;

  { A section (il_10c's list): its size and offset, its code cells
    (the head cell), the chains jmp_br_setup builds and the locations it
    counts. }
  jb_sect_ptr_t = ^jb_sect_t;
  jb_sect_t = record
    unused_0: integer32;                { +0 }
    next: jb_sect_ptr_t;                { +4 }
    unused_8: integer32;                { +8 }
    size: integer32;                    { +12 }
    offset: integer32;                  { +16 }
    head: jb_cell_ptr_t;                { +20 }
    tail: jb_cell_ptr_t;                { +24 }
    labels: jb_cell_ptr_t;              { +28 }
    consts: jb_cell_ptr_t;              { +32 }
    pc: integer32;                      { +36 }
    pc2: integer32;                     { +40 }
    last_label: jb_cell_ptr_t;          { +44 }
    last_const: jb_cell_ptr_t;          { +48 }
  end;

  { A place an inline constant may go: after cell, at location pc. }
  jb_hole_t = record
    cell: jb_cell_ptr_t;
    pc: integer32;
  end;

var
  ref: jb_ref_ptr_t;                    { +0 }
  lab: jb_cell_ptr_t;                   { +4 }
  cur: jb_cell_ptr_t;                   { +8 }
  pass: integer32;                      { +12 }
  unused_16: integer32;                 { +16 }
  lbl: jb_cell_ptr_t;                   { +20 }
  sect: jb_sect_ptr_t;                  { +24 }

  { celpkg.pas's empty descriptor (its +24, which the image copies from
    0x2CE68C): celpkg does not export it, so a copy here. }
  null_ads: codegen_$ads_t := [f1 := 0, f2 := 0, f3 := 0, f4 := 0,
      f5 := 0, f6 := 0, pad := 0, x := 0, y := 0];

  { emit.pas's data (A5 0x2CE6A8) +0x108..+0x11B, as outbin.pas and
    unix_objmod.pas declare them: +0x108 the code's size so far. }
  emit_108: extern record
    e108: integer32;
    e10c: integer32;
    e110: integer32;
    e114: integer32;
    e118: integer32;
  end;

  { cg_misc's empty unpacked descriptor (cg.ins.pas, 0x356600). }
  cg_null_ads: extern codegen_$uads_t;

{ observe_that_offset_is_negative, observe_that_offset_is_positive -
  off := -|delta|, |delta|.

  0x0BA830, 0x12 bytes; 0x0BA842, 0x10: no frame, no A5 (`move.l
  (8,SP)', `neg.l'). }

procedure observe_that_offset_is_negative(
    var off: integer32;
    delta: integer32); options(val_param); internal;
begin
  if delta < 0 then
    off := delta
  else
    off := -delta;
end;

procedure observe_that_offset_is_positive(
    var off: integer32;
    delta: integer32); options(val_param); internal;
begin
  if delta < 0 then
    off := -delta
  else
    off := delta;
end;

{ assert_byte_reach_is_possible, assert_word_reach_is_possible - d fits
  a signed byte, word.

  0x0BA852, 0x0BA86E, 0x1C bytes each: no frame (`blt', `sle'). }

function assert_byte_reach_is_possible(
    d: integer32): boolean; options(val_param); internal;
begin
  assert_byte_reach_is_possible := (d >= -128) and (d <= 127);
end;

function assert_word_reach_is_possible(
    d: integer32): boolean; options(val_param); internal;
begin
  assert_word_reach_is_possible := (d >= -32768) and (d <= 32767);
end;

{ assert_is_forward_of - a beyond b.

  0x0BA88A, 0x1C bytes: `cmp.l; sgt'. }

function assert_is_forward_of(
    a: integer32;
    b: integer32): boolean; options(val_param); internal;
begin
  assert_is_forward_of := a > b;
end;

{ jmp_br_setup - the cells of sect from first located (+12, +16 at the
  worst case: 6 for a branch, 10 for a dbcc, 2 for an alignment) and
  the labels, branches and alignments chained (+20 from +28, the last at
  +44), the inline constants too (from +32, the last at +48); a branch
  to the next instruction removed.

  0x0BA8A6, 0x20E bytes: an alignment of op 208 (kind 34) sized 0; line
  numbers and block marks (24, 33, 32) skipped; a cell with no label
  operand (+36 bits 7..3 not 7) that is not a label or an alignment of
  op 208 just counted (`sne; sne; and.b'); a br, cbr or fbr whose
  target's next code cell (nxtcc) is its own detached; the kinds in a
  compare chain in the order 17, 31, 18, 23, 39, 30, 0, 34, 16, 20
  (16 and 20 as the others: counted at their size, not chained). }


procedure jmp_br_setup;
var
  s: jb_sect_ptr_t;
  chained: boolean;
  t: codegen_$cell_ptr_t;
begin
  s := psect;
  cur := first;
  while cur <> s^.head do begin
    if (cur^.kind = align_instyp) and (cur^.op = 208) then
      cur^.size := 0;
    if cur^.kind = inline_instyp then begin
      if s^.consts = nil then
        s^.consts := cur
      else
        s^.last_const^.link := cur;
      cur^.link := nil;
      s^.last_const := cur;
    end;
    if (cur^.kind = line_no_instyp) or (cur^.kind = block_end_instyp) or
       (cur^.kind = block_start_instyp) then
      cur := cur^.next
    else if (cur^.ads2.f1 <> 7) and (cur^.kind <> def_lbl_instyp) and
            not ((cur^.kind = align_instyp) and (cur^.op = 208)) then begin
      s^.pc := s^.pc + cur^.size;
      s^.pc2 := s^.pc2 + cur^.size;
      cur := cur^.next;
    end
    else begin
      if (cur^.kind = br_instyp) or (cur^.kind = cbr_instyp) or
         (cur^.kind = fbr_instyp) then begin
        ref := cur^.ref2;
        t := nxtcc(codegen_$cell_ptr_t(ref^.owner));
        if t = nxtcc(codegen_$cell_ptr_t(cur)) then begin
          lab := cur^.next;
          detach(codegen_$cell_ptr_t(cur));
          cur := lab;
          next;
        end;
      end;
      cur^.pc := s^.pc;
      cur^.pc2 := s^.pc2;
      s^.pc := s^.pc + cur^.size;
      chained := true;
      case cur^.kind of
        br_instyp, bsr_instyp, cbr_instyp: s^.pc2 := s^.pc2 + 6;
        dbcc_instyp: s^.pc2 := s^.pc2 + 10;
        fbr_instyp: s^.pc2 := s^.pc2 + 6;
        casejmp_instyp: s^.pc2 := s^.pc2 + 6;
        def_lbl_instyp: ;
        align_instyp: s^.pc2 := s^.pc2 + 2;
        dest1_instyp, link_instyp: begin
          s^.pc2 := s^.pc2 + cur^.size;
          chained := false;
        end;
        otherwise begin
          s^.pc2 := s^.pc2 + cur^.size;
          chained := false;
        end;
      end;
      if chained then begin
        if s^.labels = nil then
          s^.labels := cur
        else
          s^.last_label^.link := cur;
        cur^.link := nil;
        s^.last_label := cur;
      end;
      cur := cur^.next;
    end;
  end;
end;

{ jmp_br_resolve - every section's branches given their sizes, its
  inline constants placed, its labels numbered, its size and offset set.

  0x0BB57A, 0x8AA bytes: emit's +0x108 cleared; for each section of
  il_10c: under -ALIGN (cargs +0x288 bit 7) an alignment cell (kind 34,
  op 208, celpkg's empty descriptors, ilength's size) appended and set
  up; ensure_inline_consts_are_reachable; +12 := 1, then passes (+12
  counted) over the chain until a pass changes nothing (-60): the shifts
  so far (-36, -32) added to each cell's locations; a label kept; an
  alignment, while no branch has been kept in the pass (-58), dropped
  when its location is a multiple of 4 and its op 208 (delinked and
  unchained), else made a nop (kind 4, op 5, size 2, the descriptors'
  +0 to mode 1 register 8) and dropped from the chain with 2 or 0 added;
  a branch's target label (+4, through its reference cell +0) located,
  with the shifts when it lies ahead (assert_is_forward_of); the
  distance from the branch's end (+2), or for a case jump from its table
  (+32's label); then by kind (a compare chain: 31, 18, 17; 23; 39;
  30):
  - bsr, cbr, br: within a byte at the worst case 4 less; else when not
    within a word and not -CPU M020 (+0x285 bit 5) the long form: a br a
    jmp (4 bytes, kind 3, op 123, make_long_jmp), a cbr around a jmp
    (make_long_cbr, op less 14 when its size is not 2), a bsr a jsr (6
    bytes absolute, op 119, under -ABS: +0x287 bit 2; else 4 bytes
    off A5 with the routine block's own A5 (+375 bit 3; cgerr 28 'DB not
    valid' without)); else unless within a byte the word form (4, op +1;
    or 6 and op +2 or +28 for -CPU M020 beyond a word; Bcc's op +14) and
    a M020 word branch beyond a word made 6 (op +1 or +14); dropped
    unless the worst case is beyond a word and it is not 6 bytes;
  - dbcc: within a word at the worst case 6 less; beyond a word a long
    one (make_long_dbcc, 6 more);
  - fbr: within a word 2 less; beyond, a long one (make_long_cbr) or with
    -CPU FPX (+0x285 bit 6) the 6-byte form (op +6);
  - casejmp: within a word 4 less, beyond through a jmp
    (make_long_casejmp);
  - a branch kept (+-58 cleared, its shifts added, the last cell -56).
  After the passes the labels numbered from 0 (+44) or their temporary
  label nodes' +56 given their locations, the alignments of op 208
  delinked; resolve_inline_const_addrs; calc_psect_size; +16 the code so
  far (emit's +0x108), which grows by the size rounded up to 4.

  Not known from the original:
  - how the passes' state was laid out (-56, -58, -60 and the shifts
    here locals; the branch's target and label module cells as the
    image has them);
  - the exact form of the size and op updates (the image's branches are
    followed). }

procedure jmp_br_resolve;
var
  d: integer32;
  d2: integer32;
  t44: integer32;
  t40: integer32;
  shift: integer32;
  shift2: integer32;
  prev: jb_cell_ptr_t;
  all_resolved: boolean;
  changed: boolean;
  lpc: integer32;
  lpc2: integer32;
  tpc: integer32;
  tpc2: integer32;
  dpc: integer32;
  dpc2: integer32;
  keep: boolean;
  far: boolean;
  a: jb_cell_ptr_t;
  n: integer32;
  dummy: codegen_$cell_ptr_t;

  { drop_update - cur (a branch settled, its size changed by dpc and
    dpc2 at the worst case) taken off the chain after prev, the shifts
    grown, a change noted; cur its successor in the chain.

    0x0BAAB4, 0x5C bytes: the parent's frame from the dynamic link
    (-60, -36, -32). }

  procedure drop_update(
      prev: jb_cell_ptr_t;
      var cur: jb_cell_ptr_t;
      dpc: integer32;
      dpc2: integer32); options(val_param);
  begin
    changed := true;
    if prev = nil then
      sect^.labels := cur^.link
    else
      prev^.link := cur^.link;
    shift := shift + dpc;
    shift2 := shift2 + dpc2;
    cur := cur^.link;
  end;

  { make_long_jmp - the descriptor of a jump (ads) made to reach its
    target through A5: the target label given a temporary label node
    (create_temp_label, +40) when it has none, and the descriptors that
    refer to it through its reference list (+32) given the node too;
    the routine's block (back from the label to a block start whose
    block is not of kind 172) must have its own A5 (+375 bit 3; else
    cgerr_no_source(28, strtk('DB not valid'))); the descriptor mode 2
    register 13 (A5) with get_proc_addr_con(7, the node, the section,
    the block's +192)'s +16 as its displacement.

    0x0BAB10, 0x10A bytes: the callers pass the descriptor's address
    (`pea (36,An)'), read at (8) +0, +4 and +8; the cell here (its
    +36, +40, +44).

    Not known from the original: the parameter's type. }

  procedure make_long_jmp(
      ads: jb_cell_ptr_t); options(val_param);
  var
    l: jb_cell_ptr_t;
    node: il_$node_ptr_t;
    r: jb_ref_ptr_t;
    c: jb_cell_ptr_t;
    b: jb_cell_ptr_t;
    blk: il_$node_ptr_t;
    blk192: il_$node_ptr_t;
    con: il_$node_ptr_t;
  begin
    l := ads^.ref2^.owner;
    if ads^.lab2 = nil then begin
      node := create_temp_label;
      l^.lab2 := node;
      r := l^.ref1y;
      repeat
        c := r^.from;
        if (c^.ads2.f1 = 7) and (c^.ref2 = r) then
          c^.lab2 := node
        else if (c^.ads1.f1 = 7) and (c^.ref1y = r) then
          c^.lab1 := node;
        r := r^.next;
      until r = l^.ref1y;
    end;
    b := l;
    while (b^.kind <> block_start_instyp) or
          (il_$node_ptr_t(b^.pc)^.kind = 172) do
      b := b^.prev;
    blk := il_$node_ptr_t(b^.pc);
    if (ord(blk^.xc[375]) & 8) = 0 then
      cgerr_no_source(28, integer32(strtk('DB not valid', 12)));
    blk192 := blk^.xp[48];
    con := get_proc_addr_con(7, ads^.lab2, integer32(sect), blk192);
    ads^.ads2.f1 := 2;
    ads^.ads2.f2 := 13;
    ads^.num2 := con^.xl[4];
    ads^.lab2 := nil;
  end;

  { make_long_cbr - conditional branch c (reference r) made to reach
    farther, unless -CPU M020 (+0x285 bit 5): the condition reversed
    to skip a jump to the target (fnl_slct(37, 5, ...) with the
    branch's descriptor, a reference cell, make_long_jmp) placed after
    it, the branch retargeted to a label after the jump (the next cell
    when it is one, else a new one), which joins the chain after the
    last cell kept (-56) with its locations. }

  procedure make_long_cbr(
      c: jb_cell_ptr_t;
      r: jb_ref_ptr_t); options(val_param);
  var
    l: jb_cell_ptr_t;
    u: codegen_$uads_t;
    j: jb_cell_ptr_t;
  begin
    if not (3 in cargs_$options.cpu) then begin
      l := c^.next;
      if l^.kind <> def_lbl_instyp then begin
        l := jb_cell_ptr_t(getlabcell(nil));
        after(codegen_$cell_ptr_t(c), codegen_$cell_ptr_t(l));
      end;
      unpack_ads(c^.ads2, u);
      j := jb_cell_ptr_t(fnl_slct(37, 5, 0, u, cg_null_ads));
      j^.ref2 := jb_ref_ptr_t(getrefcell(integer32(j),
          codegen_$cell_ptr_t(c^.ref2^.owner)));
      make_long_jmp(j);
      after(codegen_$cell_ptr_t(c), codegen_$cell_ptr_t(j));
      reversecond(codegen_$cell_ptr_t(c));
      moverefcell(codegen_$cell_ptr_t(r), codegen_$cell_ptr_t(l));
      if c^.link <> l then begin
        l^.link := prev^.link;
        prev^.link := l;
        prev := l;
        l^.pc := c^.size + c^.pc + c^.next^.size;
        l^.pc2 := c^.size + c^.pc2 + c^.next^.size;
      end;
    end;
  end;

  { make_long_dbcc - dbcc c (reference r) made to reach farther: a
    label and a jump to the target after it, the dbcc retargeted to the
    label, a jump (makejump) over the jump; the label and the cell after
    the jump (nxtlcc) chained after the last cell kept (-56) with their
    locations.

    0x0BAD38, 0x12E bytes. }

  procedure make_long_dbcc(
      c: jb_cell_ptr_t;
      r: jb_ref_ptr_t); options(val_param);
  var
    u: codegen_$uads_t;
    j: jb_cell_ptr_t;
    l: jb_cell_ptr_t;
    m: jb_cell_ptr_t;
  begin
    unpack_ads(c^.ads2, u);
    j := jb_cell_ptr_t(fnl_slct(37, 5, 0, u, cg_null_ads));
    j^.ref2 := jb_ref_ptr_t(getrefcell(integer32(j),
        codegen_$cell_ptr_t(c^.ref2^.owner)));
    make_long_jmp(j);
    after(codegen_$cell_ptr_t(c), codegen_$cell_ptr_t(j));
    l := jb_cell_ptr_t(getlabcell(nil));
    after(codegen_$cell_ptr_t(c), codegen_$cell_ptr_t(l));
    dummy := makejump(codegen_$cell_ptr_t(c), codegen_$cell_ptr_t(j^.next));
    moverefcell(codegen_$cell_ptr_t(r), codegen_$cell_ptr_t(l));
    l^.link := prev^.link;
    prev^.link := l;
    prev := l;
    l^.pc := c^.size + c^.pc + c^.next^.size;
    l^.pc2 := c^.size + c^.pc2 + c^.next^.size;
    m := jb_cell_ptr_t(nxtlcc(codegen_$cell_ptr_t(j)));
    if m <> c^.link then begin
      m^.link := l^.link;
      l^.link := m;
      prev := m;
      m^.pc := j^.size + l^.pc;
      m^.pc2 := j^.size + l^.pc2;
    end;
  end;

  { make_long_casejmp - case jump c (reference r) made to reach its
    table through a jump: a label before the first label after c, the
    jump after it, the case jump retargeted to it; the label chained
    before that label with its locations 4 before.

    0x0BAE66, 0xDA bytes. }

  procedure make_long_casejmp(
      c: jb_cell_ptr_t;
      r: jb_ref_ptr_t); options(val_param);
  var
    t: jb_cell_ptr_t;
    l: jb_cell_ptr_t;
    u: codegen_$uads_t;
    j: jb_cell_ptr_t;
    p: jb_cell_ptr_t;
  begin
    t := c^.next;
    while t^.kind <> def_lbl_instyp do
      t := t^.next;
    l := jb_cell_ptr_t(getlabcell(nil));
    after(codegen_$cell_ptr_t(t^.prev), codegen_$cell_ptr_t(l));
    unpack_ads(c^.ads2, u);
    j := jb_cell_ptr_t(fnl_slct(37, 5, 0, u, cg_null_ads));
    j^.ref2 := jb_ref_ptr_t(getrefcell(integer32(j),
        codegen_$cell_ptr_t(c^.ref2^.owner)));
    make_long_jmp(j);
    after(codegen_$cell_ptr_t(l), codegen_$cell_ptr_t(j));
    moverefcell(codegen_$cell_ptr_t(r), codegen_$cell_ptr_t(l));
    p := c;
    while p^.link <> t do
      p := p^.link;
    l^.link := t;
    p^.link := l;
    l^.pc := t^.pc - 4;
    l^.pc2 := c^.pc2 - 4;
  end;

  { add_size_of_inst_to_pc - pc advanced past c at the worst case (a
    branch or alignment of op 208 as jmp_br_setup counts it; others
    their size; line numbers and block marks nothing).

    0x0BAF40, 0x90 bytes, no frame. }

  procedure add_size_of_inst_to_pc(
      c: jb_cell_ptr_t;
      var pc: integer32); options(val_param);
  begin
    if (c^.kind = line_no_instyp) or (c^.kind = block_end_instyp) or
       (c^.kind = block_start_instyp) then
      return;
    if ((c^.ads2.f1 = 7) or (c^.kind = def_lbl_instyp) or
        (c^.kind = align_instyp)) and (c^.op = 208) then
      case c^.kind of
        cbr_instyp, bsr_instyp, br_instyp: pc := pc + 6;
        dbcc_instyp: pc := pc + 10;
        fbr_instyp: pc := pc + 6;
        casejmp_instyp: pc := pc + 6;
        def_lbl_instyp: ;
        align_instyp: pc := pc + 2;
        otherwise
          pc := pc + c^.size;
      end
    else
      pc := pc + c^.size;
  end;

  { update_const_approximate_pcs - the worst-case locations of the
    inline constants from c on, counting from pc.

    0x0BAFD0, 0x6E bytes: the kinds tested whole (`seq; or.b'). }

  procedure update_const_approximate_pcs(
      c: jb_cell_ptr_t;
      pc: integer32); options(val_param);
  var
    t: integer32;
  begin
    while c <> sect^.head do begin
      if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
              (c^.kind = line_no_instyp)) then begin
        if c^.kind = inline_instyp then
          c^.pc2 := pc;
        t := pc;
        add_size_of_inst_to_pc(c, t);
        pc := t;
      end;
      c := c^.next;
    end;
  end;

  { calc_const_approximate_pcs - the inline constants' worst-case
    locations from the section's start.

    0x0BB03E, 0x16 bytes. }

  procedure calc_const_approximate_pcs;
  begin
    update_const_approximate_pcs(sect^.head^.next, 0);
  end;

  { check_for_deferred_ref - whether c's first or second descriptor is
    PC-relative to a reference (mode 3, +2 bits 3..1 3); the reference's
    cell and displacement (nil and 0 for neither).

    0x0BB054, 0xA0 bytes. }

  procedure check_for_deferred_ref(
      out is1: boolean;
      out is2: boolean;
      c: jb_cell_ptr_t;
      out target: jb_cell_ptr_t;
      out disp: integer32); options(val_param);
  begin
    is1 := (c^.ads1.f1 = 3) and (c^.ads1.f6 = 3);
    is2 := (c^.ads2.f1 = 3) and (c^.ads2.f6 = 3);
    if is1 then begin
      target := c^.ref1^.from;
      disp := c^.disp1;
    end
    else if is2 then begin
      target := c^.ref2x^.from;
      disp := c^.num2;
    end
    else begin
      target := nil;
      disp := 0;
    end;
  end;

  { update_refs_from_here_forward - the descriptors from c on that refer
    to inline constant k made to refer to node instead (+28 or +40).

    0x0BB0F4, 0x96 bytes. }

  procedure update_refs_from_here_forward(
      c: jb_cell_ptr_t;
      k: jb_cell_ptr_t;
      node: il_$node_ptr_t); options(val_param);
  var
    is1: boolean;
    is2: boolean;
    t: jb_cell_ptr_t;
    d: integer32;
  begin
    while c <> sect^.head do begin
      if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
              (c^.kind = line_no_instyp)) then begin
        check_for_deferred_ref(is1, is2, c, t, d);
        if t <> nil then
          if (t^.kind = inline_instyp) and (t = k) then
            if is1 then
              c^.lab1 := node
            else if is2 then
              c^.lab2 := node;
      end;
      c := c^.next;
    end;
  end;

  { ensure_inline_consts_are_reachable - when the section has inline
    constants and passes 32767 bytes at the worst case, each reference
    to a constant more than 30000 bytes away gets a copy of the constant
    (getcodecell(28), the 50 bytes copied) after the last rts or bra
    within reach (or the first after it), referred to through a new node
    (gspace(12): kind 184, the section, the copy); then the chains are
    rebuilt (jmp_br_setup).

    0x0BB1C0, 0x2AE bytes: the holes after an rts (-24) and a bra (-32)
    tried in that order, then the cells ahead; the distances unsigned
    after `neg.l' (`bls', `scs'). }

  procedure ensure_inline_consts_are_reachable;
  var
    pc: integer32;
    c: jb_cell_ptr_t;
    rts_hole: jb_hole_t;
    bra_hole: jb_hole_t;
    hole: jb_hole_t;
    scan: jb_hole_t;
    k: jb_cell_ptr_t;
    kpc: integer32;
    disp: integer32;
    is2: boolean;
    is1: boolean;
    target: integer32;
    n: jb_cell_ptr_t;
    node: il_$node_ptr_t;

    { assert_available_hole - h is a place within 30000 bytes of the
      constant's reference.

      0x0BB18A, 0x36 bytes: the parent's frame from the dynamic link
      (-12 the location, -72 the displacement). }

    function assert_available_hole(
        in h: jb_hole_t): boolean;
    begin
      if h.cell <> nil then
        assert_available_hole := abs(pc - (h.pc + disp)) < 30000
      else
        assert_available_hole := false;
    end;

  begin
    if (sect^.consts <> nil) and (sect^.pc2 > 32767) then begin
      calc_const_approximate_pcs;
      bra_hole.cell := nil;
      rts_hole.cell := nil;
      pc := 0;
      c := sect^.head^.next;
      while c <> sect^.head do begin
        if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
                (c^.kind = line_no_instyp)) then begin
          check_for_deferred_ref(is1, is2, c, k, disp);
          if k <> nil then
            if k^.kind = inline_instyp then begin
              kpc := k^.pc2;
              target := disp + kpc;
              if abs(pc - target) > 30000 then begin
                hole.cell := nil;
                hole.pc := 0;
                if assert_available_hole(rts_hole) then
                  hole := rts_hole
                else if assert_available_hole(bra_hole) then
                  hole := bra_hole
                else begin
                  scan.cell := c;
                  scan.pc := pc;
                  while scan.cell <> sect^.head do begin
                    if (scan.cell^.kind = rts_instyp) or
                       (scan.cell^.kind = br_instyp) then
                      if assert_available_hole(scan) then begin
                        hole := scan;
                        exit;
                      end;
                    if not ((scan.cell^.kind = block_end_instyp) or
                            (scan.cell^.kind = block_start_instyp) or
                            (scan.cell^.kind = line_no_instyp)) then
                      add_size_of_inst_to_pc(scan.cell, scan.pc);
                    scan.cell := scan.cell^.next;
                  end;
                end;
                if hole.cell <> nil then begin
                  n := jb_cell_ptr_t(getcodecell(inline_instyp));
                  n^ := k^;
                  n^.next := hole.cell^.next;
                  n^.prev := hole.cell;
                  hole.cell^.next^.prev := n;
                  hole.cell^.next := n;
                  node := gspace(12);
                  node^.kind := 184;
                  node^.xp[1] := il_$node_ptr_t(sect);
                  node^.xp[2] := il_$node_ptr_t(n);
                  update_refs_from_here_forward(c, k, node);
                  update_const_approximate_pcs(hole.cell, hole.pc);
                  if hole.pc < pc then
                    pc := pc + n^.size;
                end;
              end;
            end;
          if c^.kind = rts_instyp then begin
            rts_hole.cell := c;
            rts_hole.pc := pc;
          end;
          if c^.kind = br_instyp then begin
            bra_hole.cell := c;
            bra_hole.pc := pc;
          end;
          add_size_of_inst_to_pc(c, pc);
        end;
        c := c^.next;
      end;
      sect^.labels := nil;
      sect^.consts := nil;
      sect^.pc := 0;
      sect^.pc2 := 0;
      jmp_br_setup(sect, sect^.head^.next);
    end;
  end;

  { resolve_inline_const_addrs - each inline constant's location: after
    the constant before it, or counted from the label before it.

    0x0BB470, 0x78 bytes, no frame. }

  procedure resolve_inline_const_addrs;
  var
    k: jb_cell_ptr_t;
    c: jb_cell_ptr_t;
  begin
    k := sect^.consts;
    while k <> nil do begin
      c := k^.prev;
      if c^.kind = inline_instyp then
        k^.pc := c^.size + c^.pc
      else begin
        while c^.kind <> def_lbl_instyp do
          c := c^.prev;
        k^.pc := c^.pc;
        while c <> k do begin
          if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
                  (c^.kind = line_no_instyp)) then
            k^.pc := k^.pc + c^.size;
          c := c^.next;
        end;
      end;
      k^.pc2 := k^.pc;
      k := k^.link;
    end;
  end;

  { calc_psect_size - s's size: from the last label or inline constant,
    the sizes after it (ilength must agree with each cell's size, else
    cgerr_no_source(16, 0)).

    0x0BB4E8, 0x92 bytes. }

  procedure calc_psect_size(
      s: jb_sect_ptr_t); options(val_param);
  var
    c: jb_cell_ptr_t;
  begin
    c := s^.head^.prev;
    if c = s^.head then
      s^.size := 0
    else begin
      while (c^.kind <> def_lbl_instyp) and (c^.kind <> inline_instyp) do
        c := c^.prev;
      s^.size := c^.pc;
      while c <> s^.head do begin
        if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
                (c^.kind = line_no_instyp)) then begin
          if ilength(codegen_$cell_ptr_t(c)) <> c^.size then
            cgerr_no_source(16, 0);
          s^.size := s^.size + c^.size;
        end;
        c := c^.next;
      end;
    end;
  end;

begin
  emit_108.e108 := 0;
  sect := il_10c;
  while sect <> nil do begin
    if 4 in cargs_$options.flags_286 then begin
      a := jb_cell_ptr_t(getcodecell(align_instyp));
      a^.op := 208;
      a^.ads1 := null_ads;
      a^.ads2 := null_ads;
      a^.size := ilength(codegen_$cell_ptr_t(a));
      after(codegen_$cell_ptr_t(sect^.head^.prev), codegen_$cell_ptr_t(a));
      jmp_br_setup(sect, a);
    end;
    ensure_inline_consts_are_reachable;
    pass := 1;
    repeat
      pass := pass + 1;
      changed := false;
      all_resolved := true;
      shift := 0;
      shift2 := 0;
      prev := nil;
      cur := sect^.labels;
      while cur <> nil do begin
        cur^.pc := cur^.pc + shift;
        cur^.pc2 := cur^.pc2 + shift2;
        keep := false;
        if cur^.kind = def_lbl_instyp then begin
          prev := cur;
          cur := cur^.link;
        end
        else if cur^.kind = align_instyp then begin
          if not all_resolved then begin
            prev := cur;
            cur := cur^.link;
          end
          else if ((cur^.pc & 3) = 0) and (cur^.op = 208) then begin
            delink(codegen_$cell_ptr_t(cur));
            if prev = nil then
              sect^.labels := cur^.link
            else
              prev^.link := cur^.link;
            cur := cur^.link;
          end
          else begin
            cur^.kind := a_instyp;
            cur^.ads1.f1 := 1;
            cur^.ads1.f2 := 8;
            cur^.ads2.f1 := 1;
            cur^.ads2.f2 := 8;
            cur^.size := 2;
            if cur^.op = 208 then begin
              cur^.op := 5;
              drop_update(prev, cur, 2, 2);
            end
            else begin
              cur^.op := 5;
              drop_update(prev, cur, 0, 0);
            end;
          end;
        end
        else begin
          dpc := 0;
          dpc2 := 0;
          ref := cur^.ref2;
          lab := ref^.owner;
          lpc := lab^.pc;
          lpc2 := lab^.pc2;
          if assert_is_forward_of(lpc2, cur^.pc2 - shift2) then begin
            lpc := lpc + shift;
            lpc2 := lpc2 + shift2;
          end;
          if cur^.kind = casejmp_instyp then begin
            tpc := cur^.ref1y^.owner^.pc;
            tpc2 := cur^.ref1y^.owner^.pc2;
            if assert_is_forward_of(tpc2, cur^.pc2) then begin
              tpc := tpc + shift;
              tpc2 := tpc2 + shift2;
            end;
            d := lpc - tpc;
            d2 := lpc2 - tpc2;
          end
          else begin
            d := lpc - (cur^.pc + 2);
            d2 := lpc2 - (cur^.pc2 + 2);
          end;
          case cur^.kind of
            bsr_instyp, cbr_instyp, br_instyp:
              if assert_byte_reach_is_possible(d2) then begin
                t40 := dpc2;
                observe_that_offset_is_negative(t40, -4);
                drop_update(prev, cur, dpc, t40);
              end
              else if not assert_word_reach_is_possible(d) and
                      not (3 in cargs_$options.cpu) then begin
                case cur^.kind of
                  br_instyp: begin
                    t44 := dpc;
                    observe_that_offset_is_positive(t44, 4 - cur^.size);
                    dpc := t44;
                    cur^.size := 4;
                    cur^.kind := dest1_sz_instyp;
                    cur^.op := 123;
                    make_long_jmp(cur);
                  end;
                  cbr_instyp: begin
                    t44 := dpc;
                    observe_that_offset_is_positive(t44, 6 - cur^.size);
                    dpc := t44;
                    if cur^.size <> 2 then begin
                      cur^.op := cur^.op - 14;
                      cur^.size := 2;
                    end;
                    make_long_cbr(cur, ref);
                  end;
                  bsr_instyp: begin
                    if 7 in cargs_$options.flags_286 then begin
                      t44 := dpc;
                      observe_that_offset_is_positive(t44, 6 - cur^.size);
                      dpc := t44;
                      cur^.size := 6;
                      cur^.ads2.f1 := 15;
                      cur^.lab2 := cur^.lab1;
                      cur^.num2 := dpc2;
                    end
                    else begin
                      a := cur;
                      while (a^.kind <> block_start_instyp) or
                            (il_$node_ptr_t(a^.pc)^.kind = 172) do
                        a := a^.prev;
                      if (ord(il_$node_ptr_t(a^.pc)^.xc[375]) & 8) = 0 then
                        cgerr_no_source(28,
                            integer32(strtk('DB not valid', 12)));
                      t44 := dpc;
                      observe_that_offset_is_positive(t44, 4 - cur^.size);
                      dpc := t44;
                      cur^.size := 4;
                      cur^.ads2.f1 := 2;
                      cur^.ads2.f2 := 13;
                      cur^.num2 := cur^.lab1^.xl[27];
                      cur^.lab2 := nil;
                    end;
                    cur^.kind := dest1_sz_instyp;
                    cur^.op := 119;
                  end;
                  otherwise
                    ;
                end;
                drop_update(prev, cur, dpc, dpc2);
              end
              else if assert_byte_reach_is_possible(d) then
                keep := true
              else begin
                if (cur^.size <> 4) and (cur^.size <> 6) then begin
                  far := false;
                  if 3 in cargs_$options.cpu then
                    far := not assert_word_reach_is_possible(d);
                  if far then begin
                    cur^.size := 6;
                    t44 := dpc;
                    observe_that_offset_is_positive(t44, 4);
                    dpc := t44;
                  end
                  else begin
                    cur^.size := 4;
                    t44 := dpc;
                    observe_that_offset_is_positive(t44, 2);
                    dpc := t44;
                    t40 := dpc2;
                    observe_that_offset_is_negative(t40, -2);
                    dpc2 := t40;
                  end;
                  case cur^.kind of
                    br_instyp, bsr_instyp: begin
                      cur^.op := cur^.op + 1;
                      if cur^.size = 6 then
                        cur^.op := cur^.op + 1;
                    end;
                    cbr_instyp:
                      if cur^.size = 6 then
                        cur^.op := cur^.op + 28
                      else
                        cur^.op := cur^.op + 14;
                    otherwise
                      ;
                  end;
                end;
                far := false;
                if (3 in cargs_$options.cpu) and (cur^.size = 4) then
                  far := not assert_word_reach_is_possible(d);
                if far then begin
                  t44 := dpc;
                  observe_that_offset_is_positive(t44, 2);
                  dpc := t44;
                  dpc2 := 0;
                  cur^.size := 6;
                  case cur^.kind of
                    br_instyp, bsr_instyp:
                      cur^.op := cur^.op + 1;
                    cbr_instyp:
                      cur^.op := cur^.op + 14;
                    otherwise
                      ;
                  end;
                end;
                if assert_word_reach_is_possible(d2) or (cur^.size = 6) then
                  drop_update(prev, cur, dpc, dpc2)
                else
                  keep := true;
              end;
            dbcc_instyp:
              if assert_word_reach_is_possible(d2) then begin
                t40 := dpc2;
                observe_that_offset_is_negative(t40, -6);
                drop_update(prev, cur, dpc, t40);
              end
              else if assert_word_reach_is_possible(d) then
                keep := true
              else begin
                t44 := dpc;
                observe_that_offset_is_positive(t44, 6);
                make_long_dbcc(cur, ref);
                drop_update(prev, cur, t44, dpc2);
              end;
            fbr_instyp:
              if assert_word_reach_is_possible(d2) then begin
                t40 := dpc2;
                observe_that_offset_is_negative(t40, -2);
                drop_update(prev, cur, dpc, t40);
              end
              else if assert_word_reach_is_possible(d) then
                keep := true
              else if not (4 in cargs_$options.cpu) then begin
                t44 := dpc;
                observe_that_offset_is_positive(t44, 6 - cur^.size);
                make_long_cbr(cur, ref);
                drop_update(prev, cur, t44, dpc2);
              end
              else begin
                cur^.op := cur^.op + 6;
                cur^.size := 6;
                t44 := dpc;
                observe_that_offset_is_positive(t44, 2);
                t40 := dpc;
                drop_update(prev, cur, t44, dpc);
              end;
            casejmp_instyp:
              if assert_word_reach_is_possible(d2) then begin
                t40 := dpc2;
                observe_that_offset_is_negative(t40, -4);
                drop_update(prev, cur, dpc, t40);
              end
              else if assert_word_reach_is_possible(d) then
                keep := true
              else begin
                t44 := dpc;
                observe_that_offset_is_positive(t44, 6 - cur^.size);
                make_long_casejmp(cur, ref);
                drop_update(prev, cur, t44, dpc2);
              end;
            otherwise
              keep := true;
          end;
          if keep then begin
            all_resolved := false;
            shift := shift + dpc;
            shift2 := shift2 + dpc2;
            prev := cur;
            cur := cur^.link;
          end;
        end;
      end;
    until not changed;
    lbl := sect^.labels;
    n := 0;
    while lbl <> nil do begin
      if lbl^.kind = def_lbl_instyp then begin
        if lbl^.lab2 = nil then begin
          lbl^.num2 := n;
          n := n + 1;
        end
        else
          lbl^.lab2^.xl[14] := lbl^.pc;
      end
      else if (lbl^.kind = align_instyp) and (lbl^.op = 208) then
        delink(codegen_$cell_ptr_t(lbl));
      lbl := lbl^.link;
    end;
    resolve_inline_const_addrs;
    calc_psect_size(sect);
    sect^.offset := emit_108.e108;
    if (sect^.size & 3) <> 0 then
      emit_108.e108 := emit_108.e108 + ((sect^.size & (-4)) + 4)
    else
      emit_108.e108 := emit_108.e108 + sect^.size;
    sect := sect^.next;
  end;
end;
