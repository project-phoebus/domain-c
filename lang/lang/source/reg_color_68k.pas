{ reg_color_68k - the m68k register allocator's colouring: the
  interference graph's conflicts (cells from reg_alloc's pool), the
  registers each range may have (available, availcolors: those free
  over every statement it spans, less the extra temporaries the code
  generator needs there), and the colouring itself: ranges taken in
  order, each one's uncoloured neighbours of higher priority coloured
  first (or given up and taken out of the graph), a colour picked from
  the preferred registers; then the ranges with more registers than
  conflicts, then the address ranges that can live in a data register.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C50AC  --------  add_conflict
    0x0C5156  --------  removeconflict
    0x0C51C0  --------  walkconflicts
    0x0C5216  --------  conflictfree
    0x0C523E  --------  count_regs
    0x0C527E  --------  reduce
    0x0C52F6  --------  reduce_temp_regs
    0x0C5350  --------  available
    0x0C53AA  --------  availcolors
    0x0C5496  --------  checkout
    0x0C54F6  --------  paint
    0x0C5674  --------  pickcolor
    0x0C570A  --------  targetfunctionresult
    0x0C572A  --------  computecommonregs
    0x0C5752  --------  setcommonregs
    0x0C5772  --------  color_graph
    A5 0x2D257C (cc.m68k): the module's data, 4 bytes (no .rwdi
    record): +0 the register set of the statement reduce_temp_regs
    works on.

  add_conflict, walkconflicts and color_graph load A5 (global;
  add_conflict and color_graph in reg_alloc.ins.pas); removeconflict
  and conflictfree (a leaf without a frame) are internal; the others
  are nested in color_graph (reduce in reduce_temp_regs, checkout in
  paint).  The four routines passed to walkconflicts (checkout,
  targetfunctionresult, computecommonregs, setcommonregs) load A5 and
  take their parent's frame from A1 (docs/rev889-patterns.md 52); the
  callers build their trampolines in the frame (12).  reduce and
  pickcolor take the parent's frame from their dynamic link (25), and
  use the parent's locals (reduce_temp_regs' j as a loop index,
  color_graph's -4).

  A statement's regs (g_opt.ins.pas, +30): bits 0..23 the registers
  free over it (D0..D7, A0..A7, FP0..FP7), bits 24..26, 27..29, 30..31
  the extra data, address and floating temporaries the code generator
  needs there (reg_save), which reduce_temp_regs turns into registers
  taken out of the free ones (the highest marker first).

  Not known from the original: the locals' and parameters' names, the
  module variable's.

  dpc gaps (docs/dpc-gaps.md): 21 (nested routines passed as routine
  parameters to walkconflicts).
}
module reg_color_68k;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

type
  { walkconflicts' routine as a routine pointer (the gate's form,
    docs/dpc-gaps.md 21: tools/cc_gap_rewrites.txt). }
  rc_walk_t = ^procedure(
      var x: reg_range_t);

var
  temp_regs: reg_regset_t;              { +0 }

define
  add_conflict, color_graph;

{ add_conflict - k among r's conflicts (once): in r's own cell when it
  has none, else in a new cell at the end of its chain.

  0x0C50AC, 0xAA bytes, link #-8: k in D2; a new cell from newconflict
  (a nil one reported, cgerr_no_source(9, 0)); the chain's last cell
  kept in A3 while it is searched (the loop entered at its test). }

procedure add_conflict(
    r: reg_range_ptr_t;
    k: integer);
var
  p: reg_conflict_ptr_t;
  last: reg_conflict_ptr_t;
  q: reg_conflict_ptr_t;
begin
  if r^.degree = 0 then begin
    r^.conflict.num := k;
    r^.degree := 1;
  end
  else if r^.conflict.num <> k then
    if r^.conflict.next = nil then begin
      p := newconflict;
      if p = nil then
        cgerr_no_source(9, 0);
      r^.conflict.next := p;
      p^.next := nil;
      p^.num := k;
      r^.degree := r^.degree + 1;
    end
    else begin
      p := r^.conflict.next;
      while p <> nil do begin
        last := p;
        if p^.num = k then
          return;
        p := p^.next;
      end;
      q := newconflict;
      if q = nil then
        cgerr_no_source(9, 0);
      last^.next := q;
      q^.next := nil;
      q^.num := k;
      r^.degree := r^.degree + 1;
    end;
end;

{ removeconflict - k taken off r's conflicts (the next cell copied into
  r's own when k is there); with none left r is marked colourable
  (flags element 6).

  0x0C5156, 0x6A bytes: the previous cell in A0 (r's +12 first); the
  chain searched from r's next cell without testing it for nil first
  (entered in the loop's body). }

procedure removeconflict(
    r: reg_range_ptr_t;
    k: integer); options(val_param); internal;
var
  prev: reg_conflict_ptr_t;
  p: reg_conflict_ptr_t;
begin
  prev := addr(r^.conflict);
  p := r^.conflict.next;
  if r^.conflict.num = k then begin
    if p <> nil then begin
      prev^.next := p^.next;
      prev^.num := p^.num;
    end
    else
      r^.conflict.num := 0;
    r^.degree := r^.degree - 1;
  end
  else
    repeat
      if p^.num = k then begin
        prev^.next := p^.next;
        r^.degree := r^.degree - 1;
        exit;
      end;
      prev := p;
      p := p^.next;
    until p = nil;
  if r^.degree = 0 then
    r^.flags := r^.flags + [6];
end;

{ walkconflicts - p of each range r conflicts with.

  0x0C51C0, 0x56 bytes, link #-8: nothing when r's degree is 0; the
  cells from r's own (+12, `lea'); reg_ranges' address kept in D4, the
  range's address pushed (`pea (-0x40,A4,D0.l)') and p called through
  its trampoline (`jsr (A0)'); the next cell read before the call. }

procedure walkconflicts(
    procedure p(var x: reg_range_t);
    var r: reg_range_t);
var
  c: reg_conflict_ptr_t;
  nx: reg_conflict_ptr_t;
begin
  if r.degree <> 0 then begin
    c := addr(r.conflict);
    repeat
      nx := c^.next;
      p(reg_ranges^[c^.num]);
      c := nx;
    until c = nil;
  end;
end;

{ conflictfree - whether k is not among r's conflicts.

  0x0C5216, 0x28 bytes: no frame, r at (4,SP) and k at (8,SP)
  (docs/rev889-patterns.md 16); D0 cleared first, `st' when the chain
  ends without k. }

function conflictfree(
    r: reg_range_ptr_t;
    k: integer): boolean; options(val_param); internal;
var
  p: reg_conflict_ptr_t;
begin
  conflictfree := false;
  if r^.conflict.num = k then
    return;
  p := r^.conflict.next;
  while p <> nil do begin
    if p^.num = k then
      return;
    p := p^.next;
  end;
  conflictfree := true;
end;

{ color_graph - colour the n ranges r^[1..n].

  First each numbered statement's extra temporaries are taken out of
  its free registers (reduce_temp_regs).  Each range that may have a
  register prefers its class's registers (data D0..D7, address
  A0..A4, floating FP0..FP7 unless -FRND) and gets none when
  availcolors finds no register, flags element 6 when it has more than
  conflicts.  A C function's result that may have D0 or A0 prefers the
  ones available and its conflicts lose them (targetfunctionresult).
  Then for each uncoloured range with a priority and registers: with
  conflicts, it prefers the registers its conflicts cannot have
  (computecommonregs, setcommonregs passes them on); then while it is
  uncoloured and has conflicts and registers, its conflict of highest
  priority (itself first) is coloured, or given up (an address range
  of a language other than Fortran tries a data register next time,
  flags element 3; else element 0; its priority cleared) and the range
  is looked at afresh; the one taken is removed from the graph.  Then
  the colourable ranges not yet coloured (not both address and data),
  then the address ranges left get a data register when one is
  available (their nodes' classes set to a data register's, 4).

  0x0C5772, 0x4E8 bytes, link #-108: the three trampolines built at
  -52, -74, -92 (cache_$clear after each); the statements from
  opt_region to runbackend_16 (unsigned, `bcs'); the ranges by `dbf'
  (a count at -106) with A3 the range's end (r + 64i); -FRND the
  byte 0x2C366B bit 6 through A2 = 0x2C3664; availcolors' result
  compared `bgt'/`ble' with the degree; the result's registers
  `andi.l #0x101'; the common registers `not.l; and.l; andi.l
  #0xFFFFFF'; the highest priority by a signed compare (`bge') of
  +48; `sgt'/`sle' of availcolors' result kept in a register and
  tested (a boolean); the given-up path jumps back to the range's
  first test (`cmpi.w #31,D6; beq' to 0x0C5966, written as a goto);
  the kinds of the third pass 190, 110, 137, 189 compared in turn.

  Not known from the original: the locals' names; how the jump back
  was written. }

procedure color_graph;
label
  10;
var
  pick: reg_regset_t;
  common: reg_regset_t;
  s: g_opt_num_t;
  i: integer;
  k: integer;
  best: integer;
  col: integer;
  c2: integer;
  m: integer;
  x: reg_range_ptr_t;
  y: reg_range_ptr_t;
  cf: reg_conflict_ptr_t;
  t: il_$node_ptr_t;
  a: reg_regset_t;
  ok: boolean;

  { count_regs - the registers in s.

    0x0C523E, 0x40 bytes: a `dbf' of 32 over the bits, each one found
    cleared from s (`bset; not.l; and.l') and the loop left when s is
    empty. }

  function count_regs(
      s: reg_regset_t): integer; options(val_param);
  var
    n: integer;
    j: integer;
  begin
    n := 0;
    if s <> [] then
      for j := 0 to 31 do
        if j in s then begin
          n := n + 1;
          s := s - [j];
          if s = [] then
            exit;
        end;
    count_regs := n;
  end;

  { reduce_temp_regs - temp_regs (a statement's regs) with its extra
    temporaries taken: for each class (data D0..D7 by the markers
    24..26, address A0..A4 by 27..29, floating FP0..FP7 by 30..31), the
    markers not set (each an extra temporary needed) taken one by one
    for the class's registers not free, the highest marker first, and
    set.

    0x0C52F6, 0x5A bytes, link #-16: the set at -8 (`not.l; andi.l'
    for each class); reduce's bounds pushed as one longword (0 and 7
    by `pea 0x7', docs/rev889-patterns.md 54). }

  procedure reduce_temp_regs;
  var
    regs: reg_regset_t;
    j: integer;

    { reduce - for each register lo..hi not in regs, the highest marker
      of s taken from s and set in regs, until s's markers are used.

      0x0C527E, 0x78 bytes: the parent's frame from the dynamic link
      (`movea.l (A6),A2'); the markers searched 31 down to 24 (a `dbf'
      of 8) with the parent's word at -10 as the index. }

    procedure reduce(
        lo: integer;
        hi: integer;
        s: reg_regset_t); options(val_param);
    var
      n: integer;
      k: integer;
    begin
      if s = [] then
        return;
      n := count_regs(s);
      if n = 0 then
        return;
      for k := lo to hi do
        if not (k in regs) then begin
          for j := 31 downto 24 do
            if j in s then begin
              s := s - [j];
              exit;
            end;
          regs := regs + [j];
          n := n - 1;
          if n = 0 then
            return;
        end;
    end;

  begin
    regs := temp_regs;
    reduce(0, 7, ([0..31] - regs) * [24..26]);
    reduce(8, 12, ([0..31] - regs) * [27..29]);
    reduce(16, 23, ([0..31] - regs) * [30..31]);
    temp_regs := regs;
  end;

  { available - the registers of r's class with the class's markers
    (none for a range given up; floating ones only when il_180's +376
    bit 7 is set and not under -FRND).

    0x0C5350, 0x5A bytes: no frame, r at (4,SP); the flags' low byte
    (+39) tested `btst' 0, 3, 2, 4 in turn; the sets 0x070000FF,
    0x38001F00, 0xC0FF0000 in D0. }

  function available(
      r: reg_range_ptr_t): reg_regset_t; options(val_param);
  begin
    if 0 in r^.flags then
      available := []
    else if 3 in r^.flags then
      available := [0..7, 24..26]
    else if 2 in r^.flags then
      available := [8..12, 27..29]
    else if (4 in r^.flags) and ((ord(il_180^.xc[376]) & 16#80) <> 0) and
            not cargs_$options.frnd then
      available := [16..23, 30..31]
    else
      available := [];
  end;

  { availcolors - the registers r may have (avail): those of its class
    free over every statement whose point 2s it covers (a cse parent's
    over all it spans), deleted statements skipped; the result the
    fewest registers left at any of them once the extra temporaries
    are counted (0 when some statement has none, or when no register
    is left).

    0x0C53AA, 0xEC bytes, link #-32: available's set in D4 and at -8;
    the statements first..last (unsigned, `bcs'); the counts
    sign-extended and compared `ble' with the fewest (D6, from 32767);
    the markers cleared at the end (`clr.b (-8,A6)'); the result at
    -22, set only when avail is not empty (the `move.l' to +56 sets
    the condition codes). }

  function availcolors(
      r: reg_range_ptr_t): integer; options(val_param);
  var
    res: integer;
    av: reg_regset_t;
    free: reg_regset_t;
    s: g_opt_num_t;
    fewest: integer32;
    used: integer32;
    left: integer32;
    st: g_opt_stmt_ptr_t;
    all: reg_regset_t;
  begin
    res := 0;
    all := available(r);
    av := all;
    fewest := 32767;
    for s := r^.first to r^.last do begin
      st := opt_4009c[s];
      if st^.hdr.deleted then
        next;
      if (r^.node = nil) or (r^.node^.kind <> cse_parent_ob) then
        if not test_stmt(r, s * 2) then
          next;
      free := all * st^.regs;
      used := count_regs((all - free) * [24..31]);
      left := count_regs(free * [0..23]) - used;
      if left < fewest then
        fewest := left;
      if fewest <= 0 then begin
        availcolors := res;
        return;
      end;
      av := av * free;
    end;
    av := av - [24..31];
    r^.avail := av;
    if av <> [] then
      res := fewest;
    availcolors := res;
  end;

  { paint - q given register c: c no longer free over the statements
    whose point 2s q covers; q's class 5 for an address register, a
    class 5 range given a data register 4; the parameters (146) whose
    node is q's that conflict with it and got no register are given up
    (checkout); the other ranges of q's node prefer c, and an
    uncoloured range sharing a class with q that may have c, prefers
    nothing yet, does not conflict with q and is live just after q's
    last statement prefers c alone.

    0x0C54F6, 0x17E bytes, link #-48: color_graph's frame kept at -44
    from the dynamic link (its r at +8, n at +12); checkout's
    trampoline at -36; the bit (D2) `bset'; the statements first..last
    (unsigned); the class's sets 0xFF00 and 0xFF; the ranges by `dbf'
    with A2 at r + 64i. }

  procedure paint(
      q: reg_range_ptr_t;
      c: integer); options(val_param);
  var
    s: g_opt_num_t;
    i: integer;
    z: reg_range_ptr_t;

    { checkout - x given up when it is a parameter (146) whose +24 is
      q's node and got no register: flags element 0, and q and x no
      longer conflict.

      0x0C5496, 0x60 bytes: loads A5; paint's frame from A1. }

    procedure checkout(
        var x: reg_range_t);
    begin
      if x.node^.kind = ptr_node then
        if x.node^.xp[6] = q^.node then
          if x.reg = 31 then begin
            x.flags := x.flags + [0];
            removeconflict(q, x.num);
            removeconflict(addr(x), q^.num);
          end;
    end;

  begin
    for s := q^.first to q^.last do
      if test_stmt(q, s * 2) then
        opt_4009c[s]^.regs := opt_4009c[s]^.regs - [c];
    q^.reg := c;
    if c in [8..15] then
      q^.rlen := 5
    else if q^.rlen = 5 then
      if c in [0..7] then
        q^.rlen := 4;
    walkconflicts(checkout, q^);
    for i := 1 to n do begin
      z := addr(r^[i]);
      if z^.node = q^.node then
        z^.prefer := z^.prefer + [c]
      else if z^.reg = 31 then
        if q^.flags * z^.flags <> [] then
          if c in z^.avail then
            if z^.prefer = [] then
              if conflictfree(q, i) then
                if test_stmt(z, q^.last * 2 + 1) then
                  z^.prefer := [c];
    end;
  end;

  { pickcolor - the register for r: of its class (data D0..D7,
    address A0..A4, floating FP0..FP7 unless -FRND), the first of those
    it prefers and may have, else of those it may have; 31 when its
    class has none it may have.

    0x0C5674, 0x96 bytes: color_graph's frame from the dynamic link,
    the set at its -4; the class's mask `(2 << hi) - (1 << lo)'; the
    result in D0, which the loop's index shares: when the loop finds
    no register the image returns hi + 1 (not met: availcolors found
    one), written here as 31. }

  function pickcolor(
      r: reg_range_ptr_t): integer; options(val_param);
  var
    lo: integer;
    hi: integer;
    k: integer;
  begin
    pickcolor := 31;
    if 3 in r^.flags then begin
      lo := 0;
      hi := 7;
    end
    else if 2 in r^.flags then begin
      lo := 8;
      hi := 12;
    end
    else if (4 in r^.flags) and not cargs_$options.frnd then begin
      lo := 16;
      hi := 23;
    end
    else
      return;
    if reg_regset_t(lshft(1, hi) * 2 - lshft(1, lo)) * r^.avail = [] then
      return;
    pick := r^.prefer * r^.avail;
    if pick = [] then
      pick := r^.avail;
    for k := lo to hi do
      if k in pick then begin
        pickcolor := k;
        return;
      end;
  end;

  { targetfunctionresult - x no longer prefers D0 or A0.

    0x0C570A, 0x20 bytes: loads A5; `andi.l #-258' of +28. }

  procedure targetfunctionresult(
      var x: reg_range_t);
  begin
    x.prefer := x.prefer - [0, 8];
  end;

  { computecommonregs - common less the registers x may have (x not
    given up).

    0x0C572A, 0x28 bytes: loads A5; color_graph's -8 through A1. }

  procedure computecommonregs(
      var x: reg_range_t);
  begin
    if not (0 in x.flags) then
      common := common * x.avail;
  end;

  { setcommonregs - x prefers common's registers too.

    0x0C5752, 0x20 bytes: loads A5; color_graph's -8 through A1. }

  procedure setcommonregs(
      var x: reg_range_t);
  begin
    x.prefer := x.prefer + common;
  end;

begin
  for s := opt_region to runbackend_16 do begin
    temp_regs := opt_4009c[s]^.regs;
    reduce_temp_regs;
    opt_4009c[s]^.regs := temp_regs;
  end;
  for i := 1 to n do begin
    x := addr(r^[i]);
    if not (0 in x^.flags) then begin
      if 3 in x^.flags then
        x^.prefer := [0..7]
      else if 2 in x^.flags then
        x^.prefer := [8..12]
      else if 4 in x^.flags then
        if not cargs_$options.frnd then
          x^.prefer := [16..23];
      m := availcolors(x);
      if m <= 0 then
        x^.flags := x^.flags + [0]
      else if m > x^.degree then
        x^.flags := x^.flags + [6];
    end;
  end;
  if il_180^.kind = function_blk then
    for i := 1 to n do begin
      x := addr(r^[i]);
      if x^.node = il_180^.xp[24] then
        if x^.avail * [0, 8] <> [] then begin
          x^.prefer := x^.prefer + available(x) * [0, 8];
          walkconflicts(targetfunctionresult, x^);
        end;
    end;
  for i := 1 to n do begin
10:
    x := addr(r^[i]);
    if (x^.reg = 31) and not (0 in x^.flags) and not (6 in x^.flags) and
       (x^.priority <> 0) and (x^.avail <> []) then begin
      if x^.degree <> 0 then begin
        common := x^.avail;
        walkconflicts(computecommonregs, x^);
        a := available(x) * ([0..31] - common) * [0..23];
        common := a;
        x^.prefer := x^.prefer + a;
        walkconflicts(setcommonregs, x^);
      end;
      while (x^.reg = 31) and (x^.degree <> 0) and (x^.avail <> []) do begin
        best := i;
        cf := addr(x^.conflict);
        while cf <> nil do begin
          k := cf^.num;
          if r^[k].priority <> 0 then
            if r^[best].priority < r^[k].priority then
              if r^[k].reg = 31 then
                if not (6 in r^[k].flags) then
                  best := cf^.num;
          cf := cf^.next;
        end;
        y := addr(r^[best]);
        ok := availcolors(y) > 0;
        if ok then begin
          col := pickcolor(y);
          paint(y, col);
        end
        else begin
          if (2 in y^.flags) and (rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2) then
            y^.flags := y^.flags + [3]
          else
            y^.flags := y^.flags + [0];
          y^.priority := 0;
          col := 31;
        end;
        while y^.degree <> 0 do begin
          k := y^.conflict.num;
          removeconflict(addr(r^[k]), best);
          removeconflict(y, k);
        end;
        if col = 31 then
          goto 10;
      end;
    end;
  end;
  for i := 1 to n do begin
    x := addr(r^[i]);
    if not (0 in x^.flags) then
      if x^.flags * [2, 3] <> [2, 3] then
        if 6 in x^.flags then
          if x^.reg = 31 then begin
            ok := availcolors(x) <= 0;
            if not ok then begin
              c2 := pickcolor(x);
              paint(x, c2);
            end;
          end;
  end;
  for i := 1 to n do begin
    x := addr(r^[i]);
    if x^.reg = 31 then
      if x^.flags * [0, 2] <> [2] then
        x^.flags := x^.flags + [0]
      else begin
        x^.flags := x^.flags + [3];
        ok := availcolors(x) <= 0;
        if ok then
          x^.flags := x^.flags + [0]
        else begin
          paint(x, pickcolor(x));
          t := x^.node;
          if t^.kind = cse_parent_ob then
            t^.xp[1]^.xw[12] := 4
          else if t^.kind = fortran_symbol then begin
            if (t^.xl[6] & 16#20000) <> 0 then
              t^.xc[10] := chr((ord(t^.xc[10]) & 16#F0) ! 3);
          end
          else if t^.kind = tree_node then
            t^.xw[12] := 4
          else if t^.kind = cse_use_ob then
            t^.xp[5]^.xw[12] := 4;
          x^.rlen := 4;
        end;
      end;
  end;
end;
