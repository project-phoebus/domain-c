{ reg_vars - the debugger's view of the register allocation (-DBS,
  -DBA): for each variable and parameter that has a debugger index, the
  points where its value is in a register (the live ranges given one)
  and where it is in memory (an availability analysis over the basic
  blocks of the 191 statements' loads and stores, propagate_availability),
  turned into ranges of source lines (calc_ln: a line and the count of
  statements of that line before) kept in 28-byte records on the
  variable's node (+68 of a variable, +54 of a parameter); the function
  result's range made when the allocator did not give it one
  (need_lr_for_fvar).

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C8B28  --------  propagate_availability
    0x0C8D24  --------  initialize_4_bit_vectors
    0x0C8E64  --------  bit_set
    0x0C8EA8  --------  bit_clear
    0x0C8EEE  --------  bit_range_set
    0x0C905A  --------  find_next
    0x0C90DE  --------  calculate_memory_ranges
    0x0C94EA  --------  calc_ln
    0x0C9668  --------  get_range
    0x0C999A  --------  fill_avail_heap
    0x0C9A6E  --------  is_reg_candidate
    0x0C9BFE  --------  need_lr_for_fvar
    0x0C9E58  --------  store_debug_info
    A5 0x2D2590 (cc.m68k; reg_life.pas, which has no data, loads the
    same): the module's data, 0xC4 bytes: +0 the debugger indexes
    given (a set of 0..255), +32 the variables by index (10 bytes
    each), +36 the blocks' bit vectors' storage, +40 the blocks' four
    vectors, +44 the end of +48's two arrays, +48 and +52 by index the
    points where the value is in memory and in a register (reg_words
    longwords each), +56 the blocks, +58 the indexes given, +0x40 ..
    +0xBF the masks -1 shl k (.rwdi), +0xC0 not addressed.

  Only store_debug_info loads A5 (global, reg_alloc.ins.pas); the
  others are internal or nested in it (calc_ln, get_range,
  fill_avail_heap, is_reg_candidate, need_lr_for_fvar) and run on its
  A5; need_lr_for_fvar and get_range take its frame from the dynamic
  link, fill_avail_heap from A1.

  Not known from the original: the names of the module's variables, the
  locals and the parameters; the 28-byte range record's fields beyond
  those set here.
}
module reg_vars;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';

type
  { A bit vector of the availability analysis (a block's): by debugger
    index. }
  rv_set_t = array [0..16383] of set of 0..31;
  rv_set_ptr_t = ^rv_set_t;

  { The memory and register points' bits, as longwords. }
  rv_words_t = array [0..16383] of integer32;
  rv_words_ptr_t = ^rv_words_t;

  { A block's four vectors: v[0] the indexes it does not store, v[1]
    those in memory at its entry, v[2] at its exit, v[3] those it
    stores (16 bytes, by block number from opt_first_block). }
  rv_vecs_t = record
    v: array [0..3] of rv_set_ptr_t;
  end;
  rv_blocks_t = array [0..16383] of rv_vecs_t;
  rv_blocks_ptr_t = ^rv_blocks_t;

  { A variable by debugger index (10 bytes): its node, the statement
    from which its value is in memory, the register it is in (31
    none). }
  rv_var_t = record
    node: il_$node_ptr_t;               { +0 }
    stmt: g_opt_stmt_ptr_t;             { +4 }
    reg: integer;                       { +8 }
  end;
  rv_vars_t = array [1..255] of rv_var_t;
  rv_vars_ptr_t = ^rv_vars_t;

  { A source position: a line and how many statements of that line
    come before (24 and 8 bits). }
  rv_pos_t = packed record
    cnt: 0..255;
    line: 0..16777215;
  end;

  { The debugger's range of a variable (28 bytes from gspace): where
    it is (reg: a register, 31 memory) from start to stop. }
  rv_lr_ptr_t = ^rv_lr_t;
  rv_lr_t = record
    next: rv_lr_ptr_t;                  { +0 }
    node: il_$node_ptr_t;               { +4: the variable when in
                                          memory }
    unused_8: integer32;                { +8 }
    loc: packed record                  { +12 }
      b12: 0..255;
      reg: 0..63;                       { +13 .7..2 }
      kind: 0..3;                       { .1..0: 1 a parameter's or
                                          variable's of class 5 }
    end;
    unused_14: integer;                 { +14 }
    unused_16: integer;                 { +16 }
    count: integer;                     { +18 }
    start: rv_pos_t;                    { +20 }
    stop: rv_pos_t;                     { +24 }
  end;

var
  seen: set of 0..255;                  { +0 }
  vars: rv_vars_ptr_t;                  { +32 }
  heap: univ_ptr;                       { +36 }
  vecs: rv_blocks_ptr_t;                { +40 }
  bits_end: univ_ptr;                   { +44 }
  membits: rv_words_ptr_t;              { +48 }
  regbits: rv_words_ptr_t;              { +52 }
  nblocks: integer;                     { +56 }
  nvars: integer;                       { +58 }
  unused_60: integer32;                 { +60 }
  masks: array [0..31] of integer32 := [
    -1, -2, -4, -8, -16, -32, -64, -128, -256, -512, -1024, -2048,
    -4096, -8192, -16384, -32768, -65536, -131072, -262144, -524288,
    -1048576, -2097152, -4194304, -8388608, -16777216, -33554432,
    -67108864, -134217728, -268435456, -536870912, -1073741824,
    16#80000000];                       { +0x40 }
  unused_c0: integer32;                 { +0xC0 }

define
  store_debug_info;

{ propagate_availability - the indexes in memory at each block's entry
  (those at the exits of all its predecessors) and exit (those at its
  entry it does not store, and those it stores), until nothing changes.

  0x0C8B28, 0x1FC bytes, link #-4144: a 4096-byte local for the
  meet; the blocks from opt_first_block by post_prev (+52); a vector
  copied from the first longword that differs. }

procedure propagate_availability; internal;
var
  tmp: array [0..1023] of set of 0..31;
  b: g_opt_block_ptr_t;
  e: g_opt_edge_ptr_t;
  n: integer32;
  k: integer32;
  j: integer32;
  done: boolean;
  w: set of 0..31;
  vb: rv_vecs_t;
begin
  n := (nvars + 31) div 32 - 1;
  repeat
    done := true;
    b := g_opt_blocks_ptr_t(il_11c)^[opt_first_block];
    while b <> nil do begin
      e := b^.preds_list;
      if e <> nil then
        if e^.src <> nil then begin
          for k := 0 to n do
            tmp[k] := vecs^[e^.src^.num - opt_first_block].v[2]^[k];
          e := e^.next_pred;
          while e <> nil do begin
            for k := 0 to n do
              tmp[k] := tmp[k] * vecs^[e^.src^.num - opt_first_block].v[2]^[k];
            e := e^.next_pred;
          end;
          for k := 0 to n do
            if vecs^[b^.num - opt_first_block].v[1]^[k] <> tmp[k] then begin
              done := false;
              for j := k to n do
                vecs^[b^.num - opt_first_block].v[1]^[j] := tmp[j];
              exit;
            end;
        end;
      vb := vecs^[b^.num - opt_first_block];
      for k := 0 to n do begin
        w := vb.v[1]^[k] * vb.v[0]^[k] + vb.v[3]^[k];
        if w <> vb.v[2]^[k] then begin
          done := false;
          vb.v[2]^[k] := w;
          for j := k + 1 to n do
            vb.v[2]^[j] := vb.v[1]^[j] * vb.v[0]^[j] + vb.v[3]^[j];
          exit;
        end;
      end;
      b := b^.post_prev;
    end;
  until done;
end;

{ initialize_4_bit_vectors - each block's four vectors (nvars + 32
  bits each, rounded to longwords) from one heap allocation: v[0] and
  v[2] all set, v[1] and v[3] clear.

  0x0C8D24, 0x140 bytes: rws_$alloc_heap of nblocks * 16 bytes and of
  nblocks * 16 * words (M$MIS$LLL). }

procedure initialize_4_bit_vectors; internal;
var
  size: integer32;
  w: integer32;
  p: integer32;
  b: integer;
  k: integer32;
begin
  nblocks := opt_last_block - opt_first_block + 1;
  size := nblocks * 16;
  vecs := rws_$alloc_heap(size);
  w := (nvars + 32) div 32;
  size := nblocks * 16 * w;
  heap := rws_$alloc_heap(size);
  p := integer32(heap);
  for b := 0 to nblocks - 1 do begin
    vecs^[b].v[0] := rv_set_ptr_t(p);
    vecs^[b].v[1] := rv_set_ptr_t(p + w * 4);
    vecs^[b].v[2] := rv_set_ptr_t(p + w * 8);
    vecs^[b].v[3] := rv_set_ptr_t(p + w * 12);
    for k := 0 to w - 1 do begin
      vecs^[b].v[0]^[k] := [0..31];
      vecs^[b].v[1]^[k] := [];
      vecs^[b].v[2]^[k] := [0..31];
      vecs^[b].v[3]^[k] := [];
    end;
    p := p + w * 16;
  end;
end;

{ bit_set - set bit k of v.

  0x0C8E64, 0x44 bytes: the bit made in a cleared longword temporary
  (`bset') and or-ed in. }

procedure bit_set(
    v: rv_set_ptr_t;
    k: integer); options(val_param); internal;
begin
  v^[k div 32] := v^[k div 32] + [k mod 32];
end;

{ bit_clear - clear bit k of v.

  0x0C8EA8, 0x46 bytes: as bit_set, the temporary complemented and
  and-ed. }

procedure bit_clear(
    v: rv_set_ptr_t;
    k: integer); options(val_param); internal;
begin
  v^[k div 32] := v^[k div 32] - [k mod 32];
end;

{ bit_range_set - mark index k in memory over the points from s1's
  statement to s2's (s1 and s2 moved to the nearest statements with a
  region: s1 back over those with no line, else forward), stopping
  (when stop) at a point where it is in a register.

  0x0C8EEE, 0x16C bytes: the points' pairs as a mask of two bits
  shifted along the longwords (`moveq #3; lsl.l'; the next longword
  when the mask was negative); the variable's index (+74 of a
  variable, +16 of a parameter) times reg_words by M$MIS$LLW. }

procedure bit_range_set(
    k: integer;
    stop: boolean;
    s1: g_opt_stmt_ptr_t;
    s2: g_opt_stmt_ptr_t); options(val_param); internal;
var
  p1: integer32;
  p2: integer32;
  v: integer;
  i: integer32;
  mask: integer32;
begin
  while s1^.hdr.region = 0 do
    if s1^.line = spos_$null_position then
      s1 := s1^.prev
    else
      while s1^.hdr.region = 0 do
        s1 := s1^.next;
  while s2^.hdr.region = 0 do
    if s2^.line = spos_$null_position then
      s2 := s2^.prev
    else
      while s2^.hdr.region = 0 do
        s2 := s2^.next;
  p1 := (s1^.hdr.region - opt_region + 1) * 2;
  p2 := (s2^.hdr.region - opt_region + 1) * 2 + 1;
  if vars^[k].node^.kind = 109 then
    v := vars^[k].node^.xw[37]
  else
    v := vars^[k].node^.xw[8];
  i := (v - 1) * reg_words + p1 div 32;
  mask := lshft(3, p1 & 31);
  while p1 <= p2 do begin
    membits^[i] := membits^[i] ! mask;
    if stop then
      if (regbits^[i] & mask) <> 0 then
        exit;
    p1 := p1 + 2;
    if mask < 0 then begin
      mask := 3;
      i := i + 1;
    end
    else
      mask := lshft(mask, 2);
  end;
end;

{ find_next - the first index after k (from 1 when k is 0) set in v;
  0 when none.

  0x0C905A, 0x84 bytes: the first longword masked with masks[k mod
  32], the others whole; the bit found by shifting 1. }

function find_next(
    v: rv_set_ptr_t;
    k: integer): integer; options(val_param); internal;
var
  j: integer;
  n: integer;
  i: integer;
  b: integer;
  x: integer32;
begin
  find_next := 0;
  if k = 0 then
    j := 1
  else
    j := k + 1;
  n := (nvars + 31) div 32;
  i := j div 32;
  if i < n then begin
    b := j & 31;
    x := masks[b] & integer32(v^[i]);
    if x = 0 then begin
      repeat
        i := i + 1;
        if i >= n then
          return;
        x := integer32(v^[i]);
      until x <> 0;
      b := 0;
    end;
    while (lshft(1, b) & x) = 0 do
      b := b + 1;
    find_next := i * 32 + b;
  end;
end;

{ calculate_memory_ranges - for each block (from opt_first_block by
  post_prev), from the 191 statements before its first: the indexes
  in registers at its entry (the block's +24 table of the 24
  registers' contents), then statement by statement the stores and
  loads of the 191 statements (a store: in memory from there, not in
  a register after an action 32, in register reg after a load) and
  the assignments (out of memory: the range in memory up to there is
  marked); then the availability at the blocks' entries marked up to
  where a register takes over.

  0x0C90DE, 0x40C bytes, link #-36: the debugger index at +78 of a
  variable, +68 of a parameter (-1 for other nodes); a call (188)
  stands for the assignment of its +48. }

procedure calculate_memory_ranges; internal;
type
  ent_t = record
    unused_0: integer32;
    node: il_$node_ptr_t;
  end;
  ents_ptr_t = ^array [0..23] of ent_t;
var
  b: g_opt_block_ptr_t;
  s: g_opt_stmt_ptr_t;
  last: g_opt_stmt_ptr_t;
  t: il_$node_ptr_t;
  done: boolean;
  j: integer;
  k: integer;
  v: integer;
  vb: rv_vecs_t;

  { The debugger index of t, -1 for nodes other than variables and
    parameters. }
  function index_of(t: il_$node_ptr_t): integer;
  begin
    index_of := -1;
    if t^.kind = 109 then
      index_of := t^.xw[39]
    else if t^.kind = 110 then
      index_of := t^.xw[34];
  end;

begin
  initialize_4_bit_vectors;
  b := g_opt_blocks_ptr_t(il_11c)^[opt_first_block];
  while b <> nil do begin
    s := b^.first_stmt;
    last := b^.last_stmt^.next;
    done := false;
    while (s^.prev <> nil) and not done do
      if s^.prev^.kind = 191 then
        s := s^.prev
      else
        done := true;
    for k := 1 to nvars do begin
      vars^[k].reg := 31;
      vars^[k].stmt := nil;
    end;
    if g_opt_bb_ptr_t(b)^.cache_in <> nil then
      for j := 0 to 23 do
        if ents_ptr_t(g_opt_bb_ptr_t(b)^.cache_in)^[j].node <> nil then begin
          v := index_of(ents_ptr_t(g_opt_bb_ptr_t(b)^.cache_in)^[j].node);
          if v > 0 then
            vars^[v].reg := j;
        end;
    vb := vecs^[b^.num - opt_first_block];
    repeat
      if s^.kind = 191 then begin
        for j := 1 to s^.act_count do begin
          v := index_of(s^.acts[j].node);
          if v > 0 then begin
            if ((s^.acts[j].action & 8) <> 0) or
               ((s^.acts[j].action & 3) = 3) then begin
              bit_clear(vb.v[0], v);
              bit_set(vb.v[3], v);
              if vars^[v].stmt = nil then
                vars^[v].stmt := s;
            end;
            if (s^.acts[j].action & 32) <> 0 then
              vars^[v].reg := 31;
            if (s^.acts[j].action & 1) <> 0 then
              vars^[v].reg := s^.acts[j].reg;
          end;
        end;
      end
      else if (s^.kind = 188) or (opt_4009c[s^.hdr.region]^.hdr.vnum <> 0) then begin
        if s^.kind = 188 then
          t := s^.x48
        else
          t := opt_4009c[s^.hdr.region]^.vars^[opt_4009c[s^.hdr.region]^.hdr.vnum]^.node;
        v := index_of(t);
        if v > 0 then begin
          bit_clear(vb.v[0], v);
          bit_clear(vb.v[3], v);
          if vars^[v].stmt <> nil then begin
            bit_range_set(v, false, vars^[v].stmt, s^.prev);
            vars^[v].stmt := nil;
          end;
          if (vars^[v].reg = 31) or (s^.kind = 188) then begin
            bit_set(vb.v[3], v);
            vars^[v].stmt := s;
          end;
        end;
      end;
      s := s^.next;
    until s = last;
    for k := 1 to nvars do
      if vars^[k].stmt <> nil then
        bit_range_set(k, false, vars^[k].stmt, b^.last_stmt);
    b := b^.post_prev;
  end;
  propagate_availability;
  b := g_opt_blocks_ptr_t(il_11c)^[opt_first_block];
  while b <> nil do begin
    k := find_next(vecs^[b^.num - opt_first_block].v[1], 0);
    while k <> 0 do begin
      bit_range_set(k, true, b^.first_stmt, b^.last_stmt);
      k := find_next(vecs^[b^.num - opt_first_block].v[1], k);
    end;
    b := b^.post_prev;
  end;
end;

{ store_debug_info - the debugger's ranges of the n ranges r^[1..n]'s
  variables and parameters (and the function result's): under -DBS or
  -DBA (db 2 or 3) only.

  0x0C9E58, 0x3C6 bytes, link #-100: the module's set cleared by eight
  `clr.l'; the memory and register arrays from one rws_$alloc_heap of
  (words + 2 * words * il_180's +290) longwords (`muls.w'), of which
  2 * words * +290 cleared; the variables' table by PAS_$NEW and
  PAS_$DISPOSE of nvars * 10 bytes; the heaps released with a status
  in the frame. }

procedure store_debug_info(
    var r: reg_ranges_ptr_t;
    words: integer;
    n: integer);
var
  lrbits: rv_words_ptr_t;               { -68 }
  lr: reg_range_t;                      { -64 }
  nparams: integer;                     { -82 }
  status: status_$t;                    { -80 }
  need: boolean;
  ok: boolean;
  sz: integer32;
  size: integer32;
  k: integer32;
  v: integer;

  { calc_ln - the source position of statement s: its line (of the
    statement before when it has none: the routine's +300 when that is
    the routine's first region's in C or Fortran), how many statements
    of that line come before it (less the first region's), and the
    region of the statement before.

    0x0C94EA, 0x17E bytes: the three results by address; C or Fortran
    as `btst' of lang in 12. }

  procedure calc_ln(
      s: reg_num_t;
      out ln: integer;
      out cnt: integer;
      out nx: integer); options(val_param);
  var
    x: g_opt_stmt_ptr_t;
    y: g_opt_stmt_ptr_t;
    z: g_opt_stmt_ptr_t;
    cf: boolean;
    lang: integer;
    rg: reg_num_t;
  begin
    if s = 0 then begin
      ln := spos_$null_position;
      cnt := 0;
      nx := 0;
    end;
    x := opt_4009c[s];
    ln := x^.line;
    lang := rshft(ord(il_180^.xc[377]) & 16#70, 4);
    cf := lang in [2, 3];
    if ln = spos_$null_position then begin
      x := x^.prev;
      while x <> nil do begin
        rg := x^.hdr.region;
        if (rg <> 0) and cf then
          if rg <= opt_region then begin
            if (rg = opt_region) and (x^.line <> spos_$null_position) then
              ln := x^.line
            else
              ln := il_180^.xw[150];
            cnt := 0;
            nx := 0;
            return;
          end;
        if x^.line <> spos_$null_position then begin
          ln := x^.line;
          exit;
        end;
        x := x^.prev;
      end;
    end;
    nx := 0;
    if x <> nil then begin
      x := x^.prev;
      y := x;
      while y <> nil do begin
        if y^.hdr.region <> 0 then begin
          nx := y^.hdr.region;
          exit;
        end;
        y := y^.prev;
      end;
    end;
    cnt := 0;
    z := nil;
    while x <> nil do begin
      if x^.line <> spos_$null_position then begin
        if x^.line <> ln then
          exit;
        cnt := cnt + 1;
        z := x;
      end;
      rg := x^.hdr.region;
      if rg <> 0 then
        if rg <= opt_region then
          exit;
      x := x^.prev;
    end;
    if cf then
      if z <> nil then
        if z^.hdr.region = opt_region then
          cnt := cnt - 1;
  end;

  { get_range - the debugger's ranges of variable t from bits (points
    of reg_words longwords): each run of set point pairs becomes a
    range of t in reg, from the first statement's position to the
    last's; a range of t that ends where the run begins (by the next
    region's position) is extended instead; a run inside one of t's
    ranges is dropped.

    0x0C9668, 0x332 bytes, link #-60: the parent's frame from the
    dynamic link (words its (12)); the mask of two bits as in
    bit_range_set; the statements spanned limited to opt_region +
    opt_main_60 - 1; the first comparison of the extension evaluated
    whole (`seq; seq; and.b'); the range record's 24-bit lines merged
    with `andi.l #0xFF000000; or.l'. }

  procedure get_range(
      bits: rv_words_ptr_t;
      t: il_$node_ptr_t;
      reg: integer); options(val_param);
  var
    i: integer32;
    p: integer32;
    mask: integer32;
    s1: integer32;
    s2: integer32;
    last: integer;
    s2w: integer;
    ln1, cnt1, nx1: integer;
    ln2, cnt2, nx2: integer;
    ln3, cnt3: integer;
    q: rv_lr_ptr_t;
    nq: rv_lr_ptr_t;
    found: boolean;
    cls5: boolean;
  begin
    i := 0;
    mask := 3;
    p := 0;
    last := opt_region + opt_main_60 - 1;
    repeat
      while (bits^[i] & mask) = 0 do begin
        p := p + 2;
        if (mask & 16#C0000000) = 0 then
          mask := lshft(mask, 2)
        else begin
          mask := 3;
          i := i + 1;
          if words = i then
            return;
        end;
      end;
      s1 := p div 2 + (opt_region - 1);
      if s1 > last then
        return;
      while (bits^[i] & mask) <> 0 do begin
        p := p + 2;
        if (mask & 16#C0000000) = 0 then
          mask := lshft(mask, 2)
        else begin
          mask := 3;
          i := i + 1;
          if words = i then
            exit;
        end;
      end;
      s2 := (p - 2) div 2 + (opt_region - 1);
      if s2 > last then
        s2 := last;
      s2w := s2;
      if t^.kind = 109 then
        q := rv_lr_ptr_t(t^.xp[17])
      else
        q := rv_lr_ptr_t(t^.xp2[13]);
      calc_ln(s1, ln1, cnt1, nx1);
      calc_ln(s2, ln2, cnt2, nx2);
      calc_ln(nx1, ln3, cnt3, nx2);
      found := false;
      if q <> nil then
        if ((ln3 = q^.stop.line) and (q^.stop.cnt = cnt3)) or
           ((q^.stop.cnt = cnt1) and (ln1 = q^.stop.line) and
            (q^.loc.reg = reg)) then begin
          calc_ln(s2w, ln1, cnt1, nx2);
          q^.stop.cnt := cnt1;
          q^.stop.line := ln1;
          found := true;
        end;
      if not found then begin
        if t^.kind = 109 then
          q := rv_lr_ptr_t(t^.xp[17])
        else
          q := rv_lr_ptr_t(t^.xp2[13]);
        while q <> nil do begin
          if (q^.start.line < ln1) or
             ((ln1 = q^.start.line) and (q^.start.cnt <= cnt1)) then
            if (q^.stop.line > ln2) or
               ((ln2 = q^.stop.line) and (q^.stop.cnt >= cnt2)) then begin
              found := true;
              exit;
            end;
          q := q^.next;
        end;
        if not found then begin
          nq := gspace(28);
          if reg = 31 then
            nq^.node := t
          else
            nq^.node := nil;
          nq^.loc.reg := reg;
          nq^.count := 1;
          nq^.start.cnt := cnt1;
          nq^.start.line := ln1;
          nq^.stop.cnt := cnt2;
          nq^.stop.line := ln2;
          if t^.kind = 109 then begin
            nq^.next := rv_lr_ptr_t(t^.xp[17]);
            t^.xp[17] := il_$node_ptr_t(nq);
            cls5 := t^.xw[36] = 5;
          end
          else begin
            nq^.next := rv_lr_ptr_t(t^.xp2[13]);
            t^.xp2[13] := il_$node_ptr_t(nq);
            cls5 := rshft(ord(t^.xc[11]) & 16#F0, 4) = 5;
          end;
          if cls5 then
            nq^.loc.kind := 1;
        end;
      end;
    until words = i;
  end;

  { fill_avail_heap - or the points of bits into variable v's register
    points (into its memory points when reg is 31); v's debugger index,
    newly given (nvars), or 0 when v had one.

    0x0C999A, 0xD4 bytes, link #-88: the parent's frame in A1 (words
    its (12)); v added to the set through a cleared 32-byte local. }

  function fill_avail_heap(
      bits: rv_words_ptr_t;
      v: integer;
      reg: integer): integer; options(val_param);
  var
    res: integer;
    p: rv_words_ptr_t;
    k: integer;
  begin
    if not (v in seen) then begin
      seen := seen + [v];
      nvars := nvars + 1;
      res := nvars;
    end
    else
      res := 0;
    if reg = 31 then
      p := addr(membits^[(v - 1) * words])
    else
      p := addr(regbits^[(v - 1) * words]);
    for k := 0 to words - 1 do
      p^[k] := p^[k] ! bits^[k];
    fill_avail_heap := res;
  end;

  { is_reg_candidate - whether range rr's variable or parameter has a
    debugger index (its number positive and +34 or +26 bit 14 clear,
    but for the function result): false when its register only stands
    for a call's argument loaded by address (action 2) and the value
    is of class 5.  On the first pass the range's points are or-ed in
    (in memory when its register only carries the argument) and the
    index given recorded (+78 of a variable with +32 bit 2, +68 of a
    parameter with +24 bit 2); on the second the argument's points
    again when they count.

    0x0C9A6E, 0x190 bytes, link #-28: the actions of the 191
    statements before the range's first statement (a call) searched
    from the last; fill_avail_heap called with A1 its parent's frame
    (`move.l (A6),(-28,A6)'). }

  function is_reg_candidate(
      var rr: reg_range_t;
      first: boolean): boolean; options(val_param);
  var
    t: il_$node_ptr_t;
    vnum: integer;
    cls: integer;
    reg: integer;
    res: boolean;
    also: boolean;
    s: g_opt_stmt_ptr_t;
    j: integer;
    found: integer;
    x: integer;
  begin
    t := rr.node;
    if t^.kind = 109 then begin
      if (t^.xw[37] <= 0) or ((t^.xw[17] & 16#4000) <> 0) then begin
        is_reg_candidate := false;
        return;
      end;
      vnum := t^.xw[37];
      cls := t^.xw[36];
    end
    else begin
      if t^.xw[8] <= 0 then begin
        is_reg_candidate := false;
        return;
      end;
      if (t^.xw[13] & 16#4000) <> 0 then
        if t <> il_180^.xp[24] then begin
          is_reg_candidate := false;
          return;
        end;
      vnum := t^.xw[8];
      cls := rshft(ord(t^.xc[11]) & 16#F0, 4);
    end;
    reg := rr.reg;
    res := true;
    also := false;
    if rr.reg <> 31 then
      if rr.defs <= 1 then
        if opt_4009c[rr.first]^.kind = 188 then begin
          s := opt_4009c[rr.first]^.prev;
          found := 0;
          while (found = 0) and (s^.kind = 191) do begin
            j := s^.act_count;
            while (found = 0) and (j >= 1) do
              if s^.acts[j].node = rr.node then
                found := j
              else
                j := j - 1;
            if found = 0 then
              s := s^.prev;
          end;
          if found <> 0 then begin
            if (s^.acts[found].action & 2) = 0 then begin
              is_reg_candidate := true;
              return;
            end;
            if cls <> 5 then
              also := true
            else
              res := false;
            if first then
              reg := 31;
          end;
        end;
    if first then begin
      x := fill_avail_heap(rv_words_ptr_t(rr.live), vnum, reg);
      if x <> 0 then
        if t^.kind = 109 then begin
          t^.xc[32] := chr(ord(t^.xc[32]) ! 4);
          t^.xw[39] := x;
        end
        else begin
          t^.xc[24] := chr(ord(t^.xc[24]) ! 4);
          t^.xw[34] := x;
        end;
    end
    else if also then
      x := fill_avail_heap(rv_words_ptr_t(rr.live), vnum, reg);
    is_reg_candidate := res;
  end;

  { need_lr_for_fvar - whether the function result (il_180's +96)
    needs a range of its own: at the routine's last return (151) with
    a value, in D0 or A0 (C: A0 for a pointer when +375 bit 4; others
    by +374's bits 18 and 20), the point marked in the range the
    allocator gave it in that register, else a range made in the
    parent's lr (bits from opt_main_20); the result given a number
    after the parameters when it has none.

    0x0C9BFE, 0x25A bytes, link #-32: the parent's frame from the
    dynamic link (`movea.l (A6),A2'); the result in D0. }

  function need_lr_for_fvar: boolean;
  var
    k: integer32;
    cls: integer;
    reg: integer;
    f: il_$node_ptr_t;
    p: integer;
    j: integer32;
    w: rv_words_ptr_t;
  begin
    need_lr_for_fvar := false;
    if il_180^.xp[24] <> nil then begin
      k := runbackend_16;
      while opt_region <= k do begin
        if opt_4009c[k]^.kind = 151 then
          exit;
        k := k - 1;
      end;
      if opt_region <= k then
        if opt_4009c[k]^.x48 <> nil then begin
          cls := opt_4009c[k]^.asg_rlen;
          if rshft(ord(il_180^.xc[377]) & 16#70, 4) = 3 then begin
            if (cls = 5) and ((ord(il_180^.xc[375]) & 16#10) <> 0) then
              reg := 8
            else
              reg := 0;
          end
          else if (cls = 5) and ((rshft(il_180^.xl2[93], 11) & 640) <> 128) then
            reg := 8
          else if (rshft(il_180^.xl2[93], 11) & 640) = 512 then
            reg := 8
          else
            reg := 0;
          f := il_180^.xp[24];
          if f^.kind = 109 then begin
            if f^.xw[37] <= 0 then begin
              f^.xw[37] := il_180^.xw[145] + 1;
              nparams := nparams + 1;
            end;
          end
          else if f^.xw[8] <= 0 then begin
            f^.xw[8] := il_180^.xw[145] + 1;
            nparams := nparams + 1;
          end;
          p := (k - opt_region + 1) * 2;
          for j := 1 to n do
            if r^[j].node = il_180^.xp[24] then
              if r^[j].reg = reg then begin
                w := rv_words_ptr_t(r^[j].live);
                w^[p div 32] := w^[p div 32] ! lshft(3, p & 31);
                return;
              end;
          lr.node := il_180^.xp[24];
          lr.first := k;
          lr.last := k;
          lr.reg := reg;
          lr.rlen := cls;
          lr.uses := 1;
          lr.defs := 1;
          lrbits := mem_$alloc(opt_main_20, words * 4);
          if lrbits = nil then
            cgerr_no_source(9, 0);
          lr.live := reg_bits_ptr_t(lrbits);
          for j := 0 to words - 1 do
            lrbits^[j] := 0;
          lrbits^[p div 32] := lrbits^[p div 32] ! lshft(3, p & 31);
          need_lr_for_fvar := true;
        end;
    end;
  end;

begin
  if cargs_$options.db < 2 then
    return;
  seen := [];
  nvars := 0;
  nparams := il_180^.xw[145];
  lrbits := nil;
  vecs := nil;
  heap := nil;
  need := need_lr_for_fvar;
  sz := nparams * words;
  size := (words + 2 * sz) * 4;
  membits := rws_$alloc_heap(size);
  regbits := addr(membits^[sz]);
  bits_end := addr(membits^[2 * sz]);
  for k := 0 to 2 * sz - 1 do
    membits^[k] := 0;
  for k := 1 to n do
    if (r^[k].node^.kind = 110) or (r^[k].node^.kind = 109) then
      ok := is_reg_candidate(r^[k], true);
  if need then
    ok := is_reg_candidate(lr, true);
  if nvars <> 0 then begin
    pas_$new(vars, nvars * 10);
    if vars = nil then
      cgerr_no_source(9, 0);
    for k := 1 to n do
      if (r^[k].node^.kind = 110) or (r^[k].node^.kind = 109) then begin
        if r^[k].node^.kind = 109 then
          v := r^[k].node^.xw[39]
        else
          v := r^[k].node^.xw[34];
        if v > 0 then
          vars^[v].node := r^[k].node;
      end;
    if need then begin
      if lr.node^.kind = 109 then
        v := lr.node^.xw[39]
      else
        v := lr.node^.xw[34];
      if v > 0 then
        vars^[v].node := lr.node;
    end;
    calculate_memory_ranges;
    for k := 1 to n do
      if (r^[k].node^.kind = 110) or (r^[k].node^.kind = 109) then
        if is_reg_candidate(r^[k], false) then
          if r^[k].reg <> 31 then
            get_range(rv_words_ptr_t(r^[k].live), r^[k].node, r^[k].reg);
    if need then
      if is_reg_candidate(lr, false) then
        get_range(rv_words_ptr_t(lr.live), lr.node, lr.reg);
    for k := 1 to nvars do begin
      if vars^[k].node^.kind = 109 then
        v := vars^[k].node^.xw[37]
      else
        v := vars^[k].node^.xw[8];
      get_range(addr(membits^[(v - 1) * words]), vars^[k].node, 31);
    end;
    pas_$dispose(vars, nvars * 10);
  end;
  rws_$release_heap(membits, status);
  if vecs <> nil then
    rws_$release_heap(vecs, status);
  if heap <> nil then
    rws_$release_heap(heap, status);
end;
