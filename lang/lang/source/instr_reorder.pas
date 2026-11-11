{ instr_reorder - instruction scheduling for the m68k back end (cc.m68k
  only).  Over a section's code cells from first, until a pass moves
  nothing: after a store to memory, a load of a data register or (with
  -CPU FPX) a 68881 instruction, the instruction two ahead is moved up
  behind it, or failing that the instruction before it is moved down
  after it, when neither depends on the other (test_operands, the
  condition codes still tested, stores, the registers involved).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0B9C50  --------  is_fpa_instr (in instr_reorder)
    0x0B9C74  --------  is_fp_instr (in instr_reorder)
    0x0B9C98  --------  not_ok_to_move (in instr_reorder)
    0x0B9DB0  --------  store_to_memory (in instr_reorder)
    0x0B9E2E  --------  is_same (in instr_reorder)
    0x0B9EBE  --------  no_src_ads (in instr_reorder)
    0x0B9EE0  --------  test_operands (in instr_reorder)
    0x0B9FD2  --------  get_mask (in instr_reorder)
    0x0B9FEE  --------  adjust_links (in instr_reorder)
    0x0BA062  --------  cannot_move (in instr_reorder)
    0x0BA104  --------  reorder_dest_mem (in instr_reorder)
    0x0BA2BA  --------  reorder_dest_reg (in instr_reorder)
    0x0BA56A  --------  reorder_m68881 (in instr_reorder)
    0x0BA754  --------  instr_reorder
    A5 0x2CE8BC: the unit has no data (jmp_br_resolve.pas's A5, the
    next module's); instr_reorder loads it and reads none of it.
    Absolute: opinfo's operand access codes (0x2CFDD8, two characters
    an instruction, 'W' a written operand), cargs's options.

  The nested routines take instr_reorder's frame from their dynamic
  link (the reorder_ routines) or in A1 (cannot_move, adjust_links:
  -8 the section, -10 the change flag); is_fpa_instr, is_fp_instr and
  no_src_ads have no frame.  The kinds are tested as sets of 0..63 or
  0..47 (`btst' on constants after the routines; docs/dpc-gaps.md 8).

  Not known from the original: every name but the routines'; the
  descriptors' fields' meanings (+0 bits 7..3 the mode, then the
  register; mode 1 a data register, 7 a label); the access table's
  name.
}
module instr_reorder;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';

type
  { A section (il_10c's list) as far as instr_reorder reads it: its
    head cell (+20). }
  ir_sect_ptr_t = ^ir_sect_t;
  ir_sect_t = record
    unused: array [0..4] of integer32;  { +0 }
    head: codegen_$cell_ptr_t;          { +20 }
  end;

var
  { opinfo.pas's data (the unit without code; cc.m68k 0x2CFDD8,
    absolute): each instruction's two operands' access ('W' written),
    indexed by the cell's +48 (as outbin.pas declares opinfo's other
    tables). }
  opinfo_access: extern array [0..367] of packed array [1..2] of char;

{ instr_reorder - the cells of sect from first reordered until nothing
  moves.

  0x0BA754, 0xD4 bytes: the change flag (-10) cleared each pass; a
  68881 instruction under -CPU FPX (cargs +0x285 bit 6, its address in
  D3) reorder_m68881; an FPA instruction passed; a cell writing a data
  register (+36 mode 1) of a kind not in [22, 24, 27, 32..34] (a set of
  0..47) reorder_dest_reg; a store reorder_dest_mem; each reorder_
  routine given the cell by address and returning the cell after it. }

procedure instr_reorder;
var
  c: codegen_$cell_ptr_t;
  s: ir_sect_ptr_t;
  changed: boolean;
  cc: codegen_$cell_ptr_t;

  { is_fpa_instr, is_fp_instr - c is an FPA instruction (kinds 54..58),
    a 68881 one (39..44, 48, 50..52).

    0x0B9C50, 0x0B9C74, 0x1A bytes each, no frame. }

  function is_fpa_instr(
      c: codegen_$cell_ptr_t): boolean; options(val_param);
  begin
    is_fpa_instr := c^.kind in [54..58];
  end;

  function is_fp_instr(
      c: codegen_$cell_ptr_t): boolean; options(val_param);
  begin
    is_fp_instr := c^.kind in [39..44, 48, 50..52];
  end;

  { not_ok_to_move - c must stay: a label, branch, call, link, line,
    block mark, alignment and the like (a set of 0..63), the ops 123,
    119, 13, 116, 117, a descriptor with +2 bits 6 or 4 (`andi.w #5' of
    bits 6..4), a write of A5 (+36 mode 1 register 13), an unmovable
    68881 instruction (final_$is_unmoveable_fp_inst); or ops 12, 17,
    18, 23, 24 (a `case' of op less 12) after a jump (op 119, 116, 117)
    past labels, lines and block marks. }

  function not_ok_to_move(
      c: codegen_$cell_ptr_t): boolean; options(val_param);
  var
    r: boolean;
    p: codegen_$cell_ptr_t;
  begin
    r := false;
    if (c^.kind in [0, 17, 18, 20..27, 30..34, 39, 51, 52]) or
       (c^.op = 123) or (c^.op = 119) or (c^.op = 13) or (c^.op = 116) or
       (c^.op = 117) or ((c^.ads1.f5 & 5) <> 0) or
       ((c^.ads2.f5 & 5) <> 0) or
       ((c^.ads2.f1 = 1) and (c^.ads2.f2 = 13)) then
      r := true
    else if final_$is_unmoveable_fp_inst(c) then
      r := true
    else begin
      p := c^.prev;
      while p^.kind in [0, 24, 32, 33] do
        p := p^.prev;
      if (p^.op = 119) or (p^.op = 116) or (p^.op = 117) then
        case c^.op of
          12, 17, 18, 23, 24:
            r := true;
          otherwise
            ;
        end;
    end;
    not_ok_to_move := r;
  end;

  { store_to_memory - c writes memory: its first or second operand
    written ('W' in opinfo's table) with a memory mode (2, 4..6, 8, 9,
    11, 15: `btst' in #0x8B74); not for labels, lines, block marks. }

  function store_to_memory(
      c: codegen_$cell_ptr_t): boolean; options(val_param);
  var
    r: boolean;
  begin
    r := false;
    if not ((c^.kind = block_end_instyp) or (c^.kind = block_start_instyp) or
            (c^.kind = line_no_instyp) or (c^.kind = def_lbl_instyp)) then
      if (opinfo_access[c^.op][1] = 'W') and
         (c^.ads1.f1 in [2, 4, 5, 6, 8, 9, 11, 15]) then
        r := true
      else if (opinfo_access[c^.op][2] = 'W') and
              (c^.ads2.f1 in [2, 4, 5, 6, 8, 9, 11, 15]) then
        r := true;
    store_to_memory := r;
  end;

  { is_same - descriptors a and b may refer to the same place: sameaddr,
    or b addresses memory (modes 1, 2, 4, 6, 8, 9, 14) through a's
    register (a of those modes) or a's index register (modes 4, 6, 14:
    +1 bits 5..1). }

  function is_same(
      in a: codegen_$ads_t;
      in b: codegen_$ads_t): boolean;
  var
    r: boolean;
    t: boolean;
  begin
    r := sameaddr(a, b);
    if b.f1 in [1, 2, 4, 6, 8, 9, 14] then begin
      if a.f1 in [1, 2, 4, 6, 8, 9, 14] then begin
        t := involves(b, a.f2);
        r := r or t;
      end;
      if a.f1 in [4, 6, 14] then begin
        t := involves(b, a.f3);
        r := r or t;
      end;
    end;
    is_same := r;
  end;

  { no_src_ads - instructions of kind k have no source operand (3, 16,
    19, 28, 29, 43, 44, 47, 50).

    0x0B9EBE, 0x18 bytes, no frame. }

  function no_src_ads(
      k: integer): boolean; options(val_param);
  begin
    no_src_ads := k in [3, 16, 19, 28, 29, 43, 44, 47, 50];
  end;

  { test_operands - a and b depend on each other: either cannot move,
    or their operands overlap (destinations; a destination and the other
    source; both sources and destinations when both have sources).

    0x0B9EE0, 0xF2 bytes: the first results or-ed (`or.b (-10,A6)'). }

  function test_operands(
      a: codegen_$cell_ptr_t;
      b: codegen_$cell_ptr_t): boolean; options(val_param);
  var
    r: boolean;
    na: boolean;
    nb: boolean;
    sa: boolean;
    sb: boolean;
    t: boolean;
  begin
    na := not_ok_to_move(a);
    nb := not_ok_to_move(b);
    if na or nb then
      test_operands := true
    else begin
      r := is_same(a^.ads2, b^.ads2);
      sa := no_src_ads(a^.kind);
      sb := no_src_ads(b^.kind);
      if sa and not sb then begin
        t := is_same(a^.ads2, b^.ads1);
        r := r or t;
      end
      else if sb and not sa then begin
        t := is_same(a^.ads1, b^.ads2);
        r := r or t;
      end
      else if not sa and not sb then begin
        t := is_same(a^.ads1, b^.ads1);
        r := r or t;
        t := is_same(a^.ads1, b^.ads2);
        r := r or t;
        t := is_same(a^.ads2, b^.ads1);
        r := r or t;
      end;
      test_operands := r;
    end;
  end;

  { get_mask - the condition codes c sets: 48 for a 68881 instruction,
    else 15. }

  function get_mask(
      c: codegen_$cell_ptr_t): integer; options(val_param);
  begin
    if is_fp_instr(c) then
      get_mask := 48
    else
      get_mask := 15;
  end;

  { adjust_links - the move: b (back, the cell before c) or a (ahead,
    the one two after c) delinked and put after c, or after the last
    line number cell past c (x) when there were any (lines); a change
    noted.

    0x0B9FEE, 0x74 bytes: instr_reorder's frame in A1 (-10). }

  procedure adjust_links(
      var c: codegen_$cell_ptr_t;
      in a: codegen_$cell_ptr_t;
      in b: codegen_$cell_ptr_t;
      in x: codegen_$cell_ptr_t;
      lines: boolean;
      back: boolean); options(val_param);
  begin
    if back then
      delink(b)
    else
      delink(a);
    if lines then
      if back then
        after(x, b)
      else
        after(x, a)
    else if back then
      after(c, b)
    else
      after(c, a);
    changed := true;
  end;

  { cannot_move - a and b may not be exchanged: their operands
    (test_operands), b the section's head cell, the condition codes
    either sets still tested after b (testcc of the next code cell's and
    b's), or either a store.

    0x0BA062, 0xA2 bytes: the results or-ed in a frame byte. }

  function cannot_move(
      a: codegen_$cell_ptr_t;
      b: codegen_$cell_ptr_t): boolean; options(val_param);
  var
    r: boolean;
    t: boolean;
  begin
    r := test_operands(a, b) or (b = s^.head);
    t := testcc(nxtcc(b), get_mask(nxtcc(b)));
    r := r or t;
    t := testcc(b, get_mask(b));
    r := r or t;
    t := store_to_memory(a);
    r := r or t;
    t := store_to_memory(b);
    r := r or t;
    cannot_move := r;
  end;

  { reorder_dest_mem - after store c: the instruction two ahead moved
    behind it when it is independent of the one between (and not a
    store, nor a data register load before a store), else the one
    before c moved after it; the cell after c.

    0x0BA104, 0x1B6 bytes: line number cells (24) skipped (-32 set,
    -16 the last); the moved cells at -20 (ahead) and -12 (back), -30
    set for back. }

  function reorder_dest_mem(
      var c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param);
  var
    lines: boolean;
    back: boolean;
    x: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t;
    a: codegen_$cell_ptr_t;
    n: codegen_$cell_ptr_t;
    m: codegen_$cell_ptr_t;
    p: codegen_$cell_ptr_t;
    fp: boolean;
    f2: boolean;
    f3: boolean;
    ok: boolean;
  begin
    n := c^.next;
    lines := false;
    back := false;
    while n^.kind = line_no_instyp do begin
      x := n;
      n := n^.next;
      lines := true;
    end;
    if store_to_memory(n) then begin
      m := n^.next;
      while m^.kind = line_no_instyp do
        m := m^.next;
      p := m^.next;
      while p^.kind = line_no_instyp do
        p := p^.next;
      ok := not cannot_move(n, m);
      if ok then
        ok := not testcc(n, get_mask(n));
      if ok then
        ok := not store_to_memory(m);
      if ok then
        ok := not (store_to_memory(p) and (m^.ads2.f1 = 1));
      if ok then begin
        fp := is_fp_instr(n);
        f2 := is_fp_instr(p);
        f3 := is_fp_instr(m);
        if not (fp and f2 and not f3) then begin
          a := m;
          adjust_links(c, a, b, x, lines, back);
          reorder_dest_mem := c^.next;
          return;
        end;
      end;
      b := c^.prev;
      while b^.kind = line_no_instyp do
        b := b^.prev;
      p := b^.prev;
      while p^.kind = line_no_instyp do
        p := p^.prev;
      ok := not cannot_move(c, b);
      if ok then
        ok := not testcc(n, get_mask(n));
      if ok then
        ok := not store_to_memory(b);
      if ok then
        ok := not store_to_memory(p);
      if ok then begin
        fp := is_fp_instr(b);
        f2 := is_fp_instr(n);
        f3 := is_fp_instr(c);
        if not (fp and f2 and not f3) then begin
          back := true;
          a := m;
          adjust_links(c, a, b, x, lines, back);
        end;
      end;
    end;
    reorder_dest_mem := c^.next;
  end;

  { reorder_dest_reg - after c, which loads a data register: when the
    next instruction uses the register, the one after it moved up (if
    independent, not a store before a data register load, and no 68881
    pair through the same register), else the one before c moved after
    it (if independent and not using registers the others load); the
    cell after c.

    0x0BA2BA, 0x2B0 bytes: as reorder_dest_mem; the register +36 bits
    10..6 (`andi.w #0x7C0; lsr.w #6'); involves on both descriptors. }

  function reorder_dest_reg(
      var c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param);
  var
    lines: boolean;
    back: boolean;
    x: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t;
    a: codegen_$cell_ptr_t;
    n: codegen_$cell_ptr_t;
    m: codegen_$cell_ptr_t;
    p: codegen_$cell_ptr_t;
    t: boolean;
    t2: boolean;
    move: boolean;
  begin
    n := c^.next;
    lines := false;
    back := false;
    while n^.kind = line_no_instyp do begin
      x := n;
      n := n^.next;
      lines := true;
    end;
    if not involves(n^.ads1, c^.ads2.f2) then
      if not involves(n^.ads2, c^.ads2.f2) then begin
        reorder_dest_reg := c^.next;
        return;
      end;
    m := n^.next;
    while m^.kind = line_no_instyp do
      m := m^.next;
    p := m^.next;
    while p^.kind = line_no_instyp do
      p := p^.next;
    move := false;
    if not cannot_move(n, m) then
      if not testcc(n, get_mask(n)) then begin
        t := store_to_memory(n);
        t2 := store_to_memory(p);
        if not (t and t2 and (m^.ads2.f1 = 1)) then begin
          t := is_fp_instr(n);
          t2 := is_fp_instr(p);
          if not (t and t2) then
            move := true
          else if is_fp_instr(m) then
            move := n^.ads2.f2 <> p^.ads1.f2;
        end;
      end;
    if move then begin
      a := m;
      adjust_links(c, a, b, x, lines, back);
    end
    else begin
      b := c^.prev;
      while b^.kind = line_no_instyp do
        b := b^.prev;
      p := b^.prev;
      while p^.kind = line_no_instyp do
        p := p^.prev;
      if not cannot_move(c, b) then
        if not testcc(n, get_mask(n)) then begin
          t := store_to_memory(b);
          t2 := store_to_memory(n);
          if not (t and t2) then begin
            t := involves(c^.ads1, p^.ads2.f2);
            t2 := involves(c^.ads2, p^.ads2.f2);
            t := t or t2;
            if not (t and (p^.ads2.f1 = 1)) then begin
              t := is_fp_instr(b);
              t2 := is_fp_instr(n);
              if not (t and t2) then begin
                t := involves(n^.ads1, b^.ads2.f2);
                t2 := involves(n^.ads2, b^.ads2.f2);
                t := t or t2;
                if not (t and (b^.ads2.f1 = 1)) then begin
                  back := true;
                  a := m;
                  adjust_links(c, a, b, x, lines, back);
                end;
              end;
            end;
          end;
        end;
    end;
    reorder_dest_reg := c^.next;
  end;

  { reorder_m68881 - after 68881 instruction c, when the next is one
    too: the one after it moved up (when it is not a 68881 one, or the
    next reads c's destination and it does not), else the one before c
    moved after it (when the registers do not meet); the cell after c.

    0x0BA56A, 0x1EA bytes: the registers +24 and +36 bits 10..6. }

  function reorder_m68881(
      var c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param);
  var
    lines: boolean;
    back: boolean;
    x: codegen_$cell_ptr_t;
    b: codegen_$cell_ptr_t;
    a: codegen_$cell_ptr_t;
    n: codegen_$cell_ptr_t;
    p: codegen_$cell_ptr_t;
    move: boolean;
    ok: boolean;
    f1: boolean;
    f2: boolean;
  begin
    n := c^.next;
    lines := false;
    back := false;
    while n^.kind = line_no_instyp do begin
      x := n;
      n := n^.next;
      lines := true;
    end;
    if is_fp_instr(n) then begin
      a := n^.next;
      while a^.kind = line_no_instyp do
        a := a^.next;
      move := false;
      if not cannot_move(n, a) then
        if not testcc(n, get_mask(n)) then
          if not is_fp_instr(a) then
            move := true
          else if c^.ads2.f2 = n^.ads1.f2 then
            move := a^.ads1.f2 <> n^.ads1.f2;
      if not move then begin
        b := c^.prev;
        while b^.kind = line_no_instyp do
          b := b^.prev;
        p := b^.prev;
        while p^.kind = line_no_instyp do
          p := p^.prev;
        ok := false;
        if not cannot_move(c, b) then
          if not testcc(n, get_mask(n)) then begin
            ok := true;
            if is_fp_instr(b) then
              if (b^.ads2.f2 = c^.ads1.f2) or (b^.ads2.f2 = c^.ads2.f2) or
                 (c^.ads2.f2 <> n^.ads1.f2) then
                ok := false;
            if ok then begin
              f1 := is_fp_instr(b);
              f2 := is_fp_instr(p);
              if not f1 and f2 then
                ok := false;
            end;
            if ok then
              if is_fp_instr(p) then
                if p^.ads2.f2 = c^.ads1.f2 then
                  ok := false;
          end;
        if ok then begin
          back := true;
          adjust_links(c, a, b, x, lines, back);
        end;
      end
      else
        adjust_links(c, a, b, x, lines, back);
    end;
    reorder_m68881 := c^.next;
  end;

begin
  s := psect;
  repeat
    changed := false;
    c := first;
    while c <> s^.head do begin
      if is_fp_instr(c) and (4 in cargs_$options.cpu) then begin
        cc := c;
        c := reorder_m68881(cc);
      end
      else if is_fpa_instr(c) then
        c := c^.next
      else if not (c^.kind in [22, 24, 27, 32, 33, 34]) and
              (c^.ads2.f1 = 1) then begin
        cc := c;
        c := reorder_dest_reg(cc);
      end
      else if store_to_memory(c) then begin
        cc := c;
        c := reorder_dest_mem(cc);
      end
      else
        c := c^.next;
    end;
  until not changed;
end;
